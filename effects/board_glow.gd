extends Node2D

## 보드 테두리에 글로우 이펙트 표시
func show_glow(board_rect: Rect2, intensity: float = 1.0) -> void:
	position = board_rect.position - Vector2(6, 6)
	var glow_size := board_rect.size + Vector2(12, 12)
	var glow_color := Color(0.4, 0.9, 0.4, 0.0)
	var bars := []
	# 상단
	var top := ColorRect.new()
	top.size = Vector2(glow_size.x, 4)
	top.color = glow_color
	add_child(top)
	bars.append(top)
	# 하단
	var bottom := ColorRect.new()
	bottom.size = Vector2(glow_size.x, 4)
	bottom.position.y = glow_size.y - 4
	bottom.color = glow_color
	add_child(bottom)
	bars.append(bottom)
	# 좌측
	var left := ColorRect.new()
	left.size = Vector2(4, glow_size.y)
	left.color = glow_color
	add_child(left)
	bars.append(left)
	# 우측
	var right := ColorRect.new()
	right.size = Vector2(4, glow_size.y)
	right.position.x = glow_size.x - 4
	right.color = glow_color
	add_child(right)
	bars.append(right)
	# 애니메이션: 페이드인 → 유지 → 페이드아웃
	var alpha := clampf(0.5 * intensity, 0.3, 0.9)
	for bar in bars:
		var tween := create_tween()
		tween.tween_property(bar, "color:a", alpha, 0.15)
		tween.tween_interval(0.3)
		tween.tween_property(bar, "color:a", 0.0, 0.4)
	# 정리
	var cleanup := create_tween()
	cleanup.tween_interval(1.0)
	cleanup.tween_callback(queue_free)
