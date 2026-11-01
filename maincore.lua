--[[
    Aesthetic UI Library
    Rayfield-Style Builder API with Tactical Modern Aesthetic Client Design
    
    Usage:
        local Aesthetic = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/SoTiredd/gg-s/refs/heads/main/maincore.lua"))()
        
        local Window = Aesthetic:CreateWindow({
            Title = "Aesthetic",
            SubTitle = "Версия 1.4+eb374b7",
            Logo = "æ",
            Keybind = Enum.KeyCode.RightControl,
            UserInfo = {
                Username = (game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer.Name) or "salam4ik",
                Subscription = "Dev", -- "Dev" | "Premium" | "Freemium"
                Subtext = "Developer Access",
            }
        })
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- [1] THEME PALETTE & FONTS (Pure neutral dark matte, zero blue tint)
local Colors = {
	Background = Color3.fromRGB(11, 11, 13),       -- Deep matte obsidian
	Sidebar = Color3.fromRGB(11, 11, 13),          -- Left sidebar dock
	Card = Color3.fromRGB(15, 16, 18),             -- Dark module card
	CardActive = Color3.fromRGB(19, 20, 23),       -- Elevated active module card (matching reference screenshot)
	CardHover = Color3.fromRGB(22, 23, 27),
	Border = Color3.fromRGB(24, 25, 28),           -- 1px hairline border
	BorderLight = Color3.fromRGB(36, 38, 44),
	Input = Color3.fromRGB(16, 17, 20),            -- Search & badges
	InputBorder = Color3.fromRGB(26, 27, 32),
	Text = Color3.fromRGB(245, 245, 248),          -- Crisp white
	TextMuted = Color3.fromRGB(135, 138, 148),      -- Descriptions & tab labels
	TextDark = Color3.fromRGB(75, 78, 88),          -- Section tags & faint subtext
	SwitchTrackOff = Color3.fromRGB(24, 25, 29),
	SwitchKnobOff = Color3.fromRGB(75, 78, 88),
	SwitchTrackOn = Color3.fromRGB(255, 255, 255),  -- Bright white switch track
	SwitchKnobOn = Color3.fromRGB(12, 12, 14),      -- Dark knob
	TabActive = Color3.fromRGB(24, 25, 28),         -- Pure neutral dark graphite (NO BLUE)
	TabHover = Color3.fromRGB(18, 19, 22),
	Accent = Color3.fromRGB(255, 255, 255),
	Success = Color3.fromRGB(46, 204, 113),
	Warning = Color3.fromRGB(241, 196, 15),
	Danger = Color3.fromRGB(231, 76, 60),
}

local Fonts = {
	Bold = Enum.Font.GothamBold,
	Medium = Enum.Font.GothamMedium,
	Regular = Enum.Font.Gotham,
}

-- Subscription badge configurations
local function GetSubscriptionConfig(sub)
	local s = string.lower(tostring(sub or "premium"))
	if s:find("dev") then
		return {
			Text = "DEV",
			Bg = Color3.fromRGB(30, 24, 40),
			Border = Color3.fromRGB(72, 54, 98),
			Color = Color3.fromRGB(210, 185, 255),
			Tag = "✦",
			Subtext = "Developer Access",
		}
	elseif s:find("freemium") or s:find("free") then
		return {
			Text = "FREEMIUM",
			Bg = Color3.fromRGB(18, 19, 22),
			Border = Color3.fromRGB(36, 38, 44),
			Color = Color3.fromRGB(145, 150, 160),
			Tag = "",
			Subtext = "Free Tier",
		}
	else -- premium (default)
		return {
			Text = "PREMIUM",
			Bg = Color3.fromRGB(34, 28, 16),
			Border = Color3.fromRGB(78, 64, 30),
			Color = Color3.fromRGB(255, 215, 110),
			Tag = "✦",
			Subtext = "Premium Access",
		}
	end
end

-- [2] INSTANCE HELPERS
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
	local tw = TweenService:Create(
		inst,
		TweenInfo.new(dur or 0.16, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

local function AddCorner(inst, radius)
	return Create("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = inst })
end

local function AddStroke(inst, color, thickness)
	return Create("UIStroke", {
		Color = color or Colors.Border,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = inst,
	})
end

local function AddShadow(inst, elevation)
	elevation = elevation or 24
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
			target.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
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

-----------------------------------------------------------------
-- [3] LIBRARY OBJECT & STATE
-----------------------------------------------------------------
local Aesthetic = {
	Flags = {},
	Windows = {},
	CurrentWindow = nil,
	Theme = Colors,
	Fonts = Fonts,
}

-----------------------------------------------------------------
-- [4] NOTIFICATION SYSTEM
-----------------------------------------------------------------
local notifContainer = nil

local function EnsureNotifContainer()
	if notifContainer and notifContainer.Parent then return notifContainer end
	local parent = GetSafeGuiParent()
	local notifGui = parent:FindFirstChild("AestheticNotifs_GUI")
	if not notifGui then
		notifGui = Create("ScreenGui", {
			Name = "AestheticNotifs_GUI",
			ResetOnSpawn = false,
			DisplayOrder = 10000,
			Parent = parent,
		})
	end
	notifContainer = Create("Frame", {
		Name = "NotificationHolder",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.new(0, 290, 1, -40),
		Parent = notifGui,
	})
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 8),
		Parent = notifContainer,
	})
	return notifContainer
end

function Aesthetic:Notify(config)
	config = config or {}
	local title = config.Title or "Notification"
	local content = config.Content or config.Text or ""
	local duration = config.Duration or 3.5
	local icon = config.Icon or "✦"

	local container = EnsureNotifContainer()

	local card = Create("Frame", {
		Name = "Notif",
		BackgroundColor3 = Colors.CardActive,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = container,
	})
	AddCorner(card, 8)
	AddStroke(card, Colors.BorderLight, 1)

	Create("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = card,
	})

	local topRow = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Parent = card,
	})

	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = icon,
		TextColor3 = Colors.Text,
		Font = Fonts.Bold,
		TextSize = 13,
		Size = UDim2.new(0, 20, 1, 0),
		Parent = topRow,
	})

	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Colors.Text,
		Font = Fonts.Bold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 24, 0, 0),
		Size = UDim2.new(1, -24, 1, 0),
		Parent = topRow,
	})

	if content ~= "" then
		Create("TextLabel", {
			BackgroundTransparency = 1,
			Text = content,
			TextColor3 = Colors.TextMuted,
			Font = Fonts.Regular,
			TextSize = 12,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 0, 0, 24),
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = card,
		})
	end

	-- Slide in animation
	card.Position = UDim2.new(0.3, 0, 0, 0)
	Tween(card, { BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0) }, 0.25)

	task.delay(duration, function()
		if card and card.Parent then
			local tw = Tween(card, { BackgroundTransparency = 1, Position = UDim2.new(0.3, 0, 0, 0) }, 0.25)
			tw.Completed:Connect(function()
				card:Destroy()
			end)
		end
	end)
