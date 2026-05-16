-- Handles all Robux monetization: the VIP game pass and the
-- Skip Stage / +1000 Coins developer products.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ObbyService = require(script.Parent:WaitForChild("ObbyService"))

local purchaseHistory = DataStoreService:GetDataStore("ObbyPurchaseHistory_v1")

-- VIP game pass --------------------------------------------------------------

local function refreshVip(player)
	if Config.GamePasses.VIP == 0 then
		return
	end
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, Config.GamePasses.VIP)
	end)
	if ok then
		ObbyService.SetVip(player, owns)
	end
end

Players.PlayerAdded:Connect(refreshVip)
for _, player in Players:GetPlayers() do
	task.spawn(refreshVip, player)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
	if purchased and gamePassId == Config.GamePasses.VIP then
		ObbyService.SetVip(player, true)
	end
end)

-- Developer products ---------------------------------------------------------

local productHandlers = {}

if Config.Products.SkipStage ~= 0 then
	productHandlers[Config.Products.SkipStage] = function(player)
		ObbyService.SkipStage(player, 1)
	end
end

if Config.Products.Coins1000 ~= 0 then
	productHandlers[Config.Products.Coins1000] = function(player)
		ObbyService.AddCoins(player, Config.Economy.Coins1000Amount)
	end
end

local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player left before we could grant; try again when they return.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local key = receiptInfo.PlayerId .. "_" .. receiptInfo.PurchaseId

	local alreadyGranted
	local readOk = pcall(function()
		alreadyGranted = purchaseHistory:GetAsync(key)
	end)
	if not readOk then
		-- Couldn't verify; do not grant twice — retry later.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if alreadyGranted then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local handler = productHandlers[receiptInfo.ProductId]
	if not handler then
		warn("No handler for product " .. tostring(receiptInfo.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local grantOk = pcall(handler, player)
	if not grantOk then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local recordOk = pcall(function()
		purchaseHistory:SetAsync(key, true)
	end)
	if not recordOk then
		-- Reward already given but we couldn't record it; retrying would
		-- double-grant, so accept the purchase now.
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

MarketplaceService.ProcessReceipt = processReceipt
