extends AudioStreamPlayer

const MAIN_THEME := "res://audio/music/main-theme.ogg"


func _ready() -> void:
	bus = "Master"
	volume_db = -6.0
	var theme := load(MAIN_THEME) as AudioStream
	if theme == null:
		push_warning("Missing music: %s" % MAIN_THEME)
		return
	stream = theme
	if not playing:
		play()


func play_main_theme() -> void:
	if stream == null:
		stream = load(MAIN_THEME) as AudioStream
	if stream != null and not playing:
		play()


func stop_music() -> void:
	stop()
