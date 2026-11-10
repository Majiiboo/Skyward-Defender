class_name Runs
extends RefCounted
# EXPEDITION: the run (2026-11-10; IDEAS-overhaul.md 1, Rudy: "yes, start it"). Instead of one
# stage and back to Home, a RUN is a row of STEPS stops across one planet. At each stop you choose
# one of up to three: a fight, an elite fight, a rest, a supply cache, and at the end the planet's
# boss. What you build carries from stop to stop: the power cards, the hero's health, the base's
# shield and hull. Lose a fight and the run is over; you keep the coins you picked up and collect a
# reward for how far you got. Beating the boss opens the next planet's expedition.
# It is a MODE beside the campaign for now (battle `run_mode`, counted as a trial: no stars, no
# stage unlocks), so nothing in the campaign changes while we find out whether it is the better game.
# Save "run": the state below. Save "runs_won": {planet index: times won}.

const RUN_FROM := 5          # opens once this stage is cleared
const STEPS := 8             # stops in a run; the last one is the boss
const KINDS := {
	"fight":  {"name": "Fight", "text": "A short battle", "icon": "role_striker", "col": Color(0.31, 0.88, 1.0)},
	"elite":  {"name": "Elite fight", "text": "Tougher bugs, a card refresh if you win", "icon": "ic_elite", "col": Color(0.71, 0.55, 1.0)},
	"rest":   {"name": "Rest", "text": "Hero +40% health, shield and hull +30%", "icon": "st_hp", "col": Color(0.44, 0.94, 0.72)},
	"supply": {"name": "Supply cache", "text": "Take one of two", "icon": "ic_pack", "col": Color(1.0, 0.78, 0.27)},
	"boss":   {"name": "Boss", "text": "The planet's boss", "icon": "ic_rank", "col": Color(1.0, 0.4, 0.45)},
}
const WAVES := {"fight": 4, "elite": 5, "boss": 3}
const ELITE_HP := 1.35
# what a supply cache offers on the map (two of these)
const CACHE := {
	"heal":    {"name": "Medkit", "text": "Hero heals to full", "icon": "st_hp"},
	"patch":   {"name": "Repair crew", "text": "Shield and hull to full", "icon": "st_def"},
	"refresh": {"name": "Spare deck", "text": "+2 card refreshes for the rest of the run", "icon": "ic_pack"},
	"coins":   {"name": "Bounty", "text": "A purse of coins", "icon": "ic_coin"},
}

static func open(save: Dictionary) -> bool:
	return DevTools.on or int(save.get("stage_unlocked", 1)) > RUN_FROM

# how many planets have an expedition: the ones you have reached in the campaign, and each needs
# the one before it won
static func planets_open(save: Dictionary) -> int:
	var reached := StageData.area_index(clampi(int(save.get("stage_unlocked", 1)), 1, StageData.MAX_STAGE)) + 1
	var won = save.get("runs_won", {})
	var n := 1
	while n < reached and typeof(won) == TYPE_DICTIONARY and int(won.get(str(n - 1), 0)) > 0:
		n += 1
	return clampi(n, 1, StageData.AREAS.size())

static func wins(save: Dictionary, planet: int) -> int:
	var won = save.get("runs_won", {})
	return int(won.get(str(planet), 0)) if typeof(won) == TYPE_DICTIONARY else 0

static func new_run(planet: int, run_seed: int) -> Dictionary:
	return {"planet": planet, "seed": run_seed, "step": 0, "hp": 1.0, "shield": 1.0, "hull": 1.0, "cards": {},
		"refreshes": 0, "alive": true, "won": false, "cleared": 0, "node": "", "claimed": false}

static func active(save: Dictionary) -> Dictionary:
	var r = save.get("run", {})
	return r if typeof(r) == TYPE_DICTIONARY and r.has("planet") and not bool(r.get("claimed", false)) else {}

# the choices at a stop: fixed for a run by its seed, so the map can be shown ahead
static func nodes(run: Dictionary, step: int) -> Array:
	if step >= STEPS - 1:
		return ["boss"]
	if step == 0:
		return ["fight"]
	var rng := RandomNumberGenerator.new()
	rng.seed = int(run.get("seed", 1)) * 7919 + step * 104729
	if step == STEPS - 2:
		return ["rest", "elite"] if rng.randf() < 0.5 else ["rest", "supply"]   # a breath before the boss
	var pool: Array = ["fight", "fight", "fight", "elite", "rest", "supply"]
	var out: Array = ["fight"] if rng.randf() < 0.6 else ["elite"]   # there is always something to fight
	var want := 2 + (1 if rng.randf() < 0.5 else 0)
	var guard := 0
	while out.size() < want and guard < 40:
		guard += 1
		var k: String = pool[rng.randi() % pool.size()]
		if not out.has(k):
			out.append(k)
	return out

