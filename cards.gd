class_name Cards
extends RefCounted
# Power cards offered on each run level. A card is one entry here; battle.gd
# applies "effect" to its run stats. Rarity sets draw weight and the frame.
# Four tiers: common 60%, uncommon 28%, epic 10%, legendary 2%.

const WEIGHTS := {"common": 60.0, "uncommon": 28.0, "epic": 10.0, "legendary": 2.0}
const FRAME := {"common": "res://cards/frame_common.png", "uncommon": "res://cards/frame_uncommon.png",
	"epic": "res://cards/frame_epic.png", "legendary": "res://cards/frame_legendary.png"}
const COLOR := {"common": Color(0.75, 0.78, 0.85), "uncommon": Color(0.2, 0.9, 1.0),
	"epic": Color(0.71, 0.55, 1.0), "legendary": Color(1.0, 0.8, 0.3)}

const CARDS := {
	"rapid_pulse":     {"name": "Rapid Pulse",     "family": "pilot",  "rarity": "common",    "max": 5, "icon": "nav_battle",
		"desc": "Fire rate +8%"},
	"heavy_bolts":     {"name": "Heavy Bolts",     "family": "pilot",  "rarity": "common",    "max": 5, "icon": "nav_battle",
		"desc": "Bolt damage +12%"},
	"burst_fire":      {"name": "Burst Fire",      "family": "pilot",  "rarity": "uncommon",  "max": 3, "icon": "nav_battle",
		"desc": "Each trigger fires a burst: 2, then 3, then 4 bolts"},
	"aegis":           {"name": "Aegis",           "family": "pilot",  "rarity": "uncommon",  "max": 2, "icon": "nav_gear",
		"desc": "+1 heart (max 5)"},
	"magnet":          {"name": "Magnet",          "family": "pilot",  "rarity": "common",    "max": 4, "icon": "gem",
		"desc": "Gem pull range +50%"},
	"reinforced_hull": {"name": "Reinforced Hull", "family": "base",   "rarity": "common",    "max": 4, "icon": "chest",
		"desc": "Base hull +25%, and repairs that much"},
	"deploy_sentry":   {"name": "Deploy Sentry",   "family": "turret", "rarity": "uncommon",  "max": 2, "icon": "patrol",
		"desc": "Mounts a Sentry on a free mount (all full: turret damage +20%)"},
	"nova_burst":      {"name": "Nova Burst",      "family": "wild",   "rarity": "legendary", "max": 1, "icon": "event",
		"desc": "Clears every enemy on screen"},
}

# Pick `count` distinct cards from the pool, weighted by rarity, skipping maxed ones.
static func draw(levels: Dictionary, count: int = 3, rng: RandomNumberGenerator = null) -> Array:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var pool: Array = []
	for id in CARDS:
		if int(levels.get(id, 0)) < int(CARDS[id].max):
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
