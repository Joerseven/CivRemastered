local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Tiles = require(ReplicatedStorage.Modules.Tiles)
local Actions = require(ServerStorage.Components.Actions)

local Worker = {}
Worker.__index = Worker

local EMPTY_TASK = {
	target = false,
}

local EMPTY_MOVEMENT = {}

local NOTHING = {}

local WORKERHEIGHT = 1

local function createAnimation(name)
	local animation = Instance.new("Animation")
	animation.AnimationId = name

	return animation
end

local function subY(position: Vector3, sub: number)
	return Vector3.new(position.X, sub, position.Z)
end

local function lookTowardsSameY(position: Vector3, target: Vector3)
	-- See comment further below
	if position:FuzzyEq(target, 0.00001) then
		return CFrame.new(position)
	end

	return CFrame.lookAt(position, Vector3.new(target.X, position.Y, target.Z))
end

Worker.animations = {
	WorkerPick = createAnimation("http://www.roblox.com/asset/?id=10065557335"),
	WorkerAxe = createAnimation("http://www.roblox.com/asset/?id=11495986079"), --createAnimation("http://www.roblox.com/asset/?id=10065626227"),
	WorkerIdle = createAnimation("http://www.roblox.com/asset/?id=10065611379"),
	WorkerFarm = createAnimation("http://www.roblox.com/asset/?id=10065618502"),
	WorkerSmith = createAnimation("http://www.roblox.com/asset/?id=10065685651"),
	WorkerArch = createAnimation("http://www.roblox.com/asset/?id=10065643313"),
}

---@return CFrame Position
function Worker:GetIdlePosition()
	return self.settlement.tile.IdlePositions["i" .. self.slot]:GetPivot()
end

function Worker.new(parent, factionColor, settlement, otherWorkers, taskBuilder, slot, playerError)
	local w = setmetatable({}, Worker)

	w.settlement = settlement

	w.slot = slot

	w.heartbeatCounter = 0

	w.movementInfo = EMPTY_MOVEMENT

	w.targetPosition = nil
	w.finishedMoving = Signal.new()

	w.colour = factionColor

	--- w.model = ReplicatedStorage.Models.Workers.WorkerIdle:Clone()
	w.workerType = "WorkerIdle"

	w.cframe = w:GetIdlePosition()
	--- w.model:PivotTo(w.idlePosition)

	w.inHand = NOTHING

	w.getSettlementWorkers = otherWorkers

	w.factionColour = factionColor

	w.playerError = playerError

	--w.model.Parent = parent

	w:IdleAnimation()

	w:SnapToIdle()

	w.taskBuilder = taskBuilder

	w:taskBuilder()

	return w
end

---@return Vector3 Entrance
function Worker:GetEntrance()
	return self:GetSettlementModel().entrance:GetPivot().Position
end


function Worker:JumpTo(target)
	self.cframe = CFrame.new(Vector3.new(target.Position.X, self.cframe.Position.Y, target.Position.Z))
	return Promise.resolve()
end

---@return Model settlement
function Worker:GetSettlementModel()
	return self.settlement.tile
end

function Worker:IdleAnimation()
	self.animation = "idle"
end

function Worker:isIdle()
	if self.currentTask.idle then
		return true
	end

	return false
end

function Worker:SwitchSkin(skin)
	self.workerType = skin
	self.animation = "idle"
end

function Worker:TeleportBack(waitTime)
	return Promise.new(function(resolve, reject, onCancel)
		self.animation = "dive"
		Promise.delay(waitTime + 1)
			:andThen(function()
				self.animation = "hide"
				self.cframe = self:GetIdlePosition()

				return Promise.delay(0.2)
			end)
			:andThen(function()
				self.animation = "jump"
				return Promise.delay(1.5)
			end)
			:andThen(function()
				self.animation = "idle"
				resolve()
			end)
	end)
end

