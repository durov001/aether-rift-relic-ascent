-- MenuClient.client.lua -- AETHER RIFT: RELIC ASCENT start menu + victory screen.
-- The start menu shows once per session; the victory screen fires on VictoryEvent.
-- Menu layout (2026-11-15, ATM top entries): sector-select zone cards + a live
-- telemetry strip + key-chip controls, fully opaque so the 3D world never bleeds
-- through. Every number shown is real: zones, stage ranges and rewards match
-- GameConfig; telemetry reads the player's own leaderstats.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local victoryEvent = remotes:WaitForChild("VictoryEvent")

local NAVY, CYAN, GOLD, TEAL, WHITE, DIM = Color3.fromHex("121622"), Color3.fromHex("00EBFF"),
	Color3.fromHex("FFD23F"), Color3.fromHex("00C9A7"), Color3.fromHex("F2F7FF"), Color3.fromHex("9AA7C7")
local RED, PURPLE = Color3.fromHex("FF5A5A"), Color3.fromHex("B967FF")

local hasDeployed, victoryToken = false, 0

-- Instance factory: new("Frame", { Size = ..., ... }, parent)
local function new(className, props, parent)
	local inst = Instance.new(className)
	for key, value in pairs(props) do inst[key] = value end
	inst.Parent = parent
	return inst
end

local menuGui = new("ScreenGui", { Name = "AetherMenu", ResetOnSpawn = false,
	IgnoreGuiInset = true, DisplayOrder = 10 }, player:WaitForChild("PlayerGui"))

local function makeLabel(parent, name, size, position, text, textSize, color, font)
	return new("TextLabel", { Name = name, Size = size, Position = position,
		BackgroundTransparency = 1, Text = text, TextColor3 = color,
		Font = font or Enum.Font.GothamBold, TextSize = textSize }, parent)
end

local function makeButton(parent, name, size, position, text, color, textSize)
	local button = new("TextButton", { Name = name, Size = size, Position = position,
		BackgroundColor3 = color, Text = text, TextColor3 = NAVY,
		Font = Enum.Font.GothamBlack, TextSize = textSize, AutoButtonColor = true }, parent)
	new("UICorner", { CornerRadius = UDim.new(0, 12) }, button)
	return button
end

local menuFrame = new("Frame", { Name = "StartMenu", Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = NAVY, BackgroundTransparency = 0, BorderSizePixel = 0 }, menuGui)

makeLabel(menuFrame, "Title", UDim2.new(0, 700, 0, 54), UDim2.new(0.5, -350, 0, 46),
	"AETHER RIFT", 48, CYAN, Enum.Font.GothamBlack)
makeLabel(menuFrame, "Subtitle", UDim2.new(0, 700, 0, 30), UDim2.new(0.5, -350, 0, 100),
	"RELIC ASCENT", 26, GOLD, Enum.Font.GothamBlack)
makeLabel(menuFrame, "Tagline", UDim2.new(0, 700, 0, 24), UDim2.new(0.5, -350, 0, 132),
	"CLIMB THE SKY  //  CLAIM THE RELIC", 15, DIM)

-- Section header with divider lines, PRISM DRIVE style.
new("Frame", { Name = "DividerLeft", Size = UDim2.new(0, 260, 0, 2),
	Position = UDim2.new(0.5, -400, 0, 182), BackgroundColor3 = CYAN,
	BackgroundTransparency = 0.5, BorderSizePixel = 0 }, menuFrame)
new("Frame", { Name = "DividerRight", Size = UDim2.new(0, 260, 0, 2),
	Position = UDim2.new(0.5, 140, 0, 182), BackgroundColor3 = CYAN,
	BackgroundTransparency = 0.5, BorderSizePixel = 0 }, menuFrame)
makeLabel(menuFrame, "SectionHeader", UDim2.new(0, 280, 0, 26), UDim2.new(0.5, -140, 0, 170),
	"THE ASCENT  ·  16 STAGES  ·  4 ZONES", 16, WHITE, Enum.Font.GothamBlack)

-- Zone cards: one per obby zone, in climb order. Stages and rewards are the
-- real ones from GameConfig (checkpoints +75, summit +600). The pips show the
-- zone's difficulty (filled = zone index out of 4).
local ZONES = {
	{ name = "EMBER RISE", stages = "STAGES 1-4", reward = "Checkpoint +75", accent = RED, level = 1 },
	{ name = "CRYSTAL SPAN", stages = "STAGES 5-8", reward = "Checkpoint +75", accent = CYAN, level = 2 },
	{ name = "VOID STEPS", stages = "STAGES 9-12", reward = "Checkpoint +75", accent = PURPLE, level = 3 },
	{ name = "CELESTIAL SUMMIT", stages = "STAGES 13-16", reward = "Summit +600", accent = GOLD, level = 4 },
}

