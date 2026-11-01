--[[
    Aesthetic Interface Suite
    Faithful recreation of the clean dark client interface:
    - Top bar with User Profile (Avatar & Name) on the top-left
    - Module search bar with "CTRL + F" shortcut hint
    - Left sidebar with sections (Combat, Movement, Visuals, Player, Misc, Configs)
    - 2-Column modular cards layout with clean iOS pill switches
    - Nested module settings (Sliders, Dropdowns, Toggles, Labels, Buttons)
    - Draggable window with smooth dragging
    - Single self-contained runnable file: just run / execute directly!
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- [1] THEME PALETTE
local Theme = {
	Background = Color3.fromRGB(15, 16, 19),      -- Deep matte obsidian
	Sidebar = Color3.fromRGB(13, 14, 17),         -- Darker left dock
	Card = Color3.fromRGB(19, 21, 26),            -- Module card background
	CardHover = Color3.fromRGB(23, 25, 32),
	CardHeader = Color3.fromRGB(21, 23, 29),
	Input = Color3.fromRGB(20, 22, 27),           -- Search bar / text fields
	InputHover = Color3.fromRGB(25, 28, 35),
	Border = Color3.fromRGB(28, 31, 38),          -- 1px hairline border
	BorderLight = Color3.fromRGB(40, 44, 55),
	Text = Color3.fromRGB(238, 240, 246),         -- White main text
	TextMuted = Color3.fromRGB(135, 141, 155),     -- Subtitles & labels
	TextDark = Color3.fromRGB(75, 80, 94),         -- Section tags & shortcuts
	Accent = Color3.fromRGB(75, 140, 255),        -- Crisp Icy Blue accent
	AccentDim = Color3.fromRGB(50, 100, 190),
	SwitchOff = Color3.fromRGB(34, 37, 46),
	SwitchKnobOff = Color3.fromRGB(115, 122, 136),
	SwitchOn = Color3.fromRGB(75, 140, 255),
	SwitchKnobOn = Color3.fromRGB(255, 255, 255),
}

-- [2] DOM HELPERS
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

local function Tween(inst, props, dur, style, dir)
	local tw = TweenService:Create(inst, TweenInfo.new(dur or 0.16, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function AddCorner(inst, radius)
	return Create("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = inst })
end

local function AddStroke(inst, color, thickness)
	return Create("UIStroke", {
		Color = color or Theme.Border,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = inst,
	})
end

local function AddShadow(inst, elevation)
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
		ZIndex = math.max(1, inst.ZIndex - 1),
		Parent = inst,
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

-- [3] MASTER AESTHETIC SUITE
local Aesthetic = {
	ScreenGui = nil,
	Overlay = nil,
	CurrentWindow = nil,
	Tabs = {},
	ActiveTab = nil,
	Open = true,
	ToggleKey = Enum.KeyCode.RightControl,
}

function Aesthetic:InitRoot()
	if self.ScreenGui and self.ScreenGui.Parent then return end
	
	local existing = GetSafeGuiParent():FindFirstChild("AestheticClient_GUI")
	if existing then existing:Destroy() end
	
	local gui = Create("ScreenGui", {
		Name = "AestheticClient_GUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 9999,
		Parent = GetSafeGuiParent(),
	})
	
	if syn and syn.protect_gui then
		pcall(syn.protect_gui, gui)
	elseif typeof(protectgui) == "function" then
		pcall(protectgui, gui)
	end
	
	-- Floating overlay for dropdowns
	local overlay = Create("Frame", {
		Name = "Overlay",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 500,
		Parent = gui,
	})
	
	self.ScreenGui = gui
	self.Overlay = overlay
	
	-- Global Toggle Key listener (RightControl / Insert)
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe and UserInputService:GetFocusedTextBox() then return end
		if input.KeyCode == self.ToggleKey then
			self:Toggle()
		end
	end)
end

function Aesthetic:Toggle()
	self.Open = not self.Open
	if self.CurrentWindow and self.CurrentWindow.MainFrame then
		local frame = self.CurrentWindow.MainFrame
		if self.Open then
			frame.Visible = true
			Tween(frame, { Size = self.CurrentWindow.DefaultSize }, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		else
			local tw = Tween(frame, { Size = UDim2.new(0, self.CurrentWindow.DefaultSize.X.Offset * 0.95, 0, self.CurrentWindow.DefaultSize.Y.Offset * 0.95) }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			tw.Completed:Connect(function()
				if not self.Open then frame.Visible = false end
			end)
		end
	end
end

-- [4] WINDOW BUILDER
function Aesthetic:CreateWindow(config)
	self:InitRoot()
	config = config or {}
	local title = config.Title or "Aesthetic"
	local subTitle = config.SubTitle or "Release 1.4 • build 257"
	local size = config.Size or UDim2.new(0, 760, 0, 480)
	
	local win = {
		Title = title,
		SubTitle = subTitle,
		DefaultSize = size,
		Tabs = {},
		ActiveTab = nil,
	}
	self.CurrentWindow = win
	
	-- Main Floating Frame
	local main = Create("Frame", {
		Name = "MainWindow",
		BackgroundColor3 = Theme.Background,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = size,
		ClipsDescendants = false,
		Parent = self.ScreenGui,
	})
	AddCorner(main, 10)
	AddStroke(main, Theme.Border, 1)
	AddShadow(main, 20)
	win.MainFrame = main
	
	-----------------------------------------------------------------
	-- 1. TOP BAR (User in Top Left + Name + Module Search)
	-----------------------------------------------------------------
	local topbar = Create("Frame", {
		Name = "Topbar",
		BackgroundColor3 = Theme.Background,
		Size = UDim2.new(1, 0, 0, 52),
		Parent = main,
	})
	AddCorner(topbar, 10)
	Create("Frame", { BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -8), Size = UDim2.new(1, 0, 0, 8), Parent = topbar })
	Create("Frame", { BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), Parent = topbar })
	MakeDraggable(topbar, main)
	
	-- USER IN TOP LEFT (Headshot Avatar + Name)
	local userBox = Create("Frame", {
		Name = "UserBox",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 8),
		Size = UDim2.new(0, 160, 0, 36),
		Parent = topbar,
	})
	
	local avatarImg = Create("ImageLabel", {
		BackgroundColor3 = Theme.Card,
		Position = UDim2.new(0, 0, 0.5, -15),
		Size = UDim2.new(0, 30, 0, 30),
		Parent = userBox,
	})
	AddCorner(avatarImg, 15)
	AddStroke(avatarImg, Theme.Border, 1)
	
	task.spawn(function()
		pcall(function()
			if LocalPlayer then
				avatarImg.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
			end
		end)
	end)
	
	local userNameLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = LocalPlayer and LocalPlayer.DisplayName or "User",
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 38, 0, 2),
		Size = UDim2.new(1, -38, 0, 16),
		Parent = userBox,
	})
	
	local userTagLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "@" .. (LocalPlayer and LocalPlayer.Name or "player"),
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 38, 0, 18),
		Size = UDim2.new(1, -38, 0, 14),
		Parent = userBox,
	})
	
	-- CLIENT BRAND (Aesthetic / Version)
	local brandBox = Create("Frame", {
		Name = "BrandBox",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 185, 0, 8),
		Size = UDim2.new(0, 160, 0, 36),
		Parent = topbar,
	})
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 0, 0, 2),
		Size = UDim2.new(1, 0, 0, 16),
		Parent = brandBox,
	})
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = subTitle,
		TextColor3 = Theme.TextDark,
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 0, 0, 18),
		Size = UDim2.new(1, 0, 0, 14),
		Parent = brandBox,
	})
	
	-- MODULE SEARCH BAR (From screenshot: "🔍 Поиск настроек...   CTRL + F")
	local searchFrame = Create("Frame", {
		Name = "SearchBar",
		BackgroundColor3 = Theme.Input,
		Position = UDim2.new(0, 370, 0.5, -14),
		Size = UDim2.new(0, 260, 0, 28),
		Parent = topbar,
	})
	AddCorner(searchFrame, 6)
	AddStroke(searchFrame, Theme.Border, 1)
	
	-- Search Icon
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "🔍",
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.Gotham,
		TextSize = 10,
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(0, 16, 1, 0),
		Parent = searchFrame,
	})
	
	local searchInput = Create("TextBox", {
		BackgroundTransparency = 1,
		PlaceholderText = "Search modules...",
		PlaceholderColor3 = Theme.TextDark,
		TextColor3 = Theme.Text,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		Text = "",
		ClearTextOnFocus = false,
		Position = UDim2.new(0, 28, 0, 0),
		Size = UDim2.new(1, -95, 1, 0),
		Parent = searchFrame,
	})
	
	-- "CTRL + F" Shortcut Pill
	local shortcutPill = Create("TextLabel", {
		BackgroundColor3 = Theme.Sidebar,
		Text = "CTRL + F",
		TextColor3 = Theme.TextDark,
		Font = Enum.Font.GothamBold,
		TextSize = 9,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.new(0, 56, 0, 18),
		Parent = searchFrame,
	})
	AddCorner(shortcutPill, 4)
	AddStroke(shortcutPill, Theme.Border, 1)
	
	-- Search Filter logic
	searchInput:GetPropertyChangedSignal("Text"):Connect(function()
		local query = searchInput.Text:lower()
		if win.ActiveTab then
			win.ActiveTab:Filter(query)
		end
	end)
	
	-- Close Button
	local closeBtn = Create("TextButton", {
		Text = "×",
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamMedium,
		TextSize = 18,
		BackgroundColor3 = Theme.Card,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.new(0, 26, 0, 26),
		AutoButtonColor = false,
		Parent = topbar,
	})
	AddCorner(closeBtn, 6)
	AddStroke(closeBtn, Theme.Border, 1)
	closeBtn.MouseButton1Click:Connect(function()
		Aesthetic:Toggle()
	end)
	
	-----------------------------------------------------------------
	-- 2. LEFT SIDEBAR (Tabs & Sections)
	-----------------------------------------------------------------
	local sidebar = Create("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = Theme.Sidebar,
		Position = UDim2.new(0, 0, 0, 52),
		Size = UDim2.new(0, 175, 1, -52),
		Parent = main,
	})
	AddCorner(sidebar, 10)
	Create("Frame", { BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0, Position = UDim2.new(1, -8, 0, 0), Size = UDim2.new(0, 8, 1, 0), Parent = sidebar })
	Create("Frame", { BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 1, 1, 0), Parent = sidebar })
	
	-- Section Tag (From screenshot: "РАЗДЕЛЫ" / SECTIONS)
	local sectionTag = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "SECTIONS",
		TextColor3 = Theme.TextDark,
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 16, 0, 12),
		Size = UDim2.new(1, -32, 0, 16),
		Parent = sidebar,
	})
	
	-- Tab buttons scrolling frame
	local tabList = Create("ScrollingFrame", {
		Name = "TabList",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.BorderLight,
		Position = UDim2.new(0, 10, 0, 34),
		Size = UDim2.new(1, -20, 1, -75),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = sidebar,
	})
	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = tabList })
	win.TabList = tabList
	
	-- Bottom Left: Collapse Sidebar Button
	local collapseBtn = Create("TextButton", {
		Name = "CollapseSidebar",
		BackgroundTransparency = 1,
		Text = "",
		Position = UDim2.new(0, 12, 1, -34),
		Size = UDim2.new(1, -24, 0, 24),
		AutoButtonColor = false,
		Parent = sidebar,
	})
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "⇤  Collapse sidebar",
		TextColor3 = Theme.TextDark,
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 1, 0),
		Parent = collapseBtn,
	})
	
	local sidebarCollapsed = false
	collapseBtn.MouseButton1Click:Connect(function()
		sidebarCollapsed = not sidebarCollapsed
		if sidebarCollapsed then
			Tween(sidebar, { Size = UDim2.new(0, 52, 1, -52) }, 0.2)
			Tween(win.ContentContainer, { Position = UDim2.new(0, 62, 0, 60), Size = UDim2.new(1, -74, 1, -70) }, 0.2)
			sectionTag.Visible = false
		else
			Tween(sidebar, { Size = UDim2.new(0, 175, 1, -52) }, 0.2)
			Tween(win.ContentContainer, { Position = UDim2.new(0, 185, 0, 60), Size = UDim2.new(1, -195, 1, -70) }, 0.2)
			sectionTag.Visible = true
		end
	end)
	
	-----------------------------------------------------------------
	-- 3. CONTENT CONTAINER (Pages)
	-----------------------------------------------------------------
	local content = Create("Frame", {
		Name = "ContentContainer",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 185, 0, 60),
		Size = UDim2.new(1, -195, 1, -70),
		ClipsDescendants = true,
		Parent = main,
	})
	win.ContentContainer = content
	
	return win
