extends SceneTree
# Cuts Luna's battle source sheets (art_src/battle) into the game's pictures.
# Run: godot --headless --path . --script res://tools/cut_battle_art.gd
#
# Solid art (base, turrets) is keyed off its black or grey background into
# transparent PNGs. Effects (shots, hits) stay on black for additive drawing,
# with the grey cell background subtracted so no box shows.

const SRC := "res://art_src/battle/"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://base"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://fx"))
	_cut_base()
	_cut_sentry()
	_cut_turret_sheet()
	_cut_swarm()
	_cut_shots()
	quit()

func _load(name: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(SRC + name))
	img.convert(Image.FORMAT_RGBA8)
	return img

# Black background -> alpha. Anything brighter than `lo` starts to show, fully
# solid by lo + span; colour is un-mixed from black so glows stay soft.
func _key_black(img: Image, lo: float = 6.0, span: float = 26.0) -> Image:
	var d := img.get_data()
	for i in d.size() / 4:
		var m: float = maxf(maxf(d[i * 4], d[i * 4 + 1]), d[i * 4 + 2])
		var a: float = clampf((m - lo) / span, 0.0, 1.0)
		if a > 0.0:
			for c in 3:
				d[i * 4 + c] = int(clampf(d[i * 4 + c] / maxf(a, 0.001), 0.0, 255.0)) if a < 1.0 else d[i * 4 + c]
		d[i * 4 + 3] = int(a * 255.0)
	return Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, d)

# Grey cell background -> alpha: grow from the cell border through pixels that
# stay close to the background, then soften the edge by one pixel.
func _key_grey_cell(img: Image, tol: float = 14.0) -> Image:
	var w := img.get_width(); var h := img.get_height()
	var d := img.get_data()
	var bg := PackedByteArray(); bg.resize(w * h)
	var stack: Array = []
	for x in w:
		stack.append(x); stack.append((h - 1) * w + x)
	for y in h:
		stack.append(y * w); stack.append(y * w + w - 1)
	while not stack.is_empty():
		var p: int = stack.pop_back()
		if bg[p] == 1:
			continue
		var lum: float = (d[p * 4] + d[p * 4 + 1] + d[p * 4 + 2]) / 3.0
		var sat: float = maxf(maxf(d[p * 4], d[p * 4 + 1]), d[p * 4 + 2]) - minf(minf(d[p * 4], d[p * 4 + 1]), d[p * 4 + 2])
		if lum > 62.0 or sat > tol:
			continue
		bg[p] = 1
		var x := p % w; var y := p / w
		if x > 0: stack.append(p - 1)
		if x < w - 1: stack.append(p + 1)
		if y > 0: stack.append(p - w)
		if y < h - 1: stack.append(p + w)
	for i in w * h:
		var a := 0 if bg[i] == 1 else 255
		if a == 255:
			var x := i % w; var y := i / w
			var edge := 0
			for n in [i - 1, i + 1, i - w, i + w]:
				if n >= 0 and n < w * h and bg[n] == 1:
					edge += 1
			if edge > 0 and (x > 0 and y > 0):
				a = 170
		d[i * 4 + 3] = a
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, d)

func _trim(img: Image, pad: int = 4) -> Image:
	var r := img.get_used_rect()
	r = r.grow(pad).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	return img.get_region(r)

func _fit_h(img: Image, h: int) -> Image:
	var out: Image = img.duplicate()
	out.resize(maxi(1, int(img.get_width() * float(h) / img.get_height())), h, Image.INTERPOLATE_LANCZOS)
	return out

func _save(img: Image, path: String) -> void:
	img.save_png(ProjectSettings.globalize_path(path))
	print("%-32s %dx%d" % [path, img.get_width(), img.get_height()])

# ------------------------------------------------------------------ base

