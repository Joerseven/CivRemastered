local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)
local tUtil = require(ReplicatedStorage.Util.tableUtil)
local Signal = require(ReplicatedStorage.Packages.Signal)

local TweenController = Knit.CreateController({
	Name = "TweenController",
	CreateTween = Signal.new(),
	Tweens = {},
})

local pow = math.pow
local cos = math.cos
local sin = math.sin
local PI = math.pi

local Tween = {
	_lines = {
		easeOutBack = function(x)
			local c1 = 1.70158
			local c3 = c1 + 1
			return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2)
		end,
		easeInSine = function(x)
			return 1 - cos((x * PI) / 2)
		end,
		easeInOutSine = function(x)
			return -(cos(PI * x) - 1) / 2
		end,
		easeInBack = function(x)
			local c1 = 1.70158
			local c3 = c1 + 1
			return c3 * x * x * x - c1 * x * x
		end,
		easeOutSine = function(x)
			return sin((x * PI) / 2)
		end,
	},
	_init = {
		UDim2 = function(self)
			self.oProp = self.object[self.property]

			self.cXP = self.target.X.Scale - self.oProp.X.Scale
			self.cXO = self.target.X.Offset - self.oProp.X.Offset
			self.cYP = self.target.Y.Scale - self.oProp.Y.Scale
			self.cYO = self.target.Y.Offset - self.oProp.Y.Offset
		end,
		Vector3 = function(self)
			self.oProp = self.object[self.property]

			self.cX = self.target.X - self.oProp.X
			self.cY = self.target.Y - self.oProp.Y
			self.cZ = self.target.Z - self.oProp.Z
		end,
		Color3 = function(self)
			self.oProp = self.object[self.property]
			self.cR = self.target.R - self.oProp.R
			self.cG = self.target.G - self.oProp.G
			self.cB = self.target.B - self.oProp.B
		end,
		number = function(self)
			self.oProp = self.object[self.property]
			self.c = self.target - self.oProp
		end,
	},
	_update = {
		number = function(self, factor)
			self.object[self.property] = self.oProp + self.c * factor
		end,

		UDim2 = function(self, factor)
			self.object[self.property] = UDim2.new(
				self.oProp.X.Scale + self.cXP * factor,
				self.oProp.X.Offset + self.cXO * factor,
				self.oProp.Y.Scale + self.cYP * factor,
				self.oProp.Y.Offset + self.cYO * factor
			)
		end,
		Color3 = function(self, factor)
			self.object[self.property] = Color3.new(
				self.oProp.R + self.cR * factor,
				self.oProp.G + self.cG * factor,
				self.oProp.B + self.cB * factor
			)

		end,
		Vector3 = function(self, factor)
			self.object[self.property] = Vector3.new(
				self.oProp.X + self.cX * factor,
				self.oProp.Y + self.cY * factor,
				self.oProp.Z + self.cZ * factor
			)
		end,
	},
}

Tween.__index = Tween

function Tween:Finish()
	if self.callback then
		self.callback()
	end
	self.object[self.property] = self.target
	self.finished = true
end

function Tween:_Interrupt()
	self.finished = true
end

function Tween:_CheckValid()
	if not self.object or not self.object.Parent then
		return false
	end

	return true
end

function Tween:_Update(dt)
	if self.finished then
		return
	end

	if not self:_CheckValid() then
		self:_Interrupt()
		return
	end

	self.progress = self.progress + dt

	self:updateT(self.line(self.progress / self.duration))

	if self.progress >= self.duration then
		self:Finish()
		return
	end
end

function TweenController:KnitInit() end

function TweenController:KnitStart()
	self.TweenService = Knit.GetService("TweenService")
	self.TweenService.GrowTween:Connect(function(...)
		self:GrowTile(...)
	end)
end

