extends SceneTree
# Luna's upgrade-part icons -> parts/alloy.png, parts/cell.png, parts/core.png (128 px,
# keyed off black). Alloy and Core from art_src/gear2/gear-tiers2-part-icons.webp (left and
# right thirds), the Cell from part-icon-plasma-cell-recolour.webp.
# Run: godot --headless --path . --script res://tools/cut_part_icons.gd

const PX := 128

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://parts"))
	var sheet := _load("res://art_src/gear2/gear-tiers2-part-icons.webp")
	var w := sheet.get_width()
	_save(sheet.get_region(Rect2i(0, 0, w / 3, sheet.get_height())), "alloy")
	_save(sheet.get_region(Rect2i(w * 2 / 3, 0, w - w * 2 / 3, sheet.get_height())), "core")
	_save(_load("res://art_src/gear2/part-icon-plasma-cell-recolour.webp"), "cell")
	quit()

func _load(path: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	img.convert(Image.FORMAT_RGBA8)
	return img

func _save(img: Image, name: String) -> void:
	img = _key(img)
	var used := img.get_used_rect()
	img = img.get_region(used.grow(4).intersection(Rect2i(Vector2i.ZERO, img.get_size())))
	var s := float(PX) / maxi(img.get_width(), img.get_height())
	img.resize(maxi(1, roundi(img.get_width() * s)), maxi(1, roundi(img.get_height() * s)), Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path("res://parts/%s.png" % name))
	print("parts/%s.png %dx%d" % [name, img.get_width(), img.get_height()])

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
