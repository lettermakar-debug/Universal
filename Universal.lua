-- MM2 HUB UPDATE
-- Discord: discord.gg/v8ZPq4y2nD
-- Все функции с скриншотов

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("MM2 HUB UPDATE", "DarkTheme")

-- Игроки
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Переменные
local targetPlayer = nil
local fovCircle = nil
local isAiming = false
local aimbotEnabled = false
local espEnabled = false
local espLines = {}
local espBoxes = {}
local espNames = {}
local showFOV = false
local fovSize = 200
local ignoreInnocents = true
local ignoreWalls = false
local autoShootEnabled = false
local autoShootKey = Enum.KeyCode.R
local throwKnifeKey = Enum.KeyCode.T
local knifeAuraEnabled = false
local invisibleEnabled = false
local teleportToPlayerEnabled = false

-- Функции для ESP
local function createESP(player)
    if player == LocalPlayer then return end
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    
    -- Бокс
    local box = Instance.new("BoxHandleAdornment")
    box.Size = Vector3.new(3, 5, 1)
    box.Adornee = player.Character.HumanoidRootPart
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Color3 = Color3.fromRGB(255, 0, 0)
    box.Transparency = 0.5
    box.Parent = player.Character.HumanoidRootPart
    table.insert(espBoxes, box)
    
    -- Имя
    local nameTag = Instance.new("BillboardGui")
    nameTag.Size = UDim2.new(0, 200, 0, 50)
    nameTag.Adornee = player.Character.HumanoidRootPart
    nameTag.AlwaysOnTop = true
    nameTag.Parent = player.Character.HumanoidRootPart
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = player.Name
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextScaled = true
    textLabel.Parent = nameTag
    table.insert(espNames, nameTag)
end

local function clearESP()
    for _, v in pairs(espBoxes) do v:Destroy() end
    espBoxes = {}
    for _, v in pairs(espNames) do v:Destroy() end
    espNames = {}
end

local function updateESP()
    clearESP()
    if not espEnabled then return end
    for _, player in pairs(Players:GetPlayers()) do
        createESP(player)
    end
end

-- Функция для Aim
local function getClosestPlayer()
    local closest = nil
    local shortestDistance = fovSize
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if ignoreInnocents and player.Team == "Innocent" then continue end
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then continue end
        
        local root = player.Character.HumanoidRootPart
        local screenPos, onScreen = Camera:WorldToScreenPoint(root.Position)
        if not onScreen then continue end
        
        if ignoreWalls then
            local ray = Ray.new(Camera.CFrame.Position, root.Position - Camera.CFrame.Position)
            local hit = workspace:FindPartOnRay(ray)
            if hit and hit.Parent ~= player.Character then continue end
        end
        
        local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
        if distance < shortestDistance then
            shortestDistance = distance
            closest = player
        end
    end
    
    return closest
end

-- Создание FOV
local function createFOV()
    if fovCircle then fovCircle:Destroy() end
    if not showFOV then return end
    
    fovCircle = Drawing.new("Circle")
    fovCircle.Radius = fovSize
    fovCircle.Thickness = 2
    fovCircle.Filled = false
    fovCircle.Color = Color3.fromRGB(255, 0, 0)
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    fovCircle.Visible = true
    fovCircle.ZIndex = 0
end

-- Основные функции
local function teleportTo(position)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(position)
    end
end

local function getGun()
    for _, item in pairs(workspace:GetDescendants()) do
        if item.Name == "Gun" and item:IsA("Tool") then
            return item
        end
    end
    return nil
end

-- Вкладки GUI
local MainTab = Window.NewTab("Главная")
local MainSection = MainTab.NewSection("Основное")

MainSection.NewButton("Обновить ESP", "Обновить ESP", function()
    updateESP()
end)

MainSection.NewToggle("ESP Вкл", "Включить ESP", function(state)
    espEnabled = state
    if state then
        updateESP()
    else
        clearESP()
    end
end)

local AimTab = Window.NewTab("Aim")
local AimSection = AimTab.NewSection("Настройки Aim")

AimSection.NewToggle("Aimbot", "Включить аимбот", function(state)
    aimbotEnabled = state
end)

AimSection.NewSlider("Размер FOV", "Размер поля зрения", 500, 50, 200, function(value)
    fovSize = value
    if fovCircle then
        fovCircle.Radius = value
    end
end)

AimSection.NewToggle("Показать FOV", "Показать поле зрения", function(state)
    showFOV = state
    if state then
        createFOV()
    elseif fovCircle then
        fovCircle:Destroy()
        fovCircle = nil
    end
end)

AimSection.NewToggle("Игнорировать мирных", "Не наводиться на мирных", function(state)
    ignoreInnocents = state
end)

AimSection.NewToggle("Игнорировать стены", "Наводиться сквозь стены", function(state)
    ignoreWalls = state
end)

local TeleportsTab = Window.NewTab("Телепорты")
local TeleportsSection = TeleportsTab.NewSection("Телепорты")

