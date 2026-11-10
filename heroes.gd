class_name Heroes
extends RefCounted
# HEROES (Rudy, 2026-11-05; DESIGN-heroes.md): the player collects complete characters
# instead of armour pieces. A hero is RATED by a star GRADE (1 Common ... 5 Mythic), has an
# ELEMENT (what he shoots: strong or weak against enemy families), a signature weapon (the
# one gear slot that stays), a passive, a LEVEL (coins) and a TIER (shards: his evolved
# looks). Heroes are BOUGHT, not handed out by stage: coins + parts ("elements": Alloy,
# Cells, Cores), or crystals as the shortcut; a few are also gated by a stage; real-money
# packs come with Store 2.0. Element ids are the old set ids so every colour, weapon and
# thruster in GearData.SETS carries over.
# Save "hero": {"selected": id, "owned": [ids], "levels": {id: n}, "def": {id: n}, "tiers": {id: n},
# "shards": {id: n}}. An old save with no "hero" block is converted once (migrate): coins
# spent on the five armour pieces become Rook's level, armour copies become Rook shards.
# The old gear block stays untouched, so the change can be undone.

const ELEMENTS := {
	"ion":       {"name": "Energy",   "short": "NRG"},
	"scavenger": {"name": "Electric", "short": "ELC"},
	"frost":     {"name": "Ice",      "short": "ICE"},
	"void":      {"name": "Void",     "short": "VOID"},
	"nightmare": {"name": "Dark",     "short": "DARK"},
	"solar":     {"name": "Fire",     "short": "FIRE"},
}
# enemy families by planet (area index) until the real families exist (queue item 17)
const FAMILIES := [
	{"name": "Hive insects",    "weak": "solar",     "resist": "frost"},
	{"name": "Scrap machines",  "weak": "scavenger", "resist": "void"},
	{"name": "Magma creatures", "weak": "frost",     "resist": "solar"},
	{"name": "Crystal shards",  "weak": "void",      "resist": "scavenger"},
	{"name": "Plasma beings",   "weak": "nightmare", "resist": "frost"},
	{"name": "Sentinel AI",     "weak": "scavenger", "resist": "nightmare"},
]
const WEAK_MULT := 1.35
const RESIST_MULT := 0.75

# the star grades (Rudy): a rating, shown as stars; a higher grade is a stronger hero
const GRADES := [
	{"name": "Common",    "color": Color(0.72, 0.78, 0.88), "mult": 1.0},
	{"name": "Uncommon",  "color": Color(0.45, 0.95, 0.5),  "mult": 1.0},
	{"name": "Rare",      "color": Color(0.25, 0.75, 1.0),  "mult": 1.0},
	{"name": "Epic",      "color": Color(0.71, 0.55, 1.0),  "mult": 1.0},
	{"name": "Legendary", "color": Color(1.0, 0.8, 0.3),    "mult": 1.0},
]
# ASCEND (Rudy's go-ahead, 2026-11-10; mock-up claude.ai/artifact/S9RA3rB68rTmrkZ6GHKyrK): the grade
# is no longer a fixed rating with its own multiplier. It is the RARITY STEP a hero STARTS on, on
# the one ladder every hero climbs (Gates: Common, Uncommon, Rare, Epic, Legendary, Mythic I-V), so
# a Common can reach the top and a rarer hero simply starts ahead. tier() = the steps he has
# ascended + his start. Each step still raises the level cap by 10 and the power (Gates), and the
# named steps unlock a hero power-up:
#   Uncommon   his passive x1.5          Rare       +1 free card refresh every run
#   Epic       starts every run with his hero card (level 1)
#   Legendary  the evolved look, passive x2          Mythic I-IV  the red aura, +12% power a step
#   Mythic V   passive x3
const STEP_PERKS := {2: "Passive x1.5", 3: "+1 free card refresh every run", 4: "Starts each run with his hero card",
	5: "Evolved look  ·  passive x2", 6: "Mythic aura", 10: "Passive x3"}
