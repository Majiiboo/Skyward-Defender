class_name Gates
extends RefCounted
# ONE standard for what progress unlocks what (Rudy, 2026-11-06): "higher tiers and higher
# stars should be under a locked standard, in relation to level or stages", and "really
# unique or strong heroes or weapons could be locked behind a purchase".
#   STARS   a hero, turret or drone body of grade N can only be BOUGHT once GRADE_STAGE[N] is
#           cleared (an item's own "stage" gate still counts when it is higher).
#   TIERS   a hero's tier 2 / 3 evolution needs TIER_STAGE cleared (plus shards and essences).
#   LEVELS  every upgrade track (hero level, weapon level, turret tracks, drone level) is capped
#           at a share of its own maximum: BANDS[0] of it from the start, the next band every
#           ten stages cleared, the whole track once stage 40 is cleared.
#   PREMIUM "premium": true on a hero / turret / body = no coin price: crystals only (a real-money
#           pack later, Store 2.0). Ember carries it today.
# Dev mode (DevTools.on) opens everything. Cleared stages = save "stage_unlocked" - 1.

const GRADE_STAGE := {1: 0, 2: 10, 3: 20, 4: 35, 5: 50}
const TIER_STAGE := {2: 15, 3: 30}
const BANDS := [0.34, 0.5, 0.67, 0.84, 1.0]   # share of a track's max level open after 0 / 10 / 20 / 30 / 40 stages cleared
const BAND_STAGES := 10

static func cleared(save: Dictionary) -> int:
	if DevTools.on:
		return StageData.MAX_STAGE
	return maxi(int(save.get("stage_unlocked", 1)) - 1, 0)

# ---- stars
static func grade_stage(grade: int) -> int:
	return int(GRADE_STAGE.get(clampi(grade, 1, 5), 0))

# the stage an item needs cleared: its stars' gate or its own, whichever is higher
static func item_stage(grade: int, own_stage: int = 0) -> int:
	return maxi(grade_stage(grade), own_stage)

static func stage_open(save: Dictionary, stage: int) -> bool:
	return cleared(save) >= stage

# ---- tiers
static func tier_stage(tier: int) -> int:
	return int(TIER_STAGE.get(tier, 0))

static func tier_open(save: Dictionary, tier: int) -> bool:
	return stage_open(save, tier_stage(tier))

# ---- levels
# the highest level a track with `max_level` levels can reach right now
static func level_cap(save: Dictionary, max_level: int) -> int:
	if DevTools.on:
		return max_level
	var band: int = mini(cleared(save) / BAND_STAGES, BANDS.size() - 1)
	return clampi(roundi(max_level * float(BANDS[band])), 1, max_level)

# the stage to clear before level `want` of that track opens (0 = open already)
static func level_stage(want: int, max_level: int) -> int:
	for i in BANDS.size():
		if want <= roundi(max_level * float(BANDS[i])):
			return i * BAND_STAGES
	return (BANDS.size() - 1) * BAND_STAGES

# "Clear stage 20 for Lv.21" (empty when the next level is open)
static func cap_text(save: Dictionary, level: int, max_level: int) -> String:
	if level >= max_level or level < level_cap(save, max_level):
		return ""
	return "Stage %d\nfor Lv.%d" % [level_stage(level + 1, max_level), level + 1]

# ---- premium
static func premium(def: Dictionary) -> bool:
	return bool(def.get("premium", false))

static func stage_text(stage: int) -> String:
	return "Clear stage %d first" % stage
