extends SceneTree
# Cuts the GLOW out of each turret picture (dev154): keeps only the bright, saturated
# pixels (crystal, vents, rods, orb, hatch rim) with soft edges, on a transparent canvas of
# the same size, into turrets/<name>_light.png. battle.gd draws that layer on the additive
# effect layer over the turret, breathing while idle, swelling while charging, flashing on
# fire. No Luna work needed: her render already holds the light.
# Run: godot --headless --path . --script res://tools/cut_turret_light.gd   (then --import)

const SRC := {"sentry": "sentry_head", "lance": "lance_head", "storm": "storm_head",
	"gravity": "gravity_head", "prism": "prism_head", "swarm": "swarm_idle"}

func _initialize() -> void:
	for name in SRC:
		var img := Image.load_from_file(ProjectSettings.globalize_path("res://turrets/%s.png" % SRC[name]))
		img.convert(Image.FORMAT_RGBA8)
		var w := img.get_width()
		var h := img.get_height()
		var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
		var lit := 0
		for y in h:
			for x in w:
				var c := img.get_pixel(x, y)
				var hi := maxf(maxf(c.r, c.g), c.b)
				var lo := minf(minf(c.r, c.g), c.b)
				var sat := (hi - lo) / maxf(hi, 0.001)
				# bright AND coloured = light; bright grey = metal highlight, left out
				var keep := smoothstep(0.62, 0.95, hi) * clampf((sat - 0.18) / 0.35, 0.0, 1.0) * c.a
				if keep > 0.02:
					lit += 1
				out.set_pixel(x, y, Color(c.r, c.g, c.b, keep))
		var path := "res://turrets/%s_light.png" % name
		out.save_png(ProjectSettings.globalize_path(path))
		print("%-28s %dx%d  lit %.1f%%" % [path, w, h, 100.0 * lit / float(w * h)])
	quit()
