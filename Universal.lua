--[[
    УНИВЕРСАЛЬНЫЙ ХАБ ДЛЯ ROBLOX (ИСПРАВЛЕННАЯ ВЕРСИЯ)
    Функции: FLING, ESP, FLIGHT, GODMODE, NO CLIP, SPEED, TELEPORT
    Система ключей с GUI, сворачивание меню, Tab для открытия/закрытия
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ==============================
-- НАСТРОЙКИ КЛЮЧЕЙ (ХАРДКОД)
-- ==============================
local ADMIN_KEY = "AdminPass123"      -- Замените на свой админ-ключ
local SCRIPT_KEY = "ScriptKey456"    -- Замените на свой скриптер-ключ

-- ==============================
-- ПЕРЕМЕННЫЕ СОСТОЯНИЯ
-- ==============================
local isAdmin = false
local isScriptKey = false
local guiOpen = false
local guiMinimized = false
local espEnabled = false
local flightEnabled = false
local flingCooldown = false
local godModeEnabled = false
local noClipEnabled = false
local speedMultiplier = 1
local selectedPlayer = nil

local espObjects = {}
local espConnections = {}
local flightBodyVelocity = nil
local flightGyro = nil
local noclipConnection = nil

-- ==============================
-- СОЗДАНИЕ GUI
-- ==============================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UniversalHub"
screenGui.Parent = player.PlayerGui

-- Основное окно
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 420, 0, 540)
mainFrame.Position = UDim2.new(0.5, -210, 0.5, -270)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

-- Заголовок с кнопками свернуть/закрыть
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.Position = UDim2.new(0.05, 0, 0, 0)
titleLabel.Text = "УНИВЕРСАЛЬНЫЙ ХАБ"
titleLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.BackgroundTransparency = 1
titleLabel.Parent = titleBar

-- Кнопка свернуть
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -70, 0, 5)
minimizeBtn.Text = "—"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 200)
minimizeBtn.TextScaled = true
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 40)
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = titleBar
minimizeBtn.MouseButton1Click:Connect(function()
    guiMinimized = not guiMinimized
    if guiMinimized then
        mainFrame.Size = UDim2.new(0, 420, 0, 40)
        scrollFrame.Visible = false
        minimizeBtn.Text = "□"
    else
        mainFrame.Size = UDim2.new(0, 420, 0, 540)
        scrollFrame.Visible = true
        minimizeBtn.Text = "—"
    end
end)

-- Кнопка закрыть
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
closeBtn.MouseButton1Click:Connect(function()
    guiOpen = false
    mainFrame.Visible = false
end)

-- Scroll frame для кнопок
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, -40)
scrollFrame.Position = UDim2.new(0, 0, 0, 40)
scrollFrame.BackgroundTransparency = 1
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = mainFrame

local uiList = Instance.new("UIListLayout")
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Padding = UDim.new(0, 8)
uiList.Parent = scrollFrame

-- ==============================
-- ФУНКЦИЯ СОЗДАНИЯ КНОПОК
-- ==============================
function createButton(text, callback, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 40)
    btn.Position = UDim2.new(0.05, 0, 0, 0)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(240, 240, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamSemibold
    btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 80)
    btn.BorderSizePixel = 0
    btn.Parent = scrollFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ==============================
