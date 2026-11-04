extends SceneTree
# Coins per stage from the wave lists (ECONOMY.md). Run: godot --headless --path . --script res://tools/econ.gd
func _initialize() -> void:
	var cum := 0
	var lines := []
	for s in range(1, StageData.MAX_STAGE + 1):
		var total := 0
		var per_wave := []
		var boss := 0
		for wave in StageData.waves(s):
			var wc := 0
			for entry in wave:
				var c := int(StageData.ENEMIES[entry[0]].coins) * int(entry[1])
				if entry[0] == "hive_mother":
					boss += c
				wc += c
			# each Drifter's spore pod gives nothing; Hive Mother hatchlings are extra Scouts (not counted)
			per_wave.append(wc)
			total += wc
		cum += total
		lines.append("%d|%d|%d|%d|%d|%d" % [s, StageData.waves(s).size(), per_wave.min(), per_wave.max(), boss, total] + "|%d" % cum)
	print("\n".join(lines))
	quit()
