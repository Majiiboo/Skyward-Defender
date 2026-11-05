extends Node2D
# Skybound battle. Data lives in stage_data.gd (sectors, enemies, waves) and
# cards.gd (power cards); this file runs the fight.
#
# Loop: waves of enemies arrive from the top; the pilot flies where you drag
# and fires straight up, or auto-aims when your finger is lifted; kills drop XP
# gems; collecting gems fills the run level and offers 3 cards; mounted turrets
# help. Enemies that reach the force field hurt the shield, then the hull.
# Clear the last wave to win the stage.

const FIELD_W := 480.0
var FIELD_H := 800.0
var BASE_Y := 786.0
const DOME_RX := 300.0
const DOME_RY := 112.0
const PILOT_HEIGHT := 60.0
# How each turret sits on its socket: draw height and widest width (px), where its
# weapon tip is (fraction of the drawn height from the foot), a hover bob (px), and cx =
# the painted turret's visual centre across its picture (0.5 = middle), so it sits
# centred on the socket ring (measured from the art's weight, 2026-11-03).
const TURRET_LOOK := {
	"lance":   {"h": 92.0, "w": 60.0, "tip": 0.96, "bob": 0.0, "cx": 0.481},
	"storm":   {"h": 82.0, "w": 76.0, "tip": 0.90, "bob": 0.0, "cx": 0.479},
	"gravity": {"h": 66.0, "w": 84.0, "tip": 0.52, "bob": 2.0, "cx": 0.435},
	"swarm":   {"h": 72.0, "w": 72.0, "tip": 0.60, "bob": 2.5, "cx": 0.501},
	"prism":   {"h": 84.0, "w": 66.0, "tip": 0.74, "bob": 0.0, "cx": 0.441},
}
const STRIP_LIFT := 8.0            # the base strip's bottom sits this far above the screen's bottom edge
const SENTRY_BASE_W := 58.0
const SENTRY_HEAD_H := 66.0
const SENTRY_ART_DIR := -PI / 2.0 - 0.26    # the painted barrels point up and a little left
# The Sentry's gun head floats above its ring base, held up by a field: it hovers a
# few px clear, bobs and drifts, leans into its swings, and dips toward the base on
# each shot before springing back up. On landing it powers up and lifts off the base.
const SENTRY_GAP := 9.0
const SENTRY_HEAD_CX := 0.498              # centre of the head's lower body (the part over the base), not the leaning barrels
# charge-up glow colour at the weapon tip, for turrets that wait on a cooldown
const CHARGE_COL := {"storm": Color(0.71, 0.55, 1.0), "swarm": Color(1.0, 0.75, 0.3), "prism": Color(0.85, 0.9, 1.0)}
const FX_NAMES := ["sentry_tracer", "spark", "lance_flare", "lance_beam", "storm_zap", "gravity_ring", "crush", "drone", "pop", "prism_beam", "prism_burst", "bolt", "impact", "nova", "bolt_rail", "bolt_spark", "bolt_heavy", "bolt_twin"]
const FIRE_TIME := {"sentry": 0.14, "lance": 0.3, "storm": 0.22, "gravity": 0.3, "swarm": 0.25, "prism": 0.3}   # how long each turret's firing art shows
const SAVE := "user://skybound_save.json"

# ---- weapons ----
const WEAPONS := {
	"laser_pistol": {"name": "Laser Pistol", "interval": 0.22, "speed": 520.0, "damage": 1.0, "projectiles": 1, "spread": 0.0, "hit_radius": 22.0},
	# Scavenger set: two small bolts side by side (a bit more damage, some misses)
	"dual_minis": {"name": "Dual Minis", "interval": 0.22, "speed": 540.0, "damage": 0.6, "projectiles": 2, "spread": 0.07, "hit_radius": 18.0},
	# Void set: a slow, heavy bolt (same damage per second, more per hit)
	"pulse_cannon": {"name": "Pulse Cannon", "interval": 0.38, "speed": 470.0, "damage": 1.75, "projectiles": 1, "spread": 0.0, "hit_radius": 28.0, "big": true},
	# Nightmare set: slow rail bolts that pierce every bug in their line
	"railgun": {"name": "Railgun", "interval": 0.45, "speed": 640.0, "damage": 1.5, "projectiles": 1, "spread": 0.0, "hit_radius": 20.0, "rail": true},
	# Solar set: fast, long-range bolts
	"laser_rifle": {"name": "Laser Rifle", "interval": 0.2, "speed": 720.0, "damage": 0.92, "projectiles": 1, "spread": 0.0, "hit_radius": 20.0},
	# Frost set: rapid small bolts
	"frost_rifle": {"name": "Frost Rifle", "interval": 0.14, "speed": 560.0, "damage": 0.64, "projectiles": 1, "spread": 0.03, "hit_radius": 18.0},
}
var weapon_id := "laser_pistol"

# ---- auto-aim feel ----
var aim_turn_speed := 10.0
var aim_error := 0.05
var aim_lead_accuracy := 0.92
var aim_avoid_overkill := true
var aim_target_sticky := 40.0
var aim_ready_angle := 0.10
var idle_fire_ratio := 1.0           # auto-aim fires as fast as dragging (Rudy: same strength either way)
var idle_power := 1.0

# ---- run stats changed by cards ----
var fire_rate_mult := 1.0
var damage_mult := 1.0
var extra_projectiles := 0
var burst_count := 1
var burst_left := 0
var burst_timer := 0.0
var burst_dir := Vector2.UP
var burst_tid := -2
var max_hearts := 3
const MAGNET_BASE := 90.0           # gem pull range at the start of a run (px); each Magnet card adds 30
var magnet_radius := MAGNET_BASE
var magnet_level := 0
const BASE_SHIELD := 140.0       # the base before gear (Gear's Stats page reads these too)
const BASE_HULL := 100.0
var hull_max := 100.0
var shield_max := 150.0
var card_levels := {}

# ---- state ----
var stage := 1
var elite := false
var promo := -1                   # the promotion trial being fought (Promotion.RANKS index), -1 = a normal stage
var _promoted := false            # this win earned the next rank (end screen)
var waves: Array = []
var wave_index := 0
var wave_queue: Array = []        # enemy ids still to spawn this wave
var wave_spawn_t := 0.0
var stage_cleared := false
var soldier_pos := Vector2(240, 620)
var dragging := false
var drag_id := -1
var last_touch := Vector2.ZERO
var hearts := 3
var shield := 150.0
var hull := 100.0
var score := 0
var kills := 0
var coins_earned := 0
var time_alive := 0.0
var fire_timer := 0.0
var game_over := false
var paused := false
var picking := false              # card pick screen open
var run_xp := 0.0
var run_level := 1
var refreshes := 1
var hit_t := 9.0                  # seconds since the shield was last hit
var inv_t := 0.0                  # pilot invulnerability after a hit
var shake := 0.0                  # screen shake strength (0..1), set by hits, fades fast
var hitstop := 0.0                # a moment of slow motion after a big kill (s)
var bullets: Array = []
var enemy_bullets: Array = []
var enemies: Array = []
var spawned: Array = []            # enemies born this frame (spore pods), joined after the enemy update
var _seen: Array = []              # enemy types this player has met (save "seen_enemies")
var _intro := {}                  # the "new enemy" card showing now: {id, t}
var gems: Array = []
var turrets: Array = []           # {type, lvl, pos, cd, fire_t, ang, flip, charge, build, bolt}
var turret_loadout: Array = []    # from the save: turret id (or "") per mount
var turret_levels := {}
var turret_tracks := {}           # id -> {atk, rate, range} (Turrets upgrade tracks)
var stage_unlocked := 1           # from the save: decides which base mounts are open (Turrets.mount_open)
var _new_mount := -1              # a mount this win just opened (shown on the end screen)
var _lid_anim := {}               # mount -> seconds into its hatch opening (first run after it opened)
var game_speed := 1.0             # x1 / x1.5 (after stage 10) / x2 (store pack); saved as "game_speed"
var _speed_pack := false           # save "speed_pack" (read at stage start)
var _cards_open := false          # the "your cards" panel is showing (the game is paused meanwhile)
var _cards_view: Control
var _xp_gain := 0                 # pilot XP this run (end screen), _xp_bonus of it for a first clear
var _xp_bonus := 0
var _took_damage := false         # any hit on the base or pilot this run (3 stars need none)
var _gems_got := 0                # gems collected this run (missions, trophies)
var _kills_by := {}               # enemy type -> kills this run
# from the equipped gear (GearData.stats), set at stage start
var _magnet_base := MAGNET_BASE
var _recovery := 1.0
var _gem_xp_mult := 1.0
var _coin_mult := 1.0
var _pilot_xp_mult := 1.0         # Solar gear: more pilot XP per run
var _bolt_set := "ion"             # the weapon's set: its colour on the pilot's bolts (Luna's bolts recoloured)
var _elem_mult := 1.0              # the hero's element vs this planet's family (Heroes.element_mult): x1.35 weak, x0.75 resists
var _move_mult := 1.0              # the hero's build (Heroes): small heroes slide faster under the finger, bulky ones slower
var _shards_got := {}              # hero shards won on this stage (the end screen)
var _coins_f := 0.0
var _shield_regen := 1.0
var _pierce5 := false
var _shot_n := 0
var _stars_got := 0
var _level_before := 1
var _level_after := 1
var drones: Array = []            # Swarm Hive micro-drones {type, pos, vel, life, dmg}
var fxs: Array = []               # short effect sprites {tex, pos, size, rot, life, max, grow, col}
var _fx: Node2D                   # additive effect layer
var _hc: Node2D                   # top bar layer (_draw_hud draws on it)
var _fx_tex := {}
var stat_pilot_dmg := 0.0
var stat_turret_dmg := 0.0
var sparks: Array = []
var rings: Array = []
var floaters: Array = []
var next_enemy_id := 0
var stat_shots := 0
var stat_hits := 0
var stat_hit_bullet := 0
var stat_hit_diver := 0
var stat_dodges := 0
var stat_feints := 0
var hive_brains := true           # debug: false turns off flit, dodge and feint (simulator comparisons)
var _stars: Array = []
var _city: Array = []
var _tex := {}
var _safe_top := 0.0              # notch / camera cutout height (SafeAreaMargin.top_inset)
var _hearts_lost := 0             # this stage (star objective 3)
var _vacuum_t := 0.0              # > 0: every pickup flies to the pilot (wave end)
var _outro_t := -1.0              # >= 0: stage won, the closing flight is playing
var _outro_lift := -1.0           # when (in _outro_t) he lifted off
var _press := {}                 # finger down: {pos, t, moved} (long-press on a turret shows its range)
var _range_mount := -1           # turret whose range ring is showing
var _range_a := 0.0
var _boss_bar_hp := 0.0           # the white "damage taken" chunk that trails the boss bar
var _boss_bar_max := 0.0
var _boss_bar_in := 0.0           # 0 -> 1 as the boss bar slides in
var _boss_flash := 0.0            # the bar flashes when a layer breaks
var _aegis_flash := 0.0           # the Aegis shell flares when the card is picked
# card overcharges (third pick of a card, Cards.OVERCHARGE)
var _crit6 := false
var _crit_rate := 0.05            # chance a bolt crits (gear milestones)
var _crit_dmg := 1.5              # a crit hits this many times as hard
var _base_dr := 0.0               # the base takes this much less damage
var _burst_pierce := false
var _gem_shield := false
var _shield_rate := 0.0            # Shield Recharge card: share of the max shield restored per second
var _hull_rate := 0.0              # its overcharge: share of the max hull per second
# new cards and fusions
var chain_level := 0              # Chain Spark: every 5th bolt sparks to this many bugs
var _chain_mult := 1.0
var _parts_got := {}              # upgrade parts picked up this run (Parts)
var _gear_got := {}               # the gear copy this clear dropped ({id, rarity}, GearData)
var _drone := {}                  # the sidekick from Gear (DroneData.read): body, pod, level
var _drone_on := false
var _drone_cd := 0.5
var _drone_aim := -PI / 2.0
var _drone_flash := 0.0
var _drone_guard := 0.0
var _drone_beam := {}
var _xp_cut := 1.0                # Quick Study overcharged: levels need less XP
var _aegis_heal := false
var _railstorm := false
var _barrage := false
var _barrage_n := 0
var _bastion := false
# dev110 cards (batch B)
var pierce_level := 0            # Piercing Rounds: bugs a bolt passes through
var _pierce_bonus := false        # its overcharge: +25% damage per bug pierced
var frost_level := 0              # Frost Rounds: hits slow bugs
var _frost_bonus := false         # its overcharge: slowed bugs take +20%
var _turret_rate := 1.0           # Turret Overclock: turrets run faster
var _turret_dmg_mult := 1.0       # its overcharge
var _overdrive := false           # Rapid Pulse overcharge: 3 s of double fire every 8 s
var _thunder := false             # Thunder Lance fusion: every pierced bug sparks
var zaps: Array = []              # spark arcs {a, b, life}

# ---- pilot animation ----
var prev_soldier_x := 240.0
var prev_soldier_y := 620.0
var vy_smooth := 0.0
var bank_smooth := 0.0
var draw_bank := 0.0
var gun_sway := 0.0
var gun_recoil := 0.0
var gun_raise := 0.0
var idle_aiming := false
var idle_aim_ang := -PI / 2.0
var aim_goal := -PI / 2.0
var aim_target_id := -2
var facing := 1.0
var facing_s := 1.0               # eases toward facing, so turning round squeezes instead of snapping
var anim := PilotSprite.Anim.new()
var _rig_view: PilotRigView        # the new cut-out pilot (PilotRig.ENABLED); null = painted PilotSprite

# ---- UI ----
var hud_font: Font = preload("res://fonts/Exo2-Variable.ttf")
var title_font: Font = preload("res://fonts/Orbitron-Variable.ttf")
var _pause_btn: Button
var _pause_panel: Control
var _card_panel: Control
var _end_panel: Control
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	Sfx.apply_from(_read_save())   # sound on/off (pause menu, Settings)
	PilotSprite.load_style()
	_stars = Backdrop.make_stars(90, 11)
	_city = Backdrop.make_city(44, 7)
	for id in StageData.ENEMIES:
		if String(StageData.ENEMIES[id].tex) == "":
			continue   # drawn in code (spore pods)
		_tex[id + "_up"] = load("res://enemies/%s_up.png" % id)
		_tex[id + "_down"] = load("res://enemies/%s_down.png" % id)
	for id in Turrets.TURRETS:
		_tex[Turrets.TURRETS[id].art + "_idle"] = load("res://turrets/%s_idle.png" % Turrets.TURRETS[id].art)
	_tex["sentry_head"] = load("res://turrets/sentry_head.png")
	# Luna's batch D turrets in two pieces: a base on the socket and a head on top
	for n in ["lance_base", "lance_head", "storm_base", "storm_head", "gravity_base", "gravity_head", "prism_head"]:
		_tex[n] = load("res://turrets/%s.png" % n)
	for n in ["body_scout", "body_striker", "body_warden", "pod_blaster", "pod_beam", "pod_missile"]:
		_tex[n] = load("res://drone/%s.png" % n)
	for b in ["scout", "striker", "warden"]:   # Luna's drone parts (dev160), when cut
		if ResourceLoader.exists("res://drone/%s_hull.png" % b):
			_tex["hull_" + b] = load("res://drone/%s_hull.png" % b)
			_tex["thruster_l_" + b] = load("res://drone/%s_thruster_l.png" % b)
			_tex["thruster_r_" + b] = load("res://drone/%s_thruster_r.png" % b)
	for n in ["blaster", "beam", "missile"]:
		_fx_tex["drone_flash_" + n] = load("res://drone/flash_%s.png" % n)
	_tex["sentry_base"] = load("res://turrets/sentry_base.png")
	for n in ["swarm_body_nolid", "swarm_lid"]:   # Luna's Swarm Hive parts (dev162)
		if ResourceLoader.exists("res://turrets/%s.png" % n):
			_tex[n] = load("res://turrets/%s.png" % n)
	for n in ["sentry", "lance", "storm", "gravity", "prism", "swarm"]:   # the turrets' own glow (dev154)
		if ResourceLoader.exists("res://turrets/%s_light.png" % n):
			_fx_tex["light_" + n] = load("res://turrets/%s_light.png" % n)
	for i in 4:
		_tex["gem_%d" % i] = load("res://pickups/gem_%d.png" % i)
	_tex["goo"] = load("res://fx/goo.png")
	_tex["ui_heart"] = load("res://icons/ui_heart.png")
	_tex["ui_coin"] = load("res://icons/ui_coin.png")
	for n in ["lid_closed", "lid_half", "lid_open"]:
		_tex[n] = load("res://base/%s.png" % n)
	for k in Parts.ORDER:   # part pickups (was loaded every frame while one lay on the field)
		if ResourceLoader.exists("res://parts/%s.png" % k):
			_tex["part_" + k] = load("res://parts/%s.png" % k)
	for n in FX_NAMES:
		_fx_tex[n] = load("res://fx/%s.png" % n)
	# effects (shots, hits, glows) are drawn on their own layer with additive light
	_fx = Node2D.new()
	var fx_mat := CanvasItemMaterial.new()
	fx_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_fx.material = fx_mat
	if PilotRig.ENABLED:
		_rig_view = PilotRigView.new()
		_rig_view.height = PILOT_HEIGHT
		add_child(_rig_view)
	_fx.draw.connect(_draw_fx)
	HomeProp.load_drone()   # Wingman Drone card
	add_child(_fx)
	# the top bar (and boss bar, NEW ENEMY card) on a layer above the pilot and effects but
	# below the menus, so he flies BEHIND it when he leaves the stage
	_hc = Node2D.new()
	_hc.draw.connect(_draw_hud)
	add_child(_hc)
	for n in ["hive_lay_1", "hive_lay_2", "hive_lay_3", "hive_lay_4", "hive_hatchling"]:
		_tex[n] = load("res://enemies/%s.png" % n)
	_load()
	_build_ui()
	_start_stage()

func _load() -> void:
	var d := _read_save()
	stage = int(d.get("selected_stage", 1))
	elite = bool(d.get("selected_elite", false))
	# a promotion trial (Promotion): the save asks once, then the ask is cleared so Home's
	# Play goes back to the normal stage
	promo = Promotion.take(d)
	if promo >= 0:
		_write_save({"selected_mode": "normal"})
		stage = int(Promotion.RANKS[promo].stage)
		elite = false
	var t := Turrets.read(d)
	turret_loadout = t.loadout
	turret_levels = t.levels
	turret_tracks = t.tracks

func _read_save() -> Dictionary:
	if FileAccess.file_exists(SAVE):
		var f := FileAccess.open(SAVE, FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if typeof(d) == TYPE_DICTIONARY:
				return d
	return {}

func _write_save(patch: Dictionary) -> void:
	var d := _read_save()
	for k in patch:
		d[k] = patch[k]
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))

# ------------------------------------------------------------------ setup

func _start_stage() -> void:
	waves = Promotion.waves(promo) if promo >= 0 else StageData.waves(stage)
	wave_index = 0
	stage_cleared = false
	_vacuum_t = 0.0
	_outro_t = -1.0
	_outro_lift = -1.0
	game_over = false
	hearts = 3
	max_hearts = 3
	shield_max = BASE_SHIELD
	hull_max = BASE_HULL
	shield = shield_max
	hull = hull_max
	score = 0
	kills = 0
	coins_earned = 0
	time_alive = 0.0
	run_xp = 0.0
	run_level = 1
	refreshes = 1
	card_levels = {}
	_crit6 = false
	_burst_pierce = false
	_gem_shield = false
	chain_level = 0
	_shield_rate = 0.0
	_hull_rate = 0.0
	_chain_mult = 1.0
	_xp_cut = 1.0
	_aegis_heal = false
	_railstorm = false
	_barrage = false
	_barrage_n = 0
	_bastion = false
	pierce_level = 0
	_pierce_bonus = false
	frost_level = 0
	_frost_bonus = false
	_turret_rate = 1.0
	_turret_dmg_mult = 1.0
	_overdrive = false
	_thunder = false
	zaps.clear()
	_boss_bar_max = 0.0
	_boss_bar_in = 0.0
	fire_rate_mult = 1.0
	damage_mult = 1.0
	extra_projectiles = 0
	burst_count = 1
	burst_left = 0
	magnet_radius = MAGNET_BASE
	magnet_level = 0
	bullets.clear(); enemy_bullets.clear(); enemies.clear(); gems.clear(); turrets.clear()
	spawned.clear()
	_seen = Array(_read_save().get("seen_enemies", []))
	_intro = {}
	sparks.clear(); rings.clear(); floaters.clear()
	drones.clear()
	fxs.clear()
	stat_pilot_dmg = 0.0
	stat_turret_dmg = 0.0
	var sv := _read_save()
	stage_unlocked = int(sv.get("stage_unlocked", 1))
	_speed_pack = bool(sv.get("speed_pack", false))
	# the pilot's gear: every slot boosts a battle stat, sets add bonuses (gear_data.gd)
	var gs := Heroes.stats(sv)   # the hero and his weapon (heroes, dev172)
	PilotRig.set_gear(sv)   # he holds the equipped weapon; visor and orb in the gear colours
	_elem_mult = Heroes.element_mult(String(gs.element), stage)   # his element against this planet's family
	_bolt_set = String(gs.element)   # bolts in the hero's element colour
	for bk in ["bolt", "bolt_rail", "bolt_spark", "bolt_heavy", "bolt_twin"]:
		if _fx_tex.has(bk):
			PilotRig.tinted(_fx_tex[bk], _bolt_set)   # made now, not in the middle of a draw
	damage_mult = gs.damage
	fire_rate_mult = gs.fire_rate
	aim_error = 0.05 / gs.aim
	aim_turn_speed = 10.0 * gs.aim
	max_hearts = 3 + int(gs.hearts)
	hearts = max_hearts
	_recovery = gs.recovery
	_magnet_base = MAGNET_BASE + float(gs.magnet)
	magnet_radius = _magnet_base
	idle_power = gs.auto_fire
	_gem_xp_mult = gs.gem_xp * (Promotion.GEM_XP_MULT if promo >= 0 else 1.0)   # trials: cards come faster
	_coin_mult = gs.coins
	_coins_f = 0.0
	_shield_regen = gs.shield_regen
	# the shield never regenerates (Rudy, dev108); the Ion 6-piece bonus makes it bigger instead
	shield_max *= gs.shield * gs.fortress
	shield = shield_max
	# combat stats from gear milestones (GearData.MILESTONE): crits, damage boost, the base
	hull_max *= gs.fortress
	hull = hull_max
	_crit_rate = gs.crit_rate
	_crit_dmg = gs.crit_dmg
	damage_mult *= 1.0 + gs.dmg_boost
	_base_dr = clampf(gs.base_dr, 0.0, 0.6)
	refreshes = 1 + int(gs.refreshes)
	_pierce5 = gs.pierce5
	_turret_dmg_mult = gs.turret_dmg
	_turret_rate = gs.turret_rate
	_pilot_xp_mult = gs.pilot_xp
	_move_mult = float(gs.get("speed", 1.0))
	if _rig_view:
		_rig_view.height = PILOT_HEIGHT * float(gs.get("scale", 1.0))   # bulky or small (his build)
	if gs.chill:
		frost_level = maxi(frost_level, 1)
	_shot_n = 0
	weapon_id = gs.weapon
	PilotSprite.style = gs.thruster
	game_speed = float(sv.get("game_speed", 1.0))
	if not _speeds().has(game_speed):
		game_speed = 1.0
	# a mount opened since the last run: its hatch opens before the turret drops in
	_lid_anim = {}
	var seen := int(sv.get("mounts_seen", 0))
	var open_now := Turrets.mounts_open(stage_unlocked)
	for i in range(seen, open_now):
		_lid_anim[i] = -0.4
	if open_now != seen:
		_write_save({"mounts_seen": open_now})
	var plevel := Turrets.pilot_level(int(sv.get("pilot_xp", 0)))
	# the drone sidekick flies along once the pilot is level 8 (Gear > Drone)
	_drone = DroneData.read(sv)
	if plevel < int(DroneData.BODIES[_drone.body].unlock):
		_drone.body = "scout"
	if plevel < int(DroneData.PODS[_drone.pod].unlock):
		_drone.pod = "blaster"
	_drone_on = DroneData.unlocked(plevel)
	_drone_cd = 0.5
	_drone_beam = {}
	_took_damage = false
	_hearts_lost = 0
	_parts_got = {}
	_stars_got = 0
	_gems_got = 0
	_kills_by = {}
	_new_mount = -1
	# a turret stands on the base only if its mount is open (stages) and it is unlocked (pilot level)
	for i in turret_loadout.size():
		if turret_loadout[i] != "" and Turrets.mount_open(i, stage_unlocked) and plevel >= int(Turrets.TURRETS[turret_loadout[i]].unlock):
			_mount_turret(turret_loadout[i], i, int(turret_levels.get(turret_loadout[i], 1)), false)
	for t in turrets:
		if _lid_anim.has(t.mount):
			t.drop_wait = float(t.drop_wait) + 1.2   # wait for the hatch
	soldier_pos = Vector2(240, BASE_Y - 200.0)
	prev_soldier_x = soldier_pos.x
	prev_soldier_y = soldier_pos.y
	aim_target_id = -2
	_end_panel.visible = false
	_card_panel.visible = false
	picking = false
	paused = false
	_start_wave()
	_maybe_brief()

func _start_wave() -> void:
	wave_queue.clear()
	if wave_index > 0 and wave_index < waves.size():
		Sfx.play("wave")
	if wave_index >= waves.size():
		return
	if _aegis_heal and wave_index > 0 and hearts < max_hearts:
		hearts += 1   # Aegis overcharged
		_float_text(soldier_pos + Vector2(0, -40), "+1 HEART", Color(1.0, 0.5, 0.6))
	for entry in waves[wave_index]:
		for i in int(entry[1]):
			wave_queue.append(entry[0])
	wave_queue.shuffle()
	# the boss always comes last
	if wave_queue.has("hive_mother"):
		wave_queue.erase("hive_mother")
		# from planet 3 (stage 21) the boss comes in a third of the way through, with bugs still arriving
		if stage >= 21:
			wave_queue.insert(wave_queue.size() / 3, "hive_mother")
		else:
			wave_queue.append("hive_mother")
	wave_spawn_t = 0.6
	_float_text(Vector2(FIELD_W * 0.5, 160), "WAVE %d" % (wave_index + 1), Color(0.75, 0.97, 1.0), true)

