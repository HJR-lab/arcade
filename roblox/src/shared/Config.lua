-- Central configuration for the obby game.
--
-- IMPORTANT: the GamePass / Product IDs below are placeholders (0).
-- Create them in the Creator Dashboard (Monetization > Passes and
-- Monetization > Developer Products) for THIS game, then paste the
-- numeric IDs here. A purchase prompt only appears once the ID is real.

local Config = {}

Config.Stages = {
	Count = 25, -- number of obby stages generated after the spawn pad
	PlatformSize = Vector3.new(12, 1, 12),
	Gap = 9, -- horizontal distance between platforms
	HeightStep = 3, -- each stage rises this many studs
}

Config.Economy = {
	CoinsPerStage = 10,
	VipMultiplier = 2, -- VIP game pass owners earn this much per stage
	Coins1000Amount = 1000, -- granted by the Coins1000 developer product
}

-- One-time purchases.
Config.GamePasses = {
	VIP = 0,
}

-- Repeatable / consumable purchases.
Config.Products = {
	SkipStage = 0, -- teleport the buyer forward one stage
	Coins1000 = 0, -- grant Config.Economy.Coins1000Amount coins
}

return Config
