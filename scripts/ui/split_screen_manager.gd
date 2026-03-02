extends Node

# ---------------------------------------------------------------------------
# SplitScreenManager — isometric camera with per-player 90° rotation snapping.
# Q / E  →  rotate P1's view CCW / CW
# , / .  →  rotate P2's view CCW / CW
# ---------------------------------------------------------------------------

const ISO_DIST  : float = 9.0    # distance along each axis
const PAN_SPEED : float = 8.0    # lerp speed for panning
const ROT_STEP  : float = PI / 2.0  # 90° per press

var _cameras  : Array[Camera3D] = []
var _targets  : Array[Node3D]   = []
# Per-player current rotation around Y (radians)
var _angles   : Array[float]    = [0.0, 0.0]
# Prefix for input actions
const PREFIXES : Array[String]  = ["p1_", "p2_"]

func _ready() -> void:
	add_to_group("split_screen_manager")

func set_cameras(cam_p1: Camera3D, cam_p2: Camera3D) -> void:
	_cameras = [cam_p1, cam_p2]
	cam_p1.add_to_group("camera_p1")
	cam_p2.add_to_group("camera_p2")
	for idx in range(2):
		_apply_camera_transform(_cameras[idx], _angles[idx])

func find_cats_now() -> void:
	_targets.clear()
	for idx in range(2):
		var nodes := get_tree().get_nodes_in_group("player_%d" % idx)
		_targets.append(nodes[0] as Node3D if nodes.size() > 0 else null)

# Returns the current offset vector for a given angle
func _iso_offset(angle: float) -> Vector3:
	return Vector3(ISO_DIST, ISO_DIST, ISO_DIST).rotated(Vector3.UP, angle)

func _apply_camera_transform(cam: Camera3D, angle: float) -> void:
	var offset := _iso_offset(angle)
	cam.position = offset
	cam.look_at(Vector3.ZERO, Vector3.UP)

func _process(delta: float) -> void:
	_handle_rotation_input()
	_update_cameras(delta)

func _handle_rotation_input() -> void:
	for idx in range(2):
		var prefix := PREFIXES[idx]
		if Input.is_action_just_pressed(prefix + "rotate_cw"):
			_angles[idx] += ROT_STEP
			AudioManager.play_sfx("rotate")
		if Input.is_action_just_pressed(prefix + "rotate_ccw"):
			_angles[idx] -= ROT_STEP

func _update_cameras(delta: float) -> void:
	# Lazy-find cats each frame until found
	for idx in range(2):
		if idx >= _targets.size() or _targets[idx] == null:
			var nodes := get_tree().get_nodes_in_group("player_%d" % idx)
			if nodes.size() > 0:
				if idx >= _targets.size():
					_targets.append(nodes[0] as Node3D)
				else:
					_targets[idx] = nodes[0] as Node3D

	for idx in range(_cameras.size()):
		if idx >= _targets.size() or _targets[idx] == null:
			continue
		var cam    := _cameras[idx]
		var target := _targets[idx]
		var offset := _iso_offset(_angles[idx])

		# Smoothly pan to follow cat
		var desired := target.global_position + offset
		cam.global_position = cam.global_position.lerp(desired, PAN_SPEED * delta)
		# Lock look direction to always point from camera toward cat
		cam.look_at(cam.global_position - offset, Vector3.UP)

# Called by cat_controller to get its camera's current flat movement basis
func get_flat_basis(player_idx: int) -> Basis:
	if player_idx >= _angles.size():
		return Basis.IDENTITY
	var angle := _angles[player_idx]
	# Forward in world space for this angle (opposite of offset XZ)
	var fwd := Vector3(-sin(angle) - cos(angle), 0.0, -sin(angle) - cos(angle))
	# Recompute cleanly from the offset direction
	var offset_xz := Vector2(sin(angle) + cos(angle), sin(angle) + cos(angle))
	# Simpler: derive from the iso offset flattened
	var off := _iso_offset(angle)
	var flat_fwd := -Vector3(off.x, 0.0, off.z).normalized()
	var flat_right := flat_fwd.cross(Vector3.DOWN).normalized()
	return Basis(flat_right, Vector3.UP, -flat_fwd)
