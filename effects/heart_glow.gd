extends Label

func show_heart(start_pos: Vector2) -> void:
	text = "\u2764"
	global_position = start_pos - Vector2(40, 40)
	add_theme_font_size_override("font_size", 60)
	add_theme_color_override("font_color", Color("#FF69B4"))
	add_theme_font_override("font", load("res://assets/fonts/default_font.tres"))
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	size = Vector2(80, 80)
	modulate.a = 0.0
	pivot_offset = Vector2(40, 40)
	scale = Vector2(0.3, 0.3)

	# 애니메이션
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)\
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2(1.4, 1.4), 0.25)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)\
		.set_delay(0.4).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
