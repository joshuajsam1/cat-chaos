extends CharacterBody3D

# ---------------------------------------------------------------------------
# OwnerNPC — walks from front door to living room using NavigationAgent3D
# ---------------------------------------------------------------------------

@export var walk_speed: float = 3.0
@export var arrival_threshold: float = 0.5

# Waypoints defined in the scene or set by house.tscn
@export var waypoints: Array[NodePath] = []

var _waypoint_nodes: Array[Node3D] = []
var _current_waypoint: int = 0
var _active: bool = false

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

const GRAVITY: float = 9.8

func _ready() -> void:
	visible = false
	set_physics_process(false)

	# Resolve waypoint node paths
	for path in waypoints:
		var node := get_node_or_null(path)
		if node:
			_waypoint_nodes.append(node as Node3D)

	# Listen for owner_arrived signal from TimerManager
	TimerManager.owner_arrived.connect(_activate)

func _activate() -> void:
	visible = true
	set_physics_process(true)
	_current_waypoint = 0
	_set_next_target()
	if anim_player and anim_player.has_animation("walk"):
		anim_player.play("walk")
	AudioManager.play_sfx("door_open")

func _set_next_target() -> void:
	if _current_waypoint < _waypoint_nodes.size():
		nav_agent.target_position = _waypoint_nodes[_current_waypoint].global_position

func _physics_process(delta: float) -> void:
	if not _active:
		_active = true  # First frame after activation
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if nav_agent.is_navigation_finished():
		_current_waypoint += 1
		if _current_waypoint >= _waypoint_nodes.size():
			_on_reached_destination()
			return
		_set_next_target()

	var next_pos := nav_agent.get_next_path_position()
	var dir := (next_pos - global_position).normalized()
	dir.y = 0.0

	velocity.x = dir.x * walk_speed
	velocity.z = dir.z * walk_speed

	# Face movement direction
	if dir.length() > 0.01:
		rotation.y = atan2(dir.x, dir.z)

	move_and_slide()

func _on_reached_destination() -> void:
	set_physics_process(false)
	if anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")
	# The game timer will fire game_over shortly after; owner just stands there
