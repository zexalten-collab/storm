local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local StormUI = {}
StormUI.__index = StormUI
StormUI.Flags = {}
StormUI._CapturingKeybind = false
StormUI._GlobalConnections = {}

StormUI.Theme = {
	Background = Color3.fromRGB(18, 12, 9),
	Main = Color3.fromRGB(24, 17, 13),
	Sidebar = Color3.fromRGB(20, 14, 11),
	Surface = Color3.fromRGB(33, 23, 18),
	SurfaceHover = Color3.fromRGB(41, 29, 22),
	SurfacePressed = Color3.fromRGB(49, 35, 27),
	SurfaceDeep = Color3.fromRGB(15, 11, 9),
	Stroke = Color3.fromRGB(86, 58, 40),
	Accent = Color3.fromRGB(222, 116, 32),
	AccentDark = Color3.fromRGB(163, 78, 19),
	AccentSoft = Color3.fromRGB(104, 61, 34),
	Text = Color3.fromRGB(245, 239, 234),
	Muted = Color3.fromRGB(190, 169, 154),
	Danger = Color3.fromRGB(210, 92, 72),
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

local function shallowCopyArray(array)
	local newArray = {}
	for index, value in ipairs(array or {}) do
		newArray[index] = value
	end
	return newArray
end

local function trimText(value)
	return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function setFlag(flag, value)
	if flag then
		StormUI.Flags[flag] = value
	end
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

local function normalizeKeyText(value, caseSensitive)
	local text = trimText(value)
	if not caseSensitive then
		text = string.lower(text)
	end
	return text
end

local function normalizeKeyList(keys, caseSensitive)
	local normalized = {}
	if typeof(keys) == "table" then
		for _, key in ipairs(keys) do
			local current = normalizeKeyText(key, caseSensitive)
			if current ~= "" then
				table.insert(normalized, current)
			end
		end
	elseif keys ~= nil then
		local current = normalizeKeyText(keys, caseSensitive)
		if current ~= "" then
			table.insert(normalized, current)
		end
	end
	return normalized
end

local function pushConnection(bucket, connection)
	if bucket and connection then
		table.insert(bucket, connection)
	end
	return connection
end

local function disconnectConnections(bucket)
	for _, connection in ipairs(bucket or {}) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(bucket or {})
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

local function makeDraggable(handle, target, connectionBucket)
	local dragging = false
	local dragInput = nil
	local dragStart = nil
	local startPosition = nil

	pushConnection(connectionBucket, handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragInput = input
			dragStart = input.Position
			startPosition = target.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					dragInput = nil
				end
			end)
		end
	end))

	pushConnection(connectionBucket, handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end))

	pushConnection(connectionBucket, UserInputService.InputChanged:Connect(function(input)
		if dragging and dragInput and input == dragInput then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		end
	end))
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

