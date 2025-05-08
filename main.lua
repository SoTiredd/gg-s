local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Revival Hub",
    Icon = 88230713249860 , -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
    LoadingTitle = "This is poorly made",
    LoadingSubtitle = "by MunchyCrunch",
    Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes
 
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface
 
    ConfigurationSaving = {
       Enabled = true,
       FolderName = blackoutrevival, -- Create a custom folder for your hub/game
       FileName = "funnyHub"
    },
 
    Discord = {
       Enabled = true, -- Prompt the user to join your Discord server if their executor supports it
       Invite = "jhmPz32bj2", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
       RememberJoins = true -- Set this to false to make them join the discord every time they load it up
    },
 
    KeySystem = false, -- Set this to true to use our key system
    KeySettings = {
       Title = "Untitled",
       Subtitle = "Key System",
       Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
       FileName = "Keyrevival", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
       SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
       GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
       Key = {"PoorlyMadeScriptKey"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
    }
 })
local Tab = Window:CreateTab("Aim", 16081386298) -- Title, Image

-- // Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- // Variables
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local MAX_DISTANCE = 150
local FOV_RADIUS = 250
local AimlockEnabled = false
local IsAiming = false
local CachedNPCs = {}
local TempCache = {} -- временное хранилище для обновлений
local CurrentTarget = nil

-- // FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness = 1
fovCircle.NumSides = 100
fovCircle.Radius = FOV_RADIUS
fovCircle.Transparency = 0.6
fovCircle.Visible = false


Tab:CreateToggle({
    Name = "Enable Aimlock",
    CurrentValue = false,
    Flag = "AimlockToggle",
    Callback = function(Value)
        AimlockEnabled = Value
        fovCircle.Visible = Value
    end
})

-- // Найти ближайшую цель
local function GetClosestTargetInFOV()
    local closest, shortestDistance = nil, math.huge
    for _, npc in ipairs(CachedNPCs) do
        if npc and npc:FindFirstChild("Head") then
            local head = npc.Head
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            local mousePos = UserInputService:GetMouseLocation()
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
            local inDistance = (Camera.CFrame.Position - head.Position).Magnitude <= MAX_DISTANCE
            local isDowned = npc:GetAttribute("NL") == true

            if onScreen and dist < FOV_RADIUS and dist < shortestDistance and inDistance and not isDowned then
                closest = npc
                shortestDistance = dist
            end
        end
    end
    return closest
end

-- // Простой жёсткий lock на цель
local function LockOnTarget(target)
    if target and target:FindFirstChild("Head") then
        local headPos = target.Head.Position
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, headPos)
    end
end

-- // Асинхронное обновление списка целей
local function UpdateCachedNPCs()
    -- Кэш будет обновлён плавно в TempCache и затем заменит основной CachedNPCs
    TempCache = {}
    local allModels = workspace:GetDescendants()
    local batchSize = 50
    local processed = 0

    for _, obj in ipairs(allModels) do
        if not AimlockEnabled then break end

        if obj:IsA("Model")
            and obj:FindFirstChild("Humanoid")
            and obj:FindFirstChild("Head")
            and obj.Name ~= LocalPlayer.Name then

            local head = obj.Head
            local distance = (Camera.CFrame.Position - head.Position).Magnitude
            local isDowned = obj:GetAttribute("NL") == true

            if distance <= MAX_DISTANCE and not isDowned then
                table.insert(TempCache, obj)
            end
        end

        processed += 1
        if processed % batchSize == 0 then
            task.wait()
        end
    end

    -- Только после полной обработки заменяем основной кэш
    CachedNPCs = TempCache
end

-- // Цикл обновления кэша (раз в 2 сек)
coroutine.wrap(function()
    while true do
        if AimlockEnabled then
            UpdateCachedNPCs()
        end
        task.wait(2)
    end
end)()

-- // Обработка зажатия ПКМ
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        IsAiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input, processed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        IsAiming = false
        CurrentTarget = nil
    end
end)

-- // Основной рендер цикл
RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    fovCircle.Position = mousePos

    if AimlockEnabled and IsAiming then
        CurrentTarget = GetClosestTargetInFOV()
        if CurrentTarget then
            LockOnTarget(CurrentTarget)
        end
    end
end)


local Tab = Window:CreateTab("Visuals", "eye") -- Title, Image

