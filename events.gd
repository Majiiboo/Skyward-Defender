class_name Events
extends RefCounted
# THE WEEKLY EVENT (2026-11-10; IDEAS-2026-11-10.md 9): a themed week. Each week has a name, a
# pair of twists that set its mood, and a track of ten rewards filled with event points. A fight
# is your best cleared stage under the week's twists (battle `event_run`, counted as a trial: no
# stars, no stage unlocks). Points: EVENT_WIN for a win, more for a clean one, a few for a loss.
# The theme and your points change over on their own every seven days. Opens once stage
# EVENT_FROM is cleared. Save "event": {"week": n, "points": n, "claimed": n}.
# More themes = more entries in THEMES; nothing else changes.

const EVENT_FROM := 10
const WEEK_S := 7 * 86400
const EVENT_HP := 1.1
const ANOMALY_HP := 1.7        # a loadout week: the bugs are this much tougher again (the given kit walked through the fight)
const EVENT_WIN := 20
const THEMES := [
	{"id": "scrap_rush", "name": "Scrap Rush", "text": "Your ability charges fast. Bugs wear thick shells.",
		"mods": ["turret_boost", "thick_shells"], "col": Color(0.75, 0.8, 0.9), "icon": "ic_alloy"},
	{"id": "night_hunt", "name": "Night Hunt", "text": "Crits come easy. Bugs come fast.",
		"mods": ["sharpshooter", "swift_bugs"], "col": Color(0.71, 0.55, 1.0), "icon": "el_dark"},
	{"id": "iron_dome", "name": "Iron Dome", "text": "A stronger shield under heavier spit.",
		"mods": ["fortified", "double_spit"], "col": Color(0.31, 0.88, 1.0), "icon": "st_def"},
	{"id": "overdrive", "name": "Overdrive", "text": "Cards come faster. The shield is cracked.",
		"mods": ["overcharge", "weak_shield"], "col": Color(1.0, 0.78, 0.27), "icon": "ic_energy"},
	# ANOMALY weeks: a theme with a "loadout" hands EVERYONE the same kit (see THE ANOMALY below)
	{"id": "borrowed_wings", "name": "Borrowed Wings", "text": "Cpt. Frost and his stream rifle behind a wall of a base. Hold the line.",
		"mods": ["fortified", "swift_bugs"], "col": Color(0.55, 0.85, 1.0), "icon": "el_ice",
		"loadout": {"hero": "frost", "weapon_class": "main", "base": ["shield_gen", "repair_bay", "plating", "medbay"]}},
	{"id": "glass_arsenal", "name": "Glass Arsenal", "text": "Ember and her launcher over a base that only knows attack. Kill fast.",
		"mods": ["sharpshooter", "weak_shield"], "col": Color(1.0, 0.55, 0.3), "icon": "el_fire",
		"loadout": {"hero": "ember", "weapon_class": "heavy", "base": ["armory", "reactor", "radar", "hangar"]}},
]
# the track: event points needed, and what it pays
const TRACK := [
	{"points": 20,  "reward": {"coins": 500}},
	{"points": 40,  "reward": {"key_u": 1}},
	{"points": 70,  "reward": {"crystals": 20}},
	{"points": 100, "reward": {"cell": 5}},
	{"points": 140, "reward": {"coins": 2000}},
	{"points": 180, "reward": {"key_u": 2}},
	{"points": 230, "reward": {"crystals": 40}},
	{"points": 280, "reward": {"core": 2}},
	{"points": 340, "reward": {"key_e": 1}},
	{"points": 400, "reward": {"crystals": 100, "key_e": 1}},
]

static func week() -> int:
	return int(Time.get_unix_time_from_system() / float(WEEK_S))

# a save key "event_theme_test" (a theme id) forces that theme for testing; it is picked up
# whenever a save passes through open / stage / state, which every user of theme() does first
static var forced := ""

static func _sync(save: Dictionary) -> void:
	forced = String(save.get("event_theme_test", ""))

static func theme(w: int = -1) -> Dictionary:
	if w < 0:
		for th in THEMES:
			if forced != "" and String(th.id) == forced:
				return th
		w = week()
	return THEMES[w % THEMES.size()]

static func ends_in_s() -> int:
	return (week() + 1) * WEEK_S - int(Time.get_unix_time_from_system())

static func open(save: Dictionary) -> bool:
	_sync(save)
	return DevTools.on or int(save.get("stage_unlocked", 1)) > EVENT_FROM

static func stage(save: Dictionary) -> int:
	_sync(save)
	return Promotion.daily_stage(save)

