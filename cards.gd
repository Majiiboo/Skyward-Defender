class_name Cards
extends RefCounted
# Power cards offered on each run level. A card is one entry here; battle.gd
# applies "effect" to its run stats. Rarity sets draw weight and the frame.
# Four tiers: common 60%, uncommon 28%, epic 10%, legendary 2%.
# Every card has at most 3 levels (dev108); the third pick (the last for a card that stops
# at 2) is its overcharge, and a card at its max is never offered again. Overcharge adds
# a bonus on top. Fusion: two overcharged cards of a pair unlock a fusion card that
# keeps both powers and adds its own (FUSIONS; offered in the middle slot of a pick).

const WEIGHTS := {"common": 60.0, "uncommon": 28.0, "epic": 10.0, "legendary": 2.0}
const FRAME := {"common": "res://cards/frame_common.png", "uncommon": "res://cards/frame_uncommon.png",
	"epic": "res://cards/frame_epic.png", "legendary": "res://cards/frame_legendary.png",
	"fusion": "res://cards/frame_legendary.png"}   # battle.gd uses cards/frame_fusion.png when present
const COLOR := {"common": Color(0.75, 0.78, 0.85), "uncommon": Color(0.2, 0.9, 1.0),
	"epic": Color(0.71, 0.55, 1.0), "legendary": Color(1.0, 0.8, 0.3), "fusion": Color(1.0, 0.45, 0.8)}

