extends SceneTree
# Round 2 turret cards check (dev196): mounts the six new turrets (two loadouts), forces each
# turret's card three times (two picks + the overcharge) and checks the flags landed, then runs
# the fight headless for ~100 s so every new code path (chains, cones, mines, marks, shells,
# embers, hull weld) executes without script errors.
# Run (uses the sim save dir): cp tools/sim_override.cfg override.cfg;
#   godot --headless --path . --script res://tools/dev/card_check.gd; rm override.cfg

const LOADOUTS := [["tesla", "flak", "cryo", "beacon"], ["mines", "repair", "tesla", "flak"]]
const CARDS := {"tesla": "tesla_chain", "flak": "flak_shrapnel", "cryo": "cryo_deep", "beacon": "beacon_dread", "mines": "mines_cluster", "repair": "repair_overdrive"}
var b: Node
var li := 0
var steps := 0
var fails := 0
var checked := false

func _initialize() -> void:
	_next()

func _write_save(lo: Array) -> void:
	var d := {"selected_stage": 35, "stage_unlocked": 46, "pilot_xp": 100000, "dev_mode": true, "areas_briefed": [0, 1, 2, 3, 4, 5],
		"seen_enemies": ["scout", "drifter", "spitter", "diver", "hive_mother", "spore"],
		"turrets": {"loadout": lo, "owned": lo, "tracks": {}}, "coins": 0}
	var f := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()

func _next() -> void:
	if b:
		b.queue_free()
		b = null
	if li >= LOADOUTS.size():
		print("CARD CHECK %s (%d failures)" % ["OK" if fails == 0 else "FAILED", fails])
		quit(0 if fails == 0 else 1)
		return
	_write_save(LOADOUTS[li])
	b = load("res://battle.tscn").instantiate()
	root.add_child(b)
	b.set_process(false)
	b.set_process_input(false)
	steps = 0
	checked = false

func _expect(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("  FAIL: " + what)

func _turret(type: String) -> Dictionary:
	for t in b.turrets:
		if String(t.type) == type:
			return t
	return {}

func _process(_d: float) -> bool:
	if b == null or not b.is_inside_tree():
		return false
	if b.waves.is_empty():
		return false
	if not checked:
		# let every turret land first
		for i in 200:
			b._process(1.0 / 30.0)
		var lo: Array = LOADOUTS[li]
		_expect(b.turrets.size() == 4, "loadout %d: four turrets mounted (got %d)" % [li, b.turrets.size()])
		for type in lo:
			var t := _turret(type)
			_expect(not t.is_empty(), "%s stands on the base" % type)
			if t.is_empty():
				continue
			var before: Dictionary = t.def.duplicate(true)
			for k in 3:
				b._pick_card(CARDS[type])
			_expect(int(b.card_levels.get(CARDS[type], 0)) == 3, "%s: three picks" % CARDS[type])
			match type:
				"tesla": _expect(int(t.def.chain) == 3 and t.get("stun", false), "Chain Coil: 3 jumps + Overload")
				"flak": _expect(is_equal_approx(float(t.def.blast), float(before.blast) * 1.2 * 1.2 * 1.2) and t.get("embers", false), "Shrapnel: blast x1.73 + Incendiary")
				"cryo": _expect(is_equal_approx(float(t.def.cone), float(before.cone) * 1.728) and is_equal_approx(float(t.def.slow), 0.8) and t.get("shatter", false), "Deep Chill: wider, slow 0.8, Shatter")
				"beacon": _expect(is_equal_approx(float(t.def.mark), 6.0) and is_equal_approx(float(t.def.atk), 0.25) and t.get("double_mark", false), "Dread Mark: 6 s, ATK +25%, Twin Mark")
				"mines": _expect(int(t.def.mines) == 6 and t.get("stun", false), "Cluster Mines: 6 mines + Shock")
				"repair": _expect(is_equal_approx(float(t.def.heal), float(before.heal) * 3.375) and t.get("hull_mend", false), "Overdrive Node: mend x3.4 + Hull Weld")
		checked = true
		print("loadout %d: %s cards applied, now fighting" % [li, ", ".join(lo)])
		return false
	for i in 300:
		steps += 1
		if b.picking:
			var offer: Array = b._offer()
			b._pick_card(offer[0])
		b._process(1.0 / 30.0)
		if b.game_over or b.stage_cleared or steps >= 3000:
			var t_share: float = b.stat_turret_dmg / maxf(b.stat_turret_dmg + b.stat_pilot_dmg, 1.0)
			print("loadout %d: %d steps, wave %d, kills %d, turret damage share %d%%, mines alive %d, shield %d / %d, hull %d" % [li, steps, b.wave_index + 1, b.kills, roundi(t_share * 100.0), b.mines.size(), roundi(b.shield), roundi(b.shield_max), roundi(b.hull)])
			_expect(b.stat_turret_dmg > 0.0, "the turrets dealt damage")
			# damage by source (dev199): every mounted turret and the hero counted
			var by: Dictionary = b._dmg_by
			print("loadout %d damage by source: %s" % [li, str(by)])
			_expect(float(by.get("hero", 0.0)) > 0.0, "the hero is counted")
			for type in LOADOUTS[li]:
				if type == "beacon" or type == "repair":
					continue   # support turrets deal no damage
				_expect(float(by.get(type, 0.0)) > 0.0, "%s is counted (got %s)" % [type, str(by.get(type, 0.0))])
			var rows: Control = b._dmg_rows(true)
			_expect(rows.get_child_count() >= 2, "the damage rows build")
			rows.free()
			li += 1
			_next()
			return false
	return false
