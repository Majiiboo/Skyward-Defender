extends SceneTree
func _initialize() -> void:
	var img := Image.load_from_file(OS.get_environment("GF"))
	var w := img.get_width(); var h := img.get_height()
	var runs := []; var inrun := false; var st := 0
	for x in w:
		var empty := true
		for y in range(0, h, 2):
			var c := img.get_pixel(x, y)
			if c.r + c.g + c.b > 0.12: empty = false; break
		if empty and not inrun: inrun = true; st = x
		if not empty and inrun: inrun = false; if x - st > 3: runs.append([st, x])
	print(w, "x", h, " empty column runs: ", runs)
	quit()
