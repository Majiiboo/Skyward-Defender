class_name GearData
extends RefCounted
# The pilot's gear (CLAUDE.md queue 8, agreed with Rudy): six slots, six sets of six
# pieces (Ion cyan, Scavenger green, Void purple, Nightmare red, Solar white-gold, Frost
# icy blue; Luna's 3D renders in art_src/gear3d, three tiers each). Colour never
# means strength: every set is equal piece for piece; strength comes from upgrade
# level. Each slot boosts one battle stat (same in every set), each piece adds a small
# secondary stat from its set, and 3 / 6 pieces of one set give a set bonus.
#
# RARITY (Rudy, dev139): every piece has a rarity, Common to Legendary, and the rarity caps
# its upgrade level (Common Lv.10 ... Legendary Lv.30). You collect COPIES of pieces (stage
# clears, Patrol, later chests); in the Workshop 3 copies of one rarity merge into 1 copy of
# the next. A piece's rarity is the best copy you hold of it, so merging raises the cap.
# Save: "gear": {"equipped": {slot: item id}, "levels": {item id: level},
#   "copies": {item id: {rarity: count}}, "recent": [item ids, newest last]}.
# Every piece of an unlocked set is owned as one Common copy (old saves get it on read).

const SLOTS := ["Weapon", "Helmet", "Chest", "Gauntlets", "Boots", "Jetpack"]
const MAX_LEVEL := 30

const RARITIES := ["common", "uncommon", "rare", "epic", "legendary"]
const RARITY := {
	"common":    {"name": "Common",    "cap": 10, "color": Color(0.72, 0.78, 0.88)},
	"uncommon":  {"name": "Uncommon",  "cap": 15, "color": Color(0.45, 0.95, 0.5)},
	"rare":      {"name": "Rare",      "cap": 20, "color": Color(0.3, 0.75, 1.0)},
	"epic":      {"name": "Epic",      "cap": 25, "color": Color(0.75, 0.5, 1.0)},
	"legendary": {"name": "Legendary", "cap": 30, "color": Color(1.0, 0.8, 0.3)},
}
const MERGE_COST := 3            # copies of one rarity -> 1 of the next
const QUICK_MERGE := ["common", "uncommon"]   # Quick Merge handles these; Rare and up by hand (Rudy)
const RECENT_MAX := 60

# what each slot does, per level (level 1 = the first step)
const SLOT_STAT := {
	"Weapon":    {"text": "ATK", "per": 0.06},                  # +6% damage per level
	"Helmet":    {"text": "Aim", "per": 0.06},                  # aim wobble -6% and turn +6% per level
	"Chest":     {"text": "Recovery", "per": 0.08},             # invulnerable time +8% per level; +1 heart at Lv.5 and Lv.10
	"Gauntlets": {"text": "Fire rate", "per": 0.04},            # +4% fire rate per level
	"Boots":     {"text": "Magnet", "per": 8.0},                # +8 px gem pull per level
	"Jetpack":   {"text": "Auto-fire", "per": 0.04},            # finger lifted: fires +4% faster per level
}

const SETS := {
	"ion":       {"name": "Ion", "color": Color(0.2, 0.85, 1.0), "unlock_stage": 1,
		"minor": "XP +3%", "bonus3": "XP +15%", "bonus6": "Shield +50%",
		"thruster": "flame", "weapon": "laser_pistol"},
	"scavenger": {"name": "Scavenger", "color": Color(0.45, 1.0, 0.35), "unlock_stage": 11,
		"minor": "Coins +4%", "bonus3": "Coins +20%", "bonus6": "+1 card refresh",
		"thruster": "pressure", "weapon": "dual_minis"},
	"void":      {"name": "Void", "color": Color(0.71, 0.45, 1.0), "unlock_stage": 21,
		"minor": "ATK +2%", "bonus3": "ATK +10%", "bonus6": "Piercing shots",
		"thruster": "gravity", "weapon": "pulse_cannon"},
	"nightmare": {"name": "Nightmare", "color": Color(1.0, 0.3, 0.3), "unlock_stage": 31,
		"minor": "Turret ATK +3%", "bonus3": "Turret ATK +15%", "bonus6": "Turret speed +20%",
		"thruster": "plasma", "weapon": "railgun"},
	"solar":     {"name": "Solar", "color": Color(1.0, 0.85, 0.45), "unlock_stage": 41,
		"minor": "Pilot XP +4%", "bonus3": "Pilot XP +20%", "bonus6": "+1 heart",
		"thruster": "flame", "weapon": "laser_rifle"},
	"frost":     {"name": "Frost", "color": Color(0.6, 0.9, 1.0), "unlock_stage": 51,
		"minor": "Shield +3%", "bonus3": "Shield +20%", "bonus6": "Freezing shots",
		"thruster": "pressure", "weapon": "frost_rifle"},
}
const SET_ORDER := ["ion", "scavenger", "void", "nightmare", "solar", "frost"]   # one planet each

