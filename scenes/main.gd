extends Control

@onready var game_board: Node2D = $GameBoard
@onready var piece_tray: HBoxContainer = $PieceTray
@onready var hud: Control = $HUD
@onready var game_over_screen: Control = $GameOver

var current_drag_piece: Node2D = null

func _ready() -> void:
	piece_tray.piece_drag_started.connect(_on_piece_drag_started)
	piece_tray.piece_drag_ended.connect(_on_piece_drag_ended)
	piece_tray.all_pieces_placed.connect(_on_all_pieces_placed)
	game_over_screen.play_again_pressed.connect(_on_play_again)
	GameState.game_over_triggered.connect(_on_game_over)
	# Defer to ensure layout sizes are resolved before positioning pieces
	await get_tree().process_frame
	_layout_game()
	_start_new_game()
	get_tree().root.size_changed.connect(_layout_game)

func _layout_game() -> void:
	var vp_size := get_viewport_rect().size
	var board_pixel: float = Constants.GRID_SIZE * Constants.CELL_SIZE  # 320

	# 보드를 뷰포트 폭의 85%로 스케일
	var target_width := vp_size.x * 0.85
	var board_scale := target_width / board_pixel
	game_board.scale = Vector2(board_scale, board_scale)
	var scaled_board := board_pixel * board_scale

	var board_x := (vp_size.x - scaled_board) / 2.0

	# 세로: HUD 아래 공간에서 보드+트레이를 중앙 배치
	var hud_h := 90.0
	var tray_h := 130.0
	var gap := 28.0
	var content_h := scaled_board + gap + tray_h
	var available_h := vp_size.y - hud_h
	var board_y := hud_h + (available_h - content_h) * 0.38

	game_board.position = Vector2(board_x, board_y)

	# 트레이: 스케일된 보드 아래 배치, 보드 폭과 동일
	var tray_y := board_y + scaled_board + gap
	piece_tray.offset_left = board_x
	piece_tray.offset_right = board_x + scaled_board
	piece_tray.offset_top = tray_y
	piece_tray.offset_bottom = tray_y + tray_h

	# HUD: 뷰포트 전체 폭
	hud.offset_left = 0
	hud.offset_right = vp_size.x
	hud.offset_top = 0
	hud.offset_bottom = hud_h

func _start_new_game() -> void:
	GameState.reset_game()
	game_board.init_grid()
	game_board.sync_visual()
	piece_tray.generate_new_set()

func _on_piece_drag_started(piece: Node2D) -> void:
	current_drag_piece = piece

func _on_piece_drag_ended(piece: Node2D) -> void:
	if current_drag_piece != piece:
		return
	current_drag_piece = null

	# Calculate grid coordinates (스케일 보정 포함)
	var local_pos := piece.global_position - game_board.global_position
	var scaled_cell := Constants.CELL_SIZE * game_board.scale.x
	var grid_col := roundi(local_pos.x / scaled_cell)
	var grid_row := roundi(local_pos.y / scaled_cell)
	var grid_pos := Vector2i(grid_col, grid_row)

	# Clear highlights
	game_board.highlight_cells([], false)

	if game_board.can_place_shape(piece.shape_cells, grid_pos):
		_place_piece(piece, grid_pos)
	else:
		SoundManager.error()
		piece.snap_back()