const PASSIVES := {
	"rook":   {"stat": "gem_xp",      "base": 0.15, "text": "Gem XP +%d%%"},
	"sparks": {"stat": "coins",       "base": 0.20, "text": "Coins +%d%%"},
	"frost":  {"stat": "chill",       "base": 0.15, "text": "Shots chill %d%%"},
	"hollow": {"stat": "pierce",      "base": 5.0,  "text": "Every %s bolt pierces"},
	"nyx":    {"stat": "crit_rate",   "base": 0.05, "text": "Crit rate +%d%%"},
	"ember":  {"stat": "hp_mult",     "base": 0.20, "text": "Max HP +%d%%"},
}
const ORDINAL := {2: "2nd", 3: "3rd", 4: "4th", 5: "5th"}
# HERO ABILITIES (2026-11-10): one big move each on a cooldown (battle _use_ability, the button
# bottom left). The cooldown shortens two seconds per rarity step.
const ABILITIES := {
	"rook":   {"name": "Volley",      "text": "4 seconds at two and a half times the fire rate"},
	"sparks": {"name": "Overload",    "text": "Lightning jumps through the 8 nearest bugs"},
	"frost":  {"name": "Whiteout",    "text": "Freezes every bug for 3 seconds"},
	"hollow": {"name": "Phase Storm", "text": "5 seconds of bolts that pass through everything"},
	"nyx":    {"name": "Execute",     "text": "Weak bugs die, the rest are marked: every hit crits"},
	"ember":  {"name": "Firestorm",   "text": "Sets every bug on fire"},
}
const ABILITY_CD := 40.0

static func ability_cd(star: int) -> float:
	return maxf(ABILITY_CD - 2.0 * (star - 1), 22.0)

# how much stronger the passive is at this step
static func passive_mult(star: int) -> float:
	return 3.0 if star >= Gates.MAX_STAR else (2.0 if star >= Gates.GOLD else (1.5 if star >= 2 else 1.0))

# Hollow's piercing bolt comes round sooner: every 5th, 4th, 3rd, 2nd
static func pierce_every(star: int) -> int:
	return 2 if star >= Gates.MAX_STAR else (3 if star >= Gates.GOLD else (4 if star >= 2 else 5))

# Frost's slow: 15%, then +5 / +10 / +20 points
static func chill_bonus(star: int) -> float:
	return 0.1 * (passive_mult(star) - 1.0)

# the passive in words at this step ("Gem XP +22%")
static func passive_text(id: String, star: int) -> String:
	if not PASSIVES.has(id):
		return ""
	var p: Dictionary = PASSIVES[id]
	if String(p.stat) == "pierce":
		return String(p.text) % String(ORDINAL[pierce_every(star)])
	if String(p.stat) == "chill":
		return String(p.text) % roundi((float(p.base) + chill_bonus(star)) * 100.0)
	return String(p.text) % roundi(float(p.base) * passive_mult(star) * 100.0)

# what reaching `star` unlocks, in a few words (every step: +10 levels and more power)
static func step_perk(star: int) -> String:
	return String(STEP_PERKS.get(star, "Power +%d%%" % roundi((Gates.RED_STEP if Gates.is_red(star) else Gates.GOLD_STEP) * 100.0)))

