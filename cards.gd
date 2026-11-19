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
	# FIVE NEW CARDS (Rudy 2026-11-18, from his ideas): a kill meter, a bouncing shot, a bursting kill, and two trade-offs
	"overdrive":       {"name": "Overdrive",       "family": "pilot",  "rarity": "uncommon",  "max": 5, "pic": "res://icons/chip_over.png",
		"desc": "Kills fill a meter; when it is full you fire charged shots for a few seconds"},
	"ricochet":        {"name": "Ricochet",        "family": "pilot",  "rarity": "uncommon",  "max": 5, "pic": "res://icons/chip_arc.png",
		"desc": "A shot that hits bounces on to the next bug"},
	"shrapnel":        {"name": "Shrapnel",        "family": "pilot",  "rarity": "uncommon",  "max": 5, "pic": "res://icons/chip_frag.png",
		"desc": "A bug you kill bursts into shards that hit its neighbours"},
	"hair_trigger":    {"name": "Hair Trigger",    "family": "pilot",  "rarity": "common",    "max": 3, "pic": "res://icons/st_rate.png",
		"desc": "Much faster fire, a little less damage a shot"},
	"heavy_caliber":   {"name": "Heavy Caliber",   "family": "pilot",  "rarity": "common",    "max": 3, "pic": "res://icons/st_atk.png",
		"desc": "Much bigger hits, a little slower fire"},
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
	# BASE CARDS (Rudy 2026-11-18): ONE per building, taken ONCE ("max": 1, "bcard"), offered only while
	# that building stands ("building"), from in-fight level 4 ("from_level"), never two in one pick
	# (draw). Each changes what the building DOES; no "+5%" filler. "*pulse" = the Core Pulse is open.
	"reflective_barrier": {"name": "Reflective Barrier", "family": "base", "rarity": "epic", "max": 1, "bcard": true, "from_level": 4, "building": "shield_gen", "pic": "res://base/bld_shield_gen.png",
		"desc": "Each hit the shield takes fires a bolt back"},
	"field_repairs":      {"name": "Field Repairs",      "family": "base", "rarity": "epic", "max": 1, "bcard": true, "from_level": 4, "building": "repair_bay", "pic": "res://base/bld_repair_bay.png",
		"desc": "Every 25 kills mend 2% of the shield"},
	"full_magazine":      {"name": "Full Magazine",      "family": "base", "rarity": "epic", "max": 1, "bcard": true, "from_level": 4, "building": "armory", "pic": "res://base/bld_armory.png",
		"desc": "+15% damage while the shield is above 80%"},
	"low_orbit_care":     {"name": "Low Orbit Care",     "family": "base", "rarity": "epic", "max": 1, "bcard": true, "from_level": 4, "building": "medbay", "pic": "res://base/bld_medbay.png",
		"desc": "Fly close to the base: 1% health every 2 s"},
	"spiked_hull":        {"name": "Spiked Hull",        "family": "base", "rarity": "epic", "max": 1, "bcard": true, "from_level": 4, "building": "plating", "pic": "res://base/bld_plating.png",
		"desc": "A bug that hits the base blasts the bugs near it"},
	"guard_wing":         {"name": "Guard Wing",         "family": "base", "rarity": "epic", "max": 1, "bcard": true, "from_level": 4, "building": "hangar", "pic": "res://base/bld_hangar.png",
		"desc": "The Hangar shoots bugs that come near the base"},
	"arc_tether":         {"name": "Arc Tether",         "family": "base", "rarity": "epic", "max": 1, "bcard": true, "from_level": 4, "building": "reactor", "pic": "res://base/bld_reactor.png",
		"desc": "Fly close to the base: fire rate +12%"},
	"target_lock":        {"name": "Target Lock",        "family": "base", "rarity": "epic", "max": 1, "bcard": true, "from_level": 4, "building": "radar", "pic": "res://base/bld_radar.png",
		"desc": "The first 3 bugs of a wave are marked: every hit crits"},
	"coolant_vent":       {"name": "Coolant Vent",       "family": "base", "rarity": "epic", "max": 1, "bcard": true, "from_level": 4, "building": "refinery", "pic": "res://base/bld_refinery.png",
		"desc": "Bugs close to the base are slowed 25%"},
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
	"burst_fire": "off", "piercing_rounds": "off", "chain_spark": "off", "frost_rounds": "off", "split_shot": "off", "seeker": "off", "drone_barrage": "off", "overdrive": "off", "ricochet": "off", "shrapnel": "off",
	"rook_twin": "off", "sparks_weld": "off", "frost_freeze": "off", "hollow_phase": "off", "nyx_mark": "off", "ember_burn": "off", "nova_burst": "off",
	"aegis": "def", "field_medic": "def", "reinforced_hull": "def", "shield_recharge": "def", "reflective_barrier": "def", "field_repairs": "def", "low_orbit_care": "def", "spiked_hull": "def", "coolant_vent": "def",
	"core_overload": "def", "second_wind": "def", "mirror_shell": "def",
}
const TYPE_NAME := {"off": "OFFENSE", "def": "DEFENSE", "pas": "PASSIVE", "base": "BASE"}
const TYPE_COLOR := {"off": Color(1.0, 0.5, 0.35), "def": Color(0.4, 0.75, 1.0), "pas": Color(0.55, 0.95, 0.6), "base": Color(0.36, 0.9, 0.92)}

