extends Node

# ---------------------------------------------------------------------------
# SplitScreenManager — fixed isometric camera, pans to follow each cat.
# The camera never rotates. It stays locked at a 45° isometric angle and
# smoothly slides its position to keep the cat centred.
# ---------------------------------------------------------------------------

# Isometric offset from the cat: equal XYZ gives true iso angle
const ISO_OFFSET := Vector3(9.0, 9.0, 9.0)
const PAN_SPEED  := 8.0   # lerp speed for panning

var _cameras: Array[Camera3D] = []
var _targets: Array[Node3D] = []

func set_cameras(cam_p1: Camera3D, cam_p2: Camera3D) -> void:
	_cameras = [cam_p1, cam_p2]
	cam_p1.add_to_group("camera_p1")
	cam_p2.add_to_group("camera_p2")
	_lock_iso(cam_p1)
	_lock_iso(cam_p2)

func _lock_iso(cam: Camera3D) -> void:
	# Point once at origin so the look_at direction is correct.
	# After this the camera's *rotation* never changes — only position shifts.
	cam.position = ISO_OFFSET
	cam.look_at(Vector3.ZERO, Vector3.UP)

func find_cats_now() -> void:
	_targets.clear()
	for idx in range(2):
		var nodes := get_tree().get_nodes_in_group("player_%d" % idx)
		_targets.append(nodes[0] as Node3D if nodes.size() > 0 else null)

func _process(delta: float) -> void:
	# Lazy-find cats if not yet located
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

		# Slide camera position — keep the fixed offset, never rotate
		var desired := target.global_position + ISO_OFFSET
		cam.global_position = cam.global_position.lerp(desired, PAN_SPEED * delta)
		# Re-apply the look_at every frame so it stays locked even if
		# floating-point drift ever nudges it
		cam.look_at(cam.global_position - ISO_OFFSET, Vector3.UP)
