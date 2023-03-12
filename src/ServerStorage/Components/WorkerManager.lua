local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Worker = require(ServerStorage.Components.Worker)

local WorkerManager = {}
WorkerManager.__index = WorkerManager

local Tiles = require(ReplicatedStorage.Modules.Tiles)

local taskPrefix = ServerStorage.Components

local Tasks = {
	IdleTask = require(taskPrefix["Tasks"]).IdleTask,
	WoodTask = require(taskPrefix["Tasks"]).WoodTask,
	SmithTask = require(taskPrefix["Tasks"]).SmithTask,
	FarmTask = require(taskPrefix["Tasks"]).FarmingTask,
	MiningTask = require(taskPrefix["Tasks"]).MiningTask,
	ArchTask = require(taskPrefix["Tasks"]).ArchTask,
}

function WorkerManager.new(settlement, factionColor, tileGetter, playerError, maid)
	local wm = setmetatable({}, WorkerManager)

	wm.tSettlement = settlement -- settlemnent as a lua table
	wm.Color = factionColor
	wm.Workers = {}
	wm.Tiles = {}
	wm.AvailableTasks = {}
	wm.tileGetter = tileGetter
	wm.playerError = playerError
	wm.maid = maid

	wm.maid:GiveTask(function()
		print("Cleaning is happening!")
		for i, v in wm.Workers do
			if v.currentTask then
				if v.currentTask.promise then
					v.currentTask.promise:cancel()
				end
			end
			wm:RemoveWorker(i)
		end
	end)

	return wm
end

function WorkerManager:RefreshTasks() end

function WorkerManager:TaskFromTile() end

--- To make this better, the loop that checks to see if there are any workers on all of the tiles can be changed to make sure that it
--- simply checks until it has a single valid tile.
function WorkerManager:BuildTask(worker)
	local tiles = self.tileGetter()
	local settlementPos = self:GetSettleTile():GetPivot().Position
	local distances = {}

	if worker.currentTask and not worker.currentTask.idle then
		warn("Worker already has task!")
		return
	end

	if not tiles[1] then
		worker.currentTask = Tasks.IdleTask.new(worker)
		return
	end

	for i, v in ipairs(tiles) do
		distances[i] = (settlementPos - v:GetPivot().Position).Magnitude
	end

	local availableSlots = {}
	local aIndex = 1

	for index = 1, #tiles, 1 do
		local tile = tiles[index]
		local temp = {}
		for _, v in self.Workers do
			if v.currentTask.tile == tile and v ~= worker then
				temp[v.currentTask.slot] = true
			end
		end

		if temp[1] and temp[2] then
			tiles[index] = nil
			continue
		end

		if aIndex ~= index then
			tiles[aIndex] = tile
			tiles[index] = nil
		end
		availableSlots[aIndex] = temp
		aIndex += 1
	end

	if not tiles[1] then
		worker.currentTask = Tasks.IdleTask.new(worker)
		return
	end

	local workerTask = Tasks[Tiles.Main[tiles[1].Name].task]
	worker.currentTask = workerTask.new(worker, tiles[1], (not availableSlots[1][1]) and 1 or 2, self.playerError)
end

function WorkerManager:GetSettleTile()
	return self.tSettlement.tile
end

function WorkerManager:GetWorkers()
	return self.Workers
end

function WorkerManager:GetWorkerSlot(tile)
	local capacity = Tiles.Main[tile.Name].capacity
	local used = {}

	for _, worker in self.Workers do
		used[worker.slot] = true
	end

	for i = 1, capacity, 1 do
		if not used[i] then
			return i
		end
	end
end

function WorkerManager:AddWorker()
	local tile = self:GetSettleTile()
	local slot = self:GetWorkerSlot(tile)

	if not slot then
		warn("Can't add any more workers")
		return
	end

	local function neighbourGetter()
		return self:GetWorkers()
	end

	local function taskBuilder(worker)
		return self:BuildTask(worker)
	end

	local worker = Worker.new(tile.Workers, self.Color, self.tSettlement, neighbourGetter, taskBuilder, slot, self.playerError)
	table.insert(self.Workers, worker)
end

function WorkerManager:Kill()
	for index in self:GetWorkers() do
		self:RemoveWorker(index);
	end
end

function WorkerManager:RemoveWorker(index)
	self.Workers[index] = nil;
end

function WorkerManager:UpdateWorkers()
	for _, v in self:GetWorkers() do
		if v.currentTask.idle then
			v:SnapToIdle()
		end
	end

	local workerCount = #self:GetWorkers()
	local capacity = Tiles.Main[self:GetSettleTile().Name].capacity
	local difference = capacity - workerCount

	for i = 1, difference do
		self:AddWorker()
	end

	for _ = -1, difference, -1 do
		self:RemoveWorker()
	end
