--[[
    VantaUI --- Zero-Style Tactical Glass Interface
    Faithful recreation of the premium dark tactical hub aesthetic:
    - Matte charcoal obsidian background with 2-column grid card sections
    - Sidebar with collapsible category trees (Offense, Defense, Player, Visuals)
    - Breadcrumb navigation header with accent path (e.g. "Offense › Perfect Timing")
    - Real-time search filter bar in topbar
    - Rounded checkbox toggles with subtext descriptions
    - Dark dropdown selector with floating overlay
    - Stat labels, sliders, colorpickers, keybinds, and buttons
    - Player profile dock (Headshot thumbnail & masked username)
    - Draggable window with bottom-right resizing grip
    - Pre-login animated loader & key verification modal
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Vanta = {
	Version = "3.2.0",
	Flags = {},
	CurrentWindow = nil,
	ScreenGui = nil,
	Overlay = nil,
	NotificationContainer = nil,
	Open = true,
	ToggleKey = Enum.KeyCode.RightControl,
}

-- [1] THEME DEFINITION (Matching the image: Deep matte obsidian with Coral Crimson accent)
local Theme = {
	Accent = Color3.fromRGB(255, 71, 114),      -- Coral Crimson / Hot Pink
	AccentDim = Color3.fromRGB(190, 45, 80),
	AccentGlow = Color3.fromRGB(255, 90, 130),
	Background = Color3.fromRGB(13, 14, 16),    -- Deep matte obsidian
	Sidebar = Color3.fromRGB(14, 15, 18),       -- Seamless left rail
	Card = Color3.fromRGB(20, 22, 27),          -- Groupbox card background
	CardHover = Color3.fromRGB(24, 26, 33),
	CardHeader = Color3.fromRGB(20, 22, 27),
	Input = Color3.fromRGB(16, 17, 21),         -- Dark input field
	Border = Color3.fromRGB(28, 30, 37),        -- Subtle hairline border
	BorderLight = Color3.fromRGB(42, 46, 56),
	Text = Color3.fromRGB(245, 246, 250),       -- Pure white title text
	TextMuted = Color3.fromRGB(140, 145, 158),   -- Gray description text
	TextDark = Color3.fromRGB(80, 85, 96),       -- Muted placeholders / disabled
	Success = Color3.fromRGB(46, 204, 113),
	Warning = Color3.fromRGB(241, 196, 15),
	Error = Color3.fromRGB(255, 71, 114),
	CheckboxOff = Color3.fromRGB(28, 30, 36),
	CheckboxBorder = Color3.fromRGB(45, 48, 58),
}
Vanta.Theme = Theme

-- Curated Lucide / UI Icons
local Icons = {
	["target"] = "rbxassetid://10734951847",
	["crosshair"] = "rbxassetid://10709769841",
	["gear"] = "rbxassetid://10734950309",
	["settings"] = "rbxassetid://10734950309",
	["dribble"] = "rbxassetid://10723387348",
	["layers"] = "rbxassetid://10723415766",
	["list"] = "rbxassetid://10723416045",
	["shield"] = "rbxassetid://10734950384",
	["user"] = "rbxassetid://10734952861",
	["world"] = "rbxassetid://10734951474",
	["wifi"] = "rbxassetid://10734953184",
	["meter"] = "rbxassetid://10734950020",
	["sliders"] = "rbxassetid://10734950020",
	["chevron-down"] = "rbxassetid://10709790948",
	["search"] = "rbxassetid://10734950117",
	["check"] = "rbxassetid://10709790644",
	["x"] = "rbxassetid://10709791437",
	["lock"] = "rbxassetid://10723416342",
	["key"] = "rbxassetid://10723416280",
}

function Vanta:GetIcon(name)
	if not name or name == "" then return "" end
	if string.sub(name, 1, 13) == "rbxassetid://" or tonumber(name) then
		return tonumber(name) and ("rbxassetid://" .. tostring(name)) or name
	end
	return Icons[name:lower()] or "rbxassetid://10734951847"
end

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
	local tw = TweenService:Create(instance, TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), properties)
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

local function AddShadow(instance, elevation)
	elevation = elevation or 16
	return Create("ImageLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		Image = "rbxassetid://6015897843",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 0.45,
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
			}, 0.05, Enum.EasingStyle.Sine)
		end
	end)
end