# BUILDINGS AS CARDS (Rudy 2026-11-18): the base is built DURING the fight. A building the player owns
# comes up as the card "bld:<id>": the first pick places it on the next free pod, each further pick
# strengthens it (BLD_MAX picks in all). Any three building cards earn a building evolution,
# "bevo:<id>", for a building that stands. These ids are not in CARDS; def() answers for them.
const BLD_MAX := 4
const BLD_COLOR := Color(0.36, 0.9, 0.92)
const BEVO := {
	"shield_gen": "Aegis Dome", "repair_bay": "Nanoforge", "armory": "War Forge", "medbay": "Trauma Ward", "plating": "Bastion Plate",
	"hangar": "Carrier Deck", "reactor": "Overdrive Core", "radar": "Deep Scan", "refinery": "Mother Lode",
}
# the old base card whose top-level effect a building s last upgrade brings (battle.gd _overcharge)
const BLD_OVER := {"shield_gen": "shield_surge", "repair_bay": "nanobots", "armory": "hot_rounds", "medbay": "stim_pack", "plating": "plate_up",
	"hangar": "drone_uplink", "reactor": "reactor_surge", "radar": "radar_sweep", "refinery": "rich_seam"}

# BONDS (Rudy 2026-11-18): a building on the base + its paired attack card at BOND_AT levels = a
# special evolution on the next evolution pick (never among the normal three). One per building.
# The hero's element flavours what a bond fires (battle _bond_flavour).
const BOND_AT := 3
const BONDS := {
	"mirror_dome":    {"name": "Mirror Dome",    "building": "shield_gen", "card": "ricochet",        "desc": "Bolts the shield fires back bounce on to 3 more bugs"},
	"overhaul":       {"name": "Overhaul",       "building": "repair_bay", "card": "overdrive",       "desc": "Each time Overdrive fires, the shield gets 5% back"},
	"arsenal_volley": {"name": "Arsenal Volley", "building": "armory",     "card": "burst_fire",      "desc": "Every 4th shot fires twice"},
	"mending_volley": {"name": "Mending Volley", "building": "medbay",     "card": "split_shot",      "desc": "Side shots give a little health back on each hit"},
	"bastion_rounds": {"name": "Bastion Rounds", "building": "plating",    "card": "piercing_rounds", "desc": "Piercing shots shove every bug they pass back"},
	"carrier_strike": {"name": "Carrier Strike", "building": "hangar",     "card": "drone_barrage",   "desc": "Every 6 s the Hangar launches 4 missiles"},
	"lightning_rod":  {"name": "Lightning Rod",  "building": "reactor",    "card": "chain_spark",     "desc": "Every 10th shot arcs from you to the base, hitting what is between"},
	"hunter_net":     {"name": "Hunter Net",     "building": "radar",      "card": "seeker",          "desc": "A marked bug that dies passes its mark to the nearest bug"},
	"fallout":        {"name": "Fallout",        "building": "refinery",   "card": "shrapnel",        "desc": "Shards carry the dead bug's burn or chill to the bugs they hit"},
}

