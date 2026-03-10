extends ColorRect

var grid_pos := Vector2i.ZERO
var is_occupied := false
var block_color := Color.TRANSPARENT

func setup(col: int, row: int) -> void:
	grid_pos = Vector2i(col, row)
	size = Vector2(Constants.CELL_SIZE, Constants.CELL_SIZE)
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
		if not has_node("Highlight"):
			var highlight := ColorRect.new()
			highlight.name = "Highlight"
			highlight.size = Vector2(size.x, 3)
			highlight.color = Color(1, 1, 1, 0.25)
			highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(highlight)
			var shadow := ColorRect.new()
			shadow.name = "Shadow"
			shadow.size = Vector2(size.x, 3)
			shadow.position.y = size.y - 3
			shadow.color = Color(0, 0, 0, 0.2)
			shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(shadow)
		_show_bevel(true)
	else:
		color = Constants.BG_GRID
		_show_bevel(false)

func _show_bevel(show: bool) -> void:
	if has_node("Highlight"):
		get_node("Highlight").visible = show
	if has_node("Shadow"):
		get_node("Shadow").visible = show
