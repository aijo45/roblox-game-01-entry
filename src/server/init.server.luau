-- Neon Coin Rush server: keeps a tiny in-memory leaderboard.
-- The client fires SubmitScore when a run ends; the server records the
-- best runs and prints the top five. No DataStores, no purchases.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MAX_BOARD = 5
local board = {}

local submitScore = Instance.new("RemoteEvent")
submitScore.Name = "SubmitScore"
submitScore.Parent = ReplicatedStorage

local function recordRun(player, score, coins, level)
	if typeof(score) ~= "number" or score < 0 or score > 100000 then
		return
	end
	table.insert(board, {
		name = player.Name,
		score = math.floor(score),
		coins = coins or 0,
		level = level or 1,
	})
	table.sort(board, function(a, b)
		return a.score > b.score
	end)
	while #board > MAX_BOARD do
		table.remove(board)
	end
	print(("Neon Coin Rush: %s scored %d (%d coins, level %d)"):format(
		player.Name, math.floor(score), coins or 0, level or 1))
	print("Top runs:")
	for i, run in ipairs(board) do
		print(("  %d. %s — %d pts, %d coins, level %d"):format(
			i, run.name, run.score, run.coins, run.level))
	end
end

submitScore.OnServerEvent:Connect(recordRun)

Players.PlayerAdded:Connect(function(player)
	print("Neon Coin Rush: " .. player.Name .. " joined.")
end)

print("Neon Coin Rush server ready.")