# the bonds that can be offered now: the building stands, the paired card has BOND_AT levels, not taken yet
static func bonds_open(levels: Dictionary, fielded: Array) -> Array:
	var out: Array = []
	for id in BONDS:
		if not levels.has(id) and fielded.has(String(BONDS[id].building)) and int(levels.get(String(BONDS[id].card), 0)) >= BOND_AT:
			out.append(id)
	return out

# the bond this card is working toward with a building that stands ("" when none, or already taken)
static func bond_of(card: String, levels: Dictionary, fielded: Array) -> String:
	for id in BONDS:
		if String(BONDS[id].card) == card and fielded.has(String(BONDS[id].building)) and not levels.has(id):
			return id
	return ""

static func is_bld(id: String) -> bool:
	return id.begins_with("bld:")

static func is_bevo(id: String) -> bool:
	return id.begins_with("bevo:")

static func is_evo(id: String) -> bool:
	return FUSIONS.has(id) or BONDS.has(id) or is_bevo(id)

static func bld_id(id: String) -> String:
	return id.get_slice(":", 1)

static func type_of(id: String) -> String:
	if is_bld(id) or is_bevo(id):
		return "base"
	return String(TYPE.get(id, "pas"))

const OVER_AT := 3
const OVERCHARGE := {
	"rapid_pulse":     "Surge: every 8 s, 3 s at double speed",
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
	"overdrive":       "Charged shots pierce",
	"ricochet":        "Bounces lose no damage",
	"shrapnel":        "Bugs killed by shards burst too",
	"hair_trigger":    "Fire rate +20%, nothing lost",
	"heavy_caliber":   "Damage +28%, and hits shove bugs back",
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
		"desc": "Every 5 seconds he holds a beam: it burns every bug in the column above him"},
	"thunder_lance": {"name": "Thunder Lance", "parts": ["chain_spark", "heavy_bolts"], "rarity": "fusion", "max": 1,
		"desc": "Hits plant a lightning rod in the bug: it arcs to every bug around it"},
	"flak_wall":     {"name": "Flak Wall",     "parts": ["split_shot", "reinforced_hull"], "rarity": "fusion", "max": 1,
		"desc": "Two more side shots, and a wall of flak hangs above him: bugs that cross it are hurt and slowed"},
	"gem_barrage":   {"name": "Hunter Swarm",  "parts": ["seeker", "magnet"], "rarity": "fusion", "max": 1,
		"desc": "Every 4th shot is a hunter: it latches on, drills, and jumps to the next bug"},
	"guardian_wing": {"name": "Guardian Wing", "parts": ["drone_barrage", "shield_recharge"], "rarity": "fusion", "max": 1,
		"desc": "The drone hits far harder and its fire mends the shield"},
	"afterburner":   {"name": "Afterburner",   "parts": ["overdrive", "hair_trigger"], "rarity": "fusion", "max": 1,
		"desc": "Overdrive lasts longer and he leaves a burning wake: bugs that cross it catch fire"},
	"cluster_storm": {"name": "Cluster Storm", "parts": ["shrapnel", "heavy_caliber"], "rarity": "fusion", "max": 1,
		"desc": "Dead bugs burst into shards that hunt the nearest bugs and burst them too"},
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
	"overdrive": ["30 kills charge 4 s of double-damage shots", "Charges in 25 kills", "Lasts 5.5 s", "Charges in 20 kills"],
	"ricochet": ["Shots bounce on to 1 more bug", "Bounce on to 2 bugs", "Bounces keep more of their hit", "Bounce on to 3 bugs"],
	"shrapnel": ["A kill throws 4 shards", "Shards hit harder", "6 shards", "Shards hit harder"],
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
	"hair_trigger": ["Fire rate +20%, damage -8%"], "heavy_caliber": ["Damage +28%, fire rate -10%"],
	"burst_fire": ["2-bolt bursts", "3-bolt bursts", "4-bolt bursts"],
	"piercing_rounds": ["Bolts pierce 1 bug", "Bolts pierce 2 bugs", "Bolts pierce 3 bugs"],
	"chain_spark": ["Every 5th bolt chains to 1 bug", "Chains to 2 bugs", "Chains to 3 bugs"],
	"frost_rounds": ["Hits slow bugs 15%", "Hits slow bugs 30%", "Hits slow bugs 45%"],
	"aegis": ["+30 HP and a light shield"],
	"field_medic": ["1% health back every 5 s", "1% health back every 3 s"],
	"reinforced_hull": ["Base shield +30, hull +20"],
	"shield_recharge": ["Shield heals 1% a second", "Shield heals 2% a second", "Shield heals 3% a second"],
	"magnet": ["Wider magnet, XP +10%"],
	"core_overload": ["Core Pulse recharges 20% faster"],
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
	"ricochet": {"stream": ["Every 3rd stream shot bounces to 1 more bug", "Bounces on to 2 bugs", "Bounces keep more of their hit", "Bounces on to 3 bugs"]},
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
	return CARDS.has(id) and OVERCHARGE.has(id) and lvl + 1 == over_level(id)

