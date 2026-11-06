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
	{"id": "cadet",       "name": "Cadet",       "level": 10, "stage": 15, "hp": 1.3,  "count": 1.3},
	{"id": "pilot",       "name": "Pilot",       "level": 20, "stage": 30, "hp": 1.45, "count": 1.3},
	{"id": "ace",         "name": "Ace",         "level": 25, "stage": 40, "hp": 1.65, "count": 1.3},
	{"id": "comet",       "name": "Comet",       "level": 30, "stage": 55, "hp": 1.6,  "count": 1.3},
	{"id": "meteor",      "name": "Meteor",      "level": 35, "stage": 60, "hp": 1.7,  "count": 1.3},
	{"id": "nova",        "name": "Nova",        "level": 40, "stage": 60, "hp": 1.65, "count": 1.35},
	{"id": "pulsar",      "name": "Pulsar",      "level": 45, "stage": 60, "hp": 1.7,  "count": 1.4},
	{"id": "quasar",      "name": "Quasar",      "level": 50, "stage": 60, "hp": 1.75, "count": 1.45},
	{"id": "supernova",   "name": "Supernova",   "level": 55, "stage": 60, "hp": 1.85, "count": 1.5},
	{"id": "singularity", "name": "Singularity", "level": 60, "stage": 60, "hp": 1.95, "count": 1.6},
]
const PER_RANK := 0.06        # +6% bolt damage and +6% base shield / hull per rank (worth the fight)
# "level" is the RECOMMENDED pilot level, one per ten levels (Rudy, dev168: 10, then the 20s,
# 30s, 40s, 50s); "stage" is the stage a player of that level is around (balance sweep: Lv.10
# at stage 13-15, Lv.20 at 30, Lv.25 at 40, Lv.30 at 53-55, Lv.33 at 60), so the trial's bugs
# are that stage's bugs. Ranks past Lv.33 are endgame: stage 60 bugs with the "hp" and "count"
# rising. The trial is tuned for the recommended level, but a player a few levels under it
# with better gear or turrets can still take it (OPEN_EARLY).
# "hp" and "count" per rank: bug health and bug numbers on top of that stage's normal scaling.
# "Turrets down" only on the first rank / step (stage 10-15, turrets ~10% of the damage); from
# stage 30 on it was a wall (0 of 3) wherever it sat.
# Tuned with the balance sim (dev168, human bot, the kit of a player at that stage): hp 1.2 wins
# every trial, 1.35-1.4 wins about half, 1.5 loses most (that was before the hero kit; with hero
# ATK + DEF levels in the sim kit, dev172, the same bot won 1.4 three of three, so every rank
# went up 0.15); a kit 12 stages weaker wins almost
# never (one Comet win in 3), a kit 8 stages stronger wins nearly always. Trials are a cliff:
# the real strategy is gear and turrets, not retries.
# (Elite is x1.85 health).
const GEM_XP_MULT := 1.25     # run XP comes faster in a trial: power cards sooner, a better run (Rudy)
const OPEN_EARLY := 7         # a trial opens 7 levels under its recommended level (Rudy: beatable early with good gear)
const WAVES := 10
const XP_BONUS := 250         # pilot XP the first time a rank is won
const NO_RANK := "Rookie"

# the two difficulty knobs (the balance simulator can override them: SIM_PROMO_HP, SIM_PROMO_COUNT)
static func hp_mult(i: int) -> float:
	var e := OS.get_environment("SIM_PROMO_HP")
	return float(e) if e != "" else float(RANKS[clampi(i, 0, RANKS.size() - 1)].hp)

static func count_mult(i: int) -> float:
	var e := OS.get_environment("SIM_PROMO_COUNT")
	return float(e) if e != "" else float(RANKS[clampi(i, 0, RANKS.size() - 1)].count)

# "x1.7 to x2.4" for the ladder text
static func hp_range_text() -> String:
	var lo := 99.0
	var hi := 0.0
	for r in RANKS:
		lo = minf(lo, float(r.hp))
		hi = maxf(hi, float(r.hp))
	return "x%.1f to x%.1f" % [lo, hi]

static func rank(save: Dictionary) -> int:
	return clampi(int(save.get("promotion", 0)), 0, RANKS.size())

static func rank_name(save: Dictionary) -> String:
	var r := rank(save)
	return NO_RANK if r == 0 else String(RANKS[r - 1].name)

# the trial to take next (index into RANKS), -1 when every rank is won
static func next(save: Dictionary) -> int:
	var r := rank(save)
	return r if r < RANKS.size() else -1

# "level" in RANKS is the RECOMMENDED pilot level (shown on the card); the trial opens a bit earlier
static func open_level(i: int) -> int:
	return maxi(int(RANKS[clampi(i, 0, RANKS.size() - 1)].level) - OPEN_EARLY, 5)

