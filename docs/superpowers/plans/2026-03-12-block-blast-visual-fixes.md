# Block Blast Visual Fixes Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Block Blast 게임의 5가지 시각적 문제를 레퍼런스 이미지와 일치하도록 수정한다.

**Architecture:** Godot 4 프로젝트의 GDScript와 .tscn 파일을 수정. 깨지는 이모지를 Gemini CLI로 생성한 PNG 아이콘으로 교체, viewport 설정 변경, 셀 렌더링 방식 개선, 그리드 라인 가시성 향상, 대기 블록 스케일 조정.

**Tech Stack:** Godot 4.6, GDScript

---

## Issues Summary

| # | 문제 | 현재 상태 | 목표 |
|---|------|----------|------|
| 1 | 한글/이미지 깨짐 | 이모지(👑⚙) 깨짐 | Gemini CLI로 PNG 아이콘 생성 후 교체 |
| 2 | 화면 미충족 | 검은 테두리, 여백 | iPhone 전체 화면 사용 |
| 3 | 블록 간격/그림자 | 2px 갭, 얕은 베벨 | 밀착 + 그림자 구분 |
| 4 | Board grid 미표시 | 그리드 라인 안 보임 | 미세한 그리드 라인 표시 |
| 5 | 대기 블록 오버플로우 | 보드 경계 초과 가능 | 보드 폭 내 수용 |

## File Structure

| 파일 | 변경 내용 |
|------|----------|
| `assets/icons/crown.png` | Gemini CLI로 생성할 왕관 아이콘 (32x32) |
| `assets/icons/settings.png` | Gemini CLI로 생성할 설정 아이콘 (32x32) |
| `scenes/hud.tscn` | Label → TextureRect로 아이콘 교체 |
| `scenes/hud.gd` | TextureRect 아이콘 로딩 로직 |
| `project.godot` | viewport stretch aspect 변경 |
| `scenes/main.tscn` | 보드/트레이 위치를 뷰포트 비율 기반으로 조정 |
| `scenes/main.gd` | 동적 레이아웃 계산 추가 |
| `autoloads/constants.gd` | 색상 팔레트 조정 (그리드 라인, 배경) |
| `scenes/grid_cell.gd` | 셀 렌더링: gap 제거, 그림자 기반 구분 |
| `scenes/game_board.gd` | 그리드 라인 색상/두께 조정, 보드 배경 개선 |
| `scenes/block_piece.gd` | TRAY_SCALE 축소, 셀 렌더링 개선 |
| `scenes/piece_tray.gd` | 레이아웃 폭 제한 로직 추가 |

---

## Chunk 1: 이모지 깨짐 수정 + 그리드 라인 가시성

### Task 1: Gemini CLI로 PNG 아이콘 생성 후 이모지 교체

**Files:**
- Create: `assets/icons/crown.png` (Gemini CLI로 생성)
- Create: `assets/icons/settings.png` (Gemini CLI로 생성)
- Modify: `scenes/hud.tscn` (Label → TextureRect 교체)
- Modify: `scenes/hud.gd` (텍스처 로딩 + 스타일)

현재 이모지(👑, ⚙, ●)가 Godot 웹 익스포트에서 깨진다. Gemini CLI로 게임 스타일에 맞는 PNG 아이콘을 생성하여 교체한다.

- [ ] **Step 1: assets 디렉토리 생성**

```bash
mkdir -p /Users/jaejin/projects/toy/block-blast/assets/icons
```

- [ ] **Step 2: `gemini-web-image-gen` 스킬로 왕관 아이콘 생성**

`gemini-web-image-gen` 스킬을 호출하여 왕관 아이콘 생성:
- 프롬프트: "Golden crown icon, flat design, simple, clean, game UI icon, 64x64, transparent background, mobile puzzle game style"
- 저장 경로: `/Users/jaejin/projects/toy/block-blast/assets/icons/crown.png`