const CARDS := {
	# offence
	"rapid_pulse":     {"name": "Rapid Pulse",     "family": "pilot",  "rarity": "common",    "max": 3, "icon": "nav_battle",
		"desc": "Fire rate +10%"},
	"heavy_bolts":     {"name": "Heavy Bolts",     "family": "pilot",  "rarity": "common",    "max": 3, "icon": "nav_battle",
		"desc": "Bolt damage +15%: bigger, hotter bolts"},
	"burst_fire":      {"name": "Burst Fire",      "family": "pilot",  "rarity": "uncommon",  "max": 5, "icon": "nav_battle",
		"desc": "Fires bursts of 2, then 3, then 4 bolts"},
	"piercing_rounds": {"name": "Piercing Rounds", "family": "pilot",  "rarity": "uncommon",  "max": 5, "icon": "nav_battle",
		"desc": "Bolts pass through 1 more bug per level"},
	"chain_spark":     {"name": "Chain Spark",     "family": "pilot",  "rarity": "uncommon",  "max": 5, "icon": "event",
		"desc": "Every 5th bolt sparks to 1 more bug per level"},
	"frost_rounds":    {"name": "Frost Rounds",    "family": "pilot",  "rarity": "uncommon",  "max": 3, "icon": "event",
		"desc": "Hits slow bugs by 15% (more each level)"},
	"split_shot":      {"name": "Split Shot",      "family": "pilot",  "rarity": "uncommon",  "max": 5, "pic": "res://icons/chip_split.png",
		"desc": "Some volleys throw extra shots to the sides"},
	"seeker":          {"name": "Seeker",          "family": "pilot",  "rarity": "uncommon",  "max": 5, "pic": "res://icons/st_aim.png",
		"desc": "Your shots curve toward the nearest bug"},
	"drone_barrage":   {"name": "Drone Barrage",   "family": "pilot",  "rarity": "uncommon",  "max": 5, "building": "*drone", "pic": "res://drone/body_scout.png",
		"desc": "The drone hits harder"},
	# passive, open to everyone: the partner that evolves Piercing Rounds
	"killer_instinct": {"name": "Killer Instinct", "family": "pilot",  "rarity": "common",    "max": 3, "pic": "res://icons/st_crit.png",
		"desc": "Critical hits hit 20% harder"},
	# defence
	"aegis":           {"name": "Aegis",           "family": "pilot",  "rarity": "uncommon",  "max": 2, "icon": "nav_gear",
		"desc": "+30 max HP, healed now, and a shield of light"},
	"reinforced_hull": {"name": "Reinforced Hull", "family": "base",   "rarity": "common",    "max": 3, "icon": "chest",
		"desc": "Base shield +30 and hull +20, repaired now"},
	"shield_recharge": {"name": "Shield Recharge", "family": "base",   "rarity": "uncommon",  "max": 3, "icon": "chest", "from_level": 4,
		"desc": "Shield recharges 1%/s, more per level"},
	"field_medic":     {"name": "Field Medic",     "family": "pilot",  "rarity": "uncommon",  "max": 3, "pic": "res://icons/st_hp.png",
		"desc": "The hero slowly gets health back"},
	# utility
	"magnet":          {"name": "Magnet",          "family": "pilot",  "rarity": "common",    "max": 3, "icon": "gem",
		"desc": "Pulls gems and coins from further, +10% XP"},
	# BASE CARDS (2026-11-10, in place of the turret cards): one per building, offered only while
	# that building stands on the base ("building"; "*pulse" = the Core Pulse is open). Picks 1-2
	# give more of what the building does, the 3rd (overcharge) adds something new.
	"shield_surge":   {"name": "Shield Surge",   "family": "base", "rarity": "uncommon", "max": 3, "building": "shield_gen", "pic": "res://base/bld_shield_gen.png",
		"desc": "Base shield +25, repaired now"},
	"nanobots":       {"name": "Nanobots",       "family": "base", "rarity": "uncommon", "max": 3, "building": "repair_bay", "pic": "res://base/bld_repair_bay.png",
		"desc": "The hull mends itself, 0.4% a second per level"},
	"hot_rounds":     {"name": "Hot Rounds",     "family": "base", "rarity": "uncommon", "max": 3, "building": "armory", "pic": "res://base/bld_armory.png",
		"desc": "Bolt damage +8% per level"},
	"stim_pack":      {"name": "Stim Pack",      "family": "base", "rarity": "uncommon", "max": 3, "building": "medbay", "pic": "res://base/bld_medbay.png",
		"desc": "+15 max HP and 25 HP healed now"},
	"plate_up":       {"name": "Plate Up",       "family": "base", "rarity": "uncommon", "max": 3, "building": "plating", "pic": "res://base/bld_plating.png",
		"desc": "Base hull +25, hits on the base 4% weaker"},
	"drone_uplink":   {"name": "Drone Uplink",   "family": "base", "rarity": "uncommon", "max": 3, "building": "hangar", "pic": "res://base/bld_hangar.png",
		"desc": "Drone damage +20% per level"},
	"reactor_surge":  {"name": "Reactor Surge",  "family": "base", "rarity": "uncommon", "max": 3, "building": "reactor", "pic": "res://base/bld_reactor.png",
		"desc": "The ability charges 10% faster per level"},
	"radar_sweep":    {"name": "Radar Sweep",    "family": "base", "rarity": "uncommon", "max": 3, "building": "radar", "pic": "res://base/bld_radar.png",
		"desc": "Crit rate +5% per level"},
	"rich_seam":      {"name": "Rich Seam",      "family": "base", "rarity": "uncommon", "max": 3, "building": "refinery", "pic": "res://base/bld_refinery.png",
		"desc": "Coins +15% per level"},
	"core_overload":  {"name": "Core Overload",  "family": "base", "rarity": "epic", "max": 2, "building": "*pulse", "pic": "res://base/core_light.png",
		"desc": "The Core Pulse recharges 20% faster"},
	# talent cards (dev197, Talents.CARD_AT): the talent map's 10th / 20th / 30th / 40th node
	# unlocks one each ("talent" = the node); pictures borrow the stat icons until Luna paints them
	"focus_fire":   {"name": "Focus Fire",   "family": "pilot", "rarity": "uncommon", "max": 3, "talent": 10, "pic": "res://icons/st_atk.png",
		"desc": "Bolt damage +6% per level"},
	"salvage":      {"name": "Salvage",      "family": "pilot", "rarity": "uncommon", "max": 3, "talent": 20, "pic": "res://icons/ic_coin.png",
		"desc": "Bugs drop +25% coins per level"},
	"second_wind":  {"name": "Second Wind",  "family": "pilot", "rarity": "epic", "max": 3, "talent": 30, "pic": "res://icons/st_hp.png",
		"desc": "Once a run, a killing blow heals you to 50% (then 75%, then full)"},
	"mirror_shell": {"name": "Mirror Shell", "family": "pilot", "rarity": "epic", "max": 3, "talent": 40, "pic": "res://icons/st_def.png",
		"desc": "A bolt that stops a bug's shot throws it back for 50% damage (then 75%, then full)"},
	# hero cards (Rudy, dev172): one per hero, offered only while he is on duty ("hero" key).
	# They BUILD UP like every card: pick 1 the basic form, pick 2 more of it, pick 3 (the
	# overcharge) his max specialty. Not a legendary handed over: earned in the run.
	"rook_twin":    {"name": "Twin Trigger",  "family": "pilot", "rarity": "uncommon", "max": 5, "hero": "rook", "pic": "res://gear/ion_weapon_t1.png",
		"desc": "Every 4th bolt fires a twin (then every 3rd, then every 2nd)"},
	"sparks_weld":  {"name": "Arc Weld",      "family": "pilot", "rarity": "uncommon", "max": 5, "hero": "sparks", "pic": "res://gear/scavenger_weapon_t1.png",
		"desc": "Every 3rd bolt arcs to 1 more bug per level"},
	"frost_freeze": {"name": "Deep Freeze",   "family": "pilot", "rarity": "uncommon", "max": 5, "hero": "frost", "pic": "res://gear/frost_weapon_t1.png",
		"desc": "Hits slow bugs 20% (more per level)"},
	"hollow_phase": {"name": "Phase Bolts",   "family": "pilot", "rarity": "uncommon", "max": 5, "hero": "hollow", "pic": "res://gear/void_weapon_t1.png",
		"desc": "Bolts pass through 1 more bug per level"},
	"nyx_mark":     {"name": "Marked Prey",   "family": "pilot", "rarity": "uncommon", "max": 5, "hero": "nyx", "pic": "res://gear/nightmare_weapon_t1.png",
		"desc": "Crit rate +10% per level"},
	"ember_burn":   {"name": "Afterburn",     "family": "pilot", "rarity": "uncommon", "max": 5, "hero": "ember", "pic": "res://gear/solar_weapon_t1.png",
		"desc": "Hits set bugs burning: 5% HP a second, longer per level"},
	# one-shot
	"nova_burst":      {"name": "Nova Burst",      "family": "wild",   "rarity": "legendary", "max": 1, "icon": "event",
		"desc": "Clears every enemy on screen (one use)"},
}

