# Block Blast Effects & Haptics Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 레퍼런스 게임 영상에서 관찰된 5가지 이펙트/햅틱 기능을 Block Blast에 구현한다.

**Architecture:** 기존 effects/ 디렉토리의 패턴(Label + Tween)을 따라 새 이펙트를 추가하고, 중앙 햅틱 매니저를 autoloads에 생성하여 모든 이펙트에서 통합 호출. 드래그 미리보기 민감도는 main.gd의 그리드 좌표 계산에 반올림 로직을 추가하여 개선.

**Tech Stack:** Godot 4.6, GDScript

---

## Issues Summary

| # | 기능 | 설명 | 레퍼런스 프레임 |
|---|------|------|---------------|
| 1 | 점수 다이아몬드 배경 | 점수 뒤에 파란 다이아몬드 형태 배경 + 점수 변경 시 펄스 애니메이션 | frame-001~010 |
| 2 | 드래그 미리보기 민감도 | 블록을 그리드 근처로 드래그할 때 더 빠르게/넓게 미리보기 하이라이트 | frame-006~007 |
| 3 | 대기 블록 생성 이펙트 | 새 블록 세트 등장 시 스케일 바운스 + 페이드인 애니메이션 | frame-006 |
| 4 | 라인 클리어 이펙트 | 셀 파괴 애니메이션 + 각 셀에서 숫자 플로팅 + 보드 글로우 + 무지개 그라데이션 | frame-008~010 |
| 5 | 통합 햅틱 시스템 | 모든 이펙트에 iOS/Android 햅틱. 강도별 차등 진동 | 전체 |

## File Structure

| 파일 | 변경 내용 |
|------|----------|
| `autoloads/haptic_manager.gd` | **신규** — 중앙 햅틱 매니저 (강도별 진동 패턴) |
| `scenes/hud.gd` | 점수 다이아몬드 배경 + 펄스 애니메이션 추가 |
| `scenes/main.gd` | 드래그 미리보기 반올림 로직, 클리어 이펙트 호출, 햅틱 호출을 매니저로 위임 |
| `scenes/game_board.gd` | 라인 클리어 시 셀별 파괴 애니메이션 + 보드 글로우 |
| `scenes/piece_tray.gd` | 대기 블록 생성 시 바운스 + 페이드인 애니메이션 |
| `effects/cell_break.gd` | **신규** — 셀 파괴 파티클 이펙트 (조각 흩어짐) |
| `effects/cell_score.gd` | **신규** — 클리어된 각 셀에서 숫자 플로팅 |
| `effects/board_glow.gd` | **신규** — 라인 클리어 시 보드 테두리 글로우 |
| `project.godot` | HapticManager autoload 등록 |

---

## Chunk 1: 햅틱 매니저 + 점수 다이아몬드

### Task 1: 중앙 햅틱 매니저 생성

**Files:**
- Create: `autoloads/haptic_manager.gd`
- Modify: `project.godot` (autoload 등록)
- Modify: `scenes/main.gd` (기존 햅틱 호출을 매니저로 위임)

- [ ] **Step 1: haptic_manager.gd 생성**

