local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TextService = game:GetService("TextService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Tiles = require(ReplicatedStorage.Modules.Tiles)
local Component = require(ReplicatedStorage.Packages.Component)
local Maid = require(ReplicatedStorage.Packages.Maid)
local WorkerManager = require(ServerStorage.Components.WorkerManager)

local tableremove = require(ReplicatedStorage.Util.tableUtil).arrayRemove

local playerError -- Initialized in Knit Start

local SettlementService = Knit.CreateService({
	Name = "SettlementService",
	Settlements = {},
	HeartbeatCounter = 0,
	WorkerTable = {},
	Client = {
		AddWorkerButton = Knit.CreateSignal(),
		RemoveWorkerButton = Knit.CreateSignal(),
		AddSettlementBillboard = Knit.CreateSignal(),
		UpdateWorkers = Knit.CreateSignal(),
	},
})

local Settlement = {}
Settlement.__index = Settlement

function SettlementService:KnitInit() end

function SettlementService:LevelToXP(level)
	return level * 80
end

function SettlementService:GetOwnerId(tile)
	local ownerId = self.WorkspaceService:GetWorkspacePlayer(tile.Parent)
	return ownerId
end

function SettlementService:KnitStart()
	self.WorkspaceService = Knit.GetService("WorkspaceService")
	self.FactionService = Knit.GetService("FactionService")
	self.WorkedTileService = Knit.GetService("WorkedTileService")
	self.WorkerService = Knit.GetService("WorkerService")
	playerError = function(player, error)
		Knit.GetService("ErrorService"):ErrorPopup(player, error)
	end
	setmetatable(self, Knit.GetService("TileService"))
end

function SettlementService:ValidateNames(player, sText, fText)
	local sTextObject, fTextObject
	do
		local sucess, errorMsg = pcall(function()
			sTextObject = TextService:FilterStringAsync(sText, player.UserId)
			fTextObject = TextService:FilterStringAsync(fText, player.UserId)
		end)

		if not sucess then
			warn(errorMsg)
			return false
		end
	end

	local sFiltered, fFiltered
	do
		local sucess, errorMsg = pcall(function()
			sFiltered = sTextObject:GetNonChatStringForBroadcastAsync()
			fFiltered = fTextObject:GetNonChatStringForBroadcastAsync()
		end)

		if not sucess or sFiltered:find("#") or fFiltered:find("#") then
			warn(errorMsg or "Text contains unsuitable words")
			return false
		end
	end

	return { name = sFiltered, faction = fFiltered }
end

function SettlementService:DataToInstance(data: table, pWorkspace: Model, deserialize: (data:any, typ:string) -> any)
	local name = Tiles.Main[data.Id].name
	local tilePosition = pWorkspace:GetPivot():ToWorldSpace(deserialize(data.CFrame, "CFrame"))

	local basetile = ReplicatedStorage.Placeables.Tile[Tiles.Main[data.BaseTile.Id].name]:Clone()
	basetile:PivotTo(pWorkspace:GetPivot():ToWorldSpace(deserialize(data.BaseTile.CFrame, "CFrame")))
	basetile:SetAttribute("name", Tiles.Main[data.BaseTile.Id].name)

	local player = self.WorkspaceService._workspaceToPlayer[pWorkspace]

	return self:Add(tilePosition, pWorkspace, basetile, Tiles.Main[data.Id].capacity, data.Attributes, player.UserId, player)
end

function SettlementService:InstanceToData(instance, id: number, workspacePosition: CFrame, serialize)
	local itemData = {}
	itemData["Id"] = id
	itemData["CFrame"] = serialize(workspacePosition:ToObjectSpace(instance:GetPivot()))
	itemData["Attributes"] = instance:GetAttributes()
	itemData["BaseTile"] = {
		Id = Tiles.GetId(instance.BaseTile:GetAttribute("name")),
		CFrame = serialize(workspacePosition:ToObjectSpace(instance.BaseTile:GetPivot()))
	}
	return itemData
end

function SettlementService:CreateBillboard(parent: Model)
	local player = Players:GetPlayerByUserId(self.WorkspaceService:GetWorkspacePlayer(parent.Parent))
	local factionColor = self.FactionService:GetFaction(player, assert(parent:GetAttribute("faction")))[1]
	self.Client.AddSettlementBillboard:FireAll(parent, factionColor)
end

function SettlementService:UpdateAll(player)
	for _, v in pairs(self.Settlements[player.UserId]) do
		self:UpdateClaimed(v.tile)
		-- local claimed = self.WorkedTileService:GetWorkedTiles(v.tile)

		-- if #claimed < math.floor((Tiles.Main[v.tile.Name].capacity + 1) / 2) then
		-- 	self.Client.AddWorkerButton:FireAll(v.tile)
		-- else
		-- 	self.Client.RemoveWorkerButton:FireAll(v.tile)
		-- end

		-- v.workers:SignalIdleWorkers()
	end
end

function SettlementService:UpdateClaimed(settlement)
	local claimed = self.WorkedTileService:GetWorkedTiles(settlement)
	local owner = Players:GetPlayerByUserId(self.WorkspaceService:GetWorkspacePlayer(settlement.Parent))

	if #claimed < math.floor((Tiles.Main[settlement.Name].capacity + 1) / 2) then
		self.Client.AddWorkerButton:FireAll(settlement)
	else
		self.Client.RemoveWorkerButton:FireAll(settlement)
	end

	local settleobject

	for _, v in pairs(self.Settlements[self.WorkspaceService:GetWorkspacePlayer(settlement.Parent)]) do
		if settlement == v.tile then
			settleobject = v
			break
		end
	end

	settleobject.workers:SignalIdleWorkers()
end

function SettlementService:Exists(pWorkspace, name)
	error("Depreciated Function")
	if self.Settlements[name] then
		return true
	end

	return false
end

function SettlementService:LevelUp(s, pWorkspace)
	local base = s.tile.BaseTile
	local workers = s.tile.Workers

	s.tile.BaseTile.Parent = nil
	s.tile.Workers.Parent = nil

	local attributes = s.tile:GetAttributes()
	local position = s.tile:GetPivot()
	local newLevel = Tiles.Main[s.tile.Name].capacity + 1

	s.tile:Destroy()

	local tileName = "SettlementLV" .. newLevel

	s.tile = ReplicatedStorage.Placeables.Settlement[tileName]:Clone()
	s.tile:PivotTo(position)

	base.Parent = s.tile

	for k, v in pairs(attributes) do
		s.tile:SetAttribute(k, v)
	end

	for _, v in workers:GetChildren() do
		v.Parent = s.tile.Workers
	end

	s.tile.Parent = pWorkspace

	local listener
	listener = s.tile:GetAttributeChangedSignal("supplyCount"):Connect(function()
		local rXp = Tiles.Main[tileName].xpNext

		if not rXp then
			return
		end

		if s.tile:GetAttribute("supplyCount") >= rXp then
			listener:Disconnect()
			self:LevelUp(s, pWorkspace)
		end
	end)

	self:CreateBillboard(s.tile)
	self:UpdateClaimed(s.tile)
	s.workers:UpdateWorkers()

	-- local attributes = settlement:GetAttributes()
	-- local position = settlement:GetPivot()
	-- local pWorkspace = settlement.Parent

	-- local baseTile = settlement.BaseTile
	-- baseTile.Parent = pWorkspace.Ignore

	-- local nSettlement = self:Add(position, pWorkspace, baseTile, settlement:GetAttribute("level") + 1, attributes)

	-- self:UpdateClaimed(nSettlement)
end

function SettlementService:AddSupplies() end

function SettlementService:Add(position, pWorkspace, basetile, level, attributes, workspacePlayerId, player)
	local s = {}
	setmetatable(s, Settlement)

	local tileName = "SettlementLV" .. level

	s.maid = Maid.new()

	s.tile = ReplicatedStorage.Placeables.Settlement[tileName]:Clone()
	s.tile:PivotTo(position)

	for k, v in pairs(attributes) do
		s.tile:SetAttribute(k, v)
	end

	if basetile:FindFirstChild("SelectionBox") then
		basetile.SelectionBox:Destroy()
	end

	s.tile.SelectionBox.Adornee = s.tile
	basetile:SetAttribute("name", basetile.Name)
	basetile.Name = "BaseTile"
	basetile.Parent = s.tile

	s.tile.Parent = pWorkspace

	s.workers = WorkerManager.new(s, self.FactionService:GetSettlementFactionColor(s.tile), function()
		return self.WorkedTileService:GetWorkedTiles(s.tile)
	end,
	function(error)
		playerError(player, error)
	end,
	s.maid)

	local listener
	listener = s.tile:GetAttributeChangedSignal("supplyCount"):Connect(function()
		local rXp = Tiles.Main[tileName].xpNext

		if not rXp then
			return
		end

		if s.tile:GetAttribute("supplyCount") >= rXp then
			listener:Disconnect()
			self:LevelUp(s, pWorkspace)
		end
	end)

	if not self.Settlements[workspacePlayerId] then
		self.Settlements[workspacePlayerId] = {}
	end

	self.Settlements[workspacePlayerId][s.tile:GetAttribute("name")] = s
	self:CreateBillboard(s.tile)

	s.workers:UpdateWorkers()
end

function SettlementService:CreateExistingSettlementBillboards(userid)
	for _, v in self.Settlements[userid] do
		self:CreateBillboard(v.tile)
	end
end

function SettlementService:PlayerAdded(player)
	for playerid in pairs(self.Settlements) do
		self:CreateExistingSettlementBillboards(playerid)
	end
	self.Settlements[player.UserId] = {}
end

function SettlementService:PlayerRemoving(player)
	local wslot = self.WorkspaceService:GetSlotFromPlayerId(player.UserId)
	for _, settlement in pairs(self.Settlements[player.UserId]) do
		settlement.workers:RemovePlayerTable(self.WorkerTable, "w" .. wslot .. settlement.tile:GetAttribute("name") .. player.UserId)
	end
	self.Settlements[player.UserId] = nil
end

function SettlementService:GetSettlement(playerId, name)
	return self.Settlements[playerId][name].tile
end

function SettlementService:GetSettlementC(playerId, name)
	local settlement = self.Settlements[playerId][name]

	if settlement then
		return self:GetSettlement(playerId, name)
	end

	return false
end

function SettlementService:GetSettlementTable(settlement, playerId)
	if not playerId then
		error("Hasn't been implemented without id")
	end

	for _, v in pairs(self.Settlements[playerId]) do
		if v.tile == settlement then
			return v
		end
	end
end

function SettlementService:PlaceSettlement(player, position, pWorkspace, basetile, name, faction)
	if not self:_CheckPermissions(player, pWorkspace) then
		playerError(player, "You don't have permission for this!")
		return false
	end

	local workspacePlayerId = self.WorkspaceService:GetWorkspacePlayer(pWorkspace)

	if not basetile or not Tiles.checkSettle(basetile.Name) then
		error("Could not create settlement, base tile doesn't exist.")
		return
	end

	local attributes = { name = name, faction = faction }

	if not self.Settlements[workspacePlayerId] then
		self.Settlements[workspacePlayerId] = {}
	end

	if self.Settlements[workspacePlayerId][attributes.name] then
		playerError(player, "Already a settlement exists with this name.")
		return
	end

	self:Add(position, pWorkspace, basetile, 1, attributes, workspacePlayerId, player)
end

function SettlementService:DeleteSettleFromWorkerTable(settleid)
	self.WorkerTable[settleid] = nil
end

function SettlementService:DeleteTile(player, tile)
	if not self:_CheckPermissions(player, tile.Parent) then
		playerError(player, "You don't have permission to delete")
		return false
	end

	game:GetService("Players")

	if not Tiles.Main[tile.Name] then
		warn("You can't delete this")
	end

	local name = tile:GetAttribute("name")

	local workedTiles = self.WorkedTileService:GetWorkedTiles(tile)

	for _, v in pairs(workedTiles) do
		self.WorkedTileService:UnWork(v)
	end

	local settlePlayer = self.WorkspaceService:GetWorkspacePlayer(tile.Parent)

	local settleTable = self:GetSettlementTable(tile, settlePlayer)

	settleTable.maid:DoCleaning()

	settleTable.workers:Kill()

	--settleTable.workers:UpdateTable(self.WorkerTable, tile:GetAttribute("name") .. player.UserId)
	local wslot = self.WorkspaceService:GetSlotFromPlayerId(settlePlayer)
	self:DeleteSettleFromWorkerTable("w" .. wslot .. tile:GetAttribute("name") .. settlePlayer)

	local ownerId = self.WorkspaceService:GetWorkspacePlayer(tile.Parent)
	self.Settlements[ownerId][name] = nil

	self:_CreateExplosion(tile:GetPivot().Position)

	tile:Destroy()

	return true
end

function SettlementService:Stepped(delta)
	self.HeartbeatCounter = (self.HeartbeatCounter + 1) % 10

	local createTable = false

	if self.HeartbeatCounter == 0 then
		createTable = true
	end

	for vi, v in self.Settlements do
		for _, s in v do
			s.workers:Stepped(delta)
			if createTable then
				local wslot = self.WorkspaceService:GetSlotFromPlayerId(vi)
				s.workers:UpdateTable(self.WorkerTable, "w" .. wslot .. s.tile:GetAttribute("name") .. vi)
			end
		end
	end

	if createTable then
		self.Client.UpdateWorkers:FireAll(self.WorkerTable)
	end
end

function SettlementService.Client:DeleteTile(...)
	return self.Server:DeleteTile(...)
end

function SettlementService.Client:ValidateNames(...)
	return self.Server:ValidateNames(...)
end

function SettlementService.Client:Exists(...)
	return self.Server:Exists(...)
end

function SettlementService.Client:PlaceSettlement(...)
	return self.Server:PlaceSettlement(...)
end

return SettlementService