# "cost" = coins + parts, all needed; "crystals" = the whole price in crystals instead;
# "stage" (optional) = must have cleared that stage first (a few are gated, most are not);
# "build" (Rudy): small heroes are drawn smaller and move faster, bulky ones slower but
# tougher ("tough" = hit recovery now; a DEF stat once the pilot is on HP, DESIGN-heroes.md)
const ROSTER := {
	"rook":   {"name": "Rook", "title": "Cadet of the Skybound Guard", "element": "ion", "grade": 1,
		"weapon": "ion_weapon", "passive": "Gem XP +15%", "look": "pilot",
		"cost": {}, "crystals": 0, "build": {"scale": 1.0, "speed": 1.0, "tough": 1.0},
		"blurb": "The pilot who held the first dome. Learns fast."},
	"sparks": {"name": "Sparks", "title": "Junkyard maintenance unit", "element": "scavenger", "grade": 1,
		"weapon": "scavenger_weapon", "passive": "Coins +20%", "look": "sparks",
		"cost": {"coins": 2500, "alloy": 12}, "crystals": 60, "build": {"scale": 0.9, "speed": 1.15, "tough": 0.9},
		"blurb": "A scrap-belt robot that fixes things by welding them to other things."},
	"frost":  {"name": "Cpt. Frost", "title": "Captain Frost, penguin, decorated", "element": "frost", "grade": 2,
		"weapon": "frost_weapon", "passive": "Shots chill", "look": "frost",
		"cost": {"coins": 8000, "alloy": 20, "cell": 6}, "crystals": 160, "build": {"scale": 1.12, "speed": 0.88, "tough": 1.25},
		"blurb": "Took the suit from a bigger pilot. Keeps the medals."},
	"hollow": {"name": "Hollow", "title": "What is left of a pilot", "element": "void", "grade": 3,
		"weapon": "void_weapon", "passive": "Every 5th bolt pierces", "look": "hollow",
		"cost": {"coins": 18000, "cell": 12, "core": 2, "ess_void": 3}, "crystals": 320, "build": {"scale": 0.95, "speed": 1.1, "tough": 0.85},
		"blurb": "Nobody remembers his ship. He does not either."},
	"nyx":    {"name": "Nyx", "title": "Night huntress", "element": "nightmare", "grade": 4,
		"weapon": "nightmare_weapon", "passive": "Crit rate +5%", "look": "nyx",
		"cost": {"coins": 40000, "cell": 20, "core": 6, "ess_nightmare": 6}, "crystals": 650, "stage": 20, "build": {"scale": 0.9, "speed": 1.2, "tough": 0.9},
		"blurb": "Sees the weak spot before the bug knows it has one."},
	"ember":  {"name": "Ember", "title": "Dragon-kin, flight harness", "element": "solar", "grade": 4,
		"weapon": "solar_weapon", "passive": "Max HP +20%", "look": "ember",
		"cost": {"coins": 40000, "alloy": 40, "cell": 20, "core": 6, "ess_solar": 6}, "crystals": 650, "stage": 30, "premium": true, "build": {"scale": 1.15, "speed": 0.85, "tough": 1.3},   # premium (Gates): crystals only
		"blurb": "Breathes fire instead of carrying a jetpack. Cheaper."},
}
const ORDER := ["rook", "sparks", "frost", "hollow", "nyx", "ember"]
const DEFAULT := "rook"

