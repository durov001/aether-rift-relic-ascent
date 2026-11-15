-- GameManager.server.lua
-- AETHER RIFT: RELIC ASCENT — economy, progression, persistence, interactions.
-- Repo: https://github.com/durov001/aether-rift-relic-ascent
-- Luau, Roblox services only, no external assets.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- ============ Remotes ============
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local rollAuraFunc = Instance.new("RemoteFunction")
rollAuraFunc.Name = "RollAuraFunc"
rollAuraFunc.Parent = remotes

local rebirthFunc = Instance.new("RemoteFunction")
rebirthFunc.Name = "RebirthFunc"
rebirthFunc.Parent = remotes

local notifyEvent = Instance.new("RemoteEvent")
notifyEvent.Name = "NotifyEvent"
notifyEvent.Parent = remotes

local comboEvent = Instance.new("RemoteEvent")
comboEvent.Name = "ComboEvent"
comboEvent.Parent = remotes

local victoryEvent = Instance.new("RemoteEvent")
victoryEvent.Name = "VictoryEvent"
victoryEvent.Parent = remotes

-- ============ DataStore (nil-safe for Studio offline) ============
local playerStore = nil
local ok, store = pcall(function()
	return DataStoreService:GetDataStore("AetherRift_v1")
end)
if ok then
	playerStore = store
end

-- ============ Player state ============
local playerStates = {}

local function getTotalMultiplier(state)
	local rebirthMult = 1 + state.Rebirths * (GameConfig.REBIRTH_MULTIPLIER_STEP - 1)
	return rebirthMult * state.AuraMult
end

local function updateLeaderstats(player)
	local state = playerStates[player.UserId]
	if not state then
		return
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	local aether = leaderstats:FindFirstChild("Aether")
	local perSecond = leaderstats:FindFirstChild("Aether/s")
	local rebirths = leaderstats:FindFirstChild("Rebirths")
	local stage = leaderstats:FindFirstChild("Stage")
	if aether then
		aether.Value = math.floor(state.Energy)
	end
	if perSecond then
		perSecond.Value = math.floor(state.IncomeRate * getTotalMultiplier(state))
	end
	if rebirths then
		rebirths.Value = state.Rebirths
	end
	if stage then
		stage.Value = state.BestStage
	end
end

-- Aura lookup delegates to the shared GameConfig helper so both
-- server scripts agree on aura names, multipliers, and colors.
local function findAuraByName(auraName)
	return GameConfig.getAuraByName(auraName)
end

local function applyAuraVisual(player, auraName, auraColor)
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local oldRing = character:FindFirstChild("EquippedAuraRing")
	if oldRing then
		oldRing:Destroy()
	end
	if auraName == "None" then
		return
	end
	local ring = Instance.new("Part")
	ring.Name = "EquippedAuraRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.3, 6.5, 6.5)
	ring.Orientation = Vector3.new(0, 0, 90)
	ring.Color = auraColor
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.45
	ring.CanCollide = false
	ring.Massless = true
	ring.Anchored = false
	ring.CFrame = root.CFrame * CFrame.new(0, -2.6, 0)
	ring.Parent = character
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = ring
	weld.Parent = ring
end

local function releaseTycoonPlot(player)
	local plotsFolder = Workspace:FindFirstChild("AetherWorld")
	if not plotsFolder then
		return
	end
	local tycoonPlots = plotsFolder:FindFirstChild("TycoonPlots")
	if not tycoonPlots then
		return
	end
	for _, plot in ipairs(tycoonPlots:GetChildren()) do
		if plot:GetAttribute("OwnerUserId") == player.UserId then
			plot:SetAttribute("OwnerUserId", 0)
			local claimPad = plot:FindFirstChild("ClaimPad")
			if claimPad then
				local ownerGui = claimPad:FindFirstChild("OwnerGui")
				if ownerGui then
					local statusLabel = ownerGui:FindFirstChild("StatusLabel")
					if statusLabel then
						statusLabel.Text = "STEP HERE TO CLAIM TYCOON"
					end
				end
			end
			for _, child in ipairs(plot:GetChildren()) do
				if child:IsA("Part") and child:GetAttribute("Purchased") ~= nil then
					child:SetAttribute("Purchased", false)
					child.Transparency = 0
					local padGui = child:FindFirstChild("PadGui")
					if padGui then
						padGui.Enabled = true
					end
				end
				if child:IsA("Part") and string.sub(child.Name, 1, 6) == "Tower_" then
					child:Destroy()
				end
			end
		end
	end
