extends CanvasLayer

# ---------------------------------------------------------------------------
# HUDController — per-player HUD: score label, timer (P1 only), steal flash
# ---------------------------------------------------------------------------

@export var player_index: int = 0

@onready var score_label: Label = $ScorePanel/ScoreLabel
@onready var timer_label: Label = $TimerLabel     # only used by P1 HUD
@onready var flash_overlay: ColorRect = $FlashOverlay
@onready var warning_bar: Panel = $WarningBar

var _flash_tween: Tween

func _ready() -> void:
	# Only P1 shows the timer in its HUD
	if timer_label:
		timer_label.visible = (player_index == 0)

	ScoreManager.score_changed.connect(_on_score_changed)
	TimerManager.tick.connect(_on_timer_tick)
	TimerManager.warning_triggered.connect(_on_warning)
	TimerManager.owner_arrived.connect(_on_owner_arrived)
	ScoreManager.steal_occurred.connect(_on_steal)

	if flash_overlay:
		flash_overlay.modulate.a = 0.0

	if warning_bar:
		warning_bar.visible = false

func _on_score_changed(p_idx: int, new_score: int) -> void:
	if p_idx != player_index:
		return
	if score_label:
		score_label.text = "Score: %d" % new_score

func _on_timer_tick(time_remaining: float) -> void:
	if player_index != 0:
		return
	if timer_label:
		var secs: int = int(ceil(time_remaining))
		var m: int = secs / 60
		var s: int = secs % 60
		timer_label.text = "%d:%02d" % [m, s]
		# Red text in last 10 seconds
		if time_remaining <= 10.0:
			timer_label.add_theme_color_override("font_color", Color.RED)
		elif time_remaining <= 30.0:
			timer_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			timer_label.remove_theme_color_override("font_color")

func _on_warning() -> void:
	if warning_bar:
		warning_bar.visible = true
	_flash(Color(1, 1, 0, 0.4), 0.5, 3)

func _on_owner_arrived() -> void:
	_flash(Color(1, 0, 0, 0.5), 0.3, 5)

func _on_steal(thief_idx: int, victim_idx: int, _points: int) -> void:
	if victim_idx == player_index:
		_flash(Color(1, 0, 0, 0.6), 0.15, 2)
	elif thief_idx == player_index:
		_flash(Color(0, 1, 0, 0.5), 0.15, 2)

func _flash(color: Color, duration: float, count: int) -> void:
	if not flash_overlay:
		return
	if _flash_tween and _flash_tween.is_running():
		_flash_tween.kill()
	_flash_tween = create_tween()
	flash_overlay.color = color
	for _i in range(count):
		_flash_tween.tween_property(flash_overlay, "modulate:a", 1.0, duration * 0.5)
		_flash_tween.tween_property(flash_overlay, "modulate:a", 0.0, duration * 0.5)
