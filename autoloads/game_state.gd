extends Node

signal score_changed(new_score: int)
signal best_score_changed(new_best: int)
signal combo_changed(new_combo: int)
signal game_over_triggered
signal new_game_started

var score: int = 0
var best_score: int = 0
var combo: int = 0

const SAVE_PATH := "user://best_score.json"
const BASE_POINTS_PER_CELL := 10
const GRID_SIZE := 8

func _ready() -> void:
    load_best_score()

func add_line_clear_score(lines_cleared: int) -> int:
    combo += 1
    var line_bonus := lines_cleared * lines_cleared
    var combo_bonus := 1.0 + (combo - 1) * 0.1
    var cells_cleared := lines_cleared * GRID_SIZE
    var points := int(cells_cleared * BASE_POINTS_PER_CELL * line_bonus * combo_bonus)
    score += points
    score_changed.emit(score)
    combo_changed.emit(combo)
    return points

func reset_combo() -> void:
    combo = 0
    combo_changed.emit(combo)

func update_best_score() -> void:
    if score > best_score:
        best_score = score
        best_score_changed.emit(best_score)
        save_best_score()

func reset_score() -> void:
    score = 0
    combo = 0

func reset_game() -> void:
    update_best_score()
    score = 0
    combo = 0
    score_changed.emit(score)
    combo_changed.emit(combo)
    new_game_started.emit()

func trigger_game_over() -> void:
    update_best_score()
    game_over_triggered.emit()

func get_feedback_type(lines_cleared: int) -> String:
    if lines_cleared >= 2:
        return "Great!"
    return "Good!"

func save_best_score() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify({"best_score": best_score}))

func load_best_score() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
        if file:
            var data = JSON.parse_string(file.get_as_text())
            if data and data.has("best_score"):
                best_score = int(data["best_score"])