end

local function resetOwnedTycoonPads(player)
	local world = Workspace:FindFirstChild("AetherWorld")
	if not world then
		return
	end
	local tycoonPlots = world:FindFirstChild("TycoonPlots")
	if not tycoonPlots then
		return
	end
	for _, plot in ipairs(tycoonPlots:GetChildren()) do
		if plot:GetAttribute("OwnerUserId") == player.UserId then
			for _, child in ipairs(plot:GetChildren()) do
				if child:IsA("Part") and child:GetAttribute("Purchased") ~= nil then
					child:SetAttribute("Purchased", false)
					child.Transparency = 0
					local padGui = child:FindFirstChild("PadGui")
					if padGui then
						padGui.Enabled = true
					end
				end
				if child:IsA("Part") and string.sub(child.Name, 1, 6) == "Tower_" then
					child:Destroy()
				end
			end
		end
	end
end

local function findOwnedPlot(player)
	local world = Workspace:FindFirstChild("AetherWorld")
	if not world then
		return nil
	end
	local tycoonPlots = world:FindFirstChild("TycoonPlots")
	if not tycoonPlots then
		return nil
	end
	for _, plot in ipairs(tycoonPlots:GetChildren()) do
		if plot:GetAttribute("OwnerUserId") == player.UserId then
			return plot
		end
	end
	return nil
end

-- ============ Player join / leave ============
local function onPlayerAdded(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local aetherValue = Instance.new("IntValue")
	aetherValue.Name = "Aether"
	aetherValue.Value = 25
	aetherValue.Parent = leaderstats

	local perSecondValue = Instance.new("IntValue")
	perSecondValue.Name = "Aether/s"
	perSecondValue.Value = 0
	perSecondValue.Parent = leaderstats

	local rebirthsValue = Instance.new("IntValue")
	rebirthsValue.Name = "Rebirths"
	rebirthsValue.Value = 0
	rebirthsValue.Parent = leaderstats

	local stageValue = Instance.new("IntValue")
	stageValue.Name = "Stage"
	stageValue.Value = 0
	stageValue.Parent = leaderstats

	local state = {
		Energy = 25,
		Rebirths = 0,
		IncomeRate = 0,
		AuraName = "None",
		AuraMult = 1,
		ObbyStages = {},
		Combo = 0,
		LastOrbTime = 0,
		BestCombo = 0,
		BestStage = 0,
	}

	if playerStore then
		local loadOk, saved = pcall(function()
			return playerStore:GetAsync("u_" .. player.UserId)
		end)
		if loadOk and type(saved) == "table" then
			state.Energy = saved.Energy or state.Energy
			state.Rebirths = saved.Rebirths or 0
			state.AuraName = saved.AuraName or "None"
			state.AuraMult = saved.AuraMult or 1
		end
	end

	playerStates[player.UserId] = state
	updateLeaderstats(player)

	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		local current = playerStates[player.UserId]
		if current and current.AuraName ~= "None" then
			local aura = findAuraByName(current.AuraName)
			if aura then
				applyAuraVisual(player, aura.Name, aura.Color)
			end
		end
	end)
end

local function onPlayerRemoving(player)
	local state = playerStates[player.UserId]
	if state and playerStore then
		pcall(function()
			playerStore:SetAsync("u_" .. player.UserId, {
				Energy = state.Energy,
				Rebirths = state.Rebirths,
				AuraName = state.AuraName,
				AuraMult = state.AuraMult,
			})
		end)
	end
	releaseTycoonPlot(player)
	playerStates[player.UserId] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- ============ Passive income loop ============