local Tab = Window:CreateTab("Exploits", 76443890191204) -- Title, Image

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local humanoid = nil
local infiniteJumpEnabled = false

-- Detect character & humanoid on respawnw
local function setupCharacter()
    local character = player.Character or player.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")
end

player.CharacterAdded:Connect(setupCharacter)
setupCharacter()

-- Listen for jump input
UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)
local Workspace = game:GetService("Workspace")

-- Переменная для хранения подключения
local descendantConnection = nil

-- Функция обработки включения/отключения
local function HandlePromptToggle(enabled)
    if enabled then
        -- Установка HoldDuration = 0 для всех существующих
        for _, prompt in ipairs(Workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                prompt.HoldDuration = 0
            end
        end

        -- Отслеживание новых Prompt
        descendantConnection = Workspace.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("ProximityPrompt") then
                descendant.HoldDuration = 0
            end
        end)
    else
        -- Отключение подключения
        if descendantConnection then
            descendantConnection:Disconnect()
            descendantConnection = nil
        end

        -- Возврат к стандартному HoldDuration (можно изменить)
        for _, prompt in ipairs(Workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                prompt.HoldDuration = 1
            end
        end
    end
end
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VirtualInput = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local lootEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Loot"):WaitForChild("MinigameResult")

-- Переменная-флаг активности перехвата
local interceptEnabled = false

-- Перехват __namecall
local mt = getrawmetatable(game)
setreadonly(mt, false)
local old = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if interceptEnabled and tostring(self) == "MinigameResult" and method == "FireServer" and #args == 1 then
        local obj = args[1]

        task.spawn(function()
            local timeout = 3
            local elapsed = 0
            while elapsed < timeout and not Workspace:FindFirstChild("Lockpick") do
                task.wait(0.1)
                elapsed += 0.1
            end

            task.wait(0.5)

            lootEvent:FireServer(obj, true)

            VirtualInput:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
            task.wait(0.05)
            VirtualInput:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
        end)
    end

    return old(self, unpack(args))
end)

-- Toggle Rayfield UI
local Toggle = Tab:CreateToggle({
    Name = "Auto Lockpick",
    CurrentValue = false,
    Flag = "Toggle1",
    Callback = function(Value)
        interceptEnabled = Value
    end,
})

-- Rayfield Toggle
local Toggle = Tab:CreateToggle({
   Name = "Instant interaction",
   CurrentValue = false,
   Flag = "Toggle2",
   Callback = function(Value)
      HandlePromptToggle(Value)
   end,
})

-- Rayfield Toggle UI
local Toggle = Tab:CreateToggle({
    Name = "Infinite jump",
    CurrentValue = false,
    Flag = "Toggle3",
    Callback = function(Value)
        infiniteJumpEnabled = Value
    end,
})
local mt = getrawmetatable(game)
setreadonly(mt, false)

local oldNamecall = mt.__namecall
local blockRagdoll = false

-- Переопределяем __namecall для перехвата FireServer
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()

    if method == "FireServer" and tostring(self) == "Ragdoll" and blockRagdoll then
        return -- блокируем вызов
    end

    return oldNamecall(self, ...)
end)

local mt = getrawmetatable(game)
setreadonly(mt, false)
local old = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if getgenv().antiDamageEnabled and self.Name == "Damage" and method == "FireServer" then
        return
    end

    return old(self, unpack(args))
end)

-- Создание переключателя Rayfield
local Toggle = Tab:CreateToggle({
    Name = "No ragdoll",
    CurrentValue = false,
    Flag = "Toggle4",
    Callback = function(Value)
        blockRagdoll = Value
    end,
})
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local mt = getrawmetatable(game)
local oldNamecall = oldNamecall or mt.__namecall

local conn_attr, conn_char

