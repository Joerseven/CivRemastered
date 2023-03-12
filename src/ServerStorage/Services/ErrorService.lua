local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local ErrorService = Knit.CreateService({
	Name = "ErrorService",
	Client = {
        BroadcastUserError = Knit.CreateSignal()
    },
})

function ErrorService:ErrorPopup(player, message)
    self.Client.BroadcastUserError:Fire(player, message)
end

function ErrorService:KnitInit() end

function ErrorService:KnitStart() end

return ErrorService