const MAX_LEVEL := 100   # 10 a star: 50 at five gold stars, 100 at red 5 (Gates, DESIGN-stars.md)
# per hero level (level 1 = nothing yet)
const PER_LEVEL := {"atk": 0.03, "rate": 0.01, "aim": 0.015, "recovery": 0.02, "magnet": 2.0, "auto_fire": 0.01}
# milestones every 5 levels, rotating (the old gear milestones, now on the hero)
const MILESTONES := [
	# (Rudy, dev186): milestones are PERKS, not only numbers: a new way of shooting on the way up
	{"stat": "crit_rate", "per": 0.03, "text": "Crit rate +3%"},
	{"stat": "hp_mult",   "per": 0.15, "text": "Max HP +15%"},
	{"stat": "crit_dmg",  "per": 0.15, "text": "Crit damage +15%"},
	{"stat": "dmg_boost", "per": 0.04, "text": "Damage boost +4%"},
	{"stat": "base_dr",   "per": 0.04, "text": "Base damage taken -4%"},
	{"stat": "fortress",  "per": 0.06, "text": "Fortress HP +6%"},
	{"stat": "twin_shot", "per": 1.0,  "text": "Every 6th shot fires a twin"},
	{"stat": "crit_rate", "per": 0.03, "text": "Crit rate +3%"},
	{"stat": "hp_mult",   "per": 0.15, "text": "Max HP +15%"},
	{"stat": "pierce1",   "per": 1.0,  "text": "Bolts pass through 1 bug"},
	{"stat": "dmg_boost", "per": 0.05, "text": "Damage boost +5%"},
	{"stat": "burst2",    "per": 1.0,  "text": "Fires in bursts of 2"},
]
const MILESTONE_EVERY := 5
# pilot HP (instead of three hearts, dev172). DEF (Rudy, dev186): ONE level track: every level
# adds ATK, HP and DEF together (DEF_PER a level, capped); no separate DEF button
const BASE_HP := 100.0
const HP_PER_LEVEL := 0.02
const DEF_PER := 0.008
const DEF_CAP := 0.5
const MAX_DEF_LEVEL := 40
# STARS (Rudy 2026-11-06, Gates / DESIGN-stars.md): save "tiers" holds the hero's STAR (1-5 gold,
# 6-10 red). A star needs the hero at his level cap plus shards, essences and coins (Gates.need);
# each star raises the cap by 10 and the power (Gates.power_mult). The LOOKS (Rudy, 2026-11-06): base at 1 star, a minor change at
# 2-4 (tier 2 portrait, rim and halo in code), Luna's tier 3 frames at 5 stars (PilotRig.LOOK_AT_STARS). TIER_BONUS stays for the Gear page's ATK line.
const TIER_BONUS := Gates.GOLD_STEP
const MAX_TIER := Gates.MAX_STAR
# armour copies -> shards when an old save is converted (their merge value)
const SHARD_VALUE := {"common": 1, "uncommon": 3, "rare": 9, "epic": 27, "legendary": 81}

static func def_cost(level: int) -> int:
	return 50 + 25 * level

static func level_cost(level: int) -> int:
	return 60 + 30 * level

# ------------------------------------------------------------------ save

static func read(save: Dictionary) -> Dictionary:
	var h = save.get("hero", null)
	if typeof(h) != TYPE_DICTIONARY:
		return migrate(save)
	var out := {"selected": DEFAULT, "owned": [DEFAULT], "levels": {}, "def": {}, "tiers": {}, "shards": {}}
	var ow = h.get("owned", [])
	if typeof(ow) == TYPE_ARRAY:
		for id in ow:
			if ROSTER.has(String(id)) and not out.owned.has(String(id)):
				out.owned.append(String(id))
	if ROSTER.has(String(h.get("selected", ""))) and out.owned.has(String(h.selected)):
		out.selected = String(h.selected)
	for key in ["levels", "def", "tiers", "shards"]:
		var src = h.get(key, {})
		if typeof(src) == TYPE_DICTIONARY:
			for id in src:
				if ROSTER.has(id):
					out[key][id] = int(src[id])
	return out

static func write(h: Dictionary) -> Dictionary:
	return {"selected": h.selected, "owned": h.owned, "levels": h.levels, "def": h.def, "tiers": h.tiers, "shards": h.shards}

