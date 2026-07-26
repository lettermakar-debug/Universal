-- MM2 HUB UPDATE - COMPLETE VERSION WITH PLAYER MENU & WORKING BUTTONS
-- Discord: discord.gg/v8ZPq4y2nD

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

-- VARIABLES
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

-- ESP COLORS
local ESP_TEAM_COLORS = {
    Murderer = Color3.fromRGB(255, 0, 0),
    Sheriff = Color3.fromRGB(0, 100, 255),
    Innocent = Color3.fromRGB(0, 255, 0)
}

-- FUNCTION TO GET PLAYER ROLE
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

-- CLEAR ESP
local function clearESP()
    for _, v in pairs(espObjects) do
        pcall(function() v:Destroy() end)
    end
    espObjects = {}
end

-- CREATE ESP
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

-- UPDATE ESP
local function updateESP()
    clearESP()
    if not espEnabled then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            createESP(player)
        end
    end
end

-- CREATE FOV
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

-- GET CLOSEST PLAYER FOR AIM
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

-- GET CLOSEST COIN
local function getClosestCoin()
    local closest = nil
    local shortestDistance = math.huge
    
    for _, item in pairs(Workspace:GetDescendants()) do
        if item:IsA("Part") and item.Name == "Coin" and item.Parent then
            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local distance = (root.Position - item.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closest = item
                end
            end
        end
    end
    return closest
end

-- GET ALL COINS
local function getAllCoins()
    local coins = {}
    for _, item in pairs(Workspace:GetDescendants()) do
        if item:IsA("Part") and item.Name == "Coin" and item.Parent then
            table.insert(coins, item)
        end
    end
    return coins
end

-- TELEPORT FUNCTIONS
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

-- SPEED
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

-- JUMP
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

-- GOD MODE
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

-- ANTI FLING
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

-- AUTO FARM
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

-- FLING PLAYER
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

-- CREATE PLAYER MENU
local function createPlayerMenu()
    if playerMenuOpen then
        return
    end
    
    playerMenuOpen = true
    
    local menuFrame = Instance.new("Frame")
    menuFrame.Size = UDim2.new(0, 350, 0, 450)
    menuFrame.Position = UDim2.new(0.5, -175, 0.5, -225)
    menuFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    menuFrame.BackgroundTransparency = 0.1
    menuFrame.BorderSizePixel = 0
    menuFrame.Parent = screenGui
    
    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 12)
    menuCorner.Parent = menuFrame
    
    local menuTitle = Instance.new("TextLabel")
    menuTitle.Size = UDim2.new(1, 0, 0, 45)
    menuTitle.Position = UDim2.new(0, 0, 0, 0)
    menuTitle.BackgroundColor3 = Color3.fromRGB(50, 50, 75)
    menuTitle.Text = "👥 Player List"
    menuTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    menuTitle.TextScaled = true
    menuTitle.Font = Enum.Font.GothamBold
    menuTitle.BorderSizePixel = 0
    menuTitle.Parent = menuFrame
    
    local closeMenuBtn = Instance.new("TextButton")
    closeMenuBtn.Size = UDim2.new(0, 35, 0, 35)
    closeMenuBtn.Position = UDim2.new(1, -40, 0, 5)
    closeMenuBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    closeMenuBtn.Text = "✕"
    closeMenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeMenuBtn.TextScaled = true
    closeMenuBtn.BorderSizePixel = 0
    closeMenuBtn.Parent = menuFrame
    closeMenuBtn.MouseButton1Click:Connect(function()
        menuFrame:Destroy()
        playerMenuOpen = false
    end)
    
    local searchBar = Instance.new("TextBox")
    searchBar.Size = UDim2.new(1, -20, 0, 35)
    searchBar.Position = UDim2.new(0, 10, 0, 50)
    searchBar.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    searchBar.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBar.PlaceholderText = "🔍 Search players..."
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
    
    -- Function to update player list
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
                    playerBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
                    playerBtn.Text = player.Name .. "  [" .. role .. "]"
                    playerBtn.TextColor3 = color
                    playerBtn.TextScaled = true
                    playerBtn.Font = Enum.Font.Gotham
                    playerBtn.BorderSizePixel = 0
                    playerBtn.Parent = scrollFrame
                    
                    -- Hover effect
                    playerBtn.MouseEnter:Connect(function()
                        playerBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
                    end)
                    playerBtn.MouseLeave:Connect(function()
                        playerBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
                    end)
                    
                    -- Teleport on click
                    playerBtn.MouseButton1Click:Connect(function()
                        teleportToPlayer(player)
                        menuFrame:Destroy()
                        playerMenuOpen = false
                    end)
                    
                    -- Right click for fling
                    playerBtn.MouseButton2Click:Connect(function()
                        flingPlayer(player)
                        menuFrame:Destroy()
                        playerMenuOpen = false
                    end)
                end
            end
        end
    end
    
    -- Initial update
    updatePlayerList("")
    
    -- Search functionality
    searchBar.Changed:Connect(function()
        updatePlayerList(searchBar.Text)
    end)
    
    -- Update when players change
    Players.PlayerAdded:Connect(function()
        updatePlayerList(searchBar.Text)
    end)
    
    Players.PlayerRemoving:Connect(function()
        updatePlayerList(searchBar.Text)
    end)
