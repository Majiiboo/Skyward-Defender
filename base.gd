class_name Base
extends RefCounted
# THE BASE YOU BUILD (Rudy, 2026-11-10: "scrap the turrets ... build a new home base ... different
# buildings that give power-ups, choosing four of them ... they have their own level"). It takes the
# turrets' place. The base never shoots: it is purely DEFENSIVE AND SUPPORTIVE. Each building gives
# one kind of help (the base's defence, repair, the hero's health or punch, his ability, the drone,
# warnings, coins), has its own level, and stands on one of the four slots, so which four you field
# is the decision. Slots open with the campaign like the mounts did (Turrets.MOUNT_OPENS_AFTER).
# Save "base": {"slots": [id x4], "levels": {id: n}}; a building you own has a level >= 1.
# Turret art is NOT used (Rudy: scrap it); a building shows an icon until the new base is painted.
# The first time a save meets the base, what was spent on turrets comes back as coins (migrate).

const SLOTS := 4
const MAX_LEVEL := 10
# "from" = the stage that must be cleared before it can be built; "cost" = coins to build it;
# "per" = what one level gives; "text" = the line shown, with %s for the number at that level
const BUILDINGS := {
	"shield_gen": {"name": "Shield Generator", "icon": "st_def", "col": Color(0.31, 0.88, 1.0), "from": 5, "cost": 0,
		"stat": "shield", "per": 0.08, "text": "Base shield +%d%%", "kind": "Defence"},
	"repair_bay": {"name": "Repair Bay", "icon": "ic_cell", "col": Color(0.44, 0.94, 0.72), "from": 5, "cost": 800,
		"stat": "repair", "per": 0.015, "text": "Mends %s%% of the shield and hull after every wave", "kind": "Repair"},
	"armory":     {"name": "Armory", "icon": "st_atk", "col": Color(1.0, 0.6, 0.3), "from": 8, "cost": 1500,
		"stat": "damage", "per": 0.03, "text": "Hero damage +%d%%", "kind": "Attack"},
	"medbay":     {"name": "Med Bay", "icon": "st_hp", "col": Color(1.0, 0.45, 0.5), "from": 10, "cost": 2000,
		"stat": "hp", "per": 0.05, "text": "Hero health +%d%%, and he heals a little after every wave", "kind": "Hero"},
	"plating":    {"name": "Hull Plating", "icon": "ic_base", "col": Color(0.75, 0.8, 0.9), "from": 12, "cost": 2500,
		"stat": "hull", "per": 0.08, "text": "Base hull +%d%%, hits on the base hurt less", "kind": "Defence"},
	"hangar":     {"name": "Hangar", "icon": "tab_drone", "col": Color(0.71, 0.55, 1.0), "from": 14, "cost": 3000,
		"stat": "drone", "per": 0.10, "text": "Drone damage +%d%%", "kind": "Helpers"},
	"reactor":    {"name": "Reactor", "icon": "ic_energy", "col": Color(1.0, 0.85, 0.4), "from": 16, "cost": 4000,
		"stat": "ability", "per": 0.04, "text": "The hero's ability charges %d%% faster", "kind": "Ability"},
	"radar":      {"name": "Radar", "icon": "st_aim", "col": Color(0.5, 1.0, 0.78), "from": 20, "cost": 5000,
		"stat": "warn", "per": 0.08, "text": "Runner lanes and hazards warn %d%% earlier", "kind": "Warning"},
	"refinery":   {"name": "Refinery", "icon": "ic_coin", "col": Color(1.0, 0.78, 0.27), "from": 25, "cost": 6000,
		"stat": "coins", "per": 0.04, "text": "Coins from fights +%d%%", "kind": "Economy"},
}
const ORDER := ["shield_gen", "repair_bay", "armory", "medbay", "plating", "hangar", "reactor", "radar", "refinery"]

static func read(save: Dictionary) -> Dictionary:
	var b = save.get("base", null)
	if typeof(b) != TYPE_DICTIONARY:
		return {"slots": ["shield_gen", "", "", ""], "levels": {"shield_gen": 1}}   # everyone starts with the generator
	var out := {"slots": ["", "", "", ""], "levels": {}}
	var lv = b.get("levels", {})
	if typeof(lv) == TYPE_DICTIONARY:
		for id in lv:
			if BUILDINGS.has(id):
				out.levels[id] = clampi(int(lv[id]), 1, MAX_LEVEL)
	var sl = b.get("slots", [])
	if typeof(sl) == TYPE_ARRAY:
		for i in mini(sl.size(), SLOTS):
			var id := String(sl[i])
			if out.levels.has(id) and not out.slots.has(id):
				out.slots[i] = id
	return out

