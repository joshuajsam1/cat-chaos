extends CanvasLayer

# ---------------------------------------------------------------------------
# CountdownOverlay — shows 3-2-1-GO! before gameplay begins
# ---------------------------------------------------------------------------

@onready var label: Label = $Label

func _ready() -> void:
	layer = 50
	GameManager.game_started.connect(queue_free)  # remove after GO fades
	_run_countdown()

func _run_countdown() -> void:
	for n in [3, 2, 1]:
		label.text = str(n)
		label.scale = Vector2(1.5, 1.5)
		label.modulate.a = 1.0
		var tw := create_tween()
		tw.tween_property(label, "scale", Vector2(1.0, 1.0), 0.7).set_ease(Tween.EASE_OUT)
		await tw.finished
		await get_tree().create_timer(0.25).timeout

	label.text = "GO!"
	label.scale = Vector2(1.2, 1.2)
	label.modulate.a = 1.0
	var tw2 := create_tween()
	tw2.parallel().tween_property(label, "scale", Vector2(2.0, 2.0), 0.6)
	tw2.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
	await tw2.finished
	queue_free()
