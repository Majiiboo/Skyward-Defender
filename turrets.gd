class_name Turrets
extends RefCounted
# The base turrets: permanent gear with their own level (coins) and a saved
# loadout of four mounts, left to right. Battle mounts the loadout at the start
# of every run. Tune numbers here, not in battle.gd.
#
# Save: user://skybound_save.json "turrets" = {"loadout": [4 ids or ""], "levels": {id: level}}

const MOUNTS := 4
const MAX_LEVEL := 10
const TRAIT_BONUS := 0.5        # +50% damage vs a trait the turret is strong against
const BOSS_TRAIT_BONUS := 0.3   # bosses resist the bonus a little
const DEFAULT_LOADOUT := ["sentry", "", "", ""]
# The base's four mounts open as you clear stages (Rudy, 2026-11-03): no turret until
# stage 5 is beaten, so the first stages are played with the pilot alone. Pilot level
# decides WHICH turrets you own (TURRETS.unlock); cleared stages decide HOW MANY stand
# on the base. Mount i opens once stage MOUNT_OPENS_AFTER[i] is cleared.
const MOUNT_OPENS_AFTER := [5, 15, 25, 40]

# art = file prefix in turrets/ (<art>_idle.png; the Sentry also has _head and _base).
# ready = the battle mechanic exists; the others show in Gear as "in development".
# unlock = the pilot level that USED to gate it (old saves keep what that level had unlocked).
# Since dev172 turrets are BOUGHT like heroes: "grade" (stars), "cost" (coins + parts) or
# "crystals", a few with a "stage" to clear first; "element" (Heroes.ELEMENTS: the same weak /
# resist table by planet) and "role" (the job, two words). strong = enemy traits it does +50%
# against, on top, for when the enemy families arrive.
const TURRETS := {
	"sentry":  {"name": "Sentry",         "art": "sentry",  "rarity": "common",    "unlock": 5, "ready": true,
		"element": "ion", "role": "Striker", "role_text": "steady single-target fire", "grade": 1, "cost": {}, "crystals": 0,
		"strong": [], "glow": Color(0.2, 0.85, 1.0),
		"damage": 1.0, "every": 0.55, "range": 520.0,
		"desc": "Twin cannons, steady fire"},
	"lance":   {"name": "Lance Pylon",    "art": "lance",   "rarity": "rare",      "unlock": 8, "ready": true,
		"element": "solar", "role": "Breaker", "role_text": "bosses and armour", "grade": 2, "cost": {"coins": 3000, "alloy": 15}, "crystals": 80,
		"strong": ["armoured", "boss"], "glow": Color(0.75, 0.9, 1.0),
		"damage": 3.0, "every": 2.2, "width": 26.0,
		"desc": "Charged beam up its whole column"},
	"storm":   {"name": "Storm Spire",    "art": "storm",   "rarity": "epic",      "unlock": 11, "ready": true,
		"element": "scavenger", "role": "Chain", "role_text": "crowds", "grade": 3, "cost": {"coins": 9000, "alloy": 20, "cell": 6}, "crystals": 200,
		"strong": ["swarm", "shielded"], "glow": Color(0.6, 0.55, 1.0),
		"damage": 1.1, "every": 1.5, "chain": 3, "cloud_r": 125.0, "cloud_h": 300.0,
		"desc": "Lightning chains between bugs"},
	"gravity": {"name": "Gravity Anchor", "art": "gravity", "rarity": "epic",      "unlock": 14, "ready": true,
		"element": "void", "role": "Control", "role_text": "groups bugs, then crushes", "grade": 3, "cost": {"coins": 12000, "cell": 10, "core": 1}, "crystals": 260, "stage": 15,
		"strong": ["swarm", "fast"], "glow": Color(0.71, 0.55, 1.0),
		"damage": 2.8, "every": 2.8, "pull": 2.0, "radius": 115.0, "crush_r": 85.0, "height": 230.0,
		"desc": "Pulls bugs together, then crushes"},
	"swarm":   {"name": "Swarm Hive",     "art": "swarm",   "rarity": "rare",      "unlock": 18, "ready": true,
		"element": "nightmare", "role": "Swarm", "role_text": "many small targets", "grade": 2, "cost": {"coins": 4000, "alloy": 20}, "crystals": 100,
		"strong": ["fast", "high"], "glow": Color(0.2, 0.85, 1.0),
		"damage": 0.5, "every": 3.0, "count": 4, "life": 4.0, "speed": 230.0,
		"desc": "Homing micro-drones"},
	"prism":   {"name": "Prism Tower",    "art": "prism",   "rarity": "legendary", "unlock": 22, "ready": true,
		"element": "frost", "role": "Support", "role_text": "slows what it hits", "grade": 4, "cost": {"coins": 25000, "cell": 16, "core": 4}, "crystals": 500, "stage": 25,
		"strong": ["wide"], "glow": Color(1.0, 0.85, 0.6),
		"damage": 0.7, "every": 2.6, "beams": 5, "spread": 1.0, "split_h": 300.0,
		"desc": "One shot splits into a fan of beams"},
	# round 2 (dev196, Luna's turrets round 2): a SECOND turret per element with a different
	# job, so the choice is a play style and never "the one Ice turret" (Rudy). "unlock" 99 =
	# an old save never gets them free; they are bought like the others.
	"repair":  {"name": "Repair Node",    "art": "repair",  "rarity": "rare",      "unlock": 99, "ready": true,
		"element": "ion", "role": "Support", "role_text": "mends the shield", "grade": 2, "cost": {"coins": 3500, "alloy": 15}, "crystals": 90, "stage": 10,
		"strong": [], "glow": Color(0.2, 0.85, 1.0),
		"damage": 0.0, "heal": 2.5, "every": 3.0,
		"desc": "Mends the base shield while it stands"},
	"tesla":   {"name": "Tesla Coil",     "art": "tesla",   "rarity": "rare",      "unlock": 99, "ready": true,
		"element": "scavenger", "role": "Striker", "role_text": "fast zaps up close", "grade": 2, "cost": {"coins": 4500, "alloy": 20}, "crystals": 110, "stage": 10,
		"strong": ["shielded"], "glow": Color(0.6, 1.0, 0.4),
		"damage": 0.7, "every": 0.4, "range": 260.0,
		"desc": "Fast zaps at the nearest bug, short reach"},
	"cryo":    {"name": "Cryo Lens",      "art": "cryo",    "rarity": "epic",      "unlock": 99, "ready": true,
		"element": "frost", "role": "Control", "role_text": "a cone of cold slows", "grade": 3, "cost": {"coins": 10000, "cell": 8}, "crystals": 220, "stage": 20,
		"strong": ["fast"], "glow": Color(0.6, 0.9, 1.0),
		"damage": 0.35, "every": 0.5, "reach": 330.0, "cone": 0.55, "slow": 0.5,
		"desc": "A cone of cold slows every bug in it"},
	"mines":   {"name": "Mine Layer",     "art": "mines",   "rarity": "epic",      "unlock": 99, "ready": true,
		"element": "void", "role": "Breaker", "role_text": "bosses and armour", "grade": 3, "cost": {"coins": 14000, "cell": 12, "core": 2}, "crystals": 300, "stage": 30,
		"strong": ["armoured", "boss"], "glow": Color(0.71, 0.55, 1.0),
		"damage": 7.0, "every": 4.0, "blast": 70.0, "mines": 3,
		"desc": "Floating mines burst on the biggest bug"},
	"beacon":  {"name": "Dread Beacon",   "art": "beacon",  "rarity": "epic",      "unlock": 99, "ready": true,
		"element": "nightmare", "role": "Support", "role_text": "marks bugs, hero ATK +10%", "grade": 3, "cost": {"coins": 15000, "cell": 12, "core": 2, "ess_nightmare": 2}, "crystals": 320, "stage": 35,
		"strong": [], "glow": Color(1.0, 0.3, 0.3),
		"damage": 0.0, "every": 2.5, "range": 420.0, "mark": 3.0, "atk": 0.10,
		"desc": "Marks a bug for critical hits; hero ATK +10%"},
	"flak":    {"name": "Flak Battery",   "art": "flak",    "rarity": "rare",      "unlock": 99, "ready": true,
		"element": "solar", "role": "Swarm", "role_text": "airbursts shred crowds", "grade": 2, "cost": {"coins": 5000, "alloy": 25}, "crystals": 120, "stage": 15,
		"strong": ["swarm", "wide"], "glow": Color(1.0, 0.7, 0.3),
		"damage": 1.3, "every": 1.4, "range": 520.0, "blast": 75.0,
		"desc": "Shells burst in the air over the thickest crowd"},
}
const ROUND2 := ["repair", "tesla", "cryo", "mines", "beacon", "flak"]   # the two-piece turrets of round 2