local function MakeResizable(grip, target, minSize, maxSize)
	minSize = minSize or Vector2.new(580, 400)
	maxSize = maxSize or Vector2.new(1000, 750)
	local resizing = false
	local startPos, startSize
	
	grip.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			startPos = input.Position
			startSize = target.AbsoluteSize
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					resizing = false
				end
			end)
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - startPos
			local targetW = math.clamp(startSize.X + delta.X, minSize.X, maxSize.X)
			local targetH = math.clamp(startSize.Y + delta.Y, minSize.Y, maxSize.Y)
			target.Size = UDim2.new(0, targetW, 0, targetH)
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
	
	local existing = GetSafeGuiParent():FindFirstChild("VantaTactical_Container")
	if existing then existing:Destroy() end
	
	local screenGui = Create("ScreenGui", {
		Name = "VantaTactical_Container",
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
		BackgroundColor3 = Theme.Card,
		Size = UDim2.new(1, 0, 0, 58),
		ClipsDescendants = true,
		Parent = self.NotificationContainer,
	})
	AddCorner(card, 8)
	AddStroke(card, Theme.Border, 1)
	AddShadow(card, 10)
	
	Create("Frame", {
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 3, 1, 0),
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
	local title = config.Title or "ZERO HUB"
	local subTitle = config.SubTitle or "v3.0.4"
	local validKeys = config.Keys or { "zero-vip", "free", "test" }
	local keyLink = config.KeyLink or "https://discord.gg/vibe"
	local saveFile = config.SaveKeyName or "ZeroKey.txt"
	
	local backdrop = Create("Frame", {
		Name = "AuthBackdrop",
		BackgroundColor3 = Color3.fromRGB(8, 9, 11),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 2000,
		Parent = self.ScreenGui,
	})
	Tween(backdrop, { BackgroundTransparency = 0.35 }, 0.3)
	
	local card = Create("Frame", {
		Name = "AuthCard",
		BackgroundColor3 = Theme.Background,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 370, 0, 195),
		ClipsDescendants = true,
		Parent = backdrop,
	})
	AddCorner(card, 12)
	local stroke = AddStroke(card, Theme.Border, 1.2)
	AddShadow(card, 22)
	
	-- Top Accent Line
	Create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 3),
		Parent = card,
	})
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.new(0, 0, 0, 20),
		Size = UDim2.new(1, 0, 0, 20),
		Parent = card,
	})
	
	local subLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = subTitle,
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.new(0, 0, 0, 42),
		Size = UDim2.new(1, 0, 0, 14),
		Parent = card,
	})
	
	-- STAGE 1: PRE-LOADER
	local loaderBox = Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 28, 0, 75),
		Size = UDim2.new(1, -56, 1, -85),
		Parent = card,
	})
	
	local loadStatus = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "[1/3] INITIALIZING ZERO CLIENT...",
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
		Position = UDim2.new(0, 0, 0, 44),
		Size = UDim2.new(1, 0, 0, 7),
		Parent = loaderBox,
	})
	AddCorner(loadTrack, 4)
	
	local loadFill = Create("Frame", {
		BackgroundColor3 = Theme.Accent,
		Size = UDim2.new(0, 0, 1, 0),
		Parent = loadTrack,
	})
	AddCorner(loadFill, 4)
	
	-- STAGE 2: KEY LOGIN
	local loginBox = Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 28, 0, 75),
		Size = UDim2.new(1, -56, 1, -85),
		Visible = false,
		Parent = card,
	})
	
	local inputFrame = Create("Frame", {
		BackgroundColor3 = Theme.Input,
		Position = UDim2.new(0, 0, 0, 4),
		Size = UDim2.new(1, 0, 0, 36),
		Parent = loginBox,
	})
	AddCorner(inputFrame, 6)
	AddStroke(inputFrame, Theme.Border, 1)
	
	local keyBox = Create("TextBox", {
		BackgroundTransparency = 1,
		PlaceholderText = "Enter license key...",
		PlaceholderColor3 = Theme.TextDark,
		TextColor3 = Theme.Text,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		Text = "",
		ClearTextOnFocus = false,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -75, 1, 0),
		Parent = inputFrame,
	})
	
	local pasteBtn = Create("TextButton", {
		Text = "PASTE",
		TextColor3 = Theme.Accent,
		Font = Enum.Font.GothamBold,
		TextSize = 9,
		BackgroundColor3 = Theme.Card,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.new(0, 48, 0, 24),
		AutoButtonColor = false,
		Parent = inputFrame,
	})
	AddCorner(pasteBtn, 4)
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
		Position = UDim2.new(0, 0, 0, 50),
		Size = UDim2.new(0.48, 0, 0, 32),
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
		Position = UDim2.new(0.52, 0, 0, 50),
		Size = UDim2.new(0.48, 0, 0, 32),
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
	
	-- Auto-load saved key
	pcall(function()
		if readfile and isfile and isfile(saveFile) then
			local saved = readfile(saveFile)
			if saved and saved ~= "" then keyBox.Text = saved end
		end
	end)
	
	-- Run Stage 1 Animation
	task.spawn(function()
		local stages = {
			{ Text = "[1/3] CONNECTING TO CLIENT BACKEND...", Pct = 0.35, Dur = 0.4 },
			{ Text = "[2/3] VERIFYING SYSTEM INTEGRITY...", Pct = 0.70, Dur = 0.45 },
			{ Text = "[3/3] MOUNTING ZERO INTERFACE...", Pct = 1.00, Dur = 0.35 },
		}
		for _, st in ipairs(stages) do
			loadStatus.Text = st.Text
			Tween(loadFill, { Size = UDim2.new(st.Pct, 0, 1, 0) }, st.Dur, Enum.EasingStyle.Sine)
			task.wait(st.Dur + 0.08)
		end
		
		task.wait(0.2)
		subLbl.Text = "LICENSE VERIFICATION"
		subLbl.TextColor3 = Theme.Accent
		loaderBox.Visible = false
		loginBox.Visible = true
	end)
	
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
			loadStatus.Text = "DECRYPTING MODULES..."
			loadStatus.TextColor3 = Theme.Success
			loadFill.BackgroundColor3 = Theme.Success
			loadFill.Size = UDim2.new(0, 0, 1, 0)
			Tween(loadFill, { Size = UDim2.new(1, 0, 1, 0) }, 0.4, Enum.EasingStyle.Sine)
			
			task.wait(0.5)
			Tween(card, { Size = UDim2.new(0, 390, 0, 215), BackgroundTransparency = 1 }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			local tw = Tween(backdrop, { BackgroundTransparency = 1 }, 0.3)
			tw.Completed:Connect(function()
				backdrop:Destroy()
				if onAuthenticated then onAuthenticated() end
			end)
		else
			task.spawn(function()
				local orig = UDim2.new(0.5, 0, 0.5, 0)
				for _, off in ipairs({ -10, 8, -6, 4, -2, 0 }) do
					Tween(card, { Position = UDim2.new(orig.X.Scale, orig.X.Offset + off, orig.Y.Scale, orig.Y.Offset) }, 0.04)
					task.wait(0.04)
				end
			end)
			Tween(stroke, { Color = Theme.Error }, 0.1)
			Vanta:Notify({ Title = "Invalid Key", Content = "The license key entered is incorrect.", Type = "Error", Duration = 3 })
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

-- [6] WINDOW CLASS
local Window = {}
Window.__index = Window

function Vanta:CreateWindow(config)
	self:InitRoot()
	config = config or {}
	local title = config.Title or "Zero Hub"
	local subTitle = config.SubTitle or "v3.0.4"
	local size = config.Size or UDim2.new(0, 720, 0, 480)
	local toggleKey = config.ToggleKey or Enum.KeyCode.RightControl
	local useKeySystem = config.KeySystem ~= nil
	self.ToggleKey = toggleKey
	
	local win = setmetatable({
		Title = title,
		SubTitle = subTitle,
		DefaultSize = size,
		Categories = {},
		Tabs = {},
		ActiveTab = nil,
		Flags = self.Flags,
	}, Window)
	self.CurrentWindow = win
	
	-- Main Window Frame
	local main = Create("Frame", {
		Name = "ZeroHub_Window",
		BackgroundColor3 = Theme.Background,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = size,
		ClipsDescendants = false,
		Parent = self.ScreenGui,
	})
	AddCorner(main, 12)
	AddStroke(main, Theme.Border, 1)
	AddShadow(main, 24)
	win.MainFrame = main
	
	-- 1. SIDEBAR (Width: 190px)
	local sidebar = Create("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = Theme.Sidebar,
		Size = UDim2.new(0, 190, 1, 0),
		Parent = main,
	})
	AddCorner(sidebar, 12)
	
	-- Cover right corners
	Create("Frame", {
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -8, 0, 0),
		Size = UDim2.new(0, 8, 1, 0),
		Parent = sidebar,
	})
	Create("Frame", {
		BackgroundColor3 = Theme.Border,
		BorderSizePixel = 0,
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		Parent = sidebar,
	})
	
	-- Brand Header (Top-Left)
	local brandBox = Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 16),
		Size = UDim2.new(1, -32, 0, 40),
		Parent = sidebar,
	})
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 18),
		Parent = brandBox,
	})
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = subTitle,
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 0, 0, 18),
		Size = UDim2.new(1, 0, 0, 14),
		Parent = brandBox,
	})
	
	-- Navigation Tree Scrolling Container
	local navScroll = Create("ScrollingFrame", {
		Name = "NavTree",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.BorderLight,
		Position = UDim2.new(0, 10, 0, 60),
		Size = UDim2.new(1, -16, 1, -120),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = sidebar,
	})
	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = navScroll })
	win.NavScroll = navScroll
	
	-- Bottom User Profile Dock
	local profileDock = Create("Frame", {
		Name = "ProfileDock",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 1, -50),
		Size = UDim2.new(1, -24, 0, 40),
		Parent = sidebar,
	})
	
	local avatar = Create("ImageLabel", {
		BackgroundColor3 = Theme.Card,
		Position = UDim2.new(0, 0, 0.5, -15),
		Size = UDim2.new(0, 30, 0, 30),
		Parent = profileDock,
	})
	AddCorner(avatar, 15)
	AddStroke(avatar, Theme.Border, 1)
	
	task.spawn(function()
		pcall(function()
			if LocalPlayer then
				avatar.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
			end
		end)
	end)
	
	-- Masked username like the picture: "st************"
	local rawName = LocalPlayer and LocalPlayer.Name or "User"
	local maskedName = string.sub(rawName, 1, 2) .. string.rep("*", math.clamp(#rawName - 2, 4, 12))
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = maskedName,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 38, 0, 0),
		Size = UDim2.new(1, -38, 1, 0),
		Parent = profileDock,
	})
	
	-- 2. TOPBAR HEADER (Draggable, Breadcrumbs & Search)
	local topbar = Create("Frame", {
		Name = "Topbar",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 190, 0, 0),
		Size = UDim2.new(1, -190, 0, 52),
		Parent = main,
	})
	MakeDraggable(topbar, main)
	
	-- Breadcrumbs Label: "Offense › Perfect Timing"
	local breadcrumbContainer = Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 18, 0.5, -10),
		Size = UDim2.new(0.6, 0, 0, 20),
		Parent = topbar,
	})
	
	local pathCatLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "Category",
		TextColor3 = Theme.Accent,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Parent = breadcrumbContainer,
	})
	
	local pathSepLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = " › ",
		TextColor3 = Theme.TextDark,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0, 0, 1, 0),
		Parent = breadcrumbContainer,
	})
	
	local pathTabLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "Tab",
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		Parent = breadcrumbContainer,
	})
	
	local function updateBreadcrumbs(catName, tabName)
		pathCatLbl.Text = catName
		pathTabLbl.Text = tabName
		pathSepLbl.Position = UDim2.new(0, pathCatLbl.AbsoluteSize.X, 0, 0)
		pathTabLbl.Position = UDim2.new(0, pathCatLbl.AbsoluteSize.X + pathSepLbl.AbsoluteSize.X, 0, 0)
	end
	win.UpdateBreadcrumbs = updateBreadcrumbs
	
	-- Search Bar in Topbar
	local searchFrame = Create("Frame", {
		BackgroundColor3 = Theme.Input,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -18, 0.5, 0),
		Size = UDim2.new(0, 150, 0, 26),
		Parent = topbar,
	})
	AddCorner(searchFrame, 6)
	AddStroke(searchFrame, Theme.Border, 1)
	
	Create("ImageLabel", {
		BackgroundTransparency = 1,
		Image = Vanta:GetIcon("search"),
		ImageColor3 = Theme.TextDark,
		Position = UDim2.new(0, 8, 0.5, -6),
		Size = UDim2.new(0, 12, 0, 12),
		Parent = searchFrame,
	})
	
	local searchInput = Create("TextBox", {
		BackgroundTransparency = 1,
		PlaceholderText = "search...",
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
		local q = searchInput.Text:lower()
		if win.ActiveTab then win.ActiveTab:Filter(q) end
	end)
	
	-- 3. CONTENT AREA (Pages Container)
	local content = Create("Frame", {
		Name = "ContentContainer",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 195, 0, 52),
		Size = UDim2.new(1, -205, 1, -58),
		ClipsDescendants = true,
		Parent = main,
	})
	win.ContentContainer = content
	
	-- 4. BOTTOM-RIGHT RESIZE GRIP
	local resizeGrip = Create("TextButton", {
		Name = "ResizeGrip",
		BackgroundTransparency = 1,
		Text = "///",
		TextColor3 = Theme.TextDark,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -4, 1, -4),
		Size = UDim2.new(0, 16, 0, 16),
		AutoButtonColor = false,
		Parent = main,
	})
	MakeResizable(resizeGrip, main)
	
	-- Pre-Login Pipeline
	if useKeySystem then
		main.Visible = false
		Vanta:StartAuthPipeline(config.KeySystem, function()
			main.Visible = true
			main.Size = UDim2.new(0, size.X.Offset * 0.9, 0, size.Y.Offset * 0.9)
			Tween(main, { Size = size }, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end)
	else
		main.Size = UDim2.new(0, size.X.Offset * 0.9, 0, size.Y.Offset * 0.9)
		Tween(main, { Size = size }, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
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

-- [7] CATEGORY FOLDER (Collapsible Group: e.g. "Offense", "Defense", "Player", "Visuals")
local Category = {}
Category.__index = Category

function Window:CreateCategory(title)
	local cat = setmetatable({
		Title = title,
		Window = self,
		Tabs = {},
		Expanded = true,
	}, Category)
	
	-- Category Header Row
	local headerBtn = Create("TextButton", {
		Name = "CatHeader_" .. title,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		Text = "",
		AutoButtonColor = false,
		Parent = self.NavScroll,
	})
	
	local titleLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.TextDark,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 6, 0, 0),
		Size = UDim2.new(1, -30, 1, 0),
		Parent = headerBtn,
	})
	
	local arrowLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "v",
		TextColor3 = Theme.TextDark,
		Font = Enum.Font.GothamBold,
		TextSize = 9,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.new(0, 12, 0, 12),
		Parent = headerBtn,
	})
	
	-- Items container for this category
	local itemsFrame = Create("Frame", {
		Name = "CatItems_" .. title,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = self.NavScroll,
	})
	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), Parent = itemsFrame })
	
	cat.HeaderButton = headerBtn
	cat.ItemsFrame = itemsFrame
	cat.Arrow = arrowLbl
	
	headerBtn.MouseButton1Click:Connect(function()
		cat.Expanded = not cat.Expanded
		itemsFrame.Visible = cat.Expanded
		arrowLbl.Text = cat.Expanded and "v" or ">"
	end)
	
	table.insert(self.Categories, cat)
	return cat
