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
	_check_gear()
	_check_attend()
	_check_promotion()
	_check_repeat()
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


func _check_gear() -> void:
	# old saves still read: every item of an unlocked set is owned at Common
	var save := {"stage_unlocked": 12, "gear": {"equipped": {"Weapon": "scavenger_weapon"}, "levels": {"ion_weapon": 7}}}
	var g := GearData.read(save)
	_expect(g.equipped.Weapon == "scavenger_weapon", "equipped kept")
	_expect(GearData.level(g, "ion_weapon") == 7, "level kept")
	_expect(GearData.rarity(g, "ion_weapon") == "common", "old piece is Common")
	_expect(GearData.owned(g, "scavenger_helmet") and not GearData.owned(g, "void_helmet"), "set unlock = owned")
	_expect(GearData.level_cap("common") == 10 and GearData.level_cap("legendary") == GearData.MAX_LEVEL, "caps")
	# 3 copies of one rarity merge into 1 of the next, and raise the piece's rarity
	GearData.add_copy(g, "ion_weapon", "common")
	GearData.add_copy(g, "ion_weapon", "common")
	_expect(GearData.copies_of(g, "ion_weapon", "common") == 3, "3 commons held")
	_expect(GearData.can_merge(g, "ion_weapon", "common"), "can merge 3 commons")
	_expect(GearData.merge(g, "ion_weapon", "common") == "uncommon", "merge gives an Uncommon")
	_expect(GearData.copies_of(g, "ion_weapon", "common") == 0 and GearData.copies_of(g, "ion_weapon", "uncommon") == 1, "counts after merge")
	_expect(GearData.rarity(g, "ion_weapon") == "uncommon", "piece is now Uncommon")
	_expect(not GearData.can_merge(g, "ion_weapon", "uncommon"), "one uncommon cannot merge")
	# Quick Merge: Common and Uncommon stacks only
	for i in 9:
		GearData.add_copy(g, "ion_boots", "common")
	for i in 3:
		GearData.add_copy(g, "ion_chest", "rare")
	_expect(GearData.quick_merge_count(g) == 4, "quick merge count shown (%d)" % GearData.quick_merge_count(g))
	var made := GearData.quick_merge(g)
	_expect(GearData.copies_of(g, "ion_boots", "common") == 1 and GearData.copies_of(g, "ion_boots", "uncommon") == 0 and GearData.copies_of(g, "ion_boots", "rare") == 1, "quick merge chains 10 commons -> 3 uncommons -> 1 rare, 1 common left (%s)" % str(g.copies.get("ion_boots")))
	_expect(GearData.copies_of(g, "ion_chest", "rare") == 3, "quick merge leaves Rare alone")
	_expect(made == 4, "quick merge count (%d)" % made)
	# the save round-trips through JSON
	var back := GearData.read(JSON.parse_string(JSON.stringify({"gear": GearData.write(g), "stage_unlocked": 12})))
	_expect(GearData.rarity(back, "ion_weapon") == "uncommon" and GearData.copies_of(back, "ion_boots", "rare") == 1, "save round trip")
	# drops: the stage's own set, Common on early stages
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var sets := {}
	var rars := {}
	for i in 200:
		var d := GearData.roll_drop(3, rng)
		sets[GearData.ITEMS[d.id].set] = true
		rars[d.rarity] = true
	_expect(sets.size() == 1 and sets.has("ion"), "stage 3 drops Ion only")
	_expect(rars.size() == 1 and rars.has("common"), "stage 3 drops Common only (%s)" % str(rars.keys()))
	rars = {}
	for i in 400:
		rars[GearData.roll_drop(58, rng).rarity] = true
	_expect(rars.has("legendary") or rars.has("epic"), "late stages drop high rarities (%s)" % str(rars.keys()))
	# parts for the high levels keep growing but stay sane
	var n29 := Parts.need(29)
	_expect(int(n29.alloy) == 78 and int(n29.cell) == 14 and int(n29.core) == 7, "parts at Lv.29 (%s)" % str(n29))
	_expect(Parts.need(9) == {"alloy": 18, "cell": 4, "core": 2}, "parts at Lv.9 unchanged")
	# loadouts: three slots, apply restores gear, turrets and drone
	var s2 := {"stage_unlocked": 30, "pilot_xp": 99999, "gear": GearData.write(g), "turrets": {"loadout": ["sentry", "", "", ""]}, "drone": {"body": "scout", "pod": "blaster", "level": 3}}
	Loadouts.save_slot(s2, 0, "Boss kit")
	s2.gear.equipped.Weapon = "ion_weapon"
	s2.turrets.loadout = ["lance", "", "", ""]
	s2.drone.pod = "beam"
	Loadouts.save_slot(s2, 1, "")
	_expect(Loadouts.apply(s2, 0), "apply slot 0")
	_expect(GearData.read(s2).equipped.Weapon == "scavenger_weapon" and Turrets.read(s2).loadout[0] == "sentry" and DroneData.read(s2).pod == "blaster", "slot 0 restored")
	_expect(DroneData.read(s2).level == 3, "drone level is not part of a loadout")
	_expect(Loadouts.apply(s2, 1) and GearData.read(s2).equipped.Weapon == "ion_weapon" and Turrets.read(s2).loadout[0] == "lance", "slot 1 restored")
	_expect(not Loadouts.apply(s2, 2), "empty slot does nothing")
	_expect(Loadouts.active(s2) == 1, "active slot")
	_expect(Loadouts.read(s2)[0].name == "Boss kit" and Loadouts.read(s2)[1].name == "Loadout 2", "names")
	var s2j = JSON.parse_string(JSON.stringify(s2))
	_expect(Loadouts.read(s2j)[0].set and Loadouts.apply(s2j, 0), "loadouts survive the save file")
	# a drop or a Patrol gear copy is granted through Progress.grant like everything else
	var s3 := {"stage_unlocked": 12}
	Progress.grant(s3, {"gear": [{"id": "ion_helmet", "rarity": "uncommon"}]})
	_expect(GearData.copies_of(GearData.read(s3), "ion_helmet", "uncommon") == 1, "grant adds a copy")
	_expect(Progress.reward_text({"gear": [{"id": "ion_helmet", "rarity": "uncommon"}]}).contains("Ion Visor"), "reward text names the piece")
	_expect(Patrol.per_wave(24).has("gear"), "Patrol farms gear copies")

