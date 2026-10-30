--[[
    Chieftain UI Library for Roblox Luau
    Recreation of the tactical / CS2 / GMod cheat aesthetic (chieftain.cc style)
    Pure Luau programmatic construction - no external rbxassetid dependencies required.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- Theme Definition
local Theme = {
    Accent = Color3.fromRGB(89, 219, 149),          -- Mint green accent
    AccentDim = Color3.fromRGB(48, 120, 82),        -- Muted green
    AccentGlow = Color3.fromRGB(89, 219, 149),
    Background = Color3.fromRGB(15, 17, 18),        -- Deep dark charcoal/obsidian
    Sidebar = Color3.fromRGB(18, 20, 22),           -- Left icon dock
    Card = Color3.fromRGB(22, 25, 27),              -- Section cards
    CardHeader = Color3.fromRGB(26, 30, 32),
    Border = Color3.fromRGB(36, 41, 45),            -- Borders and outlines
    BorderLight = Color3.fromRGB(48, 54, 60),
    InputBackground = Color3.fromRGB(16, 18, 20),
    ToggleOff = Color3.fromRGB(45, 52, 57),
    ToggleKnobOff = Color3.fromRGB(110, 118, 125),
    ToggleKnobOn = Color3.fromRGB(240, 245, 242),
    Text = Color3.fromRGB(220, 225, 228),           -- Main text
    TextMuted = Color3.fromRGB(130, 138, 144),      -- Subtext / secondary
    TextDark = Color3.fromRGB(80, 88, 94),          -- Disabled / breadcrumbs
    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,
    FontMedium = Enum.Font.GothamMedium,
}

local Chieftain = {
    Theme = Theme,
    Windows = {},
    Signals = {},
    ScreenGui = nil,
}

-- Utility helpers
local function create(className, properties, children)
    local inst = Instance.new(className)
    for prop, val in pairs(properties or {}) do
        inst[prop] = val
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function addCorner(instance, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 6),
        Parent = instance,
    })
end

local function addStroke(instance, color, thickness, transparency)
    return create("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = instance,
    })
end

local function addPadding(instance, top, right, bottom, left)
    return create("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0),
        Parent = instance,
    })
end

local function tween(inst, duration, properties, easingStyle, easingDir)
    local tw = TweenService:Create(
        inst,
        TweenInfo.new(duration or 0.2, easingStyle or Enum.EasingStyle.Quad, easingDir or Enum.EasingDirection.Out),
        properties
    )
    tw:Play()
    return tw
end

local function makeDraggable(dragHandle, frame)
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ScreenGui initialization
function Chieftain:GetScreenGui()
    if self.ScreenGui and self.ScreenGui.Parent then
        return self.ScreenGui
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "ChieftainUI_" .. tostring(math.random(1000, 9999))
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 100

    -- Executor parent protection check
    local success, _ = pcall(function()
        if gethui then
            gui.Parent = gethui()
        elseif syn and syn.protect_gui then
            syn.protect_gui(gui)
            gui.Parent = CoreGui
        else
            gui.Parent = CoreGui
        end
    end)

    if not success or not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    self.ScreenGui = gui
    return gui
end

