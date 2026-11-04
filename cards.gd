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
	"rapid_pulse":     {"name": "Rapid Pulse",     "family": "pilot",  "rarity": "common",    "max": 3, "icon": "nav_battle",
		"desc": "Fire rate +10%"},
	"heavy_bolts":     {"name": "Heavy Bolts",     "family": "pilot",  "rarity": "common",    "max": 3, "icon": "nav_battle",
		"desc": "Bolt damage +15%"},
	"burst_fire":      {"name": "Burst Fire",      "family": "pilot",  "rarity": "uncommon",  "max": 3, "icon": "nav_battle",
		"desc": "Each trigger fires a burst: 2, then 3, then 4 bolts"},
	"aegis":           {"name": "Aegis",           "family": "pilot",  "rarity": "uncommon",  "max": 2, "icon": "nav_gear",
		"desc": "+1 heart (max 5)"},
	"magnet":          {"name": "Magnet",          "family": "pilot",  "rarity": "common",    "max": 3, "icon": "gem",
		"desc": "Pulls gems from further away"},
	"reinforced_hull": {"name": "Reinforced Hull", "family": "base",   "rarity": "common",    "max": 3, "icon": "chest",
		"desc": "Base hull +25%, and repairs that much"},
	"chain_spark":     {"name": "Chain Spark",     "family": "pilot",  "rarity": "uncommon",  "max": 3, "icon": "event",
		"desc": "Every 5th bolt sparks to 1 more bug per level"},
	"wingman":         {"name": "Wingman Drone",   "family": "pilot",  "rarity": "epic",      "max": 3, "icon": "nav_gear",
		"desc": "A drone flies at your side and shoots; faster each level"},
	"quick_study":     {"name": "Quick Study",     "family": "pilot",  "rarity": "common",    "max": 3, "icon": "gem",
		"desc": "Gems give +10% XP"},
	"shield_recharge": {"name": "Shield Recharge", "family": "base",   "rarity": "uncommon",  "max": 3, "icon": "chest", "from_level": 4,
		"desc": "Base shield recharges 1% a second (more each level)"},
	"nova_burst":      {"name": "Nova Burst",      "family": "wild",   "rarity": "legendary", "max": 1, "icon": "event",
		"desc": "Clears every enemy on screen"},
}

# Overcharge (battle.gd _overcharge).
const OVER_AT := 3
const OVERCHARGE := {
	"rapid_pulse":     "Fire rate +15% more",
	"heavy_bolts":     "6th bolt hits x3",
	"burst_fire":      "Last burst bolt pierces",
	"aegis":           "Heals 1 heart each new wave",
	"magnet":          "Each gem repairs 1 shield",
	"reinforced_hull": "Base shield +40",
	"chain_spark":     "Sparks hit twice as hard",
	"shield_recharge": "Also slowly repairs the hull",
	"wingman":         "A second drone joins",
	"quick_study":     "Level-ups need 15% less XP",
}

# Fusions: both parts overcharged -> offered once per run (battle.gd _fuse).
const FUSIONS := {
	"railstorm":   {"name": "Railstorm",   "parts": ["rapid_pulse", "heavy_bolts"], "rarity": "fusion", "max": 1,
		"desc": "Every 4th bolt is a piercing rail shot (x2 damage)"},
	"gem_barrage": {"name": "Gem Barrage", "parts": ["burst_fire", "magnet"], "rarity": "fusion", "max": 1,
		"desc": "Every 10 gems fire 6 bolts at the nearest bugs"},
	"bastion":     {"name": "Bastion",     "parts": ["reinforced_hull", "aegis"], "rarity": "fusion", "max": 1,
		"desc": "A breaking shield blasts bugs back"},
	"storm_wing":  {"name": "Storm Wing",  "parts": ["chain_spark", "wingman"], "rarity": "fusion", "max": 1,
		"desc": "Drone shots spark to 2 more bugs"},
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
static func draw(levels: Dictionary, count: int = 3, rng: RandomNumberGenerator = null, run_level: int = 99) -> Array:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var pool: Array = []
	for id in CARDS:
		if int(levels.get(id, 0)) < int(CARDS[id].max) and run_level >= int(CARDS[id].get("from_level", 1)):
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
