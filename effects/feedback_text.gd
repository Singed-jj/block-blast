extends Label

func show_feedback(feedback: String, start_pos: Vector2) -> void:
	text = feedback
	global_position = start_pos
	add_theme_font_override("font", load("res://assets/fonts/default_font.tres"))
	add_theme_font_size_override("font_size", 32)
	add_theme_color_override("font_color", Color("#F0A030"))
	pivot_offset = Vector2(40, 16)
	scale = Vector2(0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.15)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_interval(0.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
