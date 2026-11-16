class_name Arsenal
extends RefCounted
# EVERY HERO HAS HIS OWN WEAPONS (Rudy, 2026-11-13). A hero's weapons are separate items: his own
# level, his own mastery, unlocked one by one. Nothing is shared between heroes.
# - Each hero has the FOUR classes in one order (ORDER: the pistol comes with him) plus a fifth
#   SPECIALTY slot that stays locked until we add his unique weapon.
# - The others open at a HERO LEVEL (OPEN_LEVEL) and then cost coins (OPEN_COST).
# - A weapon levels as far as its hero's rarity step allows (CAPS: Common 10 .. Legendary and up 30).
#   Weapon copies and Workshop merging are gone; drops that used to be a copy pay coins
#   (GearData.drop_coins).
# - Mastery (mastery.gd) is counted per weapon: key = "<hero>:<class>".
# save "arsenal" = {hero: {"equipped": class, "owned": [class], "levels": {class: n}}}
#
# The rest of the game still reads GearData.read(save): its "Weapon" slot, levels and rarity are a
# VIEW of the arsenal of the hero on duty (class -> GearData.CLASS_ITEM), so battle, the rig and
# the sims did not have to change. Never call Heroes.read from here (Heroes.read -> migrate ->
# GearData.read -> here): the raw_ readers take what they need straight from the save.

# Rudy 2026-11-14: EVERY hero has the same four classes in the same order: the pistol he comes
# with, then twin pistols, the rifle, the cannon. What differs per hero is the look, the name and
# what it fires (his element). The SPECIALTY slot (a unique weapon, not in the game yet) is
# earned: all four of his weapons at mastery step SPECIAL_STEP.
const ORDER := ["sidearm", "twin", "main", "heavy"]
const SETS := {"rook": ORDER, "sparks": ORDER, "frost": ORDER, "hollow": ORDER, "nyx": ORDER, "ember": ORDER}
const OPEN_LEVEL := [1, 5, 10, 15]          # the hero level that opens his 1st .. 4th weapon
const OPEN_COST := [0, 2000, 5000, 10000]   # and its price in coins
const SPECIAL_STEP := 3                     # mastery step on all four that earns the Specialty slot
const CAPS := [10, 15, 20, 25, 30]    # weapon level cap by the hero's step (5 and up = 30)
const SPECIALTY := "Specialty"

static func classes(hid: String) -> Array:
	return SETS.get(hid, SETS["rook"])

static func first(hid: String) -> String:
	return String(classes(hid)[0])

static func raw_selected(save: Dictionary) -> String:
	var h = save.get("hero", {})
	var id := String(h.get("selected", "rook")) if h is Dictionary else "rook"
	return id if SETS.has(id) else "rook"

static func _raw_int(save: Dictionary, block: String, hid: String, fallback: int) -> int:
	var h = save.get("hero", {})
	if not (h is Dictionary):
		return fallback
	var b = h.get(block, {})
	return int(b.get(hid, fallback)) if b is Dictionary else fallback

# the hero's step, 1..10 (the same sum as Heroes.tier)
static func raw_star(save: Dictionary, hid: String) -> int:
	var grade := int(Heroes.ROSTER[hid].get("grade", 1)) if Heroes.ROSTER.has(hid) else 1
	return clampi(maxi(_raw_int(save, "tiers", hid, 1), 1) + grade - 1, 1, 10)

static func raw_level(save: Dictionary, hid: String) -> int:
	return maxi(_raw_int(save, "levels", hid, 1), 1)

static func cap(save: Dictionary, hid: String) -> int:
	return int(CAPS[clampi(raw_star(save, hid), 1, CAPS.size()) - 1])

# the rarity word that carries the same cap in GearData (the view)
static func rarity_for(save: Dictionary, hid: String) -> String:
	return String(GearData.RARITIES[clampi(raw_star(save, hid), 1, GearData.RARITIES.size()) - 1])

# ------------------------------------------------------------------ read / write
static func read(save: Dictionary) -> Dictionary:
	var raw = save.get("arsenal", null)
	var old := _old(save) if not (raw is Dictionary) else {}
	var out := {}
	for hid in SETS:
		var set_: Array = SETS[hid]
		var row := {"equipped": String(set_[0]), "owned": [String(set_[0])], "levels": {}}
		if raw is Dictionary:
			var r = raw.get(hid, {})
			if r is Dictionary:
				var ow = r.get("owned", [])
				if ow is Array:
					for c in ow:
						if set_.has(String(c)) and not row.owned.has(String(c)):
							row.owned.append(String(c))
				var lv = r.get("levels", {})
				if lv is Dictionary:
					for c in lv:
						if set_.has(String(c)):
							row.levels[String(c)] = clampi(int(lv[c]), 1, GearData.MAX_LEVEL)
				var e := String(r.get("equipped", ""))
				if row.owned.has(e):
					row.equipped = e
		else:   # a save from before the arsenal: what the shared weapons were, for every hero
			for c in set_:
				if old.owned.has(c) and not row.owned.has(c):
					row.owned.append(c)
				if old.levels.has(c):
					row.levels[c] = int(old.levels[c])
			if row.owned.has(String(old.equipped)):
				row.equipped = String(old.equipped)
		out[hid] = row
	return out

