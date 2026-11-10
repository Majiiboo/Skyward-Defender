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
	_check_unlocks()
	_check_heroes()
	_check_materials()
	_check_store()
	_check_turrets()
	_check_gates()
	_check_ascend()
	_check_goals()
	_check_daily()
	_check_codex()
	_check_wing()
	_check_events()
	_check_runs()
	_check_base()
	_check_talents()
	_check_scrap()
	_check_etrials()
	_check_mods()
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
				if StageData.is_boss(String(spec[0])):
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
	_expect(Progress.attention({"stats": {"kills": 400.0}}).quests_tabs.size() == 5, "five quest tabs for the dots (the fifth is the Collection)")

func _check_cards() -> void:
	for id in Cards.CARDS:
		if Cards.CARDS[id].has("turret"):
			_expect(ResourceLoader.exists("res://cards/pic_%s.png" % id) or ResourceLoader.exists(String(Cards.CARDS[id].get("pic", ""))), "turret card picture missing: " + id)
			_expect(Cards.OVERCHARGE.has(id), "turret card overcharge text: " + id)
			_expect(Turrets.TURRETS.has(String(Cards.CARDS[id].turret)), "turret card for a real turret: " + id)
	# hero cards (dev172): one per hero, only offered while he is on duty, three picks each
	for id in Heroes.ORDER:
		var found := ""
		for cid in Cards.CARDS:
			if String(Cards.CARDS[cid].get("hero", "")) == id:
				found = cid
		_expect(found != "" and int(Cards.CARDS[found].max) == 3 and Cards.OVERCHARGE.has(found), "hero %s has a 3-pick card with an overcharge" % id)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var seen_other := false
	for i in 40:
		for cid in Cards.draw({}, 3, rng, 99, true, [], "rook"):
			if Cards.CARDS[cid].has("hero"):
				_expect(String(Cards.CARDS[cid].hero) == "rook", "Rook on duty: only Rook's card shows (%s)" % cid)
				seen_other = true
	_expect(seen_other, "Rook's card does come up in 40 draws")
	for i in 40:
		for cid in Cards.draw({}, 3, rng, 99, true, [], ""):
			_expect(not Cards.CARDS[cid].has("hero"), "no hero on duty: no hero card (%s)" % cid)

# progressive disclosure (Unlocks, dev168): a new player sees little, systems open in order
func _check_unlocks() -> void:
	var s := {"pilot_xp": 0, "stage_unlocked": 1}
	for id in ["turrets", "patrol", "workshop", "repeat", "promotion", "drone", "elite", "loadouts"]:
		_expect(not Unlocks.open(s, id), "fresh save: %s hidden" % id)
	_expect(Unlocks.open(s, "nothing_like_this"), "unknown ids are always open")
	_expect(Unlocks.fresh(s).is_empty(), "fresh save: nothing to announce")
	s["stage_unlocked"] = 6
	_expect(Unlocks.open(s, "turrets") and not Unlocks.open(s, "patrol"), "stage 5 cleared: turrets open, patrol not yet")
	_expect(Unlocks.fresh(s) == ["ability", "auto", "turrets", "daily", "run", "repeat"], "stage 5 cleared: the ability, AUTO, turrets, the Daily Challenge, the Expedition and repeat quests to announce, table order (%s)" % str(Unlocks.fresh(s)))
	Unlocks.mark_seen(s, "turrets")
	Unlocks.mark_seen(s, "repeat")
	for nid in ["ability", "auto", "daily", "run"]:
		Unlocks.mark_seen(s, nid)
	_expect(Unlocks.fresh(s).is_empty(), "announced once")
	s["stage_unlocked"] = 7
	_expect(Unlocks.fresh(s) == ["patrol"], "stage 6 cleared: patrol next")
	var g := GearData.read(s)
	GearData.add_copy(g, "ion_weapon", "common")
	s["gear"] = GearData.write(g)
	_expect(Unlocks.open(s, "workshop"), "a spare copy opens the Workshop early")
	s["pilot_xp"] = Turrets.xp_for_level(8)
	_expect(Unlocks.open(s, "drone") and Unlocks.open(s, "promotion") and not Unlocks.open(s, "elite"), "Lv.8: drone and promotion, not elite")
	var old := {"pilot_xp": Turrets.xp_for_level(12), "stage_unlocked": 20}
	Unlocks.settle(old)
	_expect(Unlocks.fresh(old).is_empty(), "an old save takes what it has as seen")
	_expect(UIKit.tab_shown([0, 1, 2, 3], 2, [2, 3]) == 0 and UIKit.tab_shown([0, 1, 2, 3], 1, [2]) == 1, "hidden tab falls back to the first shown")

