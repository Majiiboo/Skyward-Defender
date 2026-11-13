class_name Mastery
extends RefCounted
# WEAPON MASTERY (Rudy, 2026-11-13): every weapon CLASS (GearData.weapon_class: sidearm, twin,
# main, heavy) has five steps. A step opens after enough KILLS made while carrying a weapon of
# that class, and then costs coins to unlock. Steps 1-4 are steady gains (attack, crit, fire
# rate...); step 5 is the one worth the grind: it changes what the class's own trick does.
# Kills are counted per class at the end of every fight (battle _end_run), win or lose.
# save "mastery" = {class: {"kills": n, "level": 0..5}}

const STEPS := 5
const KILLS := [100, 300, 800, 2000, 5000]          # kills with the class, in total, for step n
const COST := [500, 1500, 4000, 10000, 25000]       # coins to unlock step n once the kills are in

# effect keys (added up over the steps bought):
#   atk, rate = +share of hero damage / fire rate      crit = +crit chance     crit_dmg = +crit multiplier
#   charge_minus = the charged shot comes n shots sooner    charge_mult_add = and hits this much harder
#   spark_minus = the arc comes n shots sooner              pierce_every = every nth bolt pierces
#   splash_x = the blast reaches this many times as far     splash_share_add = and hits this much harder
const TRACKS := {
	"sidearm": [
		{"name": "Steady hand", "text": "Attack +8%", "fx": {"atk": 0.08}},
		{"name": "Sharp eye", "text": "Crit chance +5%", "fx": {"crit": 0.05}},
		{"name": "Quick draw", "text": "Fire rate +8%", "fx": {"rate": 0.08}},
		{"name": "Kill shot", "text": "Crits hit 25% harder", "fx": {"crit_dmg": 0.25}},
		{"name": "Hair trigger", "text": "The charged shot comes one shot sooner and hits once more as hard", "fx": {"charge_minus": 1, "charge_mult_add": 1.0}},
	],
	"twin": [
		{"name": "Both barrels", "text": "Attack +8%", "fx": {"atk": 0.08}},
		{"name": "Fast hands", "text": "Fire rate +8%", "fx": {"rate": 0.08}},
		{"name": "Sharp eye", "text": "Crit chance +5%", "fx": {"crit": 0.05}},
		{"name": "Heavy rounds", "text": "Attack +10%", "fx": {"atk": 0.1}},
		{"name": "Storm link", "text": "The arc comes one shot sooner and both pistols hit 15% harder", "fx": {"spark_minus": 1, "atk": 0.15}},
	],
	"main": [
		{"name": "Tight grouping", "text": "Attack +8%", "fx": {"atk": 0.08}},
		{"name": "Smooth action", "text": "Fire rate +6%", "fx": {"rate": 0.06}},
		{"name": "Sharp eye", "text": "Crit chance +5%", "fx": {"crit": 0.05}},
		{"name": "Kill shot", "text": "Crits hit 25% harder", "fx": {"crit_dmg": 0.25}},
		{"name": "Punch through", "text": "Every 4th bolt flies through the bug it hits, and fire rate +10%", "fx": {"pierce_every": 4, "rate": 0.1}},
	],
	"heavy": [
		{"name": "Bigger charge", "text": "Attack +8%", "fx": {"atk": 0.08}},
		{"name": "Wide blast", "text": "The blast reaches 15% further", "fx": {"splash_x": 1.15}},
		{"name": "Sharp eye", "text": "Crit chance +5%", "fx": {"crit": 0.05}},
		{"name": "Packed shells", "text": "Attack +12%", "fx": {"atk": 0.12}},
		{"name": "Shockwave", "text": "The blast reaches 30% further still and hits 25% harder", "fx": {"splash_x": 1.3, "splash_share_add": 0.25}},
	],
}

static func read(save: Dictionary, cls: String) -> Dictionary:
	var all = save.get("mastery", {})
	var row = all.get(cls, {}) if all is Dictionary else {}
	if not (row is Dictionary):
		row = {}
	return {"kills": maxi(int(row.get("kills", 0)), 0), "level": clampi(int(row.get("level", 0)), 0, STEPS)}

static func _write(save: Dictionary, cls: String, row: Dictionary) -> void:
	var all = save.get("mastery", {})
	if not (all is Dictionary):
		all = {}
	all[cls] = row
	save["mastery"] = all

static func level(save: Dictionary, cls: String) -> int:
	return int(read(save, cls).level)

static func kills(save: Dictionary, cls: String) -> int:
	return int(read(save, cls).kills)

static func add_kills(save: Dictionary, cls: String, n: int) -> void:
	if not TRACKS.has(cls) or n <= 0:
		return
	var row := read(save, cls)
	row.kills = int(row.kills) + n
	_write(save, cls, row)

# the step that comes next ({} when all five are bought)
static func next_step(save: Dictionary, cls: String) -> Dictionary:
	var lv := level(save, cls)
	if lv >= STEPS or not TRACKS.has(cls):
		return {}
	var s: Dictionary = Dictionary(TRACKS[cls][lv]).duplicate()
	s["kills"] = int(KILLS[lv])
	s["cost"] = int(COST[lv])
	s["n"] = lv + 1
	return s

# "" when the next step can be unlocked now, else what is in the way
static func why_not(save: Dictionary, cls: String) -> String:
	var s := next_step(save, cls)
	if s.is_empty():
		return "Mastered"
	if kills(save, cls) < int(s.kills):
		return "%d more kills" % (int(s.kills) - kills(save, cls))
	if int(save.get("coins", 0)) < int(s.cost) and not DevTools.on:
		return "Not enough coins"
	return ""

# the kills are in and it can be afforded: the red dot
static func ready(save: Dictionary, cls: String) -> bool:
	return why_not(save, cls) == ""

static func buy(save: Dictionary, cls: String) -> bool:
	if why_not(save, cls) != "":
		return false
	var s := next_step(save, cls)
	if not DevTools.on:
		save["coins"] = int(save.get("coins", 0)) - int(s.cost)
	var row := read(save, cls)
	row.level = int(row.level) + 1
	_write(save, cls, row)
	return true

# everything the bought steps give, added up
static func bonus(save: Dictionary, cls: String) -> Dictionary:
	var out := {"atk": 0.0, "rate": 0.0, "crit": 0.0, "crit_dmg": 0.0, "charge_minus": 0, "charge_mult_add": 0.0,
		"spark_minus": 0, "pierce_every": 0, "splash_x": 1.0, "splash_share_add": 0.0}
	if not TRACKS.has(cls):
		return out
	for i in level(save, cls):
		var fx: Dictionary = TRACKS[cls][i].fx
		for k in fx:
			if k == "splash_x":
				out[k] = float(out[k]) * float(fx[k])
			elif k == "pierce_every":
				out[k] = int(fx[k])
			else:
				out[k] = out[k] + fx[k]
	return out
