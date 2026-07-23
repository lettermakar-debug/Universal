-- ========================================
--   🔪 MM2 ULTIMATE HUB (ThunderHub Style)
--   Автор: Universal Script
--   Версия: 3.0
-- ========================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local player = LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local mouse = player:GetMouse()

-- ===== ПЕРЕМЕННЫЕ =====
local espEnabled = false
local noclipEnabled = false
local farming = false
local farmThread = nil
local highJump = false
local espHighlights = {}
local guiMinimized = false
local flyEnabled = false
local flySpeed = 50
local flyBodyVelocity = nil
local flyBodyGyro = nil
local flyConnections = {}
local flingEnabled = false
local flingThread = nil
local flingPower = 5000
local autoShoot = false
local autoShootThread = nil

-- ===== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =====
local function getRole(plr)
    if plr:FindFirstChild("Murderer") and plr.Murderer.Value == true then
        return "Murderer"
    elseif plr:FindFirstChild("Sheriff") and plr.Sheriff.Value == true then
        return "Sheriff"
    else
        return "Innocent"
    end
end

local function teleportTo(target)
    if not target then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local targetPos
    if target:IsA("BasePart") then
        targetPos = target.Position
    elseif target:FindFirstChild("HumanoidRootPart") then
        targetPos = target.HumanoidRootPart.Position
    else
        return
    end
    hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
end

local function findWeapon()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():match("gun") or obj.Name:lower():match("knife") or obj.Name:lower():match("pistol")) then
            return obj
        end
        if obj:IsA("Tool") and (obj.Name:lower():match("gun") or obj.Name:lower():match("knife") or obj.Name:lower():match("pistol")) then
            return obj
        end
    end
    return nil
end

local function findCoins()
    local coins = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name == "Coin" or obj.Name == "Money" or obj.Name:lower():match("coin")) then
            table.insert(coins, obj)
        end
    end
    return coins
end

-- ===== ESP =====
local function updateESP()
    for _, hl in pairs(espHighlights) do
        if hl and hl.Parent then hl:Destroy() end
    end
    espHighlights = {}
    if not espEnabled then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            if char then
                local hl = Instance.new("Highlight")
                hl.Parent = char
                hl.FillTransparency = 0.3
                hl.OutlineTransparency = 0.3
                local role = getRole(plr)
                if role == "Murderer" then
                    hl.FillColor = Color3.fromRGB(255, 0, 0)
                    hl.OutlineColor = Color3.fromRGB(255, 50, 50)
                elseif role == "Sheriff" then
                    hl.FillColor = Color3.fromRGB(0, 100, 255)
                    hl.OutlineColor = Color3.fromRGB(50, 150, 255)
                else
                    hl.FillColor = Color3.fromRGB(0, 200, 0)
                    hl.OutlineColor = Color3.fromRGB(50, 255, 50)
                end
                table.insert(espHighlights, hl)
            end
        end
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        if espEnabled then wait(0.5) updateESP() end
    end)
end)

-- ===== ТЕЛЕПОРТЫ =====
local function teleportToWeapon() local w = findWeapon() if w then teleportTo(w) else print("Оружие не найдено") end end
local function teleportToRole(roleName)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local role = getRole(plr)
            if role == roleName and plr.Character then teleportTo(plr.Character) return end
        end
    end
    print(roleName .. " не найден")
end

-- ===== FLING (подбрасывание) =====
local function flingPlayer(target)
    if not target or not target.Character then return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local direction = (hrp.Position - character.HumanoidRootPart.Position).Unit
    hrp.AssemblyLinearVelocity = direction * flingPower + Vector3.new(0, flingPower * 0.5, 0)
    hrp.AssemblyAngularVelocity = Vector3.new(math.random(-100, 100), math.random(-100, 100), math.random(-100, 100))
end

local function toggleFling(state)
    flingEnabled = state
    if state then
        if flingThread then coroutine.close(flingThread) end
        flingThread = coroutine.create(function()
            while flingEnabled do
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        flingPlayer(plr)
                    end
                end
                wait(0.5)
            end
        end)
        coroutine.resume(flingThread)
    else
        if flingThread then coroutine.close(flingThread) end
        flingThread = nil
    end
end

-- ===== УМНАЯ АТАКА (с кнопками) =====
-- Если вы шериф – стреляет в убийцу
-- Если вы убийца – кидает нож во всех (мгновенное убийство)
-- Если невинный – телепорт к убийце