const TRAIT_NAMES := {"armoured": "armoured", "boss": "bosses", "swarm": "swarm", "shielded": "shielded",
	"fast": "fast", "high": "high flyers", "wide": "wide waves"}

# stage_unlocked = the save's highest playable stage (last cleared stage + 1).
static func mount_open(i: int, stage_unlocked: int) -> bool:
	return stage_unlocked > int(MOUNT_OPENS_AFTER[i]) or DevTools.on

static func mounts_open(stage_unlocked: int) -> int:
	var n := 0
	for i in MOUNTS:
		if mount_open(i, stage_unlocked):
			n += 1
	return n

# Damage multiplier for a turret level: +15% per level.
# Each level adds 30% (Lv.10 = 3.7x): a new turret helps, an upgraded one carries
# (Rudy, dev108: turrets should not do most of the damage at the start).
static func level_mult(level: int) -> float:
	return 1.0 + 0.3 * (level - 1)

# Coins to go from `level` to level + 1 (same rule as Gear: Lv.1 to Lv.2 costs 150).
static func upgrade_cost(level: int) -> int:
	return 150 * level

# Pilot level from total pilot XP (Rudy, 2026-11-03): levels 2-5 come fast, so a
# player who clears stage 5 is about level 5 just as the first mount opens and the
# Sentry unlocks. After that each level needs 500, 650, 800, ... more XP, and
# missions (quests) are meant to make up the difference. Home and Gear use this too.
const LEVEL_XP_EARLY := [0, 150, 330, 560, 850]   # total XP to reach levels 1..5

