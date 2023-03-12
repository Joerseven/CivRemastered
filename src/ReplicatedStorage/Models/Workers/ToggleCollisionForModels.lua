local toolbar = plugin:CreateToolbar("My Plugins")
local Selection = game:GetService("Selection")

local toggleCollision =
	toolbar:CreateButton("Toggle Model Collision", "Toggle Model Collision", "rbxassetid://8740888472")
local togglePathfinding = toolbar:CreateButton(
	"Toggle Pathfinding",
	"Toggle whether pathfiding works on this model.",
	"rbxassetid://8740888472"
)

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
	for model in pairs(Selection:Get()) do
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
