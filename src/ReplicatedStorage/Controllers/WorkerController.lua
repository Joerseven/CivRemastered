local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Knit = require(ReplicatedStorage.Packages.Knit)

local function createAnimation(name)
	local animation = Instance.new("Animation")
	animation.AnimationId = name

	return animation
end

local WorkerController = Knit.CreateController({
	Name = "WorkerController",
	Workers = {},
	WorkerModels = {}, -- This array keeps track of the actual worker models
	WorkerSet = {}, -- A set that keeps track of what settlements haven't been visited.
	Animations = {
		WorkerPick = createAnimation("http://www.roblox.com/asset/?id=11871124056"),
		WorkerAxe = createAnimation("http://www.roblox.com/asset/?id=11495986079"),
		WorkerIdle = createAnimation("http://www.roblox.com/asset/?id=10065611379"),
		WorkerDive = createAnimation("http://www.rolox.com/asset/?id=11743231525"),
		WorkerFarm = createAnimation("http://www.roblox.com/asset/?id=10065618502"),
		WorkerSmith = createAnimation("http://www.roblox.com/asset/?id=10065685651"),
		WorkerArch = createAnimation("http://www.roblox.com/asset/?id=10065643313"),
		WorkerJump = createAnimation("https://www.roblox.com/asset/?id=11787192727"),
	},
	Speeds = {
		WorkerPick = 3,
		WorkerAxe = 3,
		WorkerIdle = 3,
		WorkerDive = 1,
		WorkerFarm = 3,
		WorkerSmith = 3,
		WorkerArch = 3,
		WorkerJump = 1,
	},
	WorkspaceTable = {},
})

function WorkerController:InsertWorkerModel(settleIndex, workerIndex, worker)
	if not self.WorkerModels[settleIndex] then
		self.WorkerModels[settleIndex] = {}
	end

	self.WorkerModels[settleIndex][workerIndex] = worker
end

function WorkerController:RemoveWorkerModel(settleIndex, workerIndex)
	self.WorkerModels[settleIndex][workerIndex]:Destroy()
	self.WorkerModels[settleIndex][workerIndex] = nil

	if next(self.WorkerModels[settleIndex]) == nil then
		self.WorkerModels[settleIndex] = nil
	end
end

function WorkerController:DataToCFrame(position: Vector3int16, rotation: Vector3int16, workspaceNumber: number)
	local workerPos = Vector3.new(position.X / 80, position.Y / 80, position.Z / 80)
	local rotationCFrame =
		CFrame.Angles(math.rad(rotation.X / 80), math.rad(rotation.Y / 80), math.rad(rotation.Z) / 80)
	return workspace["Workspace" .. workspaceNumber]:GetPivot():ToWorldSpace(rotationCFrame + workerPos)
end

function WorkerController:CreateWorker(settleIndex, workerIndex, settleTable, workspaceNumber)
	local workerinfo = settleTable[workerIndex]

	local worker = ReplicatedStorage.Models.Workers[workerinfo.Type]:Clone()

	worker:PivotTo(self:DataToCFrame(workerinfo.Position, workerinfo.Rotation, workspaceNumber))

	worker.Body.Color = workerinfo.Color

	worker.Parent = workspace

	self.Workers[settleIndex][workerIndex] = workerinfo
	self:InsertWorkerModel(settleIndex, workerIndex, worker)

	self:ChangeAnimation(settleIndex, workerIndex, "idle")
end

function WorkerController:RemoveWorker(settleIndex, workerIndex)
	self:RemoveWorkerModel(settleIndex, workerIndex)
	self.Workers[settleIndex][workerIndex] = nil
end

function WorkerController:MoveWorker(settleIndex, workerIndex, settlementTable, workspaceNumber)
	local target: CFrame =
		self:DataToCFrame(settlementTable[workerIndex].Position, settlementTable[workerIndex].Rotation, workspaceNumber)
	-- Credit: Kdude, will replace this with my own tweening service when I get the time.
	TweenService:Create(
		self.WorkerModels[settleIndex][workerIndex].PrimaryPart,
		TweenInfo.new(0.2, Enum.EasingStyle.Linear),
		{ CFrame = target }
	):Play()
end

function WorkerController:ChangeWorkerType(settleIndex, workerIndex, workerType)
	local worker = self.WorkerModels[settleIndex][workerIndex]

	local position = worker:GetPivot()
	local factionColor = worker.Body.Color
	local parent = worker.Parent

	worker:Destroy()
	worker = nil

	self.WorkerModels[settleIndex][workerIndex] = ReplicatedStorage.Models.Workers[workerType]:Clone()
	self.WorkerModels[settleIndex][workerIndex]:PivotTo(position)
	self.WorkerModels[settleIndex][workerIndex].Body.Color = factionColor
	self.WorkerModels[settleIndex][workerIndex].Parent = parent

	self:ChangeAnimation(settleIndex, workerIndex, "idle")

	self.Workers[settleIndex][workerIndex].Type = workerType
