extends ColorRect

var grid_pos := Vector2i.ZERO
var is_occupied := false
var block_color := Color.TRANSPARENT

func setup(col: int, row: int) -> void:
	grid_pos = Vector2i(col, row)
	size = Vector2(Constants.CELL_SIZE - 1, Constants.CELL_SIZE - 1)
	position = Vector2(col * Constants.CELL_SIZE, row * Constants.CELL_SIZE)
	_update_visual()

func set_occupied(occupied: bool, new_color: Color = Color.TRANSPARENT) -> void:
	is_occupied = occupied
	block_color = new_color
	_update_visual()

func set_highlight(highlight: bool) -> void:
	if highlight and not is_occupied:
		color = Constants.GRID_LINE.lightened(0.3)
	else:
		_update_visual()

func _update_visual() -> void:
	if is_occupied:
		color = block_color
		_ensure_bevel()
		_show_bevel(true)
	else:
		color = Color.TRANSPARENT
		_show_bevel(false)

func _ensure_bevel() -> void:
	if has_node("TopHighlight"):
		return
	var top := ColorRect.new()
	top.name = "TopHighlight"
	top.size = Vector2(size.x, 3)
	top.color = Color(1, 1, 1, 0.4)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	var left := ColorRect.new()
	left.name = "LeftHighlight"
	left.size = Vector2(3, size.y)
	left.color = Color(1, 1, 1, 0.25)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(left)
	var bottom := ColorRect.new()
	bottom.name = "BottomShadow"
	bottom.size = Vector2(size.x, 3)
	bottom.position.y = size.y - 3
	bottom.color = Color(0, 0, 0, 0.4)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom)
	var right := ColorRect.new()
	right.name = "RightShadow"
	right.size = Vector2(3, size.y)
	right.position.x = size.x - 3
	right.color = Color(0, 0, 0, 0.25)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(right)
	var overlay := ColorRect.new()
	overlay.name = "InnerOverlay"
	overlay.size = size
	overlay.color = Color(1, 1, 1, 0.08)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

func _show_bevel(show: bool) -> void:
	for child_name in ["TopHighlight", "LeftHighlight", "BottomShadow", "RightShadow", "InnerOverlay"]:
		if has_node(child_name):
			get_node(child_name).visible = show
