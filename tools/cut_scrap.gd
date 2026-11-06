extends "res://tools/cut_ui_art.gd"
# Cuts Luna's SCRAP BELT family (art_src/scrap, LUNA-BRIEF-areas.md: junk machines built by
# the bugs, planet 2) into game pictures, keyed off black:
#   enemies/scrap/<machine>_whole.png + its pieces (body, rotor, panels, pod, flame, arms, claw,
#       hold), every piece of one machine at the SAME scale as its whole picture (Luna rendered
#       them in one canvas at one size), so EnemyRig.MACHINES places them by shares of the whole
#   enemies/parts/<machine>_chunk_0..5.png   the six death pieces (the chunk sheets, split by gaps)
#   ui/commander_calm.png, ui/commander_urgent.png   the radio-briefing officer
# Run: godot --headless --path . --script res://tools/cut_scrap.gd   (then --import)

const SRC2 := "res://art_src/scrap/"
const MACHINES := {
	"mite":    {"px": 256, "pieces": ["body", "rotor"]},
	"hulk":    {"px": 256, "pieces": ["body", "panel_l", "panel_r"]},
	"rivet":   {"px": 256, "pieces": ["body", "pod_full", "pod_empty"]},
	"dart":    {"px": 256, "pieces": ["body", "flame"]},
	"bolt":    {"px": 128, "pieces": []},
	"wrecker": {"px": 400, "pieces": ["body", "arm", "claw_open", "rotor"]},
	"queen":   {"px": 480, "pieces": ["body", "arm_l", "arm_r", "hold_open"]},
}
const CHUNKS := ["mite", "hulk", "rivet", "dart", "queen"]

func _initialize() -> void:
	for d in ["enemies/scrap", "enemies/parts", "ui"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + d))
	for id in MACHINES:
		var spec: Dictionary = MACHINES[id]
		var whole := _trim(_solid(_img(SRC2 + "%s_whole.webp" % id)), 2)
		var s := float(spec.px) / maxi(whole.get_width(), whole.get_height())
		_save(_scaled(whole, s), "res://enemies/scrap/%s_whole.png" % id)
		for p in spec.pieces:
			var path := SRC2 + "%s_%s.webp" % [id, p]
			if not FileAccess.file_exists(path):
				print("%s_%s: missing" % [id, p])
				continue
			var img := _trim(_solid(_img(path)), 2)
			# the rivet pods were rendered as whole discs: they are the dome on the back, a third of the body
			var ps := s * (0.34 if id == "rivet" and p.begins_with("pod") else 1.0)
			_save(_scaled(img, ps), "res://enemies/scrap/%s_%s.png" % [id, p])
	for id in CHUNKS:
		_chunks(id)
	for n in ["commander_calm", "commander_urgent"]:
		_save(_fit(_trim(_solid(_img(SRC2 + n + ".webp")), 2), 256), "res://ui/%s.png" % n)
	quit()

func _img(path: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	img.convert(Image.FORMAT_RGBA8)
	return img

func _scaled(img: Image, s: float) -> Image:
	var out: Image = img.duplicate()
	out.resize(maxi(1, roundi(img.get_width() * s)), maxi(1, roundi(img.get_height() * s)), Image.INTERPOLATE_LANCZOS)
	return out

# the chunk sheet: six pieces side by side, split where columns are empty (cut_parts_r1 rule)
func _chunks(id: String) -> void:
	var path := SRC2 + "%s_chunks.webp" % id
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