end

-- [5] TAB CLASS
local Tab = {}
Tab.__index = Tab

function Aesthetic.CurrentWindow:CreateTab(config)
	config = config or {}
	local title = config.Title or config.Name or "Tab"
	local iconGlyph = config.Icon or "⚡"
	
	local tab = setmetatable({
		Title = title,
		Window = self,
		Modules = {},
	}, Tab)
	
	-- Sidebar Button
	local tabBtn = Create("TextButton", {
		Name = "Tab_" .. title,
		BackgroundColor3 = Theme.Card,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
		Text = "",
		AutoButtonColor = false,
		Parent = self.TabList,
	})
	AddCorner(tabBtn, 6)
	
	local iconLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = iconGlyph,
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(0, 16, 1, 0),
		Parent = tabBtn,
	})
	
	local titleLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 34, 0, 0),
		Size = UDim2.new(1, -40, 1, 0),
		Parent = tabBtn,
	})
	
	tab.Button = tabBtn
	tab.Icon = iconLbl
	tab.Label = titleLbl
	
	-- 2-Column Page Scrolling Frame
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
	
	-- 2-Column Grid
	local grid = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 0),
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
	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = leftCol })
	
	local rightCol = Create("Frame", {
		Name = "RightCol",
		BackgroundTransparency = 1,
		Position = UDim2.new(0.51, 0, 0, 0),
		Size = UDim2.new(0.49, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = grid,
	})
	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = rightCol })
	
	tab.Page = page
	tab.LeftCol = leftCol
	tab.RightCol = rightCol
	
	tabBtn.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)
	
	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 then
		self:SelectTab(tab)
	end
	
	return tab
