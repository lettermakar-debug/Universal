--[[
    Murder Mystery 2 Universal Hub (Fixed)
    Функции:
    - ESP с цветами ролей
    - Телепорты: к оружию, шерифу, убийце
    - Kill All (для убийцы)
    - Авто-фарм монет
    - Noclip + Speed (опционально)
--]]

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local mouse = player:GetMouse()
local runService = game:GetService("RunService")

-- ===== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =====
local function getRole(plr)
    -- Возвращает строку: "Murderer", "Sheriff" или "Innocent"
    if plr:FindFirstChild("Murderer") and plr.Murderer.Value == true then
        return "Murderer"
    elseif plr:FindFirstChild("Sheriff") and plr.Sheriff.Value == true then
        return "Sheriff"
    else
        return "Innocent"
    end
end

local function teleportTo(target)
    if target and target:FindFirstChild("HumanoidRootPart") then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = target.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
        end
    end
end

local function findWeapon()
    -- Ищем оружие на карте (выпавшее или лежащее)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:match("Gun") or obj.Name:match("Knife") or obj.Name:match("Pistol") then
            return obj
        end
        -- Также проверяем инструменты (если они есть)
        if obj:IsA("Tool") and (obj.Name:match("Gun") or obj.Name:match("Knife") or obj.Name:match("Pistol")) then
            return obj
        end
    end
    return nil
end

-- ===== СОЗДАНИЕ ГЛАВНОГО GUI =====
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "MM2Hub"

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 320, 0, 450)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true

-- Заголовок
local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
title.Text = "🔪 MM2 Universal Hub"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.BorderSizePixel = 0

-- Кнопка закрытия
local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextScaled = true
closeBtn.BorderSizePixel = 0
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Вкладки
local tabFrame = Instance.new("Frame", mainFrame)
tabFrame.Size = UDim2.new(1, 0, 0, 35)
tabFrame.Position = UDim2.new(0, 0, 0, 40)
tabFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
tabFrame.BackgroundTransparency = 0.5
tabFrame.BorderSizePixel = 0

local tabs = {"Основное", "ESP", "Телепорты", "Фарм"}
local tabBtns = {}
local currentTab = "Основное"

local contentFrame = Instance.new("ScrollingFrame", mainFrame)
contentFrame.Size = UDim2.new(1, -10, 1, -85)
contentFrame.Position = UDim2.new(0, 5, 0, 75)
contentFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
contentFrame.BackgroundTransparency = 0.3
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 4
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

local contentLayout = Instance.new("UIListLayout", contentFrame)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 5)

-- Функция создания кнопки с индикатором
local function createButton(text, callback, color, order)
    local btn = Instance.new("TextButton", contentFrame)
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = color or Color3.fromRGB(60, 60, 80)
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextScaled = true
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order or 0
    btn.AutoButtonColor = false
    btn.MouseButton1Click:Connect(callback)
    
    -- Эффект наведения
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = color or Color3.fromRGB(60, 60, 80)
    end)
    return btn
end

-- Функция создания переключателя (вкл/выкл)
local function createToggle(text, initialState, callback, order)
    local frame = Instance.new("Frame", contentFrame)
    frame.Size = UDim2.new(1, -10, 0, 35)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order or 0

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.8, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextScaled = true
    label.Font = Enum.Font.Gotham

    local toggle = Instance.new("TextButton", frame)
    toggle.Size = UDim2.new(0, 50, 0, 25)
    toggle.Position = UDim2.new(1, -55, 0.5, -12.5)
    toggle.BackgroundColor3 = initialState and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
    toggle.Text = initialState and "Вкл" or "Выкл"
    toggle.TextColor3 = Color3.new(1, 1, 1)
    toggle.TextScaled = true
    toggle.BorderSizePixel = 0

    local state = initialState
    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.BackgroundColor3 = state and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
        toggle.Text = state and "Вкл" or "Выкл"
        callback(state)
    end)
    return frame
end

-- ===== ФУНКЦИОНАЛ =====

-- 1. ESP
local espEnabled = false
local espConnections = {}
local function updateESP()
    if not espEnabled then
        for _, conn in pairs(espConnections) do
            conn:Disconnect()
        end
        espConnections = {}
        -- Удаляем все Highlight
        for _, plr in pairs(game.Players:GetPlayers()) do
            if plr.Character then
                for _, obj in pairs(plr.Character:GetChildren()) do
                    if obj:IsA("Highlight") then
                        obj:Destroy()
                    end
                end
            end
        end
        return
    end

    -- Функция добавления Highlight для игрока
    local function applyHighlight(plr)
        if plr == player then return end
        local char = plr.Character
        if not char then return end
        -- Удаляем старые
        for _, obj in pairs(char:GetChildren()) do
            if obj:IsA("Highlight") then obj:Destroy() end
        end
        local hl = Instance.new("Highlight", char)
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
        hl.FillTransparency = 0.3
        hl.OutlineTransparency = 0.5
    end

    -- Применить ко всем игрокам
    for _, plr in pairs(game.Players:GetPlayers()) do
        applyHighlight(plr)
    end

    -- Слушаем появление новых игроков
    local conn1 = game.Players.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(function()
            applyHighlight(plr)
        end)
    end)
    table.insert(espConnections, conn1)

    -- Слушаем изменения ролей (можно добавить, но в MM2 роли не меняются динамически, поэтому ок)
