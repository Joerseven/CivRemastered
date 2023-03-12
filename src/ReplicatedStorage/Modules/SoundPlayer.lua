local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Packages.Promise)
local Sound = {}

function Sound.playSound(sound, parent, random)
	return Promise.new(function(resolve, reject)
		local s = sound:Clone()

		if random then
			s.TimePosition = (math.random() * s.TimeLength) / 5
		end

		if parent:IsA("Model") then
			s.Parent = parent.PrimaryPart
		elseif parent:IsA("Part") then
			s.Parent = parent
        end

		s.Ended:Connect(function()
			s:Destroy()
            resolve()
		end)

        s:Play()
	end)
end

return Sound
