local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Worker = require(ServerStorage.Components.Worker)
local WorkerTask = require(ServerStorage.Components.WorkerTask)

local WorkerService = Knit.CreateService({
	Name = "WorkerService",
	Client = {},
})

WorkerService.IdlePositions = {
	SettlementLV1 = {
		pOffset = {
			Vector3.new(0.75, 0, 0.75),
		},
		aOffset = {
			{ 0, math.rad(180), 0 },
		},
	},
	SettlementLV2 = {
		pOffset = {
			Vector3.new(0.3, 0.4, 0.9),
			Vector3.new(-0.4, 0.4, -0.4),
		},
		aOffset = {
			{ 0, math.rad(180), 0 },
			{ 0, math.rad(180), 0 },
		},
	},
	SettlementLV3 = {
		pOffset = {
			Vector3.new(1.1104736328125, 0.4, -0.8346786499023438),
			Vector3.new(-1.3, 0.4, -0.65),
			Vector3.new(-0.0865631103515625, 0.4, -0.24002838134765625),
		},
		aOffset = {
			{ 0, math.rad(180), 0 },
			{ 0, 0, 0 },
			{ 0, math.rad(180), 0 },
		},
	},
	SettlementLV4 = {
		pOffset = {
			Vector3.new(1.2578182220458984, 0.4, -0.17272186279296875),
			Vector3.new(-1.443382740020752, 0.4, 0.01526641845703125),
			Vector3.new(0.8666377067565918, 1.51, 1.3299789428710938),
			Vector3.new(-0.3000001907348633, 0.4, -0.3000030517578125),
		},
		aOffset = {
			{ 0, math.rad(180), 0 },
			{ 0, 0, 0 },
			{ 0, math.rad(180), 0 },
			{ 0, math.rad(180), 0 },
		},
	},
	SettlementLV5 = {
		pOffset = {
			Vector3.new(0.4895625114440918, 1.4746825695037842, 0.2723731994628906),
			Vector3.new(-0.024521827697753906, 0.4, 1.0382766723632812),
			Vector3.new(0.7297892570495605, 0.4, -0.9290237426757812),
			Vector3.new(1.1829757690429688, 1.5897053480148315, -1.3735885620117188),
			Vector3.new(-0.5518927574157715, 0.4, -0.5445671081542969),
		},
		aOffset = {
			{ 0, math.rad(0), 0 },
			{ 0, 0, 0 },
			{ 0, math.rad(0), 0 },
			{ 0, math.rad(0), 0 },
			{ 0, math.rad(0), 0 },
		},
	},
}

function WorkerService:GetWorkersOnSettlement(settlement)
	return settlement.Workers:GetChildren()
end

function WorkerService:GenerateIdlePosition(settlement, slot)
    local name = settlement.Name

    local idlePositions = WorkerService.IdlePositions[name]

    local position = settlement:GetPivot()

    position = position * CFrame.new(idlePositions.pOffset[slot])
    local lookTowards = (position.Position - settlement:GetPivot().Position).Magnitude > 0.01 and CFrame.lookAt(position.Position, settlement:GetPivot().Position) or position
    position = CFrame.fromMatrix(position.Position, lookTowards.XVector, position.YVector, lookTowards.ZVector)
    position = position * CFrame.Angles(unpack(idlePositions.aOffset[slot] or {0,0,0}))

    return position
end

function WorkerService:SettlementCheckForTasks(settlement)
	
end

function WorkerService:WorkerCheckForTasks(worker)
	
end

function WorkerService:UpdateWorkers(settlement)
	local workercount = #self:GetWorkersOnSettlement(settlement)
	local settleLevel = settlement:GetAttribute("level")
	local difference = settleLevel - workercount

	for i = 1, difference do
		self:AddWorker(settlement, i + settleLevel - difference)
	end

	for _ = -1, difference, -1 do
		self:RemoveWorker(settlement)
	end
end

function WorkerService:AddWorker(settlement, slot)

    local idlePosition = self:GenerateIdlePosition(settlement, slot)
    local factionColor = self.FactionService:GetSettlementFactionColor(settlement)

	local worker = Worker.new(settlement.Workers, idlePosition, factionColor)
end

function WorkerService:KnitInit() end

function WorkerService:KnitStart()
    self.FactionService = Knit.GetService("FactionService")
	self.WorkedTileService = Knit.GetService("WorkedTileService")
end

return WorkerService
