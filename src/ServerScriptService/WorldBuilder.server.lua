-- WorldBuilder.server.lua
-- AETHER RIFT: RELIC ASCENT — builds the whole world once at server start.
-- Repo: https://github.com/durov001/aether-rift-relic-ascent
-- Luau, Roblox services only, no external assets.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local AetherWorld = Instance.new("Folder")
AetherWorld.Name = "AetherWorld"
AetherWorld.Parent = Workspace

-- Generic part factory: anchored, smooth surfaces, parented to AetherWorld.
local function createPart(props)
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		if key ~= "Parent" then
			part[key] = value
		end
	end
	part.Parent = props.Parent or AetherWorld
	return part
end

-- ATM fix (2026-11-15): NO BillboardGui text anywhere in the 3D world.
-- Top-1 "Lantern Drift" shows zero floating text: all info lives in the HUD.
-- The old ~30 AlwaysOnTop billboards stacked and overlapped from every angle,
-- and bled through the semi-transparent menu. Zone names live in the HUD
-- obby bar; pad costs are in the menu; claim/buy feedback is via NotifyEvent.

-- ============ Lighting / atmosphere ============
-- Dusk sky like the top entry: purple-blue dusk, warm fog, soft bloom.
Lighting.ClockTime = 18.0
Lighting.Brightness = 2.4
Lighting.Ambient = Color3.fromRGB(55, 48, 88)
Lighting.OutdoorAmbient = Color3.fromRGB(85, 72, 125)
Lighting.FogEnd = 800
Lighting.FogColor = Color3.fromRGB(22, 18, 48)

local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.32
atmosphere.Offset = 0
atmosphere.Color = Color3.fromRGB(72, 58, 130)
atmosphere.Decay = Color3.fromRGB(32, 22, 64)
atmosphere.Glare = 0.25
atmosphere.Haze = 2.5
atmosphere.Parent = Lighting

local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.65
bloom.Size = 24
bloom.Threshold = 1.1
bloom.Parent = Lighting

-- ============ Central Plaza ============
createPart({
	Name = "CentralPlaza",
	Size = Vector3.new(140, 6, 140),
	Position = Vector3.new(0, -3, 0),
	Color = Color3.fromRGB(24, 28, 42),
	Material = Enum.Material.SmoothPlastic,
})

-- Neon trim ring around the plaza edges
local trimColor = Color3.fromRGB(0, 240, 255)
createPart({ Name = "PlazaTrimNorth", Size = Vector3.new(142, 1.5, 2), Position = Vector3.new(0, 0.2, -70), Color = trimColor, Material = Enum.Material.Neon })
createPart({ Name = "PlazaTrimSouth", Size = Vector3.new(142, 1.5, 2), Position = Vector3.new(0, 0.2, 70), Color = trimColor, Material = Enum.Material.Neon })
createPart({ Name = "PlazaTrimWest", Size = Vector3.new(2, 1.5, 142), Position = Vector3.new(-70, 0.2, 0), Color = trimColor, Material = Enum.Material.Neon })
createPart({ Name = "PlazaTrimEast", Size = Vector3.new(2, 1.5, 142), Position = Vector3.new(70, 0.2, 0), Color = trimColor, Material = Enum.Material.Neon })

-- ============ Atmosphere decor (ATM: make the world a PLACE, not a test map) ============
-- Stone path: spawn -> monolith -> obby gate.
for i = 0, 5 do
	createPart({
		Name = "PathStone_" .. i,
		Size = Vector3.new(7, 0.4, 5),
		Position = Vector3.new(0, 0.25, -4 - i * 4.2),
		Color = Color3.fromRGB(88, 92, 115),
		Material = Enum.Material.Slate,
	})
end
for i = 0, 4 do
	createPart({
		Name = "PathStoneObby_" .. i,
		Size = Vector3.new(6, 0.4, 5),
		Position = Vector3.new(-2 - i * 2.5, 0.25, -52 - i * 6),
		Color = Color3.fromRGB(88, 92, 115),
		Material = Enum.Material.Slate,
	})
end

