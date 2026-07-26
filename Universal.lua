-- MM2 HUB UPDATE - ПОЛНАЯ РУССКАЯ ВЕРСИЯ
-- Discord: discord.gg/v8ZPq4y2nD

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- ПЕРЕМЕННЫЕ
local espEnabled = false
local espObjects = {}
local aimbotEnabled = false
local silentAimEnabled = false
local fovSize = 200
local showFOV = false
local fovCircle = nil
local speedEnabled = false
local jumpEnabled = false
local autoShootEnabled = false
local knifeAuraEnabled = false
local isMinimized = false
local autoFarmEnabled = false
local antiFlingEnabled = false
local godModeEnabled = false
local farmLoop = nil
local godModeLoop = nil
local antiFlingLoop = nil
local playerMenuOpen = false
local dragObject = nil
local dragInput = nil
local dragStart = nil
local startPos = nil

-- ЦВЕТА ESP
local ESP_TEAM_COLORS = {
    Murderer = Color3.fromRGB(255, 0, 0),
    Sheriff = Color3.fromRGB(0, 100, 255),
    Innocent = Color3.fromRGB(0, 255, 0)
}

-- ФУНКЦИЯ ПОЛУЧЕНИЯ РОЛИ
local function getPlayerRole(player)
    if not player or not player.Character then return "Мирный" end
    for _, item in pairs(player.Character:GetChildren()) do
        if item:IsA("Tool") then
            if item.Name == "Knife" then return "Убийца" end
            if item.Name == "Gun" then return "Шериф" end
        end
    end
    return "Мирный"
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
    
    local box = Instance.new("BoxHandleAdornment")
    box.Size = Vector3.new(3, 5, 1)
    box.Adornee = root
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Color3 = color
    box.Transparency = 0.5
    box.Parent = root
    table.insert(espObjects, box)
    
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

-- ПОЛУЧЕНИЕ БЛИЖАЙШЕГО ИГРОКА
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

-- ПОЛУЧЕНИЕ МОНЕТ
local function getAllCoins()
    local coins = {}
    for _, item in pairs(Workspace:GetDescendants()) do
        if item:IsA("Part") and item.Name == "Coin" and item.Parent then
            table.insert(coins, item)
        end
    end
    return coins
end

-- ТЕЛЕПОРТЫ
local function teleportToPlayer(player)
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
        end
    end
end

local function teleportToPosition(position)
    local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
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

-- СКОРОСТЬ
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

-- РЕЖИМ БОГА
local function toggleGodMode(state)
    godModeEnabled = state
    
    if godModeLoop then
        godModeLoop:Disconnect()
        godModeLoop = nil
    end
    
    if state then
        godModeLoop = RunService.Heartbeat:Connect(function()
            if godModeEnabled and LocalPlayer.Character then
                local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.Health = humanoid.MaxHealth
                    humanoid.BreakJointsOnDeath = false
                end
            end
        end)
    end
end

-- АНТИ-ФЛИНГ
local function toggleAntiFling(state)
    antiFlingEnabled = state
    
    if antiFlingLoop then
        antiFlingLoop:Disconnect()
        antiFlingLoop = nil
    end
    
    if state then
        antiFlingLoop = RunService.Heartbeat:Connect(function()
            if antiFlingEnabled and LocalPlayer.Character then
                local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root and root.Velocity and root.Velocity.Magnitude > 200 then
                    root.Velocity = Vector3.new(0, 0, 0)
                end
            end
        end)
    end
end

-- АВТОФАРМ
local function toggleAutoFarm(state)
    autoFarmEnabled = state
    
    if farmLoop then
        farmLoop:Disconnect()
        farmLoop = nil
    end
    
    if state then
        farmLoop = RunService.Heartbeat:Connect(function()
            if autoFarmEnabled and LocalPlayer.Character then
                local coins = getAllCoins()
                if #coins > 0 then
                    for _, coin in pairs(coins) do
                        if coin and coin.Parent then
                            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if root then
                                root.CFrame = CFrame.new(coin.Position + Vector3.new(0, 3, 0))
                                wait(0.05)
                            end
                        end
                    end
                end
            end
        end)
    end
