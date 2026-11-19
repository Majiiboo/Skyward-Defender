class_name Bounties
extends RefCounted
# STAGE BOUNTIES (2026-11-18, agreed from the reviews: replay value). Every cleared Standard stage
# from stage BOUNTY_FROM up carries ONE bounty: play that stage again under one restriction and
# win, for a reward of materials that is paid ONCE. Boss stages have one too. Which restriction a
# stage gets is fixed by its number (kind_of), so it never changes and cannot be re-rolled.
# Found on the Campaign page, in the sheet of a cleared stage (stage_map.gd).
# The fight: start() asks once through save "selected_mode" == "bounty" + "bounty_stage"; the
# battle takes the ask (take), applies the restriction, plays the stage at its normal difficulty,
# writes no stars and unlocks nothing, and on a win calls finish().
# Save "bounties": {"done": [stages]}.

const BOUNTY_FROM := 6
const GLASS_HP := 0.6          # "glass": the hero's health is cut to this share
# "from" = the first stage the restriction can bite at (the Core Pulse opens after stage 7, the
# fourth base slot after stage 18); a stage below it gets one of the ALWAYS kinds instead
const KINDS := {
	"no_ability": {"name": "Bare Hands",   "text": "The hero's own ability is off.",        "icon": "ic_energy",    "from": 0},
	"glass":      {"name": "Glass Hero",   "text": "The hero has 40% less health.",     "icon": "ui_heart",     "from": 0},
	"no_refresh": {"name": "First Hand",   "text": "No card refreshes.",                "icon": "ic_exchange",  "from": 0},
	"swift":      {"name": "Swift Strike", "text": "Win in under %s.",                  "icon": "tw_swift_bugs", "from": 0},
	"no_pulse":   {"name": "Quiet Core",   "text": "The Core Pulse is off.",            "icon": "ic_base",      "from": 8},
	"three_slots": {"name": "Short Deck",  "text": "Base slot 4 stays dark.",           "icon": "ic_mount",     "from": 19},
}
const ORDER := ["no_ability", "glass", "no_refresh", "swift", "no_pulse", "three_slots"]
const ALWAYS := ["no_ability", "glass", "no_refresh", "swift"]

# the restriction of a stage: by its number, for good
static func kind_of(stage: int) -> String:
	var k := String(ORDER[stage % ORDER.size()])
	if stage < int(KINDS[k].from):
		k = String(ALWAYS[stage % ALWAYS.size()])
	return k

# "swift": the seconds to win in, by how long the stages of that band usually last (generous)
static func time_limit(stage: int) -> int:
	if stage <= 10:
		return 180
	if stage <= 20:
		return 270
	if stage <= 40:
		return 300
	return 360

static func name_of(stage: int) -> String:
	return String(KINDS[kind_of(stage)].name)

static func text_of(stage: int) -> String:
	var k := kind_of(stage)
	if k == "swift":
		return String(KINDS[k].text) % Energy.clock(time_limit(stage))
	return String(KINDS[k].text)

static func icon_of(stage: int) -> Texture2D:
	return UIKit.ic(String(KINDS[kind_of(stage)].icon), "ic_trial")

# the stage has a bounty on offer: a Standard stage from BOUNTY_FROM up that you have cleared
static func open(save: Dictionary, stage: int) -> bool:
	if stage < BOUNTY_FROM or stage > StageData.MAX_STAGE:
		return false
	return DevTools.on or int(save.get("stage_unlocked", 1)) > stage

# what it pays, once: the essence this planet's bugs are weak to and weapon materials, more on
# later planets, plus a few crystals; a boss stage (every 5th) pays one essence and 5 crystals more
static func reward(stage: int) -> Dictionary:
	var a := StageData.area_index(stage)
	var boss := stage % 5 == 0
	var out := {}
	out[Materials.essence_of(String(Heroes.family(stage).weak))] = 1 + a / 2 + (1 if boss else 0)
	out["barrel"] = 2 + a
	if a >= 2:
		out["lens"] = a - 1
	if a >= 4:
		out["coil"] = 1
	out["crystals"] = 5 + 2 * a + (5 if boss else 0)
	return out

static func _done_list(save: Dictionary) -> Array:
	var s = save.get("bounties", {})
	if typeof(s) != TYPE_DICTIONARY:
		return []
	var d = s.get("done", [])
	return d if typeof(d) == TYPE_ARRAY else []

static func done(save: Dictionary, stage: int) -> bool:
	for s in _done_list(save):
		if int(s) == stage:
			return true
	return false

# open bounties not won yet
static func waiting(save: Dictionary) -> int:
	var n := 0
	for s in range(BOUNTY_FROM, StageData.MAX_STAGE + 1):
		if open(save, s) and not done(save, s):
			n += 1
	return n

# ask for the bounty fight of `stage` (the battle takes the ask once); false when it is not open
static func start(save: Dictionary, stage: int) -> bool:
	if not open(save, stage):
		return false
	save["selected_mode"] = "bounty"
	save["bounty_stage"] = stage
	return true

# the battle takes the ask: the stage to fight, 0 when none was asked. The mode goes back to normal.
static func take(save: Dictionary) -> int:
	if String(save.get("selected_mode", "normal")) != "bounty":
		return 0
	save["selected_mode"] = "normal"
	var s := int(save.get("bounty_stage", 0))
	return s if s >= BOUNTY_FROM and s <= StageData.MAX_STAGE else 0

# a bounty fight was WON in `seconds`. Returns {"paid", "reward", "why"}: paid the first time the
# restriction was met; "why" says what was in the way (too slow, already yours).
static func finish(save: Dictionary, stage: int, seconds: float) -> Dictionary:
	if kind_of(stage) == "swift" and seconds > float(time_limit(stage)):
		return {"paid": false, "reward": {}, "why": "Too slow:  %s of %s" % [Energy.clock(int(seconds)), Energy.clock(time_limit(stage))]}
	if done(save, stage):
		return {"paid": false, "reward": {}, "why": "This bounty is already yours"}
	var r := reward(stage)
	Progress.grant(save, r)
	var got := _done_list(save).duplicate()
	got.append(stage)
	save["bounties"] = {"done": got}
	return {"paid": true, "reward": r, "why": ""}
