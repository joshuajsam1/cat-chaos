extends Node

# ---------------------------------------------------------------------------
# AudioManager — centralized SFX and music playback
# ---------------------------------------------------------------------------
# Sounds are loaded lazily from res://audio/. If a file doesn't exist the
# call is silently ignored so the game runs without audio assets.

const AUDIO_DIR: String = "res://audio/"

# Pool of AudioStreamPlayer nodes so sounds can overlap
const POOL_SIZE: int = 8

var _sfx_pool: Array[AudioStreamPlayer] = []
var _pool_index: int = 0
var _music_player: AudioStreamPlayer

var _cache: Dictionary = {}

func _ready() -> void:
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_pool.append(player)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

func play_sfx(sound_name: String, volume_db: float = 0.0) -> void:
	var stream := _get_stream(sound_name)
	if stream == null:
		return
	var player := _sfx_pool[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE
	player.stream = stream
	player.volume_db = volume_db
	player.play()

func play_music(sound_name: String, loop: bool = true) -> void:
	var stream := _get_stream(sound_name)
	if stream == null:
		return
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		# loop flag set on the resource; we just play it
		pass
	_music_player.stream = stream
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()

func _get_stream(sound_name: String) -> AudioStream:
	if _cache.has(sound_name):
		return _cache[sound_name]

	# Try common extensions
	for ext: String in ["ogg", "wav", "mp3"]:
		var path: String = AUDIO_DIR + sound_name + "." + ext
		if ResourceLoader.exists(path):
			var res: AudioStream = load(path)
			_cache[sound_name] = res
			return res

	# Asset missing — return null silently
	_cache[sound_name] = null
	return null