# heroes (dev172): roster, grades, buying, elements, levels, tiers, the old-save conversion
func _check_heroes() -> void:
	var s := {"coins": 3000, "crystals": 100, "stage_unlocked": 1, "pilot_xp": 0, "parts": {"alloy": 12}}
	var h := Heroes.read(s)
	_expect(Heroes.selected(h) == "rook" and Heroes.level(h, "rook") == 1 and Heroes.tier(h, "rook") == 1, "fresh save: Rook, Lv.1, tier 1")
	_expect(Heroes.owned(h, "rook") and not Heroes.owned(h, "sparks"), "fresh save: only Rook")
	_expect(Heroes.grade("rook") == 1 and Heroes.grade("nyx") == 4 and Heroes.stars_text("frost") == "★★", "grades: Rook 1 star, Frost 2, Nyx 4")
	_expect(Heroes.can_afford(s, "sparks") and not Heroes.can_afford(s, "frost"), "3000 coins + 12 alloy buys Sparks, not Frost")
	_expect(Heroes.unlock(s, h, "sparks", false) == "" and Heroes.owned(h, "sparks") and Heroes.selected(h) == "sparks", "buying Sparks puts him on duty")
	_expect(int(s.coins) == 500 and int(Parts.read(s).alloy) == 0, "Sparks cost 2500 coins and 12 alloy")
	_expect(Heroes.unlock(s, h, "sparks", false) == "Already yours", "cannot buy twice")
	_expect(Heroes.unlock(s, h, "nyx", true) == "Not enough crystals" and not Heroes.owned(h, "nyx"), "no stage gate on Nyx (Rudy: stars are earned, never stage-locked); 650 crystals needed")
	s["crystals"] = 700
	_expect(Heroes.unlock(s, h, "nyx", true) == "" and int(s.crystals) == 50 and Heroes.owned(h, "nyx"), "Nyx for 650 crystals")
	s["coins"] = 1000
	_expect(Heroes.level_up(s, h, "rook") and Heroes.level(h, "rook") == 2 and int(s.coins) == 1000 - Heroes.level_cost(1), "level up costs 60 + 30 x level")
	Heroes.add_shards(h, "rook", 35)
	_expect(Heroes.can_evolve(h, "rook") and Heroes.evolve(h, "rook") and Heroes.tier(h, "rook") == 2 and Heroes.shards(h, "rook") == 30, "5 shards = 2 stars (no save given: shards only)")
	h.shards["rook"] = 10
	_expect(not Heroes.can_evolve(h, "rook"), "3 stars needs 15 shards")
	s["hero"] = Heroes.write(h)
	var back := Heroes.read(s)
	_expect(Heroes.level(back, "rook") == 2 and Heroes.tier(back, "rook") == 2 and Heroes.owned(back, "nyx") and Heroes.selected(back) == "nyx", "write / read round trip")
	# elements: Fire is strong on Hive World (stages 1-10), Ice weak there; Energy neutral everywhere
	_expect(is_equal_approx(Heroes.element_mult("solar", 3), Heroes.WEAK_MULT) and is_equal_approx(Heroes.element_mult("frost", 3), Heroes.RESIST_MULT) and is_equal_approx(Heroes.element_mult("ion", 3), 1.0), "Hive World: Fire strong, Ice weak, Energy neutral")
	_expect(Heroes.hero_for_planet(15) == "sparks" and Heroes.hero_for_planet(5) == "ember", "shards drop for the planet's strong hero")
	for id in Heroes.ORDER:
		_expect(GearData.ITEMS.has(String(Heroes.ROSTER[id].weapon)) and GearData.SETS.has(String(Heroes.ROSTER[id].element)), "hero %s: weapon and element exist" % id)
	# stats: the keys battle reads are all there; Nyx (Legendary) hits harder than Rook
	var st := Heroes.stats(s)
	for k in ["damage", "fire_rate", "aim", "recovery", "hp", "def", "magnet", "auto_fire", "gem_xp", "coins", "weapon", "thruster", "crit_rate", "fortress", "element", "hero"]:
		_expect(st.has(k), "stats has %s" % k)
	_expect(String(st.hero) == "nyx" and String(st.element) == "nightmare" and float(st.crit_rate) > GearData.BASE_CRIT_RATE, "Nyx on duty: her element and passive")
	h.selected = "rook"
	s["hero"] = Heroes.write(h)
	var rst := Heroes.stats(s)
	_expect(float(st.damage) > float(rst.damage) * 1.05, "a Legendary out-hits a Common")
	s["coins"] = 500
	_expect(float(Heroes.stats(s).def) > 0.0, "DEF rises with the level (one track since dev186)")
	s["hero"] = Heroes.write(h)
	_expect(float(Heroes.stats(s).hp) >= Heroes.BASE_HP and Heroes.milestone_at(35).stat == "twin_shot" and Heroes.milestone_at(50).stat == "pierce1" and Heroes.milestone_at(60).stat == "burst2", "HP in the stats; perk milestones at 35, 50, 60")
	# old save: five armour pieces at Lv.6 each (5 x 1800 coins) and some spare copies -> Rook level + shards
	var old := {"stage_unlocked": 12, "gear": {"equipped": GearData.DEFAULT.duplicate(),
		"levels": {"ion_helmet": 6, "ion_chest": 6, "ion_gauntlets": 6, "ion_boots": 6, "ion_jetpack": 6, "ion_weapon": 4},
		"copies": {"ion_helmet": {"common": 4, "rare": 1}, "ion_weapon": {"common": 3}}}}
	var mh := Heroes.read(old)
	_expect(Heroes.level(mh, "rook") > 10, "old armour coins become Rook levels (got Lv.%d)" % Heroes.level(mh, "rook"))
	_expect(Heroes.tier(mh, "rook") == 1 and Heroes.shards(mh, "rook") == 12, "3 spare commons + 1 rare = 12 shards (got tier %d, %d shards)" % [Heroes.tier(mh, "rook"), Heroes.shards(mh, "rook")])
	var og := GearData.read(old)
	_expect(GearData.level(og, "ion_weapon") == 4 and int(og.copies["ion_weapon"]["common"]) == 3, "the weapon keeps its level and copies")
	var drop := GearData.roll_drop(7, RandomNumberGenerator.new())
	_expect(String(GearData.ITEMS[drop.id].slot) == "Weapon", "drops are weapons only")

# turrets and drones (dev172): bought by grade, elements, support pods
func _check_turrets() -> void:
	for id in Turrets.TURRETS:
		_expect(Heroes.ELEMENTS.has(Turrets.element(id)) and Turrets.role(id) != "" and Turrets.grade(id) >= 1, "turret %s: element, role, grade" % id)
	var s := {"coins": 5000, "crystals": 300, "stage_unlocked": 1, "pilot_xp": 0, "parts": {"alloy": 15}}
	var t := Turrets.read(s)
	_expect(Turrets.owned(t, "sentry") and not Turrets.owned(t, "lance"), "fresh save: Sentry only")
	_expect(Turrets.unlock(s, t, "lance", false) == "" and Turrets.owned(t, "lance") and int(s.coins) == 2000 and int(Parts.read(s).alloy) == 0, "Lance for 3000 coins + 15 alloy")
	_expect(Turrets.unlock(s, t, "prism", true) == "Not enough crystals" and not Turrets.owned(t, "prism"), "no stage gate on the Prism (stars are earned); 500 crystals needed")
	s["crystals"] = 600
	_expect(Turrets.unlock(s, t, "prism", true) == "" and int(s.crystals) == 600 - Turrets.crystal_price("prism"), "Prism for crystals")
	s["turrets"] = {"loadout": ["sentry", "lance", "", ""], "tracks": {}, "owned": t.owned}
	_expect(Turrets.owned(Turrets.read(s), "prism") and Turrets.owned(Turrets.read(s), "lance"), "owned list round trip")
	var old := {"pilot_xp": Turrets.xp_for_level(11), "turrets": {"loadout": ["sentry", "", "", ""], "levels": {"sentry": 3}}}
	var ot := Turrets.read(old)
	_expect(Turrets.owned(ot, "lance") and Turrets.owned(ot, "storm") and not Turrets.owned(ot, "gravity") and not Turrets.owned(ot, "tesla"), "an old save keeps the turrets its pilot level had (Lv.11: Sentry, Lance, Storm), never a round 2 turret")
	# round 2 (dev196): two turrets per element, Luna's pieces cut, firing heads for the first six
	var per_el := {}
	for id in Turrets.TURRETS:
		per_el[Turrets.element(id)] = int(per_el.get(Turrets.element(id), 0)) + 1
		for k in Turrets.REACH.get(id, []):
			_expect(Turrets.TURRETS[id].has(k), "turret %s: Range track key %s exists" % [id, k])
	for el in Heroes.ELEMENTS:
		_expect(int(per_el.get(el, 0)) == 2, "two turrets for %s (got %d)" % [el, int(per_el.get(el, 0))])
	for id in Turrets.ROUND2:
		for n in ["base", "head", "idle", "light"]:
			_expect(ResourceLoader.exists("res://turrets/%s_%s.png" % [id, n]), "turret %s: %s picture cut" % [id, n])
		_expect(ResourceLoader.exists("res://fx/shot_%s.png" % id), "turret %s: shot sprite" % id)
	for id in ["sentry", "lance", "storm", "gravity", "swarm", "prism"]:
		_expect(ResourceLoader.exists("res://turrets/%s_head_fire.png" % id) and ResourceLoader.exists("res://turrets/%s_fire_light.png" % id), "turret %s: firing head + its light" % id)
	var rs := Turrets.stats("repair", {"atk": 6, "rate": 1, "range": 1})
	_expect(is_equal_approx(float(rs.heal), 2.5 * Turrets.atk_mult(6) * Turrets.milestone_mult(6)) and is_zero_approx(float(rs.damage)), "Repair Node: ATK scales the mend, no damage")
	_expect(Turrets.parts_needed("beacon").has("ess_nightmare") and Turrets.cost_text("beacon").contains("Dark Ember"), "Dread Beacon asks for Dark Embers (materials in a turret price)")
	_expect(is_equal_approx(Turrets.element_mult("prism", 25), Heroes.WEAK_MULT) and is_equal_approx(Turrets.element_mult("lance", 25), Heroes.RESIST_MULT), "Magma World: Ice Prism strong, Fire Lance weak")
	_expect(DroneData.body_element("striker") == "solar" and DroneData.body_element("scout") == "ion" and Heroes.ELEMENTS.has(DroneData.body_element("warden")), "drone bodies have their own element")
	_expect(DroneData.pod_job("repair") == "repair" and DroneData.pod_job("blaster") == "attack" and DroneData.pod_art("magnet") == "magnet", "support pods: job and their own art")
	var ds := {"coins": 7000, "crystals": 0, "stage_unlocked": 11, "parts": {"alloy": 20, "cell": 4}}
	var dr := DroneData.read(ds)
	_expect(not DroneData.body_open(dr, "spark", 40) and DroneData.body_open(dr, "scout", 8), "Spark Bot is bought, not level-gated; Scout opens at Lv.8")
	_expect(DroneData.unlock(ds, dr, "spark", false) == "" and DroneData.body_open(dr, "spark", 1) and int(ds.coins) == 1000, "Spark Bot for 6000 coins + 20 alloy + 4 cells")
	ds["drone"] = {"body": "spark", "pod": "repair", "owned": dr.owned}
	_expect(DroneData.read(ds).body == "spark" and DroneData.body_open(DroneData.read(ds), "spark", 1), "owned bodies round trip")
	for b in ["spark", "wisp", "bat"]:
		for part in ["body_%s", "%s_hull", "%s_thruster_l", "%s_thruster_r", "%s_glow", "%s_portrait"]:
			_expect(ResourceLoader.exists("res://drone/" + (part % b) + ".png"), "drone %s: %s cut" % [b, part % b])
	_expect(ResourceLoader.exists("res://drone/pod_%s.png" % DroneData.pod_art("repair")), "the Repair pod has a picture to borrow")
	for hid in ["sparks", "frost", "hollow", "nyx", "ember"]:   # Luna's hero frames cut in (dev172, tools/cut_heroes.gd)
		for n in range(1, 6):
			_expect(ResourceLoader.exists("res://heroes/%s/turn_%d.png" % [hid, n]), "hero %s frame %d cut" % [hid, n])
		_expect(ResourceLoader.exists("res://heroes/%s/portrait.png" % hid), "hero %s portrait" % hid)

