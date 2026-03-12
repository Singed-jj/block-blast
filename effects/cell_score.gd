extends Label

func show_cell_score(points: int, pos: Vector2, delay: float = 0.0) -> void:
	text = str(points)
	add_theme_font_size_override("font_size", 16)
	add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	position = pos
	modulate.a = 0.0
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(self, "modulate:a", 1.0, 0.1)
	tween.parallel().tween_property(self, "position:y", pos.y - 30, 0.4)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
