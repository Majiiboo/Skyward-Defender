class_name StageOffers
extends RefCounted
# STAGE OFFERS (Rudy, dev265: "the per-stage offer pops up every time you beat a stage, and people
# can go back and buy one they did not buy"). Every fifth stage you clear (5, 10, 15 ...) opens
# one bundle, bigger for later stages, buyable ONCE and never taken away: a missed one waits in
# Store > Offers > Stage. Home announces a new one once (due / mark_seen).
# Priced in CRYSTALS until Google Play billing exists; `was` is what the contents cost bought
# one by one, so the saving is honest.
# Save "stage_offers": {"bought": [stages], "seen": the last stage announced}.

const EVERY := 5

static func _state(save: Dictionary) -> Dictionary:
	var s = save.get("stage_offers", {})
	if typeof(s) != TYPE_DICTIONARY:
		s = {}
	var b = s.get("bought", [])
	return {"bought": b if typeof(b) == TYPE_ARRAY else [], "seen": int(s.get("seen", 0))}

# the stages whose offer is open, newest first
static func stages(save: Dictionary) -> Array:
	var cleared := (StageData.MAX_STAGE if DevTools.on else int(save.get("stage_unlocked", 1)) - 1)
	var out: Array = []
	var s := (cleared / EVERY) * EVERY
	while s >= EVERY:
		out.append(s)
		s -= EVERY
	return out

# what the offer of `stage` holds and costs
static func offer(stage: int) -> Dictionary:
	var k := maxi(stage / EVERY, 1)
	var reward := {"coins": 1500 * k, "key_u": 2 + k / 3, "shards_duty": 8 + 2 * k}
	if k >= 2:
		reward["key_e"] = k / 2
	if k >= 3:
		reward["core"] = k / 3
	var cost := 60 + 30 * k
	return {"stage": stage, "name": "Stage %d offer" % stage, "reward": reward, "cost": cost, "was": cost * 3,
		"boss": stage % 10 == 0}

static func bought(save: Dictionary, stage: int) -> bool:
	for b in _state(save).bought:
		if int(b) == stage:
			return true
	return false

# any open offer not bought yet (the Offers tab's dot does NOT use this: it is not free)
static func waiting(save: Dictionary) -> int:
	var n := 0
	for s in stages(save):
		if not bought(save, int(s)):
			n += 1
	return n

static func why_not(save: Dictionary, stage: int) -> String:
	if not stages(save).has(stage):
		return "Clear stage %d first" % stage
	if bought(save, stage):
		return "Bought"
	if not DevTools.on and int(save.get("crystals", 0)) < int(offer(stage).cost):
		return "%d crystals needed" % int(offer(stage).cost)
	return ""

# buy it; "" on success. The hero shards go to the hero on duty.
static func buy(save: Dictionary, stage: int) -> String:
	var why := why_not(save, stage)
	if why != "":
		return why
	var o := offer(stage)
	if not DevTools.on:
		save["crystals"] = int(save.get("crystals", 0)) - int(o.cost)
	var give: Dictionary = Dictionary(o.reward).duplicate()
	if give.has("shards_duty"):
		give["shards"] = {String(Heroes.read(save).selected): int(give.shards_duty)}
		give.erase("shards_duty")
	Progress.grant(save, give)
	var st := _state(save)
	st.bought.append(stage)
	save["stage_offers"] = st
	return ""

# the newest open offer Home has not announced yet (0 = none)
static func due(save: Dictionary) -> int:
	var st := _state(save)
	for s in stages(save):
		if int(s) > int(st.seen) and not bought(save, int(s)):
			return int(s)
	return 0

static func mark_seen(save: Dictionary, stage: int) -> void:
	var st := _state(save)
	st.seen = maxi(int(st.seen), stage)
	save["stage_offers"] = st