end

-- ФЛИНГ
local function flingPlayer(player)
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local root = player.Character.HumanoidRootPart
        root.Velocity = Vector3.new(0, 1000, 0)
        wait(0.1)
        root.Velocity = Vector3.new(1000, 500, 1000)
        wait(0.1)
        root.Velocity = Vector3.new(-1000, 500, -1000)
        wait(0.1)
        root.Velocity = Vector3.new(0, 2000, 0)
    end
end

-- МЕНЮ ИГРОКОВ
local function createPlayerMenu()
    if playerMenuOpen then return end
    playerMenuOpen = true
    
    local menuFrame = Instance.new("Frame")
    menuFrame.Size = UDim2.new(0, 380, 0, 480)
    menuFrame.Position = UDim2.new(0.5, -190, 0.5, -240)
    menuFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    menuFrame.BackgroundTransparency = 0.1
    menuFrame.BorderSizePixel = 0
    menuFrame.Parent = screenGui
    
    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 12)
    menuCorner.Parent = menuFrame
    
    -- Заголовок
    local menuTitle = Instance.new("Frame")
    menuTitle.Size = UDim2.new(1, 0, 0, 45)
    menuTitle.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
    menuTitle.BorderSizePixel = 0
    menuTitle.Parent = menuFrame
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(0.8, 0, 1, 0)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "👥 Список игроков"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextScaled = true
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = menuTitle
    
    -- Кнопка закрытия
    local closeMenuBtn = Instance.new("TextButton")
    closeMenuBtn.Size = UDim2.new(0, 35, 0, 35)
    closeMenuBtn.Position = UDim2.new(1, -40, 0, 5)
    closeMenuBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    closeMenuBtn.Text = "✕"
    closeMenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeMenuBtn.TextScaled = true
    closeMenuBtn.Font = Enum.Font.GothamBold
    closeMenuBtn.BorderSizePixel = 0
    closeMenuBtn.Parent = menuTitle
    closeMenuBtn.MouseButton1Click:Connect(function()
        menuFrame:Destroy()
        playerMenuOpen = false
    end)
    
    -- Поиск
    local searchBar = Instance.new("TextBox")
    searchBar.Size = UDim2.new(1, -20, 0, 35)
    searchBar.Position = UDim2.new(0, 10, 0, 50)
    searchBar.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    searchBar.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBar.PlaceholderText = "🔍 Поиск игроков..."
    searchBar.PlaceholderColor3 = Color3.fromRGB(150, 150, 170)
    searchBar.Text = ""
    searchBar.Font = Enum.Font.Gotham
    searchBar.TextScaled = true
    searchBar.BorderSizePixel = 0
    searchBar.Parent = menuFrame
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -10, 1, -100)
    scrollFrame.Position = UDim2.new(0, 5, 0, 90)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.Parent = menuFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scrollFrame
    
    -- Обновление списка
    local function updatePlayerList(filter)
        for _, child in pairs(scrollFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local name = player.Name:lower()
                local filterLower = filter:lower()
                
                if filter == "" or string.find(name, filterLower) then
                    local role = getPlayerRole(player)
                    local color = ESP_TEAM_COLORS[role] or Color3.fromRGB(255, 255, 255)
                    
                    local playerBtn = Instance.new("TextButton")
                    playerBtn.Size = UDim2.new(1, 0, 0, 40)
                    playerBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 75)
                    playerBtn.Text = player.Name .. "  [" .. role .. "]"
                    playerBtn.TextColor3 = color
                    playerBtn.TextScaled = true
                    playerBtn.Font = Enum.Font.Gotham
                    playerBtn.BorderSizePixel = 0
                    playerBtn.Parent = scrollFrame
                    
                    playerBtn.MouseEnter:Connect(function()
                        playerBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 95)
                    end)
                    playerBtn.MouseLeave:Connect(function()
                        playerBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 75)
                    end)
                    
                    -- Левый клик - телепорт
                    playerBtn.MouseButton1Click:Connect(function()
                        teleportToPlayer(player)
                        menuFrame:Destroy()
                        playerMenuOpen = false
                    end)
                    
                    -- Правый клик - флинг
                    playerBtn.MouseButton2Click:Connect(function()
                        flingPlayer(player)
                        menuFrame:Destroy()
                        playerMenuOpen = false
                    end)
                end
            end
        end
    end
    
    updatePlayerList("")
    
    searchBar.Changed:Connect(function()
        updatePlayerList(searchBar.Text)
    end)