# Gear milestones (Rudy, dev130): every piece earns a bonus every 5 levels (Lv.5, 10, ... 30),
# and these are where the combat stats come from (crit rate, crit damage, damage boost, the
# base's damage reduction and fortress HP). stat = key in stats(); per = added at each one.
const MILESTONE := {
	"Weapon":    {"stat": "crit_rate", "per": 0.03, "text": "Crit rate +3%"},
	"Helmet":    {"stat": "crit_dmg", "per": 0.15, "text": "Crit damage +15%"},
	"Chest":     {"stat": "base_dr", "per": 0.04, "text": "Base damage taken -4%"},
	"Gauntlets": {"stat": "dmg_boost", "per": 0.04, "text": "Damage boost +4%"},
	"Boots":     {"stat": "fortress", "per": 0.06, "text": "Fortress HP +6%"},
	"Jetpack":   {"stat": "crit_rate", "per": 0.02, "text": "Crit rate +2%"},
}
const BASE_CRIT_RATE := 0.05
const BASE_CRIT_DMG := 1.5
const MILESTONE_EVERY := 5

static func milestones(level: int) -> int:
	return level / MILESTONE_EVERY

static func max_milestones() -> int:
	return MAX_LEVEL / MILESTONE_EVERY

# what each set's weapon does (Gear page)
const WEAPON_TEXT := {"laser_pistol": "Single shots", "dual_minis": "Twin shots",
	"pulse_cannon": "Heavy shots", "railgun": "Piercing shots",
	"laser_rifle": "Fast shots", "frost_rifle": "Rapid shots"}

