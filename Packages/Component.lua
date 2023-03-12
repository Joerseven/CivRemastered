local Component = {}

Component.__index = Component

function Component:new(component: string, parent)
	local c = {}

	c.i = Instance.new(component)
	c.i.Visible = false
	c.i.Parent = parent.IsA and parent or parent.i

	if not c.i:IsA("GuiObject") then
		error("Not a GUI Element")
	end

	setmetatable(c, self)

	return c
end

function Component:Clone()
	local c = {}
	c.i = self.i:Clone()
	c.i.Parent = self.i.Parent
	setmetatable(c, Component)
	return c
end

function Component:PositionOffset(x, y)
	self.i.Position = UDim2.new(UDim.new(self.i.Position.X.Scale, x), UDim.new(self.i.Position.Y.Scale, y))
	return self
end

function Component:CurveCorners(amount)
	local Corners = Instance.new("UICorner")
	Corners.CornerRadius = UDim.new(0, amount or self.i.Size.Y.Offset)
	Corners.Parent = self.i
	return self
end

function Component:AutoSize(axis)
	axis = axis or "XY"
	self.i.AutomaticSize = Enum.AutomaticSize[axis]
	return self
end

function Component:Center()
	self.i.AnchorPoint = Vector2.new(0.5, self.i.AnchorPoint.Y)
	self.i.Position = UDim2.new(UDim.new(0.5), self.i.Position.Y)
	return self
end

function Component:Left(padding)
	self.i.AnchorPoint = Vector2.new(0.0, self.i.AnchorPoint.Y)
	self.i.Position = UDim2.new(UDim.new(0, padding or 0), self.i.Position.Y)
	return self
end

function Component:Right(padding)
	self.i.AnchorPoint = Vector2.new(1.0, self.i.AnchorPoint.Y)
	self.i.Position = UDim2.new(UDim.new(1, padding or 0), self.i.Position.Y)
	return self
end

function Component:Top(padding)
	self.i.AnchorPoint = Vector2.new(self.i.AnchorPoint.X, 0)
	self.i.Position = UDim2.new(self.i.Position.X, UDim.new(0, padding or 0))
	return self
end

function Component:ImageColor(color: Color3)
	self.i.ImageColor3 = color
	return self
end

function Component:Constrain(axis)
	self.i.SizeConstraint = Enum.SizeConstraint.RelativeYY

	if axis == "x" then
		self.i.SizeConstraint = Enum.SizeConstraint.RelativeXX
	end

	return self
end

function Component:Clip()
	self.i.ClipsDescendants = true
	return self
end

function Component:Middle(padding)
	self.i.AnchorPoint = Vector2.new(self.i.AnchorPoint.X, 0.5)
	self.i.Position = UDim2.new(self.i.Position.X, UDim.new(0.5, padding or 0))
	return self
end

function Component:BringForward(amount)
	self.i.ZIndex = self.i.ZIndex + (amount or 1)
	return self
end

function Component:Bottom(padding)
	self.i.AnchorPoint = Vector2.new(self.i.AnchorPoint.X, 1)
	self.i.Position = UDim2.new(self.i.Position.X, UDim.new(1, padding or 0))
	return self
end

function Component:Height(height)
	self.i.Size = UDim2.new(self.i.Size.X, UDim.new(0, height))
	return self
end

function Component:Width(width)
	self.i.Size = UDim2.new(UDim2.new(0, width), self.i.Size.Y)
	return self
end

function Component:Show()
	self.i.Visible = true
	return self
end

function Component:Hide()
	self.i.Visible = false
	return self
end

function Component:Square(side)
	self.i.Size = UDim2.fromOffset(side, side)
	return self
end

function Component:RoundedSquare(size, corner)
	self.i.Size = UDim2.fromOffset(size, size)

	local c = self.i:FindFirstChild("Corners")

	if c then
		c.CornerRadius = UDim.new(0, corner or c.CornerRadius.Offset)
		return self
	end

	c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, corner or size / 4)
	c.Parent = self.i
	c.Name = "Corners"

	return self
end

function Component:RoundedRectangle(x, y, corner)
	self.i.Size = UDim2.fromOffset(x, y)

	local c = self.i:FindFirstChild("Corners")

	if c then
		c.CornerRadius = UDim.new(0, corner or c.CornerRadius.Offset)
		return self
	end

	c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, corner or x / 4)
	c.Parent = self.i
	c.Name = "Corners"

	return self
end

function Component:FlattenRound(amount, top, right, bottom, left)
end

function Component:Anchor(anchor: Vector2)
	self.i.AnchorPoint = anchor
	return self
end

function Component:Position(x, y)
	local tmpx = x == -5 and self.i.Position.X.Scale or self.i.Position.X.Scale + x
	local tmpy = y == -5 and self.i.Position.Y.Scale or self.i.Position.Y.Scale + y
	self.i.Position = UDim2.fromScale(tmpx, tmpy)
	return self
