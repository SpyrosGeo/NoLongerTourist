class_name EncounterRunner
extends Node

signal finished(ending: String)

const ENERGY_MAX := 100
const EXAMINE_COST := 50

var ui: EncounterUI
var _data: Dictionary = {}
var _variant_id: String = ""
var _variant: Dictionary = {}
var _energy: int = ENERGY_MAX
var _clues_remaining: Array[String] = []
var _clues_revealed: Array[String] = []
var _stages: Array = []
var _stage: Dictionary = {}
var _is_story: bool = false
var _pending_choices: Dictionary = {}
var _pending_examine: bool = false
var _awaiting_choice_ready: bool = false
var _awaiting_outcome_ready: bool = false
var _last_ending: String = "survive"


func setup(p_ui: EncounterUI) -> void:
	ui = p_ui
	if not ui.continue_pressed.is_connected(_on_continue):
		ui.continue_pressed.connect(_on_continue)
	if not ui.choice_selected.is_connected(_on_choice):
		ui.choice_selected.connect(_on_choice)
	if not ui.examine_pressed.is_connected(_on_examine):
		ui.examine_pressed.connect(_on_examine)
	if not ui.segments_ready.is_connected(_on_segments_ready):
		ui.segments_ready.connect(_on_segments_ready)


func start(path: String = "res://data/encounters/bus_fare.json") -> void:
	_data = _load_json(path)
	_energy = ENERGY_MAX
	_clues_remaining.clear()
	_clues_revealed.clear()
	_stages.clear()
	_stage = {}
	_is_story = false
	_pending_choices.clear()
	_awaiting_choice_ready = false
	_awaiting_outcome_ready = false
	_last_ending = "survive"
	ui.set_energy(_energy, ENERGY_MAX)
	ui.close_examine(true)

	if _data.is_empty():
		ui.set_title("Error")
		_begin_outcome("Could not load encounter data.", "survive")
		return

	_variant_id = "threat" if randf() < 0.5 else "human"
	var variants: Dictionary = _data.get("variants", {})
	_variant = variants.get(_variant_id, {})
	_load_clues_from_variant()

	_stages = _data.get("stages", [])
	_is_story = not _stages.is_empty()

	if _is_story:
		_stage = _stages[0] as Dictionary
		ui.play_segments(String(_stage.get("intro", "")), EncounterUI.Phase.INTRO)
	else:
		ui.play_segments(String(_data.get("intro", "")), EncounterUI.Phase.INTRO)


func get_backdrop_id() -> String:
	return String(_data.get("backdrop", "plaza_center_new"))


func get_character_id() -> String:
	return String(_data.get("character", "junkie1"))


func get_encounter_title() -> String:
	return String(_data.get("title", "Night"))


func get_last_ending() -> String:
	return _last_ending


func _load_clues_from_variant() -> void:
	_clues_remaining.clear()
	var clues: Array = _variant.get("clues", [])
	for c in clues:
		_clues_remaining.append(String(c))


func _can_examine() -> bool:
	return _energy >= EXAMINE_COST and not _clues_remaining.is_empty()


func _current_choices() -> Dictionary:
	if _is_story:
		return _stage.get("choices", {}) as Dictionary
	return _variant.get("choices", {}) as Dictionary


func _show_choice_phase() -> void:
	var body := ""
	if _is_story:
		body = String(_stage.get("ask", ""))
	else:
		body = String(_data.get("ask", ""))
	if body.is_empty():
		body = "What do you do?"
	_pending_choices = _current_choices()
	_pending_examine = _can_examine()
	_awaiting_choice_ready = true
	_awaiting_outcome_ready = false
	ui.play_segments(body, EncounterUI.Phase.CHOICES)


func _find_stage(stage_id: String) -> Dictionary:
	for stage_variant in _stages:
		if typeof(stage_variant) != TYPE_DICTIONARY:
			continue
		var stage: Dictionary = stage_variant
		if String(stage.get("id", "")) == stage_id:
			return stage
	return {}


func _on_continue() -> void:
	_show_choice_phase()


func _on_segments_ready() -> void:
	if _awaiting_choice_ready:
		_awaiting_choice_ready = false
		ui.set_choices(_pending_choices, _pending_examine)
		return
	if _awaiting_outcome_ready:
		_awaiting_outcome_ready = false
		ui.show_outcome_continue(_last_ending)
		finished.emit(_last_ending)


func _on_examine() -> void:
	if not _can_examine():
		ui.set_examine_enabled(false)
		return

	_energy -= EXAMINE_COST
	ui.set_energy(_energy, ENERGY_MAX)

	var index := randi() % _clues_remaining.size()
	var clue := _clues_remaining[index]
	_clues_remaining.remove_at(index)
	_clues_revealed.append(clue)

	var revealed := PackedStringArray()
	for c in _clues_revealed:
		revealed.append(c)
	ui.open_examine(revealed)
	ui.set_examine_enabled(_can_examine())


func _on_choice(choice_id: String) -> void:
	var choices := _current_choices()
	if not choices.has(choice_id):
		return
	var entry: Dictionary = choices[choice_id]
	ui.close_examine(true)

	if entry.has("next"):
		var next_id := String(entry.get("next", ""))
		var next_stage := _find_stage(next_id)
		if next_stage.is_empty():
			_begin_outcome("The night loses its thread.", "survive")
			return
		_stage = next_stage
		ui.play_segments(String(_stage.get("intro", "")), EncounterUI.Phase.INTRO)
		return

	var resolved := _resolve_outcome(entry)
	_begin_outcome(String(resolved.get("text", "...")), String(resolved.get("ending", "survive")))


func _begin_outcome(text: String, ending: String) -> void:
	_last_ending = ending if ending == "dead" else "survive"
	_awaiting_choice_ready = false
	_awaiting_outcome_ready = true
	ui.play_segments(text, EncounterUI.Phase.OUTCOME)


func _resolve_outcome(entry: Dictionary) -> Dictionary:
	if entry.has("results"):
		var results: Dictionary = entry.get("results", {})
		var variant_result: Variant = null
		if results.has(_variant_id):
			variant_result = results[_variant_id]
		elif results.has("human"):
			variant_result = results["human"]
		if typeof(variant_result) == TYPE_DICTIONARY:
			var obj: Dictionary = variant_result
			return {
				"text": String(obj.get("text", "...")),
				"ending": String(obj.get("ending", "survive")),
			}
		if variant_result != null:
			return {"text": String(variant_result), "ending": "survive"}

	if entry.has("result"):
		var result_val: Variant = entry.get("result")
		if typeof(result_val) == TYPE_DICTIONARY:
			var obj2: Dictionary = result_val
			return {
				"text": String(obj2.get("text", "...")),
				"ending": String(obj2.get("ending", "survive")),
			}
		return {
			"text": String(result_val),
			"ending": String(entry.get("ending", "survive")),
		}

	return {"text": "...", "ending": "survive"}


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