end

-- СОЗДАНИЕ ГЛАВНОГО GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MM2HUBUPDATE"
screenGui.Parent = game.CoreGui
screenGui.ResetOnSpawn = false

-- ГЛАВНОЕ ОКНО
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 650)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -325)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
mainFrame.Active = true
mainFrame.Draggable = true

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- ВЕРХНЯЯ ПАНЕЛЬ
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 45)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

-- ЗАГОЛОВОК
local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.6, 0, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🔪 MM2 HUB UPDATE"
title.TextColor3 = Color3.fromRGB(255, 200, 50)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.BorderSizePixel = 0
title.Parent = titleBar

-- КНОПКА СВЕРНУТЬ
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 38, 0, 35)
minimizeBtn.Position = UDim2.new(1, -78, 0, 5)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 185, 0)
minimizeBtn.Text = "━"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.TextScaled = true
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = titleBar

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 6)
minimizeCorner.Parent = minimizeBtn

minimizeBtn.MouseEnter:Connect(function()
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 210, 50)
end)
minimizeBtn.MouseLeave:Connect(function()
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 185, 0)
end)

-- КНОПКА ЗАКРЫТЬ
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 38, 0, 35)
closeBtn.Position = UDim2.new(1, -40, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
end)
closeBtn.MouseLeave:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
end)

-- КОНТЕЙНЕР КОНТЕНТА
local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, 0, 1, -45)
contentContainer.Position = UDim2.new(0, 0, 0, 45)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainFrame

-- ФУНКЦИЯ СВЕРТЫВАНИЯ
local function toggleMinimize()
    isMinimized = not isMinimized
    
    if isMinimized then
        mainFrame:TweenSize(UDim2.new(0, 500, 0, 45), "Out", "Quad", 0.3, true)
        contentContainer.Visible = false
        minimizeBtn.Text = "□"
        minimizeBtn.BackgroundColor3 = Color3.fromRGB(0, 220, 0)
    else
        mainFrame:TweenSize(UDim2.new(0, 500, 0, 650), "Out", "Quad", 0.3, true)
        wait(0.35)
        contentContainer.Visible = true
        minimizeBtn.Text = "━"
        minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 185, 0)
    end
end

minimizeBtn.MouseButton1Click:Connect(toggleMinimize)

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    clearESP()
    if godModeLoop then godModeLoop:Disconnect() end
    if farmLoop then farmLoop:Disconnect() end
    if antiFlingLoop then antiFlingLoop:Disconnect() end
end)

-- СОЗДАНИЕ ВКЛАДОК
local function createTab(name, y)
    local tab = Instance.new("TextButton")
    tab.Size = UDim2.new(0, 95, 0, 32)
    tab.Position = UDim2.new(0, 8, 0, y)
    tab.BackgroundColor3 = Color3.fromRGB(50, 50, 75)
    tab.Text = name
    tab.TextColor3 = Color3.fromRGB(255, 255, 255)
    tab.TextScaled = true
    tab.Font = Enum.Font.Gotham
    tab.BorderSizePixel = 0
    tab.Parent = contentContainer
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 6)
    tabCorner.Parent = tab
    
    tab.MouseEnter:Connect(function()
        tab.BackgroundColor3 = Color3.fromRGB(70, 70, 95)
    end)
    tab.MouseLeave:Connect(function()
        tab.BackgroundColor3 = Color3.fromRGB(50, 50, 75)
    end)
    
    return tab
end

-- СОЗДАНИЕ СЕКЦИЙ
local function createSection(name, parent)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, -20, 0, 550)
    section.Position = UDim2.new(0, 10, 0, 80)
    section.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    section.BackgroundTransparency = 0.5
    section.BorderSizePixel = 0
    section.Visible = false
    section.Parent = parent or contentContainer
    
    local sectionCorner = Instance.new("UICorner")
    sectionCorner.CornerRadius = UDim.new(0, 8)
    sectionCorner.Parent = section
    
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