func _place_piece(piece: Node2D, grid_pos: Vector2i) -> void:
	game_board.place_shape(piece.shape_cells, grid_pos, piece.block_color)
	piece.mark_placed()
	game_board.sync_visual()

	# Haptic on placement
	HapticManager.place_block()

	# Check line clears
	var lines: Dictionary = game_board.find_complete_lines()
	var total_lines: int = lines["rows"].size() + lines["cols"].size()

	if total_lines > 0:
		var cleared: Array[Vector2i] = game_board.clear_lines(lines)
		var points: int = GameState.add_line_clear_score(total_lines)

		# Haptic for each line cleared — escalating intensity
		for i in total_lines:
			HapticManager.line_clear(i, total_lines)

		# Animate clear with gold lines for columns
		game_board.animate_clear(cleared, lines["rows"], lines["cols"])

		# Per-cell floating score numbers
		var sc := game_board.scale.x
		var per_cell_points: int = points / max(cleared.size(), 1)
		for idx in cleared.size():
			var cell_pos: Vector2i = cleared[idx]
			var world_pos := game_board.global_position + Vector2(
				(cell_pos.x * Constants.CELL_SIZE + Constants.CELL_SIZE * 0.5) * sc,
				(cell_pos.y * Constants.CELL_SIZE + Constants.CELL_SIZE * 0.5) * sc
			)
			var cell_label := Label.new()
			cell_label.set_script(preload("res://effects/cell_score.gd"))
			add_child(cell_label)
			cell_label.show_cell_score(per_cell_points, world_pos, idx * 0.02)

		# Floating score effect (total)
		var float_score := Label.new()
		float_score.set_script(preload("res://effects/floating_score.gd"))
		add_child(float_score)
		var half_board := Constants.GRID_SIZE * Constants.CELL_SIZE * 0.5 * sc
		var board_center := game_board.global_position + Vector2(half_board, half_board)
		float_score.show_score(points, board_center)

		# Board glow effect
		var glow := Node2D.new()
		glow.set_script(preload("res://effects/board_glow.gd"))
		add_child(glow)
		var glow_intensity := clampf(total_lines / 3.0, 0.5, 2.0)
		glow.show_glow(game_board.get_board_rect(), glow_intensity)

		# Feedback text (Good! / Great!)
		var feedback := Label.new()
		feedback.set_script(preload("res://effects/feedback_text.gd"))
		add_child(feedback)
		var fb_text := GameState.get_feedback_type(total_lines)
		feedback.show_feedback(fb_text, board_center + Vector2(0, -40))

		# Heart glow on line clear
		var heart := Label.new()
		heart.set_script(preload("res://effects/heart_glow.gd"))
		add_child(heart)
		var score_pos := hud.global_position + Vector2(150, 50)
		heart.show_heart(score_pos)

		# Combo (show when >= 2)
		if GameState.combo >= 2:
			var combo_label := Label.new()
			combo_label.set_script(preload("res://effects/combo_text.gd"))
			add_child(combo_label)
			combo_label.show_combo(GameState.combo, board_center + Vector2(0, -80))
			HapticManager.combo(GameState.combo)
	else:
		GameState.reset_combo()

	_check_game_over()

func _check_game_over() -> void:
	var remaining_shapes: Array = piece_tray.get_remaining_shapes()
	if remaining_shapes.is_empty():
		return
	if not game_board.has_any_valid_placement(remaining_shapes):
		GameState.trigger_game_over()

func _on_all_pieces_placed() -> void:
	piece_tray.generate_new_set()
	_check_game_over()

func _on_game_over() -> void:
	SoundManager.game_over()
	game_over_screen.show_game_over(GameState.score, GameState.best_score)

func _on_play_again() -> void:
	_start_new_game()

func _process(_delta: float) -> void:
	if current_drag_piece:
		var local_pos := current_drag_piece.global_position - game_board.global_position
		var scaled_cell := Constants.CELL_SIZE * game_board.scale.x
		var grid_col := roundi(local_pos.x / scaled_cell)
		var grid_row := roundi(local_pos.y / scaled_cell)
		var grid_pos := Vector2i(grid_col, grid_row)

		game_board.clear_all_highlights()

		if game_board.can_place_shape(current_drag_piece.shape_cells, grid_pos):
			var positions: Array[Vector2i] = []
			for offset in current_drag_piece.shape_cells:
				positions.append(grid_pos + offset)
			game_board.highlight_cells(positions, true)