# the hero block an old save gets the first time: spent armour coins -> Rook's level,
# armour copies -> Rook shards (the weapon keeps everything it had)
static func migrate(save: Dictionary) -> Dictionary:
	var out := {"selected": DEFAULT, "owned": [DEFAULT], "levels": {}, "def": {}, "tiers": {}, "shards": {}}
	var g := GearData.read(save)
	var spent := 0
	var shards := 0
	for id in GearData.ITEMS:
		if String(GearData.ITEMS[id].slot) == "Weapon":
			continue
		var lv := int(g.levels.get(id, 1))
		for l in range(1, lv):
			spent += GearData.upgrade_cost(l)
		if g.copies.has(id):
			for r in g.copies[id]:
				var n := int(g.copies[id][r])
				if GearData.set_unlocked(GearData.ITEMS[id].set, int(save.get("stage_unlocked", 1))) and r == "common":
					n -= 1   # the one free copy every unlocked piece counts as
				shards += maxi(n, 0) * int(SHARD_VALUE.get(r, 1))
	var lv := 1
	while lv < MAX_LEVEL and spent >= level_cost(lv):
		spent -= level_cost(lv)
		lv += 1
	out.levels[DEFAULT] = lv
	out.tiers[DEFAULT] = 1   # stars are earned from here on (Gates): the shards stay his
	out.shards[DEFAULT] = shards
	return out

# ------------------------------------------------------------------ queries

static func level(h: Dictionary, id: String) -> int:
	return clampi(int(h.levels.get(id, 1)), 1, MAX_LEVEL)

static func def_level(h: Dictionary, id: String) -> int:
	return clampi(int(h.def.get(id, 1)), 1, MAX_DEF_LEVEL)

# the hero's STAR (the save key is still "tiers"; 1-5 gold, 6-10 red)
static func tier(h: Dictionary, id: String) -> int:
	return clampi(ascends(h, id) + grade(id) - 1, 1, MAX_TIER)   # his start rarity + the steps he climbed (ASCEND)

# the saved count: 1 = not ascended yet
static func ascends(h: Dictionary, id: String) -> int:
	return clampi(int(h.tiers.get(id, 1)), 1, MAX_TIER)

static func star(h: Dictionary, id: String) -> int:
	return tier(h, id)

# the highest level his star allows (Gates: 10 a star)
static func level_cap(h: Dictionary, id: String) -> int:
	return Gates.level_cap("hero", tier(h, id))

static func shards(h: Dictionary, id: String) -> int:
	return maxi(int(h.shards.get(id, 0)), 0)

static func selected(h: Dictionary) -> String:
	return String(h.selected) if ROSTER.has(String(h.selected)) else DEFAULT

static func owned(h: Dictionary, id: String) -> bool:
	return id == DEFAULT or h.owned.has(id) or DevTools.on

# "unlocked" = owned (loadouts, the rig)
static func unlocked(save: Dictionary, id: String) -> bool:
	return ROSTER.has(id) and owned(read(save), id)

static func grade(id: String) -> int:
	return clampi(int(ROSTER[id].get("grade", 1)), 1, GRADES.size()) if ROSTER.has(id) else 1

static func grade_name(id: String) -> String:
	return String(GRADES[grade(id) - 1].name)

static func grade_color(id: String) -> Color:
	return GRADES[grade(id) - 1].color

static func stars_text(id: String) -> String:
	return "★".repeat(grade(id))

# no stage gates (Rudy, 2026-11-06: stars are earned by building the hero, never by reaching a
# stage); the ROSTER "stage" keys are kept but unused
static func gate(_id: String) -> int:
	return 0

static func gate_open(_save: Dictionary, _id: String) -> bool:
	return true

# premium (Gates): crystals only, no coin price
static func premium(id: String) -> bool:
	return ROSTER.has(id) and Gates.premium(ROSTER[id])

# "2,500 coins + 12 Alloy" and "or 60 crystals"
static func cost_text(id: String) -> String:
	if premium(id):
		return "Crystals only"
	var c: Dictionary = ROSTER[id].get("cost", {})
	var bits: Array = []
	if int(c.get("coins", 0)) > 0:
		bits.append("%s coins" % UIKit.num(int(c.coins)))
	var needs := parts_needed(id)
	if not needs.is_empty():
		bits.append(Parts.text(needs))
	return " + ".join(bits) if not bits.is_empty() else "Free"

