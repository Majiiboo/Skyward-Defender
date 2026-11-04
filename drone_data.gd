class_name DroneData
extends RefCounted
# The drone sidekick (Rudy, dev113: a Gear unlock instead of a power card). One drone
# flies beside the pilot in battle. You pick its BODY (how it behaves) and its weapon
# POD (how it shoots), and upgrade it with coins. Pictures: drone/body_*.png,
# drone/pod_*.png, drone/flash_*.png (Luna's batch D, tools/cut_batch_d.gd).
# Save: "drone": {"body": id, "pod": id, "level": 1..10}.

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
