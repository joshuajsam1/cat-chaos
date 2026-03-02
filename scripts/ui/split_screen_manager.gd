extends Node

# ---------------------------------------------------------------------------
# SplitScreenManager — isometric camera with smooth rotation animation.
#
# Two angle values per player:
#   _target_angles  — snaps to the next 90° on each key press (instant)
#   _angles         — smoothly lerps toward _target_angles each frame
#
# Camera position uses _angles (animated).
# Movement basis uses _target_angles (snaps immediately so input feels tight).
# ---------------------------------------------------------------------------

const ISO_DIST    : float = 9.0
const PAN_SPEED   : float = 8.0
const ROT_STEP    : float = PI / 2.0   # 90° per press
const ROT_SPEED   : float = 12.0       # radians / sec for the animation

const PREFIXES : Array[String] = ["p1_", "p2_"]

var _cameras       : Array[Camera3D] = []
var _targets       : Array[Node3D]   = []
var _angles        : Array[float]    = [0.0, 0.0]   # animated current angle
var _target_angles : Array[float]    = [0.0, 0.0]   # snapped target angle

func _ready() -> void:
	add_to_group("split_screen_manager")

func set_cameras(cam_p1: Camera3D, cam_p2: Camera3D) -> void:
	_cameras = [cam_p1, cam_p2]
	cam_p1.add_to_group("camera_p1")
	cam_p2.add_to_group("camera_p2")
	for idx in range(2):
		var offset := _iso_offset(_angles[idx])
		_cameras[idx].position = offset
		_cameras[idx].look_at(Vector3.ZERO, Vector3.UP)

func find_cats_now() -> void:
	_targets.clear()
	for idx in range(2):
		var nodes := get_tree().get_nodes_in_group("player_%d" % idx)
		_targets.append(nodes[0] as Node3D if nodes.size() > 0 else null)

# ── Helpers ────────────────────────────────────────────────────────────────

func _iso_offset(angle: float) -> Vector3:
	# Rotate the base (1,1,1) isometric offset around Y
	return Vector3(ISO_DIST, ISO_DIST, ISO_DIST).rotated(Vector3.UP, angle)

# ── Per-frame ──────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_handle_rotation_input()
	_animate_rotation(delta)
	_update_cameras(delta)

func _handle_rotation_input() -> void:
	for idx in range(2):
		var p := PREFIXES[idx]
		if Input.is_action_just_pressed(p + "rotate_cw"):
			_target_angles[idx] += ROT_STEP
			AudioManager.play_sfx("rotate")
		if Input.is_action_just_pressed(p + "rotate_ccw"):
			_target_angles[idx] -= ROT_STEP

func _animate_rotation(delta: float) -> void:
	# Smooth ease-out lerp of each player's animated angle toward its target
	for idx in range(2):
		_angles[idx] = lerp_angle(_angles[idx], _target_angles[idx], ROT_SPEED * delta)

func _update_cameras(delta: float) -> void:
	# Lazy-find cats
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
		var offset := _iso_offset(_angles[idx])   # animated angle for camera

		var desired := target.global_position + offset
		cam.global_position = cam.global_position.lerp(desired, PAN_SPEED * delta)
		cam.look_at(cam.global_position - offset, Vector3.UP)

# ── Movement basis (called by CatController) ────────────────────────────────
# Uses _target_angles so movement direction snaps to the new angle instantly,
# making WASD feel tight even mid-rotation animation.

func get_flat_basis(player_idx: int) -> Basis:
	if player_idx >= _target_angles.size():
		return Basis.IDENTITY
	var offset := _iso_offset(_target_angles[player_idx])
	# Camera looks from offset toward origin, so its forward in world-space is
	# the direction FROM offset TOWARD origin, flattened onto XZ.
	var flat_fwd   := -Vector3(offset.x, 0.0, offset.z).normalized()
	# Right = forward × up  (standard camera right-hand rule)
	var flat_right := flat_fwd.cross(Vector3.UP).normalized()
	# Basis columns: X=right, Y=up, Z=back (-forward)
	return Basis(flat_right, Vector3.UP, -flat_fwd)
