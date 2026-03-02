extends CharacterBody3D

# ---------------------------------------------------------------------------
# CatController — movement, sprint, interact, sit / claim
# ---------------------------------------------------------------------------

@export var player_index: int = 0
@export var move_speed: float = 5.0
@export var sprint_multiplier: float = 1.8
@export var acceleration: float = 18.0
@export var rotation_speed: float = 12.0

@onready var shape_cast: ShapeCast3D = $ShapeCast3D
@onready var claim_territory: Node = $ClaimTerritory

var _prefix: String = ""
var _is_sitting: bool = false
var _interact_hold_timer: float = 0.0
var _interact_held: bool = false
const HOLD_THRESHOLD: float = 0.2
const GRAVITY: float = 9.8

# Colors per player
const PLAYER_COLORS: Array = [Color(1.0, 0.45, 0.1), Color(0.25, 0.55, 1.0)]
const BODY_COLOR_DARK: Array = [Color(0.8, 0.3, 0.05), Color(0.15, 0.35, 0.8)]

func _ready() -> void:
	_prefix = "p%d_" % (player_index + 1)
	add_to_group("cats")
	add_to_group("player_%d" % player_index)
	_build_cat_mesh()

# ── Procedural cat body ──────────────────────────────────────────────────
func _build_cat_mesh() -> void:
	var color: Color = PLAYER_COLORS[player_index]

	# Body — slightly flattened sphere
	var body := MeshInstance3D.new()
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.28
	body_mesh.height = 0.42
	body.mesh = body_mesh
	body.position = Vector3(0, 0.28, 0)
	body.material_override = _mat(color)
	add_child(body)

	# Head
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.32
	head.mesh = head_mesh
	head.position = Vector3(0, 0.62, 0.1)
	head.material_override = _mat(color)
	add_child(head)

	# Left ear
	var ear_l := MeshInstance3D.new()
	var ear_mesh_l := PrismMesh.new()
	ear_mesh_l.size = Vector3(0.10, 0.14, 0.06)
	ear_l.mesh = ear_mesh_l
	ear_l.position = Vector3(-0.12, 0.82, 0.08)
	ear_l.material_override = _mat(color)
	add_child(ear_l)

	# Right ear
	var ear_r := MeshInstance3D.new()
	var ear_mesh_r := PrismMesh.new()
	ear_mesh_r.size = Vector3(0.10, 0.14, 0.06)
	ear_r.mesh = ear_mesh_r
	ear_r.position = Vector3(0.12, 0.82, 0.08)
	ear_r.material_override = _mat(color)
	add_child(ear_r)

	# Nose dot
	var nose := MeshInstance3D.new()
	var nose_mesh := SphereMesh.new()
	nose_mesh.radius = 0.04
	nose.mesh = nose_mesh
	nose.position = Vector3(0, 0.6, 0.3)
	nose.material_override = _mat(Color(0.9, 0.4, 0.55))
	add_child(nose)

	# Tail
	var tail := MeshInstance3D.new()
	var tail_mesh := CapsuleMesh.new()
	tail_mesh.radius = 0.05
	tail_mesh.height = 0.5
	tail.mesh = tail_mesh
	tail.position = Vector3(0, 0.35, -0.35)
	tail.rotation_degrees.x = 40
	tail.material_override = _mat(BODY_COLOR_DARK[player_index])
	add_child(tail)

	# Player label floating above
	var label := Label3D.new()
	label.text = "P%d" % (player_index + 1)
	label.font_size = 48
	label.position = Vector3(0, 1.1, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color
	label.outline_modulate = Color.BLACK
	label.outline_render_priority = -1
	add_child(label)

func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	return m

# ── Physics ────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	_apply_gravity(delta)
	_handle_movement(delta)
	_handle_interact(delta)
	_handle_sit()
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

func _handle_movement(delta: float) -> void:
	if _is_sitting:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		return

	var raw := Vector2(
		Input.get_axis(_prefix + "move_left", _prefix + "move_right"),
		Input.get_axis(_prefix + "move_forward", _prefix + "move_back")
	)

	# Ask SplitScreenManager for the current flat basis for this player.
	# This automatically accounts for the player's current camera rotation.
	var basis := _get_flat_basis()
	var move_dir := basis * Vector3(raw.x, 0.0, raw.y)
	move_dir.y = 0.0
	if move_dir.length() > 0.01:
		move_dir = move_dir.normalized()

	var sprinting := Input.is_action_pressed(_prefix + "sprint")
	var speed := move_speed * (sprint_multiplier if sprinting else 1.0)

	velocity.x = move_toward(velocity.x, move_dir.x * speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, move_dir.z * speed, acceleration * delta)

	# Rotate cat to face movement direction
	if move_dir.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(move_dir.x, move_dir.z), rotation_speed * delta)

func _get_flat_basis() -> Basis:
	# Get the SplitScreenManager from the scene tree and ask for our basis
	var mgr := get_tree().get_nodes_in_group("split_screen_manager")
	if mgr.size() > 0 and mgr[0].has_method("get_flat_basis"):
		return mgr[0].get_flat_basis(player_index)
	# Fallback: default iso axes
	var fwd := Vector3(-1.0, 0.0, -1.0).normalized()
	var right := Vector3(1.0, 0.0, -1.0).normalized()
	return Basis(right, Vector3.UP, -fwd)

# ── Interaction ────────────────────────────────────────────────────────────
func _handle_interact(delta: float) -> void:
	if Input.is_action_just_pressed(_prefix + "interact"):
		_interact_hold_timer = 0.0
		_interact_held = false

	if Input.is_action_pressed(_prefix + "interact"):
		_interact_hold_timer += delta
		if not _interact_held and _interact_hold_timer >= HOLD_THRESHOLD:
			_interact_held = true
			var t := _nearest_interactable()
			if t and t.has_method("on_hold_start"):
				t.on_hold_start(self)
		elif _interact_held:
			var t := _nearest_interactable()
			if t and t.has_method("on_hold_tick"):
				t.on_hold_tick(self, delta)

	if Input.is_action_just_released(_prefix + "interact") and not _interact_held:
		var t := _nearest_interactable()
		if t and t.has_method("on_interact"):
			t.on_interact(self)

func _nearest_interactable() -> Node:
	if not shape_cast:
		return null
	shape_cast.force_shapecast_update()
	for i in range(shape_cast.get_collision_count()):
		var c := shape_cast.get_collider(i)
		if not c:
			continue
		if c.is_in_group("chaos_interactable"):
			return c
		if c.get_parent() and c.get_parent().is_in_group("chaos_interactable"):
			return c.get_parent()
	return null

# ── Sit / Claim ─────────────────────────────────────────────────────────
func _handle_sit() -> void:
	if Input.is_action_just_pressed(_prefix + "sit"):
		_is_sitting = not _is_sitting
		if _is_sitting:
			if claim_territory:
				claim_territory.start_claim(player_index)
		else:
			if claim_territory:
				claim_territory.stop_claim()

func get_player_index() -> int:
	return player_index

func is_sitting() -> bool:
	return _is_sitting
