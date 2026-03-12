extends Label

func show_heart(start_pos: Vector2) -> void:
	text = "\u2764"
	global_position = start_pos
	add_theme_font_size_override("font_size", 72)
	modulate = Color("#FF69B4")
	modulate.a = 0.0
	pivot_offset = Vector2(36, 36)
	scale = Vector2(0.3, 0.3)

	# 글로우 레이어: 뒤쪽에 크고 투명한 하트 2개 겹침
	var glow_outer := Label.new()
	glow_outer.text = "\u2764"
	glow_outer.add_theme_font_size_override("font_size", 72)
	glow_outer.modulate = Color("#E040FB", 0.25)
	glow_outer.scale = Vector2(1.6, 1.6)
	glow_outer.pivot_offset = Vector2(36, 36)
	glow_outer.position = Vector2(-36 * 0.6, -36 * 0.6)
	add_child(glow_outer)

	var glow_inner := Label.new()
	glow_inner.text = "\u2764"
	glow_inner.add_theme_font_size_override("font_size", 72)
	glow_inner.modulate = Color("#FF69B4", 0.45)
	glow_inner.scale = Vector2(1.25, 1.25)
	glow_inner.pivot_offset = Vector2(36, 36)
	glow_inner.position = Vector2(-36 * 0.25, -36 * 0.25)
	add_child(glow_inner)

	# 애니메이션
	var tween := create_tween()
	# 페이드인
	tween.tween_property(self, "modulate:a", 1.0, 0.15)\
		.set_ease(Tween.EASE_OUT)
	# 스케일: 작게 → 크게
	tween.parallel().tween_property(self, "scale", Vector2(1.4, 1.4), 0.25)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# 스케일: 약간 줄어듦
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)\
		.set_ease(Tween.EASE_IN_OUT)
	# 잠시 유지 후 페이드아웃
	tween.tween_property(self, "modulate:a", 0.0, 0.5)\
		.set_delay(0.4).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
