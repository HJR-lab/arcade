-- HUD + shop. Builds its UI in code so no Studio assets are required.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("ObbyRemotes")
local resetEvent = remotes:WaitForChild("ResetToCheckpoint")

local gui = Instance.new("ScreenGui")
gui.Name = "ObbyUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function makeButton(text, color, parent)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -16, 0, 38)
	btn.BackgroundColor3 = color
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 16
	btn.Text = text
	btn.AutoButtonColor = true
	btn.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn
	return btn
end

-- HUD ------------------------------------------------------------------------

local hud = Instance.new("TextLabel")
hud.Size = UDim2.new(0, 240, 0, 44)
hud.Position = UDim2.new(0.5, -120, 0, 12)
hud.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
hud.BackgroundTransparency = 0.2
hud.TextColor3 = Color3.fromRGB(255, 255, 255)
hud.Font = Enum.Font.GothamBold
hud.TextSize = 18
hud.Text = "Stage 0   |   0 Coins"
hud.Parent = gui
local hudCorner = Instance.new("UICorner")
hudCorner.CornerRadius = UDim.new(0, 10)
hudCorner.Parent = hud

local function bindStats()
	local leaderstats = player:WaitForChild("leaderstats")
	local stage = leaderstats:WaitForChild("Stage")
	local coins = leaderstats:WaitForChild("Coins")
	local function update()
		hud.Text = string.format("Stage %d   |   %d Coins", stage.Value, coins.Value)
	end
	stage.Changed:Connect(update)
	coins.Changed:Connect(update)
	update()
end
task.spawn(bindStats)

-- Side buttons ---------------------------------------------------------------

local resetBtn = makeButton("Reset to Checkpoint", Color3.fromRGB(200, 70, 70), gui)
resetBtn.Size = UDim2.new(0, 180, 0, 38)
resetBtn.Position = UDim2.new(0, 16, 1, -58)
resetBtn.MouseButton1Click:Connect(function()
	resetEvent:FireServer()
end)

local shopToggle = makeButton("Shop", Color3.fromRGB(70, 130, 220), gui)
shopToggle.Size = UDim2.new(0, 110, 0, 38)
shopToggle.Position = UDim2.new(1, -126, 1, -58)

-- Shop panel -----------------------------------------------------------------

local shop = Instance.new("Frame")
shop.Size = UDim2.new(0, 260, 0, 230)
shop.Position = UDim2.new(1, -276, 1, -300)
shop.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
shop.Visible = false
shop.Parent = gui
local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 12)
shopCorner.Parent = shop

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = shop

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.Parent = shop

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -16, 0, 28)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Text = "Shop"
title.Parent = shop

shopToggle.MouseButton1Click:Connect(function()
	shop.Visible = not shop.Visible
end)

local function promptProduct(id)
	if id == 0 then
		warn("Product ID not set in Config.lua")
		return
	end
	MarketplaceService:PromptProductPurchase(player, id)
end

local vipBtn = makeButton("Buy VIP (2x Coins)", Color3.fromRGB(230, 170, 40), shop)
vipBtn.MouseButton1Click:Connect(function()
	if Config.GamePasses.VIP == 0 then
		warn("VIP game pass ID not set in Config.lua")
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, Config.GamePasses.VIP)
end)

local skipBtn = makeButton("Skip a Stage", Color3.fromRGB(80, 170, 110), shop)
skipBtn.MouseButton1Click:Connect(function()
	promptProduct(Config.Products.SkipStage)
end)

local coinsBtn = makeButton("+1000 Coins", Color3.fromRGB(120, 100, 220), shop)
coinsBtn.MouseButton1Click:Connect(function()
	promptProduct(Config.Products.Coins1000)
end)