static func unlocked(save: Dictionary, pilot_level: int) -> bool:
	var n := next(save)
	return n >= 0 and (pilot_level >= open_level(n) or DevTools.on)

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
				count = int(ceil(count * count_mult(i)))
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

# ---- ELEMENT TRIALS (Rudy, dev172) ----
# Inside Promotion, one ladder per element. Only a hero OF THAT ELEMENT may fight it (the
# hero on duty). Each ladder is STEPS stages, each built from a boss stage one planet further
# on, so the ladder crosses every family: the element is strong on one planet and resisted
# on another, the real test. Bugs get ETRIAL_HP / ETRIAL_COUNT on top. The first clear of a
# step pays shards of that element's hero, coins and (on the last step) crystals; replays pay
# half the coins. Save "etrials": {element: steps cleared}; "selected_mode" == "etrial" +
# "etrial_el" / "etrial_step" once (take_etrial clears them), like the rank trials.
const ETRIAL_STAGES := [10, 20, 30, 40, 50]
const ETRIAL_HP := [1.2, 1.3, 1.4, 1.5, 1.6]
const ETRIAL_COUNT := 1.2
const ETRIAL_SHARDS := [10, 15, 20, 30, 40]
const ETRIAL_COINS := [300, 600, 900, 1200, 1800]
const ETRIAL_CRYSTALS_LAST := 20
const ETRIAL_STEPS := 5

static func etrial_steps(save: Dictionary, el: String) -> int:
	var t = save.get("etrials", {})
	return clampi(int(t.get(el, 0)), 0, ETRIAL_STEPS) if typeof(t) == TYPE_DICTIONARY else 0

# the hero that carries this element (the first in the roster order)
static func etrial_hero(el: String) -> String:
	for id in Heroes.ORDER:
		if Heroes.element_of(id) == el:
			return id
	return Heroes.DEFAULT

# a hero of this element the player owns (the one on duty first), "" when none
static func etrial_owned_hero(save: Dictionary, el: String) -> String:
	var h := Heroes.read(save)
	var on := Heroes.selected(h)
	if Heroes.element_of(on) == el:
		return on
	for id in Heroes.ORDER:
		if Heroes.element_of(id) == el and Heroes.owned(h, id):
			return id
	return ""

# "" when the next step can be fought, else why not
static func etrial_why_not(save: Dictionary, el: String) -> String:
	if etrial_steps(save, el) >= ETRIAL_STEPS:
		return "Ladder complete"
	if etrial_owned_hero(save, el) == "":
		return "Needs a %s hero" % Heroes.element_name(el)
	return ""

static func etrial_reward(step: int, first: bool, el: String) -> Dictionary:
	var k := clampi(step, 0, ETRIAL_STEPS - 1)
	var r := {"coins": int(ETRIAL_COINS[k]) if first else int(ETRIAL_COINS[k]) / 2}
	if first:
		r["shards"] = {etrial_hero(el): int(ETRIAL_SHARDS[k])}
		if k == ETRIAL_STEPS - 1:
			r["crystals"] = ETRIAL_CRYSTALS_LAST
	r["materials"] = {Materials.essence_of(el): (2 if first else 1)}   # the trial's own essence (materials.gd)
	return r

# the waves of step `k`: that boss stage's waves with more bugs (same shape as waves())
static func etrial_waves(k: int) -> Array:
	var src: Array = StageData.waves(int(ETRIAL_STAGES[clampi(k, 0, ETRIAL_STEPS - 1)]))
	var out: Array = []
	for wave in src:
		var w: Array = []
		for spec in wave:
			var count := int(spec[1])
			if spec[0] != "hive_mother":
				count = int(ceil(count * ETRIAL_COUNT))
			w.append([spec[0], count])
		out.append(w)
	return out

static func etrial_hp(k: int) -> float:
	return float(ETRIAL_HP[clampi(k, 0, ETRIAL_STEPS - 1)])

# Modes: start step `k` of the `el` ladder with that element's hero on duty
static func start_etrial(save: Dictionary, el: String, k: int) -> void:
	var hid := etrial_owned_hero(save, el)
	if hid != "":
		var h := Heroes.read(save)
		h.selected = hid
		save["hero"] = Heroes.write(h)
	save["selected_mode"] = "etrial"
	save["etrial_el"] = el
	save["etrial_step"] = k

# battle: the element trial the save asks for ({} = none); the ask is used up
static func take_etrial(save: Dictionary) -> Dictionary:
	if String(save.get("selected_mode", "normal")) != "etrial":
		return {}
	save["selected_mode"] = "normal"
	var el := String(save.get("etrial_el", "ion"))
	return {"el": el if Heroes.ELEMENTS.has(el) else "ion", "step": clampi(int(save.get("etrial_step", 0)), 0, ETRIAL_STEPS - 1)}