- [ ] **Step 3: `gemini-web-image-gen` 스킬로 설정 아이콘 생성**

`gemini-web-image-gen` 스킬을 호출하여 톱니바퀴 아이콘 생성:
- 프롬프트: "Gray gear settings icon, flat design, simple, clean, game UI icon, 64x64, transparent background, mobile puzzle game style"
- 저장 경로: `/Users/jaejin/projects/toy/block-blast/assets/icons/settings.png`

- [ ] **Step 4: 생성된 아이콘 확인**

Read 도구로 생성된 PNG 파일을 확인. 품질이 마음에 들지 않으면 프롬프트를 조정하여 재생성.

- [ ] **Step 5: hud.tscn — Label을 TextureRect로 교체**

`scenes/hud.tscn`에서 CrownIcon과 SettingsButton을 TextureRect로 변경:

```
# CrownIcon 노드 변경: Label → TextureRect
[node name="CrownIcon" type="TextureRect" parent="."]
layout_mode = 0
offset_left = 16.0
offset_top = 40.0
offset_right = 48.0
offset_bottom = 72.0
texture = ExtResource("crown_tex")
expand_mode = 1
stretch_mode = 5

# SettingsButton 노드 변경: Button → TextureButton
[node name="SettingsButton" type="TextureButton" parent="."]
layout_mode = 0
offset_left = 340.0
offset_top = 40.0
offset_right = 372.0
offset_bottom = 72.0
texture_normal = ExtResource("settings_tex")
stretch_mode = 5
```

또는 .tscn 직접 편집이 복잡하면 **hud.gd에서 런타임으로 텍스처 로딩**하는 방식도 가능:

```gdscript
# hud.gd — 런타임 텍스처 로딩 방식 (더 간단)
func _ready() -> void:
	# Crown icon → TextureRect
	var crown_tex := load("res://assets/icons/crown.png")
	var crown_rect := TextureRect.new()
	crown_rect.texture = crown_tex
	crown_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crown_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crown_rect.custom_minimum_size = Vector2(32, 32)
	crown_rect.size = Vector2(32, 32)
	crown_rect.position = crown_icon.position
	crown_icon.get_parent().add_child(crown_rect)
	crown_icon.queue_free()

	# Settings icon → TextureButton (클릭 가능)
	var settings_tex := load("res://assets/icons/settings.png")
	var settings_btn := TextureButton.new()
	settings_btn.texture_normal = settings_tex
	settings_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	settings_btn.custom_minimum_size = Vector2(32, 32)
	settings_btn.size = Vector2(32, 32)
	settings_btn.position = settings_button.position
	settings_button.get_parent().add_child(settings_btn)
	settings_button.queue_free()

	# NotificationBadge 제거
	notification_badge.queue_free()

	# Score style (기존 유지)
	score_label.add_theme_font_size_override("font_size", 48)
	score_label.add_theme_color_override("font_color", Constants.SCORE_TEXT)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_score_label.add_theme_font_size_override("font_size", 24)
	best_score_label.add_theme_color_override("font_color", Constants.BEST_SCORE)

	GameState.score_changed.connect(_on_score_changed)
	GameState.best_score_changed.connect(_on_best_score_changed)
	_on_score_changed(GameState.score)
	_on_best_score_changed(GameState.best_score)
```

- [ ] **Step 6: 검증**

Run: `godot --path /Users/jaejin/projects/toy/block-blast --headless --quit`
Expected: 에러 없이 종료

- [ ] **Step 7: 커밋**

```bash
git add assets/icons/ scenes/hud.tscn scenes/hud.gd
git commit -m "fix: replace broken emoji with Gemini-generated PNG icons"
```

---

### Task 2: 그리드 라인 가시성 향상

**Files:**
- Modify: `autoloads/constants.gd:8-9` (GRID_LINE 색상)
- Modify: `scenes/game_board.gd:139-145` (_draw 메서드)

