extends Control

const TITLE_SCENE := "res://scenes/title_screen.tscn"
const FONT_SIZE := 30
const FADE_SEC := 1.2
const TOTAL_SEC := 60.0
const SLIDE_IDS: PackedStringArray = ["ending1", "ending2", "ending3"]

const ENDING_COPY := "In Athens at night, a woman walks like a rumor that refused to die.\n\nThe streets tried their poetry: neon, scooters, men with opinions about sidewalks.\n\nShe survived both acts of the city's amateur tragedy.\n\nNot a hero. Not a tourist. Just still here — which, somehow, is the whole plot."

@onready var slide_a: TextureRect = %SlideA
@onready var slide_b: TextureRect = %SlideB
@onready var body_label: Label = %BodyLabel
@onready var return_button: Button = %ReturnButton
@onready var skip_button: Button = %SkipButton

var _segments: PackedStringArray = PackedStringArray()
var _segment_index: int = 0
var _full_segment: String = ""
var _typing: bool = false
var _type_tween: Tween
var _fade_tween: Tween
var _hold_tween: Tween
var _front_is_a: bool = true
var _slide_index: int = 0
var _sequence_done: bool = false
var _elapsed: float = 0.0
var _segment_beat: float = 15.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Music.play_ending_theme()

	return_button.visible = false
	return_button.pressed.connect(_go_to_title)
	_style_text_button(return_button, 20)

	skip_button.visible = true
	skip_button.pressed.connect(_go_to_title)
	_style_text_button(skip_button, 16)

	body_label.add_theme_font_size_override("font_size", FONT_SIZE)
	body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	slide_a.texture = SceneArt.texture_for(SLIDE_IDS[0])
	slide_a.modulate.a = 1.0
	slide_b.modulate.a = 0.0
	_front_is_a = true
	_slide_index = 0

	_segments = _split_segments(ENDING_COPY)
	_segment_index = 0
	_segment_beat = TOTAL_SEC / float(maxi(_segments.size(), 1))
	if _segments.is_empty():
		_finish_sequence()
	else:
		_show_current_segment()

	_schedule_slide_advances()


func _process(delta: float) -> void:
	if _sequence_done:
		return
	_elapsed += delta
	if _elapsed >= TOTAL_SEC:
		_finish_sequence()


func _schedule_slide_advances() -> void:
	var beat := TOTAL_SEC / float(SLIDE_IDS.size())
	for i in range(1, SLIDE_IDS.size()):
		var delay := beat * float(i) - FADE_SEC * 0.5
		get_tree().create_timer(maxf(delay, 0.0)).timeout.connect(
			_crossfade_to.bind(i)
		)


func _crossfade_to(index: int) -> void:
	if _sequence_done or index <= _slide_index or index >= SLIDE_IDS.size():
		return
	_slide_index = index
	var next_tex := SceneArt.texture_for(SLIDE_IDS[index])
	var front: TextureRect = slide_a if _front_is_a else slide_b
	var back: TextureRect = slide_b if _front_is_a else slide_a
	back.texture = next_tex
	back.modulate.a = 0.0
	back.z_index = front.z_index + 1

	if _fade_tween != null and is_instance_valid(_fade_tween):
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(back, "modulate:a", 1.0, FADE_SEC)
	_fade_tween.tween_property(front, "modulate:a", 0.0, FADE_SEC)
	_fade_tween.chain().tween_callback(func() -> void:
		_front_is_a = not _front_is_a
		front.z_index = 0
		back.z_index = 1
	)


func _split_segments(text: String) -> PackedStringArray:
	var parts := text.split("\n\n", false)
	var segments: PackedStringArray = PackedStringArray()
	for part in parts:
		var trimmed := part.strip_edges()
		if not trimmed.is_empty():
			segments.append(trimmed)
	if segments.is_empty() and not text.strip_edges().is_empty():
		segments.append(text.strip_edges())
	return segments


func _show_current_segment() -> void:
	_stop_typewriter()
	_cancel_hold()
	_full_segment = _segments[_segment_index]
	body_label.modulate.a = 1.0
	body_label.text = _full_segment
	body_label.visible_characters = 0
	_typing = true

	# Slow reveal: most of each beat typing, rest held so copy tracks the slides.
	var type_duration := _segment_beat * 0.72
	var hold_duration := _segment_beat * 0.28
	var char_count := maxi(_full_segment.length(), 1)
	_type_tween = create_tween()
	_type_tween.tween_property(body_label, "visible_characters", char_count, type_duration)
	_type_tween.finished.connect(
		_on_typewriter_finished.bind(hold_duration),
		CONNECT_ONE_SHOT
	)


func _on_typewriter_finished(hold_duration: float) -> void:
	_typing = false
	body_label.visible_characters = -1
	var is_last := _segment_index >= _segments.size() - 1
	if is_last:
		if _elapsed >= TOTAL_SEC:
			_finish_sequence()
		return

	_hold_tween = create_tween()
	_hold_tween.tween_interval(hold_duration)
	_hold_tween.tween_callback(func() -> void:
		if _sequence_done:
			return
		_segment_index += 1
		if _segment_index >= _segments.size():
			if _elapsed >= TOTAL_SEC:
				_finish_sequence()
			return
		_show_current_segment()
	)


func _cancel_hold() -> void:
	if _hold_tween != null and is_instance_valid(_hold_tween):
		_hold_tween.kill()
	_hold_tween = null


func _stop_typewriter() -> void:
	if _type_tween != null and is_instance_valid(_type_tween):
		_type_tween.kill()
	_type_tween = null
	_typing = false


func _finish_sequence() -> void:
	if _sequence_done:
		return
	_sequence_done = true
	_stop_typewriter()
	_cancel_hold()
	if not _full_segment.is_empty():
		body_label.text = _full_segment
		body_label.visible_characters = -1
	elif not _segments.is_empty():
		body_label.text = _segments[_segments.size() - 1]
		body_label.visible_characters = -1
	skip_button.visible = false
	return_button.visible = true


func _style_text_button(button: Button, font_size: int) -> void:
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)
	button.add_theme_color_override("font_color", Color(1, 1, 1, 0.72))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(0.85, 0.85, 0.85, 1))
	button.add_theme_font_size_override("font_size", font_size)
	button.alignment = HORIZONTAL_ALIGNMENT_RIGHT if button == skip_button else HORIZONTAL_ALIGNMENT_CENTER
	button.focus_mode = Control.FOCUS_NONE


func _go_to_title() -> void:
	Music.play_main_theme()
	get_tree().change_scene_to_file(TITLE_SCENE)
