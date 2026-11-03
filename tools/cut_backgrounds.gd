extends SceneTree
# Luna's painted worlds (art_src/dev87/bg_*.webp, 1152 x 2048) -> backdrops/<name>.webp
# at 720 x 1280, lossy, for Backdrop.draw_world. Run:
#   godot --headless --path . --script res://tools/cut_backgrounds.gd

const NAMES := ["hive_a", "hive_b", "scrap", "magma", "crystal", "plasma", "sentinel"]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://backdrops"))
	for n in NAMES:
		var img := Image.load_from_file(ProjectSettings.globalize_path("res://art_src/dev87/bg_%s.webp" % n))
		img.convert(Image.FORMAT_RGB8)
		if n == "scrap":
			# a flat grey band runs along the very bottom of this one: drop it
			img = img.get_region(Rect2i(0, 0, img.get_width(), int(img.get_height() * 0.935)))
		img.resize(720, int(720.0 * img.get_height() / img.get_width()), Image.INTERPOLATE_LANCZOS)
		var path := "res://backdrops/%s.webp" % n
		img.save_webp(ProjectSettings.globalize_path(path), true, 0.85)
		print("%-28s %dx%d" % [path, img.get_width(), img.get_height()])
	quit()