# Overcharge (battle.gd _overcharge).
# THE THREE TYPES (Rudy 2026-11-17). "off" = changes how you shoot (five levels, can EVOLVE),
# "def" = keeps the hero or the base alive, "pas" = a plain number. A card not listed is passive.
const TYPE := {
	"burst_fire": "off", "piercing_rounds": "off", "chain_spark": "off", "frost_rounds": "off", "split_shot": "off", "seeker": "off", "drone_barrage": "off",
	"rook_twin": "off", "sparks_weld": "off", "frost_freeze": "off", "hollow_phase": "off", "nyx_mark": "off", "ember_burn": "off", "nova_burst": "off",
	"aegis": "def", "field_medic": "def", "reinforced_hull": "def", "shield_recharge": "def", "shield_surge": "def", "nanobots": "def", "stim_pack": "def", "plate_up": "def",
	"core_overload": "def", "second_wind": "def", "mirror_shell": "def",
}
const TYPE_NAME := {"off": "OFFENSE", "def": "DEFENSE", "pas": "PASSIVE"}
const TYPE_COLOR := {"off": Color(1.0, 0.5, 0.35), "def": Color(0.4, 0.75, 1.0), "pas": Color(0.55, 0.95, 0.6)}

static func type_of(id: String) -> String:
	return String(TYPE.get(id, "pas"))

