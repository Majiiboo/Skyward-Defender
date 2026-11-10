class_name DroneData
extends RefCounted
# The drone sidekick (Rudy, dev113: a Gear unlock instead of a power card). One drone
# flies beside the pilot in battle. You pick its BODY (how it behaves) and its weapon
# POD (how it shoots), and upgrade it with coins. Pictures: drone/body_*.png,
# drone/pod_*.png, drone/flash_*.png (Luna's batch D, tools/cut_batch_d.gd).
# Save: "drone": {"body": id, "pod": id, "level": 1..10}.
# Element (dev172, Rudy): each BODY has its OWN element (Scout Energy, Striker Fire, Warden Ice):
# a drone you own can be strong on a planet your heroes are not. Same weak / resist table.
# Pods stay jobs (what it does with the element). Support pods deal no damage.

const UNLOCK_LEVEL := 8        # pilot level that unlocks the drone
const MAX_LEVEL := 20   # 2 a star (Gates): 10 at five gold stars, 20 at red 5

const BODIES := {
	"scout":   {"name": "Scout",   "unlock": 8,  "rate": 1.3, "dmg": 0.8, "range": 380.0, "element": "ion",
		"desc": "Fire rate +30%"},
	"striker": {"name": "Striker", "unlock": 14, "rate": 1.0, "dmg": 1.15, "range": 520.0, "element": "solar",
		"desc": "Harder hits, longer range"},
	"warden":  {"name": "Warden",  "unlock": 20, "rate": 0.8, "dmg": 1.0, "range": 420.0, "guard": 5.0, "element": "frost",
		"desc": "Blocks a shot every 5 s"},
	# round 2 (Luna, dev184): three bodies BOUGHT like heroes and turrets ("grade", "cost" or
	# "crystals"); each its own machine and element (DESIGN-turrets-drones.md)
	"spark":   {"name": "Spark Bot", "unlock": 8, "rate": 1.15, "dmg": 0.9, "range": 400.0, "element": "scavenger", "grade": 2,
		"cost": {"coins": 6000, "alloy": 20, "cell": 4}, "crystals": 120, "arc": 2,
		"desc": "Hits arc to 2 more bugs"},
	"wisp":    {"name": "Wisp",      "unlock": 8, "rate": 1.0, "dmg": 1.0, "range": 460.0, "element": "void", "grade": 3,
		"cost": {"coins": 14000, "cell": 10, "core": 2}, "crystals": 280, "phase": true,
		"desc": "Its bolts pass through 1 bug"},
	"bat":     {"name": "Night Bat", "unlock": 8, "rate": 1.2, "dmg": 1.1, "range": 520.0, "element": "nightmare", "grade": 4,
		"cost": {"coins": 30000, "cell": 16, "core": 5}, "crystals": 520, "crit": 0.15,
		"desc": "Crit rate +15%"},
}
const PODS := {
	"blaster": {"name": "Twin Blaster", "unlock": 8,  "every": 0.7, "damage": 0.45,
		"desc": "Twin quick bolts"},
	"beam":    {"name": "Beam",         "unlock": 12, "every": 1.4, "damage": 1.4,
		"desc": "Instant beam, never misses"},
	# support pods (dev172, DESIGN-turrets-drones.md): no guns, a job instead ("job"); they use
	# (Luna'"'"'s pod pictures arrived with drones round 2)
	"repair":  {"name": "Repair Pod",   "unlock": 10, "every": 0.0, "damage": 0.0, "job": "repair", "heal": 1.5,
		"desc": "No guns: patches the base shield 1.5 a second"},
	"magnet":  {"name": "Magnet Pod",   "unlock": 12, "every": 0.0, "damage": 0.0, "job": "magnet", "reach": 150.0,
		"desc": "No guns: gathers gems and coins near it for you"},
	"missile": {"name": "Missiles",     "unlock": 16, "every": 2.2, "damage": 1.6, "splash": 55.0,
		"desc": "Homing missile with splash"},
}

