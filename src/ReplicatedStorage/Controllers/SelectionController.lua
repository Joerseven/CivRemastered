local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Tiles = require(ReplicatedStorage.Modules.Tiles)

local SelectionController = Knit.CreateController({
	Name = "SelectionController",
	SelectionChange = Signal.new(),
	Frames = {},
	_blankfunction = function()
		return false
	end,
})

local function changeMaterial(model: Model, material: Enum.Material, color: Color3)
	for _, v: BasePart in model:GetDescendants() do
		if v:IsA("BasePart") then
			v.Material = material
			v.Color = color
		end
	end
end

local function notMarker(v: Instance)
	if not v:IsA("BasePart") then
		return false
	end

	if v.Name == "entrance" then
		return false
	end

	if v.Name == "w1" then
		return false
	end

	if v.Name == "w2" then
		return false
	end

	if v.Name == "i1" then
		return false
	end

	if v.Name == "i2" then
		return false
	end

	return true
end

function SelectionController:RotateHoverPrefab(selection)
	if not selection.hoverPrefab then
		warn("Nothing to rotate")
		return
	end

	if selection.tween then
		warn("Already Rotation")
		return
	end

	local newPivot = selection.hoverPrefab:GetPivot() * CFrame.Angles(0, math.rad(90), 0)

	selection.tween = self.TweenController:PivotTween({
		duration = 0.25,
		object = selection.hoverPrefab,
		target = newPivot,
		callback = function()
			selection.tween = nil
		end,
	})
end

function SelectionController:CreateArrow(tile)
	local arrow = ReplicatedStorage.Effects.arrow:Clone()
	arrow.Name = "Hover"
	changeMaterial(arrow, Enum.Material.Neon, Color3.new(0.235294, 0.639215, 0.227450))

	local equalY = tile:GetPivot().Position.Y + 0.5 -- First find the Y you want the arrow to float at

	local offset = (tile.entrance:GetPivot()).Position -- Now find where the arrow should point towards

	local at = Vector3.new(offset.X, equalY, offset.Z) -- Give the offset an equal height
	local lookTowards = Vector3.new(tile:GetPivot().Position.X, equalY, tile:GetPivot().Position.Z) -- Get the tile center at equal height

	local arrowCFrame = CFrame.lookAt(at, lookTowards) -- Look towards the tile center

	-- By default the arrow points up in the air so cframe needs to be corrected
	-- Then just move it out backwards after making it point in the right direction.
	arrow:PivotTo(arrowCFrame * CFrame.Angles(0, math.rad(-90), math.rad(90)) * CFrame.new(0, -1, 0))
	arrow.Parent = tile
end

function SelectionController:ROTATESELECTIONBLANK()
	warn("Nothing to rotate")
	return
end

SelectionController.RotateSelection = SelectionController.ROTATESELECTIONBLANK

function SelectionController:MakeTransparent(model, amount, color) -- TODO Make the idle markers stay transparent
	if model:IsA("Model") then
		for _, v in pairs(model:GetDescendants()) do
			if notMarker(v) then
				v.Transparency = amount
				if color then
					v.Color = color
				end
			end
		end
	end
end

-- Read only
function SelectionController:GetSelection()
	return self._selection
end

function SelectionController:GetBlankSelection()
	return self._blankSelection
end

function SelectionController:isActive() end

function SelectionController:ChangeSelection(selection)
	if self._selection ~= self._blankSelection then
		self._previousSelection = self._selection
	end

	self._selection.Cancel()

	self._selection = selection or self._blankSelection

	self.SelectionChange:Fire(selection == self._blankSelection and selection or nil)

	assert(self._selection.Init, "No cancel function passed to selection controller")
	assert(self._selection.Cancel, "No cancel function passed to selection controller")
	assert(self._selection.Trigger, "No trigger function passed to selection controller")
	assert(self._selection.Hover, "No hover function passed to selection controller")

	self._selection.Init()
end

function SelectionController:SetPreviousSelection()
	if self._previousSelection then
		self:ChangeSelection(self._previousSelection)
		return true
	end

	return false