# element trials (dev172): ladders per element, hero of that element needed, rewards
func _check_etrials() -> void:
	var s := {"coins": 0, "stage_unlocked": 1, "pilot_xp": 0}
	_expect(Promotion.etrial_steps(s, "solar") == 0 and Promotion.etrial_why_not(s, "ion") == "", "fresh save: Energy ladder open (Rook), nothing cleared")
	_expect(Promotion.etrial_why_not(s, "solar") != "", "no Fire hero: Fire ladder locked")
	var h := Heroes.read(s)
	h.owned.append("ember")
	s["hero"] = Heroes.write(h)
	_expect(Promotion.etrial_why_not(s, "solar") == "" and Promotion.etrial_owned_hero(s, "solar") == "ember", "owning Ember opens the Fire ladder")
	Promotion.start_etrial(s, "solar", 0)
	_expect(Heroes.selected(Heroes.read(s)) == "ember", "starting the Fire ladder puts Ember on duty")
	var t := Promotion.take_etrial(s)
	_expect(t.el == "solar" and int(t.step) == 0 and Promotion.take_etrial(s).is_empty(), "take_etrial is one-shot")
	_expect(Promotion.etrial_waves(0).size() == StageData.waves(10).size() and Promotion.etrial_waves(4).size() == StageData.waves(50).size(), "steps use the boss stages 10..50")
	_expect(Promotion.etrial_won(s, "solar", 0) and Promotion.etrial_steps(s, "solar") == 1 and not Promotion.etrial_won(s, "solar", 0), "the first clear moves the ladder on, a replay does not")
	var r := Promotion.etrial_reward(0, true, "solar")
	_expect(int(r.coins) == 300 and int(r.shards.ember) == 10 and not r.has("crystals"), "step 1 first clear: 300 coins + 10 Ember shards")
	var r5 := Promotion.etrial_reward(4, true, "solar")
	_expect(int(r5.get("crystals", 0)) == Promotion.ETRIAL_CRYSTALS_LAST, "the last step pays crystals")
	_expect(int(Promotion.etrial_reward(0, false, "solar").coins) == 150 and not Promotion.etrial_reward(0, false, "solar").has("shards"), "a replay pays half the coins, no shards")
	Progress.grant(s, r)
	_expect(Heroes.shards(Heroes.read(s), "ember") == 10 and int(s.coins) == 300, "grant pays the shards and coins")

# trial advantages and disadvantages (dev172)
func _check_mods() -> void:
	_expect(Promotion.RANK_MODS.size() == Promotion.RANKS.size() and Promotion.ETRIAL_MODS.size() == Promotion.ETRIAL_STEPS, "every rank and every element step has its twists")
	for lst in Promotion.RANK_MODS + Promotion.ETRIAL_MODS:
		var good := 0
		var bad := 0
		for m in lst:
			_expect(Promotion.MODS.has(m), "unknown mod %s" % m)
			if Promotion.MODS.has(m):
				if Promotion.MODS[m].good:
					good += 1
				else:
					bad += 1
		_expect(good >= 1 and bad >= 1, "a trial has at least one advantage and one disadvantage (%s)" % str(lst))
	_expect(Promotion.mods_for(-1, {}).is_empty() and Promotion.mods_for(0, {}) == ["rapid", "no_turrets"] and Promotion.mods_for(-1, {"el": "ion", "step": 2}) == ["sharpshooter", "swift_bugs"], "mods_for picks the right list")
	_expect(Promotion.mods_short(["rapid", "no_turrets"]).begins_with("+ Rapid fire") and Promotion.mods_lines(["no_turrets"])[0].begins_with("DISADVANTAGE"), "short and long texts")

# materials and the Craft tab (materials.gd, dev189)
func _check_materials() -> void:
	var s := {"coins": 5000, "parts": {"alloy": 30, "cell": 10, "core": 2}}
	var r := Materials.recipe("barrel")
	_expect(Materials.can_craft(s, r), "10 alloy + 200 coins crafts a barrel")
	_expect(Materials.craft(s, r) == "" and int(Materials.read(s).barrel) == 1 and int(Parts.read(s).alloy) == 20 and int(s.coins) == 4800, "barrel crafted, alloy and coins paid")
	Materials.craft(s, r)
	Materials.craft(s, r)
	_expect(Materials.craft(s, Materials.recipe("lens")) == "" and int(Materials.read(s).lens) == 1 and int(Materials.read(s).barrel) == 0, "3 barrels -> 1 lens")
	_expect(Materials.craft(s, Materials.recipe("essence"), "solar") == "" and int(Materials.read(s).ess_solar) == 1, "an essence of the picked element")
	_expect(Materials.craft(s, Materials.recipe("essence"), "solar") != "" and int(Materials.read(s).ess_solar) == 1, "a second essence: cores short")
	_expect(Parts.text({"alloy": 3, "barrel": 2, "ess_void": 1}) == "3 Alloy, 1 Void Fragment, 2 Scrap Barrel", "a price text lists materials: " + Parts.text({"alloy": 3, "barrel": 2, "ess_void": 1}))
	Progress.grant(s, {"materials": {"rotor": 2}, "gyro": 1})
	_expect(int(Materials.read(s).rotor) == 2 and int(Materials.read(s).gyro) == 1, "rewards grant materials, as a block or at the top level")
	_expect(int(s.parts.get("alloy", 0)) == 0 and not s.parts.has("rotor") and not s.parts.has("gyro"), "materials never land in the parts block")
	_expect(Materials.weapon_need(14, "solar").is_empty() and Materials.weapon_need(25, "solar").has("ess_solar"), "weapon levels ask for the line from Lv.15 and an essence from 25")
	var h := Heroes.read(s)
	h.shards["rook"] = 30
	_expect(Heroes.why_not_evolve(h, "rook", s) == "Pilot Lv.5 first", "2 stars: the pilot-level door first (got %s)" % Heroes.why_not_evolve(h, "rook", s))
	s["pilot_xp"] = Turrets.xp_for_level(5)
	_expect(Heroes.why_not_evolve(h, "rook", s) == "Lv.10 first", "then the level cap (got %s)" % Heroes.why_not_evolve(h, "rook", s))
	h.levels["rook"] = 10
	_expect(Heroes.why_not_evolve(h, "rook", s) == "Short of 2 Energy Spark", "then the essences (got %s)" % Heroes.why_not_evolve(h, "rook", s))
	Materials.add(s, "ess_ion", 2)
	s["coins"] = 1999
	_expect(Heroes.why_not_evolve(h, "rook", s) == "2000 coins needed" and not Heroes.can_evolve(h, "rook", s), "then the coins (got %s)" % Heroes.why_not_evolve(h, "rook", s))
	s["coins"] = 2000
	_expect(Heroes.evolve(h, "rook", s) and Heroes.tier(h, "rook") == 2 and int(Materials.read(s).ess_ion) == 0 and int(s.coins) == 0 and Heroes.shards(h, "rook") == 25 and Heroes.level_cap(h, "rook") == 20, "2 stars: pays 5 shards, the sparks and the coins; the cap is Lv.20 now")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	_expect(int(Materials.stage_drop(30, false, rng).get("ess_frost", 0)) == 1 and int(Materials.stage_drop(30, true, rng).get("ess_frost", 0)) == 2, "stage 30 (Magma, weak to Ice) drops a Frost Core, two in Elite")
	_expect(Materials.horde_drop(23) == {"barrel": 2, "rotor": 2, "key_u": 2} and Materials.horde_drop(7).is_empty(), "Horde: a barrel, a rotor and a key per 10 waves")

