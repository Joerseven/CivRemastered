local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local TIMEMULT = 50

local DayCycleController = Knit.CreateController({
	Name = "DayCycleController",
	_TimeInSeconds = 22000,
})

function DayCycleController:_BuildTimeString(seconds: number)
	local hours = string.format("%d", math.floor(seconds / 3600))
	local mins = string.format("%d", math.floor(seconds / 60 - (hours * 60)))
	local seconds = string.format("%d", math.floor(seconds - hours * 3600 - mins * 60))

	return hours .. ":" .. mins .. ":" .. seconds
end

function DayCycleController:KnitInit() end

function DayCycleController:Stepped(delta)
    self._TimeInSeconds =  self._TimeInSeconds + delta * TIMEMULT
    Lighting.TimeOfDay = self:_BuildTimeString(self._TimeInSeconds)
end

return DayCycleController
