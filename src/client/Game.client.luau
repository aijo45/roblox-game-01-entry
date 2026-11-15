-- Neon Coin Rush: a 2D arcade game in a Roblox GUI.
-- Move the cyan runner with the arrow keys or WASD, grab the gold coins
-- for points, and dodge the red hazards. 60 seconds, 3 lives. Every 6
-- coins raises the level: hazards get faster and one more spawns.
-- Enter starts, R restarts. Score is sent to the server at the end.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Tuning -----------------------------------------------------------------
local ARENA_W = 640
local ARENA_H = 480
local PLAYER_SIZE = 44
local PLAYER_SPEED = 340
local COIN_SIZE = 28
local COIN_SPAWN_EVERY = 1.1
local COIN_MAX = 5
local COIN_LIFETIME = 6
local HAZARD_SIZE = 36
local HAZARD_BASE_SPEED = 150
local HAZARD_SPEED_PER_LEVEL = 35
local GAME_TIME = 60
local START_LIVES = 3
local COINS_PER_LEVEL = 6
local MAX_HAZARDS = 5
local INVULN_TIME = 1.5
local COMBO_WINDOW = 2.5

-- State ------------------------------------------------------------------
local playing = false
local score = 0
local coinsCollected = 0
local lives = START_LIVES
local timeLeft = GAME_TIME
local level = 1
local combo = 1
local comboTimer = 0
local invulnTimer = 0
local coinSpawnTimer = 0
local playerX = (ARENA_W - PLAYER_SIZE) / 2
local playerY = (ARENA_H - PLAYER_SIZE) / 2
local coins = {}
local hazards = {}
local blinkOn = false

-- GUI --------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "NeonCoinRush"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(12, 12, 24)
background.BorderSizePixel = 0
background.Parent = gui

-- A faint grid so the arena reads as a game board, not an empty box.
local grid = Instance.new("Frame")
grid.Name = "Grid"
grid.AnchorPoint = Vector2.new(0.5, 0.5)
grid.Position = UDim2.fromScale(0.5, 0.5)
grid.Size = UDim2.fromOffset(ARENA_W, ARENA_H)
grid.BackgroundColor3 = Color3.fromRGB(18, 18, 38)
grid.BorderColor3 = Color3.fromRGB(60, 60, 120)
grid.BorderSizePixel = 2
grid.Parent = background

local arena = Instance.new("Frame")
arena.Name = "Arena"
arena.AnchorPoint = Vector2.new(0.5, 0.5)
arena.Position = UDim2.fromScale(0.5, 0.5)
arena.Size = UDim2.fromOffset(ARENA_W, ARENA_H)
arena.BackgroundTransparency = 1
arena.BorderSizePixel = 0
arena.ClipsDescendants = true
arena.Parent = background

local function makeLabel(parent, name, text, size, color, pos, anchor)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.TextSize = size
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = color
	label.BackgroundTransparency = 1
	label.AnchorPoint = anchor or Vector2.new(0, 0)
	label.Position = pos
	label.Size = UDim2.fromOffset(300, 32)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

-- HUD sits on the right so it never hides under Roblox's top-left buttons.
local hud = Instance.new("Frame")
hud.Name = "HUD"
hud.AnchorPoint = Vector2.new(1, 0)
hud.Position = UDim2.new(1, -16, 0, 12)
hud.Size = UDim2.fromOffset(300, 120)
hud.BackgroundTransparency = 1
hud.Parent = background

local scoreLabel = makeLabel(hud, "Score", "SCORE  0", 26, Color3.fromRGB(0, 229, 255),
	UDim2.new(0, 0, 0, 0), Vector2.new(0, 0))
scoreLabel.TextXAlignment = Enum.TextXAlignment.Right
local livesLabel = makeLabel(hud, "Lives", "LIVES  ♥♥♥", 20, Color3.fromRGB(255, 90, 120),
	UDim2.new(0, 0, 0, 34), Vector2.new(0, 0))
