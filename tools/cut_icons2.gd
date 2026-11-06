extends "res://tools/cut_ui_art.gd"
# Cuts Luna's icon renders (art_src/icons2/<name>.webp, LUNA-BRIEF-icons.md, 256 px each) into
# icons/<name>.png: keyed off black, trimmed to a square round the icon, 96 px (drawn at 18-48).
# Run: godot --headless --path . --script res://tools/cut_icons2.gd   (then --import)

const OUT_PX := 96

func _initialize() -> void:
	var dir := DirAccess.open("res://art_src/icons2")
	if dir == null:
		printerr("no art_src/icons2")
		quit()
		return
	for f in dir.get_files():
		if not f.ends_with(".webp") or f.begins_with("alt_"):
			continue
		var img := Image.load_from_file(ProjectSettings.globalize_path("res://art_src/icons2/" + f))
		img.convert(Image.FORMAT_RGBA8)
		var keyed := _solid(img, 10.0, 26.0, 2)
		var used := keyed.get_used_rect().grow(3).intersection(Rect2i(Vector2i.ZERO, keyed.get_size()))
		var cut := keyed.get_region(used)
		var side := maxi(cut.get_width(), cut.get_height())
		var sq := Image.create(side, side, false, Image.FORMAT_RGBA8)
		sq.blit_rect(cut, Rect2i(Vector2i.ZERO, cut.get_size()), Vector2i((side - cut.get_width()) / 2, (side - cut.get_height()) / 2))
		sq.resize(OUT_PX, OUT_PX, Image.INTERPOLATE_LANCZOS)
		_save(sq, "res://icons/%s.png" % f.get_basename())
	quit()
