extends SceneTree
# Cuts Luna's dev87 small pieces (art_src/dev87) into game pictures:
#   pickups/gem_0..3.png      gems (blue shard, purple prism, red ember, gold star)
#   fx/bolt.png, fx/impact.png, fx/nova.png   light (stays on black, drawn additive)
#   fx/goo.png                Spitter goo glob (travels toward the top of the picture)
#   cards/pic_<card>.png      power card pictures
#   icons/ui_*.png            coin, crystal, energy, heart, badge, padlock
#   base/lid_closed|half|open.png   locked socket hatch
#   icons/chest3d_*.png, icons/drone_*.png   Home Chest and Patrol layers
#   dev104 (art_src/cards_r1): new card + fusion pictures, frame_fusion / frame_overcharge,
#   gear/platform.png (the Gear screen platform)
# Run: godot --headless --path . --script res://tools/cut_ui_art.gd

const SRC := "res://art_src/dev87/"

# [sheet, rect (x, y, w, h), output, longest side px, mode]
# mode: "solid" = key black to alpha; "light" = keep on black (additive); add "+flip"
# to mirror left-right.
const JOBS := [
	["pickups_v1", [96, 260, 260, 232], "pickups/gem_0.png", 96, "solid"],
	["pickups_v1", [556, 136, 252, 464], "pickups/gem_1.png", 96, "solid"],
	["pickups_v1", [1008, 256, 244, 236], "pickups/gem_2.png", 96, "solid"],
	["pickups_v1", [1396, 108, 484, 476], "pickups/gem_3.png", 128, "solid"],
	["pickups_v1", [1010, 720, 370, 420], "fx/impact.png", 128, "light"],
	["bolt_goo", [440, 90, 1352, 390], "fx/bolt.png", 256, "light+flip"],
	["bolt_goo", [660, 520, 590, 720], "fx/goo.png", 128, "solid"],
	["card_pictures", [672, 880, 564, 360], "fx/nova.png", 256, "light"],
	["card_pictures", [66, 50, 552, 388], "cards/pic_rapid_pulse.png", 256, "solid"],
	["card_pictures", [674, 50, 560, 388], "cards/pic_heavy_bolts.png", 256, "solid"],
	["card_pictures", [1290, 50, 564, 388], "cards/pic_burst_fire.png", 256, "solid"],
	["card_pictures", [66, 490, 552, 396], "cards/pic_aegis.png", 256, "solid"],
	["card_pictures", [674, 490, 560, 360], "cards/pic_magnet.png", 256, "solid"],
	["card_pictures", [1290, 490, 564, 396], "cards/pic_reinforced_hull.png", 256, "solid"],
	["card_pictures", [672, 880, 564, 360], "cards/pic_nova_burst.png", 256, "light"],
	["ui_icons", [112, 128, 480, 476], "icons/ui_coin.png", 128, "solid"],
	["ui_icons", [812, 104, 304, 536], "icons/ui_crystal.png", 128, "solid"],
	["ui_icons", [1380, 72, 372, 584], "icons/ui_energy.png", 128, "solid"],
	["ui_icons", [116, 744, 460, 420], "icons/ui_heart.png", 128, "solid"],
	["badge_padlock", [60, 320, 1076, 696], "icons/ui_badge.png", 160, "solid"],
	["badge_padlock", [1164, 276, 568, 748], "icons/ui_padlock.png", 128, "solid"],
	["socket_lid", [16, 410, 944, 380], "base/lid_closed.png", 256, "solid"],
	["socket_lid", [1056, 150, 888, 680], "base/lid_half.png", 256, "solid"],
	["socket_lid", [2136, 16, 328, 892], "base/lid_open.png", 256, "solid"],
	["chest_v1", [130, 190, 690, 550], "icons/chest3d_body.png", 192, "solid"],
	["chest_v1", [1040, 200, 680, 540], "icons/chest3d_closed.png", 192, "solid"],
	["chest_v1", [1880, 86, 772, 744], "icons/chest3d_burst.png", 192, "light"],
	["chest_lid", [960, 200, 708, 452], "icons/chest3d_lid.png", 192, "solid"],
	["patrol_drone", [90, 94, 1744, 1088], "icons/drone_body.png", 192, "solid"],
	["home_buttons_v1", [730, 300, 464, 96], "icons/drone_prop.png", 128, "solid"],
	["home_buttons_v1", [1450, 176, 184, 384], "icons/drone_thrust.png", 96, "light"],
	# dev104 (art_src/cards_r1): new card pictures, fusion pictures, frames, Gear platform
	["../cards_r1/pic-chain-spark", [0, 0, 9999, 9999], "cards/pic_chain_spark.png", 256, "solid"],
	["../cards_r1/pic-wingman-redo", [0, 0, 9999, 9999], "cards/pic_wingman.png", 256, "solid"],
	["../cards_r1/pic-quick-study", [0, 0, 9999, 9999], "cards/pic_quick_study.png", 256, "solid"],
	["../cards_r1/pic-railstorm", [0, 0, 9999, 9999], "cards/pic_railstorm.png", 256, "solid"],
	["../cards_r1/pic-gem-barrage", [0, 0, 9999, 9999], "cards/pic_gem_barrage.png", 256, "solid"],
	["../cards_r1/pic-bastion", [0, 0, 9999, 9999], "cards/pic_bastion.png", 256, "solid"],
	["../cards_r1/pic-storm-wing", [0, 0, 9999, 9999], "cards/pic_storm_wing.png", 256, "solid"],
	["../cards_r1/frame-fusion", [0, 0, 9999, 9999], "cards/frame_fusion.png", 450, "solid+card"],
	["../cards_r1/frame-overcharge", [176, 326, 924, 1336], "cards/frame_overcharge.png", 450, "solid+card"],   # frame body only (sparks outside it trimmed)
	["../cards_r1/gear-platform-design-classic", [0, 0, 9999, 9999], "gear/platform.png", 720, "solid"],
	# batch D (art_src/batch_d): bolt designs for the cards (pointing right, light) and the
	# rifle muzzle flash in 4 steps (each cropped just past the barrel Luna painted in)
	["../batch_d/bolt-designs", [30, 500, 490, 280], "fx/bolt_rail.png", 256, "light"],
	["../batch_d/bolt-designs", [530, 440, 420, 260], "fx/bolt_spark.png", 256, "light"],
	["../batch_d/bolt-designs", [995, 520, 430, 210], "fx/bolt_heavy.png", 256, "light"],
	["../batch_d/bolt-designs", [1475, 560, 410, 170], "fx/bolt_twin.png", 256, "light"],
	["../batch_d/muzzle-flash", [276, 290, 240, 300], "pilot_rig/muzzle_0.png", 160, "light"],
	["../batch_d/muzzle-flash", [840, 140, 528, 660], "pilot_rig/muzzle_1.png", 192, "light"],
	["../batch_d/muzzle-flash", [1658, 330, 410, 270], "pilot_rig/muzzle_2.png", 160, "light"],
	["../batch_d/muzzle-flash", [2357, 270, 379, 380], "pilot_rig/muzzle_3.png", 160, "light"],
]

