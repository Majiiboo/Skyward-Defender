class_name Season
extends RefCounted
# THE SEASON PASS (2026-11-10). A 30-day season with 30 tiers. Everything you play pays season XP
# (a stage won or lost, the Daily Challenge, the weekly event, an Expedition stop, a daily quest
# claimed); every TIER_XP is a tier. Each tier has a FREE reward for everyone and a PREMIUM reward
# for whoever unlocked the premium track this season (crystals for now: PREMIUM_COST; real money
# when billing exists). Rewards wait until claimed and are lost when the season turns over, so
# there is a reason to come back before it ends. Opens once stage SEASON_FROM is cleared.
# Save "season": {"n": season number, "xp": n, "free": tiers claimed, "prem": tiers claimed,
# "premium": bool}. A save from another season starts fresh.

const SEASON_FROM := 8
const SEASON_S := 30 * 86400
const TIERS := 30
const TIER_XP := 100
const PREMIUM_COST := 800
# season XP for what you do
const XP_WIN := 30
const XP_LOSS := 10
const XP_SPECIAL := 15      # on top, for a Daily Challenge / event / Expedition / trial fight
const XP_QUEST := 20        # a daily quest claimed
const NAMES := ["Ember Dawn", "Iron Tide", "Frost Line", "Void Watch", "Solar Crown", "Storm Front"]

static func number() -> int:
	return int(Time.get_unix_time_from_system() / float(SEASON_S))

static func name_of(n: int = -1) -> String:
	if n < 0:
		n = number()
	return String(NAMES[n % NAMES.size()])

static func ends_in_s() -> int:
	return (number() + 1) * SEASON_S - int(Time.get_unix_time_from_system())

static func left_text() -> String:
	var s := ends_in_s()
	if s >= 86400:
		return "%dd %dh" % [s / 86400, (s % 86400) / 3600]
	return "%dh %02dm" % [s / 3600, (s % 3600) / 60]

static func open(save: Dictionary) -> bool:
	return DevTools.on or int(save.get("stage_unlocked", 1)) > SEASON_FROM

static func state(save: Dictionary) -> Dictionary:
	var e = save.get("season", {})
	if typeof(e) != TYPE_DICTIONARY or int(e.get("n", -1)) != number():
		return {"n": number(), "xp": 0, "free": 0, "prem": 0, "premium": false}
	return {"n": number(), "xp": maxi(int(e.get("xp", 0)), 0), "free": clampi(int(e.get("free", 0)), 0, TIERS),
		"prem": clampi(int(e.get("prem", 0)), 0, TIERS), "premium": bool(e.get("premium", false))}

# tiers reached (0..TIERS)
static func tier(save: Dictionary) -> int:
	return clampi(int(state(save).xp) / TIER_XP, 0, TIERS)

# XP into the tier being filled (0 at the last tier)
static func tier_xp(save: Dictionary) -> int:
	if tier(save) >= TIERS:
		return TIER_XP
	return int(state(save).xp) % TIER_XP

static func add_xp(save: Dictionary, n: int) -> void:
	if not open(save) or n <= 0:
		return
	var st := state(save)
	st.xp = mini(int(st.xp) + n, TIERS * TIER_XP)
	save["season"] = st

# what tier t (1..TIERS) pays on each track. Free: coins, parts, a key now and then, crystals on
# every fifth. Premium: about three times the worth, shards for the hero on duty, the big keys.
static func reward(t: int, premium: bool, save: Dictionary = {}) -> Dictionary:
	var hero := String(Heroes.read(save).selected) if not save.is_empty() else "rook"
	if not premium:
		if t == TIERS:
			return {"crystals": 100, "key_e": 1}
		if t % 5 == 0:
			return {"crystals": 15 + t}
		match t % 5:
			1: return {"coins": 300 + 60 * t}
			2: return {"alloy": 4 + t / 3}
			3: return {"key_u": 1}
			_: return {"cell": 2 + t / 6}
	if t == TIERS:
		return {"crystals": 300, "key_e": 2, "shards": {hero: 30}}
	if t % 5 == 0:
		return {"crystals": 40 + 2 * t, "key_e": 1}
	match t % 5:
		1: return {"coins": 1000 + 200 * t}
		2: return {"shards": {hero: 4 + t / 6}}
		3: return {"key_u": 2}
		_: return {"core": 1 + t / 10, "cell": 4}

static func unlock_premium(save: Dictionary) -> String:
	var st := state(save)
	if bool(st.premium):
		return "Already yours this season"
	if not DevTools.on:
		if int(save.get("crystals", 0)) < PREMIUM_COST:
			return "%d crystals needed" % PREMIUM_COST
		save["crystals"] = int(save.get("crystals", 0)) - PREMIUM_COST
	st.premium = true
	save["season"] = st
	return ""

# rewards reached and not taken yet (premium ones count only once the track is unlocked)
static func waiting(save: Dictionary) -> int:
	var st := state(save)
	var t := tier(save)
	return maxi(t - int(st.free), 0) + (maxi(t - int(st.prem), 0) if bool(st.premium) else 0)

static func claimable(save: Dictionary) -> bool:
	return open(save) and waiting(save) > 0

# take everything that is waiting; returns the list of rewards taken (each a reward dictionary)
static func claim_all(save: Dictionary) -> Array:
	var st := state(save)
	var t := tier(save)
	var got: Array = []
	for i in range(int(st.free) + 1, t + 1):
		got.append(reward(i, false, save))
	st.free = maxi(int(st.free), t)
	if bool(st.premium):
		for i in range(int(st.prem) + 1, t + 1):
			got.append(reward(i, true, save))
		st.prem = maxi(int(st.prem), t)
	save["season"] = st
	for r in got:
		Progress.grant(save, r)
	return got
