local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local Promise = require(ReplicatedStorage.Packages.Promise)
local Tiles = require(ReplicatedStorage.Modules.Tiles)

local Actions = {}
Actions.JumpTo = {}

function Actions.DigTo(worker, target) end

function Actions.PopupTo(worker, target) end

function Actions.JumpTo(worker, target)
	if target:IsA("CFrame") then
		return Promise.new(function(resolve, reject, onCancel)
			worker.cframe = target
			resolve()
		end)
	end

	return Promise.new(function(resolve, reject, onCancel)
		worker.cframe = target:GetPivot()
		resolve()
	end)
end

function Actions.PrepareWork(worker, target: Model, slot, moveY)
	if not target.Parent then
		return Promise.reject("NOTILE")
	end

	local slotPivot = target["w" .. slot]:GetPivot()
	local targetPos = target:GetPivot().Position

	if not moveY then
		return Promise.new(function(resolve, reject, onCancel)

			if not target.Parent then
				reject("NOTILE")
			end

			worker:MoveTo(slotPivot.Position, 0.01):andThen(function()
				worker.cframe = slotPivot
				if not target.Parent then
					reject("NOTILE")
				end
				resolve()
				return
			end)
		end)
	end

	return Promise.new(function(resolve, reject, onCancel)

		if not target.Parent then
			reject("NOTILE")
		end

		worker:MoveTo(targetPos, 0.01):andThen(function()
			worker.animation = "hide"
			local workerPos = slotPivot.Position
			worker.cframe = CFrame.lookAt(workerPos, Vector3.new(targetPos.X, workerPos.Y, targetPos.Z))
			Promise.delay(.2):andThen(function() -- Wait at least 0.2 to ensure that client recieves instructions in seperate package.
				worker.animation = "jump"
				Promise.delay(1):andThen(function()
					worker.cframe = slotPivot
					if not target.Parent then
						reject("NOTILE")
					end
					resolve()
				end)
			end)
		end)
	end)
end

function Actions.CreateReturnPath(worker)
	return worker:CreatePath(worker:GetEntrance(), false)
end

