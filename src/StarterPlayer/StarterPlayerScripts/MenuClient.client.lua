-- MenuClient.client.lua -- AETHER RIFT: RELIC ASCENT start menu + victory screen.
-- The start menu shows once per session; the victory screen fires on VictoryEvent.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local victoryEvent = remotes:WaitForChild("VictoryEvent")

local NAVY, CYAN, GOLD, TEAL, WHITE, DIM = Color3.fromHex("121622"), Color3.fromHex("00EBFF"),
	Color3.fromHex("FFD23F"), Color3.fromHex("00C9A7"), Color3.fromHex("F2F7FF"), Color3.fromHex("9AA7C7")

local hasDeployed, victoryToken = false, 0

-- Instance factory: new("Frame", { Size = ..., ... }, parent)
local function new(className, props, parent)
	local inst = Instance.new(className)
	for key, value in pairs(props) do inst[key] = value end
	inst.Parent = parent
	return inst
end

local menuGui = new("ScreenGui", { Name = "AetherMenu", ResetOnSpawn = false,
	IgnoreGuiInset = true }, player:WaitForChild("PlayerGui"))

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
	BackgroundColor3 = NAVY, BackgroundTransparency = 0.15, BorderSizePixel = 0 }, menuGui)

makeLabel(menuFrame, "Title", UDim2.new(0, 700, 0, 60), UDim2.new(0.5, -350, 0, 70),
	"AETHER RIFT", 48, CYAN, Enum.Font.GothamBlack)
makeLabel(menuFrame, "Subtitle", UDim2.new(0, 700, 0, 36), UDim2.new(0.5, -350, 0, 128),
	"RELIC ASCENT", 26, GOLD, Enum.Font.GothamBlack)
makeLabel(menuFrame, "Tagline", UDim2.new(0, 700, 0, 28), UDim2.new(0.5, -350, 0, 166),
	"Climb. Build. Roll. Rebirth.", 18, DIM)

local howToPanel = new("Frame", { Name = "HowToPanel", Size = UDim2.new(0, 520, 0, 210),
	Position = UDim2.new(0.5, -260, 0, 220), BackgroundColor3 = NAVY,
	BackgroundTransparency = 0.25, BorderSizePixel = 0 }, menuFrame)
new("UICorner", { CornerRadius = UDim.new(0, 12) }, howToPanel)
new("UIStroke", { Color = CYAN, Transparency = 0.5, Thickness = 1.5 }, howToPanel)

local howToText = table.concat({
	"WASD — Move",
	"SHIFT — Dash",
	"CLICK the Aether Core — earn energy",
	"Collect orbs — chain combos",
	"Climb the 16-stage Sky Obby — reach the Summit",
	"Claim a Tycoon plot — earn while you play",
	"Roll Auras & Rebirth — multiply everything",
}, "\n")
local howToLabel = makeLabel(howToPanel, "HowToText", UDim2.new(1, -32, 1, -16),
	UDim2.new(0, 16, 0, 8), howToText, 15, WHITE)
howToLabel.TextXAlignment = Enum.TextXAlignment.Left
howToLabel.TextYAlignment = Enum.TextYAlignment.Top

local deployButton = makeButton(menuFrame, "DeployButton", UDim2.new(0, 260, 0, 56),
	UDim2.new(0.5, -130, 0, 460), "DEPLOY", GOLD, 22)

local victoryDim = new("Frame", { Name = "VictoryDim", Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45,
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