# 36 pieces: id -> {name, slot, set}. Pictures: gear/<id>_t1..t3.png, one per upgrade
# tier (tools/cut_gear_art.gd); gear/<id>.png is the older painted fallback.
const ITEMS := {
	"ion_weapon": {"name": "Ion Pistol", "slot": "Weapon", "set": "ion"},
	"ion_helmet": {"name": "Ion Visor", "slot": "Helmet", "set": "ion"},
	"ion_chest": {"name": "Ion Core Plate", "slot": "Chest", "set": "ion"},
	"ion_gauntlets": {"name": "Ion Gloves", "slot": "Gauntlets", "set": "ion"},
	"ion_boots": {"name": "Ion Boots", "slot": "Boots", "set": "ion"},
	"ion_jetpack": {"name": "Ion Jet", "slot": "Jetpack", "set": "ion"},
	"scavenger_weapon": {"name": "Arc Welder", "slot": "Weapon", "set": "scavenger"},
	"scavenger_helmet": {"name": "Scav Helm", "slot": "Helmet", "set": "scavenger"},
	"scavenger_chest": {"name": "Scav Tri-Plate", "slot": "Chest", "set": "scavenger"},
	"scavenger_gauntlets": {"name": "Scav Grips", "slot": "Gauntlets", "set": "scavenger"},
	"scavenger_boots": {"name": "Scav Treads", "slot": "Boots", "set": "scavenger"},
	"scavenger_jetpack": {"name": "Twin Burners", "slot": "Jetpack", "set": "scavenger"},
	"void_weapon": {"name": "Pulse Cannon", "slot": "Weapon", "set": "void"},
	"void_helmet": {"name": "Void Crest", "slot": "Helmet", "set": "void"},
	"void_chest": {"name": "Void Hex Plate", "slot": "Chest", "set": "void"},
	"void_gauntlets": {"name": "Void Fists", "slot": "Gauntlets", "set": "void"},
	"void_boots": {"name": "Void Striders", "slot": "Boots", "set": "void"},
	"void_jetpack": {"name": "Void Ring", "slot": "Jetpack", "set": "void"},
	"nightmare_weapon": {"name": "Dread Railgun", "slot": "Weapon", "set": "nightmare"},
	"nightmare_helmet": {"name": "Grille Mask", "slot": "Helmet", "set": "nightmare"},
	"nightmare_chest": {"name": "Crescent Plate", "slot": "Chest", "set": "nightmare"},
	"nightmare_gauntlets": {"name": "Spike Guards", "slot": "Gauntlets", "set": "nightmare"},
	"nightmare_boots": {"name": "Spiked Greaves", "slot": "Boots", "set": "nightmare"},
	"nightmare_jetpack": {"name": "Blade Wings", "slot": "Jetpack", "set": "nightmare"},
	"solar_weapon": {"name": "Sun Rifle", "slot": "Weapon", "set": "solar"},
	"solar_helmet": {"name": "Sun Dome", "slot": "Helmet", "set": "solar"},
	"solar_chest": {"name": "Star Plate", "slot": "Chest", "set": "solar"},
	"solar_gauntlets": {"name": "Sun Fists", "slot": "Gauntlets", "set": "solar"},
	"solar_boots": {"name": "Hover Boots", "slot": "Boots", "set": "solar"},
	"solar_jetpack": {"name": "Sun Engine", "slot": "Jetpack", "set": "solar"},
	"frost_weapon": {"name": "Frost Rifle", "slot": "Weapon", "set": "frost"},
	"frost_helmet": {"name": "Frost T-Visor", "slot": "Helmet", "set": "frost"},
	"frost_chest": {"name": "Diamond Plate", "slot": "Chest", "set": "frost"},
	"frost_gauntlets": {"name": "Crystal Fists", "slot": "Gauntlets", "set": "frost"},
	"frost_boots": {"name": "Ice Spikes", "slot": "Boots", "set": "frost"},
	"frost_jetpack": {"name": "Ice Disc", "slot": "Jetpack", "set": "frost"},
}
const DEFAULT := {"Weapon": "ion_weapon", "Helmet": "ion_helmet", "Chest": "ion_chest",
	"Gauntlets": "ion_gauntlets", "Boots": "ion_boots", "Jetpack": "ion_jetpack"}

# which of Luna's three pictures a level shows: Lv.1-3, 4-7, 8+
static func tier(level: int) -> int:
	return 1 if level <= 3 else (2 if level <= 7 else 3)

static func upgrade_cost(level: int) -> int:
	return 120 * level

static func set_unlocked(set_id: String, stage_unlocked: int) -> bool:
	return stage_unlocked >= int(SETS[set_id].unlock_stage)

static func rarity_index(r: String) -> int:
	return maxi(RARITIES.find(r), 0)

static func level_cap(r: String) -> int:
	return int(RARITY.get(r, RARITY.common).cap)

