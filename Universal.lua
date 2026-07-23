-- ========================================
--   🔪 MM2 ULTIMATE HUB V5.5
--   УПРОЩЕННЫЙ ИНТЕРФЕЙС + МУЗЫКА
-- ========================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

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
local flingPower = 5000
local autoShoot = false
local autoShootThread = nil
local antiFlingEnabled = false
local antiFlingConn = nil
local godMode = false
local godModeConn = nil
local musicEnabled = false
local currentMusic = nil

-- ===== МУЗЫКА =====
local musicList = {
    {name = "🎵 Phonk", id = "1843399987"},
    {name = "🎵 Phonk 2", id = "1845473137"},
    {name = "🎵 Rap", id = "1837856009"},
    {name = "🎵 Chill", id = "1843176372"},
    {name = "🎵 EDM", id = "1843271654"},
    {name = "🎵 Rock", id = "1843242477"},
    {name = "🎵 Lofi", id = "1843396720"},
    {name = "🎵 Trap", id = "1843402036"},
    {name = "🎵 House", id = "1844597805"},
    {name = "🎵 Synthwave", id = "1845320768"},
}

local function playMusic(musicId)
    if currentMusic then
        currentMusic:Stop()
        currentMusic:Destroy()
        currentMusic = nil
    end
    if not musicEnabled then return end
    
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. musicId
    sound.Volume = 0.5
    sound.Looped = true
    sound.Parent = SoundService
    sound:Play()
    currentMusic = sound
    print("🎵 Музыка включена: " .. musicId)
end

local function toggleMusic(state)
    musicEnabled = state
    if not state and currentMusic then
        currentMusic:Stop()
        currentMusic:Destroy()
        currentMusic = nil
        print("🎵 Музыка выключена")
    end
end

local function setVolume(vol)
    if currentMusic then
        currentMusic.Volume = vol / 100
    end
end

-- ===== ОПРЕДЕЛЕНИЕ РОЛИ =====
local function getRole(plr)
    if plr:FindFirstChild("Murderer") and plr.Murderer.Value == true then
        return "Murderer"
    elseif plr:FindFirstChild("Sheriff") and plr.Sheriff.Value == true then
        return "Sheriff"
    else
        return "Innocent"
    end
end

-- ===== ТЕЛЕПОРТ =====
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

-- ===== ПОИСК ОРУЖИЯ =====
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

-- ===== ПОИСК МОНЕТ =====
local function findCoins()
    local coins = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name == "Coin" or obj.Name == "Money" or obj.Name:lower():match("coin")) then
            table.insert(coins, obj)
        end
    end
    return coins
end

-- ===== ТЕЛЕПОРТЫ =====
local function teleportToLobby()
    local spawns = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            table.insert(spawns, obj)
        end
    end
    if #spawns > 0 then
        teleportTo(spawns[1])
        print("✅ Телепорт в лобби")
    end
end