```gdscript
extends Node

## 진동 강도 레벨
enum Intensity { LIGHT, MEDIUM, HEAVY, SUCCESS, ERROR }

## 강도별 진동 시간(ms) 매핑
const VIBRATION_MS := {
	Intensity.LIGHT: 15,
	Intensity.MEDIUM: 30,
	Intensity.HEAVY: 60,
	Intensity.SUCCESS: 40,
	Intensity.ERROR: 80,
}

func vibrate(intensity: Intensity = Intensity.MEDIUM) -> void:
	var ms: int = VIBRATION_MS.get(intensity, 30)
	Input.vibrate_handheld(ms)

func vibrate_pattern(pattern: Array) -> void:
	## pattern = [{ "intensity": Intensity, "delay": float }]
	for i in pattern.size():
		var entry: Dictionary = pattern[i]
		var delay: float = entry.get("delay", 0.0)
		var intensity: Intensity = entry.get("intensity", Intensity.MEDIUM)
		if delay > 0.0:
			get_tree().create_timer(delay).timeout.connect(
				func(): vibrate(intensity)
			)
		else:
			vibrate(intensity)

## 편의 메서드
func light() -> void:
	vibrate(Intensity.LIGHT)

func medium() -> void:
	vibrate(Intensity.MEDIUM)

func heavy() -> void:
	vibrate(Intensity.HEAVY)

func place_block() -> void:
	vibrate(Intensity.MEDIUM)

func line_clear(line_index: int, total_lines: int) -> void:
	## 라인 수에 따라 강도 증가
	var base_intensity := Intensity.MEDIUM if total_lines <= 2 else Intensity.HEAVY
	var delay := line_index * 0.12
	if delay > 0.0:
		get_tree().create_timer(delay).timeout.connect(
			func(): vibrate(base_intensity)
		)
	else:
		vibrate(base_intensity)

func combo(combo_count: int) -> void:
	## 콤보 수에 따라 패턴 진동
	var intensity := Intensity.HEAVY if combo_count >= 4 else Intensity.MEDIUM
	vibrate(intensity)
	if combo_count >= 3:
		get_tree().create_timer(0.1).timeout.connect(
			func(): vibrate(Intensity.LIGHT)
		)

func new_pieces() -> void:
	vibrate(Intensity.LIGHT)

func score_pulse() -> void:
	vibrate(Intensity.LIGHT)
```

- [ ] **Step 2: project.godot에 autoload 등록**

`project.godot`의 `[autoload]` 섹션에 추가:

```ini
HapticManager="*res://autoloads/haptic_manager.gd"
```

- [ ] **Step 3: main.gd의 기존 햅틱 호출을 HapticManager로 위임**

`scenes/main.gd`에서 `_haptic_place()`와 `_haptic_line_clear()`를 교체:

기존:
```gdscript
func _haptic_place() -> void:
	Input.vibrate_handheld(30)

func _haptic_line_clear(line_index: int, total_lines: int) -> void:
	var base_ms := 40
	var duration := base_ms + line_index * 30
	var delay := line_index * 0.15
	get_tree().create_timer(delay).timeout.connect(
		func(): Input.vibrate_handheld(duration)
	)
```

변경:
```gdscript
func _haptic_place() -> void:
	HapticManager.place_block()

func _haptic_line_clear(line_index: int, total_lines: int) -> void:
	HapticManager.line_clear(line_index, total_lines)
```

- [ ] **Step 4: 검증**

```bash
godot --path /Users/jaejin/projects/toy/block-blast --headless --quit
```

- [ ] **Step 5: 커밋**

```bash
git add autoloads/haptic_manager.gd project.godot scenes/main.gd
git commit -m "feat: add centralized HapticManager with intensity levels"
```

---

### Task 2: 점수 다이아몬드 배경 + 펄스 애니메이션

**Files:**
- Modify: `scenes/hud.gd` (다이아몬드 배경 생성, 점수 변경 시 펄스)

레퍼런스에서 점수 숫자 뒤에 파란 다이아몬드(마름모) 형태 배경이 있고, 점수가 변경될 때 살짝 커졌다 줄어드는 펄스 애니메이션이 있다.

- [ ] **Step 1: hud.gd에 다이아몬드 배경 + 펄스 로직 추가**

`scenes/hud.gd`의 `_ready()` 함수에서 score_label 뒤에 다이아몬드 배경을 추가하고, `_on_score_changed()`에 펄스 애니메이션을 추가:

