class_name Heroes
extends RefCounted
# HEROES (Rudy, 2026-11-05; DESIGN-heroes.md): the player collects complete characters
# instead of armour pieces. Each hero has an ELEMENT (what he shoots, strong or weak
# against enemy families), a signature weapon (the one gear slot that stays), a passive,
# a level (coins) and stars (shards). Element ids are the old set ids so every colour,
# weapon and thruster in GearData.SETS carries over.
# Save "hero": {"selected": id, "levels": {id: n}, "stars": {id: n}, "shards": {id: n}}.
# An old save with no "hero" block is converted once (migrate): coins spent on the five
# armour pieces become Rook's level, armour copies become Rook shards. The old gear block
# stays untouched, so the change can be undone.

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

const ROSTER := {
	"rook":   {"name": "Rook", "title": "Cadet of the Skybound Guard", "element": "ion", "stage": 1,
		"weapon": "ion_weapon", "passive": "Gem XP +15%", "look": "pilot",
		"blurb": "The pilot who held the first dome. Learns fast."},
	"sparks": {"name": "Sparks", "title": "Junkyard maintenance unit", "element": "scavenger", "stage": 11,
		"weapon": "scavenger_weapon", "passive": "Coins +20%", "look": "sparks",
		"blurb": "A scrap-belt robot that fixes things by welding them to other things."},
	"frost":  {"name": "Cpt. Frost", "title": "Captain Frost, penguin, decorated", "element": "frost", "stage": 21,
		"weapon": "frost_weapon", "passive": "Shots chill", "look": "frost",
		"blurb": "Took the suit from a bigger pilot. Keeps the medals."},
	"hollow": {"name": "Hollow", "title": "What is left of a pilot", "element": "void", "stage": 31,
		"weapon": "void_weapon", "passive": "Every 5th bolt pierces", "look": "hollow",
		"blurb": "Nobody remembers his ship. He does not either."},
	"nyx":    {"name": "Nyx", "title": "Night huntress", "element": "nightmare", "stage": 41,
		"weapon": "nightmare_weapon", "passive": "Crit rate +5%", "look": "nyx",
		"blurb": "Sees the weak spot before the bug knows it has one."},
	"ember":  {"name": "Ember", "title": "Dragon-kin, flight harness", "element": "solar", "stage": 51,
		"weapon": "solar_weapon", "passive": "+1 heart", "look": "ember",
		"blurb": "Breathes fire instead of carrying a jetpack. Cheaper."},
}
const ORDER := ["rook", "sparks", "frost", "hollow", "nyx", "ember"]
const DEFAULT := "rook"

const MAX_LEVEL := 60
# per hero level (level 1 = nothing yet)
const PER_LEVEL := {"atk": 0.03, "rate": 0.01, "aim": 0.015, "recovery": 0.02, "magnet": 2.0, "auto_fire": 0.01}
# milestones every 5 levels, rotating (the old gear milestones, now on the hero)
const MILESTONES := [
	{"stat": "crit_rate", "per": 0.03, "text": "Crit rate +3%"},
	{"stat": "hearts",    "per": 1.0,  "text": "+1 heart"},
	{"stat": "crit_dmg",  "per": 0.15, "text": "Crit damage +15%"},
	{"stat": "dmg_boost", "per": 0.04, "text": "Damage boost +4%"},
	{"stat": "base_dr",   "per": 0.04, "text": "Base damage taken -4%"},
	{"stat": "fortress",  "per": 0.06, "text": "Fortress HP +6%"},
]
const MILESTONE_EVERY := 5
const STAR_SHARDS := [10, 20, 40, 80, 160]   # shards for star 1..5
const STAR_BONUS := 0.04                      # ATK and base shield / hull per star
const MAX_STARS := 5
# armour copies -> shards when an old save is converted (their merge value)
const SHARD_VALUE := {"common": 1, "uncommon": 3, "rare": 9, "epic": 27, "legendary": 81}

static func level_cost(level: int) -> int:
	return 60 + 30 * level

# ------------------------------------------------------------------ save

static func read(save: Dictionary) -> Dictionary:
	var h = save.get("hero", null)
	if typeof(h) != TYPE_DICTIONARY:
		return migrate(save)
	var out := {"selected": DEFAULT, "levels": {}, "stars": {}, "shards": {}}
	if ROSTER.has(String(h.get("selected", ""))):
		out.selected = String(h.selected)
	for key in ["levels", "stars", "shards"]:
		var src = h.get(key, {})
		if typeof(src) == TYPE_DICTIONARY:
			for id in src:
				if ROSTER.has(id):
					out[key][id] = int(src[id])
	return out

static func write(h: Dictionary) -> Dictionary:
	return {"selected": h.selected, "levels": h.levels, "stars": h.stars, "shards": h.shards}

# the hero block an old save gets the first time: spent armour coins -> Rook's level,
# armour copies -> Rook shards (the weapon keeps everything it had)
static func migrate(save: Dictionary) -> Dictionary:
	var out := {"selected": DEFAULT, "levels": {}, "stars": {}, "shards": {}}
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
	# stars first, the rest stays as shards
	var stars := 0
	while stars < MAX_STARS and shards >= STAR_SHARDS[stars]:
		shards -= STAR_SHARDS[stars]
		stars += 1
	out.stars[DEFAULT] = stars
	out.shards[DEFAULT] = shards
	return out

