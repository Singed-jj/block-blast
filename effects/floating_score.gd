extends Label

func show_score(points: int, start_pos: Vector2) -> void:
	text = "+%d" % points
	global_position = start_pos
	add_theme_font_override("font", load("res://assets/fonts/default_font.tres"))
	add_theme_font_size_override("font_size", 28)
	add_theme_color_override("font_color", Color.WHITE)
	modulate = Color(1, 1, 1, 1)
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 60, 0.8)\
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.8)\
		.set_delay(0.3)
	tween.tween_callback(queue_free)
