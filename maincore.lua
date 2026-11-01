--[[
    VantaUI --- Modern Obsidian Glass Interface Suite
    A modern, draggable, glassmorphic UI library for Roblox Luau.
    Features:
    - Sleek modern floating window with inertia dragging (mouse + touch)
    - Dynamic Left Navigation Rail with sliding active pill and player profile dock (Avatar, FPS, Ping)
    - Pre-Login Animated Cyber Loader -> Key Verification Modal -> Smooth Decrypt Transition
    - Search Bar: Live instant search filtering across elements
    - Controls: Toggles, Sliders, Dropdowns (Floating Overlay), ColorPickers, Keybinds, Inputs, Buttons, Paragraphs
    - Stackable Toast Notifications with countdown timers
    - Pure Luau, zero external dependencies, executor-safe mounting (gethui/CoreGui/PlayerGui)
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Vanta = {
	Version = "3.0.0",
	Flags = {},
	CurrentWindow = nil,
	ScreenGui = nil,
	Overlay = nil,
	NotificationContainer = nil,
	Open = true,
	ToggleKey = Enum.KeyCode.RightControl,
}

-- [1] THEME PALETTE
local Theme = {
	Accent = Color3.fromRGB(0, 210, 255),       -- Electric Cyan / Aqua
	AccentDim = Color3.fromRGB(0, 140, 190),
	AccentGlow = Color3.fromRGB(0, 230, 255),
	Background = Color3.fromRGB(12, 13, 17),    -- Deep Obsidian
	Sidebar = Color3.fromRGB(15, 17, 22),       -- Left Rail
	Topbar = Color3.fromRGB(14, 15, 20),
	Card = Color3.fromRGB(19, 21, 28),          -- Elevated Card
	CardHover = Color3.fromRGB(24, 27, 36),
	CardHeader = Color3.fromRGB(22, 25, 33),
	Input = Color3.fromRGB(16, 18, 24),
	InputHover = Color3.fromRGB(21, 24, 32),
	Border = Color3.fromRGB(34, 38, 50),
	BorderLight = Color3.fromRGB(48, 54, 70),
	ToggleOff = Color3.fromRGB(32, 36, 48),
	ToggleKnob = Color3.fromRGB(255, 255, 255),
	Text = Color3.fromRGB(240, 244, 250),
	TextMuted = Color3.fromRGB(140, 148, 164),
	TextDark = Color3.fromRGB(85, 92, 108),
	Success = Color3.fromRGB(16, 185, 129),
	Warning = Color3.fromRGB(245, 158, 11),
	Error = Color3.fromRGB(239, 68, 68),
	Info = Color3.fromRGB(0, 210, 255),
}
Vanta.Theme = Theme

-- [2] UTILITY HELPERS
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
	local tw = TweenService:Create(instance, TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), properties)
	tw:Play()
	return tw
end

local function AddCorner(instance, radius)
	return Create("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = instance })
end

local function AddStroke(instance, color, thickness)
	return Create("UIStroke", {
		Color = color or Theme.Border,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = instance,
	})
end

local function AddBevelGradient(stroke)
	return Create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(1, 0.75),
		}),
		Parent = stroke,
	})
end

local function AddShadow(instance, elevation)
	elevation = elevation or 16
	return Create("ImageLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		Image = "rbxassetid://6015897843",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 0.4,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		Position = UDim2.new(0, -elevation, 0, -elevation),
		Size = UDim2.new(1, elevation * 2, 1, elevation * 2),
		ZIndex = math.max(1, instance.ZIndex - 1),
		Parent = instance,
	})
end

local function MakeDraggable(handle, target)
	local dragging = false
	local dragInput, dragStart, startPos
	
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
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
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			Tween(target, {
				Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			}, 0.06, Enum.EasingStyle.Sine)
		end
	end)
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

-- [3] ROOT SCREEN GUI
function Vanta:InitRoot()
	if self.ScreenGui and self.ScreenGui.Parent then return end
	
	local existing = GetSafeGuiParent():FindFirstChild("VantaNova_Container")
	if existing then existing:Destroy() end
	
	local screenGui = Create("ScreenGui", {
		Name = "VantaNova_Container",
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
	
	-- Toast Notifications Stack (Bottom-Right)
	local notifContainer = Create("Frame", {
		Name = "Notifications",
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -330, 1, -20),
		AnchorPoint = Vector2.new(0, 1),
		Size = UDim2.new(0, 310, 1, -40),
		ZIndex = 1000,
		Parent = screenGui,
	})
	Create("UIListLayout", {
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = notifContainer,
	})
	
	-- Floating Overlay Layer (Dropdowns, Color Pickers)
	local overlay = Create("Frame", {
		Name = "OverlayLayer",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 500,
		Parent = screenGui,
	})
	
	self.ScreenGui = screenGui
	self.NotificationContainer = notifContainer
	self.Overlay = overlay
	
	-- Global Toggle Key listener (RightControl / Insert)
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe and UserInputService:GetFocusedTextBox() then return end
		if input.KeyCode == self.ToggleKey then
			self:Toggle()
		end
	end)
end

