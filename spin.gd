class_name Spin
extends RefCounted
# THE DAILY SPIN (2026-11-10). A wheel of eight prizes. One free spin a day; up to EXTRA_MAX more
# for crystals. The odds are shown on the wheel's sheet. Where it stops is rolled here, the page
# only turns the wheel to it. Save "spin": {"day": n, "used": spins taken today}.
# Opens once stage SPIN_FROM is cleared. A reason to open the game every day, and a small crystal sink.

const SPIN_FROM := 4
const EXTRA_MAX := 3
const EXTRA_COST := 30
# clockwise from the top; "w" = weight (chance = w / the sum)
const SEGMENTS := [
	{"reward": {"coins": 400},    "w": 24, "col": Color(1.0, 0.78, 0.27)},
	{"reward": {"alloy": 6},      "w": 18, "col": Color(0.75, 0.8, 0.9)},
	{"reward": {"crystals": 10},  "w": 14, "col": Color(0.71, 0.55, 1.0)},
	{"reward": {"coins": 1500},   "w": 12, "col": Color(1.0, 0.6, 0.3)},
	{"reward": {"key_u": 1},      "w": 12, "col": Color(0.44, 0.94, 0.72)},
	{"reward": {"cell": 4},       "w": 12, "col": Color(0.31, 0.88, 1.0)},
	{"reward": {"crystals": 50},  "w": 5,  "col": Color(0.9, 0.45, 1.0)},
	{"reward": {"key_e": 1},      "w": 3,  "col": Color(1.0, 0.45, 0.5)},
]

static func day() -> int:
	return Promotion.day()

static func open(save: Dictionary) -> bool:
	return DevTools.on or int(save.get("stage_unlocked", 1)) > SPIN_FROM

static func used(save: Dictionary) -> int:
	var s = save.get("spin", {})
	if typeof(s) != TYPE_DICTIONARY or int(s.get("day", -1)) != day():
		return 0
	return maxi(int(s.get("used", 0)), 0)

static func free_ready(save: Dictionary) -> bool:
	return open(save) and used(save) == 0

# spins left today, the free one included
static func left(save: Dictionary) -> int:
	return maxi(1 + EXTRA_MAX - used(save), 0)

# crystals the next spin costs (0 = it is the free one)
static func cost(save: Dictionary) -> int:
	return 0 if used(save) == 0 else EXTRA_COST

static func chance(i: int) -> float:
	var sum := 0.0
	for s in SEGMENTS:
		sum += float(s.w)
	return float(SEGMENTS[i].w) / sum

static func why_not(save: Dictionary) -> String:
	if not open(save):
		return "Opens after stage %d" % SPIN_FROM
	if left(save) <= 0:
		return "Back tomorrow"
	if not DevTools.on and int(save.get("crystals", 0)) < cost(save):
		return "%d crystals needed" % cost(save)
	return ""

# take a spin: pays for it, rolls, grants. Returns the segment index (-1 = refused)
static func spin(save: Dictionary, rng: RandomNumberGenerator) -> int:
	if why_not(save) != "":
		return -1
	if not DevTools.on:
		save["crystals"] = int(save.get("crystals", 0)) - cost(save)
	var sum := 0.0
	for s in SEGMENTS:
		sum += float(s.w)
	var roll := rng.randf() * sum
	var pick := SEGMENTS.size() - 1
	for i in SEGMENTS.size():
		roll -= float(SEGMENTS[i].w)
		if roll < 0.0:
			pick = i
			break
	save["spin"] = {"day": day(), "used": used(save) + 1}
	Progress.grant(save, SEGMENTS[pick].reward)
	return pick