end

-- Backward compatibility: Window:CreateTab creates a tab in default category
function Window:CreateTab(config)
	if #self.Categories == 0 then
		self:CreateCategory("General")
	end
	return self.Categories[1]:CreateTab(config)
end

-- [8] TAB CLASS (Child of Category)
local Tab = {}
Tab.__index = Tab

function Category:CreateTab(config)
	config = config or {}
	local title = config.Title or config.Name or "Tab"
	local icon = config.Icon or "target"
	
	local tab = setmetatable({
		Title = title,
		Category = self,
		Window = self.Window,
		Sections = {},
	}, Tab)
	
	-- Tab Row in Sidebar
	local tabBtn = Create("TextButton", {
		Name = "Tab_" .. title,
		BackgroundColor3 = Theme.Card,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		Text = "",
		AutoButtonColor = false,
		Parent = self.ItemsFrame,
	})
	AddCorner(tabBtn, 6)
	
	-- Left Accent Vertical Indicator Line
	local activeBar = Create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0.15, 0),
		Size = UDim2.new(0, 3, 0.7, 0),
		Visible = false,
		Parent = tabBtn,
	})
	AddCorner(activeBar, 2)
	
	local iconImg = Create("ImageLabel", {
		BackgroundTransparency = 1,
		Image = Vanta:GetIcon(icon),
		ImageColor3 = Theme.TextMuted,
		Position = UDim2.new(0, 10, 0.5, -7),
		Size = UDim2.new(0, 14, 0, 14),
		Parent = tabBtn,
	})
	
	local label = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 32, 0, 0),
		Size = UDim2.new(1, -36, 1, 0),
		Parent = tabBtn,
	})
	
	tab.Button = tabBtn
	tab.Label = label
	tab.Icon = iconImg
	tab.ActiveBar = activeBar
	
	-- 2-Column Multi-Card Page Container
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
		Parent = self.Window.ContentContainer,
	})
	
	-- 2 Column Side-by-Side Holder
	local grid = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -12, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = page,
	})
	
	local leftCol = Create("Frame", {
		Name = "LeftCol",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0.49, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = grid,
	})
	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12), Parent = leftCol })
	
	local rightCol = Create("Frame", {
		Name = "RightCol",
		BackgroundTransparency = 1,
		Position = UDim2.new(0.51, 0, 0, 0),
		Size = UDim2.new(0.49, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = grid,
	})
	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12), Parent = rightCol })
	
	tab.Page = page
	tab.LeftCol = leftCol
	tab.RightCol = rightCol
	
	tabBtn.MouseButton1Click:Connect(function()
		self.Window:SelectTab(tab)
	end)
	
	table.insert(self.Tabs, tab)
	table.insert(self.Window.Tabs, tab)
	
	if #self.Window.Tabs == 1 then
		self.Window:SelectTab(tab)
	end
	
	return tab
