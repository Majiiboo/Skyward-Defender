class_name StageData
extends RefCounted
# Everything about stages in one place: areas and zones (the look and story per 10 and
# per 5 stages), enemy definitions, and the wave list for a stage. Tune numbers here,
# not in battle.gd.

# ---- areas (ROADMAP 1.0): a planet every 10 stages, ending with its boss. Each area has
# two zones of 5 stages (A in orbit, B down at the surface; a mini-boss ends zone A), so
# the painted world changes every 5 stages and the planet every 10. "brief" is the comms
# message shown the first time you reach the area. Later areas reuse the Hive bugs until
# their own enemy families are painted (LUNA-BRIEF-areas.md).
const AREAS := [
	{"name": "Hive World", "boss": "Hive Mother",
		"brief": "Pilot, the swarms come from this planet. Hold the base, thin the swarm, and find the Hive Mother."},
	{"name": "Scrap Belt", "boss": "Hive Mother",
		"brief": "A ring of wrecked ships. The bugs nest in the junk: watch for anything that moves in the debris."},
	{"name": "Magma World", "boss": "Hive Mother",
		"brief": "The crust is cracking. Heat haze, ash and bugs that thrive in it. Keep your shield up."},
	{"name": "Crystal World", "boss": "Hive Mother",
		"brief": "Frozen seas and crystal spires. Beautiful, and full of things that want you gone."},
	{"name": "Plasma Storm", "boss": "Hive Mother",
		"brief": "A gas giant wrapped in lightning. The storm charges them up: stay sharp."},
	{"name": "Sentinel World", "boss": "Hive Mother",
		"brief": "A dead machine planet. Something here is still awake, and it has been waiting for us."},
]

# Zones: 5 stages each, two per area. Colours tint the sky, rim and shield (used only if a
# zone has no painting); "bg" is Luna's painted world (backdrops/<bg>.webp).
const SECTORS := [
	{"name": "Ember Reach", "stages": ["Ember Reach", "Nova Drift", "Cinder Belt", "Halo Verge", "Ion Fields"],
		"sky_top": Color(0.04, 0.07, 0.20), "sky_bot": Color(0.012, 0.016, 0.045), "rim": Color(0.15, 0.55, 0.95), "glow": Color(0.1, 0.4, 0.8), "bg": "hive_a"},
	{"name": "Glow Caverns", "stages": ["Shard Field", "Ring Gap", "Dust Veil", "Ashen Moon", "Broken Crown"],
		"sky_top": Color(0.10, 0.07, 0.18), "sky_bot": Color(0.02, 0.015, 0.04), "rim": Color(0.55, 0.45, 0.95), "glow": Color(0.35, 0.25, 0.7), "bg": "hive_b"},
	{"name": "Wreck Ring", "stages": ["Hull Drift", "Rust Field", "Torn Keel", "Salvage Gate", "Iron Graves"],
		"sky_top": Color(0.06, 0.06, 0.09), "sky_bot": Color(0.01, 0.01, 0.02), "rim": Color(0.8, 0.55, 0.3), "glow": Color(0.4, 0.3, 0.2), "bg": "scrap"},
	{"name": "Junk Tide", "stages": ["Scrap Wake", "Gear Storm", "Bent Spire", "Dead Dock", "Breaker Yard"],
		"sky_top": Color(0.06, 0.06, 0.09), "sky_bot": Color(0.01, 0.01, 0.02), "rim": Color(0.8, 0.55, 0.3), "glow": Color(0.4, 0.3, 0.2), "bg": "scrap"},
	{"name": "Cinder Belt", "stages": ["Lava Seam", "Ash Plain", "Pyre Ridge", "Smolder Deep", "Furnace Gate"],
		"sky_top": Color(0.20, 0.07, 0.04), "sky_bot": Color(0.04, 0.012, 0.01), "rim": Color(1.0, 0.5, 0.2), "glow": Color(0.8, 0.3, 0.1), "bg": "magma"},
	{"name": "Furnace Deep", "stages": ["Ember Vent", "Molten Run", "Slag Crown", "Caldera", "Heart of Fire"],
		"sky_top": Color(0.20, 0.07, 0.04), "sky_bot": Color(0.04, 0.012, 0.01), "rim": Color(1.0, 0.5, 0.2), "glow": Color(0.8, 0.3, 0.1), "bg": "magma"},
	{"name": "Halo Verge", "stages": ["Frost Spire", "Glass Sea", "Rime Hollow", "Crystal Reach", "White Ring"],
		"sky_top": Color(0.06, 0.14, 0.22), "sky_bot": Color(0.01, 0.03, 0.05), "rim": Color(0.6, 0.95, 1.0), "glow": Color(0.3, 0.7, 0.9), "bg": "crystal"},
	{"name": "Prism Depths", "stages": ["Shard Maze", "Mirror Lake", "Cold Light", "Facet Gorge", "Crystal Throne"],
		"sky_top": Color(0.06, 0.14, 0.22), "sky_bot": Color(0.01, 0.03, 0.05), "rim": Color(0.6, 0.95, 1.0), "glow": Color(0.3, 0.7, 0.9), "bg": "crystal"},
	{"name": "Ion Fields", "stages": ["Storm Edge", "Thunderhead", "Static Sea", "Charge Belt", "Eye of Ion"],
		"sky_top": Color(0.10, 0.05, 0.22), "sky_bot": Color(0.01, 0.03, 0.02), "rim": Color(0.6, 0.9, 0.5), "glow": Color(0.5, 0.2, 0.9), "bg": "plasma"},
	{"name": "Storm Crown", "stages": ["Arc Fall", "Pulse Line", "Volt Rift", "Sky Furnace", "Crown of Storms"],
		"sky_top": Color(0.10, 0.05, 0.22), "sky_bot": Color(0.01, 0.03, 0.02), "rim": Color(0.6, 0.9, 0.5), "glow": Color(0.5, 0.2, 0.9), "bg": "plasma"},
	{"name": "Null Reach", "stages": ["Dead Grid", "Silent Core", "Null Gate", "Last Array", "Cold Signal"],
		"sky_top": Color(0.02, 0.02, 0.05), "sky_bot": Color(0.0, 0.0, 0.01), "rim": Color(0.2, 1.0, 0.8), "glow": Color(0.1, 0.5, 0.5), "bg": "sentinel"},
	{"name": "Core Array", "stages": ["Black Lattice", "Echo Vault", "Prime Node", "Gate Zero", "The Sentinel"],
		"sky_top": Color(0.02, 0.02, 0.05), "sky_bot": Color(0.0, 0.0, 0.01), "rim": Color(0.2, 1.0, 0.8), "glow": Color(0.1, 0.5, 0.5), "bg": "sentinel"},
]
const MAX_STAGE := 60