const OVER_AT := 3
const OVERCHARGE := {
	"rapid_pulse":     "Overdrive: every 8 s, 3 s at double speed",
	"heavy_bolts":     "6th bolt hits x3",
	"burst_fire":      "Last burst bolt pierces",
	"piercing_rounds": "+25% damage per bug pierced",
	"chain_spark":     "Sparks hit twice as hard",
	"frost_rounds":    "Slowed bugs take +20% damage",
	"aegis":           "Heals 25 HP each new wave",
	"field_medic":     "1% health back every 1.5 s",
	"reinforced_hull": "Base shield +40",
	"shield_recharge": "Also slowly repairs the hull",
	"magnet":          "Each gem repairs 1 shield",
	"shield_surge":    "Hits on the shield are 15% weaker",
	"nanobots":        "Mending after a wave is doubled",
	"hot_rounds":      "Crit damage +30%",
	"stim_pack":       "Once a fight, a blow that would down you leaves you standing",
	"plate_up":        "Runners that get through do half damage",
	"drone_uplink":    "Drone damage +40% more",
	"reactor_surge":   "The ability is ready right now",
	"radar_sweep":     "A caught runner mends 3% of the shield",
	"rich_seam":       "Every wave cleared drops a pile of coins",
	"core_overload":   "The Core Pulse lasts 2 seconds longer",
	"focus_fire":      "Crit rate +10%",
	"salvage":         "Every 10th kill drops a part",
	"second_wind":     "Heals to full",
	"mirror_shell":    "The bolt flies on after the throw",
	"rook_twin":       "Twins hit +15% harder",
	"sparks_weld":     "EVERY bolt arcs",
	"frost_freeze":    "Shatter: a slowed bug that dies blasts its neighbours",
	"hollow_phase":    "+30% damage per bug passed",
	"nyx_mark":        "Crits hit x2.5",
	"ember_burn":      "A burning bug that dies spreads the fire",
	"split_shot":      "Side shots hit almost as hard as the main one",
	"seeker":          "Crit rate +10%",
	"drone_barrage":   "Drone damage +60% more",
	"killer_instinct": "Crit rate +8%",
}

# EVOLUTIONS (Rudy 2026-11-17, in place of the fusions; the table keeps its old name because the
# fight, the HUD row and the pause list already treat its entries as the special gold cards).
# "parts" = [the offensive card, its PARTNER]. The offensive card at its top level plus ONE level
# of the partner (a passive OR a defensive card, mixed so both kinds get picked) puts EVOLVE in the
# next pick: a new named form on top of the card (battle.gd _fuse). Defensive cards do not evolve.
const FUSIONS := {
	"storm_volley":  {"name": "Storm Volley",  "parts": ["burst_fire", "rapid_pulse"], "rarity": "fusion", "max": 1,
		"desc": "Bursts grow by two shots and fire faster"},
	"railstorm":     {"name": "Railshot",      "parts": ["piercing_rounds", "killer_instinct"], "rarity": "fusion", "max": 1,
		"desc": "Every 4th shot is a rail: through the whole line, twice as hard"},
	"thunder_lance": {"name": "Thunder Lance", "parts": ["chain_spark", "heavy_bolts"], "rarity": "fusion", "max": 1,
		"desc": "Every bug a shot passes through throws sparks"},
	"flak_wall":     {"name": "Flak Wall",     "parts": ["split_shot", "reinforced_hull"], "rarity": "fusion", "max": 1,
		"desc": "Two more side shots, and shots you stop fly back at the bugs"},
	"gem_barrage":   {"name": "Hunter Swarm",  "parts": ["seeker", "magnet"], "rarity": "fusion", "max": 1,
		"desc": "Every 10 gems fire 6 shots at the nearest bugs"},
	"guardian_wing": {"name": "Guardian Wing", "parts": ["drone_barrage", "shield_recharge"], "rarity": "fusion", "max": 1,
		"desc": "The drone hits far harder and its fire mends the shield"},
	# the six heroes: his own card with Aegis becomes his signature
	"sig_rook":   {"name": "Crossfire",     "parts": ["rook_twin", "aegis"], "rarity": "fusion", "max": 1, "desc": "Damage +25%, and hits on him are 15% weaker"},
	"sig_sparks": {"name": "Storm Coil",    "parts": ["sparks_weld", "aegis"], "rarity": "fusion", "max": 1, "desc": "Damage +25%, and hits on him are 15% weaker"},
	"sig_frost":  {"name": "Absolute Zero", "parts": ["frost_freeze", "aegis"], "rarity": "fusion", "max": 1, "desc": "Damage +25%, and hits on him are 15% weaker"},
	"sig_hollow": {"name": "Event Horizon", "parts": ["hollow_phase", "aegis"], "rarity": "fusion", "max": 1, "desc": "Damage +25%, and hits on him are 15% weaker"},
	"sig_nyx":    {"name": "Blood Moon",    "parts": ["nyx_mark", "aegis"], "rarity": "fusion", "max": 1, "desc": "Damage +25%, and hits on her are 15% weaker"},
	"sig_ember":  {"name": "Inferno",       "parts": ["ember_burn", "aegis"], "rarity": "fusion", "max": 1, "desc": "Damage +25%, and hits on her are 15% weaker"},
}

