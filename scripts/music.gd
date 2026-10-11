extends AudioStreamPlayer

const MAIN_THEME := "res://audio/music/main-theme.ogg"
const ENDING_THEME := "res://audio/music/ending-theme.ogg"

var _current_path: String = ""


func _ready() -> void:
	bus = "Master"
	volume_db = -6.0
	play_main_theme()


func play_main_theme() -> void:
	_play_track(MAIN_THEME, true)


func play_ending_theme() -> void:
	_play_track(ENDING_THEME, true)


func stop_music() -> void:
	stop()
	_current_path = ""


func _play_track(path: String, loop: bool) -> void:
	if _current_path == path and playing:
		return
	var theme := load(path) as AudioStream
	if theme == null:
		push_warning("Missing music: %s" % path)
		return
	if theme is AudioStreamOggVorbis:
		(theme as AudioStreamOggVorbis).loop = loop
	_current_path = path
	stream = theme
	play()
