extends SceneTree
# MONT="dir out cols x y w h scale f0 f1 f2 ..."
func _initialize() -> void:
	var a := OS.get_environment("MONT").split(" ")
	var dir := a[0]; var out := a[1]; var cols := int(a[2])
	var r := Rect2i(int(a[3]), int(a[4]), int(a[5]), int(a[6])); var sc := float(a[7])
	var frames := a.slice(8)
	var cw := int(r.size.x * sc); var ch := int(r.size.y * sc)
	var rows := ceili(frames.size() / float(cols))
	var img := Image.create(cw * cols + (cols - 1) * 4, ch * rows + (rows - 1) * 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.3, 0.3, 0.3))
	for i in frames.size():
		var f := Image.load_from_file("%s/f%08d.png" % [dir, int(frames[i])])
		f.convert(Image.FORMAT_RGBA8)
		var c := f.get_region(r)
		c.resize(cw, ch, Image.INTERPOLATE_BILINEAR)
		img.blit_rect(c, Rect2i(Vector2i.ZERO, c.get_size()), Vector2i((i % cols) * (cw + 4), (i / cols) * (ch + 4)))
	img.save_png(out)
	quit()
