extends Node2D

signal drag_started(piece: Node2D)
signal drag_ended(piece: Node2D)
signal placed(piece: Node2D)

var shape_name: String = ""
var shape_cells: Array = []
var block_color: Color = Color.WHITE
var is_dragging := false
var drag_offset := Vector2.ZERO
var original_position := Vector2.ZERO
var original_scale := Vector2.ONE
var is_placed := false

const TRAY_SCALE := 0.5
const DRAG_SCALE := 1.0
const DRAG_Y_OFFSET := -80

func setup(p_shape_name: String, p_color: Color) -> void:
	shape_name = p_shape_name
	shape_cells = Constants.BLOCK_SHAPES[p_shape_name].duplicate()
	block_color = p_color
	scale = Vector2(TRAY_SCALE, TRAY_SCALE)
	_draw_cells()

func _draw_cells() -> void:
	for child in get_children():
		child.queue_free()
	for offset in shape_cells:
		var cell := ColorRect.new()
		cell.size = Vector2(Constants.CELL_SIZE, Constants.CELL_SIZE)
		cell.position = Vector2(offset.x * Constants.CELL_SIZE, offset.y * Constants.CELL_SIZE)
		cell.color = block_color
		add_child(cell)
		# Inner shadow/highlight for 3D effect
		var top := ColorRect.new()
		top.size = Vector2(Constants.CELL_SIZE, 2)
		top.color = Color(1, 1, 1, 0.3)
		top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(top)
		var left := ColorRect.new()
		left.size = Vector2(2, Constants.CELL_SIZE)
		left.color = Color(1, 1, 1, 0.15)
		left.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(left)
		var bottom := ColorRect.new()
		bottom.size = Vector2(Constants.CELL_SIZE, 2)
		bottom.position.y = Constants.CELL_SIZE - 2
		bottom.color = Color(0, 0, 0, 0.3)
		bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(bottom)
		var right := ColorRect.new()
		right.size = Vector2(2, Constants.CELL_SIZE)
		right.position.x = Constants.CELL_SIZE - 2
		right.color = Color(0, 0, 0, 0.15)
		right.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(right)

func get_bounding_size() -> Vector2:
	var max_x := 0
	var max_y := 0
	for offset in shape_cells:
		max_x = max(max_x, offset.x + 1)
		max_y = max(max_y, offset.y + 1)
	return Vector2(max_x * Constants.CELL_SIZE, max_y * Constants.CELL_SIZE)

func _input(event: InputEvent) -> void:
	if is_placed:
		return
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			if _is_point_inside(event.position):
				is_dragging = true
				original_position = position
				original_scale = scale
				drag_offset = position - event.position
				scale = Vector2(DRAG_SCALE, DRAG_SCALE)
				z_index = 10
				drag_started.emit(self)
		else:
			if is_dragging:
				is_dragging = false
				z_index = 0
				drag_ended.emit(self)
	if event is InputEventScreenDrag or (event is InputEventMouseMotion and is_dragging):
		if is_dragging:
			position = event.position + drag_offset + Vector2(0, DRAG_Y_OFFSET)

func _is_point_inside(point: Vector2) -> bool:
	var bounds := get_bounding_size() * scale
	var rect := Rect2(global_position, bounds)
	return rect.has_point(point)

func snap_back() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position", original_position, 0.2)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(self, "scale", Vector2(TRAY_SCALE, TRAY_SCALE), 0.2)

func mark_placed() -> void:
	is_placed = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)
	placed.emit(self)