local function smartAttack()
    local myRole = getRole(LocalPlayer)
    if myRole == "Murderer" then
        -- Убить всех мгновенно
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.Health = 0 end
            end
        end
        print("🔪 Все убиты (вы убийца)")
    elseif myRole == "Sheriff" then
        -- Найти убийцу и убить
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and getRole(plr) == "Murderer" and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hum then 
                    hum.Health = 0
                    print("🔫 Убийца уничтожен")
                    return
                end
            end
        end
        print("❌ Убийца не найден")
    else
        -- Невинный – телепорт к убийце
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and getRole(plr) == "Murderer" and plr.Character then
                teleportTo(plr.Character)
                print("🚀 Телепорт к убийце")
                return
            end
        end
        print("❌ Убийца не найден")
    end
end

-- ===== АВТО-СТРЕЛЬБА (для шерифа) =====
local function toggleAutoShoot(state)
    autoShoot = state
    if state then
        if autoShootThread then coroutine.close(autoShootThread) end
        autoShootThread = coroutine.create(function()
            while autoShoot do
                if getRole(LocalPlayer) == "Sheriff" then
                    for _, plr in pairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer and getRole(plr) == "Murderer" and plr.Character then
                            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                            if hum then hum.Health = 0 end
                            print("🔫 Авто-выстрел: убийца уничтожен")
                        end
                    end
                end
                wait(0.5)
            end
        end)
        coroutine.resume(autoShootThread)
    else
        if autoShootThread then coroutine.close(autoShootThread) end
        autoShootThread = nil
    end
end

-- ===== УБИТЬ ВСЕХ СРАЗУ =====
local function killAllInstant()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end
    end
    print("💀 Все убиты мгновенно!")
end

-- ===== ВЫСОКИЙ ПРЫЖОК =====
local function setHighJump(state)
    highJump = state
    local hum = character:FindFirstChildOfClass("Humanoid")
    if hum then hum.JumpPower = state and 150 or 50 end
end

-- ===== НОКЛИП =====
local function setNoclip(state)
    noclipEnabled = state
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = not state end
    end
    if state then
        local function noclipPart(part)
            if part:IsA("BasePart") then part.CanCollide = false end
        end
        character.DescendantAdded:Connect(noclipPart)
        if not getgenv()._noclipConn then
            getgenv()._noclipConn = character.DescendantAdded:Connect(noclipPart)
        end
    else
        if getgenv()._noclipConn then
            getgenv()._noclipConn:Disconnect()
            getgenv()._noclipConn = nil
        end
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end

-- ===== ПОЛЁТ =====
local function toggleFly(state)
    flyEnabled = state
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
    for _, conn in pairs(flyConnections) do conn:Disconnect() end
    flyConnections = {}

    if state then
        hum.PlatformStand = true
        setNoclip(true)

        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        flyBodyVelocity.Parent = hrp

        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        flyBodyGyro.CFrame = hrp.CFrame
        flyBodyGyro.Parent = hrp

        local function updateFly()
            if not flyEnabled then return end
            local moveDirection = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + hrp.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - hrp.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - hrp.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + hrp.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end

            if moveDirection.Magnitude > 0 then
                moveDirection = moveDirection.Unit * flySpeed
            end
            if flyBodyVelocity then
                flyBodyVelocity.Velocity = moveDirection
            end
            if moveDirection.Magnitude > 0 and flyBodyGyro then
                flyBodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + moveDirection.Unit)
            end
        end

        local conn = RunService.Heartbeat:Connect(updateFly)
        table.insert(flyConnections, conn)

    else
        hum.PlatformStand = false
        setNoclip(false)
        if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
        if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
        for _, conn in pairs(flyConnections) do conn:Disconnect() end
        flyConnections = {}
    end
end

-- ===== АВТОФАРМ =====
local function autoFarmLoop()
    while farming do
        local coins = findCoins()
        if #coins > 0 then
            teleportTo(coins[1])
            wait(0.2)
        else
            wait(0.5)
        end
        wait(0.1)
    end
end

-- ======================================================================
-- ========== ИНТЕРФЕЙС В СТИЛЕ THUNDERHUB ==========
-- ======================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MM2UltimateHub"
screenGui.Parent = LocalPlayer.PlayerGui

-- ===== ОСНОВНОЕ ОКНО =====
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 420, 0, 620)
mainFrame.Position = UDim2.new(0.5, -210, 0.5, -310)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Тень
local shadow = Instance.new("Frame")
shadow.Size = UDim2.new(1, 10, 1, 10)
shadow.Position = UDim2.new(0, -5, 0, -5)
shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency = 0.5
shadow.BorderSizePixel = 0
shadow.Parent = mainFrame

-- ===== ЗАГОЛОВОК =====
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 60)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 30, 50))
})
titleGradient.Parent = titleBar