end

function Aesthetic.CurrentWindow:SelectTab(selected)
	for _, t in ipairs(self.Tabs) do
		local isSel = (t == selected)
		t.Page.Visible = isSel
		if isSel then
			Tween(t.Button, { BackgroundTransparency = 0.82, BackgroundColor3 = Theme.CardHover }, 0.15)
			Tween(t.Label, { TextColor3 = Theme.Text }, 0.15)
			Tween(t.Icon, { TextColor3 = Theme.Accent }, 0.15)
			t.Label.Font = Enum.Font.GothamBold
		else
			Tween(t.Button, { BackgroundTransparency = 1 }, 0.15)
			Tween(t.Label, { TextColor3 = Theme.TextMuted }, 0.15)
			Tween(t.Icon, { TextColor3 = Theme.TextMuted }, 0.15)
			t.Label.Font = Enum.Font.GothamMedium
		end
	end
	self.ActiveTab = selected
end

function Tab:Filter(query)
	for _, mod in ipairs(self.Modules) do
		if query == "" or mod.Title:lower():find(query, 1, true) then
			mod.Card.Visible = true
		else
			mod.Card.Visible = false
		end
	end
end

-- [6] MODULE CARD (Matching the screenshot: AccountHelper, PvP Bot, AutoSell, Region Helper)
local Module = {}
Module.__index = Module

