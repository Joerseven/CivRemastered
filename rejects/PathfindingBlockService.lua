local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Tiles = require(ReplicatedStorage.Modules.Tiles)

local PathfindingBlockService = Knit.CreateService({
	Name = "PathfindingBlockService",
	Client = {},
})

function PathfindingBlockService:KnitInit()
	for _, c in pairs(ReplicatedStorage.Placeables:GetChildren()) do
		for _, v in pairs(c:GetChildren()) do
			local tileInfo = Tiles.Main[v.Name]

			if not tileInfo then
				warn("Can't find the tile information for:" .. v.Name)
				continue
			end

			if tileInfo.path then
				continue
			end

            -- local boundingPart = Instance.new("Part")

			local zone = Instance.new("PathfindingModifier")
			zone.Label = "NoGoZone"

			if v:IsA("Model") then
                for _, part in pairs(v:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "Entrance" then
                        zone:Clone().Parent = part
                    end
                end
                -- print("Test")

                -- local position, size = v:GetBoundingBox()
                -- boundingPart.Size = size
                -- boundingPart.Parent = v
                -- boundingPart.CanCollide = false
                -- boundingPart.Anchored = true
                -- boundingPart:PivotTo(position)
                -- boundingPart.Transparency = 1

				-- zone.Parent = boundingPart
			end

			if v:IsA("Part") then
				zone.Parent = v
			end
		end
	end
end

function PathfindingBlockService:KnitStart() end

return PathfindingBlockService
