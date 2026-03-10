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
	# Sparkle effect on new set
	for j in 5:
		var sparkle := Label.new()
		sparkle.set_script(preload("res://effects/tray_sparkle.gd"))
		add_child(sparkle)
		sparkle.show_sparkle(global_position + Vector2(size.x * randf(), 0))

func _layout_pieces(piece_list: Array[Node2D]) -> void:
	var tray_width := size.x if size.x > 0 else 350.0
	var slot_width := tray_width / MAX_PIECES
	for i in piece_list.size():
		var piece := piece_list[i]
		var bounding := piece.get_bounding_size() * piece.scale
		var slot_center_x := slot_width * i + slot_width * 0.5
		piece.position = Vector2(
			slot_center_x - bounding.x * 0.5,
			(size.y - bounding.y) * 0.5 if size.y > 0 else 10.0
		)
		piece.original_position = piece.position

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
