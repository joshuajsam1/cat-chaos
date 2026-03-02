extends Node

# ---------------------------------------------------------------------------
# ScoreManager — per-player scores, action stats, steal tracking
# ---------------------------------------------------------------------------

signal score_changed(player_idx: int, new_score: int)
signal steal_occurred(thief_idx: int, victim_idx: int, points_stolen: int)

const PLAYER_COUNT: int = 2

# Live scores
var scores: Array[int] = [0, 0]

# Detailed stat tracking per player
# Each entry: { knockovers, tp_unrolled, laptop_uptime, claims, steals, innocent_bonus }
var stats: Array[Dictionary] = []

func _ready() -> void:
	reset()

func reset() -> void:
	scores = [0, 0]
	stats = []
	for i in range(PLAYER_COUNT):
		stats.append({
			"knockovers": 0,
			"tp_unrolled": 0,
			"laptop_uptime": 0,
			"claims": 0,
			"steals": 0,
			"innocent_bonus": 0,
		})

func add_score(player_idx: int, points: int, action: String = "") -> void:
	if player_idx < 0 or player_idx >= PLAYER_COUNT:
		return
	scores[player_idx] = max(0, scores[player_idx] + points)
	score_changed.emit(player_idx, scores[player_idx])
	_record_stat(player_idx, action, points)

func steal_score(thief_idx: int, victim_idx: int, points: int) -> void:
	if thief_idx < 0 or thief_idx >= PLAYER_COUNT:
		return
	if victim_idx < 0 or victim_idx >= PLAYER_COUNT:
		return
	var actual: int = min(points, scores[victim_idx])
	scores[victim_idx] = max(0, scores[victim_idx] - actual)
	scores[thief_idx] += actual
	stats[thief_idx]["steals"] += 1
	score_changed.emit(victim_idx, scores[victim_idx])
	score_changed.emit(thief_idx, scores[thief_idx])
	steal_occurred.emit(thief_idx, victim_idx, actual)

func get_score(player_idx: int) -> int:
	if player_idx < 0 or player_idx >= PLAYER_COUNT:
		return 0
	return scores[player_idx]

func get_winner() -> int:
	# Returns 0, 1, or -1 for tie
	if scores[0] > scores[1]:
		return 0
	elif scores[1] > scores[0]:
		return 1
	return -1

func get_stats(player_idx: int) -> Dictionary:
	if player_idx < 0 or player_idx >= PLAYER_COUNT:
		return {}
	return stats[player_idx]

func _record_stat(player_idx: int, action: String, points: int) -> void:
	match action:
		"knockover":
			stats[player_idx]["knockovers"] += 1
		"tp_unroll":
			stats[player_idx]["tp_unrolled"] += points
		"laptop":
			stats[player_idx]["laptop_uptime"] += points
		"claim":
			stats[player_idx]["claims"] += 1
		"innocent":
			stats[player_idx]["innocent_bonus"] += points
		_:
			pass
