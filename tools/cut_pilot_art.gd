extends SceneTree
# Cuts Luna's pilot source art (art_src/pilot) into the rig's pictures in pilot_rig/.
# Run: godot --headless --path . --script res://tools/cut_pilot_art.gd
#
# Parts are keyed off black (soft edges, dark insides kept solid) and saved at
# the parts sheet's full pixel size. Every part is saved at the SAME pixel scale as the
# sheet, so the rig (pilot_rig.gd) only needs one scale per part to fit it onto the
# reference. left_arm.webp and jetpack_no_flames.webp were painted bigger, so they
# are shrunk to the sheet's scale here.
# Flames stay on black (drawn as added light); boxes around glows are faded out.

const SRC := "res://art_src/pilot/"
const OUT := "res://pilot_rig/"
const TEX := 1.0                    # saved pixels per sheet pixel

# name: sheet rect (x, y, w, h)
const SHEET_PARTS := {
	"helmet":    Rect2i(40, 52, 360, 350),   # without the neck ball (it would show over the chest)
	"visor":     Rect2i(456, 156, 308, 148),
	"torso":     Rect2i(852, 72, 284, 300),
	"hips":      Rect2i(1212, 96, 332, 284),
	"upper_r":   Rect2i(144, 492, 144, 368),
	"forearm_r": Rect2i(536, 444, 148, 400),
	"upper_l":   Rect2i(936, 432, 132, 368),
	"pad_r":     Rect2i(120, 912, 172, 164),
	"pad_l":     Rect2i(524, 912, 176, 160),
	"thigh_r":   Rect2i(920, 848, 160, 284),
	"thigh_l":   Rect2i(132, 1200, 168, 308),
	"shin":      Rect2i(532, 1228, 160, 304),
	"rifle":     Rect2i(1360, 860, 64, 690),
}

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var sheet := _load("parts_sheet.webp")
	for n in SHEET_PARTS:
		var img := _solid(sheet.get_region(SHEET_PARTS[n]))
		_save(_scaled(_trim(img), TEX), OUT + n + ".png")
	# visor light only (the bright cyan line), on black, for the pulsing glow
	_save(_scaled(_visor_light(sheet.get_region(SHEET_PARTS["visor"])), TEX), OUT + "visor_light.png")
	# left forearm + open hand: the whole painted left arm, below the elbow pad.
	# Its forearm is 400 px long there and 230 px on the sheet's right forearm.
	var arm := _load("left_arm.webp")
	var fore := _solid(arm.get_region(Rect2i(440, 600, 620, 890)))
	_save(_scaled(_trim(fore), TEX * 0.575), OUT + "forearm_l.png")
	# jetpack without flames: its nozzles are 615 px apart there, ~271 on the sheet
	var jet := _load("jetpack_no_flames.webp")
	_save(_scaled(_trim(_solid(jet.get_region(Rect2i(350, 440, 900, 750)))), TEX * 0.44), OUT + "jetpack.png")
	var orb := _load("power_orb.webp")
	_save(_scaled(_trim(_solid(orb.get_region(Rect2i(560, 600, 480, 420)))), 0.25), OUT + "orb.png")
	_cut_flames()
	quit()

func _load(name: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(SRC + name))
	img.convert(Image.FORMAT_RGBA8)
	return img

func _save(img: Image, path: String) -> void:
	img.save_png(ProjectSettings.globalize_path(path))
	print("%-34s %dx%d" % [path, img.get_width(), img.get_height()])

func _scaled(img: Image, s: float) -> Image:
	var out: Image = img.duplicate()
	out.resize(maxi(1, roundi(img.get_width() * s)), maxi(1, roundi(img.get_height() * s)), Image.INTERPOLATE_LANCZOS)
	return out

func _trim(img: Image, pad: int = 3) -> Image:
	var r := img.get_used_rect().grow(pad).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	return img.get_region(r)

# Black -> alpha with soft edges, but dark areas INSIDE the part (helmet face, the
# orb socket, shadowed folds) stay solid: only black reachable from the cell border
# through dark pixels is background. Small gaps (under 2 * close px) count as closed.
func _solid(img: Image, lo: float = 8.0, span: float = 30.0, close: int = 3) -> Image:
	var w := img.get_width(); var h := img.get_height()
	var d := img.get_data()
	var on := PackedByteArray(); on.resize(w * h)
	for i in w * h:
		on[i] = 1 if maxf(maxf(d[i * 4], d[i * 4 + 1]), d[i * 4 + 2]) > lo + span * 0.5 else 0
	# grow the solid mask by `close` px so thin cracks don't let the flood in
	var grown := on.duplicate()
	for _k in close:
		var g2 := grown.duplicate()
		for y in h:
			for x in w:
				var i := y * w + x
				if grown[i] == 1:
					continue
				if (x > 0 and grown[i - 1] == 1) or (x < w - 1 and grown[i + 1] == 1) or (y > 0 and grown[i - w] == 1) or (y < h - 1 and grown[i + w] == 1):
					g2[i] = 1
		grown = g2
	var outside := PackedByteArray(); outside.resize(w * h)
	var stack: Array = []
	for x in w:
		stack.append(x); stack.append((h - 1) * w + x)
	for y in h:
		stack.append(y * w); stack.append(y * w + w - 1)
	while not stack.is_empty():
		var p: int = stack.pop_back()
		if outside[p] == 1 or grown[p] == 1:
			continue
		outside[p] = 1
		var x := p % w
		if x > 0: stack.append(p - 1)
		if x < w - 1: stack.append(p + 1)
		if p >= w: stack.append(p - w)
		if p < w * (h - 1): stack.append(p + w)
	# the grown ring next to the outside is still "outside-ish": let the soft key decide there
	for i in w * h:
		var m: float = maxf(maxf(d[i * 4], d[i * 4 + 1]), d[i * 4 + 2])
		var a: float = clampf((m - lo) / span, 0.0, 1.0)
		var inside := outside[i] == 0
		if inside:
			var x := i % w; var y := i / w
			var near_out := false
			for r in range(1, close + 2):
				if (x - r >= 0 and outside[i - r] == 1) or (x + r < w and outside[i + r] == 1) or (y - r >= 0 and outside[i - r * w] == 1) or (y + r < h and outside[i + r * w] == 1):
					near_out = true
					break
			if not near_out:
				a = 1.0
		if a > 0.0 and a < 1.0 and not inside:
			for c in 3:
				d[i * 4 + c] = int(clampf(d[i * 4 + c] / a, 0.0, 255.0))
		d[i * 4 + 3] = int(a * 255.0)
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, d)