end

function SelectionController:CancelSelection()
	--self.GUIController:SwitchSelectedAction()
	self:ChangeSelection()
end

function SelectionController:TileSelection(tileName, activateUI, deactivateUI)
	local selection = {}

	selection.Init = function()
		selection.hoverPrefab = ReplicatedStorage.Placeables.Tile[tileName]:Clone()
		selection.hoverPrefab.Name = "Hover"
		selection.hoverPrefab.Transparency = 0.5
		selection.hoverPrefab.Parent = self.currentWorkspace

		activateUI()
	end

	selection.Hover = function()
		selection.hoverPrefab.Position = self.InputController:GetCustomRaycastTarget(self.currentWorkspace)
	end

	selection.Trigger = function()
		self.TileService
			:PlaceTile(self.currentWorkspace, tileName, selection.hoverPrefab.Position)
			:andThen(function(success, result)
				if not success then
					warn("You don't have permission to place here.")
				end
			end)
	end

	selection.Cancel = function()
		selection.hoverPrefab:Destroy()
		deactivateUI()
	end

	self:ChangeSelection(selection)
end

function SelectionController:WorkSelection(onInit, onCancel, adornee)
	local selection = {
		target = nil,
		hoverPrefab = nil,
	}

	selection.Init = function()
		onInit()
		self.RotateSelection = function(_) -- Add blank param to support colon call.
			self:RotateHoverPrefab(selection)
		end
	end

	selection.Trigger = function()
		--local target = self.InputController:GetValidTarget()
		local workable = Tiles.checkWork(selection.target)

		if workable and selection.valid then
			self.WorkedTileService:WorkTile(selection.target, adornee, selection.hoverPrefab:GetPivot()):finally(function()
				self:CancelSelection()
			end)
		end
	end

	selection.Hover = function()
		local target = self.InputController:GetValidTarget(true)

		if target == selection.hoverPrefab then
			return false
		end

		local previousSelection = selection.target
		selection.target = target

		if target == previousSelection then
			return false
		end

		if selection.hoverPrefab then
			selection.hoverPrefab:Destroy()
		end

		local worktilename = Tiles.checkWork(target)

		if not worktilename then
			return false
		end

		local targetPosition = target:GetPivot()

		selection.hoverPrefab = ReplicatedStorage.Placeables.WorkTile[worktilename]:Clone()
		selection.hoverPrefab.Name = "Hover"
		targetPosition = targetPosition
		selection.hoverPrefab:PivotTo(targetPosition + Vector3.new(0, 0.01, 0))

		self:CreateArrow(selection.hoverPrefab)

		selection.hoverPrefab.Destroying:Connect(function()
			self:MakeTransparent(target, 0)
		end)

		self:MakeTransparent(target, 1)

		--self:MakeTransparent(selection.hoverPrefab, 0.2, Color3.new(0.227450, 0.858823, 0.168627))
		changeMaterial(selection.hoverPrefab, Enum.Material.SmoothPlastic, Color3.new(0.235294, 0.639215, 0.227450))

		selection.valid = true

		if (selection.hoverPrefab:GetPivot().Position - adornee:GetPivot().Position).Magnitude > 10 then
			self:MakeTransparent(selection.hoverPrefab, 0.2, Color3.new(0.921568, 0.176470, 0.176470))
			selection.valid = false
		end

		selection.hoverPrefab.Parent = workspace
		self.GUIController:CreateHoverActions()
	end

	selection.Cancel = function()
		onCancel()

		self.RotateSelection = self.ROTATESELECTIONBLANK

		if selection.hoverPrefab then
			selection.hoverPrefab:Destroy()
		end
	end

	self:ChangeSelection(selection)
end

