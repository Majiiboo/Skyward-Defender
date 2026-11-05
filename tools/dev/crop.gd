extends SceneTree
# CROP="out x y w h scale in1 in2 ..." -> side by side
func _initialize() -> void:
	var a := OS.get_environment("CROP").split(" ")
	var r := Rect2i(int(a[1]), int(a[2]), int(a[3]), int(a[4]))
	var sc := float(a[5])
	var imgs := []
	for i in range(6, a.size()):
		var im := Image.load_from_file(a[i])
		im = im.get_region(r)
		im.resize(int(r.size.x * sc), int(r.size.y * sc), Image.INTERPOLATE_LANCZOS)
		imgs.append(im)
	var out := Image.create(int(r.size.x * sc) * imgs.size(), int(r.size.y * sc), false, Image.FORMAT_RGBA8)
	for i in imgs.size():
		var im: Image = imgs[i]
		im.convert(Image.FORMAT_RGBA8)
		out.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(i * im.get_width(), 0))
	out.save_png(a[0])
	quit()
