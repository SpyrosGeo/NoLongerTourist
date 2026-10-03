extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: PackedStringArray = []

	var bio_file := FileAccess.open("res://data/protagonist.json", FileAccess.READ)
	if bio_file == null:
		errors.append("missing protagonist.json")
	else:
		var bio: Variant = JSON.parse_string(bio_file.get_as_text())
		if typeof(bio) != TYPE_DICTIONARY or not bio.has("name"):
			errors.append("protagonist.json invalid")

	if not ResourceLoader.exists("res://scenes/title_screen.tscn"):
		errors.append("missing title_screen.tscn")
	if not ResourceLoader.exists("res://scenes/main.tscn"):
		errors.append("missing main.tscn")

	var tex := PassportArt.texture()
	if tex == null:
		errors.append("passport texture failed")

	var enc := FileAccess.open("res://data/encounters/bus_fare.json", FileAccess.READ)
	if enc == null:
		errors.append("missing bus_fare.json")

	if errors.is_empty():
		print("SMOKE_TEST_OK")
		quit(0)
	else:
		for e in errors:
			printerr(e)
		print("SMOKE_TEST_FAIL")
		quit(1)
