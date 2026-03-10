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
	_start_new_game()

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

	# Calculate grid coordinates
	var local_pos := piece.global_position - game_board.global_position
	var grid_col := int(local_pos.x / Constants.CELL_SIZE)
	var grid_row := int(local_pos.y / Constants.CELL_SIZE)
	var grid_pos := Vector2i(grid_col, grid_row)

	# Clear highlights
	game_board.highlight_cells([], false)

	if game_board.can_place_shape(piece.shape_cells, grid_pos):
		_place_piece(piece, grid_pos)
	else:
		piece.snap_back()

func _haptic_place() -> void:
	Input.vibrate_handheld(30)

func _haptic_line_clear(line_index: int, total_lines: int) -> void:
	# Each successive line vibrates longer and stronger
	var base_ms := 40
	var duration := base_ms + line_index * 30
	var delay := line_index * 0.15
	get_tree().create_timer(delay).timeout.connect(
		func(): Input.vibrate_handheld(duration)
	)

func _place_piece(piece: Node2D, grid_pos: Vector2i) -> void:
	game_board.place_shape(piece.shape_cells, grid_pos, piece.block_color)
	piece.mark_placed()
	game_board.sync_visual()

	# Haptic on placement
	_haptic_place()

	# Check line clears
	var lines: Dictionary = game_board.find_complete_lines()
	var total_lines: int = lines["rows"].size() + lines["cols"].size()

	if total_lines > 0:
		var cleared: Array[Vector2i] = game_board.clear_lines(lines)
		var points: int = GameState.add_line_clear_score(total_lines)

		# Haptic for each line cleared — escalating intensity
		for i in total_lines:
			_haptic_line_clear(i, total_lines)

		# Animate clear with gold lines for columns
		game_board.animate_clear(cleared, lines["rows"], lines["cols"])

		# Floating score effect
		var float_score := Label.new()
		float_score.set_script(preload("res://effects/floating_score.gd"))
		add_child(float_score)
		var board_center := game_board.global_position + Vector2(160, 160)
		float_score.show_score(points, board_center)

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
	game_over_screen.show_game_over(GameState.score, GameState.best_score)

func _on_play_again() -> void:
	_start_new_game()

func _process(_delta: float) -> void:
	if current_drag_piece:
		var local_pos := current_drag_piece.global_position - game_board.global_position
		var grid_col := int(local_pos.x / Constants.CELL_SIZE)
		var grid_row := int(local_pos.y / Constants.CELL_SIZE)
		var grid_pos := Vector2i(grid_col, grid_row)

		game_board.clear_all_highlights()

		if game_board.can_place_shape(current_drag_piece.shape_cells, grid_pos):
			var positions: Array[Vector2i] = []
			for offset in current_drag_piece.shape_cells:
				positions.append(grid_pos + offset)
			game_board.highlight_cells(positions, true)