-- ПОСТРОЕНИЕ UI
-- ==============================
function buildUI()
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    
    local newList = Instance.new("UIListLayout")
    newList.SortOrder = Enum.SortOrder.LayoutOrder
    newList.Padding = UDim.new(0, 8)
    newList.Parent = scrollFrame

    -- FLING
    createButton("💥 FLING (ближайшего игрока)", function()
        if flingCooldown then return end
        flingCooldown = true
        task.wait(1.5)
        flingCooldown = false
        flingNearestPlayer()
    end, Color3.fromRGB(180, 40, 40))

    -- ESP
    createButton("👁️ ESP " .. (espEnabled and "ВЫКЛ" or "ВКЛ"), function()
        espEnabled = not espEnabled
        if espEnabled then
            enableESP()
        else
            disableESP()
        end
        buildUI()
    end, Color3.fromRGB(40, 80, 180))

    -- FLIGHT
    createButton("✈️ ПОЛЁТ " .. (flightEnabled and "ВЫКЛ" or "ВКЛ"), function()
        flightEnabled = not flightEnabled
        if flightEnabled then
            enableFlight()
        else
            disableFlight()
        end
        buildUI()
    end, Color3.fromRGB(40, 180, 80))

    -- GODMODE
    if isAdmin then
        createButton("🛡️ БЕССМЕРТИЕ " .. (godModeEnabled and "ВЫКЛ" or "ВКЛ"), function()
            godModeEnabled = not godModeEnabled
            toggleGodMode()
            buildUI()
        end, Color3.fromRGB(180, 180, 40))
    end

    -- NO CLIP
    if isAdmin then
        createButton("🚪 NO CLIP " .. (noClipEnabled and "ВЫКЛ" or "ВКЛ"), function()
            noClipEnabled = not noClipEnabled
            toggleNoClip()
            buildUI()
        end, Color3.fromRGB(180, 40, 180))
    end

    -- SPEED
    if isAdmin then
        createButton("⚡ УСКОРЕНИЕ x" .. speedMultiplier, function()
            speedMultiplier = speedMultiplier == 1 and 2 or speedMultiplier == 2 and 3 or 1
            humanoid.WalkSpeed = 16 * speedMultiplier
            buildUI()
        end, Color3.fromRGB(40, 180, 180))
    end

    -- TELEPORT
    if isAdmin then
        createButton("🌀 ТЕЛЕПОРТ к игроку", function()
            local target = selectPlayer()
            if target then
                local targetChar = target.Character
                if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                    rootPart.CFrame = targetChar.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                end
            end
        end, Color3.fromRGB(40, 80, 180))
    end

    task.wait()
    local children = scrollFrame:GetChildren()
    local totalHeight = 0
    for _, child in pairs(children) do
        if child:IsA("TextButton") then
            totalHeight = totalHeight + child.Size.Y.Offset + 8
        end
    end
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 40)
end

