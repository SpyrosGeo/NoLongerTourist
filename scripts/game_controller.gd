extends Node

const ENCOUNTER_PATHS: PackedStringArray = [
	"res://data/encounters/bus_fare.json",
	"res://data/encounters/night_flirt.json",
]

@onready var art_rect: TextureRect = %ArtRect
@onready var character_rect: TextureRect = %CharacterRect
@onready var ui: EncounterUI = %EncounterUI

var runner: EncounterRunner
var _night: int = 1
var _last_path: String = ""


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	runner = EncounterRunner.new()
	runner.name = "EncounterRunner"
	add_child(runner)
	runner.setup(ui)
	if not ui.next_night_pressed.is_connected(_on_next_night):
		ui.next_night_pressed.connect(_on_next_night)
	if not ui.restart_run_pressed.is_connected(_on_restart_run):
		ui.restart_run_pressed.connect(_on_restart_run)
	_start_night()


func _on_next_night() -> void:
	_night += 1
	_start_night()


func _on_restart_run() -> void:
	_night = 1
	_last_path = ""
	_start_night()


func _start_night() -> void:
	var path := _pick_encounter_path()
	_last_path = path
	runner.start(path)
	art_rect.texture = SceneArt.texture_for(runner.get_backdrop_id())
	character_rect.texture = SceneArt.character_texture(runner.get_character_id())
	ui.set_examine_texture(character_rect.texture)
	ui.set_title("Night %d — %s" % [_night, runner.get_encounter_title()])


func _pick_encounter_path() -> String:
	if ENCOUNTER_PATHS.is_empty():
		return "res://data/encounters/bus_fare.json"
	if ENCOUNTER_PATHS.size() == 1:
		return ENCOUNTER_PATHS[0]

	var options: Array[String] = []
	for path in ENCOUNTER_PATHS:
		if path != _last_path:
			options.append(path)
	if options.is_empty():
		return ENCOUNTER_PATHS[randi() % ENCOUNTER_PATHS.size()]
	return options[randi() % options.size()]