static func xp_for_level(level: int) -> int:
	if level <= LEVEL_XP_EARLY.size():
		return LEVEL_XP_EARLY[maxi(level, 1) - 1]
	var xp: int = LEVEL_XP_EARLY[-1]
	for l in range(LEVEL_XP_EARLY.size() + 1, level + 1):
		xp += 500 + 150 * (l - LEVEL_XP_EARLY.size() - 1)
	return xp

static func pilot_level(pilot_xp: int) -> int:
	var level := 1
	while level < 60 and pilot_xp >= xp_for_level(level + 1):
		level += 1
	return level

# Pilot XP for one run: what you destroyed (score / 50), plus a bonus the first time a
# stage is cleared (80 for stage 1, +20 per stage).
static func first_clear_bonus(stage: int) -> int:
	return 60 + 20 * stage

static func strong_text(id: String) -> String:
	var s: Array = TURRETS[id].strong
	if s.is_empty():
		return "all-rounder"
	var names: Array = []
	for t in s:
		names.append(TRAIT_NAMES.get(t, t))
	return "strong vs " + ", ".join(names)

# Bonus multiplier for this turret against an enemy with these traits.
static func trait_mult(id: String, traits: Array) -> float:
	for t in TURRETS[id].strong:
		if traits.has(t):
			return 1.0 + (BOSS_TRAIT_BONUS if traits.has("boss") else TRAIT_BONUS)
	return 1.0