local titleIcon = Instance.new("TextLabel")
titleIcon.Size = UDim2.new(0, 40, 1, 0)
titleIcon.BackgroundTransparency = 1
titleIcon.Text = "🔪"
titleIcon.TextColor3 = Color3.new(1, 1, 1)
titleIcon.TextScaled = true
titleIcon.Font = Enum.Font.GothamBold
titleIcon.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -80, 1, 0)
titleText.Position = UDim2.new(0, 40, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "MM2 ULTIMATE HUB"
titleText.TextColor3 = Color3.new(1, 1, 1)
titleText.TextScaled = true
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- Кнопка минимизации (иконка в трее)
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -70, 0.5, -15)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
minimizeBtn.Text = "−"
minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
minimizeBtn.TextScaled = true
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = titleBar
minimizeBtn.MouseButton1Click:Connect(function()
    guiMinimized = true
    mainFrame.Visible = false
    trayIcon.Visible = true
end)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0.5, -15)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextScaled = true
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- ===== ИКОНКА В ТРЕЕ (для восстановления) =====
local trayIcon = Instance.new("TextButton")
trayIcon.Size = UDim2.new(0, 55, 0, 55)
trayIcon.Position = UDim2.new(0, 10, 0, 10)
trayIcon.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
trayIcon.BackgroundTransparency = 0.1
trayIcon.Text = "🔪"
trayIcon.TextColor3 = Color3.new(1, 1, 1)
trayIcon.TextScaled = true
trayIcon.BorderSizePixel = 0
trayIcon.Visible = false
trayIcon.Parent = screenGui

-- Обводка иконки
local trayGlow = Instance.new("Frame")
trayGlow.Size = UDim2.new(1, 10, 1, 10)
trayGlow.Position = UDim2.new(0, -5, 0, -5)
trayGlow.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
trayGlow.BackgroundTransparency = 0.5
trayGlow.BorderSizePixel = 0
trayGlow.Parent = trayIcon

trayIcon.MouseButton1Click:Connect(function()
    guiMinimized = false
    mainFrame.Visible = true
    trayIcon.Visible = false
end)

-- ===== ВКЛАДКИ =====
local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(1, 0, 0, 45)
tabFrame.Position = UDim2.new(0, 0, 0, 50)
tabFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
tabFrame.BorderSizePixel = 0
tabFrame.Parent = mainFrame

local tabs = {"Главная", "ESP", "Телепорты", "Фарм", "Бой", "Полет", "Флинг"}
local tabButtons = {}
local currentTab = "Главная"

-- ===== КОНТЕНТ =====
local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Size = UDim2.new(1, -10, 1, -105)
contentFrame.Position = UDim2.new(0, 5, 0, 100)
contentFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
contentFrame.BackgroundTransparency = 0.3
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 4
contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 150)
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
contentFrame.Parent = mainFrame

local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 6)
contentLayout.Parent = contentFrame

-- ===== ФУНКЦИИ СОЗДАНИЯ ЭЛЕМЕНТОВ =====

-- Стильная кнопка
local function createButton(text, callback, color, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 40)
    btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 75)
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamSemibold
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order or 0
    btn.Parent = contentFrame

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, (color or Color3.fromRGB(50, 50, 75))),
        ColorSequenceKeypoint.new(1, (color or Color3.fromRGB(40, 40, 60)))
    })
    gradient.Parent = btn

    btn.MouseButton1Click:Connect(callback)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
    end)
    return btn
end

-- Стильный переключатель
local function createToggle(text, initialState, callback, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 40)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order or 0
    frame.Parent = contentFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextScaled = true
    label.Font = Enum.Font.Gotham
    label.Parent = frame

    local toggleBtn = Instance.new("Frame")
    toggleBtn.Size = UDim2.new(0, 55, 0, 28)
    toggleBtn.Position = UDim2.new(1, -60, 0.5, -14)
    toggleBtn.BackgroundColor3 = initialState and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(150, 50, 50)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = frame

    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 22, 0, 22)
    toggleCircle.Position = initialState and UDim2.new(1, -26, 0.5, -11) or UDim2.new(0, 4, 0.5, -11)
    toggleCircle.BackgroundColor3 = Color3.new(1, 1, 1)
    toggleCircle.BorderSizePixel = 0
    toggleCircle.Parent = toggleBtn

    local state = initialState
    toggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            toggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(150, 50, 50)
            TweenService:Create(toggleCircle, TweenInfo.new(0.2), {
                Position = state and UDim2.new(1, -26, 0.5, -11) or UDim2.new(0, 4, 0.5, -11)
            }):Play()
            callback(state)
        end
    end)
    return frame
end

