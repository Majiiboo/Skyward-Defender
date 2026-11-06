class_name Materials
extends RefCounted
# Materials per domain (Rudy, DESIGN-materials.md, dev189). On top of the base PARTS (Alloy ->
# Cells -> Cores, parts.gd) each domain has its own line:
#   heroes   ESSENCE per element (Energy Spark, Arc Charge, Frost Core, Void Fragment, Dark
#            Ember, Solar Flare): hero tiers (evolutions) and the 3-star+ hero unlocks
#   weapons  Scrap Barrel -> Focus Lens -> Prime Coil: weapon levels from Lv.15 (+ an essence
#            of the weapon's element from Lv.25)
#   turrets  the turret's essence for track levels past 10
#   drones   Rotor -> Gyro -> Flight Core: drone levels from Lv.5
# Where they come from: boss stages and Elite wins pay the essence of that planet's weakness,
# an element trial step pays its own essence, Horde pays barrels and rotors, Patrol trickles
# both lines, and the Workshop CRAFT tab turns lower materials into higher ones (RECIPES).
# Save: "materials": {id: n}. Parts.read / pay / text know these ids, so every price that
# lists parts can list materials too.

const KINDS := {
	"ess_ion":       {"name": "Energy Spark",  "element": "ion",       "crystals": 20, "fb": "el_energy"},
	"ess_scavenger": {"name": "Arc Charge",    "element": "scavenger", "crystals": 20, "fb": "el_electric"},
	"ess_frost":     {"name": "Frost Core",    "element": "frost",     "crystals": 20, "fb": "el_ice"},
	"ess_void":      {"name": "Void Fragment", "element": "void",      "crystals": 20, "fb": "el_void"},
	"ess_nightmare": {"name": "Dark Ember",    "element": "nightmare", "crystals": 20, "fb": "el_dark"},
	"ess_solar":     {"name": "Solar Flare",   "element": "solar",     "crystals": 20, "fb": "el_fire"},
	"barrel":     {"name": "Scrap Barrel", "color": Color(0.8, 0.72, 0.55), "crystals": 6,  "fb": "ic_alloy"},
	"lens":       {"name": "Focus Lens",   "color": Color(0.6, 0.9, 1.0),   "crystals": 20, "fb": "ic_cell"},
	"coil":       {"name": "Prime Coil",   "color": Color(1.0, 0.75, 0.4),  "crystals": 60, "fb": "ic_core"},
	"rotor":      {"name": "Rotor",        "color": Color(0.7, 0.8, 0.9),   "crystals": 6,  "fb": "ic_alloy"},
	"gyro":       {"name": "Gyro",         "color": Color(0.5, 0.95, 0.8),  "crystals": 20, "fb": "ic_cell"},
	"flightcore": {"name": "Flight Core",  "color": Color(0.95, 0.8, 0.5),  "crystals": 60, "fb": "ic_core"},
}
const ORDER := ["ess_ion", "ess_scavenger", "ess_frost", "ess_void", "ess_nightmare", "ess_solar",
	"barrel", "lens", "coil", "rotor", "gyro", "flightcore"]
const LINES := {"weapon": ["barrel", "lens", "coil"], "drone": ["rotor", "gyro", "flightcore"]}

static func is_material(k: String) -> bool:
	return KINDS.has(k)

static func essence_of(element: String) -> String:
	return "ess_" + element if KINDS.has("ess_" + element) else "ess_ion"

static func name_of(k: String) -> String:
	return String(KINDS[k].name) if KINDS.has(k) else k

static func color_of(k: String) -> Color:
	if not KINDS.has(k):
		return Color.WHITE
	if KINDS[k].has("element"):
		return Heroes.element_color(String(KINDS[k].element))
	return KINDS[k].color

# Luna's icon when painted (icons/mat_<id>.png), else the element badge or the parts icon
static func icon(k: String) -> Texture2D:
	if not KINDS.has(k):
		return null
	var p := "res://icons/mat_%s.png" % k
	if ResourceLoader.exists(p):
		return load(p)
	return UIKit.ic(String(KINDS[k].fb))

static func read(save: Dictionary) -> Dictionary:
	var m = save.get("materials", {})
	var out := {}
	for k in ORDER:
		out[k] = int(m.get(k, 0)) if typeof(m) == TYPE_DICTIONARY else 0
	return out

static func add(save: Dictionary, k: String, n: int) -> void:
	if not KINDS.has(k) or n == 0:
		return
	var m := read(save)
	m[k] = maxi(0, int(m[k]) + n)
	save["materials"] = m

static func owned_any(save: Dictionary) -> bool:
	for v in read(save).values():
		if int(v) > 0:
			return true
	return false

