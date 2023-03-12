local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local Knit = require(ReplicatedStorage.Packages.Knit)

local LightController = Knit.CreateController({
	Name = "LightController",
})

function LightController:KnitInit()
	self._light = Instance.new("Part")

	self._light.Name = "LightController"
	self._light.Anchored = true
	self._light.Transparency = 1
	self._light.Size = Vector3.new(4, 1, 2)
	self._light.CanCollide = false

	self._pointLight = Instance.new("PointLight")
	self._pointLight.Brightness = 0.72
	self._pointLight.Range = 24
	self._pointLight.Parent = self._light

	self._light.Parent = workspace
end

function LightController:KnitStart()
	self._light.Parent = Knit.GetController("InputController").Ignore
end

function LightController:Stepped()
	self._light.Position = mouse.Hit.Position + Vector3.new(0, 10, 0)
end

return LightController