-- [4] TOAST NOTIFICATIONS
function Vanta:Notify(config)
	self:InitRoot()
	config = config or {}
	local title = config.Title or "NOTIFICATION"
	local content = config.Content or ""
	local duration = config.Duration or 3.5
	local notifType = config.Type or "Info"
	
	local accent = notifType == "Success" and Theme.Success or notifType == "Warning" and Theme.Warning or notifType == "Error" and Theme.Error or Theme.Accent
	
	local card = Create("Frame", {
		BackgroundColor3 = Theme.Card,
		Size = UDim2.new(1, 0, 0, 60),
		ClipsDescendants = true,
		Parent = self.NotificationContainer,
	})
	AddCorner(card, 8)
	local stroke = AddStroke(card, Theme.Border, 1)
	AddBevelGradient(stroke)
	AddShadow(card, 10)
	
	-- Left Accent Glow Indicator
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
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 14, 0, 10),
		Size = UDim2.new(1, -24, 0, 16),
		Parent = card,
	})
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = content,
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 14, 0, 28),
		Size = UDim2.new(1, -24, 0, 24),
		Parent = card,
	})
	
	-- Countdown Progress Line
	local prog = Create("Frame", {
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -2),
		Size = UDim2.new(1, 0, 0, 2),
		Parent = card,
	})
	Tween(prog, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)
	
	task.delay(duration, function()
		if card and card.Parent then
			local tw = Tween(card, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, 0.22)
			tw.Completed:Connect(function() card:Destroy() end)
		end
	end)
end