```gdscript
extends Control

@onready var score_label := $ScoreLabel
@onready var best_score_label := $BestScoreLabel
@onready var crown_icon := $CrownIcon
@onready var settings_button := $SettingsButton
@onready var notification_badge := $NotificationBadge

var score_diamond: ColorRect = null

func _ready() -> void:
	# Score style
	score_label.add_theme_font_size_override("font_size", 48)
	score_label.add_theme_color_override("font_color", Constants.SCORE_TEXT)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Best score style
	best_score_label.add_theme_font_size_override("font_size", 24)
	best_score_label.add_theme_color_override("font_color", Constants.BEST_SCORE)

	# Score diamond background (마름모 형태)
	_create_score_diamond()

	# Crown icon → TextureRect (PNG)
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

	# Settings icon → TextureRect (PNG)
	var settings_tex := load("res://assets/icons/settings.png")
	var settings_rect := TextureRect.new()
	settings_rect.texture = settings_tex
	settings_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	settings_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	settings_rect.custom_minimum_size = Vector2(32, 32)
	settings_rect.size = Vector2(32, 32)
	settings_rect.position = settings_button.position
	settings_button.get_parent().add_child(settings_rect)
	settings_button.queue_free()

	# Notification badge 제거
	notification_badge.queue_free()

	GameState.score_changed.connect(_on_score_changed)
	GameState.best_score_changed.connect(_on_best_score_changed)
	_on_score_changed(GameState.score)
	_on_best_score_changed(GameState.best_score)

func _create_score_diamond() -> void:
	score_diamond = ColorRect.new()
	score_diamond.color = Color(0.2, 0.5, 0.9, 0.35)
	score_diamond.size = Vector2(80, 80)
	score_diamond.pivot_offset = Vector2(40, 40)
	score_diamond.rotation_degrees = 45
	# 점수 라벨 중앙에 위치
	var label_center_x := score_label.position.x + score_label.size.x * 0.5
	var label_center_y := score_label.position.y + score_label.size.y * 0.5
	score_diamond.position = Vector2(label_center_x - 40, label_center_y - 40)
	score_diamond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# score_label보다 뒤에 배치
	score_label.get_parent().add_child(score_diamond)
	score_label.get_parent().move_child(score_diamond, score_label.get_index())

func _pulse_diamond() -> void:
	if score_diamond == null:
		return
	var tween := create_tween()
	tween.tween_property(score_diamond, "scale", Vector2(1.15, 1.15), 0.1)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(score_diamond, "scale", Vector2(1.0, 1.0), 0.15)\
		.set_ease(Tween.EASE_IN_OUT)
	HapticManager.score_pulse()

func _on_score_changed(new_score: int) -> void:
	score_label.text = str(new_score)
	if new_score > 0:
		_pulse_diamond()

func _on_best_score_changed(new_best: int) -> void:
	best_score_label.text = str(new_best)
```

- [ ] **Step 2: 검증**

```bash
godot --path /Users/jaejin/projects/toy/block-blast --headless --quit
```

- [ ] **Step 3: 커밋**

```bash
git add scenes/hud.gd
git commit -m "feat: add score diamond background with pulse animation"
```

---

## Chunk 2: 드래그 미리보기 민감도 + 대기 블록 이펙트

### Task 3: 드래그 미리보기 민감도 개선

**Files:**
- Modify: `scenes/main.gd:132-145` (_process 내 그리드 좌표 계산)

현재는 `int()` 절삭으로 좌표를 계산해서, 블록이 셀의 중앙을 넘어야 스냅된다. `round()`로 변경하면 셀 경계의 50%만 넘어도 바로 스냅되어 더 민감하게 반응한다.

- [ ] **Step 1: _process()의 그리드 좌표 계산을 round()로 변경**

`scenes/main.gd`에서 `_process()` 함수와 `_on_piece_drag_ended()` 함수의 좌표 계산:

기존 (`_process`):
```gdscript
var grid_col := int(local_pos.x / Constants.CELL_SIZE)
var grid_row := int(local_pos.y / Constants.CELL_SIZE)
```

변경:
```gdscript
var grid_col := roundi(local_pos.x / Constants.CELL_SIZE)
var grid_row := roundi(local_pos.y / Constants.CELL_SIZE)
```

기존 (`_on_piece_drag_ended`):
```gdscript
var grid_col := int(local_pos.x / Constants.CELL_SIZE)
var grid_row := int(local_pos.y / Constants.CELL_SIZE)
```

변경:
```gdscript
var grid_col := roundi(local_pos.x / Constants.CELL_SIZE)
var grid_row := roundi(local_pos.y / Constants.CELL_SIZE)
```

두 곳 모두 변경해야 미리보기와 실제 배치가 일치한다.

- [ ] **Step 2: 검증**

```bash
godot --path /Users/jaejin/projects/toy/block-blast --headless --quit
```

- [ ] **Step 3: 커밋**

```bash
git add scenes/main.gd
git commit -m "feat: improve drag preview sensitivity with round-based snapping"
```

---

### Task 4: 대기 블록 생성 시 바운스 + 페이드인 이펙트

**Files:**
- Modify: `scenes/piece_tray.gd:11-34` (generate_new_set 메서드)

