-- MM2 Ultimate Hub (с полётом, свертыванием, телепортами)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

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

-- Телепорт к выбранному игроку (создаём диалог выбора)
local function teleportToPlayer(plrName)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Name == plrName and plr.Character then
            teleportTo(plr.Character)
            return
        end
    end
    print("Игрок не найден")
end

-- ===== УМНАЯ АТАКА =====
local function smartAttack()
    local myRole = getRole(LocalPlayer)
    if myRole == "Murderer" then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.Health = 0 end
            end
        end
        print("Все убиты")
    elseif myRole == "Sheriff" then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and getRole(plr) == "Murderer" and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.Health = 0 end
                print("Убийца уничтожен")
                return
            end
        end
        print("Убийца не найден")
    else
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and getRole(plr) == "Murderer" and plr.Character then
                teleportTo(plr.Character)
                print("Телепорт к убийце")
                return
            end
        end
        print("Убийца не найден")
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

    -- Удаляем старые объекты полёта
    if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
    for _, conn in pairs(flyConnections) do conn:Disconnect() end
    flyConnections = {}

    if state then
        -- Включаем режим полёта
        hum.PlatformStand = true
        setNoclip(true) -- включаем ноклип

        -- Создаём BodyVelocity и BodyGyro для управления
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        flyBodyVelocity.Parent = hrp

        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        flyBodyGyro.CFrame = hrp.CFrame
        flyBodyGyro.Parent = hrp

        -- Обработка ввода для управления
        local function onInputBegan(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local key = input.KeyCode
                if key == Enum.KeyCode.W or key == Enum.KeyCode.A or key == Enum.KeyCode.S or key == Enum.KeyCode.D or key == Enum.KeyCode.Space or key == Enum.KeyCode.LeftShift then
                    -- Обновляем скорость в каждом кадре
                end
            end
        end

        local function onInputEnded(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local key = input.KeyCode
                if key == Enum.KeyCode.W or key == Enum.KeyCode.A or key == Enum.KeyCode.S or key == Enum.KeyCode.D or key == Enum.KeyCode.Space or key == Enum.KeyCode.LeftShift then
                    -- Останавливаем движение по оси, если отпущена клавиша
                end
            end
        end

        UserInputService.InputBegan:Connect(onInputBegan)
        UserInputService.InputEnded:Connect(onInputEnded)

        -- Основной цикл обновления скорости
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
            -- Обновляем ориентацию (чтобы смотреть в направлении движения)
            if moveDirection.Magnitude > 0 and flyBodyGyro then
                flyBodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + moveDirection.Unit)
            end
        end

        -- Подключаем к RunService
        local conn = RunService.Heartbeat:Connect(updateFly)
        table.insert(flyConnections, conn)

    else
        -- Выключаем полёт
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

-- ========== ГРАФИЧЕСКИЙ ИНТЕРФЕЙС ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MM2UltimateHub"
screenGui.Parent = LocalPlayer.PlayerGui

-- Главное окно
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 380, 0, 600)
mainFrame.Position = UDim2.new(0.5, -190, 0.5, -300)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Заголовок
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
title.Text = "🔪 MM2 Ultimate Hub"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.BorderSizePixel = 0
title.Parent = mainFrame

-- Кнопки заголовка
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -70, 0, 5)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 50)
minimizeBtn.Text = "—"
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
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextScaled = true
closeBtn.BorderSizePixel = 0
closeBtn.Parent = mainFrame
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Кнопка восстановления (всегда видна, когда окно скрыто)
local restoreBtn = Instance.new("TextButton")
restoreBtn.Size = UDim2.new(0, 50, 0, 50)
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
tabFrame.Size = UDim2.new(1, 0, 0, 35)
tabFrame.Position = UDim2.new(0, 0, 0, 40)
tabFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
tabFrame.BorderSizePixel = 0
tabFrame.Parent = mainFrame

local tabs = {"Основное", "ESP", "Телепорты", "Фарм", "Атака", "Полет"}
local tabButtons = {}
local currentTab = "Основное"

-- Контент
local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Size = UDim2.new(1, -10, 1, -90)
contentFrame.Position = UDim2.new(0, 5, 0, 80)
contentFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
contentFrame.BackgroundTransparency = 0.3
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 4
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
contentFrame.Parent = mainFrame

local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 5)
contentLayout.Parent = contentFrame

-- Функции создания элементов
local function createButton(text, callback, color, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = color or Color3.fromRGB(60, 60, 80)
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextScaled = true
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order or 0
    btn.Parent = contentFrame
    btn.MouseButton1Click:Connect(callback)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(80, 80, 100) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = color or Color3.fromRGB(60, 60, 80) end)
    return btn
end

local function createToggle(text, initialState, callback, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 35)
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
    toggleBtn.Size = UDim2.new(0, 50, 0, 25)
    toggleBtn.Position = UDim2.new(1, -55, 0.5, -12.5)
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

