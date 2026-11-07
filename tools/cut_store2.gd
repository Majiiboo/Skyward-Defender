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
				_save(_fit(_solid(_img(pp), 10.0, 26.0, 2), 256), "res://icons/chest3d_%s_%s.png" % [k, p])
	for n in ["pack_daily", "pack_weekly", "pack_monthly", "pack_stage", "pack_starter", "crystals_1", "crystals_2", "crystals_3", "crystals_4", "crystals_5",
		"coins_1", "coins_2", "coins_3", "coins_4", "ic_exchange", "ic_token", "ic_pity", "ic_free"]:
		var p: String = SRC2 + n + ".webp"
		if FileAccess.file_exists(p):
			_save(_square(_trim(_solid(_img(p), 10.0, 26.0, 2), 2), 96 if n.begins_with("ic_") else 192), "res://icons/%s.png" % n)
	quit()

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