function TweenController:GrowTile(tile: Model, duration)
	local t = self:NewGrowTween({ object = tile, duration = duration })

	local r: Model = ReplicatedStorage.Effects.rain:Clone()
	r:PivotTo(tile:GetPivot() + Vector3.new(0, 3, 0))
	r.Parent = tile.Parent

	local destroyConnection = tile.Destroying:Connect(function()
		r:Destroy()
	end)

	r.Destroying:Connect(function()
		destroyConnection:Disconnect()
	end)

	local s: Sound = r.Cloud.RainPart.RainSound

	s.TimePosition = (math.random() * s.TimeLength) / 5
	s:Play()

	t.callback = function()
		r.Cloud.RainPart.RainParticle.Enabled = false
		TweenController:NewTween({
			object = r.Cloud.RainPart.RainSound,
			property = "Volume",
			target = 0,
			line = Tween._lines.easeOutSine,
			callback = function()
				r.Cloud.RainPart.RainSound:Stop()
			end,
		})
		TweenController:NewTween({
			object = r.Cloud,
			duration = 2,
			property = "Size",
			target = Vector3.new(0, 0, 0),
			line = Tween._lines.easeInSine,
			callback = function()
				r:Destroy()
			end,
		})
	end
end

function TweenController:RaiseTile(tile: Model, base, duration)
	tile:SetPrimaryPartCFrame(CFrame.new(tile:GetPrimaryPartCFrame().Position + Vector3.new(0, -3, 0)))

	local afterSunk = function()
		self:CFrameTween({
			object = tile,
			movement = Vector3.new(0, 3, 0),
			line = Tween._lines.easeOutSine,
		})
	end

	if base:IsA("Model") then
		self:CFrameTween({
			object = base,
			movement = Vector3.new(0, -3, 0),
			line = Tween._lines.easeOutSine,
			callback = afterSunk,
		})
	else
		self:NewTween({
			object = base,
			property = "Position",
			target = Vector3.new(base.Position.X, base.Position.Y - 0.5, base.Position.Z),
			line = Tween._lines.easeOutSine,
			callback = afterSunk,
		})
	end
end

function TweenController:WorkPulse(options)
	local t = {
		duration = 1,
		object = assert(options.object),
		initT = Tween._init.UDim2,
		updateT = Tween._update.UDim2,
		property = "Size",
		target = UDim2.fromScale(1.5, 1.5),
		finished = false,
	}

	setmetatable(t, Tween)

	t:initT()

	t._Update = function(this, dt)
		if not this:_CheckValid() then
			this:_Interrupt()
			return
		end

		this.duration -= dt * 8

		if this.duration <= -100 then
			this.duration = 1
		end

		this:updateT(1 - (sin(this.duration)) * 0.1)
	end

	t.Finish = function(this)
		this.object[this.property] = UDim2.fromScale(0.9, 0.9)
		this.finished = true
	end

	table.insert(TweenController.Tweens, t)

	return t
end

function TweenController:MultiTween(duration, ...)
	local promises = {}
	for i,v in ipairs({...}) do
		promises[i] = self:PNewTween({
			duration = duration,
			object = v.object,
			property = v.property,
			target = v.target,
			line = v.line,
		})
	end
	return Promise.all(promises)

end

function TweenController:PNewTween(options)
	return Promise.new(function(resolve, reject, onCancel)
		local t = {
			duration = options.duration or 1,
			progress = 0,
			object = assert(options.object),
			property = assert(options.property),
			target = assert(options.target),
			line = Tween._lines[options.line] or Tween._lines.easeOutSine,
			updateT = assert(Tween._update[typeof(options.target)]),
			initT = assert(Tween._init[typeof(options.target)]),
			callback = function()
				resolve()
			end,
			finished = false,
		}

		setmetatable(t, Tween)

		t:initT()

		table.insert(TweenController.Tweens, t)

		if onCancel(function()
			t:Finish()
		end) then
			return
		end
	end)
end

