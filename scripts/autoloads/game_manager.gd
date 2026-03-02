extends Node

# ---------------------------------------------------------------------------
# GameManager — central state machine for Cat Chaos
# ---------------------------------------------------------------------------

enum GameState {
	MENU,
	COUNTDOWN,   # 3-2-1 before game starts
	PLAYING,
	OWNER_ARRIVED,
	GAME_OVER,
}

signal state_changed(new_state: GameState)
signal game_started
signal game_ended

var current_state: GameState = GameState.MENU

func _ready() -> void:
	# Wait one frame so all autoloads are fully initialized before connecting
	await get_tree().process_frame
	TimerManager.game_over.connect(_on_game_over)

func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	state_changed.emit(new_state)
	match new_state:
		GameState.COUNTDOWN:
			_begin_countdown()
		GameState.PLAYING:
			_begin_playing()
		GameState.GAME_OVER:
			_begin_game_over()

func start_game() -> void:
	ScoreManager.reset()
	change_state(GameState.COUNTDOWN)

func _begin_countdown() -> void:
	# A short 3-second wait before gameplay starts
	await get_tree().create_timer(3.0).timeout
	change_state(GameState.PLAYING)

func _begin_playing() -> void:
	TimerManager.start_timer()
	game_started.emit()

func _begin_game_over() -> void:
	game_ended.emit()

func _on_game_over() -> void:
	change_state(GameState.GAME_OVER)

func is_playing() -> bool:
	return current_state == GameState.PLAYING
