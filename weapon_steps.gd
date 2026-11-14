class_name WeaponSteps
extends RefCounted
# WEAPON LEVEL MILESTONES (Rudy, 2026-11-14, weapons step 5). Every 5 levels a weapon earns a
# milestone that is ITS OWN, by class:
#   Lv.5, 15, 25 = small ones that sharpen what the class is good at
#   Lv.10, 20    = the two SHAPE changes (GearData.WEAPON_FORMS: they change how it fires)
#   Lv.30        = a CAPSTONE that comes from the hero's ELEMENT (CAPSTONE; PEAK until an
#                  element's own is designed: only frost has them so far)
# A weapon levels as far as its hero's rarity step allows (Arsenal.CAPS: Common 10 .. Legendary 30),
# so a Common hero only ever sees the first shape change and only Legendary and up the capstone.
# This replaced the same "Crit rate +3%" every 5 levels on every weapon.
# battle reads bonus(); the Weapons screen reads step() / count() / next_level().

const LEVELS := [5, 10, 15, 20, 25, 30]
# by class, the five before the capstone; {"form": n} = that shape of the weapon (name and text
# come from GearData.form_info, its changes are laid over the weapon by battle _weapon())
const STEPS := {
	"sidearm": [
		{"name": "Sharp sights", "text": "Crit chance +3%", "fx": {"crit": 0.03}},
		{"form": 2},
		{"name": "Kill shot", "text": "Crits hit 20% harder", "fx": {"crit_dmg": 0.2}},
		{"form": 3},
		{"name": "Overcharge", "text": "Charged shots hit once more as hard", "fx": {"charge_mult_add": 1.0}},
	],
	"twin": [
		{"name": "Fast hands", "text": "Fire rate +5%", "fx": {"rate": 0.05}},
		{"form": 2},
		{"name": "Faster hands", "text": "Fire rate +5%", "fx": {"rate": 0.05}},
		{"form": 3},
		{"name": "Heavy rounds", "text": "Attack +10%", "fx": {"atk": 0.1}},
	],
	"main": [
		{"name": "Long nozzle", "text": "Reaches 10% further", "fx": {"range_x": 1.1}},
		{"form": 2},
		{"name": "High pressure", "text": "Reaches another 10% further", "fx": {"range_x": 1.1}},
		{"form": 3},
		{"name": "Wide spray", "text": "A wider stream that is harder to slip past", "fx": {"stream_wide": 1.3}},
	],
	"heavy": [
		{"name": "Big charge", "text": "The blast reaches 10% further", "fx": {"splash_x": 1.1}},
		{"form": 2},
		{"name": "Quick loader", "text": "Fire rate +10%", "fx": {"rate": 0.1}},
		{"form": 3},
		{"name": "Packed shells", "text": "Attack +10%", "fx": {"atk": 0.1}},
	],
}
# the Lv.30 capstone, by the hero's element and the class
const CAPSTONE := {
	"frost": {
		"sidearm": {"name": "Shatter", "text": "A bug killed by a charged shot bursts into ice shards", "fx": {"shatter": 6}},
		"twin": {"name": "Blizzard", "text": "Every 10th volley is a fan of five", "fx": {"fan_every": 10, "fan": 5}},
		"main": {"name": "Frostbite", "text": "Bugs the stream has slowed take 25% more damage", "fx": {"chill_dmg": 0.25}},
		"heavy": {"name": "Ice field", "text": "The blast leaves a patch of ice that slows bugs for 3 seconds", "fx": {"patch": 3.0}},
	},
}
const PEAK := {"name": "Peak", "text": "Attack +12%", "fx": {"atk": 0.12}}   # an element with no capstone yet

static func count(lv: int) -> int:
	var n := 0
	for l in LEVELS:
		if lv >= int(l):
			n += 1
	return n

# the level of the next milestone (0 = all six reached)
static func next_level(lv: int) -> int:
	var n := count(lv)
	return int(LEVELS[n]) if n < LEVELS.size() else 0

# milestone i (0..5) of a weapon ITEM for a hero's element: {name, text, fx}
static func step(item: String, element: String, i: int) -> Dictionary:
	var cls := GearData.weapon_class(item)
	if not STEPS.has(cls) or i < 0 or i >= LEVELS.size():
		return {}
	if i == LEVELS.size() - 1:
		return Dictionary(CAPSTONE.get(element, {})).get(cls, PEAK)
	var row: Dictionary = STEPS[cls][i]
	if row.has("form"):
		var fi: Dictionary = GearData.form_info(item, int(row.form))
		return {"name": String(fi.get("name", "")), "text": String(fi.get("text", "")), "fx": {}, "form": int(row.form)}
	return row

# everything a weapon of class `cls` has earned at level `lv`, for a hero of `element`
static func bonus(cls: String, element: String, lv: int) -> Dictionary:
	var out := {"atk": 0.0, "rate": 0.0, "crit": 0.0, "crit_dmg": 0.0, "charge_mult_add": 0.0, "range_x": 1.0,
		"splash_x": 1.0, "stream_wide": 1.0, "shatter": 0, "fan_every": 0, "fan": 0, "chill_dmg": 0.0, "patch": 0.0}
	if not STEPS.has(cls):
		return out
	for i in count(lv):
		var row: Dictionary = Dictionary(CAPSTONE.get(element, {})).get(cls, PEAK) if i == LEVELS.size() - 1 else STEPS[cls][i]
		var fx: Dictionary = row.get("fx", {})
		for k in fx:
			if k == "range_x" or k == "splash_x" or k == "stream_wide":
				out[k] = float(out[k]) * float(fx[k])
			elif out[k] is int:
				out[k] = int(fx[k])
			else:
				out[k] = float(out[k]) + float(fx[k])
	return out
