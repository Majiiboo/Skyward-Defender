extends "res://tools/cut_ui_art.gd"
# Cuts Luna's hero stand (art_src/stand/, LUNA-BRIEF-hero-stand.md) into gear/:
#   stand_disc.png  the disc keyed off black, trimmed (its white light lines stay white)
#   stand_glow.png  the lights only, brightness -> alpha, on the SAME crop as the disc
#   stand_beam.png  the light column, brightness -> alpha, trimmed
# Run: godot --headless --path . --script res://tools/cut_stand.gd   (then --import)
func _initialize() -> void:
	var disc := Image.load_from_file(ProjectSettings.globalize_path("res://art_src/stand/stand_disc.webp"))
	disc.convert(Image.FORMAT_RGBA8)
	var keyed := _solid(disc, 10.0, 26.0, 2)
	var crop := keyed.get_used_rect().grow(4).intersection(Rect2i(Vector2i.ZERO, keyed.get_size()))
	var d2 := keyed.get_region(crop)
	d2.resize(d2.get_width() / 2, d2.get_height() / 2, Image.INTERPOLATE_LANCZOS)
	_save(d2, "res://gear/stand_disc.png")
	var glow := Image.load_from_file(ProjectSettings.globalize_path("res://art_src/stand/stand_glow.webp"))
	glow.convert(Image.FORMAT_RGBA8)
	var g2 := _light(glow).get_region(crop)
	g2.resize(g2.get_width() / 2, g2.get_height() / 2, Image.INTERPOLATE_LANCZOS)
	_save(g2, "res://gear/stand_glow.png")
	var beam := Image.load_from_file(ProjectSettings.globalize_path("res://art_src/stand/stand_beam.webp"))
	beam.convert(Image.FORMAT_RGBA8)
	var b2 := _light(beam)
	var bc := b2.get_used_rect().grow(4).intersection(Rect2i(Vector2i.ZERO, b2.get_size()))
	b2 = b2.get_region(bc)
	b2.resize(b2.get_width() / 2, b2.get_height() / 2, Image.INTERPOLATE_LANCZOS)
	_save(b2, "res://gear/stand_beam.png")
	quit()
