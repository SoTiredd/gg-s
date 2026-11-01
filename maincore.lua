--[[
    VantaUI --- GTA V Corner Mod Menu Suite (Clean Edition)
    Flow: Animated Pre-Login Loader -> Key Verification Login -> Decrypt -> Corner WASD Menu
    Controls:
      [W / Up]       : Previous Item
      [S / Down]     : Next Item
      [A / Left]     : Adjust Slider Down / Previous Option
      [D / Right]    : Adjust Slider Up / Next Option
      [Enter / Space]: Select / Toggle / Trigger Action
      [Q / E]        : Switch Between Tabs
      [Insert / F4]  : Hide / Show Corner Menu
      + Full Mouse Click & Hover Support
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Vanta = {
	Version = "2.1.0",
	Flags = {},
	CurrentMenu = nil,
	ScreenGui = nil,
	NotificationContainer = nil,
	Open = true,
	ToggleKey = Enum.KeyCode.Insert,
}

-- [1] THEME PALETTE
local Theme = {
	Accent = Color3.fromRGB(168, 85, 247), -- Purple/Violet GTA V mod menu accent
	AccentDark = Color3.fromRGB(120, 50, 185),
	AccentGlow = Color3.fromRGB(192, 132, 252),
	Background = Color3.fromRGB(13, 14, 18),
	Banner = Color3.fromRGB(18, 14, 25),
	Header = Color3.fromRGB(20, 22, 28),
	SubHeader = Color3.fromRGB(16, 17, 22),
	Row = Color3.fromRGB(18, 20, 26),
	RowSelected = Color3.fromRGB(168, 85, 247),
	RowSelectedText = Color3.fromRGB(255, 255, 255),
	Border = Color3.fromRGB(36, 40, 52),
	BorderLight = Color3.fromRGB(55, 60, 78),
	Text = Color3.fromRGB(240, 243, 248),
	TextMuted = Color3.fromRGB(145, 153, 168),
	TextDark = Color3.fromRGB(90, 96, 110),
	Success = Color3.fromRGB(46, 204, 113),
	Warning = Color3.fromRGB(241, 196, 15),
	Error = Color3.fromRGB(231, 76, 60),
	ToggleOn = Color3.fromRGB(46, 204, 113),
	ToggleOff = Color3.fromRGB(50, 55, 68),
}
Vanta.Theme = Theme

-- [2] INTERNAL UTILITY HELPERS
local function Create(className, properties, children)
	local inst = Instance.new(className)
	for prop, val in pairs(properties or {}) do
		if prop ~= "Parent" then
			pcall(function() inst[prop] = val end)
		end
	end
	for _, child in ipairs(children or {}) do
		if typeof(child) == "Instance" then
			child.Parent = inst
		end
	end
	if properties and properties.Parent then
		inst.Parent = properties.Parent
	end
	return inst
end

local function Tween(instance, properties, duration, style, direction)
	local tw = TweenService:Create(instance, TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), properties)
	tw:Play()
	return tw
end

local function GetSafeGuiParent()
	if gethui then
		local s, r = pcall(gethui)
		if s and r then return r end
	end
	local s, cg = pcall(function() return CoreGui:FindFirstChild("RobloxGui") or CoreGui end)
	if s and cg then return cg end
	if LocalPlayer then
		local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if pg then return pg end
	end
	return CoreGui
end

local function Shake(frame, originPos)
	task.spawn(function()
		local steps = { -10, 8, -6, 4, -2, 0 }
		for _, offset in ipairs(steps) do
			Tween(frame, { Position = UDim2.new(originPos.X.Scale, originPos.X.Offset + offset, originPos.Y.Scale, originPos.Y.Offset) }, 0.04)
			task.wait(0.04)
		end
	end)
end

-- [3] SCREEN GUI INITIALIZATION
function Vanta:InitRoot()
	if self.ScreenGui and self.ScreenGui.Parent then return end
	
	local existing = GetSafeGuiParent():FindFirstChild("VantaSuite_Root")
	if existing then existing:Destroy() end
	
	local screenGui = Create("ScreenGui", {
		Name = "VantaSuite_Root",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 9999,
		Parent = GetSafeGuiParent(),
	})
	
	if syn and syn.protect_gui then
		pcall(syn.protect_gui, screenGui)
	elseif typeof(protectgui) == "function" then
		pcall(protectgui, screenGui)
	end
	
	-- Toast notifications container (Bottom-Right)
	local notifs = Create("Frame", {
		Name = "Notifications",
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -320, 1, -20),
		AnchorPoint = Vector2.new(0, 1),
		Size = UDim2.new(0, 300, 1, -40),
		ZIndex = 1000,
		Parent = screenGui,
	})
	Create("UIListLayout", {
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = notifs,
	})
	
	self.ScreenGui = screenGui
	self.NotificationContainer = notifs
	
	-- Global Toggle Key (Insert / F4)
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe and UserInputService:GetFocusedTextBox() then return end
		if input.KeyCode == self.ToggleKey then
			self:Toggle()
		end
	end)