end

-- 2. Телепорты
local function teleportToWeapon()
    local weapon = findWeapon()
    if weapon then
        teleportTo(weapon)
    else
        print("Оружие не найдено")
    end
end

local function teleportToRole(roleName)
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= player then
            local role = getRole(plr)
            if role == roleName and plr.Character then
                teleportTo(plr.Character)
                return
            end
        end
    end
    print(roleName .. " не найден")
end

-- 3. Kill All
local function killAll()
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
            end
        end
    end
end

-- 4. Автофарм
local farming = false
local farmThread = nil
local function autoFarm()
    while farming do
        local coins = {}
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name == "Coin" or obj.Name == "Money") then
                table.insert(coins, obj)
            end
        end
        if #coins > 0 then
            -- Телепортируемся к первой монете
            teleportTo(coins[1])
            wait(0.2) -- даём время подобрать
        end
        wait(0.3)
    end
end

-- 5. Noclip
local noclip = false
local function setNoclip(state)
    noclip = state
    if state then
        -- Включаем проход через стены
        character:WaitForChild("HumanoidRootPart").CanCollide = false
        -- Можно также обрабатывать новые части
    else
        character:WaitForChild("HumanoidRootPart").CanCollide = true
    end
end

-- Следим за появлением новых частей персонажа
local noclipConn
if noclipConn then noclipConn:Disconnect() end
noclipConn = character.DescendantAdded:Connect(function(part)
    if noclip and part:IsA("BasePart") then
        part.CanCollide = false
    end
end)

-- ===== ПОСТРОЕНИЕ МЕНЮ ПО ВКЛАДКАМ =====

-- Функция очистки contentFrame
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
        
        local speedBtn = createButton("Speed (ускорение)", function()
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local speed = hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = speed * 1.5
            end
        end, Color3.fromRGB(70, 70, 100), 2)
        
        local killBtn = createButton("Kill All (если вы убийца)", killAll, Color3.fromRGB(180, 40, 40), 3)
        
        local refreshBtn = createButton("Обновить ESP", function()
            if espEnabled then
                updateESP()
            end
        end, Color3.fromRGB(60, 100, 60), 4)

    elseif tabName == "ESP" then
        createToggle("Включить ESP", false, function(state)
            espEnabled = state
            updateESP()
        end, 1)
        -- Кнопка обновления ролей вручную
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
                farmThread = coroutine.create(autoFarm)
                coroutine.resume(farmThread)
            else
                if farmThread then coroutine.close(farmThread) end
                farmThread = nil
            end
        end, 1)
        createButton("Телепорт к ближайшей монете", function()
            local nearest = nil
            local minDist = math.huge
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and (obj.Name == "Coin" or obj.Name == "Money") then
                    local dist = (obj.Position - hrp.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        nearest = obj
                    end
                end
            end
            if nearest then teleportTo(nearest) end
        end, Color3.fromRGB(200, 180, 50), 2)
    end
    -- Обновляем CanvasSize
    wait()
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y)
end

-- Создаём кнопки вкладок
local tabPos = 0
for _, name in ipairs(tabs) do
    local btn = Instance.new("TextButton", tabFrame)
    btn.Size = UDim2.new(1 / #tabs, -2, 1, -4)
    btn.Position = UDim2.new(tabPos / #tabs, 1, 0, 2)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    btn.Text = name
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Name = name
    btn.MouseButton1Click:Connect(function()
        switchTab(name)
        -- Подсветка активной вкладки
        for _, tb in pairs(tabFrame:GetChildren()) do
            if tb:IsA("TextButton") then
                tb.BackgroundColor3 = (tb.Name == name) and Color3.fromRGB(90, 90, 120) or Color3.fromRGB(50, 50, 70)
            end
        end
    end)
    table.insert(tabBtns, btn)
    tabPos = tabPos + 1
end

-- Активируем первую вкладку
switchTab("Основное")
-- Подсветка первой вкладки
tabBtns[1].BackgroundColor3 = Color3.fromRGB(90, 90, 120)

print("✅ MM2 Universal Hub загружен! Наслаждайтесь.")
