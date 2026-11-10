extends SceneTree
# Cuts Luna's NEW BASE renders (art_src/base2/, LUNA-BRIEF-base-core.md) into base/:
#   core.png + core_light.png   one shared crop (the light lines up with the socket)
#   pod_1.png, pod_2.png, pod_3.png   one shared crop (the union), so the window stays put
#   arm.png
#   bld_<id>.png x9   the building pictures that sit in a pod's window
# Solid pieces: the black around them is flood-filled from the picture's edge and made clear (a
# soft edge where the glow fades), dark insides stay solid. The core light is light on black:
# its brightness becomes its alpha. Prints the numbers the game needs (Backdrop CORE_ART).
# Run: godot --headless --path . --script res://tools/cut_base2.gd   then --import.

const SRC := "res://art_src/base2/"
const OUT := "res://base/"
const T := 0.085   # darker than this and joined to the edge = background

func _load(name: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(SRC + name + ".webp"))
	img.convert(Image.FORMAT_RGBA8)
	return img

func _maxc(c: Color) -> float:
	return maxf(c.r, maxf(c.g, c.b))

# background (dark, joined to the border) -> clear, with a soft ramp so glows fade out
func _key_solid(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var stack := PackedInt32Array()
	for x in w:
		stack.append(x)
		stack.append((h - 1) * w + x)
	for y in h:
		stack.append(y * w)
		stack.append(y * w + w - 1)
	while not stack.is_empty():
		var i := stack[stack.size() - 1]
		stack.remove_at(stack.size() - 1)
		if seen[i] == 1:
			continue
		var x := i % w
		var y := i / w
		var c := img.get_pixel(x, y)
		var m := _maxc(c)
		if m >= T * 2.2:
			continue
		seen[i] = 1
		if m < T:
			img.set_pixel(x, y, Color(0, 0, 0, 0))
			if x > 0: stack.append(i - 1)
			if x < w - 1: stack.append(i + 1)
			if y > 0: stack.append(i - w)
			if y < h - 1: stack.append(i + w)
		else:   # the fading edge of a glow next to the background: partly clear, and no further
			var a := clampf((m - T) / (T * 1.2), 0.0, 1.0)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, a))

# light painted on black -> its brightness is its alpha
func _key_light(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var m := _maxc(c)
			if m < 0.03:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				img.set_pixel(x, y, Color(c.r / m, c.g / m, c.b / m, clampf(m * 1.15, 0.0, 1.0)))

func _used(imgs: Array) -> Rect2i:
	var r := Rect2i()
	for img in imgs:
		var u: Rect2i = img.get_used_rect()
		r = u if r.size == Vector2i.ZERO else r.merge(u)
	return r.grow(2).intersection(Rect2i(0, 0, imgs[0].get_width(), imgs[0].get_height()))

func _save(img: Image, crop: Rect2i, out_w: int, name: String) -> void:
	var cut := img.get_region(crop)
	cut.resize(out_w, int(round(out_w * float(crop.size.y) / crop.size.x)), Image.INTERPOLATE_LANCZOS)
	cut.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("%s.png  %d x %d  (crop %s)" % [name, cut.get_width(), cut.get_height(), str(crop)])

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	# the core and its light
	var core := _load("base2_core")
	var light := _load("base2_core_light")
	_key_solid(core)
	_key_light(light)
	var cc := _used([core, light])
	_save(core, cc, 400, "core")
	_save(light, cc, 400, "core_light")
	# where the light's bright middle sits inside the crop (shares of its width / height)
	var sx := 0.0
	var sy := 0.0
	var sw := 0.0
	for y in range(cc.position.y, cc.end.y):
		for x in range(cc.position.x, cc.end.x):
			var a := light.get_pixel(x, y).a
			if a > 0.9:
				sx += x * a
				sy += y * a
				sw += a
	print("CORE eye at (%.4f, %.4f) of the crop; crop aspect h / w = %.4f" % [(sx / sw - cc.position.x) / cc.size.x, (sy / sw - cc.position.y) / cc.size.y, float(cc.size.y) / cc.size.x])
	# the pods: one crop for all three
	var pods: Array = []
	for i in 3:
		var p := _load("base2_pod_%d" % (i + 1))
		_key_solid(p)
		pods.append(p)
	var pc := _used(pods)
	for i in 3:
		_save(pods[i], pc, 256, "pod_%d" % (i + 1))
	var u1: Rect2i = pods[0].get_used_rect()
	print("POD 1 fills %.4f of the shared crop's width; centre at (%.4f, %.4f)" % [float(u1.size.x) / pc.size.x, (u1.get_center().x - pc.position.x) / float(pc.size.x), (u1.get_center().y - pc.position.y) / float(pc.size.y)])
	# the arm
	var arm := _load("base2_arm")
	_key_solid(arm)
	var ac: Rect2i = arm.get_used_rect()
	ac.position.x = 0
	ac.size.x = arm.get_width()
	_save(arm, ac, 512, "arm")
	# the nine buildings
	for id in ["shield_gen", "repair_bay", "armory", "medbay", "plating", "hangar", "reactor", "radar", "refinery"]:
		var b := _load("b_" + id)
		_key_solid(b)
		var bc: Rect2i = b.get_used_rect().grow(2).intersection(Rect2i(0, 0, b.get_width(), b.get_height()))
		# square crop round the object, so every building sits the same way in the window
		var side := maxi(bc.size.x, bc.size.y)
		var sq := Rect2i(bc.get_center() - Vector2i(side / 2, side / 2), Vector2i(side, side)).intersection(Rect2i(0, 0, b.get_width(), b.get_height()))
		_save(b, sq, 192, "bld_" + id)
	quit(0)