# Store 2.0 (store.gd, dev189): key chests, free opens, pity, packs
func _check_store() -> void:
	var STORE = load("res://store.gd")
	var s := {"coins": 0, "crystals": 50, "selected_stage": 12, "stage_unlocked": 13}
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_expect(STORE.free_left_s(s, "chest_u", STORE.DAY_S) == 0, "a fresh save has the free Uncommon open ready")
	var r1: Dictionary = STORE.chest_open_in(s, "u", "free", rng)
	_expect(not r1.has("why") and STORE.free_left_s(s, "chest_u", STORE.DAY_S) > 0, "the free open works once, then waits a day")
	_expect(STORE.chest_open_in(s, "u", "free", rng).has("why"), "no second free open today")
	_expect(STORE.chest_open_in(s, "u", "key", rng).has("why"), "no key, no key open")
	Materials.add(s, "key_u", 2)
	var r2: Dictionary = STORE.chest_open_in(s, "u", "key", rng)
	_expect(not r2.has("why") and int(Materials.read(s).key_u) == 1, "a key opens the chest and is spent")
	_expect(STORE.chest_open_in(s, "u", "crystals", rng).has("why") == false and int(s.crystals) == 10, "40 crystals open it too")
	_expect(STORE.chest_open_in(s, "l", "crystals", rng).has("why"), "the Legendary chest needs 300 crystals")
	_expect(STORE.chest_open_in(s, "l", "free", rng).has("why"), "the Legendary chest has no free open")
	# pity: the 10th Uncommon open is the Epic item
	Materials.add(s, "key_u", 20)
	var pity_seen := false
	var opened: int = STORE.opens_of(s, "u")
	while opened < 10:
		var r: Dictionary = STORE.chest_open_in(s, "u", "key", rng)
		opened += 1
		if opened == 10:
			pity_seen = bool(r.get("pity", false)) and r.has("gear") and r.gear[0].rarity == "epic" and r.has("ess_scavenger")
	_expect(pity_seen, "the 10th Uncommon open is the pity item: a Core, an Arc Charge (stage 12 is weak to Electric) and an Epic gear copy")
	_expect(STORE.claim_pack_in(s, STORE.PACKS_FREE[0]) == "" and int(Materials.read(s).key_u) >= 1 and STORE.claim_pack_in(s, STORE.PACKS_FREE[0]) == "Not ready", "the daily pack's free part claims once a day")
	_expect(STORE.odds_text(STORE.KEY_CHESTS["u"]).begins_with("45% 600 coins"), "odds text: " + STORE.odds_text(STORE.KEY_CHESTS["u"]))