local function teleportToMap()
    local spawns = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") and obj.Parent and not obj.Parent.Name:match("Lobby") then
            table.insert(spawns, obj)
        end
    end
    if #spawns > 0 then
        teleportTo(spawns[math.random(1, #spawns)])
        print("✅ Телепорт на карту")
    end
end

local function teleportToWeapon()
    local w = findWeapon()
    if w then teleportTo(w) else print("❌ Оружие не найдено") end
end

local function teleportToRole(roleName)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local role = getRole(plr)
            if role == roleName and plr.Character then
                teleportTo(plr.Character)
                print("✅ Телепорт к " .. roleName)
                return
            end
        end
    end
    print("❌ " .. roleName .. " не найден")
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
                hl.FillTransparency = 0.4
                hl.OutlineTransparency = 0.5
                local role = getRole(plr)
                if role == "Murderer" then
                    hl.FillColor = Color3.fromRGB(255, 0, 0)
                    hl.OutlineColor = Color3.fromRGB(200, 0, 0)
                elseif role == "Sheriff" then
                    hl.FillColor = Color3.fromRGB(0, 100, 255)
                    hl.OutlineColor = Color3.fromRGB(0, 50, 200)
                else
                    hl.FillColor = Color3.fromRGB(0, 200, 0)
                    hl.OutlineColor = Color3.fromRGB(0, 150, 0)
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

-- ===== ШОТ МАРДЕР =====
local function shootMurderer()
    if getRole(LocalPlayer) ~= "Sheriff" then
        print("❌ Вы не шериф!")
        return
    end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and getRole(plr) == "Murderer" and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Health = 0
                print("🔫 Убийца уничтожен!")
                return
            end
        end
    end
    print("❌ Убийца не найден")
end

-- ===== ФЛИНГ =====
local function flingPlayer(target)
    if not target or not target.Character then return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local direction = (hrp.Position - character.HumanoidRootPart.Position).Unit
    hrp.AssemblyLinearVelocity = direction * flingPower + Vector3.new(0, flingPower * 0.5, 0)
    hrp.AssemblyAngularVelocity = Vector3.new(math.random(-100, 100), math.random(-100, 100), math.random(-100, 100))
end

local function flingAll()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            flingPlayer(plr)
        end
    end
    print("🌀 Все подброшены!")
end

-- ===== АНТИ-ФЛИНГ =====
local function toggleAntiFling(state)
    antiFlingEnabled = state
    if antiFlingConn then antiFlingConn:Disconnect() end
    if state then
        antiFlingConn = RunService.Heartbeat:Connect(function()
            if character and character:FindFirstChild("HumanoidRootPart") then
                local hrp = character.HumanoidRootPart
                if hrp.AssemblyLinearVelocity.Magnitude > 200 then
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end
            end
        end)
        print("🛡️ Анти-флинг включен")
    else
        print("🛡️ Анти-флинг выключен")
    end
end

-- ===== GOD MODE =====
local function toggleGodMode(state)
    godMode = state
    if godModeConn then godModeConn:Disconnect() end
    if state then
        godModeConn = RunService.Heartbeat:Connect(function()
            if character then
                local hum = character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    hum.Health = hum.MaxHealth
                end
            end
        end)
        print("🛡️ God Mode включен")
    else
        print("🛡️ God Mode выключен")
    end
end

-- ===== УБИТЬ ВСЕХ =====
local function killAll()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end
    end
    print("💀 Все убиты!")
end

-- ===== АВТО-СТРЕЛЬБА =====
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
        if part:IsA("BasePart") then
            part.CanCollide = not state
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

-- ============================================================
-- ========== ПРОСТОЙ ИНТЕРФЕЙС ==========
-- ============================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MM2Hub"
screenGui.Parent = LocalPlayer.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 400)
mainFrame.Position = UDim2.new(0.5, -140, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
title.Text = "🔪 MM2 HUB"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.BorderSizePixel = 0
title.Parent = mainFrame

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
minimizeBtn.Position = UDim2.new(1, -55, 0, 3)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 50)
minimizeBtn.Text = "−"
minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
minimizeBtn.TextScaled = true
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = mainFrame
minimizeBtn.MouseButton1Click:Connect(function()
    guiMinimized = true
    mainFrame.Visible = false
    restoreBtn.Visible = true
end)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 25, 0, 25)
closeBtn.Position = UDim2.new(1, -28, 0, 3)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextScaled = true
closeBtn.BorderSizePixel = 0
closeBtn.Parent = mainFrame
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

local restoreBtn = Instance.new("TextButton")
restoreBtn.Size = UDim2.new(0, 40, 0, 40)
restoreBtn.Position = UDim2.new(0, 10, 0, 10)
restoreBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
restoreBtn.Text = "🔪"
restoreBtn.TextColor3 = Color3.new(1, 1, 1)
restoreBtn.TextScaled = true
restoreBtn.BorderSizePixel = 0
restoreBtn.Visible = false
restoreBtn.Parent = screenGui
restoreBtn.MouseButton1Click:Connect(function()
    guiMinimized = false
    mainFrame.Visible = true
    restoreBtn.Visible = false
end)

-- Вкладки
local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(1, 0, 0, 25)
tabFrame.Position = UDim2.new(0, 0, 0, 30)
tabFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
tabFrame.BorderSizePixel = 0
tabFrame.Parent = mainFrame

local tabs = {"Осн", "ESP", "Тел", "Фарм", "Бой", "Полет", "🎵"}
local tabButtons = {}

local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Size = UDim2.new(1, -10, 1, -70)
contentFrame.Position = UDim2.new(0, 5, 0, 60)
contentFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
contentFrame.BackgroundTransparency = 0.3
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 3
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
contentFrame.Parent = mainFrame

local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 3)
contentLayout.Parent = contentFrame

local function createButton(text, callback, color, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 28)
    btn.BackgroundColor3 = color or Color3.fromRGB(60, 60, 80)
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextScaled = true
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order or 0
    btn.Parent = contentFrame
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function createToggle(text, initialState, callback, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 28)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
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

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 45, 0, 20)
    toggleBtn.Position = UDim2.new(1, -50, 0.5, -10)
    toggleBtn.BackgroundColor3 = initialState and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
    toggleBtn.Text = initialState and "Вкл" or "Выкл"
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.TextScaled = true
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = frame

    local state = initialState
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        toggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
        toggleBtn.Text = state and "Вкл" or "Выкл"
        callback(state)
    end)
    return frame