end

-- CREATE GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MM2HUBUPDATE"
screenGui.Parent = game.CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 550, 0, 720)
mainFrame.Position = UDim2.new(0.5, -275, 0.5, -360)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- TITLE BAR
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 45)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

-- TITLE
local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.7, 0, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "MM2 HUB UPDATE"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.BorderSizePixel = 0
title.Parent = titleBar

-- MINIMIZE BUTTON
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 35, 0, 35)
minimizeBtn.Position = UDim2.new(1, -75, 0, 5)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
minimizeBtn.Text = "━"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.TextScaled = true
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = titleBar

minimizeBtn.MouseEnter:Connect(function()
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 220, 50)
end)
minimizeBtn.MouseLeave:Connect(function()
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
end)

-- CLOSE BUTTON
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -38, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled = true
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

closeBtn.MouseEnter:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
end)
closeBtn.MouseLeave:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
end)

-- CONTENT CONTAINER
local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, 0, 1, -45)
contentContainer.Position = UDim2.new(0, 0, 0, 45)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainFrame

-- TOGGLE MINIMIZE
local function toggleMinimize()
    isMinimized = not isMinimized
    
    if isMinimized then
        mainFrame:TweenSize(UDim2.new(0, 550, 0, 45), "Out", "Quad", 0.3, true)
        contentContainer.Visible = false
        minimizeBtn.Text = "□"
        minimizeBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        mainFrame:TweenSize(UDim2.new(0, 550, 0, 720), "Out", "Quad", 0.3, true)
        wait(0.35)
        contentContainer.Visible = true
        minimizeBtn.Text = "━"
        minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
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

-- CREATE TAB FUNCTION
local function createTab(name, y)
    local tab = Instance.new("TextButton")
    tab.Size = UDim2.new(0, 100, 0, 30)
    tab.Position = UDim2.new(0, 10, 0, y)
    tab.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    tab.Text = name
    tab.TextColor3 = Color3.fromRGB(255, 255, 255)
    tab.TextScaled = true
    tab.BorderSizePixel = 0
    tab.Parent = contentContainer
    return tab
end

-- CREATE SECTION FUNCTION
local function createSection(name, parent)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, -20, 0, 570)
    section.Position = UDim2.new(0, 10, 0, 80)
    section.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    section.BackgroundTransparency = 0.5
    section.BorderSizePixel = 0
    section.Visible = false
    section.Parent = parent or contentContainer
    
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

-- CREATE BUTTON FUNCTION
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

-- CREATE TOGGLE FUNCTION
local function createToggle(text, callback, parent)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 35)
    frame.BackgroundTransparency = 1
    frame.Parent = parent.scroll
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
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

-- CREATE SLIDER FUNCTION
local function createSlider(text, min, max, default, callback, parent)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 45)
    frame.BackgroundTransparency = 1
    frame.Parent = parent.scroll
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(default)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local slider = Instance.new("TextButton")
    slider.Size = UDim2.new(1, 0, 0, 20)
    slider.Position = UDim2.new(0, 0, 0, 22)
    slider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    slider.Text = ""
    slider.BorderSizePixel = 0
    slider.Parent = frame
    
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

-- CREATE TABS
local tabs = {}

local mainSection = createSection("Main", contentContainer)
tabs["Main"] = mainSection
mainSection.section.Visible = true

local aimSection = createSection("Aim", contentContainer)
tabs["Aim"] = aimSection

local teleportSection = createSection("Teleport", contentContainer)
tabs["Teleport"] = teleportSection

local farmSection = createSection("Farm", contentContainer)
tabs["Farm"] = farmSection

local miscSection = createSection("Misc", contentContainer)
tabs["Misc"] = miscSection

