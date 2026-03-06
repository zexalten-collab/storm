local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local StormUI = {}
StormUI.__index = StormUI
StormUI.Flags = {}

StormUI.Theme = {
	Background = Color3.fromRGB(20, 15, 12),
	Main = Color3.fromRGB(26, 20, 16),
	Sidebar = Color3.fromRGB(24, 18, 14),
	Surface = Color3.fromRGB(34, 25, 20),
	SurfaceHover = Color3.fromRGB(42, 31, 24),
	SurfacePressed = Color3.fromRGB(49, 35, 27),
	SurfaceDeep = Color3.fromRGB(18, 13, 10),
	Stroke = Color3.fromRGB(78, 55, 41),
	Accent = Color3.fromRGB(222, 116, 32),
	AccentDark = Color3.fromRGB(163, 78, 19),
	AccentSoft = Color3.fromRGB(118, 67, 38),
	Text = Color3.fromRGB(244, 238, 233),
	Muted = Color3.fromRGB(193, 171, 154),
}

local function create(className, props)
	local object = Instance.new(className)
	for key, value in pairs(props or {}) do
		if key ~= "Parent" then
			object[key] = value
		end
	end
	if props and props.Parent then
		object.Parent = props.Parent
	end
	return object
end

local function corner(object, radius)
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, radius or 10)
	uiCorner.Parent = object
	return uiCorner
end

local function stroke(object, color, thickness, transparency)
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = color or StormUI.Theme.Stroke
	uiStroke.Thickness = thickness or 1
	uiStroke.Transparency = transparency or 0
	uiStroke.Parent = object
	return uiStroke
end

local function padding(object, top, right, bottom, left)
	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingTop = UDim.new(0, top or 0)
	uiPadding.PaddingRight = UDim.new(0, right or top or 0)
	uiPadding.PaddingBottom = UDim.new(0, bottom or top or 0)
	uiPadding.PaddingLeft = UDim.new(0, left or right or top or 0)
	uiPadding.Parent = object
	return uiPadding
end

local function listLayout(object, pad)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, pad or 0)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Parent = object
	return layout
end

local function tween(object, time, properties, style, direction)
	local tweenObject = TweenService:Create(
		object,
		TweenInfo.new(time or 0.14, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
		properties
	)
	tweenObject:Play()
	return tweenObject
end

local function clamp(value, minValue, maxValue)
	return math.max(minValue, math.min(maxValue, value))
end

local function roundTo(value, minValue, increment)
	if not increment or increment <= 0 then
		return value
	end

	local steps = math.floor(((value - minValue) / increment) + 0.5)
	return minValue + (steps * increment)
end

local function formatNumber(value)
	if math.floor(value) == value then
		return tostring(value)
	end

	local text = string.format("%.2f", value)
	text = text:gsub("0+$", "")
	text = text:gsub("%.$", "")
	return text
end

local function setFlag(flag, value)
	if flag then
		StormUI.Flags[flag] = value
	end
end

local function shallowCopyArray(array)
	local newArray = {}
	for i, value in ipairs(array) do
		newArray[i] = value
	end
	return newArray
end

local function toKeyCode(key)
	if typeof(key) == "EnumItem" then
		return key
	end

	if typeof(key) == "string" then
		return Enum.KeyCode[key]
	end

	return nil
end

local function bindButtonStates(button, baseColor, hoverColor, pressedColor)
	button.MouseEnter:Connect(function()
		tween(button, 0.12, {BackgroundColor3 = hoverColor or baseColor})
	end)

	button.MouseLeave:Connect(function()
		tween(button, 0.12, {BackgroundColor3 = baseColor})
	end)

	button.MouseButton1Down:Connect(function()
		tween(button, 0.08, {BackgroundColor3 = pressedColor or hoverColor or baseColor})
	end)

	button.MouseButton1Up:Connect(function()
		tween(button, 0.12, {BackgroundColor3 = hoverColor or baseColor})
	end)
end

local function makeDraggable(handle, target)
	local dragging = false
	local dragStart = nil
	local startPosition = nil

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPosition = target.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		end
	end)
end

local function makeComponentFrame(parent, height, clipsDescendants)
	local frame = create("Frame", {
		Parent = parent,
		BackgroundColor3 = StormUI.Theme.Surface,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, height),
		ClipsDescendants = clipsDescendants == true,
	})
	corner(frame, 10)
	stroke(frame)

	create("Frame", {
		Parent = frame,
		Name = "AccentEdge",
		BackgroundColor3 = StormUI.Theme.AccentDark,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 3, 1, 0),
	})

	local inner = create("Frame", {
		Parent = frame,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -28, 1, 0),
	})

	return frame, inner
end