-- Main Window Creation
function Chieftain:CreateWindow(config)
    config = config or {}
    local windowTitle = config.Title or "chieftain.cc"
    local versionText = config.Version or "V2.0.0 Stable for Roblox (Internal)"
    local windowSize = config.Size or UDim2.fromOffset(880, 560)
    local defaultKeybind = config.Keybind or Enum.KeyCode.RightControl

    local parentGui = self:GetScreenGui()

    -- Root Main Frame
    local MainFrame = create("Frame", {
        Name = "ChieftainWindow",
        Size = windowSize,
        Position = UDim2.new(0.5, -windowSize.X.Offset / 2, 0.5, -windowSize.Y.Offset / 2),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Parent = parentGui,
    })
    addCorner(MainFrame, 6)
    addStroke(MainFrame, Theme.Border, 1)

    -- Drop shadow emulation
    local Shadow = create("Frame", {
        Name = "Shadow",
        Size = UDim2.new(1, 14, 1, 14),
        Position = UDim2.new(0, -7, 0, -5),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.65,
        ZIndex = MainFrame.ZIndex - 1,
        BorderSizePixel = 0,
        Parent = MainFrame,
    })
    addCorner(Shadow, 10)

    -- Left Vertical Sidebar (Icon Dock)
    local Sidebar = create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 54, 1, -26), -- leaves 26px for bottom bar
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = MainFrame,
    })
    addCorner(Sidebar, 6)

    -- Sidebar border right
    local SidebarRightLine = create("Frame", {
        Name = "RightLine",
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Parent = Sidebar,
    })

    -- Logo Emblem top left
    local LogoHolder = create("Frame", {
        Name = "LogoHolder",
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundTransparency = 1,
        Parent = Sidebar,
    })

    local LogoIcon = create("TextLabel", {
        Name = "LogoIcon",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = "✦",
        TextColor3 = Theme.Accent,
        TextSize = 22,
        Parent = LogoHolder,
    })

    -- Sidebar icon buttons list
    local TabIconsList = create("Frame", {
        Name = "TabIconsList",
        Size = UDim2.new(1, 0, 1, -110),
        Position = UDim2.new(0, 0, 0, 54),
        BackgroundTransparency = 1,
        Parent = Sidebar,
    })
    local TabIconsLayout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 14),
        Parent = TabIconsList,
    })

    -- Bottom Gear Setting Icon in Sidebar
    local SettingsIconBtn = create("TextButton", {
        Name = "SettingsBtn",
        Size = UDim2.new(0, 36, 0, 36),
        Position = UDim2.new(0.5, -18, 1, -44),
        BackgroundColor3 = Theme.Card,
        BackgroundTransparency = 1,
        Text = "⚙",
        Font = Theme.Font,
        TextSize = 16,
        TextColor3 = Theme.TextMuted,
        AutoButtonColor = false,
        Parent = Sidebar,
    })
    addCorner(SettingsIconBtn, 6)

    -- Top Header Bar (Breadcrumbs + Subtabs + Search)
    local Topbar = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, -54, 0, 50),
        Position = UDim2.new(0, 54, 0, 0),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent = MainFrame,
    })

    local TopbarBottomLine = create("Frame", {
        Name = "BottomLine",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Parent = Topbar,
    })

    -- Make topbar drag window
    makeDraggable(Topbar, MainFrame)

    -- Header Left: Tab Icon & Tab Name
    local HeaderLeft = create("Frame", {
        Name = "HeaderLeft",
        Size = UDim2.new(0, 180, 1, 0),
        Position = UDim2.new(0, 18, 0, 0),
        BackgroundTransparency = 1,
        Parent = Topbar,
    })
    local HeaderLeftLayout = create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 10),
        Parent = HeaderLeft,
    })

    local CurrentTabGlyph = create("TextLabel", {
        Name = "TabGlyph",
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = "👁",
        TextColor3 = Theme.Accent,
        TextSize = 15,
        Parent = HeaderLeft,
    })

    local CurrentTabTitle = create("TextLabel", {
        Name = "TabTitle",
        Size = UDim2.new(0, 70, 0, 20),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = "Visuals",
        TextColor3 = Theme.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = HeaderLeft,
    })

    local BreadcrumbSlash = create("TextLabel", {
        Name = "Slash",
        Size = UDim2.new(0, 10, 0, 20),
        BackgroundTransparency = 1,
        Font = Theme.Font,
        Text = "/",
        TextColor3 = Theme.TextDark,
        TextSize = 14,
        Parent = HeaderLeft,
    })

    -- Subtabs Container (Players, World, etc.)
    local SubtabsContainer = create("Frame", {
        Name = "SubtabsContainer",
        Size = UDim2.new(0, 280, 1, 0),
        Position = UDim2.new(0, 200, 0, 0),
        BackgroundTransparency = 1,
        Parent = Topbar,
    })
    local SubtabsLayout = create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 16),
        Parent = SubtabsContainer,
    })

    -- Topbar Search Input Box (right side)
    local SearchBoxContainer = create("Frame", {
        Name = "SearchBoxContainer",
        Size = UDim2.new(0, 240, 0, 30),
        Position = UDim2.new(1, -256, 0.5, -15),
        BackgroundColor3 = Theme.InputBackground,
        BorderSizePixel = 0,
        Parent = Topbar,
    })
    addCorner(SearchBoxContainer, 4)
    addStroke(SearchBoxContainer, Theme.Border, 1)

    local SearchIcon = create("TextLabel", {
        Name = "SearchIcon",
        Size = UDim2.new(0, 24, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        Font = Theme.Font,
        Text = "🔍",
        TextColor3 = Theme.TextMuted,
        TextSize = 12,
        Parent = SearchBoxContainer,
    })

    local SearchInput = create("TextBox", {
        Name = "SearchInput",
        Size = UDim2.new(1, -36, 1, 0),
        Position = UDim2.new(0, 30, 0, 0),
        BackgroundTransparency = 1,
        Font = Theme.Font,
        PlaceholderColor3 = Theme.TextDark,
        PlaceholderText = "Search options...",
        Text = "",
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = SearchBoxContainer,
    })

    -- Bottom Green Status Bar
    local BottomBar = create("Frame", {
        Name = "BottomBar",
        Size = UDim2.new(1, 0, 0, 26),
        Position = UDim2.new(0, 0, 1, -26),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = MainFrame,
    })
    addCorner(BottomBar, 4)

    -- Straighten top corners of bottom bar
    local BottomBarTopRepair = create("Frame", {
        Name = "TopRepair",
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = BottomBar,
    })

    local BottomLeftText = create("TextLabel", {
        Name = "Brand",
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = windowTitle,
        TextColor3 = Color3.fromRGB(15, 20, 18),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = BottomBar,
    })

    local BottomRightText = create("TextLabel", {
        Name = "Version",
        Size = UDim2.new(0, 300, 1, 0),
        Position = UDim2.new(1, -314, 0, 0),
        BackgroundTransparency = 1,
        Font = Theme.FontMedium,
        Text = versionText,
        TextColor3 = Color3.fromRGB(15, 20, 18),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = BottomBar,
    })

    -- Central Body Page Host (Two Columns: Left elements, Right preview / extra card)
    local ContentArea = create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -54, 1, -76), -- -50 topbar, -26 bottombar
        Position = UDim2.new(0, 54, 0, 50),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = MainFrame,
    })

    -- Window Structure Object
    local WindowObj = {
        MainFrame = MainFrame,
        Tabs = {},
        CurrentTab = nil,
        CurrentSubtab = nil,
        Keybind = defaultKeybind,
        Visible = true,
    }

    -- Toggle visibility with keybind
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == WindowObj.Keybind then
            WindowObj.Visible = not WindowObj.Visible
            MainFrame.Visible = WindowObj.Visible
        end
    end)

    -- Tab Creation Function
    function WindowObj:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Name or "Tab"
        local tabIcon = tabConfig.Icon or "👁"

        local TabObj = {
            Name = tabName,
            Icon = tabIcon,
            Subtabs = {},
            CurrentSubtab = nil,
            PageFrame = nil,
            IconButton = nil,
        }

        -- Left Icon dock button
        local TabBtn = create("TextButton", {
            Name = tabName .. "_Btn",
            Size = UDim2.new(0, 38, 0, 38),
            BackgroundColor3 = Theme.Card,
            BackgroundTransparency = 1,
            Text = tabIcon,
            Font = Theme.FontBold,
            TextSize = 16,
            TextColor3 = Theme.TextMuted,
            AutoButtonColor = false,
            Parent = TabIconsList,
        })
        addCorner(TabBtn, 6)

        -- Active indicator line on the left side of icon
        local ActivePill = create("Frame", {
            Name = "ActivePill",
            Size = UDim2.new(0, 3, 0, 20),
            Position = UDim2.new(0, -6, 0.5, -10),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Visible = false,
            Parent = TabBtn,
        })
        addCorner(ActivePill, 2)

        TabObj.IconButton = TabBtn
        TabObj.ActivePill = ActivePill

        -- Tab Page Frame (contains left and right column layout)
        local TabPage = create("Frame", {
            Name = tabName .. "_Page",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            Parent = ContentArea,
        })
        TabObj.PageFrame = TabPage

        -- Two-column horizontal split
        local ColumnsContainer = create("Frame", {
            Name = "ColumnsContainer",
            Size = UDim2.new(1, -28, 1, -24),
            Position = UDim2.new(0, 14, 0, 12),
            BackgroundTransparency = 1,
            Parent = TabPage,
        })

        -- Left Column (Cards list with scrolling)
        local LeftColumn = create("ScrollingFrame", {
            Name = "LeftColumn",
            Size = UDim2.new(0.48, -6, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.BorderLight,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = ColumnsContainer,
        })
        local LeftColLayout = create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 12),
            Parent = LeftColumn,
        })

        -- Right Column (Cards list or preview area)
        local RightColumn = create("ScrollingFrame", {
            Name = "RightColumn",
            Size = UDim2.new(0.52, -6, 1, 0),
            Position = UDim2.new(0.48, 6, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.BorderLight,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = ColumnsContainer,
        })
        local RightColLayout = create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 12),
            Parent = RightColumn,
        })

        TabObj.LeftColumn = LeftColumn
        TabObj.RightColumn = RightColumn

        -- Tab Selection activation
        function TabObj:Select()
            for _, t in pairs(WindowObj.Tabs) do
                t.PageFrame.Visible = false
                t.ActivePill.Visible = false
                tween(t.IconButton, 0.2, { TextColor3 = Theme.TextMuted, BackgroundTransparency = 1 })
            end

            TabObj.PageFrame.Visible = true
            TabObj.ActivePill.Visible = true
            tween(TabObj.IconButton, 0.2, { TextColor3 = Theme.Accent, BackgroundTransparency = 0.9 })

            CurrentTabGlyph.Text = TabObj.Icon
            CurrentTabTitle.Text = TabObj.Name

            WindowObj.CurrentTab = TabObj

            -- Refresh subtab bar in topbar
            for _, child in ipairs(SubtabsContainer:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end

            for index, sub in ipairs(TabObj.Subtabs) do
                local subBtn = create("TextButton", {
                    Name = sub.Name .. "_SubtabBtn",
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Font = (index == 1 and Theme.FontBold or Theme.Font),
                    Text = sub.Name,
                    TextColor3 = (index == 1 and Theme.Text or Theme.TextMuted),
                    TextSize = 13,
                    Parent = SubtabsContainer,
                })

                subBtn.MouseButton1Click:Connect(function()
                    sub:Select()
                end)
                sub.Button = subBtn
            end

            if TabObj.Subtabs[1] then
                TabObj.Subtabs[1]:Select()
            end
        end

        TabBtn.MouseButton1Click:Connect(function()
            TabObj:Select()
        end)

        -- Subtab creation (e.g. "Players", "World")
        function TabObj:CreateSubtab(subtabName)
            local SubtabObj = {
                Name = subtabName,
                Tab = TabObj,
                LeftCards = {},
                RightCards = {},
            }

            table.insert(TabObj.Subtabs, SubtabObj)

            function SubtabObj:Select()
                for _, s in ipairs(TabObj.Subtabs) do
                    if s.Button then
                        s.Button.TextColor3 = Theme.TextMuted
                        s.Button.Font = Theme.Font
                    end
                    for _, c in ipairs(s.LeftCards) do c.Visible = false end
                    for _, c in ipairs(s.RightCards) do c.Visible = false end
                end

                if SubtabObj.Button then
                    SubtabObj.Button.TextColor3 = Theme.Text
                    SubtabObj.Button.Font = Theme.FontBold
                end

                for _, c in ipairs(SubtabObj.LeftCards) do c.Visible = true end
                for _, c in ipairs(SubtabObj.RightCards) do c.Visible = true end

                TabObj.CurrentSubtab = SubtabObj
            end

            -- Create a card inside this subtab
            function SubtabObj:CreateCard(cardConfig)
                cardConfig = cardConfig or {}
                local title = cardConfig.Title
                local icon = cardConfig.Icon
                local side = (cardConfig.Side or "Left"):lower()
                local targetCol = (side == "right") and TabObj.RightColumn or TabObj.LeftColumn

                local CardFrame = create("Frame", {
                    Name = (title or "Card") .. "_Frame",
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = Theme.Card,
                    BorderSizePixel = 0,
                    Parent = targetCol,
                })
                addCorner(CardFrame, 6)
                addStroke(CardFrame, Theme.Border, 1)

                local CardLayout = create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 8),
                    Parent = CardFrame,
                })
                addPadding(CardFrame, 12, 14, 12, 14)

                -- Optional card title header
                if title then
                    local CardHeader = create("Frame", {
                        Name = "Header",
                        Size = UDim2.new(1, 0, 0, 20),
                        BackgroundTransparency = 1,
                        LayoutOrder = 0,
                        Parent = CardFrame,
                    })

                    local headerText = title
                    if icon then
                        local CardIcon = create("TextLabel", {
                            Name = "Icon",
                            Size = UDim2.new(0, 20, 1, 0),
                            Position = UDim2.new(0, 0, 0, 0),
                            BackgroundTransparency = 1,
                            Font = Theme.FontBold,
                            Text = icon,
                            TextColor3 = Theme.TextMuted,
                            TextSize = 13,
                            Parent = CardHeader,
                        })
                    end

                    local CardTitleLabel = create("TextLabel", {
                        Name = "Title",
                        Size = UDim2.new(1, (icon and -24 or 0), 1, 0),
                        Position = UDim2.new(0, (icon and 24 or 0), 0, 0),
                        BackgroundTransparency = 1,
                        Font = Theme.FontBold,
                        Text = title,
                        TextColor3 = Theme.Text,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = CardHeader,
                    })
                end

                if side == "right" then
                    table.insert(SubtabObj.RightCards, CardFrame)
                else
                    table.insert(SubtabObj.LeftCards, CardFrame)
                end

                local CardObj = {
                    Frame = CardFrame,
                    Elements = {},
                }

                -- Card UI Elements: Toggle with secondary colorpicker/settings gear
                function CardObj:AddToggle(elemConfig)
                    elemConfig = elemConfig or {}
                    local text = elemConfig.Name or "Toggle"
                    local default = elemConfig.Default or false
                    local callback = elemConfig.Callback or function() end
                    local hasGear = elemConfig.SettingsGear or false
                    local colorPickers = elemConfig.Colors or {} -- e.g. { Color3.fromRGB(0,0,0), Color3.fromRGB(255,255,255) }

                    local state = default

                    local Row = create("Frame", {
                        Name = text .. "_ToggleRow",
                        Size = UDim2.new(1, 0, 0, 28),
                        BackgroundTransparency = 1,
                        Parent = CardFrame,
                    })

                    local TitleLabel = create("TextLabel", {
                        Name = "Label",
                        Size = UDim2.new(0.55, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Font = Theme.Font,
                        Text = text,
                        TextColor3 = state and Theme.Text or Theme.TextMuted,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = Row,
                    })

                    -- Control strip on the right: [Color Dots] [Gear] [Toggle Switch]
                    local RightStrip = create("Frame", {
                        Name = "RightStrip",
                        Size = UDim2.new(0.45, 0, 1, 0),
                        Position = UDim2.new(0.55, 0, 0, 0),
                        BackgroundTransparency = 1,
                        Parent = Row,
                    })
                    local StripLayout = create("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Right,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, 8),
                        Parent = RightStrip,
                    })

                    -- Optional color dots
                    for i, col in ipairs(colorPickers) do
                        local dot = create("TextButton", {
                            Name = "ColorDot_" .. i,
                            Size = UDim2.new(0, 14, 0, 14),
                            BackgroundColor3 = col,
                            BorderSizePixel = 0,
                            Text = "",
                            AutoButtonColor = false,
                            Parent = RightStrip,
                        })
                        addCorner(dot, 7)
                        addStroke(dot, Theme.BorderLight, 1)
                    end

                    -- Optional mini gear
                    if hasGear then
                        local gearBtn = create("TextButton", {
                            Name = "GearBtn",
                            Size = UDim2.new(0, 16, 0, 16),
                            BackgroundTransparency = 1,
                            Text = "⚙",
                            Font = Theme.Font,
                            TextSize = 12,
                            TextColor3 = Theme.TextMuted,
                            Parent = RightStrip,
                        })
                    end

                    -- Toggle pill switch
                    local Switch = create("TextButton", {
                        Name = "Switch",
                        Size = UDim2.new(0, 36, 0, 18),
                        BackgroundColor3 = state and Theme.Accent or Theme.ToggleOff,
                        BorderSizePixel = 0,
                        Text = "",
                        AutoButtonColor = false,
                        Parent = RightStrip,
                    })
                    addCorner(Switch, 9)

                    local Knob = create("Frame", {
                        Name = "Knob",
                        Size = UDim2.new(0, 14, 0, 14),
                        Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
                        BackgroundColor3 = state and Theme.ToggleKnobOn or Theme.ToggleKnobOff,
                        BorderSizePixel = 0,
                        Parent = Switch,
                    })
                    addCorner(Knob, 7)

                    local function updateState(newState)
                        state = newState
                        if state then
                            tween(Switch, 0.2, { BackgroundColor3 = Theme.Accent })
                            tween(Knob, 0.2, { Position = UDim2.new(1, -16, 0.5, -7), BackgroundColor3 = Theme.ToggleKnobOn })
                            tween(TitleLabel, 0.2, { TextColor3 = Theme.Text })
                        else
                            tween(Switch, 0.2, { BackgroundColor3 = Theme.ToggleOff })
                            tween(Knob, 0.2, { Position = UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Theme.ToggleKnobOff })
                            tween(TitleLabel, 0.2, { TextColor3 = Theme.TextMuted })
                        end
                        pcall(callback, state)
                    end

                    Switch.MouseButton1Click:Connect(function()
                        updateState(not state)
                    end)

                    local ToggleControl = {
                        Set = updateState,
                        Get = function() return state end,
                    }
                    table.insert(CardObj.Elements, ToggleControl)
                    return ToggleControl
                end

                -- Dropdown Selector
                function CardObj:AddDropdown(elemConfig)
                    elemConfig = elemConfig or {}
                    local text = elemConfig.Name or "Dropdown"
                    local options = elemConfig.Options or {}
                    local default = elemConfig.Default or options[1] or ""
                    local callback = elemConfig.Callback or function() end

                    local currentSelected = default
                    local isOpen = false

                    local Container = create("Frame", {
                        Name = text .. "_Dropdown",
                        Size = UDim2.new(1, 0, 0, 28),
                        BackgroundTransparency = 1,
                        Parent = CardFrame,
                    })

                    local TitleLabel = create("TextLabel", {
                        Name = "Label",
                        Size = UDim2.new(0.4, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Font = Theme.Font,
                        Text = text,
                        TextColor3 = Theme.Text,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = Container,
                    })

                    local SelectBox = create("TextButton", {
                        Name = "SelectBox",
                        Size = UDim2.new(0.6, 0, 0, 26),
                        Position = UDim2.new(0.4, 0, 0, 1),
                        BackgroundColor3 = Theme.InputBackground,
                        BorderSizePixel = 0,
                        Text = "",
                        AutoButtonColor = false,
                        Parent = Container,
                    })
                    addCorner(SelectBox, 4)
                    addStroke(SelectBox, Theme.Border, 1)

                    local SelectedText = create("TextLabel", {
                        Name = "Value",
                        Size = UDim2.new(1, -26, 1, 0),
                        Position = UDim2.new(0, 8, 0, 0),
                        BackgroundTransparency = 1,
                        Font = Theme.Font,
                        Text = tostring(currentSelected),
                        TextColor3 = Theme.Text,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = SelectBox,
                    })

                    local Arrow = create("TextLabel", {
                        Name = "Arrow",
                        Size = UDim2.new(0, 16, 1, 0),
                        Position = UDim2.new(1, -20, 0, 0),
                        BackgroundTransparency = 1,
                        Font = Theme.FontBold,
                        Text = "∨",
                        TextColor3 = Theme.TextMuted,
                        TextSize = 10,
                        Parent = SelectBox,
                    })

                    -- Options list dropdown frame
                    local OptionsList = create("Frame", {
                        Name = "OptionsList",
                        Size = UDim2.new(1, 0, 0, #options * 24 + 4),
                        Position = UDim2.new(0, 0, 1, 4),
                        BackgroundColor3 = Theme.CardHeader,
                        BorderSizePixel = 0,
                        Visible = false,
                        ZIndex = 50,
                        Parent = SelectBox,
                    })
                    addCorner(OptionsList, 4)
                    addStroke(OptionsList, Theme.Border, 1)

                    local OptListLayout = create("UIListLayout", {
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = UDim.new(0, 2),
                        Parent = OptionsList,
                    })
                    addPadding(OptionsList, 2, 2, 2, 2)

                    local function toggleDropdown(open)
                        isOpen = (open ~= nil) and open or not isOpen
                        OptionsList.Visible = isOpen
                        Arrow.Text = isOpen and "∧" or "∨"
                    end

                    for _, opt in ipairs(options) do
                        local optBtn = create("TextButton", {
                            Name = "Option_" .. tostring(opt),
                            Size = UDim2.new(1, 0, 0, 22),
                            BackgroundColor3 = Theme.InputBackground,
                            BackgroundTransparency = 1,
                            Font = Theme.Font,
                            Text = "  " .. tostring(opt),
                            TextColor3 = (opt == currentSelected) and Theme.Accent or Theme.TextMuted,
                            TextSize = 11,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 51,
                            Parent = OptionsList,
                        })
                        addCorner(optBtn, 3)

                        optBtn.MouseButton1Click:Connect(function()
                            currentSelected = opt
                            SelectedText.Text = tostring(opt)
                            for _, b in ipairs(OptionsList:GetChildren()) do
                                if b:IsA("TextButton") then
                                    b.TextColor3 = Theme.TextMuted
                                end
                            end
                            optBtn.TextColor3 = Theme.Accent
                            toggleDropdown(false)
                            pcall(callback, opt)
                        end)
                    end

                    SelectBox.MouseButton1Click:Connect(function()
                        toggleDropdown()
                    end)

                    return {
                        Set = function(val)
                            currentSelected = val
                            SelectedText.Text = tostring(val)
                            pcall(callback, val)
                        end,
                        Get = function() return currentSelected end,
                    }
                end

                -- Multi Segment Button (e.g. Players | History | Local | Fake | View Model)
                function CardObj:AddSegment(elemConfig)
                    elemConfig = elemConfig or {}
                    local options = elemConfig.Options or { "Players", "Local", "World" }
                    local default = elemConfig.Default or options[1]
                    local callback = elemConfig.Callback or function() end

                    local current = default

                    local SegBar = create("Frame", {
                        Name = "SegmentBar",
                        Size = UDim2.new(1, 0, 0, 26),
                        BackgroundColor3 = Theme.InputBackground,
                        BorderSizePixel = 0,
                        Parent = CardFrame,
                    })
                    addCorner(SegBar, 4)
                    addStroke(SegBar, Theme.Border, 1)

                    local SegLayout = create("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        Padding = UDim.new(0, 2),
                        Parent = SegBar,
                    })
                    addPadding(SegBar, 2, 2, 2, 2)

                    local count = #options
                    local segButtons = {}

                    for _, optName in ipairs(options) do
                        local isSelected = (optName == current)
                        local btn = create("TextButton", {
                            Name = optName .. "_Seg",
                            Size = UDim2.new(1 / count, -2, 1, 0),
                            BackgroundColor3 = isSelected and Theme.Accent or Theme.InputBackground,
                            BackgroundTransparency = isSelected and 0 or 1,
                            Font = isSelected and Theme.FontBold or Theme.Font,
                            Text = optName,
                            TextColor3 = isSelected and Color3.fromRGB(15, 20, 18) or Theme.TextMuted,
                            TextSize = 11,
                            AutoButtonColor = false,
                            Parent = SegBar,
                        })
                        addCorner(btn, 3)
                        table.insert(segButtons, { Button = btn, Name = optName })

                        btn.MouseButton1Click:Connect(function()
                            current = optName
                            for _, item in ipairs(segButtons) do
                                local sel = (item.Name == current)
                                tween(item.Button, 0.15, {
                                    BackgroundTransparency = sel and 0 or 1,
                                    TextColor3 = sel and Color3.fromRGB(15, 20, 18) or Theme.TextMuted,
                                })
                                item.Button.BackgroundColor3 = Theme.Accent
                                item.Button.Font = sel and Theme.FontBold or Theme.Font
                            end
                            pcall(callback, optName)
                        end)
                    end

                    return {
                        Set = function(val)
                            current = val
                            for _, item in ipairs(segButtons) do
                                local sel = (item.Name == current)
                                item.Button.BackgroundTransparency = sel and 0 or 1
                                item.Button.TextColor3 = sel and Color3.fromRGB(15, 20, 18) or Theme.TextMuted
                                item.Button.Font = sel and Theme.FontBold or Theme.Font
                            end
                            pcall(callback, val)
                        end,
                        Get = function() return current end,
                    }
                end

                -- Interactive 3D/Wireframe Character Preview Module
                function CardObj:AddPreviewBox(elemConfig)
                    elemConfig = elemConfig or {}
                    local height = elemConfig.Height or 380

                    local PreviewContainer = create("Frame", {
                        Name = "PreviewContainer",
                        Size = UDim2.new(1, 0, 0, height),
                        BackgroundColor3 = Theme.InputBackground,
                        BorderSizePixel = 0,
                        ClipsDescendants = true,
                        Parent = CardFrame,
                    })
                    addCorner(PreviewContainer, 4)
                    addStroke(PreviewContainer, Theme.Border, 1)

                    -- Tactical corner brackets
                    local function makeBracket(pos, anchor)
                        local b = create("Frame", {
                            Size = UDim2.new(0, 12, 0, 12),
                            Position = pos,
                            AnchorPoint = anchor,
                            BackgroundTransparency = 1,
                            Parent = PreviewContainer,
                        })
                        local horiz = create("Frame", {
                            Size = UDim2.new(1, 0, 0, 2),
                            BackgroundColor3 = Theme.BorderLight,
                            BorderSizePixel = 0,
                            Parent = b,
                        })
                        local vert = create("Frame", {
                            Size = UDim2.new(0, 2, 1, 0),
                            BackgroundColor3 = Theme.BorderLight,
                            BorderSizePixel = 0,
                            Parent = b,
                        })
                        if anchor.X == 1 then
                            vert.Position = UDim2.new(1, -2, 0, 0)
                        end
                        if anchor.Y == 1 then
                            horiz.Position = UDim2.new(0, 0, 1, -2)
                        end
                        return b
                    end

                    makeBracket(UDim2.new(0.2, 0, 0.15, 0), Vector2.new(0, 0))
                    makeBracket(UDim2.new(0.8, 0, 0.15, 0), Vector2.new(1, 0))
                    makeBracket(UDim2.new(0.2, 0, 0.85, 0), Vector2.new(0, 1))
                    makeBracket(UDim2.new(0.8, 0, 0.85, 0), Vector2.new(1, 1))

                    -- Left Health Bar (Orange / Yellow)
                    local HealthBar = create("Frame", {
                        Name = "HealthBar",
                        Size = UDim2.new(0, 2, 0.5, 0),
                        Position = UDim2.new(0.2, -6, 0.35, 0),
                        BackgroundColor3 = Color3.fromRGB(240, 160, 40),
                        BorderSizePixel = 0,
                        Parent = PreviewContainer,
                    })

                    local HealthNum = create("TextLabel", {
                        Name = "HealthNum",
                        Size = UDim2.new(0, 20, 0, 12),
                        Position = UDim2.new(0, -24, 0.5, -6),
                        BackgroundTransparency = 1,
                        Font = Theme.FontBold,
                        Text = "50",
                        TextColor3 = Color3.fromRGB(240, 160, 40),
                        TextSize = 10,
                        Parent = HealthBar,
                    })

                    -- Right Armor Bar (Blue)
                    local ArmorBar = create("Frame", {
                        Name = "ArmorBar",
                        Size = UDim2.new(0, 2, 0.5, 0),
                        Position = UDim2.new(0.8, 6, 0.35, 0),
                        BackgroundColor3 = Color3.fromRGB(60, 140, 240),
                        BorderSizePixel = 0,
                        Parent = PreviewContainer,
                    })

                    local ArmorNum = create("TextLabel", {
                        Name = "ArmorNum",
                        Size = UDim2.new(0, 20, 0, 12),
                        Position = UDim2.new(1, 4, 0.5, -6),
                        BackgroundTransparency = 1,
                        Font = Theme.FontBold,
                        Text = "50",
                        TextColor3 = Color3.fromRGB(60, 140, 240),
                        TextSize = 10,
                        Parent = ArmorBar,
                    })

                    -- Top Info Labels Stack
                    local InfoStack = create("Frame", {
                        Name = "InfoStack",
                        Size = UDim2.new(0.6, 0, 0, 60),
                        Position = UDim2.new(0.2, 0, 0.02, 0),
                        BackgroundTransparency = 1,
                        Parent = PreviewContainer,
                    })
                    local InfoLayout = create("UIListLayout", {
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        Padding = UDim.new(0, 2),
                        Parent = InfoStack,
                    })

                    local function addInfoLine(txt, color)
                        create("TextLabel", {
                            Size = UDim2.new(1, 0, 0, 12),
                            BackgroundTransparency = 1,
                            Font = Theme.FontMedium,
                            Text = txt,
                            TextColor3 = color or Theme.Text,
                            TextSize = 10,
                            Parent = InfoStack,
                        })
                    end

                    addInfoLine("Lua User Group", Theme.TextMuted)
                    addInfoLine("Lua Team Name", Theme.TextMuted)
                    addInfoLine("Lua Name", Theme.Text)
                    addInfoLine("Nickname", Theme.Text)

                    -- Side Money & Distance Labels
                    local DistLabel = create("TextLabel", {
                        Size = UDim2.new(0, 40, 0, 12),
                        Position = UDim2.new(0.8, 8, 0.16, 0),
                        BackgroundTransparency = 1,
                        Font = Theme.FontMedium,
                        Text = "100M",
                        TextColor3 = Theme.Text,
                        TextSize = 10,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = PreviewContainer,
                    })

                    local MoneyLabel = create("TextLabel", {
                        Size = UDim2.new(0, 50, 0, 12),
                        Position = UDim2.new(0.8, 8, 0.16, 12),
                        BackgroundTransparency = 1,
                        Font = Theme.FontMedium,
                        Text = "$10000",
                        TextColor3 = Theme.Accent,
                        TextSize = 10,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = PreviewContainer,
                    })

                    -- Bottom Weapon / Inventory Label
                    local WeaponLabel = create("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 12),
                        Position = UDim2.new(0, 0, 0.88, 0),
                        BackgroundTransparency = 1,
                        Font = Theme.FontBold,
                        Text = "Hands",
                        TextColor3 = Theme.Text,
                        TextSize = 11,
                        Parent = PreviewContainer,
                    })

                    local SubWeaponLabel = create("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 12),
                        Position = UDim2.new(0, 0, 0.88, 14),
                        BackgroundTransparency = 1,
                        Font = Theme.Font,
                        Text = "Inventory",
                        TextColor3 = Theme.TextMuted,
                        TextSize = 10,
                        Parent = PreviewContainer,
                    })

                    -- ViewportFrame for live 3D preview model
                    local Viewport = create("ViewportFrame", {
                        Name = "CharacterViewport",
                        Size = UDim2.new(0.8, 0, 0.65, 0),
                        Position = UDim2.new(0.1, 0, 0.22, 0),
                        BackgroundTransparency = 1,
                        Parent = PreviewContainer,
                    })

                    local vpCamera = Instance.new("Camera")
                    vpCamera.FieldOfView = 50
                    Viewport.CurrentCamera = vpCamera
                    vpCamera.Parent = Viewport

                    -- Render avatar or dummy inside ViewportFrame
                    task.spawn(function()
                        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                        character.Archivable = true
                        local clonedChar = character:Clone()
                        clonedChar.Parent = Viewport

                        local rootPart = clonedChar:FindFirstChild("HumanoidRootPart") or clonedChar:FindFirstChild("Torso")
                        if rootPart then
                            vpCamera.CFrame = CFrame.new(rootPart.Position + Vector3.new(0, 0.4, 5.5), rootPart.Position)
                        end

                        -- Light subtle rotation preview
                        local angle = 0
                        RunService.RenderStepped:Connect(function(dt)
                            if Viewport and Viewport.Parent and rootPart then
                                angle = angle + dt * 15
                                clonedChar:SetPrimaryPartCFrame(
                                    CFrame.new(rootPart.Position) * CFrame.Angles(0, math.rad(angle), 0)
                                )
                            end
                        end)
                    end)

                    return {
                        Container = PreviewContainer,
                        Viewport = Viewport,
                    }
                end

                return CardObj
            end

            return SubtabObj
        end

        table.insert(WindowObj.Tabs, TabObj)

        -- If first tab, auto select
        if #WindowObj.Tabs == 1 then
            TabObj:Select()
        end

        return TabObj
    end

    table.insert(Chieftain.Windows, WindowObj)
    return WindowObj
end

return Chieftain
