--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Tiles = require(ReplicatedStorage.Modules.Tiles)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Config = require(ReplicatedStorage.Modules.Config)

local InputController = Knit.CreateController({
	Name = "InputController",
	_RaycastParams = RaycastParams.new(),
	_Mouse = Players.LocalPlayer:GetMouse(),
	_PlacePosition = Vector3.new(0, 0, 0),
	_SelectionBox = nil,
	_HoverDelayTimer = 0,
	BroadcastHover = Signal.new(),
	BroadcastDelayedHover = Signal.new(),
	BroadcastDelayedMouseLeave = Signal.new(),
	UseGrid = false,
})

function InputController:_GetValidTile(target, includeHover)
	--Disable the current selection box
	if self.selectionBox then
		self.selectionBox.Visible = false
		self.selectionBox = nil
	end

	-- In case the mouse isn't hovering over anything
	if not target then
		self.BroadcastHover:Fire(nil)
		return nil
	end

	-- First check to see if the target is a valid part/tile e.g. Grass
	-- Second check is needed because it might be a subtile of a settlement.
	if target:FindFirstChild("SelectionBox") and target.Parent.Parent == workspace and Tiles.Main[target.Name] then
		self.selectionBox = target:FindFirstChild("SelectionBox")
		self.selectionBox.Visible = true
		self.BroadcastHover:Fire(target)
		return target
	end

	-- Now it's time to check the model.
	local model = target:FindFirstAncestorWhichIsA("Model")

	-- Check if there's no model, if the model's parent is the workspace, only allow this if it's the hoverprefab.
	if (not model or (model.Parent == workspace and model.Name ~= "Hover")) then
		self.BroadcastHover:Fire(nil)
		return false
	end

	-- Once again check the model is a valid tile, whether you're allowing hoverprefabs
	if model:FindFirstChild("SelectionBox") and (Tiles.Main[model.Name] or includeHover) then
		if includeHover then
			return model
		end
		self.selectionBox = model:FindFirstChild("SelectionBox")
		self.selectionBox.Visible = true
		self.BroadcastHover:Fire(model)
		return model
	end

	return self:_GetValidTile(model, includeHover)
end

function InputController:_GetMouseTarget()
	return self._Mouse.Target
end

function InputController:GetMouseTarget()
	return self:_GetMouseTarget()
end

function InputController:onInput(inputObject: InputObject, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end

	if inputObject.UserInputType == Enum.UserInputType.Keyboard then
		local key = inputObject.KeyCode

		if key == Enum.KeyCode.V then
			if self._Target then
				self[Tiles.Main[self._Target.Name].service]:DeleteTile(self._Target)
			end
		end

		if key == Enum.KeyCode.C then
			self.SelectionController:CancelSelection()
		end

		if key == Enum.KeyCode.Q then
			self.SelectionController:SetPreviousSelection()
		end

		if key == Enum.KeyCode.X then
			if self._Target and Tiles.Main[self._Target.Name].grow then
				self.GrowTileService:GrowTile(self._Target):andThen(function(tile, duration)
					if tile and duration then
						self.TweenController:GrowTile(tile, duration)
					end
				end)
			end
		end

		if key == Enum.KeyCode.R then
			if self._Target and Tiles.Main[self._Target.Name].raise then
				self.RaiseTileService:RaiseTile(self._Target):andThen(function(...)
					self.TweenController:RaiseTile(...)
				end)
			end
		end

		if key == Enum.KeyCode.Z then
			self.SelectionController:RotateSelection()
		end

		if key == Enum.KeyCode.T then
			self.SaveService:Test()
		end
	end

	if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
		self.SelectionController:TriggerSelection()
	end
end

function InputController:onInputHeld(input)
	local character = Players.LocalPlayer.Character:FindFirstChild("Humanoid")

	if input.KeyCode == Enum.KeyCode.LeftShift then
		if character then
			character.JumpPower = 200
			character.WalkSpeed = 150
		end
	end
end

function InputController:onInputStopHeld(input)
	local character = Players.LocalPlayer.Character:FindFirstChild("Humanoid")

	if input.KeyCode == Enum.KeyCode.LeftShift then
		if character then
			character.JumpPower = 50
			character.WalkSpeed = 16
		end
	end
end

function InputController:CreateIgnoreModel()
	local ignore = Instance.new("Model", workspace)
	ignore.Name = "Ignore"
	self.Ignore = ignore
	return ignore
end

function InputController:SwitchCurrentWorkspace(pWorkspace)
	self._RaycastParams.FilterDescendantsInstances = { pWorkspace.Baseplate }
end

function InputController:KnitInit()
	self._Mouse.TargetFilter = self:CreateIgnoreModel()
end

function InputController:OnPlayerInit()
	local pWorkspace = Knit.GetService("WorkspaceService"):getPlayerWorkspace():andThen(function(pWorkspace)
		self.pWorkspace = pWorkspace

		self._RaycastParams.FilterDescendantsInstances = { pWorkspace.Baseplate }
		self._RaycastParams.FilterType = Enum.RaycastFilterType.Whitelist
	end)
	return pWorkspace
end

function InputController:GetMousePosition()
	return Vector2.new(self._Mouse.X, self._Mouse.Y)
end



function InputController:SaveLoaded()
	UserInputService.InputEnded:Connect(function(...)
		self:onInput(...)
	end)

	UserInputService.InputBegan:Connect(function(...)
		self:onInputHeld(...)
	end)

	UserInputService.InputEnded:Connect(function(...)
		self:onInputStopHeld(...)
	end)
end

function InputController:GetValidTarget(includeHover)
	if includeHover then
		return self:_GetValidTile(self:_GetMouseTarget(), true)
	end
	return self._Target
end

function InputController:AddedWorkerButton()

end

function InputController:KnitStart()
	self.SelectionController = Knit.GetController("SelectionController")
	self.TweenController = Knit.GetController("TweenController")

	self.TileService = Knit.GetService("TileService")
	self.GrowTileService = Knit.GetService("GrowTileService")
	self.RaiseTileService = Knit.GetService("RaiseTileService")
	self.SettlementService = Knit.GetService("SettlementService")
	self.WorkedTileService = Knit.GetService("WorkedTileService")
	self.SaveService = Knit.GetService("SaveService")
end

function InputController:Stepped(dt)
	local ray = workspace:Raycast(self._Mouse.UnitRay.Origin, self._Mouse.UnitRay.Direction * 1000, self._RaycastParams)
	if ray then
		self._PlacePosition = ray.Position
	end

	self._HoverDelayTimer += dt

	local mousetarget = self._Mouse.Target

	local validTile = self:_GetValidTile(mousetarget)

	if validTile ~= self._Target then
		self._HoverDelayTimer = 0
		self.BroadcastDelayedMouseLeave:Fire()
	end

	if self._HoverDelayTimer > Config.HoverTimer then
		self.BroadcastDelayedHover:Fire(validTile)
		self._HoverDelayTimer = 0
	end

	self._Target = validTile
end

function InputController:GetCustomRaycastTarget(pWorkspace: Model)
	if self.UseGrid then
		local relx = self._PlacePosition.X + 1.5
		local relz = self._PlacePosition.Z + 1.5
		return Vector3.new(math.floor(relx - relx % 3), self._PlacePosition.Y, math.floor(relz - relz % 3))
	end

	return self._PlacePosition
end

return InputController