TeleportsSection.NewButton("К убийце", "Телепорт к убийце", function()
    for _, player in pairs(Players:GetPlayers()) do
        if player.Team == "Murderer" and player.Character then
            teleportTo(player.Character.HumanoidRootPart.Position)
            break
        end
    end
end)

TeleportsSection.NewButton("К шерифу", "Телепорт к шерифу", function()
    for _, player in pairs(Players:GetPlayers()) do
        if player.Team == "Sheriff" and player.Character then
            teleportTo(player.Character.HumanoidRootPart.Position)
            break
        end
    end
end)

TeleportsSection.NewButton("К оружию", "Телепорт к оружию", function()
    local gun = getGun()
    if gun then
        teleportTo(gun.Parent.Position)
    end
end)

TeleportsSection.NewButton("В безопасную зону", "Телепорт в безопасную зону", function()
    teleportTo(Vector3.new(0, 10, 0))
end)

TeleportsSection.NewButton("В лобби", "Телепорт в лобби", function()
    teleportTo(Vector3.new(0, 0, 0))
end)

TeleportsSection.NewButton("На арену", "Телепорт на арену", function()
    teleportTo(Vector3.new(50, 10, 50))
end)

local FarmTab = Window.NewTab("Фарм")
local FarmSection = FarmTab.NewSection("Фарм")

FarmSection.NewToggle("Аура ножа", "Аура ножа (убивает всех рядом)", function(state)
    knifeAuraEnabled = state
    if state then
        RunService.Heartbeat:Connect(function()
            if knifeAuraEnabled and LocalPlayer.Character then
                local root = LocalPlayer.Character.HumanoidRootPart
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local dist = (root.Position - player.Character.HumanoidRootPart.Position).Magnitude
                        if dist < 10 then
                            player.Character.Humanoid.Health = 0
                        end
                    end
                end
            end
        end)
    end
end)

FarmSection.NewButton("Кнопка броска ножа", "Бросок ножа", function()
    LocalPlayer.Character:FindFirstChildWhichIsA("Tool"):Activate()
end)

FarmSection.NewKeybind("Клавиша броска ножа", "Клавиша для броска ножа", Enum.KeyCode.T, function()
    -- Установка клавиши
end)

local MiscTab = Window.NewTab("Разное")
local MiscSection = MiscTab.NewSection("Разное")

MiscSection.NewToggle("Невидимость", "Сделать игрока невидимым", function(state)
    invisibleEnabled = state
    if LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = state and 1 or 0
            end
        end
    end
end)

MiscSection.NewButton("Привести шерифа", "Привести и заморозить шерифа", function()
    for _, player in pairs(Players:GetPlayers()) do
        if player.Team == "Sheriff" and player.Character then
            player.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
            player.Character.HumanoidRootPart.Anchored = true
        end
    end
end)

MiscSection.NewButton("Разморозить", "Разморозить всех", function()
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.Anchored = false
        end
    end
end)

MiscSection.NewButton("Взять оружие (без телепорта)", "Мгновенно взять оружие", function()
    local gun = getGun()
    if gun then
        gun.Parent = LocalPlayer.Character
    end
end)

MiscSection.NewButton("Флинг убийцы", "Подбросить убийцу", function()
    for _, player in pairs(Players:GetPlayers()) do
        if player.Team == "Murderer" and player.Character then
            player.Character.HumanoidRootPart.Velocity = Vector3.new(0, 1000, 0)
        end
    end
end)

MiscSection.NewButton("Флинг шерифа", "Подбросить шерифа", function()
    for _, player in pairs(Players:GetPlayers()) do
        if player.Team == "Sheriff" and player.Character then
            player.Character.HumanoidRootPart.Velocity = Vector3.new(0, 1000, 0)
        end
    end
end)

-- Авто-выстрел
local AutoShootTab = Window.NewTab("Авто-выстрел")
local AutoShootSection = AutoShootTab.NewSection("Настройки авто-выстрела")

AutoShootSection.NewToggle("Авто-выстрел", "Автоматически стрелять в цель", function(state)
    autoShootEnabled = state
end)

AutoShootSection.NewKeybind("Клавиша авто-выстрела", "Клавиша для авто-выстрела", Enum.KeyCode.R, function()
    -- Установка клавиши
end)

-- Основной цикл
local Camera = workspace.CurrentCamera
createFOV()

RunService.Heartbeat:Connect(function()
    -- Aimbot
    if aimbotEnabled then
        local target = getClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local root = target.Character.HumanoidRootPart
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, root.Position)
        end
    end
    
    -- ESP обновление
    if espEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                -- Обновляем позиции ESP
            end
        end
    end
    
    -- Обновление FOV
    if fovCircle then
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    end
end)

-- Обработка клавиш
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == autoShootKey and autoShootEnabled then
        -- Авто-выстрел
        local target = getClosestPlayer()
        if target and target.Character then
            target.Character.Humanoid.Health = 0
        end
    end
    
    if input.KeyCode == throwKnifeKey then
        -- Бросок ножа
        if LocalPlayer.Character then
            local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
            if tool then
                tool:Activate()
            end
        end
    end
end)

print("MM2 HUB UPDATE загружен! Discord: discord.gg/v8ZPq4y2nD")