function ToggleInfiniteStamina(enabled)
    -- FireServer хук
    setreadonly(mt, false)

    if enabled then
        if mt.__namecall ~= oldNamecall then
            oldNamecall = mt.__namecall
        end

        mt.__namecall = newcclosure(function(self, ...)
            local args = {...}
            local method = getnamecallmethod()

            if method == "FireServer"
                and tostring(self) == "Stamina"
                and self:IsDescendantOf(ReplicatedStorage:WaitForChild("Events"):WaitForChild("Player")) then
                return -- Блокируем трату при прыжке
            end

            return oldNamecall(self, unpack(args))
        end)
    else
        if oldNamecall then
            mt.__namecall = oldNamecall
        end
    end

    -- Слушатель Sprinting
    local function SetupSprintingListener(char)
        if conn_attr then conn_attr:Disconnect() end

        conn_attr = char:GetAttributeChangedSignal("Sprinting"):Connect(function()
            if enabled and char:GetAttribute("Sprinting") == true then
                char:SetAttribute("Sprinting", false)
            end
        end)
    end

    if conn_char then conn_char:Disconnect() end

    conn_char = LocalPlayer.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart", 5)
        SetupSprintingListener(char)
    end)

    if LocalPlayer.Character then
        SetupSprintingListener(LocalPlayer.Character)
    end
end

local Toggle = Tab:CreateToggle({
    Name = "No fall damage",
    CurrentValue = false,
    Flag = "Toggle5", 
    Callback = function(Value)
    getgenv().antiDamageEnabled = Value
    end,
 })
 Tab:CreateToggle({
   Name = "Infinite Stamina",
   CurrentValue = false,
   Flag = "Toggle6",
   Callback = function(Value)
       ToggleInfiniteStamina(Value)
   end,
})


local Tab = Window:CreateTab("Misc", "cog") -- Title, Image
local Button = Tab:CreateButton({
   Name = "Bag esp",
   Callback = function()
   print("Bag esp on")
    -- Настройки
-- Настройки
local importantItems = {
	["Red Keycard"] = Color3.fromRGB(255, 0, 0),
	["Orange Keycard"] = Color3.fromRGB(255, 165, 0),
	["Green Keycard"] = Color3.fromRGB(0, 255, 0),
	["Purple Keycard"] = Color3.fromRGB(128, 0, 128),
    ["Blue Keycard"] = Color3.fromRGB(128, 0, 128),
    ["Photon Accelerator"] = Color3.fromRGB(102, 0, 51),
    ["RSH-12"] = Color3.fromRGB(102, 0, 51),
    ["Red Flare Gun"] = Color3.fromRGB(102, 0, 51),
    ["Green Flare Gun"] = Color3.fromRGB(102, 0, 51),
    ["RPG-18"] = Color3.fromRGB(102, 0, 51),
    ["KS-23"] = Color3.fromRGB(102, 0, 51),
    ["RPG-7"] = Color3.fromRGB(102, 0, 51),
    ["Operator Vest"] = Color3.fromRGB(102, 0, 51),
    ["Operator Leggings"] = Color3.fromRGB(102, 0, 51),
    ["Operator Helmet"] = Color3.fromRGB(102, 0, 51),
    ["Operator Helmet MK2"] = Color3.fromRGB(102, 0, 51),
    ["Operator Helmet MK1"] = Color3.fromRGB(102, 0, 51),
    ["Commander Helmet"] = Color3.fromRGB(102, 0, 51),
    ["Commander Vest"] = Color3.fromRGB(102, 0, 51),
    ["Commander Leggings"] = Color3.fromRGB(102, 0, 51),
    ["Bladedancer Helmet"] = Color3.fromRGB(102, 0, 51),
    ["Bladedancer Vest"] = Color3.fromRGB(102, 0, 51),
    ["Bladedancer Leggings"] = Color3.fromRGB(102, 0, 51),


}
local maxDistance = 100



-- Получаем список всех важных предметов
local function getItemInfo(mesh)
	local lootTable = mesh:FindFirstChild("LootTable")
	local labels = {}
	local colors = {}
	local isImportant = false

	if lootTable then
		for _, item in ipairs(lootTable:GetChildren()) do
			if importantItems[item.Name] then
				table.insert(labels, item.Name)
				colors[item.Name] = importantItems[item.Name]
				isImportant = true
			end
		end
	end

	if #labels == 0 then
		labels = {"Bag"}
		colors["Bag"] = Color3.new(1, 1, 1)
	end

	return labels, colors, isImportant
end

-- Создание Billboard ESP
local function createBillboardGui(labels, colors, adornee, isImportant)
	-- Удаляем старый ESP если есть
	local oldESP = adornee:FindFirstChild("ESP")
	if oldESP then
		oldESP:Destroy()
	end

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "ESP"
	billboardGui.Adornee = adornee
	billboardGui.Size = UDim2.new(0, 100, 0, 15 * #labels)
	billboardGui.StudsOffset = Vector3.new(0, 2, 0)
	billboardGui.AlwaysOnTop = true

	for i, labelText in ipairs(labels) do
		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1, 0, 0, 15)
		textLabel.Position = UDim2.new(0, 0, 0, (i - 1) * 15)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = labelText
		textLabel.TextColor3 = colors[labelText] or Color3.new(1, 1, 1)
		textLabel.TextStrokeTransparency = 0.5
		textLabel.TextScaled = false
		textLabel.TextSize = 12
		textLabel.Font = Enum.Font.SourceSansBold
		textLabel.Parent = billboardGui
	end

	billboardGui.Parent = adornee

	-- Обновляем видимость по расстоянию
	local runService = game:GetService("RunService")
	local player = game.Players.LocalPlayer

	runService.RenderStepped:Connect(function()
		if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
		if not adornee:IsDescendantOf(game) then return end

		local dist = (adornee.Position - player.Character.HumanoidRootPart.Position).Magnitude
		billboardGui.Enabled = isImportant or dist <= maxDistance
	end)
end

-- Обновление всех объектов в Loot
local function updateESP()
	local lootFolder = game.Workspace:FindFirstChild("Debris") and game.Workspace.Debris:FindFirstChild("Loot")
	if not lootFolder then return end

	for _, mesh in ipairs(lootFolder:GetChildren()) do
		if mesh:IsA("Model") or mesh:IsA("BasePart") then
			local adornee = mesh:IsA("Model") and (mesh.PrimaryPart or mesh:FindFirstChildWhichIsA("BasePart")) or mesh
			if adornee then
				local labels, colors, isImportant = getItemInfo(mesh)
				createBillboardGui(labels, colors, adornee, isImportant)
			end
		end
	end
end

-- При добавлении новой сумки
game.Workspace.Debris.Loot.ChildAdded:Connect(function(child)
	wait(0.2)
	updateESP()

	-- Обновляем при появлении предметов внутри
	local lootTable = child:WaitForChild("LootTable", 2)
	if lootTable then
		lootTable.ChildAdded:Connect(function()
			wait(0.1)
			updateESP()
		end)
		lootTable.ChildRemoved:Connect(function()
			wait(0.1)
			updateESP()
		end)
	end
end)

-- Инициализация
updateESP()
   
   end,
})
local SoundId = "rbxassetid://18437707128"