# ------------------------------------------------------------------ what things cost
# a weapon level from `level` to level + 1 (on top of Parts.need): barrels from Lv.15, lenses
# from Lv.20, a coil and an essence of its element from Lv.25
static func weapon_need(level: int, element: String) -> Dictionary:
	var n := {}
	if level >= 15:
		n["barrel"] = 1 + (level - 15) / 3
	if level >= 20:
		n["lens"] = 1 + (level - 20) / 4
	if level >= 25:
		n["coil"] = 1 + (level - 25) / 5
		n[essence_of(element)] = 1
	return n

# a turret track level past 10: its element's essence, one more every three levels
static func turret_need(track_level: int, element: String) -> Dictionary:
	if track_level < 10:
		return {}
	return {essence_of(element): 1 + (track_level - 10) / 3}

# a drone level from `level`: rotors from Lv.5, gyros from Lv.10, a flight core from Lv.15
static func drone_need(level: int) -> Dictionary:
	var n := {}
	if level >= 5:
		n["rotor"] = 1 + (level - 5) / 3
	if level >= 10:
		n["gyro"] = 1 + (level - 10) / 4
	if level >= 15:
		n["flightcore"] = 1
	return n

# a hero's next tier (2 or 3): essences of his element on top of the shards
static func tier_need(element: String, next_tier: int) -> Dictionary:
	return {essence_of(element): 2 if next_tier <= 2 else 5}

# ------------------------------------------------------------------ the Workshop CRAFT tab
# "pick" = the player picks the element of the essence made
const RECIPES := [
	{"id": "barrel", "name": "Scrap Barrel", "makes": {"barrel": 1}, "needs": {"alloy": 10}, "coins": 200,
		"desc": "Weapon line, step 1. Weapon levels from Lv.15 need them."},
	{"id": "lens", "name": "Focus Lens", "makes": {"lens": 1}, "needs": {"barrel": 3}, "coins": 400,
		"desc": "Weapon line, step 2. From Lv.20."},
	{"id": "coil", "name": "Prime Coil", "makes": {"coil": 1}, "needs": {"lens": 3, "core": 1}, "coins": 800,
		"desc": "Weapon line, step 3. From Lv.25."},
	{"id": "rotor", "name": "Rotor", "makes": {"rotor": 1}, "needs": {"alloy": 10}, "coins": 200,
		"desc": "Drone line, step 1. Drone levels from Lv.5 need them."},
	{"id": "gyro", "name": "Gyro", "makes": {"gyro": 1}, "needs": {"rotor": 3}, "coins": 400,
		"desc": "Drone line, step 2. From Lv.10."},
	{"id": "flightcore", "name": "Flight Core", "makes": {"flightcore": 1}, "needs": {"gyro": 3, "core": 1}, "coins": 800,
		"desc": "Drone line, step 3. From Lv.15."},
	{"id": "essence", "name": "Essence", "makes": {"ess_ion": 1}, "needs": {"cell": 10, "core": 2}, "coins": 1000, "pick": true,
		"desc": "One essence of the element you pick. Hero tiers, 3-star heroes, high weapon and turret levels."},
]

static func recipe(id: String) -> Dictionary:
	for r in RECIPES:
		if String(r.id) == id:
			return r
	return {}

# what recipe `r` makes, for element `el` when it is an essence pick
static func makes(r: Dictionary, el: String = "ion") -> Dictionary:
	if r.get("pick", false):
		return {essence_of(el): int(r.makes.values()[0])}
	return r.makes

static func can_craft(save: Dictionary, r: Dictionary) -> bool:
	if DevTools.on:
		return true
	return int(save.get("coins", 0)) >= int(r.get("coins", 0)) and Parts.has_all(Parts.read(save), r.needs)

# Craft one. Changes `save` in place; returns "" on success or why it failed.
static func craft(save: Dictionary, r: Dictionary, el: String = "ion") -> String:
	if r.is_empty():
		return "No such recipe"
	var why := Parts.pay(save, int(r.get("coins", 0)), r.needs, false)
	if why != "":
		return why
	for k in makes(r, el):
		add(save, k, int(makes(r, el)[k]))
	return ""

# ------------------------------------------------------------------ drops
# what a won stage pays: a boss stage (every 5th) or an Elite win drops the essence of the
# element that planet is weak to (so you farm an essence where its hero shines); Elite and
# the later planets trickle the two lines
static func stage_drop(stage: int, elite: bool, rng: RandomNumberGenerator) -> Dictionary:
	var out := {}
	var ess := essence_of(String(Heroes.family(stage).weak))
	if stage % 5 == 0:
		out[ess] = 1 + (1 if elite else 0)
	elif elite and rng.randf() < 0.35:
		out[ess] = 1
	if stage >= 11 and rng.randf() < (0.25 if elite else 0.12):
		out["barrel"] = 1
	if stage >= 16 and rng.randf() < (0.25 if elite else 0.12):
		out["rotor"] = 1
	return out

# Horde: a barrel and a rotor for every 10 waves survived
static func horde_drop(waves: int) -> Dictionary:
	return {"barrel": waves / 10, "rotor": waves / 10} if waves >= 10 else {}
