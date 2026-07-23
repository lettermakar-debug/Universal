-- Обёртка для безопасности
local script = {}

-- Подключаем сервисы
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

-- Настройки (меняй здесь)
local config = {
    espEnabled = true,          -- Включить ESP
    flingEnabled = true,        -- Включить Touch Fling
    teamCheck = false,          -- Игнорировать свою команду
    flingPower = 3000,          -- Мощность флинга (3000-5000)
    espColor = Color3.new(1, 0, 0), -- Красный для врагов
    espTeamColor = Color3.new(0, 0, 1) -- Синий для союзников
}

-- Хранилище объектов ESP
local espObjects = {}

-- Функция создания текстовой метки (BillboardGui)
local function createLabel(player)
    local gui = Instance.new("BillboardGui")
    gui.Name = "ESP_" .. player.Name
    gui.Size = UDim2.new(0, 200, 0, 50)
    gui.Adornee = player.Character and player.Character:FindFirstChild("Head")
    gui.MaxDistance = 1000
    gui.AlwaysOnTop = true
    gui.ResetOnSpawn = false
    
    local label = Instance.new("TextLabel")
    label.Name = "NameLabel"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = player.Name
    label.TextColor3 = config.espColor
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = gui
    
    gui.Parent = game:GetService("CoreGui")
    return gui
end

-- Функция обновления ESP
local function updateESP()
    if not config.espEnabled then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            local character = player.Character
            if character and character:FindFirstChild("Head") then
                -- Если нет метки, создаём
                if not espObjects[player.UserId] then
                    espObjects[player.UserId] = createLabel(player)
                end
                
                -- Обновляем цвет в зависимости от команды (если включено)
                if config.teamCheck then
                    local isTeammate = (player.Team == Players.LocalPlayer.Team)
                    espObjects[player.UserId].TextLabel.TextColor3 = isTeammate and config.espTeamColor or config.espColor
                else
                    espObjects[player.UserId].TextLabel.TextColor3 = config.espColor
                end
                
                -- Привязываем к голове
                espObjects[player.UserId].Adornee = character.Head
            else
                -- Если персонаж умер или нет головы, скрываем
                if espObjects[player.UserId] then
                    espObjects[player.UserId].Adornee = nil
                end
            end
        end
    end
end

-- Функция удаления ESP при выходе игрока
local function removeESP(player)
    if espObjects[player.UserId] then
        espObjects[player.UserId]:Destroy()
        espObjects[player.UserId] = nil
    end
end

-- Функция Touch Fling (при касании экрана)
local function setupFling()
    if not config.flingEnabled then return end
    
    UserInputService.TouchEnabled = true -- Принудительно включаем поддержку тача
    
    UserInputService.TouchStarted:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- Находим ближайшего игрока к месту касания (опционально)
        local localChar = Players.LocalPlayer.Character
        if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return end
        
        local torso = localChar.HumanoidRootPart
        local flingForce = Instance.new("LinearVelocity")
        flingForce.MaxForce = Vector3.new(1e9, 1e9, 1e9) -- Огромная сила
        flingForce.VectorVelocity = Vector3.new(0, config.flingPower, 0) -- Вверх
        flingForce.VelocityConstraintMode = Enum.VelocityConstraintMode.Linear
        flingForce.Parent = torso
        
        -- Уничтожаем через 0.1 сек, чтобы не парило
        game:GetService("Debris"):AddItem(flingForce, 0.1)
        
        -- Дополнительный импульс во все стороны
        local randomDirection = Vector3.new(
            math.random(-20, 20) / 10,
            5,
            math.random(-20, 20) / 10
        )
        torso.AssemblyLinearVelocity = randomDirection * 100
    end)
end

-- Инициализация при запуске
local function init()
    -- Чистим старые объекты
    for _, obj in pairs(espObjects) do
        obj:Destroy()
    end
    espObjects = {}
    
    -- Подключаем события
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            -- Небольшая задержка для появления Head
            task.wait(0.5)
            updateESP()
        end)
    end)
    
    Players.PlayerRemoving:Connect(removeESP)
    
    -- Обновляем ESP каждый тик
    RunService.RenderStepped:Connect(function()
        updateESP()
    end)
    
    -- Включаем Fling
    setupFling()
    
    print("Скрипт антидокс загружен. ESP и Fling активны.")
end

-- Запуск с защитой от ошибок
pcall(function()
    init()
end)

-- Обработка сбоев
local function resetOnCrash()
    warn("Обнаружен сбой, перезапуск...")
    for _, obj in pairs(espObjects) do
        obj:Destroy()
    end
    espObjects = {}
    task.wait(1)
    init()
end

-- Перехват ошибок (простая страховка)
local oldInit = init
init = function()
    local success, err = pcall(oldInit)
    if not success then
        resetOnCrash()
    end
end