static func parts_needed(id: String) -> Dictionary:
	var c: Dictionary = ROSTER[id].get("cost", {})
	var needs := {}
	for k in Parts.all_order():   # parts and materials (3-star+ heroes ask for essences, dev189)
		if int(c.get(k, 0)) > 0:
			needs[k] = int(c[k])
	return needs

static func crystal_price(id: String) -> int:
	return int(ROSTER[id].get("crystals", 0))

# can the coins + parts price be paid right now?
static func can_afford(save: Dictionary, id: String) -> bool:
	if premium(id):
		return false
	var c: Dictionary = ROSTER[id].get("cost", {})
	return int(save.get("coins", 0)) >= int(c.get("coins", 0)) and Parts.has_all(Parts.read(save), parts_needed(id))

# Buy a hero: with_crystals = the crystal price instead of coins + parts. Changes `save` and
# `h` in place; returns "" on success or why it failed. The new hero goes on duty.
static func unlock(save: Dictionary, h: Dictionary, id: String, with_crystals: bool) -> String:
	if not ROSTER.has(id):
		return "No such hero"
	if owned(h, id):
		return "Already yours"
	if with_crystals:
		var price := crystal_price(id)
		if price <= 0:
			return "Not for crystals"
		if int(save.get("crystals", 0)) < price:
			return "Not enough crystals"
		save["crystals"] = int(save.get("crystals", 0)) - price
	else:
		if premium(id):
			return "Crystals only"
		var c: Dictionary = ROSTER[id].get("cost", {})
		var why := Parts.pay(save, int(c.get("coins", 0)), parts_needed(id), false)
		if why != "":
			return why
	h.owned.append(id)
	h.selected = id
	return ""

static func milestones(lv: int) -> int:
	return lv / MILESTONE_EVERY

# the milestone a hero gets at `lv` (an empty dict when none)
static func milestone_at(lv: int) -> Dictionary:
	if lv % MILESTONE_EVERY != 0 or lv == 0:
		return {}
	return MILESTONES[(lv / MILESTONE_EVERY - 1) % MILESTONES.size()]

# what the next star asks for (Gates.need): {"coins", "shards", "mats"}
static func star_need(h: Dictionary, id: String) -> Dictionary:
	return Gates.need("hero", tier(h, id) + 1, element_of(id))

# the shards the next star asks for (0 at max)
static func next_tier_cost(h: Dictionary, id: String) -> int:
	return int(star_need(h, id).shards) if tier(h, id) < MAX_TIER else 0

# the materials the next star asks for on top of the shards (essences, coils)
static func tier_need(h: Dictionary, id: String) -> Dictionary:
	return Dictionary(star_need(h, id).mats) if tier(h, id) < MAX_TIER else {}

# why the next star cannot be taken now ("" = it can): the pilot-level door, the level cap, the
# shards, the materials, the coins, in that order (Gates.why_not)
static func why_not_evolve(h: Dictionary, id: String, save: Dictionary) -> String:
	return Gates.why_not(save, "hero", tier(h, id), level(h, id), shards(h, id), element_of(id))

# with `save`, the door, the level cap, the materials and the coins are checked too (the page
# passes it; without it only the shards count, as the old tests do)
static func can_evolve(h: Dictionary, id: String, save: Dictionary = {}) -> bool:
	if tier(h, id) >= MAX_TIER:
		return false
	if save.is_empty():
		return DevTools.on or shards(h, id) >= next_tier_cost(h, id)
	return why_not_evolve(h, id, save) == ""

# ------------------------------------------------------------------ actions

static func level_up(save: Dictionary, h: Dictionary, id: String) -> bool:
	var lv := level(h, id)
	var cost := level_cost(lv)
	if DevTools.on:
		cost = 0   # dev mode: free
	if lv >= level_cap(h, id) or int(save.get("coins", 0)) < cost:   # capped by his star (Gates)
		return false
	save["coins"] = int(save.get("coins", 0)) - cost
	h.levels[id] = lv + 1
	return true

