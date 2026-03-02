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
	# ── 1. Game world lives inside P1's viewport ──────────────────
	p1_viewport.own_world_3d = true
	var game_res: PackedScene = load("res://scenes/game.tscn")
	_game_scene = game_res.instantiate()
	p1_viewport.add_child(_game_scene)

	# ── 2. P1 camera inside P1 viewport ──────────────────────────
	_cam_p1 = Camera3D.new()
	_cam_p1.fov = 55.0
	# Start at isometric offset above P1 spawn (2,0,2)
	_cam_p1.position = Vector3(2.0, 0.0, 2.0) + Vector3(9, 9, 9)
	_cam_p1.look_at(Vector3(2.0, 0.0, 2.0), Vector3.UP)
	p1_viewport.add_child(_cam_p1)
	_cam_p1.make_current()

	# ── 3. Wait one frame so P1's World3D is fully initialized ────
	await get_tree().process_frame

	# ── 4. Share P1's World3D with P2 ────────────────────────────
	p2_viewport.world_3d = p1_viewport.find_world_3d()

	# ── 5. P2 camera inside P2 viewport (sees same world) ─────────
	_cam_p2 = Camera3D.new()
	_cam_p2.fov = 55.0
	# Start at isometric offset above P2 spawn (-2,0,2)
	_cam_p2.position = Vector3(-2.0, 0.0, 2.0) + Vector3(9, 9, 9)
	_cam_p2.look_at(Vector3(-2.0, 0.0, 2.0), Vector3.UP)
	p2_viewport.add_child(_cam_p2)
	_cam_p2.make_current()

	# ── 6. Register cameras and find cats immediately ─────────────
	split_screen_mgr.set_cameras(_cam_p1, _cam_p2)
	split_screen_mgr.find_cats_now()

	# ── 7. Countdown overlay + start ──────────────────────────────
	var cd_res: PackedScene = load("res://scenes/ui/countdown_overlay.tscn")
	add_child(cd_res.instantiate())

	await get_tree().process_frame
	GameManager.start_game()
