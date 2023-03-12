local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local TweenService = Knit.CreateService({
	Name = "TweenService",
	Client = {
		GrowTween = Knit.CreateSignal(),
	},
})

function TweenService:KnitInit()
end

function TweenService:KnitStart() end

return TweenService
