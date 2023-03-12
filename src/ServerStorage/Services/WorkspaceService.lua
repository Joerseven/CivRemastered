local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local Set = require(ReplicatedStorage.Util.tableUtil).Set
local Promise = require(ReplicatedStorage.Packages.Promise)

fakePlayer = { UserId = 2099999 }

local WorkspaceService = Knit.CreateService({
	Name = "WorkspaceService",
	_playerSpaces = {},
	_workspaces = {},
	_playerWorkspace = {},
	_workspaceToPlayer = {},
	_modelToSlot = {},
	Client = {
		WorkspaceClaimed = Knit.CreateSignal(),
		PlayerWorkspace = Knit.CreateProperty(),
	},
})


local function scaleModel(model: Model, scale: number)
	local primaryCf = model:GetPivot()
	local primary = model.PrimaryPart

	for _, v: BasePart in pairs(model:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Position = primaryCf.Position:Lerp(v.Position,scale)
			v.Size *= scale
		end
	end

	return model
end

function WorkspaceService:PlaceDecoration()
	local numberOfMountainsLong = 50
	local numberOfMountainsAcross = 30
	for i=1, 3 do -- Three sets as there are two baseplates wide.
		for k=1, numberOfMountainsLong do
			local mountain = ReplicatedStorage.Scenary.Mountain:Clone()
			scaleModel(mountain, 25 + math.random(15))

			local x: number = (i-1)*800 - 400 + math.random(-30, 30)
			local y: number = -10
			local z: number = k/numberOfMountainsLong * 2430 - 400 + math.random(-10, 10)

			mountain:PivotTo(CFrame.new(x,y,z)) -- 400 offset half of baseplate width
			mountain.Parent = workspace
		end
	end

	for i=1, 4 do
		for k=1, numberOfMountainsAcross do
			local mountain = ReplicatedStorage.Scenary.Mountain:Clone()
			scaleModel(mountain, 25 + math.random(15))
			
			local x = k/numberOfMountainsAcross * 1600 - 400 + math.random(-10,10)
			local y = -10
			local z = (i-1)*800 - 400 + math.random(-30, 30)

			mountain:PivotTo(CFrame.new(x,y,z)) -- 400 offset half of baseplate width
			mountain.Parent = workspace
		end
	end
end

function WorkspaceService:CheckPermissions(player, workspace)
	if self:getPlayerWorkspace(player) == workspace then
		return true
	end

	return false
end

function WorkspaceService:_createWorkspacePrefab()
	local pWorkspace = Instance.new("Model")

	local baseplate = Instance.new("Part")
	baseplate.Color = Color3.fromRGB(13, 105, 172)
	baseplate.Material = Enum.Material.Foil
	baseplate.Size = Vector3.new(800, 1, 800)
	baseplate.Position = Vector3.zero
	baseplate.Name = "Baseplate"
	baseplate.Anchored = true
	baseplate.Parent = pWorkspace

	-- Why the fuck did I write this weird loop.
	-- Getting rid of walls
	-- for i = 1, 4 do
	-- 	local wall = Instance.new("Part")
	-- 	wall.Transparency = 1
	-- 	wall.Anchored = true
	-- 	wall.Position = Vector3.new(0, 50, 0)
	-- 	wall.Size = Vector3.new(0, 100, 0)

	-- 	if math.ceil(i / 2) == 1 then
	-- 		wall.Size = wall.Size + Vector3.new(810, 0, 5)
	-- 		wall.Position = wall.Position + Vector3.new(0, 0, 400)
	-- 	else
	-- 		wall.Size = wall.Size + Vector3.new(5, 0, 810)
	-- 		wall.Position = wall.Position + Vector3.new(400, 0, 0)
	-- 	end

	-- 	if i % 2 == 0 then
	-- 		wall.Position = Vector3.new(wall.Position.X * -1, wall.Position.Y, wall.Position.Z * -1)
	-- 	end

	-- 	wall.Name = "wall" .. i
	-- 	wall.Parent = pWorkspace
	-- end

	local spawnpoint = Instance.new("SpawnLocation")

	spawnpoint.CanCollide = false
	spawnpoint.CanTouch = false
	spawnpoint.Transparency = 1
	spawnpoint.Position = Vector3.new(0, 10, 0)
	spawnpoint.Anchored = true
	spawnpoint.Parent = pWorkspace

	pWorkspace.PrimaryPart = baseplate
	pWorkspace.Parent = workspace

	return pWorkspace
end

function WorkspaceService:_ClearWorkspace(pWorkspace: Model)
	local toavoid = Set({
		"wall1",
		"wall2",
		"wall3",
		"wall4",
		"Baseplate",
		"SpawnLocation",
	})

	for _, v in pairs(pWorkspace:GetChildren()) do
		if toavoid[v.Name] then
			continue
		end
		v:Destroy()
	end
end

function WorkspaceService:_addPlayerToSpace(player: Player, space: number)
	self._playerSpaces[space] = player
	self._playerWorkspace[player.UserId] = self._workspaces[space]

	self._workspaceToPlayer[self._workspaces[space]] = player

	self.Client.PlayerWorkspace:SetFor(player, self._workspaces[space])
	player.RespawnLocation = self._workspaces[space].SpawnLocation
	self.Client.WorkspaceClaimed:Fire(player, self._workspaces[space])
end

function WorkspaceService:CharacterAdded(character: Model) end

function WorkspaceService:_removePlayerFromSpace(space: number)
	self:_ClearWorkspace(self._workspaces[space])
	self._workspaceToPlayer[self._workspaces[space]] = false
	self._playerSpaces[space] = nil
end

-- Needed for the player to calculate which workspace they are on.
function WorkspaceService:CheckCurrentWorkspace(player) end

function WorkspaceService:PlayerAdded(player: Player)
	for i = 6, 1, -1 do
		if not self._playerSpaces[i] then
			self:_addPlayerToSpace(player, i)
			return
		end
	end
	warn("No player spaces left.")
end

function WorkspaceService:PlayerRemoving(player: Player)
	print("Workspace playerRemove event")
	for i, v in pairs(self._playerSpaces) do
		if v == player then
			self:_removePlayerFromSpace(i)
		end
	end
end

function WorkspaceService:GetSlotFromPlayerId(userid)
	local pWorkspace = self._playerWorkspace[userid]

	local s = self._modelToSlot[pWorkspace]

	if s then
		return s
	end

	error("Can't find workspace :(")

	return false
end

function WorkspaceService:KnitInit()

	self:PlaceDecoration()

	for i = 1, 6 do
		self._workspaces[i] = self._createWorkspacePrefab()
		self._workspaces[i]:SetPrimaryPartCFrame(
			-- Again just... idk
			CFrame.new(Vector3.new(800 * ((i - 1) % 2), 0, 800 * (math.floor((i - 1) / 2))))
		)
		self._workspaces[i].Name = "Workspace" .. i
		self._workspaceToPlayer[self._workspaces[i]] = false
		self._modelToSlot[self._workspaces[i]] = i
	end
	print("Server Init")
end

function WorkspaceService:KnitStart()
	print("Server Start")
end

function WorkspaceService:GetWorkspacePlayer(pWorkspace)
	for k, v in pairs(self._playerWorkspace) do
		if v == pWorkspace then
			return k
		end
	end

	return false
end

function WorkspaceService:getPlayersOnWorkspaces()
	return TableUtil.Values(self._playerSpaces)
end

function WorkspaceService:GetWorkspaceFromPosition(row, column)
	-- This bit of maths will just convert row and column into index
	return self._workspaces[(column - 1) * 2 + row]
end

function WorkspaceService:IsPositionInWorkspace(position: Vector3)
	local row = 1
	local column = 1

	if position.X > 405 then
		row = 2
	end

	if position.Z > 405 then
		column = 2
	end

	if position.Z > 1215 then
		column = 3
	end

	return self:GetWorkspaceFromPosition(row, column)
end

function WorkspaceService:GetStandingWorkspace(player)
	local rootpart = player.Character:FindFirstChild("Humanoid").RootPart
	if not rootpart then
		return
	end

	return self:IsPositionInWorkspace(rootpart.Position)

end

function WorkspaceService:getPlayerWorkspace(player: Player)
	local pWorkspace = self._playerWorkspace[player.UserId]

	if pWorkspace then
		return pWorkspace
	end

	error("Can't find workspace :(")

	return false
end

function WorkspaceService.Client:getPlayerWorkspace(player: Player)
	return self.Server:getPlayerWorkspace(player)
end

function WorkspaceService.Client:GetWorkspaceFromPosition(player, row, column)
	return self.Server:GetWorkspaceFromPosition(row, column)
end

return WorkspaceService
