local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local PathfindingService = Knit.CreateService({
    Name = "PathfindingService",
    -- Instance as a key, value as a table of connections which hold the instance it's connected to and the weight of the node
    Graph = {},
    Client = {}
})

function PathfindingService:SyncModelPart(object) : Part
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

function PathfindingService:KnitInit()
    self.WorkspaceService = Knit.GetService("WorkspaceService")
end

function PathfindingService:PlayerAdded(player: Player)
    local pWorkspace = self.WorkspaceService:getPlayerWorkspace(player)
    self.Graph[pWorkspace] = {}
end

function PathfindingService:AddNode(object, pWorkspace)

    local part: Part = self:SyncModelPart(object)

    if self.Graph[pWorkspace][part] then
        return
    end

    self.Graph[pWorkspace][part] = {}
    local connection = part.Touched:Connect(function() end)

    for _, touchingPart in pairs(part:GetTouchingParts()) do
        if self.Graph[pWorkspace][touchingPart] then
            local distance = (part.Position - touchingPart.Position).Magnitude
            self.Graph[pWorkspace][touchingPart][part] = distance
            self.Graph[pWorkspace][part][touchingPart] = distance
        end
    end

    connection:Disconnect()
end

function PathfindingService:UpdateNode(oldObject, newObject, pWorkspace)
    local newPart = self:SyncModelPart(newObject)
    local oldPart = self:SyncModelPart(oldObject)

    for index in pairs(self.Graph[pWorkspace][oldPart]) do
        self.Graph[pWorkspace][index][newPart] = self.Graph[pWorkspace][index][oldPart]
        self.Graph[pWorkspace][index][oldPart] = nil
    end

    self.Graph[pWorkspace][newPart] = self.Graph[pWorkspace][oldPart]
    self.Graph[pWorkspace][oldPart] = nil
end

function PathfindingService:RemoveNode(object, pWorkspace)

    local part: Part = self:SyncModelPart(object)

    for index in pairs(self.Graph[pWorkspace][part]) do
        self.Graph[pWorkspace][index][part] = nil
    end

    self.Graph[pWorkspace][part] = nil
end

function PathfindingService:PrintGraph()
    print(self.Graph)
end

function PathfindingService:FindPath()
end



return PathfindingService