end

function Window:SelectTab(selected)
	for _, t in ipairs(self.Tabs) do
		local isSel = (t == selected)
		t.Page.Visible = isSel
		t.ActiveBar.Visible = isSel
		
		if isSel then
			Tween(t.Button, { BackgroundTransparency = 0.88, BackgroundColor3 = Theme.Accent }, 0.15)
			Tween(t.Label, { TextColor3 = Theme.Text }, 0.15)
			Tween(t.Icon, { ImageColor3 = Theme.Accent }, 0.15)
			t.Label.Font = Enum.Font.GothamBold
		else
			Tween(t.Button, { BackgroundTransparency = 1 }, 0.15)
			Tween(t.Label, { TextColor3 = Theme.TextMuted }, 0.15)
			Tween(t.Icon, { ImageColor3 = Theme.TextMuted }, 0.15)
			t.Label.Font = Enum.Font.GothamMedium
		end
	end
	self.ActiveTab = selected
	self.UpdateBreadcrumbs(selected.Category.Title, selected.Title)
end

function Tab:Filter(query)
	for _, sec in ipairs(self.Sections) do
		local secVisible = false
		for _, row in ipairs(sec.Rows) do
			if query == "" or row.Title:lower():find(query, 1, true) then
				row.Frame.Visible = true
				secVisible = true
			else
				row.Frame.Visible = false
			end
		end
		sec.Card.Visible = secVisible
	end
