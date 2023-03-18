--!strict
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local DataStore = game:GetService("DataStoreService")
local SaveDataStore = DataStore:GetDataStore("SaveData")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Tiles = require(ReplicatedStorage.Modules.Tiles)
local Config = require(ReplicatedStorage.Modules.Config)

local Set = require(ReplicatedStorage.Util.tableUtil).Set

local SaveService = Knit.CreateService({
	Name = "SaveService",
	TilesAdded = Signal.new(),
	Client = {},
	Services = {},
	SlotTable = {},
	Timer = 0,
})

function SaveService:_Serialize(property)
	local pType = typeof(property)
	local sData

	if pType == "Vector3" then
		sData = { x = property.x, y = property.y, z = property.z }
	elseif pType == "CFrame" then
		sData = {
			position = self:_Serialize(property.Position),
			rX = self:_Serialize(property.RightVector),
			rY = self:_Serialize(property.UpVector),
			rZ = self:_Serialize(-property.LookVector),
		}
	elseif pType == "BrickColor" then
		sData = tostring(property)
	elseif pType == "Color3" then
		sData = { Color3.ToHSV(property) }
	else
		error("Unrecognised Data Type")
	end

	return sData
end

function SaveService:_Deserialize(property, pType)
	local dData -- Deserialized data

	if pType == "Vector3" then
		dData = Vector3.new(property.x, property.y, property.z)
	elseif pType == "CFrame" then
		dData = CFrame.fromMatrix(
			self:_Deserialize(property.position, "Vector3"),
			self:_Deserialize(property.rX, "Vector3"),
			self:_Deserialize(property.rY, "Vector3"),
			self:_Deserialize(property.rZ, "Vector3")
		)
	elseif pType == "BrickColor" then
		dData = BrickColor.new(property)
	elseif pType == "Color" then
		dData = Color3.fromHSV(unpack(property))
	end

	return dData
end