function StormUI:CreateWindow(options)
	options = options or {}

	local title = options.Title or "Storm UI"
	local subtitle = options.Subtitle or "advanced library"
	local toggleKey = options.ToggleKey or Enum.KeyCode.RightControl
	local destroyPrevious = options.DestroyPrevious ~= false

	if destroyPrevious then
		local existing = PlayerGui:FindFirstChild("StormUILibrary")
		if existing then
			existing:Destroy()
		end
	end

	local screenGui = create("ScreenGui", {
		Parent = PlayerGui,
		Name = "StormUILibrary",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})

	local notificationsHolder = create("Frame", {
		Parent = screenGui,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -18, 0, 18),
		Size = UDim2.fromOffset(320, 500),
	})
	local notificationsLayout = listLayout(notificationsHolder, 10)
	notificationsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	notificationsLayout.VerticalAlignment = Enum.VerticalAlignment.Top

	local main = create("Frame", {
		Parent = screenGui,
		BackgroundColor3 = StormUI.Theme.Main,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(860, 560),
		ClipsDescendants = true,
	})
	corner(main, 16)
	stroke(main, StormUI.Theme.Stroke, 1.2, 0)

	create("Frame", {
		Parent = main,
		BackgroundColor3 = StormUI.Theme.Accent,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, 0, 0, 2),
	})

	local topBar = create("Frame", {
		Parent = main,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 54),
	})

	local titleLabel = create("TextLabel", {
		Parent = topBar,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 10),
		Size = UDim2.new(1, -220, 0, 20),
		Font = Enum.Font.GothamBold,
		Text = title,
		TextSize = 18,
		TextColor3 = StormUI.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local subtitleLabel = create("TextLabel", {
		Parent = topBar,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 28),
		Size = UDim2.new(1, -220, 0, 16),
		Font = Enum.Font.Gotham,
		Text = subtitle,
		TextSize = 12,
		TextColor3 = StormUI.Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local toggleHint = create("TextLabel", {
		Parent = topBar,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -18, 0.5, 0),
		Size = UDim2.fromOffset(150, 20),
		Font = Enum.Font.GothamSemibold,
		Text = "TOGGLE : " .. toggleKey.Name,
		TextSize = 12,
		TextColor3 = StormUI.Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	create("Frame", {
		Parent = main,
		BackgroundColor3 = StormUI.Theme.Stroke,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 54),
		Size = UDim2.new(1, 0, 0, 1),
	})

	local sidebar = create("Frame", {
		Parent = main,
		BackgroundColor3 = StormUI.Theme.Sidebar,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 55),
		Size = UDim2.new(0, 198, 1, -55),
	})

	create("Frame", {
		Parent = sidebar,
		BackgroundColor3 = StormUI.Theme.AccentDark,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(0, 3, 1, 0),
	})

	local tabScroller = create("ScrollingFrame", {
		Parent = sidebar,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.new(1, -20, 1, -20),
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = StormUI.Theme.Accent,
	})
	padding(tabScroller, 0, 2, 0, 0)
	local tabLayout = listLayout(tabScroller, 8)

	local pages = create("Frame", {
		Parent = main,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(198, 55),
		Size = UDim2.new(1, -198, 1, -55),
	})

	makeDraggable(topBar, main)

	local window = {}
	local currentTabButton = nil
	local pageList = {}
	local tabButtons = {}
	local windowVisible = true

	local function selectTab(tabButton, page)
		for _, pageObject in ipairs(pageList) do
			pageObject.Visible = false
		end

		for _, buttonObject in ipairs(tabButtons) do
			local indicator = buttonObject:FindFirstChild("Indicator")
			if indicator then
				tween(indicator, 0.12, {BackgroundTransparency = 1})
			end
			tween(buttonObject, 0.12, {BackgroundColor3 = StormUI.Theme.Surface})
			local buttonTitle = buttonObject:FindFirstChild("TabTitle")
			if buttonTitle then
				tween(buttonTitle, 0.12, {TextColor3 = StormUI.Theme.Muted})
			end
		end

		page.Visible = true
		currentTabButton = tabButton
		tween(tabButton, 0.12, {BackgroundColor3 = StormUI.Theme.SurfaceHover})
		local currentIndicator = tabButton:FindFirstChild("Indicator")
		if currentIndicator then
			tween(currentIndicator, 0.12, {BackgroundTransparency = 0})
		end
		local titleObject = tabButton:FindFirstChild("TabTitle")
		if titleObject then
			tween(titleObject, 0.12, {TextColor3 = StormUI.Theme.Text})
		end
	end

	function window:SetVisible(state)
		windowVisible = state == true
		main.Visible = windowVisible
	end

	function window:Toggle()
		windowVisible = not windowVisible
		main.Visible = windowVisible
	end

	function window:SetTitle(newTitle, newSubtitle)
		titleLabel.Text = newTitle or titleLabel.Text
		if newSubtitle ~= nil then
			subtitleLabel.Text = newSubtitle
		end
	end

	function window:Destroy()
		screenGui:Destroy()
	end

	function window:Notify(notificationOptions)
		notificationOptions = notificationOptions or {}
		local notifTitle = notificationOptions.Title or "Notification"
		local notifText = notificationOptions.Content or notificationOptions.Text or ""
		local duration = notificationOptions.Duration or 4
		local notifHeight = notifText ~= "" and 82 or 60

		local card = create("Frame", {
			Parent = notificationsHolder,
			BackgroundColor3 = StormUI.Theme.Surface,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 0),
			ClipsDescendants = true,
		})
		corner(card, 12)
		stroke(card)

		create("Frame", {
			Parent = card,
			BackgroundColor3 = StormUI.Theme.Accent,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 4, 1, 0),
		})

		local cardInner = create("Frame", {
			Parent = card,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 10),
			Size = UDim2.new(1, -26, 1, -20),
		})

		create("TextLabel", {
			Parent = cardInner,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			Font = Enum.Font.GothamBold,
			Text = notifTitle,
			TextSize = 14,
			TextColor3 = StormUI.Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
		})

		create("TextLabel", {
			Parent = cardInner,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 22),
			Size = UDim2.new(1, 0, 1, -22),
			Font = Enum.Font.Gotham,
			Text = notifText,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextSize = 12,
			TextColor3 = StormUI.Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Left,
		})

		tween(card, 0.18, {Size = UDim2.new(1, 0, 0, notifHeight)})

		task.delay(duration, function()
			if not card.Parent then
				return
			end
			tween(card, 0.18, {Size = UDim2.new(1, 0, 0, 0)})
			task.delay(0.2, function()
				if card then
					card:Destroy()
				end
			end)
		end)
	end

	function window:CreateTab(tabOptions)
		tabOptions = tabOptions or {}
		local tabName = tabOptions.Name or tabOptions.Title or "Tab"

		local tabButton = create("TextButton", {
			Parent = tabScroller,
			BackgroundColor3 = StormUI.Theme.Surface,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 42),
			AutoButtonColor = false,
			Text = "",
		})
		corner(tabButton, 10)
		stroke(tabButton)

		local indicator = create("Frame", {
			Parent = tabButton,
			Name = "Indicator",
			BackgroundColor3 = StormUI.Theme.Accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 3, 1, 0),
		})

		create("TextLabel", {
			Parent = tabButton,
			Name = "TabTitle",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 0),
			Size = UDim2.new(1, -20, 1, 0),
			Font = Enum.Font.GothamSemibold,
			Text = tabName,
			TextSize = 14,
			TextColor3 = StormUI.Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Left,
		})

		tabButton.MouseEnter:Connect(function()
			if currentTabButton ~= tabButton then
				tween(tabButton, 0.12, {BackgroundColor3 = StormUI.Theme.SurfaceHover})
			end
		end)

		tabButton.MouseLeave:Connect(function()
			if currentTabButton ~= tabButton then
				tween(tabButton, 0.12, {BackgroundColor3 = StormUI.Theme.Surface})
			end
		end)

		local page = create("ScrollingFrame", {
			Parent = pages,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = StormUI.Theme.Accent,
			Visible = false,
		})
		padding(page, 14, 14, 14, 14)
		listLayout(page, 12)

		table.insert(pageList, page)
		table.insert(tabButtons, tabButton)

		tabButton.MouseButton1Click:Connect(function()
			selectTab(tabButton, page)
		end)

		local tab = {}

		function tab:CreateSection(sectionOptions)
			if typeof(sectionOptions) == "string" then
				sectionOptions = {Name = sectionOptions}
			end
			sectionOptions = sectionOptions or {}
			local sectionName = sectionOptions.Name or sectionOptions.Title or "Section"

			local sectionFrame = create("Frame", {
				Parent = page,
				BackgroundColor3 = StormUI.Theme.Main,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
			})
			corner(sectionFrame, 12)
			stroke(sectionFrame)

			create("Frame", {
				Parent = sectionFrame,
				BackgroundColor3 = StormUI.Theme.AccentDark,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(0, 0),
				Size = UDim2.new(1, 0, 0, 2),
			})

			local header = create("TextLabel", {
				Parent = sectionFrame,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(14, 12),
				Size = UDim2.new(1, -28, 0, 20),
				Font = Enum.Font.GothamBold,
				Text = sectionName,
				TextSize = 14,
				TextColor3 = StormUI.Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
			})

			local content = create("Frame", {
				Parent = sectionFrame,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(12, 40),
				Size = UDim2.new(1, -24, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
			})
			listLayout(content, 8)
			padding(content, 0, 0, 12, 0)

			local section = {}

			function section:CreateLabel(labelOptions)
				if typeof(labelOptions) == "string" then
					labelOptions = {Text = labelOptions}
				end
				labelOptions = labelOptions or {}

				local frame, inner = makeComponentFrame(content, 36, false)
				frame.BackgroundColor3 = StormUI.Theme.SurfaceDeep
				local textLabel = create("TextLabel", {
					Parent = inner,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Font = Enum.Font.Gotham,
					Text = labelOptions.Text or labelOptions.Name or "Label",
					TextSize = 13,
					TextColor3 = StormUI.Theme.Muted,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				local api = {}
				function api:Set(newText)
					textLabel.Text = newText
				end
				function api:Get()
					return textLabel.Text
				end
				return api
			end

			function section:CreateParagraph(paragraphOptions)
				paragraphOptions = paragraphOptions or {}
				local paragraphFrame = create("Frame", {
					Parent = content,
					BackgroundColor3 = StormUI.Theme.Surface,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
				})
				corner(paragraphFrame, 10)
				stroke(paragraphFrame)
				create("Frame", {
					Parent = paragraphFrame,
					BackgroundColor3 = StormUI.Theme.AccentDark,
					BorderSizePixel = 0,
					Size = UDim2.new(0, 3, 1, 0),
				})
				padding(paragraphFrame, 10, 12, 10, 14)
				listLayout(paragraphFrame, 6)

				local titleText = create("TextLabel", {
					Parent = paragraphFrame,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 18),
					Font = Enum.Font.GothamBold,
					Text = paragraphOptions.Title or "Paragraph",
					TextSize = 14,
					TextColor3 = StormUI.Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				local contentText = create("TextLabel", {
					Parent = paragraphFrame,
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.new(1, 0, 0, 0),
					Font = Enum.Font.Gotham,
					Text = paragraphOptions.Content or paragraphOptions.Text or "",
					TextWrapped = true,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextSize = 12,
					TextColor3 = StormUI.Theme.Muted,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				local api = {}
				function api:Set(newTitle, newText)
					if newTitle ~= nil then
						titleText.Text = newTitle
					end
					if newText ~= nil then
						contentText.Text = newText
					end
				end
				return api
			end

			function section:CreateButton(buttonOptions)
				buttonOptions = buttonOptions or {}
				local button = create("TextButton", {
					Parent = content,
					BackgroundColor3 = StormUI.Theme.Surface,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 42),
					AutoButtonColor = false,
					Text = "",
				})
				corner(button, 10)
				stroke(button)
				create("Frame", {
					Parent = button,
					Name = "AccentEdge",
					BackgroundColor3 = StormUI.Theme.AccentDark,
					BorderSizePixel = 0,
					Size = UDim2.new(0, 3, 1, 0),
				})
				local inner = create("Frame", {
					Parent = button,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(14, 0),
					Size = UDim2.new(1, -28, 1, 0),
				})

				local titleObject = create("TextLabel", {
					Parent = inner,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -20, 1, 0),
					Font = Enum.Font.GothamSemibold,
					Text = buttonOptions.Name or buttonOptions.Title or "Button",
					TextSize = 14,
					TextColor3 = StormUI.Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				create("TextLabel", {
					Parent = inner,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.fromOffset(18, 18),
					Font = Enum.Font.GothamBold,
					Text = ">",
					TextSize = 14,
					TextColor3 = StormUI.Theme.Accent,
					TextXAlignment = Enum.TextXAlignment.Right,
				})

				bindButtonStates(button, StormUI.Theme.Surface, StormUI.Theme.SurfaceHover, StormUI.Theme.SurfacePressed)

				button.MouseButton1Click:Connect(function()
					if buttonOptions.Callback then
						buttonOptions.Callback()
					end
				end)

				local api = {}
				function api:Set(newText)
					titleObject.Text = newText
				end
				return api
			end

			function section:CreateToggle(toggleOptions)
				toggleOptions = toggleOptions or {}
				local state = toggleOptions.CurrentValue == true
				local flag = toggleOptions.Flag

				local holder = create("TextButton", {
					Parent = content,
					BackgroundColor3 = StormUI.Theme.Surface,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 48),
					AutoButtonColor = false,
					Text = "",
				})
				corner(holder, 10)
				stroke(holder)

				local accentEdge = create("Frame", {
					Parent = holder,
					Name = "AccentEdge",
					BackgroundColor3 = StormUI.Theme.AccentDark,
					BorderSizePixel = 0,
					Size = UDim2.new(0, 3, 1, 0),
				})

				local inner = create("Frame", {
					Parent = holder,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(14, 0),
					Size = UDim2.new(1, -28, 1, 0),
				})

				create("TextLabel", {
					Parent = inner,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -72, 1, 0),
					Font = Enum.Font.GothamSemibold,
					Text = toggleOptions.Name or "Toggle",
					TextSize = 14,
					TextColor3 = StormUI.Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				local track = create("Frame", {
					Parent = inner,
					BackgroundColor3 = StormUI.Theme.Stroke,
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.fromOffset(46, 24),
				})
				corner(track, 999)

				local knob = create("Frame", {
					Parent = track,
					BackgroundColor3 = Color3.fromRGB(255, 248, 242),
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 2, 0.5, 0),
					Size = UDim2.fromOffset(20, 20),
				})
				corner(knob, 999)

				local stateText = create("TextLabel", {
					Parent = inner,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -56, 0.5, 0),
					Size = UDim2.fromOffset(36, 20),
					Font = Enum.Font.GothamBold,
					Text = "OFF",
					TextSize = 11,
					TextColor3 = StormUI.Theme.Muted,
					TextXAlignment = Enum.TextXAlignment.Right,
				})

				local function renderToggle(doCallback)
					if state then
						tween(track, 0.12, {BackgroundColor3 = StormUI.Theme.Accent})
						tween(knob, 0.12, {Position = UDim2.new(0, 24, 0.5, 0)})
						tween(accentEdge, 0.12, {BackgroundColor3 = StormUI.Theme.Accent})
						stateText.Text = "ON"
						stateText.TextColor3 = StormUI.Theme.Accent
					else
						tween(track, 0.12, {BackgroundColor3 = StormUI.Theme.Stroke})
						tween(knob, 0.12, {Position = UDim2.new(0, 2, 0.5, 0)})
						tween(accentEdge, 0.12, {BackgroundColor3 = StormUI.Theme.AccentDark})
						stateText.Text = "OFF"
						stateText.TextColor3 = StormUI.Theme.Muted
					end

					setFlag(flag, state)
					if doCallback and toggleOptions.Callback then
						toggleOptions.Callback(state)
					end
				end

				holder.MouseEnter:Connect(function()
					tween(holder, 0.12, {BackgroundColor3 = StormUI.Theme.SurfaceHover})
				end)

				holder.MouseLeave:Connect(function()
					tween(holder, 0.12, {BackgroundColor3 = StormUI.Theme.Surface})
				end)

				holder.MouseButton1Click:Connect(function()
					state = not state
					renderToggle(true)
				end)

				renderToggle(false)

				local api = {}
				function api:Set(value)
					state = value == true
					renderToggle(true)
				end
				function api:Get()
					return state
				end
				return api
			end

			function section:CreateSlider(sliderOptions)
				sliderOptions = sliderOptions or {}
				local minValue = sliderOptions.Min or sliderOptions.Minimum or 0
				local maxValue = sliderOptions.Max or sliderOptions.Maximum or 100
				local increment = sliderOptions.Increment or 1
				local suffix = sliderOptions.Suffix or ""
				local flag = sliderOptions.Flag
				local currentValue = clamp(sliderOptions.CurrentValue or minValue, minValue, maxValue)
				local dragging = false

				local holder, inner = makeComponentFrame(content, 58, false)

				create("TextLabel", {
					Parent = inner,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(0, 6),
					Size = UDim2.new(1, -90, 0, 18),
					Font = Enum.Font.GothamSemibold,
					Text = sliderOptions.Name or "Slider",
					TextSize = 14,
					TextColor3 = StormUI.Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				local valueText = create("TextLabel", {
					Parent = inner,
					BackgroundColor3 = StormUI.Theme.SurfaceDeep,
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, 0, 0, 2),
					Size = UDim2.fromOffset(78, 22),
					Font = Enum.Font.GothamSemibold,
					Text = "",
					TextSize = 12,
					TextColor3 = StormUI.Theme.Accent,
				})
				corner(valueText, 8)
				stroke(valueText, StormUI.Theme.Stroke, 1, 0.3)

				local bar = create("Frame", {
					Parent = inner,
					BackgroundColor3 = StormUI.Theme.SurfaceDeep,
					BorderSizePixel = 0,
					Position = UDim2.fromOffset(0, 38),
					Size = UDim2.new(1, 0, 0, 6),
				})
				corner(bar, 999)

				local fill = create("Frame", {
					Parent = bar,
					BackgroundColor3 = StormUI.Theme.Accent,
					BorderSizePixel = 0,
					Size = UDim2.new(0, 0, 1, 0),
				})
				corner(fill, 999)

				local knob = create("Frame", {
					Parent = bar,
					BackgroundColor3 = Color3.fromRGB(255, 248, 242),
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.fromOffset(14, 14),
				})
				corner(knob, 999)

				local function renderSlider(doCallback)
					currentValue = clamp(roundTo(currentValue, minValue, increment), minValue, maxValue)
					local alpha = 0
					if maxValue ~= minValue then
						alpha = (currentValue - minValue) / (maxValue - minValue)
					end
					alpha = clamp(alpha, 0, 1)
					fill.Size = UDim2.new(alpha, 0, 1, 0)
					knob.Position = UDim2.new(alpha, 0, 0.5, 0)
					valueText.Text = formatNumber(currentValue) .. suffix
					setFlag(flag, currentValue)
					if doCallback and sliderOptions.Callback then
						sliderOptions.Callback(currentValue)
					end
				end

				local function setFromPosition(positionX)
					local alpha = clamp((positionX - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
					currentValue = minValue + ((maxValue - minValue) * alpha)
					renderSlider(true)
				end

				bar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = true
						setFromPosition(input.Position.X)
					end
				end)

				UserInputService.InputChanged:Connect(function(input)
					if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
						setFromPosition(input.Position.X)
					end
				end)

				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = false
					end
				end)

				renderSlider(false)

				local api = {}
				function api:Set(value)
					currentValue = value
					renderSlider(true)
				end
				function api:Get()
					return currentValue
				end
				return api
			end

			function section:CreateDropdown(dropdownOptions)
				dropdownOptions = dropdownOptions or {}
				local optionsList = {}
				for _, option in ipairs(dropdownOptions.Options or {}) do
					table.insert(optionsList, tostring(option))
				end
				local multi = dropdownOptions.Multi == true
				local flag = dropdownOptions.Flag
				local opened = false
				local optionButtons = {}
				local currentValue

				if multi then
					currentValue = {}
					if typeof(dropdownOptions.CurrentOption) == "table" then
						for _, value in ipairs(dropdownOptions.CurrentOption) do
							table.insert(currentValue, tostring(value))
						end
					end
				else
					local startValue = dropdownOptions.CurrentOption or dropdownOptions.CurrentValue or optionsList[1]
					currentValue = startValue and tostring(startValue) or nil
				end

				local holder = create("Frame", {
					Parent = content,
					BackgroundColor3 = StormUI.Theme.Surface,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 46),
					ClipsDescendants = true,
				})
				corner(holder, 10)
				stroke(holder)

				local accentEdge = create("Frame", {
					Parent = holder,
					BackgroundColor3 = StormUI.Theme.AccentDark,
					BorderSizePixel = 0,
					Size = UDim2.new(0, 3, 1, 0),
				})

				local headerButton = create("TextButton", {
					Parent = holder,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 46),
					AutoButtonColor = false,
					Text = "",
				})

				local headerInner = create("Frame", {
					Parent = holder,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(14, 0),
					Size = UDim2.new(1, -28, 0, 46),
				})

				create("TextLabel", {
					Parent = headerInner,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(0, 0),
					Size = UDim2.new(1, -120, 1, 0),
					Font = Enum.Font.GothamSemibold,
					Text = dropdownOptions.Name or "Dropdown",
					TextSize = 14,
					TextColor3 = StormUI.Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				local selectedText = create("TextLabel", {
					Parent = headerInner,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -22, 0.5, 0),
					Size = UDim2.fromOffset(150, 18),
					Font = Enum.Font.Gotham,
					Text = "",
					TextSize = 12,
					TextColor3 = StormUI.Theme.Muted,
					TextXAlignment = Enum.TextXAlignment.Right,
				})

				local arrow = create("TextLabel", {
					Parent = headerInner,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.fromOffset(14, 14),
					Font = Enum.Font.GothamBold,
					Text = "v",
					TextSize = 12,
					TextColor3 = StormUI.Theme.Accent,
				})

				local listHolder = create("Frame", {
					Parent = holder,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(10, 46),
					Size = UDim2.new(1, -20, 0, 0),
					ClipsDescendants = true,
				})

				local optionsScroll = create("ScrollingFrame", {
					Parent = listHolder,
					BackgroundColor3 = StormUI.Theme.SurfaceDeep,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 1, 0),
					CanvasSize = UDim2.new(),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollBarThickness = 3,
					ScrollBarImageColor3 = StormUI.Theme.Accent,
				})
				corner(optionsScroll, 8)
				stroke(optionsScroll, StormUI.Theme.Stroke, 1, 0.4)
				padding(optionsScroll, 6, 6, 6, 6)
				local optionsLayout = listLayout(optionsScroll, 6)

				local function isSelected(option)
					if multi then
						return table.find(currentValue, option) ~= nil
					end
					return currentValue == option
				end

				local function updateSelectedText()
					if multi then
						if #currentValue == 0 then
							selectedText.Text = "None"
						else
							selectedText.Text = table.concat(currentValue, ", ")
						end
						setFlag(flag, shallowCopyArray(currentValue))
					else
						selectedText.Text = tostring(currentValue or "None")
						setFlag(flag, currentValue)
					end
				end

				local function getOpenHeight()
					local rawHeight = (#optionsList * 34) + 14
					return math.min(rawHeight, 156)
				end

				local function refreshOptionVisual(button)
					local optionName = button:GetAttribute("OptionName")
					if isSelected(optionName) then
						tween(button, 0.12, {BackgroundColor3 = StormUI.Theme.AccentSoft})
						local label = button:FindFirstChild("OptionLabel")
						if label then
							tween(label, 0.12, {TextColor3 = StormUI.Theme.Text})
						end
					else
						tween(button, 0.12, {BackgroundColor3 = StormUI.Theme.Surface})
						local label = button:FindFirstChild("OptionLabel")
						if label then
							tween(label, 0.12, {TextColor3 = StormUI.Theme.Muted})
						end
					end
				end

				local function redrawOptions()
					for _, child in ipairs(optionsScroll:GetChildren()) do
						if child:IsA("TextButton") then
							child:Destroy()
						end
					end
					table.clear(optionButtons)

					for _, option in ipairs(optionsList) do
						local optionButton = create("TextButton", {
							Parent = optionsScroll,
							BackgroundColor3 = StormUI.Theme.Surface,
							BorderSizePixel = 0,
							Size = UDim2.new(1, 0, 0, 28),
							AutoButtonColor = false,
							Text = "",
						})
						optionButton:SetAttribute("OptionName", tostring(option))
						corner(optionButton, 8)
						stroke(optionButton, StormUI.Theme.Stroke, 1, 0.55)

						create("TextLabel", {
							Parent = optionButton,
							Name = "OptionLabel",
							BackgroundTransparency = 1,
							Position = UDim2.fromOffset(10, 0),
							Size = UDim2.new(1, -20, 1, 0),
							Font = Enum.Font.Gotham,
							Text = tostring(option),
							TextSize = 12,
							TextColor3 = StormUI.Theme.Muted,
							TextXAlignment = Enum.TextXAlignment.Left,
						})

						optionButton.MouseEnter:Connect(function()
							if not isSelected(option) then
								tween(optionButton, 0.12, {BackgroundColor3 = StormUI.Theme.SurfaceHover})
							end
						end)

						optionButton.MouseLeave:Connect(function()
							refreshOptionVisual(optionButton)
						end)

						optionButton.MouseButton1Click:Connect(function()
							local optionText = option
							if multi then
								local index = table.find(currentValue, optionText)
								if index then
									table.remove(currentValue, index)
								else
									table.insert(currentValue, optionText)
								end
								updateSelectedText()
								for _, buttonObject in ipairs(optionButtons) do
									refreshOptionVisual(buttonObject)
								end
								if dropdownOptions.Callback then
									dropdownOptions.Callback(shallowCopyArray(currentValue))
								end
							else
								currentValue = optionText
								updateSelectedText()
								for _, buttonObject in ipairs(optionButtons) do
									refreshOptionVisual(buttonObject)
								end
								if dropdownOptions.Callback then
									dropdownOptions.Callback(currentValue)
								end
								opened = false
								local openHeight = getOpenHeight()
								tween(holder, 0.16, {Size = UDim2.new(1, 0, 0, 46)})
								tween(listHolder, 0.16, {Size = UDim2.new(1, -20, 0, 0)})
								tween(accentEdge, 0.12, {BackgroundColor3 = StormUI.Theme.AccentDark})
								arrow.Text = "v"
							end
						end)

						refreshOptionVisual(optionButton)
						table.insert(optionButtons, optionButton)
					end
				end

				local function setOpened(state)
					opened = state
					local openHeight = getOpenHeight()
					if opened then
						tween(holder, 0.16, {Size = UDim2.new(1, 0, 0, 46 + openHeight + 8)})
						tween(listHolder, 0.16, {Size = UDim2.new(1, -20, 0, openHeight)})
						tween(accentEdge, 0.12, {BackgroundColor3 = StormUI.Theme.Accent})
						arrow.Text = "^"
					else
						tween(holder, 0.16, {Size = UDim2.new(1, 0, 0, 46)})
						tween(listHolder, 0.16, {Size = UDim2.new(1, -20, 0, 0)})
						tween(accentEdge, 0.12, {BackgroundColor3 = StormUI.Theme.AccentDark})
						arrow.Text = "v"
					end
				end

				headerButton.MouseEnter:Connect(function()
					tween(holder, 0.12, {BackgroundColor3 = StormUI.Theme.SurfaceHover})
				end)

				headerButton.MouseLeave:Connect(function()
					tween(holder, 0.12, {BackgroundColor3 = StormUI.Theme.Surface})
				end)

				headerButton.MouseButton1Click:Connect(function()
					setOpened(not opened)
				end)

				redrawOptions()
				updateSelectedText()

				local api = {}
				function api:Refresh(newOptions)
					optionsList = {}
					for _, option in ipairs(newOptions or {}) do
						table.insert(optionsList, tostring(option))
					end
					if multi then
						local filtered = {}
						for _, selected in ipairs(currentValue) do
							if table.find(optionsList, tostring(selected)) then
								table.insert(filtered, tostring(selected))
							end
						end
						currentValue = filtered
					else
						if currentValue and not table.find(optionsList, tostring(currentValue)) then
							currentValue = optionsList[1]
						end
					end
					redrawOptions()
					updateSelectedText()
					if opened then
						setOpened(true)
					end
				end
				function api:Set(value)
					if multi then
						currentValue = {}
						for _, selected in ipairs(value or {}) do
							table.insert(currentValue, tostring(selected))
						end
					else
						currentValue = value ~= nil and tostring(value) or nil
					end
					updateSelectedText()
					for _, buttonObject in ipairs(optionButtons) do
						refreshOptionVisual(buttonObject)
					end
					if dropdownOptions.Callback then
						if multi then
							dropdownOptions.Callback(shallowCopyArray(currentValue))
						else
							dropdownOptions.Callback(currentValue)
						end
					end
				end
				function api:Get()
					if multi then
						return shallowCopyArray(currentValue)
					end
					return currentValue
				end
				return api
			end

			function section:CreateKeybind(keybindOptions)
				keybindOptions = keybindOptions or {}
				local selectedKey = toKeyCode(keybindOptions.CurrentKeybind or keybindOptions.Default or Enum.KeyCode.RightShift) or Enum.KeyCode.RightShift
				local waiting = false
				local flag = keybindOptions.Flag

				local holder, inner = makeComponentFrame(content, 46, false)
				local accentEdge = holder:FindFirstChild("AccentEdge")

				create("TextLabel", {
					Parent = inner,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -120, 1, 0),
					Font = Enum.Font.GothamSemibold,
					Text = keybindOptions.Name or "Keybind",
					TextSize = 14,
					TextColor3 = StormUI.Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				local keyText = create("TextLabel", {
					Parent = inner,
					BackgroundColor3 = StormUI.Theme.SurfaceDeep,
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.fromOffset(88, 24),
					Font = Enum.Font.GothamBold,
					Text = selectedKey.Name,
					TextSize = 11,
					TextColor3 = StormUI.Theme.Accent,
				})
				corner(keyText, 8)
				stroke(keyText, StormUI.Theme.Stroke, 1, 0.3)

				local clickArea = create("TextButton", {
					Parent = holder,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Text = "",
					AutoButtonColor = false,
				})

				local function render()
					keyText.Text = waiting and "..." or selectedKey.Name
					setFlag(flag, selectedKey.Name)
					if accentEdge then
						accentEdge.BackgroundColor3 = waiting and StormUI.Theme.Accent or StormUI.Theme.AccentDark
					end
				end

				clickArea.MouseEnter:Connect(function()
					tween(holder, 0.12, {BackgroundColor3 = StormUI.Theme.SurfaceHover})
				end)

				clickArea.MouseLeave:Connect(function()
					tween(holder, 0.12, {BackgroundColor3 = StormUI.Theme.Surface})
				end)

				clickArea.MouseButton1Click:Connect(function()
					waiting = true
					render()
				end)

				UserInputService.InputBegan:Connect(function(input, gameProcessed)
					if waiting then
						if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
							selectedKey = input.KeyCode
							waiting = false
							render()
						end
						return
					end

					if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == selectedKey then
						if keybindOptions.Callback then
							keybindOptions.Callback(selectedKey.Name)
						end
					end
				end)

				render()

				local api = {}
				function api:Set(newKey)
					local converted = toKeyCode(newKey)
					if converted then
						selectedKey = converted
						waiting = false
						render()
					end
				end
				function api:Get()
					return selectedKey
				end
				return api
			end

			function section:CreateInput(inputOptions)
				inputOptions = inputOptions or {}
				local flag = inputOptions.Flag
				local holder, inner = makeComponentFrame(content, 60, false)
				local accentEdge = holder:FindFirstChild("AccentEdge")

				create("TextLabel", {
					Parent = inner,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(0, 6),
					Size = UDim2.new(1, 0, 0, 16),
					Font = Enum.Font.GothamSemibold,
					Text = inputOptions.Name or "Input",
					TextSize = 14,
					TextColor3 = StormUI.Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				local box = create("TextBox", {
					Parent = inner,
					BackgroundColor3 = StormUI.Theme.SurfaceDeep,
					BorderSizePixel = 0,
					Position = UDim2.fromOffset(0, 28),
					Size = UDim2.new(1, 0, 0, 22),
					Font = Enum.Font.Gotham,
					PlaceholderText = inputOptions.Placeholder or "type here...",
					Text = tostring(inputOptions.CurrentValue or ""),
					TextSize = 12,
					TextColor3 = StormUI.Theme.Text,
					PlaceholderColor3 = StormUI.Theme.Muted,
					ClearTextOnFocus = false,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				corner(box, 8)
				stroke(box, StormUI.Theme.Stroke, 1, 0.35)
				padding(box, 0, 8, 0, 8)

				setFlag(flag, box.Text)

				box.Focused:Connect(function()
					if accentEdge then
						tween(accentEdge, 0.12, {BackgroundColor3 = StormUI.Theme.Accent})
					end
				end)

				box.FocusLost:Connect(function(enterPressed)
					if accentEdge then
						tween(accentEdge, 0.12, {BackgroundColor3 = StormUI.Theme.AccentDark})
					end
					setFlag(flag, box.Text)
					if inputOptions.Callback then
						inputOptions.Callback(box.Text, enterPressed)
					end
				end)

				local api = {}
				function api:Set(value)
					box.Text = tostring(value)
					setFlag(flag, box.Text)
				end
				function api:Get()
					return box.Text
				end
				return api
			end

			section.CreateTextbox = section.CreateInput

			return section
		end

		if not currentTabButton then
			selectTab(tabButton, page)
		end

		return tab
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == toggleKey then
			window:Toggle()
		end
	end)

	return window
end

return StormUI