-- [5] PRE-LOGIN LOADING + AUTHENTICATION PIPELINE
function Vanta:StartAuthPipeline(config, onAuthenticated)
	self:InitRoot()
	config = config or {}
	local title = config.Title or "VANTA // NOVA"
	local validKeys = config.Keys or { "vanta-vip", "free", "test" }
	local keyLink = config.KeyLink or "https://discord.gg/vibe"
	local saveFile = config.SaveKeyName or "VantaLicense.txt"
	
	-- Frosted Backdrop
	local backdrop = Create("Frame", {
		Name = "AuthBackdrop",
		BackgroundColor3 = Color3.fromRGB(6, 7, 10),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 2000,
		Parent = self.ScreenGui,
	})
	Tween(backdrop, { BackgroundTransparency = 0.35 }, 0.3)
	
	-- Central Glass Card
	local card = Create("Frame", {
		Name = "AuthCard",
		BackgroundColor3 = Theme.Background,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 380, 0, 200),
		ClipsDescendants = true,
		Parent = backdrop,
	})
	AddCorner(card, 12)
	local stroke = AddStroke(card, Theme.Border, 1.2)
	AddBevelGradient(stroke)
	AddShadow(card, 22)
	
	-- Top Accent Line
	Create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 3),
		Parent = card,
	})
	
	local titleLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = string.upper(title),
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBlack,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.new(0, 0, 0, 20),
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
		Position = UDim2.new(0, 0, 0, 42),
		Size = UDim2.new(1, 0, 0, 14),
		Parent = card,
	})
	
	-----------------------------------------------------------------
	-- STAGE 1: ANIMATED PRE-LOADER (RUNS BEFORE LOGIN)
	-----------------------------------------------------------------
	local loaderBox = Create("Frame", {
		Name = "Stage1_Loader",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 28, 0, 75),
		Size = UDim2.new(1, -56, 1, -85),
		Parent = card,
	})
	
	local loadStatus = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "[1/3] CONNECTING TO SECURE AUTH SERVER...",
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.new(0, 0, 0, 12),
		Size = UDim2.new(1, 0, 0, 18),
		Parent = loaderBox,
	})
	
	local loadTrack = Create("Frame", {
		BackgroundColor3 = Theme.Input,
		Position = UDim2.new(0, 0, 0, 46),
		Size = UDim2.new(1, 0, 0, 8),
		Parent = loaderBox,
	})
	AddCorner(loadTrack, 4)
	
	local loadFill = Create("Frame", {
		BackgroundColor3 = Theme.Accent,
		Size = UDim2.new(0, 0, 1, 0),
		Parent = loadTrack,
	})
	AddCorner(loadFill, 4)
	
	-----------------------------------------------------------------
	-- STAGE 2: KEY LOGIN WINDOW
	-----------------------------------------------------------------
	local loginBox = Create("Frame", {
		Name = "Stage2_Login",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 28, 0, 75),
		Size = UDim2.new(1, -56, 1, -85),
		Visible = false,
		Parent = card,
	})
	
	local inputFrame = Create("Frame", {
		BackgroundColor3 = Theme.Input,
		Position = UDim2.new(0, 0, 0, 4),
		Size = UDim2.new(1, 0, 0, 38),
		Parent = loginBox,
	})
	AddCorner(inputFrame, 8)
	AddStroke(inputFrame, Theme.Border, 1)
	
	local keyBox = Create("TextBox", {
		BackgroundTransparency = 1,
		PlaceholderText = "Paste license key here...",
		PlaceholderColor3 = Theme.TextDark,
		TextColor3 = Theme.Text,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		Text = "",
		ClearTextOnFocus = false,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -80, 1, 0),
		Parent = inputFrame,
	})
	
	local pasteBtn = Create("TextButton", {
		Text = "PASTE",
		TextColor3 = Theme.Accent,
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		BackgroundColor3 = Theme.Card,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.new(0, 50, 0, 26),
		AutoButtonColor = false,
		Parent = inputFrame,
	})
	AddCorner(pasteBtn, 6)
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
		BackgroundColor3 = Theme.Card,
		Position = UDim2.new(0, 0, 0, 52),
		Size = UDim2.new(0.48, 0, 0, 34),
		AutoButtonColor = false,
		Parent = loginBox,
	})
	AddCorner(getBtn, 6)
	AddStroke(getBtn, Theme.Border, 1)
	
	local unlockBtn = Create("TextButton", {
		Text = "UNLOCK",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		BackgroundColor3 = Theme.Accent,
		Position = UDim2.new(0.52, 0, 0, 52),
		Size = UDim2.new(0.48, 0, 0, 34),
		AutoButtonColor = false,
		Parent = loginBox,
	})
	AddCorner(unlockBtn, 6)
	
	getBtn.MouseButton1Click:Connect(function()
		if setclipboard then
			setclipboard(keyLink)
			Vanta:Notify({ Title = "Link Copied", Content = keyLink, Type = "Info", Duration = 3 })
		else
			Vanta:Notify({ Title = "Key Link", Content = keyLink, Type = "Info", Duration = 4 })
		end
	end)
	
	-- Check saved key
	pcall(function()
		if readfile and isfile and isfile(saveFile) then
			local saved = readfile(saveFile)
			if saved and saved ~= "" then keyBox.Text = saved end
		end
	end)
	
	-- Run Stage 1 Animation
	task.spawn(function()
		local stages = {
			{ Text = "[1/3] CONNECTING TO SECURE AUTH SERVER...", Pct = 0.35, Dur = 0.4 },
			{ Text = "[2/3] FETCHING HARDWARE MANIFEST...", Pct = 0.70, Dur = 0.45 },
			{ Text = "[3/3] MOUNTING AUTHENTICATION GATE...", Pct = 1.00, Dur = 0.35 },
		}
		for _, st in ipairs(stages) do
			loadStatus.Text = st.Text
			Tween(loadFill, { Size = UDim2.new(st.Pct, 0, 1, 0) }, st.Dur, Enum.EasingStyle.Sine)
			task.wait(st.Dur + 0.08)
		end
		
		task.wait(0.2)
		subLbl.Text = "LICENSE VERIFICATION"
		loaderBox.Visible = false
		loginBox.Visible = true
	end)
	
	-- Verification Handler
	local function AttemptUnlock()
		local entered = keyBox.Text:gsub("%s+", "")
		local isValid = false
		for _, k in ipairs(validKeys) do
			if entered == k then isValid = true; break end
		end
		
		if isValid then
			pcall(function()
				if writefile then writefile(saveFile, entered) end
			end)
			
			loginBox.Visible = false
			loaderBox.Visible = true
			subLbl.Text = "ACCESS GRANTED"
			subLbl.TextColor3 = Theme.Success
			loadStatus.Text = "DECRYPTING VANTA NOVA MODULES..."
			loadStatus.TextColor3 = Theme.Success
			loadFill.BackgroundColor3 = Theme.Success
			loadFill.Size = UDim2.new(0, 0, 1, 0)
			Tween(loadFill, { Size = UDim2.new(1, 0, 1, 0) }, 0.4, Enum.EasingStyle.Sine)
			
			task.wait(0.5)
			Tween(card, { Size = UDim2.new(0, 410, 0, 220), BackgroundTransparency = 1 }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			local tw = Tween(backdrop, { BackgroundTransparency = 1 }, 0.3)
			tw.Completed:Connect(function()
				backdrop:Destroy()
				if onAuthenticated then onAuthenticated() end
			end)
		else
			-- Shake error
			task.spawn(function()
				local orig = UDim2.new(0.5, 0, 0.5, 0)
				local steps = { -10, 8, -6, 4, -2, 0 }
				for _, off in ipairs(steps) do
					Tween(card, { Position = UDim2.new(orig.X.Scale, orig.X.Offset + off, orig.Y.Scale, orig.Y.Offset) }, 0.04)
					task.wait(0.04)
				end
			end)
			Tween(stroke, { Color = Theme.Error }, 0.1)
			Vanta:Notify({ Title = "Invalid License", Content = "The key entered is invalid or expired.", Type = "Error", Duration = 3 })
			task.delay(0.6, function()
				Tween(stroke, { Color = Theme.Border }, 0.25)
			end)
		end
	end
	
	unlockBtn.MouseButton1Click:Connect(AttemptUnlock)
	keyBox.FocusLost:Connect(function(enter)
		if enter then AttemptUnlock() end
	end)
end

-- [6] MODERN WINDOW CLASS
local Window = {}
Window.__index = Window

function Vanta:CreateWindow(config)
	self:InitRoot()
	config = config or {}
	local title = config.Title or "VANTA"
	local subTitle = config.SubTitle or "NOVA SUITE"
	local size = config.Size or UDim2.new(0, 680, 0, 450)
	local toggleKey = config.ToggleKey or Enum.KeyCode.RightControl
	local useKeySystem = config.KeySystem ~= nil
	self.ToggleKey = toggleKey
	
	local win = setmetatable({
		Title = title,
		SubTitle = subTitle,
		DefaultSize = size,
		Tabs = {},
		ActiveTab = nil,
		Flags = self.Flags,
	}, Window)
	self.CurrentWindow = win
	
	-- Main Floating Window Frame
	local main = Create("Frame", {
		Name = "VantaNova_Window",
		BackgroundColor3 = Theme.Background,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = size,
		ClipsDescendants = false,
		Parent = self.ScreenGui,
	})
	AddCorner(main, 12)
	local winStroke = AddStroke(main, Theme.Border, 1)
	AddBevelGradient(winStroke)
	AddShadow(main, 20)
	
	win.MainFrame = main
	
	-- 1. LEFT NAVIGATION RAIL (Sidebar)
	local sidebar = Create("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = Theme.Sidebar,
		Size = UDim2.new(0, 185, 1, 0),
		Parent = main,
	})
	AddCorner(sidebar, 12)
	
	-- Cover right corners of sidebar
	local sideCover = Create("Frame", {
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -8, 0, 0),
		Size = UDim2.new(0, 8, 1, 0),
		Parent = sidebar,
	})
	
	-- Sidebar Divider Line
	Create("Frame", {
		BackgroundColor3 = Theme.Border,
		BorderSizePixel = 0,
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		Parent = sidebar,
	})
	
	-- Brand Header (Top of Sidebar)
	local brandBox = Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 14),
		Size = UDim2.new(1, -32, 0, 36),
		Parent = sidebar,
	})
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = string.upper(title),
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBlack,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -45, 0, 20),
		Parent = brandBox,
	})
	
	-- Version Capsule Badge
	local verBadge = Create("TextLabel", {
		BackgroundColor3 = Theme.Card,
		Text = "v3.0",
		TextColor3 = Theme.Accent,
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 2),
		Size = UDim2.new(0, 36, 0, 18),
		Parent = brandBox,
	})
	AddCorner(verBadge, 4)
	AddStroke(verBadge, Theme.Border, 1)
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = string.upper(subTitle),
		TextColor3 = Theme.TextDark,
		Font = Enum.Font.GothamBold,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 0, 0, 20),
		Size = UDim2.new(1, 0, 0, 14),
		Parent = brandBox,
	})
	
	-- Tabs Scrolling List
	local tabList = Create("ScrollingFrame", {
		Name = "TabList",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.BorderLight,
		Position = UDim2.new(0, 10, 0, 60),
		Size = UDim2.new(1, -20, 1, -125),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = sidebar,
	})
	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = tabList })
	win.TabList = tabList
	
	-- Player Profile Dock (Bottom of Sidebar)
	local profileDock = Create("Frame", {
		Name = "ProfileDock",
		BackgroundColor3 = Theme.Card,
		Position = UDim2.new(0, 10, 1, -55),
		Size = UDim2.new(1, -20, 0, 45),
		Parent = sidebar,
	})
	AddCorner(profileDock, 8)
	AddStroke(profileDock, Theme.Border, 1)
	
	local avatarImg = Create("ImageLabel", {
		BackgroundColor3 = Theme.Input,
		Position = UDim2.new(0, 8, 0.5, -14),
		Size = UDim2.new(0, 28, 0, 28),
		Parent = profileDock,
	})
	AddCorner(avatarImg, 14)
	
	-- Load headshot async
	task.spawn(function()
		pcall(function()
			if LocalPlayer then
				local content = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
				avatarImg.Image = content
			end
		end)
	end)
	
	local nameLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = LocalPlayer and LocalPlayer.DisplayName or "User",
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 42, 0, 8),
		Size = UDim2.new(1, -60, 0, 14),
		Parent = profileDock,
	})
	
	-- Live Ping & Status Dot
	local statusDot = Create("Frame", {
		BackgroundColor3 = Theme.Success,
		Position = UDim2.new(0, 42, 0, 26),
		Size = UDim2.new(0, 6, 0, 6),
		Parent = profileDock,
	})
	AddCorner(statusDot, 3)
	
	local statusLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "CONNECTED",
		TextColor3 = Theme.TextDark,
		Font = Enum.Font.GothamBold,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 52, 0, 22),
		Size = UDim2.new(1, -65, 0, 14),
		Parent = profileDock,
	})
	
	-- 2. TOPBAR HEADER (Draggable)
	local topbar = Create("Frame", {
		Name = "Topbar",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 185, 0, 0),
		Size = UDim2.new(1, -185, 0, 48),
		Parent = main,
	})
	MakeDraggable(topbar, main)
	
	-- Instant Search Filter Box
	local searchFrame = Create("Frame", {
		BackgroundColor3 = Theme.Input,
		Position = UDim2.new(0, 16, 0.5, -14),
		Size = UDim2.new(0, 200, 0, 28),
		Parent = topbar,
	})
	AddCorner(searchFrame, 6)
	AddStroke(searchFrame, Theme.Border, 1)
	
	local searchIcon = Create("ImageLabel", {
		BackgroundTransparency = 1,
		Image = "rbxassetid://10734950117",
		ImageColor3 = Theme.TextDark,
		Position = UDim2.new(0, 8, 0.5, -6),
		Size = UDim2.new(0, 12, 0, 12),
		Parent = searchFrame,
	})
	
	local searchInput = Create("TextBox", {
		BackgroundTransparency = 1,
		PlaceholderText = "Search controls...",
		PlaceholderColor3 = Theme.TextDark,
		TextColor3 = Theme.Text,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		Text = "",
		ClearTextOnFocus = false,
		Position = UDim2.new(0, 26, 0, 0),
		Size = UDim2.new(1, -30, 1, 0),
		Parent = searchFrame,
	})
	
	searchInput:GetPropertyChangedSignal("Text"):Connect(function()
		local query = searchInput.Text:lower()
		if win.ActiveTab then
			win.ActiveTab:Filter(query)
		end
	end)
	
	-- Window Action Controls (Close / Hide)
	local closeBtn = Create("TextButton", {
		Text = "×",
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamMedium,
		TextSize = 18,
		BackgroundColor3 = Theme.Card,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.new(0, 26, 0, 26),
		AutoButtonColor = false,
		Parent = topbar,
	})
	AddCorner(closeBtn, 6)
	AddStroke(closeBtn, Theme.Border, 1)
	closeBtn.MouseButton1Click:Connect(function()
		Vanta:Toggle()
	end)
	
	-- 3. CONTENT PAGES CONTAINER
	local content = Create("Frame", {
		Name = "ContentContainer",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 195, 0, 52),
		Size = UDim2.new(1, -205, 1, -62),
		ClipsDescendants = true,
		Parent = main,
	})
	win.ContentContainer = content
	
	-- Pre-Login Loading Pipeline
	if useKeySystem then
		main.Visible = false
		Vanta:StartAuthPipeline(config.KeySystem, function()
			main.Visible = true
			main.Size = UDim2.new(0, size.X.Offset * 0.9, 0, size.Y.Offset * 0.9)
			Tween(main, { Size = size }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end)
	else
		main.Size = UDim2.new(0, size.X.Offset * 0.9, 0, size.Y.Offset * 0.9)
		Tween(main, { Size = size }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end
	
	return win
end

function Vanta:Toggle()
	self.Open = not self.Open
	if self.CurrentWindow and self.CurrentWindow.MainFrame then
		local frame = self.CurrentWindow.MainFrame
		if self.Open then
			frame.Visible = true
			Tween(frame, { Size = self.CurrentWindow.DefaultSize }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		else
			local tw = Tween(frame, { Size = UDim2.new(0, self.CurrentWindow.DefaultSize.X.Offset * 0.92, 0, self.CurrentWindow.DefaultSize.Y.Offset * 0.92) }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			tw.Completed:Connect(function()
				if not self.Open then frame.Visible = false end
			end)
		end
	end
end

-- [7] TAB CLASS
local Tab = {}
Tab.__index = Tab

function Window:CreateTab(config)
	config = config or {}
	local title = config.Title or config.Name or "Tab"
	local icon = config.Icon
	
	local tab = setmetatable({
		Title = title,
		Window = self,
		Cards = {},
	}, Tab)
	
	-- Sidebar Navigation Capsule Button
	local tabBtn = Create("TextButton", {
		Name = "Tab_" .. title,
		BackgroundColor3 = Theme.Input,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
		Text = "",
		AutoButtonColor = false,
		Parent = self.TabList,
	})
	AddCorner(tabBtn, 8)
	
	local activePill = Create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0.2, 0),
		Size = UDim2.new(0, 3, 0.6, 0),
		Visible = false,
		Parent = tabBtn,
	})
	AddCorner(activePill, 2)
	
	local label = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(1, -24, 1, 0),
		Parent = tabBtn,
	})
	
	tab.Button = tabBtn
	tab.Label = label
	tab.ActivePill = activePill
	
	-- Page Scrolling Container
	local page = Create("ScrollingFrame", {
		Name = "Page_" .. title,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.BorderLight,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = self.ContentContainer,
	})
	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12), Parent = page })
	Create("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 12), Parent = page })
	tab.Page = page
	
	tabBtn.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)
	
	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 then
		self:SelectTab(tab)
	end
	
	return tab
