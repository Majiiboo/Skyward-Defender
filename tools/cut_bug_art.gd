extends SceneTree
# Cuts Luna's 3D Hive bugs (art_src/dev87) into the parts EnemyRig animates, in
# enemies/parts/: <kind>_body.png (seen from above, head pointing down) and
# <kind>_wing.png (root at the LEFT end, tip pointing RIGHT), plus the Hive Mother's
# sacs (full / empty) and claws.
# Run: godot --headless --path . --script res://tools/cut_bug_art.gd
#
# Sizes match the old parts, so the bugs keep their size on screen: EnemyRig draws a
# body at (size / 220) per texture pixel, the Hive Mother at (size / 300).

const SRC := "res://art_src/dev87/"
const OUT := "res://enemies/parts/"

func _initialize() -> void:
	for kind in ["scout", "drifter", "spitter", "diver"]:
		var img := _trim(_solid(_load("bug_%s.webp" % kind)))
		_save(_fit(img, 220), OUT + kind + "_body.png")
	_cut_hive_mother()
	_cut_wings()
	quit()

func _load(name: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(SRC + name))
	img.convert(Image.FORMAT_RGBA8)
	return img

func _save(img: Image, path: String) -> void:
	img.save_png(ProjectSettings.globalize_path(path))
	print("%-34s %dx%d" % [path, img.get_width(), img.get_height()])

# scale so the longer side is `px`
func _fit(img: Image, px: int) -> Image:
	var s := float(px) / maxi(img.get_width(), img.get_height())
	var out: Image = img.duplicate()
	out.resize(maxi(1, roundi(img.get_width() * s)), maxi(1, roundi(img.get_height() * s)), Image.INTERPOLATE_LANCZOS)
	return out

func _trim(img: Image, pad: int = 4) -> Image:
	var r := img.get_used_rect().grow(pad).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	return img.get_region(r)

# Black -> alpha with soft edges; dark areas INSIDE the bug stay solid (only black
# reachable from the border through dark pixels is background). Same idea as
# tools/cut_pilot_art.gd.
func _solid(img: Image, lo: float = 10.0, span: float = 34.0, close: int = 3) -> Image:
	var w := img.get_width(); var h := img.get_height()
	var d := img.get_data()
	var grown := PackedByteArray(); grown.resize(w * h)
	for i in w * h:
		grown[i] = 1 if maxf(maxf(d[i * 4], d[i * 4 + 1]), d[i * 4 + 2]) > lo + span * 0.5 else 0
	for _k in close:
		var g2 := grown.duplicate()
		for y in h:
			for x in w:
				var i := y * w + x
				if grown[i] == 0 and ((x > 0 and grown[i - 1] == 1) or (x < w - 1 and grown[i + 1] == 1) or (y > 0 and grown[i - w] == 1) or (y < h - 1 and grown[i + w] == 1)):
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
	for i in w * h:
		var m: float = maxf(maxf(d[i * 4], d[i * 4 + 1]), d[i * 4 + 2])
		var a: float = clampf((m - lo) / span, 0.0, 1.0)
		if outside[i] == 0:
			var x := i % w; var y := i / w
			var near_out := false
			for r in range(1, close + 2):
				if (x - r >= 0 and outside[i - r] == 1) or (x + r < w and outside[i + r] == 1) or (y - r >= 0 and outside[i - r * w] == 1) or (y + r < h and outside[i + r * w] == 1):
					near_out = true
					break
			if not near_out:
				a = 1.0
		elif a > 0.0 and a < 1.0:
			for c in 3:
				d[i * 4 + c] = int(clampf(d[i * 4 + c] / a, 0.0, 255.0))
		d[i * 4 + 3] = int(a * 255.0)
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, d)

# ------------------------------------------------------------------ Hive Mother

func _cut_hive_mother() -> void:
	var sheet := _load("hive_mother_pieces.webp")   # 1920 x 1280
	var cells := {"hive_body": Rect2i(40, 30, 620, 900), "hive_sacs_full": Rect2i(660, 110, 620, 480),
		"hive_sacs_empty": Rect2i(1300, 100, 600, 540), "hive_claw_l": Rect2i(580, 660, 380, 600),
		"hive_claw_r": Rect2i(1020, 660, 380, 600)}
	var sizes := {"hive_body": 300, "hive_sacs_full": 220, "hive_sacs_empty": 220, "hive_claw_l": 200, "hive_claw_r": 200}
	for n in cells:
		var img := _trim(_solid(sheet.get_region(cells[n])))
		_save(_fit(img, sizes[n]), OUT + n + ".png")

# ------------------------------------------------------------------ wings