function Tab:CreateModule(config)
	config = config or {}
	local title = config.Title or "Module"
	local iconGlyph = config.Icon or "❖"
	local defaultState = config.Default or false
	local side = config.Side or ((#self.Modules % 2 == 0) and "Left" or "Right")
	local cb = config.Callback or function() end
	
	local targetCol = (side == "Right") and self.RightCol or self.LeftCol
	
	local mod = setmetatable({
		Title = title,
		Tab = self,
		State = defaultState,
	}, Module)
	
	-- Card Frame
	local card = Create("Frame", {
		Name = "Module_" .. title,
		BackgroundColor3 = Theme.Card,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = targetCol,
	})
	AddCorner(card, 8)
	AddStroke(card, Theme.Border, 1)
	
	-- Card Header Row
	local header = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
		Parent = card,
	})
	
	local iconLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = iconGlyph,
		TextColor3 = defaultState and Theme.Accent or Theme.TextMuted,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(0, 16, 1, 0),
		Parent = header,
	})
	
	local titleLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 34, 0, 0),
		Size = UDim2.new(1, -85, 1, 0),
		Parent = header,
	})
	
	-- iOS Style Pill Switch (From Screenshot)
	local switch = Create("TextButton", {
		Name = "Switch",
		BackgroundColor3 = defaultState and Theme.SwitchOn or Theme.SwitchOff,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0, 34, 0, 18),
		Text = "",
		AutoButtonColor = false,
		Parent = header,
	})
	AddCorner(switch, 9)
	
	local knob = Create("Frame", {
		BackgroundColor3 = defaultState and Theme.SwitchKnobOn or Theme.SwitchKnobOff,
		Position = defaultState and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
		Size = UDim2.new(0, 14, 0, 14),
		Parent = switch,
	})
	AddCorner(knob, 7)
	
	-- Sub-Settings Body Container (Nested inside card)
	local body = Create("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 36),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = card,
	})
	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = body })
	Create("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = body,
	})
	
	function mod:Set(val)
		self.State = val
		if val then
			Tween(switch, { BackgroundColor3 = Theme.SwitchOn }, 0.15)
			Tween(knob, { Position = UDim2.new(1, -16, 0.5, -7), BackgroundColor3 = Theme.SwitchKnobOn }, 0.15)
			Tween(iconLbl, { TextColor3 = Theme.Accent }, 0.15)
		else
			Tween(switch, { BackgroundColor3 = Theme.SwitchOff }, 0.15)
			Tween(knob, { Position = UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Theme.SwitchKnobOff }, 0.15)
			Tween(iconLbl, { TextColor3 = Theme.TextMuted }, 0.15)
		end
		task.spawn(cb, val)
	end
	
	switch.MouseButton1Click:Connect(function()
		mod:Set(not mod.State)
	end)
	
	mod.Card = card
	mod.Container = body
	table.insert(self.Modules, mod)
	
	return mod