-- СОЗДАНИЕ КНОПКИ
local function createButton(text, callback, parent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 75)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    btn.Parent = parent.scroll
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(70, 70, 95)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 75)
    end)
    
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- СОЗДАНИЕ ПЕРЕКЛЮЧАТЕЛЯ
local function createToggle(text, callback, parent)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 38)
    frame.BackgroundTransparency = 1
    frame.Parent = parent.scroll
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 45, 0, 28)
    toggle.Position = UDim2.new(0.85, 0, 0.5, -14)
    toggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    toggle.Text = "ВЫКЛ"
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.TextScaled = true
    toggle.Font = Enum.Font.GothamBold
    toggle.BorderSizePixel = 0
    toggle.Parent = frame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 6)
    toggleCorner.Parent = toggle
    
    local state = false
    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.BackgroundColor3 = state and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(80, 80, 80)
        toggle.Text = state and "ВКЛ" or "ВЫКЛ"
        callback(state)
    end)
    return frame
end

-- СОЗДАНИЕ ПОЛЗУНКА
local function createSlider(text, min, max, default, callback, parent)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 50)
    frame.BackgroundTransparency = 1
    frame.Parent = parent.scroll
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 22)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(default)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local slider = Instance.new("TextButton")
    slider.Size = UDim2.new(1, 0, 0, 22)
    slider.Position = UDim2.new(0, 0, 0, 26)
    slider.BackgroundColor3 = Color3.fromRGB(50, 50, 75)
    slider.Text = ""
    slider.BorderSizePixel = 0
    slider.Parent = frame
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 6)
    sliderCorner.Parent = slider
    
    local value = default
    slider.MouseButton1Down:Connect(function()
        local connection
        connection = RunService.Heartbeat:Connect(function()
            local mousePos = UserInputService:GetMouseLocation()
            local sliderPos = slider.AbsolutePosition
            local sliderSize = slider.AbsoluteSize
            local percent = math.clamp((mousePos.X - sliderPos.X) / sliderSize.X, 0, 1)
            value = math.round(min + (max - min) * percent)
            label.Text = text .. ": " .. tostring(value)
            callback(value)
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                connection:Disconnect()
            end
        end)
    end)
    return frame
end

-- СОЗДАНИЕ ВКЛАДОК И СЕКЦИЙ
local tabs = {}

local mainSection = createSection("⭐ Главная", contentContainer)
tabs["Главная"] = mainSection
mainSection.section.Visible = true

local aimSection = createSection("🎯 Прицел", contentContainer)
tabs["Прицел"] = aimSection

local teleportSection = createSection("🚀 Телепорты", contentContainer)
tabs["Телепорты"] = teleportSection

local farmSection = createSection("💰 Фарм", contentContainer)
tabs["Фарм"] = farmSection

local miscSection = createSection("🔧 Разное", contentContainer)
tabs["Разное"] = miscSection

-- КНОПКИ ВКЛАДОК
local tabNames = {"Главная", "Прицел", "Телепорты", "Фарм", "Разное"}
for i, name in ipairs(tabNames) do
    local btn = createTab(name, 45 + (i-1) * 35)
    btn.MouseButton1Click:Connect(function()
        for _, section in pairs(tabs) do
            section.section.Visible = false
        end
        tabs[name].section.Visible = true
    end)
end

-- ⭐ ГЛАВНАЯ
createButton("🔄 Обновить ESP", function()
    updateESP()
end, mainSection)

createToggle("👁️ ESP Включен", function(state)
    espEnabled = state
    if state then
        updateESP()
    else
        clearESP()
    end
end, mainSection)

createToggle("⚡ Ускорение x2", function(state)
    setSpeed(state)
end, mainSection)

createToggle("⬆️ Супер прыжок", function(state)
    setJumpPower(state)
end, mainSection)

createToggle("🛡️ Анти-флинг", function(state)
    toggleAntiFling(state)
end, mainSection)