# The zone a stage is in (5 stages each).
static func sector(stage: int) -> Dictionary:
	return SECTORS[clampi((stage - 1) / 5, 0, SECTORS.size() - 1)]

# The area (planet) a stage is in, 0-based, and the area data.
static func area_index(stage: int) -> int:
	return clampi((stage - 1) / 10, 0, AREAS.size() - 1)

static func area(stage: int) -> Dictionary:
	return AREAS[area_index(stage)]

# 1..10 inside the area
static func area_stage(stage: int) -> int:
	return (stage - 1) % 10 + 1

# "mini" ends zone A (stage 5 of an area), "boss" ends the area (stage 10), else "".
static func boss_kind(stage: int) -> String:
	var s := area_stage(stage)
	return "boss" if s == 10 else ("mini" if s == 5 else "")

static func stage_name(stage: int) -> String:
	var s := sector(stage)
	return s.stages[(stage - 1) % 5]

# ---- enemies: how each one looks and behaves. "move" is handled in battle.gd. ----
# hp/coins are stage-1 values; xp_tier 0..3 = shard/prism/ember/star (1/3/6/10 XP), -1 = no gem.
# base_dmg = what it does to the shield/hull if it reaches the base. intro = the line on
# the "new enemy" card the first time a player meets it (empty = no card).
# Roles (Rudy, 2026-11-03): Scout = the swarm, Drifter = the tank that bursts into spores,
# Spitter = the shooter (the one bug that attacks the pilot), Diver = kamikaze on the base.
const ENEMIES := {
	"scout":   {"tex": "res://enemies/scout.png",   "size": 34.0, "hp": 2.0, "speed": 62.0, "move": "flit",
		"xp_tier": 0, "coins": 1, "traits": ["swarm"], "base_dmg": 10.0,
		"intro": "Fast swarm bug. They come in numbers: keep firing!"},
	"drifter": {"tex": "res://enemies/drifter.png", "size": 44.0, "hp": 4.0, "speed": 48.0, "move": "scurve",
		"xp_tier": 0, "coins": 1, "traits": ["swarm", "fast"], "base_dmg": 13.0, "spores": 1,
		"intro": "Tough. Bursts into a spore when it dies: shoot that too!"},
	"spitter": {"tex": "res://enemies/spitter.png", "size": 38.0, "hp": 4.0, "speed": 40.0, "move": "hover",
		"xp_tier": 0, "coins": 2, "traits": ["shooter"], "fire_every": 3.4, "base_dmg": 14.0,
		"intro": "Spits goo at you. Slide out of the way!"},
	"diver":   {"tex": "res://enemies/diver.png",   "size": 36.0, "hp": 3.0, "speed": 55.0, "move": "dive",
		"xp_tier": 1, "coins": 2, "traits": ["fast"], "base_dmg": 13.0, "dive_mult": 2.0,
		"intro": "Locks on, then dives at your base. Shoot it before it lands!"},
	"hive_mother": {"tex": "res://enemies/hive_mother.png", "size": 120.0, "hp": 60.0, "speed": 22.0, "move": "boss",
		"xp_tier": 3, "coins": 40, "traits": ["boss"], "lay_every": 6.0, "base_dmg": 0.0, "launch_every": 7.0,
		"intro": "Lays eggs that hatch Scouts. Hit her while she lays: she is weak then!"},
	# spore pod from a dying Drifter: drifts down slowly; shoot it or it chips the shield
	"spore":   {"tex": "", "size": 16.0, "hp": 1.0, "speed": 34.0, "move": "spore",
		"xp_tier": -1, "coins": 0, "traits": ["swarm"], "base_dmg": 4.0, "intro": ""},
}

