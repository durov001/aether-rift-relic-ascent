-- ClientHUD.client.lua -- AETHER RIFT: RELIC ASCENT in-game HUD.
-- Stats, obby progress, combo, dash, actions, notifications. Top-left stays clear.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local rollAuraFunc, rebirthFunc = remotes:WaitForChild("RollAuraFunc"), remotes:WaitForChild("RebirthFunc")
local notifyEvent, comboEvent = remotes:WaitForChild("NotifyEvent"), remotes:WaitForChild("ComboEvent")

local leaderstats = player:WaitForChild("leaderstats")
local aetherValue, aetherRateValue = leaderstats:WaitForChild("Aether"), leaderstats:WaitForChild("Aether/s")
local rebirthsValue, stageValue = leaderstats:WaitForChild("Rebirths"), leaderstats:WaitForChild("Stage")

local NAVY, CYAN, GOLD, TEAL, RED, WHITE, DIM = Color3.fromHex("121622"), Color3.fromHex("00EBFF"),
	Color3.fromHex("FFD23F"), Color3.fromHex("00C9A7"), Color3.fromHex("FF4D5E"),
	Color3.fromHex("F2F7FF"), Color3.fromHex("9AA7C7")

local dashReadyAt, lastDashAt, notifyToken, comboToken, comboTween = 0, -math.huge, 0, 0, nil

-- Instance factory: new("Frame", { Size = ..., ... }, parent)
local function new(className, props, parent)
	local inst = Instance.new(className)
	for key, value in pairs(props) do inst[key] = value end
	inst.Parent = parent
	return inst
end

local hud = new("ScreenGui", { Name = "AetherRiftHUD", ResetOnSpawn = false,
	IgnoreGuiInset = true }, player:WaitForChild("PlayerGui"))

local function makePanel(name, size, position, anchor)
	local panel = new("Frame", { Name = name, Size = size, Position = position,
		AnchorPoint = anchor or Vector2.new(0, 0), BackgroundColor3 = NAVY,
		BackgroundTransparency = 0.1, BorderSizePixel = 0 }, hud)
	new("UICorner", { CornerRadius = UDim.new(0, 10) }, panel)
	new("UIStroke", { Color = CYAN, Transparency = 0.45, Thickness = 1.5 }, panel)
	return panel
end

local function makeLabel(parent, name, size, position, textSize, color, font)
	return new("TextLabel", { Name = name, Size = size, Position = position,
		BackgroundTransparency = 1, TextColor3 = color or WHITE,
		Font = font or Enum.Font.GothamBold, TextSize = textSize or 16 }, parent)
end

local topBar = makePanel("TopBar", UDim2.new(0, 460, 0, 56), UDim2.new(0.5, -230, 0, 14))
local statsLabel = makeLabel(topBar, "StatsLabel", UDim2.new(1, -16, 1, 0), UDim2.new(0, 8, 0, 0), 17, WHITE, Enum.Font.GothamBlack)

local obbyBar = makePanel("ObbyBar", UDim2.new(0, 460, 0, 26), UDim2.new(0.5, -230, 0, 78))
local obbyLabel = makeLabel(obbyBar, "ObbyLabel", UDim2.new(1, -16, 1, 0), UDim2.new(0, 8, 0, 0), 13, WHITE)
obbyLabel.TextXAlignment = Enum.TextXAlignment.Left
local obbyFill = new("Frame", { Name = "ObbyFill", Size = UDim2.new(0, 0, 0, 4),
	Position = UDim2.new(0, 10, 1, -6), BackgroundColor3 = CYAN, BorderSizePixel = 0 }, obbyBar)