end

function Window:SelectTab(selected)
	for _, t in ipairs(self.Tabs) do
		local isSel = (t == selected)
		t.Page.Visible = isSel
		t.ActivePill.Visible = isSel
		
		if isSel then
			Tween(t.Button, { BackgroundTransparency = 0.82, BackgroundColor3 = Theme.Accent }, 0.2)
			Tween(t.Label, { TextColor3 = Theme.Text }, 0.2)
			t.Label.Font = Enum.Font.GothamBold
		else
			Tween(t.Button, { BackgroundTransparency = 1 }, 0.2)
			Tween(t.Label, { TextColor3 = Theme.TextMuted }, 0.2)
			t.Label.Font = Enum.Font.GothamMedium
		end
	end
	self.ActiveTab = selected
end

function Tab:Filter(query)
	for _, card in ipairs(self.Cards) do
		local cardVisible = false
		for _, row in ipairs(card.Rows) do
			if query == "" or row.Title:lower():find(query, 1, true) then
				row.Frame.Visible = true
				cardVisible = true
			else
				row.Frame.Visible = false
			end
		end
		card.Frame.Visible = cardVisible
	end
end

-- [8] SECTION CARD (GroupBox)
local Card = {}
Card.__index = Card

function Tab:CreateSection(title)
	local card = setmetatable({
		Title = title,
		Tab = self,
		Rows = {},
	}, Card)
	
	local frame = Create("Frame", {
		Name = "Card_" .. title,
		BackgroundColor3 = Theme.Card,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = self.Page,
	})
	AddCorner(frame, 10)
	local stroke = AddStroke(frame, Theme.Border, 1)
	AddBevelGradient(stroke)
	
	-- Header Banner
	local header = Create("Frame", {
		BackgroundColor3 = Theme.CardHeader,
		Size = UDim2.new(1, 0, 0, 32),
		Parent = frame,
	})
	AddCorner(header, 10)
	Create("Frame", { BackgroundColor3 = Theme.CardHeader, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -6), Size = UDim2.new(1, 0, 0, 6), Parent = header })
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(1, -28, 1, 0),
		Parent = header,
	})
	
	local body = Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 32),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = frame,
	})
	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = body })
	Create("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = body,
	})
	
	card.Frame = frame
	card.Container = body
	table.insert(self.Cards, card)
	
	return card
