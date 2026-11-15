-- GameConfig.lua
-- AETHER RIFT: RELIC ASCENT — shared tuning constants (ModuleScript)
-- Repo: https://github.com/durov001/aether-rift-relic-ascent
-- Luau, Roblox services only, no external assets.

local GameConfig = {}

GameConfig.GAME_TITLE = "AETHER RIFT: RELIC ASCENT"
GameConfig.VERSION = "1.0.0"

-- Core economy
GameConfig.BASE_CLICK_REWARD = 5
GameConfig.REBIRTH_BASE_COST = 500
GameConfig.REBIRTH_MULTIPLIER_STEP = 1.75
GameConfig.OBBY_CHECKPOINT_REWARD = 75
GameConfig.OBBY_SUMMIT_REWARD = 600
GameConfig.ORB_RESPAWN_TIME = 6
GameConfig.AURA_ROLL_COST = 150

-- Dash movement
GameConfig.DASH_COOLDOWN = 2.5
GameConfig.DASH_SPEED = 80
GameConfig.DASH_DURATION = 0.18

-- Orb combo system
GameConfig.COMBO_WINDOW = 3
GameConfig.COMBO_STEP = 0.25
GameConfig.COMBO_MAX_MULT = 3.0

-- Tycoon upgrade pads (5 tiers, bought in order of rising cost/rate)
GameConfig.TYCOON_PADS = {
	{
		Id = "Pad1_Collector",
		Name = "Aether Core Collector",
		Cost = 0,
		Rate = 4,
		Color = Color3.fromRGB(0, 255, 200),
		Offset = Vector3.new(-14, 0.5, -10),
		Size = Vector3.new(8, 1, 8),
		VisualHeight = 6,
	},
	{
		Id = "Pad2_CrystalExtractor",
		Name = "Crystal Vein Extractor",
		Cost = 50,
		Rate = 12,
		Color = Color3.fromRGB(85, 170, 255),
		Offset = Vector3.new(14, 0.5, -10),
		Size = Vector3.new(8, 1, 8),
		VisualHeight = 10,
	},
	{
		Id = "Pad3_QuantumForge",
		Name = "Quantum Relic Forge",
		Cost = 200,
		Rate = 35,
		Color = Color3.fromRGB(185, 95, 255),
		Offset = Vector3.new(-14, 0.5, 10),
		Size = Vector3.new(8, 1, 8),
		VisualHeight = 14,
	},
	{
		Id = "Pad4_VoidReactor",
		Name = "Void Singularity Reactor",
		Cost = 750,
		Rate = 110,
		Color = Color3.fromRGB(255, 195, 45),
		Offset = Vector3.new(14, 0.5, 10),
		Size = Vector3.new(8, 1, 8),
		VisualHeight = 18,
	},
	{
		Id = "Pad5_CelestialSpire",
		Name = "Celestial Ascension Spire",
		Cost = 2500,
		Rate = 350,
		Color = Color3.fromRGB(255, 75, 130),
		Offset = Vector3.new(0, 0.5, 18),
		Size = Vector3.new(12, 1, 10),
		VisualHeight = 26,
	},
}

-- Gacha auras: weighted roll, higher multiplier = rarer
GameConfig.AURAS = {
	{ Name = "Spark Wisp", Multiplier = 1.25, Weight = 50, Color = Color3.fromRGB(120, 230, 255) },
	{ Name = "Solar Flare", Multiplier = 1.60, Weight = 30, Color = Color3.fromRGB(255, 180, 50) },
	{ Name = "Void Phantom", Multiplier = 2.25, Weight = 15, Color = Color3.fromRGB(190, 90, 255) },
	{ Name = "Chronos Crown", Multiplier = 3.50, Weight = 5, Color = Color3.fromRGB(255, 65, 110) },
}

-- Sky obby zones: 16 stages split into 4 themed bands
GameConfig.OBBY_ZONES = {
	{ Name = "Ember Rise", FirstStage = 1, LastStage = 4, Color = Color3.fromRGB(255, 120, 40) },
	{ Name = "Crystal Span", FirstStage = 5, LastStage = 8, Color = Color3.fromRGB(0, 200, 255) },
	{ Name = "Void Steps", FirstStage = 9, LastStage = 12, Color = Color3.fromRGB(170, 90, 255) },
	{ Name = "Celestial Summit", FirstStage = 13, LastStage = 16, Color = Color3.fromRGB(255, 200, 45) },
}

-- Returns the zone table containing the given stage number, or nil.
function GameConfig.getZoneForStage(stage)
	for _, zone in ipairs(GameConfig.OBBY_ZONES) do
		if stage >= zone.FirstStage and stage <= zone.LastStage then
			return zone
		end
	end
	return nil
end

-- Returns the aura table matching the given name, or nil.
function GameConfig.getAuraByName(auraName)
	for _, aura in ipairs(GameConfig.AURAS) do
		if aura.Name == auraName then
			return aura
		end
	end
	return nil
end

return GameConfig
