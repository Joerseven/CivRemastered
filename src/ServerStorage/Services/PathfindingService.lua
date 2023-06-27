local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

type Node = { [PVInstance] : number }
type Graph = { [Instance]: { Node }}

type IslandList = {[number]: { PVInstance }}
type IslandPointers = {[PVInstance]: number}

local PathfindingService = Knit.CreateService({
	Name = "PathfindingService",
	-- Instance as a key, value as a table of connections which hold the instance it's connected to and the weight of the node
	Graph = {},
	Client = {},
	Islands = {},
	TileToIsland = {},
})

local function reverseTable(t: { any }): { any }
    local newTable = {}

    for i = #t, 1, -1 do
        table.insert(newTable, t[i])
    end

    return newTable
end

function PathfindingService:GetPositionAsVector2(part: Part): Vector2
	return Vector2.new(part.Position.X, part.Position.Y)
end

function PathfindingService:PointInSquare(point: Vector2, square: Part)
	local x = point.X
	local y = point.Y

	local x1 = square.Position.X - square.Size.X / 2
	local x2 = square.Position.X + square.Size.X / 2
	local y1 = square.Position.Y - square.Size.Y / 2
	local y2 = square.Position.Y + square.Size.Y / 2

	return x >= x1 and x <= x2 and y >= y1 and y <= y2
end

function PathfindingService:CreatePathMarkers(points, pWorkspace)
	local path = Instance.new("Model", pWorkspace)
	path.Name = "Path"

	for _, point in pairs(points) do
		local marker = Instance.new("Part", path)
		marker.Name = "Marker"
		marker.Size = Vector3.new(1, 1, 1)
		marker.Position = point.Position + Vector3.new(0, 0.5, 0)
		marker.Anchored = true
		marker.CanCollide = false
		marker.Transparency = 0.5
		marker.Color = Color3.fromRGB(0, 255, 0)
        marker.Shape = Enum.PartType.Ball
	end
end

function PathfindingService:SyncModelPart(object): Part
	local part: Part = nil

	if object:IsA("Model") then
		part = object.PrimaryPart
	elseif object:IsA("Part") then
		part = object
	else
		error("Object is not a model or part")
	end

	return part
end

function PathfindingService:GetClosestNode(point: Vector2, pWorkspace)
	local closestNode = nil

	for part in pairs(self.Graph[pWorkspace]) do
		local distance = (point - Vector2.new(part.Position.X, part.Position.Z)).Magnitude
		if distance < 3 and (not closestNode or distance < closestNode.distance) then
			closestNode = {
				distance = distance,
				part = part,
			}
		end
	end

	if closestNode then
		return closestNode.part
	end

	return nil
end

function PathfindingService:KnitInit()
	self.WorkspaceService = Knit.GetService("WorkspaceService")
end

function PathfindingService:PlayerAdded(player: Player)
	local pWorkspace = self.WorkspaceService:getPlayerWorkspace(player)
	self.Graph[pWorkspace] = {}
	self.IslandToTile[pWorkspace] = {}
	self.TileToIsland[pWorkspace] = {}
	-- task.delay(10, function()
	-- 	self:CreateMarkersOverGraph()
	-- end)
end

function PathfindingService:PlayerRemoving(player: Player)
	local pWorkspace = self.WorkspaceService:getPlayerWorkspace(player)
	self.Graph[pWorkspace] = nil
	self.IslandToTile[pWorkspace] = nil
	self.TileToIsland[pWorkspace] = nil
end

function PathfindingService:CreateMarkersOverGraph()
	for _, graph in pairs(self.Graph) do
		for part in pairs(graph) do
			local marker = Instance.new("Part", part.Parent)
			marker.Name = "Marker"
			marker.Size = Vector3.new(1, 1, 1)
			marker.Position = part:GetPivot().Position + Vector3.new(0, 0.5, 0)
			marker.Anchored = true
			marker.CanCollide = false
			marker.Transparency = 0.5
			marker.Color = Color3.fromRGB(0, 255, 0)
		end
	end
end