task.spawn(function()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local state = playerStates[player.UserId]
			if state and state.IncomeRate > 0 then
				state.Energy += state.IncomeRate * getTotalMultiplier(state)
				updateLeaderstats(player)
			end
		end
	end
end)

-- ============ World interactions (wired after WorldBuilder) ============
task.wait(0.5)
local aetherWorld = Workspace:WaitForChild("AetherWorld")

-- Monolith click: flat reward scaled by multiplier.
local monolith = aetherWorld:WaitForChild("AetherMonolith")
local monolithClick = monolith:WaitForChild("ClickDetector")
monolithClick.MouseClick:Connect(function(player)
	local state = playerStates[player.UserId]
	if not state then
		return
	end
	local gain = math.floor(GameConfig.BASE_CLICK_REWARD * getTotalMultiplier(state))
	state.Energy += gain
	updateLeaderstats(player)
	notifyEvent:FireClient(player, string.format("+%d Aether Energy!", gain))
end)

-- Orb collection with combo chaining.
local orbFolder = aetherWorld:WaitForChild("CollectibleOrbs")
for _, orb in ipairs(orbFolder:GetChildren()) do
	local orbDebounce = false
	orb.Touched:Connect(function(hit)
		if orbDebounce or orb.Transparency > 0 then
			return
		end
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end
		local state = playerStates[player.UserId]
		if not state then
			return
		end
		orbDebounce = true
		local now = os.clock()
		if now - state.LastOrbTime <= GameConfig.COMBO_WINDOW then
			state.Combo += 1
		else
			state.Combo = 1
		end
		state.LastOrbTime = now
		state.BestCombo = math.max(state.BestCombo, state.Combo)
		local comboMult = math.min(1 + (state.Combo - 1) * GameConfig.COMBO_STEP, GameConfig.COMBO_MAX_MULT)
		local baseValue = orb:GetAttribute("Value") or 15
		local gain = math.floor(baseValue * getTotalMultiplier(state) * comboMult)
		state.Energy += gain
		updateLeaderstats(player)
		orb.Transparency = 1
		task.delay(GameConfig.ORB_RESPAWN_TIME, function()
			orb.Transparency = 0
			orbDebounce = false
		end)
		comboEvent:FireClient(player, state.Combo, comboMult, gain)
		notifyEvent:FireClient(player, string.format("+%d Aether", gain))
	end)
end

-- Obby checkpoints and summit.
local obbyFolder = aetherWorld:WaitForChild("SkyObby")
for _, step in ipairs(obbyFolder:GetChildren()) do
	if step:GetAttribute("Reward") ~= nil then
		step.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player then
				return
			end
			local state = playerStates[player.UserId]
			if not state then
				return
			end
			local stageId = step:GetAttribute("StageId")
			if state.ObbyStages[stageId] then
				return
			end
			state.ObbyStages[stageId] = true
			local reward = step:GetAttribute("Reward")
			local gain = math.floor(reward * getTotalMultiplier(state))
			state.Energy += gain
			state.BestStage = math.max(state.BestStage, stageId)
			updateLeaderstats(player)
			local zoneName = step:GetAttribute("ZoneName") or ""
			if step.Name == "ObbySummit" then
				notifyEvent:FireClient(player, string.format("SUMMIT! +%d Aether", gain))
				victoryEvent:FireClient(player, gain, state.BestCombo)
				task.delay(1.5, function()
					local current = playerStates[player.UserId]
					if current then
						current.ObbyStages = {}
						current.BestStage = 0
						updateLeaderstats(player)
					end
					local character = player.Character
					if character then
						local root = character:FindFirstChild("HumanoidRootPart")
						if root then
							root.CFrame = CFrame.new(0, 5, 0)
						end
					end
				end)
			else
				notifyEvent:FireClient(player, string.format("%s — Checkpoint! +%d Aether", string.upper(zoneName), gain))
			end
		end)
	end
end

