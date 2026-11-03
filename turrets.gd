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
# unlock = pilot level needed. strong = enemy traits it does +50% against.
const TURRETS := {
	"sentry":  {"name": "Sentry",         "art": "sentry",  "rarity": "common",    "unlock": 5, "ready": true,
		"strong": [], "glow": Color(0.2, 0.85, 1.0),
		"damage": 0.9, "every": 0.85, "range": 430.0,
		"desc": "Twin cannons, steady fire at the nearest enemy."},
	"lance":   {"name": "Lance Pylon",    "art": "lance",   "rarity": "rare",      "unlock": 8, "ready": true,
		"strong": ["armoured", "boss"], "glow": Color(0.75, 0.9, 1.0),
		"damage": 1.8, "every": 2.6, "width": 26.0,
		"desc": "Charges, then fires a spear of light straight up through its whole column."},
	"storm":   {"name": "Storm Spire",    "art": "storm",   "rarity": "epic",      "unlock": 11, "ready": true,
		"strong": ["swarm", "shielded"], "glow": Color(0.6, 0.55, 1.0),
		"damage": 0.9, "every": 1.8, "chain": 2, "cloud_r": 125.0, "cloud_h": 300.0,
		"desc": "Builds a storm cloud above the base; lightning jumps between enemies inside it."},
	"gravity": {"name": "Gravity Anchor", "art": "gravity", "rarity": "epic",      "unlock": 14, "ready": true,
		"strong": ["swarm", "fast"], "glow": Color(0.71, 0.55, 1.0),
		"damage": 2.0, "every": 3.2, "pull": 2.0, "radius": 115.0, "crush_r": 85.0, "height": 230.0,
		"desc": "Pulls nearby enemies to one point, then crushes them on a pulse."},
	"swarm":   {"name": "Swarm Hive",     "art": "swarm",   "rarity": "rare",      "unlock": 18, "ready": true,
		"strong": ["fast", "high"], "glow": Color(0.2, 0.85, 1.0),
		"damage": 0.35, "every": 3.5, "count": 4, "life": 4.0, "speed": 230.0,
		"desc": "Releases micro-drones that chase enemies for a few seconds."},
	"prism":   {"name": "Prism Tower",    "art": "prism",   "rarity": "legendary", "unlock": 22, "ready": true,
		"strong": ["wide"], "glow": Color(1.0, 0.85, 0.6),
		"damage": 0.5, "every": 3.0, "beams": 5, "spread": 1.0, "split_h": 300.0,
		"desc": "Splits one bright shot into a fan of beams across the screen."},
}

const TRAIT_NAMES := {"armoured": "armoured", "boss": "bosses", "swarm": "swarm", "shielded": "shielded",
	"fast": "fast", "high": "high flyers", "wide": "wide waves"}

# stage_unlocked = the save's highest playable stage (last cleared stage + 1).
static func mount_open(i: int, stage_unlocked: int) -> bool:
	return stage_unlocked > int(MOUNT_OPENS_AFTER[i])

static func mounts_open(stage_unlocked: int) -> int:
	var n := 0
	for i in MOUNTS:
		if mount_open(i, stage_unlocked):
			n += 1
	return n

# Damage multiplier for a turret level: +15% per level.
static func level_mult(level: int) -> float:
	return 1.0 + 0.15 * (level - 1)

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
	var levels := {}
	var lv = t.get("levels", {})
	if typeof(lv) == TYPE_DICTIONARY:
		for id in lv:
			if TURRETS.has(id):
				levels[id] = clampi(int(lv[id]), 1, MAX_LEVEL)
	return {"loadout": loadout, "levels": levels}