local function makeZoneCard(xOffset, zone)
	local card = new("Frame", { Name = zone.name .. "Card", Size = UDim2.new(0, 190, 0, 150),
		Position = UDim2.new(0.5, xOffset, 0, 208), BackgroundColor3 = Color3.fromHex("1A2032"),
		BorderSizePixel = 0 }, menuFrame)
	new("UICorner", { CornerRadius = UDim.new(0, 12) }, card)
	new("UIStroke", { Color = zone.accent, Transparency = 0.35, Thickness = 1.5 }, card)
	new("Frame", { Name = "AccentBar", Size = UDim2.new(1, 0, 0, 5),
		Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = zone.accent,
		BorderSizePixel = 0 }, card)
	makeLabel(card, "ZoneName", UDim2.new(1, -16, 0, 26), UDim2.new(0, 8, 0, 14),
		zone.name, 17, zone.accent, Enum.Font.GothamBlack)
	makeLabel(card, "ZoneStages", UDim2.new(1, -16, 0, 22), UDim2.new(0, 8, 0, 42),
		zone.stages, 14, WHITE)
	makeLabel(card, "ZoneReward", UDim2.new(1, -16, 0, 22), UDim2.new(0, 8, 0, 68),
		zone.reward, 14, GOLD, Enum.Font.GothamBlack)
	for pip = 1, 4 do
		new("Frame", { Name = "Pip" .. pip, Size = UDim2.new(0, 28, 0, 8),
			Position = UDim2.new(0, 8 + (pip - 1) * 34, 0, 112),
			BackgroundColor3 = zone.accent, BackgroundTransparency = pip <= zone.level and 0 or 0.75,
			BorderSizePixel = 0 }, card)
	end
	makeLabel(card, "ZoneDiff", UDim2.new(1, -16, 0, 18), UDim2.new(0, 8, 0, 126),
		"DIFFICULTY " .. zone.level .. "/4", 11, DIM)
	return card
end

for i, zone in ipairs(ZONES) do
	makeZoneCard(-404 + (i - 1) * 206, zone)
end

-- Live telemetry strip: the player's own leaderstats, updated on change.
local telemetry = new("Frame", { Name = "Telemetry", Size = UDim2.new(0, 808, 0, 64),
	Position = UDim2.new(0.5, -404, 0, 378), BackgroundColor3 = Color3.fromHex("0D1120"),
	BorderSizePixel = 0 }, menuFrame)
new("UICorner", { CornerRadius = UDim.new(0, 10) }, telemetry)
new("UIStroke", { Color = CYAN, Transparency = 0.6, Thickness = 1 }, telemetry)

local leaderstats = player:WaitForChild("leaderstats")
local TELEMETRY_CELLS = {
	{ key = "Aether", label = "AETHER" },
	{ key = "Aether/s", label = "AETHER / SEC" },
	{ key = "Stage", label = "STAGE" },
	{ key = "Rebirths", label = "REBIRTHS" },
}
local telemetryValues = {}
for i, cell in ipairs(TELEMETRY_CELLS) do
	local x = (i - 1) * 202
	makeLabel(telemetry, cell.label .. "Label", UDim2.new(0, 190, 0, 18),
		UDim2.new(0, x + 6, 0, 8), cell.label, 12, DIM)
	telemetryValues[cell.key] = makeLabel(telemetry, cell.label .. "Value",
		UDim2.new(0, 190, 0, 30), UDim2.new(0, x + 6, 0, 26), "0", 22, WHITE,
		Enum.Font.GothamBlack)
end

local function refreshTelemetry()
	for _, cell in ipairs(TELEMETRY_CELLS) do
		local stat = leaderstats:FindFirstChild(cell.key)
		if stat then telemetryValues[cell.key].Text = tostring(stat.Value) end
	end
end
for _, cell in ipairs(TELEMETRY_CELLS) do
	local stat = leaderstats:FindFirstChild(cell.key)
	if stat then stat.Changed:Connect(refreshTelemetry) end
end
refreshTelemetry()