func _spawn(id: String) -> void:
	var e := _make_enemy(id, Vector2(rng.randf_range(40.0, FIELD_W - 40.0), 60.0))
	if id == "hive_mother":
		e.pos = Vector2(FIELD_W * 0.5, 40.0)
		# a younger, smaller Hive Mother: the zone-A mini-boss, or one arriving mid-stage
		if StageData.boss_kind(stage) == "mini" or wave_index < waves.size() - 1:
			e.mini = true
			e.hp *= 0.6
			e.hp_max *= 0.6
		e.r = float(e.r) * (1.4 if e.get("mini", false) else 1.8)   # drawn much bigger now (dev108)
		_boss_bar_max = e.hp_max
	_meet(id)
	enemies.append(e)

# The first time a player meets a bug type, a small card says what it does.
func _meet(id: String) -> void:
	if _seen.has(id) or String(StageData.ENEMIES[id].get("intro", "")) == "":
		return
	_seen.append(id)
	_write_save({"seen_enemies": _seen})
	_intro = {"id": id, "t": 0.0}

func _make_enemy(id: String, pos: Vector2) -> Dictionary:
	var def: Dictionary = StageData.ENEMIES[id]
	var e := {"id": next_enemy_id, "type": id, "pos": pos,
		"hp": float(def.hp) * _hp_mult(), "hp_max": float(def.hp) * _hp_mult(),
		"speed": float(def.speed) * StageData.speed_mult(stage), "r": float(def.size) * 0.4, "ph": rng.randf() * TAU,
		"state": "fly", "t": 0.0, "vel": Vector2.ZERO, "fire_t": rng.randf_range(1.0, 2.5), "lay_t": 3.0, "laying": 0.0,
		"dart_t": rng.randf_range(0.3, 1.0), "dart_vx": 0.0, "dodge_v": 0.0, "dodge_cd": 0.0, "feinted": false}
	next_enemy_id += 1
	return e

# ------------------------------------------------------------------ input

func _input(event: InputEvent) -> void:
	if paused or picking or game_over or stage_cleared or _outro_t >= 0.0:
		return
	# long-press tracking for the turret range ring (where the finger went down, how far it moved)
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		_press = {"pos": event.position - Vector2(0, _safe_top), "t": time_alive, "moved": 0.0}
	elif (event is InputEventScreenTouch or event is InputEventMouseButton) and not event.pressed:
		_press = {}
	elif (event is InputEventScreenDrag or event is InputEventMouseMotion) and not _press.is_empty():
		_press.moved = float(_press.moved) + event.relative.length()
	if event is InputEventScreenTouch:
		if event.pressed and not dragging:
			dragging = true
			drag_id = event.index
			last_touch = event.position
		elif not event.pressed and event.index == drag_id:
			dragging = false
			drag_id = -1
	elif event is InputEventScreenDrag:
		if dragging and event.index == drag_id:
			_drag_by(event.position - last_touch)
			last_touch = event.position
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not dragging:
			dragging = true
			last_touch = event.position
		else:
			_drag_by(event.position - last_touch)
			last_touch = event.position
	elif event is InputEventMouseButton and not event.pressed and dragging:
		dragging = false

# Long-press (0.4 s, finger still) on a turret: its range shows as a see-through red
# shape until the finger lifts.
func _update_range_ring(delta: float) -> void:
	var want := -1
	if not _press.is_empty() and float(_press.moved) < 14.0 and time_alive - float(_press.t) > 0.4:
		for t in turrets:
			if float(t.drop) >= 1.0 and Vector2(_press.pos).distance_to(t.pos + Vector2(0, -30)) < 52.0:
				want = int(t.mount)
	if want >= 0:
		_range_mount = want
	_range_a = move_toward(_range_a, 1.0 if want >= 0 else 0.0, delta * 6.0)

func _draw_range_ring() -> void:
	if _range_mount < 0 or _range_a <= 0.01:
		return
	var t: Dictionary = {}
	for tt in turrets:
		if int(tt.mount) == _range_mount:
			t = tt
	if t.is_empty():
		return
	var def: Dictionary = t.def
	var fill := Color(1.0, 0.25, 0.25, 0.12 * _range_a)
	var edge := Color(1.0, 0.35, 0.35, 0.6 * _range_a)
	var p: Vector2 = t.pos
	match String(t.type):
		"lance":
			var w: float = float(def.width)
			var r := Rect2(p.x - w * 0.5, 0.0, w, p.y)
			draw_rect(r, fill)
			draw_rect(r, edge, false, 1.2)
		"storm":
			_ring_shape(Vector2(p.x, p.y - float(def.cloud_h) * 0.5), float(def.cloud_r), float(def.cloud_h) * 0.5, fill, edge)
		"gravity":
			_ring_shape(Vector2(p.x, p.y - float(def.height)), float(def.radius), float(def.radius), fill, edge)
		"swarm":
			var rr: float = float(def.speed) * float(def.life) * 0.4
			_ring_shape(p, rr, rr, fill, edge)
		"prism":
			_ring_shape(p, float(def.split_h), float(def.split_h), fill, edge)
		_:
			_ring_shape(p, float(def.get("range", 300.0)), float(def.get("range", 300.0)), fill, edge)
	draw_string(hud_font, p + Vector2(-60, -70), "%s RANGE" % String(def.name).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 120, 11, Color(1, 0.6, 0.6, _range_a))

func _ring_shape(c: Vector2, rx: float, ry: float, fill: Color, edge: Color) -> void:
	var pts := PackedVector2Array()
	for i in 49:
		var a := TAU * i / 48.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts.slice(0, 48), fill)
	draw_polyline(pts, edge, 1.2, true)

func _drag_by(d: Vector2) -> void:
	d *= _move_mult   # his build: small = quick, bulky = slow
	soldier_pos.x = clampf(soldier_pos.x + d.x, 24.0, FIELD_W - 24.0)
	soldier_pos.y = clampf(soldier_pos.y + d.y, 110.0, BASE_Y - 40.0)

# ------------------------------------------------------------------ frame

func _process(delta: float) -> void:
	# the field starts below the phone's notch / camera cutout (the whole battle node is
	# moved down by _safe_top; the sky and the top bar's fill reach up behind the cutout)
	_safe_top = SafeAreaMargin.top_inset(get_viewport())
	var vp_h: float = get_viewport_rect().size.y - _safe_top
	if absf(vp_h - FIELD_H) > 0.5:
		FIELD_H = vp_h
		BASE_Y = FIELD_H - 14.0
	if paused or picking or game_over or stage_cleared:
		position = Vector2(0, _safe_top)
		queue_redraw()
		return
	delta *= game_speed
	# hit feel: a big kill slows the world for a blink; hits shake the screen a little
	if hitstop > 0.0:
		hitstop -= delta
		delta *= 0.2
	shake = maxf(shake - delta * 3.5, 0.0)
	var sk := shake * shake * 5.0
	position = Vector2(0, _safe_top) + Vector2(sin(time_alive * 93.0), cos(time_alive * 71.0)) * sk
	time_alive += delta
	hit_t += delta
	for k in _lid_anim.keys():
		_lid_anim[k] = float(_lid_anim[k]) + delta
		if _lid_anim[k] > 1.6:
			_lid_anim.erase(k)
	if not _intro.is_empty():
		_intro.t += delta
		if _intro.t > 4.0:
			_intro = {}
	inv_t = maxf(inv_t - delta, 0.0)
	_boss_flash = maxf(_boss_flash - delta * 2.5, 0.0)
	_aegis_flash = maxf(_aegis_flash - delta * 1.2, 0.0)
	var vy: float = (soldier_pos.y - prev_soldier_y) / maxf(delta, 0.001)
	prev_soldier_y = soldier_pos.y
	vy_smooth = lerpf(vy_smooth, vy, 0.15)
	# no free regeneration any more: only the Shield Recharge card (2.5 s after the last hit)
	if hit_t > 2.5:
		if _shield_rate > 0.0:
			shield = minf(shield + shield_max * _shield_rate * delta, shield_max)
		if _hull_rate > 0.0:
			hull = minf(hull + hull_max * _hull_rate * delta, hull_max)
	_vacuum_t = maxf(_vacuum_t - delta, 0.0)
	if _outro_t >= 0.0:
		_update_outro(delta)
	else:
		_aim_and_fire(delta)
	_update_drone(delta)
	_update_range_ring(delta)
	for z in zaps:
		z.life -= delta
	zaps = zaps.filter(func(z): return z.life > 0.0)
	_spawn_step(delta)
	_update_bullets(delta)
	_update_enemies(delta)
	_update_gems(delta)
	_update_shards(delta)
	_update_turrets(delta)
	_step_effects(delta)
	_pilot_motion(delta)
	anim.update(_wanted_pose(), delta)
	if hearts <= 0 or hull <= 0.0:
		_end_run(false)
	elif wave_queue.is_empty() and enemies.is_empty() and not stage_cleared and _outro_t < 0.0:
		wave_index += 1
		_vacuum_t = 1.4   # what is left flies to him
		if wave_index >= waves.size():
			_outro_t = 0.0   # the stage ends with a short flight off the top (_update_outro)
		else:
			_start_wave()
	queue_redraw()

func _spawn_step(delta: float) -> void:
	if wave_queue.is_empty():
		return
	wave_spawn_t -= delta
	if wave_spawn_t <= 0.0:
		wave_spawn_t = StageData.spawn_gap(stage) if enemies.size() < 12 else 2.4
		# arrive in small groups so the sky fills (one at a time in stage 1)
		var n: int = mini(StageData.group_size(stage), wave_queue.size())
		for i in n:
			var id: String = wave_queue.pop_front()
			_spawn(id)
			if id == "hive_mother":
				break

func _pilot_motion(delta: float) -> void:
	if dragging or idle_aiming:
		gun_raise = minf(1.0, gun_raise + delta * 6.0)
	else:
		gun_raise = maxf(0.0, gun_raise - delta * 6.0)
	var dx: float = soldier_pos.x - prev_soldier_x
	prev_soldier_x = soldier_pos.x
	if dragging and dx > 0.8:
		facing = -1.0
	elif dragging and dx < -0.8:
		facing = 1.0
	elif not dragging and idle_aiming:
		facing = -1.0 if cos(idle_aim_ang) > 0.05 else (1.0 if cos(idle_aim_ang) < -0.05 else facing)
	facing_s = move_toward(facing_s, facing, delta * 8.0)
	bank_smooth = lerpf(bank_smooth, clampf(dx * 0.02, -0.30, 0.30), minf(1.0, delta * 10.0))
	draw_bank = bank_smooth
	gun_sway = lerpf(gun_sway, clampf(dx * 0.025, -0.55, 0.55), minf(1.0, delta * 8.0))
	gun_recoil = gun_recoil * exp(-delta * 12.0)
	if _rig_view:
		var rig_aim: float = -PI / 2.0 - 0.3          # no target: rifle held up, like Luna's reference
		if dragging:
			rig_aim = -PI / 2.0 + gun_sway - draw_bank
		elif idle_aiming:
			rig_aim = idle_aim_ang
		var a: float = 1.0
		if inv_t > 0.0:
			a = lerpf(1.0, 0.55 + 0.45 * absf(cos(time_alive * PI * 4.0)), smoothstep(0.0, 0.3, inv_t))
		_rig_view.update(delta, soldier_pos + Vector2(0, sin(time_alive * 4.0) * 2.5), rig_aim, draw_bank / 0.3,
			clampf(1.0 - vy_smooth / 260.0, 0.35, 1.9), vy_smooth, a)
		# Aegis: light hugging his outline (brighter with the 2nd Aegis, flares when he is hit)
		var lv_a := int(card_levels.get("aegis", 0))
		_rig_view.shield = 0.0 if lv_a <= 0 else minf(0.55 + 0.25 * lv_a + _aegis_flash + 0.6 * smoothstep(0.0, 0.3, inv_t), 1.6)
		_rig_view.shield_form = minf(_rig_view.shield_form + delta * 1.6, 1.0)

# ------------------------------------------------------------------ aiming and shooting

func _wanted_pose() -> String:
	return PilotSprite.pose_for(dragging, draw_bank, Vector2(cos(idle_aim_ang), sin(idle_aim_ang)), idle_aiming)

func _current_pose() -> String:
	return anim.pose()

func _flipped(_pose: String) -> bool:
	# aim frames mirror with facing; lean_1/lean_2 mirror when they stand in for the right lean
	var p := anim.pose()
	if p.begins_with("aim"):
		return facing_s < 0.0
	return anim.mirrored()

func _muzzle_world() -> Vector2:
	if _rig_view:
		return _rig_view.muzzle()
	var pose := _current_pose()
	return soldier_pos + PilotSprite.muzzle(pose, PILOT_HEIGHT, _flipped(pose)).rotated(-draw_bank * 0.6)

func _kick(v: float) -> void:
	gun_recoil = v
	if _rig_view:
		_rig_view.fire()

# Stage won (Rudy, dev108): the last pickups fly in, then he turns to the sky and blasts
# off the top of the screen, and only then does Stage Cleared show.
func _update_outro(delta: float) -> void:
	_outro_t += delta
	dragging = false
	if _outro_lift < 0.0:
		# everything left flies to him (at least 0.8 s, at most 2.5 s) while he settles
		_vacuum_t = maxf(_vacuum_t, 0.2)
		soldier_pos.x = lerpf(soldier_pos.x, FIELD_W * 0.5, minf(1.0, delta * 2.0))
		if (gems.is_empty() and _outro_t > 0.8) or _outro_t > 2.5:
			_outro_lift = _outro_t
		return
	var k: float = _outro_t - _outro_lift
	soldier_pos.x = lerpf(soldier_pos.x, FIELD_W * 0.5, minf(1.0, delta * 3.0))
	soldier_pos.y -= (80.0 + 900.0 * k * k) * delta   # slow lift-off, then a rush upward
	if k < 0.05:
		_burst(soldier_pos + Vector2(0, 30), 24.0, Color(0.55, 0.85, 1.0), 14)
		_float_text(Vector2(FIELD_W * 0.5, FIELD_H * 0.35), "STAGE CLEAR", Color(0.75, 0.97, 1.0), true)
	if soldier_pos.y < -90.0 or k > 2.2:
		_outro_t = -1.0
		_outro_lift = -1.0
		_end_run(true)

func _aim_and_fire(delta: float) -> void:
	idle_aiming = false
	var weapon: Dictionary = WEAPONS[weapon_id]
	var muzzle_base := _muzzle_world()
	var target := _pick_aim_target(muzzle_base)
	if not target.is_empty():
		var flight_t: float = muzzle_base.distance_to(target.pos) / float(weapon.speed)
		var lead_pos: Vector2 = target.pos + target.vel * flight_t * aim_lead_accuracy
		aim_goal = clampf((lead_pos - muzzle_base).angle(), -PI / 2.0 - 1.2, -PI / 2.0 + 1.2)
	if not dragging and not target.is_empty():
		idle_aiming = true
		idle_aim_ang = _turn_toward(idle_aim_ang, aim_goal, aim_turn_speed * delta)
	else:
		idle_aim_ang = -PI / 2.0 + gun_sway
	fire_timer -= delta
	# follow-up bolts of a burst
	if burst_left > 0:
		burst_timer -= delta
		if burst_timer <= 0.0:
			burst_timer = 0.07
			burst_left -= 1
			_kick(0.9)
			_fire(_muzzle_world() + burst_dir * 4.0, burst_dir, burst_tid, _burst_pierce and burst_left == 0)
	var interval: float = float(weapon.interval) / fire_rate_mult
	if burst_count > 1:
		interval *= 1.0 + 0.35 * (burst_count - 1)
	if _overdrive and fmod(time_alive, 8.0) < 3.0:
		interval *= 0.5   # Rapid Pulse overcharged: overdrive window
	if dragging and fire_timer <= 0.0:
		fire_timer = interval
		_kick(1.0)
		var ang: float = -PI / 2.0 + gun_sway - draw_bank
		var dir := Vector2(cos(ang), sin(ang))
		_fire(muzzle_base + dir * 4.0, dir)
		burst_left = burst_count - 1
		burst_timer = 0.07
		burst_dir = dir
		burst_tid = -2
	elif idle_aiming and fire_timer <= 0.0 and not target.get("doomed", false) and absf(angle_difference(idle_aim_ang, aim_goal)) <= aim_ready_angle:
		fire_timer = interval * idle_fire_ratio / idle_power
		_kick(1.0)
		var shot_ang := idle_aim_ang + rng.randf_range(-aim_error, aim_error)
		var d2 := Vector2(cos(shot_ang), sin(shot_ang))
		_fire(muzzle_base + d2 * 4.0, d2, int(target.get("id", -2)))
		burst_left = burst_count - 1
		burst_timer = 0.07
		burst_dir = d2
		burst_tid = int(target.get("id", -2))

func _fire(origin: Vector2, dir: Vector2, target_id: int = -2, pierce: bool = false) -> void:
	var w: Dictionary = WEAPONS[weapon_id]
	Sfx.play("shot", rng.randf_range(0.95, 1.05))
	var count: int = int(w.projectiles) + extra_projectiles
	var spread: float = float(w.spread) + 0.18 * extra_projectiles
	for i in count:
		var off := 0.0
		if count > 1:
			off = lerpf(-spread * 0.5, spread * 0.5, float(i) / float(count - 1))
		_shot_n += 1
		# Heavy Bolts overcharged: every 6th bolt is a big one that hits 3x
		var crit: bool = _crit6 and _shot_n % 6 == 0
		var lucky: bool = rng.randf() < _crit_rate   # a critical hit (crit rate / crit damage)
		# Railstorm fusion: every 4th bolt is a rail shot that pierces the whole line
		var rail: bool = _railstorm and _shot_n % 4 == 0
		var rail_gun: bool = w.get("rail", false)   # Nightmare railgun: every bolt pierces
		bullets.append({"pos": origin, "vel": dir.rotated(off) * float(w.speed) * (1.4 if rail else 1.0),
			"dmg": float(w.damage) * damage_mult * (3.0 if crit else 1.0) * (2.0 if rail else 1.0) * (_crit_dmg if lucky else 1.0),
			"r": float(w.hit_radius), "tid": target_id, "col": "cyan", "big": w.get("big", false) or crit or rail or lucky,
			"pierce": pierce or rail or rail_gun or (_pierce5 and _shot_n % 5 == 0), "hits": [],
			"spark": chain_level if chain_level > 0 and _shot_n % 5 == 0 else 0, "pierce_left": pierce_level,
			"frost": frost_level > 0, "rail": rail or rail_gun})
		stat_shots += 1

func _turn_toward(current: float, goal: float, max_step: float) -> float:
	return current + clampf(angle_difference(current, goal), -max_step, max_step)

func _pick_aim_target(from: Vector2) -> Dictionary:
	var incoming := {}
	if aim_avoid_overkill:
		for bl in bullets:
			var tid: int = bl.get("tid", -2)
			if tid != -2:
				incoming[tid] = float(incoming.get(tid, 0.0)) + float(bl.get("dmg", 1.0))
	var best := {}
	var best_d := 1e9
	var best_any := {}
	var best_any_d := 1e9
	for e in enemies:
		if e.pos.y < 100.0:
			continue
		var d: float = from.distance_to(e.pos)
		var info := {"pos": e.pos, "vel": e.vel, "id": e.id, "doomed": e.hp - float(incoming.get(e.id, 0.0)) <= 0.0}
		if d < best_any_d:
			best_any_d = d
			best_any = info
		if not info.doomed and d < best_d:
			best_d = d
			best = info
	if best.is_empty():
		best = best_any
	elif aim_target_id != best.id:
		for e in enemies:
			if e.id == aim_target_id and from.distance_to(e.pos) <= best_d + aim_target_sticky and e.hp - float(incoming.get(e.id, 0.0)) > 0.0:
				best = {"pos": e.pos, "vel": e.vel, "id": e.id, "doomed": false}
				break
	aim_target_id = best.get("id", -2)
	return best

# ------------------------------------------------------------------ bullets, enemies, gems

func _update_bullets(delta: float) -> void:
	var live: Array = []
	var bounced: Array = []   # Ricochet bolts made this frame
	for b in bullets:
		# drone missiles steer toward their target
		if b.has("homing"):
			for e in enemies:
				if int(e.id) == int(b.homing):
					var want: Vector2 = (Vector2(e.pos) - Vector2(b.pos)).normalized() * 300.0
					b.vel = Vector2(b.vel).lerp(want, minf(1.0, delta * 4.0))
					break
		b.pos += b.vel * delta
		var hit := false
		for e in enemies:
			if b.has("hits") and Array(b.hits).has(e.id):
				continue   # a piercing bolt hits each bug once
			if not _can_hurt(e):
				continue   # a boss still arriving: bolts pass through her
			if b.pos.distance_to(e.pos) < float(b.r) + float(e.r) * 0.5:
				var dmg: float = float(b.dmg)
				if e.type == "hive_mother" and e.laying > 1.2:
					dmg *= 2.0   # weak spot open while she lays
				if b.has("src"):
					dmg *= Turrets.trait_mult(b.src, StageData.ENEMIES[e.type].traits)
					stat_turret_dmg += minf(dmg, maxf(e.hp, 0.0))
					_fx_add("spark", b.pos, 34.0, 0.28, rng.randf() * TAU)
					# Ricochet (turret card): the Sentry bolt bounces on to the nearest other bug
					if int(b.get("bounce", 0)) > 0:
						var nxt := {}
						var nd := 220.0
						for o in enemies:
							if o != e and not Array(b.get("hits", [])).has(o.id) and o.pos.distance_to(e.pos) < nd:
								nd = o.pos.distance_to(e.pos)
								nxt = o
						if not nxt.is_empty():
							var hs: Array = Array(b.get("hits", [])).duplicate()
							hs.append(e.id)
							bounced.append({"pos": e.pos, "vel": (Vector2(nxt.pos) - Vector2(e.pos)).normalized() * 420.0, "dmg": float(b.dmg) * 0.8, "r": 14.0,
								"tid": -2, "col": "tracer", "src": b.src, "bounce": int(b.bounce) - 1, "splash": float(b.get("splash", 0.0)), "hits": hs})
				else:
					dmg *= _elem_mult   # the hero's element (Heroes): weak x1.35, resists x0.75
					if _frost_bonus and float(e.get("slow_t", 0.0)) > 0.0:
						dmg *= 1.2
					if b.get("frost", false):
						e.slow_t = 1.5
						e.slow = minf(0.15 * frost_level, 0.45)
					stat_pilot_dmg += minf(dmg, maxf(e.hp, 0.0))
					_fx_add("impact", b.pos, 26.0, 0.22, rng.randf() * TAU, 1.6, Color(0.7, 0.92, 1.0) if b.get("frost", false) else Color.WHITE)
				e.hp -= dmg
				e.hit_t = HIT_FLINCH_T
				Sfx.play("boss_hit" if e.type == "hive_mother" else "hit", rng.randf_range(0.92, 1.08))
				if float(b.get("splash", 0.0)) > 0.0:
					for o in enemies:
						if o != e and o.pos.distance_to(b.pos) < float(b.splash):
							o.hp -= (dmg * 0.6) if _can_hurt(o) else 0.0
					_fx_add("nova", b.pos, float(b.splash) * 0.6, 0.3, 0.0, 1.8, Color(0.8, 0.5, 1.0))
				if int(b.get("spark", 0)) > 0:
					_chain(e, int(b.spark), dmg * 0.5 * _chain_mult)
				# Void set bonus: every 5th bolt flies on through
				hit = not b.get("pierce", false)
				# Piercing Rounds: passes through this bug if it still has passes left
				if hit and int(b.get("pierce_left", 0)) > 0:
					b.pierce_left = int(b.pierce_left) - 1
					hit = false
					if _pierce_bonus:
						b.dmg = float(b.dmg) * 1.25
				if not hit:
					b.hits.append(e.id)
					if _thunder and not b.has("src"):
						_chain(e, 1, dmg * 0.5)
				stat_hits += 1
				for k in 3:
					sparks.append({"pos": b.pos, "vel": Vector2(rng.randf_range(-100, 100), rng.randf_range(-100, 100)), "life": 0.3, "col": Color(0.2, 0.85, 1.0)})
				break
		if not hit and b.pos.y > -30.0 and b.pos.y < FIELD_H + 30.0 and b.pos.x > -30.0 and b.pos.x < FIELD_W + 30.0:
			live.append(b)
	live.append_array(bounced)
	bullets = live
	var live_eb: Array = []
	for b in enemy_bullets:
		b.pos += b.vel * delta
		var shot_down := false
		for pb in bullets:
			if pb.pos.distance_to(b.pos) < 14.0:
				shot_down = true
				pb.pos = Vector2(-999, -999)
				break
		if shot_down:
			_burst(b.pos, 5.0, Color(1.0, 0.6, 0.9), 4)
			score += 10
			continue
		if Backdrop.inside_field(Vector2(FIELD_W / 2, BASE_Y), DOME_RX, DOME_RY, b.pos):
			_hurt_base(8.0)
			_burst(b.pos, 6.0, Color(0.18, 0.9, 1.0), 4)
			continue
		if b.pos.distance_to(soldier_pos) < 14.0:
			if inv_t <= 0.0:
				stat_hit_bullet += 1
			_hurt_pilot()
			continue
		if b.pos.y < FIELD_H + 20.0:
			live_eb.append(b)
	enemy_bullets = live_eb

