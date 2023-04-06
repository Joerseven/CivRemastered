local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Tiles = require(ReplicatedStorage.Modules.Tiles)
local Promise = require(ReplicatedStorage.Packages.Promise)

local GrowTileService = Knit.CreateService({
	Name = "GrowTileService",
	Client = {},
})

function GrowTileService:KnitInit() end

function GrowTileService:_GetPosition(tile)
	return tile:GetPrimaryPartCFrame().Position
end

function GrowTileService:KnitStart()
	Knit.GetService("TileService").__index = Knit.GetService("TileService")
	setmetatable(GrowTileService, Knit.GetService("TileService"))
	self.TweenService = Knit.GetService("TweenService")
end

function GrowTileService:DataToInstance(data: table, pWorkspace: Model, deserialize)
	local name = Tiles.Main[data.Id].name
	local tilePosition = pWorkspace:GetPivot():ToWorldSpace(deserialize(data.CFrame, "CFrame"))--deserialize(data.CFrame, "CFrame"):ToWorldSpace(pWorkspace:GetPivot())
	return self:Add(name, pWorkspace, tilePosition)
end

function GrowTileService:InstanceToData(instance: Model, id: number, workspacePosition: CFrame, serialize)
	local itemData = {}
	itemData["Id"] = id
	itemData["CFrame"] = serialize(workspacePosition:ToObjectSpace(instance:GetPivot()))
	--itemData["Attributes"] = instance:GetAttributes()
	return itemData
end

function GrowTileService:Add(name, pWorkspace, position, beforeParent)
	local tile = ReplicatedStorage.Placeables.GrowTile[name]:Clone()

	assert(typeof(position) == "CFrame", "Position needs to be a CFrame")

	tile:PivotTo(position)

	if beforeParent then
		beforeParent(tile)
	end

	tile.Parent = pWorkspace
	return tile
end

function GrowTileService:GrowTile(player, base)
	local tileinfo = Tiles.Main[base.Name]

	if not self:_CheckPermissions(player, base.Parent) then
		return false
	end

	if not tileinfo or not tileinfo.grow then
		return false
	end

	base.Name = "Destroying"

	local tile = self:Add(tileinfo.grow, base.Parent, CFrame.new(base:GetPivot().Position), function(tile) end)

	local interruptedTween = tile.Destroying:Connect(function()
		if base then
			base:Destroy()
		end
	end)

	local duration = 2

	for _, v in pairs(base:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Transparency = 1
		end
	end

	task.delay(duration, function()
		for _, v in pairs(tile:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Transparency = 0
			end
		end
		interruptedTween:Disconnect()
		base:Destroy()
	end)

	return tile, duration
end

function GrowTileService.Client:GrowTile(...)
	return self.Server:GrowTile(...)
end

function GrowTileService.Client:DeleteTile(...)
	return self.Server:DeleteTile(...)
end

return GrowTileService
