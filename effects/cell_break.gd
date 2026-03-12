extends Node2D

## 셀 파괴 시 4개의 작은 조각이 흩어지는 이펙트
func show_break(pos: Vector2, color: Color) -> void:
	position = pos
	var piece_size := Vector2(8, 8)
	var offsets := [
		Vector2(-6, -6), Vector2(6, -6),
		Vector2(-6, 6), Vector2(6, 6),
	]
	var velocities := [
		Vector2(-40, -60), Vector2(40, -60),
		Vector2(-30, 50), Vector2(30, 50),
	]
	for i in 4:
		var shard := ColorRect.new()
		shard.size = piece_size
		shard.color = color.lightened(randf_range(-0.1, 0.2))
		shard.position = offsets[i]
		shard.pivot_offset = piece_size * 0.5
		add_child(shard)
		var tween := create_tween()
		var target_pos: Vector2 = offsets[i] + velocities[i] * randf_range(0.8, 1.2)
		tween.tween_property(shard, "position", target_pos, 0.4)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.parallel().tween_property(shard, "modulate:a", 0.0, 0.4)
		tween.parallel().tween_property(shard, "rotation_degrees",
			randf_range(-90, 90), 0.4)
		tween.parallel().tween_property(shard, "scale",
			Vector2(0.3, 0.3), 0.4)
	# 전체 노드 정리
	var cleanup := create_tween()
	cleanup.tween_interval(0.5)
	cleanup.tween_callback(queue_free)