livesLabel.TextXAlignment = Enum.TextXAlignment.Right
local timeLabel = makeLabel(hud, "Time", "TIME  60", 20, Color3.fromRGB(255, 220, 90),
	UDim2.new(0, 0, 0, 64), Vector2.new(0, 0))
timeLabel.TextXAlignment = Enum.TextXAlignment.Right
local levelLabel = makeLabel(hud, "Level", "LEVEL  1", 20, Color3.fromRGB(170, 255, 140),
	UDim2.new(0, 0, 0, 92), Vector2.new(0, 0))
levelLabel.TextXAlignment = Enum.TextXAlignment.Right

local timeBarBack = Instance.new("Frame")
timeBarBack.Name = "TimeBarBack"
timeBarBack.AnchorPoint = Vector2.new(0.5, 0)
timeBarBack.Position = UDim2.new(0.5, 0, 0, 14)
timeBarBack.Size = UDim2.fromOffset(320, 10)
timeBarBack.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
timeBarBack.BorderSizePixel = 0
timeBarBack.Parent = background
local timeBarCorner = Instance.new("UICorner")
timeBarCorner.CornerRadius = UDim.new(0.5, 0)
timeBarCorner.Parent = timeBarBack

local timeBar = Instance.new("Frame")
timeBar.Name = "TimeBar"
timeBar.AnchorPoint = Vector2.new(0, 0.5)
timeBar.Position = UDim2.new(0, 0, 0.5, 0)
timeBar.Size = UDim2.fromScale(1, 1)
timeBar.BackgroundColor3 = Color3.fromRGB(255, 220, 90)
timeBar.BorderSizePixel = 0
timeBar.Parent = timeBarBack
local timeBarCorner2 = Instance.new("UICorner")
timeBarCorner2.CornerRadius = UDim.new(0.5, 0)
timeBarCorner2.Parent = timeBar

local playerFrame = Instance.new("Frame")
playerFrame.Name = "Player"
playerFrame.Size = UDim2.fromOffset(PLAYER_SIZE, PLAYER_SIZE)
playerFrame.BackgroundColor3 = Color3.fromRGB(0, 229, 255)
playerFrame.BorderColor3 = Color3.fromRGB(0, 120, 140)
playerFrame.BorderSizePixel = 2
playerFrame.Parent = arena
local playerCorner = Instance.new("UICorner")
playerCorner.CornerRadius = UDim.new(0.25, 0)
playerCorner.Parent = playerFrame

local playerGlow = Instance.new("TextLabel")
playerGlow.Name = "Face"
playerGlow.Text = "▶"
playerGlow.TextSize = 22
playerGlow.Font = Enum.Font.GothamBold
playerGlow.TextColor3 = Color3.fromRGB(10, 40, 50)
playerGlow.BackgroundTransparency = 1
playerGlow.Size = UDim2.fromScale(1, 1)
playerGlow.Parent = playerFrame

-- Start overlay ----------------------------------------------------------
local startOverlay = Instance.new("Frame")
startOverlay.Name = "StartOverlay"
startOverlay.Size = UDim2.fromScale(1, 1)
startOverlay.BackgroundColor3 = Color3.fromRGB(12, 12, 24)
startOverlay.BackgroundTransparency = 0.15
startOverlay.BorderSizePixel = 0
startOverlay.Parent = background

local startTitle = Instance.new("TextLabel")
startTitle.Name = "Title"
startTitle.Text = "NEON COIN RUSH"
startTitle.TextSize = 44
startTitle.Font = Enum.Font.GothamBlack
startTitle.TextColor3 = Color3.fromRGB(0, 229, 255)
startTitle.BackgroundTransparency = 1
startTitle.AnchorPoint = Vector2.new(0.5, 0.5)
startTitle.Position = UDim2.new(0.5, 0, 0.38, 0)
startTitle.Size = UDim2.fromOffset(560, 60)
startTitle.Parent = startOverlay