레퍼런스에서 새 블록 세트가 나타날 때 작은 크기에서 스케일업 + 페이드인되는 애니메이션이 있다.

- [ ] **Step 1: piece_tray.gd의 generate_new_set()에 바운스 애니메이션 추가**

`_layout_pieces()` 호출 후, 각 피스에 바운스 + 페이드인 애니메이션 적용:

```gdscript
func generate_new_set() -> void:
	for piece in pieces:
		if is_instance_valid(piece):
			piece.queue_free()
	pieces.clear()
	var new_pieces: Array[Node2D] = []
	for i in MAX_PIECES:
		var piece: Node2D = block_piece_scene.instantiate()
		var shape_name := Constants.get_random_shape_name()
		var color := Constants.get_random_color()
		piece.setup(shape_name, color)
		piece.drag_started.connect(_on_piece_drag_started)
		piece.drag_ended.connect(_on_piece_drag_ended)
		piece.placed.connect(_on_piece_placed)
		add_child(piece)
		new_pieces.append(piece)
		pieces.append(piece)
	_layout_pieces(new_pieces)
	# 바운스 + 페이드인 애니메이션
	_animate_new_pieces(new_pieces)
	# Sparkle effect on new set
	for j in 5:
		var sparkle := Label.new()
		sparkle.set_script(preload("res://effects/tray_sparkle.gd"))
		add_child(sparkle)
		sparkle.show_sparkle(global_position + Vector2(size.x * randf(), 0))
	# 햅틱
	HapticManager.new_pieces()

func _animate_new_pieces(piece_list: Array[Node2D]) -> void:
	for i in piece_list.size():
		var piece := piece_list[i]
		var target_scale := piece.scale
		var target_pos := piece.position
		# 시작 상태: 작고 투명
		piece.scale = target_scale * 0.3
		piece.modulate.a = 0.0
		# 딜레이를 두고 순차 등장
		var delay := i * 0.08
		var tween := create_tween()
		tween.tween_interval(delay)
		tween.tween_property(piece, "modulate:a", 1.0, 0.15)
		tween.parallel().tween_property(piece, "scale", target_scale * 1.1, 0.15)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(piece, "scale", target_scale, 0.1)\
			.set_ease(Tween.EASE_IN_OUT)
```

- [ ] **Step 2: 검증**

```bash
godot --path /Users/jaejin/projects/toy/block-blast --headless --quit
```

- [ ] **Step 3: 커밋**

```bash
git add scenes/piece_tray.gd
git commit -m "feat: add bounce + fade-in animation for new piece generation"
```

---

## Chunk 3: 라인 클리어 이펙트 (핵심)

### Task 5: 셀별 숫자 플로팅 이펙트

**Files:**
- Create: `effects/cell_score.gd`
- Modify: `scenes/main.gd` (클리어 시 셀별 점수 표시 호출)

레퍼런스 frame-009에서 클리어된 각 셀 위치에서 숫자(포인트)가 플로팅된다.

- [ ] **Step 1: cell_score.gd 생성**

```gdscript
extends Label

func show_cell_score(points: int, pos: Vector2, delay: float = 0.0) -> void:
	text = str(points)
	add_theme_font_size_override("font_size", 16)
	add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	position = pos
	modulate.a = 0.0
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(self, "modulate:a", 1.0, 0.1)
	tween.parallel().tween_property(self, "position:y", pos.y - 30, 0.4)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
```

- [ ] **Step 2: main.gd에서 클리어 시 셀별 점수 호출**

`scenes/main.gd`의 `_place_piece()` 함수 내 라인 클리어 섹션에 추가:

기존 floating_score 블록 바로 뒤에:

```gdscript
		# 각 클리어된 셀에서 개별 숫자 플로팅
		var per_cell_points := points / max(cleared.size(), 1)
		for idx in cleared.size():
			var cell_pos: Vector2i = cleared[idx]
			var world_pos := game_board.global_position + Vector2(
				cell_pos.x * Constants.CELL_SIZE + Constants.CELL_SIZE * 0.5,
				cell_pos.y * Constants.CELL_SIZE + Constants.CELL_SIZE * 0.5
			)
			var cell_label := Label.new()
			cell_label.set_script(preload("res://effects/cell_score.gd"))
			add_child(cell_label)
			cell_label.show_cell_score(per_cell_points, world_pos, idx * 0.02)
```