-- Telemetry panel (2026-11-15, ATM top entries' "CHASSIS TELEMETRY" HUD):
-- live stats with bars on the left, every value real (leaderstats + dash state).
local telemetryPanel = makePanel("TelemetryPanel", UDim2.new(0, 210, 0, 196), UDim2.new(0, 16, 0, 120))
local telemetryTitle = makeLabel(telemetryPanel, "TelemetryTitle", UDim2.new(1, -16, 0, 20),
	UDim2.new(0, 8, 0, 6), 13, CYAN, Enum.Font.GothamBlack)
telemetryTitle.Text = "TELEMETRY"
telemetryTitle.TextXAlignment = Enum.TextXAlignment.Left

local function makeTelemetryRow(y, labelText, valueColor)
	local rowLabel = makeLabel(telemetryPanel, labelText .. "Label", UDim2.new(0, 110, 0, 18),
		UDim2.new(0, 8, 0, y), 12, DIM)
	rowLabel.Text = labelText
	rowLabel.TextXAlignment = Enum.TextXAlignment.Left
	local rowValue = makeLabel(telemetryPanel, labelText .. "Value", UDim2.new(0, 84, 0, 20),
		UDim2.new(1, -92, 0, y - 1), 15, valueColor, Enum.Font.GothamBlack)
	rowValue.TextXAlignment = Enum.TextXAlignment.Right
	return rowValue
end

local function makeTelemetryBar(y, color)
	local track = new("Frame", { Name = "BarTrack", Size = UDim2.new(1, -16, 0, 6),
		Position = UDim2.new(0, 8, 0, y), BackgroundColor3 = Color3.fromHex("2A3350"),
		BorderSizePixel = 0 }, telemetryPanel)
	new("UICorner", { CornerRadius = UDim.new(0, 3) }, track)
	local fill = new("Frame", { Name = "BarFill", Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = color, BorderSizePixel = 0 }, track)
	new("UICorner", { CornerRadius = UDim.new(0, 3) }, fill)
	return fill
end

local telemetryAether = makeTelemetryRow(32, "AETHER", GOLD)
local telemetryRate = makeTelemetryRow(60, "AETHER/SEC", TEAL)
local telemetryStage = makeTelemetryRow(88, "STAGE", WHITE)
local telemetryStageFill = makeTelemetryBar(110, CYAN)
local telemetryRebirths = makeTelemetryRow(124, "REBIRTHS", WHITE)
local telemetryDash = makeTelemetryRow(152, "DASH", CYAN)
local telemetryDashFill = makeTelemetryBar(174, CYAN)

local notifyFrame = makePanel("NotifyBanner", UDim2.new(0, 520, 0, 42), UDim2.new(0.5, -260, 0, 112))
notifyFrame.Visible = false
local notifyLabel = makeLabel(notifyFrame, "NotifyLabel", UDim2.new(1, -16, 1, 0), UDim2.new(0, 8, 0, 0), 15, WHITE)

local comboFrame = makePanel("ComboFrame", UDim2.new(0, 220, 0, 72), UDim2.new(1, -16, 0, 78), Vector2.new(1, 0))
comboFrame.Visible = false
local comboBig = makeLabel(comboFrame, "ComboBig", UDim2.new(1, -12, 0, 34), UDim2.new(0, 6, 0, 4), 24, GOLD, Enum.Font.GothamBlack)
local comboChain = makeLabel(comboFrame, "ComboChain", UDim2.new(1, -12, 0, 20), UDim2.new(0, 6, 0, 38), 14, WHITE)
local comboDecay = new("Frame", { Name = "ComboDecay", Size = UDim2.new(1, -20, 0, 6),
	Position = UDim2.new(0, 10, 1, -10), BackgroundColor3 = GOLD, BorderSizePixel = 0 }, comboFrame)

local actionPanel = makePanel("ActionPanel", UDim2.new(0, 200, 0, 124), UDim2.new(0, 16, 0.5, -62))

local function makeButton(name, text, position, color)
	local button = new("TextButton", { Name = name, Size = UDim2.new(1, -24, 0, 44),
		Position = position, BackgroundColor3 = color, Text = text, TextColor3 = NAVY,
		Font = Enum.Font.GothamBlack, TextSize = 15, AutoButtonColor = true }, actionPanel)
	new("UICorner", { CornerRadius = UDim.new(0, 10) }, button)
	return button
end

local rollButton = makeButton("RollAuraButton", "ROLL AURA (150 ⚡)", UDim2.new(0, 12, 0, 12), TEAL)
local rebirthButton = makeButton("RebirthButton", "REBIRTH (500 ⚡)", UDim2.new(0, 12, 0, 68), GOLD)

local dashFrame = makePanel("DashFrame", UDim2.new(0, 220, 0, 30), UDim2.new(0.5, -110, 1, -60))
local dashFill = new("Frame", { Name = "DashFill", Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = CYAN, BackgroundTransparency = 0.75, BorderSizePixel = 0 }, dashFrame)
new("UICorner", { CornerRadius = UDim.new(0, 10) }, dashFill)
local dashLabel = makeLabel(dashFrame, "DashLabel", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 14, WHITE, Enum.Font.GothamBlack)

local function formatNumber(n)
	return (tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local function getRebirthCost()
	return math.floor(GameConfig.REBIRTH_BASE_COST * (2.2 ^ rebirthsValue.Value))
end

local function refreshStats()
	statsLabel.Text = string.format("⚡ Aether: %s  |  +%s/s  |  Rebirths: %d",
		formatNumber(aetherValue.Value), formatNumber(aetherRateValue.Value), rebirthsValue.Value)
	rebirthButton.Text = "REBIRTH (" .. formatNumber(getRebirthCost()) .. " ⚡)"
	local stage = stageValue.Value
	local zone = stage > 0 and GameConfig.getZoneForStage(stage) or nil
	local zoneName, zoneColor = zone and zone.Name or "Plaza", zone and zone.Color or CYAN
	obbyLabel.Text = "Stage " .. stage .. "/16 — " .. zoneName
	obbyFill.Size = UDim2.new(math.clamp(stage / 16, 0, 1), 0, 0, 4)
	obbyFill.BackgroundColor3 = zoneColor
	telemetryAether.Text = formatNumber(aetherValue.Value)
	telemetryRate.Text = "+" .. formatNumber(aetherRateValue.Value) .. "/s"
	telemetryStage.Text = stage .. "/16"
	telemetryStageFill.Size = UDim2.new(math.clamp(stage / 16, 0, 1), 0, 1, 0)
	telemetryStageFill.BackgroundColor3 = zoneColor
	telemetryRebirths.Text = tostring(rebirthsValue.Value)
end

local function showNotification(message, color)
	notifyToken += 1
	local token = notifyToken
	notifyLabel.Text = message
	notifyLabel.TextColor3 = color or WHITE
	notifyFrame.Visible = true
	task.delay(2.5, function()
		if token == notifyToken then notifyFrame.Visible = false end
	end)
end

local function callRemote(remoteFunc, successColor)
	local ok, success, message = pcall(function() return remoteFunc:InvokeServer() end)
	if not ok then
		showNotification("Connection error — try again", RED)
		return
	end
	if success then showNotification(message or "Done!", successColor)
	else showNotification(message or "Failed", RED) end
end

local function hideCombo()
	comboFrame.Visible = false
	if comboTween then comboTween:Cancel() comboTween = nil end
end

local function showCombo(comboCount, comboMult, gain)
	comboToken += 1
	local token = comboToken
	comboBig.Text = "COMBO x" .. string.format("%.2f", comboMult)
	comboChain.Text = comboCount .. " chain  •  +" .. gain .. " ⚡"
	comboFrame.Visible = true
	if comboTween then comboTween:Cancel() end
	comboDecay.Size = UDim2.new(1, -20, 0, 6)
	comboTween = TweenService:Create(comboDecay,
		TweenInfo.new(GameConfig.COMBO_WINDOW, Enum.EasingStyle.Linear),
		{ Size = UDim2.new(0, 0, 0, 6) })
	comboTween:Play()
	task.delay(GameConfig.COMBO_WINDOW, function()
		if token == comboToken then hideCombo() end
	end)
end

local function tryDash()
	if os.clock() < dashReadyAt then return end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then return end
	local dir = humanoid.MoveDirection
	if dir.Magnitude < 0.1 then dir = hrp.CFrame.LookVector end
	local velocity = new("BodyVelocity", { MaxForce = Vector3.new(1e6, 0, 1e6),
		Velocity = dir * GameConfig.DASH_SPEED }, hrp)
	task.delay(GameConfig.DASH_DURATION, function() velocity:Destroy() end)
	local now = os.clock()
	dashReadyAt = now + GameConfig.DASH_COOLDOWN
	lastDashAt = now
end

local function updateDashBar()
	local ready = math.clamp((os.clock() - lastDashAt) / GameConfig.DASH_COOLDOWN, 0, 1)
	dashFill.Size = UDim2.new(ready, 0, 1, 0)
	local isReady = ready >= 1
	dashFill.BackgroundColor3 = isReady and CYAN or DIM
	dashLabel.Text = isReady and "DASH READY" or string.format("DASH %.1fs", dashReadyAt - os.clock())
	telemetryDashFill.Size = UDim2.new(ready, 0, 1, 0)
	telemetryDashFill.BackgroundColor3 = isReady and CYAN or DIM
	telemetryDash.Text = isReady and "READY" or string.format("%.1fs", dashReadyAt - os.clock())
end

aetherValue.Changed:Connect(refreshStats)
aetherRateValue.Changed:Connect(refreshStats)
rebirthsValue.Changed:Connect(refreshStats)
stageValue.Changed:Connect(refreshStats)
notifyEvent.OnClientEvent:Connect(function(message, color) showNotification(message, color) end)
comboEvent.OnClientEvent:Connect(function(comboCount, comboMult, gain)
	if comboCount >= 2 then showCombo(comboCount, comboMult, gain) else hideCombo() end
end)
rollButton.MouseButton1Click:Connect(function() callRemote(rollAuraFunc, TEAL) end)
rebirthButton.MouseButton1Click:Connect(function() callRemote(rebirthFunc, GOLD) end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		tryDash()
	end
end)

RunService.RenderStepped:Connect(updateDashBar)
refreshStats()