function TweenController:NewTween(options)
	local t = {
		duration = options.duration or 1,
		progress = 0,
		object = assert(options.object),
		property = assert(options.property),
		target = assert(options.target),
		line = Tween._lines[options.line] or Tween._lines.easeOutBack,
		updateT = assert(Tween._update[typeof(options.target)]),
		initT = assert(Tween._init[typeof(options.target)]),
		callback = options.callback or false,
		finished = false,
	}

	setmetatable(t, Tween)

	t:initT()

	table.insert(TweenController.Tweens, t)

	return t
end

function TweenController:ExtendTween() end

function TweenController:PivotTween(options)
	local t: { target: CFrame, object: Model } = {
		duration = options.duration or 1,
		progress = 0,
		object = assert(options.object),
		target = options.target,
		line = options.line or Tween._lines.easeOutSine,
		callback = options.callback,
	}

	setmetatable(t, Tween)

	t.originalPivot = t.object:GetPivot()

	function t:updateT(T)
		self.object:PivotTo(self.object:GetPivot():Lerp(self.target, T))
	end

	function t:_Interrupt() -- Make sure that the callback runs.
		self.finished = true
		if self.callback then
			self.callback()
		end
	end

	function t:Finish()
		self.finished = true
		if self.callback then
			self.callback()
		end
	end

	table.insert(TweenController.Tweens, t)

	return t
end

function TweenController:CFrameTween(options)
	local t = {
		duration = options.duration or 1,
		progress = 0,
		object = assert(options.object),
		movement = options.movement, -- As a Vector3
		line = options.line or Tween._lines.easeInOutSine,
		callback = options.callback,
	}

	setmetatable(t, Tween)

	t.originalCFrame = t.object:GetPrimaryPartCFrame()

	function t:updateT(T)
		self.object:SetPrimaryPartCFrame(
			CFrame.new(
				self.originalCFrame.Position.X + self.movement.X * T,
				self.originalCFrame.Position.Y + self.movement.Y * T,
				self.originalCFrame.Position.Z + self.movement.Z * T
			)
		)
	end

	function t:Finish()
		self.finished = true
		if self.callback then
			self.callback()
		end
	end

	table.insert(TweenController.Tweens, t)

	return t
end

function TweenController:NewGrowTween(options)
	local t = {
		duration = options.duration or 1,
		progress = 0,
		object = assert(options.object),
		line = options.line or Tween._lines.easeInOutSine,
	}

	setmetatable(t, Tween)

	t.scalePoint = t.object:GetPrimaryPartCFrame().Position
	t.parts = t.object:GetDescendants()
	t.pData = {}

	for k, v in ipairs(t.parts) do
		if v:IsA("BasePart") and v ~= t.object.PrimaryPart then
			t.pData[k] = { v.Position, v.Size, v.Position.Y - t.scalePoint.Y }
			v.Transparency = 0
			continue
		end
	end

	function t:updateT(T)
		for k, v in ipairs(self.parts) do
			if v:IsA("BasePart") and v ~= self.object.PrimaryPart then
				v.Transparency = 0
				local offset = self.pData[k][3]
				offset *= T
				v.Position = Vector3.new(v.Position.X, self.scalePoint.Y + offset, v.Position.Z)
				if v.Shape == Enum.PartType.Ball then
					v.Size = Vector3.new(self.pData[k][2].Y * T, self.pData[k][2].Y * T, self.pData[k][2].Y * T)
				else
					v.Size = Vector3.new(v.Size.X, self.pData[k][2].Y * T, v.Size.Z)
				end
			end
		end
	end

	function t:Finish()
		self.finished = true
		if self.callback then
			self.callback()
		end
	end

	table.insert(TweenController.Tweens, t)

	return t
end

function TweenController:Stepped(dt)
	for i = 1, #self.Tweens do
		local v = self.Tweens[i]

		if not v then
			break
		end

		v:_Update(dt)

		if v.finished then
			tUtil.arrayRemove(self.Tweens, i)
		end
	end
end

return TweenController