end

-- Backward compatibility alias: CreateSection creates a Module
Tab.CreateSection = Tab.CreateModule

-- [7] NESTED CONTROLS (INSIDE MODULES)

-- 1. SUB-TOGGLE (Indented checkbox/switch)
function Module:CreateToggle(config)
	config = config or {}
	local title = config.Title or "Toggle"
	local desc = config.Description
	local state = config.Default or false
	local cb = config.Callback or function() end
	
	local row = Create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, desc and 34 or 22),
		Text = "",
		AutoButtonColor = false,
		Parent = self.Container,
	})
	
	local titleLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -35, 0, 16),
		Parent = row,
	})
	
	if desc then
		Create("TextLabel", {
			BackgroundTransparency = 1,
			Text = desc,
			TextColor3 = Theme.TextDark,
			Font = Enum.Font.Gotham,
			TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 0, 0, 16),
			Size = UDim2.new(1, -35, 0, 14),
			Parent = row,
		})
	end
	
	-- Small pill switch
	local sw = Create("Frame", {
		BackgroundColor3 = state and Theme.SwitchOn or Theme.SwitchOff,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 28, 0, 14),
		Parent = row,
	})
	AddCorner(sw, 7)
	
	local kn = Create("Frame", {
		BackgroundColor3 = state and Theme.SwitchKnobOn or Theme.SwitchKnobOff,
		Position = state and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5),
		Size = UDim2.new(0, 10, 0, 10),
		Parent = sw,
	})
	AddCorner(kn, 5)
	
	local function setVal(v)
		state = v
		if state then
			Tween(sw, { BackgroundColor3 = Theme.SwitchOn }, 0.15)
			Tween(kn, { Position = UDim2.new(1, -12, 0.5, -5), BackgroundColor3 = Theme.SwitchKnobOn }, 0.15)
			titleLbl.TextColor3 = Theme.Text
		else
			Tween(sw, { BackgroundColor3 = Theme.SwitchOff }, 0.15)
			Tween(kn, { Position = UDim2.new(0, 2, 0.5, -5), BackgroundColor3 = Theme.SwitchKnobOff }, 0.15)
			titleLbl.TextColor3 = Theme.TextMuted
		end
		task.spawn(cb, state)
	end
	
	row.MouseButton1Click:Connect(function() setVal(not state) end)
	return { Set = setVal }