local startSub = Instance.new("TextLabel")
startSub.Name = "Subtitle"
startSub.Text = "Grab the gold coins. Dodge the red hazards.\n60 seconds. 3 lives. Chain coins for combos!"
startSub.TextSize = 20
startSub.Font = Enum.Font.Gotham
startSub.TextColor3 = Color3.fromRGB(230, 230, 245)
startSub.BackgroundTransparency = 1
startSub.AnchorPoint = Vector2.new(0.5, 0.5)
startSub.Position = UDim2.new(0.5, 0, 0.5, 0)
startSub.Size = UDim2.fromOffset(560, 70)
startSub.Parent = startOverlay

local startHint = Instance.new("TextLabel")
startHint.Name = "Hint"
startHint.Text = "Move: Arrow keys or WASD   •   Press ENTER or click to start"
startHint.TextSize = 18
startHint.Font = Enum.Font.GothamBold
startHint.TextColor3 = Color3.fromRGB(255, 220, 90)
startHint.BackgroundTransparency = 1
startHint.AnchorPoint = Vector2.new(0.5, 0.5)
startHint.Position = UDim2.new(0.5, 0, 0.62, 0)
startHint.Size = UDim2.fromOffset(560, 30)
startHint.Parent = startOverlay

local startButton = Instance.new("TextButton")
startButton.Name = "StartButton"
startButton.Text = "▶  START"
startButton.TextSize = 26
startButton.Font = Enum.Font.GothamBlack
startButton.TextColor3 = Color3.fromRGB(10, 40, 50)
startButton.BackgroundColor3 = Color3.fromRGB(0, 229, 255)
startButton.AnchorPoint = Vector2.new(0.5, 0.5)
startButton.Position = UDim2.new(0.5, 0, 0.74, 0)
startButton.Size = UDim2.fromOffset(220, 56)
startButton.Parent = startOverlay
local startButtonCorner = Instance.new("UICorner")
startButtonCorner.CornerRadius = UDim.new(0.3, 0)
startButtonCorner.Parent = startButton

-- End overlay -------------------------------------------------------------
local endOverlay = Instance.new("Frame")
endOverlay.Name = "EndOverlay"
endOverlay.Size = UDim2.fromScale(1, 1)
endOverlay.BackgroundColor3 = Color3.fromRGB(12, 12, 24)
endOverlay.BackgroundTransparency = 0.15
endOverlay.BorderSizePixel = 0
endOverlay.Visible = false
endOverlay.Parent = background

local endTitle = Instance.new("TextLabel")
endTitle.Name = "Title"
endTitle.Text = "TIME UP!"
endTitle.TextSize = 44
endTitle.Font = Enum.Font.GothamBlack
endTitle.TextColor3 = Color3.fromRGB(255, 220, 90)
endTitle.BackgroundTransparency = 1
endTitle.AnchorPoint = Vector2.new(0.5, 0.5)
endTitle.Position = UDim2.new(0.5, 0, 0.38, 0)
endTitle.Size = UDim2.fromOffset(560, 60)
endTitle.Parent = endOverlay

local endStats = Instance.new("TextLabel")
endStats.Name = "Stats"
endStats.Text = ""
endStats.TextSize = 22
endStats.Font = Enum.Font.Gotham
endStats.TextColor3 = Color3.fromRGB(230, 230, 245)
endStats.BackgroundTransparency = 1
endStats.AnchorPoint = Vector2.new(0.5, 0.5)
endStats.Position = UDim2.new(0.5, 0, 0.52, 0)
endStats.Size = UDim2.fromOffset(560, 90)
endStats.Parent = endOverlay

local endHint = Instance.new("TextLabel")
endHint.Name = "Hint"
endHint.Text = "Press R or click to play again"
endHint.TextSize = 18
endHint.Font = Enum.Font.GothamBold
endHint.TextColor3 = Color3.fromRGB(0, 229, 255)
endHint.BackgroundTransparency = 1
endHint.AnchorPoint = Vector2.new(0.5, 0.5)
endHint.Position = UDim2.new(0.5, 0, 0.66, 0)
endHint.Size = UDim2.fromOffset(560, 30)
endHint.Parent = endOverlay