# stars (Rudy, 2026-11-06, DESIGN-stars.md): earned by levelling and collecting, never stage-locked;
# gold 1-5 then red 1-5; pilot level only opens the door; premium = crystals only
func _check_gates() -> void:
	_expect(Gates.MAX_STAR == 10 and Gates.gold(7) == 5 and Gates.red(7) == 2 and not Gates.is_red(5) and Gates.is_red(6), "stars: 1-5 gold, 6-10 red")
	_expect(Gates.text(3) == "★★★" and Gates.text(7) == "★★" and Gates.badge(7) == "R★★" and Gates.long_text(1) == "1 star" and Gates.long_text(8) == "red 3", "star texts")
	_expect(is_equal_approx(Gates.power_mult(1), 1.0) and is_equal_approx(Gates.power_mult(5), 1.32) and is_equal_approx(Gates.power_mult(10), 1.92), "power: +8% a gold star, +12% a red one")
	_expect(Gates.level_cap("hero", 1) == 10 and Gates.level_cap("hero", 5) == 50 and Gates.level_cap("hero", 10) == 100 and Gates.level_cap("turret", 5) == 20 and Gates.level_cap("turret", 10) == 40 and Gates.level_cap("drone", 5) == 10 and Gates.level_cap("drone", 10) == 20, "level caps: 10 / 4 / 2 a star")
	_expect(Heroes.MAX_LEVEL == 100 and Turrets.MAX_TRACK == 40 and DroneData.MAX_LEVEL == 20, "the track maxima match red 5")
	_expect(Gates.door(2) == 5 and Gates.door(5) == 28 and Gates.door(6) == 35 and Gates.door(10) == 55, "pilot-level doors: money buys speed, play buys the ceiling")
	var n2 := Gates.need("hero", 2, "solar")
	_expect(int(n2.coins) == 2000 and int(n2.shards) == 5 and int(n2.mats.get("ess_solar", 0)) == 2 and not n2.mats.has("coil"), "2 stars: 5 shards + 2 Solar Flare + 2,000 coins")
	var n5 := Gates.need("hero", 5, "ion")
	_expect(int(n5.shards) == 100 and int(n5.mats.get("coil", 0)) == 1 and int(n5.coins) == 40000, "5 stars: 100 shards + 20 essences + a Prime Coil + 40,000")
	var n10 := Gates.need("hero", 10, "ion")
	_expect(int(n10.shards) == 500 and int(n10.mats.get("ess_ion", 0)) == 80 and int(n10.mats.get("coil", 0)) == 6, "red 5: 500 shards + 80 essences + 6 coils")
	_expect(Gates.need_text(n2) == "5 shards + 2 Solar Flare + 2000 coins", "need text: " + Gates.need_text(n2))
	_expect(Gates.need("drone", 2, "ion").mats.has("rotor") and Gates.need("drone", 3, "ion").mats.has("gyro") and Gates.need("drone", 4, "ion").mats.has("flightcore") and not Gates.need("turret", 2, "ion").mats.has("rotor"), "the drone line for drone stars, nothing of it for turrets")
	_expect(Heroes.gate("nyx") == 0 and Heroes.gate_open({"stage_unlocked": 1}, "ember") and Turrets.gate("prism") == 0 and DroneData.gate("bat") == 0, "no stage gates anywhere")
	# a hero: the level cap holds at Lv.10 until 2 stars
	var s := {"stage_unlocked": 1, "pilot_xp": 0, "coins": 100000}
	var h := Heroes.read(s)
	for i in 25:
		Heroes.level_up(s, h, "rook")
	_expect(Heroes.level(h, "rook") == 10, "1 star: Rook stops at Lv.10 (got %d)" % Heroes.level(h, "rook"))
	# a turret: every track at the cap, then essences and coins
	var ts := {"pilot_xp": Turrets.xp_for_level(5), "coins": 5000, "materials": {"ess_ion": 2}}
	var t := Turrets.read(ts)
	_expect(Turrets.star(t, "sentry") == 1 and Turrets.track_cap(1) == 4, "a fresh Sentry: 1 star, tracks capped at 4")
	_expect(Turrets.why_not_star(ts, t, "sentry") == "Lv.4 first", "the tracks must reach the cap first (got %s)" % Turrets.why_not_star(ts, t, "sentry"))
	t.tracks["sentry"] = {"atk": 4, "rate": 4, "range": 3}
	_expect(Turrets.why_not_star(ts, t, "sentry") == "Lv.4 first", "every track, the lowest counts (got %s)" % Turrets.why_not_star(ts, t, "sentry"))
	t.tracks["sentry"] = {"atk": 4, "rate": 4, "range": 4}
	_expect(Turrets.star_up(ts, t, "sentry") == "" and Turrets.star(t, "sentry") == 2 and int(ts.coins) == 3500 and int(Materials.read(ts).ess_ion) == 0, "Sentry to 2 stars: 2 Energy Sparks + 1,500 coins")
	_expect(Turrets.track_cap(2) == 8 and is_equal_approx(float(Turrets.stats("sentry", t.tracks["sentry"], 2).damage), float(Turrets.stats("sentry", t.tracks["sentry"], 1).damage) * 1.08), "2 stars: tracks to 8, damage +8%")
	ts["turrets"] = {"loadout": ["sentry", "", "", ""], "tracks": t.tracks, "owned": t.owned, "stars": t.stars}
	_expect(Turrets.star(Turrets.read(ts), "sentry") == 2, "turret stars round trip")
	# a drone body: level at the cap, essences, rotors, coins
	var ds := {"pilot_xp": Turrets.xp_for_level(5), "coins": 5000, "materials": {"ess_ion": 2, "rotor": 2}, "drone": {"body": "scout", "pod": "blaster", "level": 1}}
	var dr := DroneData.read(ds)
	_expect(DroneData.star(dr) == 1 and DroneData.level_cap(dr) == 2 and DroneData.why_not_star(ds, dr) == "Lv.2 first", "a fresh Scout: 1 star, cap Lv.2 (got %s)" % DroneData.why_not_star(ds, dr))
	dr.level = 2
	_expect(DroneData.star_up(ds, dr) == "" and DroneData.star(dr) == 2 and DroneData.level_cap(dr) == 4 and int(Materials.read(ds).rotor) == 0 and int(ds.coins) == 3500 and is_equal_approx(DroneData.star_mult(dr), 1.08), "Scout to 2 stars: 2 sparks + 2 rotors + 1,500 coins; cap Lv.4, +8%")
	ds["drone"] = dr
	_expect(DroneData.star(DroneData.read(ds), "scout") == 2 and DroneData.star(DroneData.read(ds), "wisp") == 1, "drone stars round trip, per body")
	# premium stays: crystals only
	_expect(Heroes.premium("ember") and not Heroes.premium("nyx") and Heroes.cost_text("ember") == "Crystals only" and not Heroes.can_afford({"coins": 999999, "parts": {"alloy": 99, "cell": 99, "core": 99}, "materials": {"ess_solar": 9}}, "ember"), "Ember is premium: crystals only")
	var ps := {"stage_unlocked": 1, "coins": 999999, "crystals": 700, "parts": {"alloy": 99, "cell": 99, "core": 99}, "materials": {"ess_solar": 9}}
	var ph := Heroes.read(ps)
	_expect(Heroes.unlock(ps, ph, "ember", false) == "Crystals only" and Heroes.unlock(ps, ph, "ember", true) == "" and Heroes.owned(ph, "ember") and int(ps.crystals) == 50 and Heroes.tier(ph, "ember") == 4, "Ember: coins refused, 650 crystals accepted, arrives Epic (her start step)")

# the pilot talent map (Talents, queue 16 e, dev197)
func _check_talents() -> void:
	_expect(Talents.count({}) == 0 and Talents.next({}) == 1 and Talents.SIZE == 40, "a fresh save: no nodes, node 1 next")
	_expect(String(Talents.node(10).card) == "focus_fire" and String(Talents.node(40).card) == "mirror_shell" and String(Talents.node(5).card) == "", "cards at nodes 10 and 40")
	_expect(int(Talents.cost(1).coins) == 330 and Talents.cost(1).mats.is_empty() and int(Talents.cost(15).mats.get("core", 0)) == 2 and Talents.cost(25).mats.has("ess_ion") and Talents.cost(29).mats.has("ess_nightmare") and int(Talents.cost(35).mats.get("coil", 0)) == 2, "costs: coins, then cores, essences, coils (node 25 asks for %s)" % Parts.text(Talents.cost(25).mats))
	_expect(Talents.door(7) == 7 and Talents.text(1) == "Bolt damage +1.5%" and Talents.text(10).contains("Focus Fire"), "doors and texts: " + Talents.text(10))
	var s := {"pilot_xp": 0, "coins": 0}
	_expect(Talents.why_not(s) == "330 coins needed", "node 1: coins first (got %s)" % Talents.why_not(s))
	s["coins"] = 330
	_expect(Talents.buy(s) == "" and Talents.count(s) == 1 and int(s.coins) == 0, "node 1 bought")
	_expect(Talents.why_not(s) == "Pilot Lv.2 first", "node 2 waits for pilot level 2 (got %s)" % Talents.why_not(s))
	s["pilot_xp"] = Turrets.xp_for_level(3)
	s["coins"] = 100000
	_expect(Talents.buy(s) == "" and Talents.buy(s) == "" and Talents.count(s) == 3 and Talents.why_not(s) == "Pilot Lv.4 first", "nodes 2 and 3 at pilot level 3, node 4 waits")
	var b := Talents.bonus(s)
	_expect(is_equal_approx(float(b.damage), 1.015) and is_equal_approx(float(b.turret_dmg), 1.02) and is_equal_approx(float(b.hp_mult), 0.02), "three nodes: ATK +1.5%, turret +2%, HP +2%")
	var st0 := Heroes.stats({"pilot_xp": 0})
	var st3 := Heroes.stats(s)
	_expect(is_equal_approx(float(st3.damage), float(st0.damage) * 1.015) and is_equal_approx(float(st3.turret_dmg), float(st0.turret_dmg) * 1.02), "the hero stats carry the talents")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_expect(not Cards.draw({}, 99, rng, 99, true, [], "rook", 0).has("focus_fire") and Cards.draw({}, 99, rng, 99, true, [], "rook", 10).has("focus_fire") and not Cards.draw({}, 99, rng, 99, true, [], "rook", 10).has("salvage") and Cards.draw({}, 99, rng, 99, true, [], "rook", 40).has("mirror_shell"), "talent cards are offered only once their node is bought")
	for id in Talents.CARD_AT.values():
		_expect(Cards.CARDS.has(id) and Cards.OVERCHARGE.has(id) and ResourceLoader.exists(String(Cards.CARDS[id].pic)), "talent card %s: card, overcharge text, picture" % id)
	_expect(Talents.cards(s).is_empty() and Talents.cards({"talents": 20}) == ["focus_fire", "salvage"], "cards unlocked so far")

