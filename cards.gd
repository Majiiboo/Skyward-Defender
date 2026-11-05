class_name Cards
extends RefCounted
# Power cards offered on each run level. A card is one entry here; battle.gd
# applies "effect" to its run stats. Rarity sets draw weight and the frame.
# Four tiers: common 60%, uncommon 28%, epic 10%, legendary 2%.
# Every card has at most 3 levels (dev108); the third pick (the last for a card that stops
# at 2) is its overcharge, and a card at its max is never offered again. Overcharge adds
# a bonus on top. Fusion: two overcharged cards of a pair unlock a fusion card that
# keeps both powers and adds its own (FUSIONS; offered in the middle slot of a pick).

const WEIGHTS := {"common": 60.0, "uncommon": 28.0, "epic": 10.0, "legendary": 2.0}
const FRAME := {"common": "res://cards/frame_common.png", "uncommon": "res://cards/frame_uncommon.png",
	"epic": "res://cards/frame_epic.png", "legendary": "res://cards/frame_legendary.png",
	"fusion": "res://cards/frame_legendary.png"}   # battle.gd uses cards/frame_fusion.png when present
const COLOR := {"common": Color(0.75, 0.78, 0.85), "uncommon": Color(0.2, 0.9, 1.0),
	"epic": Color(0.71, 0.55, 1.0), "legendary": Color(1.0, 0.8, 0.3), "fusion": Color(1.0, 0.45, 0.8)}

const CARDS := {
	# offence
	"rapid_pulse":     {"name": "Rapid Pulse",     "family": "pilot",  "rarity": "common",    "max": 3, "icon": "nav_battle",
		"desc": "Fire rate +10%"},
	"heavy_bolts":     {"name": "Heavy Bolts",     "family": "pilot",  "rarity": "common",    "max": 3, "icon": "nav_battle",
		"desc": "Bolt damage +15%: bigger, hotter bolts"},
	"burst_fire":      {"name": "Burst Fire",      "family": "pilot",  "rarity": "uncommon",  "max": 3, "icon": "nav_battle",
		"desc": "Fires bursts of 2, then 3, then 4 bolts"},
	"piercing_rounds": {"name": "Piercing Rounds", "family": "pilot",  "rarity": "uncommon",  "max": 3, "icon": "nav_battle",
		"desc": "Bolts pass through 1 more bug per level"},
	"chain_spark":     {"name": "Chain Spark",     "family": "pilot",  "rarity": "uncommon",  "max": 3, "icon": "event",
		"desc": "Every 5th bolt sparks to 1 more bug per level"},
	"frost_rounds":    {"name": "Frost Rounds",    "family": "pilot",  "rarity": "uncommon",  "max": 3, "icon": "event",
		"desc": "Hits slow bugs by 15% (more each level)"},
	"turret_overclock": {"name": "Turret Overclock", "family": "base",  "rarity": "uncommon",  "max": 3, "icon": "chest", "needs_turret": true,
		"desc": "Your turrets fire 15% faster"},
	# defence
	"aegis":           {"name": "Aegis",           "family": "pilot",  "rarity": "uncommon",  "max": 2, "icon": "nav_gear",
		"desc": "+30 max HP, healed now, and a shield of light"},
	"reinforced_hull": {"name": "Reinforced Hull", "family": "base",   "rarity": "common",    "max": 3, "icon": "chest",
		"desc": "Base shield +30 and hull +20, repaired now"},
	"shield_recharge": {"name": "Shield Recharge", "family": "base",   "rarity": "uncommon",  "max": 3, "icon": "chest", "from_level": 4,
		"desc": "Shield recharges 1%/s, more per level"},
	# utility
	"magnet":          {"name": "Magnet",          "family": "pilot",  "rarity": "common",    "max": 3, "icon": "gem",
		"desc": "Pulls gems and coins from further, +10% XP"},
	# turret cards (Rudy, dev133): only offered while that turret stands on the base ("turret").
	# Levels 1-2 EXTEND it (more of what it does), the 3rd pick (overcharge) CHANGES how it works.
	"sentry_ricochet": {"name": "Ricochet",       "family": "base",  "rarity": "uncommon",  "max": 3, "turret": "sentry",
		"desc": "Sentry bolts bounce to 1 more bug per level"},
	"lance_focus":     {"name": "Focused Lance",  "family": "base",  "rarity": "uncommon",  "max": 3, "turret": "lance",
		"desc": "Lance beam +40% wider and +30% damage"},
	"storm_chain":     {"name": "Chain Storm",    "family": "base",  "rarity": "uncommon",  "max": 3, "turret": "storm",
		"desc": "Lightning jumps to 2 more bugs per level"},
	"gravity_horizon": {"name": "Event Horizon",  "family": "base",  "rarity": "uncommon",  "max": 3, "turret": "gravity",
		"desc": "Gravity pull area +25% per level"},
	"swarm_surge":     {"name": "Hive Surge",     "family": "base",  "rarity": "uncommon",  "max": 3, "turret": "swarm",
		"desc": "Swarm launches 2 more drones per level"},
	"prism_fan":       {"name": "Wide Prism",     "family": "base",  "rarity": "uncommon",  "max": 3, "turret": "prism",
		"desc": "Prism splits into 2 more beams per level"},
	# one-shot
	"nova_burst":      {"name": "Nova Burst",      "family": "wild",   "rarity": "legendary", "max": 1, "icon": "event",
		"desc": "Clears every enemy on screen (one use)"},
}