local restartButton = Instance.new("TextButton")
restartButton.Name = "RestartButton"
restartButton.Text = "↻  PLAY AGAIN"
restartButton.TextSize = 24
restartButton.Font = Enum.Font.GothamBlack
restartButton.TextColor3 = Color3.fromRGB(10, 40, 50)
restartButton.BackgroundColor3 = Color3.fromRGB(0, 229, 255)
restartButton.AnchorPoint = Vector2.new(0.5, 0.5)
restartButton.Position = UDim2.new(0.5, 0, 0.76, 0)
restartButton.Size = UDim2.fromOffset(240, 54)
restartButton.Parent = endOverlay
local restartCorner = Instance.new("UICorner")
restartCorner.CornerRadius = UDim.new(0.3, 0)
restartCorner.Parent = restartButton

local function placePlayer()
	playerFrame.Position = UDim2.fromOffset(math.floor(playerX + 0.5), math.floor(playerY + 0.5))
end

local function hearts(n)
	local s = ""
	for _ = 1, START_LIVES do
		if n > 0 then
			s = s .. "♥"
			n = n - 1
		else
			s = s .. "♡"
		end
	end
	return s
end

local function updateHUD()
	scoreLabel.Text = "SCORE  " .. tostring(score)
	livesLabel.Text = "LIVES  " .. hearts(lives)
	timeLabel.Text = "TIME  " .. tostring(math.max(0, math.ceil(timeLeft)))
	levelLabel.Text = "LEVEL  " .. tostring(level) .. (combo > 1 and ("   COMBO x" .. tostring(combo)) or "")
	timeBar.Size = UDim2.fromScale(math.clamp(timeLeft / GAME_TIME, 0, 1), 1)
	if timeLeft <= 10 then
		timeBar.BackgroundColor3 = Color3.fromRGB(255, 90, 120)
	else
		timeBar.BackgroundColor3 = Color3.fromRGB(255, 220, 90)
	end
end

local function clearCoins()
	for _, c in ipairs(coins) do
		c.frame:Destroy()
	end
	coins = {}
end

local function clearHazards()
	for _, h in ipairs(hazards) do
		h.frame:Destroy()
	end
	hazards = {}
end

local function spawnCoin()
	if #coins >= COIN_MAX then
		return
	end
	local frame = Instance.new("Frame")
	frame.Name = "Coin"
	frame.Size = UDim2.fromOffset(COIN_SIZE, COIN_SIZE)
	frame.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
	frame.BorderColor3 = Color3.fromRGB(160, 110, 0)
	frame.BorderSizePixel = 2
	frame.Parent = arena
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = frame
	local inner = Instance.new("TextLabel")
	inner.Name = "Glyph"
	inner.Text = "$"
	inner.TextSize = 18
	inner.Font = Enum.Font.GothamBlack
	inner.TextColor3 = Color3.fromRGB(120, 80, 0)
	inner.BackgroundTransparency = 1
	inner.Size = UDim2.fromScale(1, 1)
	inner.Parent = frame
	local cx = math.random(8, ARENA_W - COIN_SIZE - 8)
	local cy = math.random(8, ARENA_H - COIN_SIZE - 8)
	frame.Position = UDim2.fromOffset(cx, cy)
	table.insert(coins, { frame = frame, x = cx, y = cy, age = 0 })
end