end

-- [9] SECTION CARD (The exact cards from image: "Perfect Timing", "Auto Calibrate", "Ping", "Meter")
local Section = {}
Section.__index = Section

function Tab:CreateSection(config)
	local title, icon, side
	if type(config) == "string" then
		title = config
		side = (#self.Sections % 2 == 0) and "Left" or "Right"
	else
		config = config or {}
		title = config.Title or "Section"
		icon = config.Icon
		side = config.Side or ((#self.Sections % 2 == 0) and "Left" or "Right")
	end
	
	local targetCol = (side == "Right") and self.RightCol or self.LeftCol
	
	local sec = setmetatable({
		Title = title,
		Tab = self,
		Rows = {},
	}, Section)
	
	local card = Create("Frame", {
		Name = "Card_" .. title,
		BackgroundColor3 = Theme.Card,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = targetCol,
	})
	AddCorner(card, 8)
	AddStroke(card, Theme.Border, 1)
	
	-- Card Header
	local header = Create("Frame", {
		BackgroundColor3 = Theme.CardHeader,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		Parent = card,
	})
	
	local headerX = 12
	if icon then
		Create("ImageLabel", {
			BackgroundTransparency = 1,
			Image = Vanta:GetIcon(icon),
			ImageColor3 = Theme.Accent,
			Position = UDim2.new(0, 12, 0.5, -7),
			Size = UDim2.new(0, 14, 0, 14),
			Parent = header,
		})
		headerX = 32
	end
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, headerX, 0, 0),
		Size = UDim2.new(1, -headerX - 30, 1, 0),
		Parent = header,
	})
	
	-- Header chevron arrow (collapse toggle)
	local chevron = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "v",
		TextColor3 = Theme.TextDark,
		Font = Enum.Font.GothamBold,
		TextSize = 9,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0, 12, 0, 12),
		Parent = header,
	})
	
	-- Hairline Divider under Header
	Create("Frame", {
		BackgroundColor3 = Theme.Border,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		Parent = header,
	})
	
	-- Elements container
	local body = Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 34),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = card,
	})
	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = body })
	Create("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = body,
	})
	
	sec.Card = card
	sec.Container = body
	table.insert(self.Sections, sec)
	
	return sec
