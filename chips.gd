class_name Chips
# WEAPON CHIPS (Rudy 2026-11-16): power-ups you EMBED into a weapon. They REPLACE the level
# milestones: levelling a weapon gives plain numbers, and at Lv.10 / 20 / 30 it opens a chip slot.
# What used to arrive by itself at those levels is now a chip of that weapon:
#   "shape2" / "shape3" = its two evolved shapes (WeaponSteps.form), earned at Lv.10 / 20, Epic,
#   "cap"               = its capstone by element (WeaponSteps.CAPSTONE), earned at Lv.30, Legendary,
#   "special"           = the hero's Specialty weapon (Arsenal.SPECIALS), Mythic, earned by mastery.
# Those four belong to their weapon / hero. The GENERAL chips (CHIPS) are bought once with coins and
# fit any weapon of any hero; each is an "every Nth shot" trigger, N scaled by the class (RATE) so a
# fast stream and a slow cannon trigger about as often. Each has a RARITY: rarer = stronger, dearer
# and behind a later stage. One of each per weapon; the two shapes never together.
# A weapon nobody has touched wears its own chips by default (fitted), so nothing is lost.
# Chips are chosen BEFORE a fight; power cards are picked DURING one.
# Save: "chips" {owned: [ids], fit: {"<hero>:<class>": [id x3]}}.

const SLOT_LEVELS := [10, 20, 30]
const RATE := {"sidearm": 1.0, "twin": 1.0, "main": 3.0, "heavy": 0.4}
const SPECIAL := "special"
const OWN := ["shape2", "shape3", "cap"]          # the weapon's own chips
const OWN_LEVEL := {"shape2": 10, "shape3": 20, "cap": 30}

const RARITIES := ["common", "uncommon", "epic", "legendary", "mythic"]
const RARITY := {
	"common": {"name": "Common", "col": Color(0.72, 0.78, 0.86), "cost": 800, "stage": 0},
	"uncommon": {"name": "Uncommon", "col": Color(0.45, 0.9, 0.5), "cost": 2500, "stage": 8},
	"epic": {"name": "Epic", "col": Color(0.72, 0.5, 1.0), "cost": 7000, "stage": 20},
	"legendary": {"name": "Legendary", "col": Color(1.0, 0.78, 0.27), "cost": 18000, "stage": 35},
	"mythic": {"name": "Mythic", "col": Color(1.0, 0.33, 0.33), "cost": 45000, "stage": 50},
}

const ORDER := ["frag", "drill", "cryo", "fire", "sure", "arc", "guard", "bounty", "split", "leech", "mark", "over", "stun", "reaper"]
const CHIPS := {
	"frag": {"name": "Frag", "rarity": "common", "every": 8, "icon": "chip_frag", "text": "bursts and hurts the bugs around it"},
	"drill": {"name": "Drill", "rarity": "common", "every": 6, "icon": "chip_drill", "text": "flies on through every bug in its way"},
	"cryo": {"name": "Cryo", "rarity": "common", "every": 8, "icon": "chip_cryo", "text": "slows the bug it hits"},
	"fire": {"name": "Incendiary", "rarity": "common", "every": 8, "icon": "chip_fire", "text": "sets the bug it hits burning"},
	"sure": {"name": "Sure Shot", "rarity": "uncommon", "every": 10, "icon": "chip_sure", "text": "is a sure critical hit"},
	"arc": {"name": "Arc", "rarity": "uncommon", "every": 10, "icon": "chip_arc", "text": "jumps on to a second bug"},
	"guard": {"name": "Guard", "rarity": "uncommon", "every": 20, "icon": "chip_guard", "text": "mends a little of the base shield"},
	"bounty": {"name": "Bounty", "rarity": "uncommon", "every": 25, "icon": "chip_bounty", "text": "knocks coins out of the bug it hits"},
	"split": {"name": "Splitter", "rarity": "epic", "every": 9, "icon": "chip_split", "text": "brings two smaller shots beside it"},
	"leech": {"name": "Leech", "rarity": "epic", "every": 15, "icon": "chip_leech", "text": "gives the hero 1% of his health back"},
	"mark": {"name": "Tracer", "rarity": "epic", "every": 12, "icon": "chip_mark", "text": "marks the bug: every hit on it crits for a moment"},
	"over": {"name": "Overload", "rarity": "legendary", "every": 12, "icon": "chip_over", "text": "hits two and a half times as hard"},
	"stun": {"name": "Shock", "rarity": "legendary", "every": 14, "icon": "chip_stun", "text": "stops the bug dead for a moment"},
	"reaper": {"name": "Reaper", "rarity": "mythic", "every": 20, "icon": "chip_reaper", "text": "finishes a bug that is under a third of its health (not a boss)"},
}

