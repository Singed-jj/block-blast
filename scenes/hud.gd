extends Control

@onready var score_label := $ScoreLabel
@onready var best_score_label := $BestScoreLabel
@onready var crown_icon := $CrownIcon
@onready var settings_button := $SettingsButton
@onready var notification_badge := $NotificationBadge

var score_diamond: ColorRect = null

func _ready() -> void:
	# Score style
	score_label.add_theme_font_size_override("font_size", 48)
	score_label.add_theme_color_override("font_color", Constants.SCORE_TEXT)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Best score style
	best_score_label.add_theme_font_size_override("font_size", 24)
	best_score_label.add_theme_color_override("font_color", Constants.BEST_SCORE)

	# Score diamond background (마름모 형태)
	_create_score_diamond()

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

func _create_score_diamond() -> void:
	score_diamond = ColorRect.new()
	score_diamond.color = Color(0.2, 0.5, 0.9, 0.35)
	score_diamond.size = Vector2(80, 80)
	score_diamond.pivot_offset = Vector2(40, 40)
	score_diamond.rotation_degrees = 45
	# 점수 라벨 중앙에 위치
	var label_center_x: float = score_label.position.x + score_label.size.x * 0.5
	var label_center_y: float = score_label.position.y + score_label.size.y * 0.5
	score_diamond.position = Vector2(label_center_x - 40, label_center_y - 40)
	score_diamond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# score_label보다 뒤에 배치
	score_label.get_parent().add_child(score_diamond)
	score_label.get_parent().move_child(score_diamond, score_label.get_index())

func _pulse_diamond() -> void:
	if score_diamond == null:
		return
	var tween := create_tween()
	tween.tween_property(score_diamond, "scale", Vector2(1.15, 1.15), 0.1)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(score_diamond, "scale", Vector2(1.0, 1.0), 0.15)\
		.set_ease(Tween.EASE_IN_OUT)
	HapticManager.score_pulse()

func _on_score_changed(new_score: int) -> void:
	score_label.text = str(new_score)
	if new_score > 0:
		_pulse_diamond()

func _on_best_score_changed(new_best: int) -> void:
	best_score_label.text = str(new_best)