-- Функция создания ползунка (Slider)
local function createSlider(text, minVal, maxVal, defaultVal, callback, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
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
    sliderFrame.Size = UDim2.new(1, 0, 0, 20)
    sliderFrame.Position = UDim2.new(0, 0, 0, 22)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = frame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
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
    button.MouseButton1Down:Connect(function()
        dragging = true
    end)
    button.MouseButton1Up:Connect(function()
        dragging = false
    end)
    button.MouseLeave:Connect(function()
        dragging = false
    end)

    local function updateSlider(x)
        local relX = math.clamp((x - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
        local val = minVal + relX * (maxVal - minVal)
        val = math.round(val / 1) * 1 -- округление до целого
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

-- Очистка контента
local function clearContent()
    for _, child in pairs(contentFrame:GetChildren()) do
        if child ~= contentLayout then child:Destroy() end
    end
end

-- Переключение вкладок
local function switchTab(tabName)
    currentTab = tabName
    clearContent()
    if tabName == "Основное" then
        createToggle("Noclip (проход сквозь стены)", false, setNoclip, 1)
        createButton("Ускорение (Speed x2)", function()
            local hum = character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = hum.WalkSpeed * 2 end
        end, Color3.fromRGB(70, 70, 100), 2)
        createButton("Обновить ESP", function() if espEnabled then updateESP() end end, Color3.fromRGB(60, 100, 60), 3)

    elseif tabName == "ESP" then
        createToggle("Включить ESP", false, function(state) espEnabled = state; updateESP() end, 1)
        createButton("Обновить подсветку", function() if espEnabled then updateESP() end end, Color3.fromRGB(50, 80, 120), 2)

    elseif tabName == "Телепорты" then
        createButton("Телепорт к оружию", teleportToWeapon, Color3.fromRGB(200, 150, 50), 1)
        createButton("Телепорт к шерифу", function() teleportToRole("Sheriff") end, Color3.fromRGB(50, 100, 255), 2)
        createButton("Телепорт к убийце", function() teleportToRole("Murderer") end, Color3.fromRGB(255, 50, 50), 3)
        createButton("Выбрать игрока для телепорта", function()
            -- Создаём простой диалог выбора
            local dialog = Instance.new("Frame")
            dialog.Size = UDim2.new(0, 250, 0, 300)
            dialog.Position = UDim2.new(0.5, -125, 0.5, -150)
            dialog.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            dialog.BorderSizePixel = 0
            dialog.Active = true
            dialog.Parent = screenGui

            local title2 = Instance.new("TextLabel", dialog)
            title2.Size = UDim2.new(1, 0, 0, 30)
            title2.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
            title2.Text = "Выберите игрока"
            title2.TextColor3 = Color3.new(1,1,1)
            title2.TextScaled = true

            local list = Instance.new("ScrollingFrame", dialog)
            list.Size = UDim2.new(1, -10, 1, -50)
            list.Position = UDim2.new(0, 5, 0, 35)
            list.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
            list.BorderSizePixel = 0
            list.ScrollBarThickness = 4

            local layout = Instance.new("UIListLayout", list)
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Padding = UDim.new(0, 2)

            for _, plr in pairs(Players:GetPlayers()) do
                local btn = Instance.new("TextButton", list)
                btn.Size = UDim2.new(1, 0, 0, 30)
                btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
                btn.Text = plr.Name
                btn.TextColor3 = Color3.new(1,1,1)
                btn.TextScaled = true
                btn.MouseButton1Click:Connect(function()
                    teleportToPlayer(plr.Name)
                    dialog:Destroy()
                end)
            end

            -- Кнопка закрытия
            local closeDlg = Instance.new("TextButton", dialog)
            closeDlg.Size = UDim2.new(0, 30, 0, 30)
            closeDlg.Position = UDim2.new(1, -35, 0, 0)
            closeDlg.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            closeDlg.Text = "X"
            closeDlg.TextColor3 = Color3.new(1,1,1)
            closeDlg.TextScaled = true
            closeDlg.MouseButton1Click:Connect(function() dialog:Destroy() end)
        end, Color3.fromRGB(100, 100, 200), 4)

    elseif tabName == "Фарм" then
        createToggle("Авто-фарм монет", false, function(state)
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
        createButton("Телепорт к ближайшей монете", function()
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

    elseif tabName == "Атака" then
        createButton("⚔️ Умная атака", smartAttack, Color3.fromRGB(200, 50, 50), 1)
        createToggle("Высокий прыжок (x3)", false, setHighJump, 2)
        createButton("Телепорт к убийце и удар", function()
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and getRole(plr) == "Murderer" and plr.Character then
                    teleportTo(plr.Character)
                    wait(0.1)
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.Health = 0 end
                    print("Убийца убит")
                    return
                end
            end
            print("Убийца не найден")
        end, Color3.fromRGB(150, 50, 150), 3)

    elseif tabName == "Полет" then
        createToggle("Режим полёта", false, function(state)
            toggleFly(state)
        end, 1)
        createSlider("Скорость полёта", 10, 200, flySpeed, function(val)
            flySpeed = val
        end, 2)
    end
    wait()
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 10)
end

-- Создание кнопок вкладок
local tabPos = 0
for _, name in ipairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1 / #tabs, -2, 1, -4)
    btn.Position = UDim2.new(tabPos / #tabs, 1, 0, 2)
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

-- Активируем первую вкладку
switchTab("Основное")
tabButtons[1].BackgroundColor3 = Color3.fromRGB(90, 90, 120)

print("✅ MM2 Ultimate Hub загружен! Наслаждайтесь.")