func _cut_base() -> void:
	var sheet := _load("base_strip.webp")
	var half := sheet.get_height() / 2
	# both copies are cut with the same rectangle so the lit sockets line up exactly
	var parts: Array = []
	var box := Rect2i()
	for k in 2:
		var p := _key_black(sheet.get_region(Rect2i(0, k * half, sheet.get_width(), half)))
		parts.append(p)
		box = p.get_used_rect() if k == 0 else box.merge(p.get_used_rect())
	for k in 2:
		var keyed: Image = parts[k].get_region(box)
		keyed.resize(1400, int(box.size.y * 1400.0 / box.size.x), Image.INTERPOLATE_LANCZOS)
		parts[k] = keyed
		if k == 0:
			_save(keyed, "res://base/base_strip.png")
	_find_sockets(parts[1])
	_save(_socket_glow(parts[0], parts[1]), "res://base/base_strip_glow.png")

# Only the extra light of the lit copy, inside a soft oval around each socket ring,
# on black (drawn as added light). The two painted copies differ slightly elsewhere,
# so pasting rectangles of the lit copy would show edges.
func _socket_glow(dark: Image, lit: Image) -> Image:
	var w := dark.get_width(); var h := dark.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var centres := [Vector2(0.144, 0.53), Vector2(0.297, 0.524), Vector2(0.701, 0.523), Vector2(0.857, 0.533)]
	for y in h:
		for x in w:
			var m := 0.0
			for cpos in centres:
				var dx: float = (float(x) / w - cpos.x) / 0.075
				var dy: float = (float(y) / h - cpos.y) / 0.30
				m = maxf(m, smoothstep(1.0, 0.75, sqrt(dx * dx + dy * dy)))
			if m <= 0.0:
				out.set_pixel(x, y, Color(0, 0, 0, 1))
				continue
			var a := dark.get_pixel(x, y)
			var b := lit.get_pixel(x, y)
			var g := Color(maxf(b.r * b.a - a.r * a.a - 0.06, 0.0), maxf(b.g * b.a - a.g * a.a - 0.06, 0.0), maxf(b.b * b.a - a.b * a.a - 0.06, 0.0))
			out.set_pixel(x, y, Color(g.r * m, g.g * m, g.b * m, 1.0))
	return out

# Socket ring centres in the lit strip: the near-white ring highlights, grouped
# into the four sockets by x. Printed as fractions of the strip's width and height.
func _find_sockets(img: Image) -> void:
	var w := img.get_width(); var h := img.get_height()
	var sx := [0.0, 0.0, 0.0, 0.0]; var sy := [0.0, 0.0, 0.0, 0.0]; var n := [0, 0, 0, 0]
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if c.r > 0.72 and c.g > 0.9 and c.b > 0.9 and c.a > 0.9:
				var fx := float(x) / w
				if fx > 0.42 and fx < 0.58:
					continue   # the dome's lights
				var k := 0 if fx < 0.25 else (1 if fx < 0.5 else (2 if fx < 0.75 else 3))
				sx[k] += x; sy[k] += y; n[k] += 1
	var out := []
	for k in 4:
		out.append("(%.3f, %.3f)" % [sx[k] / maxf(n[k], 1) / w, sy[k] / maxf(n[k], 1) / h])
	print("SOCKETS ", ", ".join(out))

# ------------------------------------------------------------------ turrets

