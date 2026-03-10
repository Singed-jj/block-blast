extends Control

signal play_again_pressed

@onready var final_score_label := $FinalScoreLabel
@onready var best_score_label := $BestScoreLabel
@onready var play_button := $PlayButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	visible = false
	_style_elements()

func _style_elements() -> void:
	var go_label := $GameOverLabel
	go_label.add_theme_font_size_override("font_size", 48)
	go_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))

	final_score_label.add_theme_font_size_override("font_size", 64)
	final_score_label.add_theme_color_override("font_color", Constants.SCORE_TEXT)

	best_score_label.add_theme_font_size_override("font_size", 24)
	best_score_label.add_theme_color_override("font_color", Constants.BEST_SCORE)

	# Green circular play button
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#51C95A")
	style.corner_radius_top_left = 40
	style.corner_radius_top_right = 40
	style.corner_radius_bottom_left = 40
	style.corner_radius_bottom_right = 40
	play_button.add_theme_stylebox_override("normal", style)
	play_button.add_theme_stylebox_override("hover", style)
	play_button.add_theme_stylebox_override("pressed", style)
	play_button.add_theme_font_size_override("font_size", 32)
	play_button.add_theme_color_override("font_color", Color.WHITE)

func show_game_over(score: int, best_score: int) -> void:
	final_score_label.text = str(score)
	best_score_label.text = "Best Score: %d" % best_score
	visible = true
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _on_play_pressed() -> void:
	visible = false
	play_again_pressed.emit()
