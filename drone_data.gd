class_name DroneData
extends RefCounted
# The drone sidekick (Rudy, dev113: a Gear unlock instead of a power card). One drone
# flies beside the pilot in battle. You pick its BODY (how it behaves) and its weapon
# POD (how it shoots), and upgrade it with coins. Pictures: drone/body_*.png,
# drone/pod_*.png, drone/flash_*.png (Luna's batch D, tools/cut_batch_d.gd).
# Save: "drone": {"body": id, "pod": id, "level": 1..10}.
# Element (dev172): the drone takes the HERO's element (it is his partner): its hits use the
# same weak / resist table and its damage numbers his colour.

const UNLOCK_LEVEL := 8        # pilot level that unlocks the drone
const MAX_LEVEL := 10

const BODIES := {
	"scout":   {"name": "Scout",   "unlock": 8,  "rate": 1.3, "dmg": 0.8, "range": 380.0,
		"desc": "Fire rate +30%"},
	"striker": {"name": "Striker", "unlock": 14, "rate": 1.0, "dmg": 1.15, "range": 520.0,
		"desc": "Harder hits, longer range"},
	"warden":  {"name": "Warden",  "unlock": 20, "rate": 0.8, "dmg": 1.0, "range": 420.0, "guard": 5.0,
		"desc": "Blocks a shot every 5 s"},
}
const PODS := {
	"blaster": {"name": "Twin Blaster", "unlock": 8,  "every": 0.7, "damage": 0.45,
		"desc": "Twin quick bolts"},
	"beam":    {"name": "Beam",         "unlock": 12, "every": 1.4, "damage": 1.4,
		"desc": "Instant beam, never misses"},
	# support pods (dev172, DESIGN-turrets-drones.md): no guns, a job instead ("job"); they use
	# another pod's picture until Luna paints theirs ("art")
	"repair":  {"name": "Repair Pod",   "unlock": 10, "every": 0.0, "damage": 0.0, "job": "repair", "art": "beam", "heal": 1.5,
		"desc": "No guns: patches the base shield 1.5 a second"},
	"magnet":  {"name": "Magnet Pod",   "unlock": 12, "every": 0.0, "damage": 0.0, "job": "magnet", "art": "blaster", "reach": 150.0,
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
	return {"body": body if BODIES.has(body) else "scout", "pod": pod if PODS.has(pod) else "blaster",
		"level": clampi(int(d.get("level", 1)), 1, MAX_LEVEL)}

static func unlocked(pilot_level: int) -> bool:
	return pilot_level >= UNLOCK_LEVEL

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
