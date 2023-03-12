local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local MusicController = Knit.CreateController({
    Name = "MusicController",
})

function MusicController:KnitInit()
    SoundService.BackgroundMusic:Play()
end

return MusicController