extends "res://tools/cut_ui_art.gd"
# Cuts Luna's ICONS 3 renders (art_src/icons3, LUNA-BRIEF-icons-3.md):
#   materials_sheet.webp (1024 x 1024, 4 x 4 cells of 256, fourteen used, read left to right,
#   top row first) -> icons/mat_<id>.png 96 px (keyed off black, trimmed, squared, like
#   cut_icons2); Materials.icon picks them up by name, the shard and the token are extra
#   pic_<card>.webp (512, on black) -> cards/pic_<card>.png 256 px (keyed like cut_cards2);
#   battle _card_pic prefers cards/pic_<id>.png over the card's borrowed "pic"
# Run: godot --headless --path . --script res://tools/cut_icons3.gd   (then --import)

const SRC3 := "res://art_src/icons3/"
const CELL := 256
const ICON_PX := 96
const MATS := ["ess_ion", "ess_scavenger", "ess_frost", "ess_void", "ess_nightmare", "ess_solar",
	"barrel", "lens", "coil", "rotor", "gyro", "flightcore", "shard", "token"]
const PICS := ["repair_overdrive", "tesla_chain", "cryo_deep", "mines_cluster", "beacon_dread",
	"flak_shrapnel", "focus_fire", "salvage", "second_wind", "mirror_shell"]

func _initialize() -> void:
	var sheet_p: String = SRC3 + "materials_sheet.webp"
	if FileAccess.file_exists(sheet_p):
		var sheet := _img(sheet_p)
		var cols := sheet.get_width() / CELL
		for i in MATS.size():
			var cell := sheet.get_region(Rect2i(Vector2i((i % cols) * CELL, (i / cols) * CELL), Vector2i(CELL, CELL)))
			var cut := _trim(_solid(cell, 10.0, 26.0, 2), 3)
			_save(_square(cut, ICON_PX), "res://icons/mat_%s.png" % MATS[i])
	else:
		print("materials_sheet.webp: not delivered")
	for id in PICS:
		var p: String = SRC3 + "pic_%s.webp" % id
		if not FileAccess.file_exists(p):
			print("pic_%s: not delivered, the card keeps its borrowed picture" % id)
			continue
		_save(_fit(_trim(_solid(_img(p), 12.0, 30.0, 2)), 256), "res://cards/pic_%s.png" % id)
	quit()

func _img(path: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	img.convert(Image.FORMAT_RGBA8)
	return img

func _square(img: Image, px: int) -> Image:
	var side := maxi(img.get_width(), img.get_height())
	var sq := Image.create(side, side, false, Image.FORMAT_RGBA8)
	sq.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i((side - img.get_width()) / 2, (side - img.get_height()) / 2))
	sq.resize(px, px, Image.INTERPOLATE_LANCZOS)
	return sq
