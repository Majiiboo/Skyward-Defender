extends SceneTree
# Luna's chip symbols (LUNA-BRIEF-chip-icons.md): art_src/chips/chip_<id>.webp, white light on
# black, 1024 square -> icons/chip_<id>.png at 128, pure white with the brightness as alpha, so
# the game can tint each by its rarity (gear.gd ChipTile). Skips what is not delivered.
#   godot --headless --path . --script res://tools/cut_chips.gd     (then --import)

const IDS := ["frag", "drill", "cryo", "fire", "sure", "arc", "guard", "bounty", "split", "leech", "mark", "over", "stun", "reaper", "core"]
const OUT := 128
const FLOOR := 0.04   # the render's background grey, taken off

func _initialize() -> void:
	for id in IDS:
		var src := ProjectSettings.globalize_path("res://art_src/chips/chip_%s.webp" % id)
		if not FileAccess.file_exists(src):
			print("chip_%s: not delivered yet" % id)
			continue
		var im := Image.load_from_file(src)
		im.convert(Image.FORMAT_RGBA8)
		im.resize(OUT, OUT, Image.INTERPOLATE_LANCZOS)
		for y in OUT:
			for x in OUT:
				var c := im.get_pixel(x, y)
				var a := clampf((maxf(c.r, maxf(c.g, c.b)) - FLOOR) / (1.0 - FLOOR), 0.0, 1.0)
				im.set_pixel(x, y, Color(1, 1, 1, a))
		im.save_png(ProjectSettings.globalize_path("res://icons/chip_%s.png" % id))
		print("icons/chip_%s.png" % id)
	quit()