static func read(save: Dictionary) -> Dictionary:
	var d = save.get("drone", {})
	if typeof(d) != TYPE_DICTIONARY:
		d = {}
	var body := String(d.get("body", "scout"))
	var pod := String(d.get("pod", "blaster"))
	var owned: Array = ["scout", "striker", "warden"]   # the first three stay level-gated; bought ones listed here
	var ow = d.get("owned", [])
	if typeof(ow) == TYPE_ARRAY:
		for id in ow:
			if BODIES.has(String(id)) and not owned.has(String(id)):
				owned.append(String(id))
	# stars per body (Gates, DESIGN-stars.md)
	var stars := {}
	var sv = d.get("stars", {})
	if typeof(sv) == TYPE_DICTIONARY:
		for id in sv:
			if BODIES.has(String(id)):
				stars[String(id)] = Gates.clamp_star(int(sv[id]))
	return {"body": body if BODIES.has(body) else "scout", "pod": pod if PODS.has(pod) else "blaster", "owned": owned,
		"level": clampi(int(d.get("level", 1)), 1, MAX_LEVEL), "stars": stars,
		"support": String(d.get("support", "")) if SUPPORT.has(String(d.get("support", ""))) else ""}

static func unlocked(pilot_level: int) -> bool:
	return pilot_level >= UNLOCK_LEVEL or DevTools.on

# +25% per level (Lv.10 = 3.25x)
static func level_mult(level: int) -> float:
	return 1.0 + 0.25 * (level - 1)

static func upgrade_cost(level: int) -> int:
	return 140 * level

# Milestones (Rudy, dev134): Lv.5 = fires 20% faster, Lv.10 = +25% damage.
const MILESTONES := [[5, "Fire rate +20%"], [10, "Damage +25%"]]

static func rate_bonus(level: int) -> float:
	return 1.2 if level >= 5 else 1.0

static func dmg_bonus(level: int) -> float:
	return 1.25 if level >= 10 else 1.0

# "Fire rate +20% at Lv.5" style line for the Gear page
static func milestone_text(level: int) -> String:
	var bits: Array = []
	for m in MILESTONES:
		bits.append(("%s (got)" if level >= int(m[0]) else "%s at Lv.%d") % ([m[1]] if level >= int(m[0]) else [m[1], m[0]]))
	return "  ·  ".join(bits)

# the picture a pod uses (support pods borrow one until Luna paints theirs)
static func pod_art(pod: String) -> String:
	return String(PODS[pod].get("art", pod)) if PODS.has(pod) else pod

static func pod_job(pod: String) -> String:
	return String(PODS[pod].get("job", "attack")) if PODS.has(pod) else "attack"

# the body's own element (Heroes.ELEMENTS ids); Energy when unknown
static func body_element(body: String) -> String:
	return String(BODIES[body].get("element", "ion")) if BODIES.has(body) else "ion"

# ---- bought bodies (round 2, the heroes model) ----
static func is_bought(body: String) -> bool:
	return BODIES.has(body) and BODIES[body].has("cost")

# can this body be used: the first three by pilot level, the bought ones when owned
static func body_open(dr: Dictionary, body: String, pilot_level: int) -> bool:
	if DevTools.on:
		return true
	if is_bought(body):
		return Array(dr.get("owned", [])).has(body)
	return pilot_level >= int(BODIES[body].unlock)

static func grade(body: String) -> int:
	return clampi(int(BODIES[body].get("grade", 1)), 1, 5) if BODIES.has(body) else 1

# no stage gates (Rudy, 2026-11-06)
static func gate(_body: String) -> int:
	return 0

static func gate_open(_save: Dictionary, _body: String) -> bool:
	return true

static func premium(body: String) -> bool:
	return BODIES.has(body) and Gates.premium(BODIES[body])

# ---- stars (Gates, DESIGN-stars.md): the drone's level cap and damage follow the star of the
# BODY on duty (2 levels a star); the next star needs the level at the cap plus essences of the
# body's element, the drone line (rotors, gyros, flight cores) and coins
static func star(dr: Dictionary, body: String = "") -> int:
	var b := body if body != "" else String(dr.get("body", "scout"))
	return Gates.clamp_star(int(Dictionary(dr.get("stars", {})).get(b, 1)))

static func level_cap(dr: Dictionary) -> int:
	return Gates.level_cap("drone", star(dr))

static func star_mult(dr: Dictionary) -> float:
	return Gates.power_mult(star(dr))

static func star_need(dr: Dictionary) -> Dictionary:
	return Gates.need("drone", star(dr) + 1, body_element(String(dr.body)))

