local toolbar = plugin:CreateToolbar("My Plugins")
local Selection = game:GetService("Selection")

local toggleCollision =
	toolbar:CreateButton("Toggle Model Collision", "Toggle Model Collision", "rbxassetid://8740888472")
local togglePathfinding = toolbar:CreateButton(
	"Toggle Pathfinding",
	"Toggle whether pathfiding works on this model.",
	"rbxassetid://8740888472"
)

local makeUnionsUseColor =
	toolbar:CreateButton("Color Unions", "Make the unions use their part colour", "rbxassetid://8740888472")

makeUnionsUseColor.Click:Connect(function()
	local models = Selection:Get()

	for _, model in pairs(models) do
		local changed = false
		for _, v: UnionOperation in pairs(model:GetDescendants()) do
			if v:IsA("UnionOperation") then
				v.UsePartColor = true
				changed = true
			end
		end
		if changed then
			Selection:Set({model})
			plugin:PromptSaveSelection(model.Name)
		end
	end
end)

toggleCollision.Click:Connect(function()
	local model = Selection:Get()
	model = model[1]

	if not model then
		warn("Nothing selected")
		return
	end

	if model:IsA("Model") then
		for _, v: Part in pairs(model:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = false
				print("Turned off collision for: " .. v.Name)
			end
		end
		return
	end

	print("Nothing done")
end)

togglePathfinding.Click:Connect(function()
	for _, model in pairs(Selection:Get()) do
		if not model then
			warn("Nothing Selected")
		end

		if model:IsA("Model") then
			local toggle = "on"

			for _, v in pairs(model:GetDescendants()) do
				if v:IsA("PathfindingModifier") and v.Label == "NoGoZone" then
					toggle = "off"
				end
			end

			for _, v in pairs(model:GetDescendants()) do
				if toggle == "off" then
					if v:IsA("PathfindingModifier") and v.Label == "NoGoZone" then
						v:Destroy()
					end
				end

				if toggle == "on" then
					if v:IsA("BasePart") then
						local zone = Instance.new("PathfindingModifier")
						zone.Label = "NoGoZone"
						zone.Parent = v
					end
				end
			end

			print("Toggled NoPathfinding: " .. toggle)
		end
	end
end)
