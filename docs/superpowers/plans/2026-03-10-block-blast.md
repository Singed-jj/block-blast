# Block Blast Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 8x8 그리드 기반 블록 배치 퍼즐 게임 "Block Blast"를 Godot 4로 구현한다.

**Architecture:** 데이터 모델(그리드/블록 셰이프)을 순수 GDScript 로직으로 분리하고, 씬 트리는 시각적 표현만 담당. AutoLoad로 게임 상태를 전역 관리하며, 드래그앤드롭은 Godot InputEvent 시스템 활용.

**Tech Stack:** Godot 4.4+, GDScript, GUT (Godot Unit Test) for testing

**Spec Reference:** `/Users/jaejin/projects/toy/game-spec-block-blast-2026-03-10/spec.md`

---

## File Structure

```
block-blast/
├── project.godot                    # Godot 프로젝트 설정 (해상도 390x844, Portrait)
├── CLAUDE.md                        # 프로젝트별 빌드/구조 안내
├── docs/
│   └── superpowers/plans/           # 이 계획 문서
│
├── autoloads/
│   ├── game_state.gd                # 전역 상태: score, best_score, combo, game phase
│   └── constants.gd                 # 색상 팔레트, 그리드 크기, 블록 정의
│
├── scenes/
│   ├── main.tscn + main.gd          # 루트 씬: 씬 조합, 게임 루프 제어
│   ├── game_board.tscn + game_board.gd  # 8x8 그리드: 셀 관리, 배치 판정, 줄 클리어
│   ├── grid_cell.tscn + grid_cell.gd    # 개별 셀: 점유 상태, 색상, 하이라이트
│   ├── piece_tray.tscn + piece_tray.gd  # 3개 블록 트레이: 피스 생성/관리
│   ├── block_piece.tscn + block_piece.gd # 드래그 가능한 블록 피스
│   ├── hud.tscn + hud.gd               # 점수, 베스트 점수, 설정 버튼
│   └── game_over.tscn + game_over.gd   # Game Over 오버레이 + PLAY 버튼
│
├── effects/
│   ├── floating_score.gd       # 떠오르는 점수 텍스트 (Label.new()로 동적 생성)
│   ├── combo_text.gd           # "Combo N" 표시
│   ├── feedback_text.gd        # "Good!" / "Great!" 표시
│   ├── heart_glow.gd           # 핑크/보라 네온 하트 발광
│   ├── gold_line.gd            # 세로열 클리어 골드 라인
│   └── tray_sparkle.gd         # 피스 트레이 스파클
│
└── tests/
    ├── test_grid_logic.gd           # 그리드 배치/클리어 로직 테스트
    ├── test_block_shapes.gd         # 블록 셰이프 정의 테스트
    └── test_scoring.gd              # 점수/콤보 계산 테스트
```

**파일별 책임:**
- `constants.gd`: 모든 상수 (색상 Hex, GRID_SIZE=8, 블록 셰이프 배열 등)
- `game_state.gd`: score/best_score/combo 관리, save/load (JSON), 시그널 발행
- `game_board.gd`: 2D 배열 `grid[8][8]`, 배치 가능 여부 판정, 줄 클리어 로직
- `block_piece.gd`: 드래그 입력 처리, 셰이프 데이터 보유, 그리드 스냅 프리뷰
- `piece_tray.gd`: 3개 피스 생성, 모두 배치 시 새 세트, game over 판정

---

## Chunk 1: 프로젝트 셋업 + 그리드 데이터 모델

### Task 0: Godot 4 설치 및 프로젝트 생성

**Files:**
- Create: `block-blast/project.godot`
- Create: `block-blast/CLAUDE.md`

- [ ] **Step 1: Godot 4 설치**

```fish
brew install godot
```

설치 확인:
```fish
godot --version
```
Expected: `4.4.x.stable` 이상

- [ ] **Step 2: Godot 프로젝트 초기화**

```fish
cd /Users/jaejin/projects/toy/block-blast
godot --headless --quit 2>/dev/null
```

또는 수동으로 `project.godot` 생성:

```ini
; Engine configuration file.
; It's best edited using the editor UI and not directly,
; but it can also be edited via text editor.

[application]

config/name="Block Blast"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.4")

[autoload]

Constants="*res://autoloads/constants.gd"
GameState="*res://autoloads/game_state.gd"

[display]

window/size/viewport_width=390
window/size/viewport_height=844
window/size/mode=2
window/stretch/mode="viewport"
window/stretch/aspect="keep_width"
window/handheld/orientation=1

[rendering]

renderer/rendering_method="mobile"
```

- [ ] **Step 3: CLAUDE.md 작성**

```markdown
# Block Blast

8x8 블록 배치 퍼즐 게임 (Godot 4).

## 빌드 & 실행
- `godot --path . --headless -s tests/test_grid_logic.gd` — 테스트 실행
- `godot --path .` — 에디터 실행
- `godot --path . --quit` — 프로젝트 검증

## 구조
- `autoloads/` — 전역 싱글턴 (Constants, GameState)
- `scenes/` — 씬 + 스크립트 (main, game_board, piece_tray 등)
- `effects/` — 시각 이펙트 씬
- `tests/` — GUT 테스트

## 스펙
- 원본: `../game-spec-block-blast-2026-03-10/spec.md`
```

- [ ] **Step 4: GUT 테스트 프레임워크 설치**

```fish
cd /Users/jaejin/projects/toy/block-blast
mkdir -p addons
git clone https://github.com/bitwes/Gut.git addons/gut --depth 1 --branch v9.3.0
```

`project.godot`에 GUT 플러그인 추가:
```ini
[editor_plugins]
enabled=PackedStringArray("res://addons/gut/plugin.cfg")
```

- [ ] **Step 5: 커밋**

```fish
cd /Users/jaejin/projects/toy/block-blast
git init; and git add -A; and git commit -m "chore: Godot 4 프로젝트 초기화 + GUT 테스트 프레임워크"
```

---

### Task 1: Constants 정의 (색상 팔레트 + 블록 셰이프)

**Files:**
- Create: `autoloads/constants.gd`
- Create: `tests/test_block_shapes.gd`

- [ ] **Step 1: 블록 셰이프 테스트 작성**