local function createScrollPage(parent, connectionBucket)
	local page = create("ScrollingFrame", {
		Parent = parent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = StormUI.Theme.Accent,
		Visible = false,
		AutomaticCanvasSize = Enum.AutomaticSize.None,
	})

	local content = create("Frame", {
		Parent = page,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -6, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	padding(content, 12, 14, 14, 12)
	local layout = listLayout(content, 12)

	local function syncCanvas()
		page.CanvasSize = UDim2.fromOffset(0, content.AbsoluteSize.Y + 4)
	end

	pushConnection(connectionBucket, layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(syncCanvas))
	pushConnection(connectionBucket, content:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncCanvas))
	syncCanvas()

	return page, content, syncCanvas
end

local function createPanelButton(parent, text)
	local button = create("TextButton", {
		Parent = parent,
		BackgroundColor3 = StormUI.Theme.Surface,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 42),
		AutoButtonColor = false,
		Text = "",
	})
	corner(button, 10)
	stroke(button)

	local indicator = create("Frame", {
		Parent = button,
		Name = "Indicator",
		BackgroundColor3 = StormUI.Theme.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 3, 1, 0),
	})

	local title = create("TextLabel", {
		Parent = button,
		Name = "TabTitle",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -20, 1, 0),
		Font = Enum.Font.GothamSemibold,
		Text = text,
		TextSize = 14,
		TextColor3 = StormUI.Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	button.MouseEnter:Connect(function()
		if indicator.BackgroundTransparency > 0 then
			tween(button, 0.12, {BackgroundColor3 = StormUI.Theme.SurfaceHover})
		end
	end)

	button.MouseLeave:Connect(function()
		if indicator.BackgroundTransparency > 0 then
			tween(button, 0.12, {BackgroundColor3 = StormUI.Theme.Surface})
		end
	end)

	return button
end

function StormUI:CreateWindow(options)
	options = options or {}

	disconnectConnections(StormUI._GlobalConnections)
	StormUI._GlobalConnections = {}
	local connections = StormUI._GlobalConnections

	local title = options.Title or "Storm Hub"
	local subtitle = options.Subtitle or "Dark orange interface"
	local toggleKey = toKeyCode(options.ToggleKey or Enum.KeyCode.RightControl) or Enum.KeyCode.RightControl
	local destroyPrevious = options.DestroyPrevious ~= false
	local expandedSize = options.Size or UDim2.fromOffset(760, 500)
	local expandedPosition = options.Position or UDim2.fromScale(0.5, 0.5)
	local showLoadingScreen = options.ShowLoadingScreen ~= false
	local loadingDuration = tonumber(options.LoadingDuration) or 1.1
	local loadingTitle = options.LoadingTitle or '<font color="#DE7420">NK</font> <font color="#FFFFFF">HUB</font>'
	local loadingSubtitle = options.LoadingSubtitle or "Loading hub..."
	local keySystem = options.KeySystem or {}
	local keyEnabled = keySystem.Enabled == true
	local keyCaseSensitive = keySystem.CaseSensitive == true
	local keyFlag = keySystem.Flag or "HubAccess"
	local normalizedKeys = normalizeKeyList(keySystem.Keys, keyCaseSensitive)

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

	local gateOverlay = create("Frame", {
		Parent = screenGui,
		BackgroundColor3 = Color3.fromRGB(10, 8, 7),
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 50,
	})

	local notificationsHolder = create("Frame", {
		Parent = screenGui,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -18, 1, -18),
		Size = UDim2.fromOffset(320, 320),
	})
	local notificationsLayout = listLayout(notificationsHolder, 10)
	notificationsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	notificationsLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

	local restoreButton = create("TextButton", {
		Parent = screenGui,
		BackgroundColor3 = StormUI.Theme.Surface,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 46, 1, -46),
		Size = UDim2.fromOffset(52, 52),
		AutoButtonColor = false,
		Text = "UI",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = StormUI.Theme.Text,
		Visible = false,
		ZIndex = 20,
	})
	corner(restoreButton, 12)
	stroke(restoreButton)
	bindButtonStates(restoreButton, StormUI.Theme.Surface, StormUI.Theme.SurfaceHover, StormUI.Theme.SurfacePressed)
	makeDraggable(restoreButton, restoreButton, connections)

	local main = create("Frame", {
		Parent = screenGui,
		BackgroundColor3 = StormUI.Theme.Main,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = expandedPosition,
		Size = expandedSize,
		ClipsDescendants = true,
		Visible = false,
	})
	corner(main, 16)
	stroke(main, StormUI.Theme.Stroke, 1.2, 0)

	create("Frame", {
		Parent = main,
		BackgroundColor3 = StormUI.Theme.Accent,
		BorderSizePixel = 0,
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
		Position = UDim2.fromOffset(18, 9),
		Size = UDim2.new(1, -250, 0, 22),
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
		Size = UDim2.new(1, -250, 0, 16),
		Font = Enum.Font.Gotham,
		Text = subtitle,
		TextSize = 12,
		TextColor3 = StormUI.Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local buttonX = main.AbsoluteSize.X - 34
	local closeButton = create("TextButton", {
		Parent = topBar,
		BackgroundColor3 = StormUI.Theme.Surface,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -40, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(28, 28),
		AutoButtonColor = false,
		Text = "x",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = StormUI.Theme.Text,
	})
	corner(closeButton, 8)
	stroke(closeButton, StormUI.Theme.Stroke, 1, 0.25)
	bindButtonStates(closeButton, StormUI.Theme.Surface, StormUI.Theme.SurfaceHover, StormUI.Theme.SurfacePressed)

	local minimizeButton = create("TextButton", {
		Parent = topBar,
		BackgroundColor3 = StormUI.Theme.Surface,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -74, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(28, 28),
		AutoButtonColor = false,
		Text = "-",
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = StormUI.Theme.Text,
	})
	corner(minimizeButton, 8)
	stroke(minimizeButton, StormUI.Theme.Stroke, 1, 0.25)
	bindButtonStates(minimizeButton, StormUI.Theme.Surface, StormUI.Theme.SurfaceHover, StormUI.Theme.SurfacePressed)

	local toggleHint = create("TextLabel", {
		Parent = topBar,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -94, 0.5, 0),
		Size = UDim2.fromOffset(136, 18),
		Font = Enum.Font.GothamSemibold,
		Text = "",
		TextSize = 12,
		TextColor3 = StormUI.Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local function updateToggleHint()
		toggleHint.Text = "TOGGLE: " .. toggleKey.Name
	end
	updateToggleHint()

	create("Frame", {
		Parent = main,
		BackgroundColor3 = StormUI.Theme.Stroke,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 54),
		Size = UDim2.new(1, 0, 0, 1),
	})

	local bodyClip = create("Frame", {
		Parent = main,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 55),
		Size = UDim2.new(1, 0, 1, -55),
		ClipsDescendants = true,
	})

	local sidebar = create("Frame", {
		Parent = bodyClip,
		BackgroundColor3 = StormUI.Theme.Sidebar,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 190, 1, 0),
	})

	local topTabsClip = create("Frame", {
		Parent = sidebar,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.new(1, -20, 1, -74),
		ClipsDescendants = true,
	})

	local tabScroller = create("ScrollingFrame", {
		Parent = topTabsClip,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.None,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = StormUI.Theme.Accent,
	})

	local tabButtonsContainer = create("Frame", {
		Parent = tabScroller,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -3, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	local tabButtonsLayout = listLayout(tabButtonsContainer, 8)

	local function syncTabCanvas()
		tabScroller.CanvasSize = UDim2.fromOffset(0, tabButtonsContainer.AbsoluteSize.Y + 4)
	end
	pushConnection(connections, tabButtonsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(syncTabCanvas))
	pushConnection(connections, tabButtonsContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncTabCanvas))

	local settingsSlot = create("Frame", {
		Parent = sidebar,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 10, 1, -10),
		Size = UDim2.new(1, -20, 0, 44),
	})

	local pagesHolder = create("Frame", {
		Parent = bodyClip,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(190, 0),
		Size = UDim2.new(1, -190, 1, 0),
	})

	makeDraggable(topBar, main, connections)

	local window = {}
	local destroyed = false
	local selectedEntry = nil
	local pageEntries = {}
	local normalEntries = {}
	local settingsEntry = nil
	local settingsToggleKeybind = nil
	local collapsed = false
	local animating = false
	local unlocked = not keyEnabled
	local keyPromptStatus = nil
	local keyPromptInput = nil

	setFlag("StormUIToggleKey", toggleKey.Name)
	setFlag(keyFlag, unlocked)

	local function ensureSelectedEntry()
		if selectedEntry then
			return selectedEntry
		end
		if normalEntries[1] then
			return normalEntries[1]
		end
		return settingsEntry
	end

	local function paintEntry(entry, active)
		local button = entry.Button
		local indicator = button:FindFirstChild("Indicator")
		local buttonTitle = button:FindFirstChild("TabTitle")
		if active then
			tween(button, 0.12, {BackgroundColor3 = StormUI.Theme.SurfaceHover})
			if indicator then
				tween(indicator, 0.12, {BackgroundTransparency = 0})
			end
			if buttonTitle then
				tween(buttonTitle, 0.12, {TextColor3 = StormUI.Theme.Text})
			end
		else
			tween(button, 0.12, {BackgroundColor3 = StormUI.Theme.Surface})
			if indicator then
				tween(indicator, 0.12, {BackgroundTransparency = 1})
			end
			if buttonTitle then
				tween(buttonTitle, 0.12, {TextColor3 = StormUI.Theme.Muted})
			end
		end
	end

	local function selectEntry(entry)
		if not entry then
			return
		end

		for _, entryObject in ipairs(pageEntries) do
			entryObject.Page.Visible = false
			paintEntry(entryObject, false)
		end

		entry.Page.Visible = true
		paintEntry(entry, true)
		selectedEntry = entry
	end

	local function showExpanded(animated)
		if destroyed then
			return
		end
		animating = true
		collapsed = false
		restoreButton.Visible = false
		main.Visible = true
		bodyClip.Visible = true

		if animated then
			main.Position = restoreButton.Position
			main.Size = UDim2.fromOffset(52, 52)
			bodyClip.Size = UDim2.new(1, 0, 0, 0)
			tween(main, 0.24, {Position = expandedPosition, Size = expandedSize}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			task.delay(0.04, function()
				if destroyed then
					return
				end
				tween(bodyClip, 0.2, {Size = UDim2.new(1, 0, 1, -55)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			end)
			task.delay(0.26, function()
				animating = false
			end)
		else
			main.Position = expandedPosition
			main.Size = expandedSize
			bodyClip.Size = UDim2.new(1, 0, 1, -55)
			animating = false
		end

		local preferred = ensureSelectedEntry()
		if preferred then
			selectEntry(preferred)
		end
	end

	local function collapseToButton()
		if destroyed or collapsed or animating then
			return
		end

		animating = true
		collapsed = true
		expandedPosition = main.Position
		expandedSize = main.Size
		restoreButton.Visible = true
		tween(bodyClip, 0.16, {Size = UDim2.new(1, 0, 0, 0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		tween(main, 0.22, {Position = restoreButton.Position, Size = UDim2.fromOffset(52, 52)}, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
		task.delay(0.22, function()
			if destroyed then
				return
			end
			main.Visible = false
			animating = false
		end)
	end

	function window:SetVisible(state)
		if state then
			showExpanded(true)
		else
			collapseToButton()
		end
	end

	function window:Toggle()
		if collapsed or not main.Visible then
			showExpanded(true)
		else
			collapseToButton()
		end
	end

	function window:Minimize()
		collapseToButton()
	end

	function window:Hide()
		collapseToButton()
	end

	function window:Restore()
		showExpanded(true)
	end

	function window:SetTitle(newTitle, newSubtitle)
		if newTitle ~= nil then
			titleLabel.Text = newTitle
		end
		if newSubtitle ~= nil then
			subtitleLabel.Text = newSubtitle
		end
	end

	function window:SetToggleKey(newKey, skipSync)
		local converted = toKeyCode(newKey)
		if not converted then
			return false
		end

		toggleKey = converted
		setFlag("StormUIToggleKey", toggleKey.Name)
		updateToggleHint()

		if settingsToggleKeybind and not skipSync then
			settingsToggleKeybind:Set(converted, true)
		end

		return true
	end

	function window:GetToggleKey()
		return toggleKey
	end

	function window:IsUnlocked()
		return unlocked
	end

	local function validateKey(input)
		local rawText = trimText(input)
		if rawText == "" then
			return false, keySystem.EmptyMessage or "Please enter a key."
		end

		if typeof(keySystem.Validator) == "function" then
			local ok, first, second = pcall(keySystem.Validator, rawText)
			if not ok then
				return false, keySystem.ErrorMessage or "Validation failed."
			end

			if typeof(first) == "boolean" then
				return first, second or (first and (keySystem.SuccessMessage or "Access granted.") or (keySystem.ErrorMessage or "Invalid key."))
			end

			return first == true, second or ((first == true) and (keySystem.SuccessMessage or "Access granted.") or (keySystem.ErrorMessage or "Invalid key."))
		end

		local normalizedInput = normalizeKeyText(rawText, keyCaseSensitive)
		local success = table.find(normalizedKeys, normalizedInput) ~= nil
		if success then
			return true, keySystem.SuccessMessage or "Access granted."
		end

		return false, keySystem.ErrorMessage or "Invalid key."
	end

	local function finishUnlockSequence()
		unlocked = true
		setFlag(keyFlag, true)
		gateOverlay.Visible = false
		showExpanded(false)
	end

	function window:SubmitKey(input)
		local success, message = validateKey(input)
		setFlag(keyFlag, success)
		unlocked = success

		if keyPromptStatus then
			keyPromptStatus.Text = message or ""
			keyPromptStatus.TextColor3 = success and StormUI.Theme.Accent or StormUI.Theme.Danger
		end

		if typeof(keySystem.Callback) == "function" then
			keySystem.Callback(success, trimText(input), message)
		end

		if success then
			finishUnlockSequence()
		end

		return success, message
	end

	function window:Destroy()
		if destroyed then
			return
		end
		destroyed = true
		disconnectConnections(connections)
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
			if destroyed or not card.Parent then
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

	local function createTabInternal(tabOptions)
		tabOptions = tabOptions or {}
		local tabName = tabOptions.Name or tabOptions.Title or "Tab"
		local buttonParent = tabOptions.IsSettings and settingsSlot or tabButtonsContainer
		local button = createPanelButton(buttonParent, tabName)
		local page, pageContent = createScrollPage(pagesHolder, connections)

		local entry = {
			Name = tabName,
			Button = button,
			Page = page,
			Content = pageContent,
			IsSettings = tabOptions.IsSettings == true,
		}

		table.insert(pageEntries, entry)
		if entry.IsSettings then
			settingsEntry = entry
		else
			table.insert(normalEntries, entry)
		end

		button.MouseButton1Click:Connect(function()
			selectEntry(entry)
		end)

		local tab = {}

		function tab:Select()
			selectEntry(entry)
		end

		function tab:CreateSection(sectionOptions)
			if typeof(sectionOptions) == "string" then
				sectionOptions = {Name = sectionOptions}
			end
			sectionOptions = sectionOptions or {}
			local sectionName = sectionOptions.Name or sectionOptions.Title or "Section"

			local sectionFrame = create("Frame", {
				Parent = pageContent,
				BackgroundColor3 = StormUI.Theme.Main,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				ClipsDescendants = true,
			})
			corner(sectionFrame, 12)
			stroke(sectionFrame)
			listLayout(sectionFrame, 0)

			create("Frame", {
				Parent = sectionFrame,
				BackgroundColor3 = StormUI.Theme.AccentDark,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 2),
			})

			local sectionBody = create("Frame", {
				Parent = sectionFrame,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
			})
			padding(sectionBody, 10, 12, 12, 12)
			listLayout(sectionBody, 8)

			create("TextLabel", {
				Parent = sectionBody,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 20),
				Font = Enum.Font.GothamBold,
				Text = sectionName,
				TextSize = 14,
				TextColor3 = StormUI.Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
			})

			local content = create("Frame", {
				Parent = sectionBody,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
			})
			listLayout(content, 8)

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
				local dragInput = nil

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
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = true
						dragInput = input
						setFromPosition(input.Position.X)
					end
				end)

				pushConnection(connections, UserInputService.InputChanged:Connect(function(input)
					if dragging and dragInput and input == dragInput then
						if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
							setFromPosition(input.Position.X)
						end
					end
				end))

				pushConnection(connections, UserInputService.InputEnded:Connect(function(input)
					if dragging and dragInput and input == dragInput then
						dragging = false
						dragInput = nil
					end
				end))

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
					AutomaticCanvasSize = Enum.AutomaticSize.None,
					ScrollBarThickness = 3,
					ScrollBarImageColor3 = StormUI.Theme.Accent,
				})
				corner(optionsScroll, 8)
				stroke(optionsScroll, StormUI.Theme.Stroke, 1, 0.4)

				local optionsContainer = create("Frame", {
					Parent = optionsScroll,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -6, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
				})
				padding(optionsContainer, 6, 6, 6, 6)
				local optionsLayout = listLayout(optionsContainer, 6)

				local function syncOptionsCanvas()
					optionsScroll.CanvasSize = UDim2.fromOffset(0, optionsContainer.AbsoluteSize.Y + 4)
				end
				pushConnection(connections, optionsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(syncOptionsCanvas))
				pushConnection(connections, optionsContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncOptionsCanvas))

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
					local label = button:FindFirstChild("OptionLabel")
					if isSelected(optionName) then
						tween(button, 0.12, {BackgroundColor3 = StormUI.Theme.AccentSoft})
						if label then
							tween(label, 0.12, {TextColor3 = StormUI.Theme.Text})
						end
					else
						tween(button, 0.12, {BackgroundColor3 = StormUI.Theme.Surface})
						if label then
							tween(label, 0.12, {TextColor3 = StormUI.Theme.Muted})
						end
					end
				end

				local function redrawOptions()
					for _, child in ipairs(optionsContainer:GetChildren()) do
						if child:IsA("TextButton") then
							child:Destroy()
						end
					end
					table.clear(optionButtons)

					for _, option in ipairs(optionsList) do
						local optionButton = create("TextButton", {
							Parent = optionsContainer,
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
							local optionText = tostring(option)
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
				syncOptionsCanvas()

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
					syncOptionsCanvas()
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

				local api = {}

				local function render()
					keyText.Text = waiting and "..." or selectedKey.Name
					setFlag(flag, selectedKey.Name)
					if accentEdge then
						accentEdge.BackgroundColor3 = waiting and StormUI.Theme.Accent or StormUI.Theme.AccentDark
					end
				end

				local function applyKey(newKey, fireChanged)
					local converted = toKeyCode(newKey)
					if not converted then
						return false
					end
					selectedKey = converted
					waiting = false
					StormUI._CapturingKeybind = false
					render()
					if fireChanged and keybindOptions.OnChanged then
						keybindOptions.OnChanged(selectedKey, selectedKey.Name)
					end
					return true
				end

				clickArea.MouseEnter:Connect(function()
					tween(holder, 0.12, {BackgroundColor3 = StormUI.Theme.SurfaceHover})
				end)

				clickArea.MouseLeave:Connect(function()
					tween(holder, 0.12, {BackgroundColor3 = StormUI.Theme.Surface})
				end)

				clickArea.MouseButton1Click:Connect(function()
					waiting = true
					StormUI._CapturingKeybind = true
					render()
				end)

				pushConnection(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
					if destroyed then
						return
					end

					if waiting then
						if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
							applyKey(input.KeyCode, true)
						end
						return
					end

					if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == selectedKey then
						if keybindOptions.Callback then
							keybindOptions.Callback(selectedKey.Name, selectedKey)
						end
					end
				end))

				render()

				function api:Set(newKey, suppressChanged)
					applyKey(newKey, not suppressChanged)
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
					PlaceholderText = inputOptions.Placeholder or "Type here...",
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

		if tabOptions.AutoSelect then
			selectEntry(entry)
		end

		return tab, entry
	end

	function window:CreateTab(tabOptions)
		local tab, entry = createTabInternal(tabOptions)
		if not selectedEntry or (selectedEntry and selectedEntry.IsSettings and #normalEntries == 1) then
			selectEntry(entry)
		end
		return tab
	end

	local settingsTab = nil
	do
		settingsTab = select(1, createTabInternal({Name = "Settings", IsSettings = true}))
		window.SettingsTab = settingsTab

		local controlsSection = settingsTab:CreateSection({Name = "Controls"})
		controlsSection:CreateParagraph({
			Title = "Info",
			Content = "Change the UI toggle key, minimize the interface for phone use, or hide the window and bring it back with the floating UI button.",
		})

		settingsToggleKeybind = controlsSection:CreateKeybind({
			Name = "Toggle UI Key",
			CurrentKeybind = toggleKey,
			Flag = "StormUIToggleKey",
			OnChanged = function(newKey)
				window:SetToggleKey(newKey, true)
			end,
		})

		controlsSection:CreateButton({
			Name = "Minimize UI",
			Callback = function()
				window:Minimize()
			end,
		})

		controlsSection:CreateButton({
			Name = "Hide UI",
			Callback = function()
				window:Hide()
			end,
		})
	end

	minimizeButton.MouseButton1Click:Connect(function()
		window:Minimize()
	end)

	closeButton.MouseButton1Click:Connect(function()
		window:Hide()
	end)

	restoreButton.MouseButton1Click:Connect(function()
		window:Restore()
	end)

	pushConnection(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if destroyed or StormUI._CapturingKeybind or animating then
			return
		end
		if gameProcessed then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == toggleKey then
			window:Toggle()
		end
	end))

	local function clearGate()
		for _, child in ipairs(gateOverlay:GetChildren()) do
			child:Destroy()
		end
	end

	local function buildGateCard(width, height)
		clearGate()
		gateOverlay.Visible = true
		local card = create("Frame", {
			Parent = gateOverlay,
			BackgroundColor3 = StormUI.Theme.Main,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(width, height),
		})
		corner(card, 16)
		stroke(card)
		create("Frame", {
			Parent = card,
			BackgroundColor3 = StormUI.Theme.Accent,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 2),
		})
		return card
	end

	local function showKeyPrompt()
		local card = buildGateCard(420, 250)
		local body = create("Frame", {
			Parent = card,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(18, 18),
			Size = UDim2.new(1, -36, 1, -36),
		})
		listLayout(body, 10)

		create("TextLabel", {
			Parent = body,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 26),
			Font = Enum.Font.GothamBold,
			RichText = true,
			Text = keySystem.Title or loadingTitle,
			TextSize = 22,
			TextColor3 = StormUI.Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
		})

		create("TextLabel", {
			Parent = body,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			Font = Enum.Font.Gotham,
			Text = keySystem.Subtitle or "Enter your access key to continue.",
			TextWrapped = true,
			TextSize = 13,
			TextColor3 = StormUI.Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		})

		if trimText(keySystem.Note) ~= "" then
			create("TextLabel", {
				Parent = body,
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				Font = Enum.Font.Gotham,
				Text = keySystem.Note,
				TextWrapped = true,
				TextSize = 12,
				TextColor3 = StormUI.Theme.Muted,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			})
		end

		local inputBox = create("TextBox", {
			Parent = body,
			BackgroundColor3 = StormUI.Theme.SurfaceDeep,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 36),
			Font = Enum.Font.Gotham,
			PlaceholderText = keySystem.Placeholder or "Enter key...",
			Text = "",
			TextSize = 13,
			TextColor3 = StormUI.Theme.Text,
			PlaceholderColor3 = StormUI.Theme.Muted,
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		corner(inputBox, 10)
		stroke(inputBox, StormUI.Theme.Stroke, 1, 0.2)
		padding(inputBox, 0, 10, 0, 10)

		local submitButton = create("TextButton", {
			Parent = body,
			BackgroundColor3 = StormUI.Theme.Surface,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 38),
			AutoButtonColor = false,
			Text = keySystem.ButtonText or "Continue",
			Font = Enum.Font.GothamSemibold,
			TextSize = 14,
			TextColor3 = StormUI.Theme.Text,
		})
		corner(submitButton, 10)
		stroke(submitButton)
		bindButtonStates(submitButton, StormUI.Theme.Surface, StormUI.Theme.SurfaceHover, StormUI.Theme.SurfacePressed)

		local statusLabel = create("TextLabel", {
			Parent = body,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			Font = Enum.Font.Gotham,
			Text = "",
			TextWrapped = true,
			TextSize = 12,
			TextColor3 = StormUI.Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		})

		keyPromptStatus = statusLabel
		keyPromptInput = inputBox

		local function submitCurrent()
			window:SubmitKey(inputBox.Text)
		end

		submitButton.MouseButton1Click:Connect(submitCurrent)
		inputBox.FocusLost:Connect(function(enterPressed)
			if enterPressed then
				submitCurrent()
			end
		end)
	end

	local function showLoadingCard(callback)
		if not showLoadingScreen then
			callback()
			return
		end

		local card = buildGateCard(360, 180)
		local titleText = create("TextLabel", {
			Parent = card,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(18, 22),
			Size = UDim2.new(1, -36, 0, 28),
			Font = Enum.Font.GothamBold,
			RichText = true,
			Text = loadingTitle,
			TextSize = 24,
			TextColor3 = StormUI.Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Center,
		})

		create("TextLabel", {
			Parent = card,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(18, 58),
			Size = UDim2.new(1, -36, 0, 18),
			Font = Enum.Font.Gotham,
			Text = loadingSubtitle,
			TextSize = 13,
			TextColor3 = StormUI.Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Center,
		})

		local progressBack = create("Frame", {
			Parent = card,
			BackgroundColor3 = StormUI.Theme.SurfaceDeep,
			BorderSizePixel = 0,
			Position = UDim2.new(0.5, -140, 1, -46),
			Size = UDim2.fromOffset(280, 8),
			AnchorPoint = Vector2.new(0, 0),
		})
		corner(progressBack, 999)

		local progressFill = create("Frame", {
			Parent = progressBack,
			BackgroundColor3 = StormUI.Theme.Accent,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 0, 1, 0),
		})
		corner(progressFill, 999)
		tween(progressFill, loadingDuration, {Size = UDim2.new(1, 0, 1, 0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

		task.delay(loadingDuration, function()
			if destroyed then
				return
			end
			callback()
		end)
	end

	local function startGateSequence()
		main.Visible = false
		gateOverlay.Visible = true
		showLoadingCard(function()
			if keyEnabled and not unlocked then
				showKeyPrompt()
			else
				finishUnlockSequence()
			end
		end)
	end

	task.defer(function()
		if showLoadingScreen or keyEnabled then
			startGateSequence()
		else
			showExpanded(false)
		end
	end)

	return window
end

return StormUI