end

function WorkerManager:SignalIdleWorkers()
	for _, v in pairs(self.Workers) do
		if v:isIdle() then
			v:taskBuilder()
		end
	end
end

local function compressCFrame(worker)
	local workspace = worker:GetSettlementModel().Parent
	local relCFrame: CFrame = workspace:GetPivot():ToObjectSpace(worker.cframe)
	local relPosition = relCFrame.Position
	local x, y, z = relCFrame:ToEulerAnglesXYZ()
	return Vector3int16.new(relPosition.X * 80, relPosition.Y * 80, relPosition.Z * 80),
		Vector3int16.new(math.deg(x) * 80, math.deg(y) * 80, math.deg(z) * 80)
end

local function WorkerSmol(worker)
	local s = {}
	s.Color = worker.colour
	s.Type = worker.workerType
	s.Position, s.Rotation = compressCFrame(worker)
	s.Animation = worker.animation
	return s
end

function WorkerManager:UpdateTable(workerTable, settleuid: string)
	local current = workerTable[settleuid]
	local capacity = Tiles.Main[self:GetSettleTile().Name].capacity

	if not current then
		workerTable[settleuid] = {}
	end

	-- Make sure each value has at least an empty table.
	for i = 1, capacity, 1 do
		workerTable[settleuid][i] = { empty = true }
	end

	for _, worker in self.Workers do
		workerTable[settleuid][worker.slot] = WorkerSmol(worker)
	end
end

function WorkerManager:RemovePlayerTable(workerTable, settleuid)
	workerTable[settleuid] = nil
end

function WorkerManager:Stepped(delta)
	for _, v in self.Workers do
		v:Stepped(delta)
	end
end

-- WorkerManager.IdlePositions = {
-- 	SettlementLV1 = {
-- 		pOffset = {
-- 			Vector3.new(0.75, 0, 0.75),
-- 		},
-- 		aOffset = {
-- 			{ 0, math.rad(180), 0 },
-- 		},
-- 	},
-- 	SettlementLV2 = {
-- 		pOffset = {
-- 			Vector3.new(0.3, 0.4, 0.9),
-- 			Vector3.new(-0.4, 0.4, -0.4),
-- 		},
-- 		aOffset = {
-- 			{ 0, math.rad(180), 0 },
-- 			{ 0, math.rad(180), 0 },
-- 		},
-- 	},
-- 	SettlementLV3 = {
-- 		pOffset = {
-- 			Vector3.new(1.1104736328125, 0.4, -0.8346786499023438),
-- 			Vector3.new(-1.3, 0.4, -0.65),
-- 			Vector3.new(-0.0865631103515625, 0.4, -0.24002838134765625),
-- 		},
-- 		aOffset = {
-- 			{ 0, math.rad(180), 0 },
-- 			{ 0, 0, 0 },
-- 			{ 0, math.rad(180), 0 },
-- 		},
-- 	},
-- 	SettlementLV4 = {
-- 		pOffset = {
-- 			Vector3.new(1.2578182220458984, 0.4, -0.17272186279296875),
-- 			Vector3.new(-1.443382740020752, 0.4, 0.01526641845703125),
-- 			Vector3.new(0.8666377067565918, 1.51, 1.3299789428710938),
-- 			Vector3.new(-0.3000001907348633, 0.4, -0.3000030517578125),
-- 		},
-- 		aOffset = {
-- 			{ 0, math.rad(180), 0 },
-- 			{ 0, 0, 0 },
-- 			{ 0, math.rad(180), 0 },
-- 			{ 0, math.rad(180), 0 },
-- 		},
-- 	},
-- 	SettlementLV5 = {
-- 		pOffset = {
-- 			Vector3.new(0.4895625114440918, 1.4746825695037842, 0.2723731994628906),
-- 			Vector3.new(-0.024521827697753906, 0.4, 1.0382766723632812),
-- 			Vector3.new(0.7297892570495605, 0.4, -0.9290237426757812),
-- 			Vector3.new(1.1829757690429688, 1.5897053480148315, -1.3735885620117188),
-- 			Vector3.new(-0.5518927574157715, 0.4, -0.5445671081542969),
-- 		},
-- 		aOffset = {
-- 			{ 0, math.rad(0), 0 },
-- 			{ 0, 0, 0 },
-- 			{ 0, math.rad(0), 0 },
-- 			{ 0, math.rad(0), 0 },
-- 			{ 0, math.rad(0), 0 },
-- 		},
-- 	},
-- }

return WorkerManager
