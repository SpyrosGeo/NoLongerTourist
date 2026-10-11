class_name EncounterUI
extends CanvasLayer

signal choice_selected(choice_id: String)
signal examine_pressed
signal continue_pressed
signal segments_ready
signal next_night_pressed
signal restart_run_pressed

enum Phase { INTRO, CHOICES, OUTCOME }

const TYPEWRITER_CPS := 42.0
const CONTINUE_DOTS := " ..."
const EXAMINE_TWEEN_SEC := 0.18

@onready var title_label: Label = %TitleLabel
@onready var bubble_panel: PanelContainer = %BubblePanel
@onready var bubble_label: Label = %BubbleLabel
@onready var choices_row: VBoxContainer = %ChoicesRow
@onready var continue_button: Button = %ContinueButton
@onready var restart_button: Button = %RestartButton
@onready var energy_bar: ProgressBar = %EnergyBar
@onready var energy_label: Label = %EnergyLabel
@onready var examine_overlay: Control = %ExamineOverlay
@onready var examine_dimmer: ColorRect = %Dimmer
@onready var examine_portrait: TextureRect = %ExaminePortrait
@onready var examine_clues_label: Label = %ExamineCluesLabel
@onready var cancel_examine_button: Button = %CancelExamineButton
@onready var side_column: VBoxContainer = %SideColumn

var _phase: Phase = Phase.INTRO
var _segments: PackedStringArray = PackedStringArray()
var _segment_index: int = 0
var _awaiting_advance: bool = false
var _examine_button: Button
var _examine_enabled: bool = false
var _full_segment: String = ""
var _typing: bool = false
var _type_tween: Tween
var _dots_tween: Tween
var _examine_tween: Tween
var _examine_closing: bool = false
var _outcome_survive: bool = true


func _ready() -> void:
	continue_button.pressed.connect(func() -> void: continue_pressed.emit())
	restart_button.pressed.connect(_on_outcome_button_pressed)
	cancel_examine_button.pressed.connect(close_examine)
	bubble_panel.gui_input.connect(_on_bubble_gui_input)
	_style_text_line(continue_button)
	_style_text_line(restart_button)
	_style_text_line(cancel_examine_button)
	cancel_examine_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	set_energy(100, 100)
	examine_overlay.visible = false
	examine_overlay.modulate.a = 0.0
	show_phase_intro()


func _unhandled_input(event: InputEvent) -> void:
	if examine_overlay.visible and not _examine_closing:
		if event.is_action_pressed("ui_cancel"):
			close_examine()
			get_viewport().set_input_as_handled()
			return
	if examine_overlay.visible:
		return
	if event.is_action_pressed("ui_accept"):
		if _typing or _awaiting_advance:
			_skip_or_advance_from_click()
			get_viewport().set_input_as_handled()


func set_title(text: String) -> void:
	title_label.text = text


func set_energy(current: int, maximum: int) -> void:
	energy_bar.max_value = maximum
	energy_bar.value = current
	energy_label.text = "%d/%d" % [current, maximum]


func set_examine_texture(texture: Texture2D) -> void:
	examine_portrait.texture = texture


func set_examine_enabled(enabled: bool) -> void:
	_examine_enabled = enabled
	if _examine_button != null and is_instance_valid(_examine_button):
		_examine_button.disabled = not enabled
		_style_text_line(_examine_button, not enabled)


func set_body(text: String) -> void:
	play_segments(text, _phase)


func play_segments(text: String, phase: Phase) -> void:
	_stop_typewriter()
	_stop_dots_pulse()
	_phase = phase
	_segments = _split_segments(text)
	_segment_index = 0
	_clear_choices()
	continue_button.visible = false
	restart_button.visible = false
	_awaiting_advance = false
	if _segments.is_empty():
		bubble_label.text = ""
		bubble_label.visible_characters = -1
		_on_segments_finished()
		return
	_show_current_segment()


