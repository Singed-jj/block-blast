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

	# Crown icon → TextureRect (PNG)
	var crown_tex := load("res://assets/icons/crown.png")
	var crown_rect := TextureRect.new()
	crown_rect.texture = crown_tex
	crown_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crown_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crown_rect.custom_minimum_size = Vector2(32, 32)
	crown_rect.size = Vector2(32, 32)
	crown_rect.position = crown_icon.position
	crown_icon.get_parent().add_child(crown_rect)
	crown_icon.queue_free()

	# Settings icon → TextureRect (PNG)
	var settings_tex := load("res://assets/icons/settings.png")
	var settings_rect := TextureRect.new()
	settings_rect.texture = settings_tex
	settings_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	settings_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	settings_rect.custom_minimum_size = Vector2(32, 32)
	settings_rect.size = Vector2(32, 32)
	settings_rect.position = settings_button.position
	settings_button.get_parent().add_child(settings_rect)
	settings_button.queue_free()

	# Notification badge 제거
	notification_badge.queue_free()

	GameState.score_changed.connect(_on_score_changed)
	GameState.best_score_changed.connect(_on_best_score_changed)
	_on_score_changed(GameState.score)
	_on_best_score_changed(GameState.best_score)

func _on_score_changed(new_score: int) -> void:
	score_label.text = str(new_score)

func _on_best_score_changed(new_best: int) -> void:
	best_score_label.text = str(new_best)
