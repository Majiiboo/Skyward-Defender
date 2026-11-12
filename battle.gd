extends Node2D
# Skybound battle. Data lives in stage_data.gd (sectors, enemies, waves) and
# cards.gd (power cards); this file runs the fight.
#
# Loop: waves of enemies arrive from the top; the pilot flies where you drag
# and fires straight up, or auto-aims when your finger is lifted; kills drop XP
# gems; collecting gems fills the run level and offers 3 cards; the base and its buildings
# help. Enemies that reach the force field hurt the shield, then the hull.
# Clear the last wave to win the stage.

const FIELD_W := 480.0
var FIELD_H := 800.0
var BASE_Y := 786.0
const DOME_RX := 300.0
const DOME_RY := 112.0
const PILOT_HEIGHT := 60.0
const FX_NAMES := ["sentry_tracer", "spark", "lance_flare", "lance_beam", "storm_zap", "gravity_ring", "crush", "drone", "pop", "prism_beam", "prism_burst", "bolt", "impact", "nova", "bolt_rail", "bolt_spark", "bolt_heavy", "bolt_twin"]
const SAVE := "user://skybound_save.json"

# ---- weapons ----
const WEAPONS := {
	# WEAPONS THAT PLAY DIFFERENTLY (2026-11-10, step 3 of DESIGN-base-and-helpers.md; texts in GearData.WEAPON_TEXT).
	# Energy, the all-rounder: every 5th bolt is a CHARGED SHOT (three times the damage)
	"laser_pistol": {"name": "Laser Pistol", "interval": 0.22, "speed": 520.0, "damage": 0.72, "projectiles": 1, "spread": 0.0, "hit_radius": 22.0, "charge": 5},
	# Scavenger set: two small bolts side by side (a bit more damage, some misses)
	"dual_minis": {"name": "Dual Minis", "interval": 0.22, "speed": 540.0, "damage": 0.52, "projectiles": 2, "spread": 0.07, "hit_radius": 18.0, "spark_every": 3},   # Electric: twin bolts, every 3rd ARCS to a second bug
	# Void set: a slow, heavy bolt (same damage per second, more per hit)
	"pulse_cannon": {"name": "Pulse Cannon", "interval": 0.44, "speed": 430.0, "damage": 1.85, "projectiles": 1, "spread": 0.0, "hit_radius": 28.0, "big": true, "splash": 62.0},   # Void: slow shells that EXPLODE (the blast hits bugs around the one it struck)
	# Nightmare set: slow rail bolts that pierce every bug in their line
	"railgun": {"name": "Railgun", "interval": 0.45, "speed": 640.0, "damage": 1.5, "projectiles": 1, "spread": 0.0, "hit_radius": 20.0, "rail": true},
	# Solar set: fast, long-range bolts
	"laser_rifle": {"name": "Sun Rifle", "interval": 0.3, "speed": 620.0, "damage": 0.62, "projectiles": 3, "spread": 0.5, "hit_radius": 20.0, "range": 340.0},   # Fire: a FAN of three short-range bolts: fly close and it hits hardest
	# Frost set: rapid small bolts
	"frost_rifle": {"name": "Frost Rifle", "interval": 0.14, "speed": 560.0, "damage": 0.58, "projectiles": 1, "spread": 0.03, "hit_radius": 18.0, "frost": true},   # Ice: a rapid stream that SLOWS what it hits
}
var weapon_id := "laser_pistol"
var weapon_form := 1            # the weapon's shape (GearData.WEAPON_FORMS): II from Lv.10, III from Lv.20
var _wpn := {}
var _wpn_key := ""

# the weapon in hand: its WEAPONS row with its form's changes laid over it (cached)
func _weapon() -> Dictionary:
	var key := "%s/%d" % [weapon_id, weapon_form]
	if key != _wpn_key:
		_wpn = Dictionary(WEAPONS[weapon_id]).duplicate()
		_wpn.merge(GearData.form_mods(weapon_id, weapon_form), true)
		_wpn_key = key
	return _wpn

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
var _perk_twin := false            # hero perk: every 6th shot brings a twin
var burst_left := 0
var burst_timer := 0.0
var burst_dir := Vector2.UP
var burst_tid := -2
var pilot_hp_max := 100.0           # the pilot's HP (instead of three hearts, dev172): Heroes.stats "hp"
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
var horde := false                # HORDE mode (dev172): endless waves, beat your best; save "best_horde"
var daily := false                # the DAILY CHALLENGE (Promotion.daily_*): three twists, one reward a day
var boss_rush := false            # BOSS RUSH (BossRush): every boss you have beaten, in a row, against the clock
var _rush := {}                    # what the run paid (BossRush.finish; end screen)
var event_run := false            # a WEEKLY EVENT fight (Events): the week's twists, event points at the end
var _event_points := 0            # what this fight paid (end screen)
var _abilities_used := 0          # times the ability was fired this fight (Contracts)
var _season_xp := 0               # season XP this fight paid (Season; end screen)
var _season_up := false           # it filled a tier
var _daily_reward := {}           # what today's first win paid (end screen)
var _horde_best := 0              # the best wave count before this run
var _horde_new_best := false
var etrial := {}                  # an element trial (Promotion.take_etrial): {"el", "step"}; {} = none
var _etrial_first := false        # this win cleared the step for the first time
var _etrial_reward := {}          # what it paid (end screen)
var _mods: Array = []             # the trial advantages and disadvantages in force (Promotion.MODS)
var _twist := false                # the mods are today's stage twist, not a trial's
var _bug_speed := 1.0             # Swift bugs
var _spit_mult := 1.0             # Double spit
var waves: Array = []
var wave_index := 0
var wave_queue: Array = []        # enemy ids still to spawn this wave
var wave_spawn_t := 0.0
var stage_cleared := false
var soldier_pos := Vector2(240, 620)
var dragging := false
var drag_id := -1
var last_touch := Vector2.ZERO
var pilot_hp := 100.0
var _def := 0.0                     # the hero's DEF: damage to the pilot x (1 - _def)
const GOO_DMG := 25.0               # a Spitter glob on the pilot (about four hits of base HP)
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
var stage_unlocked := 1           # from the save: decides which base slots are open (Base.slot_open)
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
var _drone_mult := 1.0             # the DRONE BODY element vs this planet (DroneData.body_element): its own, not the hero (Rudy)
# hero cards (Cards "hero", dev172): each hero has one card of his own and its overcharge
var _hero_id := "rook"
var _twin_every := 0               # Rook: every Nth bolt fires a twin (4, 3, 2)
var _twin_bonus := false           # its overcharge: twins +15%
var _weld_count := 0               # Sparks: bolts arc to this many bugs ...
var _weld_every := 3               # ... every 3rd bolt (overcharge: every bolt)
var _freeze_level := 0             # Frost: hits slow 20% a level
var _shatter := false              # its overcharge: a slowed bug that dies blasts its neighbours
var _phase_bonus := false          # Hollow overcharge: +30% damage per bug passed
var _burn_level := 0               # Ember: hits set bugs burning (5% HP/s, longer per level)
var _burn_spread := false          # its overcharge: a burning bug that dies spreads the fire
var _fire_patches: Array = []      # burning patches a burning bug leaves when it dies (Afterburn overcharged, dev209)
# damage numbers (Rudy, dev172): per bug, batched over a quarter second; crits big and gold
var _dmg_acc := {}                 # enemy id -> {"v": damage so far, "t": when it started, "pos"}
const DMG_BATCH := 0.25
const DMG_SHOW := 10.0             # damage is tiny inside (a bolt ~1.0): shown x10 so a hit reads "10", a crit "CRIT 15"
var _move_mult := 1.0              # the hero's build (Heroes): small heroes slide faster under the finger, bulky ones slower
var _shards_got := {}              # hero shards won on this stage (the end screen)
var _mats_got := {}                # materials won on this stage (materials.gd; the end screen)
var _coins_f := 0.0
var _shield_regen := 1.0
var _pierce5 := false
var _pierce_every := 5
var _chill_bonus := 0.0            # Frost's passive on the higher steps: extra slow
var _shot_n := 0
var _stars_got := 0
var _level_before := 1
var _level_after := 1
var fxs: Array = []               # short effect sprites {tex, pos, size, rot, life, max, grow, col}
var _fx: Node2D                   # additive effect layer
var _hc: Node2D                   # top bar layer (_draw_hud draws on it)
var _fx_tex := {}
var stat_pilot_dmg := 0.0
var stat_turret_dmg := 0.0
var _dmg_by := {}                 # damage by source this run: "hero", "drone", each turret type (the pause + clear stats, dev199)
var _coin_refreshes := 0          # card refreshes bought with run coins after the free ones (dev199)
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
var _hp_lost := 0.0               # this stage (star objective 3: take no damage)
var _vacuum_t := 0.0              # > 0: every pickup flies to the pilot (wave end)
var _outro_t := -1.0              # >= 0: stage won, the closing flight is playing
var _outro_lift := -1.0           # when (in _outro_t) he lifted off
var _press := {}                 # finger down: {pos, t, moved} (long-press on a turret shows its range)
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
var _shield_dr := 0.0              # Shield Surge overcharged: hits on the shield this much weaker
var _radar_heal := false           # Radar Sweep overcharged: a caught runner mends the shield
var _wave_coins := false           # Rich Seam overcharged: a pile of coins after every wave
var _pulse_bonus := 0.0            # Core Overload overcharged: the Core Pulse stands this much longer
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
var _talents := 0                 # talent map nodes bought (Talents, dev197): gates the talent cards
var _salvage := false             # Salvage overcharged: every 10th kill drops a part
var _salvage_n := 0
var _second_wind := 0             # Second Wind card level: once a run, a killing blow heals instead (0 = used / none)
var _mirror := 0                  # Mirror Shell card level: a bolt that stops a shot throws it back
var _mirror_through := false      # its overcharge: the bolt flies on
var frost_level := 0              # Frost Rounds: hits slow bugs
var _frost_bonus := false         # its overcharge: slowed bugs take +20%
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
var auto_on := false               # AUTO: the autopilot flies and aims while no finger is down (save "auto_play")
var _firing_up := false            # manual: firing straight up this frame (finger down or not)
var _auto_btn: Button
var idle_aim_ang := -PI / 2.0
var aim_goal := -PI / 2.0
var aim_target_id := -2
var facing := 1.0
var facing_s := 1.0               # eases toward facing, so turning round squeezes instead of snapping
var anim := PilotSprite.Anim.new()
var _rig_view: PilotRigView        # the new cut-out pilot (PilotRig.ENABLED); null = painted PilotSprite

# ---- UI ----
var hud_font: Font = preload("res://fonts/inter_text.tres")   # Inter 600, the game's text font (the battle's style pass, 2026-11-10)
var title_font: Font = preload("res://fonts/oxanium_heavy.tres")   # Oxanium 800: titles, numbers, buttons
var _hud_title := ""               # the top bar strings, rebuilt only when they change (efficiency pass, 27)
var _hud_title_key := -2
var _hud_num := ""
var _hud_nx := 18.0
var _hud_clock := "00:00"
var _hud_clock_s := -1
var _pause_btn: Button
var _pause_panel: Control
var _card_panel: Control
var _end_panel: Control
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	Sfx.apply_from(_read_save())   # sound on/off (pause menu, Settings)
	Music.apply_from(_read_save())
	Music.play("battle")
	PilotSprite.load_style()
	_stars = Backdrop.make_stars(90, 11)
	_city = Backdrop.make_city(44, 7)
	for id in StageData.ENEMIES:
		if String(StageData.ENEMIES[id].tex) == "":
			continue   # drawn in code (spore pods)
		_tex[id + "_up"] = load("res://enemies/%s_up.png" % id)
		_tex[id + "_down"] = load("res://enemies/%s_down.png" % id)
	for n in ["body_scout", "body_striker", "body_warden", "pod_blaster", "pod_beam", "pod_missile", "body_spark", "body_wisp", "body_bat", "pod_repair", "pod_magnet"]:
		if not ResourceLoader.exists("res://drone/%s.png" % n):
			continue
		_tex[n] = load("res://drone/%s.png" % n)
	for b in ["scout", "striker", "warden", "spark", "wisp", "bat"]:   # Luna'"'"'s drone parts (dev160, round 2 dev184), when cut
		if ResourceLoader.exists("res://drone/%s_hull.png" % b):
			_tex["hull_" + b] = load("res://drone/%s_hull.png" % b)
			_tex["thruster_l_" + b] = load("res://drone/%s_thruster_l.png" % b)
			_tex["thruster_r_" + b] = load("res://drone/%s_thruster_r.png" % b)
			for extra in ["extra", "glow"]:
				if ResourceLoader.exists("res://drone/%s_%s.png" % [b, extra]):
					_tex["%s_%s" % [extra, b]] = load("res://drone/%s_%s.png" % [b, extra])
	for n in ["blaster", "beam", "missile"]:
		_fx_tex["drone_flash_" + n] = load("res://drone/flash_%s.png" % n)
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
		_rig_view.fight = true   # a hero with fight pieces flies from above, in moving parts (HeroFight)
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
	etrial = Promotion.take_etrial(d)
	horde = String(d.get("selected_mode", "normal")) == "horde"
	if horde:
		_write_save({"selected_mode": "normal"})
		stage = clampi(int(d.get("stage_unlocked", 1)) - 1, 1, StageData.MAX_STAGE)   # built from your best Standard stage
		elite = false
		_horde_best = int(d.get("best_horde", 0))
	run_mode = String(d.get("selected_mode", "normal")) == "run" and not Runs.active(d).is_empty()
	if run_mode:   # an Expedition fight (Runs): the map page chose the stop
		_write_save({"selected_mode": "normal"})
		_run = Runs.active(d)
		stage = Runs.stage_for(_run, _run_kind())
		elite = false
	event_run = String(d.get("selected_mode", "normal")) == "event"
	if event_run:
		_write_save({"selected_mode": "normal"})
		stage = Events.stage(d)
		elite = false
	boss_rush = String(d.get("selected_mode", "normal")) == "bossrush"
	if boss_rush:
		_write_save({"selected_mode": "normal"})
		stage = BossRush.stage(d)
		elite = false
	daily = String(d.get("selected_mode", "normal")) == "daily"
	if daily:
		_write_save({"selected_mode": "normal"})
		stage = Promotion.daily_stage(d)
		elite = false
	if not etrial.is_empty():
		stage = int(Promotion.ETRIAL_STAGES[int(etrial.step)])
	if promo >= 0:
		_write_save({"selected_mode": "normal"})
		stage = int(Promotion.RANKS[promo].stage)
		elite = false