func show_phase_intro() -> void:
	_phase = Phase.INTRO
	_clear_choices()
	continue_button.visible = false
	restart_button.visible = false
	close_examine(true)


func show_phase_choices() -> void:
	_phase = Phase.CHOICES
	continue_button.visible = false
	restart_button.visible = false


func set_choices(choices: Dictionary, examine_enabled: bool = false) -> void:
	_examine_enabled = examine_enabled
	_clear_choices()
	show_phase_choices()

	_examine_button = Button.new()
	_examine_button.text = "Examine carefully"
	_examine_button.focus_mode = Control.FOCUS_NONE
	_examine_button.disabled = not examine_enabled
	_style_text_line(_examine_button, not examine_enabled)
	_examine_button.pressed.connect(func() -> void: examine_pressed.emit())
	choices_row.add_child(_examine_button)

	for choice_id in choices.keys():
		var entry: Variant = choices[choice_id]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var choice: Dictionary = entry
		var button := Button.new()
		button.text = String(choice.get("text", choice_id))
		button.focus_mode = Control.FOCUS_NONE
		_style_text_line(button)
		button.pressed.connect(_on_choice.bind(String(choice_id)))
		choices_row.add_child(button)


func show_outcome_continue(ending: String) -> void:
	_clear_choices()
	continue_button.visible = false
	_outcome_survive = ending != "dead"
	restart_button.visible = true
	restart_button.text = "Next night" if _outcome_survive else "Restart run"
	_style_text_line(restart_button)


func set_survive_button_text(text: String) -> void:
	if not _outcome_survive:
		return
	restart_button.text = text
	_style_text_line(restart_button)


func open_examine(revealed_clues: PackedStringArray) -> void:
	if _examine_tween != null and is_instance_valid(_examine_tween):
		_examine_tween.kill()
	_examine_closing = false

	var lines: PackedStringArray = PackedStringArray()
	for clue in revealed_clues:
		lines.append("• %s" % clue)
	examine_clues_label.text = "\n".join(lines)

	examine_overlay.visible = true
	examine_overlay.modulate.a = 0.0
	examine_portrait.pivot_offset = examine_portrait.size * 0.5
	examine_portrait.scale = Vector2(0.92, 0.92)
	bubble_panel.visible = false
	side_column.visible = false

	_examine_tween = create_tween()
	_examine_tween.set_parallel(true)
	_examine_tween.tween_property(examine_overlay, "modulate:a", 1.0, EXAMINE_TWEEN_SEC)
	_examine_tween.tween_property(examine_portrait, "scale", Vector2.ONE, EXAMINE_TWEEN_SEC) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func close_examine(immediate: bool = false) -> void:
	if not examine_overlay.visible and examine_overlay.modulate.a <= 0.0:
		examine_clues_label.text = ""
		bubble_panel.visible = true
		side_column.visible = true
		return

	if _examine_tween != null and is_instance_valid(_examine_tween):
		_examine_tween.kill()

	if immediate:
		_finish_close_examine()
		return

	_examine_closing = true
	_examine_tween = create_tween()
	_examine_tween.set_parallel(true)
	_examine_tween.tween_property(examine_overlay, "modulate:a", 0.0, EXAMINE_TWEEN_SEC)
	_examine_tween.tween_property(examine_portrait, "scale", Vector2(0.92, 0.92), EXAMINE_TWEEN_SEC) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_examine_tween.chain().tween_callback(_finish_close_examine)


func _finish_close_examine() -> void:
	_examine_closing = false
	examine_overlay.visible = false
	examine_overlay.modulate.a = 0.0
	examine_portrait.scale = Vector2.ONE
	examine_clues_label.text = ""
	bubble_panel.visible = true
	side_column.visible = true


func is_examine_open() -> bool:
	return examine_overlay.visible


func _on_outcome_button_pressed() -> void:
	if _outcome_survive:
		next_night_pressed.emit()
	else:
		restart_run_pressed.emit()


