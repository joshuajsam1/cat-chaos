extends Control

# ---------------------------------------------------------------------------
# MenuManager — main menu: title, controls card, tips, play button
# ---------------------------------------------------------------------------

@onready var play_btn: Button = $VBox/PlayButton
@onready var quit_btn: Button = $VBox/QuitButton
@onready var hint_cycle_timer: Timer = $HintCycleTimer
@onready var hint_label: Label = $VBox/TipsBox/HintLabel

const HINTS: Array[String] = [
	"💡 Knock objects over for instant points — but your opponent can steal them in the next 2 seconds!",
	"💡 Hold interact (Space / Enter) near a toilet paper roll to unroll it for steady points.",
	"💡 Sit still (Shift) near objects to claim them — and slowly drain your opponent's claimed score.",
	"💡 Stand on the laptop to earn passive points every second.",
	"💡 At 30 seconds left the owner heads home — sprint to the sofa and sit for a big innocence bonus!",
	"💡 Sprint (Ctrl) to cross the house faster, but you can't interact while sprinting.",
	"💡 Both cats share the same house — block doorways to slow your rival down.",
	"💡 Steals give you half the object's base points — risky but rewarding!",
]

var _hint_idx: int = 0

func _ready() -> void:
	play_btn.pressed.connect(_on_play)
	quit_btn.pressed.connect(get_tree().quit)

	hint_cycle_timer.wait_time = 5.0
	hint_cycle_timer.autostart = true
	hint_cycle_timer.timeout.connect(_next_hint)
	hint_label.text = HINTS[0]

	# Animate play button pulse
	var tween := create_tween().set_loops()
	tween.tween_property(play_btn, "scale", Vector2(1.05, 1.05), 0.6).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(play_btn, "scale", Vector2(1.0, 1.0), 0.6).set_ease(Tween.EASE_IN_OUT)

func _next_hint() -> void:
	_hint_idx = (_hint_idx + 1) % HINTS.size()
	hint_label.text = HINTS[_hint_idx]

func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_play()