현재 `GRID_LINE = #2A366A`와 `BG_GRID = #1F2A5A`의 명도 차이가 너무 작아 그리드가 안 보인다. 레퍼런스처럼 미세하지만 확실히 보이는 그리드로 변경한다.

- [ ] **Step 1: 그리드 라인 색상 조정**

`autoloads/constants.gd`에서:

```gdscript
const BG_GRID := Color("#1F2A5A")
const GRID_LINE := Color("#374478")  # 기존 #2A366A보다 밝게 — BG_GRID와 명도 차이 확대
```

- [ ] **Step 2: _draw()에서 그리드 라인 렌더링 개선**

`scenes/game_board.gd`의 `_draw()` 메서드:

```gdscript
func _draw() -> void:
	var board_size := GRID_SIZE * CELL_SIZE
	# 보드 배경 (약간 어두운 테두리 + 라운드 효과)
	draw_rect(Rect2(-4, -4, board_size + 8, board_size + 8), Constants.BG_GRID.darkened(0.3), true)
	# 내부 배경
	draw_rect(Rect2(0, 0, board_size, board_size), Constants.BG_GRID, true)
	# 그리드 라인 — 1px 실선으로 각 셀 경계 표시
	for i in range(1, GRID_SIZE):
		var offset := i * CELL_SIZE
		draw_line(Vector2(0, offset), Vector2(board_size, offset), Constants.GRID_LINE, 1.0, true)
		draw_line(Vector2(offset, 0), Vector2(offset, board_size), Constants.GRID_LINE, 1.0, true)
```

참고: `range(1, GRID_SIZE)`로 변경하여 외곽선은 제거하고 내부 구분선만 그린다. 외곽은 배경 테두리로 처리.

- [ ] **Step 3: 검증**

Run: `godot --path /Users/jaejin/projects/toy/block-blast --headless --quit`
Expected: 에러 없이 종료

- [ ] **Step 4: 커밋**

```bash
git add autoloads/constants.gd scenes/game_board.gd
git commit -m "fix: improve grid line visibility with better color contrast"
```

---

## Chunk 2: 블록 렌더링 개선 (밀착 + 그림자 구분)

### Task 3: 블록 셀 gap 제거 및 그림자 기반 구분

**Files:**
- Modify: `scenes/grid_cell.gd` (전체 리팩토링)
- Modify: `scenes/block_piece.gd:27-35` (_draw_cells 메서드)

레퍼런스에서 블록들은 gap 없이 밀착되어 있고, 셀 간 구분은 미세한 inner shadow로 처리된다. 현재는 2px gap + 상하 베벨 방식.

- [ ] **Step 1: grid_cell.gd — 셀 렌더링 리팩토링**

셀을 full-size(40x40)로 만들고, 4면 inner shadow로 셀 경계를 표현:

```gdscript
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
		_ensure_bevel()
		_show_bevel(true)
	else:
		color = Constants.BG_GRID
		_show_bevel(false)

func _ensure_bevel() -> void:
	if has_node("TopHighlight"):
		return
	# 상단 하이라이트 (밝은 edge)
	var top := ColorRect.new()
	top.name = "TopHighlight"
	top.size = Vector2(size.x, 2)
	top.color = Color(1, 1, 1, 0.3)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	# 좌측 하이라이트
	var left := ColorRect.new()
	left.name = "LeftHighlight"
	left.size = Vector2(2, size.y)
	left.color = Color(1, 1, 1, 0.15)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(left)
	# 하단 그림자 (어두운 edge)
	var bottom := ColorRect.new()
	bottom.name = "BottomShadow"
	bottom.size = Vector2(size.x, 2)
	bottom.position.y = size.y - 2
	bottom.color = Color(0, 0, 0, 0.3)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom)
	# 우측 그림자
	var right := ColorRect.new()
	right.name = "RightShadow"
	right.size = Vector2(2, size.y)
	right.position.x = size.x - 2
	right.color = Color(0, 0, 0, 0.15)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(right)

func _show_bevel(show: bool) -> void:
	for child_name in ["TopHighlight", "LeftHighlight", "BottomShadow", "RightShadow"]:
		if has_node(child_name):
			get_node(child_name).visible = show
```