function PathfindingService:AddNode(object: PVInstance, pWorkspace)

	local graph: Graph = self.Graph[pWorkspace]

	if graph[object] then
		warn("This is already a node!")
		return
	end

	graph[object] = {}

	local basePart: Part = object

	if object:IsA("Model") then
		basePart = object.PrimaryPart
	end

	local connection = basePart.Touched:Connect(function() end)

	local touchingParts = basePart:GetTouchingParts()

	local islands: IslandList = self.Islands[pWorkspace]
	local tileToIslands: IslandPointers = self.TileToIsland[pWorkspace]

	local currentIsland = nil

	if #touchingParts == 0 then
		local islandNumber = #islands + 1
		islands[islandNumber] = { object }
		tileToIslands[object] = islandNumber
	else
		currentIsland = tileToIslands[touchingParts[1]]
		table.insert(islands[currentIsland], object)
	end

	for _, touchingPart in pairs(touchingParts) do

		local objectToCheck = false

		if graph[touchingPart] then
			objectToCheck = touchingPart
		elseif graph[touchingPart.Parent] then
			objectToCheck = touchingPart.Parent
		else
			continue
		end

		local distance = (basePart.Position - touchingPart.Position).Magnitude
		graph[object][objectToCheck] = distance
		graph[objectToCheck][object] = distance

		if tileToIslands[touchingPart] ~= currentIsland then
			local islandToMerge = tileToIslands[touchingPart]
			for _, part in pairs(islands[islandToMerge]) do
				tileToIslands[part] = currentIsland
				table.insert(islands[currentIsland], part)
			end
			islands[islandToMerge] = nil
		end
	end

	connection:Disconnect()
end

function PathfindingService:RemoveNode(object, pWorkspace)
	if not self.Graph[pWorkspace][object] then
		warn("Trying to delete a node that isn't there")
		return
	end

	for index in pairs(self.Graph[pWorkspace][object]) do
		self.Graph[pWorkspace][index][object] = nil
	end

	self.Graph[pWorkspace][object] = nil
end

function PathfindingService:UpdateNode(oldObject, newObject, pWorkspace)

	for index in pairs(self.Graph[pWorkspace][oldObject]) do
		self.Graph[pWorkspace][index][newObject] = self.Graph[pWorkspace][index][oldObject]
		self.Graph[pWorkspace][index][oldObject] = nil
	end

	self.Graph[pWorkspace][newObject] = self.Graph[pWorkspace][oldObject]
	self.Graph[pWorkspace][oldObject] = nil
end


function PathfindingService:PrintGraph()
	print(self.Graph)
end

function PathfindingService:GetPath(startNode, endNode, pWorkspace, validChecker)

	if not startNode or not endNode then
		print("No tiles connected to the start points!")
		return nil
	end

	if not self.Graph[pWorkspace][endNode] then
		print("End node is not in the graph!")
		return nil
	end

	local goal = Vector2.new(endNode:GetPivot().Position.X, endNode:GetPivot().Position.Z)

	local openSet = { startNode }
	local finished = {}
	local cameFrom = {}

	local gScore = {}
	local fScore = {}

	gScore[startNode] = 0
	fScore[startNode] = 0

	while #openSet > 0 do
		local currentNode = openSet[1]
		local currentIndex = 1

		for index, node in pairs(openSet) do
			if fScore[node] < fScore[currentNode] then
				currentNode = node
				currentIndex = index
			end
		end

		if currentNode == endNode then
			local path = {}
			local current = currentNode
			while current do
				table.insert(path, current)
				current = cameFrom[current]
			end
			return reverseTable(path)
		end

		table.remove(openSet, currentIndex)
		table.insert(finished, currentNode)

		for node, distance: number in self.Graph[pWorkspace][currentNode] do

			if validChecker and not validChecker(node) then
				continue
			end

			local isFinished = false

			for _, finishedNode in pairs(finished) do
				if finishedNode == node then
					isFinished = true
					break
				end
			end

			if isFinished then
				continue
			end

			local currentPosition = Vector2.new(node.Position.X, node.Position.Z)
			local tentativeGScore = gScore[currentNode] + distance
			local isInOpen = false

			for _, openNode in pairs(openSet) do
				if openNode == node then
					isInOpen = true
					break
				end
			end

			if not isInOpen or tentativeGScore < gScore[node] then
				cameFrom[node] = currentNode
				gScore[node] = tentativeGScore
				fScore[node] = tentativeGScore + (currentPosition - goal).Magnitude

				if not isInOpen then
					table.insert(openSet, node)
				end
			end
		end
	end

    return nil
end

return PathfindingService