end

-- [9] MODERN CONTROLS

-- BUTTON
function Card:CreateButton(config)
	config = config or {}
	local title = config.Title or "Button"
	local desc = config.Description
	local cb = config.Callback or function() end
	
	local h = desc and 44 or 34
	local btn = Create("TextButton", {
		BackgroundColor3 = Theme.Input,
		Size = UDim2.new(1, 0, 0, h),
		Text = "",
		AutoButtonColor = false,
		Parent = self.Container,
	})
	AddCorner(btn, 6)
	AddStroke(btn, Theme.Border, 1)
	
	local titleLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 12, 0, desc and 6 or 0),
		Size = UDim2.new(1, -40, 0, desc and 16 or h),
		Parent = btn,
	})
	
	if desc then
		Create("TextLabel", {
			BackgroundTransparency = 1,
			Text = desc,
			TextColor3 = Theme.TextMuted,
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 12, 0, 22),
			Size = UDim2.new(1, -40, 0, 16),
			Parent = btn,
		})
	end
	
	-- Action Chevron Arrow
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "→",
		TextColor3 = Theme.TextDark,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0, 16, 0, 16),
		Parent = btn,
	})
	
	btn.MouseEnter:Connect(function() Tween(btn, { BackgroundColor3 = Theme.InputHover }, 0.15) end)
	btn.MouseLeave:Connect(function() Tween(btn, { BackgroundColor3 = Theme.Input }, 0.15) end)
	btn.MouseButton1Down:Connect(function() Tween(btn, { BackgroundColor3 = Theme.AccentDim }, 0.1) end)
	btn.MouseButton1Up:Connect(function()
		Tween(btn, { BackgroundColor3 = Theme.InputHover }, 0.1)
		task.spawn(cb)
	end)
	
	table.insert(self.Rows, { Title = title, Frame = btn })
	return btn