- [ ] **Step 2: block_piece.gd — 대기 블록 셀도 동일한 렌더링 적용**

`scenes/block_piece.gd`의 `_draw_cells()` 메서드를 수정. gap 제거 + 4면 inner shadow:

```gdscript
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
```

- [ ] **Step 3: 검증**

Run: `godot --path /Users/jaejin/projects/toy/block-blast --headless --quit`
Expected: 에러 없이 종료

- [ ] **Step 4: 커밋**

```bash
git add scenes/grid_cell.gd scenes/block_piece.gd
git commit -m "fix: remove cell gaps and add 4-sided inner shadow for block separation"
```

---

## Chunk 3: 전체 화면 + 대기 블록 오버플로우 수정

### Task 4: 뷰포트 전체 화면 대응

**Files:**
- Modify: `project.godot:28-33` (display 설정)
- Modify: `scenes/main.tscn:26-33` (보드/트레이 위치)
- Modify: `scenes/main.gd` (동적 레이아웃)

현재 `keep_width` aspect 모드로 인해 아이폰 화면을 꽉 채우지 못한다. `expand` 모드로 변경하고, 레이아웃을 동적으로 계산한다.

- [ ] **Step 1: project.godot viewport 설정 변경**

```ini
[display]

window/size/viewport_width=390
window/size/viewport_height=844
window/stretch/mode="viewport"
window/stretch/aspect="expand"
window/handheld/orientation=1
```

`window/size/mode=2` 제거 (웹에서 불필요).

- [ ] **Step 2: main.gd에 동적 레이아웃 계산 추가**

`scenes/main.gd`의 `_ready()`에 뷰포트 크기 기반 동적 배치 로직 추가:

```gdscript
func _ready() -> void:
	piece_tray.piece_drag_started.connect(_on_piece_drag_started)
	piece_tray.piece_drag_ended.connect(_on_piece_drag_ended)
	piece_tray.all_pieces_placed.connect(_on_all_pieces_placed)
	game_over_screen.play_again_pressed.connect(_on_play_again)
	GameState.game_over_triggered.connect(_on_game_over)
	await get_tree().process_frame
	_layout_game()
	_start_new_game()

func _layout_game() -> void:
	var vp_size := get_viewport_rect().size
	var board_size := Constants.GRID_SIZE * Constants.CELL_SIZE  # 320
	var board_x := (vp_size.x - board_size) / 2.0
	var board_y := vp_size.y * 0.18  # 보드 시작 Y를 뷰포트 비율로
	game_board.position = Vector2(board_x, board_y)
	# 트레이: 보드 아래 여백 두고 배치
	var tray_y := board_y + board_size + 30
	var tray_width := board_size  # 보드 폭과 동일하게 제한
	piece_tray.offset_left = board_x
	piece_tray.offset_right = board_x + tray_width
	piece_tray.offset_top = tray_y
	piece_tray.offset_bottom = tray_y + 120
```

- [ ] **Step 3: main.tscn의 고정 위치를 초기값으로 유지 (런타임에 덮어씀)**

`scenes/main.tscn`은 그대로 두되, 런타임에 `_layout_game()`이 위치를 재계산하므로 문제없다. 단, PieceTray의 layout_mode를 0(자유 배치)으로 유지.

- [ ] **Step 4: 검증**

Run: `godot --path /Users/jaejin/projects/toy/block-blast --headless --quit`
Expected: 에러 없이 종료

- [ ] **Step 5: 커밋**