# Loadout and levels from a save dictionary, cleaned up.
static func read(save: Dictionary) -> Dictionary:
	var t: Dictionary = save.get("turrets", {}) if typeof(save.get("turrets", {})) == TYPE_DICTIONARY else {}
	var loadout: Array = DEFAULT_LOADOUT.duplicate()
	var saved = t.get("loadout", null)
	if typeof(saved) == TYPE_ARRAY:
		for i in mini(MOUNTS, saved.size()):
			var id := String(saved[i])
			# each turret stands on one mount at most
			loadout[i] = id if TURRETS.has(id) and TURRETS[id].ready and not loadout.slice(0, i).has(id) else ""
	# upgrade tracks {id: {atk, rate, range}}; an old save's single level becomes its ATK
	var tracks := {}
	var lv = t.get("levels", {})
	if typeof(lv) == TYPE_DICTIONARY:
		for id in lv:
			if TURRETS.has(id):
				tracks[id] = {"atk": clampi(int(lv[id]), 1, MAX_TRACK), "rate": 1, "range": 1}
	var tr = t.get("tracks", {})
	if typeof(tr) == TYPE_DICTIONARY:
		for id in tr:
			if TURRETS.has(id) and typeof(tr[id]) == TYPE_DICTIONARY:
				var one := {}
				for k in TRACKS:
					one[k] = clampi(int(tr[id].get(k, 1)), 1, MAX_TRACK)
				tracks[id] = one
	var levels := {}
	for id in tracks:
		levels[id] = level_of(tracks[id])
	# owned turrets (dev172): bought; a save from before keeps what its pilot level had unlocked
	var owned: Array = ["sentry"]
	var ow = t.get("owned", null)
	if typeof(ow) == TYPE_ARRAY:
		for id in ow:
			if TURRETS.has(String(id)) and not owned.has(String(id)):
				owned.append(String(id))
	else:
		var plevel := pilot_level(int(save.get("pilot_xp", 0)))
		for id in TURRETS:
			if plevel >= int(TURRETS[id].unlock) and not owned.has(id):
				owned.append(id)
	return {"loadout": loadout, "levels": levels, "tracks": tracks, "owned": owned}

# ---- upgrade tracks and milestones (Rudy, dev128) ----
# Every turret has three tracks, each Lv.1-20, bought separately: ATK (damage per hit),
# Rate (fires / charges faster) and Range (its reach: Sentry range, Lance beam width, Storm
# cloud, Gravity pull, Swarm drone flight time, Prism fan). Its special tricks come from
# power cards in a run, not from here. The turret's level = the three added up (Lv.1-58);
# every 5 levels is a milestone: +5% damage each and a star on its tile.
const TRACKS := ["atk", "rate", "range"]
const TRACK_NAMES := {"atk": "ATK", "rate": "Rate", "range": "Range"}
const MAX_TRACK := 20
const REACH := {"sentry": ["range"], "lance": ["width"], "storm": ["cloud_r"], "gravity": ["radius", "crush_r"],
	"swarm": ["life"], "prism": ["spread", "split_h"],
	"repair": ["heal"], "tesla": ["range"], "cryo": ["reach"], "mines": ["blast"], "beacon": ["range", "mark"], "flak": ["range", "blast"]}

static func one_tracks(tracks: Dictionary, id: String) -> Dictionary:
	return tracks.get(id, {"atk": 1, "rate": 1, "range": 1})

static func level_of(tr: Dictionary) -> int:
	return int(tr.get("atk", 1)) + int(tr.get("rate", 1)) + int(tr.get("range", 1)) - 2

static func milestones(level: int) -> int:
	return level / 5

static func atk_mult(l: int) -> float:
	return 1.0 + 0.2 * (l - 1)          # Lv.20 = 4.8x

static func rate_mult(l: int) -> float:
	return 1.0 + 0.04 * (l - 1)         # Lv.20 = 1.76x as often

static func reach_mult(l: int) -> float:
	return 1.0 + 0.03 * (l - 1)         # Lv.20 = +57% reach

static func milestone_mult(level: int) -> float:
	return 1.0 + 0.05 * milestones(level)

# The turret's numbers with its upgrades in (battle uses this copy, t.def).
static func stats(id: String, tr: Dictionary) -> Dictionary:
	var d: Dictionary = TURRETS[id].duplicate(true)
	d.damage = float(d.damage) * atk_mult(int(tr.atk)) * milestone_mult(level_of(tr)) * TURRET_TUNE
	if d.has("heal"):   # the Repair Node: ATK is how much it mends (no TURRET_TUNE: shield points, not damage)
		d.heal = float(d.heal) * atk_mult(int(tr.atk)) * milestone_mult(level_of(tr))
	d.every = float(d.every) / rate_mult(int(tr.rate))
	for k in REACH.get(id, []):
		d[k] = float(d[k]) * reach_mult(int(tr.range))
	return d

