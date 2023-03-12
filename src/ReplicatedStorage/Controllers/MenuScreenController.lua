local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Config = require(ReplicatedStorage.Modules.Config)

local MenuScreenController = Knit.CreateController({
	Name = "MenuScreenController",
	_Loading = false,
})

function MenuScreenController:ShowButtonLoaded(status)
end

function MenuScreenController:_OnLoadClick(button: TextButton, slot: number)
	local EventService = Knit.GetService("EventService")

	return function()
		if self._Loading then
			return
		end

		self._Loading = true

		EventService.LoadSave:Fire(slot)

		button.BackgroundColor3 = Color3.fromRGB(243, 173, 42)
		button.Text = "<i>Finding Save...</i>"

		function MenuScreenController:ShowButtonLoaded(status)
			button.BackgroundColor3 = Config.PositiveColor
			button.TextColor3 = Color3.new(1,1,1)
			button.Text = "No save found, Starting new!"
			if status then
				button.Text = "Save Found! Loading..."
			end
		end
		
	end
end

function MenuScreenController:RemoveMenuScreen()

	for _, v in pairs(self.buttons) do
		self.TweenController:PNewTween({
			duration = 1,
			object = v,
			property = "Transparency",
			target = 1
		}):andThen(function()
			v:Destroy()
		end)
	end

	self.TweenController:PNewTween({
		duration = 1,
		object = self.titleImage,
		property = "ImageTransparency",
		target = 1,
	}):andThen(function()
		self.titleImage:Destroy()
	end)

	return self.TweenController:PNewTween({
		duration = 2,
		object = self.Blur,
		property = "Size",
		target = 0,
	}):andThen(function()
		self.Blur:Destroy()
	end)
end

function MenuScreenController:BuildMenuScreen()
	local gui = Instance.new("ScreenGui")

	local blur = Instance.new("BlurEffect")
	blur.Enabled = true
	blur.Size = 20
	blur.Parent = Lighting
	self.Blur = blur

	local buttonPrefab = Instance.new("TextButton")
	local corners = Instance.new("UICorner")

	corners.CornerRadius = UDim.new(1)
	corners.Parent = buttonPrefab

	buttonPrefab.BackgroundColor3 = Color3.new(1, 1, 1)
	buttonPrefab.BackgroundTransparency = 0.5
	buttonPrefab.AutomaticSize = Enum.AutomaticSize.XY

	buttonPrefab.TextSize = 45
	buttonPrefab.TextColor3 = Color3.fromRGB(48, 48, 48)
	buttonPrefab.Font = Enum.Font.Nunito
	buttonPrefab.RichText = true
	buttonPrefab.AnchorPoint = Vector2.new(0.5, 0.5)

	buttonPrefab.Size = UDim2.fromScale(0.191, 0.067)

	local buttons = {}

	for i = 1, 3 do
		buttons[i] = buttonPrefab:Clone()
		buttons[i].Text = "<b>Slot " .. i .. "</b>"
		buttons[i].Position = UDim2.fromScale(0.2 + 0.3 * (i - 1), 0.8)
        buttons[i].MouseButton1Click:Connect(self:_OnLoadClick(buttons[i], i))
		buttons[i].Parent = gui
	end

	self.buttons = buttons

	local titleImage = Instance.new("ImageLabel")

	titleImage.Image = "rbxassetid://10224966784"
	titleImage.BackgroundTransparency = 1
	titleImage.ScaleType = Enum.ScaleType.Fit
	titleImage.AnchorPoint = Vector2.new(0.5, 0.5)
	titleImage.Position = UDim2.fromScale(0.5, 0.33)
	titleImage.Size = UDim2.fromScale(0.5, 0.5)

	titleImage.Parent = gui

	self.titleImage = titleImage

	return gui
end

function MenuScreenController:KnitInit() end

function MenuScreenController:KnitStart()
	self.TweenController = Knit.GetController("TweenController")
end

return MenuScreenController