```bash
git add project.godot scenes/main.gd
git commit -m "fix: expand viewport to fill screen and add dynamic layout"
```

---

### Task 5: 대기 블록 보드 폭 내 수용

**Files:**
- Modify: `scenes/block_piece.gd:16-17` (TRAY_SCALE 조정)
- Modify: `scenes/piece_tray.gd:36-47` (_layout_pieces 개선)

대기 블록이 보드 좌우 경계를 벗어나지 않도록, 트레이 폭을 보드 폭(320px)으로 제한하고, 큰 블록은 스케일을 더 줄인다.

- [ ] **Step 1: block_piece.gd — TRAY_SCALE 축소**

```gdscript
const TRAY_SCALE := 0.5  # 기존 0.6 → 0.5로 축소
```

- [ ] **Step 2: piece_tray.gd — 적응형 스케일링 로직**

`scenes/piece_tray.gd`의 `_layout_pieces()`를 수정하여, 각 피스가 슬롯 폭을 초과하면 추가 축소:

```gdscript
func _layout_pieces(piece_list: Array[Node2D]) -> void:
	var tray_width := size.x if size.x > 0 else 320.0
	var slot_width := tray_width / MAX_PIECES
	for i in piece_list.size():
		var piece := piece_list[i]
		# 슬롯 폭에 맞춰 스케일 조정
		var base_scale := piece.TRAY_SCALE
		var bounding_at_base: Vector2 = piece.get_bounding_size() * base_scale
		var max_piece_width := slot_width - 8.0  # 양쪽 4px 여백
		if bounding_at_base.x > max_piece_width:
			base_scale = max_piece_width / piece.get_bounding_size().x
		piece.scale = Vector2(base_scale, base_scale)
		var bounding: Vector2 = piece.get_bounding_size() * piece.scale
		var slot_center_x := slot_width * i + slot_width * 0.5
		piece.position = Vector2(
			slot_center_x - bounding.x * 0.5,
			(size.y - bounding.y) * 0.5 if size.y > 0 else 10.0
		)
		piece.original_position = piece.position
```

- [ ] **Step 3: 검증**

Run: `godot --path /Users/jaejin/projects/toy/block-blast --headless --quit`
Expected: 에러 없이 종료

- [ ] **Step 4: 커밋**

```bash
git add scenes/block_piece.gd scenes/piece_tray.gd
git commit -m "fix: constrain waiting blocks within board width boundaries"
```

---

## Task Dependency & Parallelization

```
Task 1 (이모지)     ─┐
Task 2 (그리드 라인) ─┤── 병렬 가능 (서로 다른 파일)
Task 3 (블록 렌더링) ─┘
         │
         ▼
Task 4 (전체 화면)  ─┐── Task 4, 5는 순차 (main.gd 공유)
Task 5 (대기 블록)  ─┘   단, Task 5는 Task 3의 block_piece.gd 변경에 의존
```

**병렬 그룹 A** (동시 실행 가능):
- Task 1: 이모지 수정
- Task 2: 그리드 라인
- Task 3: 블록 렌더링

**순차 그룹 B** (그룹 A 완료 후):
- Task 4 → Task 5

## Visual Verification Checklist

모든 Task 완료 후 웹 빌드하여 아이폰에서 확인:

- [ ] 왕관 PNG 아이콘이 정상 표시되는가
- [ ] 설정(톱니바퀴) PNG 아이콘이 정상 표시되는가
- [ ] 게임 화면이 아이폰 전체를 꽉 채우는가 (검은 테두리 없음)
- [ ] 보드에 미세한 그리드 라인이 보이는가
- [ ] 배치된 블록들이 gap 없이 밀착되어 있는가
- [ ] 블록 셀 간 구분이 그림자(inner shadow)로 처리되는가
- [ ] 대기 블록이 보드 좌우 경계를 벗어나지 않는가
- [ ] 드래그 앤 드롭이 정상 작동하는가
