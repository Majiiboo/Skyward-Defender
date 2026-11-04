extends SceneTree
# Luna's 3D gear renders (art_src/gear3d/<set>-<slot>.webp: Tier 1 / 2 / 3 left to right
# on black, sizes vary) -> gear/<set>_<slot>_t1..t3.png, keyed off black, 192 px.
# Each render is split at the emptiest columns near its thirds, so tiers that are not on
# an even grid still come apart.
# Run: godot --headless --path . --script res://tools/cut_gear3d.gd

const SETS := ["ion", "scavenger", "void", "nightmare", "solar", "frost"]
const SLOTS := ["weapon", "helmet", "chest", "gauntlets", "boots", "jetpack"]
const PX := 192

func _initialize() -> void:
	for set_id in SETS:
		for slot in SLOTS:
			var src := ProjectSettings.globalize_path("res://art_src/gear3d/%s-%s.webp" % [set_id, slot])
			var img := Image.load_from_file(src)
			if img == null:
				push_error("missing " + src)
				continue
			img.convert(Image.FORMAT_RGBA8)
			var keyed := _key(img)
			var w := img.get_width()
			var cuts := [0, _split(keyed, w / 3.0), _split(keyed, w * 2.0 / 3.0), w]
			for t in 3:
				var box := Rect2i(cuts[t], 0, cuts[t + 1] - cuts[t], img.get_height())
				var used := keyed.get_region(box).get_used_rect()
				if used.size.x <= 0:
					push_error("empty tier %d in %s" % [t + 1, src])
					continue
				used.position += box.position
				var part := img.get_region(used.grow(8).intersection(box))
				# key again at twice the final size, keeping dark armour solid inside
				var s2 := float(PX * 2) / maxi(part.get_width(), part.get_height())
				part.resize(maxi(1, roundi(part.get_width() * s2)), maxi(1, roundi(part.get_height() * s2)), Image.INTERPOLATE_LANCZOS)
				part = _solid(part)
				var s := float(PX) / maxi(part.get_width(), part.get_height())
				part.resize(maxi(1, roundi(part.get_width() * s)), maxi(1, roundi(part.get_height() * s)), Image.INTERPOLATE_LANCZOS)
				var out := "res://gear/%s_%s_t%d.png" % [set_id, slot, t + 1]
				part.save_png(ProjectSettings.globalize_path(out))
				print("%-34s %3dx%3d  cut %d-%d" % [out, part.get_width(), part.get_height(), cuts[t], cuts[t + 1]])
	quit()

# the emptiest column within 12% of the width around x (middle of the widest empty run)
func _split(img: Image, x: float) -> int:
	var w := img.get_width()
	var h := img.get_height()
	var lo := maxi(1, int(x - w * 0.12))
	var hi := mini(w - 2, int(x + w * 0.12))
	var fill: Array = []
	for cx in range(lo, hi + 1):
		var n := 0
		for y in range(0, h, 2):
			if img.get_pixel(cx, y).a > 0.15:
				n += 1
		fill.append(n)
	var least: int = fill.min()
	# widest run of columns at the lowest fill, closest to x on ties
	var best_mid := int(x)
	var best_len := -1
	var i := 0
	while i < fill.size():
		if fill[i] == least:
			var j := i
			while j + 1 < fill.size() and fill[j + 1] == least:
				j += 1
			var mid := lo + (i + j) / 2
			if j - i > best_len or (j - i == best_len and absf(mid - x) < absf(best_mid - x)):
				best_len = j - i
				best_mid = mid
			i = j + 1
		else:
			i += 1
	return best_mid

# soft black key: glows fade out instead of cutting off
func _key(img: Image, lo: float = 18.0, span: float = 34.0) -> Image:
	var d := img.get_data()
	for i in d.size() / 4:
		var m: float = maxf(maxf(d[i * 4], d[i * 4 + 1]), d[i * 4 + 2])
		var a: float = clampf((m - lo) / span, 0.0, 1.0)
		if a > 0.0 and a < 1.0:
			for k in 3:
				d[i * 4 + k] = int(clampf(d[i * 4 + k] / a, 0.0, 255.0))
		d[i * 4 + 3] = int(a * 255.0)
	return Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, d)

# like _key, but anything enclosed by the piece's outline stays opaque, so dark armour
# never turns see-through (tools/cut_ui_art.gd)
func _solid(img: Image, lo: float = 14.0, span: float = 34.0, close: int = 4) -> Image:
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
			# pure black inside the outline is a gap (between a pair), not dark armour
			if not near_out and m > 7.0:
				a = 1.0
		elif a > 0.0 and a < 1.0:
			for c in 3:
				d[i * 4 + c] = int(clampf(d[i * 4 + c] / a, 0.0, 255.0))
		d[i * 4 + 3] = int(a * 255.0)
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, d)