# the Scrap Belt family (Luna, dev198; queue 17 b): machines join from stage 11, the Wrecker and
# the Salvage Queen are planet 2's bosses, every piece is cut
func _check_scrap() -> void:
	for id in StageData.SCRAP:
		_expect(StageData.ENEMIES.has(id) and String(StageData.ENEMIES[id].get("family", "")) == "scrap", "machine %s in the enemy table" % id)
		_expect(ResourceLoader.exists("res://enemies/scrap/%s_whole.png" % id) and EnemyRig.is_machine(id), "machine %s: whole picture + rig entry" % id)
	for id in ["mite", "hulk", "rivet", "dart", "queen"]:
		_expect(ResourceLoader.exists("res://enemies/parts/%s_chunk_0.png" % id), "machine %s: death chunks" % id)
	_expect(StageData.is_boss("queen") and StageData.is_boss("wrecker") and StageData.is_boss("hive_mother") and not StageData.is_boss("mite"), "bosses by trait")
	_expect(StageData.boss_id(15, true) == "wrecker" and StageData.boss_id(20, false) == "queen" and StageData.boss_id(10, false) == "hive_mother" and StageData.boss_id(25, true) == "hive_mother", "planet 2: the Wrecker at 15, the Queen at 20; the Hive Mother elsewhere")
	_expect(is_zero_approx(StageData.machine_share(10)) and StageData.machine_share(11) > 0.3 and StageData.machine_share(20) > 0.55 and is_equal_approx(StageData.machine_share(40), 0.45), "machine share: none before planet 2, growing over it, near half after")
	var kinds := func(stage: int) -> Array:
		var out: Array = []
		for w in StageData.waves(stage):
			for spec in w:
				if not out.has(spec[0]):
					out.append(spec[0])
		return out
	var k5: Array = kinds.call(5)
	var k11: Array = kinds.call(11)
	var k15: Array = kinds.call(15)
	var k20: Array = kinds.call(20)
	_expect(not k5.has("mite") and k5.has("hive_mother"), "stage 5: bugs only, the Hive Mother")
	_expect(k11.has("mite") and k11.has("scout") and k11.has("hulk") and not k11.has("rivet") and not k11.has("dart"), "stage 11: Mites and Hulks beside the bugs, no Rivet Gun or Dart yet (got %s)" % str(k11))
	_expect(k15.has("rivet") and k15.has("wrecker") and not k15.has("hive_mother") and k15.has("dart") and not kinds.call(14).has("dart"), "stage 15: Rivet Guns, the first Darts, the Wrecker as the mini-boss (got %s)" % str(k15))
	_expect(k20.has("dart") and k20.has("queen") and k20.has("scout"), "stage 20: Darts, the Queen, the bugs still there (got %s)" % str(k20))
	_expect(ResourceLoader.exists("res://ui/commander_urgent.png") and ResourceLoader.exists("res://ui/commander_calm.png"), "the commander portraits")

# ASCEND (2026-11-10): the star ladder read as rarities; a rarer hero starts higher; the named
# steps unlock power-ups (passive x1.5 / x2 / x3, a free refresh, the hero card in hand)
func _check_ascend() -> void:
	_expect(Gates.step_name(1) == "Common" and Gates.step_name(5) == "Legendary" and Gates.step_name(6) == "Mythic I" and Gates.step_name(10) == "Mythic V", "step names: Common .. Legendary, Mythic I-V")
	var s := {"coins": 0, "crystals": 0, "pilot_xp": 0, "hero": {"selected": "rook", "owned": ["rook", "frost", "hollow", "nyx"], "levels": {}, "def": {}, "tiers": {}, "shards": {}}}
	var h := Heroes.read(s)
	_expect(Heroes.tier(h, "rook") == 1 and Heroes.tier(h, "frost") == 2 and Heroes.tier(h, "hollow") == 3 and Heroes.tier(h, "nyx") == 4, "start steps: Rook Common, Frost Uncommon, Hollow Rare, Nyx Epic")
	_expect(Heroes.level_cap(h, "frost") == 20 and Heroes.level_cap(h, "rook") == 10, "a rarer hero starts with a higher level cap")
	var st := Heroes.stats(s)
	_expect(is_equal_approx(float(st.gem_xp), 1.15) and int(st.refreshes) == 0 and not bool(st.start_card), "Common Rook: Gem XP +15%, no step power-ups yet")
	h.tiers["rook"] = 2
	s["hero"] = Heroes.write(h)
	_expect(is_equal_approx(float(Heroes.stats(s).gem_xp), 1.225), "Uncommon: passive x1.5 (Gem XP +22%)")
	h.tiers["rook"] = 3
	s["hero"] = Heroes.write(h)
	_expect(int(Heroes.stats(s).refreshes) == 1 and not bool(Heroes.stats(s).start_card), "Rare: +1 free refresh")
	h.tiers["rook"] = 5
	s["hero"] = Heroes.write(h)
	st = Heroes.stats(s)
	_expect(bool(st.start_card) and is_equal_approx(float(st.gem_xp), 1.3), "Legendary: hero card in hand, passive x2")
	h.tiers["rook"] = 10
	s["hero"] = Heroes.write(h)
	_expect(is_equal_approx(float(Heroes.stats(s).gem_xp), 1.45), "Mythic V: passive x3")
	h.selected = "hollow"
	s["hero"] = Heroes.write(h)
	st = Heroes.stats(s)
	_expect(int(st.pierce_every) == 4 and int(st.refreshes) == 1, "Hollow starts Rare: every 4th bolt pierces, a free refresh")
	_expect(Heroes.passive_text("hollow", 3) == "Every 4th bolt pierces" and Heroes.passive_text("frost", 2) == "Shots chill 20%" and Heroes.passive_text("nyx", 10) == "Crit rate +15%", "passive texts by step")
	_expect(Cards.hero_card("nyx") == "nyx_mark" and Cards.hero_card("nobody") == "", "every hero has his card")
	# ascending Frost once takes him from Uncommon to Rare, and the save keeps the count of steps
	h.shards["frost"] = 100
	_expect(Heroes.evolve(h, "frost") and Heroes.tier(h, "frost") == 3 and Heroes.ascends(h, "frost") == 2, "Frost ascends Uncommon -> Rare")
	h.tiers["nyx"] = 9
	_expect(Heroes.tier(h, "nyx") == 10 and not Heroes.can_evolve(h, "nyx"), "the ladder ends at Mythic V for everyone")

# the next goal on Home, the daily stage twists, hero abilities (2026-11-10)
func _check_goals() -> void:
	_expect(Goals.stage_goal(1).text == "Clear stage 2: your hero's ability" and Goals.stage_goal(3).text == "Clear stage 3: the AUTO pilot", "stage goals: the ability at 2, AUTO at 3 (%s)" % Goals.stage_goal(1).text)
	_expect(String(Goals.stage_goal(4).text).begins_with("Clear stage 5: The Base") and String(Goals.stage_goal(4).text).contains("base slot 1"), "stage 5 opens the Base and its first slot (%s)" % Goals.stage_goal(4).text)
	_expect(String(Goals.stage_goal(9).text).contains(String(StageData.AREAS[1].name)), "stage 10 opens the next planet (%s)" % Goals.stage_goal(9).text)
	var far := {"coins": 0, "stage_unlocked": 4, "pilot_xp": 0, "store_free": {"chest_u": 9999999999, "chest_e": 9999999999, "pack_daily": 9999999999, "pack_weekly": 9999999999, "pack_monthly": 9999999999}}
	_expect(String(Goals.next(far).text).begins_with("Clear stage 5"), "nothing to do now: the next stage unlock (%s)" % Goals.next(far).text)
	far["coins"] = 500
	_expect(Goals.next(far).text == "Level up Rook" and Goals.next(far).go[0] == "NavGear", "coins for a level: Level up Rook")
	far.erase("store_free")
	_expect(Goals.next(far).text == "A free chest is waiting", "a free chest comes before a level")
	# twists: none on planet 1 or on boss stages, a good + bad pair elsewhere, the same all day, different stages differ somewhere
	_expect(Promotion.stage_twist(5, 100).is_empty() and Promotion.stage_twist(20, 100).is_empty(), "no twist before stage 11 or on a boss stage")
	var tw := Promotion.stage_twist(12, 100)
	_expect(tw.size() == 2 and bool(Promotion.MODS[tw[0]].good) and not bool(Promotion.MODS[tw[1]].good) and tw == Promotion.stage_twist(12, 100), "a twist is one advantage + one disadvantage, fixed for the day")
	var seen := {}
	for d in 30:
		seen[str(Promotion.stage_twist(12, 100 + d))] = true
	_expect(seen.size() >= 6, "the pair changes from day to day (%d different in 30 days)" % seen.size())
	for id in Heroes.ORDER:
		_expect(Heroes.ABILITIES.has(id) and String(Heroes.ABILITIES[id].name) != "", "hero %s has an ability" % id)
	_expect(is_equal_approx(Heroes.ability_cd(1), 40.0) and is_equal_approx(Heroes.ability_cd(5), 32.0) and is_equal_approx(Heroes.ability_cd(10), 22.0), "the ability cooldown: 40 s, 2 s less a step")