```gdscript
# tests/test_block_shapes.gd
extends GutTest

func test_all_shapes_have_cells():
    for shape_name in Constants.BLOCK_SHAPES:
        var shape = Constants.BLOCK_SHAPES[shape_name]
        assert_gt(shape.size(), 0, "Shape '%s' must have cells" % shape_name)

func test_shape_cells_are_vector2i():
    for shape_name in Constants.BLOCK_SHAPES:
        var shape = Constants.BLOCK_SHAPES[shape_name]
        for cell in shape:
            assert_typeof(cell, TYPE_VECTOR2I, "Cell in '%s' must be Vector2i" % shape_name)

func test_single_block():
    var shape = Constants.BLOCK_SHAPES["single"]
    assert_eq(shape, [Vector2i(0, 0)])

func test_horizontal_bar_3():
    var shape = Constants.BLOCK_SHAPES["h_bar_3"]
    assert_eq(shape.size(), 3)
    # 모든 셀의 y가 0 (가로)
    for cell in shape:
        assert_eq(cell.y, 0)

func test_l_shape_has_correct_cell_count():
    var shape = Constants.BLOCK_SHAPES["l_shape"]
    assert_eq(shape.size(), 4, "L-shape must have 4 cells")

func test_square_2x2():
    var shape = Constants.BLOCK_SHAPES["square_2x2"]
    assert_eq(shape.size(), 4)

func test_block_colors_count():
    assert_gte(Constants.BLOCK_COLORS.size(), 7, "At least 7 block colors")

func test_grid_size():
    assert_eq(Constants.GRID_SIZE, 8)
```

- [ ] **Step 2: 테스트 실행하여 실패 확인**

```fish
cd /Users/jaejin/projects/toy/block-blast
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_block_shapes.gd
```
Expected: FAIL — `Constants` 미존재

- [ ] **Step 3: constants.gd 구현**

```gdscript
# autoloads/constants.gd
extends Node

const GRID_SIZE := 8
const CELL_SIZE := 40  # pixels per cell

# --- Color Palette (from spec) ---
const BG_PRIMARY := Color("#4A5785")
const BG_GRID := Color("#1F2A5A")
const GRID_LINE := Color("#2A366A")
const SCORE_TEXT := Color("#F2F5FA")
const BEST_SCORE := Color("#F3B72B")

const BLOCK_COLORS: Array[Color] = [
    Color("#E74A4A"),  # Red
    Color("#51C95A"),  # Green
    Color("#4A7BFF"),  # Blue
    Color("#F3C93A"),  # Yellow/Orange
    Color("#7A5CE6"),  # Purple
    Color("#59C7F0"),  # Cyan
    Color("#F0A030"),  # Deep Orange
]

# --- Block Shapes ---
# 각 셰이프는 Vector2i 배열 (col, row 오프셋)
const BLOCK_SHAPES := {
    # Singles
    "single": [Vector2i(0, 0)],

    # Horizontal Bars
    "h_bar_2": [Vector2i(0, 0), Vector2i(1, 0)],
    "h_bar_3": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
    "h_bar_4": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
    "h_bar_5": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)],

    # Vertical Bars
    "v_bar_2": [Vector2i(0, 0), Vector2i(0, 1)],
    "v_bar_3": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)],
    "v_bar_4": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)],
    "v_bar_5": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4)],

    # Squares
    "square_2x2": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
    "square_3x3": [
        Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
        Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
        Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
    ],

    # L-shapes
    "l_shape": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)],
    "j_shape": [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(0, 2)],
    "l_shape_r": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)],
    "j_shape_r": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, 2)],

    # T-shapes
    "t_shape": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)],
    "t_shape_u": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
    "t_shape_l": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)],
    "t_shape_r": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)],

    # S/Z-shapes
    "s_shape": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
    "z_shape": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)],

    # Corners (2x2 with 1 cell missing)
    "corner_tl": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],
    "corner_tr": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)],
    "corner_bl": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
    "corner_br": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
}

# 랜덤 피스 생성용 가중치 (큰 블록은 덜 자주)
const SHAPE_WEIGHTS := {
    "single": 5,
    "h_bar_2": 8, "v_bar_2": 8,
    "h_bar_3": 10, "v_bar_3": 10,
    "h_bar_4": 6, "v_bar_4": 6,
    "h_bar_5": 3, "v_bar_5": 3,
    "square_2x2": 8, "square_3x3": 3,
    "l_shape": 5, "j_shape": 5, "l_shape_r": 5, "j_shape_r": 5,
    "t_shape": 4, "t_shape_u": 4, "t_shape_l": 4, "t_shape_r": 4,
    "s_shape": 5, "z_shape": 5,
    "corner_tl": 6, "corner_tr": 6, "corner_bl": 6, "corner_br": 6,
}

static func get_random_shape_name() -> String:
    var total_weight := 0
    for w in SHAPE_WEIGHTS.values():
        total_weight += w
    var roll := randi() % total_weight
    var cumulative := 0
    for shape_name in SHAPE_WEIGHTS:
        cumulative += SHAPE_WEIGHTS[shape_name]
        if roll < cumulative:
            return shape_name
    return SHAPE_WEIGHTS.keys()[0]

static func get_random_color() -> Color:
    return BLOCK_COLORS[randi() % BLOCK_COLORS.size()]
```

- [ ] **Step 4: 테스트 실행하여 통과 확인**

```fish
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_block_shapes.gd
```
Expected: ALL PASS

- [ ] **Step 5: 커밋**

```fish
git add autoloads/constants.gd tests/test_block_shapes.gd
git commit -m "feat: 블록 셰이프 카탈로그 + 색상 팔레트 정의"
```

---

### Task 2: GameState 싱글턴

**Files:**
- Create: `autoloads/game_state.gd`
- Create: `tests/test_scoring.gd`

- [ ] **Step 1: 점수/콤보 테스트 작성**

```gdscript
# tests/test_scoring.gd
extends GutTest

var state: Node

func before_each():
    state = preload("res://autoloads/game_state.gd").new()
    add_child(state)

func after_each():
    state.queue_free()

func test_initial_score_is_zero():
    assert_eq(state.score, 0)

func test_add_score():
    state.add_line_clear_score(1)
    assert_gt(state.score, 0)

func test_combo_increments():
    state.add_line_clear_score(1)  # combo becomes 1
    assert_eq(state.combo, 1)
    state.add_line_clear_score(1)  # combo becomes 2
    assert_eq(state.combo, 2)

func test_combo_resets_on_no_clear():
    state.add_line_clear_score(1)
    assert_eq(state.combo, 1)
    state.reset_combo()
    assert_eq(state.combo, 0)

func test_multi_line_clear_bonus():
    state.add_line_clear_score(1)
    var score_1 = state.score
    state.reset_score()
    state.add_line_clear_score(3)
    var score_3 = state.score
    assert_gt(score_3, score_1, "3-line clear should score more than 1-line")

func test_best_score_tracks_max():
    state.add_line_clear_score(2)
    state.add_line_clear_score(2)
    var current = state.score
    state.update_best_score()
    assert_eq(state.best_score, current)

func test_reset_game():
    state.add_line_clear_score(2)
    state.update_best_score()
    var best = state.best_score
    state.reset_game()
    assert_eq(state.score, 0)
    assert_eq(state.combo, 0)
    assert_eq(state.best_score, best, "Best score persists across resets")

func test_feedback_type_good():
    assert_eq(state.get_feedback_type(1), "Good!")

func test_feedback_type_great():
    assert_eq(state.get_feedback_type(2), "Great!")
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

```fish
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_scoring.gd
```
Expected: FAIL

- [ ] **Step 3: game_state.gd 구현**

```gdscript
# autoloads/game_state.gd
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

