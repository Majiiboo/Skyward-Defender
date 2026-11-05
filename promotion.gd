class_name Promotion
extends RefCounted
# Pilot ranks (Rudy, dev143, from the Slayer Legend notes): ten rank TRIALS. Each is one hard
# stage of WAVES waves built from a boss stage's wave list, with bugs far tougher than Elite
# and the boss at the end. Beat it and you are promoted for good: every rank gives PER_RANK
# more bolt damage and PER_RANK more base shield and hull, stacking (GearData.stats applies
# it). Not a stat you buy: a fight you have to win. A trial opens at a pilot level, costs
# normal power tokens, and can be retried.
# Save: "promotion": ranks beaten (0-10). Modes starts a trial with start(); battle reads
# "selected_mode" == "promotion" + "promotion_rank" once and clears the mode again.

const RANKS := [
	{"id": "cadet",       "name": "Cadet",       "level": 3,  "stage": 5},
	{"id": "pilot",       "name": "Pilot",       "level": 6,  "stage": 10},
	{"id": "ace",         "name": "Ace",         "level": 10, "stage": 15},
	{"id": "comet",       "name": "Comet",       "level": 14, "stage": 20},
	{"id": "meteor",      "name": "Meteor",      "level": 18, "stage": 25},
	{"id": "nova",        "name": "Nova",        "level": 22, "stage": 30},
	{"id": "pulsar",      "name": "Pulsar",      "level": 26, "stage": 35},
	{"id": "quasar",      "name": "Quasar",      "level": 30, "stage": 40},
	{"id": "supernova",   "name": "Supernova",   "level": 35, "stage": 50},
	{"id": "singularity", "name": "Singularity", "level": 40, "stage": 60},
]
const PER_RANK := 0.05        # +5% bolt damage and +5% base shield / hull per rank
const HP_MULT := 2.2          # bug health on top of that stage's normal scaling (Elite is 1.85)
const COUNT_MULT := 1.3       # more bugs per wave
const WAVES := 10
const XP_BONUS := 250         # pilot XP the first time a rank is won
const NO_RANK := "Rookie"

static func rank(save: Dictionary) -> int:
	return clampi(int(save.get("promotion", 0)), 0, RANKS.size())

static func rank_name(save: Dictionary) -> String:
	var r := rank(save)
	return NO_RANK if r == 0 else String(RANKS[r - 1].name)

# the trial to take next (index into RANKS), -1 when every rank is won
static func next(save: Dictionary) -> int:
	var r := rank(save)
	return r if r < RANKS.size() else -1

static func unlocked(save: Dictionary, pilot_level: int) -> bool:
	var n := next(save)
	return n >= 0 and pilot_level >= int(RANKS[n].level)

# damage and fortress multiplier for `ranks` ranks won
static func bonus(ranks: int) -> float:
	return 1.0 + PER_RANK * ranks

static func bonus_text(ranks: int) -> String:
	return "+%d%% ATK  ·  +%d%% base shield and hull" % [roundi(PER_RANK * ranks * 100.0), roundi(PER_RANK * ranks * 100.0)]

# The trial's waves: WAVES waves spread over that boss stage's wave list (the boss wave stays
# last), every bug count x COUNT_MULT, bosses as they are. Same format as StageData.waves.
static func waves(i: int) -> Array:
	var src: Array = StageData.waves(int(RANKS[clampi(i, 0, RANKS.size() - 1)].stage))
	var n := src.size()
	var out: Array = []
	for k in WAVES:
		var idx := int(floor(float(k) * float(n - 1) / float(WAVES - 1)))
		var wave: Array = []
		for spec in src[idx]:
			var count := int(spec[1])
			if spec[0] != "hive_mother":
				count = int(ceil(count * COUNT_MULT))
			elif k != WAVES - 1 and idx == n - 1:
				continue   # the boss only on the last wave, even if an earlier slot maps to the boss wave
			wave.append([spec[0], count])
		out.append(wave)
	return out

# Modes: start the trial `i` (the save then sends battle into it once)
static func start(save: Dictionary, i: int) -> void:
	save["selected_mode"] = "promotion"
	save["promotion_rank"] = i

# battle: which trial the save asks for (-1 none), and the ask is used up
static func take(save: Dictionary) -> int:
	if String(save.get("selected_mode", "normal")) != "promotion":
		return -1
	save["selected_mode"] = "normal"
	return clampi(int(save.get("promotion_rank", 0)), 0, RANKS.size() - 1)

# a win of trial `i`: true when it was a promotion (the first time)
static func won(save: Dictionary, i: int) -> bool:
	if i == rank(save):
		save["promotion"] = i + 1
		return true
	return false
