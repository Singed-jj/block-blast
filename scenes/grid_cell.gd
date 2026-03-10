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
	else:
		color = Constants.BG_GRID