static func write(save: Dictionary, a: Dictionary) -> void:
	save["arsenal"] = a

# what the old shared weapons were: {owned [class], levels {class: n}, equipped class, spare_coins}
static func _old(save: Dictionary) -> Dictionary:
	var out := {"owned": [], "levels": {}, "equipped": "", "spare_coins": 0}
	var g = save.get("gear", {})
	if not (g is Dictionary):
		return out
	var levels = g.get("levels", {})
	var copies = g.get("copies", {})
	var eq = g.get("equipped", {})
	var unlocked := int(save.get("stage_unlocked", 1))
	for id in GearData.ITEMS:
		if String(GearData.ITEMS[id].slot) != "Weapon":
			continue
		var cls := GearData.weapon_class(id)
		var had: bool = (copies is Dictionary and copies.has(id)) or GearData.set_unlocked(String(GearData.ITEMS[id].set), unlocked)
		if had and not out.owned.has(cls):
			out.owned.append(cls)
		if levels is Dictionary and levels.has(id):
			out.levels[cls] = maxi(int(out.levels.get(cls, 1)), clampi(int(levels[id]), 1, GearData.MAX_LEVEL))
		if copies is Dictionary and copies.get(id) is Dictionary:
			for r in copies[id]:
				out.spare_coins += int(copies[id][r]) * GearData.drop_coins(String(r))
			if GearData.set_unlocked(String(GearData.ITEMS[id].set), unlocked):
				out.spare_coins -= GearData.drop_coins("common")   # the one free copy every open weapon counted as
	out.spare_coins = maxi(int(out.spare_coins), 0)
	if eq is Dictionary and GearData.ITEMS.has(String(eq.get("Weapon", ""))):
		out.equipped = GearData.weapon_class(String(eq.get("Weapon", "")))
	return out

# ONCE per save (hub and the Heroes page call it on opening): writes the arsenal, pays the spare
# weapon copies out as coins, and gives every hero's weapon the mastery its class had. Returns
# the coins paid (-1 = nothing to do).
static func settle(save: Dictionary) -> int:
	if save.get("arsenal") is Dictionary:
		return -1
	var old := _old(save)
	var a := read(save)
	save["arsenal"] = a
	save["coins"] = int(save.get("coins", 0)) + int(old.spare_coins)
	var m = save.get("mastery", {})
	if m is Dictionary:
		var out := {}
		for k in m:
			if String(k).contains(":"):
				out[k] = m[k]
				continue
			for hid in SETS:
				if classes(hid).has(String(k)) and m[k] is Dictionary:
					out[key(hid, String(k))] = Dictionary(m[k]).duplicate()
		save["mastery"] = out
	return int(old.spare_coins)

# ------------------------------------------------------------------ one weapon
static func key(hid: String, cls: String) -> String:
	return "%s:%s" % [hid, cls]

static func owned(a: Dictionary, hid: String, cls: String) -> bool:
	return DevTools.on and classes(hid).has(cls) or Array(a[hid].owned).has(cls)

static func level(a: Dictionary, hid: String, cls: String) -> int:
	return int(a[hid].levels.get(cls, 1))

static func equipped(a: Dictionary, hid: String) -> String:
	return String(a[hid].equipped)

# "" when `cls` can be unlocked for `hid` now, else what is in the way
static func why_not(save: Dictionary, hid: String, cls: String) -> String:
	var i := classes(hid).find(cls)
	if i < 0:
		return "Not his"
	if owned(read(save), hid, cls):
		return "Owned"
	if DevTools.on:
		return ""
	if raw_level(save, hid) < int(OPEN_LEVEL[i]):
		return "Hero Lv.%d" % int(OPEN_LEVEL[i])
	if int(save.get("coins", 0)) < int(OPEN_COST[i]):
		return "Not enough coins"
	return ""

static func cost(hid: String, cls: String) -> int:
	return int(OPEN_COST[maxi(classes(hid).find(cls), 0)])

static func open_level(hid: String, cls: String) -> int:
	return int(OPEN_LEVEL[maxi(classes(hid).find(cls), 0)])

