extends "res://tools/cut_ui_art.gd"
# Cuts Luna's Store 2.0 art (art_src/store2, LUNA-BRIEF-store-2.md) into game pictures:
#   key_u / key_e / key_l.webp -> icons/mat_key_u.png, mat_key_e.png (Materials.icon picks mat_<id>
#       up by itself), icons/key_l.png (kept for a Legendary key later)
#   chest_<t>_stack_check.webp (1024 x 512: the closed chest on the left, the open chest with its
#       burst on the right) -> icons/chest2_<t>_closed.png and chest2_<t>_open.png (256): the Chests
#       tab shows the closed one and cross-fades to the open one when a chest opens
#   chest_<t>_body / _lid / _burst.webp, when they come -> icons/chest3d_<t>_body / _lid / _burst.png
#   pack_*.webp, crystals_N.webp, coins_N.webp, ic_*.webp, when they come -> icons/<name>.png
# Run: godot --headless --path . --script res://tools/cut_store2.gd   (then --import)

const SRC2 := "res://art_src/store2/"

func _initialize() -> void:
	for k in ["u", "e", "l"]:
		var kp := SRC2 + "key_%s.webp" % k
		if FileAccess.file_exists(kp):
			var out := ("res://icons/mat_key_%s.png" % k) if k != "l" else "res://icons/key_l.png"
			_save(_square(_trim(_solid(_img(kp), 10.0, 26.0, 2), 2), 96), out)
		var sc := SRC2 + "chest_%s_stack_check.webp" % k
		if FileAccess.file_exists(sc):
			var img := _solid(_img(sc), 10.0, 26.0, 2)
			var half := img.get_width() / 2
			_save(_fit(_trim(img.get_region(Rect2i(0, 0, half, img.get_height())), 2), 256), "res://icons/chest2_%s_closed.png" % k)
			_save(_fit(_trim(img.get_region(Rect2i(half, 0, img.get_width() - half, img.get_height())), 2), 256), "res://icons/chest2_%s_open.png" % k)
		for p in ["body", "lid", "burst"]:
			var pp := SRC2 + "chest_%s_%s.webp" % [k, p]
			if FileAccess.file_exists(pp):
				var piece := _solid(_img(pp), 10.0, 26.0, 2)
				if p == "lid" and LID_FROM_CLOSED.has(k):
					piece = _lid_from_closed(piece, LID_FROM_CLOSED[k])
				_save(_fit(piece, 256), "res://icons/chest3d_%s_%s.png" % [k, p])
	for n in ["pack_daily", "pack_weekly", "pack_monthly", "pack_stage", "pack_starter", "crystals_1", "crystals_2", "crystals_3", "crystals_4", "crystals_5",
		"coins_1", "coins_2", "coins_3", "coins_4", "ic_exchange", "ic_token", "ic_pity", "ic_free"]:
		var p: String = SRC2 + n + ".webp"
		if FileAccess.file_exists(p):
			_save(_square(_trim(_solid(_img(p), 10.0, 26.0, 2), 2), 96 if n.begins_with("ic_") else 192), "res://icons/%s.png" % n)
	quit()

# A chest whose "lid" render is the WHOLE CLOSED CHEST (Luna finds a lid on its own hard to
# render; the Legendary one came that way): the code makes the lid itself. "seam" = the lid's
# lower edge on the closed render (left corner, front corner, right corner, 512-frame px) and
# "rim" = the open body's top rim at the same three corners; the closed render is warped so the
# seam lands on the rim, then everything below the seam is cut away (a few px kept to hide the
# join). Future chests: ask for open + closed + burst, never a lid (LUNA-BRIEF-store-2.md).
const LID_FROM_CLOSED := {
	# "l" came closed first (archived as chest_l_lid_closed.webp); Luna then painted the lid itself,
	# so nothing uses this today. For a chest that only comes closed: {"seam": [left, front, right
	# corner of the lid's lower edge], "rim": [the body's rim at the same corners]}, 512-frame px.
}
const LID_KEEP := 6.0   # px of the band below the seam kept, so the shut lid overlaps the rim

func _lid_from_closed(closed: Image, fit: Dictionary) -> Image:
	var w := closed.get_width()
	var h := closed.get_height()
	var sc := w / 512.0
	var s: Array = fit.seam
	var d: Array = fit.rim
	# affine map: the seam's three corners onto the rim's three corners
	var ts := Transform2D(Vector2(s[1] - s[0]) * sc, Vector2(s[2] - s[0]) * sc, Vector2(s[0]) * sc)
	var td := Transform2D(Vector2(d[1] - d[0]) * sc, Vector2(d[2] - d[0]) * sc, Vector2(d[0]) * sc)
	var back := ts * td.affine_inverse()   # output px -> closed-render px
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var q := Vector2(x + 0.5, y + 0.5)
			var rim_y := _poly_y(d, q.x / sc) * sc + LID_KEEP * sc
			if q.y > rim_y + 2.0:
				continue
			var p := back * q
			var px := int(floor(p.x))
			var py := int(floor(p.y))
			if px < 0 or py < 0 or px >= w or py >= h:
				continue
			var c := closed.get_pixel(px, py)
			if q.y > rim_y:
				c.a *= clampf(1.0 - (q.y - rim_y) / 2.0, 0.0, 1.0)   # a two-px soft edge
			out.set_pixel(x, y, c)
	print("lid cut from the closed chest (seam warped onto the body rim)")
	return out

# the rim polyline's height at x (left corner -> front corner -> right corner), flat beyond its ends
func _poly_y(pts: Array, x: float) -> float:
	var a: Vector2 = pts[0]
	var b: Vector2 = pts[1]
	var c: Vector2 = pts[2]
	if x <= a.x:
		return a.y
	if x <= b.x:
		return lerpf(a.y, b.y, (x - a.x) / maxf(1.0, b.x - a.x))
	if x <= c.x:
		return lerpf(b.y, c.y, (x - b.x) / maxf(1.0, c.x - b.x))
	return c.y

func _img(path: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	img.convert(Image.FORMAT_RGBA8)
	return img

# centred on a square canvas, then scaled to px
func _square(img: Image, px: int) -> Image:
	var side := maxi(img.get_width(), img.get_height())
	var sq := Image.create(side, side, false, Image.FORMAT_RGBA8)
	sq.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i((side - img.get_width()) / 2, (side - img.get_height()) / 2))
	sq.resize(px, px, Image.INTERPOLATE_LANCZOS)
	return sq
