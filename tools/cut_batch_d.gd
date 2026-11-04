extends SceneTree
# Cuts Luna's batch D sheets (art_src/batch_d) into game pictures by finding each object
# on the black background (connected blobs, glow included), in reading order (rows top
# to bottom, then left to right), and saving them under the names listed below.
#   "solid" = black keyed to alpha (dark insides kept); "light" = stays on black (drawn
#   as added light).
# Run: godot --headless --path . --script res://tools/cut_batch_d.gd

const SRC := "res://art_src/batch_d/"

# sheet -> [mode, longest side px, [names in reading order ("" = skip that blob)], how]
# how: "whole" = the whole picture is one object; "largest" = keep only the biggest blobs
# (sparks dropped); [Rect2i, ...] = boxes measured by hand (sheets whose glows touch)
const SHEETS := {
	"card-piercing-rounds": ["solid", 256, ["cards/pic_piercing_rounds"], "whole"],
	"card-frost-rounds": ["solid", 256, ["cards/pic_frost_rounds"], "whole"],
	"card-turret-overclock": ["solid", 256, ["cards/pic_turret_overclock"], "whole"],
	"card-shield-recharge": ["solid", 256, ["cards/pic_shield_recharge"], "whole"],
	"card-thunder-lance": ["solid", 256, ["cards/pic_thunder_lance"], "whole"],
	"drone-bodies": ["solid", 256, ["drone/body_scout", "drone/body_striker", "drone/body_warden"]],
	"drone-pods-top": ["solid", 128, ["drone/pod_blaster", "drone/pod_beam", "drone/pod_missile"]],
	"drone-flashes-only": ["light", 128, ["drone/flash_blaster", "drone/flash_beam", "drone/flash_missile"], "largest"],
	"pilot-front-parts": ["solid", 0, ["pilot_front/helmet", "pilot_front/torso", "pilot_front/hips", "pilot_front/pad_r", "pilot_front/pad_l",
		"pilot_front/upper", "pilot_front/forearm_fist", "pilot_front/forearm_open", "", "pilot_front/rifle",
		"pilot_front/thigh_r", "pilot_front/thigh_l", "pilot_front/shin", "pilot_front/jet", ""]],
	"turret-heads": ["solid", 256, ["turrets/lance_base", "turrets/lance_head", "turrets/storm_base", "turrets/storm_head",
		"turrets/gravity_base", "turrets/gravity_head", "turrets/prism_base", "turrets/prism_head"],
		[Rect2i(410, 30, 460, 320), Rect2i(985, 5, 575, 305), Rect2i(410, 355, 460, 255), Rect2i(945, 225, 605, 395),
		Rect2i(405, 645, 470, 265), Rect2i(1015, 630, 485, 290), Rect2i(480, 915, 300, 360), Rect2i(1075, 905, 355, 355)]],
}

func _initialize() -> void:
	for d in ["cards", "drone", "turrets", "pilot_front"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + d))
	for sheet in SHEETS:
		var spec: Array = SHEETS[sheet]
		var img := Image.load_from_file(ProjectSettings.globalize_path(SRC + sheet + ".webp"))
		if img == null:
			print("missing ", sheet)
			continue
		img.convert(Image.FORMAT_RGBA8)
		var how = spec[3] if spec.size() > 3 else "blobs"
		var boxes: Array
		if typeof(how) == TYPE_ARRAY:
			boxes = how
		elif how == "whole":
			boxes = [Rect2i(Vector2i.ZERO, img.get_size())]
		elif how == "largest":
			boxes = _blobs(img)
			boxes.sort_custom(func(a, b): return a.get_area() > b.get_area())
			boxes = boxes.slice(0, spec[2].size())
			boxes.sort_custom(func(a, b): return a.position.x < b.position.x)
		else:
			boxes = _blobs(img)
		var names: Array = spec[2]
		print(sheet, ": ", boxes.size(), " blobs for ", names.size(), " names")
		for i in mini(boxes.size(), names.size()):
			if names[i] == "":
				continue
			var cell := img.get_region(boxes[i])
			var out: Image = _light(cell) if spec[0] == "light" else _trim(_only_largest(_solid(cell)) if typeof(how) == TYPE_ARRAY else _solid(cell))
			if int(spec[1]) > 0:   # 0 = keep the painted size (rig parts must stay in scale)
				out = _fit(out, int(spec[1]))
			out.save_png(ProjectSettings.globalize_path("res://%s.png" % names[i]))
			print("  %-28s %s -> %dx%d" % [names[i], boxes[i], out.get_width(), out.get_height()])
	quit()

