local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local FactionService = Knit.CreateService({
	Name = "FactionService",
	Client = {},
	_FactionLists = {},
})

function FactionService:KnitInit()
	math.randomseed(os.time())
	math.random()
	math.random()
	math.random()
end

function FactionService:KnitStart()
	self.WorkspaceService = Knit.GetService("WorkspaceService")
end

function FactionService:_CreateFaction(id, name)
	self._FactionLists[id][name] = { Color3.fromHSV(math.random(), 0.5, 0.8) }
	return self._FactionLists[id][name]
end

function FactionService:GetFaction(player, name)
	return self:GetFactionFromId(player.UserId, name)
end

function FactionService:GetFactionFromId(playerId, name)
	if not self._FactionLists[playerId] then
		self._FactionLists[playerId] = {}
	end

	local faction = self._FactionLists[playerId][name]

	if not faction then
		return self:_CreateFaction(playerId, name)
	end

	return faction
end

function FactionService:GetFactionFromSettlement(settlement)
	local ownerId = self.WorkspaceService:GetWorkspacePlayer(settlement.Parent)
	return self:GetFactionFromId(ownerId, settlement:GetAttribute("faction"))
end

function FactionService:GetSettlementFactionColor(settlement)
	return self:GetFactionFromSettlement(settlement)[1]
end

return FactionService