func _ready() -> void:
    load_best_score()

func add_line_clear_score(lines_cleared: int) -> int:
    combo += 1
    # 점수 = 기본점수 * 라인수 보너스 * 콤보 보너스
    var line_bonus := lines_cleared * lines_cleared  # 1→1, 2→4, 3→9
    var combo_bonus := 1.0 + (combo - 1) * 0.1  # combo 1→1.0, 2→1.1, ...
    var cells_cleared := lines_cleared * Constants.GRID_SIZE
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
```

- [ ] **Step 4: 테스트 실행 → 통과 확인**

```fish
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_scoring.gd
```
Expected: ALL PASS

- [ ] **Step 5: 커밋**

```fish
git add autoloads/game_state.gd tests/test_scoring.gd
git commit -m "feat: GameState 싱글턴 — 점수/콤보/베스트스코어 관리"
```

---

### Task 3: 그리드 로직 (배치 + 줄 클리어)

**Files:**
- Create: `scenes/game_board.gd` (로직 부분만 먼저)
- Create: `tests/test_grid_logic.gd`

- [ ] **Step 1: 그리드 로직 테스트 작성**

```gdscript
# tests/test_grid_logic.gd
extends GutTest

var board: Node

func before_each():
    board = preload("res://scenes/game_board.gd").new()
    add_child(board)
    board.init_grid()

func after_each():
    board.queue_free()

func test_grid_starts_empty():
    for row in Constants.GRID_SIZE:
        for col in Constants.GRID_SIZE:
            assert_false(board.is_cell_occupied(col, row))

func test_can_place_single_block():
    var shape = Constants.BLOCK_SHAPES["single"]
    assert_true(board.can_place_shape(shape, Vector2i(0, 0)))

func test_cannot_place_outside_grid():
    var shape = Constants.BLOCK_SHAPES["h_bar_3"]
    # h_bar_3 = col 0,1,2 offset → origin col=6 → max col=8 → 범위 초과
    assert_false(board.can_place_shape(shape, Vector2i(6, 0)),
        "3-wide bar at col 6 exceeds grid (col 6+2=8, out of 0-7)")
    assert_false(board.can_place_shape(shape, Vector2i(7, 0)))
    # col=5는 가능 (5+2=7, 범위 내)
    assert_true(board.can_place_shape(shape, Vector2i(5, 0)))

func test_place_shape_occupies_cells():
    var shape = Constants.BLOCK_SHAPES["square_2x2"]
    board.place_shape(shape, Vector2i(2, 3), Color.RED)
    assert_true(board.is_cell_occupied(2, 3))
    assert_true(board.is_cell_occupied(3, 3))
    assert_true(board.is_cell_occupied(2, 4))
    assert_true(board.is_cell_occupied(3, 4))

func test_cannot_place_on_occupied():
    var shape = Constants.BLOCK_SHAPES["single"]
    board.place_shape(shape, Vector2i(0, 0), Color.RED)
    assert_false(board.can_place_shape(shape, Vector2i(0, 0)))

func test_full_row_detected():
    # 8칸 가로줄을 채움
    for col in Constants.GRID_SIZE:
        board.place_shape([Vector2i(0, 0)], Vector2i(col, 0), Color.RED)
    var result = board.find_complete_lines()
    assert_has(result["rows"], 0)

func test_full_col_detected():
    for row in Constants.GRID_SIZE:
        board.place_shape([Vector2i(0, 0)], Vector2i(0, row), Color.RED)
    var result = board.find_complete_lines()
    assert_has(result["cols"], 0)

func test_clear_lines_empties_cells():
    for col in Constants.GRID_SIZE:
        board.place_shape([Vector2i(0, 0)], Vector2i(col, 0), Color.RED)
    var result = board.find_complete_lines()
    board.clear_lines(result)
    for col in Constants.GRID_SIZE:
        assert_false(board.is_cell_occupied(col, 0))

func test_simultaneous_row_and_col():
    # 행 0 전체 + 열 0 전체 채움
    for col in Constants.GRID_SIZE:
        board.place_shape([Vector2i(0, 0)], Vector2i(col, 0), Color.RED)
    for row in range(1, Constants.GRID_SIZE):
        board.place_shape([Vector2i(0, 0)], Vector2i(0, row), Color.BLUE)
    var result = board.find_complete_lines()
    assert_has(result["rows"], 0)
    assert_has(result["cols"], 0)
    var total = result["rows"].size() + result["cols"].size()
    assert_eq(total, 2)

func test_no_valid_placement_detected():
    # 그리드를 거의 다 채워서 특정 셰이프 배치 불가 확인
    var shape = Constants.BLOCK_SHAPES["square_3x3"]
    # 모든 셀 채우기
    for row in Constants.GRID_SIZE:
        for col in Constants.GRID_SIZE:
            board.place_shape([Vector2i(0, 0)], Vector2i(col, row), Color.RED)
    assert_false(board.has_valid_placement(shape))
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

```fish
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_grid_logic.gd
```
Expected: FAIL

- [ ] **Step 3: game_board.gd 로직 구현**

```gdscript
# scenes/game_board.gd
extends Node2D

signal lines_cleared(rows: Array[int], cols: Array[int])
signal piece_placed(grid_pos: Vector2i)

# grid[row][col] = { occupied: bool, color: Color }
var grid: Array = []

func init_grid() -> void:
    grid.clear()
    for row in Constants.GRID_SIZE:
        var row_data: Array = []
        for col in Constants.GRID_SIZE:
            row_data.append({"occupied": false, "color": Color.TRANSPARENT})
        grid.append(row_data)

func is_cell_occupied(col: int, row: int) -> bool:
    if col < 0 or col >= Constants.GRID_SIZE or row < 0 or row >= Constants.GRID_SIZE:
        return true  # 범위 밖은 점유로 취급
    return grid[row][col]["occupied"]

func can_place_shape(shape: Array, origin: Vector2i) -> bool:
    for offset in shape:
        var col := origin.x + offset.x
        var row := origin.y + offset.y
        if col < 0 or col >= Constants.GRID_SIZE:
            return false
        if row < 0 or row >= Constants.GRID_SIZE:
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

    # 행 검사
    for row in Constants.GRID_SIZE:
        var full := true
        for col in Constants.GRID_SIZE:
            if not grid[row][col]["occupied"]:
                full = false
                break
        if full:
            result["rows"].append(row)

    # 열 검사
    for col in Constants.GRID_SIZE:
        var full := true
        for row in Constants.GRID_SIZE:
            if not grid[row][col]["occupied"]:
                full = false
                break
        if full:
            result["cols"].append(col)

    return result

func clear_lines(lines: Dictionary) -> Array[Vector2i]:
    var cleared_cells: Array[Vector2i] = []

    for row in lines["rows"]:
        for col in Constants.GRID_SIZE:
            if grid[row][col]["occupied"]:
                cleared_cells.append(Vector2i(col, row))
                grid[row][col]["occupied"] = false
                grid[row][col]["color"] = Color.TRANSPARENT

    for col in lines["cols"]:
        for row in Constants.GRID_SIZE:
            if grid[row][col]["occupied"]:
                cleared_cells.append(Vector2i(col, row))
                grid[row][col]["occupied"] = false
                grid[row][col]["color"] = Color.TRANSPARENT

    var total_lines := lines["rows"].size() + lines["cols"].size()
    if total_lines > 0:
        lines_cleared.emit(lines["rows"], lines["cols"])

    return cleared_cells

func has_valid_placement(shape: Array) -> bool:
    for row in Constants.GRID_SIZE:
        for col in Constants.GRID_SIZE:
            if can_place_shape(shape, Vector2i(col, row)):
                return true
    return false

func has_any_valid_placement(shapes: Array) -> bool:
    for shape in shapes:
        if has_valid_placement(shape):
            return true
    return false
```