end

-- [4] NOTIFICATIONS
function Vanta:Notify(config)
	self:InitRoot()
	config = config or {}
	local title = config.Title or "NOTIFICATION"
	local content = config.Content or ""
	local duration = config.Duration or 3.5
	local notifType = config.Type or "Info"
	
	local accent = notifType == "Success" and Theme.Success or notifType == "Warning" and Theme.Warning or notifType == "Error" and Theme.Error or Theme.Accent
	
	local card = Create("Frame", {
		BackgroundColor3 = Theme.Header,
		Size = UDim2.new(1, 0, 0, 54),
		ClipsDescendants = true,
		Parent = self.NotificationContainer,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = card })
	Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = card })
	
	-- Left Accent Indicator
	Create("Frame", {
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 4, 1, 0),
		Parent = card,
	})
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = string.upper(title),
		TextColor3 = accent,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 12, 0, 8),
		Size = UDim2.new(1, -20, 0, 14),
		Parent = card,
	})
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = content,
		TextColor3 = Theme.Text,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 12, 0, 24),
		Size = UDim2.new(1, -20, 0, 24),
		Parent = card,
	})
	
	task.delay(duration, function()
		if card and card.Parent then
			local tw = Tween(card, { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0) }, 0.22)
			tw.Completed:Connect(function() card:Destroy() end)
		end
	end)
end