static func def(id: String) -> Dictionary:
	return CHIPS.get(id, {})

static func rarity_of(id: String) -> String:
	if id == SPECIAL:
		return "mythic"
	if id == "cap":
		return "legendary"
	if id == "shape2" or id == "shape3":
		return "epic"
	return String(def(id).get("rarity", "common"))

static func color(id: String) -> Color:
	return RARITY[rarity_of(id)].col

static func cost(id: String) -> int:
	return int(RARITY[rarity_of(id)].cost)

# how many slots a weapon of this level has open
static func slots(level: int) -> int:
	var n := 0
	for l in SLOT_LEVELS:
		if level >= int(l):
			n += 1
	return n

static func _special_ok(save: Dictionary, hid: String) -> bool:
	return Arsenal.special_earned(save, hid) or bool(save.get("special_test", false))

static func read(save: Dictionary) -> Dictionary:
	var out := {"owned": [], "fit": {}}
	var raw = save.get("chips", null)
	if raw is Dictionary:
		var ow = raw.get("owned", [])
		if ow is Array:
			for id in ow:
				if CHIPS.has(String(id)) and not out.owned.has(String(id)):
					out.owned.append(String(id))
		var ft = raw.get("fit", {})
		if ft is Dictionary:
			for k in ft:
				var row: Array = ["", "", ""]
				if ft[k] is Array:
					for i in mini(ft[k].size(), 3):
						var id := String(ft[k][i])
						if id == SPECIAL or OWN.has(id) or out.owned.has(id):
							row[i] = id
				out.fit[String(k)] = row
	return out

static func owned(save: Dictionary, id: String) -> bool:
	return read(save).owned.has(id) or DevTools.on

# what a weapon wears before anyone has touched its slots: its own chips, newest shape first
static func defaults(level: int) -> Array:
	var out: Array = ["", "", ""]
	if level >= 20:
		out[0] = "shape3"
	elif level >= 10:
		out[0] = "shape2"
	if level >= 30:
		out[1] = "cap"
	return out

# the three slots of one weapon ("" = empty); a slot the level has not opened reads empty
static func fitted(save: Dictionary, hid: String, cls: String, level: int) -> Array:
	var c := read(save)
	var k := Arsenal.key(hid, cls)
	var row: Array = c.fit[k] if c.fit.has(k) else defaults(level)
	var out: Array = ["", "", ""]
	for i in mini(slots(level), 3):
		var id := String(row[i])
		if id == SPECIAL and not _special_ok(save, hid):
			id = ""
		if OWN.has(id) and level < int(OWN_LEVEL[id]):
			id = ""
		out[i] = id
	return out

# N for this chip on this class of weapon
static func every(id: String, cls: String) -> int:
	return maxi(2, int(round(float(def(id).get("every", 10)) * float(RATE.get(cls, 1.0)))))

static func nth(n: int) -> String:
	if n % 100 >= 11 and n % 100 <= 13:
		return "%dth" % n
	match n % 10:
		1: return "%dst" % n
		2: return "%dnd" % n
		3: return "%drd" % n
	return "%dth" % n

# an own chip's {name, text} comes from the weapon ITEM and the hero's element
static func _own_info(id: String, hid: String, item: String) -> Dictionary:
	var el := Heroes.element_of(hid)
	if id == "cap":
		return WeaponSteps.step(item, el, WeaponSteps.LEVELS.size() - 1)
	return WeaponSteps.form(item, el, 2 if id == "shape2" else 3)

static func chip_name(id: String, hid: String, item: String) -> String:
	if id == SPECIAL:
		return String(Arsenal.special(hid).get("name", "Specialty"))
	if OWN.has(id):
		return String(_own_info(id, hid, item).get("name", ""))
	return String(def(id).get("name", ""))

static func text(id: String, hid: String, item: String) -> String:
	if id == SPECIAL:
		var sp: Dictionary = Arsenal.special(hid)
		return "%s. Fires by itself every %d s." % [String(sp.get("text", "")), int(sp.get("cd", 9))]
	if OWN.has(id):
		return String(_own_info(id, hid, item).get("text", "")) + "."
	return "Every %s shot %s." % [nth(every(id, GearData.weapon_class(item))), String(def(id).get("text", ""))]

