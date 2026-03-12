extends Control

@onready var score_label := $ScoreLabel
@onready var best_score_label := $BestScoreLabel
@onready var crown_icon := $CrownIcon
@onready var settings_button := $SettingsButton
@onready var notification_badge := $NotificationBadge

func _ready() -> void:
	var vp_width := get_viewport_rect().size.x

	# Score style — 화면 중앙 (Bold 없으므로 큰 사이즈 + 그림자)
	score_label.add_theme_font_size_override("font_size", 56)
	score_label.add_theme_color_override("font_color", Constants.SCORE_TEXT)
	score_label.add_theme_constant_override("shadow_offset_x", 2)
	score_label.add_theme_constant_override("shadow_offset_y", 2)
	score_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.3))
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.position = Vector2(vp_width * 0.5 - 95, 60)
	score_label.size = Vector2(190, 60)

	# Best score style — 좌상단 (폰트 강화)
	best_score_label.add_theme_font_size_override("font_size", 28)
	best_score_label.add_theme_color_override("font_color", Constants.BEST_SCORE)
	best_score_label.position = Vector2(50, 20)

	# Crown icon → TextureRect (PNG) — 좌상단
	var crown_tex := load("res://assets/icons/crown.png")
	var crown_rect := TextureRect.new()
	crown_rect.texture = crown_tex
	crown_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crown_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crown_rect.custom_minimum_size = Vector2(32, 32)
	crown_rect.size = Vector2(32, 32)
	crown_rect.position = Vector2(16, 16)
	crown_icon.get_parent().add_child(crown_rect)
	crown_icon.queue_free()

	# Settings icon → TextureRect (PNG) — 우상단
	var settings_tex := load("res://assets/icons/settings.png")
	var settings_rect := TextureRect.new()
	settings_rect.texture = settings_tex
	settings_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	settings_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	settings_rect.custom_minimum_size = Vector2(32, 32)
	settings_rect.size = Vector2(32, 32)
	settings_rect.position = Vector2(vp_width - 48, 16)
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