- [ ] **Step 4: 테스트 실행 → 통과 확인**

```fish
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_grid_logic.gd
```
Expected: ALL PASS

- [ ] **Step 5: 커밋**

```fish
git add scenes/game_board.gd tests/test_grid_logic.gd
git commit -m "feat: 8x8 그리드 로직 — 배치 판정, 줄 클리어, game over 감지"
```

---

## Chunk 2: 시각적 씬 구성 (그리드 + 셀 + 메인)

### Task 4: GridCell 씬 — 개별 셀 시각화

**Files:**
- Create: `scenes/grid_cell.tscn`
- Create: `scenes/grid_cell.gd`

- [ ] **Step 1: grid_cell.gd 작성**

```gdscript
# scenes/grid_cell.gd
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
        color = Constants.GRID_LINE.lightened(0.2)
    else:
        _update_visual()

func _update_visual() -> void:
    if is_occupied:
        color = block_color
    else:
        color = Constants.BG_GRID
```

- [ ] **Step 2: grid_cell.tscn 작성 (코드로 생성)**

```gdscript
# grid_cell.tscn을 코드로 구성 — 실제로는 에디터에서 만들지만,
# 이 프로젝트에서는 game_board.gd에서 동적 생성으로 처리
```

> Note: GridCell은 scene 파일 대신 game_board.gd에서 `ColorRect` + 스크립트로 동적 생성. 별도 .tscn 불필요.

- [ ] **Step 3: 커밋**

```fish
git add scenes/grid_cell.gd
git commit -m "feat: GridCell — 셀 시각화 컴포넌트"
```

---

### Task 5: GameBoard 씬 — 그리드 시각화

**Files:**
- Modify: `scenes/game_board.gd` (시각 레이어 추가)
- Create: `scenes/game_board.tscn`

- [ ] **Step 1: game_board.gd에 시각화 코드 추가**

`game_board.gd` 끝에 씬 관련 메서드 추가:

```gdscript
# --- Visual Layer ---
var cell_nodes: Array = []  # [row][col] = GridCell node
func _ready() -> void:
    init_grid()
    _create_visual_grid()

func _create_visual_grid() -> void:
    var grid_cell_script = preload("res://scenes/grid_cell.gd")
    cell_nodes.clear()
    for row in Constants.GRID_SIZE:
        var row_nodes: Array = []
        for col in Constants.GRID_SIZE:
            var cell := ColorRect.new()
            cell.set_script(grid_cell_script)
            cell.setup(col, row)
            add_child(cell)
            row_nodes.append(cell)
        cell_nodes.append(row_nodes)

func sync_visual() -> void:
    for row in Constants.GRID_SIZE:
        for col in Constants.GRID_SIZE:
            var data = grid[row][col]
            cell_nodes[row][col].set_occupied(data["occupied"], data["color"])

func clear_all_highlights() -> void:
    for row in Constants.GRID_SIZE:
        for col in Constants.GRID_SIZE:
            cell_nodes[row][col].set_highlight(false)

func highlight_cells(positions: Array[Vector2i], show: bool) -> void:
    if positions.is_empty():
        clear_all_highlights()
        return
    for pos in positions:
        if pos.x >= 0 and pos.x < Constants.GRID_SIZE and pos.y >= 0 and pos.y < Constants.GRID_SIZE:
            cell_nodes[pos.y][pos.x].set_highlight(show)

func get_board_rect() -> Rect2:
    var board_size := Constants.GRID_SIZE * Constants.CELL_SIZE
    return Rect2(global_position, Vector2(board_size, board_size))
```

- [ ] **Step 2: game_board.tscn 작성**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/game_board.gd" id="1"]

[node name="GameBoard" type="Node2D"]
script = ExtResource("1")
```

- [ ] **Step 3: 에디터에서 시각 확인**

```fish
godot --path /Users/jaejin/projects/toy/block-blast
```
8x8 그리드가 다크 네이비 셀로 표시되는지 확인.

- [ ] **Step 4: 커밋**

```fish
git add scenes/game_board.gd scenes/game_board.tscn scenes/grid_cell.gd
git commit -m "feat: 8x8 그리드 시각화 — 셀 동적 생성"
```

---

### Task 6: BlockPiece — 드래그 가능한 블록 피스

**Files:**
- Create: `scenes/block_piece.gd`
- Create: `scenes/block_piece.tscn`

- [ ] **Step 1: block_piece.gd 작성**

```gdscript
# scenes/block_piece.gd
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

const TRAY_SCALE := 0.6
const DRAG_SCALE := 1.0
const DRAG_Y_OFFSET := -80  # 손가락 위에 표시

func setup(p_shape_name: String, p_color: Color) -> void:
    shape_name = p_shape_name
    shape_cells = Constants.BLOCK_SHAPES[p_shape_name]
    block_color = p_color
    scale = Vector2(TRAY_SCALE, TRAY_SCALE)
    _draw_cells()

func _draw_cells() -> void:
    # 기존 자식 제거
    for child in get_children():
        child.queue_free()

    for offset in shape_cells:
        var cell := ColorRect.new()
        cell.size = Vector2(Constants.CELL_SIZE, Constants.CELL_SIZE)
        cell.position = Vector2(offset.x * Constants.CELL_SIZE, offset.y * Constants.CELL_SIZE)
        cell.color = block_color
        # 약간의 3D bevel 효과를 위한 마진
        cell.size -= Vector2(2, 2)
        cell.position += Vector2(1, 1)
        add_child(cell)

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
```

- [ ] **Step 2: block_piece.tscn 작성**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/block_piece.gd" id="1"]

[node name="BlockPiece" type="Node2D"]
script = ExtResource("1")
```

- [ ] **Step 3: 커밋**

```fish
git add scenes/block_piece.gd scenes/block_piece.tscn
git commit -m "feat: BlockPiece — 드래그 가능한 블록 피스 + 스냅백 애니메이션"
```

---

### Task 7: PieceTray — 3개 블록 관리

