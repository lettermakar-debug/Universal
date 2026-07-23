-- MM2 Universal Script (как AtherHub)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local mouse = player:GetMouse()

-- Переменные состояния
local espEnabled = false
local noclipEnabled = false
local farming = false
local farmThread = nil
local espHighlights = {} -- для хранения Highlight объектов

-- Вспомогательные функции
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
    if not target or not target:IsA("BasePart") and not target:FindFirstChild("HumanoidRootPart") then
        return
    end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local targetPos
    if target:IsA("BasePart") then
        targetPos = target.Position
    else
        local targetHrp = target:FindFirstChild("HumanoidRootPart")
        if not targetHrp then return end
        targetPos = targetHrp.Position
    end
    hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
end

-- Поиск оружия на карте
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

-- Поиск монет
local function findCoins()
    local coins = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name == "Coin" or obj.Name == "Money" or obj.Name:lower():match("coin")) then
            table.insert(coins, obj)
        end
    end
    return coins
end

-- Функция обновления ESP
local function updateESP()
    for _, hl in pairs(espHighlights) do
        if hl and hl.Parent then
            hl:Destroy()
        end
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

-- Подписка на появление новых игроков
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        if espEnabled then
            wait(0.5)
            updateESP()
        end
    end)
end)

-- Функции телепортов
local function teleportToWeapon()
    local weapon = findWeapon()
    if weapon then
        teleportTo(weapon)
    else
        print("Оружие не найдено")
    end
end

local function teleportToRole(roleName)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local role = getRole(plr)
            if role == roleName and plr.Character then
                teleportTo(plr.Character)
                return
            end
        end
    end
    print(roleName .. " не найден на карте")
end

-- Kill All
local function killAll()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
            end
        end
    end
end

-- Автофарм
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

-- Noclip
local function setNoclip(state)
    noclipEnabled = state
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state
        end
    end
    if state then
        local function noclipPart(part)
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
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
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- Speed
local function setSpeed(multiplier)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = humanoid.WalkSpeed * multiplier
    end
end

-- ========== СОЗДАНИЕ GUI ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MM2UniversalHub"
screenGui.Parent = LocalPlayer.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 350, 0, 500)
mainFrame.Position = UDim2.new(0.5, -175, 0.5, -250)
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
title.Text = "🔪 MM2 Universal Hub"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.BorderSizePixel = 0
title.Parent = mainFrame

-- Кнопка закрытия
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

-- Вкладки
local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(1, 0, 0, 35)
tabFrame.Position = UDim2.new(0, 0, 0, 40)
tabFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
tabFrame.BorderSizePixel = 0
tabFrame.Parent = mainFrame

local tabs = {"Основное", "ESP", "Телепорты", "Фарм"}
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

-- Функция создания кнопки
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
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = color or Color3.fromRGB(60, 60, 80)
    end)
    return btn
end

-- Функция создания переключателя
local function createToggle(text, initialState, callback, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 35)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order or 0
    frame.Parent = contentFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.8, 0, 1, 0)
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

-- Функция очистки контента
local function clearContent()
    for _, child in pairs(contentFrame:GetChildren()) do
        if child ~= contentLayout then
            child:Destroy()
        end
    end
end

-- Функция переключения вкладки
local function switchTab(tabName)
    currentTab = tabName
    clearContent()
    if tabName == "Основное" then
        createToggle("Noclip (проход сквозь стены)", false, function(state)
            setNoclip(state)
        end, 1)
        
        createButton("Ускорение (Speed x2)", function()
            setSpeed(2)
        end, Color3.fromRGB(70, 70, 100), 2)
        
        createButton("Kill All (всех убить)", killAll, Color3.fromRGB(180, 40, 40), 3)
        
        createButton("Обновить ESP", function()
            if espEnabled then updateESP() end
        end, Color3.fromRGB(60, 100, 60), 4)

    elseif tabName == "ESP" then
        createToggle("Включить ESP", false, function(state)
            espEnabled = state
            updateESP()
        end, 1)
        createButton("Обновить подсветку", function()
            if espEnabled then updateESP() end
        end, Color3.fromRGB(50, 80, 120), 2)

    elseif tabName == "Телепорты" then
        createButton("Телепорт к оружию", teleportToWeapon, Color3.fromRGB(200, 150, 50), 1)
        createButton("Телепорт к шерифу", function() teleportToRole("Sheriff") end, Color3.fromRGB(50, 100, 255), 2)
        createButton("Телепорт к убийце", function() teleportToRole("Murderer") end, Color3.fromRGB(255, 50, 50), 3)

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
                    local nearest = nil
                    local minDist = math.huge
                    for _, coin in pairs(coins) do
                        local dist = (coin.Position - hrp.Position).Magnitude
                        if dist < minDist then
                            minDist = dist
                            nearest = coin
                        end
                    end
                    if nearest then teleportTo(nearest) end
                end
            end
        end, Color3.fromRGB(200, 180, 50), 2)
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

print("✅ MM2 Universal Hub loaded! Enjoy.")
