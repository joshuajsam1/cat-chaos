extends CanvasLayer

# ---------------------------------------------------------------------------
# EndScreenManager — shows winner + per-player stat cards
# ---------------------------------------------------------------------------

@onready var winner_label: Label = $CenterContainer/VBox/WinnerLabel
@onready var p1_stats: RichTextLabel = $CenterContainer/VBox/StatsRow/P1Stats
@onready var p2_stats: RichTextLabel = $CenterContainer/VBox/StatsRow/P2Stats
@onready var restart_btn: Button = $CenterContainer/VBox/ButtonRow/RestartButton
@onready var menu_btn: Button = $CenterContainer/VBox/ButtonRow/MenuButton

func _ready() -> void:
	visible = false
	GameManager.game_ended.connect(_on_game_ended)
	if restart_btn:
		restart_btn.pressed.connect(_on_restart)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu)

func _on_game_ended() -> void:
	visible = true
	_populate()

func _populate() -> void:
	var winner := ScoreManager.get_winner()

	if winner_label:
		match winner:
			0:
				winner_label.text = "Player 1 Wins! 🐱"
			1:
				winner_label.text = "Player 2 Wins! 🐱"
			_:
				winner_label.text = "It's a Tie! 🐱🐱"

	_fill_stats(0, p1_stats)
	_fill_stats(1, p2_stats)

func _fill_stats(player_idx: int, label: RichTextLabel) -> void:
	if label == null:
		return
	var s := ScoreManager.get_stats(player_idx)
	var score := ScoreManager.get_score(player_idx)
	label.text = (
		"[b]Player %d[/b]\n" % (player_idx + 1) +
		"Score: %d\n" % score +
		"Knock-overs: %d\n" % s.get("knockovers", 0) +
		"TP Unrolled: %d pts\n" % s.get("tp_unrolled", 0) +
		"Laptop Time: %d pts\n" % s.get("laptop_uptime", 0) +
		"Territory Claims: %d\n" % s.get("claims", 0) +
		"Steals: %d\n" % s.get("steals", 0) +
		"Innocence Bonus: %d\n" % s.get("innocent_bonus", 0)
	)

	# Stat awards
	var awards: Array[String] = _compute_awards(player_idx)
	for award in awards:
		label.text += "\n  " + award

func _compute_awards(player_idx: int) -> Array[String]:
	var awards: Array[String] = []
	var s := ScoreManager.get_stats(player_idx)
	var opp := ScoreManager.get_stats(1 - player_idx)

	if s.get("knockovers", 0) > opp.get("knockovers", 0):
		awards.append("🏆 Most Destructive")
	if s.get("steals", 0) >= 3:
		awards.append("🦹 Master Thief")
	if s.get("innocent_bonus", 0) > 0:
		awards.append("😇 Innocent Angel")
	if s.get("tp_unrolled", 0) > 50:
		awards.append("🧻 TP Vandal")
	return awards

func _on_restart() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menu.tscn")
