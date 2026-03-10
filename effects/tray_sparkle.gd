extends Label

func show_sparkle(start_pos: Vector2) -> void:
	text = "\u2726"
	global_position = start_pos + Vector2(randf_range(-20, 20), randf_range(-10, 10))
	add_theme_font_size_override("font_size", randi_range(12, 20))
	modulate = Color(1, 1, 1, 0.8)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.6 + randf() * 0.4)
	tween.parallel().tween_property(self, "position:y", position.y - 15, 0.8)
	tween.tween_callback(queue_free)