static func write(b: Dictionary) -> Dictionary:
	return {"slots": b.slots, "levels": b.levels}

static func owned(b: Dictionary, id: String) -> bool:
	return b.levels.has(id) or DevTools.on

static func level(b: Dictionary, id: String) -> int:
	return clampi(int(b.levels.get(id, 1 if DevTools.on else 0)), 0, MAX_LEVEL)

static func slot_open(i: int, stage_unlocked: int) -> bool:
	return Turrets.mount_open(i, stage_unlocked)

static func can_build(save: Dictionary, id: String) -> bool:
	return DevTools.on or int(save.get("stage_unlocked", 1)) > int(BUILDINGS[id].from)

static func build_cost(id: String) -> int:
	return int(BUILDINGS[id].cost)

# coins for the next level (level 1 -> 2 costs level_cost(1))
static func level_cost(lv: int) -> int:
	return 150 * lv * (lv + 1) / 2 + 100

static func level_parts(lv: int) -> Dictionary:
	return Parts.need(lv)

# what `lv` levels of a building give, as the number its text shows
static func amount(id: String, lv: int) -> float:
	return float(BUILDINGS[id].per) * lv

static func text(id: String, lv: int) -> String:
	var a := amount(id, lv) * 100.0
	var t := String(BUILDINGS[id].text)
	return t % (("%.1f" % a) if t.contains("%s") else roundi(a))

# build it (coins); "" on success or why not
static func build(save: Dictionary, b: Dictionary, id: String) -> String:
	if not BUILDINGS.has(id):
		return "No such building"
	if owned(b, id) and not DevTools.on:
		return "Already built"
	if not can_build(save, id):
		return "Clear stage %d first" % int(BUILDINGS[id].from)
	if not DevTools.on:
		if int(save.get("coins", 0)) < build_cost(id):
			return "%s coins needed" % UIKit.num(build_cost(id))
		save["coins"] = int(save.get("coins", 0)) - build_cost(id)
	b.levels[id] = maxi(int(b.levels.get(id, 0)), 1)
	return ""

static func why_not_level(save: Dictionary, b: Dictionary, id: String) -> String:
	var lv := level(b, id)
	if lv <= 0:
		return "Build it first"
	if lv >= MAX_LEVEL:
		return "Max level"
	if DevTools.on:
		return ""
	if int(save.get("coins", 0)) < level_cost(lv):
		return "%s coins needed" % UIKit.num(level_cost(lv))
	if not Parts.has_all(Parts.read(save), level_parts(lv)):
		return "Short of %s" % Parts.text(level_parts(lv))
	return ""

static func level_up(save: Dictionary, b: Dictionary, id: String) -> String:
	var why := why_not_level(save, b, id)
	if why != "":
		return why
	var lv := level(b, id)
	if not DevTools.on:
		var paid := Parts.pay(save, level_cost(lv), level_parts(lv), false)
		if paid != "":
			return paid
	b.levels[id] = lv + 1
	return ""

# put a building on a slot (it leaves the slot it was on); "" takes it off
static func place(b: Dictionary, slot: int, id: String) -> void:
	if slot < 0 or slot >= SLOTS:
		return
	if id != "":
		var old: int = b.slots.find(id)
		if old >= 0:
			b.slots[old] = ""
	b.slots[slot] = id

# the bonuses the buildings ON OPEN SLOTS give this fight
static func stats(save: Dictionary) -> Dictionary:
	var st := {"shield": 0.0, "repair": 0.0, "damage": 0.0, "hp": 0.0, "hull": 0.0, "drone": 0.0, "ability": 0.0, "warn": 0.0, "coins": 0.0, "on": []}
	var b := read(save)
	var su := int(save.get("stage_unlocked", 1))
	for i in SLOTS:
		var id := String(b.slots[i])
		if id == "" or not (slot_open(i, su) or DevTools.on):
			continue
		st[String(BUILDINGS[id].stat)] = float(st[String(BUILDINGS[id].stat)]) + amount(id, level(b, id))
		st.on.append(id)
	return st