# The five wings lie diagonally on one sheet (root bottom-left, tip top-right), left
# to right: Scout, Drifter, Spitter, Diver, Hive Mother. Each is cut by its own
# connected shape, turned so root -> tip points right, and sized like the old wings.
func _cut_wings() -> void:
	var sheet := _solid(_load("bug_wings.webp"))
	var names := ["scout_wing", "drifter_wing", "spitter_wing", "diver_wing", "hive_wing"]
	var widths := [260, 260, 260, 260, 360]
	var blobs := _blobs(sheet)
	blobs.sort_custom(func(a, b): return a.position.x < b.position.x)
	if blobs.size() < 5:
		push_error("expected 5 wings, found %d" % blobs.size())
		return
	for i in 5:
		var img := _only_largest(sheet.get_region(Rect2i(blobs[i]).grow(6).intersection(Rect2i(Vector2i.ZERO, sheet.get_size()))))
		img = _trim(_level_wing(img), 2)
		_save(_fit(img, widths[i]), OUT + names[i] + ".png")

# Keep only the biggest connected shape in the picture (neighbouring wings on the
# sheet overlap each other's box).
func _only_largest(img: Image) -> Image:
	var w := img.get_width(); var h := img.get_height()
	var label := PackedInt32Array(); label.resize(w * h)
	var best := 0; var best_n := 0; var next := 1
	for i in w * h:
		if label[i] != 0 or img.get_pixel(i % w, i / w).a < 0.08:
			continue
		var st := [i]; label[i] = next; var n := 0
		while not st.is_empty():
			var p: int = st.pop_back(); n += 1
			var px := p % w
			for q in [p - 1, p + 1, p - w, p + w]:
				if q >= 0 and q < w * h and label[q] == 0 and absi(q % w - px) <= 1 and img.get_pixel(q % w, q / w).a >= 0.08:
					label[q] = next; st.append(q)
		if n > best_n:
			best_n = n; best = next
		next += 1
	for i in w * h:
		if label[i] != best:
			img.set_pixel(i % w, i / w, Color(0, 0, 0, 0))
	return img

# connected opaque shapes, as rects (coarse grid of 8 px)
func _blobs(img: Image) -> Array:
	var step := 8
	var w := img.get_width() / step; var h := img.get_height() / step
	var on := PackedByteArray(); on.resize(w * h)
	for y in h:
		for x in w:
			on[y * w + x] = 1 if img.get_pixel(x * step + step / 2, y * step + step / 2).a > 0.3 else 0
	var seen := PackedByteArray(); seen.resize(w * h)
	var out := []
	for i in w * h:
		if on[i] == 0 or seen[i] == 1:
			continue
		var st := [i]; seen[i] = 1
		var r := Rect2i(i % w, i / w, 1, 1); var n := 0
		while not st.is_empty():
			var p: int = st.pop_back(); n += 1
			var px := p % w; var py := p / w
			r = r.expand(Vector2i(px, py)).expand(Vector2i(px + 1, py + 1))
			for q in [p - 1, p + 1, p - w, p + w]:
				if q >= 0 and q < w * h and on[q] == 1 and seen[q] == 0 and absi(q % w - px) <= 1:
					seen[q] = 1; st.append(q)
		if n > 40:
			out.append(Rect2i(r.position * step, r.size * step))
	return out

# Turn a diagonal wing so its long axis is horizontal with the root on the left. The
# axis is the principal direction of the opaque pixels; the root is the end nearer the
# bottom-left corner (where the painted wings join the body).
func _level_wing(img: Image) -> Image:
	var w := img.get_width(); var h := img.get_height()
	var sx := 0.0; var sy := 0.0; var n := 0.0
	for y in h:
		for x in w:
			var a := img.get_pixel(x, y).a
			if a > 0.5:
				sx += x; sy += y; n += 1
	var cx := sx / n; var cy := sy / n
	var xx := 0.0; var yy := 0.0; var xy := 0.0
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 0.5:
				xx += (x - cx) * (x - cx); yy += (y - cy) * (y - cy); xy += (x - cx) * (y - cy)
	var ang := 0.5 * atan2(2.0 * xy, xx - yy)   # long axis angle
	var axis := Vector2(cos(ang), sin(ang))
	# root end: the one pointing toward bottom-left
	if axis.dot(Vector2(-1, 1)) > 0.0:
		axis = -axis   # axis now points from root toward tip
	var rot := -axis.angle()   # turn the axis to +x
	var diag := int(ceil(sqrt(float(w * w + h * h))))
	var out := Image.create(diag, diag, false, Image.FORMAT_RGBA8)
	var c := Vector2(diag, diag) * 0.5
	var ca := cos(-rot); var sa := sin(-rot)
	for y in diag:
		for x in diag:
			var dx := x - c.x; var dy := y - c.y
			var srcx := cx + dx * ca - dy * sa
			var srcy := cy + dx * sa + dy * ca
			if srcx >= 0.0 and srcy >= 0.0 and srcx < w - 1 and srcy < h - 1:
				out.set_pixel(x, y, _bilinear(img, srcx, srcy))
	return out

func _bilinear(img: Image, x: float, y: float) -> Color:
	var x0 := int(x); var y0 := int(y)
	var fx := x - x0; var fy := y - y0
	var a := img.get_pixel(x0, y0).lerp(img.get_pixel(x0 + 1, y0), fx)
	var b := img.get_pixel(x0, y0 + 1).lerp(img.get_pixel(x0 + 1, y0 + 1), fx)
	return a.lerp(b, fy)