-- Low-poly trees around the plaza rim (trunk + round canopy).
local treeSpots = {
	Vector3.new(-58, 0, -58), Vector3.new(58, 0, -58),
	Vector3.new(-62, 0, 10), Vector3.new(62, 0, 10),
	Vector3.new(-58, 0, 58), Vector3.new(58, 0, 58),
	Vector3.new(-20, 0, -62), Vector3.new(20, 0, -62),
}
for i, spot in ipairs(treeSpots) do
	local trunk = createPart({
		Name = "TreeTrunk_" .. i,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.6, 7, 1.6),
		Position = spot + Vector3.new(0, 3.5, 0),
		Color = Color3.fromRGB(74, 52, 38),
		Material = Enum.Material.Wood,
		CanCollide = false,
	})
	trunk.Orientation = Vector3.new(0, 0, 90)
	createPart({
		Name = "TreeCanopy_" .. i,
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(9, 8, 9),
		Position = spot + Vector3.new(0, 10, 0),
		Color = (i % 2 == 0) and Color3.fromRGB(46, 110, 78) or Color3.fromRGB(88, 64, 140),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
	})
end

-- Warm lantern posts ringing the plaza (glow only, no text, no lights to keep it light).
local lanternSpots = {
	Vector3.new(-30, 0, -30), Vector3.new(30, 0, -30),
	Vector3.new(-30, 0, 30), Vector3.new(30, 0, 30),
	Vector3.new(0, 0, -55), Vector3.new(0, 0, 55),
}
for i, spot in ipairs(lanternSpots) do
	createPart({
		Name = "LanternPost_" .. i,
		Size = Vector3.new(0.8, 6, 0.8),
		Position = spot + Vector3.new(0, 3, 0),
		Color = Color3.fromRGB(40, 42, 58),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
	})
	createPart({
		Name = "LanternGlow_" .. i,
		Size = Vector3.new(2.6, 2.6, 2.6),
		Position = spot + Vector3.new(0, 7, 0),
		Color = Color3.fromRGB(255, 198, 90),
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
end

-- Glowing crystals clustered near the monolith.
local crystalColors = {
	Color3.fromRGB(0, 255, 220), Color3.fromRGB(180, 90, 255),
	Color3.fromRGB(255, 195, 40), Color3.fromRGB(0, 230, 255),
	Color3.fromRGB(255, 85, 145),
}
for i, color in ipairs(crystalColors) do
	local angle = i * 1.25
	createPart({
		Name = "Crystal_" .. i,
		Size = Vector3.new(2, 4 + i, 2),
		Position = Vector3.new(math.sin(angle) * 12, 2, -24 + math.cos(angle) * 12),
		Orientation = Vector3.new(12 * i, 0, -8 * i),
		Color = color,
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
end

-- ============ Spawn ============
local spawn = Instance.new("SpawnLocation")
spawn.Name = "MainSpawn"
spawn.Size = Vector3.new(14, 1, 14)
spawn.Position = Vector3.new(0, 0.5, 0)
spawn.Neutral = true
spawn.Color = Color3.fromRGB(0, 210, 255)
spawn.Material = Enum.Material.Neon
spawn.Anchored = true
spawn.TopSurface = Enum.SurfaceType.Smooth
spawn.BottomSurface = Enum.SurfaceType.Smooth
spawn.Parent = AetherWorld

-- ============ Aether Monolith (clickable core) ============
local monolith = createPart({
	Name = "AetherMonolith",
	Shape = Enum.PartType.Ball,
	Size = Vector3.new(9, 9, 9),
	Position = Vector3.new(0, 8, -24),
	Color = Color3.fromRGB(0, 255, 220),
	Material = Enum.Material.Neon,
})
local clickDetector = Instance.new("ClickDetector")
clickDetector.MaxActivationDistance = 32
clickDetector.Parent = monolith
-- No billboard: the glowing core + menu instructions explain the click.

-- Levitation loop: bob up/down and spin slowly.
task.spawn(function()
	local baseY = monolith.Position.Y
	local t = 0
	while monolith.Parent do
		t += 0.03
		local pos = monolith.Position
		monolith.Position = Vector3.new(pos.X, baseY + math.sin(t) * 1.4, pos.Z)
		monolith.Orientation = Vector3.new(0, monolith.Orientation.Y + 1.2, 0)
		task.wait(0.03)
	end
end)

-- ============ Orb field ============
local orbFolder = Instance.new("Folder")
orbFolder.Name = "CollectibleOrbs"
orbFolder.Parent = AetherWorld

local orbPositions = {
	Vector3.new(-22, 3, -15), Vector3.new(22, 3, -15),
	Vector3.new(-35, 3, 0), Vector3.new(35, 3, 0),
	Vector3.new(-22, 3, 25), Vector3.new(22, 3, 25),
	Vector3.new(0, 3, 38), Vector3.new(-45, 3, -35),
	Vector3.new(45, 3, -35), Vector3.new(-45, 3, 35),
	Vector3.new(45, 3, 35), Vector3.new(0, 3, -48),
}
for i, pos in ipairs(orbPositions) do
	local isSuper = (i % 4 == 0)
	local orb = createPart({
		Name = isSuper and "SuperAetherOrb" or "AetherOrb",
		Shape = Enum.PartType.Ball,
		Size = isSuper and Vector3.new(4.2, 4.2, 4.2) or Vector3.new(2.8, 2.8, 2.8),
		Position = pos,
		Color = isSuper and Color3.fromRGB(255, 195, 40) or Color3.fromRGB(0, 245, 255),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = orbFolder,
	})
	-- GameManager reads Value to scale the orb reward; Super orbs pay 50.
	orb:SetAttribute("Value", isSuper and 50 or 15)
end

-- ============ Sky Obby (16-stage spiral) ============
local obbyFolder = Instance.new("Folder")
obbyFolder.Name = "SkyObby"
obbyFolder.Parent = AetherWorld

for i = 1, 16 do
	local angle = i * 0.42
	local radius = 16
	local x = math.sin(angle) * radius
	local y = 3 + i * 4.5
	local z = -82 - i * 8.5
	local zone = GameConfig.getZoneForStage(i)
	local isCheckpoint = (i % 4 == 0)
	local isSummit = (i == 16)

	local step = createPart({
		Name = isSummit and "ObbySummit" or ("ObbyStep_" .. i),
		Size = isSummit and Vector3.new(20, 2, 20)
			or (isCheckpoint and Vector3.new(12, 1.5, 12) or Vector3.new(8, 1.5, 8)),
		Position = Vector3.new(x, y, z),
		Color = isSummit and Color3.fromRGB(255, 195, 40) or zone.Color,
		Material = isSummit and Enum.Material.Neon or Enum.Material.SmoothPlastic,
		Parent = obbyFolder,
	})

	if isCheckpoint or isSummit then
		step:SetAttribute("Reward", isSummit and GameConfig.OBBY_SUMMIT_REWARD or GameConfig.OBBY_CHECKPOINT_REWARD)
		step:SetAttribute("StageId", i)
		step:SetAttribute("ZoneName", zone.Name)
		-- No billboard: the zone shows in the HUD obby bar; the summit's gold
		-- neon platform + the victory screen announce the reward.
	end
end

-- ============ Tycoon plots ============
local plotFolder = Instance.new("Folder")
plotFolder.Name = "TycoonPlots"
plotFolder.Parent = AetherWorld

local plotDefs = {
	{ Name = "Plot_Alpha", Center = Vector3.new(-105, 0, -25), Color = Color3.fromRGB(0, 230, 255) },
	{ Name = "Plot_Beta", Center = Vector3.new(105, 0, -25), Color = Color3.fromRGB(255, 85, 145) },
	{ Name = "Plot_Gamma", Center = Vector3.new(-105, 0, 45), Color = Color3.fromRGB(120, 255, 110) },
	{ Name = "Plot_Delta", Center = Vector3.new(105, 0, 45), Color = Color3.fromRGB(255, 195, 55) },
}

for _, def in ipairs(plotDefs) do
	local plot = Instance.new("Model")
	plot.Name = def.Name
	plot:SetAttribute("OwnerUserId", 0)
	plot.Parent = plotFolder

	createPart({
		Name = "PlotFloor",
		Size = Vector3.new(54, 2, 54),
		Position = def.Center + Vector3.new(0, -1, 0),
		Color = Color3.fromRGB(30, 35, 52),
		Material = Enum.Material.SmoothPlastic,
		Parent = plot,
	})

	local claimPad = createPart({
		Name = "ClaimPad",
		Size = Vector3.new(10, 1.2, 10),
		Position = def.Center + Vector3.new(0, 0.6, -20),
		Color = def.Color,
		Material = Enum.Material.Neon,
		Parent = plot,
	})
	-- No OwnerGui billboard: claim feedback comes via NotifyEvent ("Tycoon Claimed!").

	for _, padDef in ipairs(GameConfig.TYCOON_PADS) do
		local pad = createPart({
			Name = padDef.Id,
			Size = padDef.Size,
			Position = def.Center + padDef.Offset,
			Color = padDef.Color,
			Material = Enum.Material.Neon,
			Parent = plot,
		})
		pad:SetAttribute("Cost", padDef.Cost)
		pad:SetAttribute("Rate", padDef.Rate)
		pad:SetAttribute("DisplayName", padDef.Name)
		pad:SetAttribute("VisualHeight", padDef.VisualHeight)
		pad:SetAttribute("Purchased", false)
		-- No PadGui billboard: pad costs are listed in the start menu; buy
		-- feedback comes via NotifyEvent ("Built X! (+Y/s)").
	end
end

print("[AetherRift] WorldBuilder ready.")
