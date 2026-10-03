extends Node

@onready var art_rect: TextureRect = %ArtRect
@onready var ui: EncounterUI = %EncounterUI

var runner: EncounterRunner


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	runner = EncounterRunner.new()
	runner.name = "EncounterRunner"
	add_child(runner)
	runner.setup(ui)
	_start_night()


func _start_night() -> void:
	runner.start("res://data/encounters/bus_fare.json")
	art_rect.texture = SceneArt.texture_for(runner.get_backdrop_id())
