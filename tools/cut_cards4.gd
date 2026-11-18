extends "res://tools/cut_ui_art.gd"
# Cuts Luna's card pictures round 4, the SCULPTED EMBLEMS (LUNA-BRIEF-card-pictures-3.md):
#   art_src/cards_r4/pic_<card>.webp (about 500 px, on black, a soft glow painted behind the emblem)
#     -> cards/pic_<card>.png 256 px.
# The glow must fade into the card with no edge, and the dark underside of an emblem must stay solid.
# So: everything reachable from the border through pixels dimmer than EDGE is "glow" and gets its
# brightness as alpha (colour lifted back up so the glow keeps its hue); everything else is solid.
# Every pic_*.webp in the folder is cut: drop new ones in and run it again.
# Run: godot --headless --path . --script res://tools/cut_cards4.gd   (then --import)

const SRC4 := "res://art_src/cards_r4/"
const EDGE := 118.0   # dimmer than this (0-255) and joined to the border = glow
const FLOOR := 8.0    # the black itself

func _initialize() -> void:
	var n := 0
	for f in DirAccess.get_files_at(SRC4):
		if not (f.begins_with("pic_") and f.ends_with(".webp")):
			continue
		var img := Image.load_from_file(ProjectSettings.globalize_path(SRC4 + f))
		img.convert(Image.FORMAT_RGBA8)
		_save(_fit(_trim(_glow_key(img)), 256), "res://cards/%s.png" % f.get_basename())
		n += 1
	print("card pictures cut: %d" % n)
	quit()

func _glow_key(img: Image) -> Image:
	var w := img.get_width()
	var h := img.get_height()
	var d := img.get_data()
	var outside := PackedByteArray()
	outside.resize(w * h)
	var stack: Array = []
	for x in w:
		stack.append(x)
		stack.append((h - 1) * w + x)
	for y in h:
		stack.append(y * w)
		stack.append(y * w + w - 1)
	while not stack.is_empty():
		var p: int = stack.pop_back()
		if outside[p] == 1:
			continue
		if maxf(maxf(d[p * 4], d[p * 4 + 1]), d[p * 4 + 2]) >= EDGE:
			continue
		outside[p] = 1
		var x := p % w
		if x > 0: stack.append(p - 1)
		if x < w - 1: stack.append(p + 1)
		if p >= w: stack.append(p - w)
		if p < w * (h - 1): stack.append(p + w)
	for i in w * h:
		if outside[i] == 0:
			d[i * 4 + 3] = 255
			continue
		var m: float = maxf(maxf(d[i * 4], d[i * 4 + 1]), d[i * 4 + 2])
		var a: float = clampf((m - FLOOR) / (EDGE - FLOOR), 0.0, 1.0)
		if a > 0.0:
			var lift: float = minf(1.0 / a, 255.0 / maxf(m, 1.0))
			d[i * 4] = int(minf(d[i * 4] * lift, 255.0))
			d[i * 4 + 1] = int(minf(d[i * 4 + 1] * lift, 255.0))
			d[i * 4 + 2] = int(minf(d[i * 4 + 2] * lift, 255.0))
		d[i * 4 + 3] = int(a * 255.0)
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, d)
