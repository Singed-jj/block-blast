extends Label

func show_combo(combo_count: int, start_pos: Vector2) -> void:
	text = "Combo %d" % combo_count
	global_position = start_pos
	add_theme_font_size_override("font_size", 36)
	add_theme_color_override("font_color", Constants.BEST_SCORE)
	pivot_offset = Vector2(80, 20)
	scale = Vector2(0.5, 0.5)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_interval(0.6)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