function Actions.CreatePath(worker, target: Model)
	return worker:CreatePath(target.entrance:GetPivot().Position, true)
	-- return Promise.new(function(resolve, reject, onCancel)
	-- 	local path = PathfindingService:CreatePath({
	-- 		AgentRadius = 0.3,
	-- 		AgentHeight = 0.5,
	-- 		AgentCanJump = false,
	-- 		WaypointSpacing = 1,
	-- 		Costs = {
	-- 			NoGoZone = math.huge,
	-- 			Foil = math.huge,
	-- 		},
	-- 	})

	-- 	local settlement: Model = worker:GetSettlementModel()

	-- 	local origin = settlement.entrance:GetPivot().Position
	-- 	local destination = target.entrance:GetPivot().Position

	-- 	local success, result = pcall(function()
	-- 		path:ComputeAsync(origin, destination)
	-- 	end)

	-- 	print(success, result)
	-- 	print(path.Status)

	-- 	local waypoints = path:GetWaypoints()
	-- 	local nearEnough = true

	-- 	if not waypoints[1] then
	-- 		reject("NOPATH")
	-- 	end

	-- 	local pathOrigin = Vector3.new(
	-- 		waypoints[1].Position.X,
	-- 		worker:GetSettlementModel():GetPivot().Position.Y,
	-- 		waypoints[1].Position.Z
	-- 	)

	-- 	local pathDestination = Vector3.new(
	-- 		waypoints[#waypoints].Position.X,
	-- 		worker:GetSettlementModel():GetPivot().Position.Y,
	-- 		waypoints[#waypoints].Position.Z
	-- 	)

	-- 	if waypoints[#waypoints] and ((pathDestination - destination).Magnitude > 1) and ((pathOrigin - origin).Magnitude > 1) then
	-- 		nearEnough = false
	-- 	end

	-- 	if success and (path.Status == Enum.PathStatus.Success) and nearEnough then
	-- 		resolve({ waypoints, path.Blocked })
	-- 	else
	-- 		reject("NOPATH")
	-- 	end
	-- end)
end

function Actions.FollowPath(worker, waypoints, target: Vector3, blocked)
	local promise
	local index = 2
	promise = worker:MoveTo(waypoints[index].Position)
	for i = index + 1, #waypoints, 1 do
		promise = promise:andThen(function()
			return worker:MoveTo(waypoints[i].Position)
		end)
	end

	promise = promise:andThen(function()
		return worker:MoveTo(target)
	end)

	-- Getting rid of this because it doesn't seem to be doing any good.
	-- blocked:Connect(function()
	-- 	print("The path has been blocked!")
	-- end)

	return promise
end

function Actions.MoveToTileEntrance(worker, tile, moveY)
	return worker:MoveToTileEntrance(tile, moveY)
end

-- function Actions.MoveTo(worker, target: Model, speed, offset)
-- 	return Promise.new(function(resolve, reject, onCancel)
-- 		local path = PathfindingService:CreatePath({
-- 			AgentRadius = 0.3,
-- 			AgentHeight = 0.5,
-- 			AgentCanJump = false,
-- 			WaypointSpacing = 1,
-- 			Costs = {
-- 				NoGoZone = math.huge,
-- 				Foil = math.huge,
-- 			},
-- 		})

-- 		if not offset then
-- 			offset = Vector3.new(0, 0, 0)
-- 		end

-- 		local targetPosition

-- 		-- Support passing in a CFrame
-- 		if typeof(target) == "CFrame" then
-- 			targetPosition = target * offset
-- 		else
-- 			targetPosition = target:GetPivot() * offset
-- 		end

-- 		local workerPosition = worker:GetPivot().Position
-- 		local destination = Vector3.new(targetPosition.X, workerPosition.Y, targetPosition.Z)

-- 		local waypoints
-- 		local nextWaypointIndex
-- 		local reachedConnection
-- 		local blockedConnection

-- 		local function followPath()
-- 			local success, result = pcall(function()
-- 				path:ComputeAsync(worker.cframe.Position, destination)
-- 			end)

-- 			print(path.Status)

-- 			if success and path.Status == Enum.PathStatus.Success then
-- 				waypoints = path:GetWaypoints()
-- 				blockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
-- 					if blockedWaypointIndex >= nextWaypointIndex then
-- 						blockedConnection:Disconnect()
-- 						worker:CancelMovement()
-- 						followPath(destination)
-- 					end
-- 				end)

-- 				if not reachedConnection then
-- 					reachedConnection = worker.finishedMoving:Connect(function(reached)
-- 						if reached and nextWaypointIndex < #waypoints then
-- 							nextWaypointIndex += 1
-- 							worker:MoveTo(waypoints[nextWaypointIndex].Position, speed)
-- 						else
-- 							worker:CancelMovement()
-- 							resolve()
-- 							reachedConnection:Disconnect()
-- 							blockedConnection:Disconnect()
-- 						end
-- 					end)
-- 				end

-- 				nextWaypointIndex = 2
-- 				worker:MoveTo(waypoints[nextWaypointIndex].Position, speed)
-- 			else
-- 				print(success)
-- 				print(worker)
-- 				warn("Can't find a path :(", result)
-- 				worker:CancelMovement()
-- 				reject()
-- 			end
-- 		end

-- 		followPath()
-- 	end)
-- end

function Actions.GoToChange(worker, skin, pathInfo)
	return worker:GoToChange(skin, pathInfo)
end

function Actions.Harvest(worker, target)
	return worker:Harvest(target)
end

function Actions.Deposit(worker)
	return Promise.new(function(resolve, reject, onCancel)
		local settle = worker:GetSettlementModel()
		local supplies = settle:GetAttribute("supplyCount")
		if type(worker.inHand) ~= "number" then
			worker:EmptyHands()
			resolve()
			return
		end
		settle:SetAttribute("supplyCount", supplies + worker.inHand)
		worker:EmptyHands()
		resolve()
	end)
end

function Actions.Return(worker)
	return Promise.new(function(resolve, reject, onCancel)
		worker.cframe = worker:GetIdlePosition()
		resolve()
	end)
end

function Actions.SwitchSkin(worker)
	return Promise.new(function(resolve, reject, onCancel)
		worker:SwitchSkin("Axe")
		resolve()
	end)
end

return Actions
