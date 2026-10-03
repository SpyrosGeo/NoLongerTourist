class_name EncounterUI
extends CanvasLayer

signal choice_selected(choice_id: String)
signal restart_pressed
signal continue_pressed

@onready var title_label: Label = %TitleLabel
@onready var body_label: Label = %BodyLabel
@onready var clues_label: Label = %CluesLabel
@onready var choices_row: VBoxContainer = %ChoicesRow
@onready var continue_button: Button = %ContinueButton
@onready var restart_button: Button = %RestartButton


func _ready() -> void:
	continue_button.pressed.connect(func() -> void: continue_pressed.emit())
	restart_button.pressed.connect(func() -> void: restart_pressed.emit())
	_style_action_button(continue_button)
	_style_action_button(restart_button)
	show_phase_intro()


func set_title(text: String) -> void:
	title_label.text = text


func set_body(text: String) -> void:
	body_label.text = text


func set_clues(clues: PackedStringArray) -> void:
	if clues.is_empty():
		clues_label.text = ""
		clues_label.visible = false
		return
	clues_label.visible = true
	var lines: PackedStringArray = ["Clues:"]
	for clue in clues:
		lines.append("• %s" % clue)
	clues_label.text = "\n".join(lines)


func show_phase_intro() -> void:
	clues_label.visible = false
	_clear_choices()
	continue_button.visible = true
	continue_button.text = "Continue"
	restart_button.visible = false


func show_phase_choices() -> void:
	continue_button.visible = false
	restart_button.visible = false


func show_phase_outcome() -> void:
	_clear_choices()
	continue_button.visible = false
	restart_button.visible = true
	restart_button.text = "Restart night"


func set_choices(choices: Dictionary) -> void:
	_clear_choices()
	show_phase_choices()
	# Stable order for PoC buttons
	for choice_id in ["give_money", "help", "call_police", "walk_away"]:
		if not choices.has(choice_id):
			continue
		var entry: Dictionary = choices[choice_id]
		var button := Button.new()
		button.text = String(entry.get("text", choice_id))
		button.focus_mode = Control.FOCUS_NONE
		_style_action_button(button)
		button.pressed.connect(_on_choice.bind(choice_id))
		choices_row.add_child(button)


func _on_choice(choice_id: String) -> void:
	choice_selected.emit(choice_id)


func _clear_choices() -> void:
	while choices_row.get_child_count() > 0:
		var child := choices_row.get_child(0)
		choices_row.remove_child(child)
		child.free()


func _style_action_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color.WHITE
	normal.set_content_margin_all(10)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.75, 0.75, 0.75)
	pressed.set_content_margin_all(10)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color.BLACK)
	button.add_theme_color_override("font_hover_color", Color.BLACK)
	button.add_theme_color_override("font_pressed_color", Color.BLACK)