# this week's points and rewards taken (a save from another week starts fresh)
static func state(save: Dictionary) -> Dictionary:
	_sync(save)
	var e = save.get("event", {})
	if typeof(e) != TYPE_DICTIONARY or int(e.get("week", -1)) != week():
		return {"week": week(), "points": 0, "claimed": 0}
	return {"week": week(), "points": maxi(int(e.get("points", 0)), 0), "claimed": clampi(int(e.get("claimed", 0)), 0, TRACK.size())}

# the points a fight pays: a win, +5 with the hull above half, +5 with the hero untouched; 5 for a loss
static func points_for(won: bool, hull_share: float, hp_lost: float) -> int:
	if not won:
		return 5
	return EVENT_WIN + (5 if hull_share >= 0.5 else 0) + (5 if hp_lost <= 0.0 else 0)

static func add_points(save: Dictionary, n: int) -> void:
	var st := state(save)
	st.points = int(st.points) + maxi(n, 0)
	save["event_tokens"] = int(save.get("event_tokens", 0)) + maxi(n, 0)   # a token a point, for the Event store
	save["event"] = st

# how many track steps the points have reached
static func reached(save: Dictionary) -> int:
	var st := state(save)
	var n := 0
	for t in TRACK:
		if int(st.points) >= int(t.points):
			n += 1
	return n

static func claimable(save: Dictionary) -> bool:
	return int(state(save).claimed) < reached(save)

# take the next reward on the track; returns it ({} = nothing to take)
static func claim_next(save: Dictionary) -> Dictionary:
	if not claimable(save):
		return {}
	var st := state(save)
	var reward: Dictionary = TRACK[int(st.claimed)].reward
	st.claimed = int(st.claimed) + 1
	save["event"] = st
	Progress.grant(save, reward)
	return reward

# ------------------------------------------------------------------ THE ANOMALY (a fixed-loadout week)
# A theme with a "loadout" {hero, weapon_class, base [four buildings]} is fought by EVERYONE with
# that same kit: a test of play and card choices, not of how levelled you are. The kit grows with
# the stage the event is fought on (your best cleared stage), so it is a fair fight at any point.
const KIT_LEVEL_PLUS := -3     # hero level = the stage + this, 8..60 (lean on purpose: the kit should make it a fight)
const KIT_ALL_SLOTS := 19      # a "stage_unlocked" at which all four base slots are open

static func has_loadout(th: Dictionary = {}) -> bool:
	if th.is_empty():
		th = theme()
	return th.has("loadout")

# the kit in numbers for a stage: {hero, hero_level, star, weapon_class, weapon_level, base, base_level}
# ({} for a week without one)
static func loadout(stage_n: int, th: Dictionary = {}) -> Dictionary:
	if th.is_empty():
		th = theme()
	if not th.has("loadout"):
		return {}
	var lo: Dictionary = th.loadout
	var hid := String(lo.hero)
	var lv := clampi(stage_n + KIT_LEVEL_PLUS, 8, 60)
	var star := clampi(int(ceil(lv / 10.0)), Heroes.grade(hid), Gates.MAX_STAR)   # the step that allows that level
	var wcap := int(Arsenal.CAPS[clampi(star, 1, Arsenal.CAPS.size()) - 1])
	return {"hero": hid, "hero_level": lv, "star": star, "weapon_class": String(lo.weapon_class),
		"weapon_level": clampi(stage_n / 3 + 2, 3, mini(wcap, GearData.MAX_LEVEL)), "base": Array(lo.base).duplicate(),
		"base_level": clampi(stage_n / 8 + 1, 1, Base.MAX_LEVEL)}

