extends "res://tools/cut_scrap.gd"
# Cuts Luna's MAGMA WORLD family (art_src/magma, LUNA-BRIEF-magma-family.md: creatures of black
# rock and lava, planet 3) into game pictures, keyed off black:
#   enemies/magma/<id>_whole.png + its pieces, every piece of one creature at the SAME scale as
#       its whole picture. Luna rendered the pieces in the whole's canvas, so this also PRINTS
#       where each piece sits on the whole (the centre of its box as shares of the whole's box):
#       those numbers go into EnemyRig.MACHINES.
#   enemies/parts/<id>_chunk_0..5.png   the six death pieces
# Run: godot --headless --path . --script res://tools/cut_magma.gd   (then --import)

const SRC3 := "res://art_src/magma/"
const CREATURES := {
	"cinder":   {"px": 256, "pieces": ["body", "wing"]},
	"crust":    {"px": 256, "pieces": ["body", "plate_l", "plate_r"], "flip": true},   # she drew its head up: the family flies head DOWN
	"spitfire": {"px": 256, "pieces": ["body", "sac_full", "sac_empty"]},
	"comet":    {"px": 256, "pieces": ["body", "flame"]},
	"coal":     {"px": 128, "pieces": []},
	"smelter":  {"px": 400, "pieces": ["mouth_open"]},   # her body and claw renders are at another scale than the whole: the whole picture is used, the open mouth laid over it
	"caldera":  {"px": 480, "pieces": ["body", "arm_l", "arm_r", "vent_open"]},
}
const MAGMA_CHUNKS := ["cinder", "crust", "spitfire", "comet", "smelter", "caldera"]

func _initialize() -> void:
	for d in ["enemies/magma", "enemies/parts"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + d))
	for id in CREATURES:
		var spec: Dictionary = CREATURES[id]
		var flip: bool = spec.get("flip", false)
		var wk := _keyed(SRC3 + "%s_whole.webp" % id, flip)
		var wb := wk.get_used_rect()
		var s := float(spec.px) / maxi(wb.size.x, wb.size.y)
		_save(_scaled(wk.get_region(wb), s), "res://enemies/magma/%s_whole.png" % id)
		print("  %s whole box %s of %s  scale %.3f" % [id, str(wb), str(wk.get_size()), s])
		for p in spec.pieces:
			var path := SRC3 + "%s_%s.webp" % [id, p]
			if not FileAccess.file_exists(path):
				print("%s_%s: missing" % [id, p])
				continue
			var pk := _keyed(path, flip)
			var pb := pk.get_used_rect()
			# a piece rendered on a canvas of another size than its whole: bring it to the whole's
			var cs := float(wk.get_width()) / float(pk.get_width())
			_save(_scaled(pk.get_region(pb), s * cs), "res://enemies/magma/%s_%s.png" % [id, p])
			var c := (Vector2(pb.position) + Vector2(pb.size) * 0.5) * cs
			print("  %s_%s centre on the whole: (%.3f, %.3f)   box share (%.3f, %.3f)" % [id, p,
				(c.x - wb.position.x) / wb.size.x, (c.y - wb.position.y) / wb.size.y, pb.size.x * cs / wb.size.x, pb.size.y * cs / wb.size.y])
	for id in MAGMA_CHUNKS:
		_chunks3(id)
	quit()

func _keyed(path: String, flip: bool) -> Image:
	var img := _img(path)
	if flip:
		img.flip_y()
	var k := _solid(img)
	# specks far from the creature would stretch its box: drop anything fainter than a whisper
	var d := k.get_data()
	for i in k.get_width() * k.get_height():
		if d[i * 4 + 3] < 20:
			d[i * 4 + 3] = 0
	return Image.create_from_data(k.get_width(), k.get_height(), false, Image.FORMAT_RGBA8, d)

# the chunk sheet (cut_scrap _chunks, reading from art_src/magma)
func _chunks3(id: String) -> void:
	var path := SRC3 + "%s_chunks.webp" % id
	if not FileAccess.file_exists(path):
		print("%s chunks: missing" % id)
		return
	var keyed := _solid(_img(path))
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
		_save(_fit(_trim(piece), 96), "res://enemies/parts/%s_chunk_%d.png" % [id, i])
	print("%s chunks: %d pieces" % [id, runs.size()])