# {equipped, levels, copies, recent} from the save, cleaned up (old saves: the old item
# names and the old "Power Orb" slot are mapped to the Ion set, levels start at 1, every
# piece of an unlocked set gets its one Common copy)
static func read(save: Dictionary) -> Dictionary:
	var g = save.get("gear", {})
	var eq := DEFAULT.duplicate()
	var lv := {}
	var copies := {}
	var recent: Array = []
	if typeof(g) == TYPE_DICTIONARY:
		var e = g.get("equipped", {})
		if typeof(e) == TYPE_DICTIONARY:
			for s in SLOTS:
				var id := String(e.get(s, ""))
				if ITEMS.has(id) and ITEMS[id].slot == s:
					eq[s] = id
		var l = g.get("levels", {})
		if typeof(l) == TYPE_DICTIONARY:
			for id in l:
				if ITEMS.has(id):
					lv[id] = clampi(int(l[id]), 1, MAX_LEVEL)
		var c = g.get("copies", {})
		if typeof(c) == TYPE_DICTIONARY:
			for id in c:
				if ITEMS.has(id) and typeof(c[id]) == TYPE_DICTIONARY:
					var one := {}
					for r in c[id]:
						if RARITY.has(r) and int(c[id][r]) > 0:
							one[r] = int(c[id][r])
					if not one.is_empty():
						copies[id] = one
		var rc = g.get("recent", [])
		if typeof(rc) == TYPE_ARRAY:
			for id in rc:
				if ITEMS.has(String(id)):
					recent.append(String(id))
	# every piece of an unlocked set (and whatever is worn) is owned as one Common copy
	var unlocked := int(save.get("stage_unlocked", 1))
	for id in ITEMS:
		if not copies.has(id) and (set_unlocked(ITEMS[id].set, unlocked) or eq.values().has(id)):
			copies[id] = {"common": 1}
	return {"equipped": eq, "levels": lv, "copies": copies, "recent": recent}

# the part of the save that holds the gear (the Gear screen writes it back)
static func write(gear: Dictionary) -> Dictionary:
	return {"equipped": gear.equipped, "levels": gear.levels, "copies": gear.copies, "recent": gear.recent}

static func level(gear: Dictionary, id: String) -> int:
	return int(gear.levels.get(id, 1))

static func owned(gear: Dictionary, id: String) -> bool:
	return gear.copies.has(id) or DevTools.on

static func copies_of(gear: Dictionary, id: String, r: String) -> int:
	return int(gear.copies.get(id, {}).get(r, 0))

static func total_copies(gear: Dictionary, id: String) -> int:
	var n := 0
	for r in gear.copies.get(id, {}):
		n += int(gear.copies[id][r])
	return n

# the piece's rarity = the best copy held of it (Common when none)
static func rarity(gear: Dictionary, id: String) -> String:
	var best := "common"
	for r in gear.copies.get(id, {}):
		if rarity_index(r) > rarity_index(best):
			best = r
	return best

static func cap_of(gear: Dictionary, id: String) -> int:
	return level_cap(rarity(gear, id))

static func add_copy(gear: Dictionary, id: String, r: String, n: int = 1) -> void:
	if not ITEMS.has(id) or not RARITY.has(r) or n <= 0:
		return
	var one: Dictionary = gear.copies.get(id, {})
	one[r] = int(one.get(r, 0)) + n
	gear.copies[id] = one
	gear.recent.append(id)
	while gear.recent.size() > RECENT_MAX:
		gear.recent.pop_front()

# the rarity above `r` ("" for Legendary)
static func next_rarity(r: String) -> String:
	var i := rarity_index(r)
	return RARITIES[i + 1] if i + 1 < RARITIES.size() else ""

static func can_merge(gear: Dictionary, id: String, r: String) -> bool:
	return next_rarity(r) != "" and copies_of(gear, id, r) >= MERGE_COST

# 3 copies of `r` -> 1 copy of the next rarity. Returns the new rarity, or "" when it
# could not merge. (The piece keeps its level; its cap rises with its best copy.)
static func merge(gear: Dictionary, id: String, r: String) -> String:
	if not can_merge(gear, id, r):
		return ""
	var one: Dictionary = gear.copies[id]
	one[r] = int(one[r]) - MERGE_COST
	if int(one[r]) <= 0:
		one.erase(r)
	var to := next_rarity(r)
	one[to] = int(one.get(to, 0)) + 1
	gear.copies[id] = one
	return to

# Quick Merge (Rudy): merges every Common and Uncommon stack as far as it goes; Rare and
# above are merged by hand only. Returns how many merges were made.
static func quick_merge(gear: Dictionary) -> int:
	var made := 0
	for id in gear.copies.keys():
		for r in QUICK_MERGE:
			while can_merge(gear, id, r):
				merge(gear, id, r)
				made += 1
	return made

