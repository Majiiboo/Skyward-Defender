extends "res://tools/cut_ui_art.gd"
# Cuts Luna's drones round 2 (art_src/drones2/<body>/, LUNA-BRIEF-drones-2.md) into drone/:
#   body_<body>.png        the whole drone (menus, the fallback), 256 px
#   <body>_hull.png        the hull alone;  <body>_thruster_l / _r.png the wings / fins
#   <body>_glow.png        the light layer (eyes, core, coil) on black, kept as light
#   <body>_portrait.png    the front view, 256 px
#   pod_repair.png, pod_magnet.png   the two support pods, like pod_beam.png
# Parts are saved at the SAME scale as the whole picture (whole = 1024 -> 256, a quarter), so
# battle places them by the whole's proportions. Wisp's middle fin rides with the hull.
# Run: godot --headless --path . --script res://tools/cut_drones2.gd   (then --import)

const BODIES := {
	"spark": {"l": "wing_l", "r": "wing_r"},
	"wisp":  {"l": "fin_l", "r": "fin_r", "extra": "fin_mid"},
	"bat":   {"l": "wing_l", "r": "wing_r"},
}
const SCALE := 0.25

func _initialize() -> void:
	for b in BODIES:
		var src := "res://art_src/drones2/%s/" % b
		var whole := _keyed(src + "whole.webp")
		if whole == null:
			printerr("missing " + src)
			continue
		_save(_fit(_trim(whole), 256), "res://drone/body_%s.png" % b)
		var por := _keyed(src + "portrait.webp")
		if por != null:
			_save(_fit(_trim(por), 256), "res://drone/%s_portrait.png" % b)
		# parts at the whole's scale: the raw renders are 1024 like the whole
		_save(_scaled(_trim(_keyed(src + "hull.webp")), SCALE), "res://drone/%s_hull.png" % b)
		_save(_scaled(_trim(_keyed(src + BODIES[b].l + ".webp")), SCALE), "res://drone/%s_thruster_l.png" % b)
		_save(_scaled(_trim(_keyed(src + BODIES[b].r + ".webp")), SCALE), "res://drone/%s_thruster_r.png" % b)
		if BODIES[b].has("extra"):
			_save(_scaled(_trim(_keyed(src + BODIES[b].extra + ".webp")), SCALE), "res://drone/%s_extra.png" % b)
		var glow := Image.load_from_file(ProjectSettings.globalize_path(src + "glow.webp"))
		glow.convert(Image.FORMAT_RGBA8)
		_save(_scaled(_light(glow), SCALE), "res://drone/%s_glow.png" % b)
	for p in ["repair", "magnet"]:
		var img := _keyed("res://art_src/drones2/pods/pod_%s.webp" % p)
		if img != null:
			_save(_fit(_trim(img), 128), "res://drone/pod_%s.png" % p)
	quit()

func _keyed(path: String) -> Image:
	var gp := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(gp):
		return null
	var img := Image.load_from_file(gp)
	img.convert(Image.FORMAT_RGBA8)
	return _solid(img, 10.0, 26.0, 2)

func _trim(img: Image, pad: int = 2) -> Image:
	var r := img.get_used_rect().grow(pad).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	return img.get_region(r)

func _scaled(img: Image, s: float) -> Image:
	var out := img.duplicate()
	out.resize(maxi(1, roundi(img.get_width() * s)), maxi(1, roundi(img.get_height() * s)), Image.INTERPOLATE_LANCZOS)
	return out

func _fit(img: Image, px: int) -> Image:
	var s := float(px) / maxf(img.get_width(), img.get_height())
	return _scaled(img, s)

# the light layer: brightness becomes alpha, colour kept, on black (drawn as added light)
func _light(img: Image) -> Image:
	var w := img.get_width(); var h := img.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var m := maxf(maxf(c.r, c.g), c.b)
			out.set_pixel(x, y, Color(c.r, c.g, c.b, clampf((m - 0.06) / 0.5, 0.0, 1.0)))
	return out
