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

local function createBillboardGui(parent, size, offsetY, labelText, textColor)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, size.X, 0, size.Y)
	gui.StudsOffset = Vector3.new(0, offsetY, 0)
	gui.AlwaysOnTop = true
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.4
	label.Parent = gui
	return gui, label
end

-- ============ Lighting / atmosphere ============
Lighting.ClockTime = 20.5
Lighting.Brightness = 2.2
Lighting.Ambient = Color3.fromRGB(45, 50, 75)
Lighting.OutdoorAmbient = Color3.fromRGB(65, 75, 110)
Lighting.FogEnd = 1200
Lighting.FogColor = Color3.fromRGB(18, 22, 38)

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
createBillboardGui(monolith, Vector2.new(220, 60), 7, "CLICK AETHER CORE (+Aether Energy)", Color3.fromRGB(0, 255, 220))

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
		if isSummit then
			createBillboardGui(step, Vector2.new(220, 60), 6, "SKY SUMMIT (+600 AETHER)", Color3.fromRGB(255, 195, 40))
		else
			createBillboardGui(step, Vector2.new(220, 55), 5, string.upper(zone.Name) .. " — CHECKPOINT", zone.Color)
		end
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
	local ownerGui = Instance.new("BillboardGui")
	ownerGui.Name = "OwnerGui"
	ownerGui.Size = UDim2.new(0, 220, 0, 55)
	ownerGui.StudsOffset = Vector3.new(0, 5, 0)
	ownerGui.AlwaysOnTop = true
	ownerGui.Parent = claimPad
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, 0, 1, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "STEP HERE TO CLAIM TYCOON"
	statusLabel.Font = Enum.Font.GothamBlack
	statusLabel.TextScaled = true
	statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	statusLabel.TextStrokeTransparency = 0.4
	statusLabel.Parent = ownerGui

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

		local padGui = Instance.new("BillboardGui")
		padGui.Name = "PadGui"
		padGui.Size = UDim2.new(0, 220, 0, 55)
		padGui.StudsOffset = Vector3.new(0, 4, 0)
		padGui.AlwaysOnTop = true
		padGui.Parent = pad
		local infoLabel = Instance.new("TextLabel")
		infoLabel.Name = "InfoLabel"
		infoLabel.Size = UDim2.new(1, 0, 1, 0)
		infoLabel.BackgroundTransparency = 1
		infoLabel.Text = padDef.Name .. "\nCost: " .. padDef.Cost .. " (+" .. padDef.Rate .. "/s)"
		infoLabel.Font = Enum.Font.GothamBlack
		infoLabel.TextScaled = true
		infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		infoLabel.TextStrokeTransparency = 0.4
		infoLabel.Parent = padGui
	end
end

print("[AetherRift] WorldBuilder ready.")
