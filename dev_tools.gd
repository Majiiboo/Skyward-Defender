class_name DevTools
extends RefCounted
# Developer shortcuts (Rudy, dev166): on the Settings page while BuildInfo.DEV is true, so a
# test build can show every unlock and merge without hours of play. Set BuildInfo.DEV false
# for a store build and the section disappears.
# DEV MODE (Rudy, dev172): a switch on the Settings page (save "dev_mode"): every hero, turret,
# drone body and pod, weapon, mode and trial is open, mounts are open, upgrades and unlocks are
# free, power tokens never gate a fight. Progress.read sets `on` from the save; the pages that
# read the save file themselves set it too.
static var on := false

# a fat wallet: coins, crystals, parts and power
static func rich() -> void:
	var d := Progress.read()
	Progress.grant(d, {"coins": 500000, "crystals": 20000, "alloy": 999, "cell": 500, "core": 200})
	d["energy"] = 999
	d["energy_t"] = Time.get_unix_time_from_system()
	Progress.write(d)

# every stage cleared with three stars, pilot level 40 (every turret, trial and set open),
# the Commander suit, Elite
static func unlock_all() -> void:
	var d := Progress.read()
	d["stage_unlocked"] = StageData.MAX_STAGE + 1
	var st := {}
	for s in range(1, StageData.MAX_STAGE + 1):
		st[str(s)] = 3
	d["stars"] = st
	d["pilot_xp"] = maxi(int(d.get("pilot_xp", 0)), Turrets.xp_for_level(40))
	d["commander_seen"] = true
	d["areas_briefed"] = [0, 1, 2, 3, 4, 5]
	Progress.write(d)

# copies of every owned piece, so merging can be tried at every rarity: 9 Common, 3
# Uncommon, 3 Rare, 3 Epic (two Epic stacks short of a Legendary: merge them by hand)
static func gear_copies() -> void:
	var d := Progress.read()
	var g := GearData.read(d)
	for id in GearData.ITEMS:
		if not GearData.owned(g, id):
			continue
		GearData.add_copy(g, id, "common", 9)
		GearData.add_copy(g, id, "uncommon", 3)
		GearData.add_copy(g, id, "rare", 3)
		GearData.add_copy(g, id, "epic", 3)
	d["gear"] = GearData.write(g)
	var hh := Heroes.read(d)   # and 50 shards of every hero (heroes, dev172)
	for hid in Heroes.ORDER:
		Heroes.add_shards(hh, hid, 50)
	d["hero"] = Heroes.write(hh)
	for mk in Materials.ORDER:   # and 20 of every material (materials.gd, dev189)
		Materials.add(d, mk, 20)
	Progress.write(d)

# a brand-new player: the save file is deleted (the tips show again too)
static func fresh() -> void:
	var path := ProjectSettings.globalize_path(Progress.SAVE)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