# Overcharge (battle.gd _overcharge).
const OVER_AT := 3
const OVERCHARGE := {
	"rapid_pulse":     "Overdrive: every 8 s, 3 s at double speed",
	"heavy_bolts":     "6th bolt hits x3",
	"burst_fire":      "Last burst bolt pierces",
	"piercing_rounds": "+25% damage per bug pierced",
	"chain_spark":     "Sparks hit twice as hard",
	"frost_rounds":    "Slowed bugs take +20% damage",
	"turret_overclock": "Turret shots +30% damage",
	"aegis":           "Heals 25 HP each new wave",
	"reinforced_hull": "Base shield +40",
	"shield_recharge": "Also slowly repairs the hull",
	"magnet":          "Each gem repairs 1 shield",
	"sentry_ricochet": "Flak: Sentry hits splash nearby bugs",
	"lance_focus":     "Twin Lance: fires a second beam right after",
	"storm_chain":     "Overload: zaps can stun bugs",
	"gravity_horizon": "Black Hole: swallows enemy shots in its pull",
	"swarm_surge":     "Kamikaze: drones explode on impact",
	"prism_fan":       "Frozen Light: beams slow bugs",
}

# Fusions: both parts overcharged -> offered once per run (battle.gd _fuse).
const FUSIONS := {
	"railstorm":   {"name": "Railstorm",   "parts": ["rapid_pulse", "heavy_bolts"], "rarity": "fusion", "max": 1,
		"desc": "Every 4th bolt: a piercing rail shot, x2"},
	"gem_barrage": {"name": "Gem Barrage", "parts": ["burst_fire", "magnet"], "rarity": "fusion", "max": 1,
		"desc": "Every 10 gems fire 6 bolts at the nearest bugs"},
	"bastion":     {"name": "Bastion",     "parts": ["reinforced_hull", "aegis"], "rarity": "fusion", "max": 1,
		"desc": "A breaking shield blasts bugs back"},
	"thunder_lance": {"name": "Thunder Lance", "parts": ["chain_spark", "piercing_rounds"], "rarity": "fusion", "max": 1,
		"desc": "Bugs a bolt passes through throw sparks"},
}

# the pick on which a card overcharges: the 3rd, or the last for cards that stop sooner
static func over_level(id: String) -> int:
	return mini(OVER_AT, int(CARDS[id].max))

# true when picking this card now (it has `lvl` picks so far) overcharges it
static func overcharges(id: String, lvl: int) -> bool:
	return OVERCHARGE.has(id) and lvl + 1 == over_level(id)

static func overcharged(levels: Dictionary, id: String) -> bool:
	return OVERCHARGE.has(id) and int(levels.get(id, 0)) >= over_level(id)

# a card or a fusion
static func def(id: String) -> Dictionary:
	return CARDS[id] if CARDS.has(id) else FUSIONS[id]

# fusions whose two parts are overcharged and that this run hasn't taken yet
static func fusions_ready(levels: Dictionary) -> Array:
	var out: Array = []
	for f in FUSIONS:
		if not levels.has(f) and overcharged(levels, FUSIONS[f].parts[0]) and overcharged(levels, FUSIONS[f].parts[1]):
			out.append(f)
	return out

# Pick `count` distinct cards from the pool, weighted by rarity, skipping maxed ones.
# run_level: cards with "from_level" only show up from that run level on.
# mounted: the turret types on the base (turret cards need theirs).
static func draw(levels: Dictionary, count: int = 3, rng: RandomNumberGenerator = null, run_level: int = 99, has_turret: bool = true, mounted: Array = []) -> Array:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var pool: Array = []
	for id in CARDS:
		if int(levels.get(id, 0)) < int(CARDS[id].max) and run_level >= int(CARDS[id].get("from_level", 1)) and (has_turret or not CARDS[id].get("needs_turret", false)) and (not CARDS[id].has("turret") or mounted.has(CARDS[id].turret)):
			pool.append(id)
	var picks: Array = []
	while picks.size() < count and pool.size() > 0:
		var total := 0.0
		for id in pool:
			total += float(WEIGHTS[CARDS[id].rarity])
		var r := rng.randf() * total
		var chosen: String = pool[pool.size() - 1]
		for id in pool:
			r -= float(WEIGHTS[CARDS[id].rarity])
			if r <= 0.0:
				chosen = id
				break
		picks.append(chosen)
		pool.erase(chosen)
	return picks