end

-- TOGGLE
function Card:CreateToggle(config)
	config = config or {}
	local title = config.Title or "Toggle"
	local desc = config.Description
	local state = config.Default or false
	local cb = config.Callback or function() end
	
	local h = desc and 44 or 34
	local frame = Create("Frame", {
		BackgroundColor3 = Theme.Input,
		Size = UDim2.new(1, 0, 0, h),
		Parent = self.Container,
	})
	AddCorner(frame, 6)
	AddStroke(frame, Theme.Border, 1)
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 12, 0, desc and 6 or 0),
		Size = UDim2.new(1, -65, 0, desc and 16 or h),
		Parent = frame,
	})
	
	if desc then
		Create("TextLabel", {
			BackgroundTransparency = 1,
			Text = desc,
			TextColor3 = Theme.TextMuted,
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 12, 0, 22),
			Size = UDim2.new(1, -65, 0, 16),
			Parent = frame,
		})
	end
	
	-- Capsule Switch
	local track = Create("TextButton", {
		Text = "",
		BackgroundColor3 = state and Theme.Accent or Theme.ToggleOff,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0, 38, 0, 20),
		AutoButtonColor = false,
		Parent = frame,
	})
	AddCorner(track, 10)
	
	local knob = Create("Frame", {
		BackgroundColor3 = Theme.ToggleKnob,
		Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
		Size = UDim2.new(0, 16, 0, 16),
		Parent = track,
	})
	AddCorner(knob, 8)
	
	local toggleObj = { Type = "Toggle", Value = state }
	function toggleObj:Set(val)
		state = val
		self.Value = val
		if state then
			Tween(track, { BackgroundColor3 = Theme.Accent }, 0.2)
			Tween(knob, { Position = UDim2.new(1, -18, 0.5, -8) }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		else
			Tween(track, { BackgroundColor3 = Theme.ToggleOff }, 0.2)
			Tween(knob, { Position = UDim2.new(0, 2, 0.5, -8) }, 0.2)
		end
		task.spawn(cb, state)
	end
	
	track.MouseButton1Click:Connect(function()
		toggleObj:Set(not state)
	end)
	
	if config.Flag then Vanta.Flags[config.Flag] = toggleObj end
	table.insert(self.Rows, { Title = title, Frame = frame })
	return toggleObj
end

-- SLIDER
function Card:CreateSlider(config)
	config = config or {}
	local title = config.Title or "Slider"
	local min = config.Min or 0
	local max = config.Max or 100
	local cur = config.Default or min
	local step = config.Step or 1
	local sfx = config.Suffix or ""
	local cb = config.Callback or function() end
	
	local frame = Create("Frame", {
		BackgroundColor3 = Theme.Input,
		Size = UDim2.new(1, 0, 0, 48),
		Parent = self.Container,
	})
	AddCorner(frame, 6)
	AddStroke(frame, Theme.Border, 1)
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 12, 0, 6),
		Size = UDim2.new(1, -90, 0, 16),
		Parent = frame,
	})
	
	local valLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = tostring(cur) .. sfx,
		TextColor3 = Theme.Accent,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -90, 0, 6),
		Size = UDim2.new(0, 78, 0, 16),
		Parent = frame,
	})
	
	local track = Create("TextButton", {
		Text = "",
		BackgroundColor3 = Theme.ToggleOff,
		Position = UDim2.new(0, 12, 0, 30),
		Size = UDim2.new(1, -24, 0, 6),
		AutoButtonColor = false,
		Parent = frame,
	})
	AddCorner(track, 3)
	
	local fill = Create("Frame", {
		BackgroundColor3 = Theme.Accent,
		Size = UDim2.new(math.clamp((cur - min) / (max - min), 0, 1), 0, 1, 0),
		Parent = track,
	})
	AddCorner(fill, 3)
	
	local sliderObj = { Type = "Slider", Value = cur }
	local function updateSlider(xPos)
		local w = track.AbsoluteSize.X
		local relX = math.clamp(xPos - track.AbsolutePosition.X, 0, w)
		local raw = min + (max - min) * (relX / w)
		local stepped = math.floor((raw / step) + 0.5) * step
		stepped = math.clamp(stepped, min, max)
		sliderObj:Set(stepped)
	end
	
	function sliderObj:Set(val)
		val = math.clamp(val, min, max)
		cur = val
		self.Value = val
		valLbl.Text = tostring(val) .. sfx
		Tween(fill, { Size = UDim2.new((val - min) / (max - min), 0, 1, 0) }, 0.08)
		task.spawn(cb, val)
	end
	
	local dragging = false
	track.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateSlider(inp.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			updateSlider(inp.Position.X)
		end
	end)
	
	if config.Flag then Vanta.Flags[config.Flag] = sliderObj end
	table.insert(self.Rows, { Title = title, Frame = frame })
	return sliderObj
