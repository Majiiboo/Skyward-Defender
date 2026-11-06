extends "res://tools/cut_ui_art.gd"
# Cuts Luna's hero stand (art_src/stand/, LUNA-BRIEF-hero-stand.md) into gear/:
#   stand_disc.png  the disc keyed off black, trimmed (its white light lines stay white)
#   stand_glow.png  the lights only, brightness -> alpha, on the SAME crop as the disc
#   stand_beam.png  the light column, brightness -> alpha, trimmed
# Run: godot --headless --path . --script res://tools/cut_stand.gd   (then --import)
func _initialize() -> void:
	if _cut_v2():
		quit()
		return
	var disc := Image.load_from_file(ProjectSettings.globalize_path("res://art_src/stand/stand_disc.webp"))
	disc.convert(Image.FORMAT_RGBA8)
	var keyed := _solid(disc, 10.0, 26.0, 2)
	var crop := keyed.get_used_rect().grow(4).intersection(Rect2i(Vector2i.ZERO, keyed.get_size()))
	var d2 := keyed.get_region(crop)
	d2.resize(d2.get_width() / 2, d2.get_height() / 2, Image.INTERPOLATE_LANCZOS)
	_save(d2, "res://gear/stand_disc.png")
	var glow := Image.load_from_file(ProjectSettings.globalize_path("res://art_src/stand/stand_glow.webp"))
	glow.convert(Image.FORMAT_RGBA8)
	var g2 := _light(glow).get_region(crop)
	g2.resize(g2.get_width() / 2, g2.get_height() / 2, Image.INTERPOLATE_LANCZOS)
	_save(g2, "res://gear/stand_glow.png")
	var beam := Image.load_from_file(ProjectSettings.globalize_path("res://art_src/stand/stand_beam.webp"))
	beam.convert(Image.FORMAT_RGBA8)
	var b2 := _light(beam)
	var bc := b2.get_used_rect().grow(4).intersection(Rect2i(Vector2i.ZERO, b2.get_size()))
	b2 = b2.get_region(bc)
	b2.resize(b2.get_width() / 2, b2.get_height() / 2, Image.INTERPOLATE_LANCZOS)
	_save(b2, "res://gear/stand_beam.png")
	quit()

# ROUND 2 (LUNA-BRIEF-hero-stand-2.md, dev188): orbit rings, no plate. Four light layers from
# art_src/stand/stand_<name>-v2.webp -> gear/stand_<name>.png at half size, brightness -> alpha:
#   pool    the nebula haze (colour kept) under a soft ellipse mask, so its rectangle never shows
#   ring_a  the outer ring, ring_b the inner one: a grey floor is cut away (she painted a faint
#           box under the brighter front half), the ellipses' bounds are printed for the beads
#   beam    the column, with a ramp so it is strongest at the base and gone by the top (she lit
#           it from a point at the top, like a spotlight)
# Keeps the full 1024 x 512 framing for the three flat layers so they stack exactly.
func _cut_v2() -> bool:
	var base := ProjectSettings.globalize_path("res://art_src/stand/stand_%s-v2.webp")
	if not FileAccess.file_exists(base % "pool"):
		return false
	for spec in [["pool", 0.04, true], ["ring_a", 0.2, false], ["ring_b", 0.2, false], ["beam", 0.06, false]]:
		var img := Image.load_from_file(base % spec[0])
		img.convert(Image.FORMAT_RGBA8)
		var w := img.get_width()
		var h := img.get_height()
		var fl: float = spec[1]
		var used := Rect2i()
		var any := false
		for y in h:
			for x in w:
				var c := img.get_pixel(x, y)
				var v := maxf(c.r, maxf(c.g, c.b))
				var a := clampf((v - fl) / (1.0 - fl), 0.0, 1.0)
				if spec[2]:
					# the pool: haze is dark by nature, lift it, then the ellipse mask
					a = clampf(a * 2.2, 0.0, 1.0)
					var nx := (x - w * 0.5) / (w * 0.5)
					var ny := (y - h * 0.5) / (h * 0.5)
					a *= 1.0 - smoothstep(0.5, 1.0, sqrt(nx * nx + ny * ny))
					c = Color(c.r, c.g, c.b, a)
				elif spec[0] == "beam":
					a *= clampf((float(y) / h - 0.12) / 0.5, 0.0, 1.0)
					c = Color(1.0, 1.0, 1.0, a) if v <= 0.0 else Color(c.r / v, c.g / v, c.b / v, a)
				else:
					c = Color(1.0, 1.0, 1.0, a)
				img.set_pixel(x, y, c)
				if a > 0.08:
					used = Rect2i(x, y, 1, 1) if not any else used.expand(Vector2i(x, y)).expand(Vector2i(x + 1, y + 1))
					any = true
		print("%s: lit x %d-%d  y %d-%d  (centre %.3f, %.3f  rx %.3f ry %.3f of the picture)" % [spec[0], used.position.x, used.end.x, used.position.y, used.end.y,
			used.get_center().x / float(w), used.get_center().y / float(h), used.size.x * 0.5 / w, used.size.y * 0.5 / h])
		if spec[0] == "beam":
			img = img.get_region(used.grow(4).intersection(Rect2i(0, 0, w, h)))
		img.resize(img.get_width() / 2, img.get_height() / 2, Image.INTERPOLATE_LANCZOS)
		_save(img, "res://gear/stand_%s.png" % spec[0])
	return true