func _initialize() -> void:
	for d in ["pickups", "fx", "cards", "icons", "base", "gear"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + d))
	var sheets := {}
	for j in JOBS:
		if not sheets.has(j[0]):
			var img := Image.load_from_file(ProjectSettings.globalize_path(SRC + j[0] + ".webp"))
			img.convert(Image.FORMAT_RGBA8)
			sheets[j[0]] = img
		var src: Image = sheets[j[0]]
		var r: Array = j[1]
		var rect := Rect2i(r[0], r[1], r[2], r[3]).intersection(Rect2i(Vector2i.ZERO, src.get_size()))
		var cell := src.get_region(rect)
		var mode: String = j[4]
		var out: Image
		if mode.begins_with("light"):
			out = _light(cell)
		else:
			out = _trim(_solid(cell))
		if mode.ends_with("+flip"):
			out.flip_x()
		if mode.ends_with("+card"):
			out.resize(300, 450, Image.INTERPOLATE_LANCZOS)   # same size as the other card frames
			_save(out, "res://" + j[2])
			continue
		_save(_fit(out, j[3]), "res://" + j[2])
	_platform_layers()
	quit()

func _save(img: Image, path: String) -> void:
	img.save_png(ProjectSettings.globalize_path(path))
	print("%-34s %dx%d" % [path, img.get_width(), img.get_height()])

func _fit(img: Image, px: int) -> Image:
	var s := float(px) / maxi(img.get_width(), img.get_height())
	var out: Image = img.duplicate()
	out.resize(maxi(1, roundi(img.get_width() * s)), maxi(1, roundi(img.get_height() * s)), Image.INTERPOLATE_LANCZOS)
	return out

func _trim(img: Image, pad: int = 3) -> Image:
	var r := img.get_used_rect().grow(pad).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	return img.get_region(r) if r.size.x > 0 else img

