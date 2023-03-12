local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)

local BannedPlayers = DataStoreService:GetDataStore("BannedPlayers")

local BanService = Knit.CreateService({
	Name = "BanService",
	Client = {},
	Admins = {
		["2402422743"] = true,
	},
})

function BanService:PlayerAdded(player: Player)
	if self.Admins[tostring(player.UserId)] then
		local function onChatMessage(message)
			local playerName = string.match(message, "^/ban (%w+)$")

			Promise.promisify(function()
				return Players:GetUserIdFromNameAsync(playerName)
			end)():andThen(function(userId)
				self:BanPlayer(userId, "Something Bad")
			end)
		end

		player.Chatted:Connect(onChatMessage)

		local function onChatMessageForUnban(message)
			local playerName = string.match(message, "^/unban (%w+)$")

			Promise.promisify(function()
				return Players:GetUserIdFromNameAsync(playerName)
			end)():andThen(function(userId)
				BanService:UnbanPlayer(userId)
			end)
		end

		player.Chatted:Connect(onChatMessageForUnban)
	end

	self:CheckPlayerBanned(player):andThen(function(isBanned)
		if isBanned then
			player:Kick("You are banned from this experience!")
		end
	end)
end

function BanService:BanPlayer(playerId: number, reason)
	return Promise.new(function(resolve, reject, onCancel)
		BannedPlayers:SetAsync(tostring(playerId), "true", { playerId })
		for _, v in Players:GetPlayers() do
			if v.UserId == tostring(playerId) then
				v:Kick()
			end
		end
		print(playerId .. " has been banned for: " .. reason)
		resolve()
	end)
end

function BanService:UnbanPlayer(playerId: number)
	return Promise.new(function(resolve, reject, onCancel)
		BannedPlayers:SetAsync(tostring(playerId), "false", { playerId })
		print(playerId .. " has been unbanned!")
		resolve()
	end)
end

function BanService:CheckPlayerBanned(player)
	return Promise.promisify(function()
		return BannedPlayers:GetAsync(player.UserId)
	end)():andThen(function(isBanned)
		if not isBanned or isBanned == "false" then
			return false
		end

		return true
	end)
end

return BanService
