local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local SoundPlayer = require(ReplicatedStorage.Modules.SoundPlayer)
local Tiles = require(ReplicatedStorage.Modules.Tiles)

local TileService = Knit.CreateService({
	Name = "TileService",
	_offsetTracker = 1,
	_addition = 0,
	Client = {
		placeTile = Knit.CreateSignal(),
		deleteTile = Knit.CreateSignal(),
	},
})

TileService.__index = TileService

function TileService:_GetPosition(tile) : string
	return tile:GetPivot().Position
end

function TileService:_CheckPermissions(player, pWorkspace)
	return self.PermissionService:GetWorkspacePermissions(player, pWorkspace)
end

function TileService:_NextAddition()
	self._addition += 0.00015
	if self._addition > 0.009 then
		self._addition = 0
	end
	return self._addition
end

function TileService:_incrementOffset()
	self._offsetTracker = (self._offsetTracker + 1) % 100
end

function TileService:_CreateExplosion(position)
	local explosionParent = Instance.new("Part")
	explosionParent.Position = position
	explosionParent.Size = Vector3.new(0.1,0.1,0.1)
	explosionParent.Anchored = true
	explosionParent.CanCollide = false
	explosionParent.CanQuery = false
	explosionParent.Transparency = 1

	explosionParent.Parent = workspace
	local explosion = Instance.new("Explosion")
	explosion.Parent = explosionParent
	explosion.DestroyJointRadiusPercent = 0
	explosion.Position = position

	SoundPlayer.playSound(SoundService.explosionSound, explosionParent, false):andThenCall(function()
		explosionParent:Destroy()
	end)
end

function TileService:KnitInit()

	self.Client.placeTile:Connect(function(p1, w, t, p2)
		self:PlaceTile(p1, w, t, p2)
	end)

	self.WorkspaceService = Knit.GetService("WorkspaceService")
end

function TileService:KnitStart()
	self.PermissionService = Knit.GetService("PermissionService")
	self.PathfindingService = Knit.GetService("PathfindingService")
end

function TileService:DataToInstance(data: table, pWorkspace: Model, deserialize)
	local name = Tiles.Main[data.Id].name
	local tilePosition = pWorkspace:GetPivot():ToWorldSpace(deserialize(data.CFrame, "CFrame"))--deserialize(data.CFrame, "CFrame"):ToWorldSpace(pWorkspace:GetPivot())
	return self:Add(name, pWorkspace, tilePosition.Position)
end

function TileService:InstanceToData(instance: Model, id: number, workspacePosition: CFrame, serialize)
	local itemData = {}
	itemData["Id"] = id
	itemData["CFrame"] =  serialize(workspacePosition:ToObjectSpace(instance:GetPivot()))
	--itemData["Attributes"] = instance:GetAttributes()
	return itemData
end

function TileService:Add(name: string, pWorkspace, position: Vector3, _)
	local tile = ReplicatedStorage.Placeables.Tile[name]:Clone()
	tile.Position = position
	tile.Parent = pWorkspace
	self.PathfindingService:AddNode(tile, pWorkspace)
	tile.Destroying:Connect(function()
		self.PathfindingService:RemoveNode(tile, pWorkspace)
	end)
	return tile
end

function TileService:PlaceTile(player: Player, pWorkspace, tileName: string, position: Vector3)
	if not self:_CheckPermissions(player, pWorkspace) then
		return false
	end

	if not (self.WorkspaceService:IsPositionInWorkspace(position) == pWorkspace) then
		return false
	end

	local addition = TileService:_NextAddition()

	local tile = self:Add(tileName, pWorkspace, position + Vector3.new(0, addition, 0))

	SoundPlayer.playSound(SoundService.placeGrass, tile, false)

	return true
end

function TileService:DeleteTile(player, tile, finsert)
	if not self:_CheckPermissions(player, tile.Parent) then
		warn("You don't have permission to delete")
		return false
	end

	if not Tiles.Main[tile.Name] then
		warn("This is not deleteable")
		return false
	end

	if finsert then
		finsert()
	end

	self:_CreateExplosion(self:_GetPosition(tile))

	tile:Destroy()

	return true
end

function TileService.Client:PlaceTile(player, pWorkspace, tileName, position)
	return self.Server:PlaceTile(player, pWorkspace, tileName, position)
end

function TileService.Client:DeleteTile(player, tile)
	return self.Server:DeleteTile(player, tile)
end

return TileService
