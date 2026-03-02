extends Node

# ---------------------------------------------------------------------------
# TimerManager — 90-second countdown with milestone signals
# ---------------------------------------------------------------------------

const GAME_DURATION: float = 90.0
const WARNING_THRESHOLD: float = 30.0   # "30 seconds left" flash
const CRITICAL_THRESHOLD: float = 10.0  # Owner walks in

signal tick(time_remaining: float)
signal warning_triggered          # At 30 s
signal owner_arrived              # At 10 s
signal game_over

var time_remaining: float = GAME_DURATION
var _running: bool = false
var _warning_fired: bool = false
var _owner_fired: bool = false

func _ready() -> void:
	pass

func start_timer() -> void:
	time_remaining = GAME_DURATION
	_running = true
	_warning_fired = false
	_owner_fired = false

func stop_timer() -> void:
	_running = false

func reset_timer() -> void:
	stop_timer()
	time_remaining = GAME_DURATION
	_warning_fired = false
	_owner_fired = false

func _process(delta: float) -> void:
	if not _running:
		return

	time_remaining -= delta
	tick.emit(time_remaining)

	if not _warning_fired and time_remaining <= WARNING_THRESHOLD:
		_warning_fired = true
		warning_triggered.emit()

	if not _owner_fired and time_remaining <= CRITICAL_THRESHOLD:
		_owner_fired = true
		owner_arrived.emit()

	if time_remaining <= 0.0:
		time_remaining = 0.0
		_running = false
		game_over.emit()

func get_formatted_time() -> String:
	var secs: int = int(ceil(time_remaining))
	var m: int = secs / 60
	var s: int = secs % 60
	return "%d:%02d" % [m, s]