**Files:**
- Create: `scenes/piece_tray.gd`
- Create: `scenes/piece_tray.tscn`

- [ ] **Step 1: piece_tray.gd 작성**

```gdscript
# scenes/piece_tray.gd
extends HBoxContainer

signal piece_drag_started(piece: Node2D)
signal piece_drag_ended(piece: Node2D)
signal all_pieces_placed

var pieces: Array[Node2D] = []
var block_piece_scene := preload("res://scenes/block_piece.tscn")
const MAX_PIECES := 3

func generate_new_set() -> void:
    # 기존 피스 제거
    for piece in pieces:
        if is_instance_valid(piece):
            piece.queue_free()
    pieces.clear()

    for i in MAX_PIECES:
        var piece: Node2D = block_piece_scene.instantiate()
        var shape_name := Constants.get_random_shape_name()
        var color := Constants.get_random_color()
        piece.setup(shape_name, color)
        piece.drag_started.connect(_on_piece_drag_started)
        piece.drag_ended.connect(_on_piece_drag_ended)
        piece.placed.connect(_on_piece_placed)
        add_child(piece)
        pieces.append(piece)

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
```

- [ ] **Step 2: piece_tray.tscn 작성**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/piece_tray.gd" id="1"]

[node name="PieceTray" type="HBoxContainer"]
script = ExtResource("1")
custom_minimum_size = Vector2(390, 120)
alignment = 1
```

- [ ] **Step 3: 커밋**

```fish
git add scenes/piece_tray.gd scenes/piece_tray.tscn
git commit -m "feat: PieceTray — 3개 블록 세트 관리 + 자동 리필"
```

---

## Chunk 3: 메인 씬 + HUD + Game Over

### Task 8: HUD 씬

**Files:**
- Create: `scenes/hud.gd`
- Create: `scenes/hud.tscn`

- [ ] **Step 1: hud.gd 작성**

```gdscript
# scenes/hud.gd
extends Control

@onready var score_label := $ScoreLabel
@onready var best_score_label := $BestScoreLabel
@onready var crown_icon := $CrownIcon
@onready var settings_button := $SettingsButton
@onready var notification_badge := $NotificationBadge

func _ready() -> void:
    GameState.score_changed.connect(_on_score_changed)
    GameState.best_score_changed.connect(_on_best_score_changed)
    _on_score_changed(GameState.score)
    _on_best_score_changed(GameState.best_score)
    _setup_settings_button()

func _on_score_changed(new_score: int) -> void:
    score_label.text = str(new_score)

func _on_best_score_changed(new_best: int) -> void:
    best_score_label.text = str(new_best)

func _setup_settings_button() -> void:
    settings_button.text = "⚙"
    settings_button.flat = true
    settings_button.add_theme_font_size_override("font_size", 28)
    notification_badge.text = "●"
    notification_badge.add_theme_color_override("font_color", Color("#FF2E2E"))
    notification_badge.add_theme_font_size_override("font_size", 10)
```

- [ ] **Step 2: hud.tscn 작성**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/hud.gd" id="1"]

[node name="HUD" type="Control"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_bottom = 100.0
script = ExtResource("1")

[node name="CrownIcon" type="Label" parent="."]
layout_mode = 0
offset_left = 16.0
offset_top = 40.0
offset_right = 56.0
offset_bottom = 70.0
text = "👑"

[node name="BestScoreLabel" type="Label" parent="."]
layout_mode = 0
offset_left = 50.0
offset_top = 40.0
offset_right = 180.0
offset_bottom = 70.0
text = "0"

[node name="ScoreLabel" type="Label" parent="."]
layout_mode = 0
offset_left = 100.0
offset_top = 65.0
offset_right = 290.0
offset_bottom = 100.0
text = "0"
horizontal_alignment = 1

[node name="SettingsButton" type="Button" parent="."]
layout_mode = 0
offset_left = 340.0
offset_top = 40.0
offset_right = 380.0
offset_bottom = 75.0
text = "⚙"
flat = true

[node name="NotificationBadge" type="Label" parent="."]
layout_mode = 0
offset_left = 368.0
offset_top = 36.0
offset_right = 380.0
offset_bottom = 48.0
text = "●"
```

> Note: 정확한 레이아웃은 에디터에서 조정. 여기서는 구조만 정의.

- [ ] **Step 3: 커밋**

```fish
git add scenes/hud.gd scenes/hud.tscn
git commit -m "feat: HUD — 점수 + 베스트 스코어 표시"
```

---

### Task 9: Game Over 씬

**Files:**
- Create: `scenes/game_over.gd`
- Create: `scenes/game_over.tscn`

- [ ] **Step 1: game_over.gd 작성**

```gdscript
# scenes/game_over.gd
extends Control

signal play_again_pressed

@onready var final_score_label := $FinalScoreLabel
@onready var best_score_label := $BestScoreLabel
@onready var play_button := $PlayButton

func _ready() -> void:
    play_button.pressed.connect(_on_play_pressed)
    visible = false

func show_game_over(score: int, best_score: int) -> void:
    final_score_label.text = str(score)
    best_score_label.text = str(best_score)
    visible = true
    # 페이드인 애니메이션
    modulate.a = 0.0
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _on_play_pressed() -> void:
    visible = false
    play_again_pressed.emit()
```

- [ ] **Step 2: game_over.tscn 구조**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/game_over.gd" id="1"]

[node name="GameOver" type="Control"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.2, 0.4, 0.9, 0.85)

[node name="GameOverLabel" type="Label" parent="."]
layout_mode = 1
anchors_preset = 5
anchor_left = 0.5
anchor_right = 0.5
offset_top = 200.0
text = "Game Over"
horizontal_alignment = 1

[node name="FinalScoreLabel" type="Label" parent="."]
layout_mode = 1
anchors_preset = 5
anchor_left = 0.5
anchor_right = 0.5
offset_top = 320.0
text = "0"
horizontal_alignment = 1

[node name="BestScoreLabel" type="Label" parent="."]
layout_mode = 1
anchors_preset = 5
anchor_left = 0.5
anchor_right = 0.5
offset_top = 400.0
text = "Best Score: 0"
horizontal_alignment = 1

[node name="PlayButton" type="Button" parent="."]
layout_mode = 1
anchors_preset = 5
anchor_left = 0.5
anchor_right = 0.5
offset_left = -40.0
offset_top = 500.0
offset_right = 40.0
offset_bottom = 580.0
text = "▶"
```

- [ ] **Step 3: 커밋**

```fish
git add scenes/game_over.gd scenes/game_over.tscn
git commit -m "feat: Game Over 화면 — 최종 점수 + PLAY 버튼"
```

---

### Task 10: Main 씬 — 게임 루프 통합

**Files:**
- Create: `scenes/main.gd`
- Create: `scenes/main.tscn`

- [ ] **Step 1: main.gd 작성 — 핵심 게임 루프**

```gdscript
# scenes/main.gd
extends Control

