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
		var col: int = origin.x + int(offset.x)
		var row: int = origin.y + int(offset.y)
		if col < 0 or col >= GRID_SIZE:
			return false
		if row < 0 or row >= GRID_SIZE:
			return false
		if grid[row][col]["occupied"]:
			return false
	return true

func place_shape(shape: Array, origin: Vector2i, color: Color) -> void:
	for offset in shape:
		var col: int = origin.x + int(offset.x)
		var row: int = origin.y + int(offset.y)
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
	var total_lines: int = lines["rows"].size() + lines["cols"].size()
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

# --- Visual Layer ---
var cell_nodes: Array = []

func _ready() -> void:
	init_grid()
	_create_visual_grid()

func _create_visual_grid() -> void:
	var grid_cell_script = preload("res://scenes/grid_cell.gd")
	cell_nodes.clear()
	for row in GRID_SIZE:
		var row_nodes: Array = []
		for col in GRID_SIZE:
			var cell := ColorRect.new()
			cell.set_script(grid_cell_script)
			cell.setup(col, row)
			add_child(cell)
			row_nodes.append(cell)
		cell_nodes.append(row_nodes)

func sync_visual() -> void:
	for row in GRID_SIZE:
		for col in GRID_SIZE:
			var data = grid[row][col]
			cell_nodes[row][col].set_occupied(data["occupied"], data["color"])

func clear_all_highlights() -> void:
	for row in GRID_SIZE:
		for col in GRID_SIZE:
			cell_nodes[row][col].set_highlight(false)

func highlight_cells(positions: Array[Vector2i], show: bool) -> void:
	if positions.is_empty():
		clear_all_highlights()
		return
	for pos in positions:
		if pos.x >= 0 and pos.x < GRID_SIZE and pos.y >= 0 and pos.y < GRID_SIZE:
			cell_nodes[pos.y][pos.x].set_highlight(show)

func get_board_rect() -> Rect2:
	var board_size := GRID_SIZE * CELL_SIZE
	return Rect2(global_position, Vector2(board_size, board_size))

func _draw() -> void:
	var board_size := GRID_SIZE * CELL_SIZE
	# 보드 외곽 프레임 (반투명 밝은 패딩)
	draw_rect(Rect2(-6, -6, board_size + 12, board_size + 12), Color(1, 1, 1, 0.08), true)
	# 보드 배경
	draw_rect(Rect2(0, 0, board_size, board_size), Constants.BG_GRID, true)
	# 미묘한 inner border/bevel
	draw_line(Vector2(0, 0), Vector2(board_size, 0), Color(1, 1, 1, 0.1), 1.0, true)
	draw_line(Vector2(0, 0), Vector2(0, board_size), Color(1, 1, 1, 0.05), 1.0, true)
	draw_line(Vector2(0, board_size), Vector2(board_size, board_size), Color(0, 0, 0, 0.2), 1.0, true)
	draw_line(Vector2(board_size, 0), Vector2(board_size, board_size), Color(0, 0, 0, 0.1), 1.0, true)
	# 그리드 라인 — 내부 구분선
	for i in range(1, GRID_SIZE):
		var offset := i * CELL_SIZE
		draw_line(Vector2(0, offset), Vector2(board_size, offset), Constants.GRID_LINE, 1.0, true)
		draw_line(Vector2(offset, 0), Vector2(offset, board_size), Constants.GRID_LINE, 1.0, true)
	# 보드-트레이 구분선
	draw_line(Vector2(0, board_size + 15), Vector2(board_size, board_size + 15), Color(1, 1, 1, 0.1), 1.0, true)

func animate_clear(cleared_cells: Array[Vector2i], rows: Array[int], cols: Array[int]) -> void:
	for pos in cleared_cells:
		if pos.y < cell_nodes.size() and pos.x < cell_nodes[pos.y].size():
			var cell_node = cell_nodes[pos.y][pos.x]
			var cell_color: Color = cell_node.color
			# 페이드아웃
			var tween := create_tween()
			tween.tween_property(cell_node, "modulate:a", 0.0, 0.2)
			tween.tween_callback(func():
				cell_node.modulate.a = 1.0
				cell_node.set_occupied(false, Color.TRANSPARENT)
			)
			# 파괴 파티클
			var break_fx := Node2D.new()
			break_fx.set_script(preload("res://effects/cell_break.gd"))
			add_child(break_fx)
			var world_pos := Vector2(
				pos.x * CELL_SIZE + CELL_SIZE * 0.5,
				pos.y * CELL_SIZE + CELL_SIZE * 0.5
			)
			break_fx.show_break(world_pos, cell_color)
	for col in cols:
		_show_gold_line(col)

func _show_gold_line(col: int) -> void:
	var line := ColorRect.new()
	line.size = Vector2(4, GRID_SIZE * CELL_SIZE)
	line.position = Vector2(col * CELL_SIZE + CELL_SIZE / 2 - 2, 0)
	line.color = Constants.BEST_SCORE
	line.modulate.a = 0.0
	add_child(line)
	var tween := create_tween()
	tween.tween_property(line, "modulate:a", 1.0, 0.1)
	tween.tween_property(line, "modulate:a", 0.0, 0.4)
	tween.tween_callback(line.queue_free)
