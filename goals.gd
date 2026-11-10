class_name Goals
extends RefCounted
# THE NEXT GOAL (2026-11-10; IDEAS-tap-titans-afk.md 1, REVIEW-2026-11-10.md): Home always names
# one thing worth doing next, in a few words, and a tap takes you there. Things you can do right
# now come first (an Ascend that is ready, a free chest, a level you can afford); otherwise the
# next thing a stage clear unlocks.
# next(save) -> {"text": ..., "go": [nav tab, root meta, index]} ("go" empty = it is a stage to clear)

# what clearing a Standard stage opens, beyond the Unlocks table: the battle buttons (battle.gd
# ABILITY_FROM / AUTO_FROM / RUNNER_FROM), the daily twists (Promotion.TWIST_FROM), speed x1.5
const STAGE_OPENS := {2: "your hero's ability", 3: "the AUTO pilot", 10: "game speed x1.5"}

static func next(save: Dictionary) -> Dictionary:
	var h := Heroes.read(save)
	var id := Heroes.selected(h)
	var hname := String(Heroes.ROSTER[id].name)
	var lv := Heroes.level(h, id)
	var cap := Heroes.level_cap(h, id)
	if lv >= cap and Heroes.tier(h, id) < Gates.MAX_STAR and Heroes.why_not_evolve(h, id, save) == "":
		return {"text": "%s is ready to ASCEND" % hname, "go": ["NavGear", "gear_page", 0]}
	if load("res://store.gd").free_waiting(save):
		return {"text": "A free chest is waiting", "go": ["NavStore", "store_tab", 0]}
	if lv < cap and int(save.get("coins", 0)) >= Heroes.level_cost(lv):
		return {"text": "Level up %s" % hname, "go": ["NavGear", "gear_page", 0]}
	if Promotion.daily_open(save) and not Promotion.daily_done(save):
		return {"text": "Today's challenge is waiting", "go": ["NavModes", "", 0]}
	var st := stage_goal(int(save.get("stage_unlocked", 1)))
	if not st.is_empty():
		return st
	if lv >= cap and Heroes.tier(h, id) < Gates.MAX_STAR:
		return {"text": "%s: %s" % [hname, Heroes.why_not_evolve(h, id, save)], "go": ["NavGear", "gear_page", 0]}
	return {"text": "Beat your best in Horde", "go": ["NavModes", "", 0]}

# the nearest thing a stage clear opens: "Clear stage 5: Turrets"
static func stage_goal(stage_unlocked: int) -> Dictionary:
	var opens := {}   # stage -> what it opens
	for s in STAGE_OPENS:
		opens[int(s)] = String(STAGE_OPENS[s])
	for uid in Unlocks.UNLOCKS:
		var u: Dictionary = Unlocks.UNLOCKS[uid]
		if u.has("stage") and not opens.has(int(u.stage)):
			opens[int(u.stage)] = String(u.name)
	for i in Turrets.MOUNT_OPENS_AFTER.size():
		var ms := int(Turrets.MOUNT_OPENS_AFTER[i])
		opens[ms] = (String(opens[ms]) + " + turret mount %d" % (i + 1)) if opens.has(ms) else "turret mount %d" % (i + 1)
	for a in range(1, StageData.AREAS.size()):   # a new planet after every 10th stage
		var ps := a * 10
		opens[ps] = (String(StageData.AREAS[a].name) + (" + " + String(opens[ps]) if opens.has(ps) else ""))
	var best := 0
	for s in opens:
		if int(s) >= stage_unlocked and (best == 0 or int(s) < best):
			best = int(s)
	if best == 0 or best > StageData.MAX_STAGE:
		return {}
	return {"text": "Clear stage %d: %s" % [best, String(opens[best])], "go": [], "stage": best}
