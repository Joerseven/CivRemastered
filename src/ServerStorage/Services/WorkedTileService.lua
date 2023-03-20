local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Tiles = require(ReplicatedStorage.Modules.Tiles)
local SoundPlayer = require(ReplicatedStorage.Modules.SoundPlayer)
local tRemove = require(ReplicatedStorage.Util.tableUtil).removeIf

local WorkedTileService = Knit.CreateService({
	Name = "WorkedTileService",
	WorkTiles = {},
	Client = {},
})

function WorkedTileService:GetWorkedTiles(settlement)
	local ownerId = self.WorkspaceService:GetWorkspacePlayer(settlement.Parent)
	local newTable = {}

	if not self.WorkTiles[ownerId] then
		warn("Player must have left")
		return
	end

	for _, v in ipairs(self.WorkTiles[ownerId]) do
		if v:GetAttribute("claimee") == settlement:GetAttribute("name") then
			table.insert(newTable, v)
		end
	end
	return newTable
end

function WorkedTileService:Add(player, name, pWorkspace, position, attributes)
	local tile = ReplicatedStorage.Placeables.WorkTile[name]:Clone()
	tile:PivotTo(position)
	tile.Parent = pWorkspace

	if attributes then
		for k, v in pairs(attributes) do
			tile:SetAttribute(k, v)
		end
	end

	local ownerId = self.WorkspaceService:GetWorkspacePlayer(pWorkspace)

	table.insert(self.WorkTiles[ownerId], tile)
	self.PathfindingService:AddNode(tile, pWorkspace)
	tile.Destroying:Connect(function()
		self.PathfindingService:RemoveNode(tile, pWorkspace)
	end)

	return tile
end

function WorkedTileService:DataToInstance(data: table, pWorkspace: Model, deserialize)
	local name = Tiles.Main[data.Id].name
	local tilePosition = pWorkspace:GetPivot():ToWorldSpace(deserialize(data.CFrame, "CFrame"))
	return self:Add(false, name, pWorkspace, tilePosition, data.Attributes)
end

function WorkedTileService:InstanceToData(instance: Model, id: number, workspacePosition: CFrame, serialize)
	local itemData = {}
	itemData["Id"] = id
	itemData["CFrame"] = serialize(workspacePosition:ToObjectSpace(instance:GetPivot()))
	itemData["Attributes"] = instance:GetAttributes()
	return itemData
end

function WorkedTileService:ClaimTile(wTile, settlement)
	wTile:SetAttribute("claimee", settlement:GetAttribute("name"))
	self.SettlementService:UpdateClaimed(settlement)
end

function WorkedTileService:UnWork(tile)
	local newTileName, service = Tiles.unwork(tile)
	self[service]:Add(newTileName, tile.Parent, tile:GetPivot())
	self:RemoveTile(tile)
end

function WorkedTileService:WorkTile(player, tile, settlement, pivot)
	local pWorkspace = tile.Parent

	if not self:_CheckPermissions(player, pWorkspace) then
		warn("You don't have permission to change this tile.")
		return false
	end

	if not (#self:GetWorkedTiles(settlement) < math.floor(Tiles.Main[settlement.Name].capacity / 2) + 0.5) then
		warn("You've already claimed the maximum amount of tiles!")
		return false
	end

	local workTileName = Tiles.checkWork(tile)

	if not workTileName then
		warn("You can't work this tile")
	end

	local position = pivot

	tile:Destroy()

	local wTile = WorkedTileService:Add(player, workTileName, pWorkspace, position)

	self:ClaimTile(wTile, settlement)

	local tSettle = self.SettlementService:GetSettlementTable(settlement, player.UserId)
	SoundPlayer.playSound(SoundService.workSound, wTile)
	--tSettle.workers:SignalIdleWorkers()
end

function WorkedTileService:PlayerAdded(player)
	local id = player.UserId
	self.WorkTiles[id] = {}
end

function WorkedTileService:PlayerRemoving(player)
	local id = player.UserId
	self.WorkTiles[id] = nil
end

function WorkedTileService:GetClaimee(workedTile)
	local claimee = workedTile:GetAttribute("claimee")
	if not claimee or claimee == "" then
		return false
	end
	return claimee
end

function WorkedTileService:DeleteTile(player, tile)
	if not self:_CheckPermissions(player, tile.Parent) then
		warn("You don't have permission to delete")
		return false
	end

	if not Tiles.Main[tile.Name] then
		warn("You can't delete this")
	end

	self:_CreateExplosion(tile:GetPivot().Position)

	self:RemoveTile(tile)

	local claimee = self:GetClaimee(tile)

	if claimee then
		local claimeeTile = self.SettlementService:GetSettlementC(player.UserId, claimee)
		if claimeeTile then
			self.SettlementService:UpdateClaimed(claimeeTile)
		end
	end

	return true
end

function WorkedTileService:RemoveTile(tile)
	local ownerId = self.WorkspaceService:GetWorkspacePlayer(tile.Parent)

	tRemove(self.WorkTiles[ownerId], function(t, i)
		if t[i] == tile then
			return false
		end
		return true
	end)

	tile:Destroy()
end

function WorkedTileService:KnitInit() end

function WorkedTileService:KnitStart()
	setmetatable(self, Knit.GetService("TileService"))

	self.SettlementService = Knit.GetService("SettlementService")
	self.WorkspaceService = Knit.GetService("WorkspaceService")
	self.GrowTileService = Knit.GetService("GrowTileService")
	self.RaiseTileService = Knit.GetService("RaiseTileService")
	self.PathfindingService = Knit.GetService("PathfindingService")
end

function WorkedTileService.Client:WorkTile(...)
	return self.Server:WorkTile(...)
end

function WorkedTileService.Client:DeleteTile(...)
	return self.Server:DeleteTile(...)
end

return WorkedTileService
