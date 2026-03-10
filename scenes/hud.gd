extends Control

@onready var score_label := $ScoreLabel
@onready var best_score_label := $BestScoreLabel
@onready var crown_icon := $CrownIcon
@onready var settings_button := $SettingsButton
@onready var notification_badge := $NotificationBadge

func _ready() -> void:
	# Score style
	score_label.add_theme_font_size_override("font_size", 48)
	score_label.add_theme_color_override("font_color", Constants.SCORE_TEXT)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Best score style
	best_score_label.add_theme_font_size_override("font_size", 24)
	best_score_label.add_theme_color_override("font_color", Constants.BEST_SCORE)

	# Crown
	crown_icon.add_theme_font_size_override("font_size", 24)
	crown_icon.add_theme_color_override("font_color", Constants.BEST_SCORE)

	# Settings button
	settings_button.flat = true
	settings_button.add_theme_font_size_override("font_size", 28)

	# Notification badge
	notification_badge.add_theme_color_override("font_color", Color("#FF2E2E"))
	notification_badge.add_theme_font_size_override("font_size", 10)

	GameState.score_changed.connect(_on_score_changed)
	GameState.best_score_changed.connect(_on_best_score_changed)
	_on_score_changed(GameState.score)
	_on_best_score_changed(GameState.best_score)

func _on_score_changed(new_score: int) -> void:
	score_label.text = str(new_score)

func _on_best_score_changed(new_best: int) -> void:
	best_score_label.text = str(new_best)
