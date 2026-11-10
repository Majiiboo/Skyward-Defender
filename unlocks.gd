class_name Unlocks
extends RefCounted
# Progressive disclosure (Rudy, dev168 fun pass: "too much to absorb, not enough play").
# Every system stays built, but a new player only SEES Play, the Pilot gear page, Quests and
# the Store. The rest appears one piece at a time as the player reaches it, each announced
# once on Home with a NEW pop-up that takes you there. Nothing here changes what a system
# does; it only decides when it is shown.
# UNLOCKS: id -> "stage" = the Standard stage that must be CLEARED (save stage_unlocked > n)
# or "level" = the pilot level; "name" + "text" for the pop-up; "go" = [nav tab, meta, index]
# like hub.gd's rail "go" (opens that page on that tab).
# Save "seen_new": ids already announced.

const UNLOCKS := {
	# the battle buttons and modes of 2026-11-10 (battle.gd ABILITY_FROM / AUTO_FROM, Promotion.DAILY_FROM / TWIST_FROM)
	"ability":   {"stage": 2,  "name": "Hero ability", "go": [], "pic": "el_energy",
		"text": "The round button at the bottom left of a fight: your hero's big move, about every 40 seconds."},
	"pulse":     {"stage": 7,  "name": "Core Pulse", "go": [], "pic": "st_def",
		"text": "Tap the glowing core of your base in a fight: for 4 seconds nothing can hurt the base, and bugs close to it are stunned."},
	"season":    {"stage": 8,  "name": "Season Pass", "go": [], "pic": "tab_trophies",
		"text": "Thirty tiers of rewards every 30 days. Every fight and daily quest moves you up. The trophy button on Home."},
	"research":  {"stage": 12, "name": "Research Lab", "go": ["NavGear", "gear_page", 1], "pic": "st_aim",
		"text": "Slow, permanent upgrades that run on real time, even while the game is closed. Heroes > Base > Research."},
	"auto":      {"stage": 3,  "name": "AUTO pilot", "go": [], "pic": "ic_energy",
		"text": "Tap AUTO in a fight and an autopilot flies and aims for you. Your own hands still beat it."},
	"turrets":   {"stage": 5,  "name": "The Base",   "go": ["NavGear", "gear_page", 1], "pic": "ic_base",
		"text": "Your base has its first slot. Build on it: each building gives one kind of help, and you field four."},
	"daily":     {"stage": 5,  "name": "Daily Challenge", "go": ["NavModes", "", 0], "pic": "ic_gift",
		"text": "One fight a day on your best stage with three twists. The first win pays coins, crystals and a key."},
	"run":       {"stage": 5,  "name": "Expedition", "go": ["NavModes", "", 0], "pic": "ic_rank",
		"text": "A run of eight stops across a planet. Your cards and health carry from fight to fight; the boss waits at the end."},
	"patrol":    {"stage": 6,  "name": "Patrol",    "go": [], "pic": "res://drone/body_scout.png",
		"text": "Patrol farms a stage you have cleared while you are away: coins, parts, spare gear."},
	"workshop":  {"stage": 8,  "name": "Workshop",  "go": ["NavGear", "gear_page", 3], "pic": "ic_cell",
		"text": "Merge parts into better parts, and spare gear copies into higher rarity."},
	"repeat":    {"stage": 3,  "name": "Repeat quests", "go": ["NavQuests", "quests_tab", 3],
		"text": "Goals that come back bigger every time you claim them."},
	"promotion": {"level": 5,  "name": "Promotion", "go": ["NavModes", "", 0], "pic": "ic_rank",
		"text": "Rank trials in Modes: one very hard stage each. Win once and you are stronger for good."},
	"drone":     {"level": 8,  "name": "Drone",     "go": ["NavGear", "gear_page", 2], "pic": "res://drone/body_scout.png",
		"text": "A sidekick that flies with you. Pick one and level it in Gear > Drone."},
	"elite":     {"level": 10, "name": "Elite",     "go": ["NavModes", "", 0], "pic": "ic_elite",
		"text": "A second ladder from stage 1 with far tougher bugs and better drops."},
	"twists":    {"stage": 10, "name": "Daily twists", "go": [], "pic": "tw_rapid",
		"text": "From here every stage carries one advantage and one disadvantage that change each day, and pays 20% more coins."},
	"event":     {"stage": 10, "name": "Weekly event", "go": ["NavModes", "", 0], "pic": "ic_gift",
		"text": "A themed week: its own twists, and a track of ten rewards you fill by fighting in it."},
	"loadouts":  {"stage": 12, "name": "Loadouts",  "go": ["NavGear", "gear_page", 0],
		"text": "Save three kits of gear, turrets and drone and switch in one tap."},
}

# is this system shown yet?
static func open(save: Dictionary, id: String) -> bool:
	if DevTools.on:
		return true
	if not UNLOCKS.has(id):
		return true
	var u: Dictionary = UNLOCKS[id]
	if u.has("stage") and int(save.get("stage_unlocked", 1)) > int(u.stage):
		return true
	if u.has("level") and Turrets.pilot_level(int(save.get("pilot_xp", 0))) >= int(u.level):
		return true
	# the Workshop also opens as soon as there is something to merge: a SPARE copy of a piece
	# (every unlocked piece counts as one Common copy, so one is not a spare) or enough parts
	if id == "workshop":
		var g := GearData.read(save)
		for pid in g.copies:
			var n := 0
			for r in g.copies[pid]:
				n += int(g.copies[pid][r])
			if n >= 2:
				return true
		var parts := Parts.read(save)
		for k in Parts.MERGE:
			if int(parts.get(k, 0)) >= Parts.MERGE_COST:
				return true
	return false

# "Unlocks after stage 5" / "Unlocks at pilot Lv.8" for a teaser
static func hint(id: String) -> String:
	var u: Dictionary = UNLOCKS.get(id, {})
	if u.has("stage"):
		return "Unlocks after stage %d" % int(u.stage)
	if u.has("level"):
		return "Unlocks at pilot Lv.%d" % int(u.level)
	return ""

# systems that are open but have not been announced yet (in table order)
static func fresh(save: Dictionary) -> Array:
	var seen: Array = save.get("seen_new", [])
	var out: Array = []
	for id in UNLOCKS:
		if open(save, id) and not seen.has(id):
			out.append(id)
	return out

static func mark_seen(save: Dictionary, id: String) -> void:
	var seen: Array = save.get("seen_new", [])
	if not seen.has(id):
		seen.append(id)
	save["seen_new"] = seen

# a fresh save from before this build: everything already open is taken as seen, so a
# veteran is not greeted with eight pop-ups in a row
static func settle(save: Dictionary) -> void:
	if save.has("seen_new"):
		return
	var seen: Array = []
	for id in UNLOCKS:
		if open(save, id):
			seen.append(id)
	save["seen_new"] = seen

# the picture for the unlock moment: a res:// path or an icon name ("pic"), else none
static func pic(id: String) -> Texture2D:
	var p := String(UNLOCKS.get(id, {}).get("pic", ""))
	if p == "":
		return null
	if p.begins_with("res://"):
		return load(p) if ResourceLoader.exists(p) else null
	return UIKit.ic(p)