end

-- [10] EXACT CONTROLS FROM THE USER'S PHOTO

-- 1. TOGGLE (Rounded Checkbox switch with subtext like "Greens every shot...")
function Section:CreateToggle(config)
	config = config or {}
	local title = config.Title or "Toggle"
	local desc = config.Description
	local state = config.Default or false
	local cb = config.Callback or function() end
	
	local row = Create("TextButton", {
		Name = "ToggleRow_" .. title,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, desc and 38 or 24),
		Text = "",
		AutoButtonColor = false,
		Parent = self.Container,
	})
	
	-- Checkbox square (from image: pink checkmark when true, dark square when false)
	local box = Create("Frame", {
		BackgroundColor3 = state and Theme.Accent or Theme.CheckboxOff,
		Position = UDim2.new(0, 0, 0, 2),
		Size = UDim2.new(0, 16, 0, 16),
		Parent = row,
	})
	AddCorner(box, 4)
	AddStroke(box, state and Theme.Accent or Theme.CheckboxBorder, 1)
	
	local checkIcon = Create("ImageLabel", {
		BackgroundTransparency = 1,
		Image = Vanta:GetIcon("check"),
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0.5, -5, 0.5, -5),
		Size = UDim2.new(0, 10, 0, 10),
		Visible = state,
		Parent = box,
	})
	
	local titleLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 24, 0, 1),
		Size = UDim2.new(1, -24, 0, 16),
		Parent = row,
	})
	
	if desc then
		Create("TextLabel", {
			BackgroundTransparency = 1,
			Text = desc,
			TextColor3 = Theme.TextMuted,
			Font = Enum.Font.Gotham,
			TextSize = 10,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 24, 0, 18),
			Size = UDim2.new(1, -24, 0, 18),
			Parent = row,
		})
	end
	
	local toggleObj = { Type = "Toggle", Value = state }
	function toggleObj:Set(val)
		state = val
		self.Value = val
		checkIcon.Visible = state
		Tween(box, { BackgroundColor3 = state and Theme.Accent or Theme.CheckboxOff }, 0.15)
		task.spawn(cb, state)
	end
	
	row.MouseButton1Click:Connect(function()
		toggleObj:Set(not state)
	end)
	
	if config.Flag then Vanta.Flags[config.Flag] = toggleObj end
	table.insert(self.Rows, { Title = title, Frame = row })
	return toggleObj
end