function SelectionController:SettleSelection(activate, deactivate)
	local selection = {}

	selection.Init = function()
		selection.hoverPrefab = ReplicatedStorage.Placeables.Settlement.SettlementLV1:Clone()
		selection.hoverPrefab.Name = "Hover"

		--self:MakeTransparent(selection.hoverPrefab, 0.5)
		changeMaterial(selection.hoverPrefab, Enum.Material.SmoothPlastic, Color3.new(0.235294, 0.639215, 0.227450))

		selection.hoverPrefab.Parent = workspace
		self.GUIController:CreateHoverActions()

		self:CreateArrow(selection.hoverPrefab)

		self.RotateSelection = function(_)
			self:RotateHoverPrefab(selection)
		end

		activate()
	end

	selection.Trigger = function()
		local position = selection.hoverPrefab:GetPivot()
		local pWorkspace = self.currentWorkspace
		local tile = selection.tile

		if not tile then
			return
		end

		if selection.tween then
			return
		end

		self:CancelSelection()
		self.RotateSelection = self.ROTATESELECTIONBLANK

		self.GUIController:CreateSettlementPrompt():andThen(function(info)
			self.SettlementService:PlaceSettlement(position, pWorkspace, tile, info.name, info.faction):catch(warn)
		end)
	end

	selection.Hover = function()
		local target = self.InputController:GetValidTarget(true)

		if target and target.Name == "Hover" then
			return
		end

		if target and Tiles.checkSettle(target.Name) then
			selection.hoverPrefab:PivotTo(
				CFrame.new(target:GetPivot().Position) * selection.hoverPrefab:GetPivot().Rotation
					+ Vector3.new(0, 0.5, 0)
			)
			selection.tile = target
			return
		end

		selection.tile = nil
		selection.hoverPrefab:PivotTo(CFrame.new(0, -10000, 0))
	end

	selection.Cancel = function()
		selection.hoverPrefab:Destroy()
		deactivate()
	end

	self:ChangeSelection(selection)
end

function SelectionController:TriggerSelection()
	self._selection.Trigger()
end

function SelectionController:KnitInit()
	print("Client Init")
	self._blankSelection = {
		Init = self._blankfunction,
		Trigger = self._blankfunction,
		Hover = self._blankfunction,
		Cancel = self._blankfunction,
	}

	self._selection = self._blankSelection
end

function SelectionController:CheckCurrentWorkspace()
	if not self.currentWorkspace then
		return
	end

	if not Players.LocalPlayer.Character then
		return
	end

	local rootPart = Players.LocalPlayer.Character:FindFirstChild("Humanoid").RootPart
	
	if not rootPart then
		return
	end

	local position = rootPart:GetPivot().Position

	local row = 1
	local column = 1

	if position.X > 405 then
		row = 2
	end

	if position.Z > 405 then
		column = 2
	end

	if position.Z > 1215 then
		column = 3
	end

	if self.currentPosition[1] == row and self.currentPosition[2] == column then
		return
	end

	self.WorkspaceService:GetWorkspaceFromPosition(row, column):andThen(function(pWorkspace)
		self.currentWorkspace = pWorkspace
		self.InputController:SwitchCurrentWorkspace(pWorkspace)
		self.currentPosition = { row, column }
	end)
end

function SelectionController:Stepped()
	self:CheckCurrentWorkspace()
	self._selection.Hover()
end

function SelectionController:OnPlayerInit()
	return self.WorkspaceService:getPlayerWorkspace():andThen(function(pWorkspace)
		self.currentWorkspace = pWorkspace
		self.currentPosition = {1, 1}
	end)
end

function SelectionController:KnitStart()
	Knit.GetService("WorkspaceService").WorkspaceClaimed:Connect(function(pWorkspace)
		self.currentWorkspace = pWorkspace
		self.currentPosition = { 1, 1 }
	end)

	print("Client Start")

	self.WorkspaceService = Knit.GetService("WorkspaceService")
	self.InputController = Knit.GetController("InputController")
	self.GUIController = Knit.GetController("GUIController")
	self.TileService = Knit.GetService("TileService")
	self.SettlementService = Knit.GetService("SettlementService")
	self.WorkedTileService = Knit.GetService("WorkedTileService")
	self.TweenController = Knit.GetController("TweenController")
end

return SelectionController