static func def_up(save: Dictionary, h: Dictionary, id: String) -> bool:
	var lv := def_level(h, id)
	var cost := def_cost(lv)
	if DevTools.on:
		cost = 0
	if lv >= MAX_DEF_LEVEL or int(save.get("coins", 0)) < cost:
		return false
	save["coins"] = int(save.get("coins", 0)) - cost
	h.def[id] = lv + 1
	return true

static func evolve(h: Dictionary, id: String, save: Dictionary = {}) -> bool:
	if not can_evolve(h, id, save):
		return false
	if not save.is_empty() and Gates.pay(save, "hero", tier(h, id), element_of(id)) != "":
		return false
	h.shards[id] = maxi(shards(h, id) - next_tier_cost(h, id), 0)
	h.tiers[id] = ascends(h, id) + 1
	return true

static func add_shards(h: Dictionary, id: String, n: int) -> void:
	if ROSTER.has(id) and n > 0:
		h.shards[id] = shards(h, id) + n

# ------------------------------------------------------------------ elements

static func element_of(id: String) -> String:
	return String(ROSTER[id].element) if ROSTER.has(id) else "ion"

static func element_name(el: String) -> String:
	return String(ELEMENTS.get(el, {}).get("name", "Energy"))

static func element_color(el: String) -> Color:
	return GearData.SETS[el].color if GearData.SETS.has(el) else GearData.SETS["ion"].color

static func family(stage: int) -> Dictionary:
	return FAMILIES[StageData.area_index(stage)]

# damage multiplier of an element on this stage's family
static func element_mult(el: String, stage: int) -> float:
	var f := family(stage)
	if el == String(f.weak):
		return WEAK_MULT
	if el == String(f.resist):
		return RESIST_MULT
	return 1.0

# "Weak to Fire · Resists Ice" for Home and the Stage Map
static func family_text(stage: int) -> String:
	var f := family(stage)
	return "Weak to %s  ·  Resists %s" % [element_name(f.weak), element_name(f.resist)]

# the hero whose element is this planet's weakness (shards drop for him there)
static func hero_for_planet(stage: int) -> String:
	var weak: String = family(stage).weak
	for id in ORDER:
		if String(ROSTER[id].element) == weak:
			return id
	return DEFAULT