# Bounding boxes of the objects: a quarter-size mask of lit pixels, grown so glows and
# parts join, split into connected pieces, small specks dropped, sorted into rows.
func _blobs(img: Image) -> Array:
	var k := 4
	var w := img.get_width() / k
	var h := img.get_height() / k
	var small: Image = img.duplicate()
	small.resize(w, h, Image.INTERPOLATE_BILINEAR)
	var m := PackedByteArray(); m.resize(w * h)
	for y in h:
		for x in w:
			var c := small.get_pixel(x, y)
			m[y * w + x] = 1 if maxf(c.r, maxf(c.g, c.b)) > 0.1 else 0
	for _i in 3:   # grow
		var g := m.duplicate()
		for y in h:
			for x in w:
				if m[y * w + x] == 0 and ((x > 0 and m[y * w + x - 1] == 1) or (x < w - 1 and m[y * w + x + 1] == 1) or (y > 0 and m[(y - 1) * w + x] == 1) or (y < h - 1 and m[(y + 1) * w + x] == 1)):
					g[y * w + x] = 1
		m = g
	var seen := PackedByteArray(); seen.resize(w * h)
	var boxes: Array = []
	for start in w * h:
		if m[start] == 0 or seen[start] == 1:
			continue
		var stack := [start]
		seen[start] = 1
		var x0 := w; var y0 := h; var x1 := 0; var y1 := 0; var n := 0
		while not stack.is_empty():
			var p: int = stack.pop_back()
			var px := p % w; var py := p / w
			x0 = mini(x0, px); y0 = mini(y0, py); x1 = maxi(x1, px); y1 = maxi(y1, py); n += 1
			for q in [p - 1, p + 1, p - w, p + w]:
				if q >= 0 and q < w * h and m[q] == 1 and seen[q] == 0 and absi((q % w) - px) <= 1:
					seen[q] = 1
					stack.append(q)
		if n > 60:
			boxes.append(Rect2i(x0 * k, y0 * k, (x1 - x0 + 1) * k, (y1 - y0 + 1) * k).grow(6).intersection(Rect2i(Vector2i.ZERO, img.get_size())))
	# reading order: rows (centres within 40% of a box height), then left to right
	boxes.sort_custom(func(a, b): return a.get_center().y < b.get_center().y)
	var rows: Array = []
	for b in boxes:
		if rows.is_empty() or b.get_center().y - rows[-1][0].get_center().y > rows[-1][0].size.y * 0.4:
			rows.append([b])
		else:
			rows[-1].append(b)
	var out: Array = []
	for r in rows:
		r.sort_custom(func(a, b): return a.position.x < b.position.x)
		out.append_array(r)
	return out

func _fit(img: Image, px: int) -> Image:
	var s := float(px) / maxi(img.get_width(), img.get_height())
	var out: Image = img.duplicate()
	out.resize(maxi(1, roundi(img.get_width() * s)), maxi(1, roundi(img.get_height() * s)), Image.INTERPOLATE_LANCZOS)
	return out

func _trim(img: Image, pad: int = 3) -> Image:
	var r := img.get_used_rect().grow(pad).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	return img.get_region(r) if r.size.x > 0 else img

# keep only the biggest connected solid piece (drops slivers of neighbours that fall
# inside a hand-measured box)
func _only_largest(img: Image) -> Image:
	var w := img.get_width(); var h := img.get_height()
	var d := img.get_data()
	var lab := PackedInt32Array(); lab.resize(w * h)
	var best := -1; var best_n := 0; var id := 0
	for s in w * h:
		if lab[s] != 0 or d[s * 4 + 3] < 60:
			continue
		id += 1
		var n := 0
		var st := [s]
		lab[s] = id
		while not st.is_empty():
			var p: int = st.pop_back()
			n += 1
			var x := p % w
			for q in [p - 1 if x > 0 else -1, p + 1 if x < w - 1 else -1, p - w, p + w]:
				if q >= 0 and q < w * h and lab[q] == 0 and d[q * 4 + 3] >= 60:
					lab[q] = id
					st.append(q)
		if n > best_n:
			best_n = n; best = id
	for i in w * h:
		if lab[i] != best and d[i * 4 + 3] >= 60:
			d[i * 4 + 3] = 0
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, d)

# light on black: crop to what is lit, kept opaque (drawn additive)
func _light(img: Image) -> Image:
	return img

# black -> alpha with soft edges; dark parts inside the object stay solid
func _solid(img: Image, lo: float = 14.0, span: float = 34.0) -> Image:
	var w := img.get_width(); var h := img.get_height()
	var d := img.get_data()
	var outside := PackedByteArray(); outside.resize(w * h)
	var stack: Array = []
	for x in w:
		stack.append(x); stack.append((h - 1) * w + x)
	for y in h:
		stack.append(y * w); stack.append(y * w + w - 1)
	while not stack.is_empty():
		var p: int = stack.pop_back()
		if outside[p] == 1:
			continue
		if maxf(maxf(d[p * 4], d[p * 4 + 1]), d[p * 4 + 2]) > lo + span * 0.5:
			continue
		outside[p] = 1
		var x := p % w
		if x > 0: stack.append(p - 1)
		if x < w - 1: stack.append(p + 1)
		if p >= w: stack.append(p - w)
		if p < w * (h - 1): stack.append(p + w)
	for i in w * h:
		var m: float = maxf(maxf(d[i * 4], d[i * 4 + 1]), d[i * 4 + 2])
		var a: float = clampf((m - lo) / span, 0.0, 1.0) if outside[i] == 1 else 1.0
		if outside[i] == 1 and a > 0.0 and a < 1.0:
			for c in 3:
				d[i * 4 + c] = int(clampf(d[i * 4 + c] / a, 0.0, 255.0))
		d[i * 4 + 3] = int(a * 255.0)
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, d)