# coins for one track from `level` to level + 1, and the parts (Parts.need on a 1-10 scale)
static func track_cost(level: int) -> int:
	return 60 * level

static func track_parts(level: int) -> Dictionary:
	return Parts.need(level / 2)

# ---- buying turrets (dev172, the heroes model), elements and roles ----
const TURRET_TUNE := 2.5   # one knob for the whole base damage (sim dev172, human bot + auto kit: 1.0 = turrets 7-17% of the damage, 2.0 = 10-25%, 2.5 = about 30% from stage 20)

static func owned(t: Dictionary, id: String) -> bool:
	return id == "sentry" or Array(t.get("owned", [])).has(id) or DevTools.on

static func grade(id: String) -> int:
	return clampi(int(TURRETS[id].get("grade", 1)), 1, Heroes.GRADES.size()) if TURRETS.has(id) else 1

static func stars_text(id: String) -> String:
	return "★".repeat(grade(id))

static func element(id: String) -> String:
	return String(TURRETS[id].get("element", "ion")) if TURRETS.has(id) else "ion"

static func role(id: String) -> String:
	return String(TURRETS[id].get("role", "")) if TURRETS.has(id) else ""

# the turret's element against this stage's family (Heroes: weak x1.35, resists x0.75)
static func element_mult(id: String, stage: int) -> float:
	return Heroes.element_mult(element(id), stage)

static func gate(id: String) -> int:
	return int(TURRETS[id].get("stage", 0)) if TURRETS.has(id) else 0

static func gate_open(save: Dictionary, id: String) -> bool:
	return int(save.get("stage_unlocked", 1)) > gate(id) or DevTools.on

static func parts_needed(id: String) -> Dictionary:
	var c: Dictionary = TURRETS[id].get("cost", {})
	var needs := {}
	for k in Parts.all_order():   # parts and materials (the Dread Beacon asks for Dark Embers)
		if int(c.get(k, 0)) > 0:
			needs[k] = int(c[k])
	return needs

static func cost_text(id: String) -> String:
	var c: Dictionary = TURRETS[id].get("cost", {})
	var bits: Array = []
	if int(c.get("coins", 0)) > 0:
		bits.append("%s coins" % UIKit.num(int(c.coins)))
	var needs := parts_needed(id)
	if not needs.is_empty():
		bits.append(Parts.text(needs))
	return " + ".join(bits) if not bits.is_empty() else "Free"

static func crystal_price(id: String) -> int:
	return int(TURRETS[id].get("crystals", 0))

static func can_afford(save: Dictionary, id: String) -> bool:
	var c: Dictionary = TURRETS[id].get("cost", {})
	return int(save.get("coins", 0)) >= int(c.get("coins", 0)) and Parts.has_all(Parts.read(save), parts_needed(id))

# Buy a turret: coins + parts, or the crystal price. Changes `save` and `t` (Turrets.read)
# in place; returns "" on success or why it failed. The caller writes t.owned back.
static func unlock(save: Dictionary, t: Dictionary, id: String, with_crystals: bool) -> String:
	if not TURRETS.has(id):
		return "No such turret"
	if owned(t, id):
		return "Already yours"
	if not gate_open(save, id):
		return "Clear stage %d first" % gate(id)
	if with_crystals:
		var price := crystal_price(id)
		if price <= 0:
			return "Not for crystals"
		if int(save.get("crystals", 0)) < price:
			return "Not enough crystals"
		save["crystals"] = int(save.get("crystals", 0)) - price
	else:
		var c: Dictionary = TURRETS[id].get("cost", {})
		var why := Parts.pay(save, int(c.get("coins", 0)), parts_needed(id), false)
		if why != "":
			return why
	t.owned.append(id)
	return ""