local Button = Tab:CreateButton({
   Name = "Кириешки",
   Callback = function()
      local sound = Instance.new("Sound")
      sound.SoundId = SoundId
      sound.Volume = 100
      sound.PlayOnRemove = true
      sound.Parent = workspace
      sound:Destroy() -- PlayOnRemove позволит сразу воспроизвести звук при удалении
   end,
})


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local NoclipConnection = nil
local Clip = true
local floatName = "HumanoidRootPart"

local updateInterval = 0.3
local lastUpdate = 0

local function ApplyNoclip(dt)
	lastUpdate += dt
	if lastUpdate < updateInterval then return end
	lastUpdate = 0

	if not Clip and LocalPlayer.Character then
		for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do
			if v:IsA("BasePart") and v.CanCollide and v.Name ~= floatName then
				v.CanCollide = false
			end
		end
	end
end

-- Включение Noclip
local function noclip()
	if NoclipConnection then return end
	Clip = false
	lastUpdate = 0
	NoclipConnection = RunService.Heartbeat:Connect(ApplyNoclip)
end

-- Выключение Noclip и восстановление CanCollide
local function clip()
	if NoclipConnection then
		NoclipConnection:Disconnect()
		NoclipConnection = nil
	end
	Clip = true

	local character = LocalPlayer.Character
	if character then
		for _, v in ipairs(character:GetDescendants()) do
			if v:IsA("BasePart") and v.Name ~= floatName then
				v.CanCollide = true
			end
		end
	end
end

-- Переключатель
local Toggle = Tab:CreateToggle({
	Name = "Noclip",
	CurrentValue = not Clip,
	Flag = "noclipToggle",
	Callback = function(Value)
		if Value then
			noclip()
		else
			clip()
		end
	end,
})


local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Подключаем сервисы
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

-- Игрок и части
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Управляющие силы
local velocity = Instance.new("BodyVelocity")
velocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
velocity.P = 1e5

local gyro = Instance.new("BodyGyro")
gyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
gyro.P = 1e5