# the first time a save meets the base: every coin spent on turrets (buying them and their tracks)
# comes back, so nothing put into the old system is lost. Returns the coins refunded (0 = done before).
static func migrate(save: Dictionary) -> int:
	if save.has("base") or bool(save.get("turrets_refunded", false)):
		return 0
	save["turrets_refunded"] = true
	var t := Turrets.read(save)
	var back := 0
	for id in Turrets.TURRETS:
		if not Turrets.owned(t, id):
			continue
		back += int(Dictionary(Turrets.TURRETS[id].get("cost", {})).get("coins", 0))
		var tr := Turrets.one_tracks(t.get("tracks", {}), id)
		for k in Turrets.TRACKS:
			for l in range(1, int(tr[k])):
				back += Turrets.track_cost(l)
	save["coins"] = int(save.get("coins", 0)) + back
	save["base"] = write(read(save))
	return back

# LEVEL 5 PERKS (2026-11-10): at PERK_LEVEL every building gains one thing that changes a fight,
# not only a bigger number, so a level is worth chasing and "which four" is a sharper choice.
const PERK_LEVEL := 5
const PERKS := {
	"shield_gen": "Emergency shield: once a fight, a broken shield comes back at 30%",
	"repair_bay": "Repairs are doubled while the hull is below half",
	"armory":     "Crit rate +5%",
	"medbay":     "Second wind: once a fight, a blow that would down the hero leaves him standing",
	"plating":    "Runners that get through do half damage",
	"hangar":     "Your gun drone hits 20% harder",
	"reactor":    "Every fight starts with the ability ready",
	"radar":      "A caught runner pays double",
	"refinery":   "2 more Alloy for every stage cleared",
}

static func perk_text(id: String) -> String:
	return String(PERKS.get(id, ""))

static func has_perk(b: Dictionary, id: String) -> bool:
	return level(b, id) >= PERK_LEVEL

# the perks in force this fight: buildings at PERK_LEVEL standing on open slots
static func perks(save: Dictionary) -> Array:
	var out: Array = []
	var b := read(save)
	for id in stats(save).on:
		if has_perk(b, String(id)):
			out.append(String(id))
	return out

# LINKS (2026-11-10): two buildings that work together. Field both (on open slots, any two) and
# the link is live: one more bonus on top of what each gives alone. Every building has at least
# one partner, so "which four" is also "which pairs". The fight draws a gold line between linked pods.
const LINKS := {
	"bulwark":    {"a": "shield_gen", "b": "plating",  "name": "Bulwark",        "text": "Hits on the base are 10% weaker"},
	"hospital":   {"a": "repair_bay", "b": "medbay",   "name": "Field Hospital", "text": "Mending after a wave is 50% stronger, base and hero"},
	"war_room":   {"a": "armory",     "b": "radar",    "name": "War Room",       "text": "Crit rate +4%"},
	"arsenal":    {"a": "armory",     "b": "hangar",   "name": "Arsenal",        "text": "Hero damage +5%"},
	"drone_bay":  {"a": "hangar",     "b": "reactor",  "name": "Drone Bay",      "text": "Drone damage +20%"},
	"capacitor":  {"a": "reactor",    "b": "shield_gen", "name": "Capacitor",    "text": "The Core Pulse recharges 25% faster"},
	"prospector": {"a": "refinery",   "b": "radar",    "name": "Prospector",     "text": "Coins from fights +10%"},
}
const LINK_ORDER := ["bulwark", "hospital", "war_room", "arsenal", "drone_bay", "capacitor", "prospector"]

# the links live this fight: both buildings standing on open slots
static func links(save: Dictionary) -> Array:
	var on: Array = stats(save).on
	var out: Array = []
	for l in LINK_ORDER:
		if on.has(String(LINKS[l].a)) and on.has(String(LINKS[l].b)):
			out.append(l)
	return out

# the links a building can form: [{"id", "with", "name", "text"}]
static func links_of(id: String) -> Array:
	var out: Array = []
	for l in LINK_ORDER:
		var d: Dictionary = LINKS[l]
		if String(d.a) == id or String(d.b) == id:
			out.append({"id": l, "with": String(d.b) if String(d.a) == id else String(d.a), "name": String(d.name), "text": String(d.text)})
	return out

# a building's picture: Luna's render (base/bld_<id>.png, tools/cut_base2.gd), else its icon
static var _pics := {}
static func pic(id: String) -> Texture2D:
	if not _pics.has(id):
		var p := "res://base/bld_%s.png" % id
		_pics[id] = load(p) if ResourceLoader.exists(p) else UIKit.ic(String(BUILDINGS[id].icon))
	return _pics[id]
