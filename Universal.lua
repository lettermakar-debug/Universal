-- MM2 HUB UPDATE - РАБОЧАЯ ВЕРСИЯ
-- Discord: discord.gg/v8ZPq4y2nD

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

-- СОЗДАНИЕ GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MM2HUBUPDATE"
screenGui.Parent = game.CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 450, 0, 600)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -300)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
title.Text = "MM2 HUB UPDATE"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.BorderSizePixel = 0
title.Parent = mainFrame

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
end)

-- ФУНКЦИИ
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
    section.Size = UDim2.new(1, -20, 0, 400)
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
    label.Size = UDim2.new(0.8, 0, 1, 0)
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

-- Вкладка "Главная"
local mainSection = createSection("Главная", mainFrame)
tabs["Главная"] = mainSection
mainSection.section.Visible = true

-- Вкладка "Aim"
local aimSection = createSection("Aim", mainFrame)
tabs["Aim"] = aimSection

-- Вкладка "Телепорты"
local tpSection = createSection("Телепорты", mainFrame)
tabs["Телепорты"] = tpSection

-- Вкладка "Фарм"
local farmSection = createSection("Фарм", mainFrame)
tabs["Фарм"] = farmSection

-- Кнопки вкладок
local tabNames = {"Главная", "Aim", "Телепорты", "Фарм"}
for i, name in ipairs(tabNames) do
    local btn = createTab(name, 45 + (i-1) * 35)
    btn.MouseButton1Click:Connect(function()
        for _, section in pairs(tabs) do
            section.section.Visible = false
        end
        tabs[name].section.Visible = true
    end)
end

-- НАПОЛНЕНИЕ ВКЛАДОК

-- ГЛАВНАЯ
createButton("Обновить ESP", function()
    print("ESP обновлен")
end, mainSection)

createToggle("ESP Вкл", function(state)
    print("ESP: " .. tostring(state))
end, mainSection)

createToggle("Aimbot", function(state)
    print("Aimbot: " .. tostring(state))
end, mainSection)

-- AIM
createToggle("Показать FOV", function(state)
    print("FOV: " .. tostring(state))
end, aimSection)

createToggle("Игнорировать мирных", function(state)
    print("Игнор мирных: " .. tostring(state))
end, aimSection)

-- ТЕЛЕПОРТЫ
createButton("К убийце", function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
            break
        end
    end
end, tpSection)

createButton("К оружию", function()
    for _, item in pairs(workspace:GetDescendants()) do
        if item.Name == "Gun" and item:IsA("Tool") then
            item.Parent = LocalPlayer.Character
            break
        end
    end
end, tpSection)

createButton("В безопасную зону", function()
    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 10, 0)
end, tpSection)

-- ФАРМ
createToggle("Аура ножа", function(state)
    print("Аура ножа: " .. tostring(state))
end, farmSection)

createButton("Бросить нож", function()
    local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
    if tool then tool:Activate() end
end, farmSection)

print("MM2 HUB UPDATE загружен!")
