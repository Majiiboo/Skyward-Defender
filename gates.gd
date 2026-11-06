class_name Gates
extends RefCounted
# STARS: one standard for how heroes, turrets and drone bodies grow (Rudy, 2026-11-06,
# DESIGN-stars.md). Nothing is locked behind a stage. A higher star is locked behind BUILDING the
# thing: level it to its cap, collect for it, evolve it; the new star raises the cap and the
# power. Five gold stars, then five RED stars (the endgame ladder). Pilot level only opens the
# door to each star. "premium": true on an item = crystals only (no coin price).
# Weapons grow by rarity (copies merged in the Workshop, GearData) and are not here.

const GOLD := 5
const MAX_STAR := 10               # 1-5 gold, 6-10 = red 1-5
const GOLD_STEP := 0.08            # power per gold star past the first
const RED_STEP := 0.12             # power per red star
const DOOR := [0, 5, 12, 20, 28, 35, 40, 45, 50, 55]   # pilot level that opens star i + 1: money buys speed, play buys the ceiling (Rudy)
const RED_COL := Color(1.0, 0.35, 0.4)
const GOLD_COL := Color(1.0, 0.82, 0.3)

# level cap per star: `step` levels a star (hero 10, turret track 4, drone 2)
const CAP_STEP := {"hero": 10, "turret": 4, "drone": 2}

# what the next star asks for, by kind: coins, essences of the element, the hero's shards, coils
# or the drone line; index = the star reached - 2 (gold 2 first)
const NEED := {
	"hero": {
		"coins":    [2000, 6000, 15000, 40000, 60000, 90000, 130000, 170000, 220000],
		"shards":   [5, 15, 40, 100, 150, 200, 300, 400, 500],
		"essence":  [2, 5, 10, 20, 30, 40, 50, 60, 80],
		"coil":     [0, 0, 0, 1, 2, 3, 4, 5, 6]},
	"turret": {
		"coins":    [1500, 4000, 10000, 25000, 40000, 65000, 90000, 120000, 150000],
		"essence":  [2, 5, 10, 20, 30, 40, 50, 60, 80],
		"coil":     [0, 0, 0, 1, 2, 3, 4, 5, 6]},
	"drone": {
		"coins":    [1500, 4000, 10000, 25000, 40000, 65000, 90000, 120000, 150000],
		"essence":  [2, 5, 10, 20, 30, 40, 50, 60, 80],
		"rotor":    [2, 0, 0, 0, 0, 0, 0, 0, 0],
		"gyro":     [0, 2, 0, 0, 0, 0, 0, 0, 0],
		"flightcore": [0, 0, 1, 2, 3, 4, 5, 6, 7]},
}

static func clamp_star(star: int) -> int:
	return clampi(star, 1, MAX_STAR)

static func is_red(star: int) -> bool:
	return star > GOLD

static func gold(star: int) -> int:
	return mini(clamp_star(star), GOLD)

static func red(star: int) -> int:
	return maxi(clamp_star(star) - GOLD, 0)

# "★★★" (gold) or the red count "★★" in red (the caller colours it with color())
static func text(star: int) -> String:
	return "★".repeat(red(star)) if is_red(star) else "★".repeat(gold(star))

# for a one-colour tile badge: red stars carry an R ("R★★")
static func badge(star: int) -> String:
	return ("R" + text(star)) if is_red(star) else text(star)

static func color(star: int) -> Color:
	return RED_COL if is_red(star) else GOLD_COL

# "3 stars", "red 2"
static func long_text(star: int) -> String:
	return ("red %d" % red(star)) if is_red(star) else ("%d star%s" % [gold(star), "" if gold(star) == 1 else "s"])

# the power multiplier a star gives (ATK, HP, fortress; turret damage; drone damage)
static func power_mult(star: int) -> float:
	return 1.0 + GOLD_STEP * (gold(star) - 1) + RED_STEP * red(star)

# the highest level a `kind` can reach at `star`
static func level_cap(kind: String, star: int) -> int:
	return int(CAP_STEP.get(kind, 10)) * clamp_star(star)

static func max_level(kind: String) -> int:
	return level_cap(kind, MAX_STAR)

# ---- the next star
# the pilot level that opens star `star` (0 = none)
static func door(star: int) -> int:
	return int(DOOR[clampi(star - 1, 0, DOOR.size() - 1)])

static func door_open(save: Dictionary, star: int) -> bool:
	return DevTools.on or Turrets.pilot_level(int(save.get("pilot_xp", 0))) >= door(star)

# what star `star` (2..10) asks for: {"coins": n, "shards": n (heroes), "mats": {id: n}}
static func need(kind: String, star: int, element: String) -> Dictionary:
	var i := clampi(star - 2, 0, 8)
	if star < 2 or star > MAX_STAR or not NEED.has(kind):
		return {"coins": 0, "shards": 0, "mats": {}}
	var n: Dictionary = NEED[kind]
	var mats := {}
	if int(n.essence[i]) > 0:
		mats[Materials.essence_of(element)] = int(n.essence[i])
	for k in ["coil", "rotor", "gyro", "flightcore"]:
		if n.has(k) and int(n[k][i]) > 0:
			mats[k] = int(n[k][i])
	return {"coins": int(n.coins[i]), "shards": int(n.get("shards", [0, 0, 0, 0, 0, 0, 0, 0, 0])[i]), "mats": mats}

# "5 shards + 2 Energy Spark + 2,000 coins"
static func need_text(nd: Dictionary) -> String:
	var bits: Array = []
	if int(nd.get("shards", 0)) > 0:
		bits.append("%d shards" % int(nd.shards))
	if not Dictionary(nd.get("mats", {})).is_empty():
		bits.append(Parts.text(nd.mats))
	if int(nd.get("coins", 0)) > 0:
		bits.append("%s coins" % UIKit.num(int(nd.coins)))
	return " + ".join(bits)

# Why the next star cannot be taken now: "" when it can. `level` = the item's level now,
# `shards` = the hero's shards (0 for turrets and drones). Checks in the order the player
# should fix them: the door, the level cap, then the collection and the coins.
static func why_not(save: Dictionary, kind: String, star: int, level: int, shards: int, element: String) -> String:
	if star >= MAX_STAR:
		return "Max stars"
	var nxt := star + 1
	if not door_open(save, nxt):
		return "Pilot Lv.%d first" % door(nxt)
	if level < level_cap(kind, star):
		return "Lv.%d first" % level_cap(kind, star)
	if DevTools.on:
		return ""
	var nd := need(kind, nxt, element)
	if shards < int(nd.shards):
		return "%d / %d shards" % [shards, int(nd.shards)]
	if not Parts.has_all(Parts.read(save), nd.mats):
		return "Short of %s" % Parts.text(nd.mats)
	if int(save.get("coins", 0)) < int(nd.coins):
		return "%s coins needed" % UIKit.num(int(nd.coins))
	return ""

# Pay for star `star + 1` of `kind` (coins + materials; the caller takes the shards). "" on
# success. Dev mode pays nothing.
static func pay(save: Dictionary, kind: String, star: int, element: String) -> String:
	if DevTools.on:
		return ""
	var nd := need(kind, star + 1, element)
	return Parts.pay(save, int(nd.coins), nd.mats, false)

# ---- premium
static func premium(def: Dictionary) -> bool:
	return bool(def.get("premium", false))
