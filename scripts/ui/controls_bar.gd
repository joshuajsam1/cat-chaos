extends CanvasLayer

# ---------------------------------------------------------------------------
# ControlsBar — always-visible transparent strip at the top of the screen.
# Shows both players' key bindings including the new rotate controls.
# ---------------------------------------------------------------------------

# Hide during menu / end screen; show during gameplay and countdown
func _ready() -> void:
	layer = 15   # above HUD (10), below end screen (20)
	GameManager.state_changed.connect(_on_state_changed)
	_on_state_changed(GameManager.current_state)

func _on_state_changed(state: GameManager.GameState) -> void:
	match state:
		GameManager.GameState.MENU, GameManager.GameState.GAME_OVER:
			visible = false
		_:
			visible = true