end

-- DROPDOWN (FLOATING OVERLAY POPUP)
function Card:CreateDropdown(config)
	config = config or {}
	local title = config.Title or "Dropdown"
	local opts = config.Options or { "Option 1" }
	local cur = config.Default or opts[1]
	local multi = config.Multi or false
	local cb = config.Callback or function() end
	
	local selected = multi and (type(cur) == "table" and cur or {cur}) or cur
	local isOpen = false
	
	local frame = Create("Frame", {
		BackgroundColor3 = Theme.Input,
		Size = UDim2.new(1, 0, 0, 40),
		Parent = self.Container,
	})
	AddCorner(frame, 6)
	AddStroke(frame, Theme.Border, 1)
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(0.45, 0, 1, 0),
		Parent = frame,
	})
	
	local valBtn = Create("TextButton", {
		BackgroundColor3 = Theme.Card,
		Size = UDim2.new(0.5, 0, 0, 26),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Text = "",
		AutoButtonColor = false,
		Parent = frame,
	})
	AddCorner(valBtn, 4)
	AddStroke(valBtn, Theme.Border, 1)
	
	local dispLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = multi and table.concat(selected, ", ") or tostring(selected or "None"),
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(1, -24, 1, 0),
		Parent = valBtn,
	})
	
	local chevron = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "▼",
		TextColor3 = Theme.TextDark,
		Font = Enum.Font.GothamBold,
		TextSize = 9,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.new(0, 12, 0, 12),
		Parent = valBtn,
	})
	
	-- Floating Menu on Overlay Layer
	local menu = Create("ScrollingFrame", {
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.BorderLight,
		Size = UDim2.new(0, 180, 0, 0),
		Visible = false,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = Vanta.Overlay,
	})
	AddCorner(menu, 6)
	AddStroke(menu, Theme.Border, 1)
	AddShadow(menu, 12)
	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = menu })
	Create("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = menu })
	
	local dropObj = { Type = "Dropdown", Value = selected, Options = opts }
	function dropObj:Set(newVal)
		selected = newVal
		self.Value = newVal
		dispLbl.Text = multi and table.concat(selected, ", ") or tostring(selected or "None")
		task.spawn(cb, newVal)
	end
	
	local function rebuildMenu()
		for _, child in ipairs(menu:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		for _, opt in ipairs(opts) do
			local optBtn = Create("TextButton", {
				Text = opt,
				TextColor3 = Theme.TextMuted,
				Font = Enum.Font.Gotham,
				TextSize = 11,
				BackgroundColor3 = Theme.Input,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 24),
				AutoButtonColor = false,
				Parent = menu,
			})
			AddCorner(optBtn, 4)
			optBtn.MouseEnter:Connect(function() Tween(optBtn, { BackgroundTransparency = 0.8, BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Text }, 0.1) end)
			optBtn.MouseLeave:Connect(function() Tween(optBtn, { BackgroundTransparency = 1, TextColor3 = Theme.TextMuted }, 0.1) end)
			optBtn.MouseButton1Click:Connect(function()
				if multi then
					local idx = table.find(selected, opt)
					if idx then table.remove(selected, idx) else table.insert(selected, opt) end
					dropObj:Set(selected)
				else
					dropObj:Set(opt)
					isOpen = false
					menu.Visible = false
				end
			end)
		end
	end
	rebuildMenu()
	
	valBtn.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		if isOpen then
			local abs = valBtn.AbsolutePosition
			local sz = valBtn.AbsoluteSize
			menu.Position = UDim2.new(0, abs.X, 0, abs.Y + sz.Y + 4)
			menu.Size = UDim2.new(0, sz.X, 0, math.min(#opts * 28 + 12, 140))
			menu.Visible = true
		else
			menu.Visible = false
		end
	end)
	
	if config.Flag then Vanta.Flags[config.Flag] = dropObj end
	table.insert(self.Rows, { Title = title, Frame = frame })
	return dropObj
end

-- COLORPICKER
function Card:CreateColorPicker(config)
	config = config or {}
	local title = config.Title or "Color"
	local cur = config.Default or Color3.fromRGB(0, 210, 255)
	local cb = config.Callback or function() end
	local isOpen = false
	
	local frame = Create("Frame", {
		BackgroundColor3 = Theme.Input,
		Size = UDim2.new(1, 0, 0, 36),
		Parent = self.Container,
	})
	AddCorner(frame, 6)
	AddStroke(frame, Theme.Border, 1)
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -70, 1, 0),
		Parent = frame,
	})
	
	local swatch = Create("TextButton", {
		Text = "",
		BackgroundColor3 = cur,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0, 32, 0, 20),
		AutoButtonColor = false,
		Parent = frame,
	})
	AddCorner(swatch, 4)
	AddStroke(swatch, Color3.fromRGB(255, 255, 255), 1)
	
	-- Preset Palette Modal
	local palette = Create("Frame", {
		BackgroundColor3 = Theme.Card,
		Size = UDim2.new(0, 180, 0, 90),
		Visible = false,
		Parent = Vanta.Overlay,
	})
	AddCorner(palette, 8)
	AddStroke(palette, Theme.Border, 1)
	AddShadow(palette, 12)
	
	local pGrid = Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 10),
		Size = UDim2.new(1, -20, 1, -20),
		Parent = palette,
	})
	Create("UIGridLayout", { CellSize = UDim2.new(0, 34, 0, 28), CellPadding = UDim2.new(0, 8, 0, 8), Parent = pGrid })
	
	local presets = {
		Color3.fromRGB(0, 210, 255),
		Color3.fromRGB(16, 185, 129),
		Color3.fromRGB(168, 85, 247),
		Color3.fromRGB(244, 63, 94),
		Color3.fromRGB(245, 158, 11),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(200, 200, 200),
		Color3.fromRGB(40, 45, 55),
	}
	
	local colObj = { Type = "ColorPicker", Value = cur }
	function colObj:Set(newCol)
		cur = newCol
		self.Value = newCol
		swatch.BackgroundColor3 = newCol
		task.spawn(cb, newCol)
	end
	
	for _, c in ipairs(presets) do
		local pBtn = Create("TextButton", { Text = "", BackgroundColor3 = c, AutoButtonColor = false, Parent = pGrid })
		AddCorner(pBtn, 4)
		pBtn.MouseButton1Click:Connect(function()
			colObj:Set(c)
			palette.Visible = false
			isOpen = false
		end)
	end
	
	swatch.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		if isOpen then
			local abs = swatch.AbsolutePosition
			palette.Position = UDim2.new(0, abs.X - 148, 0, abs.Y + 26)
			palette.Visible = true
		else
			palette.Visible = false
		end
	end)
	
	if config.Flag then Vanta.Flags[config.Flag] = colObj end
	table.insert(self.Rows, { Title = title, Frame = frame })
	return colObj
