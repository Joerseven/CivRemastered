local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Promise = require(ReplicatedStorage.Packages.Promise)
local Knit = require(ReplicatedStorage.Packages.Knit)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

local EventController = Knit.CreateController({
	Name = "EventController",
	_Controllers = {},
})

function EventController:OnPlayerInit()
	return function()
		self._Controllers.GUIController:OnPlayerInit()
		self._Controllers.SelectionController:OnPlayerInit():andThen(function()
			return self._Controllers.InputController:OnPlayerInit()
		end):andThen(function()
			Promise.promisify(function()
				return Players.LocalPlayer:WaitForChild("PlayerGui")
			end)():andThen(function(gui)
				self._Controllers.MenuScreenController:BuildMenuScreen().Parent = gui
			end)
		end)
	end
end

function EventController:ConnectStepped( ... )
	for i,v in pairs({ ... }) do
		self.EnableStepped[v] = true
	end
end

function EventController:AfterSaveLoaded()
	self._Controllers.GUIController:SaveLoaded()
	self._Controllers.InputController:SaveLoaded()
	self._Controllers.WorkerController:SaveLoaded() -- Returns a promise but nothing depends on this atm

	self:ConnectStepped("SelectionController", "InputController", "LightController", "DayCycleController", "GUIController")
end

function EventController:SaveLoaded()
	return function(status)
		self._Controllers.MenuScreenController:ShowButtonLoaded(status)
		self._Controllers.MenuScreenController:RemoveMenuScreen():andThen(function()
			self:AfterSaveLoaded()
		end)
	end
end

function EventController:LoadServices()
	for _, v in pairs(ReplicatedStorage.Controllers:GetChildren()) do
		if v.Name ~= "EventController" then
			self._Controllers[v.Name] = Knit.GetController(v.Name)
		end
	end
end

function EventController:KnitInit() end

function EventController:KnitStart()

	self:LoadServices()

	local EventService = Knit.GetService("EventService")

	EventService.PlayerInitialised:Connect(self:OnPlayerInit())
	EventService.InitPlayer:Fire()

	EventService.SaveLoaded:Connect(self:SaveLoaded())

	self.EnableStepped = {
		["TweenController"] = true,
	}

	RunService.Stepped:Connect(function(_, dt)
		self._Controllers.InputController:Stepped(dt)

		for i, v in pairs(self._Controllers) do

			if not self.EnableStepped[i] then
				continue
			end

			local stepped = v.Stepped
			if stepped then
				v:Stepped(dt)
			end
		end
	end)
end

return EventController
