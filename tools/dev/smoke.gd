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
	_expect(Unlocks.fresh(s) == ["turrets", "repeat"], "stage 5 cleared: turrets and repeat quests to announce, table order")
	Unlocks.mark_seen(s, "turrets")
	Unlocks.mark_seen(s, "repeat")
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
	_expect(Heroes.unlock(s, h, "nyx", true) != "" and not Heroes.owned(h, "nyx"), "Nyx is gated by stage 20 even for crystals")
	s["stage_unlocked"] = 21
	_expect(Heroes.unlock(s, h, "nyx", true) == "Not enough crystals", "650 crystals needed for Nyx")
	s["crystals"] = 700
	_expect(Heroes.unlock(s, h, "nyx", true) == "" and int(s.crystals) == 50 and Heroes.owned(h, "nyx"), "Nyx for 650 crystals")
	s["coins"] = 1000
	_expect(Heroes.level_up(s, h, "rook") and Heroes.level(h, "rook") == 2 and int(s.coins) == 1000 - Heroes.level_cost(1), "level up costs 60 + 30 x level")
	Heroes.add_shards(h, "rook", 35)
	_expect(Heroes.can_evolve(h, "rook") and Heroes.evolve(h, "rook") and Heroes.tier(h, "rook") == 2 and Heroes.shards(h, "rook") == 5, "30 shards = tier 2")
	_expect(not Heroes.can_evolve(h, "rook"), "tier 3 needs 90")
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
	_expect(Turrets.unlock(s, t, "prism", true) != "" and not Turrets.owned(t, "prism"), "Prism needs stage 25 first")
	s["stage_unlocked"] = 26
	s["crystals"] = 600
	_expect(Turrets.unlock(s, t, "prism", true) == "" and int(s.crystals) == 600 - Turrets.crystal_price("prism"), "Prism for crystals once the stage is cleared")
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
	var ds := {"coins": 7000, "crystals": 0, "parts": {"alloy": 20, "cell": 4}}
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
	_expect(Heroes.can_evolve(h, "rook") and not Heroes.can_evolve(h, "rook", s), "tier 2 needs 30 shards and 2 Energy Sparks")
	Materials.add(s, "ess_ion", 2)
	_expect(Heroes.evolve(h, "rook", s) and Heroes.tier(h, "rook") == 2 and int(Materials.read(s).ess_ion) == 0, "evolving pays the sparks")
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
