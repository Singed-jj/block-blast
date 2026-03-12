extends Control

signal play_again_pressed

@onready var final_score_label := $CenterContainer/FinalScoreLabel
@onready var best_score_label := $CenterContainer/BestScoreLabel
@onready var play_button := $CenterContainer/PlayButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	visible = false
	_style_elements()

func _style_elements() -> void:
	# Background gradient feel via ColorRect (already set in tscn)

	# "Game Over" label — cyan/mint with glow feel
	var go_label := $CenterContainer/GameOverLabel
	go_label.add_theme_font_size_override("font_size", 52)
	go_label.add_theme_color_override("font_color", Color("#00E5FF"))

	# "Score" title label — golden/orange
	var score_title := $CenterContainer/ScoreTitle
	score_title.add_theme_font_size_override("font_size", 22)
	score_title.add_theme_color_override("font_color", Color("#FFB74D"))

	# Score number — white, large
	final_score_label.add_theme_font_size_override("font_size", 72)
	final_score_label.add_theme_color_override("font_color", Color.WHITE)

	# "Best Score" title label — golden/orange
	var best_title := $CenterContainer/BestScoreTitle
	best_title.add_theme_font_size_override("font_size", 22)
	best_title.add_theme_color_override("font_color", Color("#FFB74D"))

	# Best score number — golden/orange
	best_score_label.add_theme_font_size_override("font_size", 40)
	best_score_label.add_theme_color_override("font_color", Color("#FFB74D"))

	# Green rounded play button
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#4CAF50")
	style.corner_radius_top_left = 25
	style.corner_radius_top_right = 25
	style.corner_radius_bottom_left = 25
	style.corner_radius_bottom_right = 25
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color("#66BB6A")
	hover_style.corner_radius_top_left = 25
	hover_style.corner_radius_top_right = 25
	hover_style.corner_radius_bottom_left = 25
	hover_style.corner_radius_bottom_right = 25
	hover_style.content_margin_top = 10.0
	hover_style.content_margin_bottom = 10.0

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color("#388E3C")
	pressed_style.corner_radius_top_left = 25
	pressed_style.corner_radius_top_right = 25
	pressed_style.corner_radius_bottom_left = 25
	pressed_style.corner_radius_bottom_right = 25
	pressed_style.content_margin_top = 10.0
	pressed_style.content_margin_bottom = 10.0

	play_button.add_theme_stylebox_override("normal", style)
	play_button.add_theme_stylebox_override("hover", hover_style)
	play_button.add_theme_stylebox_override("pressed", pressed_style)
	play_button.add_theme_font_size_override("font_size", 36)
	play_button.add_theme_color_override("font_color", Color.WHITE)

func show_game_over(score: int, best_score: int) -> void:
	final_score_label.text = str(score)
	best_score_label.text = str(best_score)
	visible = true
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _on_play_pressed() -> void:
	visible = false
	play_again_pressed.emit()
