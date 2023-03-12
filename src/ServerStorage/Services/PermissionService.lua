local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local PermissionService = Knit.CreateService({
    Name = "PermissionService",
    Client = {
        PlayerTable = Knit.CreateProperty({}),
        EditTable = Knit.CreateProperty({}) -- Use a property so that clients can observe on change.
    },
})

local GetWorkspacePlayer = function()
    error("Forward Declaration being called")
end


function PermissionService:PlayerAdded(player: Player)
    local players = self.Client.PlayerTable:Get()
    players[player.UserId] = player
    self.Client.PlayerTable:Set(players)

    local editTable = self.Client.EditTable:Get()
    editTable[player.UserId] = { [ player.UserId ] = true }
    self.Client.EditTable:Set(editTable)
end

function PermissionService:PlayerRemoving(player: Player)

    local playerTable = self.Client.PlayerTable:Get()
    playerTable[player.UserId] = nil
    self.Client.PlayerTable:Set(playerTable)

    local editTable = self.Client.EditTable:Get()
    editTable[player.UserId] = nil
    self.Client.EditTable:Set(editTable)
end

function PermissionService:ChangePermission(player: Player, targetPlayer: Player, newPermission: boolean)
    local editTable = self.Client.EditTable:Get()
    editTable[player.UserId][targetPlayer.UserId] = newPermission
    self.Client.EditTable:Set(editTable)
end

function PermissionService:GetWorkspacePermissions(player, pWorkspace)
    local targetPlayer = self.GetWorkspacePlayer(pWorkspace)
    if not targetPlayer then
        return false
    end
    -- check if the player is inside the workspace
    if not self.WorkspaceService:GetStandingWorkspace(player, pWorkspace) then
        return false
    end

    return self.Client.EditTable:Get()[targetPlayer][player.UserId]
end

function PermissionService.Client:ChangePermission(...)
    print(...)
    return self.Server:ChangePermission(...)
end

function PermissionService:KnitStart()
    self.GetWorkspacePlayer = function(pWorkspace)
        return Knit.GetService("WorkspaceService"):GetWorkspacePlayer(pWorkspace)
    end

    self.WorkspaceService = Knit.GetService("WorkspaceService")

    self.Client.PlayerTable:Set(Players:GetPlayers())
end



return PermissionService