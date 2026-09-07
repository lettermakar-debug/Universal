-- ServerScriptService/DevPhysics.server.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MASTER_KEY = "ROBLOX_DEV_2026"
local USER_KEY = "GUEST_ACCESS_2026"

local remotes = ReplicatedStorage:FindFirstChild("DevPhysicsRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "DevPhysicsRemotes"
	remotes.Parent = ReplicatedStorage
end

local impulseEvent = remotes:FindFirstChild("Impulse")
if not impulseEvent then
	impulseEvent = Instance.new("RemoteEvent")
	impulseEvent.Name = "Impulse"
	impulseEvent.Parent = remotes
end

local teleportEvent = remotes:FindFirstChild("Teleport")
if not teleportEvent then
	teleportEvent = Instance.new("RemoteEvent")
	teleportEvent.Name = "Teleport"
	teleportEvent.Parent = remotes
end

local access = {}

local function authenticate(player, key)
	if key == MASTER_KEY then
		access[player] = "MASTER"
		return "MASTER"
	elseif key == USER_KEY then
		access[player] = "USER"
		return "USER"
	end

	access[player] = nil
	return nil
end

-- Вызывайте authenticate из своего GUI/RemoteFunction.
-- В production-проекте лучше использовать UserId/группы,
-- а не секрет, передаваемый клиентом.

impulseEvent.OnServerEvent:Connect(function(player)
	local role = access[player]

	if role ~= "MASTER" then
		return
	end

	local rng = Random.new()

	for _, target in ipairs(Players:GetPlayers()) do
		if target ~= player then
			local character = target.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")

			if root then
				local impulse = Vector3.new(
					rng:NextNumber(-150, 150),
					rng:NextNumber(200, 400),
					rng:NextNumber(-150, 150)
				)

				root:ApplyImpulse(impulse * root.AssemblyMass)
			end
		end
	end
end)

teleportEvent.OnServerEvent:Connect(function(player)
	if access[player] ~= "MASTER" then
		return
	end

	local candidates = {}

	for _, target in ipairs(Players:GetPlayers()) do
		if target ~= player
			and target.Character
			and target.Character:FindFirstChild("HumanoidRootPart") then
			table.insert(candidates, target)
		end
	end

	if #candidates == 0 then
		return
	end

	local target = candidates[math.random(1, #candidates)]
	local targetRoot = target.Character.HumanoidRootPart
	local ownRoot = player.Character and
		player.Character:FindFirstChild("HumanoidRootPart")

	if ownRoot then
		ownRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 3, 0)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	access[player] = nil
end)