# what each pick of a FIVE-LEVEL card gives (index = picks so far); the fifth shows its OVERCHARGE line
const STEPS5 := {
	"burst_fire": ["2-shot bursts", "3-shot bursts", "Bursts fire closer together", "4-shot bursts"],
	"piercing_rounds": ["Shots pierce 1 bug", "Shots pierce 2 bugs", "Shot damage +6%", "Shots pierce 3 bugs"],
	"chain_spark": ["Every 5th shot chains to 1 bug", "Chains to 2 bugs", "Every 4th shot chains", "Chains to 3 bugs"],
	"split_shot": ["A side shot every 4th volley", "Every 3rd volley", "2 side shots", "Every 2nd volley"],
	"seeker": ["Shots curve toward bugs, damage +5%", "Curve harder, damage +5%", "Curve harder, damage +5%", "Curve harder, damage +5%"],
	"drone_barrage": ["Drone damage x2", "Drone damage x3", "Drone damage x4", "Drone damage x5"],
	"rook_twin": ["Every 4th shot fires twice", "Every 3rd shot fires twice", "Twins hit 40% harder", "Every 2nd shot fires twice"],
	"sparks_weld": ["Every 3rd shot arcs to 1 bug", "Arcs to 2 bugs", "Every 2nd shot arcs", "Arcs to 3 bugs"],
	"frost_freeze": ["Hits slow bugs 12%", "Hits slow bugs 24%", "Hits slow bugs 36%", "Hits slow bugs 48%"],
	"hollow_phase": ["Shots pierce 1 bug", "Shots pierce 2 bugs", "Shot damage +6%", "Shots pierce 3 bugs"],
	"nyx_mark": ["Crit rate +8%, crits 15% harder", "Crit rate +8%, crits 15% harder", "Crit rate +8%, crits 15% harder", "Crit rate +8%, crits 15% harder"],
	"ember_burn": ["Hits set bugs burning", "Burns last longer", "Burns last longer", "Burns last longer"],
}
const OVERCHARGE5 := {"burst_fire": "The last shot of a burst pierces", "rook_twin": "Twins hit 80% harder", "frost_freeze": "Slow 60%, and a slowed bug that dies blasts its neighbours"}


# the fusion a card is a part of ("" when none): the CHAIN tag on its card (dev199)
# What THIS pick gives, in one short line (Rudy, dev209: no "then 3, then 4", nothing about later
# picks). Index = picks taken so far. The overcharge pick shows its OVERCHARGE line instead.
const STEPS := {
	"rapid_pulse": ["Fire rate +10%"], "heavy_bolts": ["Bolt damage +15%"],
	"burst_fire": ["2-bolt bursts", "3-bolt bursts", "4-bolt bursts"],
	"piercing_rounds": ["Bolts pierce 1 bug", "Bolts pierce 2 bugs", "Bolts pierce 3 bugs"],
	"chain_spark": ["Every 5th bolt chains to 1 bug", "Chains to 2 bugs", "Chains to 3 bugs"],
	"frost_rounds": ["Hits slow bugs 15%", "Hits slow bugs 30%", "Hits slow bugs 45%"],
	"aegis": ["+30 HP and a light shield"],
	"field_medic": ["1% health back every 5 s", "1% health back every 3 s"],
	"reinforced_hull": ["Base shield +30, hull +20"],
	"shield_recharge": ["Shield heals 1% a second", "Shield heals 2% a second", "Shield heals 3% a second"],
	"magnet": ["Wider magnet, XP +10%"],
	"shield_surge": ["Base shield +25, repaired now"], "nanobots": ["Hull mends 0.4% a second", "Hull mends 0.8% a second"],
	"hot_rounds": ["Bolt damage +8%"], "stim_pack": ["+15 max HP, 25 HP healed"], "plate_up": ["Hull +25, base hits 4% weaker"],
	"drone_uplink": ["Drone damage +20%"], "reactor_surge": ["Ability charges 10% faster"], "radar_sweep": ["Crit rate +5%"],
	"rich_seam": ["Coins +15%"], "core_overload": ["Core Pulse recharges 20% faster"],
	"focus_fire": ["Bolt damage +6%"], "salvage": ["Bugs drop +25% coins"],
	"second_wind": ["Once a run: survive a hit at 50% HP", "Survive at 75% HP", "Survive at full HP"],
	"mirror_shell": ["Stopped shots fly back (50%)", "Fly back at 75%", "Fly back at full damage"],
	"rook_twin": ["Every 4th bolt fires twice", "Every 3rd bolt fires twice", "Every 2nd bolt fires twice"],
	"sparks_weld": ["Every 3rd bolt arcs to 1 bug", "Arcs to 2 bugs", "Arcs to 3 bugs"],
	"frost_freeze": ["Hits slow bugs 20%", "Hits slow bugs 40%", "Hits slow bugs 60%"],
	"hollow_phase": ["Bolts pierce 1 bug", "Bolts pierce 2 bugs", "Bolts pierce 3 bugs"],
	"nyx_mark": ["Crit rate +10%"], "ember_burn": ["Hits set bugs burning", "Burns last longer", "Burns last even longer"],
}