-- Направление и параметры
local flying = false
local baseSpeed = 20
local currentSpeed = baseSpeed
local acceleration = 10
local deceleration = 5
local maxSpeed = 100

local direction = {
    forward = false,
    backward = false,
    left = false,
    right = false,
    up = false,
    down = false
}

-- Обработка клавиш
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.W then direction.forward = true end
    if input.KeyCode == Enum.KeyCode.S then direction.backward = true end
    if input.KeyCode == Enum.KeyCode.A then direction.left = true end
    if input.KeyCode == Enum.KeyCode.D then direction.right = true end
    if input.KeyCode == Enum.KeyCode.Space then direction.up = true end
    if input.KeyCode == Enum.KeyCode.LeftControl then direction.down = true end
end)

UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then direction.forward = false end
    if input.KeyCode == Enum.KeyCode.S then direction.backward = false end
    if input.KeyCode == Enum.KeyCode.A then direction.left = false end
    if input.KeyCode == Enum.KeyCode.D then direction.right = false end
    if input.KeyCode == Enum.KeyCode.Space then direction.up = false end
    if input.KeyCode == Enum.KeyCode.LeftControl then direction.down = false end
end)

-- 🟢 Rayfield Keybind
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local flying = false
local baseSpeed, maxSpeed, acceleration, deceleration = 5, 50, 2, 1
local currentSpeed = baseSpeed

local direction = {
    forward = false, backward = false,
    left = false, right = false,
    up = false, down = false
}

local rootPart, humanoid, velocity, gyro

local function setupCharacter(char)
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")

    velocity = Instance.new("BodyVelocity")
    velocity.MaxForce = Vector3.new(1, 1, 1) * 1e5
    velocity.Velocity = Vector3.zero

    gyro = Instance.new("BodyGyro")
    gyro.MaxTorque = Vector3.new(1, 1, 1) * 1e5
    gyro.P = 1e4
end

-- Повторная инициализация после респавна
LocalPlayer.CharacterAdded:Connect(setupCharacter)
if LocalPlayer.Character then
    setupCharacter(LocalPlayer.Character)
end

-- Переключение полёта через кейбинд
local Keybind = Tab:CreateKeybind({
    Name = "Fly Keybind",
    CurrentKeybind = "Insert",
    HoldToInteract = false,
    Flag = "FlyKeybind",
    Callback = function()
        flying = not flying

        if flying and rootPart and humanoid then
            humanoid.PlatformStand = true
            currentSpeed = baseSpeed

            velocity.Parent = rootPart
            gyro.Parent = rootPart

            RunService:BindToRenderStep("FlyControl", Enum.RenderPriority.Character.Value, function()
                local cam = workspace.CurrentCamera
                local move = Vector3.zero

                if direction.forward then move += cam.CFrame.LookVector end
                if direction.backward then move -= cam.CFrame.LookVector end
                if direction.left then move -= cam.CFrame.RightVector end
                if direction.right then move += cam.CFrame.RightVector end
                if direction.up then move += cam.CFrame.UpVector end
                if direction.down then move -= cam.CFrame.UpVector end

                if move.Magnitude > 0 then
                    currentSpeed = direction.forward and math.min(currentSpeed + acceleration, maxSpeed)
                        or math.max(currentSpeed - deceleration, baseSpeed)
                    velocity.Velocity = move.Unit * currentSpeed
                else
                    velocity.Velocity = Vector3.zero
                    currentSpeed = math.max(currentSpeed - deceleration, baseSpeed)
                end

                gyro.CFrame = cam.CFrame
            end)
        else
            if humanoid then humanoid.PlatformStand = false end
            if velocity then velocity.Parent = nil end
            if gyro then gyro.Parent = nil end
            RunService:UnbindFromRenderStep("FlyControl")
        end
    end
})

-- Управление направлениями
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local code = input.KeyCode
        if code == Enum.KeyCode.W then direction.forward = true end
        if code == Enum.KeyCode.S then direction.backward = true end
        if code == Enum.KeyCode.A then direction.left = true end
        if code == Enum.KeyCode.D then direction.right = true end
        if code == Enum.KeyCode.Space then direction.up = true end
        if code == Enum.KeyCode.LeftControl then direction.down = true end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local code = input.KeyCode
        if code == Enum.KeyCode.W then direction.forward = false end
        if code == Enum.KeyCode.S then direction.backward = false end
        if code == Enum.KeyCode.A then direction.left = false end
        if code == Enum.KeyCode.D then direction.right = false end
        if code == Enum.KeyCode.Space then direction.up = false end
        if code == Enum.KeyCode.LeftControl then direction.down = false end
    end