static func why_not_star(save: Dictionary, dr: Dictionary) -> String:
	return Gates.why_not(save, "drone", star(dr), int(dr.level), 0, body_element(String(dr.body)))

# take the body's next star: pays (Gates.pay), raises dr.stars[body]; "" on success
static func star_up(save: Dictionary, dr: Dictionary) -> String:
	var why := why_not_star(save, dr)
	if why != "":
		return why
	why = Gates.pay(save, "drone", star(dr), body_element(String(dr.body)))
	if why != "":
		return why
	if not dr.has("stars"):
		dr["stars"] = {}
	dr.stars[String(dr.body)] = star(dr) + 1
	return ""

static func stars_text(body: String) -> String:
	return "★".repeat(grade(body))

static func parts_needed(body: String) -> Dictionary:
	var c: Dictionary = BODIES[body].get("cost", {})
	var needs := {}
	for k in Parts.ORDER:
		if int(c.get(k, 0)) > 0:
			needs[k] = int(c[k])
	return needs

static func cost_text(body: String) -> String:
	if premium(body):
		return "Crystals only"
	var c: Dictionary = BODIES[body].get("cost", {})
	var bits: Array = []
	if int(c.get("coins", 0)) > 0:
		bits.append("%s coins" % UIKit.num(int(c.coins)))
	var needs := parts_needed(body)
	if not needs.is_empty():
		bits.append(Parts.text(needs))
	return " + ".join(bits) if not bits.is_empty() else "Free"

static func crystal_price(body: String) -> int:
	return int(BODIES[body].get("crystals", 0))

# Buy a body: coins + parts, or the crystal price; "" on success. The caller writes dr back.
static func unlock(save: Dictionary, dr: Dictionary, body: String, with_crystals: bool) -> String:
	if not is_bought(body):
		return "Not for sale"
	if Array(dr.owned).has(body):
		return "Already yours"
	if with_crystals:
		var price := crystal_price(body)
		if int(save.get("crystals", 0)) < price:
			return "Not enough crystals"
		save["crystals"] = int(save.get("crystals", 0)) - price
	else:
		if premium(body):
			return "Crystals only"
		var c: Dictionary = BODIES[body].get("cost", {})
		var why := Parts.pay(save, int(c.get("coins", 0)), parts_needed(body), false)
		if why != "":
			return why
	dr.owned.append(body)
	return ""

# THE SUPPORT DRONE (2026-11-10, the drone squad; Rudy: "helpers as drones", "maybe one [building]
# will give you an extra drone"). A second drone that does a JOB instead of shooting. It flies only
# while a Hangar stands on the base (Base), and the Hangar's level makes it better at its job.
# Save drone.support = one of these ids ("" = none).
const SUPPORT := {
	"shield":    {"name": "Guard", "art": "body_warden", "col": Color(0.31, 0.88, 1.0)},
	"collector": {"name": "Collector", "art": "pod_magnet", "col": Color(1.0, 0.78, 0.27)},
	"medic":     {"name": "Medic", "art": "pod_repair", "col": Color(0.44, 0.94, 0.72)},
}
const SUPPORT_ORDER := ["shield", "collector", "medic"]

static func support_open(save: Dictionary) -> bool:
	return DevTools.on or Array(Base.stats(save).on).has("hangar")

static func hangar_level(save: Dictionary) -> int:
	return maxi(Base.level(Base.read(save), "hangar"), 1)

# seconds between the hits the Guard blocks
static func guard_every(lvl: int) -> float:
	return maxf(10.5 - 0.5 * lvl, 5.0)

# share of the hero's health the Medic gives back each second
static func medic_rate(lvl: int) -> float:
	return 0.004 + 0.0006 * lvl

# how far the Collector reaches for pickups
static func collect_reach(lvl: int) -> float:
	return 170.0 + 14.0 * lvl

static func support_text(id: String, lvl: int) -> String:
	match id:
		"shield": return "Blocks a hit on your hero every %.1f s" % guard_every(lvl)
		"collector": return "Brings in pickups from %d px away" % roundi(collect_reach(lvl))
		"medic": return "Heals your hero %.1f%% a second" % (medic_rate(lvl) * 100.0)
	return ""