const GEM_XP := [2, 4, 7, 12]
const GEM_COLORS := [Color(0.29, 0.66, 1.0), Color(0.71, 0.55, 1.0), Color(1.0, 0.35, 0.42), Color(1.0, 0.83, 0.3)]

# ---- difficulty scaling per stage ----
static func hp_mult(stage: int, elite: bool) -> float:
	# gentle through the first planet (+7% a stage), a little steeper after it (+8%), when
	# the player has turrets and upgrades to answer with
	# (beyond the first planet +6% a stage; gear and turret upgrades carry the player there)
	return pow(1.07, mini(stage, 5) - 1) * pow(1.08, clampi(stage - 5, 0, 5)) * pow(1.06, maxi(stage - 10, 0)) * (1.85 if elite else 1.0)

static func speed_mult(stage: int) -> float:
	# stages 1-3 are the tutorial: slower bugs, building up to normal speed at stage 4
	var tutorial: float = [0.75, 0.85, 0.95][stage - 1] if stage <= 3 else 1.0
	return minf(1.0 + 0.03 * (stage - 1), 1.6) * tutorial

# How many enemies arrive together, and how often, while a wave is spawning.
static func group_size(stage: int) -> int:
	# one at a time in stage 1, pairs through the first planet, threes from stage 6
	return 1 if stage == 1 else (2 if stage <= 5 else 3)

static func spawn_gap(stage: int) -> float:
	return 2.0 if stage == 1 else (1.8 if stage <= 5 else 1.7)

static func wave_count(stage: int) -> int:
	# the first planet is the tutorial (5 then 8 waves); later planets 10 waves in zone A,
	# 12 in zone B, so a stage stays a few minutes long
	if stage <= 5:
		return 5
	if stage <= 10:
		return 8
	return 10 if area_stage(stage) <= 5 else 12

# A wave = list of [enemy_id, count]. Enemies arrive one at a time over the wave.
static func waves(stage: int) -> Array:
	var out: Array = []
	var n := wave_count(stage)
	for w in range(1, n + 1):
		var wave: Array = []
		var extra: int = (stage - 1) / 2
		# tutorial stages start small: 3 scouts in stage 1 wave 1, growing each wave
		# later waves grow by about two bugs every three waves, so long stages stay fair
		wave.append(["scout", (2 + w) if stage == 1 else ((4 + w) if stage == 2 else 4 + (w * 2) / 3 + extra / 2)])
		if stage >= 2 and w >= 2:
			wave.append(["drifter", 1 + w / 3 + extra / 3])
		# Spitters make you move: from wave 3 of stage 3, more later
		if stage >= 3 and w >= (3 if stage == 3 else 2):
			wave.append(["spitter", 1 + (w - 1) / (4 if stage == 3 else 3) + extra / 4])
		if stage >= 4 and w >= 4:
			wave.append(["diver", 1 + (w - 3) / 4 + extra / 5])   # kamikazes: few, but they hit hard
		if stage % 5 == 0 and w == n:
			wave.append(["hive_mother", 1])
		out.append(wave)
	return out