-- [5] PRE-LOGIN LOADING + AUTHENTICATION PIPELINE
function Vanta:StartAuthPipeline(config, onAuthenticated)
	self:InitRoot()
	config = config or {}
	local title = config.Title or "VANTA // SUITE"
	local validKeys = config.Keys or { "vanta-vip", "free", "test" }
	local keyLink = config.KeyLink or "https://discord.gg/vibe"
	local saveFile = config.SaveKeyName or "VantaLicense.txt"
	
	-- Backdrop
	local backdrop = Create("Frame", {
		Name = "AuthBackdrop",
		BackgroundColor3 = Color3.fromRGB(4, 5, 8),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 2000,
		Parent = self.ScreenGui,
	})
	Tween(backdrop, { BackgroundTransparency = 0.4 }, 0.3)
	
	-- Central Card
	local card = Create("Frame", {
		Name = "PipelineCard",
		BackgroundColor3 = Theme.Background,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 360, 0, 190),
		ClipsDescendants = true,
		Parent = backdrop,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = card })
	local cardStroke = Create("UIStroke", { Color = Theme.Border, Thickness = 1.2, Parent = card })
	
	-- Accent Top Line
	local topLine = Create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 3),
		Parent = card,
	})
	
	-- Drop Shadow
	Create("ImageLabel", {
		BackgroundTransparency = 1,
		Image = "rbxassetid://6015897843",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 0.35,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		Position = UDim2.new(0, -20, 0, -20),
		Size = UDim2.new(1, 40, 1, 40),
		ZIndex = card.ZIndex - 1,
		Parent = card,
	})
	
	-- Card Header
	local headerLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = string.upper(title),
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBlack,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.new(0, 0, 0, 18),
		Size = UDim2.new(1, 0, 0, 20),
		Parent = card,
	})
	
	local subLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "INITIALIZING CORE SYSTEM",
		TextColor3 = Theme.Accent,
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.new(0, 0, 0, 38),
		Size = UDim2.new(1, 0, 0, 14),
		Parent = card,
	})
	
	---------------------------------------------------------------------
	-- STAGE 1: LOADING (RUNS BEFORE LOGIN AS REQUESTED)
	---------------------------------------------------------------------
	local loadContainer = Create("Frame", {
		Name = "Stage1_Loader",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 24, 0, 68),
		Size = UDim2.new(1, -48, 1, -80),
		Parent = card,
	})
	
	local loadStatus = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "[1/3] CONNECTING TO SECURE AUTH SERVER...",
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.new(0, 0, 0, 10),
		Size = UDim2.new(1, 0, 0, 18),
		Parent = loadContainer,
	})
	
	local loadTrack = Create("Frame", {
		BackgroundColor3 = Theme.Header,
		Position = UDim2.new(0, 0, 0, 42),
		Size = UDim2.new(1, 0, 0, 8),
		Parent = loadContainer,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = loadTrack })
	
	local loadFill = Create("Frame", {
		BackgroundColor3 = Theme.Accent,
		Size = UDim2.new(0, 0, 1, 0),
		Parent = loadTrack,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = loadFill })
	
	---------------------------------------------------------------------
	-- STAGE 2: LOGIN WINDOW (SHOWN AFTER PRE-LOADER FINISHES)
	---------------------------------------------------------------------
	local loginContainer = Create("Frame", {
		Name = "Stage2_Login",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 24, 0, 68),
		Size = UDim2.new(1, -48, 1, -80),
		Visible = false,
		Parent = card,
	})
	
	local boxBg = Create("Frame", {
		BackgroundColor3 = Theme.Header,
		Position = UDim2.new(0, 0, 0, 4),
		Size = UDim2.new(1, 0, 0, 36),
		Parent = loginContainer,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = boxBg })
	Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = boxBg })
	
	local keyBox = Create("TextBox", {
		BackgroundTransparency = 1,
		PlaceholderText = "Paste license key here...",
		PlaceholderColor3 = Theme.TextDark,
		TextColor3 = Theme.Text,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		Text = "",
		ClearTextOnFocus = false,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -70, 1, 0),
		Parent = boxBg,
	})
	
	local pasteBtn = Create("TextButton", {
		Text = "PASTE",
		TextColor3 = Theme.Accent,
		Font = Enum.Font.GothamBold,
		TextSize = 9,
		BackgroundColor3 = Theme.SubHeader,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.new(0, 48, 0, 24),
		AutoButtonColor = false,
		Parent = boxBg,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = pasteBtn })
	pasteBtn.MouseButton1Click:Connect(function()
		pcall(function()
			if getclipboard then keyBox.Text = getclipboard() end
		end)
	end)
	
	local getBtn = Create("TextButton", {
		Text = "GET KEY",
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		BackgroundColor3 = Theme.Header,
		Position = UDim2.new(0, 0, 0, 48),
		Size = UDim2.new(0.48, 0, 0, 32),
		AutoButtonColor = false,
		Parent = loginContainer,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = getBtn })
	Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = getBtn })
	
	local unlockBtn = Create("TextButton", {
		Text = "UNLOCK",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		BackgroundColor3 = Theme.Accent,
		Position = UDim2.new(0.52, 0, 0, 48),
		Size = UDim2.new(0.48, 0, 0, 32),
		AutoButtonColor = false,
		Parent = loginContainer,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = unlockBtn })
	
	getBtn.MouseButton1Click:Connect(function()
		if setclipboard then
			setclipboard(keyLink)
			Vanta:Notify({ Title = "Link Copied", Content = keyLink, Type = "Info", Duration = 3.5 })
		else
			Vanta:Notify({ Title = "Key Link", Content = keyLink, Type = "Info", Duration = 4 })
		end
	end)
	
	-- Auto-check saved key from disk
	pcall(function()
		if readfile and isfile and isfile(saveFile) then
			local saved = readfile(saveFile)
			if saved and saved ~= "" then keyBox.Text = saved end
		end
	end)
	
	-- Run Stage 1 Loading -> then Transition to Login
	task.spawn(function()
		local preStages = {
			{ Text = "[1/3] CONNECTING TO SECURE AUTH SERVER...", Pct = 0.35, Dur = 0.4 },
			{ Text = "[2/3] FETCHING HARDWARE MANIFEST...", Pct = 0.70, Dur = 0.45 },
			{ Text = "[3/3] MOUNTING AUTHENTICATION GATE...", Pct = 1.00, Dur = 0.35 },
		}
		for _, st in ipairs(preStages) do
			loadStatus.Text = st.Text
			Tween(loadFill, { Size = UDim2.new(st.Pct, 0, 1, 0) }, st.Dur, Enum.EasingStyle.Sine)
			task.wait(st.Dur + 0.08)
		end
		
		task.wait(0.2)
		subLbl.Text = "LICENSE VERIFICATION"
		loadContainer.Visible = false
		loginContainer.Visible = true
		Tween(card, { Size = UDim2.new(0, 360, 0, 185) }, 0.2)
	end)
	
	-- Verification Logic
	local function AttemptUnlock()
		local entered = keyBox.Text:gsub("%s+", "")
		local isValid = false
		for _, k in ipairs(validKeys) do
			if entered == k then
				isValid = true
				break
			end
		end
		
		if isValid then
			pcall(function()
				if writefile then writefile(saveFile, entered) end
			end)
			
			-- Stage 3: Instant Decrypt & Finish
			loginContainer.Visible = false
			loadContainer.Visible = true
			subLbl.Text = "ACCESS GRANTED"
			subLbl.TextColor3 = Theme.Success
			loadStatus.Text = "DECRYPTING CORNER MENU MODULES..."
			loadStatus.TextColor3 = Theme.Success
			loadFill.BackgroundColor3 = Theme.Success
			loadFill.Size = UDim2.new(0, 0, 1, 0)
			Tween(loadFill, { Size = UDim2.new(1, 0, 1, 0) }, 0.4, Enum.EasingStyle.Sine)
			
			task.wait(0.5)
			Tween(card, { Size = UDim2.new(0, 380, 0, 200), BackgroundTransparency = 1 }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			local tw = Tween(backdrop, { BackgroundTransparency = 1 }, 0.3)
			tw.Completed:Connect(function()
				backdrop:Destroy()
				if onAuthenticated then onAuthenticated() end
			end)
		else
			Shake(card, UDim2.new(0.5, 0, 0.5, 0))
			Tween(cardStroke, { Color = Theme.Error }, 0.1)
			Vanta:Notify({ Title = "Invalid License", Content = "The key entered is invalid.", Type = "Error", Duration = 3 })
			task.delay(0.6, function()
				Tween(cardStroke, { Color = Theme.Border }, 0.25)
			end)
		end
	end
	
	unlockBtn.MouseButton1Click:Connect(AttemptUnlock)
	keyBox.FocusLost:Connect(function(enter)
		if enter then AttemptUnlock() end
	end)
end

-- [6] GTA V CORNER MENU
local Menu = {}
Menu.__index = Menu

function Vanta:CreateMenu(config)
	self:InitRoot()
	config = config or {}
	local title = config.Title or "VANTA"
	local subTitle = config.SubTitle or "GTA V CORNER SUITE"
	local toggleKey = config.ToggleKey or Enum.KeyCode.Insert
	local useKeySystem = config.KeySystem ~= nil
	self.ToggleKey = toggleKey
	
	local menu = setmetatable({
		Title = title,
		SubTitle = subTitle,
		Tabs = {},
		ActiveTabIndex = 1,
		ActiveRowIndex = 1,
		Flags = self.Flags,
	}, Menu)
	self.CurrentMenu = menu
	
	-- Corner Root Frame (Top-Left Dock)
	local root = Create("Frame", {
		Name = "VantaGTAV_Menu",
		BackgroundColor3 = Theme.Background,
		Position = UDim2.new(0, 20, 0, 20),
		Size = UDim2.new(0, 320, 0, 460),
		ClipsDescendants = true,
		Parent = self.ScreenGui,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = root })
	Create("UIStroke", { Color = Theme.Border, Thickness = 1.2, Parent = root })
	
	-- Shadow
	Create("ImageLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		Image = "rbxassetid://6015897843",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 0.35,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		Position = UDim2.new(0, -18, 0, -18),
		Size = UDim2.new(1, 36, 1, 36),
		ZIndex = root.ZIndex - 1,
		Parent = root,
	})
	menu.RootFrame = root
	
	-- 1. GTA V BANNER HEADER
	local banner = Create("Frame", {
		Name = "Banner",
		BackgroundColor3 = Theme.Banner,
		Size = UDim2.new(1, 0, 0, 68),
		Parent = root,
	})
	Create("Frame", { BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 3), Parent = banner })
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = string.upper(title),
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBlack,
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 16, 0, 14),
		Size = UDim2.new(1, -32, 0, 24),
		Parent = banner,
	})
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = string.upper(subTitle),
		TextColor3 = Theme.Accent,
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 16, 0, 40),
		Size = UDim2.new(1, -32, 0, 14),
		Parent = banner,
	})
	
	-- 2. TAB SELECTOR BAR (Q / E)
	local tabSelector = Create("Frame", {
		Name = "TabSelector",
		BackgroundColor3 = Theme.SubHeader,
		Position = UDim2.new(0, 0, 0, 68),
		Size = UDim2.new(1, 0, 0, 32),
		Parent = root,
	})
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "[Q]",
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		Position = UDim2.new(0, 6, 0, 0),
		Size = UDim2.new(0, 24, 1, 0),
		Parent = tabSelector,
	})
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "[E]",
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		Position = UDim2.new(1, -30, 0, 0),
		Size = UDim2.new(0, 24, 1, 0),
		Parent = tabSelector,
	})
	
	local curTabLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "TAB",
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.new(0, 32, 0, 0),
		Size = UDim2.new(1, -64, 1, 0),
		Parent = tabSelector,
	})
	menu.CurrentTabLabel = curTabLbl
	
	-- 3. SUBHEADER BREADCRUMB & COUNTER
	local subHeader = Create("Frame", {
		Name = "SubHeader",
		BackgroundColor3 = Theme.Header,
		Position = UDim2.new(0, 0, 0, 100),
		Size = UDim2.new(1, 0, 0, 24),
		Parent = root,
	})
	
	local pathLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "MENU",
		TextColor3 = Theme.Accent,
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(0.6, 0, 1, 0),
		Parent = subHeader,
	})
	menu.PathLabel = pathLbl
	
	local counterLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "1 / 1",
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(0.6, 0, 0, 0),
		Size = UDim2.new(0.4, -12, 1, 0),
		Parent = subHeader,
	})
	menu.CounterLabel = counterLbl
	
	-- 4. ITEMS CONTAINER
	local itemsFrame = Create("ScrollingFrame", {
		Name = "Items",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.BorderLight,
		Position = UDim2.new(0, 0, 0, 124),
		Size = UDim2.new(1, 0, 0, 248),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = root,
	})
	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0), Parent = itemsFrame })
	menu.ItemsContainer = itemsFrame
	
	-- 5. TOOLTIP / DESCRIPTION FOOTER BOX
	local footerBox = Create("Frame", {
		Name = "Footer",
		BackgroundColor3 = Theme.SubHeader,
		Position = UDim2.new(0, 0, 1, -54),
		Size = UDim2.new(1, 0, 0, 34),
		Parent = root,
	})
	Create("Frame", { BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1), Parent = footerBox })
	
	local descLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "Select an item to view description.",
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 12, 0, 4),
		Size = UDim2.new(1, -24, 1, -8),
		Parent = footerBox,
	})
	menu.DescLabel = descLbl
	
	-- 6. KEYBOARD LEGEND BAR
	local legendBar = Create("Frame", {
		Name = "Legend",
		BackgroundColor3 = Theme.Background,
		Position = UDim2.new(0, 0, 1, -20),
		Size = UDim2.new(1, 0, 0, 20),
		Parent = root,
	})
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "[W/S] Move   [A/D] Adjust   [Enter] Select   [Q/E] Tabs",
		TextColor3 = Theme.TextDark,
		Font = Enum.Font.GothamBold,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 1, 0),
		Parent = legendBar,
	})
	
	menu:SetupInputHooks()
	
	-- Pre-Login Loading Pipeline
	if useKeySystem then
		root.Position = UDim2.new(0, -340, 0, 20)
		Vanta:StartAuthPipeline(config.KeySystem, function()
			Tween(root, { Position = UDim2.new(0, 20, 0, 20) }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end)
	else
		-- Direct slide-in
		Tween(root, { Position = UDim2.new(0, 20, 0, 20) }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end
	
	return menu
end

-- Backward compatibility alias
function Vanta:CreateWindow(config)
	return self:CreateMenu(config)
end

function Vanta:Toggle()
	self.Open = not self.Open
	if self.CurrentMenu and self.CurrentMenu.RootFrame then
		local frame = self.CurrentMenu.RootFrame
		if self.Open then
			frame.Visible = true
			Tween(frame, { Position = UDim2.new(0, 20, 0, 20) }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		else
			local tw = Tween(frame, { Position = UDim2.new(0, -340, 0, 20) }, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			tw.Completed:Connect(function()
				if not self.Open then frame.Visible = false end
			end)
		end
	end
end

-- [7] WASD / ARROW INPUT HOOKS
function Menu:SetupInputHooks()
	UserInputService.InputBegan:Connect(function(input, gpe)
		if (gpe and UserInputService:GetFocusedTextBox()) or not Vanta.Open then return end
		
		local currentTab = self.Tabs[self.ActiveTabIndex]
		local count = currentTab and #currentTab.Rows or 0
		
		if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up then
			if count > 0 then
				self.ActiveRowIndex = self.ActiveRowIndex - 1
				if self.ActiveRowIndex < 1 then self.ActiveRowIndex = count end
				self:UpdateSelection()
			end
		elseif input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.Down then
			if count > 0 then
				self.ActiveRowIndex = self.ActiveRowIndex + 1
				if self.ActiveRowIndex > count then self.ActiveRowIndex = 1 end
				self:UpdateSelection()
			end
		elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
			if currentTab and currentTab.Rows[self.ActiveRowIndex] then
				local row = currentTab.Rows[self.ActiveRowIndex]
				if row.OnLeft then row:OnLeft() end
			end
		elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
			if currentTab and currentTab.Rows[self.ActiveRowIndex] then
				local row = currentTab.Rows[self.ActiveRowIndex]
				if row.OnRight then row:OnRight() end
			end
		elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Space then
			if currentTab and currentTab.Rows[self.ActiveRowIndex] then
				local row = currentTab.Rows[self.ActiveRowIndex]
				if row.OnActivate then row:OnActivate() end
			end
		elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.LeftBracket then
			if #self.Tabs > 1 then
				local newIdx = self.ActiveTabIndex - 1
				if newIdx < 1 then newIdx = #self.Tabs end
				self:SelectTab(newIdx)
			end
		elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.RightBracket then
			if #self.Tabs > 1 then
				local newIdx = self.ActiveTabIndex + 1
				if newIdx > #self.Tabs then newIdx = 1 end
				self:SelectTab(newIdx)
			end
		end
	end)
end

function Menu:UpdateSelection()
	local currentTab = self.Tabs[self.ActiveTabIndex]
	if not currentTab then return end
	local rows = currentTab.Rows
	self.CounterLabel.Text = tostring(self.ActiveRowIndex) .. " / " .. tostring(#rows)
	
	for idx, row in ipairs(rows) do
		local isSel = (idx == self.ActiveRowIndex)
		if row.SetSelected then row:SetSelected(isSel) end
		if isSel then self.DescLabel.Text = row.Description or (row.Title .. " option") end
	end
end

-- [8] TAB & CONTROLS CLASS
local Tab = {}
Tab.__index = Tab

function Menu:CreateTab(config)
	config = config or {}
	local title = config.Title or config.Name or "TAB"
	local tab = setmetatable({ Title = title, Menu = self, Rows = {} }, Tab)
	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 then self:SelectTab(1) end
	return tab
end

function Menu:SelectTab(index)
	self.ActiveTabIndex = index
	self.ActiveRowIndex = 1
	local tab = self.Tabs[index]
	if not tab then return end
	
	self.CurrentTabLabel.Text = string.upper(tab.Title)
	self.PathLabel.Text = string.upper(self.Title) .. " > " .. string.upper(tab.Title)
	
	for _, child in ipairs(self.ItemsContainer:GetChildren()) do
		if child:IsA("GuiObject") then child.Visible = false end
	end
	for _, row in ipairs(tab.Rows) do
		if row.Frame then row.Frame.Visible = true end
	end
	self:UpdateSelection()
end

function Tab:CreateSection(title)
	self:AddSeparator({ Title = title })
	return self
end

function Tab:AddSeparator(config)
	config = config or {}
	local frame = Create("Frame", {
		Name = "Separator",
		BackgroundColor3 = Theme.SubHeader,
		Size = UDim2.new(1, 0, 0, 22),
		BorderSizePixel = 0,
		Parent = self.Menu.ItemsContainer,
	})
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = string.upper(config.Title or "CATEGORY"),
		TextColor3 = Theme.Accent,
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -24, 1, 0),
		Parent = frame,
	})
	frame.Visible = (self.Menu.Tabs[self.Menu.ActiveTabIndex] == self)
	return frame
end

function Tab:CreateBaseRow(title, desc)
	local rowFrame = Create("TextButton", {
		Name = "Row_" .. title,
		BackgroundColor3 = Theme.Row,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 31),
		Text = "",
		AutoButtonColor = false,
		Parent = self.Menu.ItemsContainer,
	})
	Create("Frame", { BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), Parent = rowFrame })
	
	local arrow = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = ">",
		TextColor3 = Theme.RowSelectedText,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		Position = UDim2.new(0, 6, 0, 0),
		Size = UDim2.new(0, 12, 1, 0),
		Visible = false,
		Parent = rowFrame,
	})
	
	local titleLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(0.65, 0, 1, 0),
		Parent = rowFrame,
	})
	
	local rowObj = { Title = title, Description = desc, Frame = rowFrame, TitleLabel = titleLbl, Arrow = arrow, Tab = self }
	function rowObj:SetSelected(isSelected)
		if isSelected then
			Tween(rowFrame, { BackgroundColor3 = Theme.Accent }, 0.12)
			titleLbl.TextColor3 = Theme.RowSelectedText
			titleLbl.Font = Enum.Font.GothamBold
			titleLbl.Position = UDim2.new(0, 20, 0, 0)
			arrow.Visible = true
		else
			Tween(rowFrame, { BackgroundColor3 = Theme.Row }, 0.12)
			titleLbl.TextColor3 = Theme.Text
			titleLbl.Font = Enum.Font.GothamMedium
			titleLbl.Position = UDim2.new(0, 14, 0, 0)
			arrow.Visible = false
		end
	end
	
	rowFrame.MouseEnter:Connect(function()
		local idx = table.find(self.Rows, rowObj)
		if idx then
			self.Menu.ActiveRowIndex = idx
			self.Menu:UpdateSelection()
		end
	end)
	rowFrame.MouseButton1Click:Connect(function()
		if rowObj.OnActivate then rowObj:OnActivate() end
	end)
	
	table.insert(self.Rows, rowObj)
	rowFrame.Visible = (self.Menu.Tabs[self.Menu.ActiveTabIndex] == self)
	return rowObj