@onready var game_board: Node2D = $GameBoard
@onready var piece_tray: HBoxContainer = $PieceTray
@onready var hud: Control = $HUD
@onready var game_over_screen: Control = $GameOver

var current_drag_piece: Node2D = null

func _ready() -> void:
    # 시그널 연결
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

    # 그리드 좌표 계산
    var board_rect := game_board.get_board_rect()
    var local_pos := piece.global_position - game_board.global_position
    var grid_col := int(local_pos.x / Constants.CELL_SIZE)
    var grid_row := int(local_pos.y / Constants.CELL_SIZE)
    var grid_pos := Vector2i(grid_col, grid_row)

    # 배치 가능 여부 확인
    if game_board.can_place_shape(piece.shape_cells, grid_pos):
        _place_piece(piece, grid_pos)
    else:
        piece.snap_back()
        game_board.highlight_cells([], false)

func _place_piece(piece: Node2D, grid_pos: Vector2i) -> void:
    # 블록 배치
    game_board.place_shape(piece.shape_cells, grid_pos, piece.block_color)
    piece.mark_placed()
    game_board.sync_visual()

    # 줄 클리어 확인
    var lines := game_board.find_complete_lines()
    var total_lines := lines["rows"].size() + lines["cols"].size()

    if total_lines > 0:
        var cleared := game_board.clear_lines(lines)
        var points := GameState.add_line_clear_score(total_lines)
        game_board.sync_visual()
        # TODO: 이펙트 표시 (Chunk 4에서 구현)
    else:
        GameState.reset_combo()

    # Game Over 체크
    _check_game_over()

func _check_game_over() -> void:
    var remaining_shapes := piece_tray.get_remaining_shapes()
    if remaining_shapes.is_empty():
        return  # 새 세트가 올 예정
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
        # 드래그 중 그리드 하이라이트 업데이트
        var local_pos := current_drag_piece.global_position - game_board.global_position
        var grid_col := int(local_pos.x / Constants.CELL_SIZE)
        var grid_row := int(local_pos.y / Constants.CELL_SIZE)
        var grid_pos := Vector2i(grid_col, grid_row)

        # 이전 하이라이트 제거
        game_board.highlight_cells([], false)

        if game_board.can_place_shape(current_drag_piece.shape_cells, grid_pos):
            var positions: Array[Vector2i] = []
            for offset in current_drag_piece.shape_cells:
                positions.append(grid_pos + offset)
            game_board.highlight_cells(positions, true)
```

- [ ] **Step 2: main.tscn 작성**

```
[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://scenes/main.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/game_board.tscn" id="2"]
[ext_resource type="PackedScene" path="res://scenes/piece_tray.tscn" id="3"]
[ext_resource type="PackedScene" path="res://scenes/hud.tscn" id="4"]
[ext_resource type="PackedScene" path="res://scenes/game_over.tscn" id="5"]

[node name="Main" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.29, 0.34, 0.52, 1.0)

[node name="HUD" parent="." instance=ExtResource("4")]

[node name="GameBoard" parent="." instance=ExtResource("2")]
position = Vector2(35, 150)

[node name="PieceTray" parent="." instance=ExtResource("3")]
layout_mode = 0
offset_left = 20.0
offset_top = 510.0
offset_right = 370.0
offset_bottom = 630.0

[node name="GameOver" parent="." instance=ExtResource("5")]
```

- [ ] **Step 3: 에디터에서 실행하여 기본 게임 루프 확인**

```fish
godot --path /Users/jaejin/projects/toy/block-blast
```

확인 항목:
- 8x8 그리드 표시됨
- 하단에 3개 블록 피스 표시됨
- 피스를 드래그하여 그리드에 배치 가능
- 행/열 클리어 동작
- 점수 증가
- 배치 불가 시 Game Over 화면

- [ ] **Step 4: 커밋**

```fish
git add scenes/main.gd scenes/main.tscn
git commit -m "feat: 메인 씬 — 게임 루프 통합 (배치→클리어→스코어→게임오버)"
```

---

## Chunk 4: 시각 이펙트 + 폴리시

### Task 11: 플로팅 점수 이펙트

**Files:**
- Create: `effects/floating_score.gd`
- Create: `effects/floating_score.tscn`

- [ ] **Step 1: floating_score.gd 작성**

```gdscript
# effects/floating_score.gd
extends Label

func show_score(points: int, start_pos: Vector2) -> void:
    text = "+%d" % points
    global_position = start_pos
    modulate = Color(1, 1, 1, 1)

    var tween := create_tween()
    tween.tween_property(self, "position:y", position.y - 60, 0.8)\
        .set_ease(Tween.EASE_OUT)
    tween.parallel().tween_property(self, "modulate:a", 0.0, 0.8)\
        .set_delay(0.3)
    tween.tween_callback(queue_free)
```

- [ ] **Step 2: 커밋**

```fish
git add effects/floating_score.gd
git commit -m "feat: 플로팅 점수 이펙트"
```

---

### Task 12: 콤보 텍스트 이펙트

**Files:**
- Create: `effects/combo_text.gd`
- Create: `effects/combo_text.tscn`

- [ ] **Step 1: combo_text.gd 작성**

```gdscript
# effects/combo_text.gd
extends Label

func show_combo(combo_count: int, start_pos: Vector2) -> void:
    text = "Combo %d" % combo_count
    global_position = start_pos
    modulate = Constants.BEST_SCORE  # 금색
    scale = Vector2(0.5, 0.5)
    pivot_offset = size / 2

    var tween := create_tween()
    tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)\
        .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
    tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
    tween.tween_interval(0.6)
    tween.tween_property(self, "modulate:a", 0.0, 0.3)
    tween.tween_callback(queue_free)
```

- [ ] **Step 2: 커밋**

```fish
git add effects/combo_text.gd
git commit -m "feat: 콤보 텍스트 이펙트 — 팝인 + 페이드아웃"
```

---

### Task 13: 피드백 텍스트 ("Good!" / "Great!")

**Files:**
- Create: `effects/feedback_text.gd`

- [ ] **Step 1: feedback_text.gd 작성**

```gdscript
# effects/feedback_text.gd
extends Label

func show_feedback(feedback: String, start_pos: Vector2) -> void:
    text = feedback
    global_position = start_pos
    modulate = Color("#F0A030")  # Orange glow
    scale = Vector2(0.3, 0.3)
    pivot_offset = size / 2

    var tween := create_tween()
    tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.15)\
        .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
    tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
    tween.tween_interval(0.5)
    tween.tween_property(self, "modulate:a", 0.0, 0.3)
    tween.tween_callback(queue_free)