func _check_attend() -> void:
	# attendance: one claim a day, day advances, day 7 wraps to 1, missing a day keeps the week
	var d := {"coins": 0}
	var a := Progress.attend(d)
	_expect(a.day == 1 and a.claimable, "fresh save: day 1 to claim")
	var got := Progress.claim_attend(d)
	_expect(int(got.get("coins", 0)) == 100 and int(d.coins) == 100, "day 1 pays 100 coins")
	a = Progress.attend(d)
	_expect(a.day == 1 and a.claimed_today and not a.claimable and a.next == 2, "after the claim: day 1 shown as done, next is 2")
	_expect(Progress.claim_attend(d).is_empty(), "no second claim today")
	d.attend.last = Progress.today() - 3   # three days away
	_expect(Progress.attend(d).next == 2 and Progress.attend(d).claimable, "a gap keeps the week")
	d.attend = {"day": 7, "last": Progress.today() - 1}
	got = Progress.claim_attend(d)
	_expect(int(got.get("crystals", 0)) == 25 and int(d.attend.day) == 1, "day 7 is the big one and wraps to 1")
	# old saves: today's gift_day counts as claimed
	var old := {"gift_day": Progress.today()}
	_expect(not Progress.attend(old).claimable, "old gift_day counts as today's claim")
	# attention: dots follow claimable things
	var s := {"stage_unlocked": 12, "parts": {"alloy": 3}}
	var at := Progress.attention(s)
	_expect(at.store and at.gear and at.gear_ws[0] and not at.gear_ws[1] and not at.patrol, "attention: gift + parts merge (%s)" % str(at))
	s.attend = {"day": 2, "last": Progress.today()}
	s.parts = {}
	var g := GearData.read(s)
	for i in 3:
		GearData.add_copy(g, "ion_boots", "common")
	s.gear = GearData.write(g)
	at = Progress.attention(s)
	_expect(not at.store and at.gear and at.gear_ws[1], "attention: gear merge only (%s)" % str(at))