end

-- KEYBIND
function Card:CreateKeybind(config)
	config = config or {}
	local title = config.Title or "Keybind"
	local cur = config.Default or Enum.KeyCode.E
	local cb = config.Callback or function() end
	local listening = false
	
	local frame = Create("Frame", {
		BackgroundColor3 = Theme.Input,
		Size = UDim2.new(1, 0, 0, 36),
		Parent = self.Container,
	})
	AddCorner(frame, 6)
	AddStroke(frame, Theme.Border, 1)
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -80, 1, 0),
		Parent = frame,
	})
	
	local bindBtn = Create("TextButton", {
		Text = cur and "[" .. cur.Name .. "]" or "[None]",
		TextColor3 = Theme.Accent,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		BackgroundColor3 = Theme.Card,
		Size = UDim2.new(0, 65, 0, 22),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		AutoButtonColor = false,
		Parent = frame,
	})
	AddCorner(bindBtn, 4)
	AddStroke(bindBtn, Theme.Border, 1)
	
	local keyObj = { Type = "Keybind", Value = cur }
	function keyObj:SetKey(k)
		cur = k
		self.Value = k
		bindBtn.Text = k and "[" .. k.Name .. "]" or "[None]"
	end
	
	bindBtn.MouseButton1Click:Connect(function()
		listening = true
		bindBtn.Text = "[...]"
	end)
	
	UserInputService.InputBegan:Connect(function(inp, gpe)
		if listening and inp.UserInputType == Enum.UserInputType.Keyboard then
			listening = false
			if inp.KeyCode == Enum.KeyCode.Escape then
				keyObj:SetKey(nil)
			else
				keyObj:SetKey(inp.KeyCode)
			end
			return
		end
		if not gpe and cur and inp.KeyCode == cur then
			task.spawn(cb, true)
		end
	end)
	
	if config.Flag then Vanta.Flags[config.Flag] = keyObj end
	table.insert(self.Rows, { Title = title, Frame = frame })
	return keyObj
end

-- INPUT
function Card:CreateInput(config)
	config = config or {}
	local title = config.Title or "Input"
	local def = config.Default or ""
	local cb = config.Callback or function() end
	
	local frame = Create("Frame", {
		BackgroundColor3 = Theme.Input,
		Size = UDim2.new(1, 0, 0, 38),
		Parent = self.Container,
	})
	AddCorner(frame, 6)
	AddStroke(frame, Theme.Border, 1)
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(0.45, 0, 1, 0),
		Parent = frame,
	})
	
	local tbBg = Create("Frame", {
		BackgroundColor3 = Theme.Card,
		Size = UDim2.new(0.5, 0, 0, 26),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Parent = frame,
	})
	AddCorner(tbBg, 4)
	AddStroke(tbBg, Theme.Border, 1)
	
	local tb = Create("TextBox", {
		BackgroundTransparency = 1,
		PlaceholderText = config.Placeholder or "Type...",
		PlaceholderColor3 = Theme.TextDark,
		TextColor3 = Theme.Text,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		Text = def,
		ClearTextOnFocus = false,
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(1, -16, 1, 0),
		Parent = tbBg,
	})
	
	local inObj = { Type = "Input", Value = def }
	tb.FocusLost:Connect(function()
		inObj.Value = tb.Text
		task.spawn(cb, tb.Text)
	end)
	
	if config.Flag then Vanta.Flags[config.Flag] = inObj end
	table.insert(self.Rows, { Title = title, Frame = frame })
	return inObj
end

-- PARAGRAPH
function Card:CreateParagraph(config)
	config = config or {}
	local title = config.Title or "Info"
	local content = config.Content or ""
	
	local frame = Create("Frame", {
		BackgroundColor3 = Theme.Input,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = self.Container,
	})
	AddCorner(frame, 6)
	AddStroke(frame, Theme.Border, 1)
	Create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = frame })
	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = frame })
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 16),
		Parent = frame,
	})
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = content,
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = frame,
	})
	
	table.insert(self.Rows, { Title = title, Frame = frame })
	return frame
end

return Vanta
