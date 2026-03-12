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

func light() -> void:
	vibrate(Intensity.LIGHT)

func medium() -> void:
	vibrate(Intensity.MEDIUM)

func heavy() -> void:
	vibrate(Intensity.HEAVY)

func place_block() -> void:
	vibrate(Intensity.MEDIUM)
	SoundManager.place_block()

func line_clear(line_index: int, total_lines: int) -> void:
	var base_intensity := Intensity.MEDIUM if total_lines <= 2 else Intensity.HEAVY
	var delay := line_index * 0.12
	if delay > 0.0:
		get_tree().create_timer(delay).timeout.connect(
			func(): vibrate(base_intensity)
		)
	else:
		vibrate(base_intensity)
	SoundManager.line_clear(line_index, total_lines)

func combo(combo_count: int) -> void:
	var intensity := Intensity.HEAVY if combo_count >= 4 else Intensity.MEDIUM
	vibrate(intensity)
	if combo_count >= 3:
		get_tree().create_timer(0.1).timeout.connect(
			func(): vibrate(Intensity.LIGHT)
		)
	SoundManager.combo(combo_count)

func new_pieces() -> void:
	vibrate(Intensity.LIGHT)
	SoundManager.new_pieces()

func score_pulse() -> void:
	vibrate(Intensity.LIGHT)
