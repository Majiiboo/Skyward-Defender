extends SceneTree
# Luna's Specialty weapon pictures (LUNA-BRIEF-specialty-weapons.md): art_src/special/spec_<name>.webp,
# 1024 square on black -> fx/special/spec_<name>.png.
# LIGHT pictures: the brightness becomes the alpha and the colour is kept, for the additive layer.
# The coil is an OBJECT: the black round it is flood-filled away from the border, its dark insides stay.
# The beam is a strip: only its middle 300 px are kept, so it can be repeated upward.
#   godot --headless --path . --script res://tools/cut_special.gd     (then --import)

const LIGHT := {"globe": 256, "globe_burst": 384, "mark": 256, "beam_hit": 384, "rift": 384, "glaive": 256}
const FLOOR := 0.03
const BEAM_X := 362   # the beam: x 362..662 of 1024
const BEAM_W := 300
const KEY := 0.09     # the coil: darker than this and joined to the border = background

func _light(im: Image) -> void:
	for y in im.get_height():
		for x in im.get_width():
			var c := im.get_pixel(x, y)
			var m := maxf(c.r, maxf(c.g, c.b))
			var a := clampf((m - FLOOR) / (1.0 - FLOOR), 0.0, 1.0)
			if m > 0.001:
				im.set_pixel(x, y, Color(c.r / m, c.g / m, c.b / m, a))
			else:
				im.set_pixel(x, y, Color(1, 1, 1, 0))

func _load(name: String) -> Image:
	var src := ProjectSettings.globalize_path("res://art_src/special/spec_%s.webp" % name)
	if not FileAccess.file_exists(src):
		print("spec_%s: not delivered yet" % name)
		return null
	var im := Image.load_from_file(src)
	im.convert(Image.FORMAT_RGBA8)
	return im

func _save(im: Image, name: String) -> void:
	im.save_png(ProjectSettings.globalize_path("res://fx/special/spec_%s.png" % name))
	print("fx/special/spec_%s.png  %dx%d" % [name, im.get_width(), im.get_height()])

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://fx/special"))
	for name in LIGHT:
		var im := _load(name)
		if im == null:
			continue
		im.resize(int(LIGHT[name]), int(LIGHT[name]), Image.INTERPOLATE_LANCZOS)
		_light(im)
		_save(im, name)
	var beam := _load("beam")
	if beam != null:
		var strip := beam.get_region(Rect2i(BEAM_X, 0, BEAM_W, 1024))
		strip.resize(150, 512, Image.INTERPOLATE_LANCZOS)
		_light(strip)
		for y in strip.get_height():   # the sides fade out, so the strip never shows a cut edge
			for x in strip.get_width():
				var edge := clampf(minf(float(x), float(strip.get_width() - 1 - x)) / 18.0, 0.0, 1.0)
				var c := strip.get_pixel(x, y)
				c.a *= edge
				strip.set_pixel(x, y, c)
		_save(strip, "beam")
	var coil := _load("coil")
	if coil != null:
		var w := coil.get_width()
		var h := coil.get_height()
		var bg := PackedByteArray()
		bg.resize(w * h)
		var stack: Array[int] = []
		for x in w:
			stack.append(x)
			stack.append((h - 1) * w + x)
		for y in h:
			stack.append(y * w)
			stack.append(y * w + w - 1)
		while not stack.is_empty():
			var i: int = stack.pop_back()
			if bg[i] == 1:
				continue
			var px := i % w
			var py := i / w
			var c := coil.get_pixel(px, py)
			if maxf(c.r, maxf(c.g, c.b)) > KEY:
				continue
			bg[i] = 1
			if px > 0: stack.append(i - 1)
			if px < w - 1: stack.append(i + 1)
			if py > 0: stack.append(i - w)
			if py < h - 1: stack.append(i + w)
		for y in h:
			for x in w:
				if bg[y * w + x] == 1:
					coil.set_pixel(x, y, Color(0, 0, 0, 0))
		coil.resize(256, 256, Image.INTERPOLATE_LANCZOS)
		_save(coil, "coil")
	quit()
