class_name SceneArt
extends RefCounted
# Loads pixel-art PNGs from res://art/views/{art_id}.png


static func texture_for(art_id: String, _gate_open: bool = false) -> Texture2D:
	var path := "res://art/views/%s.png" % art_id
	var tex := _try_load(path)
	if tex != null:
		return tex
	return _fallback_night_plaza()


static func character_texture(character_id: String) -> Texture2D:
	return _try_load("res://art/ui/%s.png" % character_id)


static func _try_load(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex != null:
			return tex
	if FileAccess.file_exists(path):
		var img := Image.new()
		if img.load(path) == OK:
			return ImageTexture.create_from_image(img)
	return null


static func _fallback_night_plaza() -> Texture2D:
	var w := 240
	var h := 180
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.05, 0.05, 0.08))
	for y in range(0, 70):
		for x in range(w):
			img.set_pixel(x, y, Color(0.08, 0.08, 0.12))
	for y in range(70, h):
		for x in range(w):
			var v := 0.12 if ((x + y) % 3) == 0 else 0.18
			img.set_pixel(x, y, Color(v, v, v * 1.05))
	# Simple building silhouettes
	for i in 5:
		var bx := 10 + i * 45
		var bh := 40 + (i % 3) * 12
		for y in range(70 - bh, 70):
			for x in range(bx, bx + 36):
				if x < w and y >= 0:
					img.set_pixel(x, y, Color(0.02, 0.02, 0.03))
					if (x + y) % 11 == 0 and y < 70 - 8:
						img.set_pixel(x, y, Color(0.55, 0.5, 0.25))
	return ImageTexture.create_from_image(img)
