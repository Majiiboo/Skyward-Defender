class_name GearData
extends RefCounted
# The pilot's gear (CLAUDE.md queue 8, agreed with Rudy): six slots, three sets of six
# pieces (Luna's gear sheet: Ion = cyan, Scavenger = green, Void = purple). Colour never
# means strength: every set is equal piece for piece; strength comes from upgrade
# level. Each slot boosts one battle stat (same in every set), each piece adds a small
# secondary stat from its set, and 3 / 6 pieces of one set give a set bonus.
# Save: "gear": {"equipped": {slot: item id}, "levels": {item id: level}}.

const SLOTS := ["Weapon", "Helmet", "Chest", "Gauntlets", "Boots", "Jetpack"]
const MAX_LEVEL := 10

# what each slot does, per level (level 1 = the first step)
const SLOT_STAT := {
	"Weapon":    {"text": "Bolt damage", "per": 0.06},          # +6% damage per level
	"Helmet":    {"text": "Auto-aim accuracy", "per": 0.06},    # aim wobble -6% and turn +6% per level
	"Chest":     {"text": "Hit recovery", "per": 0.08},         # invulnerable time +8% per level; +1 heart at Lv.5 and Lv.10
	"Gauntlets": {"text": "Fire rate", "per": 0.04},            # +4% fire rate per level
	"Boots":     {"text": "Gem magnet", "per": 8.0},            # +8 px gem pull per level
	"Jetpack":   {"text": "Auto-fire speed", "per": 0.04},      # finger lifted: fires +4% faster per level
}

const SETS := {
	"ion":       {"name": "Ion", "color": Color(0.2, 0.85, 1.0), "unlock_stage": 1,
		"minor": "gem XP +3% per piece", "bonus3": "Gem XP +15%", "bonus6": "Shield recharges 50% faster",
		"thruster": "flame", "weapon": "laser_pistol"},
	"scavenger": {"name": "Scavenger", "color": Color(0.45, 1.0, 0.35), "unlock_stage": 11,
		"minor": "coins +4% per piece", "bonus3": "Coins from kills +20%", "bonus6": "+1 free card refresh per run",
		"thruster": "pressure", "weapon": "dual_minis"},
	"void":      {"name": "Void", "color": Color(0.71, 0.45, 1.0), "unlock_stage": 21,
		"minor": "damage +2% per piece", "bonus3": "Damage +10%", "bonus6": "Every 5th bolt pierces",
		"thruster": "gravity", "weapon": "pulse_cannon"},
}

# 18 pieces: id -> {name, slot, set}. Pictures: gear/<id>.png (tools/cut_gear_art.gd).
const ITEMS := {
	"ion_weapon": {"name": "Ion Pistol", "slot": "Weapon", "set": "ion"},
	"ion_helmet": {"name": "Ion Visor", "slot": "Helmet", "set": "ion"},
	"ion_chest": {"name": "Ion Core Plate", "slot": "Chest", "set": "ion"},
	"ion_gauntlets": {"name": "Ion Gloves", "slot": "Gauntlets", "set": "ion"},
	"ion_boots": {"name": "Ion Boots", "slot": "Boots", "set": "ion"},
	"ion_jetpack": {"name": "Ion Jet", "slot": "Jetpack", "set": "ion"},
	"scavenger_weapon": {"name": "Dual Minis", "slot": "Weapon", "set": "scavenger"},
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
}
const DEFAULT := {"Weapon": "ion_weapon", "Helmet": "ion_helmet", "Chest": "ion_chest",
	"Gauntlets": "ion_gauntlets", "Boots": "ion_boots", "Jetpack": "ion_jetpack"}

static func upgrade_cost(level: int) -> int:
	return 120 * level

static func set_unlocked(set_id: String, stage_unlocked: int) -> bool:
	return stage_unlocked >= int(SETS[set_id].unlock_stage)

# {equipped, levels} from the save, cleaned up (old saves: the old item names and the
# old "Power Orb" slot are mapped to the Ion set, levels start at 1)
static func read(save: Dictionary) -> Dictionary:
	var g = save.get("gear", {})
	var eq := DEFAULT.duplicate()
	var lv := {}
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
	return {"equipped": eq, "levels": lv}

static func level(gear: Dictionary, id: String) -> int:
	return int(gear.levels.get(id, 1))

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
		# each piece's small set stat
		match String(ITEMS[id].set):
			"ion": st.gem_xp += 0.03
			"scavenger": st.coins += 0.04
			"void": st.damage *= 1.02
	if set_count(gear, "ion") >= 3: st.gem_xp += 0.15
	if set_count(gear, "ion") >= 6: st.shield_regen = 1.5
	if set_count(gear, "scavenger") >= 3: st.coins += 0.20
	if set_count(gear, "scavenger") >= 6: st.refreshes = 1
	if set_count(gear, "void") >= 3: st.damage *= 1.10
	if set_count(gear, "void") >= 6: st.pierce5 = true
	return st

# a single number for the Gear screen: sum of levels, weighted
static func power(gear: Dictionary) -> int:
	var p := 0
	for s in SLOTS:
		p += 40 + 18 * (level(gear, gear.equipped[s]) - 1)
	return p
