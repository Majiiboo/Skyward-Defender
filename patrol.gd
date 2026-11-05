class_name Patrol
extends RefCounted
# Patrol: offline farming (Rudy, dev135). The pilot farms a stage you have cleared, one wave
# every WAVE_S seconds, whether the game is open or closed, and each cleared wave adds its
# drops to the Patrol store, up to CAP_S of farming. Mostly coins (an hour pays about one
# clear of that stage); now and then that stage's element, rarer the higher it is: Alloy on
# any stage, Cells from stage 11, Cores from stage 21. Later: rare gear copies for merging.
# Save: "patrol": {"stage": n, "since": unix time of the last count, "stored_s": seconds
# farmed and not yet collected, "store": {coins, alloy, cell, core} as fractions}.

const WAVE_S := 30.0
const CAP_S := 8.0 * 3600.0
const WAVES_PER_HOUR := 3600.0 / WAVE_S

# what one cleared wave of `stage` adds (fractions add up over many waves)
static func per_wave(stage: int) -> Dictionary:
	var coins := 0.0
	for wave in StageData.waves(stage):
		for spec in wave:
			if spec[0] != "hive_mother":
				coins += float(StageData.ENEMIES[spec[0]].get("coins", 0)) * float(spec[1])
	var out := {"coins": coins / WAVES_PER_HOUR, "alloy": 0.04 + 0.0006 * stage}
	if stage >= 11:
		out["cell"] = 0.003 + 0.00008 * (stage - 11)
	if stage >= 21:
		out["core"] = 0.0008 + 0.00003 * (stage - 21)
	return out

static func read(save: Dictionary) -> Dictionary:
	var p = save.get("patrol", {})
	if typeof(p) != TYPE_DICTIONARY:
		p = {}
	var best := maxi(1, int(save.get("stage_unlocked", 1)) - 1)   # the highest cleared stage
	var store = p.get("store", {})
	return {"stage": clampi(int(p.get("stage", best)), 1, best), "since": float(p.get("since", Time.get_unix_time_from_system())),
		"stored_s": float(p.get("stored_s", 0.0)), "store": store if typeof(store) == TYPE_DICTIONARY else {}}

# Count the waves farmed since the last count (capped) into the store. Changes `save`.
static func tick(save: Dictionary) -> Dictionary:
	var p := read(save)
	var now := Time.get_unix_time_from_system()
	var add := clampf(now - float(p.since), 0.0, CAP_S - float(p.stored_s))
	var waves := add / WAVE_S
	var pw := per_wave(int(p.stage))
	for k in pw:
		p.store[k] = float(p.store.get(k, 0.0)) + float(pw[k]) * waves
	p.stored_s = float(p.stored_s) + add
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

# Collect: whole amounts into the save, fractions kept for next time, the clock restarts.
static func claim(save: Dictionary) -> Dictionary:
	var p := tick(save)
	var got := ready(p)
	Progress.grant(save, got)
	for k in got:
		p.store[k] = float(p.store[k]) - float(got[k])
	p.stored_s = 0.0
	save["patrol"] = p
	return got

static func set_stage(save: Dictionary, stage: int) -> void:
	var p := tick(save)   # what was farmed so far stays in the store
	p.stage = stage
	save["patrol"] = p