end

-- 2. SLIDER
function Module:CreateSlider(config)
	config = config or {}
	local title = config.Title or "Slider"
	local min = config.Min or 0
	local max = config.Max or 100
	local cur = config.Default or min
	local step = config.Step or 1
	local sfx = config.Suffix or ""
	local cb = config.Callback or function() end
	
	local row = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
		Parent = self.Container,
	})
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -50, 0, 14),
		Parent = row,
	})
	
	local valLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = tostring(cur) .. sfx,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -50, 0, 0),
		Size = UDim2.new(0, 50, 0, 14),
		Parent = row,
	})
	
	local track = Create("TextButton", {
		Text = "",
		BackgroundColor3 = Theme.Input,
		Position = UDim2.new(0, 0, 0, 20),
		Size = UDim2.new(1, 0, 0, 4),
		AutoButtonColor = false,
		Parent = row,
	})
	AddCorner(track, 2)
	
	local fill = Create("Frame", {
		BackgroundColor3 = Theme.Accent,
		Size = UDim2.new(math.clamp((cur - min) / (max - min), 0, 1), 0, 1, 0),
		Parent = track,
	})
	AddCorner(fill, 2)
	
	local function update(xPos)
		local w = track.AbsoluteSize.X
		local relX = math.clamp(xPos - track.AbsolutePosition.X, 0, w)
		local raw = min + (max - min) * (relX / w)
		local stepped = math.floor((raw / step) + 0.5) * step
		stepped = math.clamp(stepped, min, max)
		cur = stepped
		valLbl.Text = tostring(cur) .. sfx
		Tween(fill, { Size = UDim2.new((cur - min) / (max - min), 0, 1, 0) }, 0.05)
		task.spawn(cb, cur)
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
	
	return { Set = function(_, v) cur = v; valLbl.Text = tostring(v) .. sfx; fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0) end }
end