- [ ] **Step 3: 검증**

```bash
godot --path /Users/jaejin/projects/toy/block-blast --headless --quit
```

- [ ] **Step 4: 커밋**

```bash
git add effects/cell_score.gd scenes/main.gd
git commit -m "feat: add per-cell floating score numbers on line clear"
```

---

### Task 6: 셀 파괴 파티클 이펙트

**Files:**
- Create: `effects/cell_break.gd`
- Modify: `scenes/game_board.gd:147-170` (animate_clear 메서드)

레퍼런스에서 셀이 사라질 때 조각이 흩어지는 파괴 이펙트가 있다.

- [ ] **Step 1: cell_break.gd 생성**

```gdscript
extends Node2D

## 셀 파괴 시 4개의 작은 조각이 흩어지는 이펙트
func show_break(pos: Vector2, color: Color) -> void:
	position = pos
	var piece_size := Vector2(8, 8)
	var offsets := [
		Vector2(-6, -6), Vector2(6, -6),
		Vector2(-6, 6), Vector2(6, 6),
	]
	var velocities := [
		Vector2(-40, -60), Vector2(40, -60),
		Vector2(-30, 50), Vector2(30, 50),
	]
	for i in 4:
		var shard := ColorRect.new()
		shard.size = piece_size
		shard.color = color.lightened(randf_range(-0.1, 0.2))
		shard.position = offsets[i]
		shard.pivot_offset = piece_size * 0.5
		add_child(shard)
		var tween := create_tween()
		var target_pos := offsets[i] + velocities[i] * randf_range(0.8, 1.2)
		tween.tween_property(shard, "position", target_pos, 0.4)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.parallel().tween_property(shard, "modulate:a", 0.0, 0.4)
		tween.parallel().tween_property(shard, "rotation_degrees",
			randf_range(-90, 90), 0.4)
		tween.parallel().tween_property(shard, "scale",
			Vector2(0.3, 0.3), 0.4)
	# 전체 노드 정리
	var cleanup := create_tween()
	cleanup.tween_interval(0.5)
	cleanup.tween_callback(queue_free)
```

- [ ] **Step 2: game_board.gd의 animate_clear()에 파괴 이펙트 추가**

`scenes/game_board.gd`의 `animate_clear()` 함수를 수정:

```gdscript
func animate_clear(cleared_cells: Array[Vector2i], rows: Array[int], cols: Array[int]) -> void:
	for idx in cleared_cells.size():
		var pos: Vector2i = cleared_cells[idx]
		if pos.y < cell_nodes.size() and pos.x < cell_nodes[pos.y].size():
			var cell_node = cell_nodes[pos.y][pos.x]
			var cell_color: Color = cell_node.color
			# 기존 페이드아웃
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
```

- [ ] **Step 3: 검증**

```bash
godot --path /Users/jaejin/projects/toy/block-blast --headless --quit
```

- [ ] **Step 4: 커밋**

```bash
git add effects/cell_break.gd scenes/game_board.gd
git commit -m "feat: add cell break particle effect on line clear"
```

---

### Task 7: 보드 글로우 이펙트

**Files:**
- Create: `effects/board_glow.gd`
- Modify: `scenes/main.gd` (라인 클리어 시 보드 글로우 호출)

레퍼런스 frame-009~010에서 라인 클리어 시 보드 테두리가 밝게 빛나는 글로우 이펙트가 있다. 큰 콤보일수록 더 강하게 빛난다.

- [ ] **Step 1: board_glow.gd 생성**

