local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TextService = game:GetService("TextService")
local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Component = require(ReplicatedStorage.Packages.Component)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Tiles = require(ReplicatedStorage.Modules.Tiles)

local Config = require(ReplicatedStorage.Modules.Config)

local DEFAULTTITLE = "Tiles"

-- passes frames to selectioncontroller that have:
-- Activate
-- Deactivate

local GUIController = Knit.CreateController({
	Name = "GUIController",
	buttons = {},
	frames = {},
	SwitchTimer = 0,
	LastTask = function() end,
	CurrentHover = Instance.new("BillboardGui"),
	ButtonQueue = {},
})

local activateSound = Instance.new("Sound")
activateSound.SoundId = "rbxassetid://12376691130"
activateSound.Looped = false
activateSound.Volume = 0.1
activateSound.Parent = workspace

local deactivateSound = Instance.new("Sound")
deactivateSound.SoundId = "rbxassetid://12376705215"
deactivateSound.Looped = false
deactivateSound.Volume = 0.1
deactivateSound.Parent = workspace

local switchSound = Instance.new("Sound")
switchSound.SoundId = "rbxassetid://12376688310"
switchSound.Looped = false
switchSound.Volume = 0.1
switchSound.Parent = workspace

function GUIController:LevelToXP(tilename)
	return 2 ^ (Tiles.Main[tilename].capacity + 5)
end

function GUIController:SwitchSelected(name, frame, changeTitleText)
	name = name or ""

	local tween
	local active = ""

	local deactivate = function()
		tween:Finish()
		frame:TransparentBackground():RoundedSquare(0)
		changeTitleText(DEFAULTTITLE)
		active = ""
		--SoundService:PlayLocalSound(deactivateSound)
	end

	local activate = function()
		if active == name then
			deactivate()
			return
		end

		frame:BackgroundColor(Color3.fromRGB(60, 179, 113)):TransparentBackground(true)
		tween = self.TweenController:NewTween({
			duration = 0.5,
			object = frame.i,
			property = "Size",
			target = UDim2.fromOffset(90, 90),
		})
		changeTitleText(name)
		SoundService:PlayLocalSound(activateSound)
		active = name
	end

	if name == "Settlement" then
		self.SelectionController:SettleSelection(activate, deactivate)
		return true
	end

	self.SelectionController:TileSelection(name, activate, deactivate)
end