createToggle("👑 Режим бога", function(state)
    toggleGodMode(state)
end, mainSection)

-- 🎯 ПРИЦЕЛ
createToggle("🎯 Аимбот", function(state)
    aimbotEnabled = state
end, aimSection)

createToggle("🔇 Silent Aim", function(state)
    silentAimEnabled = state
end, aimSection)

createToggle("🔫 Авто-выстрел", function(state)
    autoShootEnabled = state
end, aimSection)

createToggle("⭕ Показать FOV", function(state)
    showFOV = state
    createFOV()
end, aimSection)

createSlider("📐 Размер FOV", 50, 500, 200, function(value)
    fovSize = value
    if fovCircle then
        fovCircle.Radius = value
    end
end, aimSection)

-- 🚀 ТЕЛЕПОРТЫ
createButton("🔪 К убийце", function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and getPlayerRole(player) == "Убийца" then
            teleportToPlayer(player)
            break
        end
    end
end, teleportSection)

createButton("⭐ К шерифу", function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and getPlayerRole(player) == "Шериф" then
            teleportToPlayer(player)
            break
        end
    end
end, teleportSection)

createButton("🔫 К оружию", function()
    local gun = getGun()
    if gun then
        gun.Parent = LocalPlayer.Character
    end
end, teleportSection)

createButton("🪙 К монетке", function()
    local coins = getAllCoins()
    if #coins > 0 then
        teleportToPosition(coins[1].Position)
    end
end, teleportSection)

createButton("🏠 В безопасную зону", function()
    teleportToPosition(Vector3.new(0, 10, 0))
end, teleportSection)

createButton("🏛️ В лобби", function()
    teleportToPosition(Vector3.new(0, 0, 0))
end, teleportSection)

-- 💰 ФАРМ
createToggle("🤖 Автофарм монет", function(state)
    toggleAutoFarm(state)
end, farmSection)

createToggle("🗡️ Аура ножа", function(state)
    knifeAuraEnabled = state
end, farmSection)

createButton("💥 Бросить нож", function()
    local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
    if tool then tool:Activate() end
end, farmSection)

-- 🔧 РАЗНОЕ
createButton("👥 Открыть меню игроков", function()
    createPlayerMenu()
end, miscSection)

createButton("💫 Флинг убийцу", function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and getPlayerRole(player) == "Убийца" then
            flingPlayer(player)
            break
        end
    end
end, miscSection)

createButton("💫 Флинг шерифа", function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and getPlayerRole(player) == "Шериф" then
            flingPlayer(player)
            break
        end
    end
end, miscSection)

createButton("💫 Флинг всех", function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            flingPlayer(player)
            wait(0.2)
        end
    end
end, miscSection)

-- ОСНОВНОЙ ЦИКЛ
RunService.Heartbeat:Connect(function()
    -- Аимбот
    if aimbotEnabled then
        local target = getClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local root = target.Character.HumanoidRootPart
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, root.Position)
        end
    end
    
    -- Silent Aim
    if silentAimEnabled then
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
    
    -- Авто-выстрел
    if autoShootEnabled then
        local target = getClosestPlayer()
        if target and target.Character then
            target.Character.Humanoid.Health = 0
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
                for _, obj in pairs(espObjects) do
                    if obj:IsA("BoxHandleAdornment") and obj.Adornee == player.Character:FindFirstChild("HumanoidRootPart") then
                        obj.Color3 = color
                    end
                end
            end
        end
    end
end)

-- ГОРЯЧАЯ КЛАВИША ДЛЯ СВЕРТЫВАНИЯ (Ctrl+M)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.M and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        toggleMinimize()
    end
end)

print("🔪 MM2 HUB UPDATE загружен!")
print("✅ ESP: Убийца - Красный, Шериф - Синий, Мирный - Зеленый")
print("✅ Ускорение x2 и Супер прыжок")
print("✅ Аимбот и Silent Aim")
print("✅ Автофарм монет")
print("✅ Анти-флинг и Режим бога")
print("✅ Меню игроков (ЛКМ - телепорт, ПКМ - флинг)")
print("Нажми '━' или Ctrl+M чтобы свернуть")