-- 2. STAT / INFO LABEL (Exact label from image: "Ping: 40ms")
function Section:CreateLabel(text)
	local lbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = text or "",
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 16),
		Parent = self.Container,
	})
	table.insert(self.Rows, { Title = text, Frame = lbl })
	return {
		Set = function(_, newText) lbl.Text = newText end
	}
end

-- 3. DROPDOWN (Exact dropdown from image: "Change Meter" -> "Vertical v")
function Section:CreateDropdown(config)
	config = config or {}
	local title = config.Title or "Dropdown"
	local desc = config.Description
	local opts = config.Options or { "Option" }
	local cur = config.Default or opts[1]
	local cb = config.Callback or function() end
	local isOpen = false
	
	local wrapper = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, desc and 62 or 46),
		Parent = self.Container,
	})
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 16),
		Parent = wrapper,
	})
	
	local box = Create("TextButton", {
		BackgroundColor3 = Theme.Input,
		Position = UDim2.new(0, 0, 0, 18),
		Size = UDim2.new(1, 0, 0, 26),
		Text = "",
		AutoButtonColor = false,
		Parent = wrapper,
	})
	AddCorner(box, 4)
	AddStroke(box, Theme.Border, 1)
	
	local dispLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = tostring(cur or "Select..."),
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(1, -24, 1, 0),
		Parent = box,
	})
	
	local arrow = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "v",
		TextColor3 = Theme.TextDark,
		Font = Enum.Font.GothamBold,
		TextSize = 9,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0, 12, 0, 12),
		Parent = box,
	})
	
	if desc then
		Create("TextLabel", {
			BackgroundTransparency = 1,
			Text = desc,
			TextColor3 = Theme.TextMuted,
			Font = Enum.Font.Gotham,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 0, 0, 48),
			Size = UDim2.new(1, 0, 0, 14),
			Parent = wrapper,
		})
	end
	
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
	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), Parent = menu })
	Create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), Parent = menu })
	
	local dropObj = { Type = "Dropdown", Value = cur, Options = opts }
	function dropObj:Set(newVal)
		cur = newVal
		self.Value = newVal
		dispLbl.Text = tostring(newVal)
		task.spawn(cb, newVal)
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
		optBtn.MouseEnter:Connect(function() Tween(optBtn, { BackgroundTransparency = 0.85, BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Text }, 0.1) end)
		optBtn.MouseLeave:Connect(function() Tween(optBtn, { BackgroundTransparency = 1, TextColor3 = Theme.TextMuted }, 0.1) end)
		optBtn.MouseButton1Click:Connect(function()
			dropObj:Set(opt)
			isOpen = false
			menu.Visible = false
		end)
	end
	
	box.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		if isOpen then
			local abs = box.AbsolutePosition
			local sz = box.AbsoluteSize
			menu.Position = UDim2.new(0, abs.X, 0, abs.Y + sz.Y + 4)
			menu.Size = UDim2.new(0, sz.X, 0, math.min(#opts * 26 + 10, 130))
			menu.Visible = true
		else
			menu.Visible = false
		end
	end)
	
	if config.Flag then Vanta.Flags[config.Flag] = dropObj end
	table.insert(self.Rows, { Title = title, Frame = wrapper })
	return dropObj
end

-- 4. SLIDER
function Section:CreateSlider(config)
	config = config or {}
	local title = config.Title or "Slider"
	local min = config.Min or 0
	local max = config.Max or 100
	local cur = config.Default or min
	local step = config.Step or 1
	local sfx = config.Suffix or ""
	local cb = config.Callback or function() end
	
	local frame = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 38),
		Parent = self.Container,
	})
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -60, 0, 16),
		Parent = frame,
	})
	
	local valLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = tostring(cur) .. sfx,
		TextColor3 = Theme.Accent,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -60, 0, 0),
		Size = UDim2.new(0, 60, 0, 16),
		Parent = frame,
	})
	
	local track = Create("TextButton", {
		Text = "",
		BackgroundColor3 = Theme.Input,
		Position = UDim2.new(0, 0, 0, 22),
		Size = UDim2.new(1, 0, 0, 6),
		AutoButtonColor = false,
		Parent = frame,
	})
	AddCorner(track, 3)
	AddStroke(track, Theme.Border, 1)
	
	local fill = Create("Frame", {
		BackgroundColor3 = Theme.Accent,
		Size = UDim2.new(math.clamp((cur - min) / (max - min), 0, 1), 0, 1, 0),
		Parent = track,
	})
	AddCorner(fill, 3)
	
	local sliderObj = { Type = "Slider", Value = cur }
	local function update(xPos)
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
		Tween(fill, { Size = UDim2.new((val - min) / (max - min), 0, 1, 0) }, 0.06)
		task.spawn(cb, val)
	end
	
	local dragging = false
	track.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			update(inp.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			update(inp.Position.X)
		end
	end)
	
	if config.Flag then Vanta.Flags[config.Flag] = sliderObj end
	table.insert(self.Rows, { Title = title, Frame = frame })
	return sliderObj
