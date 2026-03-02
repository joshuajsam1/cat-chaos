extends RigidBody3D

# ---------------------------------------------------------------------------
# ToiletPaperRoll — hold interact to unroll, spawns paper trail segments
# ---------------------------------------------------------------------------

@export var points_per_meter: float = 5.0
@export var unroll_speed: float = 2.0         # metres of paper per second
@export var max_paper_length: float = 20.0    # total metres before depleted
@export var segment_spawn_interval: float = 0.15

# Paper segment scene (a flat quad / CSG box)
@export var paper_segment_scene: PackedScene

signal fully_unrolled(player_idx: int)

var _unrolling: bool = false
var _owner_idx: int = -1
var _paper_spawned: float = 0.0
var _segment_timer: float = 0.0
var _accumulated_pts: float = 0.0

# Steal: stolen segments belong to thief
var _segments: Array[Node3D] = []

func _ready() -> void:
	add_to_group("chaos_interactable")

func _physics_process(delta: float) -> void:
	if not _unrolling:
		return

	# Accumulate paper
	var amount := unroll_speed * delta
	_paper_spawned += amount
	_accumulated_pts += amount * points_per_meter
	ScoreManager.add_score(_owner_idx, int(_accumulated_pts), "tp_unroll")
	_accumulated_pts -= int(_accumulated_pts)  # keep fractional

	# Spawn visual segment
	_segment_timer -= delta
	if _segment_timer <= 0.0:
		_segment_timer = segment_spawn_interval
		_spawn_segment()

	if _paper_spawned >= max_paper_length:
		_unrolling = false
		fully_unrolled.emit(_owner_idx)

func on_interact(_cat: Node) -> void:
	# Tap to swipe the roll (like KnockableObject)
	freeze = false
	var dir := Vector3(randf_range(-1, 1), 0.2, randf_range(-1, 1)).normalized()
	apply_central_impulse(dir * 5.0)
	AudioManager.play_sfx("tp_swipe")

func on_hold_start(cat: Node) -> void:
	if _paper_spawned >= max_paper_length:
		return
	_unrolling = true
	_owner_idx = cat.get_player_index()
	AudioManager.play_sfx("tp_unroll")

func on_hold_tick(cat: Node, _delta: float) -> void:
	# Keep owner updated in case cat changes (shouldn't happen, but safe)
	if _unrolling:
		_owner_idx = cat.get_player_index()

func on_hold_end(_cat: Node) -> void:
	_unrolling = false

# Called when cat releases interact
func stop_unrolling() -> void:
	_unrolling = false

func _spawn_segment() -> void:
	if paper_segment_scene == null:
		return
	var seg: Node3D = paper_segment_scene.instantiate()
	get_parent().add_child(seg)
	seg.global_position = global_position + Vector3(
		randf_range(-0.1, 0.1), 0.02, randf_range(-0.1, 0.1)
	)
	_segments.append(seg)

func try_steal_pile(new_owner: int) -> int:
	# Steal a portion of accumulated points (for ClaimTerritory)
	var stolen_pts: int = int(_paper_spawned * points_per_meter * 0.5)
	if _owner_idx >= 0 and _owner_idx != new_owner:
		ScoreManager.steal_score(new_owner, _owner_idx, stolen_pts)
		_owner_idx = new_owner
	return stolen_pts
