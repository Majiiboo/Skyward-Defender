class_name Talents
extends RefCounted
# The PILOT TALENT MAP (Rudy, queue 16 e, dev197): a path of 40 nodes bought IN ORDER, each a
# small permanent bonus for every hero (bolt damage, turret damage, HP, crit, coins, base,
# fire rate, gem XP, crit damage, magnet). Every 10th node also unlocks a NEW power card for
# runs (Cards "talent" key). Costs rise: coins first, then cores, then essences, then Prime
# Coils; and node N opens at pilot level N (a talent a level: the brake on money, DESIGN-stars.md).
# Save: "talents" = how many nodes are bought (they are a path, so a number is enough).

const SIZE := 40
# the ten-node cycle: stat, the bonus one node gives, the short tag on its tile
const CYCLE := [
	{"stat": "damage",     "per": 0.015, "tag": "ATK",   "name": "Bolt damage",   "fmt": "+%.1f%%", "x": 100.0},
	{"stat": "turret_dmg", "per": 0.02,  "tag": "TUR",   "name": "Turret damage", "fmt": "+%.0f%%", "x": 100.0},
	{"stat": "hp_mult",    "per": 0.02,  "tag": "HP",    "name": "Hero HP",       "fmt": "+%.0f%%", "x": 100.0},
	{"stat": "crit_rate",  "per": 0.005, "tag": "CRIT",  "name": "Crit rate",     "fmt": "+%.1f%%", "x": 100.0},
	{"stat": "coins",      "per": 0.03,  "tag": "COIN",  "name": "Coins",         "fmt": "+%.0f%%", "x": 100.0},
	{"stat": "fortress",   "per": 0.02,  "tag": "BASE",  "name": "Base HP",       "fmt": "+%.0f%%", "x": 100.0},
	{"stat": "fire_rate",  "per": 0.01,  "tag": "RATE",  "name": "Fire rate",     "fmt": "+%.0f%%", "x": 100.0},
	{"stat": "gem_xp",     "per": 0.03,  "tag": "XP",    "name": "Gem XP",        "fmt": "+%.0f%%", "x": 100.0},
	{"stat": "crit_dmg",   "per": 0.04,  "tag": "CRIT+", "name": "Crit damage",   "fmt": "+%.0f%%", "x": 100.0},
	{"stat": "magnet",     "per": 6.0,   "tag": "CARD",  "name": "Magnet",        "fmt": "+%.0f px", "x": 1.0},
]
# every 10th node: a new power card (cards.gd "talent": node)
const CARD_AT := {10: "focus_fire", 20: "salvage", 30: "second_wind", 40: "mirror_shell"}
const ELEMENTS := ["ion", "scavenger", "frost", "void", "nightmare", "solar"]

static func count(save: Dictionary) -> int:
	return clampi(int(save.get("talents", 0)), 0, SIZE)

# node `n` (1-based)
static func node(n: int) -> Dictionary:
	var c: Dictionary = CYCLE[(n - 1) % CYCLE.size()].duplicate()
	c["n"] = n
	c["card"] = String(CARD_AT.get(n, ""))
	return c

static func bonus_text(n: int) -> String:
	var c := node(n)
	return String(c.fmt) % (float(c.per) * float(c.x))

# "Bolt damage +1.5%" (+ "unlocks the Focus Fire card")
static func text(n: int) -> String:
	var c := node(n)
	var t := "%s %s" % [c.name, bonus_text(n)]
	if String(c.card) != "":
		t += "  ·  unlocks the %s card" % String(Cards.CARDS[c.card].name)
	return t

# the pilot level node `n` opens at
static func door(n: int) -> int:
	return n

# what node `n` costs: coins always; cores from 11, an essence (the node's element) from 21,
# Prime Coils from 31
static func cost(n: int) -> Dictionary:
	var coins := roundi(300.0 * n * (1.0 + n / 10.0))
	var mats := {}
	if n > 30:
		mats["coil"] = 1 + (n - 31) / 3
		mats[Materials.essence_of(ELEMENTS[(n - 1) % ELEMENTS.size()])] = 3
	elif n > 20:
		mats[Materials.essence_of(ELEMENTS[(n - 1) % ELEMENTS.size()])] = 1 + (n - 21) / 3
	elif n > 10:
		mats["core"] = 1 + (n - 11) / 3
	return {"coins": coins, "mats": mats}

static func cost_text(n: int) -> String:
	var c := cost(n)
	var bits: Array = ["%s coins" % UIKit.num(int(c.coins))]
	if not Dictionary(c.mats).is_empty():
		bits.append(Parts.text(c.mats))
	return " + ".join(bits)

# the next node to buy (SIZE + 1 when the map is done)
static func next(save: Dictionary) -> int:
	return count(save) + 1

# why the next node cannot be bought ("" = it can)
static func why_not(save: Dictionary) -> String:
	var n := next(save)
	if n > SIZE:
		return "Map complete"
	if not DevTools.on and Turrets.pilot_level(int(save.get("pilot_xp", 0))) < door(n):
		return "Pilot Lv.%d first" % door(n)
	if DevTools.on:
		return ""
	var c := cost(n)
	if int(save.get("coins", 0)) < int(c.coins):
		return "%s coins needed" % UIKit.num(int(c.coins))
	if not Parts.has_all(Parts.read(save), c.mats):
		return "Short of %s" % Parts.text(c.mats)
	return ""

static func affordable(save: Dictionary) -> bool:
	return why_not(save) == ""

# buy the next node; "" on success. Changes `save` in place.
static func buy(save: Dictionary) -> String:
	var why := why_not(save)
	if why != "":
		return why
	var n := next(save)
	var c := cost(n)
	why = Parts.pay(save, int(c.coins), c.mats, false)
	if why != "":
		return why
	save["talents"] = n
	return ""

# the bonuses of every node bought, as the keys Heroes.stats applies: multipliers for damage,
# turret_dmg, fortress and fire_rate; additions for hp_mult, crit_rate, coins, gem_xp, crit_dmg,
# magnet
static func bonus(save: Dictionary) -> Dictionary:
	var b := {"damage": 1.0, "turret_dmg": 1.0, "fortress": 1.0, "fire_rate": 1.0,
		"hp_mult": 0.0, "crit_rate": 0.0, "coins": 0.0, "gem_xp": 0.0, "crit_dmg": 0.0, "magnet": 0.0}
	for n in range(1, count(save) + 1):
		var c := node(n)
		var k := String(c.stat)
		if ["damage", "turret_dmg", "fortress", "fire_rate"].has(k):
			b[k] = float(b[k]) * (1.0 + float(c.per))
		else:
			b[k] = float(b[k]) + float(c.per)
	return b

# the cards the map has unlocked so far
static func cards(save: Dictionary) -> Array:
	var out: Array = []
	for n in CARD_AT:
		if count(save) >= int(n):
			out.append(String(CARD_AT[n]))
	return out