```

- [ ] **Step 2: 커밋**

```fish
git add effects/feedback_text.gd
git commit -m "feat: Good!/Great! 피드백 텍스트 이펙트"
```

---

### Task 14: 이펙트를 메인 씬에 통합

**Files:**
- Modify: `scenes/main.gd` (`_place_piece` 메서드의 TODO 영역)

- [ ] **Step 1: main.gd에 이펙트 생성 코드 추가**

`_place_piece` 메서드의 이펙트 부분 교체:

```gdscript
# _place_piece 내부의 if total_lines > 0: 블록 교체 (Label.new() + set_script로 동적 생성)
    if total_lines > 0:
        var cleared := game_board.clear_lines(lines)
        var points := GameState.add_line_clear_score(total_lines)
        game_board.sync_visual()

        # 플로팅 점수
        var float_score := Label.new()
        float_score.set_script(preload("res://effects/floating_score.gd"))
        add_child(float_score)
        var board_center := game_board.global_position + Vector2(160, 160)
        float_score.show_score(points, board_center)

        # 피드백 텍스트
        var feedback := Label.new()
        feedback.set_script(preload("res://effects/feedback_text.gd"))
        add_child(feedback)
        var fb_text := GameState.get_feedback_type(total_lines)
        feedback.show_feedback(fb_text, board_center + Vector2(0, -40))

        # 콤보 (2 이상일 때만)
        if GameState.combo >= 2:
            var combo := Label.new()
            combo.set_script(preload("res://effects/combo_text.gd"))
            add_child(combo)
            combo.show_combo(GameState.combo, board_center + Vector2(0, -80))
```

- [ ] **Step 2: 실행 테스트**

```fish
godot --path /Users/jaejin/projects/toy/block-blast
```

확인 항목:
- 줄 클리어 시 플로팅 점수 표시
- "Good!" 또는 "Great!" 팝업
- 연속 클리어 시 "Combo N" 표시

- [ ] **Step 3: 커밋**

```fish
git add scenes/main.gd effects/
git commit -m "feat: 줄 클리어 이펙트 통합 — 플로팅 점수 + Good!/Great! + 콤보"
```

---

### Task 15: 줄 클리어 애니메이션 + 골드 라인

**Files:**
- Modify: `scenes/game_board.gd`
- Create: `effects/gold_line.gd`

- [ ] **Step 1: clear_lines에 애니메이션 추가 (행/열 구분)**

```gdscript
# game_board.gd에 추가
func animate_clear(cleared_cells: Array[Vector2i], rows: Array[int], cols: Array[int]) -> void:
    # 셀 페이드아웃
    for pos in cleared_cells:
        if pos.y < cell_nodes.size() and pos.x < cell_nodes[pos.y].size():
            var cell_node = cell_nodes[pos.y][pos.x]
            var tween := create_tween()
            tween.tween_property(cell_node, "modulate:a", 0.0, 0.2)
            tween.tween_callback(func():
                cell_node.modulate.a = 1.0
                cell_node.set_occupied(false, Color.TRANSPARENT)
            )

    # 세로열 클리어 시 골드 라인 이펙트
    for col in cols:
        _show_gold_line(col)

func _show_gold_line(col: int) -> void:
    var line := ColorRect.new()
    line.size = Vector2(4, Constants.GRID_SIZE * Constants.CELL_SIZE)
    line.position = Vector2(col * Constants.CELL_SIZE + Constants.CELL_SIZE / 2 - 2, 0)
    line.color = Constants.BEST_SCORE  # 골드
    line.modulate.a = 0.0
    add_child(line)
    var tween := create_tween()
    tween.tween_property(line, "modulate:a", 1.0, 0.1)
    tween.tween_property(line, "modulate:a", 0.0, 0.4)
    tween.tween_callback(line.queue_free)
```

- [ ] **Step 2: 커밋**

```fish
git add scenes/game_board.gd effects/gold_line.gd
git commit -m "feat: 줄 클리어 페이드아웃 + 세로열 골드 라인 이펙트"
```

---

### Task 15b: 하트 글로우 이펙트

**Files:**
- Create: `effects/heart_glow.gd`
- Modify: `scenes/main.gd`

- [ ] **Step 1: heart_glow.gd 작성**

```gdscript
# effects/heart_glow.gd
extends Label

func show_heart(start_pos: Vector2) -> void:
    text = "❤"
    global_position = start_pos
    add_theme_font_size_override("font_size", 48)
    modulate = Color("#E96BFF")  # Pink/Purple
    scale = Vector2(0.5, 0.5)
    pivot_offset = Vector2(24, 24)

    var tween := create_tween()
    tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.2)\
        .set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
    tween.tween_property(self, "modulate:a", 0.0, 0.6)\
        .set_delay(0.3)
    tween.tween_callback(queue_free)
```

- [ ] **Step 2: main.gd의 줄 클리어 이펙트에 하트 글로우 추가**

```gdscript
        # 하트 글로우 (줄 클리어/콤보 시)
        var heart := Label.new()
        heart.set_script(preload("res://effects/heart_glow.gd"))
        add_child(heart)
        var score_pos := hud.score_label.global_position + Vector2(0, -30)
        heart.show_heart(score_pos)
```

- [ ] **Step 3: 커밋**

```fish
git add effects/heart_glow.gd scenes/main.gd
git commit -m "feat: 하트 글로우 이펙트 — 줄 클리어 시 핑크/보라 네온"
```

---

### Task 15c: 피스 트레이 스파클

**Files:**
- Create: `effects/tray_sparkle.gd`
- Modify: `scenes/piece_tray.gd`

- [ ] **Step 1: tray_sparkle.gd 작성**

```gdscript
# effects/tray_sparkle.gd
extends Label

func show_sparkle(start_pos: Vector2) -> void:
    text = "✦"
    global_position = start_pos + Vector2(randf_range(-20, 20), randf_range(-10, 10))
    add_theme_font_size_override("font_size", randi_range(12, 20))
    modulate = Color(1, 1, 1, 0.8)

    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.6 + randf() * 0.4)
    tween.parallel().tween_property(self, "position:y", position.y - 15, 0.8)
    tween.tween_callback(queue_free)
```

- [ ] **Step 2: piece_tray.gd의 generate_new_set에 스파클 추가**

```gdscript
func generate_new_set() -> void:
    # ... 기존 코드 ...

    # 스파클 이펙트
    for i in 5:
        var sparkle := Label.new()
        sparkle.set_script(preload("res://effects/tray_sparkle.gd"))
        add_child(sparkle)
        sparkle.show_sparkle(global_position + Vector2(size.x * randf(), 0))