-- ==============================
-- 1. FLING (ИСПРАВЛЕННЫЙ)
-- ==============================
function flingNearestPlayer()
    local nearest = nil
    local minDist = math.huge
    
    for _, target in pairs(Players:GetPlayers()) do
        if target ~= player then
            local targetChar = target.Character
            if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                local dist = (rootPart.Position - targetChar.HumanoidRootPart.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = target
                end
            end
        end
    end
    
    if not nearest then
        return
    end
    
    local targetChar = nearest.Character
    if not targetChar then return end
    
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    
    -- Телепортируемся к игроку
    rootPart.CFrame = targetHRP.CFrame + Vector3.new(0, 2, 3)
    task.wait(0.1)
    
    -- Создаём мощный флинг
    local force = Vector3.new(
        math.random(-300, 300),
        math.random(200, 400),
        math.random(-300, 300)
    )
    
    -- Основной толчок
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = force
    bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVelocity.Parent = targetHRP
    
    -- Разбрасываем все части тела
    for _, part in pairs(targetChar:GetChildren()) do
        if part:IsA("BasePart") and part ~= targetHRP then
            local bv = Instance.new("BodyVelocity")
            bv.Velocity = Vector3.new(
                math.random(-150, 150),
                math.random(100, 250),
                math.random(-150, 150)
            )
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Parent = part
            task.wait(0.05)
            bv:Destroy()
        end
    end
    
    -- Взрывной эффект (свет)
    local explosion = Instance.new("Explosion")
    explosion.Position = targetHRP.Position
    explosion.BlastRadius = 15
    explosion.BlastPressure = 500000
    explosion.Parent = Workspace
    
    task.wait(0.3)
    bodyVelocity:Destroy()
end

-- ==============================
-- 2. ESP (ИСПРАВЛЕННЫЙ)
-- ==============================
function enableESP()
    disableESP()
    for _, target in pairs(Players:GetPlayers()) do
        if target ~= player then
            local char = target.Character
            if char then
                local box = Instance.new("BoxHandleAdornment")
                box.Size = Vector3.new(4, 6, 2)
                box.Color3 = target.TeamColor and target.TeamColor.Color or Color3.fromRGB(255, 200, 100)
                box.Transparency = 0.4
                box.ZIndex = 0
                box.AlwaysOnTop = true
                box.Parent = char

                local nameTag = Instance.new("BillboardGui")
                nameTag.Size = UDim2.new(0, 200, 0, 40)
                nameTag.StudsOffset = Vector3.new(0, 3.5, 0)
                nameTag.AlwaysOnTop = true
                nameTag.Parent = char

                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(1, 0, 1, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                nameLabel.TextStrokeTransparency = 0.3
                nameLabel.TextScaled = true
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.Text = target.Name .. "\n❤️ " .. (char:FindFirstChild("Humanoid") and math.floor(char.Humanoid.Health) or "?")
                nameLabel.Parent = nameTag

                local healthBar = Instance.new("Frame")
                healthBar.Size = UDim2.new(1, 0, 0, 6)
                healthBar.Position = UDim2.new(0, 0, 1, 0)
                healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                healthBar.Parent = nameTag

                espObjects[target] = {box = box, nameTag = nameTag, healthBar = healthBar, label = nameLabel}
            end
        end
    end

    local updateConnection = RunService.RenderStepped:Connect(function()
        for target, data in pairs(espObjects) do
            if target and target.Character then
                local humanoid = target.Character:FindFirstChild("Humanoid")
                if humanoid then
                    local health = math.floor(humanoid.Health)
                    if data.label then
                        data.label.Text = target.Name .. "\n❤️ " .. health
                    end
                    if data.healthBar then
                        local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                        data.healthBar.Size = UDim2.new(healthPercent, 0, 0, 6)
                        data.healthBar.BackgroundColor3 = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                    end
                end
            end
        end
    end)
    table.insert(espConnections, updateConnection)

    local playerRemovedConnection = Players.PlayerRemoving:Connect(function(target)
        if espObjects[target] then
            if espObjects[target].box then espObjects[target].box:Destroy() end
            if espObjects[target].nameTag then espObjects[target].nameTag:Destroy() end
            espObjects[target] = nil
        end
    end)
    table.insert(espConnections, playerRemovedConnection)
end

function disableESP()
    for _, conn in pairs(espConnections) do
        pcall(conn.Disconnect, conn)
    end
    espConnections = {}
    for _, data in pairs(espObjects) do
        if data.box then data.box:Destroy() end
        if data.nameTag then data.nameTag:Destroy() end
    end
    espObjects = {}
end

-- ==============================
-- 3. FLIGHT (ИСПРАВЛЕННЫЙ)
-- ==============================
function enableFlight()
    if flightEnabled then return end
    flightEnabled = true

    flightBodyVelocity = Instance.new("BodyVelocity")
    flightBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flightBodyVelocity.Parent = rootPart

    flightGyro = Instance.new("BodyGyro")
    flightGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flightGyro.Parent = rootPart

    humanoid.PlatformStand = true

    local flightSpeed = 50
    local verticalSpeed = 30

    local function updateFlight()
        if not flightEnabled or not flightBodyVelocity then return end

        local moveDirection = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then 
            moveDirection = moveDirection + Camera.CFrame.LookVector * Vector3.new(1, 0, 1) 
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then 
            moveDirection = moveDirection - Camera.CFrame.LookVector * Vector3.new(1, 0, 1) 
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then 
            moveDirection = moveDirection - Camera.CFrame.RightVector * Vector3.new(1, 0, 1) 
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then 
            moveDirection = moveDirection + Camera.CFrame.RightVector * Vector3.new(1, 0, 1) 
        end

        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit * flightSpeed
        end

        local vertical = 0
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vertical = verticalSpeed end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vertical = -verticalSpeed end

        flightBodyVelocity.Velocity = moveDirection + Vector3.new(0, vertical, 0)
        flightGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position + Camera.CFrame.LookVector * Vector3.new(1, 0, 1))
    end

    local flightConnection = RunService.RenderStepped:Connect(updateFlight)
    table.insert(espConnections, flightConnection)
end

function disableFlight()
    flightEnabled = false
    if flightBodyVelocity then flightBodyVelocity:Destroy() end
    if flightGyro then flightGyro:Destroy() end
    flightBodyVelocity = nil
    flightGyro = nil
    humanoid.PlatformStand = false
end

-- ==============================
-- 4. GODMODE
-- ==============================
function toggleGodMode()
    godModeEnabled = not godModeEnabled
    if godModeEnabled then
        humanoid.MaxHealth = 9e9
        humanoid.Health = 9e9
        humanoid.BreakJointsOnDeath = false
    else
        humanoid.MaxHealth = 100
        humanoid.Health = 100
        humanoid.BreakJointsOnDeath = true
    end
end

-- ==============================
-- 5. NO CLIP (ИСПРАВЛЕННЫЙ)
-- ==============================
function toggleNoClip()
    noClipEnabled = not noClipEnabled
    if noClipEnabled then
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = RunService.RenderStepped:Connect(function()
            if not noClipEnabled then
                noclipConnection:Disconnect()
                return
            end
            for _, part in pairs(character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    else
        if noclipConnection then noclipConnection:Disconnect() end
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- ==============================
-- 6. TELEPORT (ВЫБОР ИГРОКА)
-- ==============================
function selectPlayer()
    local players = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            table.insert(players, plr)
        end
    end
    if #players == 0 then
        return nil
    end
    return players[1]
end

-- ==============================
-- СИСТЕМА КЛЮЧЕЙ
-- ==============================
function showKeyPrompt()
    local keyFrame = Instance.new("Frame")
    keyFrame.Size = UDim2.new(0, 360, 0, 180)
    keyFrame.Position = UDim2.new(0.5, -180, 0.5, -90)
    keyFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    keyFrame.BorderSizePixel = 0
    keyFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = keyFrame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = "ВВЕДИТЕ КЛЮЧ ДОСТУПА"
    title.TextColor3 = Color3.fromRGB(200, 200, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.BackgroundTransparency = 1
    title.Parent = keyFrame

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0.8, 0, 0, 40)
    input.Position = UDim2.new(0.1, 0, 0.3, 0)
    input.Text = ""
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    input.BorderSizePixel = 0
    input.Font = Enum.Font.Gotham
    input.TextScaled = true
    input.Parent = keyFrame

    local submitBtn = Instance.new("TextButton")
    submitBtn.Size = UDim2.new(0.4, 0, 0, 40)
    submitBtn.Position = UDim2.new(0.3, 0, 0.6, 0)
    submitBtn.Text = "ПОДТВЕРДИТЬ"
    submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
    submitBtn.BorderSizePixel = 0
    submitBtn.Font = Enum.Font.GothamBold
    submitBtn.TextScaled = true
    submitBtn.Parent = keyFrame

    local errorLabel = Instance.new("TextLabel")
    errorLabel.Size = UDim2.new(1, 0, 0, 30)
    errorLabel.Position = UDim2.new(0, 0, 0.8, 0)
    errorLabel.Text = ""
    errorLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    errorLabel.TextScaled = true
    errorLabel.Font = Enum.Font.Gotham
    errorLabel.BackgroundTransparency = 1
    errorLabel.Parent = keyFrame

    submitBtn.MouseButton1Click:Connect(function()
        local key = input.Text
        if key == ADMIN_KEY then
            isAdmin = true
            isScriptKey = false
            keyFrame:Destroy()
            mainFrame.Visible = true
            guiOpen = true
            buildUI()
        elseif key == SCRIPT_KEY then
            isScriptKey = true
            isAdmin = false
            keyFrame:Destroy()
            mainFrame.Visible = true
            guiOpen = true
            buildUI()
        else
            errorLabel.Text = "❌ НЕВЕРНЫЙ КЛЮЧ!"
        end
    end)

    input.FocusLost:Connect(function()
        if input.Text ~= "" then
            submitBtn.MouseButton1Click:Fire()
        end
    end)
end

-- ==============================
-- ОТКРЫТИЕ/ЗАКРЫТИЕ ПО TAB
-- ==============================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Tab then
        guiOpen = not guiOpen
        mainFrame.Visible = guiOpen
        if guiOpen then
            guiMinimized = false
            mainFrame.Size = UDim2.new(0, 420, 0, 540)
            scrollFrame.Visible = true
            minimizeBtn.Text = "—"
        end
    end
end)

-- ==============================
-- ЗАПУСК
-- ==============================
showKeyPrompt()

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    rootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    flightEnabled = false
    if flightBodyVelocity then flightBodyVelocity:Destroy() end
    if flightGyro then flightGyro:Destroy() end
    flightBodyVelocity = nil
    flightGyro = nil
    if noClipEnabled then
        noClipEnabled = false
        if noclipConnection then noclipConnection:Disconnect() end
    end
end)

Players.PlayerRemoving:Connect(function(target)
    if espObjects[target] then
        if espObjects[target].box then espObjects[target].box:Destroy() end
        if espObjects[target].nameTag then espObjects[target].nameTag:Destroy() end
        espObjects[target] = nil
    end
end)

print("✅ Универсальный хаб загружен! Введите ключ для доступа. Tab — открыть/закрыть меню.")
