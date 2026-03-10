extends Node2D

signal lines_cleared(rows: Array[int], cols: Array[int])
signal piece_placed(grid_pos: Vector2i)

const GRID_SIZE := 8
const CELL_SIZE := 40

var grid: Array = []

func init_grid() -> void:
	grid.clear()
	for row in GRID_SIZE:
		var row_data: Array = []
		for col in GRID_SIZE:
			row_data.append({"occupied": false, "color": Color.TRANSPARENT})
		grid.append(row_data)

func is_cell_occupied(col: int, row: int) -> bool:
	if col < 0 or col >= GRID_SIZE or row < 0 or row >= GRID_SIZE:
		return true
	return grid[row][col]["occupied"]

func can_place_shape(shape: Array, origin: Vector2i) -> bool:
	for offset in shape:
		var col := origin.x + offset.x
		var row := origin.y + offset.y
		if col < 0 or col >= GRID_SIZE:
			return false
		if row < 0 or row >= GRID_SIZE:
			return false
		if grid[row][col]["occupied"]:
			return false
	return true

func place_shape(shape: Array, origin: Vector2i, color: Color) -> void:
	for offset in shape:
		var col := origin.x + offset.x
		var row := origin.y + offset.y
		grid[row][col]["occupied"] = true
		grid[row][col]["color"] = color
	piece_placed.emit(origin)

func find_complete_lines() -> Dictionary:
	var result := {"rows": [] as Array[int], "cols": [] as Array[int]}
	for row in GRID_SIZE:
		var full := true
		for col in GRID_SIZE:
			if not grid[row][col]["occupied"]:
				full = false
				break
		if full:
			result["rows"].append(row)
	for col in GRID_SIZE:
		var full := true
		for row in GRID_SIZE:
			if not grid[row][col]["occupied"]:
				full = false
				break
		if full:
			result["cols"].append(col)
	return result

func clear_lines(lines: Dictionary) -> Array[Vector2i]:
	var cleared_cells: Array[Vector2i] = []
	for row in lines["rows"]:
		for col in GRID_SIZE:
			if grid[row][col]["occupied"]:
				cleared_cells.append(Vector2i(col, row))
				grid[row][col]["occupied"] = false
				grid[row][col]["color"] = Color.TRANSPARENT
	for col in lines["cols"]:
		for row in GRID_SIZE:
			if grid[row][col]["occupied"]:
				cleared_cells.append(Vector2i(col, row))
				grid[row][col]["occupied"] = false
				grid[row][col]["color"] = Color.TRANSPARENT
	var total_lines := lines["rows"].size() + lines["cols"].size()
	if total_lines > 0:
		lines_cleared.emit(lines["rows"], lines["cols"])
	return cleared_cells

func has_valid_placement(shape: Array) -> bool:
	for row in GRID_SIZE:
		for col in GRID_SIZE:
			if can_place_shape(shape, Vector2i(col, row)):
				return true
	return false

func has_any_valid_placement(shapes: Array) -> bool:
	for shape in shapes:
		if has_valid_placement(shape):
			return true
	return false
