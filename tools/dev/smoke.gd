extends SceneTree
# Smoke check (headless): loads every script in the project root and the tools, so a typo
# shows up before a build is handed over, then runs a few quick logic checks on the data
# classes (no save file is touched). Run:
#   godot --headless --path . --script res://tools/dev/smoke.gd
# Exit code 1 when anything fails.

var fails := 0

func _initialize() -> void:
	# every script in the root (the game) must parse and be instantiable
	var dir := DirAccess.open("res://")
	for f in dir.get_files():
		if f.ends_with(".gd"):
			var s = load("res://" + f)
			if s == null or not s.can_instantiate():
				_fail("script does not load: " + f)
	_check_energy()
	_check_cards()
	print("SMOKE %s  (%d failures)" % ["OK" if fails == 0 else "FAILED", fails])
	quit(1 if fails > 0 else 0)

func _fail(msg: String) -> void:
	fails += 1
	printerr("FAIL: " + msg)

func _expect(ok: bool, msg: String) -> void:
	if not ok:
		_fail(msg)

func _check_energy() -> void:
	_expect(Energy.cost(false, 1) == 0, "stage 1 should be free")
	_expect(Energy.cost(false, 5) == 0, "stage 5 should be free")
	_expect(Energy.cost(false, 6) == Energy.STAGE_COST, "stage 6 costs the normal price")
	_expect(Energy.cost(true, 1) == Energy.ELITE_COST, "elite always pays")
	_expect(Energy.cost(false) == Energy.STAGE_COST, "unknown stage pays the normal price")
	# a free stage never touches the tokens
	var s := {"energy": 3, "energy_t": Time.get_unix_time_from_system()}
	var e0 := Energy.update(s)
	_expect(Energy.try_spend(s, Energy.cost(false, 2)) and int(s.energy) == e0, "free stage leaves tokens as they are")


func _check_cards() -> void:
	for id in Cards.CARDS:
		if Cards.CARDS[id].has("turret"):
			_expect(ResourceLoader.exists("res://cards/pic_%s.png" % id), "turret card picture missing: " + id)