static func quick_merge_count(gear: Dictionary) -> int:
	var n := 0
	for id in gear.copies:
		for r in QUICK_MERGE:
			var c := copies_of(gear, id, r)
			# chained: commons that become uncommons may merge on
			if r == "common":
				n += c / MERGE_COST
			else:
				n += (c + copies_of(gear, id, "common") / MERGE_COST) / MERGE_COST
	return n

# ---- drops (stage clears, Patrol; chests later) ----
# The piece comes from that planet's set (stages 1-10 Ion, 11-20 Scavenger ...), now and
# then from an earlier one. Rarity rises with the stage: Common only on the first planet,
# Rare from planet 3, Epic from planet 4, Legendary from planet 5, always rare (Rudy:
# common pieces on low stages, better rarities only on high stages, spread out).
const DROP_WEIGHTS := [   # per planet: common, uncommon, rare, epic, legendary
	[100, 0, 0, 0, 0],
	[85, 15, 0, 0, 0],
	[70, 25, 5, 0, 0],
	[55, 30, 12, 3, 0],
	[45, 32, 16, 6, 1],
	[35, 33, 20, 9, 3],
]

static func stage_set(stage: int) -> String:
	return SET_ORDER[clampi((stage - 1) / 10, 0, SET_ORDER.size() - 1)]

static func roll_drop(stage: int, rng: RandomNumberGenerator) -> Dictionary:
	var planet := clampi((stage - 1) / 10, 0, SET_ORDER.size() - 1)
	var set_id: String = SET_ORDER[planet]
	if planet > 0 and rng.randf() < 0.25:
		set_id = SET_ORDER[rng.randi_range(0, planet - 1)]   # a piece for an older set
	var slot: String = "Weapon"   # heroes (dev172): the weapon is the only gear slot that drops; armour is gone
	var w: Array = DROP_WEIGHTS[planet]
	var total := 0
	for x in w:
		total += int(x)
	var pick := rng.randi_range(1, total)
	var r := "common"
	for i in w.size():
		pick -= int(w[i])
		if pick <= 0:
			r = RARITIES[i]
			break
	return {"id": "%s_%s" % [set_id, slot.to_lower()], "rarity": r}

# the best rarity a stage can drop (the Modes rewards row)
static func best_drop_rarity(stage: int) -> String:
	var w: Array = DROP_WEIGHTS[clampi((stage - 1) / 10, 0, SET_ORDER.size() - 1)]
	var best := "common"
	for i in w.size():
		if int(w[i]) > 0:
			best = RARITIES[i]
	return best

# chance that clearing `stage` drops a piece: every 5th stage (mini-boss / boss) always,
# Elite always, other stages about a third of the time
static func drop_chance(stage: int, elite: bool) -> float:
	return 1.0 if (stage % 5 == 0 or elite) else 0.35

static func rarity_name(r: String) -> String:
	return String(RARITY.get(r, RARITY.common).name)

static func rarity_color(r: String) -> Color:
	return RARITY.get(r, RARITY.common).color

static func set_count(gear: Dictionary, set_id: String) -> int:
	var n := 0
	for s in SLOTS:
		if ITEMS[gear.equipped[s]].set == set_id:
			n += 1
	return n