# The visor's glowing line: bright cyan pixels only, faded in by brightness, on black.
func _visor_light(img: Image) -> Image:
	var keyed := _trim(_solid(img))
	var w := keyed.get_width(); var h := keyed.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var c := keyed.get_pixel(x, y)
			var k := smoothstep(0.35, 0.8, c.g * c.a) * smoothstep(0.3, 0.7, c.b * c.a)
			out.set_pixel(x, y, Color(c.r * k, c.g * k, c.b * k, 1.0))
	return out

# ------------------------------------------------------------------ flames

# Sheet rects (uneven grid). Columns: plume, nozzle glow, particle. "mask" = fade the
# faint coloured box behind a glow with a soft oval, so no square edge shows.
const FLAMES := [
	["ion_plume",      Rect2i(410, 0, 356, 300),   256, false],
	["ion_glow",       Rect2i(788, 4, 344, 280),   128, true],
	["ion_spark",      Rect2i(1200, 30, 280, 220), 96, false],
	["plasma_plume",   Rect2i(490, 300, 200, 362), 256, false],
	["plasma_glow",    Rect2i(788, 288, 344, 194), 128, true],
	["plasma_spark",   Rect2i(1200, 290, 250, 196), 96, false],
	["pressure_glow",  Rect2i(788, 488, 344, 166), 128, true],
	["pressure_spark", Rect2i(1164, 486, 340, 180), 128, true],
	["gravity_plume",  Rect2i(430, 664, 320, 220), 200, false],
	["gravity_glow",   Rect2i(810, 664, 300, 216), 128, true],
	["gravity_spark",  Rect2i(1205, 664, 260, 232), 96, false],
	["pixel_plume",    Rect2i(456, 880, 264, 348), 160, false],
	["pixel_glow",     Rect2i(832, 888, 256, 204), 96, false],
	["pixel_spark",    Rect2i(1272, 948, 116, 112), 32, false],
	["smoke",          Rect2i(826, 1096, 290, 184), 128, false],
]

func _cut_flames() -> void:
	var img := _load("flames_sheet.webp")
	for f in FLAMES:
		var cell := img.get_region(f[1])
		if f[3]:
			cell = _oval_fade(cell)
		var out := _black_trim(cell)
		var hh: int = f[2]
		_save(_scaled(out, float(hh) / out.get_height()), OUT + "flame_" + f[0] + ".png" if f[0] != "smoke" else OUT + "smoke.png")

# Subtract the box's own colour (its darkest corner) and multiply by a soft oval.
func _oval_fade(img: Image) -> Image:
	var w := img.get_width(); var h := img.get_height()
	var bg := Color(1, 1, 1)
	for p in [Vector2i(2, 2), Vector2i(w - 3, 2), Vector2i(2, h - 3), Vector2i(w - 3, h - 3)]:
		var c := img.get_pixelv(p)
		bg = Color(minf(bg.r, c.r), minf(bg.g, c.g), minf(bg.b, c.b))
	for y in h:
		for x in w:
			var dx := (x - w * 0.5) / (w * 0.5); var dy := (y - h * 0.5) / (h * 0.5)
			var m := smoothstep(1.0, 0.72, sqrt(dx * dx + dy * dy))
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(maxf(c.r - bg.r, 0.0) * m, maxf(c.g - bg.g, 0.0) * m, maxf(c.b - bg.b, 0.0) * m, 1.0))
	return img

# Keep RGB on opaque black, cropped to what is lit.
func _black_trim(img: Image) -> Image:
	var w := img.get_width(); var h := img.get_height()
	var t: Image = img.duplicate()
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if maxf(maxf(c.r, c.g), c.b) < 0.03:
				c = Color(0, 0, 0, 0)
			else:
				c.a = 1.0
			img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0) if c.a > 0.0 else Color(0, 0, 0, 1))
			t.set_pixel(x, y, c)
	var r := t.get_used_rect()
	return img.get_region(r) if r.size.x > 0 else img
