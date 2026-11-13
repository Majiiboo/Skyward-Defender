extends "res://tools/cut_ui_art.gd"
# Cuts Luna's FIGHT pieces of a hero (art_src/heroes/<id>/fight/, LUNA-BRIEF-frost-fight-pieces.md:
# the hero seen from straight above, in rigid pieces) into heroes/<id>/fight/<piece>.png, keyed
# off black. Every piece is brought to the size it has on frostfight_whole (FIT, measured against
# the whole picture) and then saved at HALF of the 1024 art, so HeroFight draws them all at ONE scale.
# Run: godot --headless --path . --script res://tools/cut_frost_fight.gd   (then --import)

const HALF := 0.5
# piece -> [source file (without the hero prefix), fit to the whole, mirror]
const SETS := {
	"frost": {
		"prefix": "frostfight_",
		"pieces": {
			"body":    ["body", 1.19, false],
			"helmet":  ["helmet", 1.03, false],
			"flipper": ["flipper_l_v2", 1.4, false],     # the smooth one; the first has fin grooves
			"arm":     ["arm_r", 0.95, false],
			"leg_r":   ["leg_r", 0.95, false],
			"leg_l":   ["leg_r", 0.95, true],            # leg_l came with a flat cap on top: the right one mirrored
			"flame":   ["flame", 1.0, false],
			# his weapons seen from above, one per CLASS (HeroFight._top): carried close, tucked under the arm
			"top_main":    ["rifle", 0.81, false],
			"top_sidearm": ["top_pistol", 1.0, false],
			"top_heavy":   ["top_launcher", 1.0, false],
			"whole":   ["whole", 1.0, false],
		},
	},
}

func _initialize() -> void:
	for id in SETS:
		var spec: Dictionary = SETS[id]
		var src := "res://art_src/heroes/%s/fight/" % id
		var out := "res://heroes/%s/fight/" % id
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
		for p in spec.pieces:
			var row: Array = spec.pieces[p]
			if not FileAccess.file_exists(src + String(spec.prefix) + String(row[0]) + ".webp"):
				print("%s %s: not delivered yet" % [id, p])
				continue
			var img := Image.load_from_file(ProjectSettings.globalize_path(src + String(spec.prefix) + String(row[0]) + ".webp"))
			img.convert(Image.FORMAT_RGBA8)
			var keyed: Image = _light(img) if p == "flame" else _solid(img)
			var used := keyed.get_used_rect()
			var cut := _trim(keyed, 2)
			if bool(row[2]):
				cut.flip_x()
			var s := float(row[1]) * HALF
			cut.resize(maxi(1, roundi(cut.get_width() * s)), maxi(1, roundi(cut.get_height() * s)), Image.INTERPOLATE_LANCZOS)
			_save(cut, out + p + ".png")
			print("%s %s: in the art %s -> saved %dx%d" % [id, p, used, cut.get_width(), cut.get_height()])
	quit()