end

-- BUTTON
function Tab:AddButton(config)
	config = config or {}
	local row = self:CreateBaseRow(config.Title or "Button", config.Description)
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "...",
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -30, 0, 0),
		Size = UDim2.new(0, 20, 1, 0),
		Parent = row.Frame,
	})
	function row:OnActivate() task.spawn(config.Callback or function() end) end
	return row
end
Tab.CreateButton = Tab.AddButton

-- TOGGLE
function Tab:AddToggle(config)
	config = config or {}
	local row = self:CreateBaseRow(config.Title or "Toggle", config.Description)
	local state = config.Default or false
	local cb = config.Callback or function() end
	
	local badge = Create("TextLabel", {
		BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff,
		Text = state and "ON" or "OFF",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0, 36, 0, 18),
		Parent = row.Frame,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = badge })
	
	row.Type = "Toggle"
	row.Value = state
	function row:Set(val)
		state = val
		self.Value = val
		badge.Text = state and "ON" or "OFF"
		Tween(badge, { BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff }, 0.15)
		task.spawn(cb, state)
	end
	function row:OnActivate() self:Set(not state) end
	function row:OnLeft() self:Set(false) end
	function row:OnRight() self:Set(true) end
	
	if config.Flag then Vanta.Flags[config.Flag] = row end
	return row