func _read_save() -> Dictionary:
	if FileAccess.file_exists(SAVE):
		var f := FileAccess.open(SAVE, FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if typeof(d) == TYPE_DICTIONARY:
				return d
				DevTools.on = bool(d.get("dev_mode", false))
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
	waves = Promotion.waves(promo) if promo >= 0 else (Promotion.etrial_waves(int(etrial.step)) if not etrial.is_empty() else StageData.waves(stage))
	if boss_rush:
		waves = BossRush.waves(_read_save())
	if run_mode:
		waves = Runs.trim_waves(waves, _run_kind())
	if horde:
		waves = [_horde_wave(0)]
	wave_index = 0
	_wave_kind = ""
	stage_cleared = false
	_vacuum_t = 0.0
	_outro_t = -1.0
	_outro_lift = -1.0
	game_over = false
	pilot_hp = 100.0
	pilot_hp_max = 100.0
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
	_twin_every = 0
	_twin_bonus = false
	_weld_count = 0
	_weld_every = 3
	_freeze_level = 0
	_shatter = false
	_salvage = false
	_salvage_n = 0
	_second_wind = 0
	_mirror = 0
	_mirror_through = false
	_phase_bonus = false
	_burn_level = 0
	_burn_spread = false
	_dmg_acc = {}
	_variants_seen = {}
	_shield_rate = 0.0
	_shield_dr = 0.0
	_radar_heal = false
	_wave_coins = false
	_pulse_bonus = 0.0
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
	_overdrive = false
	_thunder = false
	_fire_patches.clear()
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
	bullets.clear(); enemy_bullets.clear(); enemies.clear(); gems.clear()
	spawned.clear()
	_seen = Array(_read_save().get("seen_enemies", []))
	_intro = {}
	sparks.clear(); rings.clear(); floaters.clear()
	fxs.clear()
	stat_pilot_dmg = 0.0
	stat_turret_dmg = 0.0
	_dmg_by = {}
	_coin_refreshes = 0
	_runner_due.clear()
	_strikes.clear()
	_crate_due = -1.0
	_supply_pending = false
	_supplies_taken = 0
	_strike_cd = 8.0
	_streak_break()
	_streak_best = 0
	_lanes.clear()
	_runners_caught = 0
	_ult_live = 0.0
	var sv := _read_save()
	stage_unlocked = int(sv.get("stage_unlocked", 1))
	_speed_pack = bool(sv.get("speed_pack", false))
	# the pilot's gear: every slot boosts a battle stat, sets add bonuses (gear_data.gd)
	var gs := Heroes.stats(sv)   # the hero and his weapon (heroes, dev172)
	PilotRig.set_gear(sv)   # he holds the equipped weapon; visor and orb in the gear colours
	HeroFight.apply_from(sv)   # Settings: the new hero motion (on unless switched off)
	HeroFight.warm(PilotRig.hero)
	_elem_mult = Heroes.element_mult(String(gs.element), stage)   # his element against this planet's family
	_hero_id = String(gs.get("hero", "rook"))
	_drone_mult = Heroes.element_mult(DroneData.body_element(String(DroneData.read(sv).body)), stage)
	# the trial twists (Promotion.MODS): advantages and disadvantages of this fight
	_mods = Promotion.mods_for(promo, etrial)
	if daily:
		_mods = Promotion.daily_mods()
	if event_run:
		_mods = Array(Events.theme().mods)
	_twist = false
	if _mods.is_empty() and not elite and not horde and not _is_trial():
		_mods = Promotion.stage_twist(stage)   # today's pair on a Standard stage (planet 2 on)
		_twist = not _mods.is_empty()
	for m in _mods:
		_tex["tw_" + String(m)] = Promotion.mod_icon(m)   # the twist icons for the HUD banner, loaded once
	_bug_speed = 1.25 if _mods.has("swift_bugs") else 1.0
	_spit_mult = 0.5 if _mods.has("double_spit") else 1.0
	if _mods.has("rapid"):
		fire_rate_mult *= 1.25
	if _mods.has("sharpshooter"):
		_crit_rate += 0.2
	if _mods.has("fortified"):
		shield_max *= 1.5
		shield = shield_max
	if _mods.has("weak_shield"):
		shield_max *= 0.5
		shield = shield_max
	if _mods.has("reinforced"):
		pilot_hp_max *= 1.5
		pilot_hp = pilot_hp_max
	if _mods.has("overcharge"):
		_gem_xp_mult *= 1.5
	_bolt_set = String(gs.element)   # bolts in the hero's element colour
	for bk in ["bolt", "bolt_rail", "bolt_spark", "bolt_heavy", "bolt_twin"]:
		if _fx_tex.has(bk):
			PilotRig.tinted(_fx_tex[bk], _bolt_set)   # made now, not in the middle of a draw
	damage_mult = gs.damage
	fire_rate_mult = gs.fire_rate
	aim_error = 0.05 / gs.aim
	aim_turn_speed = 10.0 * gs.aim
	pilot_hp_max = float(gs.get("hp", 100.0))
	_def = clampf(float(gs.get("def", 0.0)), 0.0, 0.6)
	pilot_hp = pilot_hp_max
	_recovery = gs.recovery
	_magnet_base = MAGNET_BASE + float(gs.magnet)
	magnet_radius = _magnet_base
	idle_power = gs.auto_fire
	_gem_xp_mult = gs.gem_xp * (Promotion.GEM_XP_MULT if _is_trial() else 1.0)   # trials: cards come faster
	_coin_mult = gs.coins
	if _twist:
		_coin_mult *= Promotion.TWIST_COINS   # a twisted stage pays more
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
	_pierce_every = int(gs.get("pierce_every", 5))   # Hollow's piercing bolt comes sooner on the higher steps (ASCEND)
	_ult_cd = float(gs.get("ability_cd", 40.0))   # shorter on the higher rarity steps
	if _mods.has("turret_boost"):   # the old Turret boost twist is Quick charge now: the ability comes back half again as fast
		_ult_cd /= 1.5
	_apply_base(sv)   # the buildings on the base (Base): shield, hull, repair, hero, ability, drone, warnings, coins
	_apply_research(sv)   # the Research Lab (Research)
	_ult_t = 0.0 if _base_perks.has("reactor") else 12.0   # Reactor Lv.5: the ability is ready from the start
	_pulse_setup()   # the Core Pulse, the base s own button
	_wing_id = String(gs.get("wing", ""))   # the wingmate (Heroes.wing)
	_ult_ups = int(gs.get("ability_ups", 0))   # ability upgrades bought (Heroes.ABILITY_UPS)
	_wing_ups = int(gs.get("wing_ups", 0))
	_live_ups = 0
	_wing_t = 25.0
	_ult_kind = ""
	# hero level perks (Heroes.MILESTONES, dev186): a twin every 6th shot, one bug pierced, bursts of 2
	_perk_twin = float(gs.get("twin_shot", 0.0)) > 0.0
	if float(gs.get("pierce1", 0.0)) > 0.0:
		pierce_level += 1
	if float(gs.get("burst2", 0.0)) > 0.0:
		burst_count = maxi(burst_count, 2)
	_pilot_xp_mult = gs.pilot_xp
	_move_mult = float(gs.get("speed", 1.0))
	if _rig_view:
		_rig_view.height = PILOT_HEIGHT * float(gs.get("scale", 1.0))   # bulky or small (his build)
	if gs.chill:
		frost_level = maxi(frost_level, 1)
	_chill_bonus = float(gs.get("chill_bonus", 0.0))
	# ASCEND, Epic and up: the hero flies in with his own card already at level 1
	if bool(gs.get("start_card", false)):
		_start_hero_card()
	_shot_n = 0
	weapon_id = gs.weapon
	weapon_form = int(gs.get("weapon_form", 1))
	PilotSprite.style = gs.thruster
	game_speed = float(sv.get("game_speed", 1.0))
	auto_on = bool(sv.get("auto_play", false)) and _auto_open()
	_lefty = bool(sv.get("left_hand", false))   # Settings: left-handed
	_haptics = bool(sv.get("haptics", true))            # Settings: the phone buzzes on hits
	_shake_mult = float(sv.get("shake", 1.0))            # Settings: screen shake full / less / off
	_dmg_numbers = bool(sv.get("dmg_numbers", true))     # Settings: damage numbers over bugs
	_auto_next = bool(sv.get("auto_next", false))        # Settings: go on to the next stage by itself
	if not _speeds().has(game_speed):
		game_speed = 1.0
	var plevel := Turrets.pilot_level(int(sv.get("pilot_xp", 0)))
	_talents = Talents.count(sv)
	# the drone sidekick flies along once the pilot is level 8 (Gear > Drone)
	_drone = DroneData.read(sv)
	if not DroneData.body_open(_drone, String(_drone.body), plevel):
		_drone.body = "scout"
	if plevel < int(DroneData.PODS[_drone.pod].unlock) and not DevTools.on:
		_drone.pod = "blaster"
	_drone_on = DroneData.unlocked(plevel)
	_setup_support(sv)   # the second, support drone (needs a Hangar on the base)
	_drone_cd = 0.5
	_drone_beam = {}
	_took_damage = false
	_hp_lost = 0.0
	_parts_got = {}
	_stars_got = 0
	_poison_t = 0.0
	_gems_got = 0
	_kills_by = {}
	if stage == 1 and not _is_trial() and not _seen.has("tip_move"):   # the first fight ever: say how to play, once
		_seen.append("tip_move")
		_write_save({"seen_enemies": _seen})
		_move_tip = 7.0
	if run_mode:
		_run_begin()
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
	if _aegis_heal and wave_index > 0 and pilot_hp < pilot_hp_max:
		pilot_hp = minf(pilot_hp + 25.0, pilot_hp_max)   # Aegis overcharged: a heal between waves
		_float_text(soldier_pos + Vector2(0, -40), "+25 HP", Color(1.0, 0.5, 0.6))
	if wave_index > 0:
		_wave_patch()   # every cleared wave mends the shield a little
	_plan_runners()
	_plan_supply()
	# SPECIAL WAVES (WAVE_KINDS): now and then a wave comes with a twist of its own
	var prev_kind := _wave_kind
	_wave_kind = _wave_kind_for(wave_index)
	var wk: Dictionary = WAVE_KINDS.get(_wave_kind, {})
	_wave_hp = float(wk.get("hp", 1.0))
	_wave_speed = float(wk.get("speed", 1.0))
	if prev_kind == "gold":   # the Gold Rush wave just cleared: its pile of coins
		for i in 8:
			gems.append({"pos": Vector2(FIELD_W * 0.5 + rng.randf_range(-90, 90), 200.0 + rng.randf_range(-20, 20)), "tier": 0, "coin": true, "life": 16.0,
				"value": (12.0 + 1.0 * stage) / 8.0, "vel": Vector2(rng.randf_range(-80, 80), rng.randf_range(-40, 60))})
	for entry in waves[wave_index]:
		var many: int = int(entry[1]) if _is_boss_id(String(entry[0])) else maxi(1, roundi(int(entry[1]) * float(wk.get("count", 1.0))))
		for i in many:
			wave_queue.append(entry[0])
	wave_queue.shuffle()
	# the boss always comes last
	for bid in ["hive_mother", "queen", "wrecker", "caldera", "smelter"]:
		if not wave_queue.has(bid):
			continue
		wave_queue.erase(bid)
		# from planet 2 (stage 11) the boss comes in with the wave still arriving (a third of the way
		# through from planet 3, halfway on planet 2), so the wall has company (16 g)
		if stage >= 21:
			wave_queue.insert(wave_queue.size() / 3, bid)
		elif stage >= 11:
			wave_queue.insert(wave_queue.size() / 2, bid)
		else:
			wave_queue.append(bid)
	wave_spawn_t = 0.6
	_float_text(Vector2(FIELD_W * 0.5, 160), "WAVE %d" % (wave_index + 1), Color(0.75, 0.97, 1.0), true)
	if not wk.is_empty():
		_float_text(Vector2(FIELD_W * 0.5, 190), "%s  ·  %s" % [String(wk.name), String(wk.text)], wk.col, true)
		Sfx.play("boss", 1.3)

func _spawn(id: String) -> void:
	var e := _make_enemy(id, Vector2(rng.randf_range(40.0, FIELD_W - 40.0), 60.0))
	if _is_boss_id(id):
		e.pos = Vector2(FIELD_W * 0.5, 40.0)
		# bosses last much longer (Rudy, dev209: a strong kit went straight through the Hive Mother):
		# BOSS_HP on every boss, more layers on the bar (_boss_layers)
		e.hp *= BOSS_HP
		e.hp_max *= BOSS_HP
		# a younger, smaller Hive Mother: the zone-A mini-boss, or one arriving mid-stage
		if StageData.boss_kind(stage) == "mini" or wave_index < waves.size() - 1:
			e.mini = true
			e.hp *= MINI_HP
			e.hp_max *= MINI_HP
		elif stage >= 10 and not horde:
			# the planet boss is a soft wall (Rudy, 16 g): half again as tough from stage 10, and she
			# fights with the last wave still arriving (dev198 sweep: nothing threatened the base)
			e.hp *= BOSS_WALL
			e.hp_max *= BOSS_WALL
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

# The first time ever a variant shows up: the same small info card as a new enemy (Rudy, dev209:
# what it does, no "kill it first"; players work out the strategy). Waits if a card is up.
func _meet_variant(v: String, bug: String) -> void:
	var key := "v_" + v
	if _seen.has(key) or not _intro.is_empty():
		return
	_seen.append(key)
	_write_save({"seen_enemies": _seen})
	_intro = {"id": bug, "t": 0.0, "variant": v}

func _make_enemy(id: String, pos: Vector2) -> Dictionary:
	var def: Dictionary = StageData.ENEMIES[id]
	var e := {"id": next_enemy_id, "type": id, "pos": pos,
		"hp": float(def.hp) * _hp_mult() * (1.0 if StageData.is_boss(id) else _wave_hp), "hp_max": float(def.hp) * _hp_mult() * (1.0 if StageData.is_boss(id) else _wave_hp),
		"speed": float(def.speed) * StageData.speed_mult(stage) * _bug_speed * _wave_speed, "r": float(def.size) * 0.4, "ph": rng.randf() * TAU,
		"state": "fly", "t": 0.0, "vel": Vector2.ZERO, "fire_t": rng.randf_range(1.0, 2.5), "lay_t": 3.0, "laying": 0.0,
		"dart_t": rng.randf_range(0.3, 1.0), "dart_vx": 0.0, "dodge_v": 0.0, "dodge_cd": 0.0, "feinted": false}
	next_enemy_id += 1
	_roll_variant(e)   # armoured / shielded / booster / healer, by stage (VARIANTS)
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
	var sk := shake * shake * 5.0 * _shake_mult
	position = Vector2(0, _safe_top) + Vector2(sin(time_alive * 93.0), cos(time_alive * 71.0)) * sk
	time_alive += delta
	hit_t += delta
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
		if auto_on and not dragging:
			_auto_pilot(delta)
		_aim_and_fire(delta)
	_update_drone(delta)
	for z in zaps:
		z.life -= delta
	zaps = zaps.filter(func(z): return z.life > 0.0)
	_spawn_step(delta)
	_update_runners(delta)
	_update_strikes(delta)
	_update_supply(delta)
	_update_support(delta)
	_update_streak(delta)
	_move_tip = maxf(_move_tip - delta, 0.0)
	_update_ability(delta)
	_update_pulse(delta)
	_update_wing(delta)
	_update_bullets(delta)
	_update_fire_patches(delta)
	_update_enemies(delta)
	_update_gems(delta)
	_update_shards(delta)
	_step_effects(delta)
	_pilot_motion(delta)
	anim.update(_wanted_pose(), delta)
	if pilot_hp <= 0.0 or hull <= 0.0:
		_end_run(false)
	elif wave_queue.is_empty() and enemies.is_empty() and _lanes.is_empty() and not stage_cleared and _outro_t < 0.0:
		wave_index += 1
		if horde or wave_index < waves.size():
			_vacuum_t = 1.4   # between waves what is left flies to him (gems feed the next cards)
		if horde:
			waves.append(_horde_wave(wave_index))   # endless: the next wave is built as it comes
			_coins_f += 20.0 + 4.0 * wave_index   # a bounty per wave cleared
			coins_earned = int(_coins_f)
			_start_wave()
		elif wave_index >= waves.size():
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
			if _is_boss_id(id):
				break

func _pilot_motion(delta: float) -> void:
	if dragging or idle_aiming or _firing_up:
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
		if dragging or _firing_up:
			rig_aim = -PI / 2.0 + gun_sway - draw_bank
		elif idle_aiming:
			rig_aim = idle_aim_ang
		var a: float = 1.0
		if inv_t > 0.0:
			a = lerpf(1.0, 0.55 + 0.45 * absf(cos(time_alive * PI * 4.0)), smoothstep(0.0, 0.3, inv_t))
		# his head turns to the nearest bug above him (HeroFight)
		var near_d := 420.0 * 420.0
		_rig_view.fstate.look = Vector2.INF
		for e in enemies:
			var ed: float = (e.pos as Vector2).distance_squared_to(soldier_pos)
			if ed < near_d and e.pos.y < soldier_pos.y - 20.0:
				near_d = ed
				_rig_view.fstate.look = e.pos
		_rig_view.update(delta, soldier_pos + Vector2(0, sin(time_alive * 4.0) * 2.5), rig_aim, draw_bank / 0.3,
			clampf(1.0 - vy_smooth / 260.0, 0.35, 1.9), vy_smooth, a)
		# Aegis: light hugging his outline (brighter with the 2nd Aegis, flares when he is hit)
		var lv_a := int(card_levels.get("aegis", 0))
		_rig_view.shield = 0.0 if lv_a <= 0 else minf(0.55 + 0.25 * lv_a + _aegis_flash + 0.6 * smoothstep(0.0, 0.3, inv_t), 1.6)
		_rig_view.shield_form = minf(_rig_view.shield_form + delta * 1.6, 1.0)

# ------------------------------------------------------------------ aiming and shooting

func _wanted_pose() -> String:
	return PilotSprite.pose_for(dragging or _firing_up, draw_bank, Vector2(cos(idle_aim_ang), sin(idle_aim_ang)), idle_aiming)

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
		# the weapon has weight: a slow, heavy weapon kicks harder than a rapid one
		_rig_view.fire(v * clampf(0.55 + float(_weapon().get("interval", 0.25)) * 1.8, 0.7, 2.2))

# Stage won (Rudy, dev108): the last pickups fly in, then he turns to the sky and blasts
# off the top of the screen, and only then does Stage Cleared show.
func _update_outro(delta: float) -> void:
	_outro_t += delta
	dragging = false
	if _outro_lift < 0.0:
		# no vacuum show at the end of a stage (Rudy, dev209: pointless, the cards reset anyway):
		# coins and parts still on screen are counted at once, gems vanish, and he lifts off
		var left_coins := 0.0
		for g in gems:
			if g.has("part"):
				_parts_got[g.part] = int(_parts_got.get(g.part, 0)) + 1
			elif g.get("coin", false):
				left_coins += float(g.get("value", 1.0)) * _coin_mult
		gems.clear()
		if left_coins > 0.0:
			_coins_f += left_coins
			coins_earned = int(_coins_f)
			_float_text(soldier_pos + Vector2(0, -44), "+%d" % int(left_coins), Color(1.0, 0.85, 0.35))
		_outro_lift = _outro_t
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

# MANUAL and AUTO (Rudy's queue 32, built 2026-11-10 after the sweep in REVIEW-2026-11-10.md: with
# the old rule, lifted finger = full auto-aim, a phone lying on the table won stages 1-30).
#   MANUAL (AUTO off): he fires straight up at full rate, finger down or not. A bolt bends to a bug
#     that is nearly above him (ASSIST), so lining up feels good on a thumb. Standing still no
#     longer aims for you: you fly under what you want dead.
#   AUTO on, finger up: the autopilot aims for him at AUTO_FIRE of the rate and dodges like a
#     person (_auto_pilot: a quarter second to react, about one dodge in three missed), so a hand on
#     the screen beats it. A finger down takes over at once; lifting it hands back.
const AUTO_FROM := 3      # AUTO unlocks once this stage is cleared (the first stages teach flying)
const AUTO_FIRE := 0.75
const ASSIST := 0.26      # radians either side of straight up (0.16 until the turrets went: alone, the manual bot lost stage 30 that AUTO won)

func _auto_open() -> bool:
	return stage_unlocked > AUTO_FROM or DevTools.on

# the bug a straight-up bolt should bend to: the one closest to his line of fire, inside ASSIST
func _assist_target(from: Vector2, up_ang: float, speed: float) -> Dictionary:
	var best := {}
	var best_off := ASSIST
	for e in enemies:
		if e.pos.y < 100.0 or e.pos.y > from.y - 20.0:
			continue
		var lead: Vector2 = e.pos + e.vel * (from.distance_to(e.pos) / speed) * aim_lead_accuracy
		var a: float = (lead - from).angle()
		var off: float = absf(angle_difference(up_ang, a))
		if off < best_off:
			best_off = off
			best = {"ang": a, "id": e.id}
	return best

func _aim_and_fire(delta: float) -> void:
	idle_aiming = false
	_firing_up = false
	var weapon: Dictionary = _weapon()
	var muzzle_base := _muzzle_world()
	var auto: bool = auto_on and not dragging
	var target := _pick_aim_target(muzzle_base) if auto else {}
	if not target.is_empty():
		var flight_t: float = muzzle_base.distance_to(target.pos) / float(weapon.speed)
		var lead_pos: Vector2 = target.pos + target.vel * flight_t * aim_lead_accuracy
		aim_goal = clampf((lead_pos - muzzle_base).angle(), -PI / 2.0 - 1.2, -PI / 2.0 + 1.2)
	if auto and not target.is_empty():
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
	if _ult_live > 0.0:
		interval *= 0.7 if _ult_kind == "phase" else 0.4   # Phase Storm / Volley (hero abilities)
	if _overdrive and fmod(time_alive, 8.0) < 3.0:
		interval *= 0.5   # Rapid Pulse overcharged: overdrive window
	if auto:
		if idle_aiming and fire_timer <= 0.0 and not target.get("doomed", false) and absf(angle_difference(idle_aim_ang, aim_goal)) <= aim_ready_angle:
			fire_timer = interval * idle_fire_ratio / (idle_power * AUTO_FIRE)
			_kick(1.0)
			var shot_ang := idle_aim_ang + rng.randf_range(-aim_error, aim_error)
			var d2 := Vector2(cos(shot_ang), sin(shot_ang))
			_fire(muzzle_base + d2 * 4.0, d2, int(target.get("id", -2)))
			burst_left = burst_count - 1
			burst_timer = 0.07
			burst_dir = d2
			burst_tid = int(target.get("id", -2))
		return
	# manual: straight up, ONLY while a finger is down (Rudy, dev265 playtest: lifting the finger stops the fire)
	_firing_up = dragging
	if _firing_up and fire_timer <= 0.0:
		fire_timer = interval
		_kick(1.0)
		var ang: float = -PI / 2.0 + gun_sway - draw_bank
		var tid := -2
		var help := _assist_target(muzzle_base, ang, float(weapon.speed))
		if not help.is_empty():
			ang = float(help.ang)
			tid = int(help.id)
		var dir := Vector2(cos(ang), sin(ang))
		_fire(muzzle_base + dir * 4.0, dir, tid)
		burst_left = burst_count - 1
		burst_timer = 0.07
		burst_dir = dir
		burst_tid = tid

# The autopilot's hands (AUTO on, no finger down). It decides four times a second, misses about one
# decision in three, slides out of the way of shots and diving bugs, and when nothing is near it
# drifts to pickups. Never as sharp as a player: that is the point.
const AI_SPEED := 420.0
var _ai_t := 0.0
var _ai_x := -1.0          # where it is sliding to (-1 = staying put)
var _ai_gem := false
var _ai_hunt := false          # the autopilot is flying under a bug (unhurried)
const AI_HUNT_SPEED := 170.0

func _ai_threat(p0: Vector2, target_x: float) -> float:
	var worst := 9999.0
	for k in 15:
		var t := 0.05 * k
		var p := Vector2(move_toward(p0.x, target_x, AI_SPEED * t), p0.y)
		for s in _strikes:   # a planet hazard about to land: inside its circle is not safe
			if float(s.t) < 1.3:
				worst = minf(worst, p.distance_to(s.pos) - STRIKE_R + 24.0)
		for eb in enemy_bullets:
			worst = minf(worst, (eb.pos + eb.vel * t).distance_to(p))
		for e in enemies:
			if e.type == "diver" and e.state != "fly":
				worst = minf(worst, (e.pos + e.vel * t).distance_to(p) - 8.0)
			elif not _is_boss(e):
				worst = minf(worst, (e.pos + e.vel * t).distance_to(p) - 6.0)
	return worst

func _auto_pilot(delta: float) -> void:
	_ai_t -= delta
	if _ai_t <= 0.0:
		_ai_t = 0.25
		if rng.randf() > 0.3:   # (a missed beat keeps doing what it was doing)
			var p := soldier_pos
			var here := _ai_threat(p, p.x)
			_ai_x = -1.0
			_ai_gem = false
			_ai_hunt = false
			if here < 24.0:
				var best_d := here
				for i in range(-10, 11):
					var tx := clampf(p.x + i * 18.0, 30.0, FIELD_W - 30.0)
					var d := _ai_threat(p, tx) - absf(tx - p.x) * 0.02 - absf(tx - FIELD_W * 0.5) * 0.01
					if d > best_d:
						best_d = d
						_ai_x = tx
			elif here > 90.0:
				var bd := 170.0
				for g in gems:
					var dg: float = g.pos.distance_to(p)
					if dg < bd and g.pos.y < BASE_Y - 90.0:
						bd = dg
						_ai_x = g.pos.x
						_ai_gem = true
			# nothing to dodge, no gem in reach: he HUNTS (Rudy, dev265: "he doesn't really move across the screen").
			# He flies under the lowest bug, the one nearest the base, if the way there is safe.
			if _ai_x < 0.0 and here > 60.0:
				var low_y := -1.0
				var low_x := -1.0
				for e in enemies:
					if e.pos.y > low_y and e.pos.y > 30.0 and e.pos.y < BASE_Y - 60.0 and String(e.type) != "crate":
						low_y = e.pos.y
						low_x = e.pos.x
				if low_x >= 0.0 and absf(low_x - p.x) > 36.0:
					var hx := clampf(low_x, 30.0, FIELD_W - 30.0)
					if _ai_threat(p, hx) > 50.0:
						_ai_x = hx
						_ai_hunt = true
	if _ai_x >= 0.0:
		var step := (AI_HUNT_SPEED if _ai_hunt else (AI_SPEED if not _ai_gem else 220.0)) * delta
		_drag_by(Vector2(clampf(_ai_x - soldier_pos.x, -step, step), 0.0))
		if absf(_ai_x - soldier_pos.x) < 2.0:
			_ai_x = -1.0

func _toggle_auto() -> void:
	if not _auto_open():
		_float_text(Vector2(FIELD_W - 130, _auto_rect().position.y - 14.0), "AUTO unlocks after stage %d" % AUTO_FROM, Color(0.75, 0.82, 0.92))
		return
	auto_on = not auto_on
	_ai_x = -1.0
	Sfx.play("tap")
	_write_save({"auto_play": auto_on})
	_float_text(Vector2(FIELD_W - 90, _auto_rect().position.y - 14.0), "AUTO ON" if auto_on else "MANUAL", Color(0.31, 0.88, 1.0) if auto_on else Color(1.0, 0.85, 0.4))
	queue_redraw()

# bottom right, above the base (Rudy): a thumb reaches it without covering the fight
func _auto_rect() -> Rect2:
	return Rect2(12.0 if _lefty else FIELD_W - 62.0, BASE_Y - 196.0, 50.0, 50.0)   # left-handed: the two buttons swap sides

func _draw_auto_btn() -> void:
	var r := _auto_rect()
	if _auto_btn:
		_auto_btn.position = r.position - Vector2(4, 4)
	var open := _auto_open()
	var cy := Color(0.31, 0.88, 1.0)
	_hc.draw_style_box(UIKit.pill(Color(0.055, 0.09, 0.157, 0.86) if not auto_on else Color(0.07, 0.2, 0.3, 0.92), 16, Vector2.ZERO), r)
	var c := r.get_center()
	if auto_on:
		# a ring that turns while the autopilot has him
		var a0 := time_alive * 2.2
		_hc.draw_arc(c, 21.0, a0, a0 + PI * 1.3, 24, Color(cy, 0.9 if not dragging else 0.3), 2.0, true)
	else:
		_hc.draw_arc(c, 21.0, 0.0, TAU, 32, Color(1, 1, 1, 0.14 if open else 0.07), 1.5, true)
	_hc.draw_string(title_font, Vector2(r.position.x, c.y + 4.5), "AUTO", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 11, cy if auto_on else Color(1, 1, 1, 0.75 if open else 0.3))

func _fire(origin: Vector2, dir: Vector2, target_id: int = -2, pierce: bool = false) -> void:
	var w: Dictionary = _weapon()
	Sfx.play("shot", rng.randf_range(0.95, 1.05))
	var count: int = int(w.projectiles) + extra_projectiles
	var spread: float = float(w.spread) + 0.18 * extra_projectiles
	for i in count:
		var off := 0.0
		if count > 1:
			off = lerpf(-spread * 0.5, spread * 0.5, float(i) / float(count - 1))
		_shot_n += 1
		# Heavy Bolts overcharged: every 6th bolt is a big one that hits 3x
		var crit: bool = (_crit6 and _shot_n % 6 == 0) or (int(w.get("charge", 0)) > 0 and _shot_n % int(w.charge) == 0)   # the Pistol's charged shot
		var w_charged: bool = int(w.get("charge", 0)) > 0 and _shot_n % int(w.charge) == 0 and not (_crit6 and _shot_n % 6 == 0)   # the weapon's own charged bolt
		var lucky: bool = rng.randf() < _crit_rate   # a critical hit (crit rate / crit damage)
		# Railstorm fusion: every 4th bolt is a rail shot that pierces the whole line
		var rail: bool = _railstorm and _shot_n % 4 == 0
		var rail_gun: bool = w.get("rail", false)   # Nightmare railgun: every bolt pierces
		if (crit or rail) and i == 0 and _rig_view:
			_rig_view.fire(1.6)   # a charged or rail shot shoves him back harder
		bullets.append({"pos": origin, "vel": dir.rotated(off) * float(w.speed) * (1.4 if rail else 1.0),
			"dmg": float(w.damage) * damage_mult * (1.3 if _ult_live > 0.0 and _live_ups >= 2 else 1.0) * ((float(w.get("charge_mult", 3.0)) if w_charged else 3.0) if crit else 1.0) * (2.0 if rail else 1.0) * (_crit_dmg if lucky else 1.0),
			"r": float(w.hit_radius), "tid": target_id, "col": "cyan", "big": w.get("big", false) or crit or rail or lucky,
			"pierce": pierce or rail or rail_gun or (w_charged and bool(w.get("charge_pierce", false))) or (_ult_live > 0.0 and (_ult_kind == "phase" or _live_ups >= 3)) or (_pierce5 and _shot_n % maxi(_pierce_every, 2) == 0), "hits": [],
			"spark": chain_level if chain_level > 0 and _shot_n % 5 == 0 else (1 if int(w.get("spark_every", 0)) > 0 and _shot_n % int(w.spark_every) == 0 else 0), "pierce_left": pierce_level,
			"frost": frost_level > 0 or bool(w.get("frost", false)), "rail": rail or rail_gun, "lucky": lucky,
			"splash_share": float(w.get("splash_share", 0.6)), "fslow": float(w.get("frost_slow", 0.0)),
			"freeze": int(w.get("freeze_every", 0)) > 0 and _shot_n % int(w.freeze_every) == 0,
			"splash": float(w.get("splash", 0.0)), "ttl": (float(w.range) / float(w.speed)) if w.has("range") else 99.0,
			"weld": _weld_count if _weld_count > 0 and _shot_n % _weld_every == 0 else 0})
		# Twin Trigger (Rook card): every Nth bolt brings a twin beside it
		if (_twin_every > 0 and _shot_n % _twin_every == 0) or (_perk_twin and _shot_n % 6 == 0):
			var tw: Dictionary = bullets[-1].duplicate(true)
			tw.vel = Vector2(tw.vel).rotated(0.09)
			tw.pos = Vector2(tw.pos) + Vector2(10.0, 0.0)
			tw.dmg = float(tw.dmg) * (1.15 if _twin_bonus else 1.0)
			bullets.append(tw)
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
		if b.has("ttl"):   # a short-range bolt (the Sun Rifle's fan) fades out
			b.ttl = float(b.ttl) - delta
			if float(b.ttl) <= 0.0:
				continue
				continue
		for e in enemies:
			if b.has("hits") and Array(b.hits).has(e.id):
				continue   # a piercing bolt hits each bug once
			if not _can_hurt(e):
				continue   # a boss still arriving: bolts pass through her
			if b.pos.distance_to(e.pos) < float(b.r) + float(e.r) * 0.5:
				var dmg: float = float(b.dmg)
				if _boss_weak(e):
					dmg *= WEAK_MULT   # her weak point is open (_boss_weak): a reticle shows it
				var emult: float = _drone_mult if b.get("drone", false) else _elem_mult   # the drone has its own element
				dmg *= emult
				if _frost_bonus and float(e.get("slow_t", 0.0)) > 0.0:
					dmg *= 1.2
				if b.get("frost", false):
					e.slow_t = 1.5
					e.slow = minf(maxf(0.15 * maxi(frost_level, 1), float(b.get("fslow", 0.0))) + _chill_bonus, 0.5)
					if b.get("freeze", false) and not _is_boss(e):   # the Frost Rifle's third shape: Ice lock
						e.freeze_t = maxf(float(e.get("freeze_t", 0.0)), 0.9)
				# hero cards: Deep Freeze slows, Afterburn sets burning
				if _freeze_level > 0:
					e.slow_t = maxf(float(e.get("slow_t", 0.0)), 1.5)
					e.slow = maxf(float(e.get("slow", 0.0)), minf(0.2 * _freeze_level, 0.6))
					# at full strength a hit can freeze a bug solid for a moment (dev209: ice must SHOW)
					if float(e.slow) >= 0.6 and not _is_boss(e) and rng.randf() < 0.25:
						e.freeze_t = 0.9
				if _burn_level > 0 and e.type != "spore":
					e.burn_t = 1.5 + 0.75 * _burn_level
					e.burn_dps = 0.05 * float(e.hp_max)
				if float(e.get("mark_t", 0.0)) > 0.0 and not b.get("lucky", false):   # a Dread Beacon's mark: every bolt crits (dev196)
					dmg *= _crit_dmg
					b.lucky = true
				stat_pilot_dmg += minf(dmg, maxf(e.hp, 0.0))
				_count_dmg("drone" if b.get("drone", false) else "hero", dmg, e)
				_show_dmg(e, dmg, bool(b.get("lucky", false)), emult)
				_fx_add("impact", b.pos, 26.0, 0.22, rng.randf() * TAU, 1.6, Color(0.7, 0.92, 1.0) if b.get("frost", false) else Color.WHITE)
				dmg = _through_shield(e, dmg)   # a shielded variant's bubble first
				e.hp -= dmg
				e.hit_t = HIT_FLINCH_T
				Sfx.play("boss_hit" if _is_boss(e) else "hit", rng.randf_range(0.92, 1.08))
				if float(b.get("splash", 0.0)) > 0.0:
					for o in enemies:
						if o != e and o.pos.distance_to(b.pos) < float(b.splash):
							o.hp -= (dmg * float(b.get("splash_share", 0.6))) if _can_hurt(o) else 0.0
					_fx_add("nova", b.pos, float(b.splash) * 0.6, 0.3, 0.0, 1.8, Color(0.8, 0.5, 1.0))
				if int(b.get("weld", 0)) > 0:   # Arc Weld (Sparks card)
					_chain(e, int(b.weld), dmg * 0.6)
				if int(b.get("spark", 0)) > 0:
					_chain(e, int(b.spark), dmg * 0.5 * _chain_mult)
				# Void set bonus: every 5th bolt flies on through
				hit = not b.get("pierce", false)
				# Piercing Rounds: passes through this bug if it still has passes left
				if hit and int(b.get("pierce_left", 0)) > 0:
					b.pierce_left = int(b.pierce_left) - 1
					hit = false
					if _phase_bonus:   # Phase Bolts overcharged (Hollow)
						b.dmg = float(b.dmg) * 1.3
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
			if not b.get("boss", false) and pb.pos.distance_to(b.pos) < 14.0:   # a boss's shots cannot be shot down: move
				shot_down = true
				# Mirror Shell (talent card): the shot is thrown back up the way it came, as a bolt of
				# ours; overcharged, our bolt flies on instead of being spent
				if _mirror > 0 and not pb.has("src") and not pb.get("mirrored", false):
					var back: Vector2 = -Vector2(b.vel).normalized() * 420.0
					bullets.append({"pos": b.pos, "vel": back, "dmg": float(pb.dmg) * [0.5, 0.75, 1.0][clampi(_mirror - 1, 0, 2)], "r": 10.0, "tid": -1,
						"col": "cyan", "big": false, "pierce": false, "hits": [], "mirrored": true})
					_fx_add("spark", b.pos, 30.0, 0.25, 0.0, 1.6, Color(0.7, 0.95, 1.0))
				if not _mirror_through:
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
		if String(b.get("kind", "")) == "poison" and b.pos.distance_to(soldier_pos) < 18.0:
			# the Hive Mother's poison: a lighter hit, then it eats at him for a few seconds
			if inv_t <= 0.0 and not (_ult_live > 0.0 and _ult_kind == "phase" and _live_ups >= 3):
				stat_hit_bullet += 1
				_poison_t = POISON_T
				_float_text(soldier_pos + Vector2(0, -52), "POISONED", Color(0.55, 1.0, 0.4), true)
			_hurt_pilot(GOO_DMG * 0.5)
			_burst(b.pos, 14.0, Color(0.5, 1.0, 0.35), 10)
			continue
		if b.pos.distance_to(soldier_pos) < 14.0:
			if inv_t <= 0.0:
				stat_hit_bullet += 1
			_hurt_pilot(GOO_DMG)
			continue
		if b.pos.y < FIELD_H + 20.0:
			live_eb.append(b)
	enemy_bullets = live_eb

func _update_enemies(delta: float) -> void:
	_update_poison(delta)
	var live: Array = []
	var centre := Vector2(FIELD_W / 2, BASE_Y)
	_update_auras(delta)   # support variants (boosters, healers)
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
		match ("runner" if e.has("runner") else String(def.move)):
			"crate":
				# a supply drop: drifts down, hangs and sways, then lifts away if nobody opens it
				if e.t > SUPPLY_STAY:
					e.pos.y -= 160.0 * delta
					if e.pos.y < -30.0:
						e.gone = true
				elif e.pos.y < FIELD_H * 0.3:
					e.pos.y += 70.0 * delta
				else:
					e.pos.x += sin(e.t * 1.2 + e.ph) * 22.0 * delta
			"runner":
				e.pos.y += e.speed * delta   # straight down its lane for the base
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
				if float(e.get("freeze_t", 0.0)) <= 0.0:   # frozen bugs hold their fire
					e.fire_t -= delta
				if e.fire_t <= 0.0 and e.pos.y > 40.0:
					e.fire_t = float(def.fire_every) * _spit_mult
					e.shots = int(e.get("shots", 0)) + 1
					# every other shot goes for the base instead of the pilot
					var aim_at: Vector2 = soldier_pos if e.shots % 3 != 0 else Vector2(e.pos.x + rng.randf_range(-60, 60), BASE_Y - 40.0)
					# a goo glob leaves the mouth of the sac on the art; a Rivet Gun fires a faster rivet
					var mouth := _muzzle_of(e, float(def.size) * 1.35, float(e.get("tilt_s", 0.0)))
					var shot: String = String(def.get("shot", "goo"))
					var shot_v: float = 200.0 if shot == "rivet" else (150.0 if shot == "lava" else 135.0)
					var dir: Vector2 = (aim_at - mouth).normalized()
					enemy_bullets.append({"pos": mouth + dir * 4.0, "vel": dir * shot_v, "kind": shot, "ph": rng.randf() * TAU})
					# from stage 25 a Spitter sometimes spits two globs in a small V
					if stage >= 25 and rng.randf() < 0.3:
						var d2 := dir.rotated(0.22 if rng.randf() < 0.5 else -0.22)
						enemy_bullets.append({"pos": mouth + d2 * 4.0, "vel": d2 * shot_v, "kind": shot, "ph": rng.randf() * TAU})
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
			"wrecker":
				# the Wrecker (Scrap Belt mini-boss): drops to hover height, slides over a turret
				# and lowers its claw arm onto it: the turret is HELD (it cannot fire) until the
				# Wrecker has taken a quarter of its health since the grab, then it lets go, lifts
				# and goes for another one a few seconds later. With no turret it hangs over the base.
				var hover_y := 150.0
				if not e.get("arrived", false):
					e.pos.y += e.speed * delta
					if e.pos.y >= hover_y:
						e.arrived = true
						Sfx.play("boss")
						e.state = "seek"
						e.grab_cd = 1.5
				else:
					var held: Dictionary = {}
					for t in _pods:
						if int(t.get("held_by", -1)) == int(e.id):
							held = t
					match String(e.state):
						"seek":
							e.grab_cd = float(e.get("grab_cd", 0.0)) - delta
							var target: Dictionary = {}
							var bd := 1e9
							for t in _pods:
								if t.drop >= 1.0 and not t.get("held_by", -1) >= 0 and absf(t.pos.x - e.pos.x) < bd:
									bd = absf(t.pos.x - e.pos.x)
									target = t
							var want_x: float = float(target.pos.x) if not target.is_empty() else FIELD_W * 0.5 + sin(e.t * 0.5) * FIELD_W * 0.25
							e.pos.x = lerpf(e.pos.x, want_x, delta * 1.2)
							e.pos.y = lerpf(e.pos.y, hover_y, delta * 2.0)
							e.ext = move_toward(float(e.get("ext", 0.0)), 0.0, delta * 2.0)
							if not target.is_empty() and e.grab_cd <= 0.0 and absf(e.pos.x - float(target.pos.x)) < 12.0:
								e.state = "drop"
								e.target_mount = int(target.mount)
						"drop":
							var ty: float = BASE_Y - 178.0
							e.pos.y = move_toward(e.pos.y, ty, delta * 130.0)
							e.ext = move_toward(float(e.get("ext", 0.0)), 1.0, delta * 1.6)
							if e.pos.y >= ty - 1.0 and float(e.ext) >= 1.0:
								for t in _pods:
									if int(t.mount) == int(e.target_mount):
										t.held_by = int(e.id)
								e.state = "hold"
								e.grab_hp = e.hp
								shake = maxf(shake, 0.4)
								Sfx.play("hull")
								_float_text(e.pos + Vector2(0, -70), "POD GRABBED!", Color(1.0, 0.5, 0.4), true)
						"hold":
							if not held.is_empty():   # it tears at the pod: the shield drains until it is shot off
								shield = maxf(shield - shield_max * 0.02 * delta, 0.0)
							e.pos.x += sin(e.t * 2.0) * 6.0 * delta
							e.hold_t = float(e.get("hold_t", 0.0)) + delta
							# shot off (a quarter of its health since the grab) or it tires after HOLD_MAX s
							# (Elite 15 fell to this: an Elite Wrecker took too long to shoot off)
							if e.hp < float(e.get("grab_hp", e.hp)) - e.hp_max * 0.25 or float(e.hold_t) >= WRECKER_HOLD_MAX:
								if not held.is_empty():
									held.held_by = -1
								e.state = "lift"
								e.hold_t = 0.0
								e.grab_cd = float(def.grab_every)
								_burst(e.pos + Vector2(0, 60), 24.0, Color(0.3, 0.9, 1.0), 14)
								_float_text(e.pos + Vector2(0, -70), "LET GO!", Color(0.4, 1.0, 0.6), true)
						"lift":
							e.ext = move_toward(float(e.get("ext", 0.0)), 0.0, delta * 2.5)
							e.pos.y = move_toward(e.pos.y, hover_y, delta * 110.0)
							if e.pos.y <= hover_y + 1.0:
								e.state = "seek"
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
						var d := _make_enemy(String(def.get("launches", "diver")), e.pos + Vector2(rng.randf_range(-30.0, 30.0), -10.0))   # the Queen launches Darts
						d.lock_y = (e.pos.y + 60.0) / FIELD_H
						live.append(d)
						_burst(e.pos, 16.0, Color(1.0, 0.75, 0.3), 6)
				if e.type == "hive_mother" and e.get("arrived", false):   # she shoots as well as hatches (Rudy, dev265)
					_boss_attack(e, delta)
				if e.laying > 0.0:
					e.laying -= delta
				else:
					e.lay_t -= delta
					if e.lay_t <= 0.0 and e.pos.y >= 160.0:
						e.lay_t = float(def.lay_every) * (0.66 if e.hp < e.hp_max * 0.5 else 1.0)
						e.laying = 3.0
						e.hatched = false
				if e.laying > 0.0 and e.laying < 2.2 and not e.get("hatched", false):
					# the sac bursts: scouts crawl out of it, unfold, then fly; the Salvage Queen's
					# hold opens and Mites fly out of it instead
					e.hatched = true
					var brood: String = String(def.get("spawns", "scout"))
					for k in (4 if e.hp < e.hp_max * 0.5 else 3):
						if brood == "scout":
							var s := {"id": next_enemy_id, "type": "scout", "pos": e.pos + Vector2(float(k - 1) * 36.0, -54.0),
								"hp": 2.0 * _hp_mult(), "hp_max": 2.0 * _hp_mult(),
								"speed": 62.0 * StageData.speed_mult(stage), "r": 13.6, "ph": rng.randf() * TAU,
								"state": "hatch", "t": 0.0, "vel": Vector2(float(k - 1) * 45.0, -70.0), "fire_t": 9.0, "lay_t": 0.0, "laying": 0.0,
								"hatchling": true, "fold": 1.0}
							next_enemy_id += 1
							live.append(s)
						else:
							var pours: bool = String(StageData.ENEMIES[brood].move) == "spore"   # the Smelter pours Hot Coals from its mouth, downward
							var m := _make_enemy(brood, e.pos + (Vector2(float(k - 1) * 26.0, 46.0) if pours else Vector2(float(k - 1) * 30.0, -54.0)))
							m.state = "hatch"
							m.vel = Vector2(float(k - 1) * 60.0, 30.0) if pours else Vector2(float(k - 1) * 50.0, -60.0)
							live.append(m)
					var bcol := (Color(1.0, 0.55, 0.15) if StageData.MAGMA.has(brood) else Color(0.3, 0.9, 1.0)) if brood != "scout" else Color(0.71, 0.55, 1.0)
					_burst(e.pos + Vector2(0, -58), 40.0, bcol, 22)   # the sacs on her back burst / the hold doors fly open
					_fx_add("nova", e.pos + Vector2(0, -58), 60.0, 0.5, 0.0, 1.8, Color(bcol, 0.9))
					_float_text(e.pos + Vector2(0, -110), ("POURING!" if brood == "coal" else ("ERUPTING!" if brood == "cinder" else "RELEASING!")) if brood != "scout" else "HATCHING!", bcol.lightened(0.3), true)
					shake = maxf(shake, 0.35)
		# frozen solid: it does not move (or shoot) until the ice breaks
		if float(e.get("freeze_t", 0.0)) > 0.0:
			e.freeze_t = float(e.freeze_t) - delta
			e.pos = prev
			if float(e.freeze_t) <= 0.0:
				_burst(e.pos, float(e.r) * 0.6, Color(0.75, 0.92, 1.0), 6)   # the ice breaks
		# Frost Rounds: a slowed bug covers only part of its move
		if float(e.get("slow_t", 0.0)) > 0.0:
			e.slow_t = float(e.slow_t) - delta
			e.pos = prev.lerp(e.pos, 1.0 - float(e.get("slow", 0.0)))
		if float(e.get("mark_t", 0.0)) > 0.0:   # a Dread Beacon's mark wears off
			e.mark_t = float(e.mark_t) - delta
		# a booster's aura: the bug covers 30% more ground this frame
		if float(e.get("boost_t", 0.0)) > 0.0 and e.state != "aim" and e.state != "hatch" and e.type != "spore":   # a spore keeps its motion in e.vel: stretching it would compound
			e.boost_t = float(e.boost_t) - delta
			e.pos = prev.lerp(e.pos, 1.3)
			if def.has("fire_every"):
				e.fire_t = float(e.fire_t) - delta * 0.5   # spits sooner
		# Afterburn (Ember card): a burning bug loses HP every frame and sheds embers
		if float(e.get("burn_t", 0.0)) > 0.0:
			e.burn_t = float(e.burn_t) - delta
			if _can_hurt(e):
				var bd: float = float(e.get("burn_dps", 0.0)) * delta
				e.hp -= bd
				stat_pilot_dmg += bd
				_count_dmg("hero", bd, e)
				_show_dmg(e, bd, false, _elem_mult)
			if rng.randf() < delta * 10.0:
				sparks.append({"pos": e.pos + Vector2(rng.randf_range(-8, 8), rng.randf_range(-8, 8)), "vel": Vector2(rng.randf_range(-20, 20), rng.randf_range(-70, -30)), "life": 0.35, "col": Color(1.0, 0.55, 0.2)})
			# from Afterburn level 2 the fire jumps to bugs it touches
			if _burn_level >= 2:
				e.spread_t = float(e.get("spread_t", 0.0)) - delta
				if float(e.spread_t) <= 0.0:
					e.spread_t = 0.3
					for o in enemies:
						if o != e and o.type != "spore" and float(o.get("burn_t", 0.0)) <= 0.0 and o.pos.distance_to(e.pos) < (float(e.r) + float(o.r)) * 0.75:
							o.burn_t = 1.5 + 0.75 * _burn_level
							o.burn_dps = 0.05 * float(o.hp_max)
		if not _is_boss(e):
			e.pos.x = clampf(e.pos.x, 16.0, FIELD_W - 16.0)   # never drifts off the sides (a wave must stay killable)
			if e.pos.y < -120.0:
				e.pos.y = -120.0
				e.vel = Vector2.ZERO
		e.vel = (e.pos - prev) / maxf(delta, 0.001)
		# faster than its cruising speed (a dart, a dive): it stretches into the motion (dev153)
		e.stretch_s = lerpf(float(e.get("stretch_s", 0.0)), clampf(e.vel.length() / maxf(float(e.speed), 1.0) - 1.0, 0.0, 1.2) * 0.16, minf(1.0, delta * 12.0))
		# tilt and wing fold ease toward their targets so dives and hatches never snap
		e.tilt_s = lerp_angle(float(e.get("tilt_s", _enemy_tilt(e))), _enemy_tilt(e), minf(1.0, delta * 10.0))
		var want_fold: float = 1.0 if _lunging(e) or (e.state == "hatch" and e.t < 0.45) else 0.0
		e.fold = move_toward(float(e.get("fold", want_fold)), want_fold, delta * 5.0)
		if _is_boss(e):
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
		if e.type == "crate":
			if e.hp <= 0.0:
				_crate_broken(e)
				continue
			if e.get("gone", false):
				continue
		if e.hp <= 0.0:
			_kill(e)
			continue
		if not _is_boss(e) and Backdrop.inside_field(centre, DOME_RX, DOME_RY, e.pos):
			_hurt_base((RUNNER_DMG * (0.5 if _base_perks.has("plating") else 1.0)) if e.has("runner") else float(def.get("base_dmg", 10.0)))
			if _is_diver(e):
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

# a boss (the Hive Mother, the Salvage Queen, the Wrecker mini-boss): the boss bar, the arrival
# veil, the big worth, no side clamp, no base contact (StageData.ENEMIES traits "boss")
func _is_boss(e: Dictionary) -> bool:
	return StageData.is_boss(String(e.type))

func _is_boss_id(id: String) -> bool:
	return StageData.is_boss(id)

# where an enemy's shots leave it (the Spitter's mouth, a machine's nose gun)
func _muzzle_of(e: Dictionary, size: float, tilt: float) -> Vector2:
	if EnemyRig.is_machine(String(e.type)):
		return EnemyRig.machine_anchor(String(e.type), "muzzle", e.pos, size, tilt)
	return EnemyRig.anchor("spitter", "muzzle", e.pos, size, tilt)

# the kamikazes: the Diver, the Dart, the Comet
func _is_diver(e: Dictionary) -> bool:
	return String(StageData.ENEMIES[e.type].move) == "dive"

func _lunging(e: Dictionary) -> bool:
	return _is_diver(e) and (e.state == "dive" or e.state == "aim")

# The tilt an enemy wants this frame; drawing uses e.tilt_s, which eases toward it.
func _enemy_tilt(e: Dictionary) -> float:
	if _lunging(e):
		return (Vector2(e.target) - e.pos).angle() + PI / 2.0 if e.has("target") else e.vel.angle() + PI / 2.0
	if _is_boss(e):
		return 0.0
	return clampf(e.vel.x * 0.004, -0.35, 0.35) + sin(e.t * 6.0 + e.ph) * 0.05

func _kill(e: Dictionary) -> void:
	var def: Dictionary = StageData.ENEMIES[e.type]
	var worth: int = 1500 if _is_boss(e) else (25 if e.type == "spore" else (150 if e.has("variant") else 100))
	score += worth
	_spawn_shards(e, def)
	_flush_dmg(int(e.id))   # the last number before it goes
	# Shatter (Deep Freeze overcharged): a slowed bug blasts its neighbours
	if _shatter and float(e.get("slow_t", 0.0)) > 0.0 and not _is_boss(e):
		for o in enemies:
			if o != e and o.hp > 0.0 and o.pos.distance_to(e.pos) < 90.0 and _can_hurt(o):
				o.hp -= 0.35 * float(e.hp_max)
				stat_pilot_dmg += 0.35 * float(e.hp_max)
		_fx_add("nova", e.pos, 55.0, 0.3, 0.0, 1.6, Color(0.7, 0.9, 1.0))
	# Afterburn overcharged: the fire jumps to the nearest bug
	if _burn_spread and float(e.get("burn_t", 0.0)) > 0.0:
		var nd := 140.0
		var nxt := {}
		for o in enemies:
			if o != e and o.hp > 0.0 and o.type != "spore" and o.pos.distance_to(e.pos) < nd:
				nd = o.pos.distance_to(e.pos)
				nxt = o
		if not nxt.is_empty():
			nxt.burn_t = 2.5
			nxt.burn_dps = 0.05 * float(nxt.hp_max)
			zaps.append({"a": e.pos, "b": nxt.pos, "life": 0.2, "seed": rng.randf() * 100.0})
		# and it leaves a burning patch that sets bugs passing through it alight
		if _fire_patches.size() < 8:
			_fire_patches.append({"pos": e.pos, "life": 2.6, "max": 2.6, "r": 44.0, "ph": rng.randf() * TAU})
	Sfx.play("boss_kill" if _is_boss(e) else "kill", rng.randf_range(0.9, 1.1))
	kills += 1
	if String(def.move) != "spore":
		_streak_add()   # the kill streak (more coins from the bugs you kill while it runs)
	if e.has("runner"):
		_runner_caught(e)
	_kills_by[e.type] = int(_kills_by.get(e.type, 0)) + 1
	_burst(e.pos, float(e.r), Color(1.0, 0.8, 0.4), 12 if _is_boss(e) else 7)
	if _is_boss(e):
		hitstop = 0.18
		shake = maxf(shake, 0.8)
	elif int(def.xp_tier) >= 1:
		hitstop = maxf(hitstop, 0.05)
	_float_text(e.pos, "+%d" % worth, Color(1.0, 0.85, 0.4))
	# a Drifter bursts into spore pods that drift down at the base
	for k in int(def.get("spores", 0)):
		var pod := _make_enemy(String(def.get("spawns_on_death", "spore")), e.pos)   # a Hulk bursts into Junk Bolts
		pod.vel = Vector2(rng.randf_range(-70.0, 70.0), rng.randf_range(-70.0, -30.0))
		spawned.append(pod)
	var tier: int = int(def.xp_tier)
	var count: int = 1
	if _is_boss(e):
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
	if _salvage and e.type != "spore":   # Salvage overcharged (talent card): every 10th kill drops a part
		_salvage_n += 1
		if _salvage_n % 10 == 0:
			var kind := "core" if _salvage_n % 100 == 0 else ("cell" if _salvage_n % 30 == 0 else "alloy")
			_parts_got[kind] = int(_parts_got.get(kind, 0)) + 1
			_float_text(e.pos + Vector2(0, -20), "+1 %s" % Parts.KINDS[kind].name, Parts.KINDS[kind].color)
	# coins drop as pickups too (Rudy, dev108: gems = XP, coins = money); the boss showers them
	var ncoins: int = mini(int(def.coins), 10)   # a boss drops 10 coins worth her full reward between them
	for i in ncoins:
		gems.append({"pos": e.pos + Vector2(rng.randf_range(-14, 14), rng.randf_range(-8, 8)), "tier": 0, "coin": true, "life": 16.0,
			"value": float(def.coins) / float(ncoins) * _streak_mult(),
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
	# cards build up over the whole stage (they reset only when a new stage starts). Rudy
	# (dev209 playtest): they came too fast (level 11 by the end of stage 5), so each level asks
	# for more gem XP and the climb steepens past 14: a short stage ends near level 7, a long
	# late one near 13-14, and each pick matters more.
	var base := 8.0 + 7.0 * (run_level - 1)
	if run_level > 14:
		base *= pow(1.5, run_level - 14)
	return base * _xp_cut


# ------------------------------------------------------------------ damage, effects, end

func _hurt_base(amount: float) -> void:
	if _pulse_live > 0.0:   # the Core Pulse stands: nothing gets through
		_pulse_blocked += 1
		_pulse_flash = maxf(_pulse_flash, 0.35)
		return
	amount *= (1.0 - _base_dr) * _base_hit()   # gear milestones (Chest); bugs hit the base harder (dev272)
	hit_t = 0.0
	_took_damage = true
	shake = maxf(shake, 0.45 if shield <= 0.0 else 0.3)
	_buzz(25)
	if shield > 0.0 and _shield_dr > 0.0:
		amount *= 1.0 - _shield_dr
	if shield > 0.0:
		Sfx.play("shield")
		shield = maxf(shield - amount, 0.0)
		if shield <= 0.0 and _base_perks.has("shield_gen") and not _dome_used:   # Shield Generator Lv.5: it comes back once
			_dome_used = true
			_pod_ping("shield_gen")
			shield = shield_max * 0.3
			_fx_add("nova", Vector2(FIELD_W * 0.5, BASE_Y - DOME_RY * 0.5), 220.0, 0.6, 0.0, 2.2, Color(0.31, 0.88, 1.0))
			_float_text(Vector2(FIELD_W * 0.5, BASE_Y - DOME_RY - 30.0), "EMERGENCY SHIELD", Color(0.5, 0.92, 1.0), true)
			return
		if _bastion and shield <= 0.0:
			_bastion_blast()
	else:
		Sfx.play("hull")
		hull = maxf(hull - amount, 0.0)

func _hurt_pilot(amount: float = GOO_DMG) -> void:
	if inv_t > 0.0:
		return
	if _ult_live > 0.0 and _ult_kind == "phase" and _live_ups >= 3:   # Out of Phase (Hollow s third upgrade)
		return
	if _support_blocks():   # the Guard drone takes this one
		return
	inv_t = 1.0 * _recovery
	if _rig_view:
		_rig_view.hit()   # he flinches and flashes
	_buzz(45)
	_streak_break()   # a hit ends the kill streak
	var dmg := amount * _enemy_hit() * (1.0 - _def)   # DEF takes its share off; bugs hit harder (dev272)
	pilot_hp = maxf(pilot_hp - dmg, 0.0)
	# Second Wind (talent card): once a run, the blow that would finish him heals him instead
	if pilot_hp <= 0.0 and _second_wind > 0:
		pilot_hp = pilot_hp_max * [0.5, 0.75, 1.0][clampi(_second_wind - 1, 0, 2)]
		_second_wind = 0
		inv_t = 2.0
		_fx_add("nova", soldier_pos, 120.0, 0.6, 0.0, 2.2, Color(0.6, 1.0, 0.7))
		_float_text(soldier_pos + Vector2(0, -60), "SECOND WIND", Color(0.6, 1.0, 0.7), true)
		Sfx.play("shield")
		shake = maxf(shake, 0.4)
		return
	Sfx.play("hurt")
	_hp_lost += dmg
	_took_damage = true
	shake = maxf(shake, 0.7)
	_burst(soldier_pos, 16.0, Color(1.0, 0.35, 0.42), 10)
	_float_text(soldier_pos + Vector2(0, -30), "-%d" % roundi(dmg), Color(1.0, 0.4, 0.45))

func _burst(p: Vector2, radius: float, col: Color, count: int = 7) -> void:
	rings.append({"pos": p, "life": 0.4, "max": 0.4, "r": radius * 2.6, "col": col})
	for k in count:
		sparks.append({"pos": p, "vel": Vector2(rng.randf_range(-120, 120), rng.randf_range(-120, 120)), "life": 0.4, "col": col})

func _float_text(p: Vector2, text: String, col: Color, big: bool = false) -> void:
	floaters.append({"pos": p + Vector2(rng.randf_range(-6, 6), 0), "text": text, "life": 1.1 if big else 0.9, "col": col, "big": big})

# Damage numbers (Rudy, dev172): a crit shows at once, big and gold; everything else on a bug
# adds up for a quarter second and shows as one small number, coloured by the element: orange
# when the hero is strong here, grey when the planet resists him.
func _show_dmg(e: Dictionary, dmg: float, crit: bool, mult: float = 1.0) -> void:
	if not _dmg_numbers:
		return
	if dmg <= 0.0:
		return
	if crit:
		_float_text(e.pos + Vector2(0, -float(e.r) - 10.0), "CRIT %d" % roundi(dmg * DMG_SHOW), Color(1.0, 0.82, 0.32), true)
		return
	var a: Dictionary = _dmg_acc.get(int(e.id), {"v": 0.0, "t": time_alive, "m": mult})
	a.v = float(a.v) + dmg
	a.pos = e.pos + Vector2(0, -float(e.r) - 6.0)
	_dmg_acc[int(e.id)] = a

func _dmg_col(mult: float) -> Color:
	if mult > 1.01:
		return Color(1.0, 0.6, 0.25)
	if mult < 0.99:
		return Color(0.7, 0.72, 0.8)
	return Color(0.95, 0.97, 1.0, 0.9)

# show what a bug has taken so far (its id; -1 = every bug whose batch is due)
func _flush_dmg(id: int = -1) -> void:
	var done: Array = []
	for k in _dmg_acc:
		var a: Dictionary = _dmg_acc[k]
		if int(k) == id or (id < 0 and time_alive - float(a.t) >= DMG_BATCH):
			if float(a.v) * DMG_SHOW >= 0.5:
				_float_text(Vector2(a.get("pos", Vector2.ZERO)), str(roundi(float(a.v) * DMG_SHOW)), _dmg_col(float(a.get("m", 1.0))))
			done.append(k)
	for k in done:
		_dmg_acc.erase(k)

func _step_effects(delta: float) -> void:
	_flush_dmg()
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
	_xp_bonus = Turrets.first_clear_bonus(stage) if won and not elite and not _is_trial() and stage >= was else 0
	# an element trial (Promotion): the first clear of a step pays shards, coins, crystals
	_etrial_first = false
	_etrial_reward = {}
	if not etrial.is_empty() and won:
		_etrial_first = Promotion.etrial_won(d, String(etrial.el), int(etrial.step))
		_etrial_reward = Promotion.etrial_reward(int(etrial.step), _etrial_first, String(etrial.el))
		Progress.grant(d, _etrial_reward)
		_write_save({"etrials": d.get("etrials", {}), "coins": int(d.coins), "crystals": int(d.get("crystals", 0)), "hero": d.get("hero", {})})
	if run_mode:   # an Expedition fight: the run takes the result (Runs.fight_done)
		_run_end(won)
	# the hero on duty adds to his contracts (Contracts): a win, his kills, his abilities
	if Contracts.open(d):
		Contracts.add(d, _hero_id, won, kills, _abilities_used)
		_write_save({"contracts": d.contracts})
	_abilities_used = 0
	# season XP for every fight (Season): more for a win, a little on top for the special modes
	_season_xp = 0
	_season_up = false
	if Season.open(d):
		_season_xp = (Season.XP_WIN if won else Season.XP_LOSS) + (Season.XP_SPECIAL if _is_trial() else 0)
		var tier_was := Season.tier(d)
		Season.add_xp(d, _season_xp)
		_season_up = Season.tier(d) > tier_was
		_write_save({"season": d.season})
	# a weekly event fight: event points, win or lose (Events.points_for)
	_event_points = 0
	if event_run:
		_event_points = Events.points_for(won, hull / maxf(hull_max, 1.0), _hp_lost)
		Events.add_points(d, _event_points)
		_write_save({"event": d.event})
	# a Boss Rush: coins for every boss down, the first full line of each length pays more (BossRush.finish)
	_rush = {}
	if boss_rush:
		_rush = BossRush.finish(d, won, waves.size() if won else wave_index, waves.size(), time_alive)
		_write_save({"bossrush": d.bossrush, "coins": int(d.coins), "crystals": int(d.get("crystals", 0)), "materials": d.get("materials", {})})
	# the daily challenge: the first win of the day pays its reward
	_daily_reward = {}
	if daily and won and Promotion.daily_won(d):
		_daily_reward = Promotion.daily_reward(d)
		Progress.grant(d, _daily_reward)
		_write_save({"daily_day": int(d.daily_day), "crystals": int(d.get("crystals", 0)), "materials": d.get("materials", {})})
	# a promotion trial: a win the first time = the next rank, for good (Promotion)
	_promoted = false
	if promo >= 0 and won and Promotion.won(d, promo):
		_promoted = true
		_xp_bonus = Promotion.XP_BONUS
		_write_save({"promotion": int(d.promotion)})
	_xp_gain = int(score / 50 * _pilot_xp_mult) + _xp_bonus
	_level_before = Turrets.pilot_level(old_xp)
	_level_after = Turrets.pilot_level(old_xp + _xp_gain)
	if horde:   # the wave count is the score; a new best is saved
		_horde_new_best = wave_index + 1 > _horde_best
		if _horde_new_best:
			_write_save({"best_horde": wave_index + 1})
			d["best_horde"] = wave_index + 1
		if score > int(d.get("best_horde_score", 0)):   # the Modes card shows it (style pass, 2026-11-09)
			_write_save({"best_horde_score": score})
			d["best_horde_score"] = score
	var patch := {"coins": int(d.get("coins", 0)) + coins_earned, "best_score": maxi(score, int(d.get("best_score", 0))),
		"best_kills": maxi(kills, int(d.get("best_kills", 0))), "pilot_xp": old_xp + _xp_gain}
	# stars for the stage map = the 3 stage objectives (_objectives): cleared, base hull
	# above half, the pilot untouched (dev172: HP instead of hearts; a hit is a hit)
	if won and not elite and not _is_trial():
		var got := 1 + (1 if hull >= hull_max * 0.5 else 0) + (1 if _hp_lost <= 0.0 else 0)
		var st = d.get("stars", {})
		if typeof(st) != TYPE_DICTIONARY:
			st = {}
		st[str(stage)] = maxi(int(st.get(str(stage), 0)), got)
		patch["stars"] = st
		_stars_got = got
	# stage clear: 2 Alloy (+1 per 10 stages), a Plasma Cell on every 5th stage, all kept
	# with what was picked up (parts are kept even when the base falls)
	if won:
		_parts_got["alloy"] = int(_parts_got.get("alloy", 0)) + 2 + stage / 10 + (2 if _base_perks.has("refinery") else 0)   # Refinery Lv.5
		if stage % 5 == 0:
			_parts_got["cell"] = int(_parts_got.get("cell", 0)) + 1
	var owned := Parts.read(d)
	for k in _parts_got:
		owned[k] = int(owned.get(k, 0)) + int(_parts_got[k])
	var parts_only := {}
	for k in Parts.ORDER:   # Parts.read carries the materials too (dev189); only the parts go in "parts"
		parts_only[k] = int(owned.get(k, 0))
	patch["parts"] = parts_only
	# materials (materials.gd, dev189): a boss stage or an Elite win pays this planet's essence,
	# later stages trickle barrels and rotors, Horde pays a barrel and a rotor per 10 waves
	_mats_got = {}
	if won and not _is_trial():
		_mats_got = Materials.horde_drop(wave_index + 1) if horde else Materials.stage_drop(stage, elite, rng)
	elif horde and not won:
		_mats_got = Materials.horde_drop(wave_index)
	if not _mats_got.is_empty():
		var md := {"materials": Materials.read(d)}
		for k in _mats_got:
			md.materials[k] = int(md.materials[k]) + int(_mats_got[k])
		patch["materials"] = md.materials
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
	if won and not _is_trial() and (StageData.boss_kind(stage) != "" or elite):
		var hid := Heroes.hero_for_planet(stage)
		var sn := (3 if StageData.boss_kind(stage) == "boss" else 2) + (1 if elite else 0)
		var hh := Heroes.read(d)
		Heroes.add_shards(hh, hid, sn)
		patch["hero"] = Heroes.write(hh)
		_shards_got = {"id": hid, "n": sn}
	if won and not _is_trial() and elite:   # Elite is its own ladder (dev167): a win opens the next Elite stage
		patch["elite_unlocked"] = maxi(stage + 1, int(d.get("elite_unlocked", 1)))
	if won and not _is_trial() and not elite:   # a trial never unlocks stages; Elite has its own ladder
		patch["stage_unlocked"] = maxi(stage + 1, was)
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
	_ult_btn = Button.new()   # the hero ability (drawn in _draw_ult_btn)
	_ult_btn.flat = true
	_ult_btn.focus_mode = Control.FOCUS_NONE
	_ult_btn.size = Vector2(64, 64)
	for st in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		_ult_btn.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	_ult_btn.pressed.connect(_use_ability)
	add_child(_ult_btn)
	_auto_btn = Button.new()   # AUTO / MANUAL (drawn in _draw_auto_btn, which also keeps it in place)
	_auto_btn.flat = true
	_auto_btn.focus_mode = Control.FOCUS_NONE
	_auto_btn.size = Vector2(58, 58)
	for st in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		_auto_btn.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	_auto_btn.pressed.connect(_toggle_auto)
	add_child(_auto_btn)
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
		{"text": "Take no damage", "state": ("done" if won else "ok") if _hp_lost <= 0.0 else "fail"},
	]

# damage by source (dev199, from Rudy's Rogue Defense note): "hero", "drone" or a turret type;
# counted as what the bug actually lost, like the share stats
func _count_dmg(src: String, dmg: float, e: Dictionary) -> void:
	_dmg_by[src] = float(_dmg_by.get(src, 0.0)) + minf(dmg, maxf(float(e.hp), 0.0))

# the DAMAGE block for the pause menu and the clear screen: every source with its share
# and total, biggest first, a thin bar each; compact = fewer rows, smaller
func _dmg_rows(compact: bool = false) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var total := 0.0
	for k in _dmg_by:
		total += float(_dmg_by[k])
	var keys: Array = _dmg_by.keys()
	keys.sort_custom(func(a, b): return float(_dmg_by[a]) > float(_dmg_by[b]))
	box.add_child(UIKit.label("DAMAGE  ·  %s total" % UIKit.num(int(total)), 10 if compact else 11, UIKit.MUTED))
	if total <= 0.0:
		box.add_child(UIKit.label("nothing hit yet", 10, UIKit.MUTED))
		return box
	var elapsed: float = maxf(time_alive, 1.0)
	for k in keys.slice(0, 5 if compact else 8):
		var d: float = float(_dmg_by[k])
		var name := "Drone" if k == "drone" else (String(Heroes.ROSTER.get(_hero_id, {}).get("name", "Hero")) if k == "hero" else String(k).capitalize())
		var col: Color = Heroes.element_color(Heroes.element_of(_hero_id)) if k == "hero" else (Color(0.8, 0.6, 1.0) if k == "drone" else UIKit.SOFT)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var nl := UIKit.label(name, 11 if not compact else 10, Color.WHITE)
		nl.custom_minimum_size = Vector2(96, 0)
		row.add_child(nl)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.min_value = 0.0
		bar.max_value = 1.0
		bar.value = d / total
		bar.custom_minimum_size = Vector2(0, 8)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.add_theme_stylebox_override("background", UIKit.box(Color(1, 1, 1, 0.08), Color(0, 0, 0, 0), 4, 0))
		bar.add_theme_stylebox_override("fill", UIKit.box(Color(col, 0.85), Color(0, 0, 0, 0), 4, 0))
		row.add_child(bar)
		var sl := UIKit.label("%d%%  ·  %s  ·  %s/s" % [roundi(100.0 * d / total), UIKit.num(int(d)), UIKit.num(int(d / elapsed))], 10, UIKit.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
		sl.custom_minimum_size = Vector2(118, 0)
		row.add_child(sl)
		box.add_child(row)
	return box

# one loot tile on the end screen: the item's picture big, its amount under it
func _loot_tile(tex: Texture2D, text: String, col: Color) -> Control:
	var p := PanelContainer.new()
	var sb := UIKit.box(Color(col.r * 0.14, col.g * 0.14, col.b * 0.2, 0.85), Color(col, 0.55), 10, 1)
	sb.set_content_margin_all(4)
	p.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	var tr := TextureRect.new()
	tr.texture = tex
	tr.custom_minimum_size = Vector2(44, 40)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vb.add_child(tr)
	vb.add_child(UIKit.label(text, 12, col, HORIZONTAL_ALIGNMENT_CENTER))
	p.add_child(vb)
	return p

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
	if _twist:
		v.add_child(UIKit.label("TODAY'S TWIST  ·  coins +%d%%" % roundi((Promotion.TWIST_COINS - 1.0) * 100.0), 11, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	for m in _mods:   # the trial twists, one per line with Luna's icon (dev189)
		v.add_child(Promotion.mods_row([m], 11, 20.0, true, true))
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
	quit_b.pressed.connect(_confirm_leave)   # asks first (Rudy, dev209)
	v.add_child(quit_b)
	_pause_panel.add_child(box)
	box.size = Vector2(340.0, box.get_combined_minimum_size().y)
	UIKit.pop_in(box)   # the menu pops into place (dev157)

# "Are you sure?" before leaving a stage from the pause menu: leaving restarts the stage
func _confirm_leave() -> void:
	var layer := ColorRect.new()
	layer.color = Color(0.0, 0.01, 0.04, 0.55)
	layer.position = Vector2(0, -_safe_top)
	layer.size = get_viewport_rect().size
	_pause_panel.add_child(layer)
	var p := UIKit.popup_panel()
	var w := 300.0
	p.custom_minimum_size = Vector2(w, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.add_child(UIKit.popup_title("LEAVE THE STAGE?"))
	var msg := UIKit.label("You will restart it from wave 1.", 13, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(msg)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var stay := UIKit.teal_button("Stay", 15)
	stay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stay.custom_minimum_size = Vector2(0, 44)
	stay.pressed.connect(layer.queue_free)
	row.add_child(stay)
	var go := UIKit.ghost_button("Leave", 15)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.custom_minimum_size = Vector2(0, 44)
	go.pressed.connect(func(): get_tree().change_scene_to_file("res://hub.tscn"))
	row.add_child(go)
	v.add_child(row)
	p.add_child(v)
	# centred by a container: placed by hand, the card grew to the bottom of the screen (Rudy, dev271)
	var cc := CenterContainer.new()
	cc.size = layer.size
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(cc)
	cc.add_child(p)
	UIKit.pop_in(p)

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
	var ch := 228.0   # room for three lines of the bolder text (dev172)
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
	# the free refresh(es), then refreshes bought with the coins picked up in this run (dev199,
	# from Rudy's Undead Slayer note): 150 coins, then 300, 450...
	var coin_cost: int = 150 * (_coin_refreshes + 1)
	var coins_now: int = int(_coins_f)
	var txt: String = ("Refresh (%d left)" % refreshes) if refreshes > 0 else ("Refresh  ·  %d coins" % coin_cost)
	var refresh := UIKit.ghost_button(txt, 13)
	refresh.position = Vector2(FIELD_W * 0.5 - 90, FIELD_H * 0.5 + 50)
	refresh.size = Vector2(180, 34)
	refresh.disabled = refreshes <= 0 and coins_now < coin_cost
	refresh.pressed.connect(func():
		if refreshes > 0:
			refreshes -= 1
			_open_cards()
		elif int(_coins_f) >= coin_cost:
			_coins_f -= float(coin_cost)
			coins_earned = int(_coins_f)
			_coin_refreshes += 1
			Sfx.play("coin")
			_open_cards())
	if _card_panel.get_child_count() > 3:
		Tips.first(get_tree(), [["cards", _card_panel.get_child(3)]])   # the first card
	_card_panel.add_child(refresh)
	_card_panel.visible = true

# A card's picture: Luna's cards/pic_<id>.png, else a menu icon. A fusion without its
# own picture shows its two parts side by side, overlapping.
# the cards taken this run, as a row of small pictures beside the LV chip with a pip per level
# (dev199, Rudy's Undead Slayer note): the build at a glance; overcharged ones framed gold
var _card_tex_cache := {}
func _card_tex(id: String) -> Texture2D:
	if _card_tex_cache.has(id):
		return _card_tex_cache[id]
	var own := "res://cards/pic_%s.png" % id
	var path: String = own if ResourceLoader.exists(own) else String(Cards.def(id).get("pic", ""))
	if path == "" and Cards.FUSIONS.has(id):
		path = "res://cards/pic_%s.png" % String(Cards.FUSIONS[id].parts[0])
	var tex: Texture2D = load(path) if path != "" and ResourceLoader.exists(path) else null
	_card_tex_cache[id] = tex
	return tex

func _draw_card_row(at: Vector2) -> void:
	if card_levels.is_empty():
		return
	var ids: Array = card_levels.keys()
	var px := 18.0
	var step := px + 5.0
	var room: int = int((FIELD_W - 150.0 - at.x) / step)   # up to the HUD buttons on the right
	var shown: int = mini(ids.size(), room)
	for i in shown:
		var id: String = ids[i]
		var lvl: int = int(card_levels[id])
		var def: Dictionary = Cards.def(id)
		var over: bool = Cards.overcharged(card_levels, id)
		var col: Color = Glass.GOLD if over else Cards.COLOR.get(String(def.get("rarity", "common")), Color.WHITE)
		var r := Rect2(at + Vector2(i * step, 0), Vector2(px, px))
		_hc.draw_rect(r.grow(1.0), Color(0.03, 0.05, 0.12, 0.85))
		var tex := _card_tex(id)
		if tex != null:
			_hc.draw_texture_rect(tex, r, false)
		_hc.draw_rect(r.grow(1.0), Color(col, 0.9), false, 1.0)
		# level pips under it
		for k in mini(lvl, 3):
			_hc.draw_circle(r.position + Vector2(3.0 + k * 6.0, px + 4.0), 1.6, Color(col, 0.95))
	if ids.size() > shown:
		_hc.draw_string(hud_font, at + Vector2(shown * step, 13.0), "+%d" % (ids.size() - shown), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UIKit.MUTED)

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
	var own := "res://cards/pic_%s.png" % id
	var pic_path := own if ResourceLoader.exists(own) else String(Cards.def(id).get("pic", own))   # Luna's picture first; a hero card without one yet borrows its weapon art (cards.gd "pic": Rook's Twin Trigger)
	if ResourceLoader.exists(pic_path):
		icon.texture = load(pic_path)
		icon.custom_minimum_size = Vector2(0, h)
		if id == "nova_burst":
			var add := CanvasItemMaterial.new()
			add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD   # painted as light on black
			icon.material = add
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
	b.clip_contents = true   # nothing ever drawn outside the card (dev209: text spilled past the frame)
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_card_pic(id, 50.0 if fusion or over else 62.0))
	var name_l := UIKit.label(def.name, 12, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(name_l)
	var gold := Color(1.0, 0.82, 0.32)
	# the frame already shows the rarity: the tag is just NEW or the level, in the rarity colour
	var tag := "FUSION" if fusion else ("OVERCHARGE" if over else ("NEW" if lvl == 0 else "Lv.%d" % (lvl + 1)))
	v.add_child(UIKit.label(tag, 10, gold if over else col, HORIZONTAL_ALIGNMENT_CENTER))
	# a card that leads to a fusion carries a small link badge in its corner (was a CHAIN line)
	if Cards.chain_of(id) != "" and not fusion and not over:
		var link := Control.new()
		link.mouse_filter = Control.MOUSE_FILTER_IGNORE
		link.position = Vector2(size.x - 34.0, 12.0)
		link.size = Vector2(22, 22)
		var lc: Color = Cards.COLOR.fusion
		link.draw.connect(func():
			link.draw_circle(Vector2(11, 11), 11.0, Color(0.05, 0.03, 0.08, 0.85))
			link.draw_arc(Vector2(8, 11), 4.5, 0.0, TAU, 16, lc, 2.0, true)
			link.draw_arc(Vector2(14, 11), 4.5, 0.0, TAU, 16, lc, 2.0, true))
		b.add_child(link)
	# an overcharge card shows only its new bonus (the card itself is known by now)
	if not over:
		var d := UIKit.label(Cards.pick_text(id, lvl) if not fusion else String(def.desc), 10, Color(0.8, 0.88, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
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
	var cs := _read_save()   # the collection book (Codex): a card picked for the first time ever goes in
	if Codex.note_card(cs, id):
		_write_save({"cards_seen": cs.cards_seen})
	if not _replaying:
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
		if not _replaying:   # (not when a run puts its cards back at the start of a fight)
			# its own moment (dev199, Rudy's Undead Slayer note): a gold ring off the hero, a shout,
			# a beat of hit-stop and a shake, so the third pick feels like the event it is
			_fx_add("nova", soldier_pos, 130.0, 0.6, 0.0, 2.4, Color(1.0, 0.85, 0.4))
			_burst(soldier_pos, 40.0, Color(1.0, 0.85, 0.4), 18)
			_float_text(soldier_pos + Vector2(0, -84), "OVERCHARGE!", Color(1.0, 0.85, 0.4), true)
			hitstop = maxf(hitstop, 0.12)
			shake = maxf(shake, 0.35)
		if not _replaying:
			Sfx.play("level", 1.3)
	match id:
		"rapid_pulse": fire_rate_mult *= 1.10
		"heavy_bolts": damage_mult *= 1.15
		"burst_fire": burst_count += 1
		"aegis":
			pilot_hp_max += 30.0   # Aegis: +30 max HP, healed now
			_aegis_flash = 1.0
			if _rig_view:
				_rig_view.shield_form = 0.0   # the band closes in around him
			pilot_hp = minf(pilot_hp + 30.0, pilot_hp_max)
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
		# talent cards (Talents.CARD_AT, dev197)
		"focus_fire": damage_mult *= 1.06
		"salvage": _coin_mult += 0.25
		"second_wind": _second_wind = int(card_levels[id])
		"mirror_shell": _mirror = int(card_levels[id])
		"shield_recharge": _shield_rate += 0.01
		# base cards (Cards "building"): more of what the building does
		"shield_surge":
			shield_max += 25.0
			shield = minf(shield + 25.0, shield_max)
		"nanobots": _hull_rate += 0.004
		"hot_rounds": damage_mult *= 1.08
		"stim_pack":
			pilot_hp_max += 15.0
			pilot_hp = minf(pilot_hp + 25.0, pilot_hp_max)
		"plate_up":
			hull_max += 25.0
			hull = minf(hull + 25.0, hull_max)
			_base_dr = clampf(_base_dr + 0.04, 0.0, 0.6)
		"drone_uplink": _drone_mult *= 1.2
		"reactor_surge":
			_ult_cd *= 0.9
			_ult_t *= 0.9
		"radar_sweep": _crit_rate += 0.05
		"rich_seam": _coin_mult += 0.15
		"core_overload":
			_pulse_cd_mult *= 0.8
			_pulse_t *= 0.8
		# hero cards (Cards "hero"): the build-up over the three picks
		"rook_twin": _twin_every = [4, 3, 2][clampi(int(card_levels[id]) - 1, 0, 2)]
		"sparks_weld": _weld_count += 1
		"frost_freeze": _freeze_level += 1
		"hollow_phase": pierce_level += 1
		"nyx_mark": _crit_rate += 0.10
		"ember_burn": _burn_level += 1
		"nova_burst":
			for e in enemies.duplicate():
				if not _is_boss(e):
					e.hp = 0.0
					_kill(e)
			enemies = enemies.filter(func(e): return _is_boss(e))
			_burst(soldier_pos, 60.0, Color(1.0, 0.9, 0.6), 24)
			_fx_add("nova", soldier_pos, 150.0, 0.7, 0.0, 4.5)   # Luna's white-gold ring sweeps the screen
			shake = maxf(shake, 0.6)
	if not _replaying:
		_float_text(soldier_pos + Vector2(0, -56), Cards.CARDS[id].name, Cards.COLOR[Cards.CARDS[id].rarity])
	_card_panel.visible = false
	picking = false

func _overcharge(id: String) -> void:
	match id:
		"focus_fire": _crit_rate += 0.10
		"salvage": _salvage = true
		"mirror_shell": _mirror_through = true
		"rapid_pulse": _overdrive = true
		"heavy_bolts": _crit6 = true
		"piercing_rounds": _pierce_bonus = true
		"frost_rounds": _frost_bonus = true
		"burst_fire": _burst_pierce = true
		"magnet": _gem_shield = true
		"reinforced_hull":
			shield_max += 40.0
			shield = minf(shield + 40.0, shield_max)
		"aegis": _aegis_heal = true
		"chain_spark": _chain_mult = 2.0
		"shield_recharge": _hull_rate = 0.004
		# base cards: the third pick adds something new
		"shield_surge": _shield_dr = 0.15
		"nanobots": _base_repair = maxf(_base_repair * 2.0, 0.03)
		"hot_rounds": _crit_dmg += 0.3
		"stim_pack": _second_wind = maxi(_second_wind, 1)
		"plate_up":
			if not _base_perks.has("plating"):
				_base_perks.append("plating")
		"drone_uplink": _drone_mult *= 1.4
		"reactor_surge": _ult_t = 0.0
		"radar_sweep": _radar_heal = true
		"rich_seam": _wave_coins = true
		"core_overload": _pulse_bonus = 2.0
		"rook_twin": _twin_bonus = true
		"sparks_weld": _weld_every = 1
		"frost_freeze": _shatter = true
		"hollow_phase": _phase_bonus = true
		"nyx_mark": _crit_dmg += 1.0
		"ember_burn": _burn_spread = true
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
# capture hook (tools/dev/capture.gd CAP_CALL="_dbg_cards|sparks_weld,frost_freeze,nyx_mark"): a pick of these cards
var _dbg_offer: Array = []
func _dbg_cards(ids: String) -> void:
	_dbg_offer = Array(ids.split(","))
	_open_cards()

func _offer() -> Array:
	if not _dbg_offer.is_empty():
		var forced := _dbg_offer
		_dbg_offer = []
		return forced
	var fielded: Array = _base_slots.filter(func(sid): return String(sid) != "")   # base cards need their building (Cards "building")
	if _pulse_open():
		fielded.append("*pulse")
	var picks := Cards.draw(card_levels, 3, rng, run_level, false, fielded, _hero_id, _talents)
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
			if not _is_boss(e):
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
	# support pods (dev172, DESIGN-turrets-drones.md): a job instead of guns
	match DroneData.pod_job(String(_drone.pod)):
		"repair":
			# patches the base shield a little every second (the shield never regenerates on its own)
			if shield < shield_max:
				shield = minf(shield + float(pod.get("heal", 1.5)) * delta, shield_max)
				if rng.randf() < delta * 2.0:
					_drone_beam = {"a": p, "b": Vector2(FIELD_W * 0.5, BASE_Y - DOME_RY * 0.6), "life": 0.25, "col": Color(0.4, 1.0, 0.8)}
			_drone_aim = lerp_angle(_drone_aim, -PI / 2.0, delta * 3.0)
			return
		"magnet":
			# gathers gems and coins near it and brings them to the pilot
			for g in gems:
				if Vector2(g.pos).distance_to(p) < float(pod.get("reach", 150.0)):
					g.pos = Vector2(g.pos).move_toward(soldier_pos, 300.0 * delta)
			_drone_aim = lerp_angle(_drone_aim, -PI / 2.0, delta * 3.0)
			return
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
	var dmg: float = float(WEAPONS.laser_pistol.damage) * float(pod.damage) * float(body.dmg) * DroneData.level_mult(int(_drone.level)) * DroneData.dmg_bonus(int(_drone.level)) * DroneData.star_mult(_drone)   # its own element is applied on the hit (_drone_mult)
	# round 2 body passives: the Night Bat crits, the Wisp phases through a bug, the Spark Bot arcs
	var d_lucky: bool = rng.randf() < float(body.get("crit", 0.0))
	if d_lucky:
		dmg *= _crit_dmg
	var d_pierce: int = 1 if body.get("phase", false) else 0
	var d_arc: int = int(body.get("arc", 0))
	var dir := Vector2.from_angle(_drone_aim)
	match String(_drone.pod):
		"beam":
			# instant hit: a purple line to the target
			dmg *= _drone_mult   # the beam hits now: the drone element
			if d_arc > 0:
				_chain(best, d_arc, dmg * 0.6)   # the Spark Bot's beam arcs on
			best.hp -= dmg if _can_hurt(best) else 0.0
			_show_dmg(best, dmg, false, _drone_mult)
			stat_pilot_dmg += dmg
			_count_dmg("drone", dmg, best)
			_drone_beam = {"a": p + dir * 14.0, "b": best.pos, "life": 0.18, "col": Color(0.8, 0.5, 1.0)}
			_fx_add("impact", best.pos, 24.0, 0.2, 0.0, 1.6, Color(0.85, 0.6, 1.0))
		"missile":
			bullets.append({"pos": p + dir * 12.0, "vel": dir * 260.0, "dmg": dmg, "r": 12.0, "tid": int(best.id), "col": "missile", "drone": true, "lucky": d_lucky, "pierce_left": d_pierce, "weld": d_arc,
				"big": false, "pierce": false, "hits": [], "homing": int(best.id), "splash": float(pod.splash)})
		_:
			for s in [-1.0, 1.0]:
				var off: Vector2 = dir.orthogonal() * 5.0 * float(s)
				bullets.append({"pos": p + dir * 12.0 + off, "vel": dir * 500.0, "dmg": dmg, "r": 9.0, "tid": int(best.id), "col": "cyan", "drone": true, "lucky": d_lucky, "pierce_left": d_pierce, "weld": d_arc,
					"big": false, "pierce": false, "hits": []})

func _draw_drone() -> void:
	if not _drone_on:
		return
	var p := _drone_pos()
	var rot := _drone_aim + PI / 2.0   # the painted drones face up
	var pt: Texture2D = _tex["pod_" + DroneData.pod_art(String(_drone.pod))]
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
			if float(look.get("flap", 0.0)) > 0.0:   # wings and fins beat, mirrored on each side
				spin = -side * sin(time_alive * 7.0) * float(look.flap)
			draw_set_transform_matrix(base * Transform2D(_drone_tilt * 0.5 + spin, at))
			draw_texture_rect(tt, Rect2(-tw * 0.5, -th * 0.5, tw, th), false)
		draw_set_transform_matrix(base)
		draw_texture_rect(pt, Rect2(-pw * 0.5, -hh * 0.35 - ph * 0.5, pw, ph), false)
		draw_texture_rect(ht, Rect2(-hw * 0.5, -hh * 0.5, hw, hh), false)
		if _tex.has("extra_" + String(_drone.body)):   # the Wisp's middle fin, trailing
			var et: Texture2D = _tex["extra_" + String(_drone.body)]
			var eh: float = hh * 0.9
			var ew: float = eh * et.get_width() / et.get_height()
			draw_set_transform_matrix(base * Transform2D(sin(time_alive * 5.0) * 0.12, Vector2(0, hh * 0.35)))
			draw_texture_rect(et, Rect2(-ew * 0.5, 0.0, ew, eh), false)
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
	# round 2 (Luna, dev184): wings and fins ride the hull's edge; "flap" = the pair beats slowly
	"spark":   {"hull_w": 30.0, "thr_h": 14.0, "thr_out": 0.2, "thr_y": 0.05, "spin": false, "flap": 0.0},
	"wisp":    {"hull_w": 24.0, "thr_h": 30.0, "thr_out": 0.1, "thr_y": 0.3, "spin": false, "flap": 0.25},
	"bat":     {"hull_w": 18.0, "thr_h": 26.0, "thr_out": 0.05, "thr_y": -0.05, "spin": false, "flap": 0.35},
}
var _drone_tilt := 0.0   # the thrusters' lagging bank

# on the light layer: the pod's muzzle flash and beams
func _draw_drone_light() -> void:
	# round 2 bodies: Luna's glow layer (eyes, core, coil) breathing over the hull
	if _drone_on and _tex.has("glow_" + String(_drone.body)) and _tex.has("hull_" + String(_drone.body)):
		var gt: Texture2D = _tex["glow_" + String(_drone.body)]
		var ht2: Texture2D = _tex["hull_" + String(_drone.body)]
		var k: float = float(DRONE_PARTS[_drone.body].hull_w) / ht2.get_width()
		var gs := gt.get_size() * k
		var ga: float = 0.55 + 0.25 * sin(time_alive * 3.0) + 0.6 * _drone_flash / 0.12
		_fx.draw_set_transform(_drone_pos(), _drone_aim + PI / 2.0 + _drone_bank, Vector2(1.0 - absf(_drone_bank) * 0.25, 1.0))
		_fx.draw_texture_rect(gt, Rect2(-gs * 0.5, gs), false, Color(1, 1, 1, clampf(ga, 0.0, 1.0)))
		_fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
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
		var zc: Color = z.get("col", Color(0.6, 0.85, 1.0))   # healers zap green (variants)
		_fx.draw_polyline(pts, Color(zc, a), 2.0, true)
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
	var area_done: bool = won and StageData.boss_kind(stage) == "boss" and not elite and not _is_trial() and not horde
	var title := "AREA COMPLETE" if area_done else ("STAGE CLEARED" if won else "BASE LOST")
	if horde:
		title = "NEW BEST!" if _horde_new_best else "HORDE OVER"
	if not etrial.is_empty():   # an element trial (Promotion)
		title = "STEP CLEARED" if won else "TRIAL FAILED"
	if boss_rush:
		title = "RUSH CLEARED" if won else "RUSH OVER"
	if daily:
		title = "CHALLENGE CLEARED" if won else "CHALLENGE FAILED"
	if event_run:
		title = "EVENT CLEARED" if won else "EVENT LOST"
	if run_mode:
		title = ("EXPEDITION WON" if bool(_run.get("won", false)) else "STOP CLEARED") if won else "EXPEDITION OVER"
	if promo >= 0:   # a promotion trial (Promotion)
		title = "PROMOTED!" if _promoted else ("TRIAL CLEARED" if won else "TRIAL FAILED")
	var t := UIKit.label(title, 24, UIKit.GOLD if won else Color(1.0, 0.4, 0.45), HORIZONTAL_ALIGNMENT_CENTER)
	t.add_theme_font_override("font", title_font)
	v.add_child(t)
	if _season_xp > 0:
		v.add_child(UIKit.label(("SEASON TIER %d!   " % Season.tier(_read_save()) if _season_up else "") + "+%d season XP" % _season_xp, 12, UIKit.GOLD if _season_up else UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	if event_run:
		v.add_child(UIKit.label("%s  ·  +%d event points  (%d)" % [String(Events.theme().name).to_upper(), _event_points, int(Events.state(_read_save()).points)], 13, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	if boss_rush and not _rush.is_empty():
		v.add_child(UIKit.label("%d of %d bosses  ·  %s%s" % [waves.size() if won else wave_index, waves.size(), BossRush.time_text(time_alive), "  ·  NEW BEST" if bool(_rush.new_best) else ""], 13, UIKit.GOLD if won else UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER))
		v.add_child(UIKit.label(("FIRST CLEAR:  " if bool(_rush.first) else "") + Progress.reward_text(_rush.reward), 12, UIKit.GOLD if bool(_rush.first) else UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	if daily:
		if not _daily_reward.is_empty():
			v.add_child(UIKit.label("TODAY'S REWARD:  " + Progress.reward_text(_daily_reward), 12, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
		elif won:
			v.add_child(UIKit.label("Today's reward is already yours", 12, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	if promo >= 0:
		v.add_child(UIKit.label("PROMOTION TRIAL  ·  %s" % String(Promotion.RANKS[promo].name).to_upper(), 13, UIKit.CYAN, HORIZONTAL_ALIGNMENT_CENTER))
	else:
		if horde:
			v.add_child(UIKit.label("HORDE  ·  WAVE %d REACHED  ·  BEST %d" % [wave_index + 1, maxi(_horde_best, wave_index + 1)], 13, Color(1.0, 0.6, 0.3), HORIZONTAL_ALIGNMENT_CENTER))
		else:
			v.add_child(UIKit.label("%s %d  ·  %s" % ["ELITE" if elite else "STAGE", stage, StageData.stage_name(stage).to_upper()], 13, UIKit.CYAN, HORIZONTAL_ALIGNMENT_CENTER))
	if _promoted:
		var pr := Promotion.rank(_read_save())
		v.add_child(UIKit.label("RANK: %s" % String(Promotion.RANKS[promo].name).to_upper(), 16, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
		v.add_child(UIKit.label("For good: %s" % Promotion.bonus_text(pr), 12, Color(0.85, 0.92, 1.0), HORIZONTAL_ALIGNMENT_CENTER))
	elif not etrial.is_empty():
		v.add_child(UIKit.label("%s TRIAL  ·  STEP %d / %d" % [Heroes.element_name(String(etrial.el)).to_upper(), int(etrial.step) + 1, Promotion.ETRIAL_STEPS], 13, Heroes.element_color(String(etrial.el)), HORIZONTAL_ALIGNMENT_CENTER))
		if won:
			v.add_child(UIKit.label(("FIRST CLEAR:  " if _etrial_first else "REPLAY:  ") + Progress.reward_text(_etrial_reward), 12, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
		else:
			v.add_child(UIKit.label("Bugs are x%.1f tougher and more of them. Level him up, then try again." % Promotion.etrial_hp(int(etrial.step)), 11, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	elif promo >= 0 and not won:
		v.add_child(UIKit.label("Bugs are x%.2f tougher here. Upgrade, then try again." % Promotion.hp_mult(promo), 11, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	# three stars, popping in one after another (none in a trial)
	var got: int = _stars_got if won and not elite and not _is_trial() else 0
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
		if stage == PilotRig.COMMANDER_STAGE and not _is_trial() and not bool(_read_save().get("commander_seen", false)):
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
	# everything this stage dropped, as tiles (big icon, amount) that wrap onto more rows, so a
	# lucky stage never pushes the box off the screen (Rudy, dev209 playtest)
	var loot := HFlowContainer.new()
	loot.alignment = FlowContainer.ALIGNMENT_CENTER
	loot.add_theme_constant_override("h_separation", 6)
	loot.add_theme_constant_override("v_separation", 6)
	for k in Parts.ORDER:
		if int(_parts_got.get(k, 0)) > 0:
			loot.add_child(_loot_tile(Parts.icon(k), "+%d" % int(_parts_got[k]), Color(0.75, 0.9, 1.0)))
	if not _gear_got.is_empty():
		var gid: String = _gear_got.id
		var gpath := "res://gear/%s_t1.png" % gid
		loot.add_child(_loot_tile(load(gpath) if ResourceLoader.exists(gpath) else load("res://gear/%s.png" % gid), GearData.rarity_name(_gear_got.rarity), GearData.rarity_color(_gear_got.rarity)))
	if not _shards_got.is_empty():
		var sid: String = _shards_got.id
		var pp := "res://heroes/%s/portrait.png" % sid
		loot.add_child(_loot_tile(load(pp) if ResourceLoader.exists(pp) else UIKit.ic("mat_shard", "ic_shard"), "+%d" % int(_shards_got.n), Heroes.element_color(Heroes.element_of(sid))))
	for mk in _mats_got:
		if int(_mats_got[mk]) > 0:
			loot.add_child(_loot_tile(Materials.icon(String(mk)), "+%d" % int(_mats_got[mk]), Materials.color_of(String(mk))))
	if loot.get_child_count() > 0:
		v.add_child(loot)
	# who did the damage, best first (moved here from the pause menu)
	v.add_child(_dmg_rows(true))
	if _level_after > _level_before:
		v.add_child(UIKit.label("PILOT LEVEL %d!" % _level_after, 15, Color(0.85, 0.75, 1.0), HORIZONTAL_ALIGNMENT_CENTER))
	if not won:
		v.add_child(UIKit.label("Reached wave %d of %d" % [mini(wave_index + 1, waves.size()), waves.size()], 12, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var sp := Control.new(); sp.custom_minimum_size = Vector2(0, 4)
	v.add_child(sp)
	if won and stage < StageData.MAX_STAGE and not _is_trial():
		var nxt := UIKit.gold_button("Next stage", 17)
		nxt.custom_minimum_size = Vector2(0, 46)
		nxt.pressed.connect(func():
			if not Energy.try_play(_end_panel, elite, stage + 1):   # a stage costs power tokens (stages 1-5 free)
				return
			_write_save({"selected_stage": stage + 1})
			stage += 1
			_start_stage())
		v.add_child(nxt)
		if _auto_next:   # Settings > Auto-advance: the next stage starts by itself after a short count
			var left := [5]
			nxt.text = "Next stage  ·  5"
			var tm := Timer.new()
			tm.wait_time = 1.0
			tm.autostart = true   # it starts when the end screen enters the tree
			nxt.add_child(tm)
			var stay := UIKit.ghost_button("Stay on this screen", 12)
			tm.timeout.connect(func():
				left[0] -= 1
				if left[0] <= 0:
					tm.stop()
					nxt.text = "Next stage"
					if is_instance_valid(stay):
						stay.queue_free()
					nxt.pressed.emit()
				else:
					nxt.text = "Next stage  ·  %d" % left[0])
			stay.pressed.connect(func():
				tm.stop()
				nxt.text = "Next stage"
				stay.queue_free())
			v.add_child(stay)
	if run_mode:   # an Expedition fight ends on the map, never on Next stage / Play again
		var cont := UIKit.gold_button("Continue" if won and not Runs.over(_run) else "See the run", 17)
		cont.custom_minimum_size = Vector2(0, 50)
		cont.pressed.connect(func(): get_tree().change_scene_to_file("res://run_map.tscn"))
		v.add_child(cont)
		p.add_child(v)
		_end_panel.add_child(p)
		_end_panel.visible = true
		return
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
	Backdrop.draw_base_shade(self, Vector2(FIELD_W * 0.5, BASE_Y), DOME_RX, DOME_RY)
	Backdrop.draw_force_field(self, Vector2(FIELD_W * 0.5, BASE_Y), DOME_RX, DOME_RY, clampf(shield / shield_max, 0.0, 1.0), clampf(hull / hull_max, 0.0, 1.0), time_alive, elite, hit_t)
	_draw_core_base()
	_draw_pulse()
	_draw_lanes()   # a runner is coming down this lane
	_draw_strikes()   # the planet's hazard about to land
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
		# no ring any more (Rudy, dev209): the gem itself, a thin dark edge so it still shows on blue
		# worlds, and a little glitter, so it never looks like a round enemy shot
		if g.get("pull", false):
			# flying to the pilot: a short fading streak behind it
			var back: Vector2 = (p - soldier_pos).normalized() * (10.0 + 3.0 * g.tier)
			draw_line(p + back, p, Color(c, 0.0), r * 1.2, true)
			draw_line(p + back * 0.6, p, Color(c, 0.45), r * 0.9, true)
		# Luna's gem, turning slowly (a squeeze across its width) and bobbing
		var gtx: Texture2D = _tex["gem_%d" % int(g.tier)]
		var gs: float = r * 4.2 / maxf(gtx.get_width(), gtx.get_height())
		var spin: float = 0.75 + 0.25 * cos(time_alive * 3.0 + p.x * 0.05)
		draw_set_transform(p + Vector2(0, sin(time_alive * 4.0 + p.x) * 1.2), 0.0, Vector2(gs * spin * 1.18, gs * 1.18))
		draw_texture_rect(gtx, Rect2(-gtx.get_size() * 0.5, gtx.get_size()), false, Color(0, 0, 0, 0.55 * blink))   # dark edge
		draw_set_transform(p + Vector2(0, sin(time_alive * 4.0 + p.x) * 1.2), 0.0, Vector2(gs * spin, gs))
		draw_texture_rect(gtx, Rect2(-gtx.get_size() * 0.5, gtx.get_size()), false, Color(1, 1, 1, blink))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# glitter: two tiny four-point sparkles that wink in turn round the gem
		for si in 2:
			var tw: float = maxf(0.0, sin(time_alive * 3.1 + p.x * 0.21 + si * PI))
			if tw > 0.4:
				var sk: float = (tw - 0.4) / 0.6
				var sp: Vector2 = p + Vector2(r * (1.7 if si == 0 else -1.5), -r * (1.3 if si == 0 else -0.9))
				var sl: float = r * 0.9 * sk
				draw_line(sp - Vector2(sl, 0), sp + Vector2(sl, 0), Color(c.lightened(0.6), 0.9 * sk * blink), 1.0, true)
				draw_line(sp - Vector2(0, sl), sp + Vector2(0, sl), Color(c.lightened(0.6), 0.9 * sk * blink), 1.0, true)
		var gl: float = maxf(0.0, sin(time_alive * 2.2 + p.x * 0.37))
		if gl > 0.85:
			var k: float = (gl - 0.85) / 0.15
			draw_line(p + Vector2(-r * 1.4 * k, -r * 0.6), p + Vector2(r * 1.4 * k, -r * 0.6), Color(1, 1, 1, 0.9 * k * blink), 1.0, true)
			draw_line(p + Vector2(0, -r * 0.6 - r * 1.4 * k), p + Vector2(0, -r * 0.6 + r * 1.4 * k), Color(1, 1, 1, 0.9 * k * blink), 1.0, true)
	_draw_drone()
	_draw_support()
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
		if eb.get("kind", "") == "bossgoo":
			# the Hive Mother's own goo: bigger and brighter than a Spitter's, with a hard white rim (it cannot be shot down)
			var bd: Vector2 = eb.vel.normalized()
			draw_line(eb.pos - bd * 18.0, eb.pos, Color(1.0, 0.35, 0.8, 0.3), 7.0, true)
			draw_circle(eb.pos, 7.5, Color(0.85, 0.2, 0.7, 0.95))
			draw_circle(eb.pos, 3.5, Color(1.0, 0.85, 0.95))
			draw_arc(eb.pos, 8.5 + 1.0 * sin(time_alive * 14.0 + float(eb.ph)), 0.0, TAU, 18, Color(1, 1, 1, 0.75), 1.4, true)
			continue
		if eb.get("kind", "") == "poison":
			# the Hive Mother's poison glob: a big green drop with a bubbling skin and a trail
			var pd: Vector2 = eb.vel.normalized()
			var pw: float = 1.0 + 0.12 * sin(time_alive * 12.0 + float(eb.ph))
			draw_line(eb.pos - pd * 22.0, eb.pos, Color(0.4, 1.0, 0.3, 0.3), 9.0, true)
			draw_circle(eb.pos, 10.0 * pw, Color(0.25, 0.75, 0.2, 0.9))
			draw_circle(eb.pos + Vector2(-2.5, -3.0), 4.0, Color(0.75, 1.0, 0.55, 0.9))
			draw_arc(eb.pos, 12.5 * pw, 0.0, TAU, 20, Color(0.6, 1.0, 0.4, 0.6), 1.5, true)
			continue
		if eb.get("kind", "") == "lava":
			# a Spitfire's lava glob (2026-11-10): a white-hot drop with an orange skin and a short trail
			var ld: Vector2 = eb.vel.normalized()
			draw_line(eb.pos - ld * 16.0, eb.pos, Color(1.0, 0.45, 0.1, 0.35), 6.0, true)
			draw_circle(eb.pos, 6.5 + 0.8 * sin(time_alive * 16.0 + float(eb.ph)), Color(1.0, 0.42, 0.1, 0.85))
			draw_circle(eb.pos + ld * 1.5, 3.4, Color(1.0, 0.92, 0.6))
			continue
		if eb.get("kind", "") == "rivet":
			# a Rivet Gun's rivet (dev198): a short steel dart with a cyan tail, flying straight
			var rd: Vector2 = eb.vel.normalized()
			draw_line(eb.pos - rd * 14.0, eb.pos + rd * 4.0, Color(0.3, 0.9, 1.0, 0.35), 5.0, true)
			draw_line(eb.pos - rd * 10.0, eb.pos + rd * 5.0, Color(0.8, 0.85, 0.9), 2.5, true)
			draw_circle(eb.pos + rd * 5.0, 2.2, Color(0.6, 1.0, 1.0))
			continue
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
	_draw_fire_patches()   # burning patches under the bugs (dev209)
	_draw_poison()
	# enemies
	for e in enemies:
		_draw_enemy(e)
	_draw_shards()
	for r in rings:
		var k: float = 1.0 - r.life / r.max
		draw_arc(r.pos, r.r * k, 0.0, TAU, 20, Color(r.col, (1.0 - k) * 0.7), 2.0, true)
	for s in sparks:
		draw_circle(s.pos, 2.0, Color(s.col, clampf(s.life * 2.5, 0.0, 1.0)))
	for f in (floaters if not picking else []):
		var big: bool = f.get("big", false)
		draw_string(title_font if big else hud_font, f.pos + Vector2(-40 if big else -14, 0), f.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18 if big else 14, Color(f.col, clampf(f.life * 1.5, 0.0, 1.0)))
	_hc.queue_redraw()   # the top bar lives on its own layer above the pilot (_hc)
	_fx.queue_redraw()

func _draw_enemy(e: Dictionary) -> void:
	if e.type == "crate":   # a supply drop
		_draw_crate(e)
		return
	var def: Dictionary = StageData.ENEMIES[e.type]
	if e.type == "spore":
		# spore pod (code-drawn until it has art): a glowing purple seed that pulses
		var pr: float = float(def.size) * 0.5 * (1.0 + 0.08 * sin(e.t * 7.0 + e.ph))
		draw_circle(e.pos, pr * 2.0, Color(0.7, 0.35, 1.0, 0.14))
		draw_circle(e.pos, pr, Color(0.42, 0.16, 0.62))
		draw_circle(e.pos + Vector2(-pr * 0.3, -pr * 0.3), pr * 0.45, Color(0.85, 0.6, 1.0, 0.8))
		return
	if _is_diver(e) and (e.state == "aim" or e.state == "dive") and e.has("target"):
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
	EnemyRig.tint = _status_tint(e)   # icy blue when slowed or frozen, red-orange when burning (dev209)
	var sac_k := -1.0   # the Spitter's sac / the Rivet Gun's pod: fills over the cycle, empties on the shot
	if e.type == "spitter" or e.type == "rivet" or e.type == "spitfire":
		# the sac swells before it spits and settles right after, on smooth ramps
		var every: float = float(def.fire_every)
		var scol := Color(0.3, 0.9, 1.0) if e.type == "rivet" else (Color(1.0, 0.55, 0.15) if e.type == "spitfire" else Color(0.8, 0.4, 1.0))
		sac_k = 1.0 - smoothstep(0.15, every * 0.8, float(e.fire_t))
		var swell: float = maxf(smoothstep(0.8, 0.2, e.fire_t), smoothstep(every - 0.3, every, e.fire_t))
		if swell > 0.01:
			var pulse: float = 0.5 + 0.5 * sin(e.t * 8.0)
			var sac_at: Vector2 = EnemyRig.machine_anchor(String(e.type), "pod", e.pos, size, ang) if EnemyRig.is_machine(String(e.type)) else EnemyRig.anchor("spitter", "sac", e.pos, size, ang)
			draw_circle(sac_at, size * 0.16 * (1.0 + 0.4 * pulse * swell), Color(scol, 0.25 * swell))
		# the spit telegraph (dev168, Archero-style fairness): a third of a second before a
		# glob, the sac flashes and a ring closes on the mouth, so you can see it coming and move
		if float(e.fire_t) < SPIT_WARN and e.pos.y > 40.0:
			var wk: float = 1.0 - float(e.fire_t) / SPIT_WARN
			bright = maxf(bright, 1.0 + 0.7 * (0.5 + 0.5 * sin(e.t * 40.0)))
			var mouth := _muzzle_of(e, size * 1.35, ang)
			draw_arc(mouth, size * (0.6 - 0.4 * wk), 0.0, TAU, 24, Color(scol.lerp(Color(1.0, 0.45, 0.6), 0.5), 0.3 + 0.5 * wk), 2.0)
	if e.type == "hive_mother":
		EnemyRig.draw_hive_mother(self, e.pos, size * (0.68 if e.get("mini", false) else 0.9), time_alive, float(e.laying), e.hp < e.hp_max * 0.5)
		_draw_boss_warn(e, size)
	elif EnemyRig.is_machine(String(e.type)):
		# the Scrap Belt machines from Luna's pieces (dev198); the bosses a little bigger
		var msz: float = size * ((0.68 if e.get("mini", false) else 0.9) if _is_boss(e) else 1.0)
		EnemyRig.draw_machine(self, e.type, e.pos, msz, time_alive, float(e.ph), ang, a, bright, sac_k, float(e.get("ext", 0.0)), float(e.get("laying", 0.0)), float(e.get("stretch_s", 0.0)), e.vel.angle())
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
	EnemyRig.tint = Color.WHITE
	_draw_status(e, size)
	_draw_variant(e, size)
	_draw_runner(e, size)
	_draw_weak(e, size)
	if e.hp < e.hp_max and not _is_boss(e):
		var w := size * 0.9
		draw_rect(Rect2(e.pos.x - w * 0.5, e.pos.y - size * 0.6, w, 3), Color(1, 1, 1, 0.15))
		draw_rect(Rect2(e.pos.x - w * 0.5, e.pos.y - size * 0.6, w * clampf(e.hp / e.hp_max, 0.0, 1.0), 3), Color(1.0, 0.5, 0.4))

# ---- death shards (dev147, AAA motion item 26 e): a killed bug breaks into six pieces of
# its own painted body (regions of the body picture), thrown outward, tumbling under
# gravity and fading. No new art: the pieces are cut from the picture at run time.
const HIT_FLINCH_T := 0.12
const SPIT_WARN := 0.35   # seconds before a Spitter spits: the sac flares and a ring closes on its mouth (dev168: see it coming, move)
const SHARD_LIFE := 0.75
var _shards: Array = []
var _shard_atlas := {}   # enemy type -> [Texture2D]: Luna's chunk pieces (enemies/parts/<bug>_chunk_N.png, dev160), else six cuts of the body

func _spawn_shards(e: Dictionary, def: Dictionary) -> void:
	if not ["scout", "drifter", "spitter", "diver", "mite", "hulk", "rivet", "dart", "queen", "cinder", "crust", "spitfire", "comet", "smelter", "caldera"].has(String(e.type)) or _shards.size() > 90:
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
	# a ceiling on live effects (efficiency pass, 27): the oldest goes first on a crowded screen,
	# and battery saver keeps half as many
	var cap: int = 90 if Perf.lite() else 180
	if fxs.size() >= cap:
		fxs.pop_front()
	fxs.append({"tex": name, "pos": pos, "size": size, "rot": rot, "life": life, "max": life, "grow": grow, "col": col})

# The additive light layer: Luna's shot and hit sprites (painted on black, so they
# only add light), turret charge glows and beams.
func _draw_fx() -> void:
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
	# Sentry tracers: the bright head sits on the bullet, the tail trails behind; a flak shell
	# is the same tracer, short and orange (dev196)
	var tr: Texture2D = _fx_tex["sentry_tracer"]
	for bl in bullets:
		if bl.col != "tracer" and bl.col != "shell":
			continue
		var L: float = 30.0 if bl.col == "tracer" else 20.0
		var th: float = L * tr.get_height() / tr.get_width()
		_fx.draw_set_transform(bl.pos, bl.vel.angle(), Vector2.ONE)
		_fx.draw_texture_rect(tr, Rect2(-L * 0.9, -th * 0.5, L, th), false, Color.WHITE if bl.col == "tracer" else Color(1.0, 0.7, 0.35))
	# the pilot's bolts: Luna's energy bolt, its bright head on the bullet (Heavy Bolts:
	# bigger and brighter)
	var bt0: Texture2D = _fx_tex["bolt"]
	var bw: float = 1.0 + (damage_mult - 1.0) * 1.6
	for bl in bullets:
		if bl.col == "tracer" or bl.col == "purple" or bl.col == "shell":
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
		# (Rudy, dev209: the twisted "DNA" twin and the pill-shaped heavy looked wrong: Heavy Bolts
		# and Burst Fire now draw Luna's own bolt, bigger and hotter, or as two thin parallel bolts)
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
		var btx: Texture2D = PilotRig.tinted(bt0, _bolt_set)
		var heavy: bool = int(card_levels.get("heavy_bolts", 0)) > 0
		if heavy:
			# Heavy Bolts: the same bolt, longer and fatter, with a hot white core on top
			BL *= 1.25
			bth *= 1.35
		if burst_count > 1 and not heavy:
			# Burst Fire: two thin bolts side by side
			for sgn in [-1.0, 1.0]:
				_fx.draw_texture_rect(btx, Rect2(-BL * 0.85, -bth * 0.32 + sgn * bth * 0.3, BL * 0.9, bth * 0.64), false, tint)
			continue
		_fx.draw_texture_rect(btx, Rect2(-BL * 0.85, -bth * 0.5, BL, bth), false, tint)
		if heavy:
			_fx.draw_texture_rect(btx, Rect2(-BL * 0.6, -bth * 0.22, BL * 0.6, bth * 0.44), false, Color(1, 1, 1, 0.8))
	# a boss still arriving is untouchable (_can_hurt): a pulsing veil of light says so (dev164)
	for e in enemies:
		if _is_boss(e) and not e.get("arrived", false):
			var pulse := 0.5 + 0.5 * sin(time_alive * 6.0)
			_fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			Backdrop.soft_glow(_fx, e.pos, float(e.r) * 1.7, Color(0.8, 0.55, 1.0, 0.2 + 0.12 * pulse))
	_fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _fx_sprite(name: String, pos: Vector2, size: float, alpha: float) -> void:
	var tex: Texture2D = _fx_tex[name]
	var h: float = size * tex.get_height() / tex.get_width()
	_fx.draw_set_transform(pos, 0.0, Vector2.ONE)
	_fx.draw_texture_rect(tex, Rect2(-size * 0.5, -h * 0.5, size, h), false, Color(1, 1, 1, alpha))

# Top bar layout (drawn by _draw_hud on the _hc layer)
const HUD_H := 70.0                  # bar height (the XP bar runs along its bottom)
const PAUSE_RECT := Rect2(FIELD_W - 52, 10, 38, 36)
const SPEED_RECT := Rect2(FIELD_W - 98, 10, 38, 36)
const CARDS_RECT := Rect2(FIELD_W - 144, 10, 38, 36)

# A small glass button on the top bar (lit cyan while its panel is open / active).
func _hud_frame(p: Rect2, active: bool) -> void:
	var sb := UIKit.pill(Color(0.07, 0.2, 0.3, 0.92) if active else Color(0.055, 0.09, 0.157, 0.86), 12, Vector2.ZERO)
	if active:
		sb.border_color = Color(0.31, 0.88, 1.0, 0.9)
		sb.set_border_width_all(1)
	_hc.draw_style_box(sb, p)

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
	# the clean top bar (2026-11-10, the battle's style pass): no frame, a soft shade that fades into
	# the sky, the stage big on the left, three roomy buttons on the right, then one quiet row: wave
	# pips, the score, the HP bar. Nothing touches the screen edge (Rudy, dev209).
	var navy := Color(0.027, 0.047, 0.094)
	_hc.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(FIELD_W, 0), Vector2(FIELD_W, HUD_H + 16.0), Vector2(0, HUD_H + 16.0)]),
		PackedColorArray([Color(navy, 0.9), Color(navy, 0.9), Color(navy, 0.0), Color(navy, 0.0)]))
	# row 1: stage number (white) and name (cyan), then the run time
	# the stage title and the clock are built once per change, not per frame (efficiency pass, 27)
	var hud_key: int = (wave_index if horde else 0) * 1000 + stage   # rebuilt on a new stage too (Next stage keeps the scene)
	if _hud_title == "" or _hud_title_key != hud_key:
		_hud_title_key = hud_key
		_hud_num = "%d " % stage
		_hud_nx = 16.0 + title_font.get_string_size(_hud_num, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		_hud_title = (("TRIAL · " + String(Promotion.RANKS[promo].name)) if promo >= 0 else (("%s TRIAL %d" % [Heroes.element_name(String(etrial.el)), int(etrial.step) + 1]) if not etrial.is_empty() else (("HORDE · WAVE %d" % (wave_index + 1)) if horde else ("DAILY CHALLENGE" if daily else (String(Events.theme().name) if event_run else (("EXPEDITION · " + String(Runs.KINDS[_run_kind()].name)) if run_mode else StageData.stage_name(stage))))))).to_upper()
		if boss_rush:
			_hud_title = "BOSS RUSH"
	_hc.draw_string(title_font, Vector2(16, 34), _hud_num, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	_hc.draw_string(title_font, Vector2(_hud_nx, 33), _hud_title, HORIZONTAL_ALIGNMENT_LEFT, CARDS_RECT.position.x - 64.0 - _hud_nx, 13, UIKit.GOLD if _is_trial() else (Color(1.0, 0.6, 0.3) if horde else cyan))
	var whole_s := int(time_alive)
	if whole_s != _hud_clock_s:
		_hud_clock_s = whole_s
		_hud_clock = "%02d:%02d" % [whole_s / 60, whole_s % 60]
	_hc.draw_string(hud_font, Vector2(CARDS_RECT.position.x - 90, 33), _hud_clock, HORIZONTAL_ALIGNMENT_RIGHT, 80, 13, muted)
	if Perf.show_fps:   # Settings > frame counter
		_hc.draw_string(hud_font, Vector2(18, HUD_H + 34), "%d fps" % Engine.get_frames_per_second(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(muted, 0.8))
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
	_hc.draw_string(title_font, SPEED_RECT.position + Vector2(0, 23), "x%s" % (str(game_speed) if game_speed != 1.0 else "1"), HORIZONTAL_ALIGNMENT_CENTER, SPEED_RECT.size.x, 13, Color.WHITE if _speeds().size() > 1 else Color(1, 1, 1, 0.5))
	# pause button: two bars (a play arrow while paused)
	var p := PAUSE_RECT
	_hud_frame(p, paused)
	var pc := p.get_center()
	if paused:
		_hc.draw_colored_polygon(PackedVector2Array([pc + Vector2(-5, -8), pc + Vector2(8, 0), pc + Vector2(-5, 8)]), Color.WHITE)
	else:
		_hc.draw_style_box(UIKit.pill(Color.WHITE, 2, Vector2.ZERO), Rect2(pc + Vector2(-6.5, -8), Vector2(4, 16)))
		_hc.draw_style_box(UIKit.pill(Color.WHITE, 2, Vector2.ZERO), Rect2(pc + Vector2(2.5, -8), Vector2(4, 16)))
	# row 2: waves as pips (a count when there are many), the score, the HP bar
	var y2 := 60.0
	var wave_now := mini(wave_index + 1, waves.size())
	var wx := 17.0
	if waves.size() <= 10:
		for i in waves.size():
			var pr := Rect2(wx + i * 13.0, y2 - 8.0, 9.0, 5.0)
			_hc.draw_style_box(UIKit.pill(Color.WHITE if i == wave_now - 1 else (Color(cyan, 0.85) if i < wave_now - 1 else Color(1, 1, 1, 0.16)), 2, Vector2.ZERO), pr)
		wx += waves.size() * 13.0 + 10.0
	else:
		_hc.draw_string(hud_font, Vector2(wx, y2), "WAVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, muted)
		_hc.draw_string(title_font, Vector2(wx + 38.0, y2), "%d/%d" % [wave_now, waves.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
		wx += 96.0
	_hc.draw_string(title_font, Vector2(wx + 6.0, y2), str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, muted)
	# the pilot's HP bar (dev172: HP instead of hearts): a red pill with the number in it, at the right
	var bar := Rect2(FIELD_W - 174.0, y2 - 11.0, 160.0, 12.0)
	var heart: Texture2D = _tex["ui_heart"]
	_hc.draw_texture_rect(heart, Rect2(bar.position.x - 20.0, y2 - 13.0, 15.0, 15.0 * heart.get_height() / heart.get_width()), false)
	_hc.draw_style_box(UIKit.pill(Color(0.16, 0.05, 0.08, 0.9), 6, Vector2.ZERO), bar)
	var hk := clampf(pilot_hp / maxf(pilot_hp_max, 1.0), 0.0, 1.0)
	if hk > 0.0:
		_hc.draw_style_box(UIKit.pill(Color(1.0, 0.35, 0.42) if hk > 0.3 else Color(1.0, 0.2, 0.25), 6, Vector2.ZERO), Rect2(bar.position, Vector2(maxf(bar.size.x * hk, 12.0), bar.size.y)))
	_hc.draw_string(title_font, Vector2(bar.position.x, y2 - 1.0), "%d / %d" % [ceili(pilot_hp), roundi(pilot_hp_max)], HORIZONTAL_ALIGNMENT_CENTER, int(bar.size.x), 10, Color.WHITE)
	# a trial's advantages and disadvantages, announced under the bar for the first seconds
	if not _mods.is_empty() and time_alive > 3.5 and time_alive < 11.0:   # after the objectives box has gone
		var ma: float = clampf(11.0 - time_alive, 0.0, 1.0) * clampf((time_alive - 3.5) * 2.0, 0.0, 1.0)
		var my := HUD_H + 64.0
		for m in _mods:   # Luna's twist icon beside each line; green good, red bad (dev189)
			if not Promotion.MODS.has(m):
				continue
			var txt := "%s: %s" % [String(Promotion.MODS[m].name).to_upper(), Promotion.MODS[m].text]
			var ico: Texture2D = _tex.get("tw_" + String(m))
			var tw: float = hud_font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
			var x0: float = FIELD_W * 0.5 - (tw + (22.0 if ico else 0.0)) * 0.5
			if ico:
				_hc.draw_texture_rect(ico, Rect2(x0, my - 14.0, 18.0, 18.0), false, Color(1, 1, 1, ma))
				x0 += 22.0
			_hc.draw_string(hud_font, Vector2(x0, my), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(Promotion.GOOD_COL if Promotion.MODS[m].good else Promotion.BAD_COL, ma))
			my += 18.0
	# run XP: a thin pill under the bar, filled cyan to purple, the run level on a chip
	var need := _xp_need()
	var xp := clampf(run_xp / need, 0.0, 1.0)
	var track := Rect2(70, HUD_H + 7, FIELD_W - 84, 5)
	_hc.draw_style_box(UIKit.pill(Color(0.1, 0.153, 0.25, 0.9), 3, Vector2.ZERO), track)
	if xp > 0.02:
		var fr := Rect2(track.position, Vector2(track.size.x * xp, track.size.y))
		var pts := Glass.box(fr, 2.5).slice(0, -1)
		var cols := PackedColorArray()
		for q in pts:
			cols.append(Glass.CYAN.lerp(Glass.PURPLE, clampf((q.x - track.position.x) / track.size.x, 0.0, 1.0)))
		_hc.draw_polygon(pts, cols)
	var chip := Rect2(14, HUD_H, 48, 19)
	_hc.draw_style_box(UIKit.pill(Color(0.094, 0.145, 0.239, 0.95), 9, Vector2.ZERO), chip)
	_hc.draw_string(title_font, Vector2(chip.position.x, chip.position.y + 14), "LV %d" % run_level, HORIZONTAL_ALIGNMENT_CENTER, chip.size.x, 11, Color(0.9, 0.84, 1.0))
	_draw_card_row(Vector2(14.0, HUD_H + 24.0))   # its own row under the XP bar
	_draw_auto_btn()
	_draw_ult_btn()
	_draw_wing_chip()
	_draw_streak()
	_draw_move_tip()
	for e in enemies:
		if _is_boss(e):
			_draw_boss_bar(e)
	_draw_objectives_banner()
	_draw_intro()

# A boss's health in stacked layers (8 for a boss, 5 for a mini-boss): the bar empties
# one colour at a time, the next colour shows underneath, "x3" counts what is left,
# a white chunk trails each hit and the bar flashes when a layer breaks.
const BOSS_LAYER_COLS := [Color(0.95, 0.30, 0.40), Color(1.0, 0.55, 0.25), Color(1.0, 0.85, 0.3), Color(0.45, 0.9, 0.5),
	Color(0.3, 0.85, 1.0), Color(0.35, 0.5, 1.0), Color(0.80, 0.40, 1.0), Color(1.0, 0.45, 0.75)]

func _boss_layers(e: Dictionary) -> int:
	return 5 if e.get("mini", false) else 8   # was 3 / 5 (dev209: bosses last longer)

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
	var by := HUD_H + 56.0 - 8.0 * (1.0 - a)
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
	var bname: String = String(StageData.ENEMIES[e.type].get("name", String(e.type).replace("_", " "))).to_upper()
	if e.get("mini", false) and e.type != "wrecker" and e.type != "smelter":
		bname = "YOUNG " + bname   # a mid-stage or zone-A young boss (the Wrecker is its own thing)
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
	var vv: String = String(_intro.get("variant", ""))
	var edge: Color = VARIANTS[vv].col if vv != "" else Color(1.0, 0.55, 0.35)
	_hc.draw_polyline(frame, Color(edge, 0.8 * a), 1.2, true)
	# the bug itself, small, on the left
	var icon := r.position + Vector2(38.0, 37.0)
	if id == "hive_mother":
		EnemyRig.draw_hive_mother(_hc, icon, 26.0, time_alive, 0.0, false)
	elif EnemyRig.is_machine(id):
		EnemyRig.draw_machine(_hc, id, icon, 26.0 if _is_boss_id(id) else 46.0, time_alive, 0.0, 0.0, a)
	else:
		EnemyRig.draw_bug(_hc, id, icon, 46.0, time_alive, 0.0, 0.0, 0.0, 1.0, a)
	var head := "NEW VARIANT" if vv != "" else "NEW ENEMY"
	var title := (String(VARIANTS[vv].name).capitalize() + " " + id.replace("_", " ").capitalize()) if vv != "" else id.replace("_", " ").capitalize()
	var body := String(VARIANTS[vv].desc) if vv != "" else String(StageData.ENEMIES[id].intro)
	_hc.draw_string(title_font, r.position + Vector2(76.0, 20.0), head, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(edge.lightened(0.2), a))
	_hc.draw_string(hud_font, r.position + Vector2(76.0, 38.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, a))
	_hc.draw_multiline_string(hud_font, r.position + Vector2(76.0, 54.0), body, HORIZONTAL_ALIGNMENT_LEFT, 236.0, 11, 2, Color(0.75, 0.82, 0.92, a))

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
	# the commander on the line (Luna's portrait, dev198): urgent on the first planet and the
	# Scrap Belt, calm after
	var who := "res://ui/commander_%s.png" % ("urgent" if ai <= 1 else "calm")
	if ResourceLoader.exists(who):
		var face := TextureRect.new()
		face.texture = load(who)
		face.custom_minimum_size = Vector2(0, 110)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		v.add_child(face)
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
	if _is_boss(e):
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
	return StageData.hp_mult(stage, false) * (StageData.elite_mult(wave_index) if elite else 1.0) * (Promotion.hp_mult(promo) if promo >= 0 else 1.0) * (Promotion.etrial_hp(int(etrial.step)) if not etrial.is_empty() else 1.0) * (1.25 if _mods.has("thick_shells") else 1.0) * (Promotion.DAILY_HP if daily else 1.0) * (BossRush.RUSH_HP * (1.0 + BossRush.RUSH_STEP * wave_index) if boss_rush else 1.0) * (Events.EVENT_HP if event_run else 1.0) * (Runs.ELITE_HP if run_mode and _run_kind() == "elite" else 1.0) * (Runs.step_hp(_run) if run_mode else 1.0) * _no_turret_hp() * _tough() * ((1.0 + HORDE_HP_PER_WAVE * wave_index) if horde else 1.0)

# HORDE (Rudy's Modes card, dev172): endless waves built from your best Standard stage's wave
# list, cycling through it with more bugs each lap and bug health up HORDE_HP_PER_WAVE a wave; a
# boss every 10th wave. The run ends when you fall; the score is the wave count.
const HORDE_HP_PER_WAVE := 0.04
const BOSS_WALL := 1.5   # the planet boss (stage 10, 20, ...): a soft wall (16 g, dev198)
const BOSS_HP := 3.4   # was 2.5 until the visible weak point (WEAK_MULT 2.5, open about a third of the time, Rudy 2026-11-10: "then they need more health so you do not eat through them")    # every boss (dev209); a mini-boss keeps MINI_HP of that (2.5 x 0.48 = 1.2, twice the old 0.6)
const MINI_HP := 0.48
const WRECKER_HOLD_MAX := 6.0   # the Wrecker lets a turret go after this long whatever happens
func _horde_wave(k: int) -> Array:
	var src: Array = StageData.waves(stage)
	var body: Array = []
	for w in src:
		var has_boss := false
		for spec in w:
			if StageData.is_boss(String(spec[0])):
				has_boss = true
		if not has_boss:
			body.append(w)
	if body.is_empty():
		body = src
	var base: Array = body[k % body.size()]
	var lap := k / body.size()
	var out: Array = []
	for spec in base:
		out.append([spec[0], int(ceil(int(spec[1]) * (1.0 + 0.15 * lap)))])
	if k > 0 and (k + 1) % 10 == 0:
		out.append([StageData.boss_id(stage, false) if (k + 1) % 20 == 0 else "hive_mother", 1])   # the planet's boss every other time
	return out

# a rank trial or an element trial: no stars, no stage unlocks, no drops; the trial pays
func _is_trial() -> bool:
	return promo >= 0 or not etrial.is_empty() or daily or event_run or run_mode or boss_rush

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
	return not _is_boss(e) or bool(e.get("arrived", false))

# ---- ENEMY VARIANTS (queue item 17 a, dev172): the same bugs with a twist, mixed in by stage ----
# armoured: a plated shell, nearly double health, slower (trait "armoured": the Lance eats it)
# shielded: a bubble that stops bolts and beams until it breaks (trait "shielded": the Storm)
# booster:  a SUPPORT bug: bugs near it move faster and spit sooner; kill it first (orange aura)
# healer:   a SUPPORT bug: heals bugs near it; kill it first (green aura)
# One roll per bug: the chance rises with the stage, each variant from its own stage on.
const VARIANTS := {
	"armoured": {"from": 6,  "name": "ARMOURED", "col": Color(0.75, 0.78, 0.85), "desc": "Steel bands soak the hits and break off as it weakens."},
	"shielded": {"from": 11, "name": "SHIELDED", "col": Color(0.4, 0.9, 1.0), "desc": "An energy shell takes the hits until it breaks."},
	"booster":  {"from": 16, "name": "BOOSTER",  "col": Color(1.0, 0.6, 0.2), "desc": "Speeds up the bugs around it."},
	"healer":   {"from": 21, "name": "HEALER",   "col": Color(0.4, 1.0, 0.5), "desc": "Mends the bugs around it."},
}
const AURA_R := 120.0
var _variants_seen := {}   # variant -> true once its card showed this run

func _roll_variant(e: Dictionary) -> void:
	if not ["scout", "drifter", "spitter", "diver", "mite", "hulk", "rivet", "dart", "cinder", "crust", "spitfire", "comet"].has(String(e.type)) or e.has("hatchling"):
		return
	var pool: Array = []
	for v in VARIANTS:
		if stage >= int(VARIANTS[v].from):
			pool.append(v)
	if pool.is_empty():
		return
	var p: float = clampf(0.06 + 0.006 * (stage - 5), 0.06, 0.32)
	if rng.randf() > p:
		return
	var v: String = pool[rng.randi() % pool.size()]
	e.variant = v
	match v:
		"armoured":
			e.hp *= 1.9
			e.hp_max *= 1.9
			e.speed = float(e.speed) * 0.85
			e.r = float(e.r) * 1.1
		"shielded":
			e.shield_hp = 0.7 * float(e.hp_max)
			e.shield_max = e.shield_hp
		"booster", "healer":
			e.hp *= 0.85
			e.hp_max *= 0.85
	_meet_variant(v, String(e.type))

# the bug's traits: its kind's plus its variant's (turret "strong vs" bonuses)
func _traits(e: Dictionary) -> Array:
	var t: Array = Array(StageData.ENEMIES[e.type].traits).duplicate()
	match String(e.get("variant", "")):
		"armoured": t.append("armoured")
		"shielded": t.append("shielded")
		"booster", "healer": t.append("support")
	return t

# a shielded bug's bubble takes the hit first; returns what gets through
func _through_shield(e: Dictionary, dmg: float) -> float:
	var sh: float = float(e.get("shield_hp", 0.0))
	if sh <= 0.0:
		return dmg
	e.shield_hp = sh - dmg
	if float(e.shield_hp) <= 0.0:
		_fx_add("nova", e.pos, float(e.r) * 2.6, 0.3, 0.0, 1.8, Color(0.4, 0.9, 1.0))
		Sfx.play("shield")
		return -float(e.shield_hp)
	_fx_add("impact", e.pos + Vector2(0, -float(e.r) * 0.6), 20.0, 0.15, rng.randf() * TAU, 1.4, Color(0.5, 0.95, 1.0))
	return 0.0

# support bugs: boosters speed up and healers patch every bug in their aura (each frame)
func _update_auras(delta: float) -> void:
	for e in enemies:
		var v := String(e.get("variant", ""))
		if v != "booster" and v != "healer":
			continue
		for o in enemies:
			if o == e or o.pos.distance_to(e.pos) > AURA_R:
				continue
			if v == "booster":
				o.boost_t = 0.25
			elif o.hp < o.hp_max and not _is_boss(o):
				o.hp = minf(float(o.hp) + 0.04 * float(o.hp_max) * delta, float(o.hp_max))
				if rng.randf() < delta * 1.5:
					zaps.append({"a": e.pos, "b": o.pos, "life": 0.18, "seed": rng.randf() * 100.0, "col": Color(0.4, 1.0, 0.5)})

func _draw_variant(e: Dictionary, size: float) -> void:
	# each variant shows ON the bug, not as a ring round it (Rudy, dev209 playtest)
	var v := String(e.get("variant", ""))
	if v == "":
		return
	var col: Color = VARIANTS[v].col
	var ang: float = float(e.get("tilt_s", 0.0))
	match v:
		"armoured":
			# curved steel bands across its back, like an armadillo shell (the bug is drawn head
			# down, so the bands lie across the picture); one falls off per third of its health,
			# and the last cracks before it goes
			var k: float = clampf(float(e.hp) / maxf(float(e.hp_max), 1.0), 0.0, 1.0)
			var plates: int = ceili(k * 3.0 - 0.001)
			var bw: float = size * 0.27
			var bh: float = size * 0.085
			draw_set_transform(e.pos, ang, Vector2.ONE)
			for i in plates:
				var y: float = (float(i) - 1.0) * size * 0.15 - size * 0.04
				var top := PackedVector2Array()
				var bot := PackedVector2Array()
				for j in 9:
					var u: float = float(j) / 8.0 * 2.0 - 1.0
					var bulge: float = (1.0 - u * u) * size * 0.05
					top.append(Vector2(u * bw, y - bh * 0.5 - bulge))
					bot.append(Vector2(u * bw * 0.92, y + bh * 0.5 - bulge * 0.6))
				var poly := PackedVector2Array(top)
				for j in range(bot.size() - 1, -1, -1):
					poly.append(bot[j])
				draw_colored_polygon(poly, Color(0.34, 0.37, 0.44, 0.95))
				draw_polyline(top, Color(0.85, 0.89, 0.96, 0.85), 1.4, true)    # the top edge catches the light
				draw_polyline(bot, Color(0.1, 0.11, 0.14, 0.9), 1.0, true)      # its shadow edge
				draw_circle(top[0].lerp(bot[0], 0.5), 1.3, Color(0.8, 0.84, 0.92))
				draw_circle(top[8].lerp(bot[8], 0.5), 1.3, Color(0.8, 0.84, 0.92))
				if i == plates - 1 and fmod(k * 3.0, 1.0) > 0.0 and fmod(k * 3.0, 1.0) < 0.5:
					draw_polyline(PackedVector2Array([Vector2(-bw * 0.4, y - bh * 0.5), Vector2(-bw * 0.1, y + bh * 0.1), Vector2(bw * 0.15, y - bh * 0.3), Vector2(bw * 0.35, y + bh * 0.5)]), Color(0.05, 0.05, 0.07, 0.95), 1.2, true)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			var was: int = int(e.get("plates", 3))
			if plates < was:
				e.plates = plates
				_burst(e.pos, size * 0.3, Color(0.75, 0.8, 0.9), 6)   # a band breaks off
		"shielded":
			var sh: float = float(e.get("shield_hp", 0.0))
			if sh > 0.0:
				# an energy shell with a hex pattern and a bright rim along its top
				var k: float = sh / maxf(float(e.get("shield_max", 1.0)), 1.0)
				var r := size * 0.72
				var flick: float = 0.85 + 0.15 * sin(time_alive * 9.0 + float(e.ph))
				draw_circle(e.pos, r, Color(col, (0.06 + 0.06 * k) * flick))
				for i in 7:
					var hc: Vector2 = e.pos if i == 0 else e.pos + Vector2.from_angle(float(i) * TAU / 6.0 + 0.5) * r * 0.52
					var hp := PackedVector2Array()
					for j in 7:
						hp.append(hc + Vector2.from_angle(float(j) * TAU / 6.0) * r * 0.25)
					draw_polyline(hp, Color(col, (0.12 + 0.2 * k) * flick), 1.0, true)
				draw_arc(e.pos, r, 0.0, TAU, 40, Color(col, (0.3 + 0.35 * k) * flick), 1.4, true)
				draw_arc(e.pos, r, PI * 1.12, PI * 1.88, 16, Color(col.lightened(0.5), 0.6 * k + 0.2), 2.4, true)
		"booster":
			# orange speed chevrons above it, and links to the bugs it is speeding up
			for i in 3:
				var cy: float = e.pos.y - size * 0.55 - float(i) * 6.0 - fmod(time_alive * 18.0, 6.0)
				var ca: float = 0.85 - 0.25 * float(i)
				draw_polyline(PackedVector2Array([Vector2(e.pos.x - 6, cy + 4), Vector2(e.pos.x, cy - 1), Vector2(e.pos.x + 6, cy + 4)]), Color(col, ca), 2.0, true)
			for o in enemies:
				if o != e and float(o.get("boost_t", 0.0)) > 0.0 and o.pos.distance_to(e.pos) <= AURA_R:
					draw_line(e.pos, o.pos, Color(col, 0.35), 1.0, true)
		"healer":
			# a green cross above it that breathes (its green zaps show who it mends)
			var pulse: float = 0.5 + 0.5 * sin(time_alive * 4.0)
			var cc := Vector2(e.pos.x, e.pos.y - size * 0.6)
			var arm: float = 5.0 + 1.5 * pulse
			draw_rect(Rect2(cc.x - arm, cc.y - 2.0, arm * 2.0, 4.0), Color(col, 0.75 + 0.25 * pulse))
			draw_rect(Rect2(cc.x - 2.0, cc.y - arm, 4.0, arm * 2.0), Color(col, 0.75 + 0.25 * pulse))
	# the shield bar over the health bar
	if v == "shielded" and float(e.get("shield_hp", 0.0)) > 0.0:
		var w := size * 0.9
		draw_rect(Rect2(e.pos.x - w * 0.5, e.pos.y - size * 0.6 - 5.0, w * clampf(float(e.shield_hp) / float(e.shield_max), 0.0, 1.0), 3), Color(0.4, 0.9, 1.0))

# ---- status effects that SHOW on the bug (Rudy, dev209 playtest) ----
# Ice: the bug turns icy blue as it slows, frost crystals sit on it, and a frozen bug is an
# ice block. Fire: it glows red-orange and flames lick up off it. Burning patches flicker
# where a burning bug died (Afterburn overcharged).

func _status_tint(e: Dictionary) -> Color:
	var t := Color.WHITE
	if float(e.get("freeze_t", 0.0)) > 0.0:
		t = Color(0.62, 0.88, 1.35)
	elif float(e.get("slow_t", 0.0)) > 0.0:
		var k: float = clampf(float(e.get("slow", 0.0)) / 0.45, 0.35, 1.0)
		t = t.lerp(Color(0.62, 0.86, 1.25), k)
	if float(e.get("burn_t", 0.0)) > 0.0:
		var f: float = 0.88 + 0.12 * sin(time_alive * 18.0 + float(e.ph))
		t = Color(t.r * 1.28 * f, t.g * 0.8, t.b * 0.6)
	if String(e.get("variant", "")) == "armoured":
		t = Color(t.r * 0.74, t.g * 0.78, t.b * 0.88)   # a steel cast under its plates
	return t

func _draw_status(e: Dictionary, size: float) -> void:
	var frozen: bool = float(e.get("freeze_t", 0.0)) > 0.0
	var slowed: bool = float(e.get("slow_t", 0.0)) > 0.0
	if frozen or slowed:
		# frost crystals round the body: a few while slowed, a full crust when frozen
		var n: int = 8 if frozen else (2 + int(clampf(float(e.get("slow", 0.0)) / 0.15, 1.0, 3.0)))
		var ph: float = float(e.ph) * 7.0
		for i in n:
			var a: float = ph + float(i) * TAU / float(n)
			var dir := Vector2.from_angle(a)
			var at: Vector2 = e.pos + dir * size * (0.3 if frozen else 0.34)
			var ln: float = size * (0.2 if frozen else 0.13) * (0.8 + 0.4 * fmod(float(i) * 0.37 + ph, 1.0))
			var side := dir.orthogonal() * ln * 0.32
			var pts := PackedVector2Array([at - dir * ln * 0.25, at + side, at + dir * ln, at - side])
			draw_colored_polygon(pts, Color(0.86, 0.96, 1.0, 0.8 if frozen else 0.65))
			draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color(0.45, 0.75, 1.0, 0.8), 1.0, true)
		if frozen:
			# the ice block: a pale shell over the body with a glint across it
			draw_circle(e.pos, size * 0.44, Color(0.72, 0.9, 1.0, 0.22))
			draw_arc(e.pos, size * 0.44, 0.0, TAU, 28, Color(0.85, 0.96, 1.0, 0.55), 1.5, true)
			draw_line(e.pos + Vector2(-size * 0.2, -size * 0.26), e.pos + Vector2(size * 0.04, -size * 0.34), Color(1, 1, 1, 0.7), 2.0, true)
	if float(e.get("burn_t", 0.0)) > 0.0:
		# flames licking up off the bug: four tongues that flicker and sway
		for i in 4:
			var a: float = PI + float(i) * PI / 3.0 + 0.3 * sin(float(e.ph) + float(i))
			var base: Vector2 = e.pos + Vector2(cos(a) * size * 0.3, sin(a) * size * 0.16 - size * 0.02)
			var h: float = size * (0.24 + 0.1 * sin(time_alive * 14.0 + float(i) * 2.1 + float(e.ph)))
			_flame(base, h, size * 0.09, sin(time_alive * 9.0 + float(i)) * size * 0.05, 1.0)

# one flame tongue: a teardrop rising from `base`, orange outside, yellow inside
func _flame(base: Vector2, h: float, w: float, sway: float, a: float) -> void:
	var tip: Vector2 = base + Vector2(sway, -h)
	var outer := PackedVector2Array([base + Vector2(-w, 0), base + Vector2(-w * 0.6, -h * 0.45) + Vector2(sway * 0.4, 0), tip,
		base + Vector2(w * 0.6, -h * 0.45) + Vector2(sway * 0.4, 0), base + Vector2(w, 0), base + Vector2(0, w * 0.7)])
	draw_colored_polygon(outer, Color(1.0, 0.42, 0.1, 0.75 * a))
	var ih: float = h * 0.55
	var itip: Vector2 = base + Vector2(sway * 0.6, -ih)
	var inner := PackedVector2Array([base + Vector2(-w * 0.5, 0), itip, base + Vector2(w * 0.5, 0), base + Vector2(0, w * 0.4)])
	draw_colored_polygon(inner, Color(1.0, 0.88, 0.35, 0.85 * a))

func _update_fire_patches(delta: float) -> void:
	if _fire_patches.is_empty():
		return
	var live: Array = []
	for fp in _fire_patches:
		fp.life = float(fp.life) - delta
		if float(fp.life) <= 0.0:
			continue
		for o in enemies:
			if o.type != "spore" and o.pos.distance_to(fp.pos) < float(fp.r):
				o.burn_t = maxf(float(o.get("burn_t", 0.0)), 1.2)
				o.burn_dps = 0.05 * float(o.hp_max)
		live.append(fp)
	_fire_patches = live

func _draw_fire_patches() -> void:
	for fp in _fire_patches:
		var k: float = clampf(float(fp.life) / float(fp.max), 0.0, 1.0)
		var a: float = minf(1.0, k * 3.0)
		var c: Vector2 = fp.pos
		var r: float = float(fp.r)
		draw_set_transform(c, 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, r, Color(1.0, 0.35, 0.08, 0.16 * a))
		draw_circle(Vector2.ZERO, r * 0.6, Color(1.0, 0.6, 0.15, 0.18 * a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# flames of uneven size, scattered over the patch, each on its own flicker (not a tidy row)
		for i in 6:
			var u: float = fmod(float(i) * 0.618 + float(fp.ph), 1.0)
			var x: float = (u * 2.0 - 1.0) * r * 0.75
			var y: float = sin(float(i) * 2.3 + float(fp.ph)) * r * 0.16
			var h: float = r * (0.18 + 0.28 * fmod(float(i) * 0.41 + float(fp.ph), 1.0) + 0.12 * sin(time_alive * (9.0 + float(i)) + float(i) * 1.7)) * a
			_flame(c + Vector2(x, y), h, r * (0.08 + 0.06 * u), sin(time_alive * 6.0 + float(i) * 1.3) * 4.0, a * (0.7 + 0.3 * u))

# ASCEND (Epic and up): the run starts with the hero's own card at level 1, as if it were the
# first pick (it shows on the HUD card row and its next levels come up in the picks as usual)
func _start_hero_card() -> void:
	var id := Cards.hero_card(_hero_id)
	if id == "" or int(card_levels.get(id, 0)) > 0:
		return
	card_levels[id] = 1
	match id:
		"rook_twin": _twin_every = 4
		"sparks_weld": _weld_count += 1
		"frost_freeze": _freeze_level += 1
		"hollow_phase": pierce_level += 1
		"nyx_mark": _crit_rate += 0.10
		"ember_burn": _burn_level += 1

# ------------------------------------------------------------------ RUNNERS + the wave patch (2026-11-10)
# The sweep in REVIEW-2026-11-10.md: bug health alone is a knife edge (untouched, or a wall). So
# pressure comes from something to CHASE instead. A RUNNER is a small bug that streaks straight down
# one lane for the base. A gold lane lights up a second before it comes, so there is time to get
# under it. Caught: a burst of coins and gem XP. Missed: it chips the shield (RUNNER_DMG, small on
# purpose). To keep those chips from adding up to a lost stage, every cleared wave patches the
# shield a little (WAVE_PATCH).
const RUNNER_FROM := 3          # first stage with runners
const RUNNER_WARN := 1.1        # seconds the lane shows before the runner
const RUNNER_SPEED := 165.0
const RUNNER_HP := 2.4          # stage-1 health (a Scout has 1.6)
const RUNNER_DMG := 6.0
const WAVE_PATCH := 0.06        # share of the shield mended after each wave
var _runner_due: Array = []     # seconds from now, one per runner still to come this wave
var _lanes: Array = []          # {x, t}: lanes lit, counting down to the runner

func _runners_for(stage_n: int, wave_n: int) -> int:
	if stage_n < RUNNER_FROM or wave_n < 1:
		return 0
	return 1 + (1 if stage_n >= 11 else 0) + (1 if stage_n >= 31 and wave_n >= 3 else 0)

func _plan_runners() -> void:
	_runner_due.clear()
	for i in _runners_for(stage, wave_index):
		_runner_due.append(rng.randf_range(3.0, 7.0) + 5.0 * i)

func _update_runners(delta: float) -> void:
	for i in _runner_due.size():
		_runner_due[i] = float(_runner_due[i]) - delta
	while not _runner_due.is_empty() and float(_runner_due[0]) <= 0.0:
		_runner_due.pop_front()
		if wave_queue.is_empty() and enemies.is_empty():
			continue   # the wave is over: no straggler holds it open
		_lanes.append({"x": rng.randf_range(50.0, FIELD_W - 50.0), "t": RUNNER_WARN * _warn_mult})
		Sfx.play("spit", 1.5)
		if not _seen.has("runner"):   # the first one ever: say what the lane means
			_seen.append("runner")
			_write_save({"seen_enemies": _seen})
			_float_text(Vector2(FIELD_W * 0.5, FIELD_H * 0.3), "RUNNER! Catch it in its lane", Color(1.0, 0.85, 0.4), true)
	var keep: Array = []
	for l in _lanes:
		l.t = float(l.t) - delta
		if float(l.t) > 0.0:
			keep.append(l)
			continue
		var kind: String = "mite" if stage >= 11 and rng.randf() < StageData.machine_share(stage) else "scout"
		if stage >= 21 and rng.randf() < StageData.magma_share(stage):
			kind = "cinder"   # on the Magma World the runners are Cinder Flies as often as not
		var e := _make_enemy(kind, Vector2(float(l.x), 30.0))
		e.erase("variant")
		e.runner = true
		e.hp = RUNNER_HP * _hp_mult()
		e.hp_max = e.hp
		e.speed = RUNNER_SPEED
		e.shield_hp = 0.0
		enemies.append(e)
	_lanes = keep

# the lane (under the bugs): a faint gold strip, dashes running down it, chevrons at the top
func _draw_lanes() -> void:
	for l in _lanes:
		var k: float = 1.0 - float(l.t) / (RUNNER_WARN * _warn_mult)
		var x: float = float(l.x)
		var gold := Color(1.0, 0.82, 0.3)
		draw_rect(Rect2(x - 15.0, HUD_H, 30.0, BASE_Y - 150.0 - HUD_H), Color(gold, 0.05 + 0.06 * k))
		var off: float = fmod(time_alive * 260.0, 36.0)
		var y: float = HUD_H + off
		while y < BASE_Y - 160.0:
			draw_line(Vector2(x, y), Vector2(x, y + 14.0), Color(gold, 0.3 + 0.4 * k), 2.0)
			y += 36.0
		for c in 2:
			var cy: float = HUD_H + 26.0 + c * 12.0 + sin(time_alive * 10.0) * 2.0
			draw_polyline(PackedVector2Array([Vector2(x - 9.0, cy - 6.0), Vector2(x, cy + 3.0), Vector2(x + 9.0, cy - 6.0)]), Color(gold, 0.9), 2.5, true)

# on the bug: gold streaks trailing behind it (it is moving down the screen, so they trail up)
func _draw_runner(e: Dictionary, size: float) -> void:
	if not e.has("runner"):
		return
	var gold := Color(1.0, 0.82, 0.3)
	# long streaks behind it, bright near the bug and fading out
	for i in 3:
		var dx: float = (i - 1) * size * 0.3
		var top: float = -size * 0.3
		var length: float = size * (2.6 if i == 1 else 1.7)
		draw_line(e.pos + Vector2(dx, top), e.pos + Vector2(dx, top - length * 0.5), Color(gold, 0.85), 3.0, true)
		draw_line(e.pos + Vector2(dx, top - length * 0.5), e.pos + Vector2(dx, top - length), Color(gold, 0.3), 3.0, true)
	# a chevron in front of it, pointing where it is going
	var cy: float = size * 0.62 + sin(time_alive * 14.0) * 2.0
	draw_polyline(PackedVector2Array([e.pos + Vector2(-size * 0.3, cy - size * 0.2), e.pos + Vector2(0, cy), e.pos + Vector2(size * 0.3, cy - size * 0.2)]), gold, 3.0, true)

func _runner_caught(e: Dictionary) -> void:
	_runners_caught += 1
	_pod_ping("radar")
	if _radar_heal and shield < shield_max:
		shield = minf(shield + shield_max * 0.03, shield_max)
	_float_text(e.pos + Vector2(0, -22), "CAUGHT!", Color(1.0, 0.85, 0.4), true)
	var worth: float = (4.0 + 0.4 * stage) * (2.0 if _base_perks.has("radar") else 1.0)   # Radar Lv.5: a caught runner pays double
	for i in 4:
		gems.append({"pos": e.pos + Vector2(rng.randf_range(-14, 14), rng.randf_range(-8, 8)), "tier": 0, "coin": true, "life": 16.0,
			"value": worth / 4.0, "vel": Vector2(rng.randf_range(-70, 70), rng.randf_range(-110, -40))})
	gems.append({"pos": e.pos, "tier": 2, "life": 16.0, "vel": Vector2(0, -60)})
	hitstop = maxf(hitstop, 0.05)

func _wave_patch() -> void:
	_pod_ping("repair_bay")
	_pod_ping("medbay")
	if _wave_coins:   # Rich Seam overcharged: the Refinery throws up a pile of coins
		var from := Backdrop.core_eye(FIELD_W, BASE_Y) + Vector2(0, -DOME_RY)
		for i in 5:
			gems.append({"pos": from + Vector2(rng.randf_range(-40, 40), rng.randf_range(-10, 10)), "tier": 0, "coin": true, "life": 16.0,
				"value": (6.0 + 0.5 * stage) / 5.0, "vel": Vector2(rng.randf_range(-90, 90), rng.randf_range(-160, -70))})
	# the Repair Bay mends the hull too, the Med Bay the hero (Base)
	if _base_repair > 0.0 and hull < hull_max:
		hull = minf(hull + hull_max * _base_repair * (2.0 if _base_perks.has("repair_bay") and hull < hull_max * 0.5 else 1.0), hull_max)
	if _base_heal > 0.0 and pilot_hp < pilot_hp_max:
		pilot_hp = minf(pilot_hp + pilot_hp_max * _base_heal, pilot_hp_max)
	if shield >= shield_max or shield_max <= 0.0:
		return
	var add: float = shield_max * (WAVE_PATCH + _base_repair * (2.0 if _base_perks.has("repair_bay") and hull < hull_max * 0.5 else 1.0))
	shield = minf(shield + add, shield_max)
	_float_text(Vector2(FIELD_W * 0.5, BASE_Y - DOME_RY - 16.0), "SHIELD +%d" % roundi(add), Color(0.4, 0.9, 1.0))

# ------------------------------------------------------------------ HERO ABILITIES (2026-11-10)
# One big move per hero on a cooldown (the button bottom left, mirror of AUTO): the thing that makes
# six heroes six ways to play. Open once stage ABILITY_FROM is cleared. The cooldown shortens with
# his rarity step (Heroes.ability_cd). AUTO presses it too, late and only on a crowd or a boss.
const ABILITY_FROM := 2
var _ult_cd := 40.0       # the full cooldown
var _ult_t := 12.0        # seconds until it is ready (a run starts with a short wait)
var _ult_live := 0.0      # Rook / Hollow: seconds of the effect left
var _ult_btn: Button
var _ult_flash := 0.0
var _runners_caught := 0

func _ability_open() -> bool:
	return stage_unlocked > ABILITY_FROM or DevTools.on

func _bolt_dmg() -> float:
	return float(WEAPONS[weapon_id].damage) * damage_mult

func _ult_hit(e: Dictionary, dmg: float) -> void:
	if not _can_hurt(e):
		return
	dmg *= _elem_mult
	e.hp -= dmg
	e.hit_t = HIT_FLINCH_T
	stat_pilot_dmg += dmg
	_count_dmg("hero", dmg, e)
	_show_dmg(e, dmg, true, _elem_mult)

func _update_ability(delta: float) -> void:
	_ult_t = maxf(_ult_t - delta, 0.0)
	_ult_live = maxf(_ult_live - delta, 0.0)
	_ult_flash = maxf(_ult_flash - delta * 2.0, 0.0)
	# AUTO: it waits for a crowd or a boss, and is a second late
	if auto_on and not dragging and _ult_t <= 0.0 and _ability_open():
		var boss := false
		for e in enemies:
			boss = boss or (_is_boss(e) and e.get("arrived", false))
		if boss or enemies.size() >= 6:
			_ai_ult -= delta
			if _ai_ult <= 0.0:
				_use_ability()
		else:
			_ai_ult = 1.0
var _ai_ult := 1.0

func _use_ability() -> void:
	if not _ability_open():
		_float_text(Vector2(100.0, _ult_rect().position.y - 14.0), "Unlocks after stage %d" % ABILITY_FROM, Color(0.75, 0.82, 0.92))
		return
	if _ult_t > 0.0 or paused or picking or game_over or stage_cleared or _outro_t >= 0.0:
		return
	_ult_t = _ult_cd
	_ai_ult = 1.0
	_ult_flash = 1.0
	_abilities_used += 1
	_buzz(30)
	_ability_effect(_hero_id, false)
	if _rig_view:
		_rig_view.cast()   # his ability pose

# WINGMATE (2026-11-10; IDEAS-2026-11-10.md 6): a second hero you own rides along as support
# (Heroes.wing). He lends his passive at half strength (Heroes.stats) and fires his own ability by
# himself every WING_CD seconds when there is a crowd or a boss. It makes a roster worth owning.
const WING_CD := 55.0
var _wing_id := ""
var _wing_t := 25.0
var _ult_kind := ""       # "volley" or "phase" while _ult_live runs
var _ult_ups := 0         # the duty hero s ability upgrades (0-3)
var _wing_ups := 0        # the wingmate s
var _live_ups := 0        # the upgrades of whoever started the Volley / Phase Storm now running

func _update_wing(delta: float) -> void:
	if _wing_id == "" or not _ability_open():
		return
	_wing_t = maxf(_wing_t - delta, 0.0)
	if _wing_t > 0.0:
		return
	var boss := false
	for e in enemies:
		boss = boss or (_is_boss(e) and e.get("arrived", false))
	if boss or enemies.size() >= 4:
		_wing_t = WING_CD
		_ability_effect(_wing_id, true)

# what an ability does (the hero on duty, or the wingmate's assist)
func _ability_effect(hid: String, assist: bool) -> void:
	var col: Color = Heroes.element_color(Heroes.element_of(hid))
	var ab: Dictionary = Heroes.ABILITIES.get(hid, Heroes.ABILITIES["rook"])
	var shout := String(ab.name).to_upper() + "!"
	if assist:
		shout = "%s: %s" % [String(Heroes.ROSTER[hid].name).to_upper(), shout]
	_float_text(soldier_pos + Vector2(0, -92 if not assist else -116), shout, col.lerp(Color.WHITE, 0.3), true)
	_fx_add("nova", soldier_pos, 140.0 if not assist else 100.0, 0.6, 0.0, 3.2, col)
	_burst(soldier_pos, 46.0, col, 20)
	if not assist:
		hitstop = maxf(hitstop, 0.1)
		shake = maxf(shake, 0.4)
	Sfx.play("level", 0.8 if not assist else 1.1)
	var base := _bolt_dmg()
	var ups: int = _wing_ups if assist else _ult_ups   # ability upgrades bought (Heroes.ABILITY_UPS), in order
	match hid:
		"sparks":
			# Overload: lightning jumps through the nearest bugs (8; 12 with upgrade 1; harder with 2; a stun with 3)
			var pool: Array = enemies.filter(func(e): return _can_hurt(e))
			pool.sort_custom(func(a, b): return a.pos.distance_squared_to(soldier_pos) < b.pos.distance_squared_to(soldier_pos))
			var from: Vector2 = _muzzle_world()
			for i in mini(pool.size(), 12 if ups >= 1 else 8):
				zaps.append({"a": from, "b": pool[i].pos, "life": 0.35, "seed": rng.randf() * 100.0})
				_ult_hit(pool[i], base * (9.0 if ups >= 2 else 7.0))
				if ups >= 3 and not _is_boss(pool[i]):
					pool[i].freeze_t = maxf(float(pool[i].get("freeze_t", 0.0)), 1.5)
				from = pool[i].pos
		"frost":
			# Whiteout: every bug freezes solid; a boss is slowed instead (longer with 1; harder with 2; mends the shield with 3)
			var hold: float = 4.5 if ups >= 1 else 3.0
			for e in enemies:
				if _is_boss(e):
					e.slow = 0.45
					e.slow_t = hold + 1.0
				else:
					e.freeze_t = hold
				_ult_hit(e, base * (4.0 if ups >= 2 else 2.0))
			if ups >= 3 and shield < shield_max:
				var add: float = minf(shield_max * 0.1, shield_max - shield)
				shield += add
				_float_text(Vector2(FIELD_W * 0.5, BASE_Y - DOME_RY - 16.0), "SHIELD +%d" % roundi(add), Color(0.75, 0.92, 1.0))
			_fx_add("nova", Vector2(FIELD_W * 0.5, FIELD_H * 0.4), 300.0, 0.7, 0.0, 2.4, Color(0.75, 0.92, 1.0))
		"nyx":
			# Execute: the weak die, the rest are marked (marked bugs always crit). Upgrades: the
			# line rises to half health, the mark lasts longer, every bug put down gives a second back.
			var line: float = 0.5 if ups >= 1 else 0.4
			var downed := 0
			for e in enemies:
				if not _can_hurt(e):
					continue
				if not _is_boss(e) and e.type != "crate" and e.hp <= line * float(e.hp_max):
					_ult_hit(e, float(e.hp) + 1.0)
					downed += 1
				else:
					_ult_hit(e, base * 4.0)
					e.mark_t = 10.0 if ups >= 2 else 6.0
			if ups >= 3 and downed > 0 and not assist:
				_ult_t = maxf(_ult_t - minf(float(downed), 10.0), 0.0)
		"ember":
			# Firestorm: everything burns (longer with 1; more burning ground with 2; a blast first with 3)
			var patches: int = 5 if ups >= 2 else 3
			for e in enemies:
				if String(StageData.ENEMIES[e.type].move) == "spore":
					_ult_hit(e, float(e.hp) + 1.0)
					continue
				if ups >= 3:
					_ult_hit(e, base * 3.0)
				e.burn_t = 6.0 if ups >= 1 else 4.0
				e.burn_dps = (0.03 if _is_boss(e) else 0.14) * float(e.hp_max)
			for i in patches:
				if _fire_patches.size() < 10:
					_fire_patches.append({"pos": Vector2(FIELD_W * (0.5 + (float(i) - (patches - 1) * 0.5) * (0.25 if patches == 3 else 0.18)), FIELD_H * 0.42), "life": 4.0, "max": 4.0, "r": 60.0, "ph": rng.randf() * TAU})
		"hollow":
			# Phase Storm: bolts that pass through everything (5 s; 7 with 1; harder bolts with 2; nothing can hurt him with 3)
			_ult_live = 7.0 if ups >= 1 else 5.0
			_ult_kind = "phase"
			_live_ups = ups
		_:
			# Rook, Volley: two and a half times the fire rate (4 s; 6 with 1; harder bolts with 2; they pierce with 3)
			_ult_live = 6.0 if ups >= 1 else 4.0
			_ult_kind = "volley"
			_live_ups = ups

# the wingmate's small ring above the ability button: his element, filling as his assist charges
func _draw_wing_chip() -> void:
	if _wing_id == "" or not _ability_open():
		return
	var r := _ult_rect()
	var c := Vector2(r.get_center().x, r.position.y - 26.0)
	var col: Color = Heroes.element_color(Heroes.element_of(_wing_id))
	_hc.draw_circle(c, 17.0, Color(0.055, 0.09, 0.157, 0.88))
	_hc.draw_arc(c, 16.0, 0.0, TAU, 32, Color(1, 1, 1, 0.1), 1.5, true)
	_hc.draw_arc(c, 16.0, -PI / 2.0, -PI / 2.0 + TAU * (1.0 - _wing_t / WING_CD), 32, Color(col, 0.85), 2.0, true)
	var icon: Texture2D = _tex_cached(UIKit.ELEMENT_ICON.get(Heroes.element_of(_wing_id), "el_energy"))
	if icon != null:
		_hc.draw_texture_rect(icon, Rect2(c - Vector2(10, 10), Vector2(20, 20)), false, Color(1, 1, 1, 0.9))

# bottom left, above the base: the mirror of AUTO
func _ult_rect() -> Rect2:
	return Rect2(FIELD_W - 68.0 if _lefty else 10.0, BASE_Y - 204.0, 58.0, 58.0)

func _draw_ult_btn() -> void:
	var r := _ult_rect()
	if _ult_btn:
		_ult_btn.position = r.position - Vector2(3, 3)
	var open := _ability_open()
	var col: Color = Heroes.element_color(Heroes.element_of(_hero_id))
	var c := r.get_center()
	var ready: bool = open and _ult_t <= 0.0
	var pulse: float = 0.5 + 0.5 * sin(time_alive * 5.0)
	_hc.draw_circle(c, 29.0, Color(0.055, 0.09, 0.157, 0.88))
	if ready:
		_hc.draw_circle(c, 29.0, Color(col, 0.16 + 0.1 * pulse))
		_hc.draw_arc(c, 28.0, 0.0, TAU, 48, Color(col, 0.75 + 0.25 * pulse), 2.5, true)
	else:
		_hc.draw_arc(c, 28.0, 0.0, TAU, 48, Color(1, 1, 1, 0.1), 2.0, true)
		if open:   # the ring fills clockwise as it charges
			var k: float = 1.0 - _ult_t / maxf(_ult_cd, 1.0)
			_hc.draw_arc(c, 28.0, -PI / 2.0, -PI / 2.0 + TAU * k, 48, Color(col, 0.8), 2.5, true)
	if _ult_flash > 0.0:
		_hc.draw_arc(c, 29.0 + 22.0 * (1.0 - _ult_flash), 0.0, TAU, 48, Color(col, _ult_flash), 3.0, true)
	var icon: Texture2D = _tex_cached(UIKit.ELEMENT_ICON.get(Heroes.element_of(_hero_id), "el_energy"))
	if icon != null:
		_hc.draw_texture_rect(icon, Rect2(c - Vector2(17, 17), Vector2(34, 34)), false, Color(1, 1, 1, 1.0 if ready else (0.4 if open else 0.2)))
	if open and not ready:
		_hc.draw_string(title_font, Vector2(r.position.x, c.y + 5.0), str(ceili(_ult_t)), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 15, Color.WHITE)

var _ult_icons := {}
func _tex_cached(icon_name: String) -> Texture2D:
	if not _ult_icons.has(icon_name):
		_ult_icons[icon_name] = UIKit.ic(icon_name)
	return _ult_icons[icon_name]

# capture hook (tools/dev/capture.gd CAP_CALL="_dbg_runner"): a lane lights up now and the ability is ready
func _dbg_runner() -> void:
	_lanes.append({"x": 330.0, "t": RUNNER_WARN * _warn_mult})
	_ult_t = 0.0

# capture hooks (tools/dev/capture.gd CAP_CALL): the end screens with some play behind them
func _dbg_win() -> void:
	_end_run(true)

func _dbg_lose() -> void:
	_end_run(false)

# ------------------------------------------------------------------ KILL STREAK (2026-11-10)
# Kills in quick succession build a streak: every kill within STREAK_HOLD seconds of the last adds
# one, and each point is +1% coins from the bugs you kill (up to STREAK_MAX). Getting hit, or
# going quiet, ends it. It rewards staying on the attack, which is what playing by hand is for.
const STREAK_HOLD := 2.6
const STREAK_MAX := 50
var _streak := 0
var _streak_t := 0.0
var _streak_pop := 0.0
var _streak_best := 0

func _streak_add() -> void:
	_streak += 1
	_streak_t = STREAK_HOLD
	_streak_pop = 1.0
	_streak_best = maxi(_streak_best, _streak)
	if _streak == 10 or _streak == 25 or _streak == 50 or (_streak > 50 and _streak % 50 == 0):
		_float_text(soldier_pos + Vector2(0, -70), "STREAK x%d" % _streak, Color(1.0, 0.85, 0.4), true)
		Sfx.play("level", 1.0 + minf(_streak, 100) * 0.004)

func _streak_break() -> void:
	_streak = 0
	_streak_t = 0.0

func _streak_mult() -> float:
	return 1.0 + 0.01 * mini(_streak, STREAK_MAX)

func _update_streak(delta: float) -> void:
	_streak_pop = maxf(_streak_pop - delta * 5.0, 0.0)
	if _streak > 0:
		_streak_t -= delta
		if _streak_t <= 0.0:
			_streak_break()

# top right, under the HP bar: the count, a small "+n% coins", and a line that drains
func _draw_streak() -> void:
	if _streak < 3:
		return
	var gold := Color(1.0, 0.82, 0.3)
	var x := FIELD_W - 14.0
	var y := HUD_H + 44.0
	var fs := 22 + int(6.0 * _streak_pop)
	_hc.draw_string(title_font, Vector2(x - 120.0, y), "x%d" % _streak, HORIZONTAL_ALIGNMENT_RIGHT, 120.0, fs, gold)
	_hc.draw_string(hud_font, Vector2(x - 120.0, y + 14.0), "+%d%% coins" % mini(_streak, STREAK_MAX), HORIZONTAL_ALIGNMENT_RIGHT, 120.0, 10, Color(gold, 0.8))
	var k: float = clampf(_streak_t / STREAK_HOLD, 0.0, 1.0)
	_hc.draw_style_box(UIKit.pill(Color(1, 1, 1, 0.12), 2, Vector2.ZERO), Rect2(x - 64.0, y + 20.0, 64.0, 3.0))
	_hc.draw_style_box(UIKit.pill(gold, 2, Vector2.ZERO), Rect2(x - 64.0 * k, y + 20.0, 64.0 * k, 3.0))

# ------------------------------------------------------------------ PLANET HAZARDS (2026-11-10)
# Every planet after the first has its own danger from the world itself, so a new planet feels like
# a new place and not only new bugs: scrap falling out of orbit, eruptions, shard rain, lightning,
# a targeting laser. One mechanic today (a STRIKE): a circle lights up near the hero, closes for
# STRIKE_WARN seconds, then hits everything inside it: the hero, and bugs too, so you can lead
# bugs into it. More often on later planets. Luna art can replace the code circle per planet later.
const HAZARDS := [
	{},
	{"name": "FALLING SCRAP", "col": Color(0.75, 0.8, 0.9)},
	{"name": "ERUPTION", "col": Color(1.0, 0.5, 0.2)},
	{"name": "SHARD RAIN", "col": Color(0.75, 0.55, 1.0)},
	{"name": "LIGHTNING", "col": Color(0.45, 0.9, 1.0)},
	{"name": "TARGETING LASER", "col": Color(1.0, 0.3, 0.35)},
]
const STRIKE_WARN := 1.7
const STRIKE_R := 48.0
var _strikes: Array = []     # {pos, t}
var _strike_cd := 8.0

func _hazard() -> Dictionary:
	var a := clampi(StageData.area_index(stage), 0, HAZARDS.size() - 1)
	return HAZARDS[a]

func _update_strikes(delta: float) -> void:
	var hz := _hazard()
	if hz.is_empty():
		return
	var area := StageData.area_index(stage)
	if not enemies.is_empty():
		_strike_cd -= delta
	if _strike_cd <= 0.0:
		_strike_cd = maxf(14.0 - area, 8.0) + rng.randf_range(-1.0, 2.0)   # first sweep at 11 - 1.2 x area and 12 + 2 x area damage: the autopilot died at stages 12 and 60
		var p := Vector2(clampf(soldier_pos.x + rng.randf_range(-70.0, 70.0), 50.0, FIELD_W - 50.0), clampf(soldier_pos.y + rng.randf_range(-40.0, 20.0), 140.0, BASE_Y - 60.0))
		_strikes.append({"pos": p, "t": STRIKE_WARN * _warn_mult})
		Sfx.play("spit", 0.7)
		if not _seen.has("hazard_%d" % area):   # the first one on this planet: say what the circle means
			_seen.append("hazard_%d" % area)
			_write_save({"seen_enemies": _seen})
			_float_text(Vector2(FIELD_W * 0.5, FIELD_H * 0.3), "%s! Leave the circle" % String(hz.name), Color(hz.col).lerp(Color.WHITE, 0.3), true)
	var keep: Array = []
	for s in _strikes:
		s.t = float(s.t) - delta
		if float(s.t) > 0.0:
			keep.append(s)
			continue
		# it lands
		var col: Color = hz.col
		_fx_add("nova", s.pos, STRIKE_R * 1.6, 0.4, 0.0, 1.6, col)
		_burst(s.pos, STRIKE_R * 0.8, col, 18)
		shake = maxf(shake, 0.35)
		Sfx.play("hull", 1.2)
		if soldier_pos.distance_to(s.pos) <= STRIKE_R:
			_hurt_pilot(8.0 + area)
		for e in enemies:
			if not _is_boss(e) and _can_hurt(e) and e.pos.distance_to(s.pos) <= STRIKE_R + float(e.r):
				e.hp -= 0.4 * float(e.hp_max)
				e.hit_t = HIT_FLINCH_T
	_strikes = keep

# the warning: a faint disc, a ring that closes onto it, the edge brightening as it is about to land
func _draw_strikes() -> void:
	if _strikes.is_empty():
		return
	var col: Color = _hazard().get("col", Color.WHITE)
	for s in _strikes:
		var k: float = 1.0 - float(s.t) / (STRIKE_WARN * _warn_mult)
		draw_circle(s.pos, STRIKE_R, Color(col, 0.07 + 0.12 * k))
		draw_arc(s.pos, STRIKE_R, 0.0, TAU, 48, Color(col, 0.5 + 0.5 * k), 2.0, true)
		draw_arc(s.pos, STRIKE_R * (2.2 - 1.2 * k), 0.0, TAU, 48, Color(col, 0.25 + 0.5 * k), 2.0, true)
		for i in 4:
			var a := time_alive * 1.5 + i * PI * 0.5
			draw_line(s.pos + Vector2(cos(a), sin(a)) * STRIKE_R * 0.75, s.pos + Vector2(cos(a), sin(a)) * STRIKE_R, Color(col, 0.8), 2.0, true)

# capture hook (CAP_CALL="_dbg_strike"): a hazard circle closing on the hero and a streak on the HUD
func _dbg_strike() -> void:
	_strikes.append({"pos": soldier_pos + Vector2(30, -10), "t": STRIKE_WARN * 0.6})
	_streak = 12
	_streak_t = STREAK_HOLD

# ------------------------------------------------------------------ SUPPLY DROPS (2026-11-10)
# A decision in the middle of a fight (IDEAS-2026-11-10.md 5). From stage SUPPLY_FROM, at the start
# of every third wave a crate drifts down and hangs in the sky for a few seconds. Shoot it open and
# the fight stops for a choice of two: a mend, a refresh, a medkit, a charged ability, a bounty,
# or a CURSED offer (a big bonus with a price). Leave it and it flies off.
const SUPPLY_FROM := 6
const SUPPLY_STAY := 11.0
const SUPPLIES := {
	"patch":   {"name": "Shield patch", "text": "Shield +30%", "icon": "st_def"},
	"refresh": {"name": "Spare deck", "text": "+1 card refresh", "icon": "ic_pack"},
	"medkit":  {"name": "Medkit", "text": "Hero heals 40%", "icon": "st_hp"},
	"charge":  {"name": "Charge", "text": "Ability ready now, 25% faster this stage", "icon": "ic_energy"},
	"bounty":  {"name": "Bounty", "text": "A purse of coins", "icon": "ic_coin"},
	"cursed":  {"name": "Cursed core", "text": "Damage +30%, hero max HP -25%", "icon": "ic_elite", "cursed": true},
}
var _crate_due := -1.0
var _supply_pending := false
var _supply_open := false
var _supply_offer: Array = []
var _supply_panel: Control
var _crate_tex: Texture2D
var _supplies_taken := 0

func _plan_supply() -> void:
	if stage >= SUPPLY_FROM and wave_index > 0 and wave_index % 3 == 2:
		_crate_due = 4.0

func _update_supply(delta: float) -> void:
	if _crate_due >= 0.0:
		_crate_due -= delta
		if _crate_due < 0.0:
			var e := _make_enemy("crate", Vector2(rng.randf_range(80.0, FIELD_W - 80.0), 40.0))
			e.erase("variant")
			e.shield_hp = 0.0
			enemies.append(e)
			_float_text(Vector2(FIELD_W * 0.5, FIELD_H * 0.26), "SUPPLY DROP!", Color(0.4, 0.95, 0.7), true)
			Sfx.play("card_open")
	if _supply_pending and not picking:
		_supply_pending = false
		_open_supply()

# the crate: Luna's Uncommon chest, swaying, with a thin health line under it
func _draw_crate(e: Dictionary) -> void:
	if _crate_tex == null:
		_crate_tex = UIKit.ic("chest2_u_closed", "ic_chest_u")
	var s := 54.0
	var leaving: float = clampf((float(e.t) - SUPPLY_STAY + 1.5) / 1.5, 0.0, 1.0)
	draw_set_transform(e.pos, sin(e.t * 2.0) * 0.12, Vector2.ONE)
	draw_circle(Vector2.ZERO, 34.0, Color(0.4, 0.95, 0.7, 0.10 * (1.0 - leaving)))
	if _crate_tex != null:
		draw_texture_rect(_crate_tex, Rect2(-s * 0.5, -s * 0.5, s, s), false, Color(1, 1, 1, 1.0 - 0.7 * leaving))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var k: float = clampf(float(e.hp) / maxf(float(e.hp_max), 0.01), 0.0, 1.0)
	draw_rect(Rect2(e.pos.x - 22.0, e.pos.y + 32.0, 44.0, 3.0), Color(1, 1, 1, 0.15))
	draw_rect(Rect2(e.pos.x - 22.0, e.pos.y + 32.0, 44.0 * k, 3.0), Color(0.4, 0.95, 0.7))

func _crate_broken(e: Dictionary) -> void:
	_burst(e.pos, 30.0, Color(0.4, 0.95, 0.7), 16)
	_fx_add("nova", e.pos, 70.0, 0.4, 0.0, 1.8, Color(0.4, 0.95, 0.7))
	Sfx.play("buy")
	_supply_pending = true

func _supply_roll() -> Array:
	var pool: Array = ["patch", "refresh", "medkit", "bounty"]
	if _ability_open():
		pool.append("charge")
	if shield >= shield_max:
		pool.erase("patch")
	if pilot_hp >= pilot_hp_max:
		pool.erase("medkit")
	pool.shuffle()
	var out: Array = [pool[0], pool[1]]
	if rng.randf() < 0.35:
		out[1] = "cursed"
	return out

func _open_supply() -> void:
	picking = true
	_supply_open = true
	dragging = false
	_supply_offer = _supply_roll()
	if _supply_panel == null:
		_supply_panel = Control.new()
		add_child(_supply_panel)
	for c in _supply_panel.get_children():
		c.queue_free()
	_supply_panel.visible = true
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = Vector2(FIELD_W, FIELD_H)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_supply_panel.add_child(dim)
	var title := UIKit.title("SUPPLY DROP", 24, Color(0.5, 1.0, 0.78), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(0, FIELD_H * 0.5 - 190)
	title.size = Vector2(FIELD_W, 30)
	_supply_panel.add_child(title)
	var sub := UIKit.label("Take one", 13, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	sub.position = Vector2(0, FIELD_H * 0.5 - 158)
	sub.size = Vector2(FIELD_W, 20)
	_supply_panel.add_child(sub)
	var w := 196.0
	var h := 200.0
	var gap := 14.0
	var x0 := FIELD_W * 0.5 - (w * 2.0 + gap) * 0.5
	for i in _supply_offer.size():
		var def: Dictionary = SUPPLIES[_supply_offer[i]]
		var cursed: bool = def.get("cursed", false)
		var col := Color(1.0, 0.4, 0.45) if cursed else Color(0.4, 0.95, 0.7)
		var b := Button.new()
		b.position = Vector2(x0 + i * (w + gap), FIELD_H * 0.5 - 124)
		b.size = Vector2(w, h)
		var nb := UIKit.box(Color(0.055, 0.09, 0.157, 0.97), Color(col, 0.7), 22, 1)
		var pb := UIKit.box(Color(0.094, 0.145, 0.239, 0.97), col, 22, 2)
		for st in ["normal", "hover"]:
			b.add_theme_stylebox_override(st, nb)
		b.add_theme_stylebox_override("pressed", pb)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var v := VBoxContainer.new()
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 12.0
		v.offset_right = -12.0
		v.offset_top = 14.0
		v.offset_bottom = -14.0
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_theme_constant_override("separation", 8)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tr := TextureRect.new()
		tr.texture = UIKit.ic(String(def.icon))
		tr.custom_minimum_size = Vector2(0, 64)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(tr)
		v.add_child(UIKit.title(String(def.name), 18, col.lerp(Color.WHITE, 0.4), HORIZONTAL_ALIGNMENT_CENTER))
		var tl := UIKit.label(String(def.text), 13, Color(0.85, 0.9, 0.97), HORIZONTAL_ALIGNMENT_CENTER)
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(tl)
		b.add_child(v)
		var k: int = i
		b.pressed.connect(func(): _supply_pick(k))
		_supply_panel.add_child(b)
		b.pivot_offset = Vector2(w, h) * 0.5
		b.scale = Vector2(0.85, 0.85)
		b.modulate.a = 0.0
		var tw := b.create_tween().set_parallel(true)
		tw.tween_property(b, "scale", Vector2.ONE, 0.25).set_delay(0.08 * i).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(b, "modulate:a", 1.0, 0.18).set_delay(0.08 * i)

func _supply_pick(i: int) -> void:
	if not _supply_open or i < 0 or i >= _supply_offer.size():
		return
	var id: String = _supply_offer[i]
	_supply_open = false
	picking = false
	_supplies_taken += 1
	if _supply_panel:
		_supply_panel.visible = false
	Sfx.play("card")
	match id:
		"patch":
			shield = minf(shield + shield_max * 0.3, shield_max)
		"refresh":
			refreshes += 1
		"medkit":
			pilot_hp = minf(pilot_hp + pilot_hp_max * 0.4, pilot_hp_max)
		"charge":
			_ult_t = 0.0
			_ult_cd *= 0.75
		"bounty":
			_coins_f += 60.0 + 12.0 * stage
			coins_earned = int(_coins_f)
		"cursed":
			damage_mult *= 1.3
			pilot_hp_max = maxf(roundf(pilot_hp_max * 0.75), 1.0)
			pilot_hp = minf(pilot_hp, pilot_hp_max)
	_float_text(soldier_pos + Vector2(0, -60), String(SUPPLIES[id].name), Color(1.0, 0.45, 0.5) if id == "cursed" else Color(0.5, 1.0, 0.78), true)

# capture hook (CAP_CALL="_dbg_supply"): the supply choice
func _dbg_supply() -> void:
	_open_supply()

# ------------------------------------------------------------------ BOSS WEAK POINT (2026-11-10)
# Every boss has a window when it is open: the Hive Mother and the Salvage Queen while they lay or
# release (it was x2 and invisible), the Wrecker while its claw holds a turret. In the window bolts
# hit WEAK_MULT harder and a gold reticle closes on her with the words, so the player knows to pour
# it on. (IDEAS-2026-11-10.md 3.)
const WEAK_MULT := 2.5
var _lefty := false

func _boss_weak(e: Dictionary) -> bool:
	if not _is_boss(e) or not e.get("arrived", false):
		return false
	return float(e.get("laying", 0.0)) > 1.2 or (e.type == "wrecker" and String(e.get("state", "")) == "hold")

func _draw_weak(e: Dictionary, size: float) -> void:
	if not _boss_weak(e):
		return
	var gold := Color(1.0, 0.82, 0.3)
	var r: float = size * 0.42
	var pulse: float = 0.5 + 0.5 * sin(time_alive * 9.0)
	draw_arc(e.pos, r, 0.0, TAU, 48, Color(gold, 0.55 + 0.4 * pulse), 2.5, true)
	draw_arc(e.pos, r * (1.25 + 0.12 * pulse), 0.0, TAU, 48, Color(gold, 0.25), 1.5, true)
	for i in 4:
		var a := time_alive * 1.2 + i * PI * 0.5
		var d := Vector2(cos(a), sin(a))
		draw_line(e.pos + d * r * 0.7, e.pos + d * r * 1.3, gold, 3.0, true)
	draw_string(title_font, Vector2(e.pos.x - 100.0, e.pos.y - r * 1.3 - 8.0), "WEAK POINT  x%s" % str(WEAK_MULT), HORIZONTAL_ALIGNMENT_CENTER, 200.0, 14, Color(gold, 0.8 + 0.2 * pulse))

# capture hook (CAP_CALL="_dbg_weak"): a boss with her weak point open
func _dbg_weak() -> void:
	enemies.clear()
	wave_queue.clear()
	_spawn("hive_mother")
	enemies[0].pos = Vector2(FIELD_W * 0.5, 230.0)
	enemies[0].arrived = true
	enemies[0].laying = 3.0
	enemies[0].hatched = true

# ------------------------------------------------------------------ EXPEDITION fights (Runs, 2026-11-10)
# A fight that belongs to a run (selected_mode "run"; the map page set run.node). It is short
# (Runs.trim_waves), starts with what the run carries (the cards picked so far, the hero's health,
# the shield and hull as they were left) and hands the result back to the run when it ends.
var run_mode := false
var _run := {}
var _replaying := false   # cards being put back at the start of a run fight: no sound, no shouts

func _run_kind() -> String:
	return String(_run.get("node", "fight"))

# after the stage is set up: put the run's state back
func _run_begin() -> void:
	var cards: Dictionary = _run.get("cards", {})
	_replaying = true
	for id in cards:
		for i in int(cards[id]):
			if Cards.CARDS.has(id) or Cards.FUSIONS.has(id):
				_pick_card(String(id))
	_replaying = false
	picking = false
	if _card_panel:
		_card_panel.visible = false
	run_level = 1 + mini(int(_run.get("step", 0)), 6)   # a run is already under way: the first pick is not far off
	refreshes += int(_run.get("refreshes", 0))
	# FIELD WORKS: what was bolted onto the base during this run (Runs.UPGRADES)
	shield_max *= 1.0 + 0.2 * Runs.boost(_run, "bulwark")
	hull_max *= 1.0 + 0.2 * Runs.boost(_run, "armour")
	_base_dr = clampf(_base_dr + 0.08 * Runs.boost(_run, "armour"), 0.0, 0.6)
	damage_mult *= 1.0 + 0.1 * Runs.boost(_run, "guns")
	pilot_hp_max = roundf(pilot_hp_max * (1.0 + 0.15 * Runs.boost(_run, "medic")))
	_pulse_cd_mult *= pow(0.85, Runs.boost(_run, "capacitor"))
	_ult_cd *= pow(0.85, Runs.boost(_run, "capacitor"))
	_coin_mult *= 1.0 + 0.25 * Runs.boost(_run, "salvage")
	pilot_hp = maxf(roundf(pilot_hp_max * clampf(float(_run.get("hp", 1.0)), 0.05, 1.0)), 1.0)
	shield = shield_max * clampf(float(_run.get("shield", 1.0)), 0.0, 1.0)
	hull = maxf(hull_max * clampf(float(_run.get("hull", 1.0)), 0.05, 1.0), 1.0)

func _run_end(won: bool) -> void:
	var d := _read_save()
	var run: Dictionary = d.get("run", _run)
	Runs.fight_done(run, won, pilot_hp / maxf(pilot_hp_max, 1.0), shield / maxf(shield_max, 1.0), hull / maxf(hull_max, 1.0), card_levels)
	_run = run
	_write_save({"run": run})

# ------------------------------------------------------------------ THE BASE YOU BUILD, in a fight (Base, 2026-11-10)
var _base_slots: Array = ["", "", "", ""]   # the building on each slot ("" = none or the slot is closed)
var _base_repair := 0.0     # Repair Bay: extra share mended after a wave (shield and hull)
var _base_heal := 0.0       # Med Bay: share of the hero's health back after a wave
var _warn_mult := 1.0       # Radar: runner lanes and hazards show this much longer
var _base_perks: Array = []   # buildings at level 5 on the base: their perks (Base.PERKS)
var _dome_used := false      # the Shield Generator's emergency shield went up this fight

func _apply_base(sv: Dictionary) -> void:
	_base_links = []
	_pulse_cd_mult = 1.0
	_pods = []
	_base_perks = []
	if _mods.has("no_turrets"):   # the Base offline twist (trials): the buildings give nothing this fight
		_base_slots = ["", "", "", ""]
		_base_open = [false, false, false, false]   # every pod dark
		return
	var bs := Base.stats(sv)
	var b := Base.read(sv)
	var su := int(sv.get("stage_unlocked", 1))
	for i in Base.SLOTS:
		_base_slots[i] = String(b.slots[i]) if (Base.slot_open(i, su) or DevTools.on) else ""
		_base_open[i] = Base.slot_open(i, su) or DevTools.on
		_base_levels[i] = Base.level(b, _base_slots[i]) if _base_slots[i] != "" else 0
		if _base_slots[i] != "":   # the Wrecker goes for a pod with a building in it
			_pods.append({"mount": i, "pos": Backdrop.pod_pos(i, FIELD_W, BASE_Y), "drop": 1.0, "held_by": -1})
		if _base_slots[i] != "":
			_tex["bld_" + String(_base_slots[i])] = Base.pic(String(_base_slots[i]))
	shield_max *= 1.0 + float(bs.shield)
	shield = shield_max
	hull_max *= 1.0 + float(bs.hull)
	hull = hull_max
	_base_dr = clampf(_base_dr + float(bs.hull) * 0.2, 0.0, 0.6)   # Hull Plating also takes the edge off each hit
	damage_mult *= 1.0 + float(bs.damage)
	pilot_hp_max = roundf(pilot_hp_max * (1.0 + float(bs.hp)))
	pilot_hp = pilot_hp_max
	_base_heal = minf(float(bs.hp) * 0.4, 0.2)
	_base_repair = float(bs.repair)
	# the level-5 perks of the buildings in force (Base.perks)
	_base_perks = Base.perks(sv)
	_dome_used = false
	if _base_perks.has("armory"):
		_crit_rate += 0.05
	if _base_perks.has("medbay"):
		_second_wind = maxi(_second_wind, 1)
	if _base_perks.has("hangar"):
		_drone_mult *= 1.2
	_drone_mult *= 1.0 + float(bs.drone)
	_ult_cd /= 1.0 + float(bs.ability)
	_warn_mult = 1.0 + float(bs.warn)
	_coin_mult *= 1.0 + float(bs.coins)
	# the links between buildings in force (Base.links): a bonus for fielding a pair
	for l in Base.links(sv):
		_base_links.append([_base_slots.find(String(Base.LINKS[l].a)), _base_slots.find(String(Base.LINKS[l].b))])
		match String(l):
			"bulwark": _base_dr = clampf(_base_dr + 0.10, 0.0, 0.6)
			"hospital":
				_base_repair *= 1.5
				_base_heal *= 1.5
			"war_room": _crit_rate += 0.04
			"arsenal": damage_mult *= 1.05
			"drone_bay": _drone_mult *= 1.2
			"capacitor": _pulse_cd_mult = 0.75
			"prospector": _coin_mult *= 1.1

# With the turrets gone the hero does all the shooting. The turrets did nothing on the first
# stages and about a third of the damage from planet 3 on (16 g sweeps), so bug health comes down by
# that share: nothing to stage 5, sliding to NO_TURRET_HP by stage 20. First sweep without this:
# stages 30 and 60 lost by wave 4 with the hull at zero.
const NO_TURRET_HP := 0.64
func _no_turret_hp() -> float:
	return lerpf(1.0, NO_TURRET_HP, clampf((stage - 5) / 15.0, 0.0, 1.0))

# ------------------------------------------------------------------ THE SUPPORT DRONE (DroneData.SUPPORT, 2026-11-10)
# A second drone on the hero's other side that does a job instead of shooting: the Guard blocks a
# hit on the hero now and then, the Collector brings pickups in, the Medic mends him. It flies only
# while a Hangar stands on the base; the Hangar's level sets how good it is.
var _sup := ""
var _sup_lvl := 1
var _sup_p := Vector2.ZERO
var _sup_guard_t := 0.0
var _sup_flash := 0.0

func _setup_support(sv: Dictionary) -> void:
	_sup = String(DroneData.read(sv).get("support", "")) if (_drone_on and DroneData.support_open(sv)) else ""
	_sup_lvl = DroneData.hangar_level(sv)
	_sup_p = Vector2.ZERO
	_sup_guard_t = 3.0
	if _sup != "":
		_tex["sup"] = load("res://drone/%s.png" % String(DroneData.SUPPORT[_sup].art))

func _update_support(delta: float) -> void:
	if _sup == "":
		return
	_sup_flash = maxf(_sup_flash - delta * 2.5, 0.0)
	var tgt := soldier_pos + Vector2(54.0, 2.0 + sin(time_alive * 3.0 + 1.6) * 4.0)
	_sup_p = tgt if _sup_p == Vector2.ZERO else _sup_p.lerp(tgt, minf(1.0, delta * 7.0))
	match _sup:
		"shield":
			_sup_guard_t = maxf(_sup_guard_t - delta, 0.0)
		"collector":
			var reach := DroneData.collect_reach(_sup_lvl)
			for g in gems:
				if Vector2(g.pos).distance_to(_sup_p) < reach:
					g.pos = Vector2(g.pos).move_toward(soldier_pos, 320.0 * delta)
		"medic":
			if pilot_hp < pilot_hp_max:
				pilot_hp = minf(pilot_hp + pilot_hp_max * DroneData.medic_rate(_sup_lvl) * delta, pilot_hp_max)

# the Guard takes a hit meant for the hero; true = blocked
func _support_blocks() -> bool:
	if _sup != "shield" or _sup_guard_t > 0.0:
		return false
	_sup_guard_t = DroneData.guard_every(_sup_lvl)
	_sup_flash = 1.0
	inv_t = maxf(inv_t, 0.4)
	_fx_add("nova", soldier_pos, 60.0, 0.35, 0.0, 1.6, Color(0.31, 0.88, 1.0))
	_float_text(soldier_pos + Vector2(0, -52), "BLOCKED", Color(0.5, 0.92, 1.0))
	Sfx.play("shield")
	return true

func _draw_support() -> void:
	if _sup == "" or not _tex.has("sup"):
		return
	var tx: Texture2D = _tex["sup"]
	var col: Color = DroneData.SUPPORT[_sup].col
	var s := 38.0
	var h: float = s * tx.get_height() / tx.get_width()
	draw_set_transform(_sup_p, sin(time_alive * 1.3) * 0.08, Vector2.ONE)
	draw_texture_rect(tx, Rect2(-s * 0.5, -h * 0.5, s, h), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _sup == "shield":
		# its bubble round the hero: bright when a block is ready, a thin arc filling while it recharges
		var k: float = 1.0 - _sup_guard_t / DroneData.guard_every(_sup_lvl)
		if _sup_guard_t <= 0.0:
			draw_arc(soldier_pos, 34.0, 0.0, TAU, 40, Color(col, 0.35 + 0.15 * sin(time_alive * 4.0)), 1.5, true)
		else:
			draw_arc(soldier_pos, 34.0, -PI / 2.0, -PI / 2.0 + TAU * k, 40, Color(col, 0.2), 1.5, true)
	elif _sup == "medic" and pilot_hp < pilot_hp_max:
		draw_line(_sup_p, soldier_pos + Vector2(0, -10), Color(col, 0.35 + 0.2 * sin(time_alive * 8.0)), 1.5, true)
	if _sup_flash > 0.0:
		draw_arc(soldier_pos, 34.0 + 16.0 * (1.0 - _sup_flash), 0.0, TAU, 40, Color(col, _sup_flash), 2.5, true)

# THE FIRST FIGHT'S HINT (first-stages check, 2026-11-10): on stage 1, until it has been seen once,
# two short lines under the hero say how to play, because nothing else does (the tip boxes are off).
var _move_tip := 0.0

func _draw_move_tip() -> void:
	if _move_tip <= 0.0:
		return
	var a: float = clampf(_move_tip, 0.0, 1.0) * clampf((7.0 - _move_tip) * 2.0, 0.0, 1.0)
	var y: float = soldier_pos.y + 64.0
	_hc.draw_string(title_font, Vector2(0, y), "HOLD TO FIRE, DRAG TO FLY", HORIZONTAL_ALIGNMENT_CENTER, FIELD_W, 18, Color(1, 1, 1, a))
	_hc.draw_string(hud_font, Vector2(0, y + 20.0), "He fires straight up while your finger is down. Get under the bugs.", HORIZONTAL_ALIGNMENT_CENTER, FIELD_W, 12, Color(0.8, 0.86, 0.95, a))

# ---- THE CORE BASE in the fight (Backdrop.draw_core_base; stand-in shapes until Luna's art).
# A pod flashes when its building does something you can see: _pod_ping(id).
var _base_levels: Array = [0, 0, 0, 0]
var _base_open: Array = [false, false, false, false]
var _pod_ping_t: Array = [-9.0, -9.0, -9.0, -9.0]
var _pods: Array = []   # {mount, pos, drop, held_by}: the built pods, for the Wrecker to grab (it took turrets once)
var _base_links: Array = []   # [slot, slot] for every live link (Base.links): a gold line between the two pods
var _pulse_cd_mult := 1.0     # the Capacitor link shortens the Core Pulse s recharge

func _pod_held(i: int) -> bool:
	for p in _pods:
		if int(p.mount) == i and int(p.held_by) >= 0:
			for e in enemies:
				if int(e.id) == int(p.held_by):
					return true
	return false

func _pod_ping(id: String) -> void:
	var i := _base_slots.find(id)
	if i >= 0:
		_pod_ping_t[i] = time_alive

func _draw_core_base() -> void:
	var pods: Array = []
	for i in Base.SLOTS:
		var id: String = _base_slots[i]
		var pd := {"open": _base_open[i], "level": _base_levels[i], "flash": 1.0 - (time_alive - float(_pod_ping_t[i])) / 0.7}
		if id != "":
			pd["col"] = Color(1.0, 0.35, 0.3) if _pod_held(i) else Base.BUILDINGS[id].col
			pd["tex"] = _tex.get("bld_" + id)
		pods.append(pd)
	Backdrop.draw_core_base(self, FIELD_W, BASE_Y, FIELD_H, time_alive, pods, shield / maxf(shield_max, 1.0), _base_links)

# ------------------------------------------------------------------ CORE PULSE (2026-11-10)
# The base's own button (Rudy: "the base as a whole, one can act like a shield"). Tap the core:
# for PULSE_T seconds nothing can hurt the base, every bug close to it is stunned and takes a
# knock, enemy shots in the air are wiped, and a little shield comes back. Then it recharges for
# PULSE_CD seconds (the ring round the core fills). Opens after stage PULSE_FROM. AUTO presses it
# when the shield is low and a crowd is in. The base still never shoots: this is a wall, not a gun.
const PULSE_FROM := 7
const PULSE_T := 4.0
const PULSE_CD := 70.0
const PULSE_REACH := 300.0     # bugs this far above the base line or closer are caught
var _pulse_t := 20.0           # seconds until it is ready
var _pulse_live := 0.0         # seconds of the wall left
var _pulse_flash := 0.0
var _pulse_btn: Button
var _pulse_blocked := 0        # hits it stopped this fight (shown on nothing yet; for the sim)

func _pulse_open() -> bool:
	return (stage_unlocked > PULSE_FROM or DevTools.on) and not _mods.has("no_turrets")

func _pulse_setup() -> void:
	_pulse_t = 20.0
	_pulse_live = 0.0
	_pulse_flash = 0.0
	_pulse_blocked = 0
	if _pulse_btn == null:
		_pulse_btn = Button.new()
		_pulse_btn.flat = true
		_pulse_btn.focus_mode = Control.FOCUS_NONE
		_pulse_btn.size = Vector2(72, 60)
		for st in ["normal", "hover", "pressed", "focus", "disabled"]:
			_pulse_btn.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		_pulse_btn.pressed.connect(_use_pulse)
		add_child(_pulse_btn)

func _use_pulse() -> void:
	if not _pulse_open():
		_float_text(Backdrop.core_eye(FIELD_W, BASE_Y) + Vector2(0, -54), "Unlocks after stage %d" % PULSE_FROM, Color(0.75, 0.82, 0.92))
		return
	if _pulse_t > 0.0 or paused or picking or game_over or stage_cleared or _outro_t >= 0.0:
		return
	_pulse_t = PULSE_CD * _pulse_cd_mult
	_pulse_live = PULSE_T + _pulse_bonus
	_pulse_flash = 1.0
	_buzz(55)
	_ai_pulse = 1.0
	var eye := Backdrop.core_eye(FIELD_W, BASE_Y)
	_float_text(eye + Vector2(0, -DOME_RY - 8.0), "CORE PULSE!", Color(0.6, 0.95, 1.0), true)
	_fx_add("nova", eye, 320.0, 0.7, 0.0, 2.6, Color(0.31, 0.88, 1.0))
	shake = maxf(shake, 0.5)
	hitstop = maxf(hitstop, 0.08)
	Sfx.play("shield", 0.7)
	for e in enemies:
		if e.pos.y < BASE_Y - PULSE_REACH or not _can_hurt(e):
			continue
		if _is_boss(e):
			e.slow = 0.4
			e.slow_t = 2.5
		else:
			e.freeze_t = maxf(float(e.get("freeze_t", 0.0)), 2.0)
			var dmg: float = 0.15 * float(e.hp_max)
			e.hp -= dmg
			e.hit_t = HIT_FLINCH_T
			_count_dmg("base", dmg, e)
	enemy_bullets = enemy_bullets.filter(func(b): return b.pos.y < BASE_Y - PULSE_REACH)
	if shield < shield_max:
		shield = minf(shield + shield_max * 0.05, shield_max)
	for i in Base.SLOTS:
		_pod_ping_t[i] = time_alive

var _ai_pulse := 1.0
func _update_pulse(delta: float) -> void:
	_pulse_t = maxf(_pulse_t - delta, 0.0)
	_pulse_live = maxf(_pulse_live - delta, 0.0)
	_pulse_flash = maxf(_pulse_flash - delta * 1.6, 0.0)
	if _pulse_btn:
		_pulse_btn.position = Backdrop.core_eye(FIELD_W, BASE_Y) - Vector2(36, 30)
		_pulse_btn.visible = _pulse_open()
	# AUTO: the shield is low and a crowd is close, a second late
	if auto_on and not dragging and _pulse_t <= 0.0 and _pulse_open() and shield < shield_max * 0.6:
		var near := 0
		for e in enemies:
			near += 1 if e.pos.y > BASE_Y - PULSE_REACH else 0
		if near >= 4:
			_ai_pulse -= delta
			if _ai_pulse <= 0.0:
				_use_pulse()
		else:
			_ai_pulse = 1.0

# over the core: the charge ring, READY, and the wall itself while it stands
func _draw_pulse() -> void:
	if not _pulse_open():
		return
	var eye := Backdrop.core_eye(FIELD_W, BASE_Y)
	var cyan := Color(0.31, 0.88, 1.0)
	var ready := _pulse_t <= 0.0
	if ready:
		var beat := 0.5 + 0.5 * sin(time_alive * 5.0)
		draw_arc(eye, 21.0 + 2.0 * beat, 0.0, TAU, 48, Color(1.0, 0.78, 0.27, 0.7 + 0.3 * beat), 2.5, true)
	else:
		draw_arc(eye, 21.0, 0.0, TAU, 48, Color(1, 1, 1, 0.1), 2.0, true)
		draw_arc(eye, 21.0, -PI / 2.0, -PI / 2.0 + TAU * (1.0 - _pulse_t / (PULSE_CD * _pulse_cd_mult)), 48, Color(cyan, 0.85), 2.5, true)
	if _pulse_live > 0.0:
		var k := _pulse_live / PULSE_T
		var c := Vector2(FIELD_W * 0.5, BASE_Y)
		var pts := Backdrop._ell_pts(c, DOME_RX + 4.0, DOME_RY + 4.0, PI, TAU)
		draw_polyline(pts, Color(1, 1, 1, 0.35 + 0.4 * k), 5.0, true)
		draw_polyline(pts, Color(cyan, 0.9), 2.0, true)
		draw_colored_polygon(Backdrop._ell_pts(c, DOME_RX, DOME_RY, PI, TAU), Color(cyan, 0.06 + 0.06 * sin(time_alive * 12.0)))
	if _pulse_flash > 0.0:
		draw_arc(eye, 21.0 + 150.0 * (1.0 - _pulse_flash), 0.0, TAU, 64, Color(cyan, _pulse_flash), 3.0, true)

# capture hook (tools/dev/capture.gd CAP_CALL="_dbg_pulse"): the Core Pulse fires now
func _dbg_pulse() -> void:
	_pulse_t = 0.0
	_use_pulse()

# RESEARCH (Research.bonus): the lab's finished levels, on top of everything else
func _apply_research(sv: Dictionary) -> void:
	var rb := Research.bonus(sv)
	shield_max *= 1.0 + float(rb.shield)
	shield = shield_max
	hull_max *= 1.0 + float(rb.hull)
	hull = hull_max
	damage_mult *= 1.0 + float(rb.damage)
	pilot_hp_max = roundf(pilot_hp_max * (1.0 + float(rb.hp)))
	pilot_hp = pilot_hp_max
	_crit_rate += float(rb.crit)
	_drone_mult *= 1.0 + float(rb.drone)
	_ult_cd /= 1.0 + float(rb.ability)
	_coin_mult *= 1.0 + float(rb.coins)

# ---- SETTINGS read at the stage start (settings.gd): the buzz, the shake, the numbers, auto-advance
var _haptics := true
var _shake_mult := 1.0
var _dmg_numbers := true
var _auto_next := false

func _buzz(ms: int) -> void:
	if _haptics and not OS.has_feature("editor") and DisplayServer.get_name() != "headless":
		Input.vibrate_handheld(ms)

# ---- SPECIAL WAVES (2026-11-10): from stage SPECIAL_FROM about one wave in four comes with a
# twist, named on screen as it starts, so a stage is not ten of the same wave. Never the first
# wave or the last (the boss's). Which waves are special is fixed per stage, so a replay can plan.
#   swarm: nearly twice the bugs, each half as tough      heavy: fewer bugs, much tougher
#   rush:  they fly a third faster, a little weaker        gold:  clear it and a pile of coins drops
const SPECIAL_FROM := 8
const WAVE_KINDS := {
	"swarm": {"name": "SWARM", "text": "twice the bugs, half as tough", "count": 1.9, "hp": 0.5, "col": Color(1.0, 0.6, 0.3)},
	"heavy": {"name": "HEAVY WAVE", "text": "fewer bugs, much tougher", "count": 0.6, "hp": 1.8, "col": Color(0.75, 0.8, 0.9)},
	"rush":  {"name": "RUSH", "text": "they come fast", "hp": 0.85, "speed": 1.3, "col": Color(1.0, 0.45, 0.5)},
	"gold":  {"name": "GOLD RUSH", "text": "clear it for a pile of coins", "col": Color(1.0, 0.82, 0.3)},
}
const WAVE_KIND_ORDER := ["swarm", "heavy", "rush", "gold"]
var _wave_kind := ""
var _wave_hp := 1.0
var _wave_speed := 1.0

func _wave_kind_for(w: int) -> String:
	if stage < SPECIAL_FROM or horde or boss_rush or run_mode or w <= 0 or w >= waves.size() - 1:
		return ""
	var h: int = absi((stage * 7919 + w * 104729 + (5003 if elite else 0)) % 1000)
	if h >= 260:
		return ""
	return String(WAVE_KIND_ORDER[absi(stage * 13 + w * 17 + h) % WAVE_KIND_ORDER.size()])

# ------------------------------------------------------------------ THE HIVE MOTHER SHOOTS (Rudy, dev265 playtest:
# "fairly easy; she should shoot as well as hatch, in a variety of ways, maybe a poison effect")
# Between broods she attacks in turn: a FAN of goo, a quick BURST aimed at the hero, and (the full
# boss only) a slow POISON glob: a lighter hit that then eats at him for POISON_T seconds. Her
# mouth lights up HM_WARN seconds before each attack. Angry (under half health) she attacks
# sooner and with more. The young one (mini) only knows the smaller fan and burst.
const HM_EVERY := 3.6
const HM_WARN := 0.6
const POISON_T := 4.0
const POISON_DPS := 0.025     # share of the hero's max health a second (never the last point)
var _poison_t := 0.0

func _boss_mouth(e: Dictionary) -> Vector2:
	return e.pos + Vector2(0.0, float(e.r) * 0.85)

func _boss_glob(e: Dictionary, dir: Vector2, kind: String, speed: float) -> void:
	var mouth := _boss_mouth(e)
	enemy_bullets.append({"pos": mouth + dir * 6.0, "vel": dir * speed, "kind": "bossgoo" if kind == "goo" else kind, "ph": rng.randf() * TAU, "boss": true})
	for k in 3:
		sparks.append({"pos": mouth, "vel": dir.rotated(rng.randf_range(-0.8, 0.8)) * rng.randf_range(30, 90), "life": 0.3,
			"col": Color(0.5, 1.0, 0.35) if kind == "poison" else Color(0.75, 0.4, 1.0)})

func _boss_attack(e: Dictionary, delta: float) -> void:
	if float(e.get("laying", 0.0)) > 0.0 or float(e.get("freeze_t", 0.0)) > 0.0:
		return   # busy hatching, or frozen
	var mini: bool = e.get("mini", false)
	var enraged: bool = e.hp < e.hp_max * 0.5
	var aim: Vector2 = (soldier_pos - _boss_mouth(e)).normalized()
	# the rest of a burst
	if int(e.get("atk_left", 0)) > 0:
		e.atk_gap = float(e.get("atk_gap", 0.0)) - delta
		if float(e.atk_gap) <= 0.0:
			e.atk_gap = 0.22
			e.atk_left = int(e.atk_left) - 1
			_boss_glob(e, aim.rotated(rng.randf_range(-0.06, 0.06)), "goo", 170.0)
			Sfx.play("spit", rng.randf_range(1.0, 1.15))
		return
	var before: float = float(e.get("atk_t", 2.6))
	e.atk_t = before - delta
	if before > HM_WARN and float(e.atk_t) <= HM_WARN:
		Sfx.play("spit", 0.8)   # the warning starts
	if float(e.atk_t) > 0.0:
		return
	e.atk_t = HM_EVERY * (1.3 if mini else 1.0) * (0.72 if enraged else 1.0)
	e.atk_n = int(e.get("atk_n", 0)) + 1
	var kinds: int = 2 if mini else 3
	match int(e.atk_n) % kinds:
		1:   # the fan
			var n: int = 3 if mini else (7 if enraged else 5)
			var spread: float = 0.55 if mini else 0.95
			for i in n:
				_boss_glob(e, aim.rotated(lerpf(-spread * 0.5, spread * 0.5, float(i) / float(n - 1))), "goo", 135.0)
			Sfx.play("spit")
		0 when not mini:   # poison: one slow glob, two when angry
			_boss_glob(e, aim, "poison", 112.0)
			if enraged:
				_boss_glob(e, aim.rotated(0.4 if rng.randf() < 0.5 else -0.4), "poison", 112.0)
			Sfx.play("spit", 0.7)
		_:   # the burst: the first now, the rest a beat apart
			_boss_glob(e, aim, "goo", 170.0)
			e.atk_left = (1 if mini else 2) + (1 if enraged else 0)
			e.atk_gap = 0.22
			Sfx.play("spit", 1.1)

# her mouth lights before an attack: a ring closing on it, green before poison
func _draw_boss_warn(e: Dictionary, _size: float) -> void:
	if not e.get("arrived", false) or float(e.get("laying", 0.0)) > 0.0 or int(e.get("atk_left", 0)) > 0:
		return
	var t: float = float(e.get("atk_t", 9.0))
	if t > HM_WARN or t <= 0.0:
		return
	var k: float = 1.0 - t / HM_WARN
	var kinds: int = 2 if e.get("mini", false) else 3
	var poison: bool = kinds == 3 and (int(e.get("atk_n", 0)) + 1) % 3 == 0
	var col := Color(0.5, 1.0, 0.35) if poison else Color(1.0, 0.45, 0.75)
	var m := _boss_mouth(e)
	draw_circle(m, 10.0 + 6.0 * k, Color(col, 0.18 + 0.2 * k))
	draw_arc(m, 34.0 - 22.0 * k, 0.0, TAU, 28, Color(col, 0.35 + 0.5 * k), 2.0, true)

func _update_poison(delta: float) -> void:
	if _poison_t <= 0.0:
		return
	_poison_t -= delta
	var loss: float = minf(pilot_hp_max * POISON_DPS * delta, maxf(pilot_hp - 1.0, 0.0))
	if loss > 0.0:
		pilot_hp -= loss
		_hp_lost += loss
		_took_damage = true

# poisoned: a green haze round the hero with bubbles rising, and the seconds left
func _draw_poison() -> void:
	if _poison_t <= 0.0:
		return
	var a: float = clampf(_poison_t / 0.5, 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(time_alive * 6.0)
	draw_circle(soldier_pos, 26.0 + 3.0 * pulse, Color(0.4, 1.0, 0.3, 0.12 * a))
	draw_arc(soldier_pos, 27.0 + 3.0 * pulse, 0.0, TAU, 28, Color(0.55, 1.0, 0.4, 0.55 * a), 1.5, true)
	for i in 4:
		var ph: float = fmod(time_alive * 0.9 + float(i) * 0.25, 1.0)
		draw_circle(soldier_pos + Vector2(sin(float(i) * 2.4 + time_alive) * 18.0, 14.0 - 44.0 * ph), 2.6 * (1.0 - ph), Color(0.6, 1.0, 0.45, 0.8 * (1.0 - ph) * a))
	draw_string(hud_font, soldier_pos + Vector2(-30.0, 46.0), "POISON %ds" % ceili(_poison_t), HORIZONTAL_ALIGNMENT_CENTER, 60.0, 10, Color(0.6, 1.0, 0.45, a))

func _dbg_boss_attack() -> void:
	for e in enemies:
		if e.type == "hive_mother":
			e.arrived = true
			e.atk_t = 0.01

# TOUGHER BUGS (Rudy, dev271 playtest: "you shoot them a few times and your weapons drill right
# through", "I can get shot multiple times and my health just goes down a little"). Three dials, all
# gentle on the first stages and full from stage 6: bug health, what a hit does to the hero (his
# health grows with his level, a bug's hit did not: it now grows a little every stage), and what a
# bug does to the base.
const TOUGH_HP := 1.15         # to stage 20, easing to TOUGH_LATE by stage 30 (1.3 everywhere lost every stage-30 and stage-45 test: the base fell by wave 4)
const TOUGH_LATE := 1.05
const HIT_HERO := 1.6
const HIT_HERO_STAGE := 0.03
const HIT_BASE := 1.15
const HIT_BASE_STAGE := 0.0
static var TOUGH_ON := true   # the sim can switch it off to compare

func _ease_in() -> float:
	return clampf((stage - 1) / 5.0, 0.0, 1.0)

func _tough() -> float:
	return lerpf(1.0, lerpf(TOUGH_HP, TOUGH_LATE, clampf((stage - 20) / 10.0, 0.0, 1.0)), _ease_in()) if TOUGH_ON else 1.0

func _enemy_hit() -> float:
	return lerpf(1.0, HIT_HERO, _ease_in()) * (1.0 + HIT_HERO_STAGE * maxi(stage - 6, 0)) if TOUGH_ON else 1.0

func _base_hit() -> float:
	return lerpf(1.0, lerpf(HIT_BASE, 1.0, clampf((stage - 20) / 10.0, 0.0, 1.0)), _ease_in()) if TOUGH_ON else 1.0   # back to 1 by stage 30: the base is already the tight spot there

func _dbg_leave() -> void:   # captures: the pause menu with the "leave the stage?" card over it
	_toggle_pause()
	_confirm_leave()
