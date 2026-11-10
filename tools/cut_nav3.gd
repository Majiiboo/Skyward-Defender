extends "res://tools/cut_ui_art.gd"
# Cuts Luna's NAV ICONS round 2 (art_src/nav3, LUNA-BRIEF-nav-icons.md + LUNA-BRIEF-nav-quest-ticks.md):
# every icon comes whole + its moving parts, all on one 1024 canvas on black. Each picture is keyed
# off black (dark insides kept, like cut_icons3), and every file of one icon gets the SAME square crop
# (the union of that icon's pictures), so the parts still stack exactly -> icons/nav3/<icon>_<part>.png
# at PX. The moon and the spark are trimmed on their own. NavIcon (nav_icon.gd) draws them.
# Run: godot --headless --path . --script res://tools/cut_nav3.gd   (then --import)

const SRCN := "res://art_src/nav3/"
const OUTN := "res://icons/nav3/"
const PX := 192
const SETS := {
	"store": ["", "_body", "_lid", "_latch", "_open"],
	"heroes": ["", "_body", "_head", "_visor", "_light"],
	"battle": ["", "_disc", "_rings", "_ticks"],
	"modes": ["", "_planet", "_ring_back", "_ring_front"],
	"quests": ["", "_board", "_clip", "_tick_1", "_tick_2", "_tick_3"],
}
const SINGLES := {"modes_moon": 48, "spark": 64}

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTN))
	for icon in SETS:
		var cuts := {}
		var u := Rect2i()
		for suf in SETS[icon]:
			var p: String = SRCN + "nav3_%s%s.png" % [icon, suf]
			if not FileAccess.file_exists(p):
				print("nav3_%s%s: missing" % [icon, suf])
				continue
			var c := _solid(_img(p), 14.0, 30.0, 2)
			cuts[suf] = c
			var r := c.get_used_rect()
			u = r if u.size == Vector2i.ZERO else u.merge(r)
		var side := maxi(u.size.x, u.size.y) + 8
		var org := u.position + u.size / 2 - Vector2i(side, side) / 2
		for suf in cuts:
			var sq := Image.create(side, side, false, Image.FORMAT_RGBA8)
			sq.blit_rect(cuts[suf], Rect2i(org, Vector2i(side, side)), Vector2i.ZERO)
			sq.resize(PX, PX, Image.INTERPOLATE_LANCZOS)
			sq.save_png(ProjectSettings.globalize_path(OUTN + icon + suf + ".png"))
		print(icon, ": ", cuts.size(), " pictures, crop ", Rect2i(org, Vector2i(side, side)))
	for one in SINGLES:
		var p: String = SRCN + "nav3_%s.png" % one
		if not FileAccess.file_exists(p):
			continue
		var c := _trim(_solid(_img(p), 14.0, 30.0, 2), 2)
		var w: int = SINGLES[one]
		c.resize(w, maxi(1, w * c.get_height() / c.get_width()), Image.INTERPOLATE_LANCZOS)
		c.save_png(ProjectSettings.globalize_path(OUTN + one + ".png"))
	quit()

func _img(path: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	img.convert(Image.FORMAT_RGBA8)
	return img