# THE SAVE THE FIGHT READS ITS KIT FROM: a deep COPY of the real save with the loadout written in.
# It is only ever READ (battle._start_stage); it must never be written back. Everything of the
# player's own that would make two players differ is set aside in the copy: his hero, weapon, base,
# wingmate, ability upgrades, mastery and chips of that weapon, talents, research, rank bonus, drone.
# A week without a loadout returns the save itself, untouched.
static func kit_save(real: Dictionary, stage_n: int) -> Dictionary:
	_sync(real)
	var k := loadout(stage_n)
	if k.is_empty():
		return real
	var d := real.duplicate(true)
	var hid := String(k.hero)
	var cls := String(k.weapon_class)
	var h := Heroes.read(d)
	if not h.owned.has(hid):
		h.owned.append(hid)
	h.selected = hid
	h.levels[hid] = int(k.hero_level)
	h.tiers[hid] = maxi(int(k.star) - Heroes.grade(hid) + 1, 1)
	h.def[hid] = 1
	h.ability[hid] = 0
	h["wing"] = ""
	d["hero"] = Heroes.write(h)
	var a := Arsenal.read(d)
	a[hid] = {"equipped": cls, "owned": Arsenal.ORDER.duplicate(), "levels": {cls: int(k.weapon_level)}}
	Arsenal.write(d, a)
	var levels := {}
	for id in k.base:
		levels[String(id)] = int(k.base_level)
	d["base"] = {"slots": Array(k.base).duplicate(), "levels": levels}
	d["stage_unlocked"] = maxi(int(d.get("stage_unlocked", 1)), KIT_ALL_SLOTS)
	var key := Arsenal.key(hid, cls)
	if d.get("mastery") is Dictionary:
		d.mastery.erase(key)
	if d.get("chips") is Dictionary and d.chips.get("fit") is Dictionary:
		d.chips.fit.erase(key)   # the weapon wears its own chips (Chips.defaults)
	d["talents"] = 0
	d.erase("research")
	d["promotion"] = 0
	d.erase("drone")
	d.erase("special_test")
	return d

# "3d 4h" / "5h 12m"
static func left_text() -> String:
	var s := ends_in_s()
	if s >= 86400:
		return "%dd %dh" % [s / 86400, (s % 86400) / 3600]
	return "%dh %02dm" % [s / 3600, (s % 3600) / 60]

# ------------------------------------------------------------------ THE EVENT STORE (Rudy, dev265)
# Every event point also pays one EVENT TOKEN. Tokens are kept from week to week and are spent in
# Store > Event on the items below; each has a limit that comes back with the new week.
# Save "event_tokens": n. Save "event_shop": {"week": n, "bought": {id: times}}.
const SHOP := [
	{"id": "coins",    "name": "3,000 Coins",    "give": {"coins": 3000},     "cost": 25, "limit": 10, "icon": "ic_coin"},
	{"id": "key_u",    "name": "Uncommon Key",   "give": {"key_u": 1},        "cost": 30, "limit": 5,  "icon": "mat_key_u"},
	{"id": "cores",    "name": "2 Power Cores",  "give": {"core": 2},         "cost": 60, "limit": 3,  "icon": "ic_core"},
	{"id": "crystals", "name": "40 Crystals",    "give": {"crystals": 40},    "cost": 70, "limit": 2,  "icon": "ic_crystal"},
	{"id": "shards",   "name": "10 Hero Shards", "give": {"shards_duty": 10}, "cost": 80, "limit": 3,  "icon": "mat_shard"},
	{"id": "key_e",    "name": "Epic Key",       "give": {"key_e": 1},        "cost": 90, "limit": 2,  "icon": "mat_key_e"},
]

static func tokens(save: Dictionary) -> int:
	return maxi(int(save.get("event_tokens", 0)), 0)

static func shop_bought(save: Dictionary, id: String) -> int:
	var s = save.get("event_shop", {})
	if typeof(s) != TYPE_DICTIONARY or int(s.get("week", -1)) != week():
		return 0
	var b = s.get("bought", {})
	return int(b.get(id, 0)) if typeof(b) == TYPE_DICTIONARY else 0

static func shop_item(id: String) -> Dictionary:
	for it in SHOP:
		if String(it.id) == id:
			return it
	return {}

static func shop_why_not(save: Dictionary, id: String) -> String:
	var it := shop_item(id)
	if it.is_empty():
		return "Not in the event store"
	if not open(save):
		return "Opens after stage %d" % EVENT_FROM
	if shop_bought(save, id) >= int(it.limit):
		return "Back next week"
	if not DevTools.on and tokens(save) < int(it.cost):
		return "%d tokens needed" % int(it.cost)
	return ""

# trade tokens for an item; "" on success
static func shop_buy(save: Dictionary, id: String) -> String:
	var why := shop_why_not(save, id)
	if why != "":
		return why
	var it := shop_item(id)
	if not DevTools.on:
		save["event_tokens"] = tokens(save) - int(it.cost)
	var give: Dictionary = Dictionary(it.give).duplicate()
	if give.has("shards_duty"):
		give["shards"] = {String(Heroes.read(save).selected): int(give.shards_duty)}
		give.erase("shards_duty")
	Progress.grant(save, give)
	var n := shop_bought(save, id) + 1
	var s = save.get("event_shop", {})
	var b: Dictionary = {}
	if typeof(s) == TYPE_DICTIONARY and int(s.get("week", -1)) == week() and typeof(s.get("bought", {})) == TYPE_DICTIONARY:
		b = s.bought
	b[id] = n
	save["event_shop"] = {"week": week(), "bought": b}
	return ""