# ------------------------------------------------------------------ queries

static func level(h: Dictionary, id: String) -> int:
	return clampi(int(h.levels.get(id, 1)), 1, MAX_LEVEL)

static func stars(h: Dictionary, id: String) -> int:
	return clampi(int(h.stars.get(id, 0)), 0, MAX_STARS)

static func shards(h: Dictionary, id: String) -> int:
	return maxi(int(h.shards.get(id, 0)), 0)

static func selected(h: Dictionary) -> String:
	return String(h.selected) if ROSTER.has(String(h.selected)) else DEFAULT

static func unlocked(save: Dictionary, id: String) -> bool:
	return ROSTER.has(id) and int(save.get("stage_unlocked", 1)) >= int(ROSTER[id].stage)

static func milestones(lv: int) -> int:
	return lv / MILESTONE_EVERY

# the milestone a hero gets at `lv` (an empty dict when none)
static func milestone_at(lv: int) -> Dictionary:
	if lv % MILESTONE_EVERY != 0 or lv == 0:
		return {}
	return MILESTONES[(lv / MILESTONE_EVERY - 1) % MILESTONES.size()]

static func next_star_cost(h: Dictionary, id: String) -> int:
	var s := stars(h, id)
	return int(STAR_SHARDS[s]) if s < MAX_STARS else 0

static func can_evolve(h: Dictionary, id: String) -> bool:
	return stars(h, id) < MAX_STARS and shards(h, id) >= next_star_cost(h, id)

# the look tier from the stars: 1 base, 2 from 3 stars, 3 at 5 (Luna's evolutions)
static func look_tier(h: Dictionary, id: String) -> int:
	var s := stars(h, id)
	return 3 if s >= 5 else (2 if s >= 3 else 1)

# ------------------------------------------------------------------ actions

static func level_up(save: Dictionary, h: Dictionary, id: String) -> bool:
	var lv := level(h, id)
	var cost := level_cost(lv)
	if lv >= MAX_LEVEL or int(save.get("coins", 0)) < cost:
		return false
	save["coins"] = int(save.get("coins", 0)) - cost
	h.levels[id] = lv + 1
	return true

static func evolve(h: Dictionary, id: String) -> bool:
	if not can_evolve(h, id):
		return false
	h.shards[id] = shards(h, id) - next_star_cost(h, id)
	h.stars[id] = stars(h, id) + 1
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
	var st := {"damage": 1.0, "fire_rate": 1.0, "aim": 1.0, "recovery": 1.0, "hearts": 0, "magnet": 0.0,
		"auto_fire": 1.0, "gem_xp": 1.0, "coins": 1.0, "shield_regen": 1.0, "refreshes": 0, "pierce5": false,
		"turret_dmg": 1.0, "turret_rate": 1.0, "pilot_xp": 1.0, "shield": 1.0, "chill": false,
		"crit_rate": GearData.BASE_CRIT_RATE, "crit_dmg": GearData.BASE_CRIT_DMG, "dmg_boost": 0.0, "base_dr": 0.0, "fortress": 1.0,
		"weapon": "laser_pistol", "thruster": String(GearData.SETS[hero.element].thruster),
		"hero": id, "element": String(hero.element)}
	# the hero's level
	var lv := level(h, id)
	var steps := lv - 1
	st.damage *= 1.0 + float(PER_LEVEL.atk) * steps
	st.fire_rate *= 1.0 + float(PER_LEVEL.rate) * steps
	st.aim = 1.0 + float(PER_LEVEL.aim) * steps
	st.recovery = 1.0 + float(PER_LEVEL.recovery) * steps
	st.magnet = float(PER_LEVEL.magnet) * steps
	st.auto_fire = 1.0 + float(PER_LEVEL.auto_fire) * steps
	for m in milestones(lv):
		var ms: Dictionary = MILESTONES[m % MILESTONES.size()]
		st[ms.stat] = float(st[ms.stat]) + float(ms.per)
	st.hearts = int(st.hearts)
	# stars
	var s := stars(h, id)
	st.damage *= 1.0 + STAR_BONUS * s
	st.fortress *= 1.0 + STAR_BONUS * s
	# the passive
	match id:
		"rook": st.gem_xp += 0.15
		"sparks": st.coins += 0.20
		"frost": st.chill = true
		"hollow": st.pierce5 = true
		"nyx": st.crit_rate += 0.05
		"ember": st.hearts += 1
	# the one gear slot: the weapon (its level, its type)
	var wid: String = gear.equipped["Weapon"]
	var wlv := GearData.level(gear, wid)
	st.damage *= 1.0 + float(GearData.SLOT_STAT["Weapon"].per) * wlv
	st.weapon = GearData.SETS[GearData.ITEMS[wid].set].weapon
	st.crit_rate += float(GearData.MILESTONE["Weapon"].per) * GearData.milestones(wlv)
	# pilot rank (Promotion)
	var pr := Promotion.rank(save)
	st.damage *= Promotion.bonus(pr)
	st.fortress *= Promotion.bonus(pr)
	return st

# a single number for the Heroes page: level, stars and the weapon, weighted
static func power(save: Dictionary) -> int:
	var h := read(save)
	var id := selected(h)
	var gear := GearData.read(save)
	return 40 + 18 * (level(h, id) - 1) + 60 * stars(h, id) + 18 * (GearData.level(gear, gear.equipped["Weapon"]) - 1)