```

- [ ] **Step 3: 커밋**

```fish
git add effects/tray_sparkle.gd scenes/piece_tray.gd
git commit -m "feat: 피스 트레이 스파클 — 새 블록 세트 제공 시 반짝임"
```

---

## Chunk 5: 폴리시 + 배경/테마

### Task 16: 시각적 폴리시 — 블록 베벨 효과

**Files:**
- Modify: `scenes/grid_cell.gd`

- [ ] **Step 1: 3D 베벨 효과 추가**

```gdscript
# grid_cell.gd의 _update_visual() 교체
func _update_visual() -> void:
    if is_occupied:
        color = block_color
        # 3D bevel: top-left highlight, bottom-right shadow
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
```

- [ ] **Step 2: 커밋**

```fish
git add scenes/grid_cell.gd
git commit -m "feat: 블록 3D 베벨 효과 — 하이라이트/섀도우"
```

---

### Task 17: 그리드 라인 + 배경 스타일링

**Files:**
- Modify: `scenes/game_board.gd`

- [ ] **Step 1: 그리드 배경 + 라인 그리기**

```gdscript
# game_board.gd에 _draw() 추가
func _draw() -> void:
    var board_size := Constants.GRID_SIZE * Constants.CELL_SIZE

    # 보드 배경
    draw_rect(Rect2(-4, -4, board_size + 8, board_size + 8),
        Constants.BG_GRID.darkened(0.2), true)

    # 그리드 라인
    for i in range(Constants.GRID_SIZE + 1):
        var offset := i * Constants.CELL_SIZE
        # 가로
        draw_line(Vector2(0, offset), Vector2(board_size, offset),
            Constants.GRID_LINE, 1.0)
        # 세로
        draw_line(Vector2(offset, 0), Vector2(offset, board_size),
            Constants.GRID_LINE, 1.0)
```

- [ ] **Step 2: 커밋**

```fish
git add scenes/game_board.gd
git commit -m "feat: 그리드 배경 + 라인 스타일링"
```

---

### Task 18: HUD 스타일링 (폰트 + 색상)

**Files:**
- Modify: `scenes/hud.gd`
- Modify: `scenes/hud.tscn`

- [ ] **Step 1: HUD 레이블 스타일링**

```gdscript
# hud.gd의 _ready()에 스타일 적용 추가
func _ready() -> void:
    # 점수 라벨 스타일
    score_label.add_theme_font_size_override("font_size", 48)
    score_label.add_theme_color_override("font_color", Constants.SCORE_TEXT)
    score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    # 베스트 스코어 라벨 스타일
    best_score_label.add_theme_font_size_override("font_size", 24)
    best_score_label.add_theme_color_override("font_color", Constants.BEST_SCORE)

    GameState.score_changed.connect(_on_score_changed)
    GameState.best_score_changed.connect(_on_best_score_changed)
    _on_score_changed(GameState.score)
    _on_best_score_changed(GameState.best_score)
```

- [ ] **Step 2: 커밋**

```fish
git add scenes/hud.gd scenes/hud.tscn
git commit -m "feat: HUD 스타일링 — 스펙 색상 팔레트 적용"
```

---

### Task 19: Game Over 화면 스타일링

**Files:**
- Modify: `scenes/game_over.gd`

- [ ] **Step 1: Game Over 블루 그라데이션 + 스타일**

```gdscript
# game_over.gd의 show_game_over 수정
func _ready() -> void:
    play_button.pressed.connect(_on_play_pressed)
    visible = false
    _style_elements()

func _style_elements() -> void:
    # "Game Over" 텍스트
    var go_label := $GameOverLabel
    go_label.add_theme_font_size_override("font_size", 48)
    go_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))

    # 점수
    final_score_label.add_theme_font_size_override("font_size", 64)
    final_score_label.add_theme_color_override("font_color", Constants.SCORE_TEXT)

    # 베스트 점수
    best_score_label.add_theme_font_size_override("font_size", 24)
    best_score_label.add_theme_color_override("font_color", Constants.BEST_SCORE)

    # PLAY 버튼 (녹색 원형)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#51C95A")
    style.corner_radius_top_left = 40
    style.corner_radius_top_right = 40
    style.corner_radius_bottom_left = 40
    style.corner_radius_bottom_right = 40
    play_button.add_theme_stylebox_override("normal", style)
    play_button.add_theme_font_size_override("font_size", 32)
```

- [ ] **Step 2: 커밋**

```fish
git add scenes/game_over.gd
git commit -m "feat: Game Over 스타일링 — 블루 배경 + 녹색 PLAY 버튼"
```

---

### Task 20: 최종 통합 테스트 + 마무리

**Files:**
- Modify: `project.godot` (최종 확인)
- Modify: `CLAUDE.md` (업데이트)

- [ ] **Step 1: 전체 테스트 실행**

```fish
cd /Users/jaejin/projects/toy/block-blast
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/
```
Expected: ALL PASS

- [ ] **Step 2: 게임 플레이 테스트**

```fish
godot --path /Users/jaejin/projects/toy/block-blast
```

체크리스트:
- [ ] 8x8 그리드 표시 (다크 네이비 배경)
- [ ] 3개 블록 피스가 하단 트레이에 표시
- [ ] 블록 드래그 시 확대 + 그리드 위 프리뷰 하이라이트
- [ ] 유효 위치에 드롭 시 배치 + 셀 색상 변경
- [ ] 무효 위치에 드롭 시 스냅백 애니메이션
- [ ] 행/열 완성 시 클리어 + 페이드아웃
- [ ] 줄 클리어 시 점수 증가 + 플로팅 점수
- [ ] "Good!" (1줄) / "Great!" (2줄+) 피드백
- [ ] 연속 클리어 시 "Combo N" 표시
- [ ] 3개 블록 모두 배치 시 새 세트 생성
- [ ] 배치 불가 시 Game Over 화면
- [ ] 녹색 PLAY 버튼으로 재시작
- [ ] 베스트 스코어 유지

- [ ] **Step 3: WORKSPACE_INDEX.md 업데이트**

```fish
# /Users/jaejin/projects/toy/WORKSPACE_INDEX.md에 block-blast 추가
```

- [ ] **Step 4: 최종 커밋**

```fish
cd /Users/jaejin/projects/toy/block-blast
git add -A
git commit -m "feat: Block Blast v1.0 — 8x8 블록 퍼즐 게임 완성"
```

---

## Summary

| Chunk | Tasks | 내용 |
|-------|-------|------|
| 1 | 0-3 | 프로젝트 셋업 + 데이터 모델 (Constants, GameState, Grid 로직) |
| 2 | 4-7 | 시각적 씬 (GridCell, GameBoard, BlockPiece, PieceTray) |
| 3 | 8-10 | 메인 씬 + HUD(⚙️ 포함) + Game Over + 게임 루프 통합 |
| 4 | 11-15c | 시각 이펙트 (플로팅 점수, 콤보, Good!/Great!, 골드 라인, 하트 글로우, 트레이 스파클) |
| 5 | 16-20 | 폴리시 (베벨, 그리드라인, HUD/GameOver 스타일, 최종 테스트) |

**예상 파일 수**: ~23개 (스크립트 17 + 씬 6 + 설정 2)
**TDD 커버리지**: 그리드 로직, 블록 셰이프, 점수 시스템
**스펙 이펙트 커버리지**: 하트 글로우 ✅, 콤보 텍스트 ✅, Good!/Great! ✅, 플로팅 점수 ✅, 골드 라인 ✅, 드래그 확대 ✅, 클리어 페이드 ✅, Game Over 전환 ✅, 트레이 스파클 ✅