func _update_enemies(delta: float) -> void:
	var live: Array = []
	var centre := Vector2(FIELD_W / 2, BASE_Y)
	for e in enemies:
		var def: Dictionary = StageData.ENEMIES[e.type]
		e.t += delta
		if float(e.get("hit_t", 0.0)) > 0.0:
			e.hit_t = float(e.hit_t) - delta   # the flinch after a hit (_draw_enemy)
		var prev: Vector2 = e.pos
		if e.state == "hatch":
			e.pos += e.vel * delta
			e.vel.y += 90.0 * delta
			if e.t > 0.7:
				e.state = "fly"
		match String(def.move):
			"straight":
				if e.state == "hatch":
					pass
				else:
					e.pos.y += e.speed * delta
				e.pos.x += sin(e.t * 1.6 + e.ph) * 8.0 * delta
			"flit":
				# Scouts dart sideways in quick bursts, then drift, like flies
				if e.state != "hatch" and not hive_brains:
					e.pos.y += e.speed * delta
				elif e.state != "hatch":
					e.dart_t = float(e.get("dart_t", 0.5)) - delta
					if e.dart_t <= 0.0:
						e.dart_t = rng.randf_range(0.6, 1.4)
						var side: float = -1.0 if rng.randf() < 0.5 else 1.0
						if e.pos.x < 60.0: side = 1.0
						elif e.pos.x > FIELD_W - 60.0: side = -1.0
						e.dart_vx = side * rng.randf_range(90.0, 150.0) * StageData.speed_mult(stage)
					e.dart_vx = float(e.get("dart_vx", 0.0)) * exp(-4.0 * delta)
					e.pos.x = clampf(e.pos.x + e.dart_vx * delta, 20.0, FIELD_W - 20.0)
					# a dart steals a little from the descent, the pause gives it back
					e.pos.y += e.speed * (1.15 - 0.4 * clampf(absf(e.dart_vx) / 150.0, 0.0, 1.0)) * delta
			"scurve":
				e.pos.y += e.speed * delta
				e.pos.x += cos(e.t * 1.4 + e.ph) * 80.0 * delta
			"hover":
				_spitter_dodge(e, delta)
				# descend to a third of the screen, then drift sideways and spit at the pilot
				var hover_y := FIELD_H * 0.3 + sin(e.ph) * 40.0
				if e.pos.y < hover_y and e.t < 9.0:
					e.pos.y += e.speed * delta
				elif e.t < 9.0:
					e.pos.x += sin(e.t * 0.9 + e.ph) * 50.0 * delta
					e.pos.y += 8.0 * delta
				else:
					e.pos.y += e.speed * 1.3 * delta   # done hovering: comes down for the base
				if e.fire_t > SPIT_WARN and e.fire_t - delta <= SPIT_WARN and e.pos.y > 40.0:
					Sfx.play("spit")   # the telegraph starts (drawn in _draw_enemy)
				e.fire_t -= delta
				if e.fire_t <= 0.0 and e.pos.y > 40.0:
					e.fire_t = float(def.fire_every)
					e.shots = int(e.get("shots", 0)) + 1
					# every other shot goes for the base instead of the pilot
					var aim_at: Vector2 = soldier_pos if e.shots % 3 != 0 else Vector2(e.pos.x + rng.randf_range(-60, 60), BASE_Y - 40.0)
					# a goo glob leaves the mouth of the sac on the art
					var mouth := EnemyRig.anchor("spitter", "muzzle", e.pos, float(def.size) * 1.35, float(e.get("tilt_s", 0.0)))
					var dir: Vector2 = (aim_at - mouth).normalized()
					enemy_bullets.append({"pos": mouth + dir * 4.0, "vel": dir * 135.0, "kind": "goo", "ph": rng.randf() * TAU})
					# from stage 25 a Spitter sometimes spits two globs in a small V
					if stage >= 25 and rng.randf() < 0.3:
						var d2 := dir.rotated(0.22 if rng.randf() < 0.5 else -0.22)
						enemy_bullets.append({"pos": mouth + d2 * 4.0, "vel": d2 * 135.0, "kind": "goo", "ph": rng.randf() * TAU})
					for k in 4:
						sparks.append({"pos": mouth, "vel": dir.rotated(rng.randf_range(-0.8, 0.8)) * rng.randf_range(30, 80), "life": 0.3, "col": Color(0.75, 0.4, 1.0)})
			"dive":
				# Kamikaze on the base (Rudy): flies in, stops to lock on (wings fold, a red line
				# shows where it will hit), then dives at the dome about twice as fast as other
				# bugs. It ignores the pilot. Shoot it during the dive or it hits the shield hard.
				if e.state == "fly":
					e.pos.y += e.speed * 1.3 * delta
					e.pos.x += sin(e.t * 1.2 + e.ph) * 30.0 * delta
					if e.pos.y > FIELD_H * float(e.get("lock_y", 0.24)):
						e.state = "aim"
						e.t_state = 0.0
						e.target = Vector2(clampf(e.pos.x + rng.randf_range(-110.0, 110.0), FIELD_W * 0.18, FIELD_W * 0.82), BASE_Y - DOME_RY * 0.85)
				elif e.state == "aim":
					e.t_state += delta
					e.pos.y += 6.0 * delta   # hangs in the air while it locks on
					if e.t_state > 0.6:
						e.state = "dive"
						# own field: e.vel is re-measured from movement every frame below
						e.dive_v = (Vector2(e.target) - e.pos).normalized() * e.speed * float(def.dive_mult)
				else:
					e.pos += Vector2(e.dive_v) * delta
			"spore":
				# a Drifter's spore pod: pops out, then sinks slowly toward the base, swaying
				e.vel.y = move_toward(float(e.vel.y), e.speed, 120.0 * delta)
				e.vel.x = float(e.vel.x) * exp(-2.0 * delta)
				e.pos += e.vel * delta + Vector2(sin(e.t * 2.3 + e.ph) * 14.0 * delta, 0.0)
			"boss":
				var enraged: bool = e.hp < e.hp_max * 0.5
				var hover_y := 210.0 + (80.0 if enraged else 0.0)
				if e.pos.y < hover_y:
					e.pos.y += e.speed * delta
				else:
					e.arrived = true   # settled on screen: only now can she be hurt (Rudy, dev163)
					Sfx.play("boss")
					var want_x: float = FIELD_W * 0.5 + sin(e.t * (0.8 if enraged else 0.5)) * (FIELD_W * 0.28)
					if enraged and absf(soldier_pos.x - e.pos.x) < 60.0:
						want_x += 120.0 * (1.0 if e.pos.x < FIELD_W * 0.5 else -1.0)
					e.pos.x = lerpf(e.pos.x, want_x, delta * (1.5 if enraged else 0.9))
				# angry: now and then she launches a Diver from her back
				if enraged and e.pos.y >= 160.0:
					e.launch_t = float(e.get("launch_t", 2.0)) - delta
					if e.launch_t <= 0.0:
						e.launch_t = float(def.launch_every)
						var d := _make_enemy("diver", e.pos + Vector2(rng.randf_range(-30.0, 30.0), -10.0))
						d.lock_y = (e.pos.y + 60.0) / FIELD_H
						live.append(d)
						_burst(e.pos, 16.0, Color(1.0, 0.75, 0.3), 6)
				if e.laying > 0.0:
					e.laying -= delta
				else:
					e.lay_t -= delta
					if e.lay_t <= 0.0 and e.pos.y >= 160.0:
						e.lay_t = float(def.lay_every) * (0.66 if e.hp < e.hp_max * 0.5 else 1.0)
						e.laying = 3.0
						e.hatched = false
				if e.laying > 0.0 and e.laying < 2.2 and not e.get("hatched", false):
					# the sac bursts: scouts crawl out of it, unfold, then fly
					e.hatched = true
					for k in (4 if e.hp < e.hp_max * 0.5 else 3):
						var s := {"id": next_enemy_id, "type": "scout", "pos": e.pos + Vector2(float(k - 1) * 36.0, -54.0),
							"hp": 2.0 * _hp_mult(), "hp_max": 2.0 * _hp_mult(),
							"speed": 62.0 * StageData.speed_mult(stage), "r": 13.6, "ph": rng.randf() * TAU,
							"state": "hatch", "t": 0.0, "vel": Vector2(float(k - 1) * 45.0, -70.0), "fire_t": 9.0, "lay_t": 0.0, "laying": 0.0,
							"hatchling": true, "fold": 1.0}
						next_enemy_id += 1
						live.append(s)
					_burst(e.pos + Vector2(0, -58), 40.0, Color(0.71, 0.55, 1.0), 22)   # the sacs on her back burst
					_fx_add("nova", e.pos + Vector2(0, -58), 60.0, 0.5, 0.0, 1.8, Color(0.8, 0.5, 1.0))
					_float_text(e.pos + Vector2(0, -110), "HATCHING!", Color(0.85, 0.6, 1.0), true)
					shake = maxf(shake, 0.35)
		# Frost Rounds: a slowed bug covers only part of its move
		if float(e.get("slow_t", 0.0)) > 0.0:
			e.slow_t = float(e.slow_t) - delta
			e.pos = prev.lerp(e.pos, 1.0 - float(e.get("slow", 0.0)))
		e.vel = (e.pos - prev) / maxf(delta, 0.001)
		# faster than its cruising speed (a dart, a dive): it stretches into the motion (dev153)
		e.stretch_s = lerpf(float(e.get("stretch_s", 0.0)), clampf(e.vel.length() / maxf(float(e.speed), 1.0) - 1.0, 0.0, 1.2) * 0.16, minf(1.0, delta * 12.0))
		# tilt and wing fold ease toward their targets so dives and hatches never snap
		e.tilt_s = lerp_angle(float(e.get("tilt_s", _enemy_tilt(e))), _enemy_tilt(e), minf(1.0, delta * 10.0))
		var want_fold: float = 1.0 if _lunging(e) or (e.state == "hatch" and e.t < 0.45) else 0.0
		e.fold = move_toward(float(e.get("fold", want_fold)), want_fold, delta * 5.0)
		if e.type == "hive_mother":
			# the white chunk trails the real health, then catches up
			if _boss_bar_hp < e.hp or _boss_bar_hp > e.hp_max:
				_boss_bar_hp = e.hp
			var layers := _boss_layers(e)
			var was := ceili(_boss_bar_hp / e.hp_max * layers - 0.0001)
			_boss_bar_hp = move_toward(_boss_bar_hp, maxf(e.hp, 0.0), delta * e.hp_max * 0.25)
			if ceili(_boss_bar_hp / e.hp_max * layers - 0.0001) < was:
				_boss_flash = 1.0   # a layer broke
				shake = maxf(shake, 0.3)
			if _intro.is_empty():
				if e.get("arrived", false):   # her bar slides in once she can be hurt (dev164)
					_boss_bar_in = minf(_boss_bar_in + delta * 3.0, 1.0)
		if e.hp <= 0.0:
			_kill(e)
			continue
		if e.type != "hive_mother" and Backdrop.inside_field(centre, DOME_RX, DOME_RY, e.pos):
			_hurt_base(float(def.get("base_dmg", 10.0)))
			if e.type == "diver":
				_burst(e.pos, 26.0, Color(1.0, 0.55, 0.3), 16)   # a kamikaze hit: bigger, hotter
				shake = maxf(shake, 0.55)
			else:
				_burst(e.pos, 14.0, Color(0.18, 0.9, 1.0), 10)
			continue
		if e.pos.y > FIELD_H + 40.0 or e.pos.x < -60.0 or e.pos.x > FIELD_W + 60.0:
			continue
		live.append(e)
	enemies = live + spawned
	spawned.clear()

# Spitters watch incoming bolts and sometimes sidestep one about to hit. The
# chance grows with the stage so early stages stay gentle.
func _spitter_dodge(e: Dictionary, delta: float) -> void:
	e.dodge_cd = maxf(float(e.get("dodge_cd", 0.0)) - delta, 0.0)
	e.dodge_v = float(e.get("dodge_v", 0.0)) * exp(-5.0 * delta)
	e.pos.x = clampf(e.pos.x + e.dodge_v * delta, 24.0, FIELD_W - 24.0)
	if e.dodge_cd > 0.0 or e.pos.y < 100.0 or not hive_brains:
		return
	for b in bullets:
		if b.vel.y >= 0.0 or b.pos.y < e.pos.y:
			continue
		var dt: float = (b.pos.y - e.pos.y) / -b.vel.y
		if dt > 0.45:
			continue
		var cross: float = b.pos.x + b.vel.x * dt
		if absf(cross - e.pos.x) > float(e.r) + 8.0:
			continue
		e.dodge_cd = 0.9   # one look per bolt; a missed roll still waits
		if rng.randf() < minf(0.35 + 0.05 * (stage - 1), 0.75):
			var side: float = 1.0 if e.pos.x >= cross else -1.0
			if e.pos.x < 70.0: side = 1.0
			elif e.pos.x > FIELD_W - 70.0: side = -1.0
			e.dodge_v = side * 190.0
			stat_dodges += 1
		return

func _lunging(e: Dictionary) -> bool:
	return e.type == "diver" and (e.state == "dive" or e.state == "aim")

# The tilt an enemy wants this frame; drawing uses e.tilt_s, which eases toward it.
func _enemy_tilt(e: Dictionary) -> float:
	if _lunging(e):
		return (Vector2(e.target) - e.pos).angle() + PI / 2.0 if e.has("target") else e.vel.angle() + PI / 2.0
	if e.type == "hive_mother":
		return 0.0
	return clampf(e.vel.x * 0.004, -0.35, 0.35) + sin(e.t * 6.0 + e.ph) * 0.05

func _kill(e: Dictionary) -> void:
	var def: Dictionary = StageData.ENEMIES[e.type]
	var worth: int = 1500 if e.type == "hive_mother" else (25 if e.type == "spore" else 100)
	score += worth
	_spawn_shards(e, def)
	Sfx.play("boss_kill" if e.type == "hive_mother" else "kill", rng.randf_range(0.9, 1.1))
	kills += 1
	_kills_by[e.type] = int(_kills_by.get(e.type, 0)) + 1
	_burst(e.pos, float(e.r), Color(1.0, 0.8, 0.4), 12 if e.type == "hive_mother" else 7)
	if e.type == "hive_mother":
		hitstop = 0.18
		shake = maxf(shake, 0.8)
	elif int(def.xp_tier) >= 1:
		hitstop = maxf(hitstop, 0.05)
	_float_text(e.pos, "+%d" % worth, Color(1.0, 0.85, 0.4))
	# a Drifter bursts into spore pods that drift down at the base
	for k in int(def.get("spores", 0)):
		var pod := _make_enemy("spore", e.pos)
		pod.vel = Vector2(rng.randf_range(-70.0, 70.0), rng.randf_range(-70.0, -30.0))
		spawned.append(pod)
	var tier: int = int(def.xp_tier)
	var count: int = 1
	if e.type == "hive_mother":
		count = 6
	if tier < 0:
		count = 0
	for i in count:
		gems.append({"pos": e.pos + Vector2(rng.randf_range(-16, 16), rng.randf_range(-10, 10)), "tier": tier, "life": 16.0,
			"vel": Vector2(rng.randf_range(-30, 30), rng.randf_range(-60, -20))})
	# upgrade parts are counted quietly and shown on the Stage Cleared screen (Rudy: no
	# need to show them dropping)
	for kind in _part_drops(e, def):
		_parts_got[kind] = int(_parts_got.get(kind, 0)) + 1
	# coins drop as pickups too (Rudy, dev108: gems = XP, coins = money); the boss showers them
	var ncoins: int = mini(int(def.coins), 10)   # a boss drops 10 coins worth her full reward between them
	for i in ncoins:
		gems.append({"pos": e.pos + Vector2(rng.randf_range(-14, 14), rng.randf_range(-8, 8)), "tier": 0, "coin": true, "life": 16.0,
			"value": float(def.coins) / float(ncoins),
			"vel": Vector2(rng.randf_range(-45, 45), rng.randf_range(-75, -30))})

func _update_gems(delta: float) -> void:
	var live: Array = []
	for g in gems:
		g.life -= delta
		var d: float = g.pos.distance_to(soldier_pos)
		g.pull = d < magnet_radius or _vacuum_t > 0.0   # end of a wave: everything flies in
		if g.pull:
			# (faster the closer it gets; never negative, so far-off pickups also come in)
			g.pos = g.pos.move_toward(soldier_pos, (320.0 + maxf(magnet_radius - d, 0.0) * 4.0 + (380.0 if _vacuum_t > 0.0 else 0.0)) * delta)
		else:
			g.vel.y = minf(g.vel.y + 70.0 * delta, 55.0)
			g.vel.x *= 0.98
			g.pos += g.vel * delta

		if d < 16.0 and g.has("part"):
			_parts_got[g.part] = int(_parts_got.get(g.part, 0)) + 1
			_float_text(soldier_pos + Vector2(0, -40), "+1 %s" % Parts.KINDS[g.part].name, Parts.KINDS[g.part].color)
			_fx_add("spark", g.pos, 26.0, 0.25, 0.0, 1.8, Parts.KINDS[g.part].color)
			continue
		if d < 16.0 and g.get("coin", false):
			_coins_f += float(g.get("value", 1.0)) * _coin_mult
			Sfx.play_rising("coin")
			coins_earned = int(_coins_f)
			_fx_add("spark", g.pos, 18.0, 0.2, 0.0, 1.7, Color(1.0, 0.85, 0.35))
			continue
		if d < 16.0:
			_gain_xp(float(StageData.GEM_XP[g.tier]) * _gem_xp_mult)
			_gems_got += 1
			Sfx.play_rising("gem")
			if _gem_shield:
				shield = minf(shield + 1.0, shield_max)   # Magnet overcharged
			if _barrage:
				_barrage_n += 1
				if _barrage_n >= 10:
					_barrage_n = 0
					_gem_barrage()
			_burst(soldier_pos, 4.0, StageData.GEM_COLORS[g.tier], 3)
			_fx_add("spark", g.pos, 20.0 + 4.0 * g.tier, 0.2, 0.0, 1.7, StageData.GEM_COLORS[g.tier])   # pop
			continue
		if (g.life <= 0.0 or g.pos.y > BASE_Y - DOME_RY * 0.5) and _vacuum_t <= 0.0:
			continue
		live.append(g)
	gems = live

func _gain_xp(amount: float) -> void:
	run_xp += amount
	var need := _xp_need()
	if run_xp >= need:
		run_xp -= need
		run_level += 1
		Sfx.play("level")
		_float_text(soldier_pos + Vector2(0, -40), "LEVEL %d" % run_level, Color(0.85, 0.75, 1.0), true)
		_open_cards()

func _xp_need() -> float:
	# the first card after 2 kills, then one about every 10-14 s; cards build up over the
	# whole stage (they reset only when a new stage starts). Past level 18 they slow down.
	var base := 4.0 + 3.0 * (run_level - 1)
	if run_level > 18:
		base *= pow(1.6, run_level - 18)
	return base * _xp_cut

# ------------------------------------------------------------------ turrets

# Turrets from the Gear loadout are mounted at the start of every run (mount =
# index into Backdrop.STRIP_SOCKETS), only on mounts the player has opened by clearing
# stages (Turrets.mount_open). Each type's numbers live in turrets.gd.
func _mount_turret(type: String, mount: int = -1, lvl: int = 1, fx: bool = true) -> bool:
	if mount < 0:
		for i in Backdrop.STRIP_SOCKETS.size():
			var taken := false
			for t in turrets:
				if t.mount == i:
					taken = true
			if not taken:
				mount = i
				break
	if mount < 0:
		return false
	# every turret drops onto its socket, one after another at the start of a run
	# (fx = true drops it straight away, used by tests)
	# t.def = this turret's numbers with its upgrade tracks and milestones in (Turrets.stats)
	turrets.append({"type": type, "lvl": lvl, "def": Turrets.stats(type, Turrets.one_tracks(turret_tracks, type)), "mount": mount, "pos": _socket(mount), "cd": 0.5 + 0.3 * mount,
		"fire_t": 0.0, "ang": -PI / 2.0, "face": 1.0, "charge": 0.0, "build": 0.0, "bolt": [],
		"drop": 0.0, "drop_wait": 0.0 if fx else 0.3 + 0.18 * mount})
	return true

func _socket(i: int) -> Vector2:
	return Backdrop.socket_pos(i, FIELD_W, FIELD_H - STRIP_LIFT)

func _turret_dmg(t: Dictionary) -> float:
	return float(t.def.damage) * _turret_dmg_mult

func _turret_hit(t: Dictionary, e: Dictionary, dmg: float) -> void:
	if not _can_hurt(e):
		return
	dmg *= Turrets.trait_mult(t.type, StageData.ENEMIES[e.type].traits)
	stat_turret_dmg += minf(dmg, maxf(e.hp, 0.0))
	e.hp -= dmg
	e.hit_t = HIT_FLINCH_T
	# turret card overcharges: Overload (Storm) stuns now and then, Frozen Light (Prism) slows
	if t.get("stun", false) and rng.randf() < 0.2:
		e.slow_t = 0.8
		e.slow = 0.95
	elif t.get("frost_light", false):
		e.slow_t = 1.5
		e.slow = maxf(float(e.get("slow", 0.0)), 0.3)

func _update_turrets(delta: float) -> void:
	for t in turrets:
		t.pos = _socket(t.mount)   # follows the screen height
		if t.drop < 1.0:
			t.drop_wait -= delta
			if t.drop_wait <= 0.0:
				t.drop = minf(t.drop + delta / 0.45, 1.0)
				if t.drop >= 1.0:
					# landed: a flash on the socket
					_fx_add("spark", t.pos + Vector2(0, -6), 70.0, 0.35, 0.0, 1.8)
					_burst(t.pos, 18.0, Color(0.2, 0.85, 1.0), 8)
			continue
		t.fire_t = maxf(t.fire_t - delta, 0.0)
		match String(t.type):
			"lance": _update_lance(t, delta * _turret_rate)
			"storm": _update_storm(t, delta * _turret_rate)
			"gravity": _update_gravity(t, delta * _turret_rate)
			"swarm": _update_swarm(t, delta * _turret_rate)
			"prism": _update_prism(t, delta * _turret_rate)
			_: _update_sentry(t, delta * _turret_rate)
	_update_drones(delta)

func _update_sentry(t: Dictionary, delta: float) -> void:
	var def: Dictionary = t.def
	# hover: lift off once landed, a spring for the shot dip, swing speed for the lean
	if float(t.drop) >= 1.0:
		t.lift = move_toward(float(t.get("lift", 0.0)), 1.0, delta * 1.4)
	var hv: float = float(t.get("hov_v", 0.0))
	var hy: float = float(t.get("hov_y", 0.0))
	hv += (-hy * 140.0 - hv * 9.0) * delta
	t.hov_y = hy + hv * delta
	t.hov_v = hv
	var prev_ang: float = float(t.ang)
	var best := -1
	var bd: float = float(def.range)
	for i in enemies.size():
		var d: float = t.pos.distance_to(enemies[i].pos)
		if enemies[i].pos.y > 100.0 and d < bd:
			bd = d
			best = i
	if best >= 0:
		_spring_ang(t, (enemies[best].pos - t.pos).angle(), delta, 110.0, 12.0)   # overshoots a touch and settles (dev153)
		t.swing = lerpf(float(t.get("swing", 0.0)), angle_difference(prev_ang, t.ang) / maxf(delta, 0.001), 0.2)
		t.face = move_toward(float(t.face), -1.0 if cos(t.ang) > 0.05 else (1.0 if cos(t.ang) < -0.05 else float(t.face)), delta * 6.0)
		t.cd -= delta
		if t.cd <= 0.0:
			t.cd = float(def.every)
			t.fire_t = FIRE_TIME.sentry
			t.hov_v = float(t.hov_v) + 55.0      # the shot pushes the head down toward its base
			var dir := Vector2.from_angle(t.ang)
			Sfx.play("turret", rng.randf_range(0.9, 1.1))
			bullets.append({"pos": _turret_tip(t), "vel": dir * 360.0, "dmg": _turret_dmg(t), "r": 18.0, "tid": -2, "col": "tracer", "src": t.type,
				"bounce": int(card_levels.get("sentry_ricochet", 0)), "splash": 55.0 if t.get("flak", false) else 0.0, "hits": []})
	else:
		# nothing in range: the head sweeps slowly from side to side, searching
		var search: float = -PI / 2.0 + sin(time_alive * 0.7 + float(t.mount) * 1.3) * 0.9
		t.ang = lerp_angle(t.ang, search, minf(1.0, delta * 2.0))
		t.ang_v = float(t.get("ang_v", 0.0)) * 0.8
		t.swing = lerpf(float(t.get("swing", 0.0)), angle_difference(prev_ang, t.ang) / maxf(delta, 0.001), 0.2)
		t.face = move_toward(float(t.face), -1.0 if cos(t.ang) > 0.05 else (1.0 if cos(t.ang) < -0.05 else float(t.face)), delta * 3.0)
		t.cd = maxf(float(t.cd) - delta, 0.0)

# is the bug on the Lance's firing line (from its tip along t.ang)?
func _lance_in_column(t: Dictionary, e: Dictionary) -> bool:
	var tip := _turret_tip(t)
	var dir := Vector2.from_angle(float(t.ang))
	var rel: Vector2 = e.pos - tip
	var along := rel.dot(dir)
	return along > 0.0 and absf(rel.cross(dir)) < float(t.def.width) * 0.5 + float(e.r) * 0.6 and e.pos.y > 90.0

