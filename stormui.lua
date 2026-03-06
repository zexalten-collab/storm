local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local StormUI = {}
StormUI.__index = StormUI
StormUI.Flags = {}
StormUI._CapturingKeybind = false

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
	local dragInput = nil
	local dragStart = nil
	local startPosition = nil

	handle.InputBegan:Connect(function(input)
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
	end)

	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and dragInput and input == dragInput then
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

	local function trimValue(value)
		return tostring(value or ""):match("^%s*(.-)%s*$")
	end

	local function normalizeKeyTextLocal(value, caseSensitive)
		local normalized = trimValue(value)
		if not caseSensitive then
			normalized = string.lower(normalized)
		end
		return normalized
	end

	local function normalizeKeyListLocal(keys, caseSensitive)
		local normalized = {}
		if typeof(keys) == "table" then
			for _, entry in ipairs(keys) do
				local textValue = normalizeKeyTextLocal(entry, caseSensitive)
				if textValue ~= "" then
					table.insert(normalized, textValue)
				end
			end
		elseif keys ~= nil then
			local textValue = normalizeKeyTextLocal(keys, caseSensitive)
			if textValue ~= "" then
				table.insert(normalized, textValue)
			end
		end
		return normalized
	end

	local title = options.Title or "Storm UI"
	local subtitle = options.Subtitle or "Advanced library"
	local toggleKey = toKeyCode(options.ToggleKey or Enum.KeyCode.RightControl) or Enum.KeyCode.RightControl
	local destroyPrevious = options.DestroyPrevious ~= false
	local windowWidth = options.Width or 760
	local windowHeight = options.Height or 520

	local showLoading = options.ShowLoadingScreen ~= false
	local loadingTitle = options.LoadingTitle or '<font color="#DE7420">NK</font> HUB'
	local loadingSubtitle = options.LoadingSubtitle or "Loading hub..."
	local loadingDuration = options.LoadingDuration or 1.1

	local keySystem = options.KeySystem or {}
	local keySystemEnabled = keySystem.Enabled == true
	local keySystemFlag = keySystem.Flag or "StormUIAccess"
	local keySystemCaseSensitive = keySystem.CaseSensitive == true
	local keySystemKeys = normalizeKeyListLocal(keySystem.Keys, keySystemCaseSensitive)
	local keySystemTitle = keySystem.Title or '<font color="#DE7420">NK</font> HUB'
	local keySystemSubtitle = keySystem.Subtitle or "Enter your access key to continue"
	local keySystemNote = keySystem.Note or "This hub is locked."
	local keySystemPlaceholder = keySystem.Placeholder or "Enter key..."
	local keySystemButtonText = keySystem.ButtonText or "Unlock"
	local keySystemSuccessText = keySystem.SuccessText or "Access granted."
	local keySystemErrorText = keySystem.ErrorText or "Invalid key."

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
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -18),
		Size = UDim2.fromOffset(340, 260),
	})
	local notificationsLayout = listLayout(notificationsHolder, 10)
	notificationsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	notificationsLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

	local introLocked = showLoading or keySystemEnabled
	local isOpen = true
	local isMinimized = false
	local keyUnlocked = not keySystemEnabled
	local lastEnteredKey = ""

	setFlag("StormUIToggleKey", toggleKey.Name)
	setFlag(keySystemFlag, keyUnlocked)

	local main = create("Frame", {
		Parent = screenGui,
		BackgroundColor3 = StormUI.Theme.Main,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(windowWidth, windowHeight),
		ClipsDescendants = true,
		Visible = not introLocked,
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
		Size = UDim2.new(1, -270, 0, 20),
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
		Size = UDim2.new(1, -270, 0, 16),
		Font = Enum.Font.Gotham,
		Text = subtitle,
		TextSize = 12,
		TextColor3 = StormUI.Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local controlsHolder = create("Frame", {
		Parent = topBar,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(72, 28),
	})

	local toggleHint = create("TextLabel", {
		Parent = topBar,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -96, 0.5, 0),
		Size = UDim2.fromOffset(150, 20),
		Font = Enum.Font.GothamSemibold,
		Text = "",
		TextSize = 12,
		TextColor3 = StormUI.Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local minimizeButton = create("TextButton", {
		Parent = controlsHolder,
		BackgroundColor3 = StormUI.Theme.Surface,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(30, 28),
		Text = "",
		AutoButtonColor = false,
	})
	corner(minimizeButton, 8)
	stroke(minimizeButton)
	bindButtonStates(minimizeButton, StormUI.Theme.Surface, StormUI.Theme.SurfaceHover, StormUI.Theme.SurfacePressed)
	create("TextLabel", {
		Parent = minimizeButton,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = "-",
		TextSize = 16,
		TextColor3 = StormUI.Theme.Text,
	})

	local closeButton = create("TextButton", {
		Parent = controlsHolder,
		BackgroundColor3 = StormUI.Theme.Surface,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(38, 0),
		Size = UDim2.fromOffset(30, 28),
		Text = "",
		AutoButtonColor = false,
	})
	corner(closeButton, 8)
	stroke(closeButton)
	bindButtonStates(closeButton, StormUI.Theme.Surface, StormUI.Theme.SurfaceHover, StormUI.Theme.SurfacePressed)
	create("TextLabel", {
		Parent = closeButton,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = "x",
		TextSize = 14,
		TextColor3 = StormUI.Theme.Text,
	})

	create("Frame", {
		Parent = main,
		BackgroundColor3 = StormUI.Theme.Stroke,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 54),
		Size = UDim2.new(1, 0, 0, 1),
	})

	local sidebarWidth = 188
	local sidebar = create("Frame", {
		Parent = main,
		BackgroundColor3 = StormUI.Theme.Sidebar,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 55),
		Size = UDim2.new(0, sidebarWidth, 1, -55),
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
	listLayout(tabScroller, 8)

	local pages = create("Frame", {
		Parent = main,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(sidebarWidth, 55),
		Size = UDim2.new(1, -sidebarWidth, 1, -55),
	})

	local restoreSize = UserInputService.TouchEnabled and 56 or 46
	local restoreButton = create("TextButton", {
		Parent = screenGui,
		Name = "RestoreButton",
		Visible = false,
		BackgroundColor3 = StormUI.Theme.Accent,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 16, 1, -16),
		Size = UDim2.fromOffset(restoreSize, restoreSize),
		Text = "",
		AutoButtonColor = false,
	})
	corner(restoreButton, 14)
	stroke(restoreButton, StormUI.Theme.Stroke, 1.1, 0)
	bindButtonStates(restoreButton, StormUI.Theme.Accent, Color3.fromRGB(235, 135, 55), Color3.fromRGB(184, 92, 21))
	create("TextLabel", {
		Parent = restoreButton,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = "UI",
		TextSize = 16,
		TextColor3 = Color3.fromRGB(255, 255, 255),
	})

	makeDraggable(topBar, main)
	makeDraggable(restoreButton, restoreButton)

	local introOverlay = nil
	local introCard = nil
	local introTitleLabel = nil
	local introSubtitleLabel = nil
	local introNoteLabel = nil
	local introStatusLabel = nil
	local keyInput = nil
	local keyActionButton = nil
	local loadingBarFill = nil

	if introLocked then
		introOverlay = create("Frame", {
			Parent = screenGui,
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.26,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 30,
		})

		introCard = create("Frame", {
			Parent = introOverlay,
			BackgroundColor3 = StormUI.Theme.Main,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(360, 220),
			ZIndex = 31,
		})
		corner(introCard, 16)
		stroke(introCard, StormUI.Theme.Stroke, 1.2, 0)
		create("Frame", {
			Parent = introCard,
			BackgroundColor3 = StormUI.Theme.Accent,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 2),
			ZIndex = 32,
		})

		introTitleLabel = create("TextLabel", {
			Parent = introCard,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(20, 24),
			Size = UDim2.new(1, -40, 0, 28),
			Font = Enum.Font.GothamBold,
			Text = loadingTitle,
			TextSize = 24,
			TextColor3 = StormUI.Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Center,
			RichText = true,
			ZIndex = 32,
		})

		introSubtitleLabel = create("TextLabel", {
			Parent = introCard,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(20, 62),
			Size = UDim2.new(1, -40, 0, 18),
			Font = Enum.Font.Gotham,
			Text = loadingSubtitle,
			TextSize = 13,
			TextColor3 = StormUI.Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 32,
		})

		introNoteLabel = create("TextLabel", {
			Parent = introCard,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(20, 92),
			Size = UDim2.new(1, -40, 0, 18),
			Font = Enum.Font.Gotham,
			Text = "",
			TextSize = 12,
			TextColor3 = StormUI.Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Center,
			Visible = false,
			ZIndex = 32,
		})

		local loadingBarBack = create("Frame", {
			Parent = introCard,
			BackgroundColor3 = StormUI.Theme.SurfaceDeep,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(28, 130),
			Size = UDim2.new(1, -56, 0, 10),
			ZIndex = 32,
		})
		corner(loadingBarBack, 999)
		stroke(loadingBarBack, StormUI.Theme.Stroke, 1, 0.45)
		loadingBarFill = create("Frame", {
			Parent = loadingBarBack,
			BackgroundColor3 = StormUI.Theme.Accent,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 0, 1, 0),
			ZIndex = 33,
		})
		corner(loadingBarFill, 999)

		keyInput = create("TextBox", {
			Parent = introCard,
			BackgroundColor3 = StormUI.Theme.SurfaceDeep,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(28, 126),
			Size = UDim2.new(1, -56, 0, 34),
			Font = Enum.Font.Gotham,
			Text = "",
			TextSize = 13,
			TextColor3 = StormUI.Theme.Text,
			PlaceholderText = keySystemPlaceholder,
			PlaceholderColor3 = StormUI.Theme.Muted,
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Left,
			Visible = false,
			ZIndex = 32,
		})
		corner(keyInput, 10)
		stroke(keyInput, StormUI.Theme.Stroke, 1, 0.25)
		padding(keyInput, 0, 10, 0, 10)

		keyActionButton = create("TextButton", {
			Parent = introCard,
			BackgroundColor3 = StormUI.Theme.Surface,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(28, 170),
			Size = UDim2.new(1, -56, 0, 34),
			Text = keySystemButtonText,
			Font = Enum.Font.GothamSemibold,
			TextSize = 13,
			TextColor3 = StormUI.Theme.Text,
			AutoButtonColor = false,
			Visible = false,
			ZIndex = 32,
		})
		corner(keyActionButton, 10)
		stroke(keyActionButton)
		bindButtonStates(keyActionButton, StormUI.Theme.Surface, StormUI.Theme.SurfaceHover, StormUI.Theme.SurfacePressed)

		introStatusLabel = create("TextLabel", {
			Parent = introCard,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 20, 1, -26),
			Size = UDim2.new(1, -40, 0, 16),
			Font = Enum.Font.Gotham,
			Text = "",
			TextSize = 12,
			TextColor3 = StormUI.Theme.Accent,
			TextXAlignment = Enum.TextXAlignment.Center,
			Visible = false,
			ZIndex = 32,
		})
	end

	local window = {}
	local currentTabButton = nil
	local pageList = {}
	local tabButtons = {}
	local customTabCount = 0
	local settingsTabButton = nil

	local function updateToggleHint()
		toggleHint.Text = "TOGGLE: " .. toggleKey.Name
	end

	local function syncVisibility()
		main.Visible = (not introLocked) and isOpen and (not isMinimized)
		restoreButton.Visible = (not introLocked) and (isMinimized or not isOpen)
	end

	local function fadeOutIntro()
		introLocked = false
		if introOverlay and introOverlay.Parent then
			tween(introCard, 0.18, {Size = UDim2.fromOffset(introCard.Size.X.Offset, 0)})
			tween(introOverlay, 0.18, {BackgroundTransparency = 1})
			task.delay(0.2, function()
				if introOverlay then
					introOverlay:Destroy()
					introOverlay = nil
				end
				syncVisibility()
			end)
		else
			syncVisibility()
		end
	end

	local function showKeyPrompt()
		if not introCard then
			return
		end
		introTitleLabel.Text = keySystemTitle
		introSubtitleLabel.Text = keySystemSubtitle
		introNoteLabel.Text = keySystemNote
		introNoteLabel.Visible = keySystemNote ~= ""
		introStatusLabel.Text = ""
		introStatusLabel.Visible = false
		introCard.Size = UDim2.fromOffset(360, 250)
		if loadingBarFill and loadingBarFill.Parent then
			loadingBarFill.Parent.Visible = false
		end
		if keyInput then
			keyInput.Visible = true
			keyInput.Text = ""
		end
		if keyActionButton then
			keyActionButton.Text = keySystemButtonText
			keyActionButton.Visible = true
		end
	end

	local function finishUnlock(message)
		keyUnlocked = true
		setFlag(keySystemFlag, true)
		if keySystem.Callback then
			pcall(keySystem.Callback, true, lastEnteredKey, message)
		end
		window:Notify({
			Title = "Access",
			Content = message or keySystemSuccessText,
			Duration = 3,
		})
		fadeOutIntro()
	end

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
		isOpen = state == true
		if isOpen then
			isMinimized = false
		end
		syncVisibility()
	end

	function window:Open()
		if introLocked then
			return
		end
		isOpen = true
		isMinimized = false
		syncVisibility()
	end

	function window:Close()
		if introLocked then
			return
		end
		isOpen = false
		isMinimized = false
		syncVisibility()
	end

	function window:Toggle()
		if introLocked then
			return
		end
		if isOpen and not isMinimized then
			isOpen = false
		else
			isOpen = true
			isMinimized = false
		end
		syncVisibility()
	end

	function window:Restore()
		if introLocked then
			return
		end
		isOpen = true
		isMinimized = false
		syncVisibility()
	end

	function window:Minimize()
		if introLocked then
			return
		end
		isOpen = true
		isMinimized = true
		syncVisibility()
	end

	function window:IsMinimized()
		return isMinimized
	end

	function window:IsOpen()
		return isOpen and not isMinimized
	end

	function window:IsUnlocked()
		return keyUnlocked
	end

	function window:SetToggleKey(newKey)
		local converted = toKeyCode(newKey)
		if converted then
			toggleKey = converted
			setFlag("StormUIToggleKey", toggleKey.Name)
			updateToggleHint()
		end
	end

	function window:GetToggleKey()
		return toggleKey
	end

	function window:SetTitle(newTitle, newSubtitle)
		titleLabel.Text = newTitle or titleLabel.Text
		if newSubtitle ~= nil then
			subtitleLabel.Text = newSubtitle
		end
	end

	function window:SubmitKey(inputValue)
		if not keySystemEnabled then
			return true, keySystemSuccessText
		end

		local cleaned = trimValue(inputValue)
		local valid = false
		local message = nil

		if keySystem.Validator then
			local success, result, responseMessage = pcall(keySystem.Validator, cleaned)
			if success then
				valid = result == true
				message = responseMessage
			else
				valid = false
				message = "Key validator error."
			end
		else
			local normalized = normalizeKeyTextLocal(cleaned, keySystemCaseSensitive)
			valid = normalized ~= "" and table.find(keySystemKeys, normalized) ~= nil
			if not valid then
				message = keySystemErrorText
			end
		end

		if valid then
			lastEnteredKey = cleaned
			if introStatusLabel then
				introStatusLabel.TextColor3 = StormUI.Theme.Accent
				introStatusLabel.Text = message or keySystemSuccessText
				introStatusLabel.Visible = true
			end
			finishUnlock(message or keySystemSuccessText)
			return true, message or keySystemSuccessText
		end

		if introStatusLabel then
			introStatusLabel.TextColor3 = Color3.fromRGB(255, 158, 158)
			introStatusLabel.Text = message or keySystemErrorText
			introStatusLabel.Visible = true
		end
		if keySystem.Callback then
			pcall(keySystem.Callback, false, cleaned, message or keySystemErrorText)
		end
		return false, message or keySystemErrorText
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
			Size = UDim2.new(1, 0, 0, 2),
		})

		local cardInner = create("Frame", {
			Parent = card,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 10),
			Size = UDim2.new(1, -28, 1, -20),
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
		local isInternalTab = tabOptions.Internal == true or tabOptions.IsSettings == true

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

		if not isInternalTab then
			customTabCount = customTabCount + 1
		end

		tabButton.MouseButton1Click:Connect(function()
			selectTab(tabButton, page)
		end)

		local tab = {}
		tab.Button = tabButton
		tab.Page = page

		function tab:Select()
			selectTab(tabButton, page)
		end

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
				local changedCallback = keybindOptions.OnChanged or keybindOptions.Changed or keybindOptions.ChangedCallback

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
					StormUI._CapturingKeybind = true
					render()
				end)

				UserInputService.InputBegan:Connect(function(input, gameProcessed)
					if waiting then
						if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
							selectedKey = input.KeyCode
							waiting = false
							StormUI._CapturingKeybind = false
							render()
							if changedCallback then
								changedCallback(selectedKey)
							end
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
						StormUI._CapturingKeybind = false
						render()
						if changedCallback then
							changedCallback(selectedKey)
						end
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
		elseif not isInternalTab and currentTabButton == settingsTabButton and customTabCount == 1 then
			selectTab(tabButton, page)
		end

		return tab
	end

	if options.IncludeSettings ~= false then
		local settingsTab = window:CreateTab({Name = options.SettingsTabName or "Settings", Internal = true})
		local settingsSection = settingsTab:CreateSection({Name = options.SettingsSectionName or "Interface"})

		settingsSection:CreateParagraph({
			Title = "Controls",
			Content = "Change the UI toggle key or hide the interface for mobile and tablet use.",
		})

		settingsSection:CreateKeybind({
			Name = "UI Toggle Key",
			CurrentKeybind = toggleKey,
			Flag = "StormUIToggleKey",
			OnChanged = function(newKey)
				window:SetToggleKey(newKey)
			end,
		})

		settingsSection:CreateButton({
			Name = "Minimize UI",
			Callback = function()
				window:Minimize()
			end,
		})

		settingsSection:CreateButton({
			Name = "Hide UI",
			Callback = function()
				window:Close()
			end,
		})

		window.SettingsTab = settingsTab
		window.SettingsSection = settingsSection
		settingsTabButton = settingsTab.Button
	end

	updateToggleHint()
	syncVisibility()

	minimizeButton.MouseButton1Click:Connect(function()
		window:Minimize()
	end)

	closeButton.MouseButton1Click:Connect(function()
		window:Close()
	end)

	restoreButton.MouseButton1Click:Connect(function()
		window:Restore()
	end)

	if keyInput then
		keyInput.FocusLost:Connect(function(enterPressed)
			if enterPressed then
				window:SubmitKey(keyInput.Text)
			end
		end)
	end

	if keyActionButton then
		keyActionButton.MouseButton1Click:Connect(function()
			window:SubmitKey(keyInput and keyInput.Text or "")
		end)
	end

	if introLocked and introOverlay then
		if showLoading and loadingBarFill then
			tween(loadingBarFill, loadingDuration, {Size = UDim2.new(1, 0, 1, 0)}, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
			task.delay(loadingDuration, function()
				if keySystemEnabled then
					showKeyPrompt()
				else
					fadeOutIntro()
				end
			end)
		elseif keySystemEnabled then
			showKeyPrompt()
		else
			fadeOutIntro()
		end
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or introLocked or StormUI._CapturingKeybind then
			return
		end

		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == toggleKey then
			window:Toggle()
		end
	end)

	return window
end

return StormUI