function GUIController:CreateSettlementPrompt(parent)
	if not parent then
		parent = self.ScreenGui
	end

	local frame = Component
		:new("Frame", parent)
		:FadeBackground()
		:Center()
		:Middle()
		:Padding(25, 25, 25, 25)
		:RoundedSquare(20, 20)
		:MakeList(10, false)
		:AutoSize() -- override only one autosize
		:Position(-5, -0.2)

	local text = Component:new("TextLabel", frame)
		:Font("Nunito", 40)
		:Center()
		:AutoSize()
		:Text("Create Settlement")
		:TransparentBackground()
		:Border(0)

	local settleName = Component:new("TextBox", frame)
		:Font("Nunito", 24)
		:Center()
		:DefaultText("Settlement Name")
		:Text("")
		:BackgroundColor(Color3.new(1, 1, 1))
		:RoundedRectangle(280, 40, 20)
		:Border(0)

	local settleFaction = settleName:Clone():DefaultText("Faction Name")

	local buttonRow = Component:new("Frame", frame):TransparentBackground():Size(1, 0, 0, 50)

	local buttonWidth = 120

	local confirmButton = Component:new("TextButton", buttonRow)
		:Font("Nunito", 32)
		:Text("Confirm")
		:AutoSize("Y")
		:BackgroundColor(Color3.new(0.14, 0.14, 0.25))
		:Border(0)
		:RoundedRectangle(1, 40, 40)
		:Size(0, 0, buttonWidth, 0)
		:Center()
		:Anchor(Vector2.new(1, 0))
		:Offset(-10, 0)
		:Padding(10, 20, 10, 20)
		:TextColor(Color3.new(1, 1, 1))

	local cancelButton = Component:new("TextButton", buttonRow)
		:AutoSize("Y")
		:Center()
		:Anchor(Vector2.new(0, 0))
		:Offset(10, 0)
		:Font("Nunito", 32)
		:Text("Cancel")
		:BackgroundColor(Color3.new(0.811764, 0.811764, 0.823529))
		:Border(0)
		:RoundedRectangle(1, 40, 40)
		:Size(0, 0, buttonWidth, 0)
		:Padding(10, 20, 10, 20)
		:TextColor(Color3.new(0.184313, 0.184313, 0.184313))

	frame:Mount()

	local p -- Declare so that we can use inside promise to cancel.

	p = Promise.new(function(resolve, reject, onCancel)
		if onCancel(function()
			if frame then
				frame.i:Destroy()
			end
		end) then
			return
		end

		cancelButton.i.MouseButton1Click:Connect(function()
			p:cancel()
		end)

		confirmButton.i.MouseButton1Click:Connect(function()
			local sText = settleName.i.Text
			local fText = settleFaction.i.Text

			if sText == "" or fText == "" then
				text.i.Text = "Can't be empty!"
				return
			end

			if sText:len() > 30 or fText:len() > 30 then
				text.i.Text = "Settlement or faction name too long!"
				return
			end

			if sText:find("#") or fText:find("#") then
				text.i.Text = "Can't have the hash symbol!"
				return
			end

			local status, info = self.SettlementService:ValidateNames(sText, fText):await()

			if not status or not info then
				text.i.Text = "Roblox filtering didn't like that."
				return
			end

			frame.i:Destroy()
			resolve(info)
		end)
	end)

	return p
end

function GUIController:CreateBillboard(adornee: Model | { BaseTile: Model }, factionColor)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromScale(12, 6.4)
	billboard.SizeOffset = Vector2.new(0, 2)
	billboard.Parent = self.ScreenGui
	billboard.Adornee = adornee.BaseTile
	billboard.AlwaysOnTop = false
	billboard.StudsOffset = Vector3.new(0, -7.5, 0)
	billboard.Active = true

	self.ButtonQueue[billboard] = 0

	adornee.Destroying:Connect(function()
		billboard:Destroy()
		self.ButtonQueue[billboard] = nil
	end)

	local containerFrame = Component:new("Frame", billboard)
		:TransparentBackground()
		:RSize(0.5, 0.25)
		:Center()
		:Bottom()
		:Name("Container")
		:Mount()

	local clipFrame = Component:new("Frame", containerFrame):TransparentBackground():RSize(1, 0.8):Clip():Mount()

	local frame = Component:new("Frame", clipFrame):RoundedRectangle(1, 1, 9999999):RSize(1, 1.2):FadeBackground()

	frame.i.Corners.CornerRadius = UDim.new(0.2, 0)

	local barsize = math.min(adornee:GetAttribute("supplyCount") / self:LevelToXP(adornee.Name), 1)

	local name = Component:new("TextLabel", frame)
		:Anchor(Vector2.new(0, 0.5))
		:Position(0.22, 0.42)
		:RSize(0.7, 0.8)
		:RPadding(0.1, 0.1, 0.1, 0.1)
		:TransparentBackground()
		:Font("Nunito")
		:Text(adornee:GetAttribute("name"))
		:FontColor(Color3.new(0.2, 0.2, 0.2))
		:TextScaled()

	local xpbar = Component
		:new("Frame", containerFrame)
		:Bottom()
		:RSize(barsize, 0.2)
		:BackgroundColor(Color3.fromHex("#22B95E"))
		:Border(0)
		--:Anchor(Vector2.new(0,0))
		:CurveCorners(999999)
		:BringForward(-4)
		:Mount()

	local level = Component:new("TextLabel", containerFrame)
		:RCircle(1.5)
		:Position(-0.2, 0)
		:Constrain("y")
		:Middle()
		:RPadding(0.25, 0.25, 0.25, 0.25)
		:Border(0)
		:BackgroundColor(factionColor)
		:Font("Nunito")
		:TextScaled()
		:FontColor(Color3.new(1, 1, 1))
		:Text(adornee.Name:sub(-1, -1))
		:BringForward(2)
		:Mount()

	frame:Mount()

	adornee.AttributeChanged:Connect(function(attribute)
		if attribute == "supplyCount" then
			xpbar:RSize(math.min(adornee:GetAttribute("supplyCount") / self:LevelToXP(adornee.Name), 1), 0.2)
		end
	end)

	--self:CreateBillboardButton(adornee, "Hammer", nil, 25)