end

function WorkerController:ChangeAnimation(settleIndex, workerIndex, animationType)
	local worker = self.WorkerModels[settleIndex][workerIndex]
	local workerType = self.Workers[settleIndex][workerIndex].Type

	local anim: AnimationTrack

	for _, v in ipairs(worker.AnimationController.Animator:GetPlayingAnimationTracks()) do
		v:Stop()
	end

	local hide = (animationType == "hide" or animationType == "jump") and 1 or 0

	for _, value in ipairs(worker:GetChildren()) do
		if value:IsA("MeshPart") then
			value.Transparency = hide
		end
	end

	local speed = 3

	if animationType == "idle" then
		anim = worker.AnimationController.Animator:LoadAnimation(self.Animations.WorkerIdle)
	elseif animationType == "dive" then
		anim = worker.AnimationController.Animator:LoadAnimation(self.Animations.WorkerDive)
		speed = 2
	elseif animationType == "work" then
		anim = worker.AnimationController.Animator:LoadAnimation(self.Animations[workerType])
	elseif animationType == "jump" then
		anim = worker.AnimationController.Animator:LoadAnimation(self.Animations.WorkerJump)
		speed = 1.5
	end

	if anim then
		anim.Looped = true

		if animationType == "dive" or animationType == "jump" then
			anim.Looped = false
			local con
			con = anim:GetMarkerReachedSignal("StopHere"):Connect(function()
				anim:AdjustSpeed(0)
				con:Disconnect()
			end)
		end

		if animationType == "jump" then
			local con2
			con2 = anim:GetMarkerReachedSignal("ShowHere"):Connect(function()
				for _, value in ipairs(worker:GetChildren()) do
					if value:IsA("MeshPart") then
						value.Transparency = 0
					end
				end
				con2:Disconnect()
			end)
		end

		anim:Play(0, 1, speed) -- Put the first two arguments as the default arguments, want to play it 3x as fast.
	end

	self.Workers[settleIndex][workerIndex].Animation = animationType
end

function WorkerController:UpdateWorkers(workerTable)
	if not self.workspaceCFrame then
		warn("Hasn't recieved the server info: WorkerController")
		return
	end

	-- This can be optimised by using another data structure. w - Worker, s - Settlement.
	-- table is self.Workers[settlementId](name+playerdid)[workerId](slot)
	for sIndex, sValue in pairs(self.Workers) do
		-- If the settlement isn't in the table then remove all of the workers.
		if not workerTable[sIndex] then
			for wIndex in self.Workers[sIndex] do
				self:RemoveWorker(sIndex, wIndex)
			end
			continue
		end

		-- Check the workers individually to see if they need to be removed.
		for wIndex in pairs(sValue) do
			if (not workerTable[sIndex][wIndex]) or workerTable[sIndex][wIndex].empty then
				self:RemoveWorker(sIndex, wIndex)
				workerTable[sIndex][wIndex] = nil
			end
		end
	end

	for index: string, settlement in pairs(workerTable) do
		if not self.Workers[index] then
			self.Workers[index] = {}
		end

		local workspaceNumber: number = tonumber(index:sub(2,2))

		for i = 1, #settlement, 1 do
			if settlement[i].empty then
				continue
			end

			if not self.Workers[index][i] then
				self:CreateWorker(index, i, settlement, workspaceNumber)
				continue
			end

			if self.Workers[index][i].Type ~= settlement[i].Type then
				self:ChangeWorkerType(index, i, settlement[i].Type)
			end

			if self.Workers[index][i].Animation ~= settlement[i].Animation then
				self:ChangeAnimation(index, i, settlement[i].Animation)
			end

			self:MoveWorker(index, i, settlement, workspaceNumber)
		end
	end
end

function WorkerController:SaveLoaded()
	return self.WorkspaceService:getPlayerWorkspace():andThen(function(pWorkspace)
		self.workspaceCFrame = pWorkspace:GetPivot()
		self.DummyConnection:Disconnect()
		self.SettlementService.UpdateWorkers:Connect(function(...)
			self:UpdateWorkers(...)
		end)
	end)
end

function WorkerController:KnitInit() end

function WorkerController:KnitStart()
	self.WorkspaceService = Knit.GetService("WorkspaceService")
	self.SettlementService = Knit.GetService("SettlementService")

	self.DummyConnection = self.SettlementService.UpdateWorkers:Connect(function(...)
		-- This function should be blank, this stops the remote event invocation queue from building up.
	end)
end

return WorkerController