# Light on black: subtract the faint cell background, crop to what is lit, alpha 1.
func _light(img: Image) -> Image:
	var w := img.get_width(); var h := img.get_height()
	var bg := 1.0
	for p in [Vector2i(2, 2), Vector2i(w - 3, 2), Vector2i(2, h - 3), Vector2i(w - 3, h - 3)]:
		var c := img.get_pixelv(p)
		bg = minf(bg, maxf(maxf(c.r, c.g), c.b))
	bg += 0.025
	var lit := Rect2i()
	var any := false
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var k := 1.0 / (1.0 - bg)
			c = Color(maxf(c.r - bg, 0.0) * k, maxf(c.g - bg, 0.0) * k, maxf(c.b - bg, 0.0) * k, 1.0)
			img.set_pixel(x, y, c)
			if maxf(maxf(c.r, c.g), c.b) > 0.03:
				lit = Rect2i(x, y, 1, 1) if not any else lit.expand(Vector2i(x, y)).expand(Vector2i(x + 1, y + 1))
				any = true
	return img.get_region(lit.grow(2).intersection(Rect2i(0, 0, w, h))) if any else img

# Black -> alpha with soft edges; dark parts inside the object stay solid (see
# tools/cut_bug_art.gd for the same method).
func _solid(img: Image, lo: float = 14.0, span: float = 34.0, close: int = 3) -> Image:
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

# Luna's two-layer Gear platform (art_src/cards_r1/platform_floor_classic.png on black,
# platform_rim_classic.png already see-through, same canvas): both cropped to the same
# box and scaled alike -> gear/platform_floor.png, gear/platform_rim.png, plus
# gear/platform_rim_lights.png = only the lit windows and antenna tips of the rim, in
# white, for the set-bonus glow (gear.gd PlatformFloor tints and adds it).
func _platform_layers() -> void:
	var floor_src := Image.load_from_file(ProjectSettings.globalize_path("res://art_src/cards_r1/platform_floor_classic.png"))
	var rim := Image.load_from_file(ProjectSettings.globalize_path("res://art_src/cards_r1/platform_rim_classic.png"))
	if floor_src == null or rim == null:
		return
	floor_src.convert(Image.FORMAT_RGBA8)
	rim.convert(Image.FORMAT_RGBA8)
	var floor_img := _solid(floor_src)
	var box := floor_img.get_used_rect().merge(rim.get_used_rect()).grow(3).intersection(Rect2i(Vector2i.ZERO, rim.get_size()))
	# the floor picture keeps faint dark ghosts of the buildings above the deck: clear
	# everything above the deck's back edge (the rim layer covers that strip)
	var cut_y := box.position.y + int(box.size.y * 0.17)
	for y in range(0, cut_y):
		for x in floor_img.get_width():
			floor_img.set_pixel(x, y, Color(0, 0, 0, 0))
	var s := 720.0 / maxi(box.size.x, box.size.y)
	var size := Vector2i(roundi(box.size.x * s), roundi(box.size.y * s))
	var pairs := [[floor_img.get_region(box), "gear/platform_floor.png"], [rim.get_region(box), "gear/platform_rim.png"],
		[_lights_mask(rim.get_region(box), 10), "gear/platform_rim_lights.png"], [_lights_mask(floor_img.get_region(box), 3), "gear/platform_floor_lights.png"]]
	for pair in pairs:
		var im: Image = pair[0]
		im.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
		_save(im, "res://" + pair[1])

# White mask of what is lit in a picture (bright and coloured: cyan / purple light, not
# grey metal), plus a soft halo `halo` px wide, for tinted additive glows.
func _lights_mask(src: Image, halo: int) -> Image:
	var w := src.get_width(); var h := src.get_height()
	var d := src.get_data()
	var m := PackedByteArray(); m.resize(w * h * 4)
	for i in w * h:
		var r: float = d[i * 4] / 255.0
		var g: float = d[i * 4 + 1] / 255.0
		var b: float = d[i * 4 + 2] / 255.0
		var mx := maxf(r, maxf(g, b))
		var sat := mx - minf(r, minf(g, b))
		var k := smoothstep(0.45, 0.8, mx) * smoothstep(0.15, 0.4, sat) * (d[i * 4 + 3] / 255.0)
		m[i * 4] = 255; m[i * 4 + 1] = 255; m[i * 4 + 2] = 255
		m[i * 4 + 3] = int(k * 255.0)
	var sharp := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, m)
	if halo <= 0:
		return sharp
	# halo: shrink and grow back (a cheap blur), then keep the brighter of the two
	var soft: Image = sharp.duplicate()
	soft.resize(maxi(1, w / halo), maxi(1, h / halo), Image.INTERPOLATE_BILINEAR)
	soft.resize(w, h, Image.INTERPOLATE_BILINEAR)
	var sd := soft.get_data()
	for i in w * h:
		m[i * 4 + 3] = maxi(m[i * 4 + 3], mini(255, int(sd[i * 4 + 3] * 2.2)))
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, m)
