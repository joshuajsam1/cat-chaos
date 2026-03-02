extends Node

# ---------------------------------------------------------------------------
# ClaimTerritory — while cat sits, claims nearby interactables and steals
# points from the opponent's claimed objects.
# ---------------------------------------------------------------------------

@export var claim_radius: float = 2.5
@export var claim_tick_interval: float = 1.0   # seconds between steal ticks
@export var steal_points_per_tick: int = 15
@export var points_per_claim: int = 30

var _player_idx: int = -1
var _active: bool = false
var _tick_timer: float = 0.0

func start_claim(player_idx: int) -> void:
	_player_idx = player_idx
	_active = true
	_tick_timer = 0.0
	_claim_nearby()

func stop_claim() -> void:
	_active = false

func _process(delta: float) -> void:
	if not _active:
		return
	_tick_timer += delta
	if _tick_timer >= claim_tick_interval:
		_tick_timer -= claim_tick_interval
		_steal_nearby()

func _claim_nearby() -> void:
	var origin: Vector3 = get_parent().global_position
	for node in get_tree().get_nodes_in_group("chaos_interactable"):
		var dist := origin.distance_to(node.global_position)
		if dist <= claim_radius:
			if node.has_method("claim"):
				node.claim(_player_idx)
				ScoreManager.add_score(_player_idx, points_per_claim, "claim")
				AudioManager.play_sfx("claim")

func _steal_nearby() -> void:
	var origin: Vector3 = get_parent().global_position
	for node in get_tree().get_nodes_in_group("chaos_interactable"):
		var dist := origin.distance_to(node.global_position)
		if dist <= claim_radius:
			# Check if claimed by opponent
			var owner_prop = node.get("claimed_by") if node.get("claimed_by") != null else -1
			if owner_prop >= 0 and owner_prop != _player_idx:
				if node.has_method("try_steal"):
					node.try_steal(_player_idx)
				ScoreManager.steal_score(_player_idx, owner_prop, steal_points_per_tick)
