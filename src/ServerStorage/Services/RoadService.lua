local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local RoadService = Knit.CreateService({
	Name = "RoadService",
	Client = {},
})

local function RoadValidChecker(node: Part, connected: { Part: number })
	return true
end

function RoadService:KnitInit() end

function RoadService:KnitStart()
	self.PathfindingService = Knit.GetService("PathfindingService")
	self.WorkspaceService = Knit.GetService("WorkspaceService")
end

function RoadService:GetPointOnSpline(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number)
	local alpha = 0.5
	local tension = 0

	local t01 = (p1-p0).Magnitude ^ alpha
	local t12 = (p2-p1).Magnitude ^ alpha
	local t23 = (p3-p2).Magnitude ^ alpha

	local m1 = (1.0 - tension) * (p2 - p1 + t12 * ((p1 - p0) / t01 - (p2 - p0) / (t01 + t12)))
	local m2 = (1.0 - tension) * (p2 - p1 + t12 * ((p3 - p2) / t23 - (p3 - p1) / (t12 + t23)))

	local segment = {
		a = 2 * (p1 - p2) + m1 + m2,
		b = -3 * (p1 - p2) - m1 - m1 - m2,
		c = m1,
		d = p1
	}

	return segment.a * t * t * t + segment.b * t * t + segment.c * t + segment.d
end

function RoadService:CreateCorner(firstRoadStart, firstRoadEnd, secondRoadStart, secondRoadEnd)
	local thing = Instance.new("Model")
	-- self:CreateMarker(firstRoadStart.Position, Color3.new(1, 0, 0)).Parent = thing
	-- self:CreateMarker(firstRoadEnd.Position, Color3.new(0,1, 0)).Parent = thing
	-- self:CreateMarker(secondRoadStart.Position, Color3.new(0, 0, 1)).Parent = thing
	-- self:CreateMarker(secondRoadEnd.Position, Color3.new(1, 1, 0)).Parent = thing
	thing.Parent = workspace
	local sections = 10
	local corner = Instance.new("Model")
	corner.Name = "Corner"
	for i = 1, sections do
	    -- local t1 = i / sections
	    -- local point1 = segment.a * t1 * t1 * t1 + segment.b * t1 * t1 + segment.c * t1 + segment.d
	    -- local t2 = i+1 / sections
	    -- local point2 = segmebt.a * t2 * t2 * t2 + segment.b * t2 * t2 + segment.c * t2 + segment.d
		local t1 = i / sections
		local t2 = (i + 1) / sections
		local point1 = self:GetPointOnSpline(firstRoadStart.Position, firstRoadEnd.Position, secondRoadStart.Position, secondRoadEnd.Position, t1)
		local point2 = self:GetPointOnSpline(firstRoadStart.Position, firstRoadEnd.Position, secondRoadStart.Position, secondRoadEnd.Position, t2)
	    local cornerPart = Instance.new("Part")
	    cornerPart.Size = Vector3.new(0.5, 0.05, 0.1)
	    cornerPart:PivotTo(CFrame.new(point1, point2) + Vector3.new(0, 0.00001 * i, 0))
	    cornerPart.Anchored = true
	    cornerPart.CanCollide = false
	    cornerPart.Transparency = 0
	    cornerPart.Color = Color3.new(0.2, 0.2, 0.2)
	    cornerPart.Shape = Enum.PartType.Block
	    cornerPart.Parent = corner
		cornerPart.Material = Enum.Material.Basalt
		cornerPart.Name = "CornerPart"
	end
	return corner
end

-- Create markers on each point of the path
function RoadService:CreateMarker(position: Vector3, color: Color3)
	local marker = Instance.new("Part")
	marker.Size = Vector3.new(0.2,0.2,0.2)
	marker.Anchored = true
	marker.Position = position + Vector3.new(0,0.3,0)
	marker.CanCollide = false
	marker.Color = color
	marker.Shape = Enum.PartType.Ball
	return marker
end

function RoadService:CreateRoadPart(start: Vector3, destination: Vector3, cornerLength: number)
	local travelVector = destination - start
	local length = travelVector.Magnitude

	print("Length: " .. length)

	local roadPart = Instance.new("Part")
	roadPart.Size = Vector3.new(0.5, 0.05, length - cornerLength)
	roadPart:PivotTo(CFrame.new(start, destination) * CFrame.new(0, 0, -length / 2) + Vector3.new(0, 0.2, 0))
	local roadStart = roadPart.CFrame * CFrame.new(0, 0, (length - cornerLength) / 2)
	local roadEnd = roadPart.CFrame * CFrame.new(0, 0, (cornerLength - length) / 2)
	roadPart.Anchored = true
	roadPart.CanCollide = false
	roadPart.Transparency = 0
	roadPart.Color = Color3.new(0.2, 0.2, 0.2)
	roadPart.Shape = Enum.PartType.Block
	roadPart.Material = Enum.Material.Basalt
	return roadPart, roadStart, roadEnd
end

function RoadService:CreateRoad(entranceTile, exitTile, pWorkspace)
	local path = self.PathfindingService:GetPath(entranceTile, exitTile, pWorkspace)

	if not path then
		print("Can't find a path!")
		return nil
	end

	local road = Instance.new("Model")

	local previousRoadPosition = nil

	for i = 1, #path - 1 do
		local start = path[i]
		local destination = path[i + 1]

		local startPosition = start.Position + Vector3.new(0, 0.2, 0)
		local destinationPosition = destination.Position + Vector3.new(0, 0.2, 0)

		local roadPart, roadStart, roadEnd = self:CreateRoadPart(startPosition, destinationPosition, 0.4)
		if previousRoadPosition then
			local p0 = previousRoadPosition.start
			local p1 = previousRoadPosition.finish
			local p2 = roadStart
			local p3 = roadEnd
			-- local p0 = startPosition
			-- local p1 = (previousRoadPosition:GetPivot() * CFrame.new(0, 0, -previousRoadPosition.Size.Z / 2)).Position
			-- local p2 = destinationPosition
			-- local p3 = (roadPart:GetPivot() * CFrame.new(0, 0, roadPart.Size.Z / 2)).Position
			self:CreateCorner(p0, p1, p2, p3).Parent = road
		end
		roadPart.Parent = road
		previousRoadPosition = { start = roadStart, finish = roadEnd }
	end

	road.Parent = pWorkspace
end

return RoadService
