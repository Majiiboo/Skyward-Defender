extends "res://tools/cut_ui_art.gd"
# Cuts Luna's cards round 2 (art_src/cards_r3, LUNA-BRIEF-cards-2.md):
#   pic_<card>.webp (512, on black)  -> cards/pic_<card>.png 256 px (keyed like the first card set)
#   frame_uncommon-v2.png (300 x 444, see-through window) -> cards/frame_uncommon.png with the
#       window filled in the Common frame's dark, so the card reads the same as the others
#   tw_<twist>.png (256, on black)   -> icons/tw_<twist>.png 96 px (trimmed, squared)
# Run: godot --headless --path . --script res://tools/cut_cards2.gd   (then --import)

const SRC3 := "res://art_src/cards_r3/"
const HERO_CARDS := ["rook_twin", "sparks_weld", "frost_freeze", "hollow_phase", "nyx_mark", "ember_burn"]
const TWISTS := ["rapid", "sharpshooter", "fortified", "reinforced", "turret_boost", "overcharge",
	"swift_bugs", "thick_shells", "no_turrets", "double_spit", "weak_shield"]
const ICON_PX := 96

func _initialize() -> void:
	for id in HERO_CARDS:
		var p := SRC3 + "pic_%s.webp" % id
		if not FileAccess.file_exists(p):
			print("pic_%s: not delivered, the card keeps its weapon picture" % id)
			continue
		var img := Image.load_from_file(ProjectSettings.globalize_path(p))
		img.convert(Image.FORMAT_RGBA8)
		_save(_fit(_trim(_solid(img)), 256), "res://cards/pic_%s.png" % id)
	_frame()
	for t in TWISTS:
		var p := SRC3 + "tw_%s.png" % t
		if not FileAccess.file_exists(p):
			print("tw_%s: missing" % t)
			continue
		var img := Image.load_from_file(ProjectSettings.globalize_path(p))
		img.convert(Image.FORMAT_RGBA8)
		var cut := _trim(_solid(img, 10.0, 26.0, 2))
		var side := maxi(cut.get_width(), cut.get_height())
		var sq := Image.create(side, side, false, Image.FORMAT_RGBA8)
		sq.blit_rect(cut, Rect2i(Vector2i.ZERO, cut.get_size()), Vector2i((side - cut.get_width()) / 2, (side - cut.get_height()) / 2))
		sq.resize(ICON_PX, ICON_PX, Image.INTERPOLATE_LANCZOS)
		_save(sq, "res://icons/tw_%s.png" % t)
	quit()

# The Uncommon frame: Luna's v2 has the Common frame's size and window but leaves the window
# see-through; flood the window from the centre with the Common frame's dark so the picture
# and text sit on the same ground as on every other card.
func _frame() -> void:
	var p := SRC3 + "frame_uncommon-v2.png"
	if not FileAccess.file_exists(p):
		return
	var img := Image.load_from_file(ProjectSettings.globalize_path(p))
	img.convert(Image.FORMAT_RGBA8)
	var common := Image.load_from_file(ProjectSettings.globalize_path("res://cards/frame_common.png"))
	common.convert(Image.FORMAT_RGBA8)
	var dark := common.get_pixel(common.get_width() / 2, common.get_height() / 2)
	if img.get_size() != common.get_size():
		img.resize(common.get_width(), common.get_height(), Image.INTERPOLATE_LANCZOS)
	var w := img.get_width()
	var h := img.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var stack: Array[Vector2i] = [Vector2i(w / 2, h / 2)]
	var filled := 0
	while not stack.is_empty():
		var q: Vector2i = stack.pop_back()
		if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h or seen[q.y * w + q.x] == 1:
			continue
		seen[q.y * w + q.x] = 1
		var c := img.get_pixelv(q)
		if c.a > 0.06:
			continue
		img.set_pixelv(q, dark)
		filled += 1
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			stack.append(q + d)
	# the soft rim of the window: pixels half see-through next to the fill get the dark under them
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if c.a > 0.06 and c.a < 0.98 and seen[y * w + x] == 0:
				var near := false
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var n: Vector2i = Vector2i(x, y) + d
					if n.x >= 0 and n.y >= 0 and n.x < w and n.y < h and seen[n.y * w + n.x] == 1:
						near = true
				if near:
					img.set_pixel(x, y, dark.lerp(Color(c.r, c.g, c.b, 1.0), c.a))
	print("frame window filled: %d px (%.0f%%)" % [filled, 100.0 * filled / (w * h)])
	_save(img, "res://cards/frame_uncommon.png")