# a win of step `k`: true the first time (the ladder moves on)
static func etrial_won(save: Dictionary, el: String, k: int) -> bool:
	var t = save.get("etrials", {})
	if typeof(t) != TYPE_DICTIONARY:
		t = {}
	if int(t.get(el, 0)) == k:
		t[el] = k + 1
		save["etrials"] = t
		return true
	return false

# ---- ADVANTAGES AND DISADVANTAGES (Rudy, dev172) ----
# Every rank trial and every element step carries one or two advantages and one or two
# disadvantages: named twists the fight is built around. battle.gd applies them (apply_mods),
# the ladders show them, the HUD announces them at the start.
const MODS := {
	"rapid":        {"name": "Rapid fire",     "good": true,  "text": "Fire rate +25%"},
	"sharpshooter": {"name": "Sharpshooter",   "good": true,  "text": "Crit rate +20%"},
	"fortified":    {"name": "Fortified",      "good": true,  "text": "Base shield +50%"},
	"reinforced":   {"name": "Reinforced",     "good": true,  "text": "Pilot HP +50%"},
	"turret_boost": {"name": "Turret boost",   "good": true,  "text": "Turrets +50% damage"},
	"overcharge":   {"name": "Overcharge",     "good": true,  "text": "Power cards come 50% faster"},
	"swift_bugs":   {"name": "Swift bugs",     "good": false, "text": "Bugs move 25% faster"},
	"thick_shells": {"name": "Thick shells",   "good": false, "text": "Bugs +25% health"},
	"no_turrets":   {"name": "Turrets down",   "good": false, "text": "No turrets on the base"},
	"double_spit":  {"name": "Double spit",    "good": false, "text": "Spitters spit twice as often"},
	"weak_shield":  {"name": "Cracked shield", "good": false, "text": "Base shield halved"},
}
# per rank trial (index into RANKS), good ones first
const RANK_MODS := [
	["rapid", "no_turrets"],
	["fortified", "swift_bugs"],
	["sharpshooter", "double_spit"],
	["overcharge", "thick_shells"],
	["turret_boost", "weak_shield"],
	["reinforced", "swift_bugs", "thick_shells"],
	["rapid", "sharpshooter", "no_turrets"],
	["fortified", "double_spit"],
	["overcharge", "thick_shells", "weak_shield"],
	["turret_boost", "swift_bugs", "double_spit"],
]
# per element step
const ETRIAL_MODS := [
	["rapid", "no_turrets"],
	["fortified", "swift_bugs"],
	["sharpshooter", "swift_bugs"],
	["overcharge", "double_spit"],
	["reinforced", "thick_shells", "weak_shield"],
]

# the mods of the fight: a rank trial (promo >= 0), an element step, or none
static func mods_for(promo: int, etrial: Dictionary) -> Array:
	if promo >= 0:
		return Array(RANK_MODS[clampi(promo, 0, RANK_MODS.size() - 1)])
	if not etrial.is_empty():
		return Array(ETRIAL_MODS[clampi(int(etrial.get("step", 0)), 0, ETRIAL_MODS.size() - 1)])
	return []

# "+ Rapid fire  − Swift bugs" (short, for a ladder row)
static func mods_short(mods: Array) -> String:
	var bits: Array = []
	for m in mods:
		if MODS.has(m):
			bits.append(("+ " if MODS[m].good else "− ") + String(MODS[m].name))
	return "   ".join(bits)

# the long form, one per line, for the pause menu and the start banner
static func mods_lines(mods: Array) -> Array:
	var out: Array = []
	for m in mods:
		if MODS.has(m):
			out.append("%s %s: %s" % ["ADVANTAGE" if MODS[m].good else "DISADVANTAGE", String(MODS[m].name).to_upper(), MODS[m].text])
	return out

# Luna's twist icons (icons/tw_<id>.png, cards round 2): green for an advantage, red for a
# disadvantage, so the colour says which without the words
const GOOD_COL := Color(0.55, 1.0, 0.6)
const BAD_COL := Color(1.0, 0.5, 0.55)
static func mod_icon(m: String) -> Texture2D:
	return UIKit.ic("tw_" + m)

# a row of the twists as icon + name (a ladder row, a trial step); long = ": what it does" too
static func mods_row(mods: Array, size_px: int = 11, px: float = 20.0, long: bool = false, center: bool = false) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	if center:
		h.alignment = BoxContainer.ALIGNMENT_CENTER
	for m in mods:
		if MODS.has(m):
			var txt := String(MODS[m].name) + ((": " + String(MODS[m].text)) if long else "")
			h.add_child(UIKit.iconed(mod_icon(m), txt, size_px, GOOD_COL if MODS[m].good else BAD_COL, px))
	return h
