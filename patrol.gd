class_name Patrol
extends RefCounted
# Patrol: offline farming (Rudy, dev135). The pilot farms a stage you have cleared, one wave
# every WAVE_S seconds, whether the game is open or closed, and each cleared wave adds its
# drops to the Patrol store. Mostly coins; now and then that stage's element, rarer the
# higher it is: Alloy on any stage, Cells from stage 11, Cores from stage 21. Later: rare gear
# copies for merging.
# Kept stingy on purpose (Rudy, dev136: leaving it for a day must not give everything):
#   - an hour pays about COIN_RATE of one clear of that stage, elements are rare;
#   - full speed for FULL_S after a collect, half speed until HALF_S, a quarter until CAP_S,
#     then nothing more until you collect (checking in now and then pays best);
#   - at most DAY_CAP_S of farming counts per day, however often you collect;
#   - at most MAX_COLLECTS collects a day (Rudy); what is farmed after that waits for tomorrow.
# Save: "patrol": {"stage": n, "since": unix time of the last count, "stored_s": seconds
# farmed since the last collect, "store": {coins, alloy, cell, core} as fractions,
# "day": day number, "day_s": seconds counted that day, "day_claims": collects that day}.

const WAVE_S := 30.0
const WAVES_PER_HOUR := 3600.0 / WAVE_S
const FULL_S := 2.0 * 3600.0
const HALF_S := 6.0 * 3600.0
const CAP_S := 8.0 * 3600.0
const DAY_CAP_S := 12.0 * 3600.0
const COIN_RATE := 0.4
const MAX_COLLECTS := 3

# what one cleared wave of `stage` adds at full speed (fractions add up over many waves)
static func per_wave(stage: int) -> Dictionary:
	var coins := 0.0
	for wave in StageData.waves(stage):
		for spec in wave:
			if not StageData.is_boss(String(spec[0])):
				coins += float(StageData.ENEMIES[spec[0]].get("coins", 0)) * float(spec[1])
	var out := {"coins": coins * COIN_RATE / WAVES_PER_HOUR, "alloy": 0.02 + 0.0003 * stage}
	if stage >= 11:
		out["cell"] = 0.0015 + 0.00004 * (stage - 11)
	if stage >= 21:
		out["core"] = 0.0003 + 0.00001 * (stage - 21)
	# a gear copy of that stage's set now and then (dev139; about one every 3-4 hours at
	# full speed, rarity by stage: GearData.roll_drop)
	out["gear"] = 0.002 + 0.00004 * stage
	# materials (materials.gd, dev189): the two lines trickle from planet 2 on, the planet's own
	# essence very slowly (about one a day at full speed)
	if stage >= 11:
		out["barrel"] = 0.0012 + 0.00002 * stage
		out["rotor"] = 0.0012 + 0.00002 * stage
	out[Materials.essence_of(String(Heroes.family(stage).weak))] = 0.0004
	return out

# speed at this many seconds since the last collect: 1, then 0.5, then 0.25
static func speed_at(stored_s: float) -> float:
	return 1.0 if stored_s < FULL_S else (0.5 if stored_s < HALF_S else 0.25)

# full-speed seconds earned while the store goes from `from_s` to `to_s`
static func _full_speed_s(from_s: float, to_s: float) -> float:
	var total := 0.0
	for seg in [[0.0, FULL_S, 1.0], [FULL_S, HALF_S, 0.5], [HALF_S, CAP_S, 0.25]]:
		var a := maxf(from_s, float(seg[0]))
		var b := minf(to_s, float(seg[1]))
		if b > a:
			total += (b - a) * float(seg[2])
	return total

static func today() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0)

static func read(save: Dictionary) -> Dictionary:
	var p = save.get("patrol", {})
	if typeof(p) != TYPE_DICTIONARY:
		p = {}
	var best := maxi(1, int(save.get("stage_unlocked", 1)) - 1)   # the highest cleared stage
	var store = p.get("store", {})
	var same_day: bool = int(p.get("day", -1)) == today()
	return {"stage": clampi(int(p.get("stage", best)), 1, best), "since": float(p.get("since", Time.get_unix_time_from_system())),
		"stored_s": float(p.get("stored_s", 0.0)), "store": store if typeof(store) == TYPE_DICTIONARY else {},
		"day": today(), "day_s": float(p.get("day_s", 0.0)) if same_day else 0.0,
		"day_claims": int(p.get("day_claims", 0)) if same_day else 0}

# Count the waves farmed since the last count (slower as the store fills, capped, and
# within today's limit) into the store. Changes `save`.
static func tick(save: Dictionary) -> Dictionary:
	var p := read(save)
	var now := Time.get_unix_time_from_system()
	var add := clampf(now - float(p.since), 0.0, minf(CAP_S - float(p.stored_s), DAY_CAP_S - float(p.day_s)))
	var waves := _full_speed_s(float(p.stored_s), float(p.stored_s) + add) / WAVE_S
	var pw := per_wave(int(p.stage))
	for k in pw:
		p.store[k] = float(p.store.get(k, 0.0)) + float(pw[k]) * waves
	p.stored_s = float(p.stored_s) + add
	p.day_s = float(p.day_s) + add
	p.since = now
	save["patrol"] = p
	return p

# whole amounts ready to collect
static func ready(p: Dictionary) -> Dictionary:
	var out := {}
	for k in p.store:
		var n := int(floor(float(p.store[k])))
		if n > 0:
			out[k] = n
	return out

# Collect: whole amounts into the save, fractions kept for next time, full speed again.
static func claim(save: Dictionary) -> Dictionary:
	var p := tick(save)
	if collects_left(p) <= 0:
		return {}
	var got := ready(p)
	for k in got:
		p.store[k] = float(p.store[k]) - float(got[k])
	# whole gear copies become real pieces of the farmed stage's set
	if got.has("gear"):
		var rng := RandomNumberGenerator.new()
		var pieces: Array = []
		for i in int(got.gear):
			pieces.append(GearData.roll_drop(int(p.stage), rng))
		got["gear"] = pieces
	Progress.grant(save, got)
	p.stored_s = 0.0
	p.day_claims = int(p.day_claims) + 1
	save["patrol"] = p
	return got

static func collects_left(p: Dictionary) -> int:
	return maxi(0, MAX_COLLECTS - int(p.get("day_claims", 0)))

static func set_stage(save: Dictionary, stage: int) -> void:
	var p := tick(save)   # what was farmed so far stays in the store
	p.stage = stage
	save["patrol"] = p