local function spawnHazard()
	local speed = HAZARD_BASE_SPEED + (level - 1) * HAZARD_SPEED_PER_LEVEL
	local frame = Instance.new("Frame")
	frame.Name = "Hazard"
	frame.Size = UDim2.fromOffset(HAZARD_SIZE, HAZARD_SIZE)
	frame.BackgroundColor3 = Color3.fromRGB(255, 60, 80)
	frame.BorderColor3 = Color3.fromRGB(140, 0, 20)
	frame.BorderSizePixel = 2
	frame.Parent = arena
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.2, 0)
	corner.Parent = frame
	local mark = Instance.new("TextLabel")
	mark.Name = "Mark"
	mark.Text = "✕"
	mark.TextSize = 22
	mark.Font = Enum.Font.GothamBlack
	mark.TextColor3 = Color3.fromRGB(90, 0, 10)
	mark.BackgroundTransparency = 1
	mark.Size = UDim2.fromScale(1, 1)
	mark.Parent = frame
	-- Start at a random edge and drift diagonally across the arena.
	local edge = math.random(1, 4)
	local hx, hy
	if edge == 1 then
		hx, hy = math.random(0, ARENA_W - HAZARD_SIZE), 0
	elseif edge == 2 then
		hx, hy = math.random(0, ARENA_W - HAZARD_SIZE), ARENA_H - HAZARD_SIZE
	elseif edge == 3 then
		hx, hy = 0, math.random(0, ARENA_H - HAZARD_SIZE)
	else
		hx, hy = ARENA_W - HAZARD_SIZE, math.random(0, ARENA_H - HAZARD_SIZE)
	end
	local angle = math.rad(math.random(20, 160))
	local vx = math.cos(angle) * speed
	local vy = math.sin(angle) * speed
	if edge == 2 then
		vy = -math.abs(vy)
	elseif edge == 1 then
		vy = math.abs(vy)
	end
	if edge == 3 then
		vx = math.abs(vx)
	elseif edge == 4 then
		vx = -math.abs(vx)
	end
	frame.Position = UDim2.fromOffset(hx, hy)
	table.insert(hazards, { frame = frame, x = hx, y = hy, vx = vx, vy = vy })
end

local function overlaps(ax, ay, asize, bx, by, bsize)
	return ax < bx + bsize and ax + asize > bx and ay < by + bsize and ay + asize > by
end

local function startGame()
	playing = true
	score = 0
	coinsCollected = 0
	lives = START_LIVES
	timeLeft = GAME_TIME
	level = 1
	combo = 1
	comboTimer = 0
	invulnTimer = 0
	coinSpawnTimer = 0
	playerX = (ARENA_W - PLAYER_SIZE) / 2
	playerY = (ARENA_H - PLAYER_SIZE) / 2
	clearCoins()
	clearHazards()
	spawnCoin()
	spawnCoin()
	spawnHazard()
	spawnHazard()
	playerFrame.Visible = true
	startOverlay.Visible = false
	endOverlay.Visible = false
	placePlayer()
	updateHUD()
end

local function submitScore()
	local remote = ReplicatedStorage:FindFirstChild("SubmitScore")
	if remote then
		remote:FireServer(score, coinsCollected, level)
	end
end

local function endGame(reason)
	if not playing then
		return
	end
	playing = false
	submitScore()
	if reason == "time" then
		endTitle.Text = "TIME UP!"
		endTitle.TextColor3 = Color3.fromRGB(255, 220, 90)
	else
		endTitle.Text = "GAME OVER"
		endTitle.TextColor3 = Color3.fromRGB(255, 90, 120)
	end
	endStats.Text = "Score: " .. tostring(score)
		.. "\nCoins: " .. tostring(coinsCollected)
		.. "   •   Level reached: " .. tostring(level)
	endOverlay.Visible = true
	updateHUD()
end

local function collectCoin(c, i)
	c.frame:Destroy()
	table.remove(coins, i)
	coinsCollected = coinsCollected + 1
	if comboTimer > 0 then
		combo = math.min(combo + 1, 5)
	else
		combo = 1
	end
	comboTimer = COMBO_WINDOW
	score = score + 10 * combo
	if coinsCollected % COINS_PER_LEVEL == 0 then
		level = level + 1
		if #hazards < MAX_HAZARDS then
			spawnHazard()
		end
	end
	updateHUD()
end