end
Tab.CreateToggle = Tab.AddToggle

-- SLIDER
function Tab:AddSlider(config)
	config = config or {}
	local row = self:CreateBaseRow(config.Title or "Slider", config.Description)
	local min = config.Min or 0
	local max = config.Max or 100
	local cur = config.Default or min
	local step = config.Step or 1
	local sfx = config.Suffix or ""
	local cb = config.Callback or function() end
	
	local valLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "< " .. tostring(cur) .. sfx .. " >",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0, 80, 1, 0),
		Parent = row.Frame,
	})
	
	row.Type = "Slider"
	row.Value = cur
	function row:Set(val)
		cur = math.clamp(val, min, max)
		self.Value = cur
		valLbl.Text = "< " .. tostring(cur) .. sfx .. " >"
		task.spawn(cb, cur)
	end
	function row:OnLeft() self:Set(cur - step) end
	function row:OnRight() self:Set(cur + step) end
	function row:OnActivate() if cur >= max then self:Set(min) else self:Set(cur + step) end end
	
	if config.Flag then Vanta.Flags[config.Flag] = row end
	return row
end
Tab.CreateSlider = Tab.AddSlider

-- DROPDOWN
function Tab:AddDropdown(config)
	config = config or {}
	local row = self:CreateBaseRow(config.Title or "Dropdown", config.Description)
	local opts = config.Options or { "Option" }
	local curIdx = table.find(opts, config.Default) or 1
	local cb = config.Callback or function() end
	
	local choiceLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "< " .. tostring(opts[curIdx] or "None") .. " >",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0, 110, 1, 0),
		Parent = row.Frame,
	})
	
	row.Type = "Dropdown"
	row.Value = opts[curIdx]
	function row:Set(val)
		local idx = table.find(opts, val)
		if idx then
			curIdx = idx
			self.Value = val
			choiceLbl.Text = "< " .. tostring(val) .. " >"
			task.spawn(cb, val)
		end
	end
	function row:OnLeft()
		curIdx = curIdx - 1
		if curIdx < 1 then curIdx = #opts end
		self:Set(opts[curIdx])
	end
	function row:OnRight()
		curIdx = curIdx + 1
		if curIdx > #opts then curIdx = 1 end
		self:Set(opts[curIdx])
	end
	function row:OnActivate() self:OnRight() end
	
	if config.Flag then Vanta.Flags[config.Flag] = row end
	return row