# AN OFFENSIVE CARD READS DIFFERENTLY PER WEAPON (agreed with Rudy 2026-11-13). Keyed by the shot
# shape of the weapon in hand (Shots.SHAPE: ball = twin pistols, stream = rifle, boulder = launcher;
# the pistol s pellet uses the plain lines above). battle.gd does the same split in _fire.
const CLASS_STEPS := {
	"burst_fire": {
		"ball": ["Both pistols throw a 2nd ball", "A 3rd ball each volley", "Volleys come faster", "A 4th ball each volley"],
		"stream": ["The stream surges: fire rate +48%", "Fire rate +19% more", "Fire rate +9% more", "Fire rate +13% more"],
		"boulder": ["A small second shell", "A third small shell", "Small shells hit harder", "A fourth small shell"],
	},
}
const CLASS_OVER := {
	"burst_fire": {"ball": "The extra balls pierce", "stream": "Every 4th stream shot pierces", "boulder": "The small shells pierce"},
}

static func pick_text(id: String, picks_so_far: int, shape: String = "") -> String:
	if CLASS_STEPS.has(id) and CLASS_STEPS[id].has(shape):
		var sc: Array = CLASS_STEPS[id][shape]
		return String(sc[mini(picks_so_far, sc.size() - 1)])
	if STEPS5.has(id):
		var s5: Array = STEPS5[id]
		return String(s5[mini(picks_so_far, s5.size() - 1)])
	if STEPS.has(id):
		var s: Array = STEPS[id]
		return String(s[mini(picks_so_far, s.size() - 1)])
	return String(def(id).desc)

static func chain_of(id: String) -> String:
	for f in FUSIONS:
		if Array(FUSIONS[f].parts).has(id):
			return f
	return ""

# the pick on which a card overcharges: the 3rd, or the last for cards that stop sooner
static func over_level(id: String) -> int:
	return int(CARDS[id].max)   # the LAST pick: the 3rd for a three-level card, the 5th for an offensive one

# true when picking this card now (it has `lvl` picks so far) overcharges it
static func overcharges(id: String, lvl: int) -> bool:
	return OVERCHARGE.has(id) and lvl + 1 == over_level(id)

static func overcharged(levels: Dictionary, id: String) -> bool:
	return OVERCHARGE.has(id) and int(levels.get(id, 0)) >= over_level(id)

# a card or a fusion
static func def(id: String) -> Dictionary:
	return CARDS[id] if CARDS.has(id) else FUSIONS[id]

# the line the top pick of a card shows
static func over_text(id: String, shape: String = "") -> String:
	if CLASS_OVER.has(id) and CLASS_OVER[id].has(shape):
		return String(CLASS_OVER[id][shape])
	return String(OVERCHARGE5.get(id, OVERCHARGE.get(id, "")))

# UNLOCKED OVER THE GAME (Rudy 2026-11-18): a new hero starts with a few basic cards and ONE
# evolution, his own; more open as HE levels up. A card not listed is open from level 1 (the
# hero s own card, and the base and talent cards, which have their own conditions).
const UNLOCK := {
	"burst_fire": 2, "magnet": 3, "reinforced_hull": 3, "piercing_rounds": 5, "field_medic": 8, "chain_spark": 8,
	"split_shot": 10, "killer_instinct": 12, "shield_recharge": 12, "seeker": 15, "frost_rounds": 18, "drone_barrage": 18, "nova_burst": 20,
}
const EVO_UNLOCK := {"storm_volley": 5, "railstorm": 10, "thunder_lance": 15, "flak_wall": 20, "gem_barrage": 25, "guardian_wing": 30}
const EVO_EVERY := 3   # every third hero card taken in a fight earns an evolution pick