```gdscript
extends Node2D

## 보드 테두리에 글로우 이펙트 표시
func show_glow(board_rect: Rect2, intensity: float = 1.0) -> void:
	position = board_rect.position - Vector2(6, 6)
	var glow_size := board_rect.size + Vector2(12, 12)
	# 4면 글로우 바
	var glow_color := Color(0.4, 0.9, 0.4, 0.0)  # 초록빛 글로우 (레퍼런스)
	var bars := []
	# 상단
	var top := ColorRect.new()
	top.size = Vector2(glow_size.x, 4)
	top.color = glow_color
	add_child(top)
	bars.append(top)
	# 하단
	var bottom := ColorRect.new()
	bottom.size = Vector2(glow_size.x, 4)
	bottom.position.y = glow_size.y - 4
	bottom.color = glow_color
	add_child(bottom)
	bars.append(bottom)
	# 좌측
	var left := ColorRect.new()
	left.size = Vector2(4, glow_size.y)
	left.color = glow_color
	add_child(left)
	bars.append(left)
	# 우측
	var right := ColorRect.new()
	right.size = Vector2(4, glow_size.y)
	right.position.x = glow_size.x - 4
	right.color = glow_color
	add_child(right)
	bars.append(right)
	# 애니메이션: 페이드인 → 유지 → 페이드아웃
	var alpha := clampf(0.5 * intensity, 0.3, 0.9)
	for bar in bars:
		var tween := create_tween()
		tween.tween_property(bar, "color:a", alpha, 0.15)
		tween.tween_interval(0.3)
		tween.tween_property(bar, "color:a", 0.0, 0.4)
	# 정리
	var cleanup := create_tween()
	cleanup.tween_interval(1.0)
	cleanup.tween_callback(queue_free)
```

- [ ] **Step 2: main.gd에서 라인 클리어 시 보드 글로우 호출**

`scenes/main.gd`의 `_place_piece()` 함수 내, `game_board.animate_clear()` 호출 직후에 추가:

```gdscript
		# 보드 글로우 이펙트
		var glow := Node2D.new()
		glow.set_script(preload("res://effects/board_glow.gd"))
		add_child(glow)
		var glow_intensity := clampf(total_lines / 3.0, 0.5, 2.0)
		glow.show_glow(game_board.get_board_rect(), glow_intensity)
```

- [ ] **Step 3: main.gd의 라인 클리어 섹션에 콤보 햅틱 추가**

기존 콤보 표시 부분에 햅틱 추가:

```gdscript
		# Combo (show when >= 2)
		if GameState.combo >= 2:
			var combo_label := Label.new()
			combo_label.set_script(preload("res://effects/combo_text.gd"))
			add_child(combo_label)
			combo_label.show_combo(GameState.combo, board_center + Vector2(0, -80))
			HapticManager.combo(GameState.combo)
```

- [ ] **Step 4: 검증**

```bash
godot --path /Users/jaejin/projects/toy/block-blast --headless --quit
```

- [ ] **Step 5: 커밋**

```bash
git add effects/board_glow.gd scenes/main.gd
git commit -m "feat: add board glow effect and combo haptics on line clear"
```

---

## Task Dependency & Parallelization

```
Task 1 (햅틱 매니저) ──────────┐
         │                     │
         ▼                     │
Task 2 (점수 다이아몬드) ─┐    │
Task 3 (미리보기 민감도) ─┤── 병렬 (서로 다른 파일)
Task 4 (대기 블록 이펙트) ┘    │
         │                     │
         ▼                     │
Task 5 (셀 숫자 플로팅)  ─┐    │
Task 6 (셀 파괴 파티클)  ─┤── 병렬 (독립 이펙트 파일)
Task 7 (보드 글로우)     ─┘    │
```

**순서:**
1. Task 1 먼저 (다른 모든 Task가 HapticManager 의존)
2. Task 2, 3, 4 병렬
3. Task 5, 6, 7 병렬 (단, Task 5와 7은 main.gd 공유 → 주의)

## Verification Checklist

- [ ] 점수 뒤에 파란 다이아몬드 배경이 보이는가
- [ ] 점수 변경 시 다이아몬드가 펄스하는가
- [ ] 블록 드래그 시 미리보기가 더 빠르게 반응하는가
- [ ] 새 블록 세트 등장 시 바운스 + 페이드인 애니메이션이 있는가
- [ ] 라인 클리어 시 각 셀에서 숫자가 플로팅되는가
- [ ] 라인 클리어 시 셀 파괴 파티클이 흩어지는가
- [ ] 라인 클리어 시 보드 테두리가 글로우하는가
- [ ] 블록 배치, 라인 클리어, 콤보, 새 블록 등 모든 이벤트에 햅틱이 작동하는가
- [ ] 강한 이펙트(높은 콤보)일수록 강한 햅틱인가