end

-- 5. BUTTON
function Section:CreateButton(config)
	config = config or {}
	local title = config.Title or "Button"
	local cb = config.Callback or function() end
	
	local btn = Create("TextButton", {
		BackgroundColor3 = Theme.Input,
		Size = UDim2.new(1, 0, 0, 28),
		Text = title,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		AutoButtonColor = false,
		Parent = self.Container,
	})
	AddCorner(btn, 6)
	AddStroke(btn, Theme.Border, 1)
	
	btn.MouseEnter:Connect(function() Tween(btn, { BackgroundColor3 = Theme.CardHover }, 0.15) end)
	btn.MouseLeave:Connect(function() Tween(btn, { BackgroundColor3 = Theme.Input }, 0.15) end)
	btn.MouseButton1Down:Connect(function() Tween(btn, { BackgroundColor3 = Theme.AccentDim }, 0.1) end)
	btn.MouseButton1Up:Connect(function()
		Tween(btn, { BackgroundColor3 = Theme.CardHover }, 0.1)
		task.spawn(cb)
	end)
	
	table.insert(self.Rows, { Title = title, Frame = btn })
	return btn
end

-- 6. COLORPICKER
function Section:CreateColorPicker(config)
	config = config or {}
	local title = config.Title or "Color"
	local cur = config.Default or Theme.Accent
	local cb = config.Callback or function() end
	local isOpen = false
	
	local frame = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		Parent = self.Container,
	})
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -40, 1, 0),
		Parent = frame,
	})
	
	local swatch = Create("TextButton", {
		Text = "",
		BackgroundColor3 = cur,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 28, 0, 16),
		AutoButtonColor = false,
		Parent = frame,
	})
	AddCorner(swatch, 4)
	AddStroke(swatch, Theme.BorderLight, 1)
	
	local palette = Create("Frame", {
		BackgroundColor3 = Theme.Card,
		Size = UDim2.new(0, 160, 0, 80),
		Visible = false,
		Parent = Vanta.Overlay,
	})
	AddCorner(palette, 6)
	AddStroke(palette, Theme.Border, 1)
	AddShadow(palette, 10)
	
	local pGrid = Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 8),
		Size = UDim2.new(1, -16, 1, -16),
		Parent = palette,
	})
	Create("UIGridLayout", { CellSize = UDim2.new(0, 30, 0, 26), CellPadding = UDim2.new(0, 6, 0, 6), Parent = pGrid })
	
	local presets = {
		Theme.Accent,
		Color3.fromRGB(0, 210, 255),
		Color3.fromRGB(16, 185, 129),
		Color3.fromRGB(245, 158, 11),
		Color3.fromRGB(168, 85, 247),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(180, 185, 195),
		Color3.fromRGB(35, 38, 48),
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
			palette.Position = UDim2.new(0, abs.X - 130, 0, abs.Y + 22)
			palette.Visible = true
		else
			palette.Visible = false
		end
	end)
	
	if config.Flag then Vanta.Flags[config.Flag] = colObj end
	table.insert(self.Rows, { Title = title, Frame = frame })
	return colObj
end

-- 7. KEYBIND
function Section:CreateKeybind(config)
	config = config or {}
	local title = config.Title or "Keybind"
	local cur = config.Default or Enum.KeyCode.E
	local cb = config.Callback or function() end
	local listening = false
	
	local frame = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		Parent = self.Container,
	})
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -70, 1, 0),
		Parent = frame,
	})
	
	local bindBtn = Create("TextButton", {
		Text = cur and "[" .. cur.Name .. "]" or "[None]",
		TextColor3 = Theme.Accent,
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		BackgroundColor3 = Theme.Input,
		Size = UDim2.new(0, 60, 0, 20),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
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

-- 8. INPUT
function Section:CreateInput(config)
	config = config or {}
	local title = config.Title or "Input"
	local def = config.Default or ""
	local cb = config.Callback or function() end
	
	local frame = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 42),
		Parent = self.Container,
	})
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 16),
		Parent = frame,
	})
	
	local box = Create("TextBox", {
		BackgroundColor3 = Theme.Input,
		PlaceholderText = config.Placeholder or "Enter...",
		PlaceholderColor3 = Theme.TextDark,
		TextColor3 = Theme.Text,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		Text = def,
		ClearTextOnFocus = false,
		Position = UDim2.new(0, 0, 0, 18),
		Size = UDim2.new(1, 0, 0, 24),
		Parent = frame,
	})
	AddCorner(box, 4)
	AddStroke(box, Theme.Border, 1)
	
	local inObj = { Type = "Input", Value = def }
	box.FocusLost:Connect(function()
		inObj.Value = box.Text
		task.spawn(cb, box.Text)
	end)
	
	if config.Flag then Vanta.Flags[config.Flag] = inObj end
	table.insert(self.Rows, { Title = title, Frame = frame })
	return inObj
end

return Vanta
