extends RigidBody3D

# ---------------------------------------------------------------------------
# KnockableObject — swipe to knock over, short steal window after impact
# ---------------------------------------------------------------------------

@export var points_on_knock: int = 50
@export var swipe_force: float = 8.0
@export var steal_window_seconds: float = 2.0

signal knocked_over(player_idx: int)

var _has_been_knocked: bool = false
var _knock_owner: int = -1
var _steal_timer: float = 0.0
var _steal_window_open: bool = false

# Original transform for optional reset
var _original_transform: Transform3D

@export var object_color: Color = Color(0.8, 0.55, 0.2)

func _ready() -> void:
	add_to_group("chaos_interactable")
	_original_transform = global_transform
	freeze = true
	# Apply color to mesh
	var mesh_node := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_node:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = object_color
		mesh_node.material_override = mat

func _physics_process(delta: float) -> void:
	if _steal_window_open:
		_steal_timer -= delta
		if _steal_timer <= 0.0:
			_steal_window_open = false

# ------------------------------------------------------------------
# ChaosInteractable interface (called directly since this IS the root)
# ------------------------------------------------------------------

func on_interact(cat: Node) -> void:
	if _has_been_knocked:
		_try_steal(cat)
		return
	_knock(cat)

func on_hold_start(_cat: Node) -> void:
	pass  # No hold behaviour for basic knockable

func on_hold_tick(_cat: Node, _delta: float) -> void:
	pass

func on_hold_end(_cat: Node) -> void:
	pass

# ------------------------------------------------------------------

func _knock(cat: Node) -> void:
	_has_been_knocked = true
	_knock_owner = (cat as Node3D).get("player_index") as int
	freeze = false

	# Apply force away from the cat's position
	var dir: Vector3 = (global_position - (cat as Node3D).global_position).normalized()
	dir.y = 0.3  # Slight upward arc
	apply_central_impulse(dir * swipe_force)

	ScoreManager.add_score(_knock_owner, points_on_knock, "knockover")
	knocked_over.emit(_knock_owner)
	AudioManager.play_sfx("knock")

	# Open steal window for opponent
	_steal_window_open = true
	_steal_timer = steal_window_seconds

func _try_steal(cat: Node) -> void:
	if not _steal_window_open:
		return
	var stealer: int = (cat as Node3D).get("player_index") as int
	if stealer == _knock_owner:
		return
	# Transfer half the knock points
	var steal_pts: int = points_on_knock / 2
	ScoreManager.steal_score(stealer, _knock_owner, steal_pts)
	_knock_owner = stealer
	_steal_window_open = false
	AudioManager.play_sfx("steal")

func reset_object() -> void:
	freeze = true
	global_transform = _original_transform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_has_been_knocked = false
	_knock_owner = -1
	_steal_window_open = false