static func overcharged(levels: Dictionary, id: String) -> bool:
	return CARDS.has(id) and OVERCHARGE.has(id) and int(levels.get(id, 0)) >= over_level(id)

# a card or a fusion
static func def(id: String) -> Dictionary:
	if is_bld(id):
		var b: Dictionary = Base.BUILDINGS[bld_id(id)]
		return {"name": String(b.name), "desc": String(b.kind) + " building", "max": BLD_MAX, "rarity": "uncommon", "pic": "res://base/bld_%s.png" % bld_id(id)}
	if is_bevo(id):
		return {"name": String(BEVO[bld_id(id)]), "desc": "Gives twice as much, and its special power is on", "max": 1, "rarity": "fusion", "pic": "res://base/bld_%s.png" % bld_id(id)}
	if BONDS.has(id):
		return {"name": String(BONDS[id].name), "desc": String(BONDS[id].desc), "max": 1, "rarity": "fusion", "pic": "res://base/bld_%s.png" % String(BONDS[id].building)}
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
	"hair_trigger": 6, "heavy_caliber": 9, "overdrive": 14, "ricochet": 20, "shrapnel": 25,
	"split_shot": 10, "killer_instinct": 12, "shield_recharge": 12, "seeker": 15, "frost_rounds": 18, "drone_barrage": 18, "nova_burst": 20,
}
const EVO_UNLOCK := {"storm_volley": 5, "railstorm": 10, "thunder_lance": 15, "flak_wall": 20, "gem_barrage": 25, "afterburner": 22, "cluster_storm": 28, "guardian_wing": 30}
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
		if CARDS[chosen].get("bcard", false):   # never two base cards in one pick
			pool = pool.filter(func(c): return not CARDS[c].get("bcard", false))
	return picks

# the hero's own card ("" when he has none)
static func hero_card(hero: String) -> String:
	for id in CARDS:
		if String(CARDS[id].get("hero", "")) == hero:
			return id
	return ""
