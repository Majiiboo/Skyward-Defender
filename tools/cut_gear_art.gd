extends SceneTree
# Luna's gear sheet (art_src/gear_sheet.webp, 1920 x 1280: columns Ion / Scavenger /
# Void, rows Weapon, Helmet, Chest, Gauntlets, Boots, Jetpack, then the chest orbs)
# -> gear/<set>_<slot>.png and gear/orb_<set>.png, keyed off black, 160 px.
# Run: godot --headless --path . --script res://tools/cut_gear_art.gd

const SETS := ["ion", "scavenger", "void"]
const ROWS := [["weapon", 0, 178], ["helmet", 178, 398], ["chest", 398, 602], ["gauntlets", 602, 772],
	["boots", 772, 975], ["jetpack", 975, 1165], ["orb", 1165, 1280]]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://gear"))
	var sheet := Image.load_from_file(ProjectSettings.globalize_path("res://art_src/gear_sheet.webp"))
	sheet.convert(Image.FORMAT_RGBA8)
	for c in 3:
		for r in ROWS:
			var cell := sheet.get_region(Rect2i(c * 640, r[1], 640, r[2] - r[1]))
			var img := _key(cell)
			var used := img.get_used_rect()
			if used.size.x <= 0:
				continue
			img = img.get_region(used.grow(3).intersection(Rect2i(Vector2i.ZERO, img.get_size())))
			var px := 96 if r[0] == "orb" else 160
			var s := float(px) / maxi(img.get_width(), img.get_height())
			img.resize(maxi(1, roundi(img.get_width() * s)), maxi(1, roundi(img.get_height() * s)), Image.INTERPOLATE_LANCZOS)
			var name: String = ("orb_%s" % SETS[c]) if r[0] == "orb" else ("%s_%s" % [SETS[c], r[0]])
			img.save_png(ProjectSettings.globalize_path("res://gear/%s.png" % name))
			print("gear/%-22s %dx%d" % [name + ".png", img.get_width(), img.get_height()])
	quit()

# soft black key (the middle column's background is a slightly lighter black)
func _key(img: Image, lo: float = 22.0, span: float = 30.0) -> Image:
	var d := img.get_data()
	for i in d.size() / 4:
		var m: float = maxf(maxf(d[i * 4], d[i * 4 + 1]), d[i * 4 + 2])
		var a: float = clampf((m - lo) / span, 0.0, 1.0)
		if a > 0.0 and a < 1.0:
			for k in 3:
				d[i * 4 + k] = int(clampf(d[i * 4 + k] / a, 0.0, 255.0))
		d[i * 4 + 3] = int(a * 255.0)
	return Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, d)