-- Tycoon plots: claim pads and buy pads.
local tycoonPlots = aetherWorld:WaitForChild("TycoonPlots")
for _, plot in ipairs(tycoonPlots:GetChildren()) do
	local claimPad = plot:FindFirstChild("ClaimPad")
	if claimPad then
		claimPad.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player then
				return
			end
			if plot:GetAttribute("OwnerUserId") ~= 0 then
				return
			end
			if findOwnedPlot(player) ~= nil then
				return
			end
			plot:SetAttribute("OwnerUserId", player.UserId)
			local ownerGui = claimPad:FindFirstChild("OwnerGui")
			if ownerGui then
				local statusLabel = ownerGui:FindFirstChild("StatusLabel")
				if statusLabel then
					statusLabel.Text = player.DisplayName .. "'s Aether Tycoon"
				end
			end
			notifyEvent:FireClient(player, "Tycoon Claimed!")
		end)
	end

	for _, child in ipairs(plot:GetChildren()) do
		if child:IsA("Part") and child:GetAttribute("Purchased") ~= nil then
			child.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if not player then
					return
				end
				if plot:GetAttribute("OwnerUserId") ~= player.UserId then
					return
				end
				if child:GetAttribute("Purchased") == true then
					return
				end
				local state = playerStates[player.UserId]
				if not state then
					return
				end
				local cost = child:GetAttribute("Cost") or 0
				if state.Energy < cost then
					return
				end
				local rate = child:GetAttribute("Rate") or 0
				local displayName = child:GetAttribute("DisplayName") or child.Name
				local height = child:GetAttribute("VisualHeight") or 6
				state.Energy -= cost
				state.IncomeRate += rate
				child:SetAttribute("Purchased", true)
				child.Transparency = 0.85
				local padGui = child:FindFirstChild("PadGui")
				if padGui then
					padGui.Enabled = false
				end
				local tower = Instance.new("Part")
				tower.Name = "Tower_" .. child.Name
				tower.Size = Vector3.new(4.5, height, 4.5)
				tower.Position = child.Position + Vector3.new(0, height / 2, 0)
				tower.Color = child.Color
				tower.Material = Enum.Material.Neon
				tower.Anchored = true
				tower.TopSurface = Enum.SurfaceType.Smooth
				tower.BottomSurface = Enum.SurfaceType.Smooth
				tower.Parent = plot
				updateLeaderstats(player)
				notifyEvent:FireClient(player, string.format("Built %s! (+%d/s)", displayName, rate))
			end)
		end
	end
end

-- ============ Aura gacha ============
rollAuraFunc.OnServerInvoke = function(player)
	local state = playerStates[player.UserId]
	if not state then
		return false, "No player state!"
	end
	if state.Energy < GameConfig.AURA_ROLL_COST then
		return false, "Need 150 Aether!"
	end
	state.Energy -= GameConfig.AURA_ROLL_COST
	local totalWeight = 0
	for _, aura in ipairs(GameConfig.AURAS) do
		totalWeight += aura.Weight
	end
	local roll = math.random(1, totalWeight)
	local picked = GameConfig.AURAS[1]
	local running = 0
	for _, aura in ipairs(GameConfig.AURAS) do
		running += aura.Weight
		if roll <= running then
			picked = aura
			break
		end
	end
	state.AuraName = picked.Name
	state.AuraMult = picked.Multiplier
	applyAuraVisual(player, picked.Name, picked.Color)
	updateLeaderstats(player)
	return true, string.format("Unlocked [%s] (%.2fx Multiplier)!", picked.Name, picked.Multiplier)
end

-- ============ Rebirth ============
rebirthFunc.OnServerInvoke = function(player)
	local state = playerStates[player.UserId]
	if not state then
		return false, "No player state!"
	end
	local required = math.floor(GameConfig.REBIRTH_BASE_COST * math.pow(2.2, state.Rebirths))
	if state.Energy < required then
		return false, string.format("Need %d Aether to Rebirth!", required)
	end
	state.Rebirths += 1
	state.Energy = 50
	state.IncomeRate = 0
	resetOwnedTycoonPads(player)
	updateLeaderstats(player)
	local totalMult = getTotalMultiplier(state)
	return true, string.format("REBIRTH #%d! Permanent %.2fx Multiplier!", state.Rebirths, totalMult)
end

print("[AetherRift] GameManager ready.")