func _on_choice(choice_id: String) -> void:
	close_examine(true)
	_emit_choice.call_deferred(choice_id)


func _emit_choice(choice_id: String) -> void:
	choice_selected.emit(choice_id)


func _clear_choices() -> void:
	_examine_button = null
	while choices_row.get_child_count() > 0:
		var child := choices_row.get_child(0)
		choices_row.remove_child(child)
		child.queue_free()


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
	_stop_dots_pulse()
	_awaiting_advance = false
	_full_segment = _segments[_segment_index]
	bubble_label.modulate.a = 1.0
	bubble_label.text = _full_segment
	bubble_label.visible_characters = 0
	_typing = true

	var char_count := maxi(_full_segment.length(), 1)
	var duration := float(char_count) / TYPEWRITER_CPS
	_type_tween = create_tween()
	_type_tween.tween_property(bubble_label, "visible_characters", char_count, duration)
	_type_tween.finished.connect(_on_typewriter_finished, CONNECT_ONE_SHOT)


func _on_typewriter_finished() -> void:
	_typing = false
	bubble_label.visible_characters = -1
	var is_last := _segment_index >= _segments.size() - 1
	if _phase == Phase.INTRO or not is_last:
		_awaiting_advance = true
		bubble_label.text = _full_segment + CONTINUE_DOTS
		_start_dots_pulse()
		return
	_on_segments_finished()


func _start_dots_pulse() -> void:
	_stop_dots_pulse()
	_dots_tween = create_tween()
	_dots_tween.set_loops()
	_dots_tween.tween_property(bubble_label, "modulate:a", 0.55, 0.45)
	_dots_tween.tween_property(bubble_label, "modulate:a", 1.0, 0.45)


func _stop_dots_pulse() -> void:
	if _dots_tween != null and is_instance_valid(_dots_tween):
		_dots_tween.kill()
	_dots_tween = null
	if bubble_label != null:
		bubble_label.modulate.a = 1.0


func _stop_typewriter() -> void:
	if _type_tween != null and is_instance_valid(_type_tween):
		_type_tween.kill()
	_type_tween = null
	_typing = false


func _skip_or_advance_from_click() -> void:
	if _typing:
		_stop_typewriter()
		bubble_label.visible_characters = -1
		_on_typewriter_finished()
		return
	if _awaiting_advance:
		_advance_segment()


func _on_bubble_gui_input(event: InputEvent) -> void:
	if examine_overlay.visible:
		return
	if not _typing and not _awaiting_advance:
		return
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			_skip_or_advance_from_click()
			get_viewport().set_input_as_handled()


func _advance_segment() -> void:
	if not _awaiting_advance:
		return
	_awaiting_advance = false
	_stop_dots_pulse()
	_segment_index += 1
	if _segment_index >= _segments.size():
		_on_segments_finished()
		return
	_show_current_segment()


func _on_segments_finished() -> void:
	_awaiting_advance = false
	_stop_typewriter()
	_stop_dots_pulse()
	if not _full_segment.is_empty():
		bubble_label.text = _full_segment
		bubble_label.visible_characters = -1
	continue_button.visible = false
	restart_button.visible = false
	match _phase:
		Phase.INTRO:
			continue_pressed.emit()
		Phase.CHOICES, Phase.OUTCOME:
			segments_ready.emit()


func _style_text_line(button: Button, disabled: bool = false) -> void:
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)
	button.add_theme_stylebox_override("disabled", empty)
	if disabled:
		button.add_theme_color_override("font_color", Color(1, 1, 1, 0.28))
		button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 0.28))
		button.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 0.28))
		button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.28))
	else:
		button.add_theme_color_override("font_color", Color(1, 1, 1, 0.88))
		button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
		button.add_theme_color_override("font_pressed_color", Color(0.85, 0.85, 0.85, 1))
		button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.28))
	button.add_theme_font_size_override("font_size", 16)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_NONE
