extends Label

func show_combo(combo_count: int, start_pos: Vector2) -> void:
	# 메인 Label은 "Combo " 부분 (시안)
	text = "Combo "
	global_position = start_pos
	add_theme_font_size_override("font_size", 44)
	add_theme_color_override("font_color", Color("#00BFFF"))
	pivot_offset = Vector2(90, 24)
	scale = Vector2(0.5, 0.5)
	modulate.a = 0.0

	# 텍스트 그림자용 레이어 (약간 오프셋, 어두운색)
	var shadow := Label.new()
	shadow.text = "Combo %d" % combo_count
	shadow.add_theme_font_size_override("font_size", 44)
	shadow.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 0.5))
	shadow.position = Vector2(2, 2)
	add_child(shadow)

	# 숫자 부분 (금색) - 메인 Label 오른쪽에 배치
	var number_label := Label.new()
	number_label.text = "%d" % combo_count
	number_label.add_theme_font_size_override("font_size", 48)
	number_label.add_theme_color_override("font_color", Color("#F3C93A"))
	add_child(number_label)

	# 숫자 위치는 "Combo " 텍스트 너비 이후
	await get_tree().process_frame
	var combo_width := get_theme_font("font").get_string_size("Combo ", HORIZONTAL_ALIGNMENT_LEFT, -1, 44).x if get_theme_font("font") else 120.0
	number_label.position = Vector2(combo_width, -2)
	shadow.z_index = -1

	# 글로우 배경 (시안 반투명)
	var glow := Label.new()
	glow.text = "Combo %d" % combo_count
	glow.add_theme_font_size_override("font_size", 44)
	glow.add_theme_color_override("font_color", Color("#00BFFF", 0.2))
	glow.scale = Vector2(1.15, 1.15)
	glow.pivot_offset = Vector2(90, 24)
	glow.position = Vector2(-90 * 0.15, -24 * 0.15)
	glow.z_index = -2
	add_child(glow)

	# 애니메이션
	var tween := create_tween()
	# 페이드인
	tween.tween_property(self, "modulate:a", 1.0, 0.1)
	# 스케일 바운스: 1.3배 → 1.0배
	tween.parallel().tween_property(self, "scale", Vector2(1.3, 1.3), 0.2)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)\
		.set_ease(Tween.EASE_IN_OUT)
	# 유지 후 페이드아웃
	tween.tween_interval(0.6)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)\
		.set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