-- 3. DROPDOWN
function Module:CreateDropdown(config)
	config = config or {}
	local title = config.Title or "Dropdown"
	local opts = config.Options or { "Option" }
	local cur = config.Default or opts[1]
	local cb = config.Callback or function() end
	local isOpen = false
	
	local row = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		Parent = self.Container,
	})
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0.45, 0, 1, 0),
		Parent = row,
	})
	
	local box = Create("TextButton", {
		BackgroundColor3 = Theme.Input,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0.52, 0, 0, 22),
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	AddCorner(box, 4)
	AddStroke(box, Theme.Border, 1)
	
	local dispLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = tostring(cur),
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 6, 0, 0),
		Size = UDim2.new(1, -20, 1, 0),
		Parent = box,
	})
	
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "v",
		TextColor3 = Theme.TextDark,
		Font = Enum.Font.GothamBold,
		TextSize = 8,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.new(0, 10, 0, 10),
		Parent = box,
	})
	
	local menu = Create("ScrollingFrame", {
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.BorderLight,
		Size = UDim2.new(0, 160, 0, 0),
		Visible = false,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = Aesthetic.Overlay,
	})
	AddCorner(menu, 6)
	AddStroke(menu, Theme.Border, 1)
	AddShadow(menu, 10)
	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), Parent = menu })
	Create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), Parent = menu })
	
	for _, opt in ipairs(opts) do
		local optBtn = Create("TextButton", {
			Text = opt,
			TextColor3 = Theme.TextMuted,
			Font = Enum.Font.Gotham,
			TextSize = 10,
			BackgroundColor3 = Theme.Input,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 22),
			AutoButtonColor = false,
			Parent = menu,
		})
		AddCorner(optBtn, 4)
		optBtn.MouseEnter:Connect(function() Tween(optBtn, { BackgroundTransparency = 0.85, BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Text }, 0.1) end)
		optBtn.MouseLeave:Connect(function() Tween(optBtn, { BackgroundTransparency = 1, TextColor3 = Theme.TextMuted }, 0.1) end)
		optBtn.MouseButton1Click:Connect(function()
			cur = opt
			dispLbl.Text = tostring(opt)
			isOpen = false
			menu.Visible = false
			task.spawn(cb, opt)
		end)
	end
	
	box.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		if isOpen then
			local abs = box.AbsolutePosition
			local sz = box.AbsoluteSize
			menu.Position = UDim2.new(0, abs.X, 0, abs.Y + sz.Y + 4)
			menu.Size = UDim2.new(0, sz.X, 0, math.min(#opts * 24 + 10, 120))
			menu.Visible = true
		else
			menu.Visible = false
		end
	end)
	
	return { Set = function(_, v) cur = v; dispLbl.Text = tostring(v) end }
end

-- 4. BUTTON / CONFIGURE ACTION
function Module:CreateButton(config)
	config = config or {}
	local title = config.Title or "Button"
	local cb = config.Callback or function() end
	
	local btn = Create("TextButton", {
		BackgroundColor3 = Theme.Input,
		Size = UDim2.new(1, 0, 0, 24),
		Text = title,
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamMedium,
		TextSize = 10,
		AutoButtonColor = false,
		Parent = self.Container,
	})
	AddCorner(btn, 4)
	AddStroke(btn, Theme.Border, 1)
	
	btn.MouseEnter:Connect(function() Tween(btn, { TextColor3 = Theme.Text, BackgroundColor3 = Theme.CardHover }, 0.15) end)
	btn.MouseLeave:Connect(function() Tween(btn, { TextColor3 = Theme.TextMuted, BackgroundColor3 = Theme.Input }, 0.15) end)
	btn.MouseButton1Click:Connect(function() task.spawn(cb) end)
	
	return btn
end

-- 5. LABEL
function Module:CreateLabel(text)
	local lbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = text or "",
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 16),
		Parent = self.Container,
	})
	return { Set = function(_, t) lbl.Text = t end }
end

return Aesthetic
