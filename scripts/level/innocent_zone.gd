extends Area3D

# ---------------------------------------------------------------------------
# InnocentZone — sofa Area3D that grants innocence bonus at game end
# ---------------------------------------------------------------------------

@export var innocence_bonus: int = 100

# Tracks which cats are currently inside
var _cats_inside: Array[int] = []

signal cat_entered_sofa(player_idx: int)
signal cat_left_sofa(player_idx: int)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameManager.game_ended.connect(_on_game_ended)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("cats"):
		return
	if not body.has_method("get_player_index"):
		return
	var idx: int = body.get_player_index()
	if idx not in _cats_inside:
		_cats_inside.append(idx)
		cat_entered_sofa.emit(idx)

func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("cats"):
		return
	if not body.has_method("get_player_index"):
		return
	var idx: int = body.get_player_index()
	_cats_inside.erase(idx)
	cat_left_sofa.emit(idx)

func _on_game_ended() -> void:
	# Award bonus to any cat sitting on the sofa when time runs out
	for idx in _cats_inside:
		ScoreManager.add_score(idx, innocence_bonus, "innocent")
		AudioManager.play_sfx("innocence")

func get_innocent_cats() -> Array[int]:
	return _cats_inside.duplicate()
