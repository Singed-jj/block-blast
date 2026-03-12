extends Node

## Preloaded sound streams
var _streams := {
	"place": preload("res://assets/sfx/place.wav"),
	"clear": preload("res://assets/sfx/clear.wav"),
	"combo": preload("res://assets/sfx/combo.wav"),
	"new_pieces": preload("res://assets/sfx/new_pieces.wav"),
	"game_over": preload("res://assets/sfx/game_over.wav"),
	"error": preload("res://assets/sfx/error.wav"),
}

## Pool of AudioStreamPlayers for concurrent playback
var _players: Array[AudioStreamPlayer] = []
const POOL_SIZE := 6

func _ready() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		_players.append(player)
	_setup_ios_audio_unlock()

func _setup_ios_audio_unlock() -> void:
	if not OS.has_feature("web"):
		return
	# iOS Safari requires user gesture to unlock AudioContext
	JavaScriptBridge.eval("""
	(function() {
		var unlocked = false;
		function unlock() {
			if (unlocked) return;
			var ctx = window.AudioContext || window.webkitAudioContext;
			if (!ctx) return;
			// Try Godot's internal audio context first
			var godotCtx = (typeof GodotAudio !== 'undefined' && GodotAudio.ctx)
				? GodotAudio.ctx : new ctx();
			if (godotCtx.state === 'suspended') {
				godotCtx.resume().then(function() {
					unlocked = true;
					document.removeEventListener('touchstart', unlock, true);
					document.removeEventListener('touchend', unlock, true);
					document.removeEventListener('click', unlock, true);
				});
			} else {
				unlocked = true;
			}
		}
		document.addEventListener('touchstart', unlock, true);
		document.addEventListener('touchend', unlock, true);
		document.addEventListener('click', unlock, true);
	})();
	""")

func _get_free_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	return _players[0]  # fallback: reuse first

func _play(stream_name: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _streams.get(stream_name)
	if not stream:
		return
	var player := _get_free_player()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()

## --- Semantic API ---

func place_block() -> void:
	_play("place")

func line_clear(line_index: int, total_lines: int) -> void:
	var pitch := 1.0 + line_index * 0.1
	var delay := line_index * 0.12
	if delay > 0.0:
		get_tree().create_timer(delay).timeout.connect(
			func(): _play("clear", pitch)
		)
	else:
		_play("clear", pitch)

func combo(combo_count: int) -> void:
	var pitch := 1.0 + (combo_count - 1) * 0.15
	_play("combo", clampf(pitch, 1.0, 2.0))

func new_pieces() -> void:
	_play("new_pieces")

func game_over() -> void:
	_play("game_over")

func error() -> void:
	_play("error")
