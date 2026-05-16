-- Core obby logic: builds the course, tracks progress, handles coins,
-- checkpoints and persistence. Required by ObbyServer (which calls Init)
-- and by PurchaseHandler (which grants rewards).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local ObbyService = {}

-- Remotes created up-front so the client can WaitForChild them.
local remotes = Instance.new("Folder")
remotes.Name = "ObbyRemotes"
remotes.Parent = ReplicatedStorage

local resetEvent = Instance.new("RemoteEvent")
resetEvent.Name = "ResetToCheckpoint"
resetEvent.Parent = remotes

local progressStore = DataStoreService:GetDataStore("ObbyProgress_v1")

local checkpoints = {} -- [stage] = CFrame to teleport to
local sessionData = {} -- [userId] = { stage = number, coins = number }

local function loadData(player)
	local data = { stage = 0, coins = 0 }
	local ok, result = pcall(function()
		return progressStore:GetAsync("u_" .. player.UserId)
	end)
	if ok and type(result) == "table" then
		data.stage = math.clamp(tonumber(result.stage) or 0, 0, Config.Stages.Count)
		data.coins = tonumber(result.coins) or 0
	end
	sessionData[player.UserId] = data
	return data
end

local function saveData(player)
	local data = sessionData[player.UserId]
	if not data then
		return
	end
	pcall(function()
		progressStore:SetAsync("u_" .. player.UserId, { stage = data.stage, coins = data.coins })
	end)
end

local function syncLeaderstats(player)
	local data = sessionData[player.UserId]
	local leaderstats = player:FindFirstChild("leaderstats")
	if data and leaderstats then
		leaderstats.Stage.Value = data.stage
		leaderstats.Coins.Value = data.coins
	end
end

local function teleportToCheckpoint(player)
	local data = sessionData[player.UserId]
	if not data then
		return
	end
	local cf = checkpoints[data.stage] or checkpoints[0]
	local character = player.Character
	if character and cf then
		if character:FindFirstChild("HumanoidRootPart") then
			character:PivotTo(cf)
		end
	end
end

function ObbyService.GetData(player)
	return sessionData[player.UserId]
end

function ObbyService.SetVip(player, isVip)
	player:SetAttribute("VIP", isVip and true or false)
end

function ObbyService.AddCoins(player, amount)
	local data = sessionData[player.UserId]
	if not data or amount <= 0 then
		return
	end
	data.coins += amount
	syncLeaderstats(player)
	saveData(player)
end

function ObbyService.SkipStage(player, count)
	local data = sessionData[player.UserId]
	if not data then
		return
	end
	data.stage = math.clamp(data.stage + (count or 1), 0, Config.Stages.Count)
	syncLeaderstats(player)
	saveData(player)
	teleportToCheckpoint(player)
end

local function awardStage(player, stageIndex)
	local data = sessionData[player.UserId]
	if not data or stageIndex <= data.stage then
		return
	end
	local gained = stageIndex - data.stage
	data.stage = stageIndex

	local multiplier = player:GetAttribute("VIP") and Config.Economy.VipMultiplier or 1
	data.coins += gained * Config.Economy.CoinsPerStage * multiplier

	syncLeaderstats(player)
	saveData(player)
end

local function buildCourse()
	local folder = Instance.new("Folder")
	folder.Name = "ObbyCourse"
	folder.Parent = Workspace

	local origin = Vector3.new(0, 50, 0)
	local stepX = Config.Stages.Gap + Config.Stages.PlatformSize.X

	for i = 0, Config.Stages.Count do
		local platform = Instance.new("Part")
		platform.Anchored = true
		platform.Size = Config.Stages.PlatformSize
		platform.Position = origin + Vector3.new(i * stepX, i * Config.Stages.HeightStep, 0)
		platform.Material = Enum.Material.SmoothPlastic
		platform.Color = Color3.fromHSV(i / (Config.Stages.Count + 1), 0.55, 0.9)
		platform.Name = "Stage_" .. i
		platform.Parent = folder

		local topY = platform.Position.Y + Config.Stages.PlatformSize.Y / 2
		checkpoints[i] = CFrame.new(platform.Position + Vector3.new(0, Config.Stages.PlatformSize.Y / 2 + 3, 0))

		if i == 0 then
			local spawnPad = Instance.new("SpawnLocation")
			spawnPad.Anchored = true
			spawnPad.Size = Vector3.new(Config.Stages.PlatformSize.X, 0.4, Config.Stages.PlatformSize.Z)
			spawnPad.Position = Vector3.new(platform.Position.X, topY + 0.2, platform.Position.Z)
			spawnPad.Material = Enum.Material.Neon
			spawnPad.Color = Color3.fromRGB(0, 170, 255)
			spawnPad.Neutral = true
			spawnPad.Duration = 0
			spawnPad.Name = "Spawn"
			spawnPad.Parent = folder
		else
			local pad = Instance.new("Part")
			pad.Anchored = true
			pad.CanCollide = false
			pad.Size = Vector3.new(Config.Stages.PlatformSize.X, 0.4, Config.Stages.PlatformSize.Z)
			pad.Position = Vector3.new(platform.Position.X, topY + 0.2, platform.Position.Z)
			pad.Material = Enum.Material.Neon
			pad.Color = Color3.fromRGB(0, 255, 120)
			pad.Name = "Checkpoint_" .. i
			pad.Parent = folder

			local stageIndex = i
			pad.Touched:Connect(function(hit)
				local character = hit.Parent
				local hitPlayer = character and Players:GetPlayerFromCharacter(character)
				if hitPlayer then
					awardStage(hitPlayer, stageIndex)
				end
			end)
		end
	end
end

local function onCharacterAdded(player, character)
	character:WaitForChild("HumanoidRootPart")
	task.wait(0.15)
	teleportToCheckpoint(player)
end

local function onPlayerAdded(player)
	local data = loadData(player)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local stage = Instance.new("IntValue")
	stage.Name = "Stage"
	stage.Value = data.stage
	stage.Parent = leaderstats

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = data.coins
	coins.Parent = leaderstats

	leaderstats.Parent = player

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
end

local function onPlayerRemoving(player)
	saveData(player)
	sessionData[player.UserId] = nil
end

function ObbyService.Init()
	buildCourse()

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	resetEvent.OnServerEvent:Connect(function(player)
		teleportToCheckpoint(player)
	end)

	-- Periodic autosave so progress survives a server crash.
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in Players:GetPlayers() do
				saveData(player)
			end
		end
	end)

	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			saveData(player)
		end
	end)
end

return ObbyService