# Lance: turns its cannon toward the nearest bug in range (sweeping slowly while it
# waits), charges, and fires a spear of light along that line that hits everything on
# it (enemy shots included).
func _update_lance(t: Dictionary, delta: float) -> void:
	var def: Dictionary = t.def
	var best := -1
	var bd := 650.0
	for i in enemies.size():
		var d: float = t.pos.distance_to(enemies[i].pos)
		if enemies[i].pos.y > 90.0 and d < bd:
			bd = d
			best = i
	var want: float = (enemies[best].pos - _turret_tip(t)).angle() if best >= 0 else -PI / 2.0 + sin(time_alive * 0.6 + float(t.mount)) * 0.7
	want = clampf(want, -PI + 0.15, -0.15)   # never aims down into the base
	if best >= 0:
		_spring_ang(t, want, delta, 70.0, 10.0)
		t.ang = clampf(float(t.ang), -PI + 0.15, -0.15)
	else:
		t.ang = lerp_angle(float(t.ang), want, minf(1.0, delta * 1.5))
		t.ang_v = float(t.get("ang_v", 0.0)) * 0.8
	t.charge = minf(t.charge + delta, float(def.every))
	if t.charge < float(def.every):
		return
	var any := false
	for e in enemies:
		if _lance_in_column(t, e):
			any = true
			break
	if not any:
		return
	# Twin Lance (card overcharge): a second beam a moment after the first
	if t.get("twin", false) and not t.get("twin_shot", false):
		t.charge = float(def.every) - 0.25
		t.twin_shot = true
	else:
		t.charge = 0.0
		t.twin_shot = false
	t.fire_t = FIRE_TIME.lance
	var dmg := _turret_dmg(t)
	for e in enemies:
		if _lance_in_column(t, e):
			_turret_hit(t, e, dmg)
			for k in 3:
				_fx_add("lance_flare", e.pos, 44.0, 0.3, 0.0, 1.4)
	var tip := _turret_tip(t)
	var dir := Vector2.from_angle(float(t.ang))
	var half: float = float(def.width) * 0.5
	enemy_bullets = enemy_bullets.filter(func(b): return (b.pos - tip).dot(dir) < 0.0 or absf((b.pos - tip).cross(dir)) > half)

func _storm_centre(t: Dictionary) -> Vector2:
	var def: Dictionary = t.def
	var sway: float = sin(time_alive * 0.4 + float(t.mount)) * 18.0
	return Vector2(clampf(t.pos.x, float(def.cloud_r) * 0.7, FIELD_W - float(def.cloud_r) * 0.7) + sway, BASE_Y - float(def.cloud_h))

# Storm Spire: the cloud builds over 3 s; then lightning strikes the enemy
# nearest the cloud's middle and jumps to up to `chain` more nearby (70% each).
func _update_storm(t: Dictionary, delta: float) -> void:
	var def: Dictionary = t.def
	t.build = minf(t.build + delta / 3.0, 1.0)
	# the cloud gathers when bugs come near and thins away when the sky is clear
	var near := false
	var cc := _storm_centre(t)
	for e in enemies:
		if e.pos.y > 100.0 and cc.distance_to(e.pos) < float(def.cloud_r) * 1.6:
			near = true
			break
	t.storm_a = move_toward(float(t.get("storm_a", 0.0)), 1.0 if near else 0.0, delta * 3.0)
	if t.fire_t <= 0.0:
		t.bolt = []
	if t.build < 1.0:
		return
	t.cd -= delta
	if t.cd > 0.0:
		return
	var c := _storm_centre(t)
	var first := {}
	var fd: float = float(def.cloud_r)
	for e in enemies:
		var d: float = c.distance_to(e.pos)
		if e.pos.y > 100.0 and d < fd:
			fd = d
			first = e
	if first.is_empty():
		t.cd = 0.2
		return
	t.cd = float(def.every)
	t.fire_t = FIRE_TIME.storm
	var dmg := _turret_dmg(t)
	var hit: Array = [first.id]
	var path: Array = [c, first.pos]
	_turret_hit(t, first, dmg)
	var last: Dictionary = first
	for k in int(def.chain):
		dmg *= 0.7
		var nxt := {}
		var nd := 110.0
		for e in enemies:
			if hit.has(e.id) or e.pos.y < 100.0:
				continue
			var d: float = last.pos.distance_to(e.pos)
			if d < nd:
				nd = d
				nxt = e
		if nxt.is_empty():
			break
		_turret_hit(t, nxt, dmg)
		hit.append(nxt.id)
		path.append(nxt.pos)
		last = nxt
	t.bolt = path
	t.bolt_seed = rng.randi()   # one fixed zigzag per strike, so the bolt doesn't jitter
	for p in path.slice(1):
		_fx_add("storm_zap", p, 40.0, 0.3, rng.randf() * TAU)

func _gravity_centre(t: Dictionary) -> Vector2:
	var def: Dictionary = t.def
	return Vector2(clampf(t.pos.x, float(def.radius), FIELD_W - float(def.radius)), BASE_Y - float(def.height))

# Gravity Anchor: for the last `pull` seconds of each cycle it drags enemies near
# its well toward the middle (bosses are too heavy), then crushes everything in
# the inner circle with a pulse. With nothing in reach it keeps pulling and waits.
func _update_gravity(t: Dictionary, delta: float) -> void:
	var def: Dictionary = t.def
	var c := _gravity_centre(t)
	t.cd = maxf(t.cd - delta, 0.0)
	var catching := false
	var in_crush := false
	# Black Hole (card overcharge): enemy shots inside the pull are swallowed
	if t.get("horizon", false):
		enemy_bullets = enemy_bullets.filter(func(b): return c.distance_to(b.pos) > float(def.radius))
	if t.cd <= float(def.pull):
		for e in enemies:
			if e.pos.y < 100.0 or e.type == "hive_mother":
				continue
			var d: float = c.distance_to(e.pos)
			if d < float(def.radius):
				catching = true
				e.pos = e.pos.move_toward(c, (40.0 + 70.0 * (1.0 - d / float(def.radius))) * delta)
			if d < float(def.crush_r):
				in_crush = true
	# the well only opens while it has something to pull, and fades in and out
	t.well_a = move_toward(float(t.get("well_a", 0.0)), 1.0 if catching else 0.0, delta * 3.0)
	if t.cd > float(def.pull):
		return
	if t.cd > 0.0 or not in_crush:
		return
	t.cd = float(def.every)
	t.fire_t = FIRE_TIME.gravity
	var dmg := _turret_dmg(t)
	for e in enemies:
		if e.pos.y > 100.0 and c.distance_to(e.pos) < float(def.crush_r):
			_turret_hit(t, e, dmg)
	_fx_add("crush", c, float(def.crush_r) * 1.9, 0.45, rng.randf() * TAU, 1.3)

# Swarm Hive: lets out a handful of micro-drones; they live in `drones`.
func _update_swarm(t: Dictionary, delta: float) -> void:
	var def: Dictionary = t.def
	var any := false
	for e in enemies:
		if e.pos.y > 100.0:
			any = true
			break
	# the hatch lid (dev162): opens over the half second before a launch, stays open while the
	# drones leave, closes after (drawn in _draw_turret)
	var want: float = 1.0 if ((any and t.cd < 0.55) or float(t.fire_t) > 0.0) else 0.0
	t.lid = move_toward(float(t.get("lid", 0.0)), want, delta * (9.0 if want > 0.5 else 3.5))
	t.cd -= delta
	if t.cd > 0.0:
		return
	if not any:
		t.cd = 0.2
		return
	t.cd = float(def.every)
	t.fire_t = FIRE_TIME.swarm
	for i in int(def.count):
		var a: float = -PI / 2.0 + lerpf(-0.7, 0.7, float(i) / maxf(float(def.count) - 1.0, 1.0))
		drones.append({"type": "swarm", "pos": _turret_tip(t), "vel": Vector2.from_angle(a) * 120.0,
			"life": float(def.life), "age": 0.0, "dmg": _turret_dmg(t), "boom": t.get("boom", false)})

# Each drone steers toward the nearest enemy, hits once and is gone.
func _update_drones(delta: float) -> void:
	var speed: float = float(Turrets.TURRETS.swarm.speed)
	var live: Array = []
	for dr in drones:
		dr.life -= delta
		dr.age += delta
		var best := {}
		var bd := 1e9
		for e in enemies:
			var d: float = dr.pos.distance_to(e.pos)
			if e.pos.y > 100.0 and d < bd:
				bd = d
				best = e
		if not best.is_empty():
			dr.vel = dr.vel.lerp((best.pos - dr.pos).normalized() * speed, minf(1.0, delta * 4.0))
			if bd < float(best.r) * 0.6 + 6.0:
				_turret_hit(dr, best, float(dr.dmg))
				if dr.get("boom", false):   # Kamikaze (card overcharge): the drone bursts on nearby bugs
					for o in enemies:
						if o != best and o.pos.distance_to(dr.pos) < 60.0:
							_turret_hit(dr, o, float(dr.dmg) * 0.6)
					_fx_add("nova", dr.pos, 50.0, 0.3, 0.0, 1.6, Color(0.4, 0.9, 1.0))
				_fx_add("pop", dr.pos, 30.0, 0.3, rng.randf() * TAU)
				continue
		dr.pos += dr.vel * delta
		if dr.life > 0.0:
			live.append(dr)
	drones = live

func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))

# Prism Tower: sends a bright orb up; at the split height it breaks into a fan of
# beams aimed around the nearest enemy, each hitting everything along its line.
func _update_prism(t: Dictionary, delta: float) -> void:
	var def: Dictionary = t.def
	var split := Vector2(t.pos.x, BASE_Y - float(def.split_h))
	if float(t.get("orb_t", 0.0)) > 0.0:
		t.orb_t -= delta
		if t.orb_t <= 0.0:
			var aim := -PI / 2.0
			var bd := 1e9
			for e in enemies:
				if e.pos.y > 100.0 and e.pos.y < split.y and split.distance_to(e.pos) < bd:
					bd = split.distance_to(e.pos)
					aim = clampf((e.pos - split).angle(), -PI / 2.0 - 1.0, -PI / 2.0 + 1.0)
			var segs: Array = []
			var n: int = int(def.beams)
			for i in n:
				var a: float = aim + lerpf(-float(def.spread), float(def.spread), float(i) / float(n - 1)) * 0.5
				segs.append([split, split + Vector2.from_angle(a) * 900.0])
			var dmg := _turret_dmg(t)
			for e in enemies:
				if e.pos.y < 100.0:
					continue
				for s in segs:
					if _seg_dist(e.pos, s[0], s[1]) < float(e.r) * 0.6 + 6.0:
						_turret_hit(t, e, dmg)
						break   # one hit per enemy per volley, even where beams overlap
			t.beams = segs
			t.fire_t = FIRE_TIME.prism
			_fx_add("prism_burst", split, 70.0, 0.4, 0.0, 1.3)
		return
	t.cd -= delta
	if t.cd > 0.0:
		return
	for e in enemies:
		if e.pos.y > 100.0 and e.pos.y < split.y:
			t.cd = float(def.every)
			t.orb_t = 0.25
			return
	t.cd = 0.2

# ------------------------------------------------------------------ damage, effects, end

func _hurt_base(amount: float) -> void:
	amount *= 1.0 - _base_dr   # gear milestones (Chest)
	hit_t = 0.0
	_took_damage = true
	shake = maxf(shake, 0.45 if shield <= 0.0 else 0.3)
	if shield > 0.0:
		Sfx.play("shield")
		shield = maxf(shield - amount, 0.0)
		if _bastion and shield <= 0.0:
			_bastion_blast()
	else:
		Sfx.play("hull")
		hull = maxf(hull - amount, 0.0)

func _hurt_pilot() -> void:
	if inv_t > 0.0:
		return
	inv_t = 1.5 * _recovery
	hearts -= 1
	Sfx.play("hurt")
	_hearts_lost += 1
	_took_damage = true
	shake = maxf(shake, 0.7)
	_burst(soldier_pos, 16.0, Color(1.0, 0.35, 0.42), 10)
	_float_text(soldier_pos + Vector2(0, -30), "-1 HEART", Color(1.0, 0.4, 0.45))

func _burst(p: Vector2, radius: float, col: Color, count: int = 7) -> void:
	rings.append({"pos": p, "life": 0.4, "max": 0.4, "r": radius * 2.6, "col": col})
	for k in count:
		sparks.append({"pos": p, "vel": Vector2(rng.randf_range(-120, 120), rng.randf_range(-120, 120)), "life": 0.4, "col": col})

func _float_text(p: Vector2, text: String, col: Color, big: bool = false) -> void:
	floaters.append({"pos": p + Vector2(rng.randf_range(-6, 6), 0), "text": text, "life": 1.1 if big else 0.9, "col": col, "big": big})

func _step_effects(delta: float) -> void:
	var live_fx: Array = []
	for f in fxs:
		f.life -= delta
		if f.life > 0.0:
			live_fx.append(f)
	fxs = live_fx
	var live: Array = []
	for s in sparks:
		s.pos += s.vel * delta
		s.vel *= 0.92
		s.life -= delta
		if s.life > 0.0:
			live.append(s)
	sparks = live
	live = []
	for r in rings:
		r.life -= delta
		if r.life > 0.0:
			live.append(r)
	rings = live
	live = []
	for f in floaters:
		f.pos.y -= 40.0 * delta
		f.life -= delta
		if f.life > 0.0:
			live.append(f)
	floaters = live

func _end_run(won: bool) -> void:
	if won:
		stage_cleared = true
		Sfx.play("win")
	else:
		game_over = true
		Sfx.play("lose")
	dragging = false
	var d := _read_save()
	# pilot XP: what you destroyed, plus a bonus the first time this stage is cleared
	var was := int(d.get("stage_unlocked", 1))
	var old_xp := int(d.get("pilot_xp", 0))
	_xp_bonus = Turrets.first_clear_bonus(stage) if won and not elite and promo < 0 and stage >= was else 0
	# a promotion trial: a win the first time = the next rank, for good (Promotion)
	_promoted = false
	if promo >= 0 and won and Promotion.won(d, promo):
		_promoted = true
		_xp_bonus = Promotion.XP_BONUS
		_write_save({"promotion": int(d.promotion)})
	_xp_gain = int(score / 50 * _pilot_xp_mult) + _xp_bonus
	_level_before = Turrets.pilot_level(old_xp)
	_level_after = Turrets.pilot_level(old_xp + _xp_gain)
	var patch := {"coins": int(d.get("coins", 0)) + coins_earned, "best_score": maxi(score, int(d.get("best_score", 0))),
		"best_kills": maxi(kills, int(d.get("best_kills", 0))), "pilot_xp": old_xp + _xp_gain}
	# stars for the stage map = the 3 stage objectives (_objectives): cleared, base hull
	# above half, no hearts lost (dev111; "no damage at all" was near impossible without regen)
	if won and not elite and promo < 0:
		var got := 1 + (1 if hull >= hull_max * 0.5 else 0) + (1 if _hearts_lost == 0 else 0)
		var st = d.get("stars", {})
		if typeof(st) != TYPE_DICTIONARY:
			st = {}
		st[str(stage)] = maxi(int(st.get(str(stage), 0)), got)
		patch["stars"] = st
		_stars_got = got
	# stage clear: 2 Alloy (+1 per 10 stages), a Plasma Cell on every 5th stage, all kept
	# with what was picked up (parts are kept even when the base falls)
	if won:
		_parts_got["alloy"] = int(_parts_got.get("alloy", 0)) + 2 + stage / 10
		if stage % 5 == 0:
			_parts_got["cell"] = int(_parts_got.get("cell", 0)) + 1
	var owned := Parts.read(d)
	for k in _parts_got:
		owned[k] = int(owned.get(k, 0)) + int(_parts_got[k])
	patch["parts"] = owned
	# a gear copy for merging (dev139): always on boss stages and in Elite, else about a
	# third of the time; the piece comes from this planet's set (GearData.roll_drop)
	_gear_got = {}
	if won and rng.randf() < GearData.drop_chance(stage, elite):
		_gear_got = GearData.roll_drop(stage, rng)
		var g := GearData.read(d)
		GearData.add_copy(g, _gear_got.id, _gear_got.rarity)
		patch["gear"] = GearData.write(g)
	# hero shards (heroes, dev172): a boss stage or an Elite win drops shards of the hero this
	# planet is weak to (Heroes.hero_for_planet), so stars come from playing where he shines
	_shards_got = {}
	if won and promo < 0 and (StageData.boss_kind(stage) != "" or elite):
		var hid := Heroes.hero_for_planet(stage)
		var sn := (3 if StageData.boss_kind(stage) == "boss" else 2) + (1 if elite else 0)
		var hh := Heroes.read(d)
		Heroes.add_shards(hh, hid, sn)
		patch["hero"] = Heroes.write(hh)
		_shards_got = {"id": hid, "n": sn}
	if won and promo < 0 and elite:   # Elite is its own ladder (dev167): a win opens the next Elite stage
		patch["elite_unlocked"] = maxi(stage + 1, int(d.get("elite_unlocked", 1)))
	if won and promo < 0 and not elite:   # a trial never unlocks stages; Elite has its own ladder
		patch["stage_unlocked"] = maxi(stage + 1, was)
		if Turrets.mounts_open(patch["stage_unlocked"]) > Turrets.mounts_open(was):
			_new_mount = Turrets.mounts_open(patch["stage_unlocked"]) - 1
		stage_unlocked = patch["stage_unlocked"]
	_write_save(patch)
	var ncards := 0
	for k in card_levels:
		ncards += int(card_levels[k])
	Progress.record_run({"kills": kills, "kills_by_type": _kills_by, "won": won, "stage": stage,
		"boss": StageData.boss_kind(stage) if won else "", "perfect": won and _stars_got == 3, "gems": _gems_got,
		"cards": ncards, "seconds": time_alive, "coins": coins_earned})
	_show_end(won)

# ------------------------------------------------------------------ UI

func _build_ui() -> void:
	# pause button: invisible hit area over the frame drawn in _draw_hud (a bit bigger, for thumbs)
	_pause_btn = Button.new()
	_pause_btn.flat = true
	_pause_btn.focus_mode = Control.FOCUS_NONE
	_pause_btn.position = PAUSE_RECT.position - Vector2(6, 6)
	_pause_btn.size = PAUSE_RECT.size + Vector2(12, 12)
	for st in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		_pause_btn.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	_pause_btn.pressed.connect(_toggle_pause)
	add_child(_pause_btn)
	for spec in [[SPEED_RECT, _cycle_speed], [CARDS_RECT, _toggle_cards]]:
		var hb := Button.new()
		hb.flat = true
		hb.focus_mode = Control.FOCUS_NONE
		hb.position = Rect2(spec[0]).position - Vector2(3, 6)
		hb.size = Rect2(spec[0]).size + Vector2(6, 12)
		for st in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
			hb.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		hb.pressed.connect(spec[1])
		add_child(hb)
	_cards_view = Control.new()
	_cards_view.visible = false
	add_child(_cards_view)
	# pause menu (filled by _fill_pause each time it opens)
	_pause_panel = Control.new()
	_pause_panel.visible = false
	add_child(_pause_panel)
	# card pick panel (filled when opened)
	_card_panel = Control.new()
	_card_panel.visible = false
	add_child(_card_panel)
	# end panel (filled when shown)
	_end_panel = Control.new()
	_end_panel.visible = false
	add_child(_end_panel)

# The 3 star objectives of every stage. state: "todo" (not decided yet), "ok" (on track),
# "done", "fail". Shown at the start, in the pause menu and on the Stage Cleared screen.
func _objectives(won: bool = false) -> Array:
	var hull_ok := hull >= hull_max * 0.5
	return [
		{"text": "Clear the stage", "state": "done" if won else "todo"},
		{"text": "Keep the base hull above half", "state": ("done" if won else "ok") if hull_ok else "fail"},
		{"text": "Lose no hearts", "state": ("done" if won else "ok") if _hearts_lost == 0 else "fail"},
	]

# a five-pointed star outline
func _star_pts(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	return pts

# At the start of a stage: a glass card with its three star objectives, for 4 s.
func _draw_objectives_banner() -> void:
	var t := time_alive
	if t > 4.6 or stage_cleared or game_over:
		return
	var a: float = smoothstep(0.2, 0.6, t) * (1.0 - smoothstep(4.0, 4.6, t))
	if a <= 0.01:
		return
	var r := Rect2(FIELD_W * 0.5 - 160, FIELD_H * 0.3, 320, 104)
	Glass.panel(_hc, Glass.box(r, 14.0), a, Color(0, 0, 0, 0), Color(0.03, 0.05, 0.12, 0.8))
	_hc.draw_string(title_font, r.position + Vector2(0, 24), "STAGE %d  ·  EARN 3 STARS" % stage, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, Color(Glass.GOLD, a))
	var objs := _objectives()
	for i in objs.size():
		var y: float = r.position.y + 46.0 + i * 20.0
		var st := _star_pts(Vector2(r.position.x + 30, y - 4), 6.5)
		_hc.draw_colored_polygon(st, Color(Glass.GOLD, 0.85 * a))
		_hc.draw_string(hud_font, Vector2(r.position.x + 46, y + 1), String(objs[i].text), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, a))