func _cut_sentry() -> void:
	var img := _load("sentry_two_pieces.webp")
	var h := img.get_height()
	var head := _trim(_key_black(img.get_region(Rect2i(0, 0, img.get_width(), int(h * 0.6))), 16.0, 26.0))
	var base := _trim(_key_black(img.get_region(Rect2i(0, int(h * 0.6), img.get_width(), h - int(h * 0.6))), 16.0, 26.0))
	head = _fit_h(head, 256)
	base = _fit_h(base, 120)
	_save(head, "res://turrets/sentry_head.png")
	_save(base, "res://turrets/sentry_base.png")
	# the Gear icon: head standing on its base, as in battle (head bottom ~0.42 of
	# the base height above the base's centre)
	var w: int = maxi(head.get_width(), base.get_width())
	var base_cy: int = 236 + 60
	var icon := Image.create(w, base_cy + 60, false, Image.FORMAT_RGBA8)
	icon.blend_rect(base, Rect2i(Vector2i.ZERO, base.get_size()), Vector2i((w - base.get_width()) / 2, base_cy - 60))
	icon.blend_rect(head, Rect2i(Vector2i.ZERO, head.get_size()), Vector2i((w - head.get_width()) / 2, base_cy - 50 - int(head.get_height() * 0.9)))
	_save(_fit_h(_trim(icon, 2), 256), "res://turrets/sentry_idle.png")

# Idle column of the sized sheet: rows lance, storm, gravity, (swarm), prism.
func _cut_turret_sheet() -> void:
	var img := _load("turrets_sheet.webp")
	var cells := {"lance": Rect2i(118, 258, 525, 216), "storm": Rect2i(118, 490, 525, 190),
		"gravity": Rect2i(118, 695, 525, 172), "prism": Rect2i(118, 1040, 525, 228)}
	for id in cells:
		var cell := img.get_region(cells[id])
		var keyed := _trim(_key_grey_cell(cell))
		_save(_fit_h(keyed, 256), "res://turrets/%s_idle.png" % id)

func _cut_swarm() -> void:
	var img := _load("swarm_hive_compact.webp")
	_save(_fit_h(_trim(_key_black(img, 22.0, 26.0)), 256), "res://turrets/swarm_idle.png")

# ------------------------------------------------------------------ shots

func _cut_shots() -> void:
	var img := _load("shots_sheet.webp")
	var cols := [303, 676]
	var rows := [48, 320, 634, 944, 1352, 1628]
	var names := [["sentry_tracer", "spark"], ["", "lance_flare"], ["lance_beam", "storm_zap"],
		["gravity_ring", "crush"], ["drone", "pop"], ["prism_beam", "prism_burst"]]
	for r in rows.size():
		for c in 2:
			var name: String = names[r][c]
			if name == "":
				continue
			var cell := img.get_region(Rect2i(cols[c], rows[r], 305, 245))
			if name == "gravity_ring":
				cell = cell.get_region(Rect2i(110, 0, 195, 245))   # the bigger of the two rings
			_save(_fit_h(_trim(_lift_black(cell), 2), 128), "res://fx/%s.png" % name)

# Grey cell background -> pure black (for additive drawing): subtract the cell's
# corner colour and stretch the rest back up. Stays RGB on black, alpha 1.
func _lift_black(img: Image) -> Image:
	var w := img.get_width(); var h := img.get_height()
	var bg := 0.0
	for p in [Vector2i(3, 3), Vector2i(w - 4, 3), Vector2i(3, h - 4), Vector2i(w - 4, h - 4), Vector2i(w / 2, 3), Vector2i(3, h / 2)]:
		var c := img.get_pixelv(p)
		bg = maxf(bg, maxf(maxf(c.r, c.g), c.b))
	bg += 0.03
	var d := img.get_data()
	var any := false
	for i in w * h:
		for c in 3:
			d[i * 4 + c] = int(clampf((d[i * 4 + c] / 255.0 - bg) / (1.0 - bg), 0.0, 1.0) * 255.0)
		d[i * 4 + 3] = 255
	var out := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, d)
	# trim needs alpha, so mark black as clear for the crop, then restore
	var t: Image = out.duplicate()
	var td: PackedByteArray = t.get_data()
	for i in w * h:
		if td[i * 4] < 4 and td[i * 4 + 1] < 4 and td[i * 4 + 2] < 4:
			td[i * 4 + 3] = 0
	var tr := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, td).get_used_rect()
	if tr.size.x <= 0:
		return out
	return out.get_region(tr)