static func is_fight(kind: String) -> bool:
	return WAVES.has(kind)

# the campaign stage a fight is built from: it climbs through the planet; the boss is the planet's
static func stage_for(run: Dictionary, kind: String) -> int:
	var base := int(run.get("planet", 0)) * 10
	if kind == "boss":
		return clampi(base + 10, 1, StageData.MAX_STAGE)
	var s := base + 1 + int(run.get("step", 0))
	if s - base >= 5:
		s += 1   # the 5th stage of a planet is its mini-boss stage: skipped, so no two stops share a stage
	return clampi(s, 1, StageData.MAX_STAGE)

# the bugs toughen as the run goes on, because your cards do too: +STEP_HP a stop
const STEP_HP := 0.16
static func step_hp(run: Dictionary) -> float:
	return 1.0 + STEP_HP * int(run.get("step", 0))

# a run's fights are short: the first waves of the stage; the boss fight is its last waves
static func trim_waves(waves: Array, kind: String) -> Array:
	var n := int(WAVES.get(kind, 4))
	if waves.size() <= n:
		return waves
	return waves.slice(waves.size() - n) if kind == "boss" else waves.slice(0, n)

# a stop that is not a fight, resolved on the map; `choice` = which supply offer
static func cache_offers(run: Dictionary) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(run.get("seed", 1)) * 31 + int(run.get("step", 0)) * 977
	var ids: Array = CACHE.keys()
	var a: int = rng.randi() % ids.size()
	var b: int = (a + 1 + rng.randi() % (ids.size() - 1)) % ids.size()
	return [ids[a], ids[b]]

static func take_rest(run: Dictionary) -> void:
	run["hp"] = minf(float(run.get("hp", 1.0)) + 0.4, 1.0)
	run["shield"] = minf(float(run.get("shield", 1.0)) + 0.3, 1.0)
	run["hull"] = minf(float(run.get("hull", 1.0)) + 0.3, 1.0)
	_advance(run)

static func take_cache(save: Dictionary, run: Dictionary, id: String) -> void:
	match id:
		"heal": run["hp"] = 1.0
		"patch":
			run["shield"] = 1.0
			run["hull"] = 1.0
		"refresh": run["refreshes"] = int(run.get("refreshes", 0)) + 2
		"coins": Progress.grant(save, {"coins": 150 + 60 * (int(run.get("planet", 0)) + 1) * (int(run.get("step", 0)) + 1)})
	_advance(run)

static func _advance(run: Dictionary) -> void:
	run["step"] = int(run.get("step", 0)) + 1
	run["cleared"] = int(run.get("cleared", 0)) + 1
	run["node"] = ""

# the battle reports a fight: the state it ended in carries on, or the run ends
static func fight_done(run: Dictionary, won: bool, hp_share: float, shield_share: float, hull_share: float, cards: Dictionary) -> void:
	if not won:
		run["alive"] = false
		run["node"] = ""
		return
	run["hp"] = clampf(hp_share, 0.05, 1.0)
	run["shield"] = clampf(shield_share, 0.0, 1.0)
	run["hull"] = clampf(hull_share, 0.05, 1.0)
	run["cards"] = cards.duplicate()
	if String(run.get("node", "")) == "elite":
		run["refreshes"] = int(run.get("refreshes", 0)) + 1
	if String(run.get("node", "")) == "boss":
		run["won"] = true
		run["alive"] = false
	_advance(run)

static func over(run: Dictionary) -> bool:
	return not run.is_empty() and not bool(run.get("alive", true))

# what the run pays when it ends: by how many stops were cleared, more on later planets; the boss
# adds a prize
static func reward(run: Dictionary) -> Dictionary:
	var n := int(run.get("cleared", 0))
	var p := int(run.get("planet", 0)) + 1
	var out := {"coins": 120 * n * p}
	if n >= 3:
		out["key_u"] = 1 + (1 if n >= 6 else 0)
	if bool(run.get("won", false)):
		out["crystals"] = 20 + 10 * p
		out["key_e"] = 1
	return out

# collect the reward of a finished run; returns it ({} = nothing to collect)
static func collect(save: Dictionary) -> Dictionary:
	var run := active(save)
	if run.is_empty() or not over(run):
		return {}
	var r := reward(run)
	Progress.grant(save, r)
	if bool(run.get("won", false)):
		var won = save.get("runs_won", {})
		if typeof(won) != TYPE_DICTIONARY:
			won = {}
		var key := str(int(run.planet))
		won[key] = int(won.get(key, 0)) + 1
		save["runs_won"] = won
	run["claimed"] = true
	save["run"] = run
	return r
