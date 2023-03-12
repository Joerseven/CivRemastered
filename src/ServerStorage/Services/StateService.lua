local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local StateService = Knit.CreateService({
	Name = "StateService",
	Client = {},
})

function StateService:KnitInit() end

function StateService:KnitStart() end

function StateService:getPlayersState()
	return "GAME"
end

return StateService