# the Daily Challenge (2026-11-10): three twists that change with the date, one reward a day
func _check_daily() -> void:
	var s := {"stage_unlocked": 5, "coins": 0}
	_expect(not Promotion.daily_open(s), "the Daily Challenge is closed until stage 5 is cleared")
	s["stage_unlocked"] = 13
	_expect(Promotion.daily_open(s) and Promotion.daily_stage(s) == 12, "it is fought on your best cleared stage")
	s["stage_unlocked"] = 11
	_expect(Promotion.daily_stage(s) == 9, "never on a boss stage (10 cleared -> stage 9)")
	var kinds := {}
	for d in 40:
		var m := Promotion.daily_mods(500 + d)
		_expect(m.size() == 3 and bool(Promotion.MODS[m[0]].good) and not bool(Promotion.MODS[m[1]].good) and not bool(Promotion.MODS[m[2]].good) and m[1] != m[2], "day %d: one advantage, two different disadvantages (%s)" % [d, str(m)])
		kinds[str(m)] = true
	_expect(kinds.size() >= 10, "the three twists change from day to day (%d different in 40 days)" % kinds.size())
	_expect(not Promotion.daily_done(s) and Promotion.daily_won(s) and Promotion.daily_done(s) and not Promotion.daily_won(s), "the reward is once a day")
	_expect(int(Promotion.daily_reward(s).key_u) == 1 and int(Promotion.daily_reward(s).coins) == 200 + 30 * 9, "the reward: coins by stage, 10 crystals, an Uncommon key")

# the collection book (Codex, 2026-11-10): four categories, a crystal reward per quarter filled
func _check_codex() -> void:
	var s := {"crystals": 0, "stage_unlocked": 1}
	for cat in Codex.CATS:
		var es := Codex.entries(s, String(cat))
		_expect(es.size() >= 6, "the %s page has entries (%d)" % [cat, es.size()])
		for e in es:
			_expect(e.tex != null and String(e.name) != "", "%s / %s has a picture and a name" % [cat, e.id])
	_expect(Codex.count(s, "heroes")[0] == 1 and Codex.count(s, "heroes")[1] == Heroes.ORDER.size(), "a fresh save owns one hero of six")
	_expect(not Codex.claimable(s), "a fresh save has no collection reward waiting")
	s["hero"] = {"selected": "rook", "owned": ["rook", "sparks"], "levels": {}, "def": {}, "tiers": {}, "shards": {}}
	_expect(Codex.reached(s, "heroes") == 1 and Codex.claimable(s, "heroes") and Codex.next_goal(s, "heroes").need == 2, "two heroes of six: the first quarter is reached")
	_expect(Codex.claim(s, "heroes") == 10 and int(s.crystals) == 10 and not Codex.claimable(s, "heroes") and Codex.claim(s, "heroes") == 0, "the reward pays 10 crystals, once")
	_expect(Codex.next_goal(s, "heroes").need == 3 and Codex.next_goal(s, "heroes").crystals == 15, "next: three heroes for 15 crystals")
	_expect(Codex.note_card(s, "heavy_bolts") and not Codex.note_card(s, "heavy_bolts") and not Codex.note_card(s, "no_such_card") and Codex.count(s, "cards")[0] == 1, "a card goes into the book the first time it is picked")
	s["seen_enemies"] = ["scout", "drifter", "spitter", "runner"]
	_expect(Codex.count(s, "enemies")[0] == 3, "enemies met count; the runner tip is not an entry")
	_expect(Progress.attention(s).quests_tabs.size() == 5 and Progress.attention(s).quests_tabs[4] == Codex.claimable(s), "the Collection tab carries its own red dot")

# the wingmate (2026-11-10): a second owned hero lends half his passive
func _check_wing() -> void:
	var s := {"pilot_xp": 0, "hero": {"selected": "rook", "owned": ["rook", "nyx", "hollow"], "levels": {}, "def": {}, "tiers": {}, "shards": {}}}
	var h := Heroes.read(s)
	_expect(Heroes.wing(h) == "" and Heroes.wing_choices(h) == ["hollow", "nyx"], "no wingmate at first; the owned heroes not on duty can ride along (%s)" % str(Heroes.wing_choices(h)))
	var base_crit := float(Heroes.stats(s).crit_rate)
	h["wing"] = Heroes.wing_next(h)
	_expect(Heroes.wing(h) == "hollow", "tap: the first choice")
	h["wing"] = Heroes.wing_next(h)
	s["hero"] = Heroes.write(h)
	var st := Heroes.stats(s)
	_expect(String(st.wing) == "nyx" and is_equal_approx(float(st.crit_rate) - base_crit, 0.05 * Heroes.passive_mult(4) * 0.5), "Nyx as wingmate: half her crit passive (+%.3f)" % (float(st.crit_rate) - base_crit))
	_expect(is_equal_approx(float(st.gem_xp), 1.15), "Rook keeps his own passive whole")
	h = Heroes.read(s)
	h["wing"] = Heroes.wing_next(h)
	_expect(Heroes.wing(h) == "", "tap again after the last one: nobody")
	h["wing"] = "hollow"
	s["hero"] = Heroes.write(h)
	_expect(int(Heroes.stats(s).pierce_every) == Heroes.pierce_every(3) * 2, "Hollow as wingmate: his piercing bolt half as often")
	h.selected = "hollow"
	_expect(Heroes.wing(h) == "", "the hero on duty cannot be his own wingmate")
	h["wing"] = "ember"
	_expect(Heroes.wing(h) == "", "a hero you do not own cannot ride along")