end
Tab.CreateDropdown = Tab.AddDropdown

-- COLORPICKER
function Tab:AddColorPicker(config)
	config = config or {}
	local row = self:CreateBaseRow(config.Title or "Color", config.Description)
	local curCol = config.Default or Color3.fromRGB(255, 255, 255)
	local cb = config.Callback or function() end
	
	local swatch = Create("Frame", {
		BackgroundColor3 = curCol,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.new(0, 24, 0, 14),
		Parent = row.Frame,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = swatch })
	Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Parent = swatch })
	
	local palette = {
		Color3.fromRGB(255, 75, 75),
		Color3.fromRGB(255, 165, 0),
		Color3.fromRGB(255, 235, 59),
		Color3.fromRGB(76, 175, 80),
		Color3.fromRGB(0, 168, 255),
		Color3.fromRGB(168, 85, 247),
		Color3.fromRGB(255, 255, 255),
	}
	local pIdx = 1
	row.Type = "ColorPicker"
	row.Value = curCol
	function row:Set(col)
		curCol = col
		self.Value = col
		swatch.BackgroundColor3 = col
		task.spawn(cb, col)
	end
	function row:OnActivate()
		pIdx = pIdx + 1
		if pIdx > #palette then pIdx = 1 end
		self:Set(palette[pIdx])
	end
	row.OnRight = row.OnActivate
	function row:OnLeft()
		pIdx = pIdx - 1
		if pIdx < 1 then pIdx = #palette end
		self:Set(palette[pIdx])
	end
	
	if config.Flag then Vanta.Flags[config.Flag] = row end
	return row