end

-----------------------------------------------------------------
-- [5] CREATE WINDOW
-----------------------------------------------------------------
function Aesthetic:CreateWindow(windowConfig)
	windowConfig = windowConfig or {}
	local winTitle = windowConfig.Title or "Aesthetic"
	local winSub = windowConfig.SubTitle or windowConfig.Version or "Версия 1.4+eb374b7"
	local logoGlyph = windowConfig.Logo or "æ"
	local winSize = windowConfig.Size or UDim2.new(0, 960, 0, 600)
	local toggleKey = windowConfig.Keybind or Enum.KeyCode.RightControl
	local customGameName = windowConfig.GameName
	
	-- User Profile Information (Username + Subscription Level)
	local userInfo = windowConfig.UserInfo or {}
	local userDisplayName = userInfo.Username or userInfo.Name or (LocalPlayer and LocalPlayer.Name) or "Player"
	local userSubTier = userInfo.Subscription or userInfo.Tier or "Premium"
	local userSubtext = userInfo.Subtext
	local subConfig = GetSubscriptionConfig(userSubTier)

	-- Clean up existing window
	local existing = GetSafeGuiParent():FindFirstChild("AestheticClient_GUI")
	if existing then existing:Destroy() end

	local screenGui = Create("ScreenGui", {
		Name = "AestheticClient_GUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 9999,
		Parent = GetSafeGuiParent(),
	})

	-- Floating Overlay for Dropdowns
	local overlay = Create("Frame", {
		Name = "Overlay",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 500,
		Parent = screenGui,
	})

	-- Main Window Frame
	local main = Create("Frame", {
		Name = "MainWindow",
		BackgroundColor3 = Colors.Background,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = winSize,
		ClipsDescendants = false,
		Parent = screenGui,
	})
	AddCorner(main, 12)
	AddStroke(main, Colors.Border, 1)
	AddShadow(main, 24)

	-------------------------------------------------------------
	-- 1. LEFT SIDEBAR (185px)
	-------------------------------------------------------------
	local sidebar = Create("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = Colors.Sidebar,
		Size = UDim2.new(0, 185, 1, 0),
		Parent = main,
	})
	AddCorner(sidebar, 12)
	Create("Frame", {
		BackgroundColor3 = Colors.Sidebar,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -8, 0, 0),
		Size = UDim2.new(0, 8, 1, 0),
		Parent = sidebar,
	})

	-- Brand Box
	local brandBox = Create("Frame", {
		Name = "BrandBox",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 10),
		Size = UDim2.new(1, -28, 0, 36),
		Parent = sidebar,
	})

	local logoBox = Create("Frame", {
		Name = "LogoBox",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0, 0, 0.5, -16),
		Size = UDim2.new(0, 32, 0, 32),
		Parent = brandBox,
	})
	AddCorner(logoBox, 6)

	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = logoGlyph,
		TextColor3 = Color3.fromRGB(12, 13, 16),
		Font = Fonts.Bold,
		TextSize = 20,
		Position = UDim2.new(0, 0, 0, -1),
		Size = UDim2.new(1, 0, 1, 0),
		Parent = logoBox,
	})

	local brandTitleLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = winTitle,
		TextColor3 = Colors.Text,
		Font = Fonts.Bold,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 40, 0, 2),
		Size = UDim2.new(1, -65, 0, 18),
		Parent = brandBox,
	})

	local brandSubLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = winSub,
		TextColor3 = Colors.TextDark,
		Font = Fonts.Regular,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 40, 0, 20),
		Size = UDim2.new(1, -40, 0, 14),
		Parent = brandBox,
	})

	-- Settings Gear
	Create("TextButton", {
		Name = "SettingsGear",
		BackgroundTransparency = 1,
		Text = "⚙",
		TextColor3 = Colors.TextDark,
		Font = Fonts.Bold,
		TextSize = 13,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 20, 0, 20),
		AutoButtonColor = false,
		Parent = brandBox,
	})

	-- Section Tag
	local sectionsHeader = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "SECTIONS",
		TextColor3 = Colors.TextDark,
		Font = Fonts.Bold,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 16, 0, 58),
		Size = UDim2.new(1, -32, 0, 16),
		Parent = sidebar,
	})

	-- Tabs List
	local tabList = Create("ScrollingFrame", {
		Name = "TabList",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Colors.BorderLight,
		Position = UDim2.new(0, 10, 0, 78),
		Size = UDim2.new(1, -20, 1, -120),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = sidebar,
	})
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
		Parent = tabList,
	})

	-- Collapse Sidebar Button
	local collapseBtn = Create("TextButton", {
		Name = "CollapseBtn",
		BackgroundTransparency = 1,
		Text = "",
		Position = UDim2.new(0, 12, 1, -34),
		Size = UDim2.new(1, -24, 0, 24),
		AutoButtonColor = false,
		Parent = sidebar,
	})

	local collapseLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "⇤  Collapse sidebar",
		TextColor3 = Colors.TextDark,
		Font = Fonts.Regular,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 1, 0),
		Parent = collapseBtn,
	})

	-------------------------------------------------------------
	-- 2. VERTICAL 1PX HAIRLINE DIVIDER
	-------------------------------------------------------------
	local verticalDivider = Create("Frame", {
		Name = "VerticalDivider",
		BackgroundColor3 = Colors.Border,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 185, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		Parent = main,
	})

	-------------------------------------------------------------
	-- 3. TOP BAR
	-------------------------------------------------------------
	local topbar = Create("Frame", {
		Name = "Topbar",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 186, 0, 0),
		Size = UDim2.new(1, -186, 0, 52),
		Parent = main,
	})
	MakeDraggable(topbar, main)

	-- Topbar bottom border
	Create("Frame", {
		BackgroundColor3 = Colors.Border,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		Parent = topbar,
	})

	local topbarControls = Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0.5, -16),
		Size = UDim2.new(0, 520, 0, 32),
		Parent = topbar,
	})

	-- Search Bar
	local searchBox = Create("Frame", {
		Name = "SearchBox",
		BackgroundColor3 = Colors.Input,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0, 220, 1, 0),
		Parent = topbarControls,
	})
	AddCorner(searchBox, 6)
	AddStroke(searchBox, Colors.InputBorder, 1)

	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "🔍",
		TextColor3 = Colors.TextDark,
		Font = Fonts.Regular,
		TextSize = 11,
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(0, 16, 1, 0),
		Parent = searchBox,
	})

	local searchInput = Create("TextBox", {
		BackgroundTransparency = 1,
		PlaceholderText = "Search for module...",
		PlaceholderColor3 = Colors.TextDark,
		TextColor3 = Colors.Text,
		Font = Fonts.Regular,
		TextSize = 12,
		Text = "",
		ClearTextOnFocus = false,
		Position = UDim2.new(0, 28, 0, 0),
		Size = UDim2.new(1, -32, 1, 0),
		Parent = searchBox,
	})

	-- Current Game Badge
	local gameBadge = Create("Frame", {
		Name = "GameBadge",
		BackgroundColor3 = Colors.Input,
		Position = UDim2.new(0, 230, 0, 0),
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = topbarControls,
	})
	AddCorner(gameBadge, 6)
	AddStroke(gameBadge, Colors.InputBorder, 1)

	Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "🌐",
		Font = Fonts.Regular,
		TextSize = 11,
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(0, 16, 1, 0),
		Parent = gameBadge,
	})

	local gameNameLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = customGameName or "Loading...",
		TextColor3 = Colors.TextMuted,
		Font = Fonts.Medium,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 28, 0, 0),
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = gameBadge,
	})
	Create("UIPadding", { PaddingRight = UDim.new(0, 12), Parent = gameBadge })

	if not customGameName then
		task.spawn(function()
			local resolved = "Experience"
			pcall(function()
				if game.PlaceId and game.PlaceId > 0 then
					local info = MarketplaceService:GetProductInfo(game.PlaceId)
					if info and info.Name and info.Name ~= "" then
						resolved = info.Name
					end
				elseif game.Name and game.Name ~= "" then
					resolved = game.Name
				end
			end)
			gameNameLbl.Text = resolved
		end)
	end

	-------------------------------------------------------------
	-- USER PROFILE (Top-Right: Username + Subscription Badge)
	-------------------------------------------------------------
	local userProfile = Create("Frame", {
		Name = "UserProfile",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.new(0, 240, 0, 36),
		Parent = topbar,
	})

	local avatarImg = Create("ImageLabel", {
		Name = "Avatar",
		BackgroundColor3 = Colors.Input,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 34, 0, 34),
		Parent = userProfile,
	})
	AddCorner(avatarImg, 17)
	AddStroke(avatarImg, Colors.BorderLight, 1)

	task.spawn(function()
		pcall(function()
			if LocalPlayer then
				avatarImg.Image = Players:GetUserThumbnailAsync(
					LocalPlayer.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size48x48
				)
			end
		end)
	end)

	local userDetails = Create("Frame", {
		Name = "Details",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -44, 1, 0),
		Parent = userProfile,
	})

	-- Top row: Username + Subscription Badge (Right-Aligned)
	local userTopRow = Create("Frame", {
		Name = "TopRow",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 1),
		Size = UDim2.new(0, 0, 0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = userDetails,
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.LeftToRight,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		Parent = userTopRow,
	})

	local usernameLbl = Create("TextLabel", {
		Name = "Username",
		BackgroundTransparency = 1,
		Text = userDisplayName,
		TextColor3 = Colors.Text,
		Font = Fonts.Bold,
		TextSize = 13,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = userTopRow,
	})

	local subBadge = Create("Frame", {
		Name = "SubBadge",
		BackgroundColor3 = subConfig.Bg,
		Size = UDim2.new(0, 0, 0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = userTopRow,
	})
	AddCorner(subBadge, 4)
	local subStroke = AddStroke(subBadge, subConfig.Border, 1)
	Create("UIPadding", {
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		Parent = subBadge,
	})

	local subBadgeLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = subConfig.Text .. (subConfig.Tag ~= "" and (" " .. subConfig.Tag) or ""),
		TextColor3 = subConfig.Color,
		Font = Fonts.Bold,
		TextSize = 9,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = subBadge,
	})

	local subtextLbl = Create("TextLabel", {
		Name = "Subtext",
		BackgroundTransparency = 1,
		Text = userSubtext or subConfig.Subtext,
		TextColor3 = Colors.TextDark,
		Font = Fonts.Regular,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 19),
		Size = UDim2.new(1, 0, 0, 14),
		Parent = userDetails,
	})

	-------------------------------------------------------------
	-- 4. CONTENT WORKSPACE
	-------------------------------------------------------------
	local contentWorkspace = Create("Frame", {
		Name = "ContentWorkspace",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 202, 0, 62),
		Size = UDim2.new(1, -218, 1, -72),
		Parent = main,
	})

	local breadcrumbLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = Colors.TextDark,
		Font = Fonts.Bold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 18),
		Parent = contentWorkspace,
	})

	local pagesContainer = Create("Frame", {
		Name = "PagesContainer",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 24),
		Size = UDim2.new(1, 0, 1, -24),
		ClipsDescendants = true,
		Parent = contentWorkspace,
	})

	-------------------------------------------------------------
	-- WINDOW OBJECT
	-------------------------------------------------------------
	local Window = {
		ScreenGui = screenGui,
		Main = main,
		Sidebar = sidebar,
		Overlay = overlay,
		Tabs = {},
		ActiveTab = nil,
		IsCollapsed = false,
		IsOpen = true,
	}

	-- Set user details dynamically
	function Window:SetUser(cfg)
		cfg = cfg or {}
		if cfg.Username then
			usernameLbl.Text = cfg.Username
		end
		if cfg.Subscription then
			local c = GetSubscriptionConfig(cfg.Subscription)
			subBadge.BackgroundColor3 = c.Bg
			subStroke.Color = c.Border
			subBadgeLbl.Text = c.Text .. (c.Tag ~= "" and (" " .. c.Tag) or "")
			subBadgeLbl.TextColor3 = c.Color
			if not cfg.Subtext then
				subtextLbl.Text = c.Subtext
			end
		end
		if cfg.Subtext then
			subtextLbl.Text = cfg.Subtext
		end
	end

	-- Live Search filtering
	searchInput:GetPropertyChangedSignal("Text"):Connect(function()
		local q = searchInput.Text:lower()
		if Window.ActiveTab then
			for _, child in ipairs(Window.ActiveTab.LeftCol:GetChildren()) do
				if child:IsA("Frame") and child.Name:sub(1, 5) == "Card_" then
					child.Visible = (q == "" or child.Name:lower():find(q, 1, true) ~= nil)
				end
			end
			for _, child in ipairs(Window.ActiveTab.RightCol:GetChildren()) do
				if child:IsA("Frame") and child.Name:sub(1, 5) == "Card_" then
					child.Visible = (q == "" or child.Name:lower():find(q, 1, true) ~= nil)
				end
			end
		end
	end)

	-- Sidebar collapse logic
	collapseBtn.MouseButton1Click:Connect(function()
		Window.IsCollapsed = not Window.IsCollapsed
		if Window.IsCollapsed then
			Tween(sidebar, { Size = UDim2.new(0, 52, 1, 0) }, 0.2)
			verticalDivider.Position = UDim2.new(0, 52, 0, 0)
			topbar.Position = UDim2.new(0, 53, 0, 0)
			topbar.Size = UDim2.new(1, -53, 0, 52)
			contentWorkspace.Position = UDim2.new(0, 68, 0, 62)
			contentWorkspace.Size = UDim2.new(1, -84, 1, -72)
			collapseLbl.Text = "⇥"
			brandTitleLbl.Visible = false
			brandSubLbl.Visible = false
			sectionsHeader.Visible = false
			for _, t in ipairs(Window.Tabs) do
				t.Label.Visible = false
			end
		else
			Tween(sidebar, { Size = UDim2.new(0, 185, 1, 0) }, 0.2)
			verticalDivider.Position = UDim2.new(0, 185, 0, 0)
			topbar.Position = UDim2.new(0, 186, 0, 0)
			topbar.Size = UDim2.new(1, -186, 0, 52)
			contentWorkspace.Position = UDim2.new(0, 202, 0, 62)
			contentWorkspace.Size = UDim2.new(1, -218, 1, -72)
			collapseLbl.Text = "⇤  Collapse sidebar"
			brandTitleLbl.Visible = true
			brandSubLbl.Visible = true
			sectionsHeader.Visible = true
			for _, t in ipairs(Window.Tabs) do
				t.Label.Visible = true
			end
		end
	end)

	-- Keybind toggle
	if toggleKey then
		UserInputService.InputBegan:Connect(function(input, gpe)
			if not gpe and input.KeyCode == toggleKey then
				Window:Toggle()
			end
		end)
	end

	function Window:Toggle()
		self.IsOpen = not self.IsOpen
		main.Visible = self.IsOpen
		overlay.Visible = self.IsOpen
	end

	function Window:Destroy()
		screenGui:Destroy()
	end

	function Window:SelectTab(targetTab)
		for _, t in ipairs(self.Tabs) do
			local isCurrent = (t == targetTab or t.Title == targetTab)
			t.Page.Visible = isCurrent
			if isCurrent then
				t.Button.BackgroundColor3 = Colors.TabActive
				Tween(t.Button, { BackgroundTransparency = 0 }, 0.15)
				Tween(t.Label, { TextColor3 = Colors.Text }, 0.15)
				Tween(t.Icon, { TextColor3 = Color3.fromRGB(255, 255, 255) }, 0.15)
				t.Label.Font = Fonts.Bold
				self.ActiveTab = t
				breadcrumbLbl.Text = t.Title
			else
				Tween(t.Button, { BackgroundTransparency = 1 }, 0.15)
				Tween(t.Label, { TextColor3 = Colors.TextMuted }, 0.15)
				Tween(t.Icon, { TextColor3 = Colors.TextMuted }, 0.15)
				t.Label.Font = Fonts.Medium
			end
		end
	end

	-------------------------------------------------------------
	-- TAB CONSTRUCTOR
	-------------------------------------------------------------
	function Window:CreateTab(tabConfig)
		tabConfig = tabConfig or {}
		local tabTitle = tabConfig.Title or "Tab"
		local tabIcon = tabConfig.Icon or "✦"

		-- Tab Page ScrollFrame
		local page = Create("ScrollingFrame", {
			Name = "Page_" .. tabTitle,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Colors.BorderLight,
			Size = UDim2.new(1, 0, 1, 0),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
			Parent = pagesContainer,
		})

		-- 2-Column Grid Holder
		local grid = Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = page,
		})

		local left = Create("Frame", {
			Name = "LeftCol",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(0.49, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = grid,
		})
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12), Parent = left })

		local right = Create("Frame", {
			Name = "RightCol",
			BackgroundTransparency = 1,
			Position = UDim2.new(0.51, 0, 0, 0),
			Size = UDim2.new(0.49, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = grid,
		})
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12), Parent = right })

		-- Tab Button in Sidebar (34px height for great touch and mouse feel)
		local tabBtn = Create("TextButton", {
			Name = "Tab_" .. tabTitle,
			BackgroundColor3 = Colors.TabActive,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 34),
			Text = "",
			AutoButtonColor = false,
			Parent = tabList,
		})
		AddCorner(tabBtn, 6)

		local iconLbl = Create("TextLabel", {
			BackgroundTransparency = 1,
			Text = tabIcon,
			TextColor3 = Colors.TextMuted,
			Font = Fonts.Bold,
			TextSize = 15,
			Position = UDim2.new(0, 10, 0, 0),
			Size = UDim2.new(0, 20, 1, 0),
			Parent = tabBtn,
		})

		local label = Create("TextLabel", {
			BackgroundTransparency = 1,
			Text = tabTitle,
			TextColor3 = Colors.TextMuted,
			Font = Fonts.Medium,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 36, 0, 0),
			Size = UDim2.new(1, -42, 1, 0),
			Visible = not Window.IsCollapsed,
			Parent = tabBtn,
		})

		local tabObj = {
			Title = tabTitle,
			Button = tabBtn,
			Icon = iconLbl,
			Label = label,
			Page = page,
			LeftCol = left,
			RightCol = right,
			Cards = {},
		}

		-- Smooth hover effect for inactive tabs
		tabBtn.MouseEnter:Connect(function()
			if Window.ActiveTab ~= tabObj then
				Tween(tabBtn, { BackgroundColor3 = Colors.TabHover, BackgroundTransparency = 0 }, 0.12)
				Tween(label, { TextColor3 = Colors.Text }, 0.12)
				Tween(iconLbl, { TextColor3 = Colors.Text }, 0.12)
			end
		end)
		tabBtn.MouseLeave:Connect(function()
			if Window.ActiveTab ~= tabObj then
				Tween(tabBtn, { BackgroundTransparency = 1 }, 0.12)
				Tween(label, { TextColor3 = Colors.TextMuted }, 0.12)
				Tween(iconLbl, { TextColor3 = Colors.TextMuted }, 0.12)
			end
		end)

		tabBtn.MouseButton1Click:Connect(function()
			Window:SelectTab(tabObj)
		end)

		table.insert(Window.Tabs, tabObj)

		-- Select first tab automatically
		if #Window.Tabs == 1 then
			Window:SelectTab(tabObj)
		end

		---------------------------------------------------------
		-- CARD / MODULE CONSTRUCTOR
		---------------------------------------------------------
		function tabObj:CreateCard(cardConfig)
			cardConfig = cardConfig or {}
			local cardTitle = cardConfig.Title or "Module"
			local cardIcon = cardConfig.Icon
			local cardSide = (cardConfig.Side == "Right" and right) or left
			local isEnabled = cardConfig.Default or false
			local cardFlag = cardConfig.Flag
			local cardCallback = cardConfig.Callback or function() end

			if cardFlag then
				Aesthetic.Flags[cardFlag] = isEnabled
			end

			local cardFrame = Create("Frame", {
				Name = "Card_" .. cardTitle,
				BackgroundColor3 = isEnabled and Colors.CardActive or Colors.Card,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = cardSide,
			})
			AddCorner(cardFrame, 8)
			local cardStroke = AddStroke(cardFrame, isEnabled and Colors.BorderLight or Colors.Border, 1)

			local header = Create("Frame", {
				Name = "Header",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 42),
				Parent = cardFrame,
			})

			local headerX = 14
			if cardIcon then
				Create("TextLabel", {
					BackgroundTransparency = 1,
					Text = cardIcon,
					TextColor3 = Colors.Text,
					Font = Fonts.Bold,
					TextSize = 15,
					Position = UDim2.new(0, 14, 0, 0),
					Size = UDim2.new(0, 18, 1, 0),
					Parent = header,
				})
				headerX = 38
			end

			Create("TextLabel", {
				BackgroundTransparency = 1,
				Text = cardTitle,
				TextColor3 = Colors.Text,
				Font = Fonts.Bold,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0, headerX, 0, 0),
				Size = UDim2.new(1, -headerX - 60, 1, 0),
				Parent = header,
			})

			-- iOS Pill Switch on Card Header
			local switch = Create("TextButton", {
				BackgroundColor3 = isEnabled and Colors.SwitchTrackOn or Colors.SwitchTrackOff,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.new(0, 34, 0, 18),
				Text = "",
				AutoButtonColor = false,
				Parent = header,
			})
			AddCorner(switch, 9)

			local knob = Create("Frame", {
				BackgroundColor3 = isEnabled and Colors.SwitchKnobOn or Colors.SwitchKnobOff,
				Position = isEnabled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
				Size = UDim2.new(0, 14, 0, 14),
				Parent = switch,
			})
			AddCorner(knob, 7)

			local body = Create("Frame", {
				Name = "Body",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 42),
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = cardFrame,
			})
			Create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 10),
				Parent = body,
			})
			Create("UIPadding", {
				PaddingTop = UDim.new(0, 2),
				PaddingBottom = UDim.new(0, 14),
				PaddingLeft = UDim.new(0, 14),
				PaddingRight = UDim.new(0, 14),
				Parent = body,
			})

			local Card = {
				Title = cardTitle,
				Frame = cardFrame,
				Body = body,
				State = isEnabled,
			}

			local function updateSwitch(newState, silent)
				isEnabled = newState
				Card.State = newState
				if cardFlag then
					Aesthetic.Flags[cardFlag] = isEnabled
				end

				if isEnabled then
					Tween(cardFrame, { BackgroundColor3 = Colors.CardActive }, 0.15)
					Tween(cardStroke, { Color = Colors.BorderLight }, 0.15)
					Tween(switch, { BackgroundColor3 = Colors.SwitchTrackOn }, 0.15)
					Tween(knob, { Position = UDim2.new(1, -16, 0.5, -7), BackgroundColor3 = Colors.SwitchKnobOn }, 0.15)
				else
					Tween(cardFrame, { BackgroundColor3 = Colors.Card }, 0.15)
					Tween(cardStroke, { Color = Colors.Border }, 0.15)
					Tween(switch, { BackgroundColor3 = Colors.SwitchTrackOff }, 0.15)
					Tween(knob, { Position = UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Colors.SwitchKnobOff }, 0.15)
				end

				if not silent then
					pcall(cardCallback, isEnabled)
				end
			end

			switch.MouseButton1Click:Connect(function()
				updateSwitch(not isEnabled)
			end)

			function Card:Set(val)
				updateSwitch(val == true)
			end

			function Card:Get()
				return isEnabled
			end

			-----------------------------------------------------
			-- CARD ELEMENT: TOGGLE (Sub-toggle inside body)
			-----------------------------------------------------
			function Card:CreateToggle(toggleConfig)
				toggleConfig = toggleConfig or {}
				local tTitle = toggleConfig.Title or "Toggle"
				local tVal = toggleConfig.Default or false
				local tFlag = toggleConfig.Flag
				local tCallback = toggleConfig.Callback or function() end

				if tFlag then Aesthetic.Flags[tFlag] = tVal end

				local row = Create("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 24),
					Parent = body,
				})

				Create("TextLabel", {
					BackgroundTransparency = 1,
					Text = tTitle,
					TextColor3 = Colors.TextMuted,
					Font = Fonts.Medium,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, 0, 0, 0),
					Size = UDim2.new(1, -40, 1, 0),
					Parent = row,
				})

				local tSwitch = Create("TextButton", {
					BackgroundColor3 = tVal and Colors.SwitchTrackOn or Colors.SwitchTrackOff,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.new(0, 30, 0, 16),
					Text = "",
					AutoButtonColor = false,
					Parent = row,
				})
				AddCorner(tSwitch, 8)

				local tKnob = Create("Frame", {
					BackgroundColor3 = tVal and Colors.SwitchKnobOn or Colors.SwitchKnobOff,
					Position = tVal and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
					Size = UDim2.new(0, 12, 0, 12),
					Parent = tSwitch,
				})
				AddCorner(tKnob, 6)

				local function setToggle(newVal, silent)
					tVal = newVal
					if tFlag then Aesthetic.Flags[tFlag] = tVal end
					if tVal then
						Tween(tSwitch, { BackgroundColor3 = Colors.SwitchTrackOn }, 0.15)
						Tween(tKnob, { Position = UDim2.new(1, -14, 0.5, -6), BackgroundColor3 = Colors.SwitchKnobOn }, 0.15)
					else
						Tween(tSwitch, { BackgroundColor3 = Colors.SwitchTrackOff }, 0.15)
						Tween(tKnob, { Position = UDim2.new(0, 2, 0.5, -6), BackgroundColor3 = Colors.SwitchKnobOff }, 0.15)
					end
					if not silent then pcall(tCallback, tVal) end
				end

				tSwitch.MouseButton1Click:Connect(function()
					setToggle(not tVal)
				end)

				return {
					Set = function(_, v) setToggle(v == true) end,
					Get = function(_) return tVal end,
				}
			end

			-----------------------------------------------------
			-- CARD ELEMENT: SLIDER
			-----------------------------------------------------
			function Card:CreateSlider(sliderConfig)
				sliderConfig = sliderConfig or {}
				local sTitle = sliderConfig.Title or "Slider"
				local min = sliderConfig.Min or 0
				local max = sliderConfig.Max or 100
				local defaultVal = sliderConfig.Default or min
				local step = sliderConfig.Step or 1
				local suffix = sliderConfig.Suffix or ""
				local sFlag = sliderConfig.Flag
				local sCallback = sliderConfig.Callback or function() end

				local curVal = math.clamp(defaultVal, min, max)
				if sFlag then Aesthetic.Flags[sFlag] = curVal end

				local row = Create("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 24),
					Parent = body,
				})

				Create("TextLabel", {
					BackgroundTransparency = 1,
					Text = sTitle,
					TextColor3 = Colors.TextMuted,
					Font = Fonts.Medium,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, 0, 0, 0),
					Size = UDim2.new(0.4, 0, 1, 0),
					Parent = row,
				})

				local track = Create("TextButton", {
					BackgroundColor3 = Colors.InputBorder,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0.42, 0, 0.5, 0),
					Size = UDim2.new(0.42, 0, 0, 2),
					Text = "",
					AutoButtonColor = false,
					Parent = row,
				})

				local initialPct = math.clamp((curVal - min) / (max - min), 0, 1)

				local fill = Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(190, 195, 205),
					Size = UDim2.new(initialPct, 0, 1, 0),
					Parent = track,
				})

				local dot = Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(initialPct, 0, 0.5, 0),
					Size = UDim2.new(0, 10, 0, 10),
					Parent = track,
				})
				AddCorner(dot, 5)

				local valLbl = Create("TextLabel", {
					BackgroundTransparency = 1,
					Text = tostring(curVal) .. suffix,
					TextColor3 = Colors.TextMuted,
					Font = Fonts.Medium,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Right,
					Position = UDim2.new(0.86, 0, 0, 0),
					Size = UDim2.new(0.14, 0, 1, 0),
					Parent = row,
				})

				local function setVal(newVal, silent)
					newVal = math.clamp(newVal, min, max)
					if step > 0 then
						newVal = math.floor((newVal - min) / step + 0.5) * step + min
					end
					if step < 1 then
						newVal = tonumber(string.format("%.2f", newVal))
					else
						newVal = math.floor(newVal)
					end

					curVal = newVal
					if sFlag then Aesthetic.Flags[sFlag] = curVal end

					local p = math.clamp((curVal - min) / (max - min), 0, 1)
					valLbl.Text = tostring(curVal) .. suffix
					fill.Size = UDim2.new(p, 0, 1, 0)
					dot.Position = UDim2.new(p, 0, 0.5, 0)

					if not silent then pcall(sCallback, curVal) end
				end

				local dragging = false
				local function updateFromInput(inputX)
					local w = track.AbsoluteSize.X
					if w <= 0 then return end
					local rel = math.clamp(inputX - track.AbsolutePosition.X, 0, w)
					local p = rel / w
					local raw = min + (max - min) * p
					setVal(raw)
				end

				track.InputBegan:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
						dragging = true
						updateFromInput(inp.Position.X)
					end
				end)
				UserInputService.InputEnded:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
						dragging = false
					end
				end)
				UserInputService.InputChanged:Connect(function(inp)
					if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
						updateFromInput(inp.Position.X)
					end
				end)

				return {
					Set = function(_, v) setVal(v) end,
					Get = function(_) return curVal end,
				}
			end

			-----------------------------------------------------
			-- CARD ELEMENT: DROPDOWN
			-----------------------------------------------------
			function Card:CreateDropdown(dropConfig)
				dropConfig = dropConfig or {}
				local dTitle = dropConfig.Title or "Dropdown"
				local options = dropConfig.Options or {}
				local currentChoice = dropConfig.Default or options[1] or "None"
				local dFlag = dropConfig.Flag
				local dCallback = dropConfig.Callback or function() end

				if dFlag then Aesthetic.Flags[dFlag] = currentChoice end

				local row = Create("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 26),
					Parent = body,
				})

				Create("TextLabel", {
					BackgroundTransparency = 1,
					Text = dTitle,
					TextColor3 = Colors.TextMuted,
					Font = Fonts.Medium,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, 0, 0, 0),
					Size = UDim2.new(0.4, 0, 1, 0),
					Parent = row,
				})

				local btn = Create("TextButton", {
					BackgroundColor3 = Colors.Input,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.new(0.55, 0, 0, 24),
					Text = "",
					AutoButtonColor = false,
					Parent = row,
				})
				AddCorner(btn, 4)
				AddStroke(btn, Colors.Border, 1)

				local choiceLbl = Create("TextLabel", {
					BackgroundTransparency = 1,
					Text = tostring(currentChoice),
					TextColor3 = Colors.Text,
					Font = Fonts.Regular,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Position = UDim2.new(0, 8, 0, 0),
					Size = UDim2.new(1, -24, 1, 0),
					Parent = btn,
				})

				Create("TextLabel", {
					BackgroundTransparency = 1,
					Text = "v",
					TextColor3 = Colors.TextDark,
					Font = Fonts.Bold,
					TextSize = 9,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -6, 0.5, 0),
					Size = UDim2.new(0, 10, 0, 10),
					Parent = btn,
				})

				local menu = Create("ScrollingFrame", {
					BackgroundColor3 = Colors.CardActive,
					BorderSizePixel = 0,
					ScrollBarThickness = 2,
					ScrollBarImageColor3 = Colors.BorderLight,
					Size = UDim2.new(0, 160, 0, 0),
					Visible = false,
					CanvasSize = UDim2.new(0, 0, 0, 0),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					Parent = overlay,
				})
				AddCorner(menu, 6)
				AddStroke(menu, Colors.BorderLight, 1)
				AddShadow(menu, 12)
				Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), Parent = menu })
				Create("UIPadding", {
					PaddingTop = UDim.new(0, 4),
					PaddingBottom = UDim.new(0, 4),
					PaddingLeft = UDim.new(0, 4),
					PaddingRight = UDim.new(0, 4),
					Parent = menu,
				})

				local isOpen = false

				local function rebuildOptions()
					for _, child in ipairs(menu:GetChildren()) do
						if child:IsA("TextButton") then child:Destroy() end
					end

					for _, opt in ipairs(options) do
						local optBtn = Create("TextButton", {
							Text = tostring(opt),
							TextColor3 = (opt == currentChoice) and Colors.Text or Colors.TextMuted,
							Font = Fonts.Regular,
							TextSize = 11,
							BackgroundColor3 = Colors.Input,
							BackgroundTransparency = (opt == currentChoice) and 0.8 or 1,
							Size = UDim2.new(1, 0, 0, 24),
							AutoButtonColor = false,
							Parent = menu,
						})
						AddCorner(optBtn, 4)
						optBtn.MouseEnter:Connect(function()
							Tween(optBtn, { BackgroundTransparency = 0.85, TextColor3 = Colors.Text }, 0.1)
						end)
						optBtn.MouseLeave:Connect(function()
							local isSel = (opt == currentChoice)
							Tween(optBtn, { BackgroundTransparency = isSel and 0.8 or 1, TextColor3 = isSel and Colors.Text or Colors.TextMuted }, 0.1)
						end)
						optBtn.MouseButton1Click:Connect(function()
							currentChoice = opt
							choiceLbl.Text = tostring(opt)
							if dFlag then Aesthetic.Flags[dFlag] = opt end
							menu.Visible = false
							isOpen = false
							pcall(dCallback, opt)
						end)
					end
				end

				rebuildOptions()

				btn.MouseButton1Click:Connect(function()
					isOpen = not isOpen
					if isOpen then
						local abs = btn.AbsolutePosition
						local sz = btn.AbsoluteSize
						menu.Position = UDim2.new(0, abs.X, 0, abs.Y + sz.Y + 4)
						menu.Size = UDim2.new(0, sz.X, 0, math.min(#options * 26 + 10, 130))
						menu.Visible = true
					else
						menu.Visible = false
					end
				end)

				return {
					Set = function(_, opt)
						currentChoice = opt
						choiceLbl.Text = tostring(opt)
						if dFlag then Aesthetic.Flags[dFlag] = opt end
						pcall(dCallback, opt)
					end,
					Refresh = function(_, newOptions)
						options = newOptions or {}
						rebuildOptions()
					end,
					Get = function(_) return currentChoice end,
				}
			end

			-----------------------------------------------------
			-- CARD ELEMENT: CHECKBOX
			-----------------------------------------------------
			function Card:CreateCheckbox(checkConfig)
				checkConfig = checkConfig or {}
				local cTitle = checkConfig.Title or "Checkbox"
				local isChecked = checkConfig.Default or false
				local cFlag = checkConfig.Flag
				local cCallback = checkConfig.Callback or function() end

				if cFlag then Aesthetic.Flags[cFlag] = isChecked end

				local row = Create("TextButton", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 24),
					Text = "",
					AutoButtonColor = false,
					Parent = body,
				})

				Create("TextLabel", {
					BackgroundTransparency = 1,
					Text = cTitle,
					TextColor3 = Colors.TextMuted,
					Font = Fonts.Medium,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, 0, 0, 0),
					Size = UDim2.new(1, -28, 1, 0),
					Parent = row,
				})

				local box = Create("Frame", {
					BackgroundColor3 = isChecked and Color3.fromRGB(255, 255, 255) or Colors.Input,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.new(0, 18, 0, 18),
					Parent = row,
				})
				AddCorner(box, 4)
				AddStroke(box, isChecked and Color3.fromRGB(255, 255, 255) or Colors.Border, 1)

				local check = Create("TextLabel", {
					BackgroundTransparency = 1,
					Text = "✓",
					TextColor3 = Color3.fromRGB(12, 13, 16),
					Font = Fonts.Bold,
					TextSize = 12,
					Visible = isChecked,
					Size = UDim2.new(1, 0, 1, 0),
					Parent = box,
				})

				local function setCheck(newVal, silent)
					isChecked = newVal
					if cFlag then Aesthetic.Flags[cFlag] = isChecked end
					check.Visible = isChecked
					Tween(box, { BackgroundColor3 = isChecked and Color3.fromRGB(255, 255, 255) or Colors.Input }, 0.12)
					if not silent then pcall(cCallback, isChecked) end
				end

				row.MouseButton1Click:Connect(function()
					setCheck(not isChecked)
				end)

				return {
					Set = function(_, v) setCheck(v == true) end,
					Get = function(_) return isChecked end,
				}
			end

			-----------------------------------------------------
			-- CARD ELEMENT: BUTTON
			-----------------------------------------------------
			function Card:CreateButton(btnConfig)
				btnConfig = btnConfig or {}
				local bTitle = btnConfig.Title or "Button"
				local bCallback = btnConfig.Callback or function() end

				local btn = Create("TextButton", {
					BackgroundColor3 = Colors.Input,
					Size = UDim2.new(1, 0, 0, 26),
					Text = bTitle,
					TextColor3 = Colors.Text,
					Font = Fonts.Medium,
					TextSize = 12,
					AutoButtonColor = false,
					Parent = body,
				})
				AddCorner(btn, 6)
				AddStroke(btn, Colors.Border, 1)

				btn.MouseEnter:Connect(function()
					Tween(btn, { BackgroundColor3 = Colors.CardHover }, 0.1)
				end)
				btn.MouseLeave:Connect(function()
					Tween(btn, { BackgroundColor3 = Colors.Input }, 0.1)
				end)
				btn.MouseButton1Click:Connect(function()
					Tween(btn, { BackgroundColor3 = Color3.fromRGB(32, 33, 40) }, 0.08)
					task.wait(0.08)
					Tween(btn, { BackgroundColor3 = Colors.CardHover }, 0.1)
					pcall(bCallback)
				end)

				return {
					SetText = function(_, txt) btn.Text = txt end,
				}
			end

			-----------------------------------------------------
			-- CARD ELEMENT: KEYBIND
			-----------------------------------------------------
			function Card:CreateKeybind(keyConfig)
				keyConfig = keyConfig or {}
				local kTitle = keyConfig.Title or "Keybind"
				local curKey = keyConfig.Default or Enum.KeyCode.Unknown
				local kFlag = keyConfig.Flag
				local kCallback = keyConfig.Callback or function() end

				if kFlag then Aesthetic.Flags[kFlag] = curKey end

				local row = Create("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 24),
					Parent = body,
				})

				Create("TextLabel", {
					BackgroundTransparency = 1,
					Text = kTitle,
					TextColor3 = Colors.TextMuted,
					Font = Fonts.Medium,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, 0, 0, 0),
					Size = UDim2.new(0.6, 0, 1, 0),
					Parent = row,
				})

				local keyBtn = Create("TextButton", {
					BackgroundColor3 = Colors.Input,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.new(0, 64, 0, 22),
					Text = curKey == Enum.KeyCode.Unknown and "[ None ]" or ("[ " .. curKey.Name .. " ]"),
					TextColor3 = Colors.Text,
					Font = Fonts.Regular,
					TextSize = 11,
					AutoButtonColor = false,
					Parent = row,
				})
				AddCorner(keyBtn, 4)
				AddStroke(keyBtn, Colors.Border, 1)

				local listening = false
				keyBtn.MouseButton1Click:Connect(function()
					if listening then return end
					listening = true
					keyBtn.Text = "[ ... ]"
					keyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

					local conn
					conn = UserInputService.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.Keyboard then
							conn:Disconnect()
							listening = false
							if input.KeyCode == Enum.KeyCode.Escape then
								curKey = Enum.KeyCode.Unknown
								keyBtn.Text = "[ None ]"
							else
								curKey = input.KeyCode
								keyBtn.Text = "[ " .. curKey.Name .. " ]"
							end
							keyBtn.TextColor3 = Colors.Text
							if kFlag then Aesthetic.Flags[kFlag] = curKey end
							pcall(kCallback, curKey)
						end
					end)
				end)

				return {
					Set = function(_, key)
						curKey = key
						keyBtn.Text = curKey == Enum.KeyCode.Unknown and "[ None ]" or ("[ " .. curKey.Name .. " ]")
						if kFlag then Aesthetic.Flags[kFlag] = curKey end
					end,
					Get = function(_) return curKey end,
				}
			end

			-----------------------------------------------------
			-- CARD ELEMENT: INPUT / TEXTBOX
			-----------------------------------------------------
			function Card:CreateInput(inputConfig)
				inputConfig = inputConfig or {}
				local iTitle = inputConfig.Title or "Input"
				local placeholder = inputConfig.Placeholder or "Type here..."
				local defaultVal = inputConfig.Default or ""
				local iFlag = inputConfig.Flag
				local iCallback = inputConfig.Callback or function() end

				if iFlag then Aesthetic.Flags[iFlag] = defaultVal end

				local row = Create("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 26),
					Parent = body,
				})

				Create("TextLabel", {
					BackgroundTransparency = 1,
					Text = iTitle,
					TextColor3 = Colors.TextMuted,
					Font = Fonts.Medium,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, 0, 0, 0),
					Size = UDim2.new(0.4, 0, 1, 0),
					Parent = row,
				})

				local boxFrame = Create("Frame", {
					BackgroundColor3 = Colors.Input,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.new(0.55, 0, 0, 24),
					Parent = row,
				})
				AddCorner(boxFrame, 4)
				AddStroke(boxFrame, Colors.Border, 1)

				local txtBox = Create("TextBox", {
					BackgroundTransparency = 1,
					Text = defaultVal,
					PlaceholderText = placeholder,
					PlaceholderColor3 = Colors.TextDark,
					TextColor3 = Colors.Text,
					Font = Fonts.Regular,
					TextSize = 11,
					ClearTextOnFocus = false,
					Position = UDim2.new(0, 8, 0, 0),
					Size = UDim2.new(1, -16, 1, 0),
					Parent = boxFrame,
				})

				txtBox.FocusLost:Connect(function(enterPressed)
					local val = txtBox.Text
					if iFlag then Aesthetic.Flags[iFlag] = val end
					pcall(iCallback, val, enterPressed)
				end)

				return {
					Set = function(_, text)
						txtBox.Text = text
						if iFlag then Aesthetic.Flags[iFlag] = text end
					end,
					Get = function(_) return txtBox.Text end,
				}
			end

			-----------------------------------------------------
			-- CARD ELEMENT: LABEL
			-----------------------------------------------------
			function Card:CreateLabel(textOrConfig)
				local lText = (type(textOrConfig) == "table" and (textOrConfig.Text or textOrConfig.Title)) or tostring(textOrConfig or "")

				local lbl = Create("TextLabel", {
					BackgroundTransparency = 1,
					Text = lText,
					TextColor3 = Colors.TextMuted,
					Font = Fonts.Regular,
					TextSize = 12,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					Parent = body,
				})

				return {
					Set = function(_, newText) lbl.Text = newText end,
				}
			end

			table.insert(tabObj.Cards, Card)
			return Card
		end

		-- Alias: CreateModule = CreateCard
		tabObj.CreateModule = tabObj.CreateCard

		return tabObj
	end

	table.insert(Aesthetic.Windows, Window)
	Aesthetic.CurrentWindow = Window

	return Window
end

-- Fallback global
_G.Aesthetic = Aesthetic

return Aesthetic
