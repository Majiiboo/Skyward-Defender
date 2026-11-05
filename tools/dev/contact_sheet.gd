extends SceneTree
# CDIR, CFILES (comma list), CW (cell width), OUTP
func _initialize() -> void:
	var files := OS.get_environment("CFILES").split(",")
	var cw := int(OS.get_environment("CW"))
	var cols := int(OS.get_environment("CCOLS")) if OS.get_environment("CCOLS") != "" else 4
	var imgs: Array = []
	var ch := 0
	for f in files:
		var img := Image.load_from_file(OS.get_environment("CDIR") + "/" + f)
		img.convert(Image.FORMAT_RGBA8)
		img.resize(cw, int(img.get_height() * float(cw) / img.get_width()), Image.INTERPOLATE_BILINEAR)
		imgs.append(img)
		ch = maxi(ch, img.get_height())
	var rows := int(ceil(imgs.size() / float(cols)))
	var out := Image.create(cols * (cw + 8) + 8, rows * (ch + 8) + 8, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.4, 0.42, 0.48))
	for i in imgs.size():
		out.blend_rect(imgs[i], Rect2i(Vector2i.ZERO, imgs[i].get_size()), Vector2i(8 + (i % cols) * (cw + 8), 8 + (i / cols) * (ch + 8)))
	out.save_png(OS.get_environment("OUTP"))
	quit()
