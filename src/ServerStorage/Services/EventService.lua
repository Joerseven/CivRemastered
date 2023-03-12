local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Maid = require(ReplicatedStorage.Packages.Maid)

local EventService = Knit.CreateService({
	Name = "EventService",
	_Services = {},
	_Ignore = {},
	_Maids = {},
	Client = {
		 -- Client to server
		InitPlayer = Knit.CreateSignal(),
		LoadSave = Knit.CreateSignal(),
		-- Server to client
		PlayerInitialised = Knit.CreateSignal(), 
		SaveLoaded = Knit.CreateSignal(),
	},
	_SaveLoaded = {},
})

function EventService:LoadCharacter(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Died:Connect(function()
				Promise.delay(1):andThen(function()
					player:LoadCharacter()
				end)
			end)
		end
	end)

	player:LoadCharacter()
end

function EventService:LoadPlayer()
	return function(player: Player)
		self._Services.BanService:PlayerAdded(player)
		self._Services.WorkspaceService:PlayerAdded(player)
		self._Services.PermissionService:PlayerAdded(player)
		self._Services.WorkedTileService:PlayerAdded(player)
		self._Services.SettlementService:PlayerAdded(player)

		self._Maids[player.UserId] = Maid.new()

		self._Maids[player.UserId]:GiveTask(function()
			local promise = Promise.resolve()
			if self._SaveLoaded[player.UserId] then
				promise = self._Services.SaveService:SaveOnLeave(player)
			end
			promise:andThen(function()
				for _, v in pairs(self._Services) do
					if v.PlayerRemoving then
						v:PlayerRemoving(player)
					end
				end
			end)
		end)

		self.Client.PlayerInitialised:Fire(player)
	end
end

function EventService:LoadSave()
	return function(player, saveSlot)
		self._Services.SaveService:LoadSave(player, saveSlot):andThen(function(data)
			self._Services.SaveService:PlaceSave(player, self._Services.WorkspaceService:getPlayerWorkspace(player), data)
			self:LoadCharacter(player)
			self.Client.SaveLoaded:Fire(player, data and true or false)
			self._Services.SaveService:AddToStepped(player, saveSlot)
			self._SaveLoaded[player.UserId] = true
		end)
	end
end

function EventService:KnitInit()
	self.Client.InitPlayer:Connect(self:LoadPlayer())
	self.Client.LoadSave:Connect(self:LoadSave())
end

function EventService:KnitStart()

	for _, v in pairs(ServerStorage.Services:GetChildren()) do
		if v.Name ~= "EventService" then
			self._Services[v.Name] = Knit.GetService(v.Name)
		end
	end

	RunService.Stepped:Connect(function(_, dt)
		for _, v in pairs(self._Services) do
			if v.Stepped then
				v:Stepped(dt)
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		local maid = self._Maids[player.UserId]

		if maid then
			maid:DoCleaning()
		end
	end)
end

return EventService