-- TAB BUTTONS
local tabNames = {"Main", "Aim", "Teleport", "Farm", "Misc"}
for i, name in ipairs(tabNames) do
    local btn = createTab(name, 45 + (i-1) * 35)
    btn.MouseButton1Click:Connect(function()
        for _, section in pairs(tabs) do
            section.section.Visible = false
        end
        tabs[name].section.Visible = true
    end)
end

-- MAIN TAB
createButton("Update ESP", function()
    updateESP()
end, mainSection)

createToggle("ESP Enabled", function(state)
    espEnabled = state
    if state then
        updateESP()
    else
        clearESP()
    end
end, mainSection)

createToggle("Speed x2", function(state)
    setSpeed(state)
end, mainSection)

createToggle("Super Jump", function(state)
    setJumpPower(state)
end, mainSection)

createToggle("Anti Fling", function(state)
    toggleAntiFling(state)
end, mainSection)

createToggle("God Mode", function(state)
    toggleGodMode(state)
end, mainSection)

-- AIM TAB
createToggle("Aimbot", function(state)
    aimbotEnabled = state
end, aimSection)

createToggle("Silent Aim", function(state)
    silentAimEnabled = state
end, aimSection)

createToggle("Auto Shoot", function(state)
    autoShootEnabled = state
end, aimSection)

createToggle("Show FOV", function(state)
    showFOV = state
    createFOV()
end, aimSection)

createSlider("FOV Size", 50, 500, 200, function(value)
    fovSize = value
    if fovCircle then
        fovCircle.Radius = value
    end
end, aimSection)

-- TELEPORT TAB
createButton("Teleport To Murderer", function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and getPlayerRole(player) == "Murderer" then
            teleportToPlayer(player)
            break
        end
    end
end, teleportSection)

createButton("Teleport To Sheriff", function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and getPlayerRole(player) == "Sheriff" then
            teleportToPlayer(player)
            break
        end
    end
end, teleportSection)

createButton("Teleport To Gun", function()
    local gun = getGun()
    if gun then
        gun.Parent = LocalPlayer.Character
    end
end, teleportSection)

createButton("Teleport To Coin", function()
    local coin = getClosestCoin()
    if coin then
        teleportToPosition(coin.Position)
    end
end, teleportSection)

createButton("Teleport To Safe Zone", function()
    teleportToPosition(Vector3.new(0, 10, 0))
end, teleportSection)

createButton("Teleport To Lobby", function()
    teleportToPosition(Vector3.new(0, 0, 0))
end, teleportSection)

-- FARM TAB
createToggle("Auto Farm Coins", function(state)
    toggleAutoFarm(state)
end, farmSection)

createToggle("Knife Aura", function(state)
    knifeAuraEnabled = state
end, farmSection)

createButton("Throw Knife", function()
    local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
    if tool then tool:Activate() end
end, farmSection)

-- MISC TAB
createButton("👥 Open Player Menu", function()
    createPlayerMenu()
end, miscSection)

createButton("Fling Murderer", function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and getPlayerRole(player) == "Murderer" then
            flingPlayer(player)
            break
        end
    end
end, miscSection)

createButton("Fling Sheriff", function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and getPlayerRole(player) == "Sheriff" then
            flingPlayer(player)
            break
        end
    end
end, miscSection)

createButton("Fling All Players", function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            flingPlayer(player)
            wait(0.2)
        end
    end
end, miscSection)

-- MAIN LOOP
RunService.Heartbeat:Connect(function()
    -- Aimbot
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
    
    -- Update FOV
    if fovCircle then
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    end
    
    -- Knife Aura
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
    
    -- Auto Shoot
    if autoShootEnabled then
        local target = getClosestPlayer()
        if target and target.Character then
            target.Character.Humanoid.Health = 0
        end
    end
    
    -- Update Speed
    if speedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if LocalPlayer.Character.Humanoid.WalkSpeed ~= 32 then
            LocalPlayer.Character.Humanoid.WalkSpeed = 32
        end
    end
    
    -- Update Jump
    if jumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if LocalPlayer.Character.Humanoid.JumpPower ~= 100 then
            LocalPlayer.Character.Humanoid.JumpPower = 100
        end
    end
end)

-- UPDATE ESP ON NEW PLAYERS
Players.PlayerAdded:Connect(function()
    wait(1)
    if espEnabled then updateESP() end
end)

-- UPDATE ESP COLORS ON ROLE CHANGE
