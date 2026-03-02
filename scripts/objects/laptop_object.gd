extends Node3D

# ---------------------------------------------------------------------------
# LaptopObject — Area3D trigger gives passive pts/sec while cat stands on it
# ---------------------------------------------------------------------------

@export var points_per_second: float = 10.0
@export var activation_points: int = 25   # immediate bonus on first activation

signal activated(player_idx: int)
signal deactivated

var _active_cat_idx: int = -1
var _accumulator: float = 0.0

@onready var area: Area3D = $Area3D

func _ready() -> void:
	add_to_group("chaos_interactable")
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if _active_cat_idx < 0:
		return
	_accumulator += points_per_second * delta
	if _accumulator >= 1.0:
		var pts: int = int(_accumulator)
		_accumulator -= pts
		ScoreManager.add_score(_active_cat_idx, pts, "laptop")

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("cats"):
		return
	if not body.has_method("get_player_index"):
		return
	var idx: int = body.get_player_index()
	if _active_cat_idx == idx:
		return
	_active_cat_idx = idx
	ScoreManager.add_score(idx, activation_points, "laptop")
	activated.emit(idx)
	AudioManager.play_sfx("laptop_open")

func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("cats"):
		return
	if body.has_method("get_player_index") and body.get_player_index() == _active_cat_idx:
		_active_cat_idx = -1
		_accumulator = 0.0
		deactivated.emit()

# ChaosInteractable interface (tap to knock the laptop off the table)
func on_interact(cat: Node) -> void:
	var rb: RigidBody3D = $RigidBody3D if has_node("RigidBody3D") else null
	if rb:
		rb.freeze = false
		var dir: Vector3 = (global_position - (cat as Node3D).global_position).normalized()
		dir.y = 0.4
		rb.apply_central_impulse(dir * 6.0)
	ScoreManager.add_score(cat.get_player_index(), 30, "knockover")
	AudioManager.play_sfx("laptop_knock")
