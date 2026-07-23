--[[
    Универсальный скрипт Murder Mystery 2
    Функции: ESP (роли), телепорт к оружию/шерифу/убийце,
    авто-фарм монет, Kill All (для убийцы), Noclip, Speed.
--]]

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local mouse = player:GetMouse()

-- Создание GUI
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 200, 0, 300)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.Active = true
mainFrame.Draggable = true

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Text = "MM2 Universal Hub"
title.TextColor3 = Color3.new(1,1,1)
title.TextScaled = true

-- Функция создания кнопок
local function createButton(text, callback, yPos)
    local btn = Instance.new("TextButton", mainFrame)
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextScaled = true
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ESP (подсветка игроков)
local function setupESP()
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= player then
            local highlight = Instance.new("Highlight")
            highlight.Parent = plr.Character or plr.CharacterAdded:Wait()
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.FillTransparency = 0.5
        end
    end
end

-- Телепорт к объекту
local function teleportTo(target)
    if target and target:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
    end
end

-- Kill All (если вы убийца)
local function killAll()
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.Health = 0 end
        end
    end
end

-- Авто-фарм монет
local function autoFarm()
    while getgenv().farming do
        for _, v in pairs(workspace:GetDescendants()) do
            if v.Name == "Coin" and v:IsA("BasePart") then
                character.HumanoidRootPart.CFrame = v.CFrame + Vector3.new(0, 2, 0)
                wait(0.1)
            end
        end
        wait(0.5)
    end
end

-- Noclip
local function setNoclip(state)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state
        end
    end
end

-- Создание кнопок
local y = 35
createButton("ESP (вкл)", function() setupESP() end, y); y = y + 35
createButton("ТП к оружию", function()
    local gun = workspace:FindFirstChild("Gun") or workspace:FindFirstChild("DroppedGun")
    if gun then teleportTo(gun) end
end, y); y = y + 35
createButton("ТП к шерифу", function()
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr.Character and plr.Character:FindFirstChild("Sheriff") then
            teleportTo(plr.Character)
        end
    end
end, y); y = y + 35
createButton("ТП к убийце", function()
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr.Character and plr.Character:FindFirstChild("Murderer") then
            teleportTo(plr.Character)
        end
    end
end, y); y = y + 35
createButton("Kill All", killAll, y); y = y + 35
createButton("Авто-фарм", function()
    getgenv().farming = not getgenv().farming
    if getgenv().farming then coroutine.wrap(autoFarm)() end
end, y); y = y + 35
createButton("Noclip", function()
    getgenv().noclip = not getgenv().noclip
    setNoclip(getgenv().noclip)
end, y)