end

function Component:Circle(radius)
	self.i.Size = UDim2.fromOffset(radius, radius)

	if self.i:FindFirstChild("Corners") then
		return self
	end

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = self.i
	c.Name = "Corners"

	return self
end

function Component:RCircle(size)
	self.i.Size = UDim2.fromScale(size, size)

	if self.i:FindFirstChild("Corners") then
		return self
	end

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(size, 0)
	c.Parent = self.i
	c.Name = "Corners"

	return self
end

function Component:Bold()
	 self.i.RichText = true
	 self.i.Text = "<b>" .. self.i.Text .. "</b>"
	 return self
end

function Component:FadeBackground()
	self.i.BackgroundColor3 = Color3.new(1, 1, 1)
	self.i.BackgroundTransparency = 0.4
	return self
end

function Component:Border(size, color)
	if size then
		self.i.BorderSizePixel = size
	end

	if color then
		self.i.BorderColor3 = color
	end

	return self
end

function Component:TransparentBackground(no)
	if no then
		self.i.BackgroundTransparency = 0
		return self
	end
	self.i.BackgroundTransparency = 1
	return self
end

function Component:CenterOrigin()
	self.i.AnchorPoint = Vector2.new(0.5, 0.5)
	return self
end

function Component:Padding(top, right, bottom, left)
	local p = Instance.new("UIPadding")
	p.PaddingBottom = UDim.new(0, bottom)
	p.PaddingRight = UDim.new(0, right)
	p.PaddingLeft = UDim.new(0, left)
	p.PaddingTop = UDim.new(0, top)
	p.Parent = self.i
	return self
end

function Component:RPadding(top, right, bottom, left)
	local p = Instance.new("UIPadding")
	p.PaddingBottom = UDim.new(bottom, 0)
	p.PaddingRight = UDim.new(right, 0)
	p.PaddingLeft = UDim.new(left, 0)
	p.PaddingTop = UDim.new(top, 0)
	p.Parent = self.i
	return self
end

function Component:Text(text)
	self.i.Text = text or ""
	return self
end

function Component:Offset(x, y)
	local nx = self.i.Position.X.Offset + x
	local ny = self.i.Position.Y.Offset + y
	self.i.Position = UDim2.new(self.i.Position.X.Scale, nx, self.i.Position.Y.Scale, ny)
	return self
end

function Component:Parent(parent)
	self.Parent = parent
	return self
end

function Component:NotVisible()
	self.i.Visible = false
	self.i:SetAttribute("hideOnMount", true)
	return self
end

function Component:RSize(x, y)
	self.i.Size = UDim2.fromScale(x == -5 and self.i.Size.X.Scale or x, y == -5 and self.i.Size.Y.Scale or y)
	return self
end

function Component:Size(sx, sy, ox, oy)
	self.i.Size = UDim2.new(sx, ox, sy, oy)
	return self
end

function Component:TextColor(color)
	self.i.TextColor3 = color
	return self
end

function Component:DefaultText(text)
	self.i.PlaceholderText = text
	return self
end

function Component:ImageUrl(id)
	self.i.Image = "rbxassetid://" .. id
	return self
end

function Component:MakeList(padding, left, auto, valign)
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, padding or 0)
	list.Parent = self.i
	list.SortOrder = Enum.SortOrder.LayoutOrder

	list.FillDirection = left and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = valign or Enum.VerticalAlignment.Center
	self.i.AutomaticSize = left and Enum.AutomaticSize.X or Enum.AutomaticSize.Y
	if auto then self.i.AutomaticSize = Enum.AutomaticSize.XY end

	return self
end

function Component:BackgroundColor(color)
	self.i.BackgroundColor3 = color
	return self
end

function Component:TextAlign(align: Enum.TextXAlignment)
	self.i.TextXAlignment = align
	return self
end

function Component:Name(name)
	self.i.Name = name
	return self
end

function Component:MinSize(size)
	local s = Instance.new("UITextSizeConstraint")
	s.MaxTextSize = size
	s.Parent = self.i
	return self
end

function Component:Font(font, size)
	self.i.Font = font
	self.i.TextSize = size or 14
	return self
end

function Component:FontColor(color)
	self.i.TextColor3 = color
	return self
end

function Component:TextScaled()
	self.i.TextScaled = true
	return self
end

function Component:Mount()
	for i, v in pairs(self.i:GetDescendants()) do
		if v:IsA("GuiObject") and not v:GetAttribute("hideOnMount") then
			v.Visible = true
		end
	end
	self.i.Visible = true

	return self
end

function Component:Destroy()
	self.i:Destroy()
	
end

return Component
