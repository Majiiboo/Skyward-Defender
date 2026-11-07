extends "res://tools/cut_ui_art.gd"
# Cuts Luna's STAR MAP art (art_src/talents, LUNA-BRIEF-talent-map.md) for gear.gd StarMap:
#   nebula_0..3.webp (1024 x 1152, a constellation sky with the figure as ghost line art)
#       -> talents/nebula_<s>.png 640 x 720 with alpha from brightness, so the code's own dark
#          gradient shows through and neighbouring skies blend into each other
#   node_dim / node_lit / node_next, system_dim / system_lit / system_next (512, black)
#       -> talents/<name>.png 128 px, keyed off black
# Run: godot --headless --path . --script res://tools/cut_talents.gd   (then --import)

const SRC2 := "res://art_src/talents/"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://talents"))
	for s in 4:
		var p: String = SRC2 + "nebula_%d.webp" % s
		if FileAccess.file_exists(p):
			var img := _img(p)
			img.resize(640, 720, Image.INTERPOLATE_LANCZOS)
			_save(_alpha_from_light(img), "res://talents/nebula_%d.png" % s)
	for n in ["node_dim", "node_lit", "node_next", "system_dim", "system_lit", "system_next"]:
		var p: String = SRC2 + n + ".webp"
		if FileAccess.file_exists(p):
			_save(_square(_trim(_solid(_img(p), 10.0, 26.0, 2), 4), 128), "res://talents/%s.png" % n)
	quit()

func _img(path: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	img.convert(Image.FORMAT_RGBA8)
	return img

func _alpha_from_light(img: Image) -> Image:
	var w := img.get_width()
	var h := img.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var a: float = clampf((maxf(maxf(c.r, c.g), c.b) - 0.04) / 0.96, 0.0, 1.0)
			out.set_pixel(x, y, Color(c.r, c.g, c.b, a))
	return out

func _square(img: Image, px: int) -> Image:
	var side := maxi(img.get_width(), img.get_height())
	var sq := Image.create(side, side, false, Image.FORMAT_RGBA8)
	sq.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i((side - img.get_width()) / 2, (side - img.get_height()) / 2))
	sq.resize(px, px, Image.INTERPOLATE_LANCZOS)
	return sq
