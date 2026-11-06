extends "res://tools/cut_ui_art.gd"
# Cuts Luna's UI kit renders (art_src/ui/ui-<name>.webp, LUNA-BRIEF-ui-kit.md) into ui/<name>.png:
# each piece keyed off black and trimmed, at its full size. UIKit stretches them as 9-slice
# boxes (corners kept, edges and middle stretched), so the pictures stay small and crisp.
# Run: godot --headless --path . --script res://tools/cut_ui_kit.gd   (then --import)

# each piece is saved at its ON-SCREEN size (a 405 px wide button becomes 160 px: a kit button is
# about 160 x 52 on the phone), so the 9-slice corners stay the painted shape at any size
const SCALE := {"btn": 0.36, "panel": 0.4, "header_bar": 0.42, "chip": 0.28, "popup": 0.6, "topbar": 1.0,
	"bar": 0.24, "nav_dock": 1.0, "nav_tile": 1.0, "hud_frame": 1.0}
const PIECES := ["btn_gold", "btn_gold_pressed", "btn_teal", "btn_teal_pressed", "btn_glass", "btn_glass_pressed",
	"btn_off", "btn_tab", "panel_glass", "panel_dark", "panel_gold", "panel_tile", "header_bar", "chip", "popup", "topbar",
	"bar_track", "bar_fill_cyan", "bar_fill_red", "bar_fill_blue", "bar_fill_gold", "nav_dock", "nav_tile", "hud_frame"]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://ui"))
	for n in PIECES:
		var path := ProjectSettings.globalize_path("res://art_src/ui/ui-%s-v2.webp" % n)   # round 2 (gloss in the corner) wins
		if not FileAccess.file_exists(path):
			path = ProjectSettings.globalize_path("res://art_src/ui/ui-%s.webp" % n)
		if not FileAccess.file_exists(path):
			printerr("missing " + path)
			continue
		var img := Image.load_from_file(path)
		img.convert(Image.FORMAT_RGBA8)
		var keyed := _solid(img, 10.0, 26.0, 2)
		var used := keyed.get_used_rect().grow(2).intersection(Rect2i(Vector2i.ZERO, keyed.get_size()))
		var out: Image = keyed.get_region(used)
		var sc := 1.0
		for k in SCALE:
			if n.begins_with(k):
				sc = float(SCALE[k])
		if sc != 1.0:
			out.resize(maxi(1, roundi(out.get_width() * sc)), maxi(1, roundi(out.get_height() * sc)), Image.INTERPOLATE_LANCZOS)
		_save(out, "res://ui/%s.png" % n)
	quit()
