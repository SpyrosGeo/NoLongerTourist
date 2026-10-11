extends Control

const ENCOUNTER_SCENE := "res://scenes/main.tscn"

@onready var passport_rect: TextureRect = %PassportRect
@onready var passport_fields: Control = %Fields
@onready var game_title: Label = %GameTitle
@onready var name_label: Label = %NameValue
@onready var nationality_label: Label = %NationalityValue
@onready var dob_label: Label = %DobValue
@onready var passport_no_label: Label = %PassportNoValue
@onready var purpose_label: Label = %PurposeValue
@onready var stamp_label: Label = %StampValue
@onready var note_label: Label = %NoteValue
@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Music.play_main_theme()
	passport_rect.texture = PassportArt.texture()
	if PassportArt.has_custom_art():
		passport_fields.visible = false
		note_label.visible = false
		game_title.visible = false
	else:
		_apply_bio(_load_bio())
		game_title.visible = true
	_style_button(start_button, true)
	_style_button(quit_button, false)
	start_button.pressed.connect(_on_start)
	quit_button.pressed.connect(_on_quit)


func _load_bio() -> Dictionary:
	var file := FileAccess.open("res://data/protagonist.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _apply_bio(bio: Dictionary) -> void:
	game_title.text = "UNITY SQUARE"
	name_label.text = String(bio.get("name", "—"))
	nationality_label.text = String(bio.get("nationality", "—"))
	dob_label.text = String(bio.get("dob", "—"))
	passport_no_label.text = String(bio.get("passport_no", "—"))
	purpose_label.text = String(bio.get("purpose", "—"))
	stamp_label.text = String(bio.get("entry_stamp", "—"))
	note_label.text = String(bio.get("eerie_note", ""))


func _style_button(button: Button, primary: bool) -> void:
	var normal := StyleBoxFlat.new()
	var hover := StyleBoxFlat.new()
	if primary:
		normal.bg_color = Color.WHITE
		hover.bg_color = Color(0.85, 0.85, 0.85)
		button.add_theme_color_override("font_color", Color.BLACK)
		button.add_theme_color_override("font_hover_color", Color.BLACK)
		button.add_theme_color_override("font_pressed_color", Color.BLACK)
	else:
		normal.bg_color = Color(0.05, 0.05, 0.05, 0.85)
		normal.border_width_left = 1
		normal.border_width_top = 1
		normal.border_width_right = 1
		normal.border_width_bottom = 1
		normal.border_color = Color.WHITE
		hover = normal.duplicate()
		hover.bg_color = Color(0.12, 0.12, 0.12, 0.9)
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_pressed_color", Color.WHITE)
	normal.set_content_margin_all(12)
	hover.set_content_margin_all(12)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.focus_mode = Control.FOCUS_NONE


func _on_start() -> void:
	get_tree().change_scene_to_file(ENCOUNTER_SCENE)


func _on_quit() -> void:
	get_tree().quit()
