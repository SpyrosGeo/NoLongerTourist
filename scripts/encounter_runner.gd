class_name EncounterRunner
extends Node

signal finished

var ui: EncounterUI
var _data: Dictionary = {}
var _variant_id: String = ""
var _variant: Dictionary = {}


func setup(p_ui: EncounterUI) -> void:
	ui = p_ui
	if not ui.continue_pressed.is_connected(_on_continue):
		ui.continue_pressed.connect(_on_continue)
	if not ui.choice_selected.is_connected(_on_choice):
		ui.choice_selected.connect(_on_choice)
	if not ui.restart_pressed.is_connected(_on_restart):
		ui.restart_pressed.connect(_on_restart)


func start(path: String = "res://data/encounters/bus_fare.json") -> void:
	_data = _load_json(path)
	if _data.is_empty():
		ui.set_title("Error")
		ui.set_body("Could not load encounter data.")
		ui.set_clues(PackedStringArray())
		ui.show_phase_outcome()
		return

	_variant_id = "threat" if randf() < 0.5 else "human"
	var variants: Dictionary = _data.get("variants", {})
	_variant = variants.get(_variant_id, {})

	ui.set_title(String(_data.get("title", "Night")))
	ui.set_body(String(_data.get("intro", "")))
	ui.set_clues(PackedStringArray())
	ui.show_phase_intro()


func get_backdrop_id() -> String:
	return String(_data.get("backdrop", "plaza_center"))


func _on_continue() -> void:
	# Move from intro into clues + choices
	var body := String(_data.get("ask", ""))
	if body.is_empty():
		body = "What do you do?"
	ui.set_body(body)
	var clues: Array = _variant.get("clues", [])
	var packed := PackedStringArray()
	for c in clues:
		packed.append(String(c))
	ui.set_clues(packed)
	ui.set_choices(_variant.get("choices", {}))


func _on_choice(choice_id: String) -> void:
	var choices: Dictionary = _variant.get("choices", {})
	if not choices.has(choice_id):
		return
	var entry: Dictionary = choices[choice_id]
	ui.set_clues(PackedStringArray())
	ui.set_body(String(entry.get("result", "...")))
	ui.show_phase_outcome()
	finished.emit()


func _on_restart() -> void:
	start()


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid JSON: %s" % path)
		return {}
	return parsed