function SaveService:_SerializeWorkspace(pWorkspace: Model)
	local saveData = { {
		Id = "Meta",
		Place = 1,
		Chunks = 1,
		Length = 0,
	}, {} }

	local children = pWorkspace:GetChildren()
	local wCFrame = pWorkspace:GetPivot()
	local metaData = saveData[1]
	local currentChunk = saveData[2]

	for i = 1, #children do
		local v = children[i]
		local id: string = Tiles.GetId(v.Name)

		if not id then
			continue
		end

		local service = Tiles.Main[v.Name].service

		local itemData = self.Services[service]:InstanceToData(v, id, wCFrame, function(data)
			return self:_Serialize(data)
		end)

		local length = HttpService:JSONEncode(itemData):len()

		local maxLength = 3000000

		if metaData.Length + length > maxLength then -- Safety buffer
			metaData.Chunks += 1
			metaData.Length = 0
			saveData[metaData.Chunks + 1] = {}
			currentChunk = saveData[metaData.Chunks + 1]
		end

		metaData.Length += length

		currentChunk[#currentChunk + 1] = itemData
	end
	print(saveData)
	return saveData
end

function SaveService:_DeserializeWorkspace(data: table, pWorkspace: Model, player: Player)
	local metaData = data[1]
	local wCFrame = pWorkspace:GetPivot()

	if not (metaData.Id and metaData.Id == "Meta") then
		warn("Save file isn't valid, perhaps legacy.")
		return
	end

	for i = 2, metaData.Chunks + 1 do
		local chunk = data[i]

		if not chunk then
			warn("Chunk couldn't be found? Save data corruption possible")
			continue
		end

		for j = 1, #chunk do
			local itemData = chunk[j]
			local objectName = Tiles.Main[itemData.Id].name
			local objectParent = self.Services[Tiles.Main[itemData.Id].service]

			local tile: Model = objectParent:DataToInstance(itemData, pWorkspace, function(iData, type) return self:_Deserialize(iData, type) end)
		end
	end

	self.Services.SettlementService:UpdateAll(player)
	self.TilesAdded:Fire(pWorkspace)
end

function SaveService:PlaceSave(player, pWorkspace, data)
	if not data then
		return false
	end

	self:_DeserializeWorkspace(data, pWorkspace, player)
end

function SaveService.Client:LoadWorkspace(player, slot)
	return self.Server:LoadWorkspace(player, slot)
end

function SaveService:SaveWorkspace(player: Player, slot: number)
	return Promise.new(function(resolve,reject,onCancel)
		local pWorkspace = Knit.GetService("WorkspaceService"):getPlayerWorkspace(player)
		local data = self:_SerializeWorkspace(pWorkspace)

		local metadata = data[1]

		local prefix = ""

		if game:GetService("RunService"):IsStudio() then
			prefix = "studio"
		end

		SaveDataStore:SetAsync(prefix .. "p" .. player.UserId .. "s" .. slot, metadata, { player.UserId })

		for i = 1, metadata.Chunks do
			SaveDataStore:SetAsync(prefix .. "p" .. player.UserId .. "s" .. slot .. "c" .. i, data[i+1], { player.UserId })
		end

		print("Saved Successfully!")

		resolve(true)
	end)
end

function SaveService:LoadSave(player: Player, slot: number)
	return Promise.new(function(resolve, reject, onCancel)
		local prefix = ""

		if game:GetService("RunService"):IsStudio() then
			prefix = "studio"
		end

		local data = {}

		local playerSlotKey = prefix .. "p" .. player.UserId .. "s" .. slot

		data[1] = SaveDataStore:GetAsync(playerSlotKey)

		if data[1] == nil then
			warn("No save file here!")
			resolve(false)
		end

		local chunks = data[1].Chunks

		local ChunksToLoad = {}
		local pGetAsync = Promise.promisify(function(key) return SaveDataStore:GetAsync(key) end)

		for i = 1, chunks do
			ChunksToLoad[i] = pGetAsync(playerSlotKey .. "c" .. i)
		end

		Promise.all(ChunksToLoad):andThen(function(results)
			for i,v in ipairs(results) do
				data[i + 1] = v
			end

			resolve(data)
		end):catch(reject)
	end)
end

-- Name this different so it can be called before the others. 
function SaveService:SaveOnLeave(player)
	local slot: number = self.SlotTable[player.UserId]
	return self:SaveWorkspace(player, slot)
end

function SaveService:AddToStepped(player: Player, slot: number)
	self.SlotTable[player.UserId] = slot
end

function SaveService:Stepped(dt)
	local timeInterval = Config.SaveInterval
	self.Timer += dt

	if self.Timer >= timeInterval then
		print(Players:GetPlayers())
		for _, player in pairs(Players:GetPlayers()) do
			local slot = self.SlotTable[player.UserId]
			if slot then
				self:SaveWorkspace(player, slot):catch(warn)
			end
		end
		self.Timer = 0
	end
end

-- function SaveService:KnitInit()
-- 	self.invIdTable = {}
-- 	self.tileLocations = {}
-- 	self.Services = {}

-- 	for i, v in ipairs(self.IdTable) do
-- 		self.invIdTable[v] = i
-- 	end

-- 	local idset = Set(self.IdTable)

-- 	for _, v in pairs(ReplicatedStorage.Placeables:GetDescendants()) do
-- 		if v.Name and idset[v.Name] then
-- 			self.tileLocations[v.Name] = v.Parent
-- 			self.Services[v.Parent.Name] = {}
-- 		end
-- 	end
-- end

function SaveService:KnitStart()

	self.Services = {
		TileService = false,
		GrowTileService = false,
		RaiseTileService = false,
		WorkedTileService = false,
		SettlementService = false
	}

	for i in pairs(self.Services) do
		self.Services[i] = Knit.GetService(i)
	end
end

return SaveService