# ------------------------------------------------------------------ battle stats
# The same keys GearData.stats gave battle, now from the hero + the one weapon slot.
static func stats(save: Dictionary) -> Dictionary:
	var h := read(save)
	var id := selected(h)
	var hero: Dictionary = ROSTER[id]
	var gear := GearData.read(save)
	var st := {"damage": 1.0, "fire_rate": 1.0, "aim": 1.0, "recovery": 1.0, "magnet": 0.0,
		"auto_fire": 1.0, "gem_xp": 1.0, "coins": 1.0, "shield_regen": 1.0, "refreshes": 0, "pierce5": false,
		"turret_dmg": 1.0, "turret_rate": 1.0, "pilot_xp": 1.0, "shield": 1.0, "chill": false,
		"crit_rate": GearData.BASE_CRIT_RATE, "crit_dmg": GearData.BASE_CRIT_DMG, "dmg_boost": 0.0, "base_dr": 0.0, "fortress": 1.0,
		"weapon": "laser_pistol", "thruster": String(GearData.SETS[hero.element].thruster),
		"hero": id, "element": String(hero.element), "hp": BASE_HP, "hp_mult": 1.0, "def": 0.0, "twin_shot": 0.0, "pierce1": 0.0, "burst2": 0.0,
		"scale": float(hero.build.scale), "speed": float(hero.build.speed), "tough": float(hero.build.tough)}
	# (no grade multiplier since ASCEND: a rarer hero starts on a higher step instead)
	# the hero's level
	var lv := level(h, id)
	var steps := lv - 1
	st.damage *= 1.0 + float(PER_LEVEL.atk) * steps
	st.fire_rate *= 1.0 + float(PER_LEVEL.rate) * steps
	st.aim = 1.0 + float(PER_LEVEL.aim) * steps
	st.recovery = (1.0 + float(PER_LEVEL.recovery) * steps) * float(hero.build.tough)   # bulky heroes shrug hits off longer
	st.magnet = float(PER_LEVEL.magnet) * steps
	st.auto_fire = 1.0 + float(PER_LEVEL.auto_fire) * steps
	for m in milestones(lv):
		var ms: Dictionary = MILESTONES[m % MILESTONES.size()]
		st[ms.stat] = float(st[ms.stat]) + float(ms.per)
	# HP and DEF (Rudy: HP instead of three hearts, so defence can be a stat): HP grows with the
	# level and the tier, DEF with its own upgrade track; bulky builds start with more HP
	st.hp = BASE_HP * float(hero.build.tough) * (1.0 + HP_PER_LEVEL * steps)
	st.def = minf(DEF_PER * steps + DEF_PER * 0.5 * (def_level(h, id) - 1), DEF_CAP)   # the level (and any old DEF levels bought before dev186)
	# his star (Gates: +8% a gold star, +12% a red one)
	var star := tier(h, id)
	var sm := Gates.power_mult(star)
	st.damage *= sm
	st.fortress *= sm
	st.hp *= sm
	# the passive, stronger on the named steps (ASCEND: x1.5 Uncommon, x2 Legendary, x3 Mythic V)
	var pm := passive_mult(star)
	st["pierce_every"] = 0
	st["chill_bonus"] = 0.0
	match id:
		"rook": st.gem_xp += 0.15 * pm
		"sparks": st.coins += 0.20 * pm
		"frost":
			st.chill = true
			st.chill_bonus = chill_bonus(star)
		"hollow":
			st.pierce5 = true
			st.pierce_every = pierce_every(star)
		"nyx": st.crit_rate += 0.05 * pm
		"ember": st.hp_mult += 0.2 * pm
	# the step power-ups: a free refresh from Rare, his hero card in hand from Epic
	if star >= 3:
		st.refreshes += 1
	st["start_card"] = star >= 4
	st["ability_cd"] = ability_cd(star)
	# the one gear slot: the weapon (its level, its type)
	var wid: String = gear.equipped["Weapon"]
	var wlv := GearData.level(gear, wid)
	st.damage *= 1.0 + float(GearData.SLOT_STAT["Weapon"].per) * wlv
	st.weapon = GearData.SETS[GearData.ITEMS[wid].set].weapon
	st.crit_rate += float(GearData.MILESTONE["Weapon"].per) * GearData.milestones(wlv)
	# the pilot talent map (Talents, dev197): small permanent bonuses for every hero
	var tb := Talents.bonus(save)
	st.damage *= float(tb.damage)
	st.turret_dmg *= float(tb.turret_dmg)
	st.fortress *= float(tb.fortress)
	st.fire_rate *= float(tb.fire_rate)
	st.hp_mult += float(tb.hp_mult)
	st.crit_rate += float(tb.crit_rate)
	st.coins += float(tb.coins)
	st.gem_xp += float(tb.gem_xp)
	st.crit_dmg += float(tb.crit_dmg)
	st.magnet += float(tb.magnet)
	# pilot rank (Promotion)
	st.hp = roundf(float(st.hp) * float(st.hp_mult))   # milestones and Ember's passive
	var pr := Promotion.rank(save)
	st.damage *= Promotion.bonus(pr)
	st.fortress *= Promotion.bonus(pr)
	return st

# a single number for the Heroes page: grade, level, tier and the weapon, weighted
static func power(save: Dictionary) -> int:
	var h := read(save)
	var id := selected(h)
	var gear := GearData.read(save)
	return 40 + 18 * (level(h, id) - 1) + 80 * (tier(h, id) - 1) + 18 * (GearData.level(gear, gear.equipped["Weapon"]) - 1)