end)

local Button = Tab:CreateButton({
   Name = "Fast rejoin",
   Callback = function()
   local ts = game:GetService("TeleportService")
    local p = game:GetService("Players").LocalPlayer
    ts:Teleport(game.PlaceId, p)
   end,
})
local Players = game:GetService("Players")

-- ✅ List of staff members (Usernames or UserIds)
local StaffList = {
    ["oTheSilver"] = true,
    ["oxitender"] = true,
    ["Zanee_K"] = true,
    ["Capra_K"] = true,
    ["55Epa"] = true,
    ["Asprekt"] = true,
    ["voaj77"] = true,
    ["Cynicer"] = true,
    ["Avitosud"] = true,
    ["TheLuckyMiner2015"] = true,
    ["WarMarble"] = true,
    ["feIsiea"] = true,
    ["DefineAsty"] = true,
    ["amTempo"] = true,
    ["Efflorescized"] = true,
    ["Poipokoi"] = true,
    ["necefh23"] = true,
    ["RiccoE46"] = true,
    ["CounterThat"] = true,
    ["TheKrapy"] = true
}

-- 🔔 Function to show notification
local function notifyStaffJoin(player)
    if Rayfield then
        Rayfield:Notify({
            Title = "⚠️ Staff Alert",
            Content = player.Name .. " has joined the server.",
            Duration = 6.5,
            Image = 4483362458,
        })
    end
end

-- 🧠 Check if player is in StaffList
local function isStaff(player)
    return StaffList[player.Name] or StaffList[player.UserId]
end

-- 👀 Monitor existing and future players
for _, player in ipairs(Players:GetPlayers()) do
    if isStaff(player) then
        notifyStaffJoin(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if isStaff(player) then
        notifyStaffJoin(player)
    end
end)
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local equippedGear = playerGui:WaitForChild("EquippedGear")

local screenGui
local textLabel
local connection
local gearConnection

-- Создаёт отображение прочности
local function createDisplay(gasMask)
    if screenGui then return end -- Не создавать повторно

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DurabilityDisplay"
    screenGui.Parent = playerGui

    textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0, 100, 0, 30)
    textLabel.Position = UDim2.new(1, -110, 1, -40)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Text = ""
    textLabel.Parent = screenGui

    local function updateDurability()
        local durability = gasMask:GetAttribute("Durability")
        if durability ~= nil then
            local percentage = math.clamp(math.floor(durability + 0.5), 0, 100)
            textLabel.Text = percentage .. "%"
            if percentage < 25 then
                textLabel.TextColor3 = Color3.new(1, 0, 0)
            else
                textLabel.TextColor3 = Color3.new(1, 1, 1)
            end
        else
            textLabel.Text = ""
        end
    end

    connection = gasMask:GetAttributeChangedSignal("Durability"):Connect(updateDurability)
    updateDurability()
end

-- Удаляет отображение и отключает события
local function removeDisplay()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
        textLabel = nil
    end
end

-- Проверяет наличие маски и запускает отображение, если нужно
local function checkAndShow()
    local gasMask = equippedGear:FindFirstChild("Gas Mask")
    if gasMask then
        createDisplay(gasMask)
    else
        removeDisplay()
    end
end

-- Обрабатывает переключение тумблера
local toggleEnabled = false

-- Rayfield Toggle
local Toggle = Tab:CreateToggle({
    Name = "Show Gas Mask Durability",
    CurrentValue = false,
    Flag = "Toggle1",
    Callback = function(Value)
        toggleEnabled = Value
        if Value then
            checkAndShow()
            -- Следим за изменениями в EquippedGear
            gearConnection = equippedGear.ChildAdded:Connect(function(child)
                if child.Name == "Gas Mask" then
                    checkAndShow()
                end
            end)
            equippedGear.ChildRemoved:Connect(function(child)
                if child.Name == "Gas Mask" then
                    checkAndShow()
                end
            end)
        else
            if gearConnection then
                gearConnection:Disconnect()
                gearConnection = nil
            end
            removeDisplay()
        end
    end,
})