end

local billboardButtons = {
	Hammer = "10555583305",
	Wagon = "12989680239",
}

function GUIController:CreateBillboardButton(adornee, buttonName, buttonClick, rotation)
	local parent = false
	for _, v in pairs(self.ScreenGui:GetChildren()) do
		if v:IsA("BillboardGui") and v.Adornee == adornee.BaseTile then
			parent = v.Container
		end
	end

	if not parent then
		error("Can't find settlement billboard to place button on.")
		return false
	end

	if parent:FindFirstChild(buttonName) then
		warn("A button already exists")
		return
	end

	self.ButtonQueue[parent.Parent] += 1

	local colors = {
		work = Color3.new(1, 0.8, 0.2),
		active = Color3.fromRGB(60, 179, 113),
	}

	local frame = Component:new("Frame", parent)
		:RCircle(0.9)
		:Position(1 - 0.25 * (self.ButtonQueue[parent.Parent] - 1), 0)
		:Name(buttonName)
		:Constrain()
		:BackgroundColor(colors.work)
		:Anchor(Vector2.new(0.5, 0.5))

	local button = Component:new("TextButton", frame)
		:BringForward(5)
		:RCircle(1)
		:Position(0, 0)
		:Text()
		:TransparentBackground()
		:Constrain()

	local img = Component:new("ImageLabel", frame)
		:TransparentBackground()
		:Name(buttonName)
		:Constrain()
		:ImageUrl(billboardButtons[buttonName])
		:Position(0.5, 0.5)
		:RSize(0.6, 0.6)
		:Anchor(Vector2.new(0.5, 0.5))

	img.i.ScaleType = Enum.ScaleType.Fit

	if rotation then
		img.i.Rotation = rotation
	end

	frame:Mount()

	local onSelected = function()
		frame:BackgroundColor(colors.active)
	end

	local onDeselect = function()
		frame:BackgroundColor(colors.work)
	end

	button.i.MouseButton1Click:Connect(function()
		buttonClick(onSelected, onDeselect, adornee)
	end)

	button.i.Destroying:Connect(function()
		self.ButtonQueue[parent.Parent] -= 1
	end)
end

function GUIController:RemoveBillboardButton(adornee, name)
	local parent = false
	for _, v in pairs(self.ScreenGui:GetChildren()) do
		if v:IsA("BillboardGui") and v.Adornee == adornee.BaseTile then
			parent = v.Container
		end
	end

	if not parent then
		error("Can't find settlement billboard to remove button from.")
		return false
	end

	local button = parent:FindFirstChild(name)

	if button then
		local n = 0
		button:Destroy()
		for _, v in pairs(parent:GetChildren()) do
			for k in pairs(billboardButtons) do
				if v.Name == k then
					v.Position = UDim2.fromScale(1 - 0.25 * n, 0)
					n += 1
					break
				end
			end
		end
	end
end

function GUIController:_CreateSecondryBar(parent)
	local actions = { "Water", "Raise", "Rotate", "Destroy" }

	self.secondryBar = Component:new("Frame", parent)
		:Left(10)
		:MakeList(20, false, true)
		:Padding(0, 0, 0, 0)
		:Name("SecondryBar")
		:Middle()
		:Width(80)
		:Border(0)
		:TransparentBackground()

	for index, value in ipairs(actions) do
		local button =
			Component:new("ImageButton", self.secondryBar):RoundedSquare(90):Border(0):FadeBackground():BringForward()
	end

	self.secondryBar:Mount()