makeLabel(menuFrame, "MechanicsLine", UDim2.new(0, 808, 0, 22), UDim2.new(0.5, -404, 0, 454),
	"Tycoon plots earn Aether every second  ·  Roll Auras (150) to multiply all gains  ·  Rebirth for a permanent boost",
	13, DIM)
makeLabel(menuFrame, "ControlsLine", UDim2.new(0, 808, 0, 26), UDim2.new(0.5, -404, 0, 480),
	"[WASD] MOVE   [SHIFT] DASH   [MOUSE1] CLICK THE AETHER CORE   [ORBS] CHAIN COMBOS", 15, WHITE)

local deployButton = makeButton(menuFrame, "DeployButton", UDim2.new(0, 260, 0, 56),
	UDim2.new(0.5, -130, 0, 522), "DEPLOY  >>", GOLD, 22)

local victoryDim = new("Frame", { Name = "VictoryDim", Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.25,
	BorderSizePixel = 0, Visible = false }, menuGui)
local victoryPanel = new("Frame", { Name = "VictoryPanel", Size = UDim2.new(0, 440, 0, 300),
	Position = UDim2.new(0.5, -220, 0.5, -150), BackgroundColor3 = NAVY,
	BorderSizePixel = 0 }, victoryDim)
new("UICorner", { CornerRadius = UDim.new(0, 14) }, victoryPanel)
new("UIStroke", { Color = GOLD, Thickness = 2 }, victoryPanel)

makeLabel(victoryPanel, "VictoryTitle", UDim2.new(1, -32, 0, 52), UDim2.new(0, 16, 0, 24),
	"SUMMIT REACHED!", 32, GOLD, Enum.Font.GothamBlack)
makeLabel(victoryPanel, "VictorySub", UDim2.new(1, -32, 0, 28), UDim2.new(0, 16, 0, 80),
	"You conquered the Sky Obby", 17, WHITE)
local victoryReward = makeLabel(victoryPanel, "VictoryReward", UDim2.new(1, -32, 0, 36),
	UDim2.new(0, 16, 0, 122), "", 22, CYAN, Enum.Font.GothamBlack)
local victoryCombo = makeLabel(victoryPanel, "VictoryCombo", UDim2.new(1, -32, 0, 28),
	UDim2.new(0, 16, 0, 164), "", 16, DIM)
local playAgainButton = makeButton(victoryPanel, "PlayAgainButton", UDim2.new(0, 220, 0, 48),
	UDim2.new(0.5, -110, 0, 216), "PLAY AGAIN", TEAL, 18)

local function setMovementLocked(locked)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = locked and 0 or 16
	humanoid.JumpPower = locked and 0 or 50
end

local function showStartMenu()
	menuFrame.Visible = true
	task.spawn(setMovementLocked, true)
end

local function fadeOutMenu()
	local fadeInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fadeProps = { TextLabel = "TextTransparency", TextButton = "TextTransparency",
		Frame = "BackgroundTransparency", UIStroke = "Transparency" }
	TweenService:Create(menuFrame, fadeInfo, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(deployButton, fadeInfo, { BackgroundTransparency = 1 }):Play()
	for _, descendant in ipairs(menuFrame:GetDescendants()) do
		local prop = fadeProps[descendant.ClassName]
		if prop then TweenService:Create(descendant, fadeInfo, { [prop] = 1 }):Play() end
	end
end

local function deployPlayer()
	if hasDeployed then return end
	hasDeployed = true
	fadeOutMenu()
	task.delay(0.4, function() menuFrame.Visible = false end)
	setMovementLocked(false)
end

local function hideVictoryScreen()
	victoryToken += 1
	victoryDim.Visible = false
end

local function showVictoryScreen(reward, bestCombo)
	victoryToken += 1
	local token = victoryToken
	victoryReward.Text = "+" .. reward .. " Aether"
	victoryCombo.Text = "Best combo: x" .. bestCombo
	victoryDim.Visible = true
	task.delay(6, function()
		if token == victoryToken then hideVictoryScreen() end
	end)
end

deployButton.MouseButton1Click:Connect(deployPlayer)
playAgainButton.MouseButton1Click:Connect(hideVictoryScreen)
victoryEvent.OnClientEvent:Connect(showVictoryScreen)

-- Respawn before deploying: lock movement again, never re-show the menu.
player.CharacterAdded:Connect(function()
	if not hasDeployed then task.spawn(setMovementLocked, true) end
end)

showStartMenu()