function Worker:CreatePath(target: Vector3, isOut: boolean)
	local errorType = isOut and "NOPATH" or "NORETURN"

	return Promise.new(function(resolve, reject, onCancel)
		local path = PathfindingService:CreatePath({
			AgentRadius = 0.5,
			AgentHeight = 0.5,
			AgentCanJump = false,
			WaypointSpacing = 1,
			Costs = {
				NoGoZone = math.huge,
				Foil = math.huge,
			},
		})

		local origin = self.cframe.Position

		if isOut then
			origin = subY(self:GetSettlementModel().entrance:GetPivot().Position, WORKERHEIGHT)
		end

		local destination = subY(target, WORKERHEIGHT)

		if (origin - destination).Magnitude < 1.5 then
			resolve({{
				PathWaypoint.new(origin, Enum.PathWaypointAction.Walk),
				PathWaypoint.new(destination, Enum.PathWaypointAction.Walk)
			}, false}) -- I'm just going to disable the path.Blocked, it doesn't seem to be doing any good. 
		end

		local success = pcall(function()
			path:ComputeAsync(origin, destination)
		end)

		local waypoints = path:GetWaypoints()
		local nearEnough = true

		-- Check waypoints isn't empty, sometimes waypoints is empty and it doesn't return a PathStatus.NoPath
		if not waypoints[1] then
			reject(errorType)
		end

		local pathOrigin = subY(waypoints[1].Position, WORKERHEIGHT)
		local pathDestination = subY(waypoints[#waypoints].Position, WORKERHEIGHT)

		-- if
		-- 	waypoints[#waypoints]
		-- 	and ((pathDestination - destination).Magnitude > 1)
		-- 	and ((pathOrigin - origin).Magnitude > 1)
		-- then
		-- 	-- The path that has been generated isn't near enough to either of the starting points.
		-- 	nearEnough = false
		-- end
		if (pathDestination - destination).Magnitude > 1 or (pathOrigin - origin).Magnitude > 1 then
			nearEnough = false
		end

		if success and (path.Status == Enum.PathStatus.Success) and nearEnough then
			resolve({ waypoints, path.Blocked })
		else
			reject(errorType)
		end
	end)
end

function Worker:CreateReturnPath()
	return Promise.new(function(resolve, reject, onCancel)
		local path = PathfindingService:CreatePath({
			AgentRadius = 0.3,
			AgentHeight = 0.5,
			AgentCanJump = false,
			WaypointSpacing = 1,
			Costs = {
				NoGoZone = math.huge,
				Foil = math.huge,
			},
		})

		local origin = self.cframe.Position
		local destination = self:GetEntrance()

		local success, result = pcall(function()
			path:ComputeAsync(origin, destination)
		end)

		local waypoints = path:GetWaypoints()
		local nearEnough = true

		if not waypoints[1] then
			reject("NORETURN")
		end

		local waypointDestination =
			Vector3.new(waypoints[#waypoints].Position.X, origin.Y, waypoints[#waypoints].Position.Z)

		local waypointOrigin = Vector3.new(waypoints[1].Position.X, origin.Y, waypoints[1].Position.Z)

		if
			waypoints[#waypoints]
			and ((waypointDestination - destination).Magnitude > 1)
			and ((waypointOrigin - origin).Magnitude > 1)
		then
			nearEnough = false
		end

		if path.Status == Enum.PathStatus.Success and nearEnough then
			resolve(waypoints)
		else
			warn("Near enough: ", nearEnough)
			warn("Sucess:", success)
			reject("NORETURN")
		end
	end)
end

function Worker:EndTask()
	self.currentTask = EMPTY_TASK
end

function Worker:GetPivot()
	return self.cframe
end

function Worker:GetTask()
	return self.currentTask
end

function Worker:EmptyHands()
	self.inHand = NOTHING
end

function Worker:CancelMovement()
	self.movementInfo = EMPTY_MOVEMENT
end

function Worker:PathTo(target: Vector3, speed: number, moveY: boolean, blocked, index)
	return Promise.new(function(resolve, reject, onCancel)
		local blockedConnection

		blockedConnection = blocked:Connect(function(blockedWaypointIndex)
			if blockedWaypointIndex >= index then
				blockedConnection:Disconnect()
				reject("BLOCKEDPATH")
			end
		end)
	end)
end

function Worker:MoveTo(target: Vector3, speed: number, moveY: boolean)
	if not speed then
		speed = 0.01
	end

	return Promise.new(function(resolve, reject, onCancel)
		if self.movementInfo ~= EMPTY_MOVEMENT then
			warn("Overwriting movement")
		end

		local moveToY = WORKERHEIGHT

		if moveY then
			moveToY = target.Y
		end

		local connection = self.finishedMoving:ConnectOnce(function()
			self.movementInfo = EMPTY_MOVEMENT
			resolve()
		end)

		onCancel(function()
			connection:Disconnect()
			self.movementInfo = EMPTY_MOVEMENT
		end)

		local modelPosition: Vector3 = self.cframe.Position

		local targetPosition = Vector3.new(target.X, moveToY, target.Z)

		local facing

		if
			(math.abs((targetPosition.X - modelPosition.X)) < 0.001)
			and (math.abs((targetPosition.Z - modelPosition.Z)) < 0.001)
		then
			facing = self.cframe.Rotation + modelPosition
		else
			facing = CFrame.lookAt(modelPosition, targetPosition)
		end

		self.cframe = facing

		self.movementInfo = {
			origin = facing,
			targetCFrame = CFrame.new(targetPosition),
			distance = 0,
			speed = speed,
		}
	end)
end

function Worker:HoldSupply(amount: number)
	if not amount then
		self.inHand = NOTHING
		return
	end

	self.inHand = amount
end

function Worker:Harvest(target: Model)
	return Promise.new(function(resolve, reject, onCancel)
		-- self.animation:Stop()

		if not target.Parent then
			reject("NOTILE")
		end

		local con
		con = target.Destroying:Connect(function()
			reject("NOTILE")
			con:Disconnect()
		end)
		
		self.animation = "work"
		-- self.animation.Looped = true
		-- self.animation:Play()
		-- self.animation:AdjustSpeed(3)

		local times = 3

		local delay = task.delay(10, function()
			con:Disconnect()
			self:HoldSupply(target:GetAttribute("supply") * 30)
			self.animation = "idle"
			resolve()
		end)
	end)
end

function Worker:MoveToTileEntrance(tile: Model, moveY)
	local entrance = tile.entrance:GetPivot()
	local tilePosition = tile:GetPivot()

	self.cframe = CFrame.lookAt(self.cframe.Position, subY(tile:GetPivot().Position, self.cframe.Position.Y))

	if not moveY then
		return self:MoveTo(entrance.Position)
	end

	return Promise.new(function(resolve, reject, onCancel)
		self.animation = "dive"
		Promise.delay(1.5):andThen(function()
			self.cframe =
				CFrame.lookAt(subY(tilePosition, WORKERHEIGHT), subY(entrance.Position, WORKERHEIGHT))
			self.animation = "idle"
			self:MoveTo(subY(entrance.Position, WORKERHEIGHT)):andThen(function()
				resolve()
			end)
		end)
	end)
end

function Worker:MoveToSettleEntrance()
	return self:MoveTo(self:GetEntrance())
end

function Worker:StepTowards(movementinfo, delta)
	local currentPivot: CFrame = self.cframe
	local currentPosition = currentPivot.Position

	local difference = movementinfo.targetCFrame.Position - currentPosition
	local distance = difference.Magnitude

	if (movementinfo.speed == 0) or ((distance >= 0) and (distance <= movementinfo.speed)) then
		self.cframe = movementinfo.targetCFrame
		self.movementInfo = EMPTY_MOVEMENT
		self.finishedMoving:Fire(true)
		return
	end

	local travelling = currentPosition + difference.Unit * movementinfo.speed

	local dest = Vector3.new(travelling.X, travelling.Y, travelling.Z)

	self.cframe = CFrame.new(dest) * currentPivot.Rotation
end

function Worker:GoToChange(skin, pathInfo)
	return Promise.new(function(resolve, reject)
		local currentPosition = self.cframe.Position

		-- If the worker is already at the entrance and is in the right uniform, he can just carry on.
		-- The default FuzzyEq epsilon wouldn't work on equal values? Was weird
		if (currentPosition:FuzzyEq(subY(self:GetEntrance(), WORKERHEIGHT), 0.001)) and (skin == self.workerType) then
			resolve(pathInfo)
			return
		end

		self.cframe = lookTowardsSameY(currentPosition, self:GetSettlementModel():GetPivot().Position)

		if self.movementInfo ~= EMPTY_MOVEMENT then
			error("Already has movement info")
		end

		self.animation = "dive"

		Promise.delay(2):andThen(function()
			self.animation = "hide"
			self.workerType = skin

			Promise.delay(math.random(1,5000)/1250):andThen(function()
				self.cframe = self:GetSettlementModel().entrance:GetPivot()
				Promise.delay(1):andThen(function()
					self.animation = "jump"
					Promise.delay(2):andThen(function()
						self.animation = "idle"
						resolve(pathInfo)
					end)
				end)
			end)
		end)
	end)
end

function Worker:IdleToEntrance()
	local settlement = self:GetSettlementModel()

	local idlePaths = Tiles.Main[settlement.Name].idlePositions.path

	if not idlePaths then
		return self:MoveTo(settlement:GetPivot() * Tiles.Main[settlement.Name].entrance)
	end

	local goToPaths = idlePaths[self.slot]
	local addTo = self:MoveTo(settlement:GetPivot() * goToPaths[1])

	for i = 2, #goToPaths, 1 do
		addTo = addTo:andThen(function()
			return self:MoveTo(settlement:GetPivot() * goToPaths[i])
		end)
	end

	return addTo
end

function Worker:GetNearestHomePoint(goal: Vector3)
	local tile = self:GetSettlementModel()
	local points = Tiles.Main[tile.Name].idlePositions.path[self.slot]
	local pos = self.cframe.Position
	local tilePivot = tile:GetPivot()

	local bestPointIndex = 1
	local bestDistance = math.huge

	for i, v in pairs(points) do
		local distToTarget = (pos - (tilePivot * v)).Magnitude
		if distToTarget < bestDistance then
			local distToGoal = (goal - (tilePivot * v)).Magnitude
			local distPlayerToGoal = (pos - goal).Magnitude
			if distToGoal < distPlayerToGoal then
				bestDistance = distToTarget
				bestPointIndex = i
			end
		end
	end

	return points[bestPointIndex]
end

function Worker:IsHome()
	local tilePosition = self:GetSettlementModel():GetPivot().Position
	local position = self.cframe.Position

	if
		(position.X > tilePosition.X + 1.5)
		or (position.Y > tilePosition.Y + 1.5)
		or (position.X < tilePosition.X - 1.5)
		or (position.Y < tilePosition.Y - 1.5)
	then
		return false
	end

	return true
end

function Worker:CheckMovement()
	return self.movementInfo
end

function Worker:Stepped(delta)
	if self.movementInfo ~= EMPTY_MOVEMENT then
		self:StepTowards(self.movementInfo, delta)
	end
end

function Worker:SnapToIdle()
	local idlePosition = self:GetIdlePosition()
	self.cframe = idlePosition
end

function Worker:ChangeSkin() end

function Worker:UpdateTask() end

function Worker:GiveTask(task) end

return Worker