end

function GUIController:CreateTileBar(parent)
	local images = {
		{ "Grass", "11871952212" },
		{ "Stone", "11871951681" },
		{ "Desert", "11871952538" },
		{ "Settlement", "11871951918" },
		{ "Farmland", "11871952391" },
		{ "Sand", "11871952054" },
		{ "Snow", "11871958071" },
	}

	local settleImage = "11871800699"

	self.actionBar = Component:new("Frame", parent)
		:Center()
		:Bottom(-20)
		:FadeBackground()
		:CurveCorners(50)
		:MakeList(20, true)
		:Height(80)
		:Padding(5, 20, 5, 20)
		:Name("TileBar")

	local barTitle = Component:new("TextLabel", parent)
		:Center()
		:Bottom(-102)
		:RoundedRectangle(150, 40, 20)
		:BackgroundColor(Color3.fromRGB(0, 8, 42))
		:Text(DEFAULTTITLE)
		:BringForward(3)
		:Font("Nunito", 25)
		:Padding(5, 5, 5, 5)
		:FontColor(Color3.new(1, 1, 1))
		:Bold()

	self.actionBar.defaultText = DEFAULTTITLE

	local ubarTitle = Component:new("Frame", parent)
		:Center()
		:Bottom(-102)
		:RoundedRectangle(148, 20, 0)
		:BackgroundColor(Color3.fromRGB(0, 8, 42))

	for _, v in ipairs(images) do
		local image = Component:new("ImageButton", self.actionBar)
			:ImageUrl(v[2])
			:Square(80)
			:BringForward(6)
			:TransparentBackground()
			:Name(v[1])
			:BringForward()

		local function mouseenter()
			barTitle:Text(v[1])
			--SoundService:PlayLocalSound(switchSound)
		end

		local function mouseleave()
			barTitle:Text("<b>" .. self.actionBar.defaultText .. "</b>")
		end

		image.i.MouseEnter:Connect(function()
			mouseenter()
		end)

		image.i.MouseLeave:Connect(function()
			mouseleave()
		end)

		local frame = Component:new("Frame", image)
			:RoundedSquare(20, 15)
			:TransparentBackground()
			:Name(v[1])
			:Center()
			:BringForward(5)
			:Middle()
			:Circle(0)

		local function changeTitleText(text)
			self.actionBar.defaultText = text
			barTitle:Text("<b>" .. self.actionBar.defaultText .. "</b>")
		end

		image.i.MouseButton1Click:Connect(function()
			self:SwitchSelected(image.i.Name, frame, changeTitleText)
		end)

		self.frames[#self.frames + 1] = frame
		self.buttons[#self.buttons + 1] = image
	end

	self.actionBar:Mount()
	barTitle:Mount()
	ubarTitle:Mount()
end

function GUIController:CreateActionBar(parent)
	local actions = {
		Grow = {
			image = "12239944798",
		},
		Raise = {
			image = "12239944549",
		},
		Rotate = {
			image = "12250197547",
		},
		Delete = {
			image = "12239945030",
		},
		Cancel = {
			image = "12239945255",
		},
	}

	local frame = Component:new("Frame", parent)
		:Name("ActionBar")
		:Padding(0, 10, 10, 10)
		:Middle()
		:Left(20)
		:FadeBackground()
		:AutoSize("Y")
		:RoundedRectangle(120, 40, 20)

	local fillBar = Component
		:new("Frame", frame)
		:Center()
		:Top(24)
		-- No idea why this needs to be smaller at such a random point as well.
		:RoundedRectangle(118, 17, 0)
		:BackgroundColor(Color3.fromRGB(0, 8, 42))
		:BringForward(2)

	local title = Component:new("TextLabel", frame)
		:Center()
		:Padding(5, 5, 5, 5)
		:BackgroundColor(Color3.fromRGB(0, 8, 42))
		:Font("Nunito", 25)
		:FontColor(Color3.new(1, 1, 1))
		:Text("Actions")
		:Bold()
		:Top(-5)
		:RoundedRectangle(120, 45, 20)
		:BringForward(3)

	local listContainer = Component:new("Frame", frame)
		:Center()
		:Top(53)
		:MakeList(15, false, false, Enum.VerticalAlignment.Top)
		:TransparentBackground()

	for key, value in pairs(actions) do
		local actionContainer = Component:new("Frame", listContainer)
			:Size(0, 0, 80, 80)
			:TransparentBackground()
			:MakeList(10, false, false)
			:Name(key)

		local actionText = Component:new("TextLabel", actionContainer)
			:Font("Nunito", 20)
			:FontColor(Color3.new(0.2, 0.2, 0.2))
			:Text(key)
			:Center()
			:TransparentBackground()

		local actionLabel = Component:new("ImageLabel", actionContainer)
			:Size(0, 0, 60, 60)
			:TransparentBackground()
			:ImageUrl(value.image)
	end

	-- local tweenHolder = {
	-- 	Grow = Promise.resolve(),
	-- 	Raise = Promise.resolve(),
	-- 	Delete = Promise.resolve(),
	-- 	Rotate = Promise.resolve(),
	-- 	Cancel = Promise.resolve(),
	-- }

	-- local targets = {
	-- 	Grow = 0,
	-- 	Raise = 0,
	-- 	Delete = 0,
	-- 	Rotate = 0,
	-- 	Cancel = 0,
	-- }

	-- local function makeChildrenTransparent(listObject: any, amount: number)

	-- 	if amount == targets[listObject.name] then
	-- 		return
	-- 	end

	-- 	tweenHolder[listObject.Name]:cancel()
	-- 	tweenHolder[listObject.Name] = self.TweenController:PNewTween({
	-- 		duration = 0.5,
	-- 		object = listObject.ImageLabel,
	-- 		property = "ImageTransparency",
	-- 		target = amount,
	-- 	})

	-- 	targets[listObject.Name] = amount
	-- end

	-- local currentObj = {}

	-- self.InputController.BroadcastHover:Connect(function(object)

	-- 	local trans = {
	-- 		Grow = 0.6,
	-- 		Raise = 0.6,
	-- 		Delete = 0.6,
	-- 		Rotate = 0.0,
	-- 		Cancel = 0.0,
	-- 	}

	-- 	local function triggerTransShift()
	-- 		for k,v in pairs(trans) do
	-- 			makeChildrenTransparent(listContainer.i:FindFirstChild(k), v)
	-- 		end
	-- 	end

	-- 	if object == currentObj then
	-- 		return
	-- 	end

	-- 	currentObj = object

	-- 	local selection = self.SelectionController:GetSelection()

	-- 	if selection ~= self.SelectionController:GetBlankSelection() then
	-- 		trans.Cancel = 0
	-- 	end

	-- 	if self.SelectionController.RotateSelection ~= self.SelectionController.ROTATESELECTIONBLANK then
	-- 		trans.Rotate = 0
	-- 	end

	-- 	if not object then
	-- 		triggerTransShift()
	-- 	elseif object:IsA("BasePart") or object:IsA("Model") then

	-- 		if Tiles.Main[object.Name].grow then
	-- 			trans.Grow = 0
	-- 		end

	-- 		if Tiles.Main[object.Name].raise then
	-- 			trans.Raise = 0
	-- 		end

	-- 		trans.Delete = 0

	-- 		triggerTransShift()
	-- 	end

	-- end)

	frame:Mount()
end

function GUIController:Stepped(dt) end

local function capitalizeWord(word)
	return word:sub(1, 1):upper() .. word:sub(2)
end

function GUIController:CreateHoverActions(parent)
	if not parent then
		if workspace:FindFirstChild("Hover") then
			parent = workspace.Hover
		else
			return
		end
	end

	if self.ScreenGui:FindFirstChild("HoverActions") then
		return
	end

	parent.Destroying:Connect(function()
		if self.ScreenGui:FindFirstChild("HoverActions") then
			self.ScreenGui.HoverActions:Destroy()
		end
	end)

	local parentActions = parent.Name == "Hover" and { rotate = true, cancel = true } or Tiles.GetTasks(parent.Name)

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "HoverActions"
	billboardGui.StudsOffset = Vector3.new(0, 0, 0)
	billboardGui.Size = UDim2.new(0, 200, 0, 200)
	billboardGui.AlwaysOnTop = true
	-- set the hover attribute to true so it knows not to delete itself
	billboardGui:SetAttribute("hover", parent.Name == "Hover" and true or false)
	billboardGui.MaxDistance = 1000
	billboardGui.Parent = self.ScreenGui
	billboardGui.Adornee = parent

	local counter = 0

	local wheelDivisons = 0

	for _, value in pairs(parentActions) do
		if not value then
			continue
		end

		wheelDivisons += 1
	end

	local angle = (math.pi * 2) / wheelDivisons

	for key, value in pairs(parentActions) do
		-- angle is the angle between each divison, counter is the current divison
		local xMod = (math.cos(angle * counter - math.pi / 2 * (wheelDivisons % 2)) * 0.4 + 0.5)
		local yMod = (math.sin(angle * counter - math.pi / 2 * (wheelDivisons % 2)) * 0.4 + 0.5)

		counter += 1

		if not value then
			continue
		end

		local containerFrame = Component:new("Frame", billboardGui)
			:Size(0, 0, 80, 80)
			:MakeList(10, false, false)
			:FadeBackground()
			:CurveCorners(25)
			:Padding(10, 20, 10, 20)
			:Position(xMod, yMod)
			:Anchor(Vector2.new(0.5, 0.5))
			:Mount()

		local action = Component:new("TextLabel", containerFrame)
			:Font("Nunito", 24)
			:Anchor(Vector2.new(0.5, 0.5))
			:FontColor(Color3.new(0.1, 0.1, 0.1))
			:Text(capitalizeWord(key))
			:TransparentBackground()
			:Name(key)
			:AutoSize()
			:Mount()

		local actionKey = Component:new("ImageLabel", containerFrame)
			:BringForward(2)
			:Position(xMod, yMod)
			:PositionOffset(0, -60)
			:Anchor(Vector2.new(0.5, 0.5))
			:Size(0, 0, 40, 40)
			:ImageUrl(Config.ActionKeyImages[key])
			:TransparentBackground()
			:Name(key)
			:Mount()
	end
end

function GUIController:DestroyHoverActions()
	if self.ScreenGui:FindFirstChild("HoverActions") then
		if self.ScreenGui.HoverActions:GetAttribute("hover") then
			return
		end
		self.ScreenGui.HoverActions:Destroy()
	end
end

function GUIController:CreateSettings(parent)
	local frame =
		Component:new("Frame", parent):Center():Middle(-120):FadeBackground():Size(0, 0, 460, 515):CurveCorners(30)

	local title = Component:new("TextLabel", frame)
		:Font("Nunito", 32)
		:TextColor(Color3.new(1, 1, 1))
		:Center()
		:AutoSize()
		:Padding(20, 20, 20, 20)
		:CurveCorners(400)
		:Anchor(Vector2.new(0.5, 0.5))
		:BackgroundColor(Config.ActiveColor)
		:Text("Permissions")
		:Bold()
		:BringForward(3)

	local container = Component:new("Frame", frame)
		:RSize(1, 1)
		:TransparentBackground()
		:MakeList(15, false, false, Enum.VerticalAlignment.Top)
		:Padding(40)

	local p1 = self.PlayerTable:OnReady()
	local p2 = self.PermissionTable:OnReady()

	-- Results[1] is the player table and results[2] is the permissionstable
	Promise.all({ p1, p2 }):andThen(function(results)
		local playerId = tostring(Players.LocalPlayer.UserId)
		local playerPermissions = results[2][playerId]
		for index, value in pairs(results[1]) do
			local playerRow = Component:new("Frame", container):Size(0.9, 0, 0, 60):Border(0):TransparentBackground()
			local playerName = Component:new("TextLabel", playerRow)
				:Left(90)
				:Middle()
				:TransparentBackground()
				:Font("Nunito", 30)
				:TextScaled()
				:TextColor(Color3.new(0.1, 0.1, 0.1))
				:Text(value.Name)
				:Size(0, 0, 200, 60)
				:MinSize(30)
				:TextAlign(Enum.TextXAlignment.Left)

			local permissionsButton = Component:new("TextButton", playerRow)
				:Middle()
				:Right(0)
				:BackgroundColor(playerPermissions[index] and Config.PositiveColor or Config.NegativeColor)
				:Font(Config.MainFont, 24)
				:AutoSize()
				:Border(0)
				:TextColor(Color3.new(1, 1, 1))
				:Padding(10, 10, 10, 10)
				:CurveCorners(5)
				:Text(playerPermissions[index] and "Can edit" or "Can't edit")
				:Bold()

			local function switchPermissions()
				local newVal = not results[2][tostring(Players.LocalPlayer.UserId)][index]
				results[2][playerId][index] = newVal
				self.PermissionService:ChangePermission(results[1][index], newVal):andThen(function()
					permissionsButton:Text(newVal and "<b>Can edit</b>" or "<b>Can't edit</b>")
					permissionsButton:BackgroundColor(newVal and Config.PositiveColor or Config.NegativeColor)
				end)
			end

			permissionsButton.i.MouseButton1Click:Connect(switchPermissions)

			Promise.new(function(resolve, reject, onCancel)
				resolve(
					Players:GetUserThumbnailAsync(
						value.UserId,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailSize.Size60x60
					)
				)
			end):andThen(function(url)
				local i = Component:new("ImageLabel", playerRow)
					:Left(10)
					:Middle()
					:Size(0, 0, 60, 60)
					:TransparentBackground()
					:Border(0)
					:CurveCorners(60)
					:Mount()
				-- Can't use the :ImageUrl function as it adds rbxassetid to the start.
				i.i.Image = url
			end)
		end
	end)

	frame:Mount()

	return frame
end

function GUIController:CreateSettingsIcon(parent)
	--local settingId = "11889971043"
	local settingId = "11897883023"

	local bar = Component:new("Frame", parent):Right(-30):Top(30):FadeBackground():Size(0, 0, 70, 70):CurveCorners(15) -- High value to fully curve

	local settingsButton = Component:new("ImageButton", bar)
		:ImageUrl(settingId)
		:Size(0, 0, 37, 40)
		:Center()
		:Middle()
		:TransparentBackground()
		:ImageColor(Color3.new(0.4, 0.4, 0.4))

	local settingsOn = false
	local settingsFrame
	local tweenPromise

	local function toggleSettings()
		if tweenPromise then
			tweenPromise:cancel()
		end

		if settingsOn then
			settingsButton.i.ImageColor3 = Color3.new(0.4, 0.4, 0.4)
			tweenPromise = self.TweenController:MultiTween(0.25, {
				object = settingsButton.i,
				property = "Rotation",
				target = 0,
			}, {
				object = bar.i,
				property = "BackgroundTransparency",
				target = Config.BackgroundFade,
			}, {
				object = bar.i,
				property = "BackgroundColor3",
				target = Color3.new(1, 1, 1),
			})
			settingsFrame.i:Destroy()
			settingsOn = false
		else
			settingsButton.i.ImageColor3 = Color3.new(1, 1, 1)
			tweenPromise = self.TweenController:MultiTween(0.25, {
				object = settingsButton.i,
				property = "Rotation",
				target = 90,
			}, {
				object = bar.i,
				property = "BackgroundTransparency",
				target = 0,
			}, {
				object = bar.i,
				property = "BackgroundColor3",
				target = Config.ActiveColor,
			})
			settingsFrame = self:CreateSettings(parent)
			settingsOn = true
		end

		tweenPromise:andThen(function()
			tweenPromise = false
		end)
	end

	settingsButton.i.MouseButton1Click:Connect(toggleSettings)

	bar:Mount()
end

function GUIController:_CreateErrorBase(text)
	local errorBox = Component:new("TextLabel", self.ScreenGui)
		:FontColor(Color3.new(1, 1, 1))
		:BackgroundColor(Color3.new(0.8, 0.235294, 0.235294))
		:CurveCorners(5)
		:Border(0)
		:Center()
		:Text(text)
		:Padding(10, 20, 10, 20)
		:AutoSize()
		:Font("Nunito", 35)
		:Bold()
		:Center()
		:Top(-50)

	errorBox:Mount()

	return errorBox
end

function GUIController:CreateErrorPopup(message)
	local frame = self:_CreateErrorBase(message)
	self.TweenController:NewTween({
		object = frame.i,
		property = "Position",
		target = UDim2.new(0.5, 0, 0, 20),
		callback = function()
			task.delay(3, function()
				frame:Destroy()
			end)
		end,
	})
end

function GUIController:OnPlayerInit()

	local workerButtonClick = function(onSelected, onDeselect, adornee)
		self.SelectionController:WorkSelection(onSelected, onDeselect, adornee)
	end

	local settlerButtonClick = function()
	end

	self.SettlementService.AddWorkerButton:Connect(function(adornee)
		self:CreateBillboardButton(adornee, "Hammer", workerButtonClick, 25)
	end)

	self.SettlementService.RemoveWorkerButton:Connect(function(adornee)
		self:RemoveBillboardButton(adornee, "Hammer")
	end)

	self.SettlementService.AddSettlerButton:Connect(function(adornee)
		self:CreateBillboardButton(adornee, "Wagon", settlerButtonClick, 0)
	end)

	self.SettlementService.AddSettlementBillboard:Connect(function(...)
		self:CreateBillboard(...)
	end)
end

function GUIController:SaveLoaded()
	self.ScreenGui.Enabled = true
	self:CreateTileBar(self.ScreenGui)
	self.InputController.BroadcastDelayedHover:Connect(function(target)
		self:CreateHoverActions(target)
	end)

	self.InputController.BroadcastDelayedMouseLeave:Connect(function()
		self:DestroyHoverActions()
	end)
	-- self:CreateActionBar(self.ScreenGui)
	self:CreateSettingsIcon(self.ScreenGui)
end

function GUIController:KnitInit()
	local PlayerGui = player:WaitForChild("PlayerGui")
	self.ScreenGui = Instance.new("ScreenGui")
	self.ScreenGui.Enabled = false
	self.ScreenGui.Name = "MenuGui"
	self.ScreenGui.ResetOnSpawn = false
	self.ScreenGui.Parent = PlayerGui
	self.Mouse = player:GetMouse()

	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

	-- self:_CreateActionBar(self.ScreenGui)
	-- self:CreateSettingsIcon(self.ScreenGui)
	--self:_CreateSecondryBar(self.ScreenGui)
end

function GUIController:KnitStart()
	self.TweenController = Knit.GetController("TweenController")
	self.SelectionController = Knit.GetController("SelectionController")
	self.SettlementService = Knit.GetService("SettlementService")
	self.InputController = Knit.GetController("InputController")

	local ErrorService = Knit.GetService("ErrorService")
	self.PermissionService = Knit.GetService("PermissionService")
	-- Don't do this again not worth it.
	self.PermissionTable = Knit.GetService("PermissionService").EditTable
	self.PlayerTable = Knit.GetService("PermissionService").PlayerTable

	ErrorService.BroadcastUserError:Connect(function(...)
		self:CreateErrorPopup(...)
	end)
end

return GUIController