-- Ползунок
local function createSlider(text, minVal, maxVal, defaultVal, callback, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 55)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order or 0
    frame.Parent = contentFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(defaultVal)
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.Gotham
    label.Parent = frame

    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, 0, 0, 22)
    sliderFrame.Position = UDim2.new(0, 0, 0, 24)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = frame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 200, 150)
    fill.BorderSizePixel = 0
    fill.Parent = sliderFrame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 20, 1, -4)
    button.Position = UDim2.new((defaultVal - minVal) / (maxVal - minVal), -10, 0, 2)
    button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = ""
    button.BorderSizePixel = 1
    button.Parent = sliderFrame

    local dragging = false
    button.MouseButton1Down:Connect(function() dragging = true end)
    button.MouseButton1Up:Connect(function() dragging = false end)
    button.MouseLeave:Connect(function() dragging = false end)

    local function updateSlider(x)
        local relX = math.clamp((x - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
        local val = minVal + relX * (maxVal - minVal)
        val = math.round(val / 1) * 1
        fill.Size = UDim2.new(relX, 0, 1, 0)
        button.Position = UDim2.new(relX, -10, 0, 2)
        label.Text = text .. ": " .. tostring(val)
        callback(val)
    end

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
            updateSlider(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            updateSlider(input.Position.X)
        end
    end)
    return frame
end

-- ===== ПОСТРОЕНИЕ КОНТЕНТА ВКЛАДОК =====
local function clearContent()
    for _, child in pairs(contentFrame:GetChildren()) do
        if child ~= contentLayout then child:Destroy() end
    end
end

local function switchTab(tabName)
    currentTab = tabName
    clearContent()

    if tabName == "Главная" then
        createToggle("Noclip (проход сквозь стены)", false, setNoclip, 1)
        createButton("⚡ Ускорение (Speed x2)", function()
            local hum = character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = hum.WalkSpeed * 2 end
        end, Color3.fromRGB(70, 70, 120), 2)
        createButton("🔄 Обновить ESP", function() if espEnabled then updateESP() end end, Color3.fromRGB(60, 120, 60), 3)
        createButton("💀 Убить всех мгновенно", killAllInstant, Color3.fromRGB(200, 40, 40), 4)

    elseif tabName == "ESP" then
        createToggle("🔍 Включить ESP", false, function(state) espEnabled = state; updateESP() end, 1)
        createButton("🔄 Обновить подсветку", function() if espEnabled then updateESP() end end, Color3.fromRGB(50, 80, 150), 2)

    elseif tabName == "Телепорты" then
        createButton("🔫 Телепорт к оружию", teleportToWeapon, Color3.fromRGB(200, 150, 50), 1)
        createButton("👮 Телепорт к шерифу", function() teleportToRole("Sheriff") end, Color3.fromRGB(50, 100, 255), 2)
        createButton("🔪 Телепорт к убийце", function() teleportToRole("Murderer") end, Color3.fromRGB(255, 50, 50), 3)

    elseif tabName == "Фарм" then
        createToggle("💰 Авто-фарм монет", false, function(state)
            farming = state
            if farming then
                if farmThread then coroutine.close(farmThread) end
                farmThread = coroutine.create(autoFarmLoop)
                coroutine.resume(farmThread)
            else
                if farmThread then coroutine.close(farmThread) end
                farmThread = nil
            end
        end, 1)
        createButton("🪙 К ближайшей монете", function()
            local coins = findCoins()
            if #coins > 0 then
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local nearest, minDist = nil, math.huge
                    for _, coin in pairs(coins) do
                        local dist = (coin.Position - hrp.Position).Magnitude
                        if dist < minDist then minDist = dist; nearest = coin end
                    end
                    if nearest then teleportTo(nearest) end
                end
            end
        end, Color3.fromRGB(200, 180, 50), 2)

    elseif tabName == "Бой" then
        createButton("⚔️ УМНАЯ АТАКА", smartAttack, Color3.fromRGB(200, 50, 50), 1)
        createButton("🔫 Шериф → Убить убийцу", function()
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and getRole(plr) == "Murderer" and plr.Character then
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.Health = 0 end
                    print("🔫 Убийца уничтожен")
                    return
                end
            end
            print("❌ Убийца не найден")
        end, Color3.fromRGB(50, 150, 255), 2)
        createButton("🔪 Убийца → Убить всех", function()
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.Health = 0 end
                end
            end
            print("🔪 Все убиты!")
        end, Color3.fromRGB(255, 50, 50), 3)
        createToggle("🎯 Авто-стрельба (шериф)", false, toggleAutoShoot, 4)
        createToggle("🦘 Высокий прыжок (x3)", false, setHighJump, 5)

    elseif tabName == "Полет" then
        createToggle("✈️ Режим полёта", false, toggleFly, 1)
        createSlider("🚀 Скорость полёта", 10, 200, flySpeed, function(val) flySpeed = val end, 2)

    elseif tabName == "Флинг" then
        createToggle("🌀 Флинг (подбрасывание всех)", false, toggleFling, 1)
        createSlider("💥 Сила флинга", 1000, 15000, flingPower, function(val) flingPower = val end, 2)