static func unlock_level(id: String) -> int:
	return int(EVO_UNLOCK.get(id, 1)) if FUSIONS.has(id) else int(UNLOCK.get(id, 1))

# a HERO card = anything that is not a building s card; three of them earn an evolution
static func is_hero_card(id: String) -> bool:
	return CARDS.has(id) and not CARDS[id].has("building") or id == "drone_barrage"

# the evolutions this hero can be offered now: unlocked at his level, his own signature only,
# the drone one only with a drone, none twice in a fight
static func evos_open(hero: String, hero_level: int, levels: Dictionary, has_drone: bool = true) -> Array:
	var out: Array = []
	for f in FUSIONS:
		if levels.has(f) or unlock_level(f) > hero_level:
			continue
		if String(f).begins_with("sig_") and String(f) != "sig_" + hero:
			continue
		if String(f) == "guardian_wing" and not has_drone:
			continue
		out.append(f)
	return out

# the evolution this card is the offensive part of ("" when none), and its partner
static func evolves_to(id: String) -> String:
	for f in FUSIONS:
		if String(FUSIONS[f].parts[0]) == id:
			return f
	return ""

static func partner_of(id: String) -> String:
	var f := evolves_to(id)
	return String(FUSIONS[f].parts[1]) if f != "" else ""

# evolutions on offer: the offensive card at its top level, one level of the partner, not taken yet
static func fusions_ready(levels: Dictionary) -> Array:
	var out: Array = []
	for f in FUSIONS:
		var off: String = FUSIONS[f].parts[0]
		if not levels.has(f) and CARDS.has(off) and int(levels.get(off, 0)) >= int(CARDS[off].max) and int(levels.get(FUSIONS[f].parts[1], 0)) >= 1:
			out.append(f)
	return out

# A card you already hold comes up more often, and so does the partner of an offensive card you
# hold: with about 19 picks a stage, a build has to be able to come together.
static func _weight(levels: Dictionary, id: String) -> float:
	var w := float(WEIGHTS[CARDS[id].rarity])
	if int(levels.get(id, 0)) > 0:
		w *= 3.0 if type_of(id) == "off" else 1.6
	return w

# Pick `count` distinct cards from the pool, weighted by rarity, skipping maxed ones.
# run_level: cards with "from_level" only show up from that run level on.
# mounted: the turret types on the base (turret cards need theirs). hero: the hero on duty
# (his own card only shows up for him).
static func draw(levels: Dictionary, count: int = 3, rng: RandomNumberGenerator = null, run_level: int = 99, has_turret: bool = true, mounted: Array = [], hero: String = "", talents: int = 99, hero_level: int = 99) -> Array:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var pool: Array = []
	for id in CARDS:
		if int(levels.get(id, 0)) < int(CARDS[id].max) and unlock_level(id) <= hero_level and run_level >= int(CARDS[id].get("from_level", 1)) and (has_turret or not CARDS[id].get("needs_turret", false)) and (not CARDS[id].has("building") or mounted.has(CARDS[id].building)) and (not CARDS[id].has("hero") or String(CARDS[id].hero) == hero) and talents >= int(CARDS[id].get("talent", 0)):   # talent cards: the map's node must be bought (dev197)
			pool.append(id)
	var picks: Array = []
	while picks.size() < count and pool.size() > 0:
		var total := 0.0
		for id in pool:
			total += _weight(levels, id)
		var r := rng.randf() * total
		var chosen: String = pool[pool.size() - 1]
		for id in pool:
			r -= _weight(levels, id)
			if r <= 0.0:
				chosen = id
				break
		picks.append(chosen)
		pool.erase(chosen)
	return picks

# the hero's own card ("" when he has none)
static func hero_card(hero: String) -> String:
	for id in CARDS:
		if String(CARDS[id].get("hero", "")) == hero:
			return id
	return ""