local function hitHazard()
	if invulnTimer > 0 then
		return
	end
	lives = lives - 1
	invulnTimer = INVULN_TIME
	combo = 1
	comboTimer = 0
	updateHUD()
	if lives <= 0 then
		endGame("lives")
	end
end

startButton.MouseButton1Click:Connect(startGame)
restartButton.MouseButton1Click:Connect(startGame)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Return then
		if not playing and startOverlay.Visible then
			startGame()
		elseif not playing and endOverlay.Visible then
			startGame()
		end
	elseif input.KeyCode == Enum.KeyCode.R then
		if not playing and endOverlay.Visible then
			startGame()
		end
	end
end)

placePlayer()
updateHUD()
gui.Parent = player:WaitForChild("PlayerGui")

RunService.RenderStepped:Connect(function(dt)
	if not playing then
		return
	end
	timeLeft = timeLeft - dt
	comboTimer = comboTimer - dt
	if comboTimer <= 0 then
		combo = 1
	end
	if invulnTimer > 0 then
		invulnTimer = invulnTimer - dt
		blinkOn = not blinkOn
		playerFrame.BackgroundTransparency = blinkOn and 0.6 or 0
	else
		playerFrame.BackgroundTransparency = 0
	end
	if timeLeft <= 0 then
		timeLeft = 0
		updateHUD()
		endGame("time")
		return
	end

	-- Move the player with arrows or WASD.
	local dx = 0
	local dy = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.Left) or UserInputService:IsKeyDown(Enum.KeyCode.A) then
		dx = dx - 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Right) or UserInputService:IsKeyDown(Enum.KeyCode.D) then
		dx = dx + 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Up) or UserInputService:IsKeyDown(Enum.KeyCode.W) then
		dy = dy - 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Down) or UserInputService:IsKeyDown(Enum.KeyCode.S) then
		dy = dy + 1
	end
	if dx ~= 0 or dy ~= 0 then
		local len = math.sqrt(dx * dx + dy * dy)
		playerX = math.clamp(playerX + (dx / len) * PLAYER_SPEED * dt, 0, ARENA_W - PLAYER_SIZE)
		playerY = math.clamp(playerY + (dy / len) * PLAYER_SPEED * dt, 0, ARENA_H - PLAYER_SIZE)
		placePlayer()
	end

	-- Coins: age them out, then collect on overlap.
	coinSpawnTimer = coinSpawnTimer + dt
	if coinSpawnTimer >= COIN_SPAWN_EVERY then
		coinSpawnTimer = 0
		spawnCoin()
	end
	for i = #coins, 1, -1 do
		local c = coins[i]
		c.age = c.age + dt
		if c.age >= COIN_LIFETIME then
			c.frame:Destroy()
			table.remove(coins, i)
		elseif overlaps(playerX, playerY, PLAYER_SIZE, c.x, c.y, COIN_SIZE) then
			collectCoin(c, i)
		end
	end

	-- Hazards drift and bounce off the arena walls.
	for _, h in ipairs(hazards) do
		h.x = h.x + h.vx * dt
		h.y = h.y + h.vy * dt
		if h.x <= 0 then
			h.x = 0
			h.vx = math.abs(h.vx)
		elseif h.x >= ARENA_W - HAZARD_SIZE then
			h.x = ARENA_W - HAZARD_SIZE
			h.vx = -math.abs(h.vx)
		end
		if h.y <= 0 then
			h.y = 0
			h.vy = math.abs(h.vy)
		elseif h.y >= ARENA_H - HAZARD_SIZE then
			h.y = ARENA_H - HAZARD_SIZE
			h.vy = -math.abs(h.vy)
		end
		h.frame.Position = UDim2.fromOffset(math.floor(h.x + 0.5), math.floor(h.y + 0.5))
		if overlaps(playerX, playerY, PLAYER_SIZE, h.x, h.y, HAZARD_SIZE) then
			hitHazard()
			if not playing then
				return
			end
		end
	end

	updateHUD()
end)
