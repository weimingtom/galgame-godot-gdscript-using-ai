extends Node

## BGM / 音效播放，支持淡入淡出与循环

const DEFAULT_FADE := 1.0
const DEFAULT_VOLUME := -10.0

var _bgm_player: AudioStreamPlayer
var _se_player: AudioStreamPlayer
var _current_bgm: String = ""
var _fade_tween: Tween


func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = &"Music"
	add_child(_bgm_player)
	_se_player = AudioStreamPlayer.new()
	_se_player.bus = &"SFX"
	add_child(_se_player)


func play_bgm(path: String, fade: float = DEFAULT_FADE, volume_db: float = DEFAULT_VOLUME) -> void:
	if path.is_empty():
		return
	if not ResourceLoader.exists(path):
		push_warning("BGM 不存在: %s" % path)
		return
	if path == _current_bgm and _bgm_player.playing:
		_bgm_player.volume_db = volume_db
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	_apply_loop(stream)
	_fade_tween = _kill_tween(_fade_tween)
	if _bgm_player.playing and fade > 0.0:
		_fade_tween = create_tween()
		_fade_tween.tween_method(_set_bgm_volume, _bgm_player.volume_db, -40.0, fade * 0.5)
		_fade_tween.tween_callback(func() -> void:
			_start_bgm(stream, path, volume_db, fade * 0.5)
		)
	else:
		_start_bgm(stream, path, volume_db, 0.0)


func stop_bgm(fade: float = DEFAULT_FADE) -> void:
	if not _bgm_player.playing:
		_current_bgm = ""
		return
	_fade_tween = _kill_tween(_fade_tween)
	if fade <= 0.0:
		_bgm_player.stop()
		_current_bgm = ""
		return
	_fade_tween = create_tween()
	_fade_tween.tween_method(_set_bgm_volume, _bgm_player.volume_db, -40.0, fade)
	_fade_tween.tween_callback(func() -> void:
		_bgm_player.stop()
		_current_bgm = ""
	)


func play_se(path: String, volume_db: float = -6.0) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("音效不存在: %s" % path)
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	_se_player.stream = stream
	_se_player.volume_db = volume_db
	_se_player.play()


func set_paused(paused: bool) -> void:
	_bgm_player.stream_paused = paused
	_se_player.stream_paused = paused


func _start_bgm(stream: AudioStream, path: String, volume_db: float, fade_in: float) -> void:
	_bgm_player.stream = stream
	_current_bgm = path
	if fade_in > 0.0:
		_bgm_player.volume_db = -40.0
		_bgm_player.play()
		var tween := create_tween()
		tween.tween_method(_set_bgm_volume, -40.0, volume_db, fade_in)
	else:
		_bgm_player.volume_db = volume_db
		_bgm_player.play()


func _set_bgm_volume(value: float) -> void:
	_bgm_player.volume_db = value


func _apply_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream is AudioStreamOggVorbis:
		stream.loop = true


func _kill_tween(tween: Tween) -> Tween:
	if tween != null and tween.is_valid():
		tween.kill()
	return null