end
Tab.CreateColorPicker = Tab.AddColorPicker

-- KEYBIND
function Tab:AddKeybind(config)
	config = config or {}
	local row = self:CreateBaseRow(config.Title or "Keybind", config.Description)
	local curKey = config.Default or Enum.KeyCode.E
	local listening = false
	local cb = config.Callback or function() end
	
	local keyLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "[" .. (curKey and curKey.Name or "NONE") .. "]",
		TextColor3 = Theme.Accent,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0, 60, 1, 0),
		Parent = row.Frame,
	})
	
	row.Type = "Keybind"
	row.Value = curKey
	function row:SetKey(k)
		curKey = k
		self.Value = k
		keyLbl.Text = "[" .. (k and k.Name or "NONE") .. "]"
	end
	function row:OnActivate()
		listening = true
		keyLbl.Text = "[...]"
	end
	
	UserInputService.InputBegan:Connect(function(input, gpe)
		if listening and input.UserInputType == Enum.UserInputType.Keyboard then
			listening = false
			if input.KeyCode == Enum.KeyCode.Escape then
				row:SetKey(nil)
			else
				row:SetKey(input.KeyCode)
			end
			return
		end
		if not gpe and curKey and input.KeyCode == curKey then
			task.spawn(cb, true)
		end
	end)
	
	if config.Flag then Vanta.Flags[config.Flag] = row end
	return row
end
Tab.CreateKeybind = Tab.AddKeybind

-- INPUT
function Tab:AddInput(config)
	config = config or {}
	local row = self:CreateBaseRow(config.Title or "Input", config.Description)
	local cb = config.Callback or function() end
	
	local tb = Create("TextBox", {
		BackgroundColor3 = Theme.Header,
		PlaceholderText = config.Placeholder or "Enter...",
		PlaceholderColor3 = Theme.TextDark,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.Gotham,
		TextSize = 11,
		Text = config.Default or "",
		ClearTextOnFocus = false,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0, 90, 0, 20),
		Parent = row.Frame,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = tb })
	
	row.Type = "Input"
	row.Value = config.Default or ""
	function row:OnActivate() tb:CaptureFocus() end
	tb.FocusLost:Connect(function()
		row.Value = tb.Text
		task.spawn(cb, tb.Text)
	end)
	
	if config.Flag then Vanta.Flags[config.Flag] = row end
	return row
end
Tab.CreateInput = Tab.AddInput

return Vanta