func _check_promotion() -> void:
	var s := {"pilot_xp": 0}
	_expect(Promotion.rank(s) == 0 and Promotion.rank_name(s) == "Rookie" and Promotion.next(s) == 0, "fresh save: no rank, Cadet next")
	_expect(not Promotion.unlocked(s, 4) and Promotion.unlocked(s, 5) and int(Promotion.RANKS[0].level) == 10, "Cadet trial: recommended Lv.10, opens at Lv.5 (dev168)")
	_expect(int(Promotion.RANKS[1].level) == 20 and Promotion.open_level(1) == 13, "Pilot trial: recommended Lv.20, opens at Lv.13")
	for i in Promotion.RANKS.size():
		var w := Promotion.waves(i)
		_expect(w.size() == Promotion.WAVES, "trial %d has %d waves" % [i, Promotion.WAVES])
		var boss_last := false
		var boss_count := 0
		for k in w.size():
			for spec in w[k]:
				if spec[0] == "hive_mother":
					boss_count += 1
					if k == w.size() - 1:
						boss_last = true
		_expect(boss_last, "trial %d ends with the boss" % i)
		_expect(boss_count <= 2, "trial %d: at most the mid-stage young mother plus the boss (%d)" % [i, boss_count])
	var w0: Array = Promotion.waves(0)
	var n5: Array = StageData.waves(int(Promotion.RANKS[0].stage))
	_expect(int(w0[0][0][1]) == int(ceil(int(n5[0][0][1]) * Promotion.count_mult(0))), "counts scaled by COUNT_MULT")
	# the mode hand-off: start sets it, take reads it once and clears it
	Promotion.start(s, 0)
	_expect(Promotion.take(s) == 0 and Promotion.take(s) == -1, "take() is one-shot")
	# a win promotes once; a replay does not
	_expect(Promotion.won(s, 0) and Promotion.rank(s) == 1, "first win promotes")
	_expect(not Promotion.won(s, 0) and Promotion.rank(s) == 1, "replay does not promote again")
	_expect(not Promotion.won(s, 5), "cannot skip ranks")
	# the bonus reaches battle through GearData.stats
	var base: float = GearData.stats({"promotion": 0}).damage
	var st := GearData.stats({"promotion": 4})
	_expect(absf(float(st.damage) / float(base) - 1.24) < 0.001 and absf(float(st.fortress) - 1.24) < 0.001, "4 ranks = +24% damage and fortress (6% a rank, dev167)")

func _check_repeat() -> void:
	var d := {"stats": {"kills": 400.0, "stages": 1.0}}
	var r := Progress.repeat(d)
	_expect(r[0].goal == 150 and r[0].done and r[0].lv == 1, "a fresh repeat quest counts the lifetime stat")
	_expect(not r[1].done, "3 stages not yet")
	d.repeat = {"r_kills": {"lv": 3, "base": 300.0}}
	r = Progress.repeat(d)
	_expect(r[0].goal == 350 and not r[0].done and absf(float(r[0].progress) - 100.0) < 0.01, "level 3: goal 350, progress from its base")
	_expect(int(Progress.repeat_reward(Progress.REPEAT[0], 1).coins) == 60 and int(Progress.repeat_reward(Progress.REPEAT[0], 5).coins) == 120, "reward grows with the level")
	_expect(Progress.attention({"stats": {"kills": 400.0}}).quests_tabs.size() == 4, "four quest tabs for the dots")

func _check_cards() -> void:
	for id in Cards.CARDS:
		if Cards.CARDS[id].has("turret"):
			_expect(ResourceLoader.exists("res://cards/pic_%s.png" % id), "turret card picture missing: " + id)