end

local function createSlider(text, minVal, maxVal, defaultVal, callback, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 40)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order or 0
    frame.Parent = contentFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 16)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(defaultVal)
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.Gotham
    label.Parent = frame

    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, 0, 0, 16)
    sliderFrame.Position = UDim2.new(0, 0, 0, 18)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = frame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    fill.BorderSizePixel = 0
    fill.Parent = sliderFrame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 16, 1, -4)
    button.Position = UDim2.new((defaultVal - minVal) / (maxVal - minVal), -8, 0, 2)
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
        button.Position = UDim2.new(relX, -8, 0, 2)
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

local function clearContent()
    for _, child in pairs(contentFrame:GetChildren()) do
        if child ~= contentLayout then child:Destroy() end
    end
end

local function switchTab(tabName)
    clearContent()
    
    if tabName == "Осн" then
        createToggle("Noclip", false, setNoclip, 1)
        createToggle("Выс. прыжок", false, setHighJump, 2)
        createToggle("God Mode", false, toggleGodMode, 3)
        createToggle("Анти-флинг", false, toggleAntiFling, 4)
        createButton("Speed x2", function()
            local hum = character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = hum.WalkSpeed * 2 end
        end, Color3.fromRGB(70, 70, 100), 5)
        createButton("Убить всех", killAll, Color3.fromRGB(200, 40, 40), 6)

    elseif tabName == "ESP" then
        createToggle("ESP", false, function(state)
            espEnabled = state
            updateESP()
        end, 1)
        createButton("Обновить", function() if espEnabled then updateESP() end end, Color3.fromRGB(60, 120, 60), 2)

    elseif tabName == "Тел" then
        createButton("В лобби", teleportToLobby, Color3.fromRGB(50, 150, 50), 1)
        createButton("На карту", teleportToMap, Color3.fromRGB(50, 150, 150), 2)
        createButton("К оружию", teleportToWeapon, Color3.fromRGB(200, 150, 50), 3)
        createButton("К шерифу", function() teleportToRole("Sheriff") end, Color3.fromRGB(50, 100, 255), 4)
        createButton("К убийце", function() teleportToRole("Murderer") end, Color3.fromRGB(255, 50, 50), 5)

    elseif tabName == "Фарм" then
        createToggle("Автофарм", false, function(state)
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
        createButton("К монете", function()
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
        createButton("ШОТ МАРДЕР", shootMurderer, Color3.fromRGB(50, 150, 255), 1)
        createButton("Флинг всех", flingAll, Color3.fromRGB(150, 50, 200), 2)
        createSlider("Сила флинга", 1000, 15000, flingPower, function(val) flingPower = val end, 3)
        createToggle("Автострельба", false, toggleAutoShoot, 4)

    elseif tabName == "Полет" then
        createToggle("Полет", false, toggleFly, 1)
        createSlider("Скорость", 10, 200, flySpeed, function(val) flySpeed = val end, 2)

    elseif tabName == "🎵" then
        createToggle("🎵 Музыка", false, function(state)
            toggleMusic(state)
        end, 1)
        createSlider("🔊 Громкость", 0, 100, 50, function(val)
            setVolume(val)
        end, 2)
        for i, music in ipairs(musicList) do
            createButton(music.name, function()
                playMusic(music.id)
            end, Color3.fromRGB(80, 50, 120), i + 2)
        end
        createButton("⏹️ Стоп", function()
            if currentMusic then
                currentMusic:Stop()
                currentMusic:Destroy()
                currentMusic = nil
                print("🎵 Музыка остановлена")
            end
        end, Color3.fromRGB(200, 50, 50), #musicList + 3)
    end
    
    wait()
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 10)
end

-- Создание кнопок вкладок
local tabPos = 0
for _, name in ipairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1 / #tabs, -1, 1, -2)
    btn.Position = UDim2.new(tabPos / #tabs, 1, 0, 1)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    btn.Text = name
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Name = name
    btn.Parent = tabFrame
    btn.MouseButton1Click:Connect(function()
        switchTab(name)
        for _, tb in pairs(tabFrame:GetChildren()) do
            if tb:IsA("TextButton") then
                tb.BackgroundColor3 = (tb.Name == name) and Color3.fromRGB(90, 90, 120) or Color3.fromRGB(50, 50, 70)
            end
        end
    end)
    table.insert(tabButtons, btn)
    tabPos = tabPos + 1
end

switchTab("Осн")
tabButtons[1].BackgroundColor3 = Color3.fromRGB(90, 90, 120)

print("✅ MM2 HUB загружен!")
print("🎵 Вкладка Музыка добавлена!")
