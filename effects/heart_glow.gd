extends Label

func show_heart(start_pos: Vector2) -> void:
	text = "\u2764"
	global_position = start_pos
	add_theme_font_size_override("font_size", 48)
	modulate = Color("#E96BFF")
	pivot_offset = Vector2(24, 24)
	scale = Vector2(0.5, 0.5)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.2)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.6)\
		.set_delay(0.3)
	tween.tween_callback(queue_free)
