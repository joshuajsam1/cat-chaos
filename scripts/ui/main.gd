extends Node

# ---------------------------------------------------------------------------
# Main — bootstraps split-screen.
#
# Architecture (Godot 4 guaranteed approach):
#   Game scene lives inside P1SubViewport (own_world_3d = true).
#   P2SubViewport.world_3d is set to the same World3D as P1's, so both
#   cameras see the exact same physics simulation from different angles.
# ---------------------------------------------------------------------------

@onready var split_screen_mgr: Node = $SplitScreenManager
@onready var p1_viewport: SubViewport = $SplitContainer/P1ViewportContainer/P1SubViewport
@onready var p2_viewport: SubViewport = $SplitContainer/P2ViewportContainer/P2SubViewport

var _game_scene: Node3D = null
var _cam_p1: Camera3D = null
var _cam_p2: Camera3D = null

func _ready() -> void:
	# ── 1. Game world lives inside P2's viewport (right side) ─────
	# P1 camera is in p1_viewport (left), sharing P2's world.
	# This ensures the "primary" world renders on the right and the
	# shared viewport on the left, giving stable left = P1 rendering.
	p2_viewport.own_world_3d = true
	var game_res: PackedScene = load("res://scenes/game.tscn")
	_game_scene = game_res.instantiate()
	p2_viewport.add_child(_game_scene)

	# ── 2. P2 camera inside P2 viewport (right side) ─────────────
	_cam_p2 = Camera3D.new()
	_cam_p2.fov = 55.0
	_cam_p2.position = Vector3(-2.0, 0.0, 2.0) + Vector3(9, 9, 9)
	_cam_p2.look_at(Vector3(-2.0, 0.0, 2.0), Vector3.UP)
	p2_viewport.add_child(_cam_p2)
	_cam_p2.make_current()

	# ── 3. Wait one frame so P2's World3D is fully initialized ────
	await get_tree().process_frame

	# ── 4. Share P2's World3D with P1 ────────────────────────────
	p1_viewport.world_3d = p2_viewport.find_world_3d()

	# ── 5. P1 camera inside P1 viewport (left side) ───────────────
	_cam_p1 = Camera3D.new()
	_cam_p1.fov = 55.0
	_cam_p1.position = Vector3(2.0, 0.0, 2.0) + Vector3(9, 9, 9)
	_cam_p1.look_at(Vector3(2.0, 0.0, 2.0), Vector3.UP)
	p1_viewport.add_child(_cam_p1)
	_cam_p1.make_current()

	# ── 6. Register cameras and find cats immediately ─────────────
	split_screen_mgr.set_cameras(_cam_p1, _cam_p2)
	split_screen_mgr.find_cats_now()

	# ── 7. Countdown overlay + start ──────────────────────────────
	var cd_res: PackedScene = load("res://scenes/ui/countdown_overlay.tscn")
	add_child(cd_res.instantiate())

	await get_tree().process_frame
	GameManager.start_game()
