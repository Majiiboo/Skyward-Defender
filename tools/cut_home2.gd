extends "res://tools/cut_ui_art.gd"
# Cuts Luna's HOME round 2 (art_src/skies/<planet>/, art_src/home2/; LUNA-BRIEF-home-2.md):
#   skies/<planet>_stars.webp    640 x 1280, opaque, loops top to bottom (the far layer)
#   skies/<planet>_clouds.webp   640 x 1280 with alpha from brightness (light on black)
#   skies/<planet>_planet.webp   800 x 500, black above the planet keyed to alpha
#   skies/<planet>_glow.webp     800 x 500 with alpha from brightness (the atmosphere rim)
#   skies/<planet>_float_0..7.png   the eight floaters (4 x 2 cells of 512), keyed, 160 px
#   base/strip_nodome.png        the strip without its dome, the SAME canvas as base/base_strip.png
#   base/dome_<kind>_<n>.png     standard, beam_1..3, shield_1..3, emp_1..3, all cropped with ONE
#                                rect (dome_standard's used box) so they swap in place
# It prints DOME_RECT: where the dome sits on the strip (fractions), for backdrop.gd.
# Run: godot --headless --path . --script res://tools/cut_home2.gd   (then --import)

const PLANETS := ["hive", "scrap", "magma", "crystal", "plasma", "sentinel"]
const SKY := "res://art_src/skies/"
const H2 := "res://art_src/home2/"

func _initialize() -> void:
	for d in ["skies", "base"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + d))
	if OS.get_environment("DOMES_ONLY") != "1":
		for p in PLANETS:
			_sky(p)
	_domes()
	quit()

func _img(path: String) -> Image:
	if not FileAccess.file_exists(ProjectSettings.globalize_path(path)):
		print("missing: " + path)
		return null
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	img.convert(Image.FORMAT_RGBA8)
	return img

func _resized(img: Image, w: int, h: int) -> Image:
	var out: Image = img.duplicate()
	out.resize(w, h, Image.INTERPOLATE_LANCZOS)
	return out

# light on black -> alpha from the brightest channel (the colour kept), so normal blending
# shows only the light; a tiny floor so faint haze goes fully clear
func _alpha_from_light(img: Image) -> Image:
	var w := img.get_width()
	var h := img.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var a: float = clampf((maxf(maxf(c.r, c.g), c.b) - 0.03) / 0.97, 0.0, 1.0)
			out.set_pixel(x, y, Color(c.r, c.g, c.b, a))
	return out

func _save_webp(img: Image, path: String, quality: float = 0.86) -> void:
	var err := img.save_webp(ProjectSettings.globalize_path(path), true, quality)
	print("%-34s %dx%d %s" % [path, img.get_width(), img.get_height(), "" if err == OK else "ERROR %d" % err])

func _sky(p: String) -> void:
	var dir := SKY + p + "/"
	var stars := _img(dir + "stars.webp")
	if stars != null:
		_save_webp(_resized(stars, 640, 1280), "res://skies/%s_stars.webp" % p)
	var clouds := _img(dir + "clouds.webp")
	if clouds != null:
		_save_webp(_alpha_from_light(_resized(clouds, 640, 1280)), "res://skies/%s_clouds.webp" % p)
	var planet := _img(dir + "planet.webp")
	if planet != null:
		_save_webp(_solid(_resized(planet, 800, 500), 10.0, 26.0, 2), "res://skies/%s_planet.webp" % p)
	var glow := _img(dir + "glow.webp")
	if glow != null:
		_save_webp(_alpha_from_light(_resized(glow, 800, 500)), "res://skies/%s_glow.webp" % p)
	var fl := _img(dir + "floaters.webp")
	if fl != null:
		var cw := fl.get_width() / 4
		var ch := fl.get_height() / 2
		for i in 8:
			var cell := fl.get_region(Rect2i((i % 4) * cw, (i / 4) * ch, cw, ch))
			var keyed := _trim(_solid(cell, 10.0, 26.0, 2), 2)
			if keyed.get_width() < 8 or keyed.get_height() < 8:
				continue
			_save(_fit(keyed, 160), "res://skies/%s_float_%d.png" % [p, i])

func _domes() -> void:
	# the strip without its dome: keyed, its used box resized to the game strip's 1400 width,
	# then set on the SAME canvas height as base/base_strip.png, bottoms aligned
	var strip_png := Image.load_from_file(ProjectSettings.globalize_path("res://base/base_strip.png"))
	strip_png.convert(Image.FORMAT_RGBA8)
	var sw := strip_png.get_width()
	var sh := strip_png.get_height()
	var nd := _img(H2 + "strip_nodome.webp")
	if nd != null:
		var keyed := _solid(nd, 10.0, 26.0, 2)
		var box := keyed.get_used_rect()
		var cut := keyed.get_region(box)
		var scale := float(sw) / cut.get_width()
		var rs := _resized(cut, sw, maxi(1, roundi(cut.get_height() * scale)))
		var canvas := Image.create(sw, sh, false, Image.FORMAT_RGBA8)
		canvas.blit_rect(rs, Rect2i(Vector2i.ZERO, rs.get_size()), Vector2i(0, sh - rs.get_height()))
		_save(canvas, "res://base/strip_nodome.png")
		# where the dome was: the pixels of the old strip that the new one does not cover
		var diff := Rect2i()
		var any := false
		for y in sh:
			for x in sw:
				var a0 := strip_png.get_pixel(x, y).a
				var a1 := canvas.get_pixel(x, y).a
				if a0 > 0.5 and a1 < 0.2:
					diff = Rect2i(x, y, 1, 1) if not any else diff.expand(Vector2i(x, y)).expand(Vector2i(x + 1, y + 1))
					any = true
		if any:
			print("DOME_RECT (fractions of the strip): x %.4f y %.4f w %.4f h %.4f" % [float(diff.position.x) / sw, float(diff.position.y) / sh, float(diff.size.x) / sw, float(diff.size.y) / sh])
	# the dome pieces: one crop rect for all (dome_standard's used box, grown a little)
	var std := _img(H2 + "dome_standard.webp")
	if std == null:
		return
	# one crop for every dome picture: the UNION of their used boxes (the beam and the EMP ring
	# rise above the standard dome), so they all swap in place; the standard dome's own box
	# inside that union is printed for backdrop.gd (STRIP_DOME places the standard dome on the strip)
	var names: Array = ["standard"]
	for k in ["beam", "shield", "emp"]:
		for n in [1, 2, 3]:
			names.append("%s_%d" % [k, n])
	var keyed := {}
	var union := Rect2i()
	var std_box := Rect2i()
	for n in names:
		var img := _img(H2 + "dome_%s.webp" % n)
		if img == null:
			continue
		keyed[n] = _solid(img, 10.0, 26.0, 2)
		var used: Rect2i = keyed[n].get_used_rect()
		union = used if union.size == Vector2i.ZERO else union.merge(used)
		if n == "standard":
			std_box = used
	union = union.grow(6).intersection(Rect2i(Vector2i.ZERO, Vector2i(1024, 1024)))
	print("dome union box %s, the standard dome inside it: x %.4f y %.4f w %.4f h %.4f" % [str(union), float(std_box.position.x - union.position.x) / union.size.x, float(std_box.position.y - union.position.y) / union.size.y, float(std_box.size.x) / union.size.x, float(std_box.size.y) / union.size.y])
	for n in keyed:
		_save(_fit(keyed[n].get_region(union), 480), "res://base/dome_%s.png" % n)
