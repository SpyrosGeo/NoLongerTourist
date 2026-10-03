class_name PassportArt
extends RefCounted
# Prefer custom title art; fall back to procedural passport.


static func texture() -> Texture2D:
	for path in [
		"res://art/ui/main_theme.png",
		"res://art/ui/main_theme.jpeg",
		"res://art/ui/passport.png",
		"res://art/ui/passport.jpeg",
	]:
		var tex := _try_load(path)
		if tex != null:
			return tex
	return _procedural()


static func has_custom_art() -> bool:
	for path in [
		"res://art/ui/main_theme.png",
		"res://art/ui/main_theme.jpeg",
		"res://art/ui/passport.png",
		"res://art/ui/passport.jpeg",
	]:
		if ResourceLoader.exists(path) or FileAccess.file_exists(path):
			return true
	return false


static func _try_load(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex != null:
			return tex
	if FileAccess.file_exists(path):
		var loaded := Image.new()
		if loaded.load(path) == OK:
			return ImageTexture.create_from_image(loaded)
	return null


static func _procedural() -> Texture2D:
	var w := 320
	var h := 200
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var n := 0.92 + (0.04 if ((x * 13 + y * 7) % 11) == 0 else 0.0)
			img.set_pixel(x, y, Color(n, n * 0.98, n * 0.94))

	_rect_outline(img, 6, 6, w - 12, h - 12, Color(0.08, 0.08, 0.08), 2)
	_fill_rect(img, 10, 10, w - 20, 18, Color(0.12, 0.12, 0.14))
	for i in 11:
		_fill_rect(img, 18 + i * 26, 14, 18, 8, Color(0.85, 0.85, 0.85))

	_rect_outline(img, 16, 36, 72, 90, Color(0.05, 0.05, 0.05), 2)
	_fill_rect(img, 18, 38, 68, 86, Color(0.78, 0.78, 0.76))
	_fill_rect(img, 38, 52, 28, 28, Color(0.15, 0.15, 0.15))
	_fill_rect(img, 32, 78, 40, 36, Color(0.18, 0.18, 0.18))
	img.set_pixel(46, 64, Color.WHITE)
	img.set_pixel(56, 64, Color(0.05, 0.05, 0.05))

	var fx := 100
	for i in 5:
		var fy := 40 + i * 18
		_hline(img, fx, w - 18, fy + 12, Color(0.2, 0.2, 0.2))
		_fill_rect(img, fx, fy, 40, 4, Color(0.35, 0.35, 0.35))

	_stamp(img, 230, 120, 34, Color(0.45, 0.08, 0.08))

	for y in range(0, h, 3):
		for x in w:
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, c.darkened(0.04))
	for i in 80:
		var x := (i * 47) % w
		var y := (i * 91) % h
		var c := img.get_pixel(x, y)
		img.set_pixel(x, y, c.darkened(0.12))

	return ImageTexture.create_from_image(img)


static func _fill_rect(img: Image, x: int, y: int, rw: int, rh: int, color: Color) -> void:
	for py in range(maxi(y, 0), mini(y + rh, img.get_height())):
		for px in range(maxi(x, 0), mini(x + rw, img.get_width())):
			img.set_pixel(px, py, color)


static func _hline(img: Image, x0: int, x1: int, y: int, color: Color) -> void:
	if y < 0 or y >= img.get_height():
		return
	for x in range(maxi(x0, 0), mini(x1, img.get_width())):
		img.set_pixel(x, y, color)


static func _rect_outline(img: Image, x: int, y: int, rw: int, rh: int, color: Color, thickness: int) -> void:
	for t in thickness:
		_hline(img, x, x + rw, y + t, color)
		_hline(img, x, x + rw, y + rh - 1 - t, color)
		for py in range(y, y + rh):
			var lx := x + t
			var rx := x + rw - 1 - t
			if lx >= 0 and lx < img.get_width() and py >= 0 and py < img.get_height():
				img.set_pixel(lx, py, color)
			if rx >= 0 and rx < img.get_width() and py >= 0 and py < img.get_height():
				img.set_pixel(rx, py, color)


static func _stamp(img: Image, cx: int, cy: int, radius: int, color: Color) -> void:
	for y in range(cy - radius, cy + radius + 1):
		for x in range(cx - radius, cx + radius + 1):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var dx := float(x - cx) * 1.15
			var dy := float(y - cy + 2) * 0.9
			var d2 := dx * dx + dy * dy
			var r2 := float(radius * radius)
			if d2 <= r2 and d2 >= r2 * 0.72:
				if ((x + y) % 2) == 0:
					img.set_pixel(x, y, color)
	_fill_rect(img, cx - 10, cy - 2, 22, 3, color)
