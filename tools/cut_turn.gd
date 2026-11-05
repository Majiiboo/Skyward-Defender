extends "res://tools/cut_ui_art.gd"
# Cuts Luna's pilot turn-around frames (art_src/turn, LUNA-BRIEF-pilot-turn.md, dev161):
# five whole-body frames per suit, keyed off black. All five frames of a suit are cropped
# to the SAME rectangle (the union of their used areas), so they stay aligned exactly as
# she rendered them, then scaled to TARGET_H tall: pilot_turn/<suit>_<n>.png.
# Prints each frame's own bounds so drift between frames shows up.
# Run: godot --headless --path . --script res://tools/cut_turn.gd   (then --import)

const SRC2 := "res://art_src/turn/"
const TARGET_H := 640

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://pilot_turn"))
	for suit in ["commander", "rookie"]:
		var frames: Array = []
		var union := Rect2i()
		for n in range(1, 6):
			var path := ProjectSettings.globalize_path(SRC2 + "turn_%s_%d.webp" % [suit, n])
			if not FileAccess.file_exists(path):
				printerr("missing " + path)
				continue
			var img := Image.load_from_file(path)
			img.convert(Image.FORMAT_RGBA8)
			var keyed := _solid(img)
			var used := keyed.get_used_rect()
			print("%s %d: bounds x %d-%d  y %d-%d  (h %d)" % [suit, n, used.position.x, used.end.x, used.position.y, used.end.y, used.size.y])
			frames.append(keyed)
			union = used if union.size == Vector2i.ZERO else union.merge(used)
		union = union.grow(6).intersection(Rect2i(Vector2i.ZERO, frames[0].get_size()))
		for i in frames.size():
			var out: Image = frames[i].get_region(union)
			var s := float(TARGET_H) / out.get_height()
			out.resize(maxi(1, roundi(out.get_width() * s)), TARGET_H, Image.INTERPOLATE_LANCZOS)
			_save(out, "res://pilot_turn/%s_%d.png" % [suit, i + 1])
	quit()
