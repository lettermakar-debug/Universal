-- MM2 HUB UPDATE - ПОЛНАЯ РАБОЧАЯ ВЕРСИЯ
-- Discord: discord.gg/v8ZPq4y2nD

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local Workspace = game:GetService("Workspace")

-- ПЕРЕМЕННЫЕ
local espEnabled = false
local espObjects = {}
local aimbotEnabled = false
local fovSize = 200
local showFOV = false
local fovCircle = nil
local speedEnabled = false
local jumpEnabled = false
local autoShootEnabled = false
local knifeAuraEnabled = false
local ESP_TEAM_COLORS = {
    Murderer = Color3.fromRGB(255, 0, 0),
    Sheriff = Color3.fromRGB(0, 100, 255),
    Innocent = Color3.fromRGB(0, 255, 0)
}

-- ФУНКЦИЯ ПОЛУЧЕНИЯ РОЛИ
local function getPlayerRole(player)
    if not player or not player.Character then return "Innocent" end
    for _, item in pairs(player.Character:GetChildren()) do
        if item:IsA("Tool") then
            if item.Name == "Knife" then return "Murderer" end
            if item.Name == "Gun" then return "Sheriff" end
        end
    end
    return "Innocent"
end

-- ОЧИСТКА ESP
local function clearESP()
    for _, v in pairs(espObjects) do
        pcall(function() v:Destroy() end)
    end
    espObjects = {}
end

-- СОЗДАНИЕ ESP
local function createESP(player)
    if player == LocalPlayer or not player.Character then return end
    
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local role = getPlayerRole(player)
    local color = ESP_TEAM_COLORS[role] or Color3.fromRGB(255, 255, 255)
    
    -- Бокс
    local box = Instance.new("BoxHandleAdornment")
    box.Size = Vector3.new(3, 5, 1)
    box.Adornee = root
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Color3 = color
    box.Transparency = 0.5
    box.Parent = root
    table.insert(espObjects, box)
    
    -- Имя с ролью
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.Adornee = root
    billboard.AlwaysOnTop = true
    billboard.Parent = root
    table.insert(espObjects, billboard)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = player.Name .. " [" .. role .. "]"
    label.TextColor3 = color
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard
    table.insert(espObjects, label)
    
    -- Линия к игроку
    local line = Instance.new("LineHandleAdornment")
    line.Length = 0
    line.Adornee = root
    line.AlwaysOnTop = true
    line.ZIndex = 5
    line.Color3 = color
    line.Thickness = 2
    line.Parent = root
    table.insert(espObjects, line)
end

-- ОБНОВЛЕНИЕ ESP
local function updateESP()
    clearESP()
    if not espEnabled then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            createESP(player)
        end
    end
end

-- СОЗДАНИЕ FOV
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

-- AIMPOT
local function getClosestPlayer()
    local closest = nil
    local shortestDistance = fovSize
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        
        local screenPos, onScreen = Camera:WorldToScreenPoint(root.Position)
        if not onScreen then continue end
        
        local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
        if distance < shortestDistance then
            shortestDistance = distance
            closest = player
        end
    end
    return closest
end

-- ТЕЛЕПОРТЫ
local function teleportToPlayer(player)
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
    end
end

local function getGun()
    for _, item in pairs(Workspace:GetDescendants()) do
        if item:IsA("Tool") and item.Name == "Gun" then
            return item
        end
    end
    return nil
end

-- УСКОРЕНИЕ
local function setSpeed(state)
    speedEnabled = state
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local humanoid = LocalPlayer.Character.Humanoid
        if state then
            humanoid.WalkSpeed = 32
        else
            humanoid.WalkSpeed = 16
        end
    end
end

-- ПРЫЖОК
local function setJumpPower(state)
    jumpEnabled = state
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local humanoid = LocalPlayer.Character.Humanoid
        if state then
            humanoid.JumpPower = 100
        else
            humanoid.JumpPower = 50
        end
    end
end

-- СОЗДАНИЕ GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MM2HUBUPDATE"
screenGui.Parent = game.CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 450, 0, 600)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -300)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- ЗАГОЛОВОК
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
title.Text = "MM2 HUB UPDATE"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.BorderSizePixel = 0
title.Parent = mainFrame

-- КНОПКА ЗАКРЫТИЯ
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled = true
closeBtn.BorderSizePixel = 0
closeBtn.Parent = mainFrame
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    clearESP()
end)

-- ФУНКЦИИ СОЗДАНИЯ GUI
local function createTab(name, y)
    local tab = Instance.new("TextButton")
    tab.Size = UDim2.new(0, 80, 0, 30)
    tab.Position = UDim2.new(0, 10, 0, y)
    tab.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    tab.Text = name
    tab.TextColor3 = Color3.fromRGB(255, 255, 255)
    tab.TextScaled = true
    tab.BorderSizePixel = 0
    tab.Parent = mainFrame
    return tab
end

local function createSection(name, parent)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, -20, 0, 460)
    section.Position = UDim2.new(0, 10, 0, 80)
    section.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    section.BackgroundTransparency = 0.5
    section.BorderSizePixel = 0
    section.Visible = false
    section.Parent = parent or mainFrame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 30)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(200, 200, 255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = section
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, -35)
    scroll.Position = UDim2.new(0, 0, 0, 35)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 6
    scroll.Parent = section
    
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 5)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = scroll
    
    return {section = section, scroll = scroll, list = list}
end

