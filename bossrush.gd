class_name BossRush
extends RefCounted
# BOSS RUSH (2026-11-10). Every boss you have beaten in the campaign, one after another, with a
# few small bugs beside each (they drop the gems that feed your cards). No waves of ordinary bugs,
# no breaks. It is fought at your best cleared stage's strength with each boss at RUSH_HP of her
# normal health and RUSH_STEP tougher than the one before (the cards you gather keep pace). The clock is the score:
# your best time is kept, and beating the full line for the first time at each new length pays
# crystals and an Epic key. Counted as a trial (battle `boss_rush`): no stars, no stage unlocks.
# Opens once stage RUSH_FROM is cleared. Save "bossrush": {"n": bosses in your best run, "t": its
# seconds, "paid": the longest line already paid for}.

const RUSH_FROM := 20
const RUSH_HP := 0.9
const RUSH_STEP := 0.2   # every boss down the line is this much tougher than the one before
const MAX_BOSSES := 8

static func open(save: Dictionary) -> bool:
	return DevTools.on or int(save.get("stage_unlocked", 1)) > RUSH_FROM

static func stage(save: Dictionary) -> int:
	return Promotion.daily_stage(save)

# the line: the boss of every fifth stage you have cleared, in order (mini-boss, planet boss, ...)
static func bosses(save: Dictionary) -> Array:
	var cleared := int(save.get("stage_unlocked", 1)) - 1
	if DevTools.on:
		cleared = StageData.MAX_STAGE
	var n := clampi(cleared / 5, 2, MAX_BOSSES)
	var out: Array = []
	for i in n:
		var bs := (i + 1) * 5
		out.append(StageData.boss_id(bs, bs % 10 == 5))
	return out

static func waves(save: Dictionary) -> Array:
	var out: Array = []
	var line := bosses(save)
	for i in line.size():
		out.append([["scout", 3 + i], [String(line[i]), 1]])
	return out

static func best(save: Dictionary) -> Dictionary:
	var b = save.get("bossrush", {})
	if typeof(b) != TYPE_DICTIONARY:
		return {"n": 0, "t": 0.0, "paid": 0}
	return {"n": maxi(int(b.get("n", 0)), 0), "t": maxf(float(b.get("t", 0.0)), 0.0), "paid": maxi(int(b.get("paid", 0)), 0)}

# settle a run: `down` bosses beaten, `t` seconds. Returns {"reward": {...}, "new_best": bool, "first": bool}
static func finish(save: Dictionary, won: bool, down: int, total: int, t: float) -> Dictionary:
	var b := best(save)
	var reward := {"coins": (250 if won else 100) * maxi(down, 0)}
	var first := false
	if won and total > int(b.paid):   # the first time the whole line of this length falls
		first = true
		reward["crystals"] = 15 * total
		reward["key_e"] = 1
		b.paid = total
	var new_best := false
	if won and (total > int(b.n) or (total == int(b.n) and (float(b.t) <= 0.0 or t < float(b.t)))):
		new_best = true
		b.n = total
		b.t = t
	save["bossrush"] = b
	Progress.grant(save, reward)
	return {"reward": reward, "new_best": new_best, "first": first}

# "3:07"
static func time_text(t: float) -> String:
	var s := int(round(t))
	return "%d:%02d" % [s / 60, s % 60]
