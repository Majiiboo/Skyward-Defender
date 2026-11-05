extends "res://tools/cut_ui_art.gd"
# Cuts Luna's animation parts, round 1 (art_src/parts_r1, dev160; LUNA-BRIEF-animation-parts.md
# v2: every piece its own picture on black) into game pictures, keyed off black with the
# same routine as the other cutters (_solid from cut_ui_art.gd):
#   turrets/sentry_barrels.png, sentry_head_nobarrels.png, swarm_lid.png, swarm_body_nolid.png
#   enemies/parts/<bug>_body_clean.png, _legs_l, _legs_r, _feelers (scout, drifter, spitter, diver)
#   enemies/parts/spitter_sac_full.png, spitter_sac_empty.png
#   enemies/parts/<bug>_chunk_0..5.png   (the six pieces of each chunk sheet, split by gaps)
#   drone/<body>_hull.png, <body>_thruster_l.png, <body>_thruster_r.png (scout, striker, warden)
# Run: godot --headless --path . --script res://tools/cut_parts_r1.gd   (then --import)

const P := "res://art_src/parts_r1/"

func _initialize() -> void:
	for d in ["turrets", "enemies/parts", "drone"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + d))
	var jobs := [
		["turret_sentry_barrels", "turrets/sentry_barrels.png", 256],
		["turret_sentry_head_nobarrels", "turrets/sentry_head_nobarrels.png", 256],
		["turret_swarm_lid", "turrets/swarm_lid.png", 256],
		["turret_swarm_body_nolid", "turrets/swarm_body_nolid.png", 270],
		["bug_spitter_sac_full", "enemies/parts/spitter_sac_full.png", 200],
		["bug_spitter_sac_empty", "enemies/parts/spitter_sac_empty.png", 200],
	]
	for b in ["scout", "drifter", "spitter", "diver"]:
		for p in ["body_clean", "legs_l", "legs_r", "feelers"]:
			jobs.append(["bug_%s_%s" % [b, p], "enemies/parts/%s_%s.png" % [b, p], 256])
	for b in ["scout", "striker", "warden"]:
		for p in ["hull", "thruster_l", "thruster_r"]:
			jobs.append(["drone_%s_%s" % [b, p], "drone/%s_%s.png" % [b, p], 200])
	for j in jobs:
		var img := _load(j[0])
		if img == null:
			continue
		_save(_fit(_trim(_solid(img)), j[2]), "res://" + j[1])
	# the chunk sheets: six pieces side by side, split where columns are empty
	for b in ["scout", "drifter", "spitter", "diver"]:
		var img := _load("bug_%s_chunks" % b)
		if img == null:
			continue
		var keyed := _solid(img)
		var w := keyed.get_width()
		var h := keyed.get_height()
		var has := PackedByteArray()
		has.resize(w)
		for x in w:
			var any := 0
			for y in range(0, h, 2):
				if keyed.get_pixel(x, y).a > 0.08:
					any = 1
					break
			has[x] = any
		# runs of filled columns, small gaps bridged
		var runs: Array = []
		var x := 0
		while x < w:
			if has[x] == 1:
				var x0 := x
				var gap := 0
				while x < w and gap < 10:
					gap = 0 if has[x] == 1 else gap + 1
					x += 1
				runs.append([x0, x - gap])
			else:
				x += 1
		runs.sort_custom(func(a, c): return (a[1] - a[0]) > (c[1] - c[0]))
		runs = runs.slice(0, 6)
		runs.sort_custom(func(a, c): return a[0] < c[0])
		for i in runs.size():
			var r: Array = runs[i]
			var piece := keyed.get_region(Rect2i(r[0], 0, r[1] - r[0], h))
			_save(_fit(_trim(piece), 96), "res://enemies/parts/%s_chunk_%d.png" % [b, i])
		print("%s chunks: %d pieces" % [b, runs.size()])
	quit()

func _load(name: String) -> Image:
	var path := ProjectSettings.globalize_path(P + name + ".webp")
	if not FileAccess.file_exists(path):
		printerr("missing: " + path)
		return null
	var img := Image.load_from_file(path)
	img.convert(Image.FORMAT_RGBA8)
	return img