static func unlock(save: Dictionary, hid: String, cls: String) -> bool:
	if why_not(save, hid, cls) != "":
		return false
	if not DevTools.on:
		save["coins"] = int(save.get("coins", 0)) - cost(hid, cls)
	var a := read(save)
	if not Array(a[hid].owned).has(cls):
		a[hid].owned.append(cls)
	save["arsenal"] = a
	return true

# a weapon is waiting to be unlocked for this hero (the red dot)
static func ready(save: Dictionary, hid: String) -> bool:
	for c in classes(hid):
		if why_not(save, hid, String(c)) == "":
			return true
	return false

static func equip(save: Dictionary, hid: String, cls: String) -> bool:
	var a := read(save)
	if not Array(a[hid].owned).has(cls) and not (DevTools.on and classes(hid).has(cls)):
		return false
	if not Array(a[hid].owned).has(cls):
		a[hid].owned.append(cls)
	a[hid].equipped = cls
	save["arsenal"] = a
	return true

# the Heroes page edits the GearData view (equip, level up): put it back into the arsenal
static func take_view(save: Dictionary, gear: Dictionary) -> void:
	var hid := raw_selected(save)
	var a := read(save)
	var row: Dictionary = a[hid]
	var cls := GearData.weapon_class(String(gear.equipped.get("Weapon", "")))
	if classes(hid).has(cls) and (Array(row.owned).has(cls) or DevTools.on):
		if not Array(row.owned).has(cls):
			row.owned.append(cls)
		row.equipped = cls
	for c in row.owned:
		var id := String(GearData.CLASS_ITEM[c])
		if gear.levels.has(id):
			row.levels[c] = clampi(int(gear.levels[id]), 1, GearData.MAX_LEVEL)
	save["arsenal"] = a

# ------------------------------------------------------------------ the Specialty slot
# how many of his four weapons have reached mastery step SPECIAL_STEP
static func special_count(save: Dictionary, hid: String) -> int:
	var n := 0
	for c in classes(hid):
		if Mastery.level(save, key(hid, String(c))) >= SPECIAL_STEP:
			n += 1
	return n

static func special_earned(save: Dictionary, hid: String) -> bool:
	return special_count(save, hid) >= classes(hid).size()

# ------------------------------------------------------------------ reset (Rudy's Wing Fighter note, 2026-11-16)
# A weapon can be taken back to Lv.1 and everything spent on its levels comes back: coins, parts,
# materials. Trying another weapon costs nothing. Its mastery (earned by kills) and its unlock stay.
# {coins, parts {id: n}} that a reset of this weapon pays back
static func refund(save: Dictionary, hid: String, cls: String) -> Dictionary:
	var out := {"coins": 0, "parts": {}}
	var lv := level(read(save), hid, cls)
	var el := String(Heroes.ROSTER[hid].element) if Heroes.ROSTER.has(hid) else "ion"
	for l in range(1, lv):
		out.coins += GearData.upgrade_cost(l)
		var need := Parts.need(l)
		need.merge(Materials.weapon_need(l, el))
		for k in need:
			out.parts[k] = int(out.parts.get(k, 0)) + int(need[k])
	return out

static func reset(save: Dictionary, hid: String, cls: String) -> bool:
	var a := read(save)
	if not Array(a[hid].owned).has(cls) or level(a, hid, cls) <= 1:
		return false
	var back := refund(save, hid, cls)
	save["coins"] = int(save.get("coins", 0)) + int(back.coins)
	for k in back.parts:
		Parts.add(save, String(k), int(back.parts[k]))
	a[hid].levels[cls] = 1
	save["arsenal"] = a
	return true

# ------------------------------------------------------------------ the Specialty weapons (2026-11-16)
# Each hero has a unique weapon, earned with all four of his weapons at mastery step SPECIAL_STEP.
# It rides in the EXTRA slot: it fires by itself every `cd` seconds beside the weapon in hand
# (battle _update_special). Stand-in looks drawn in code until Luna paints them.
const SPECIALS := {
	"frost": {"name": "Snow Globe", "text": "Lobs a globe that freezes every bug where it lands", "cd": 9.0},
	"ember": {"name": "Dragon Breath", "text": "Breathes a wide cone of fire, very short range", "cd": 8.0},
	"sparks": {"name": "Tesla Coil", "text": "Drops a coil that zaps nearby bugs on its own", "cd": 12.0},
	"rook": {"name": "Orbital Strike", "text": "Marks the toughest bug and calls a beam down on it", "cd": 9.0},
	"hollow": {"name": "Rift", "text": "Opens a rift that drags bugs in and swallows the weak ones", "cd": 12.0},
	"nyx": {"name": "Glaive", "text": "Throws a glaive that cuts through bugs and flies back", "cd": 6.0},
}

static func special(hid: String) -> Dictionary:
	return SPECIALS.get(hid, {})
