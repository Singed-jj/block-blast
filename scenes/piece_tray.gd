extends HBoxContainer

signal piece_drag_started(piece: Node2D)
signal piece_drag_ended(piece: Node2D)
signal all_pieces_placed

var pieces: Array[Node2D] = []
var block_piece_scene := preload("res://scenes/block_piece.tscn")
const MAX_PIECES := 3

func generate_new_set() -> void:
	for piece in pieces:
		if is_instance_valid(piece):
			piece.queue_free()
	pieces.clear()
	var new_pieces: Array[Node2D] = []
	for i in MAX_PIECES:
		var piece: Node2D = block_piece_scene.instantiate()
		var shape_name := Constants.get_random_shape_name()
		var color := Constants.get_random_color()
		piece.setup(shape_name, color)
		piece.drag_started.connect(_on_piece_drag_started)
		piece.drag_ended.connect(_on_piece_drag_ended)
		piece.placed.connect(_on_piece_placed)
		add_child(piece)
		new_pieces.append(piece)
		pieces.append(piece)
	_layout_pieces(new_pieces)
	# 바운스 + 페이드인 애니메이션
	_animate_new_pieces(new_pieces)
	# Sparkle effect on new set
	for j in 5:
		var sparkle := Label.new()
		sparkle.set_script(preload("res://effects/tray_sparkle.gd"))
		add_child(sparkle)
		sparkle.show_sparkle(global_position + Vector2(size.x * randf(), 0))
	# 햅틱
	HapticManager.new_pieces()

func _animate_new_pieces(piece_list: Array[Node2D]) -> void:
	for i in piece_list.size():
		var piece := piece_list[i]
		var target_scale := piece.scale
		# 시작 상태: 작고 투명
		piece.scale = target_scale * 0.3
		piece.modulate.a = 0.0
		# 딜레이를 두고 순차 등장
		var delay := i * 0.08
		var tween := create_tween()
		tween.tween_interval(delay)
		tween.tween_property(piece, "modulate:a", 1.0, 0.15)
		tween.parallel().tween_property(piece, "scale", target_scale * 1.1, 0.15)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(piece, "scale", target_scale, 0.1)\
			.set_ease(Tween.EASE_IN_OUT)

func _layout_pieces(piece_list: Array[Node2D]) -> void:
	var tray_width := size.x if size.x > 0 else 320.0
	var padding := 16.0  # 양쪽 고정 패딩
	var usable_width := tray_width - padding * 2.0
	# 1단계: 각 피스의 스케일과 바운딩 크기 계산
	var scales: Array[float] = []
	var boundings: Array[Vector2] = []
	for piece in piece_list:
		var base_scale: float = piece.TRAY_SCALE
		scales.append(base_scale)
		boundings.append(piece.get_bounding_size() * base_scale)
	# 2단계: 전체 피스 폭 합산, 넘치면 비례 축소
	var total_piece_width := 0.0
	for b in boundings:
		total_piece_width += b.x
	var min_gap := 12.0
	var total_needed := total_piece_width + min_gap * (piece_list.size() - 1)
	if total_needed > usable_width:
		var shrink := usable_width / total_needed
		for i in piece_list.size():
			scales[i] *= shrink
			boundings[i] = piece_list[i].get_bounding_size() * scales[i]
		total_piece_width = 0.0
		for b in boundings:
			total_piece_width += b.x
	# 3단계: 균일 간격 배치
	var remaining := usable_width - total_piece_width
	var gap := remaining / (piece_list.size() + 1)
	var cursor_x := padding + gap
	for i in piece_list.size():
		var piece := piece_list[i]
		piece.scale = Vector2(scales[i], scales[i])
		piece.position = Vector2(
			cursor_x,
			(size.y - boundings[i].y) * 0.5 if size.y > 0 else 10.0
		)
		piece.original_position = piece.position
		cursor_x += boundings[i].x + gap

func get_remaining_shapes() -> Array:
	var shapes: Array = []
	for piece in pieces:
		if is_instance_valid(piece) and not piece.is_placed:
			shapes.append(piece.shape_cells)
	return shapes

func get_remaining_count() -> int:
	var count := 0
	for piece in pieces:
		if is_instance_valid(piece) and not piece.is_placed:
			count += 1
	return count

func _on_piece_drag_started(piece: Node2D) -> void:
	piece_drag_started.emit(piece)

func _on_piece_drag_ended(piece: Node2D) -> void:
	piece_drag_ended.emit(piece)

func _on_piece_placed(_piece: Node2D) -> void:
	if get_remaining_count() == 0:
		all_pieces_placed.emit()