local function createButton(text, callback, parent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.BorderSizePixel = 0
    btn.Parent = parent.scroll
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function createToggle(text, callback, parent)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 35)
    frame.BackgroundTransparency = 1
    frame.Parent = parent.scroll
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 40, 0, 25)
    toggle.Position = UDim2.new(0.85, 0, 0.5, -12.5)
    toggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    toggle.Text = ""
    toggle.BorderSizePixel = 0
    toggle.Parent = frame
    
    local state = false
    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.BackgroundColor3 = state and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(80, 80, 80)
        callback(state)
    end)
    return frame
end

-- СОЗДАНИЕ ВКЛАДОК
local tabs = {}
local sections = {}

local mainSection = createSection("Главная", mainFrame)
tabs["Главная"] = mainSection
mainSection.section.Visible = true

local aimSection = createSection("Aim", mainFrame)
tabs["Aim"] = aimSection

local tpSection = createSection("Телепорты", mainFrame)
tabs["Телепорты"] = tpSection

local farmSection = createSection("Фарм", mainFrame)
tabs["Фарм"] = farmSection

local miscSection = createSection("Разное", mainFrame)
tabs["Разное"] = miscSection

-- КНОПКИ ВКЛАДОК
local tabNames = {"Главная", "Aim", "Телепорты", "Фарм", "Разное"}
for i, name in ipairs(tabNames) do
    local btn = createTab(name, 45 + (i-1) * 35)
    btn.MouseButton1Click:Connect(function()
        for _, section in pairs(tabs) do
            section.section.Visible = false
        end
        tabs[name].section.Visible = true
    end)
end

-- ЗАПОЛНЕНИЕ ВКЛАДОК

-- ГЛАВНАЯ
createButton("Обновить ESP", function()
    updateESP()
end, mainSection)

createToggle("ESP Вкл", function(state)
    espEnabled = state
    if state then
        updateESP()
    else
        clearESP()
    end
end, mainSection)

createToggle("Ускорение x2", function(state)
    setSpeed(state)
end, mainSection)

createToggle("Супер прыжок", function(state)
    setJumpPower(state)
end, mainSection)

-- AIM
createToggle("Aimbot", function(state)
    aimbotEnabled = state
end, aimSection)

createToggle("Показать FOV", function(state)
    showFOV = state
    createFOV()
end, aimSection)

-- ТЕЛЕПОРТЫ
createButton("К убийце", function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and getPlayerRole(player) == "Murderer" then
            teleportToPlayer(player)
            break
        end
    end
end, tpSection)

createButton("К шерифу", function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and getPlayerRole(player) == "Sheriff" then
            teleportToPlayer(player)
            break
        end
    end
end, tpSection)

createButton("К оружию", function()
    local gun = getGun()
    if gun then
        gun.Parent = LocalPlayer.Character
    end
end, tpSection)

createButton("В безопасную зону", function()
    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 10, 0)
end, tpSection)

-- ФАРМ
createToggle("Аура ножа", function(state)
    knifeAuraEnabled = state
end, farmSection)

createButton("Бросить нож", function()
    local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
    if tool then tool:Activate() end
end, farmSection)

-- РАЗНОЕ
createToggle("Авто-выстрел", function(state)
    autoShootEnabled = state
end, miscSection)

createButton("Телепорт к игроку", function()
    local playerList = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playerList, player.Name)
        end
    end
    -- Просто телепорт к первому игроку
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            teleportToPlayer(player)
            break
        end
    end
end, miscSection)

-- ОСНОВНОЙ ЦИКЛ
RunService.Heartbeat:Connect(function()
    -- Aimbot
    if aimbotEnabled then
        local target = getClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local root = target.Character.HumanoidRootPart
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, root.Position)
        end
    end
    
    -- Обновление FOV
    if fovCircle then
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    end
    
    -- Аура ножа
    if knifeAuraEnabled and LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
                    if targetRoot and (root.Position - targetRoot.Position).Magnitude < 15 then
                        player.Character.Humanoid.Health = 0
                    end
                end
            end
        end
    end
    
    -- Обновление скорости
    if speedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if LocalPlayer.Character.Humanoid.WalkSpeed ~= 32 then
            LocalPlayer.Character.Humanoid.WalkSpeed = 32
        end
    end
    
    -- Обновление прыжка
    if jumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if LocalPlayer.Character.Humanoid.JumpPower ~= 100 then
            LocalPlayer.Character.Humanoid.JumpPower = 100
        end
    end
end)

-- ОБНОВЛЕНИЕ ESP ПРИ НОВЫХ ИГРОКАХ
Players.PlayerAdded:Connect(function()
    wait(1)
    if espEnabled then updateESP() end
end)

-- ОБНОВЛЕНИЕ ESP ПРИ СМЕНЕ РОЛИ
RunService.Heartbeat:Connect(function()
    if espEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local role = getPlayerRole(player)
                local color = ESP_TEAM_COLORS[role] or Color3.fromRGB(255, 255, 255)
                -- Обновляем цвета ESP
                for _, obj in pairs(espObjects) do
                    if obj:IsA("BoxHandleAdornment") and obj.Adornee == player.Character:FindFirstChild("HumanoidRootPart") then
                        obj.Color3 = color
                    end
                end
            end
        end
    end
end)

print("MM2 HUB UPDATE загружен!")
print("Цвета ESP: Убийца - Красный, Шериф - Синий, Мирный - Зеленый")
print("Ускорение x2 и супер прыжок включены!")