# the weekly event (Events, 2026-11-10): a theme a week, points, a track of ten rewards
func _check_events() -> void:
	var s := {"stage_unlocked": 10, "coins": 0, "crystals": 0}
	_expect(not Events.open(s), "the weekly event is closed until stage 10 is cleared")
	s["stage_unlocked"] = 13
	_expect(Events.open(s) and Events.stage(s) == 12, "it is fought on your best cleared stage")
	for th in Events.THEMES:
		_expect(Array(th.mods).size() == 2 and bool(Promotion.MODS[th.mods[0]].good) and not bool(Promotion.MODS[th.mods[1]].good) and UIKit.ic(String(th.icon)) != null, "theme %s: one advantage, one disadvantage, a picture" % th.id)
	_expect(Events.theme(0).id != Events.theme(1).id and Events.theme(0).id == Events.theme(Events.THEMES.size()).id, "the theme changes every week and comes round again")
	_expect(Events.points_for(true, 1.0, 0.0) == 30 and Events.points_for(true, 0.2, 12.0) == 20 and Events.points_for(false, 0.0, 50.0) == 5, "points: 30 for a clean win, 20 for a rough one, 5 for a loss")
	_expect(int(Events.state(s).points) == 0 and not Events.claimable(s), "a fresh week: no points, nothing to take")
	Events.add_points(s, 45)
	_expect(Events.reached(s) == 2 and Events.claimable(s), "45 points reach the first two rewards")
	var r1 := Events.claim_next(s)
	var r2 := Events.claim_next(s)
	_expect(int(r1.get("coins", 0)) == 500 and int(s.coins) == 500 and int(r2.get("key_u", 0)) == 1 and int(Materials.read(s).key_u) == 1 and Events.claim_next(s).is_empty(), "the rewards are taken in order, once each")
	s["event"]["week"] = Events.week() - 1
	_expect(int(Events.state(s).points) == 0 and int(Events.state(s).claimed) == 0, "a new week starts the track again")
	var last := 0
	for t in Events.TRACK:
		_expect(int(t.points) > last, "the track rises (%d)" % int(t.points))
		last = int(t.points)

# the Expedition (Runs, 2026-11-10): a run of stops, what carries, how it ends, what it pays
func _check_runs() -> void:
	var s := {"stage_unlocked": 5, "coins": 0, "crystals": 0}
	_expect(not Runs.open(s), "the Expedition is closed until stage 5 is cleared")
	s["stage_unlocked"] = 13
	_expect(Runs.open(s) and Runs.planets_open(s) == 1, "planet 2 reached, but its expedition waits for a win on planet 1")
	var run := Runs.new_run(0, 4242)
	_expect(Runs.nodes(run, 0) == ["fight"] and Runs.nodes(run, Runs.STEPS - 1) == ["boss"], "a run starts with a fight and ends with the boss")
	for st in range(1, Runs.STEPS - 1):
		var ks: Array = Runs.nodes(run, st)
		var uniq := {}
		for k in ks:
			uniq[k] = true
			_expect(Runs.KINDS.has(k), "stop %d: %s is a known kind" % [st, k])
		_expect(ks.size() >= 2 and ks.size() <= 3 and uniq.size() == ks.size() and ks == Runs.nodes(run, st), "stop %d offers 2 or 3 different things, the same every time it is asked (%s)" % [st, str(ks)])
	_expect(Runs.stage_for(run, "fight") == 1 and Runs.stage_for(run, "boss") == 10 and Runs.stage_for(Runs.new_run(1, 1), "boss") == 20, "fights climb through the planet; the boss is the planet's boss stage")
	var w: Array = StageData.waves(10)
	_expect(Runs.trim_waves(w, "fight").size() == 4 and Runs.trim_waves(w, "boss").size() == 3 and Runs.trim_waves(w, "boss")[-1] == w[-1], "a fight is the first 4 waves, the boss fight the last 3")
	run["node"] = "fight"
	Runs.fight_done(run, true, 0.6, 0.5, 0.9, {"heavy_bolts": 2})
	_expect(int(run.step) == 1 and is_equal_approx(float(run.hp), 0.6) and int(run.cards.heavy_bolts) == 2 and bool(run.alive), "a won fight carries the hero's health and the cards to the next stop")
	Runs.take_rest(run)
	_expect(int(run.step) == 2 and is_equal_approx(float(run.hp), 1.0) and is_equal_approx(float(run.shield), 0.8), "a rest mends and moves on")
	var offers := Runs.cache_offers(run)
	_expect(offers.size() == 2 and offers[0] != offers[1] and Runs.CACHE.has(offers[0]), "a supply cache offers two different things")
	Runs.take_cache(s, run, "refresh")
	_expect(int(run.refreshes) == 2 and int(run.step) == 3, "the spare deck: two refreshes for the rest of the run")
	run["node"] = "elite"
	Runs.fight_done(run, false, 0.0, 0.0, 0.0, {})
	_expect(Runs.over(run) and not bool(run.won) and int(run.cleared) == 3, "a lost fight ends the run")
	s["run"] = run
	var got := Runs.collect(s)
	_expect(int(got.coins) == 360 and int(got.get("key_u", 0)) == 1 and int(s.coins) == 360 and Runs.active(s).is_empty() and Runs.collect(s).is_empty(), "the reward is paid once: coins by stops cleared, a key from three")
	var win := Runs.new_run(0, 7)
	win["step"] = Runs.STEPS - 1
	win["cleared"] = Runs.STEPS - 1
	win["node"] = "boss"
	Runs.fight_done(win, true, 0.5, 0.2, 0.7, {})
	s["run"] = win
	var prize := Runs.collect(s)
	_expect(bool(win.won) and int(prize.get("key_e", 0)) == 1 and Runs.wins(s, 0) == 1 and Runs.planets_open(s) == 2, "beating the boss wins the run, pays the prize and opens planet 2's expedition")

# the base you build (Base, 2026-11-10): buildings in place of turrets, four slots, a level each
func _check_base() -> void:
	var s := {"stage_unlocked": 20, "coins": 5000, "parts": {"alloy": 50, "cell": 20, "core": 5}}
	var b := Base.read(s)
	_expect(b.slots[0] == "shield_gen" and Base.level(b, "shield_gen") == 1 and not Base.owned(b, "armory"), "everyone starts with the Shield Generator on slot 1")
	for id in Base.ORDER:
		_expect(Base.BUILDINGS.has(id) and UIKit.ic(String(Base.BUILDINGS[id].icon)) != null and Base.text(String(id), 1) != "", "building %s: a picture and a line" % id)
	_expect(is_equal_approx(float(Base.stats(s).shield), 0.08) and Base.stats(s).on == ["shield_gen"], "a Lv.1 generator: shield +8%")
	_expect(Base.build(s, b, "refinery") == "Clear stage 25 first" and Base.build(s, b, "armory") == "" and int(s.coins) == 3500 and Base.owned(b, "armory"), "the Armory costs 1500 coins; the Refinery waits for stage 25")
	_expect(Base.build(s, b, "armory") == "Already built", "a building is built once")
	s["base"] = Base.write(b)
	_expect(is_equal_approx(float(Base.stats(s).damage), 0.0), "a building off the base gives nothing")
	Base.place(b, 1, "armory")
	s["base"] = Base.write(b)
	_expect(is_equal_approx(float(Base.stats(s).damage), 0.03), "placed on an open slot it counts")
	var c0 := int(s.coins)
	_expect(Base.level_up(s, b, "armory") == "" and Base.level(b, "armory") == 2 and int(s.coins) == c0 - Base.level_cost(1), "a level costs coins (and parts later)")
	s["base"] = Base.write(b)
	_expect(is_equal_approx(float(Base.stats(s).damage), 0.06), "Lv.2 Armory: hero damage +6%")
	Base.place(b, 0, "armory")
	_expect(b.slots[0] == "armory" and b.slots[1] == "", "a building stands on one slot at a time")
	s["stage_unlocked"] = 3
	s["base"] = Base.write(b)
	_expect(Base.stats(s).on.is_empty(), "a closed slot gives nothing")
	# the turrets' coins come back once
	var old := {"stage_unlocked": 20, "coins": 100, "turrets": {"loadout": ["sentry", "lance", "", ""], "owned": ["sentry", "lance"], "tracks": {"sentry": {"atk": 3, "rate": 2, "range": 1}}}}
	var back := Base.migrate(old)
	_expect(back == 3000 + 60 + 120 + 60 and int(old.coins) == 100 + back and Base.migrate(old) == 0 and old.has("base"), "what was spent on turrets comes back as coins, once (%d)" % back)