# What the equipped gear does in battle.
static func stats(save: Dictionary) -> Dictionary:
	var gear := read(save)
	var st := {"damage": 1.0, "fire_rate": 1.0, "aim": 1.0, "recovery": 1.0, "hearts": 0, "magnet": 0.0,
		"auto_fire": 1.0, "gem_xp": 1.0, "coins": 1.0, "shield_regen": 1.0, "refreshes": 0, "pierce5": false,
		"turret_dmg": 1.0, "turret_rate": 1.0, "pilot_xp": 1.0, "shield": 1.0, "chill": false,
		"crit_rate": BASE_CRIT_RATE, "crit_dmg": BASE_CRIT_DMG, "dmg_boost": 0.0, "base_dr": 0.0, "fortress": 1.0,
		"weapon": "laser_pistol", "thruster": "flame"}
	for s in SLOTS:
		var id: String = gear.equipped[s]
		var lv := level(gear, id)
		var per: float = float(SLOT_STAT[s].per)
		match s:
			"Weapon":
				st.damage *= 1.0 + per * lv
				st.weapon = SETS[ITEMS[id].set].weapon
			"Helmet": st.aim = 1.0 + per * lv
			"Chest":
				st.recovery = 1.0 + per * lv
				st.hearts = (1 if lv >= 5 else 0) + (1 if lv >= 10 else 0)
			"Gauntlets": st.fire_rate *= 1.0 + per * lv
			"Boots": st.magnet = per * lv
			"Jetpack":
				st.auto_fire = 1.0 + per * lv
				st.thruster = SETS[ITEMS[id].set].thruster
		# its milestones (every 5 levels)
		var ms: Dictionary = MILESTONE[s]
		st[ms.stat] = float(st[ms.stat]) + float(ms.per) * milestones(lv)
		# each piece's small set stat
		match String(ITEMS[id].set):
			"ion": st.gem_xp += 0.03
			"scavenger": st.coins += 0.04
			"void": st.damage *= 1.02
			"nightmare": st.turret_dmg += 0.03
			"solar": st.pilot_xp += 0.04
			"frost": st.shield += 0.03
	if set_count(gear, "ion") >= 3: st.gem_xp += 0.15
	if set_count(gear, "ion") >= 6: st.shield_regen = 1.5
	if set_count(gear, "scavenger") >= 3: st.coins += 0.20
	if set_count(gear, "scavenger") >= 6: st.refreshes = 1
	if set_count(gear, "void") >= 3: st.damage *= 1.10
	if set_count(gear, "void") >= 6: st.pierce5 = true
	if set_count(gear, "nightmare") >= 3: st.turret_dmg += 0.15
	if set_count(gear, "nightmare") >= 6: st.turret_rate = 1.2
	if set_count(gear, "solar") >= 3: st.pilot_xp += 0.20
	if set_count(gear, "solar") >= 6: st.hearts += 1
	if set_count(gear, "frost") >= 3: st.shield += 0.20
	if set_count(gear, "frost") >= 6: st.chill = true
	st.shield *= st.shield_regen   # Ion 6-piece: base shield +50%
	# pilot rank (Promotion): +5% damage and +5% base shield / hull per rank won
	var pr := Promotion.rank(save)
	st.damage *= Promotion.bonus(pr)
	st.fortress *= Promotion.bonus(pr)
	return st

# a single number for the Gear screen: sum of levels, weighted
static func power(gear: Dictionary) -> int:
	var p := 0
	for s in SLOTS:
		p += 40 + 18 * (level(gear, gear.equipped[s]) - 1)
	return p

# HOW EACH WEAPON SHOOTS (2026-11-10; battle WEAPONS carries the numbers). One short line each, for
# the Weapons screen: the weapon is how your hands play, so the six must feel different.
const WEAPON_STYLE := {
	"laser_pistol": {"style": "Charged shot", "text": "Every 5th bolt hits three times as hard"},
	"dual_minis":   {"style": "Arc", "text": "Twin bolts; every 3rd arcs to a second bug"},
	"pulse_cannon": {"style": "Blast", "text": "Slow shells that explode"},
	"railgun":      {"style": "Pierce", "text": "A slow bolt through every bug in its line"},
	"laser_rifle":  {"style": "Fan", "text": "Three short-range bolts: fly close"},
	"frost_rifle":  {"style": "Stream", "text": "A rapid stream that slows what it hits"},
}

# the style of an item ("" for anything that is not a weapon)
static func weapon_style(item_id: String) -> Dictionary:
	if not ITEMS.has(item_id) or String(ITEMS[item_id].slot) != "Weapon":
		return {}
	return WEAPON_STYLE.get(String(SETS[ITEMS[item_id].set].weapon), {})
