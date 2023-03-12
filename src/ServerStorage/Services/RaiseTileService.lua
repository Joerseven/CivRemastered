local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Tiles = require(ReplicatedStorage.Modules.Tiles)

local RaiseTileService = Knit.CreateService({
	Name = "RaiseTileService",
	Client = {},
})

function RaiseTileService:KnitInit() end

function RaiseTileService:_GetPosition(tile)
	if tile:IsA("Model") then
		return tile:GetPrimaryPartCFrame().Position
	end

	return tile.Position
end

function RaiseTileService:KnitStart()
	setmetatable(RaiseTileService, Knit.GetService("TileService"))
end

function RaiseTileService:DataToInstance(data: table, pWorkspace: Model, deserialize)
	local name = Tiles.Main[data.Id].name
	local tilePosition = pWorkspace:GetPivot():ToWorldSpace(deserialize(data.CFrame, "CFrame"))--deserialize(data.CFrame, "CFrame"):ToWorldSpace(pWorkspace:GetPivot())
	return self:Add(name, pWorkspace, tilePosition)
end

function RaiseTileService:InstanceToData(instance: Model, id: number, workspacePosition: CFrame, serialize)
	local itemData = {}
	itemData["Id"] = id
	itemData["CFrame"] = serialize(workspacePosition:ToObjectSpace(instance:GetPivot()))
	--itemData["Attributes"] = instance:GetAttributes()
	return itemData
end

function RaiseTileService:Add(name, pWorkspace, position, beforeParent)
	local tile = ReplicatedStorage.Placeables.RaiseTile[name]:Clone()

	assert(typeof(position) == "CFrame", "Position needs to be a CFrame")

	tile:PivotTo(position)

	if beforeParent then
		beforeParent(tile)
	end

	tile.Parent = pWorkspace
	return tile
end

function RaiseTileService:RaiseTile(player, base)
	local tileinfo = Tiles.Main[base.Name]

	if not self:_CheckPermissions(player, base.Parent) then
		warn("You don't have permission for this tile")
		return false	
	end

	if false then
		return
	end

	if not tileinfo or not tileinfo.raise then
		return false
	end

	base.Name = "Destroying"

	local tile = self:Add(tileinfo.raise, base.Parent, CFrame.new(self:_GetPosition(base)))

	-- If the tween is interrupted the base should be destroyed.
	-- if the tween finishes this event is disconnected.
	local interruptedTween = tile.Destroying:Connect(function()
		if base then
			base:Destroy()
		end
	end)

	local duration = 2

    local name = tile.Name
    tile.Name = "Rising"

	task.delay(duration, function()
		interruptedTween:Disconnect()
		base:Destroy()
        tile.Name = name
	end)

	return tile, base, duration
end

function RaiseTileService.Client:RaiseTile(...)
	return self.Server:RaiseTile(...)
end

function RaiseTileService.Client:DeleteTile(...)
	return self.Server:DeleteTile(...)
end

return RaiseTileService