# The pause menu, rebuilt every time it opens so it shows the run as it is now: the
# stage, the wave, the star objectives so far, the cards you have, sound toggles
# (placeholders until there is sound), then Resume and Back to Hub, the same width.
func _fill_pause() -> void:
	for c in _pause_panel.get_children():
		c.queue_free()
	var vp := get_viewport_rect().size
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.01, 0.04, 0.6)
	dim.position = Vector2(0, -_safe_top)
	dim.size = vp
	_pause_panel.add_child(dim)
	var box := UIKit.panel(18)
	var w := 340.0
	box.custom_minimum_size = Vector2(w, 0)
	box.position = Vector2(FIELD_W * 0.5 - w * 0.5, HUD_H + 26)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	box.add_child(v)
	var title := UIKit.label("PAUSED", 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_override("font", title_font)
	v.add_child(title)
	v.add_child(UIKit.label(("PROMOTION TRIAL  ·  %s" % String(Promotion.RANKS[promo].name).to_upper()) if promo >= 0 else ("STAGE %d  ·  %s" % [stage, StageData.stage_name(stage).to_upper()]), 13, UIKit.CYAN, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UIKit.label("%s  ·  Wave %d of %d  ·  %02d:%02d" % [String(StageData.area(stage).name), mini(wave_index + 1, waves.size()), waves.size(), int(time_alive) / 60, int(time_alive) % 60], 12, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	# objectives
	v.add_child(UIKit.header("STARS"))
	for o in _objectives():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var st: String = o.state
		var mark := UIKit.label({"todo": "...", "ok": "on track", "done": "done", "fail": "missed"}[st], 11,
			{"todo": UIKit.MUTED, "ok": UIKit.CYAN, "done": Color(0.5, 1.0, 0.55), "fail": Color(1.0, 0.45, 0.45)}[st], HORIZONTAL_ALIGNMENT_RIGHT)
		var star := UIKit.label("★", 15, UIKit.GOLD if st != "fail" else Color(0.4, 0.4, 0.5))
		row.add_child(star)
		var tl := UIKit.label(String(o.text), 13, Color.WHITE)
		tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(tl)
		row.add_child(mark)
		v.add_child(row)
	# (YOUR CARDS left the pause menu in dev167: the HUD has the cards button)
	# sound and music (placeholders, saved for when sound arrives)
	var d := _read_save()
	var srow := HBoxContainer.new()
	srow.add_theme_constant_override("separation", 8)
	for spec in [["sound_on", "Sound"], ["music_on", "Music"]]:
		var key: String = spec[0]
		var on := bool(d.get(key, true))
		var b := UIKit.ghost_button("%s: %s" % [spec[1], "On" if on else "Off"], 13)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func():
			var now := not bool(_read_save().get(key, true))
			_write_save({key: now})
			if key == "sound_on":
				Sfx.set_on(now)
			b.text = "%s: %s" % [spec[1], "On" if now else "Off"])
		srow.add_child(b)
	v.add_child(srow)
	var resume := UIKit.gold_button("Resume", 17)
	resume.custom_minimum_size = Vector2(0, 46)
	resume.pressed.connect(_toggle_pause)
	v.add_child(resume)
	var quit_b := UIKit.ghost_button("Back to Hub", 14)
	quit_b.custom_minimum_size = Vector2(0, 42)
	quit_b.pressed.connect(func(): get_tree().change_scene_to_file("res://hub.tscn"))
	v.add_child(quit_b)
	v.add_child(UIKit.label("Leaving ends this run (you restart the stage).", 11, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	_pause_panel.add_child(box)
	box.size = Vector2(340.0, box.get_combined_minimum_size().y)
	UIKit.pop_in(box)   # the menu pops into place (dev157)

func _toggle_pause() -> void:
	if _cards_open:
		_toggle_cards()
		return
	if picking or game_over or stage_cleared:
		return
	paused = not paused
	if paused:
		_fill_pause()
	_pause_panel.visible = paused
	# the tap on the pause button also started a drag; drop it so he does not keep firing
	dragging = false
	drag_id = -1
	queue_redraw()

func _open_cards() -> void:
	picking = true
	Sfx.play("card_open")
	dragging = false
	for c in _card_panel.get_children():
		c.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = Vector2(FIELD_W, FIELD_H)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_card_panel.add_child(dim)
	var title := UIKit.label("LEVEL %d" % run_level, 20, Color(0.85, 0.75, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_override("font", title_font)
	title.position = Vector2(0, FIELD_H * 0.5 - 250)
	title.size = Vector2(FIELD_W, 30)
	_card_panel.add_child(title)
	var sub := UIKit.label("Choose a power card", 13, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	sub.position = Vector2(0, FIELD_H * 0.5 - 222)
	sub.size = Vector2(FIELD_W, 20)
	_card_panel.add_child(sub)
	var picks := _offer()
	var cw := 136.0
	var ch := 204.0
	var gap := 10.0
	var x0 := FIELD_W * 0.5 - (cw * 3.0 + gap * 2.0) * 0.5
	for i in picks.size():
		var id: String = picks[i]
		var card := _make_card(id, Vector2(x0 + i * (cw + gap), FIELD_H * 0.5 - 190), Vector2(cw, ch))
		_card_panel.add_child(card)
		# the three cards rise in one after another and settle with a small overshoot
		card.pivot_offset = Vector2(cw, ch) * 0.5
		card.scale = Vector2(0.82, 0.82)
		card.modulate.a = 0.0
		card.position.y += 26.0
		var tw := card.create_tween().set_parallel(true)
		tw.tween_property(card, "modulate:a", 1.0, 0.18).set_delay(0.07 * i)
		tw.tween_property(card, "scale", Vector2.ONE, 0.32).set_delay(0.07 * i).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(card, "position:y", card.position.y - 26.0, 0.32).set_delay(0.07 * i).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var refresh := UIKit.ghost_button("Refresh (%d left)" % refreshes if refreshes > 0 else "No refresh left", 13)
	refresh.position = Vector2(FIELD_W * 0.5 - 80, FIELD_H * 0.5 + 30)
	refresh.size = Vector2(160, 34)
	refresh.disabled = refreshes <= 0
	refresh.pressed.connect(func():
		if refreshes > 0:
			refreshes -= 1
			_open_cards())
	if _card_panel.get_child_count() > 3:
		Tips.first(get_tree(), [["cards", _card_panel.get_child(3)]])   # the first card
	_card_panel.add_child(refresh)
	_card_panel.visible = true

# A card's picture: Luna's cards/pic_<id>.png, else a menu icon. A fusion without its
# own picture shows its two parts side by side, overlapping.
func _card_pic(id: String, h: float) -> Control:
	if Cards.FUSIONS.has(id) and not ResourceLoader.exists("res://cards/pic_%s.png" % id):
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", -int(h * 0.3))
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for part in Cards.FUSIONS[id].parts:
			var p := _card_pic(part, h)
			p.custom_minimum_size = Vector2(h, h)
			row.add_child(p)
		return row
	var icon := TextureRect.new()
	var pic_path := "res://cards/pic_%s.png" % id
	if ResourceLoader.exists(pic_path):
		icon.texture = load(pic_path)
		icon.custom_minimum_size = Vector2(0, h)
		if id == "nova_burst":
			var add := CanvasItemMaterial.new()
			add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD   # painted as light on black
			icon.material = add
	elif Cards.CARDS.has(id) and Cards.CARDS[id].has("turret"):
		# a turret card shows its turret until Luna paints the card (LUNA-BRIEF-turret-cards.md)
		icon.texture = _tex[Turrets.TURRETS[Cards.CARDS[id].turret].art + "_idle"]
		icon.custom_minimum_size = Vector2(0, h * 0.9)
	else:
		icon.texture = Icons.get_icon(String(Cards.def(id).get("icon", "event")))
		icon.custom_minimum_size = Vector2(0, h * 0.76)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon

func _make_card(id: String, pos: Vector2, size: Vector2) -> Control:
	var def: Dictionary = Cards.def(id)
	var fusion := Cards.FUSIONS.has(id)
	var lvl: int = int(card_levels.get(id, 0))
	var col: Color = Cards.COLOR[def.rarity]
	var b := Button.new()
	b.position = pos
	b.size = size
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var over := not fusion and Cards.overcharges(id, lvl)
	var frame := TextureRect.new()
	# Luna's fusion and overcharge frames; the rarity frame otherwise
	var special := "res://cards/frame_fusion.png" if fusion else ("res://cards/frame_overcharge.png" if over else "")
	var own_frame := special != "" and ResourceLoader.exists(special)
	var fpath: String = special if own_frame else Cards.FRAME[def.rarity]
	frame.texture = load(fpath)
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(frame)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 24; v.offset_right = -24; v.offset_top = 24; v.offset_bottom = -22   # text kept well inside the frame
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_card_pic(id, 50.0 if fusion or over else 62.0))
	var name_l := UIKit.label(def.name, 12, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(name_l)
	var gold := Color(1.0, 0.82, 0.32)
	var tag := "FUSION" if fusion else ("OVERCHARGE" if over else String(def.rarity).to_upper() + ("  Lv.%d" % (lvl + 1)))
	v.add_child(UIKit.label(tag, 10, gold if over else col, HORIZONTAL_ALIGNMENT_CENTER))
	# an overcharge card shows only its new bonus (the card itself is known by now)
	if not over:
		var d := UIKit.label(def.desc, 10, Color(0.8, 0.88, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(d)
	if over:
		var od := UIKit.label("+ " + String(Cards.OVERCHARGE[id]), 10, gold, HORIZONTAL_ALIGNMENT_CENTER)
		od.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(od)
	if (over or fusion) and not own_frame:
		# without its own frame: a thin edge that breathes, on top of the rarity frame
		var edge := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0)
		sb.border_color = gold if over else col
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(6)
		edge.add_theme_stylebox_override("panel", sb)
		edge.set_anchors_preset(Control.PRESET_FULL_RECT)
		edge.offset_left = 5; edge.offset_right = -5; edge.offset_top = 5; edge.offset_bottom = -5
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(edge)
		var tw := edge.create_tween().set_loops()
		tw.tween_property(edge, "modulate:a", 0.35, 0.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(edge, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	b.add_child(v)
	b.pressed.connect(func(): _pick_card(id))
	return b

func _pick_card(id: String) -> void:
	Sfx.play("card")
	if Cards.FUSIONS.has(id):
		card_levels[id] = 1
		_fuse(id)
		_card_panel.visible = false
		picking = false
		return
	var over := Cards.overcharges(id, int(card_levels.get(id, 0)))
	card_levels[id] = int(card_levels.get(id, 0)) + 1
	if over:
		_overcharge(id)
	match id:
		"rapid_pulse": fire_rate_mult *= 1.10
		"heavy_bolts": damage_mult *= 1.15
		"burst_fire": burst_count += 1
		"aegis":
			max_hearts = mini(max_hearts + 1, 5)
			_aegis_flash = 1.0
			if _rig_view:
				_rig_view.shield_form = 0.0   # the band closes in around him
			hearts = mini(hearts + 1, max_hearts)
		"magnet":
			magnet_level += 1
			magnet_radius = _magnet_base + 40.0 * magnet_level   # +40 px per card (on top of the boots)
			_gem_xp_mult *= 1.1
		"reinforced_hull":
			shield_max += 30.0
			shield = minf(shield + 30.0, shield_max)
			hull_max += 20.0
			hull = minf(hull + 20.0, hull_max)
		"chain_spark": chain_level += 1
		"piercing_rounds": pierce_level += 1
		"frost_rounds": frost_level += 1
		"turret_overclock": _turret_rate *= 1.15
		# turret cards: change that turret's own numbers (t.def)
		"lance_focus": _turret_mod("lance", _lance_focus)
		"storm_chain": _turret_mod("storm", func(t): t.def.chain = int(t.def.chain) + 2)
		"gravity_horizon": _turret_mod("gravity", _gravity_grow)
		"swarm_surge": _turret_mod("swarm", func(t): t.def.count = int(t.def.count) + 2)
		"prism_fan": _turret_mod("prism", func(t): t.def.beams = int(t.def.beams) + 2)
		"shield_recharge": _shield_rate += 0.01
		"nova_burst":
			for e in enemies.duplicate():
				if e.type != "hive_mother":
					e.hp = 0.0
					_kill(e)
			enemies = enemies.filter(func(e): return e.type == "hive_mother")
			_burst(soldier_pos, 60.0, Color(1.0, 0.9, 0.6), 24)
			_fx_add("nova", soldier_pos, 150.0, 0.7, 0.0, 4.5)   # Luna's white-gold ring sweeps the screen
			shake = maxf(shake, 0.6)
	_float_text(soldier_pos + Vector2(0, -56), Cards.CARDS[id].name, Cards.COLOR[Cards.CARDS[id].rarity])
	_card_panel.visible = false
	picking = false

# The third pick of a card: its extra bonus (Cards.OVERCHARGE), with a gold flourish.
# Turret cards: run `f` on every turret of this type on the base.
func _turret_mod(type: String, f: Callable) -> void:
	for t in turrets:
		if String(t.type) == type:
			f.call(t)

func _lance_focus(t: Dictionary) -> void:
	t.def.width = float(t.def.width) * 1.4
	t.def.damage = float(t.def.damage) * 1.3

func _gravity_grow(t: Dictionary) -> void:
	t.def.radius = float(t.def.radius) * 1.25
	t.def.crush_r = float(t.def.crush_r) * 1.25

func _overcharge(id: String) -> void:
	match id:
		"sentry_ricochet": _turret_mod("sentry", func(t): t.flak = true)
		"lance_focus": _turret_mod("lance", func(t): t.twin = true)
		"storm_chain": _turret_mod("storm", func(t): t.stun = true)
		"gravity_horizon": _turret_mod("gravity", func(t): t.horizon = true)
		"swarm_surge": _turret_mod("swarm", func(t): t.boom = true)
		"prism_fan": _turret_mod("prism", func(t): t.frost_light = true)
		"rapid_pulse": _overdrive = true
		"heavy_bolts": _crit6 = true
		"piercing_rounds": _pierce_bonus = true
		"frost_rounds": _frost_bonus = true
		"turret_overclock": _turret_dmg_mult *= 1.3
		"burst_fire": _burst_pierce = true
		"magnet": _gem_shield = true
		"reinforced_hull":
			shield_max += 40.0
			shield = minf(shield + 40.0, shield_max)
		"aegis": _aegis_heal = true
		"chain_spark": _chain_mult = 2.0
		"shield_recharge": _hull_rate = 0.004
	var gold := Color(1.0, 0.82, 0.32)
	_float_text(soldier_pos + Vector2(0, -80), "OVERCHARGED!", gold, true)
	_burst(soldier_pos, 34.0, gold, 18)
	_fx_add("nova", soldier_pos, 40.0, 0.5, 0.0, 1.6, gold)

# A fusion card (Cards.FUSIONS): both parts were overcharged; it adds its own power.
func _fuse(id: String) -> void:
	match id:
		"railstorm": _railstorm = true
		"gem_barrage": _barrage = true
		"bastion": _bastion = true
		"thunder_lance": _thunder = true
	var pink: Color = Cards.COLOR.fusion
	_float_text(soldier_pos + Vector2(0, -80), "FUSION!", pink, true)
	_burst(soldier_pos, 46.0, pink, 26)
	_fx_add("nova", soldier_pos, 60.0, 0.6, 0.0, 2.2, pink)
	shake = maxf(shake, 0.35)

# The three cards of a pick; a ready fusion takes the middle slot.
func _offer() -> Array:
	var picks := Cards.draw(card_levels, 3, rng, run_level, not turrets.is_empty(), turrets.map(func(tt): return String(tt.type)))
	var ready := Cards.fusions_ready(card_levels)
	if not ready.is_empty():
		var f: String = ready[rng.randi() % ready.size()]
		if picks.size() >= 2:
			picks[1] = f
		else:
			picks.append(f)
	return picks

# Chain Spark: lightning jumps from a hit bug to the nearest others.
func _chain(from: Dictionary, count: int, dmg: float) -> void:
	var near: Array = []
	for o in enemies:
		if o.id != from.id and o.hp > 0.0 and o.pos.distance_to(from.pos) < 160.0:
			near.append(o)
	near.sort_custom(func(a, b): return a.pos.distance_squared_to(from.pos) < b.pos.distance_squared_to(from.pos))
	for i in mini(count, near.size()):
		var o: Dictionary = near[i]
		o.hp -= dmg if _can_hurt(o) else 0.0
		stat_pilot_dmg += dmg
		zaps.append({"a": from.pos, "b": o.pos, "life": 0.22, "seed": rng.randf() * 100.0})
		_fx_add("spark", o.pos, 26.0, 0.2, rng.randf() * TAU, 1.6, Color(0.7, 0.9, 1.0))

# Gem Barrage: a fan of bolts at the nearest bugs.
func _gem_barrage() -> void:
	var from := _muzzle_world()
	var targets: Array = enemies.filter(func(e): return e.pos.y > 80.0)
	targets.sort_custom(func(a, b): return a.pos.distance_squared_to(from) < b.pos.distance_squared_to(from))
	for k in 6:
		var dir := Vector2.UP.rotated(lerpf(-0.5, 0.5, k / 5.0))
		if not targets.is_empty():
			dir = (Vector2(targets[k % targets.size()].pos) - from).normalized()
		_fire(from + dir * 4.0, dir)
	_burst(from, 18.0, Cards.COLOR.fusion, 8)

# Bastion: the shield breaks outward, hurting and shoving back every bug near the dome.
func _bastion_blast() -> void:
	var c := Vector2(FIELD_W / 2, BASE_Y)
	for e in enemies:
		if e.pos.distance_to(c) < 330.0:
			e.hp -= (6.0 * damage_mult) if _can_hurt(e) else 0.0
			if e.type != "hive_mother":
				e.pos += (e.pos - c).normalized() * 70.0
	_fx_add("nova", c + Vector2(0, -60), 220.0, 0.6, 0.0, 1.8, Color(0.55, 0.85, 1.0))
	_float_text(c + Vector2(0, -150), "BASTION!", Cards.COLOR.fusion, true)
	shake = maxf(shake, 0.5)

# The drone sidekick (Gear > Drone, DroneData): one drone flies beside the pilot and
# shoots with its pod. Scout fires faster, Striker hits harder and further, Warden
# also blocks an enemy shot near the pilot every few seconds.
# The drone follows on a spring (dev147, motion item 26 c): it lags behind the pilot when
# he moves, overshoots a little and settles, bobbing on its own; it banks into the motion.
var _drone_p := Vector2.ZERO        # where the drone is now
var _drone_v := Vector2.ZERO        # and how fast it is going
var _drone_bank := 0.0              # lean from its sideways speed
const DRONE_K := 60.0               # spring stiffness
const DRONE_DAMP := 10.0            # damping (a little under critical: a small overshoot)

func _drone_pos() -> Vector2:
	return _drone_p

func _drone_target() -> Vector2:
	return soldier_pos + Vector2(-54.0, 6.0 + sin(time_alive * 3.0) * 4.0)

func _update_drone(delta: float) -> void:
	_drone_flash = maxf(_drone_flash - delta, 0.0)
	_drone_beam.life = maxf(float(_drone_beam.get("life", 0.0)) - delta, 0.0)
	if not _drone_on:
		return
	var tgt := _drone_target()
	if _drone_p == Vector2.ZERO:
		_drone_p = tgt
	# a damped spring toward the spot beside the pilot (stable at 30-120 fps)
	var dt := minf(delta, 0.05)
	_drone_v += ((tgt - _drone_p) * DRONE_K - _drone_v * DRONE_DAMP) * dt
	_drone_p += _drone_v * dt
	_drone_bank = lerpf(_drone_bank, clampf(_drone_v.x / 600.0, -0.35, 0.35), minf(1.0, dt * 8.0))
	_drone_tilt = lerpf(_drone_tilt, _drone_bank, minf(1.0, dt * 4.0))   # the thrusters follow a beat later
	var body: Dictionary = DroneData.BODIES[_drone.body]
	var pod: Dictionary = DroneData.PODS[_drone.pod]
	var p := _drone_pos()
	# Warden: swats one enemy shot near the pilot every few seconds
	if body.has("guard"):
		_drone_guard = maxf(_drone_guard - delta, 0.0)
		if _drone_guard <= 0.0:
			for b in enemy_bullets:
				if b.pos.distance_to(soldier_pos) < 70.0:
					_drone_beam = {"a": p, "b": b.pos, "life": 0.15, "col": Color(0.71, 0.55, 1.0)}
					_burst(b.pos, 8.0, Color(0.71, 0.55, 1.0), 6)
					b.pos = Vector2(-999, -999)
					_drone_guard = float(body.guard)
					break
	var best := {}
	var bd: float = float(body.range)
	for e in enemies:
		var d: float = p.distance_to(e.pos)
		if e.pos.y > 90.0 and d < bd:
			bd = d
			best = e
	if best.is_empty():
		_drone_aim = lerp_angle(_drone_aim, -PI / 2.0, delta * 3.0)
		return
	_drone_aim = lerp_angle(_drone_aim, (Vector2(best.pos) - p).angle(), minf(1.0, delta * 10.0))
	_drone_cd -= delta * float(body.rate) * DroneData.rate_bonus(int(_drone.level))
	if _drone_cd > 0.0:
		return
	_drone_cd = float(pod.every)
	_drone_flash = 0.12
	var dmg: float = float(WEAPONS.laser_pistol.damage) * float(pod.damage) * float(body.dmg) * DroneData.level_mult(int(_drone.level)) * DroneData.dmg_bonus(int(_drone.level))
	var dir := Vector2.from_angle(_drone_aim)
	match String(_drone.pod):
		"beam":
			# instant hit: a purple line to the target
			best.hp -= dmg if _can_hurt(best) else 0.0
			stat_pilot_dmg += dmg
			_drone_beam = {"a": p + dir * 14.0, "b": best.pos, "life": 0.18, "col": Color(0.8, 0.5, 1.0)}
			_fx_add("impact", best.pos, 24.0, 0.2, 0.0, 1.6, Color(0.85, 0.6, 1.0))
		"missile":
			bullets.append({"pos": p + dir * 12.0, "vel": dir * 260.0, "dmg": dmg, "r": 12.0, "tid": int(best.id), "col": "missile",
				"big": false, "pierce": false, "hits": [], "homing": int(best.id), "splash": float(pod.splash)})
		_:
			for s in [-1.0, 1.0]:
				var off: Vector2 = dir.orthogonal() * 5.0 * float(s)
				bullets.append({"pos": p + dir * 12.0 + off, "vel": dir * 500.0, "dmg": dmg, "r": 9.0, "tid": int(best.id), "col": "cyan",
					"big": false, "pierce": false, "hits": []})

func _draw_drone() -> void:
	if not _drone_on:
		return
	var p := _drone_pos()
	var rot := _drone_aim + PI / 2.0   # the painted drones face up
	var pt: Texture2D = _tex["pod_" + String(_drone.pod)]
	var bt: Texture2D = _tex["body_" + String(_drone.body)]
	var bw := 46.0
	var bh: float = bw * bt.get_height() / bt.get_width()
	var pw := 18.0
	var ph: float = pw * pt.get_height() / pt.get_width()
	var sq := Vector2(1.0 - absf(_drone_bank) * 0.25, 1.0)
	var hull_key := "hull_" + String(_drone.body)
	if _tex.has(hull_key):
		# Luna's parts (dev160): hull, left and right thrusters. The thrusters follow the
		# hull's bank a beat late (follow-through) and their props spin.
		var look: Dictionary = DRONE_PARTS[_drone.body]
		var ht: Texture2D = _tex[hull_key]
		var hw: float = float(look.hull_w)
		var hh: float = hw * ht.get_height() / ht.get_width()
		var base := Transform2D(rot + _drone_bank, sq, 0.0, p)
		for side in [-1.0, 1.0]:
			var tt: Texture2D = _tex["thruster_%s_%s" % ["l" if side < 0.0 else "r", String(_drone.body)]]
			var th: float = float(look.thr_h)
			var tw: float = th * tt.get_width() / tt.get_height()
			var at := Vector2(side * (hw * 0.5 + tw * float(look.thr_out)), float(look.thr_y) * hh)
			# lagging tilt, plus a spin for the ring props (the picture turns round its centre)
			var spin: float = time_alive * 9.0 * side if look.spin else 0.0
			draw_set_transform_matrix(base * Transform2D(_drone_tilt * 0.5 + spin, at))
			draw_texture_rect(tt, Rect2(-tw * 0.5, -th * 0.5, tw, th), false)
		draw_set_transform_matrix(base)
		draw_texture_rect(pt, Rect2(-pw * 0.5, -hh * 0.35 - ph * 0.5, pw, ph), false)
		draw_texture_rect(ht, Rect2(-hw * 0.5, -hh * 0.5, hw, hh), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	# the body banks into its sideways motion and squeezes a touch as it does (3D feel)
	draw_set_transform(p, rot + _drone_bank, sq)
	draw_texture_rect(pt, Rect2(-pw * 0.5, -bh * 0.35 - ph * 0.5, pw, ph), false)
	draw_texture_rect(bt, Rect2(-bw * 0.5, -bh * 0.5, bw, bh), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# Luna's drone parts (dev160): how wide the hull is drawn, how tall a thruster is, how far
# out from the hull's edge it sits (as a share of its own width), its height on the hull
# (share of hull height, 0 = centre), and whether its ring prop spins.
const DRONE_PARTS := {
	"scout":   {"hull_w": 30.0, "thr_h": 20.0, "thr_out": 0.35, "thr_y": 0.0, "spin": true},
	"striker": {"hull_w": 36.0, "thr_h": 34.0, "thr_out": 0.25, "thr_y": 0.0, "spin": false},
	"warden":  {"hull_w": 32.0, "thr_h": 32.0, "thr_out": 0.3, "thr_y": 0.0, "spin": false},
}
var _drone_tilt := 0.0   # the thrusters' lagging bank

# on the light layer: the pod's muzzle flash and beams
func _draw_drone_light() -> void:
	if float(_drone_beam.get("life", 0.0)) > 0.0:
		var a: float = float(_drone_beam.life) / 0.18
		_fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_fx.draw_line(_drone_beam.a, _drone_beam.b, Color(_drone_beam.col, a), 3.0, true)
		_fx.draw_line(_drone_beam.a, _drone_beam.b, Color(1, 1, 1, a), 1.0, true)
	if _drone_on and _drone_flash > 0.0:
		var ft: Texture2D = _fx_tex["drone_flash_" + String(_drone.pod)]
		var p := _drone_pos() + Vector2.from_angle(_drone_aim) * 22.0
		var fw := 30.0
		_fx.draw_set_transform(p, _drone_aim, Vector2.ONE)
		_fx.draw_texture_rect(ft, Rect2(0, -fw * ft.get_height() / ft.get_width() * 0.5, fw, fw * ft.get_height() / ft.get_width()), false, Color(1, 1, 1, _drone_flash / 0.12))
		_fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# spark arcs: short jagged lines on the light layer
func _draw_zaps() -> void:
	_fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for z in zaps:
		var a: float = clampf(z.life / 0.22, 0.0, 1.0)
		var pts := PackedVector2Array()
		var n := 6
		for k in n + 1:
			var t := float(k) / n
			var p: Vector2 = Vector2(z.a).lerp(z.b, t)
			if k > 0 and k < n:
				var nrm: Vector2 = (Vector2(z.b) - Vector2(z.a)).orthogonal().normalized()
				p += nrm * sin(z.seed + k * 2.3 + time_alive * 40.0) * 7.0
			pts.append(p)
		_fx.draw_polyline(pts, Color(0.6, 0.85, 1.0, a), 2.0, true)
		_fx.draw_polyline(pts, Color(1, 1, 1, a), 1.0, true)

# Stage Cleared / Base Lost, in the glass style (Rudy, dev111): the title, three big
# stars that pop in one by one, the objectives that earned them (or didn't), the
# rewards on glass tiles, what unlocked, then Next stage / Play again / Hub.
func _show_end(won: bool) -> void:
	for c in _end_panel.get_children():
		c.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.01, 0.04, 0.68)
	dim.position = Vector2(0, -_safe_top)
	dim.size = get_viewport_rect().size
	_end_panel.add_child(dim)
	var w := 350.0
	var p := UIKit.panel(18)
	p.custom_minimum_size = Vector2(w, 0)
	p.position = Vector2(FIELD_W * 0.5 - w * 0.5, HUD_H + 10)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 9)
	var area_done: bool = won and StageData.boss_kind(stage) == "boss" and not elite and promo < 0
	var title := "AREA COMPLETE" if area_done else ("STAGE CLEARED" if won else "BASE LOST")
	if promo >= 0:   # a promotion trial (Promotion)
		title = "PROMOTED!" if _promoted else ("TRIAL CLEARED" if won else "TRIAL FAILED")
	var t := UIKit.label(title, 24, UIKit.GOLD if won else Color(1.0, 0.4, 0.45), HORIZONTAL_ALIGNMENT_CENTER)
	t.add_theme_font_override("font", title_font)
	v.add_child(t)
	if promo >= 0:
		v.add_child(UIKit.label("PROMOTION TRIAL  ·  %s" % String(Promotion.RANKS[promo].name).to_upper(), 13, UIKit.CYAN, HORIZONTAL_ALIGNMENT_CENTER))
	else:
		v.add_child(UIKit.label("%s %d  ·  %s" % ["ELITE" if elite else "STAGE", stage, StageData.stage_name(stage).to_upper()], 13, UIKit.CYAN, HORIZONTAL_ALIGNMENT_CENTER))
	if _promoted:
		var pr := Promotion.rank(_read_save())
		v.add_child(UIKit.label("RANK: %s" % String(Promotion.RANKS[promo].name).to_upper(), 16, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
		v.add_child(UIKit.label("For good: %s" % Promotion.bonus_text(pr), 12, Color(0.85, 0.92, 1.0), HORIZONTAL_ALIGNMENT_CENTER))
	elif promo >= 0 and not won:
		v.add_child(UIKit.label("Bugs are x%.2f tougher here. Upgrade, then try again." % Promotion.hp_mult(promo), 11, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	# three stars, popping in one after another (none in a trial)
	var got: int = _stars_got if won and not elite and promo < 0 else 0
	var srow := HBoxContainer.new()
	srow.alignment = BoxContainer.ALIGNMENT_CENTER
	srow.add_theme_constant_override("separation", 14)
	for i in 3:
		var s := Control.new()
		s.custom_minimum_size = Vector2(54, 54)
		s.pivot_offset = Vector2(27, 27)
		var on := i < got
		s.draw.connect(func():
			var pts := _star_pts(Vector2(27, 29), 25.0 if i == 1 else 21.0)
			if on:
				s.draw_colored_polygon(pts, UIKit.GOLD)
			else:
				s.draw_colored_polygon(pts, Color(0.12, 0.14, 0.22, 0.9))
			var closed := pts.duplicate()
			closed.append(pts[0])
			s.draw_polyline(closed, Color(1, 0.95, 0.7) if on else Color(0.4, 0.45, 0.6), 1.4, true))
		s.scale = Vector2.ZERO
		var tw := s.create_tween()
		tw.tween_interval(0.25 + 0.3 * i)
		tw.tween_property(s, "scale", Vector2(1.25, 1.25) if on else Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "scale", Vector2.ONE, 0.12)
		srow.add_child(s)
	if not elite:
		v.add_child(srow)
		# why each star was earned or missed
		for o in _objectives(won):
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var ok: bool = o.state == "done" or o.state == "ok"
			row.add_child(UIKit.label("✓" if ok and won else ("✗" if o.state == "fail" or not won else "·"), 14, Color(0.5, 1.0, 0.55) if ok and won else Color(1.0, 0.45, 0.45)))
			var tl := UIKit.label(String(o.text), 13, Color.WHITE if ok and won else UIKit.MUTED)
			tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(tl)
			v.add_child(row)
	if area_done:
		var nxt_area := StageData.area_index(stage) + 1
		v.add_child(UIKit.label("%s cleared!" % StageData.area(stage).name, 14, UIKit.CYAN, HORIZONTAL_ALIGNMENT_CENTER))
		if nxt_area < StageData.AREAS.size():
			v.add_child(UIKit.label("Next planet: %s" % StageData.AREAS[nxt_area].name, 12, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		# the Area 1 boss earns the Commander suit (PilotRig.COMMANDER_STAGE), said once
		if stage == PilotRig.COMMANDER_STAGE and promo < 0 and not bool(_read_save().get("commander_seen", false)):
			_write_save({"commander_seen": true})
			var suit_l := UIKit.label("NEW SUIT: COMMANDER ARMOUR", 16, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
			suit_l.add_theme_font_override("font", title_font)
			v.add_child(suit_l)
			v.add_child(UIKit.label("Switch suits in Gear", 11, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	# rewards on glass tiles
	var rw := HBoxContainer.new()
	rw.add_theme_constant_override("separation", 8)
	for spec in [["COINS", "+%d" % coins_earned, UIKit.GOLD], ["PILOT XP", "+%d" % _xp_gain, Color(0.85, 0.75, 1.0)], ["KILLS", str(kills), Color.WHITE]]:
		var tile := UIKit.panel(12)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", 0)
		tv.add_child(UIKit.label(spec[0], 10, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		tv.add_child(UIKit.label(spec[1], 18, spec[2], HORIZONTAL_ALIGNMENT_CENTER))
		tile.add_child(tv)
		rw.add_child(tile)
	v.add_child(rw)
	if _xp_bonus > 0:
		v.add_child(UIKit.label("includes first clear bonus +%d XP" % _xp_bonus, 11, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	if not _parts_got.is_empty():
		var bits: Array = []
		for k in Parts.ORDER:
			if int(_parts_got.get(k, 0)) > 0:
				bits.append("+%d %s" % [int(_parts_got[k]), Parts.KINDS[k].name])
		v.add_child(UIKit.label("Parts:  " + "   ".join(bits), 12, Color(0.7, 0.9, 1.0), HORIZONTAL_ALIGNMENT_CENTER))
	if not _gear_got.is_empty():
		# the gear copy this clear dropped: its picture, name and rarity (merge it in the Workshop)
		var gid: String = _gear_got.id
		var grow := HBoxContainer.new()
		grow.alignment = BoxContainer.ALIGNMENT_CENTER
		grow.add_theme_constant_override("separation", 8)
		var gpic := TextureRect.new()
		var gpath := "res://gear/%s_t1.png" % gid
		gpic.texture = load(gpath) if ResourceLoader.exists(gpath) else load("res://gear/%s.png" % gid)
		gpic.custom_minimum_size = Vector2(36, 36)
		gpic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		gpic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		grow.add_child(gpic)
		grow.add_child(UIKit.label("GEAR:  %s %s" % [GearData.rarity_name(_gear_got.rarity), GearData.ITEMS[gid].name], 12, GearData.rarity_color(_gear_got.rarity)))
		if not _shards_got.is_empty():
			grow.add_child(UIKit.label("SHARDS:  %d for %s" % [int(_shards_got.n), Heroes.ROSTER[_shards_got.id].name], 12, Heroes.element_color(Heroes.element_of(_shards_got.id))))
		v.add_child(grow)
	if _level_after > _level_before:
		v.add_child(UIKit.label("PILOT LEVEL %d!" % _level_after, 15, Color(0.85, 0.75, 1.0), HORIZONTAL_ALIGNMENT_CENTER))
		for id in Turrets.TURRETS:
			var u: int = int(Turrets.TURRETS[id].unlock)
			if u > _level_before and u <= _level_after:
				v.add_child(UIKit.label("%s unlocked" % Turrets.TURRETS[id].name, 12, UIKit.CYAN, HORIZONTAL_ALIGNMENT_CENTER))
	if not won:
		v.add_child(UIKit.label("Reached wave %d of %d" % [mini(wave_index + 1, waves.size()), waves.size()], 12, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	if won and _new_mount >= 0:
		v.add_child(UIKit.label("NEW TURRET MOUNT OPEN!", 14, UIKit.CYAN, HORIZONTAL_ALIGNMENT_CENTER))
		var on_m: String = turret_loadout[_new_mount] if _new_mount < turret_loadout.size() else ""
		var hint := ("Your %s stands on mount %d from the next stage." % [Turrets.TURRETS[on_m].name, _new_mount + 1]) if on_m != "" and _level_after >= int(Turrets.TURRETS[on_m].unlock) else ("Place a turret on mount %d in Gear." % (_new_mount + 1))
		v.add_child(UIKit.label(hint, 12, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var sp := Control.new(); sp.custom_minimum_size = Vector2(0, 4)
	v.add_child(sp)
	if won and stage < StageData.MAX_STAGE and promo < 0:
		var nxt := UIKit.gold_button("Next stage", 17)
		nxt.custom_minimum_size = Vector2(0, 46)
		nxt.pressed.connect(func():
			if not Energy.try_play(_end_panel, elite, stage + 1):   # a stage costs power tokens (stages 1-5 free)
				return
			_write_save({"selected_stage": stage + 1})
			stage += 1
			_start_stage())
		v.add_child(nxt)
	var brow := HBoxContainer.new()
	brow.add_theme_constant_override("separation", 8)
	var again := UIKit.teal_button("Retry" if not won else "Play again")
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.custom_minimum_size = Vector2(0, 40)
	again.pressed.connect(func(): if Energy.try_play(_end_panel, elite, stage): _start_stage())
	brow.add_child(again)
	var home := UIKit.ghost_button("Back to Hub", 14)
	home.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home.custom_minimum_size = Vector2(0, 40)
	home.pressed.connect(func(): get_tree().change_scene_to_file("res://hub.tscn"))
	brow.add_child(home)
	v.add_child(brow)
	p.add_child(v)
	_end_panel.add_child(p)
	_end_panel.visible = true
	# the card slides up into place
	p.modulate.a = 0.0
	p.position.y += 30.0
	var pt := p.create_tween().set_parallel(true)
	pt.tween_property(p, "modulate:a", 1.0, 0.25)
	pt.tween_property(p, "position:y", p.position.y - 30.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# ------------------------------------------------------------------ drawing

func _draw() -> void:
	var fsize := Vector2(FIELD_W, FIELD_H)
	var sec := StageData.sector(stage)
	draw_rect(Rect2(Vector2(0, -_safe_top - 20.0), get_viewport_rect().size + Vector2(0, 40.0)), sec.sky_bot)
	if sec.has("bg"):
		Backdrop.draw_world(self, fsize, FIELD_H, String(sec.bg), _stars, time_alive, soldier_pos.x / FIELD_W - 0.5)
	else:
		Backdrop.draw_sky_palette(self, fsize, _stars, time_alive, sec.sky_top, sec.sky_bot, sec.glow, soldier_pos.x / FIELD_W - 0.5)
		Backdrop.draw_horizon(self, fsize, BASE_Y, elite, _city, time_alive, sec.rim)
	Backdrop.draw_force_field(self, Vector2(FIELD_W * 0.5, BASE_Y), DOME_RX, DOME_RY, clampf(shield / shield_max, 0.0, 1.0), clampf(hull / hull_max, 0.0, 1.0), time_alive, elite, hit_t)
	Backdrop.draw_strip(self, FIELD_W, FIELD_H - STRIP_LIFT)
	Backdrop.draw_base_lights(self, FIELD_W, FIELD_H - STRIP_LIFT, time_alive)
	for i in Turrets.MOUNTS:
		_draw_socket_lid(i)
	for t in turrets:
		_draw_turret(t)
	_draw_turret_back()
	# gems
	for g in gems:
		var c: Color = StageData.GEM_COLORS[g.tier] if not g.get("coin", false) else Color(1.0, 0.82, 0.3)
		var p: Vector2 = g.pos
		var r: float = 4.0 + g.tier * 1.2
		var blink: float = 1.0 if g.life > 2.0 else (0.4 + 0.6 * absf(sin(g.life * 10.0)))
		if g.has("part"):
			_draw_part_pickup(p, String(g.part), blink)
			continue
		if g.get("coin", false):
			# Luna's coin, flipping as it falls
			var ctx: Texture2D = _tex["ui_coin"]
			var cs: float = 14.0 / ctx.get_width()
			draw_set_transform(p, 0.0, Vector2(cs * (0.35 + 0.65 * absf(cos(time_alive * 5.0 + p.x))), cs))
			draw_texture_rect(ctx, Rect2(-ctx.get_size() * 0.5, ctx.get_size()), false, Color(1, 1, 1, blink))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			continue
		# stand out on any world (Rudy: blue gems vanished on blue skies): a dark backing,
		# a thin light ring that pulses, then the gem and a white glint
		draw_circle(p, r * 2.3, Color(0.0, 0.01, 0.05, 0.55 * blink))
		var pulse: float = 0.5 + 0.5 * sin(time_alive * 5.0 + p.x * 0.1)
		draw_arc(p, r * (2.0 + 0.4 * pulse), 0.0, TAU, 20, Color(c.lightened(0.5), (0.35 + 0.35 * pulse) * blink), 1.2, true)
		if g.get("pull", false):
			# flying to the pilot: a short fading streak behind it
			var back: Vector2 = (p - soldier_pos).normalized() * (10.0 + 3.0 * g.tier)
			draw_line(p + back, p, Color(c, 0.0), r * 1.2, true)
			draw_line(p + back * 0.6, p, Color(c, 0.45), r * 0.9, true)
		draw_circle(p, r * 2.2, Color(c, 0.12 * blink))
		# Luna's gem, turning slowly (a squeeze across its width) and bobbing
		var gtx: Texture2D = _tex["gem_%d" % int(g.tier)]
		var gs: float = r * 4.2 / maxf(gtx.get_width(), gtx.get_height())
		var spin: float = 0.75 + 0.25 * cos(time_alive * 3.0 + p.x * 0.05)
		draw_set_transform(p + Vector2(0, sin(time_alive * 4.0 + p.x) * 1.2), 0.0, Vector2(gs * spin, gs))
		draw_texture_rect(gtx, Rect2(-gtx.get_size() * 0.5, gtx.get_size()), false, Color(1, 1, 1, blink))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var gl: float = maxf(0.0, sin(time_alive * 2.2 + p.x * 0.37))
		if gl > 0.85:
			var k: float = (gl - 0.85) / 0.15
			draw_line(p + Vector2(-r * 1.4 * k, -r * 0.6), p + Vector2(r * 1.4 * k, -r * 0.6), Color(1, 1, 1, 0.9 * k * blink), 1.0, true)
			draw_line(p + Vector2(0, -r * 0.6 - r * 1.4 * k), p + Vector2(0, -r * 0.6 + r * 1.4 * k), Color(1, 1, 1, 0.9 * k * blink), 1.0, true)
	_draw_drone()
	# pilot
	var bob: float = sin(time_alive * 4.0) * 2.5
	var pose := _current_pose()
	draw_set_transform(soldier_pos + Vector2(0, 38), 0.0, Vector2(1.3, 0.4))
	draw_circle(Vector2.ZERO, 14, Color(0.2, 0.85, 1.0, 0.08))
	if magnet_level > 0:
		draw_set_transform(soldier_pos, 0.0, Vector2.ONE)
		draw_arc(Vector2.ZERO, minf(magnet_radius, 900.0), 0.0, TAU, 48, Color(0.29, 0.66, 1.0, 0.10), 1.5, true)
	# after a hit he pulses softly (no on/off blink), easing back to solid at the end
	var pilot_a: float = 1.0
	if inv_t > 0.0:
		pilot_a = lerpf(1.0, 0.55 + 0.45 * absf(cos(time_alive * PI * 4.0)), smoothstep(0.0, 0.3, inv_t))
	var turn: float = clampf(absf(facing_s), 0.15, 1.0) if pose.begins_with("aim") else 1.0
	if not _rig_view:
		PilotSprite.draw(self, soldier_pos + Vector2(0, bob), PILOT_HEIGHT, pose, _flipped(pose), -draw_bank * 0.6, time_alive,
			clampf(1.0 - vy_smooth / 260.0, 0.35, 1.9), clampf(draw_bank * 5.0, -1.0, 1.0), smoothstep(0.3, 1.0, gun_recoil), anim.mix(), turn, pilot_a)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# bullets
	for bl in bullets:
		if bl.col == "tracer":
			continue   # turret tracers are drawn on the light layer
		var dir: Vector2 = bl.vel.normalized()
		var purple: bool = bl.col == "purple"
		if not purple:
			continue   # the pilot's bolts are Luna's energy bolt, drawn on the light layer
		draw_line(bl.pos - dir * 10.0, bl.pos + dir * 4.0, Color(0.71, 0.55, 1.0, 0.5), 5.0, true)
		draw_line(bl.pos - dir * 10.0, bl.pos + dir * 4.0, Color(0.95, 0.9, 1.0), 2.0, true)
	# Rapid Pulse: the muzzle stays hot between shots
	if fire_rate_mult > 1.01:
		var heat: float = clampf((fire_rate_mult - 1.0) / 0.5, 0.0, 1.0)
		draw_circle(_muzzle_world(), 3.0 + 4.0 * heat, Color(1.0, 0.75, 0.5, 0.25 + 0.35 * heat))
	for eb in enemy_bullets:
		if eb.get("kind", "") == "goo":
			# Luna's goo glob (it travels toward the top of its picture), wobbling as it flies
			var gd: Vector2 = eb.vel.normalized()
			var wob: float = sin(time_alive * 14.0 + float(eb.ph))
			var gt: Texture2D = _tex["goo"]
			var gh := 22.0
			var gw: float = gh * gt.get_width() / gt.get_height()
			draw_set_transform(eb.pos, gd.angle() + PI / 2.0, Vector2(1.0 - 0.08 * wob, 1.0 + 0.08 * wob))
			draw_texture_rect(gt, Rect2(-gw * 0.5, -gh * 0.3, gw, gh), false)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_circle(eb.pos, 5, Color(1.0, 0.2, 0.6, 0.5))
			draw_circle(eb.pos, 2.5, Color(1.0, 0.8, 0.9))
	# enemies
	for e in enemies:
		_draw_enemy(e)
	_draw_shards()
	_draw_turret_front()
	for r in rings:
		var k: float = 1.0 - r.life / r.max
		draw_arc(r.pos, r.r * k, 0.0, TAU, 20, Color(r.col, (1.0 - k) * 0.7), 2.0, true)
	for s in sparks:
		draw_circle(s.pos, 2.0, Color(s.col, clampf(s.life * 2.5, 0.0, 1.0)))
	for f in (floaters if not picking else []):
		var big: bool = f.get("big", false)
		draw_string(title_font if big else hud_font, f.pos + Vector2(-40 if big else -14, 0), f.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18 if big else 14, Color(f.col, clampf(f.life * 1.5, 0.0, 1.0)))
	_draw_range_ring()
	_hc.queue_redraw()   # the top bar lives on its own layer above the pilot (_hc)
	_fx.queue_redraw()

func _draw_enemy(e: Dictionary) -> void:
	var def: Dictionary = StageData.ENEMIES[e.type]
	if e.type == "spore":
		# spore pod (code-drawn until it has art): a glowing purple seed that pulses
		var pr: float = float(def.size) * 0.5 * (1.0 + 0.08 * sin(e.t * 7.0 + e.ph))
		draw_circle(e.pos, pr * 2.0, Color(0.7, 0.35, 1.0, 0.14))
		draw_circle(e.pos, pr, Color(0.42, 0.16, 0.62))
		draw_circle(e.pos + Vector2(-pr * 0.3, -pr * 0.3), pr * 0.45, Color(0.85, 0.6, 1.0, 0.8))
		return
	if e.type == "diver" and (e.state == "aim" or e.state == "dive") and e.has("target"):
		# the lock-on: a red dashed line to where it will hit, brightening until it dives
		var la: float = clampf(float(e.get("t_state", 0.0)) / 0.6, 0.0, 1.0) if e.state == "aim" else 0.35
		var tgt: Vector2 = e.target
		var seg: Vector2 = tgt - e.pos
		var n := int(seg.length() / 14.0)
		for k in n:
			if k % 2 == 0:
				draw_line(e.pos + seg * (float(k) / n), e.pos + seg * (float(k + 1) / n), Color(1.0, 0.3, 0.3, 0.55 * la), 1.2, true)
		draw_set_transform(tgt, 0.0, Vector2(1.0, 0.4))
		draw_arc(Vector2.ZERO, 10.0 + 4.0 * sin(time_alive * 10.0), 0.0, TAU, 20, Color(1.0, 0.3, 0.3, 0.7 * la), 1.2, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var size: float = float(def.size) * 1.35
	var ang: float = float(e.get("tilt_s", _enemy_tilt(e)))
	var fold: float = float(e.get("fold", 0.0))
	# the flinch (dev147): a hit bug shrinks for a tenth of a second and springs back
	var flinch: float = float(e.get("hit_t", 0.0))
	var bright := 1.0
	if flinch > 0.0:
		var fk := sin(clampf(flinch / HIT_FLINCH_T, 0.0, 1.0) * PI)
		size *= 1.0 - 0.16 * fk
		bright = 1.0 + 1.8 * fk   # and it flashes white for the same blink (dev156)
	if e.get("hatchling", false):
		size *= lerpf(0.6, 1.0, smoothstep(0.2, 1.2, float(e.t)))   # grows out of the sac
	var a: float = clampf((e.pos.y - 60.0) / 50.0, 0.15, 1.0)   # fades in as it enters
	var sac_k := -1.0   # the Spitter's sac: fills over its cycle, empties on the spit (Luna's sac parts, dev161)
	if e.type == "spitter":
		# the sac swells before it spits and settles right after, on smooth ramps
		var every: float = float(def.fire_every)
		sac_k = 1.0 - smoothstep(0.15, every * 0.8, float(e.fire_t))
		var swell: float = maxf(smoothstep(0.8, 0.2, e.fire_t), smoothstep(every - 0.3, every, e.fire_t))
		if swell > 0.01:
			var pulse: float = 0.5 + 0.5 * sin(e.t * 8.0)
			draw_circle(EnemyRig.anchor("spitter", "sac", e.pos, size, ang), size * 0.16 * (1.0 + 0.4 * pulse * swell), Color(0.8, 0.4, 1.0, 0.25 * swell))
		# the spit telegraph (dev168, Archero-style fairness): a third of a second before a
		# glob, the sac flashes and a ring closes on the mouth, so you can see it coming and move
		if float(e.fire_t) < SPIT_WARN and e.pos.y > 40.0:
			var wk: float = 1.0 - float(e.fire_t) / SPIT_WARN
			bright = maxf(bright, 1.0 + 0.7 * (0.5 + 0.5 * sin(e.t * 40.0)))
			var mouth := EnemyRig.anchor("spitter", "muzzle", e.pos, size * 1.35, ang)
			draw_arc(mouth, size * (0.6 - 0.4 * wk), 0.0, TAU, 24, Color(1.0, 0.45, 0.6, 0.3 + 0.5 * wk), 2.0)
	if e.type == "hive_mother":
		EnemyRig.draw_hive_mother(self, e.pos, size * (0.68 if e.get("mini", false) else 0.9), time_alive, float(e.laying), e.hp < e.hp_max * 0.5)
	elif e.get("hatchling", false) and fold > 0.01:
		# Luna's crumpled hatchling cross-fades into the flying Scout as its wings open
		var ht: Texture2D = _tex["hive_hatchling"]
		var hs: Vector2 = ht.get_size() * (size * 0.75 / ht.get_height())
		draw_set_transform(e.pos, ang, Vector2.ONE)
		draw_texture_rect(ht, Rect2(-hs * 0.5, hs), false, Color(1, 1, 1, a * fold))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		EnemyRig.draw_bug(self, e.type, e.pos, size, time_alive, float(e.ph), ang, fold, 1.0 + float(e.speed) / 150.0, a * (1.0 - fold), float(e.get("stretch_s", 0.0)), e.vel.angle(), bright, sac_k)
	else:
		EnemyRig.draw_bug(self, e.type, e.pos, size, time_alive, float(e.ph), ang, fold, 1.0 + float(e.speed) / 150.0, a, float(e.get("stretch_s", 0.0)), e.vel.angle(), bright, sac_k)
	if e.hp < e.hp_max and e.type != "hive_mother":
		var w := size * 0.9
		draw_rect(Rect2(e.pos.x - w * 0.5, e.pos.y - size * 0.6, w, 3), Color(1, 1, 1, 0.15))
		draw_rect(Rect2(e.pos.x - w * 0.5, e.pos.y - size * 0.6, w * clampf(e.hp / e.hp_max, 0.0, 1.0), 3), Color(1.0, 0.5, 0.4))

# Batch D turrets (Luna's bases and heads). base_w: base width on screen; head_h: head
# height; gap: how far the head floats above the base's top; art_dir: where the painted
# head points (radians) for the ones that turn (Lance), 0 for round heads that hover.
const SPLIT_LOOK := {
	"lance":   {"base_w": 60.0, "head_h": 34.0, "gap": 2.0, "art_dir": 2.68, "turns": true},
	"storm":   {"base_w": 58.0, "head_h": 50.0, "gap": 10.0, "art_dir": 0.0, "turns": false},
	"gravity": {"base_w": 60.0, "head_h": 36.0, "gap": 8.0, "art_dir": 0.0, "turns": false},
	"prism":   {"base_w": 0.0, "head_h": 78.0, "gap": 0.0, "art_dir": 0.0, "turns": false},
}

func _split_geo(t: Dictionary) -> Dictionary:
	var look: Dictionary = SPLIT_LOOK[t.type]
	var base_h := 0.0
	if float(look.base_w) > 0.0:
		var bt: Texture2D = _tex[t.type + "_base"]
		base_h = bt.get_height() * float(look.base_w) / bt.get_width()
	var ph: float = float(t.mount) * 1.3
	var bob: float = sin(time_alive * 2.0 + ph) * (2.0 if not look.turns else 0.6)
	var ht: Texture2D = _tex[t.type + "_head"]
	var hh: float = float(look.head_h)
	var hw: float = ht.get_width() * hh / ht.get_height()
	var centre: Vector2 = t.pos + Vector2(0, -base_h * 0.55 - float(look.gap) - hh * 0.5 + bob)
	if t.type == "prism":
		centre = t.pos + Vector2(0, 6.0 - hh * 0.5)
	return {"base_h": base_h, "centre": centre, "hw": hw, "hh": hh}

func _draw_split_turret(t: Dictionary, yo: float, a: float) -> void:
	var look: Dictionary = SPLIT_LOOK[t.type]
	if float(look.base_w) > 0.0:
		var bt: Texture2D = _tex[t.type + "_base"]
		var bs := bt.get_size() * (float(look.base_w) / bt.get_width())
		draw_texture_rect(bt, Rect2(t.pos + Vector2(-bs.x * 0.5, -bs.y * 0.55 + yo), bs), false, Color(1, 1, 1, a))
		Backdrop.draw_socket_lip(self, int(t.mount), FIELD_W, FIELD_H - STRIP_LIFT)   # seated in the socket
	var g := _split_geo(t)
	var ht: Texture2D = _tex[t.type + "_head"]
	var pose := _split_pose(t)
	draw_set_transform(g.centre + Vector2(0, yo), pose.rot, Vector2(pose.sx, 1.0) * pose.pulse)
	draw_texture_rect(ht, Rect2(-g.hw * 0.5, -g.hh * 0.5, g.hw, g.hh), false, Color(1, 1, 1, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# how a split turret's head is turned, mirrored and pulsed right now (shared by the head
# and its light layer, dev154)
func _split_pose(t: Dictionary) -> Dictionary:
	var look: Dictionary = SPLIT_LOOK[t.type]
	var rot := 0.0
	var sx := 1.0
	var kick: float = clampf(float(t.fire_t) / float(FIRE_TIME.get(t.type, 0.2)), 0.0, 1.0)
	if look.turns:
		# the cannon turns to its target; mirrored when it aims to the right
		var face: float = -1.0 if cos(float(t.ang)) > 0.05 else 1.0
		var art: float = float(look.art_dir) if face > 0.0 else PI - float(look.art_dir)
		rot = angle_difference(art, float(t.ang))
		sx = face
	elif t.type == "prism":
		rot = clampf(angle_difference(-PI / 2.0, float(t.ang)) * 0.25, -0.3, 0.3)   # leans toward its target
	var pulse: float = 1.0 + 0.06 * kick + (0.03 * sin(time_alive * 3.0 + float(t.mount)) if not look.turns else 0.0)
	return {"rot": rot, "sx": sx, "pulse": pulse}

# The turrets' own light (dev154): the glow cut from each turret picture
# (tools/cut_turret_light.gd) drawn on the additive layer exactly over the turret, breathing
# while idle, swelling as it charges, flashing when it fires.
func _draw_turret_lights() -> void:
	for t in turrets:
		if t.drop < 1.0 or not _fx_tex.has("light_" + String(t.type)):
			continue
		var lt: Texture2D = _fx_tex["light_" + String(t.type)]
		var kick: float = clampf(float(t.fire_t) / float(FIRE_TIME.get(t.type, 0.2)), 0.0, 1.0)
		var strength: float = 0.5 + 0.22 * sin(time_alive * 2.1 + float(t.mount) * 1.7) + 0.6 * kick
		if CHARGE_COL.has(t.type):
			var every: float = float(t.def.every)
			strength += 0.5 * smoothstep(minf(0.8, every * 0.6), 0.0, float(t.cd))
		elif t.type == "lance":
			strength += 0.5 * smoothstep(0.5, 1.0, float(t.charge) / maxf(float(t.def.every), 0.1))
		var col := Color(1, 1, 1, clampf(strength, 0.0, 1.0))
		if t.type == "sentry":
			var g := _sentry_geo(t)
			var hs: float = SENTRY_HEAD_H / lt.get_height()
			var hsz := lt.get_size() * hs
			_fx.draw_set_transform(g.pivot, g.rot, Vector2(g.face, 1.0))
			_fx.draw_texture_rect(lt, Rect2(Vector2(-hsz.x * SENTRY_HEAD_CX, -hsz.y * 0.9) + Vector2(0, g.recoil), hsz), false, col)
		elif SPLIT_LOOK.has(t.type):
			var g := _split_geo(t)
			var pose := _split_pose(t)
			_fx.draw_set_transform(g.centre, pose.rot, Vector2(pose.sx, 1.0) * pose.pulse)
			_fx.draw_texture_rect(lt, Rect2(-g.hw * 0.5, -g.hh * 0.5, g.hw, g.hh), false, col)
		else:
			# the whole-picture turrets (Swarm): same placement as _draw_turret
			var look: Dictionary = TURRET_LOOK[t.type]
			var sz := lt.get_size() * minf(float(look.h) / lt.get_height(), float(look.w) / lt.get_width())
			var bob: float = sin(time_alive * 2.2 + float(t.mount)) * float(look.bob)
			var k2 := kick * kick
			var ksz := Vector2(sz.x * (1.0 + 0.03 * k2), sz.y * (1.0 - 0.05 * k2))
			_fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			_fx.draw_texture_rect(lt, Rect2(t.pos + Vector2(-ksz.x * float(look.cx), -ksz.y + 6.0 + bob), ksz), false, col)
	_fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_turret(t: Dictionary) -> void:
	# Luna's turret sits in its socket with a soft shadow; it falls in from above
	# when mounted (drop 0 -> 1) and lands with a flash.
	if t.drop <= 0.0:
		return
	var k: float = t.drop
	var yo: float = -90.0 * (1.0 - k) * (1.0 - k)
	var a: float = clampf(k * 4.0, 0.0, 1.0)
	Backdrop.draw_socket_shadow(self, int(t.mount), FIELD_W, FIELD_H - STRIP_LIFT, 0.55 * k)
	if SPLIT_LOOK.has(t.type):
		_draw_split_turret(t, yo, a)
		return
	if t.type == "sentry":
		var bt: Texture2D = _tex["sentry_base"]
		var bs := bt.get_size() * (SENTRY_BASE_W / bt.get_width())
		draw_texture_rect(bt, Rect2(t.pos + Vector2(-bs.x * 0.5, -bs.y * 0.5 + yo), bs), false, Color(1, 1, 1, a))
		Backdrop.draw_socket_lip(self, int(t.mount), FIELD_W, FIELD_H - STRIP_LIFT)   # the foot sits inside the ring
		var g := _sentry_geo(t)
		var ht: Texture2D = _tex["sentry_head"]
		var hs: float = SENTRY_HEAD_H / ht.get_height()
		var hsz := ht.get_size() * hs
		draw_set_transform(g.pivot + Vector2(0, yo), g.rot, Vector2(g.face, 1.0))
		draw_texture_rect(ht, Rect2(Vector2(-hsz.x * SENTRY_HEAD_CX, -hsz.y * 0.9) + Vector2(0, g.recoil), hsz), false, Color(1, 1, 1, a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var tex: Texture2D = _tex[Turrets.TURRETS[t.type].art + "_idle"]
	# the Swarm Hive from Luna's parts (dev162): the hive with its hatch open, and the lid
	# drawn over the hole, flipping up and over the back before the drones launch (t.lid)
	var lidded: bool = t.type == "swarm" and _tex.has("swarm_body_nolid") and _tex.has("swarm_lid")
	if lidded:
		tex = _tex["swarm_body_nolid"]
	var look: Dictionary = TURRET_LOOK[t.type]
	var sz := tex.get_size() * minf(float(look.h) / tex.get_height(), float(look.w) / tex.get_width())
	var bob: float = sin(time_alive * 2.2 + float(t.mount)) * float(look.bob)
	# a shot kicks the turret: it squats a little on its socket and springs back
	var kick: float = clampf(float(t.fire_t) / float(FIRE_TIME.get(t.type, 0.2)), 0.0, 1.0)
	kick = kick * kick
	var ksz := Vector2(sz.x * (1.0 + 0.03 * kick), sz.y * (1.0 - 0.05 * kick))
	var rect := Rect2(t.pos + Vector2(-ksz.x * float(look.cx), -ksz.y + 6.0 + yo + bob), ksz)
	draw_texture_rect(tex, rect, false, Color(1, 1, 1, a))
	if lidded:
		# hinge on the far edge of the hatch; closed = the lid lies flat as the hive's top face
		# (squashed for the three-quarter view), open = flipped up and back past vertical
		var lk := smoothstep(0.0, 1.0, float(t.get("lid", 0.0)))
		var sy := lerpf(0.42, -0.85, lk)
		if absf(sy) > 0.03:
			var hinge := rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.035)
			var lw := rect.size.x * 0.46
			draw_set_transform(hinge, 0.0, Vector2(1.0 - 0.12 * lk, sy))
			draw_texture_rect(_tex["swarm_lid"], Rect2(-lw * 0.5, 0.0, lw, lw), false, Color(1, 1, 1, a))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# The field holding the Sentry's head up: a soft glow on the base, a faint column of
# light, and thin rings rising from base to head. It brightens when the head dips.
func _draw_sentry_field(t: Dictionary) -> void:
	var g := _sentry_geo(t)
	var lift: float = g.lift
	if lift <= 0.01:
		return
	var cyan := Color(0.18, 0.9, 1.0)
	var x: float = g.pivot.x
	var y0: float = g.base_top
	var y1: float = minf(g.head_bottom, y0 - 1.0)
	var squeeze: float = clampf((y0 - y1) / SENTRY_GAP, 0.3, 1.5)
	var hot: float = lift * (1.0 + clampf(float(t.get("hov_y", 0.0)) * 0.25, 0.0, 0.8) + 0.25 * (1.0 - minf(squeeze, 1.0)))
	_fx.draw_set_transform(Vector2(t.pos.x, y0), 0.0, Vector2(1.0, 0.32))
	Backdrop.soft_glow(_fx, Vector2.ZERO, 20.0, Color(cyan, 0.5 * hot))
	_fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_fx.draw_colored_polygon(PackedVector2Array([Vector2(t.pos.x - 13, y0), Vector2(t.pos.x + 13, y0), Vector2(x + 8, y1), Vector2(x - 8, y1)]),
		Color(cyan, 0.10 * hot))
	for i in 3:
		var ph := fposmod(time_alive * 1.4 + float(i) / 3.0 + float(t.mount) * 0.3, 1.0)
		var y := lerpf(y0, y1, ph)
		var w := lerpf(13.0, 8.0, ph)
		_fx.draw_set_transform(Vector2(lerpf(t.pos.x, x, ph), y), 0.0, Vector2(1.0, 0.3))
		_fx.draw_arc(Vector2.ZERO, w, 0.0, TAU, 24, Color(cyan, sin(ph * PI) * 0.55 * hot), 1.2, true)
	_fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# Where the Sentry's head sits and points. The painted barrels point up-left, so the
# head is mirrored for targets on the right; `face` eases through the turn so it
# swings round instead of flipping.
func _sentry_geo(t: Dictionary) -> Dictionary:
	var bt: Texture2D = _tex["sentry_base"]
	var base_h: float = bt.get_height() * (SENTRY_BASE_W / bt.get_width())
	var lift: float = smoothstep(0.0, 1.0, float(t.get("lift", 0.0)))
	var ph: float = float(t.mount) * 1.7
	var hover := Vector2(sin(time_alive * 0.9 + ph) * 1.5, -SENTRY_GAP * lift + (sin(time_alive * 2.3 + ph) * 1.6 + sin(time_alive * 3.7 + ph) * 0.5) * lift + float(t.get("hov_y", 0.0)))
	var pivot: Vector2 = t.pos + Vector2(0, -base_h * 0.42) + hover
	var face: float = signf(t.face) * maxf(absf(t.face), 0.15) if t.face != 0.0 else 0.15
	var art_dir: float = SENTRY_ART_DIR if t.face >= 0.0 else PI - SENTRY_ART_DIR
	var lean: float = clampf(float(t.get("swing", 0.0)) * 0.06, -0.12, 0.12) + sin(time_alive * 1.3 + ph) * 0.025 * lift
	var rot: float = clampf(angle_difference(art_dir, t.ang), -1.1, 1.1) + lean   # turns well out to each side
	var ht: Texture2D = _tex["sentry_head"]
	var hs: float = SENTRY_HEAD_H / ht.get_height()
	var recoil: float = 4.0 * float(t.fire_t) / FIRE_TIME.sentry
	var local := Vector2((0.47 - SENTRY_HEAD_CX) * ht.get_width() * face, (0.04 - 0.9) * ht.get_height()) * hs + Vector2(0, recoil)
	return {"pivot": pivot, "rot": rot, "face": face, "recoil": recoil, "muzzle": pivot + local.rotated(rot), "lift": lift, "base_top": t.pos.y - base_h * 0.28, "head_bottom": pivot.y + hs * ht.get_height() * 0.1}

# The point a turret's weapon fires from.
func _turret_tip(t: Dictionary) -> Vector2:
	if t.type == "sentry":
		return _sentry_geo(t).muzzle
	if SPLIT_LOOK.has(t.type):
		var g := _split_geo(t)
		if t.type == "lance":
			return g.centre + Vector2.from_angle(float(t.ang)) * g.hw * 0.48
		return g.centre if t.type != "prism" else g.centre + Vector2(0, -g.hh * 0.1)
	var look: Dictionary = TURRET_LOOK[t.type]
	var tex: Texture2D = _tex[Turrets.TURRETS[t.type].art + "_idle"]
	var h: float = tex.get_height() * minf(float(look.h) / tex.get_height(), float(look.w) / tex.get_width())
	return t.pos + Vector2(0, 6.0 - h * float(look.tip) + sin(time_alive * 2.2 + float(t.mount)) * float(look.bob))

# ---- death shards (dev147, AAA motion item 26 e): a killed bug breaks into six pieces of
# its own painted body (regions of the body picture), thrown outward, tumbling under
# gravity and fading. No new art: the pieces are cut from the picture at run time.
const HIT_FLINCH_T := 0.12
const SPIT_WARN := 0.35   # seconds before a Spitter spits: the sac flares and a ring closes on its mouth (dev168: see it coming, move)
const SHARD_LIFE := 0.75
var _shards: Array = []
var _shard_atlas := {}   # enemy type -> [Texture2D]: Luna's chunk pieces (enemies/parts/<bug>_chunk_N.png, dev160), else six cuts of the body

func _spawn_shards(e: Dictionary, def: Dictionary) -> void:
	if not ["scout", "drifter", "spitter", "diver"].has(String(e.type)) or _shards.size() > 90:
		return
	if not _shard_atlas.has(e.type):
		var list: Array = []
		for i in 6:   # Luna's painted chunks (shell, leg, wing half, goo...), slivers skipped
			var cp := "res://enemies/parts/%s_chunk_%d.png" % [e.type, i]
			if ResourceLoader.exists(cp):
				var ct: Texture2D = load(cp)
				if ct.get_width() >= 20:
					list.append(ct)
		if list.is_empty():
			var tex: Texture2D = EnemyRig._t(String(e.type) + "_body")
			var ts := tex.get_size()
			for gy in 3:
				for gx in 2:
					var at := AtlasTexture.new()
					at.atlas = tex
					at.region = Rect2(ts.x * gx * 0.5, ts.y * gy / 3.0, ts.x * 0.5, ts.y / 3.0)
					list.append(at)
		_shard_atlas[e.type] = list
	var bug_px: float = float(def.size) * 1.35
	var tilt: float = float(e.get("tilt_s", 0.0))
	var pieces: Array = _shard_atlas[e.type]
	for i in pieces.size():
		if Perf.lite() and i % 2 == 1:
			continue   # battery saver: half the shards
		var at: Texture2D = pieces[i]
		var off: Vector2
		var sz: Vector2
		if at is AtlasTexture:
			# a cut of the body: starts where it sat on the whole bug
			var s: float = bug_px / 220.0
			off = (Vector2(at.region.position.x + at.region.size.x * 0.5, at.region.position.y + at.region.size.y * 0.5) - at.atlas.get_size() * 0.5) * s
			sz = at.region.size * s
		else:
			# a painted chunk: about a third of the bug tall, thrown from a spot on the body
			off = Vector2.from_angle(TAU * i / pieces.size() + rng.randf() * 0.6) * bug_px * 0.25
			sz = at.get_size() * (bug_px * 0.42 / maxf(at.get_height(), 1.0))
		var dir := off.normalized() if off.length() > 0.1 else Vector2.from_angle(rng.randf() * TAU)
		_shards.append({"at": at, "sz": sz, "pos": e.pos + off.rotated(tilt), "vel": dir.rotated(tilt) * rng.randf_range(90.0, 200.0) + Vector2(0, -60.0) + e.vel * 0.3,
			"rot": tilt + rng.randf_range(-0.6, 0.6), "spin": rng.randf_range(-7.0, 7.0), "life": SHARD_LIFE})

func _update_shards(delta: float) -> void:
	var live: Array = []
	for sh in _shards:
		sh.life -= delta
		if sh.life <= 0.0:
			continue
		sh.vel.y += 480.0 * delta
		sh.vel.x *= 0.985
		sh.pos += sh.vel * delta
		sh.rot += sh.spin * delta
		live.append(sh)
	_shards = live

func _draw_shards() -> void:
	for sh in _shards:
		var at: Texture2D = sh.at
		var a: float = clampf(float(sh.life) / SHARD_LIFE * 1.6, 0.0, 1.0)
		var sz: Vector2 = sh.sz
		draw_set_transform(sh.pos, sh.rot, Vector2.ONE)
		draw_texture_rect(at, Rect2(-sz * 0.5, sz), false, Color(1, 1, 1, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _fx_add(name: String, pos: Vector2, size: float, life: float, rot: float = 0.0, grow: float = 1.5, col: Color = Color.WHITE) -> void:
	fxs.append({"tex": name, "pos": pos, "size": size, "rot": rot, "life": life, "max": life, "grow": grow, "col": col})

# The additive light layer: Luna's shot and hit sprites (painted on black, so they
# only add light), turret charge glows and beams.
func _draw_fx() -> void:
	# a socket's ring lights up once its turret has landed
	var lit := [0.0, 0.0, 0.0, 0.0]
	for t in turrets:
		# under the Sentry the ring stays dim, so its hovering base and head read as two pieces
		var glow: float = 0.35 if t.type == "sentry" else 1.0
		lit[t.mount] = maxf(lit[t.mount], smoothstep(0.6, 1.0, float(t.drop)) * glow)
	Backdrop.draw_socket_glow(_fx, FIELD_W, FIELD_H - STRIP_LIFT, lit)
	for t in turrets:
		if t.type == "sentry" and float(t.drop) >= 1.0:
			_draw_sentry_field(t)
	_draw_zaps()
	_draw_drone_light()
	for f in fxs:
		var k: float = 1.0 - f.life / f.max
		var tex: Texture2D = _fx_tex[f.tex]
		var w: float = float(f.size) * lerpf(1.0, float(f.grow), 1.0 - (1.0 - k) * (1.0 - k))
		var h: float = w * tex.get_height() / tex.get_width()
		var col: Color = f.col
		_fx.draw_set_transform(f.pos, f.rot, Vector2.ONE)
		_fx.draw_texture_rect(tex, Rect2(-w * 0.5, -h * 0.5, w, h), false, Color(col.r, col.g, col.b, pow(1.0 - k, 1.2)))
	# Sentry tracers: the bright head sits on the bullet, the tail trails behind
	var tr: Texture2D = _fx_tex["sentry_tracer"]
	for bl in bullets:
		if bl.col != "tracer":
			continue
		var L := 30.0
		var th: float = L * tr.get_height() / tr.get_width()
		_fx.draw_set_transform(bl.pos, bl.vel.angle(), Vector2.ONE)
		_fx.draw_texture_rect(tr, Rect2(-L * 0.9, -th * 0.5, L, th), false)
	# the pilot's bolts: Luna's energy bolt, its bright head on the bullet (Heavy Bolts:
	# bigger and brighter)
	var bt0: Texture2D = _fx_tex["bolt"]
	var bw: float = 1.0 + (damage_mult - 1.0) * 1.6
	for bl in bullets:
		if bl.col == "tracer" or bl.col == "purple":
			continue
		if bl.col == "missile":
			_fx.draw_set_transform(bl.pos, bl.vel.angle(), Vector2.ONE)
			_fx.draw_texture_rect(bt0, Rect2(-20, -5, 24, 10), false, Color(0.85, 0.5, 1.0))
			continue
		var big: float = 1.6 if bl.get("big", false) else (1.25 if bl.get("pierce", false) else 1.0)
		# the cards change how a bolt LOOKS (Luna's bolt designs): a needle with a ring for
		# rail / piercing shots, a crackling bolt for Chain Spark, a fat slug for Heavy Bolts,
		# twin strands for Burst Fire; Frost Rounds tint them icy
		var look := ""
		if bl.get("rail", false) or pierce_level > 0:
			look = "bolt_rail"
		elif int(bl.get("spark", 0)) > 0:
			look = "bolt_spark"
		elif int(card_levels.get("heavy_bolts", 0)) > 0:
			look = "bolt_heavy"
		elif burst_count > 1:
			look = "bolt_twin"
		var tint := Color(0.78, 0.95, 1.0) if bl.get("frost", false) else Color.WHITE
		_fx.draw_set_transform(bl.pos, bl.vel.angle(), Vector2.ONE)
		if look != "":
			var lt: Texture2D = PilotRig.tinted(_fx_tex[look], _bolt_set)
			var LL: float = {"bolt_rail": 38.0, "bolt_spark": 32.0, "bolt_heavy": 24.0 + 6.0 * bw, "bolt_twin": 28.0}[look] * big
			var lh: float = LL * lt.get_height() / lt.get_width()
			_fx.draw_texture_rect(lt, Rect2(-LL * 0.8, -lh * 0.5, LL, lh), false, tint)
			continue
		var BL := 26.0 * (0.85 + 0.15 * bw) * big
		var bth: float = BL * bt0.get_height() / bt0.get_width() * bw * (1.2 if big > 1.3 else 1.0)
		_fx.draw_texture_rect(PilotRig.tinted(bt0, _bolt_set), Rect2(-BL * 0.85, -bth * 0.5, BL, bth), false, tint)
	# Swarm drones
	var dt: Texture2D = _fx_tex["drone"]
	for dr in drones:
		var da: float = minf(1.0, dr.age / 0.15) * minf(1.0, dr.life / 0.4)
		_fx.draw_set_transform(dr.pos, dr.vel.angle(), Vector2.ONE)
		_fx.draw_texture_rect(dt, Rect2(-11, -11 * dt.get_height() / dt.get_width(), 22, 22 * dt.get_height() / dt.get_width()), false, Color(1, 1, 1, da))
	_draw_turret_lights()
	# a boss still arriving is untouchable (_can_hurt): a pulsing veil of light says so (dev164)
	for e in enemies:
		if e.type == "hive_mother" and not e.get("arrived", false):
			var pulse := 0.5 + 0.5 * sin(time_alive * 6.0)
			_fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			Backdrop.soft_glow(_fx, e.pos, float(e.r) * 1.7, Color(0.8, 0.55, 1.0, 0.2 + 0.12 * pulse))
	for t in turrets:
		if t.drop >= 1.0 and CHARGE_COL.has(t.type):
			# charge-up: light gathers at the weapon in the last moments before a shot,
			# holds (softly pulsing) while it waits for a target, and empties when it fires
			var every: float = float(t.def.every)
			var kc: float = smoothstep(minf(0.8, every * 0.6), 0.0, float(t.cd)) * (0.85 + 0.15 * sin(time_alive * 6.0 + float(t.mount)))
			if kc > 0.02:
				var col: Color = CHARGE_COL[t.type]
				_fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				Backdrop.soft_glow(_fx, _turret_tip(t), 6.0 + 9.0 * kc, Color(col, 0.55 * kc))
	for t in turrets:
		if t.drop < 1.0:
			continue
		match String(t.type):
			"lance":
				# the tip gathers light while it charges; firing throws a beam to the sky
				var tip := _turret_tip(t)
				var kc: float = clampf(t.charge / float(t.def.every), 0.0, 1.0)
				_fx_sprite("lance_flare", tip, 8.0 + 26.0 * kc * kc, 0.25 + 0.6 * kc)
				if t.fire_t > 0.0:
					var kf: float = t.fire_t / FIRE_TIME.lance
					var bt: Texture2D = _fx_tex["lance_beam"]
					_fx.draw_set_transform(tip, float(t.ang), Vector2.ONE)
					_fx.draw_texture_rect(bt, Rect2(0, -14.0 * kf, 900.0, 28.0 * kf), false)
					_fx_sprite("lance_flare", tip, 70.0 * kf, kf)
			"gravity":
				var pulling: float = smoothstep(0.0, 1.0, float(t.get("well_a", 0.0)))
				var after: float = float(t.fire_t) / FIRE_TIME.gravity
				var wa: float = maxf(pulling, after)
				if wa > 0.01:
					var gt: Texture2D = _fx_tex["gravity_ring"]
					var gs: float = 120.0 * (0.6 + 0.4 * pulling)
					_fx.draw_set_transform(_gravity_centre(t), -time_alive * 2.0, Vector2.ONE)
					_fx.draw_texture_rect(gt, Rect2(-gs * 0.5, -gs * 0.5, gs, gs), false, Color(1, 1, 1, 0.9 * wa))
			"prism":
				if float(t.get("orb_t", 0.0)) > 0.0:
					var kk: float = smoothstep(0.0, 1.0, 1.0 - float(t.orb_t) / 0.25)
					var p: Vector2 = _turret_tip(t).lerp(Vector2(t.pos.x, BASE_Y - float(t.def.split_h)), kk)
					_fx_sprite("prism_burst", p, 26.0, 0.9)
				if t.fire_t > 0.0 and t.has("beams"):
					var fa: float = smoothstep(0.0, FIRE_TIME.prism, float(t.fire_t))
					var pt: Texture2D = _fx_tex["prism_beam"]
					for s in t.beams:
						var seg: Vector2 = s[1] - s[0]
						_fx.draw_set_transform(s[0], seg.angle(), Vector2.ONE)
						_fx.draw_texture_rect(pt, Rect2(0, -8, seg.length(), 16), false, Color(0.8, 0.8, 0.8, fa))
	_fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _fx_sprite(name: String, pos: Vector2, size: float, alpha: float) -> void:
	var tex: Texture2D = _fx_tex[name]
	var h: float = size * tex.get_height() / tex.get_width()
	_fx.draw_set_transform(pos, 0.0, Vector2.ONE)
	_fx.draw_texture_rect(tex, Rect2(-size * 0.5, -h * 0.5, size, h), false, Color(1, 1, 1, alpha))

# Behind the enemies: the Storm Spire's cloud and the Gravity Anchor's well.
func _draw_turret_back() -> void:
	for t in turrets:
		if t.type == "gravity":
			_draw_gravity_well(t)
		if t.type != "storm":
			continue
		var def: Dictionary = t.def
		var c := _storm_centre(t)
		var r: float = float(def.cloud_r)
		var a: float = float(t.build) * smoothstep(0.0, 1.0, float(t.get("storm_a", 0.0)))
		if a < 0.01:
			continue
		var col: Color = def.glow
		# flattened puffs, the middle ones higher, drifting slowly
		for i in 7:
			var f: float = float(i) / 6.0
			var p := c + Vector2((f - 0.5) * r * 1.6, sin(f * PI * 2.0 + time_alive * 0.7) * 5.0 - sin(f * PI) * 12.0)
			draw_set_transform(p, 0.0, Vector2(1.0, 0.55))
			draw_circle(Vector2.ZERO, r * (0.24 + 0.14 * sin(f * PI)), Color(col.darkened(0.6), 0.16 * a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if t.fire_t > 0.0:
			draw_line(_turret_tip(t), c, Color(col, 0.35), 1.0, true)

# The well grows in while it pulls (three thin arcs turning inward) and fades
# out after the pulse.
func _draw_gravity_well(t: Dictionary) -> void:
	var def: Dictionary = t.def
	var c := _gravity_centre(t)
	var pulling: float = smoothstep(0.0, 1.0, float(t.get("well_a", 0.0)))
	var after: float = float(t.fire_t) / FIRE_TIME.gravity
	var a: float = maxf(pulling, after)
	if a < 0.01:
		return
	var col: Color = def.glow
	# a faint tether from the turret shows whose well it is
	draw_line(_turret_tip(t), c, Color(col, 0.18 * a), 1.0, true)

# In front of the enemies: the Storm Spire's lightning (the rest of the turret
# light is on the additive layer, _draw_fx).
func _draw_turret_front() -> void:
	for t in turrets:
		if t.type == "storm" and t.fire_t > 0.0 and t.bolt.size() > 1:
			var col: Color = Turrets.TURRETS.storm.glow
			var a: float = smoothstep(0.0, FIRE_TIME.storm, float(t.fire_t))
			for i in t.bolt.size() - 1:
				var pts := _zigzag(t.bolt[i], t.bolt[i + 1], int(t.get("bolt_seed", 0)) + i)
				draw_polyline(pts, Color(col, 0.5 * a), 3.0, true)
				draw_polyline(pts, Color(0.92, 0.9, 1.0, a), 1.2, true)

func _zigzag(a: Vector2, b: Vector2, seed: int) -> PackedVector2Array:
	var zr := RandomNumberGenerator.new()
	zr.seed = seed
	var pts := PackedVector2Array([a])
	var n := Vector2(-(b - a).y, (b - a).x).normalized()
	for i in range(1, 6):
		pts.append(a.lerp(b, float(i) / 6.0) + n * zr.randf_range(-7.0, 7.0))
	pts.append(b)
	return pts

# Top bar layout (drawn by _draw_hud on the _hc layer)
const HUD_H := 70.0                  # bar height (the XP bar runs along its bottom)
const PAUSE_RECT := Rect2(FIELD_W - 50, 10, 36, 30)
const SPEED_RECT := Rect2(FIELD_W - 92, 10, 36, 30)
const CARDS_RECT := Rect2(FIELD_W - 134, 10, 36, 30)

# A small glass button on the top bar (lit cyan while its panel is open / active).
func _hud_frame(p: Rect2, active: bool) -> void:
	var fill := Color(0.18 * 0.3, 0.9 * 0.3, 0.3, 0.75) if active else Color(0.035, 0.06, 0.14, 0.7)
	Glass.panel(_hc, Glass.box(p, 9.0), 1.0, Color(Glass.CYAN, 0.9) if active else Color(0, 0, 0, 0), fill)

# Luna's heart; a lost heart shows as a dark, see-through shape.
func _draw_heart(c: Vector2, s: float, on: bool) -> void:
	var ht: Texture2D = _tex["ui_heart"]
	var hw := s * 2.3
	var hh: float = hw * ht.get_height() / ht.get_width()
	_hc.draw_texture_rect(ht, Rect2(c.x - hw * 0.5, c.y - hh * 0.5, hw, hh), false, Color(1, 1, 1) if on else Color(0.25, 0.28, 0.4, 0.45))

# The battle's top bar in the Home Glass look (Rudy, dev111): a dark shade behind the
# notch, a floating glass capsule with the stage, timer and glass buttons on row 1, score,
# wave pips and hearts on row 2, then the run XP as a cyan-to-purple bar under it with
# the run level on a glass chip.
func _draw_hud() -> void:
	var cyan := Color(0.18, 0.9, 1.0)
	var muted := Color(0.62, 0.70, 0.84)
	_draw_hurt_edge()
	if _safe_top > 0.0:
		_hc.draw_rect(Rect2(0, -_safe_top - 2.0, FIELD_W, _safe_top + 6.0), Color(0.02, 0.03, 0.08, 0.85))
	Glass.panel(_hc, Glass.box(Rect2(6, 3, FIELD_W - 12, HUD_H - 9), 16.0), 1.0, Color(0, 0, 0, 0), Color(0.03, 0.05, 0.12, 0.72))
	# row 1: stage number (white) and name (cyan), then the run time
	var num := "%d " % stage
	_hc.draw_string(title_font, Vector2(18, 30), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
	var nx: float = 18.0 + title_font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	_hc.draw_string(title_font, Vector2(nx, 30), (("TRIAL · " + String(Promotion.RANKS[promo].name)) if promo >= 0 else StageData.stage_name(stage)).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 240.0 - nx, 13, UIKit.GOLD if promo >= 0 else cyan)
	var mins := int(time_alive) / 60
	var secs := int(time_alive) % 60
	_hc.draw_string(hud_font, Vector2(CARDS_RECT.position.x - 88, 30), "%02d:%02d" % [mins, secs], HORIZONTAL_ALIGNMENT_RIGHT, 80, 13, muted)
	if Perf.show_fps:   # Settings > frame counter
		_hc.draw_string(hud_font, Vector2(18, HUD_H + 14), "%d fps" % Engine.get_frames_per_second(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(muted, 0.8))
	# cards button: three small fanned cards
	_hud_frame(CARDS_RECT, _cards_open)
	var cc := CARDS_RECT.get_center()
	for k in 3:
		_hc.draw_set_transform(cc + Vector2((k - 1) * 4.0, 2.0), (k - 1) * 0.28, Vector2.ONE)
		_hc.draw_rect(Rect2(-5, -8, 10, 14), Color(0.05, 0.08, 0.16))
		_hc.draw_rect(Rect2(-5, -8, 10, 14), Color(0.85, 0.75, 1.0) if k == 1 else Color(cyan, 0.9), false, 1.2)
	_hc.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# game speed
	_hud_frame(SPEED_RECT, game_speed > 1.0)
	_hc.draw_string(title_font, SPEED_RECT.position + Vector2(0, 20), "x%s" % (str(game_speed) if game_speed != 1.0 else "1"), HORIZONTAL_ALIGNMENT_CENTER, SPEED_RECT.size.x, 11, Color.WHITE if _speeds().size() > 1 else Color(1, 1, 1, 0.5))
	# pause button: two thin bars (a play arrow while paused)
	var p := PAUSE_RECT
	_hud_frame(p, paused)
	var pc := p.get_center()
	if paused:
		_hc.draw_colored_polygon(PackedVector2Array([pc + Vector2(-5, -8), pc + Vector2(8, 0), pc + Vector2(-5, 8)]), Color.WHITE)
	else:
		_hc.draw_rect(Rect2(pc + Vector2(-6, -8), Vector2(3.5, 16)), Color.WHITE)
		_hc.draw_rect(Rect2(pc + Vector2(2.5, -8), Vector2(3.5, 16)), Color.WHITE)
	# row 2: score, waves as pips (text when there are many), hearts
	var y2 := 52.0
	_hc.draw_string(hud_font, Vector2(18, y2), "SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, muted)
	_hc.draw_string(hud_font, Vector2(58, y2), str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	var wave_now := mini(wave_index + 1, waves.size())
	var wx := 160.0
	_hc.draw_string(hud_font, Vector2(wx, y2), "WAVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, muted)
	wx += 36.0
	if waves.size() <= 10:
		for i in waves.size():
			var r := Rect2(wx + i * 13.0, y2 - 9.0, 9.0, 9.0)
			var dia := PackedVector2Array([Vector2(r.get_center().x, r.position.y), Vector2(r.end.x, r.get_center().y),
				Vector2(r.get_center().x, r.end.y), Vector2(r.position.x, r.get_center().y), Vector2(r.get_center().x, r.position.y)])
			if i < wave_now - 1:
				_hc.draw_colored_polygon(dia, Color(cyan, 0.85))
			elif i == wave_now - 1:
				_hc.draw_colored_polygon(dia, Color.WHITE)
			_hc.draw_polyline(dia, Color(cyan, 0.6), 1.0, true)
	else:
		_hc.draw_string(hud_font, Vector2(wx, y2), "%d/%d" % [wave_now, waves.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	for i in max_hearts:
		_draw_heart(Vector2(FIELD_W - 24 - (max_hearts - 1 - i) * 22, y2 - 3), 7.5, i < hearts)
	# run XP: a rounded track under the capsule, filled cyan to purple, level on a chip
	var need := _xp_need()
	var xp := clampf(run_xp / need, 0.0, 1.0)
	var track := Rect2(64, HUD_H - 1, FIELD_W - 82, 5)
	_hc.draw_colored_polygon(Glass.box(track, 2.5).slice(0, -1), Color(0.03, 0.05, 0.12, 0.8))
	if xp > 0.02:
		var fr := Rect2(track.position, Vector2(track.size.x * xp, track.size.y))
		var pts := Glass.box(fr, 2.5).slice(0, -1)
		var cols := PackedColorArray()
		for q in pts:
			cols.append(Glass.CYAN.lerp(Glass.PURPLE, clampf((q.x - track.position.x) / track.size.x, 0.0, 1.0)))
		_hc.draw_polygon(pts, cols)
	var chip := Rect2(12, HUD_H - 8, 48, 18)
	Glass.panel(_hc, Glass.box(chip, 8.0), 1.0, Color(Glass.PURPLE, 0.8), Color(0.08, 0.05, 0.16, 0.9))
	_hc.draw_string(hud_font, Vector2(chip.position.x, chip.position.y + 13), "LV %d" % run_level, HORIZONTAL_ALIGNMENT_CENTER, chip.size.x, 11, Color(0.9, 0.84, 1.0))
	for e in enemies:
		if e.type == "hive_mother":
			_draw_boss_bar(e)
	_draw_objectives_banner()
	_draw_intro()

# A boss's health in stacked layers (5 for a boss, 3 for a mini-boss): the bar empties
# one colour at a time, the next colour shows underneath, "x3" counts what is left,
# a white chunk trails each hit and the bar flashes when a layer breaks.
const BOSS_LAYER_COLS := [Color(0.95, 0.30, 0.40), Color(1.0, 0.55, 0.25), Color(1.0, 0.85, 0.3), Color(0.45, 0.9, 0.5), Color(0.80, 0.40, 1.0)]

func _boss_layers(e: Dictionary) -> int:
	return 3 if e.get("mini", false) else 5

func _draw_boss_bar(e: Dictionary) -> void:
	var a: float = smoothstep(0.0, 1.0, _boss_bar_in)
	if a <= 0.0:
		return
	var layers := _boss_layers(e)
	var f := clampf(e.hp / e.hp_max, 0.0, 1.0)
	var lag := clampf(_boss_bar_hp / e.hp_max, 0.0, 1.0)
	var cur := maxi(ceili(f * layers - 0.0001), 1)        # layers left, counting the one in use
	var fill := clampf(f * layers - (cur - 1), 0.0, 1.0)
	var lag_fill := clampf(lag * layers - (cur - 1), 0.0, 1.0)
	var bw := 260.0
	var by := HUD_H + 34.0 - 8.0 * (1.0 - a)
	var r := Rect2(FIELD_W * 0.5 - bw * 0.5, by, bw, 8)
	var cut := 5.0
	var frame := PackedVector2Array([r.position + Vector2(-cut - 3, 4), r.position + Vector2(-3, -3), Vector2(r.end.x + 3, r.position.y - 3),
		Vector2(r.end.x + cut + 3, r.position.y + 4), Vector2(r.end.x + 3, r.end.y + 3), Vector2(r.position.x - 3, r.end.y + 3), r.position + Vector2(-cut - 3, 4)])
	_hc.draw_colored_polygon(frame, Color(0.03, 0.045, 0.10, 0.85 * a))
	var col: Color = BOSS_LAYER_COLS[(cur - 1) % BOSS_LAYER_COLS.size()]
	# the next layer down shows under the current one
	if cur > 1:
		_hc.draw_rect(r, Color(BOSS_LAYER_COLS[(cur - 2) % BOSS_LAYER_COLS.size()], 0.55 * a))
	_hc.draw_rect(Rect2(r.position, Vector2(bw * lag_fill, r.size.y)), Color(1, 1, 1, 0.75 * a))
	_hc.draw_rect(Rect2(r.position, Vector2(bw * fill, r.size.y)), Color(col, a))
	_hc.draw_line(r.position + Vector2(0, 1), Vector2(r.position.x + bw * fill, r.position.y + 1), Color(1, 1, 1, 0.35 * a), 1.0)   # top sheen
	# quarter ticks
	for k in range(1, 4):
		var tx := r.position.x + bw * k * 0.25
		_hc.draw_line(Vector2(tx, r.position.y), Vector2(tx, r.end.y), Color(0.03, 0.045, 0.10, 0.6 * a), 1.0)
	var edge := Color(1, 1, 1, a).lerp(Color(col, a), 1.0 - _boss_flash)
	_hc.draw_polyline(frame, Color(edge, (0.6 + 0.4 * _boss_flash) * a), 1.0 + _boss_flash, true)
	var bname := "YOUNG HIVE MOTHER" if e.get("mini", false) else "HIVE MOTHER"
	_hc.draw_string(title_font, Vector2(r.position.x, by - 7), bname, HORIZONTAL_ALIGNMENT_LEFT, bw - 40, 11, Color(1, 0.85, 0.9, a))
	_hc.draw_string(title_font, Vector2(r.end.x - 40, by - 7), "x%d" % cur, HORIZONTAL_ALIGNMENT_RIGHT, 40, 12 + int(4.0 * _boss_flash), Color(col.lightened(0.3), a))

# "NEW ENEMY" card under the top bar, the first time a player meets a bug type. It
# slides in, stays a few seconds and fades; the game keeps running behind it.
func _draw_intro() -> void:
	if _intro.is_empty():
		return
	var t: float = _intro.t
	var a: float = smoothstep(0.0, 0.25, t) * (1.0 - smoothstep(3.5, 4.0, t))
	var id: String = _intro.id
	var r := Rect2(FIELD_W * 0.5 - 160.0, HUD_H + 34.0 - 10.0 * (1.0 - smoothstep(0.0, 0.25, t)), 320.0, 74.0)
	var cut := 10.0
	var frame := PackedVector2Array([r.position + Vector2(cut, 0), Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.end.y - cut),
		Vector2(r.end.x - cut, r.end.y), Vector2(r.position.x, r.end.y), r.position + Vector2(0, cut), r.position + Vector2(cut, 0)])
	_hc.draw_colored_polygon(frame, Color(0.03, 0.045, 0.10, 0.88 * a))
	_hc.draw_polyline(frame, Color(1.0, 0.55, 0.35, 0.8 * a), 1.2, true)
	# the bug itself, small, on the left
	var icon := r.position + Vector2(38.0, 37.0)
	if id == "hive_mother":
		EnemyRig.draw_hive_mother(_hc, icon, 26.0, time_alive, 0.0, false)
	else:
		EnemyRig.draw_bug(_hc, id, icon, 46.0, time_alive, 0.0, 0.0, 0.0, 1.0, a)
	_hc.draw_string(title_font, r.position + Vector2(76.0, 20.0), "NEW ENEMY", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.6, 0.4, a))
	_hc.draw_string(hud_font, r.position + Vector2(76.0, 38.0), id.replace("_", " ").capitalize(), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, a))
	_hc.draw_multiline_string(hud_font, r.position + Vector2(76.0, 54.0), String(StageData.ENEMIES[id].intro), HORIZONTAL_ALIGNMENT_LEFT, 236.0, 11, 2, Color(0.75, 0.82, 0.92, a))

# Luna's armoured hatch over a locked socket. On the first run after a mount opens,
# the hatch tips up (closed -> half -> open, standing behind the socket) with a cyan
# flash, then folds away, and the turret drops in.
func _draw_socket_lid(i: int) -> void:
	var p: Vector2 = _socket(i)
	var w := 52.0
	var open: bool = Turrets.mount_open(i, stage_unlocked)
	if open and not _lid_anim.has(i):
		return
	var t: float = float(_lid_anim.get(i, 0.0)) if open else 0.0
	var closed_a := 1.0 - smoothstep(0.0, 0.3, t)
	var half_a := smoothstep(0.0, 0.3, t) * (1.0 - smoothstep(0.3, 0.6, t))
	var open_a := smoothstep(0.3, 0.6, t) * (1.0 - smoothstep(1.0, 1.5, t))
	_lid_pic("lid_closed", p + Vector2(0, -1), w, closed_a, 0.5)
	_lid_pic("lid_half", p + Vector2(0, -2), w, half_a, 0.75)
	if open_a > 0.01:
		var ot: Texture2D = _tex["lid_open"]
		var oh := 40.0
		var ow: float = oh * ot.get_width() / ot.get_height()
		draw_texture_rect(ot, Rect2(p.x - ow * 0.5, p.y - oh - 2.0, ow, oh), false, Color(1, 1, 1, open_a))
	if open and t > 0.25 and t < 0.9:
		var k := (t - 0.25) / 0.65
		draw_set_transform(p, 0.0, Vector2(1.0, 0.36))
		draw_arc(Vector2.ZERO, 18.0 + 26.0 * k, 0.0, TAU, 32, Color(0.18, 0.9, 1.0, 0.8 * (1.0 - k)), 2.0, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# a hatch picture, its width `w`, placed so the point `anchor_y` (0..1 down the picture)
# sits on p
func _lid_pic(name: String, p: Vector2, w: float, a: float, anchor_y: float) -> void:
	if a <= 0.01:
		return
	var tx: Texture2D = _tex[name]
	var h: float = w * tx.get_height() / tx.get_width()
	draw_texture_rect(tx, Rect2(p.x - w * 0.5, p.y - h * anchor_y, w, h), false, Color(1, 1, 1, a))

# ------------------------------------------------------------------ speed and cards view

# Game speeds the player has: x1 always, x1.5 once stage 10 is cleared, x2 with the
# speed pack (a store item, save "speed_pack").
func _speeds() -> Array:
	var s := [1.0]
	if stage_unlocked > 10:
		s.append(1.5)
	if _speed_pack:
		s.append(2.0)
	return s

func _cycle_speed() -> void:
	var s := _speeds()
	if s.size() == 1:
		_float_text(Vector2(FIELD_W - 120, HUD_H + 40), "x1.5 unlocks after stage 10", Color(0.75, 0.82, 0.92))
		return
	var i := s.find(game_speed)
	game_speed = s[(i + 1) % s.size()]
	_write_save({"game_speed": game_speed})
	queue_redraw()

# "Your cards": every card picked this run with its picture and level. Pauses the game.
func _toggle_cards() -> void:
	if picking or game_over or stage_cleared or (paused and not _cards_open):
		return
	_cards_open = not _cards_open
	paused = _cards_open
	dragging = false
	drag_id = -1
	for c in _cards_view.get_children():
		c.queue_free()
	_cards_view.visible = _cards_open
	if not _cards_open:
		queue_redraw()
		return
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.01, 0.04, 0.6)
	dim.size = get_viewport_rect().size
	dim.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed: _toggle_cards())
	_cards_view.add_child(dim)
	var box := UIKit.panel(16)
	box.position = Vector2(24, HUD_H + 40)
	box.custom_minimum_size = Vector2(FIELD_W - 48, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	var title := UIKit.label("YOUR CARDS", 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_override("font", title_font)
	v.add_child(title)
	if card_levels.is_empty():
		v.add_child(UIKit.label("No cards yet. Collect gems to level up!", 12, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for id in card_levels:
		var def: Dictionary = Cards.def(id)
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(92, 0)
		cell.add_child(_card_pic(id, 56.0 if not Cards.FUSIONS.has(id) else 40.0))
		var nl := UIKit.label(def.name, 11, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cell.add_child(nl)
		var lv_text := "FUSION" if Cards.FUSIONS.has(id) else "Lv.%d / %d" % [int(card_levels[id]), int(def.max)]
		cell.add_child(UIKit.label(lv_text, 10, Cards.COLOR[def.rarity], HORIZONTAL_ALIGNMENT_CENTER))
		if Cards.CARDS.has(id) and Cards.overcharged(card_levels, id):
			cell.add_child(UIKit.label("OVERCHARGED", 9, Color(1.0, 0.82, 0.32), HORIZONTAL_ALIGNMENT_CENTER))
		grid.add_child(cell)
	v.add_child(grid)
	var close := UIKit.gold_button("Back to battle")
	close.custom_minimum_size = Vector2(0, 42)
	close.pressed.connect(_toggle_cards)
	v.add_child(close)
	box.add_child(v)
	_cards_view.add_child(box)
	box.modulate.a = 0.0
	box.create_tween().tween_property(box, "modulate:a", 1.0, 0.15)

# ------------------------------------------------------------------ area briefing

# The first time a player reaches a planet (its first stage), a comms message from base
# says where they are; the battle waits until they tap Launch. Save "areas_briefed".
func _maybe_brief() -> void:
	if elite or StageData.area_stage(stage) != 1:
		return
	var ai := StageData.area_index(stage)
	var done: Array = []
	for v in Array(_read_save().get("areas_briefed", [])):
		done.append(int(v))   # the save stores numbers as decimals; compare as whole numbers
	if done.has(ai):
		return
	done.append(ai)
	_write_save({"areas_briefed": done})
	paused = true
	var panel := Control.new()
	panel.size = get_viewport_rect().size
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.01, 0.04, 0.7)
	dim.size = panel.size
	panel.add_child(dim)
	var box := UIKit.panel(16)
	box.position = Vector2(30, panel.size.y * 0.5 - 150)
	box.custom_minimum_size = Vector2(FIELD_W - 60, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	var tag := UIKit.label("INCOMING TRANSMISSION", 11, Color(1.0, 0.6, 0.4), HORIZONTAL_ALIGNMENT_CENTER)
	tag.add_theme_font_override("font", title_font)
	v.add_child(tag)
	var a: Dictionary = StageData.area(stage)
	var title := UIKit.label(String(a.name).to_upper(), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_override("font", title_font)
	v.add_child(title)
	v.add_child(UIKit.label("Planet %d of %d" % [ai + 1, StageData.AREAS.size()], 11, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var msg := UIKit.label("", 14, Color(0.85, 0.92, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.custom_minimum_size = Vector2(FIELD_W - 100, 66)
	v.add_child(msg)
	var go := UIKit.gold_button("Launch")
	go.custom_minimum_size = Vector2(0, 46)
	go.pressed.connect(func():
		paused = false
		panel.queue_free())
	v.add_child(go)
	box.add_child(v)
	panel.add_child(box)
	add_child(panel)
	# the message types itself out, like a radio transmission
	var full: String = a.brief
	box.modulate.a = 0.0
	var tw := box.create_tween()
	tw.tween_property(box, "modulate:a", 1.0, 0.25)
	tw.tween_method(func(n: float): msg.text = full.substr(0, int(n)), 0.0, float(full.length()), full.length() * 0.025)

# An upgrade part lying on the field: Luna's icon (parts/<kind>.png) when it arrives,
# else a small faceted shape in the part's colour with a slow turn.
func _draw_part_pickup(p: Vector2, kind: String, a: float) -> void:
	var col: Color = Parts.KINDS[kind].color
	draw_circle(p, 13.0, Color(0.0, 0.01, 0.05, 0.55 * a))
	draw_arc(p, 12.0 + sin(time_alive * 5.0) * 1.0, 0.0, TAU, 20, Color(col, 0.8 * a), 1.4, true)
	if _tex.has("part_" + kind):
		draw_texture_rect(_tex["part_" + kind], Rect2(p - Vector2(11, 11), Vector2(22, 22)), false, Color(1, 1, 1, a))
		return
	var sides: int = {"alloy": 4, "cell": 6, "core": 8}[kind]
	var pts := PackedVector2Array()
	for i in sides:
		var ang := time_alive * 1.5 + TAU * i / sides
		pts.append(p + Vector2(cos(ang), sin(ang) * 0.8) * 7.0)
	draw_colored_polygon(pts, Color(col.darkened(0.3), a))
	pts.append(pts[0])
	draw_polyline(pts, Color(col.lightened(0.4), a), 1.2, true)

# Which upgrade parts a dying bug drops (Parts; Rudy: modes and later stages give more
# and rarer parts). Bugs: now and then Alloy Scrap, more often on later stages; from
# planet 3 they can drop a Plasma Cell. Young Hive Mother: Alloy + a Cell. Boss: Alloy,
# 2 Cells, and from stage 20 a 35-60% chance of a Void Core (Boss Rush, when built, is
# the Core mode). Rarer parts only come in on later stages (Rudy, dev115).
# Elite: everything doubles and bugs can drop Cells from the start.
func _part_drops(e: Dictionary, def: Dictionary) -> Array:
	var out: Array = []
	var later: float = clampf(float(stage) / 60.0, 0.0, 1.0)
	if e.type == "hive_mother":
		if e.get("mini", false):
			out = ["alloy", "alloy", "alloy", "cell"]
		else:
			out = ["alloy", "alloy", "alloy", "alloy", "cell", "cell"]
			if stage >= 20 and rng.randf() < 0.35 + 0.25 * later:   # rare parts only on later planets
				out.append("core")
	elif e.type != "spore":
		var tough: bool = int(def.xp_tier) >= 1 or def.has("fire_every")
		if rng.randf() < (0.05 if tough else 0.025) * (1.0 + 1.5 * later):
			out.append("alloy")
		if (stage >= 21 or elite) and rng.randf() < 0.004 + 0.008 * later:
			out.append("cell")
	if elite:
		out.append_array(out.duplicate())
	return out

# bug health for this run: the stage's scaling, Elite, and a promotion trial on top
func _hp_mult() -> float:
	return StageData.hp_mult(stage, elite) * (Promotion.hp_mult(promo) if promo >= 0 else 1.0)

# A turret head swinging to a new target on a damped spring (dev153): it arrives fast,
# overshoots a touch and settles, instead of easing in. k = stiffness, d = damping.
func _spring_ang(t: Dictionary, want: float, delta: float, k: float, d: float) -> void:
	var v: float = float(t.get("ang_v", 0.0))
	var diff := angle_difference(float(t.ang), want)
	v += (diff * k - v * d) * minf(delta, 0.05)
	t.ang_v = v
	t.ang = float(t.ang) + v * minf(delta, 0.05)

# A red flash round the screen edge the moment the pilot loses a heart (dev156), fading
# over a third of a second; drawn on the HUD layer so it sits over the whole field.
func _draw_hurt_edge() -> void:
	var start: float = 1.5 * _recovery
	if inv_t <= 0.0 or start <= 0.0:
		return
	var k: float = smoothstep(start - 0.4, start, inv_t)
	if k <= 0.01:
		return
	var red := Color(1.0, 0.22, 0.25, 0.5 * k)
	var clear := Color(1.0, 0.22, 0.25, 0.0)
	var top: float = -_safe_top
	var w := 90.0
	# four gradient bands: dark red at the edge, clear toward the middle
	_hc.draw_polygon(PackedVector2Array([Vector2(0, top), Vector2(FIELD_W, top), Vector2(FIELD_W, top + w), Vector2(0, top + w)]), PackedColorArray([red, red, clear, clear]))
	_hc.draw_polygon(PackedVector2Array([Vector2(0, FIELD_H - w), Vector2(FIELD_W, FIELD_H - w), Vector2(FIELD_W, FIELD_H), Vector2(0, FIELD_H)]), PackedColorArray([clear, clear, red, red]))
	_hc.draw_polygon(PackedVector2Array([Vector2(0, top), Vector2(w, top), Vector2(w, FIELD_H), Vector2(0, FIELD_H)]), PackedColorArray([red, clear, clear, red]))
	_hc.draw_polygon(PackedVector2Array([Vector2(FIELD_W - w, top), Vector2(FIELD_W, top), Vector2(FIELD_W, FIELD_H), Vector2(FIELD_W - w, FIELD_H)]), PackedColorArray([clear, red, red, clear]))

# A boss cannot be hurt until she has fully arrived and can act (Rudy, dev163): the Hive
# Mother (and the young one mid-stage) is untouchable while she descends to her hover height.
func _can_hurt(e: Dictionary) -> bool:
	return e.type != "hive_mother" or bool(e.get("arrived", false))