# every chip that may be offered for this weapon, own ones first
static func offered(save: Dictionary, hid: String, item: String) -> Array:
	var out: Array = []
	if _special_ok(save, hid):
		out.append(SPECIAL)
	for id in ["cap", "shape3", "shape2"]:
		if not _own_info(id, hid, item).is_empty():
			out.append(id)
	out.append_array(ORDER)
	return out

static func why_not_buy(save: Dictionary, id: String) -> String:
	if not CHIPS.has(id):
		return "Not for sale"
	if read(save).owned.has(id):
		return "Owned"
	if DevTools.on:
		return ""
	var r: Dictionary = RARITY[rarity_of(id)]
	if int(save.get("stage_unlocked", 1)) <= int(r.stage):
		return "Clear stage %d" % int(r.stage)
	if int(save.get("coins", 0)) < int(r.cost):
		return "%d coins" % int(r.cost)
	return ""

static func buy(save: Dictionary, id: String) -> bool:
	if why_not_buy(save, id) != "":
		return false
	var c := read(save)
	if not DevTools.on:
		save["coins"] = int(save.get("coins", 0)) - cost(id)
	c.owned.append(id)
	save["chips"] = c
	return true

# do you have this chip for this weapon ("" = yes)
static func why_not_have(save: Dictionary, hid: String, level: int, id: String) -> String:
	if id == SPECIAL:
		return "" if _special_ok(save, hid) else "All four weapons at mastery step %d" % Arsenal.SPECIAL_STEP
	if OWN.has(id):
		return "" if level >= int(OWN_LEVEL[id]) else "Weapon Lv.%d" % int(OWN_LEVEL[id])
	return "" if owned(save, id) else "Not bought"

# "" when this chip may go into that slot of that weapon
static func why_not_fit(save: Dictionary, hid: String, cls: String, level: int, slot: int, id: String) -> String:
	if slot < 0 or slot >= SLOT_LEVELS.size():
		return "No such slot"
	if slot >= slots(level):
		return "Weapon Lv.%d" % int(SLOT_LEVELS[slot])
	if id == "":
		return ""
	var have := why_not_have(save, hid, level, id)
	if have != "":
		return have
	var row: Array = fitted(save, hid, cls, level)
	for i in row.size():
		if i == slot:
			continue
		if String(row[i]) == id:
			return "Already in this weapon"
		if (id == "shape2" or id == "shape3") and (String(row[i]) == "shape2" or String(row[i]) == "shape3"):
			return "One shape at a time"
	return ""

# put a chip into a slot ("" takes it out)
static func fit(save: Dictionary, hid: String, cls: String, level: int, slot: int, id: String) -> bool:
	if why_not_fit(save, hid, cls, level, slot, id) != "":
		return false
	var c := read(save)
	var row: Array = fitted(save, hid, cls, level)
	row[slot] = id
	c.fit[Arsenal.key(hid, cls)] = row
	save["chips"] = c
	return true

# what the fight needs: the general chips [{id, every}], the weapon's shape (1-3), whether its
# capstone is in, and whether the Specialty sits in a slot
static func live(save: Dictionary, hid: String, cls: String, level: int) -> Dictionary:
	var out := {"chips": [], "special": false, "form": 1, "cap": false}
	for id in fitted(save, hid, cls, level):
		match String(id):
			"":
				pass
			SPECIAL:
				out.special = true
			"shape2":
				out.form = maxi(int(out.form), 2)
			"shape3":
				out.form = 3
			"cap":
				out.cap = true
			_:
				out.chips.append({"id": String(id), "every": every(String(id), cls)})
	return out

# the SHAPE a chip is drawn in says what kind it is: hex = the weapon's own (and the Specialty),
# tri = it hits harder, dia = it changes where the shot goes, circ = a status or a helper
const SHAPE := {"sure": "tri", "over": "tri", "reaper": "tri", "frag": "tri", "mark": "tri",
	"drill": "dia", "split": "dia", "arc": "dia",
	"cryo": "circ", "fire": "circ", "stun": "circ", "leech": "circ", "guard": "circ", "bounty": "circ"}
static func shape(id: String) -> String:
	return String(SHAPE.get(id, "hex"))
