local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

game.Players.CharacterAutoLoads = false

Knit.AddServices(ServerStorage.Services)

Knit.Start()
	:andThen(function()
		print("Knit server started successfully")
	end)
	:catch(warn)
