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
const SENTRY_HEAD_CX := 0.468              # visual centre of the head picture across its width
# charge-up glow colour at the weapon tip, for turrets that wait on a cooldown
const CHARGE_COL := {"storm": Color(0.71, 0.55, 1.0), "swarm": Color(1.0, 0.75, 0.3), "prism": Color(0.85, 0.9, 1.0)}
const FX_NAMES := ["sentry_tracer", "spark", "lance_flare", "lance_beam", "storm_zap", "gravity_ring", "crush", "drone", "pop", "prism_beam", "prism_burst", "bolt", "impact", "nova"]
const FIRE_TIME := {"sentry": 0.14, "lance": 0.3, "storm": 0.22, "gravity": 0.3, "swarm": 0.25, "prism": 0.3}   # how long each turret's firing art shows
const SAVE := "user://skybound_save.json"

# ---- weapons ----
const WEAPONS := {
	"laser_pistol": {"name": "Laser Pistol", "interval": 0.22, "speed": 520.0, "damage": 1.0, "projectiles": 1, "spread": 0.0, "hit_radius": 22.0},
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
var hull_max := 100.0
var shield_max := 150.0
var card_levels := {}

# ---- state ----
var stage := 1
var elite := false
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
var _stars_got := 0
var _level_before := 1
var _level_after := 1
var drones: Array = []            # Swarm Hive micro-drones {type, pos, vel, life, dmg}
var fxs: Array = []               # short effect sprites {tex, pos, size, rot, life, max, grow, col}
var _fx: Node2D                   # additive effect layer
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
var _boss_bar_hp := 0.0
var _boss_bar_max := 0.0

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
	_tex["sentry_base"] = load("res://turrets/sentry_base.png")
	for i in 4:
		_tex["gem_%d" % i] = load("res://pickups/gem_%d.png" % i)
	_tex["goo"] = load("res://fx/goo.png")
	_tex["ui_heart"] = load("res://icons/ui_heart.png")
	for n in ["lid_closed", "lid_half", "lid_open"]:
		_tex[n] = load("res://base/%s.png" % n)
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
	add_child(_fx)
	for n in ["hive_lay_1", "hive_lay_2", "hive_lay_3", "hive_lay_4", "hive_hatchling"]:
		_tex[n] = load("res://enemies/%s.png" % n)
	_load()
	_build_ui()
	_start_stage()

func _load() -> void:
	var d := _read_save()
	stage = int(d.get("selected_stage", 1))
	elite = bool(d.get("selected_elite", false))
	var t := Turrets.read(d)
	turret_loadout = t.loadout
	turret_levels = t.levels

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
	waves = StageData.waves(stage)
	wave_index = 0
	stage_cleared = false
	game_over = false
	hearts = 3
	max_hearts = 3
	shield_max = 150.0
	hull_max = 100.0
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
	_took_damage = false
	_stars_got = 0
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
	if wave_index >= waves.size():
		return
	for entry in waves[wave_index]:
		for i in int(entry[1]):
			wave_queue.append(entry[0])
	wave_queue.shuffle()
	# the boss always comes last
	if wave_queue.has("hive_mother"):
		wave_queue.erase("hive_mother")
		wave_queue.append("hive_mother")
	wave_spawn_t = 0.6
	_float_text(Vector2(FIELD_W * 0.5, 160), "WAVE %d" % (wave_index + 1), Color(0.75, 0.97, 1.0), true)

func _spawn(id: String) -> void:
	var e := _make_enemy(id, Vector2(rng.randf_range(40.0, FIELD_W - 40.0), 60.0))
	if id == "hive_mother":
		e.pos = Vector2(FIELD_W * 0.5, 40.0)
		# the mini-boss that ends zone A is a younger, smaller Hive Mother
		if StageData.boss_kind(stage) == "mini":
			e.mini = true
			e.hp *= 0.6
			e.hp_max *= 0.6
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
		"hp": float(def.hp) * StageData.hp_mult(stage, elite), "hp_max": float(def.hp) * StageData.hp_mult(stage, elite),
		"speed": float(def.speed) * StageData.speed_mult(stage), "r": float(def.size) * 0.4, "ph": rng.randf() * TAU,
		"state": "fly", "t": 0.0, "vel": Vector2.ZERO, "fire_t": rng.randf_range(1.0, 2.5), "lay_t": 3.0, "laying": 0.0,
		"dart_t": rng.randf_range(0.3, 1.0), "dart_vx": 0.0, "dodge_v": 0.0, "dodge_cd": 0.0, "feinted": false}
	next_enemy_id += 1
	return e

# ------------------------------------------------------------------ input

func _input(event: InputEvent) -> void:
	if paused or picking or game_over or stage_cleared:
		return
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

func _drag_by(d: Vector2) -> void:
	soldier_pos.x = clampf(soldier_pos.x + d.x, 24.0, FIELD_W - 24.0)
	soldier_pos.y = clampf(soldier_pos.y + d.y, 110.0, BASE_Y - 40.0)

# ------------------------------------------------------------------ frame

func _process(delta: float) -> void:
	var vp_h: float = get_viewport_rect().size.y
	if absf(vp_h - FIELD_H) > 0.5:
		FIELD_H = vp_h
		BASE_Y = FIELD_H - 14.0
	if paused or picking or game_over or stage_cleared:
		position = Vector2.ZERO
		queue_redraw()
		return
	delta *= game_speed
	# hit feel: a big kill slows the world for a blink; hits shake the screen a little
	if hitstop > 0.0:
		hitstop -= delta
		delta *= 0.2
	shake = maxf(shake - delta * 3.5, 0.0)
	var sk := shake * shake * 5.0
	position = Vector2(sin(time_alive * 93.0), cos(time_alive * 71.0)) * sk
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
	var vy: float = (soldier_pos.y - prev_soldier_y) / maxf(delta, 0.001)
	prev_soldier_y = soldier_pos.y
	vy_smooth = lerpf(vy_smooth, vy, 0.15)
	# shield regenerates after 4 s without a hit
	if hit_t > 4.5 and shield < shield_max:
		shield = minf(shield + 6.0 * delta, shield_max)
	_aim_and_fire(delta)
	_spawn_step(delta)
	_update_bullets(delta)
	_update_enemies(delta)
	_update_gems(delta)
	_update_turrets(delta)
	_step_effects(delta)
	_pilot_motion(delta)
	anim.update(_wanted_pose(), delta)
	if hearts <= 0 or hull <= 0.0:
		_end_run(false)
	elif wave_queue.is_empty() and enemies.is_empty() and not stage_cleared:
		wave_index += 1
		if wave_index >= waves.size():
			_end_run(true)
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
			_fire(_muzzle_world() + burst_dir * 4.0, burst_dir, burst_tid)
	var interval: float = float(weapon.interval) / fire_rate_mult
	if burst_count > 1:
		interval *= 1.0 + 0.35 * (burst_count - 1)
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

func _fire(origin: Vector2, dir: Vector2, target_id: int = -2) -> void:
	var w: Dictionary = WEAPONS[weapon_id]
	var count: int = int(w.projectiles) + extra_projectiles
	var spread: float = float(w.spread) + 0.18 * extra_projectiles
	for i in count:
		var off := 0.0
		if count > 1:
			off = lerpf(-spread * 0.5, spread * 0.5, float(i) / float(count - 1))
		bullets.append({"pos": origin, "vel": dir.rotated(off) * float(w.speed), "dmg": float(w.damage) * damage_mult,
			"r": float(w.hit_radius), "tid": target_id, "col": "cyan"})
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
	for b in bullets:
		b.pos += b.vel * delta
		var hit := false
		for e in enemies:
			if b.pos.distance_to(e.pos) < float(b.r) + float(e.r) * 0.5:
				var dmg: float = float(b.dmg)
				if e.type == "hive_mother" and e.laying > 1.2:
					dmg *= 2.0   # weak spot open while she lays
				if b.has("src"):
					dmg *= Turrets.trait_mult(b.src, StageData.ENEMIES[e.type].traits)
					stat_turret_dmg += minf(dmg, maxf(e.hp, 0.0))
					_fx_add("spark", b.pos, 34.0, 0.28, rng.randf() * TAU)
				else:
					stat_pilot_dmg += minf(dmg, maxf(e.hp, 0.0))
					_fx_add("impact", b.pos, 26.0, 0.22, rng.randf() * TAU, 1.6)
				e.hp -= dmg
				hit = true
				stat_hits += 1
				for k in 3:
					sparks.append({"pos": b.pos, "vel": Vector2(rng.randf_range(-100, 100), rng.randf_range(-100, 100)), "life": 0.3, "col": Color(0.2, 0.85, 1.0)})
				break
		if not hit and b.pos.y > -30.0 and b.pos.y < FIELD_H + 30.0 and b.pos.x > -30.0 and b.pos.x < FIELD_W + 30.0:
			live.append(b)
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
			_hurt_base(6.0)
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
				e.fire_t -= delta
				if e.fire_t <= 0.0 and e.pos.y > 40.0:
					e.fire_t = float(def.fire_every)
					e.shots = int(e.get("shots", 0)) + 1
					# every other shot goes for the base instead of the pilot
					var aim_at: Vector2 = soldier_pos if e.shots % 4 != 0 else Vector2(e.pos.x + rng.randf_range(-60, 60), BASE_Y - 40.0)
					# a goo glob leaves the mouth of the sac on the art
					var mouth := EnemyRig.anchor("spitter", "muzzle", e.pos, float(def.size) * 1.35, float(e.get("tilt_s", 0.0)))
					var dir: Vector2 = (aim_at - mouth).normalized()
					enemy_bullets.append({"pos": mouth + dir * 4.0, "vel": dir * 135.0, "kind": "goo", "ph": rng.randf() * TAU})
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
				var hover_y := 165.0 + (90.0 if enraged else 0.0)
				if e.pos.y < hover_y:
					e.pos.y += e.speed * delta
				else:
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
						var s := {"id": next_enemy_id, "type": "scout", "pos": e.pos + Vector2(float(k - 1) * 22.0, -30.0),
							"hp": 2.0 * StageData.hp_mult(stage, elite), "hp_max": 2.0 * StageData.hp_mult(stage, elite),
							"speed": 62.0 * StageData.speed_mult(stage), "r": 13.6, "ph": rng.randf() * TAU,
							"state": "hatch", "t": 0.0, "vel": Vector2(float(k - 1) * 45.0, -70.0), "fire_t": 9.0, "lay_t": 0.0, "laying": 0.0,
							"hatchling": true, "fold": 1.0}
						next_enemy_id += 1
						live.append(s)
					_burst(e.pos + Vector2(0, -32), 22.0, Color(0.71, 0.55, 1.0), 12)   # the sacs on her back burst
		e.vel = (e.pos - prev) / maxf(delta, 0.001)
		# tilt and wing fold ease toward their targets so dives and hatches never snap
		e.tilt_s = lerp_angle(float(e.get("tilt_s", _enemy_tilt(e))), _enemy_tilt(e), minf(1.0, delta * 10.0))
		var want_fold: float = 1.0 if _lunging(e) or (e.state == "hatch" and e.t < 0.45) else 0.0
		e.fold = move_toward(float(e.get("fold", want_fold)), want_fold, delta * 5.0)
		if e.type == "hive_mother":
			_boss_bar_hp = e.hp
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
	kills += 1
	coins_earned += int(def.coins)
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

func _update_gems(delta: float) -> void:
	var live: Array = []
	for g in gems:
		g.life -= delta
		var d: float = g.pos.distance_to(soldier_pos)
		g.pull = d < magnet_radius
		if g.pull:
			g.pos = g.pos.move_toward(soldier_pos, (320.0 + (magnet_radius - d) * 4.0) * delta)
		else:
			g.vel.y = minf(g.vel.y + 70.0 * delta, 55.0)
			g.vel.x *= 0.98
			g.pos += g.vel * delta

		if d < 16.0:
			_gain_xp(float(StageData.GEM_XP[g.tier]))
			_burst(soldier_pos, 4.0, StageData.GEM_COLORS[g.tier], 3)
			_fx_add("spark", g.pos, 20.0 + 4.0 * g.tier, 0.2, 0.0, 1.7, StageData.GEM_COLORS[g.tier])   # pop
			continue
		if g.life <= 0.0 or g.pos.y > BASE_Y - DOME_RY * 0.5:
			continue
		live.append(g)
	gems = live

func _gain_xp(amount: float) -> void:
	run_xp += amount
	var need := _xp_need()
	if run_xp >= need:
		run_xp -= need
		run_level += 1
		_float_text(soldier_pos + Vector2(0, -40), "LEVEL %d" % run_level, Color(0.85, 0.75, 1.0), true)
		_open_cards()

func _xp_need() -> float:
	var base := 4.0 + 3.5 * (run_level - 1)   # the first card after 2 kills, then about one every 12-15 s
	if run_level > 12:
		base *= pow(2.0, run_level - 12)   # past the cap, picks keep coming but much slower
	return base

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
	turrets.append({"type": type, "lvl": lvl, "mount": mount, "pos": _socket(mount), "cd": 0.5 + 0.3 * mount,
		"fire_t": 0.0, "ang": -PI / 2.0, "face": 1.0, "charge": 0.0, "build": 0.0, "bolt": [],
		"drop": 0.0, "drop_wait": 0.0 if fx else 0.3 + 0.18 * mount})
	return true

func _socket(i: int) -> Vector2:
	return Backdrop.socket_pos(i, FIELD_W, FIELD_H - STRIP_LIFT)

func _turret_dmg(t: Dictionary) -> float:
	return float(Turrets.TURRETS[t.type].damage) * Turrets.level_mult(int(t.lvl))

func _turret_hit(t: Dictionary, e: Dictionary, dmg: float) -> void:
	dmg *= Turrets.trait_mult(t.type, StageData.ENEMIES[e.type].traits)
	stat_turret_dmg += minf(dmg, maxf(e.hp, 0.0))
	e.hp -= dmg

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
			"lance": _update_lance(t, delta)
			"storm": _update_storm(t, delta)
			"gravity": _update_gravity(t, delta)
			"swarm": _update_swarm(t, delta)
			"prism": _update_prism(t, delta)
			_: _update_sentry(t, delta)
	_update_drones(delta)

func _update_sentry(t: Dictionary, delta: float) -> void:
	var def: Dictionary = Turrets.TURRETS[t.type]
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
		t.ang = lerp_angle(t.ang, (enemies[best].pos - t.pos).angle(), 0.12)
		t.swing = lerpf(float(t.get("swing", 0.0)), angle_difference(prev_ang, t.ang) / maxf(delta, 0.001), 0.2)
		t.face = move_toward(float(t.face), -1.0 if cos(t.ang) > 0.05 else (1.0 if cos(t.ang) < -0.05 else float(t.face)), delta * 6.0)
		t.cd -= delta
		if t.cd <= 0.0:
			t.cd = float(def.every)
			t.fire_t = FIRE_TIME.sentry
			t.hov_v = float(t.hov_v) + 55.0      # the shot pushes the head down toward its base
			var dir := Vector2.from_angle(t.ang)
			bullets.append({"pos": _turret_tip(t), "vel": dir * 360.0, "dmg": _turret_dmg(t), "r": 18.0, "tid": -2, "col": "tracer", "src": t.type})
	else:
		t.swing = lerpf(float(t.get("swing", 0.0)), 0.0, 0.2)

func _lance_in_column(t: Dictionary, e: Dictionary) -> bool:
	return absf(e.pos.x - t.pos.x) < float(Turrets.TURRETS.lance.width) * 0.5 + float(e.r) * 0.6 and e.pos.y > 100.0 and e.pos.y < t.pos.y

# Lance Pylon: charges, then holds the charge until something is in its column,
# and fires a spear of light straight up that hits everything in that column
# (enemy shots included).
func _update_lance(t: Dictionary, delta: float) -> void:
	var def: Dictionary = Turrets.TURRETS.lance
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
	t.charge = 0.0
	t.fire_t = FIRE_TIME.lance
	var dmg := _turret_dmg(t)
	for e in enemies:
		if _lance_in_column(t, e):
			_turret_hit(t, e, dmg)
			for k in 3:
				_fx_add("lance_flare", e.pos, 44.0, 0.3, 0.0, 1.4)
	var half: float = float(def.width) * 0.5
	enemy_bullets = enemy_bullets.filter(func(b): return absf(b.pos.x - t.pos.x) > half)

func _storm_centre(t: Dictionary) -> Vector2:
	var def: Dictionary = Turrets.TURRETS.storm
	var sway: float = sin(time_alive * 0.4 + float(t.mount)) * 18.0
	return Vector2(clampf(t.pos.x, float(def.cloud_r) * 0.7, FIELD_W - float(def.cloud_r) * 0.7) + sway, BASE_Y - float(def.cloud_h))

# Storm Spire: the cloud builds over 3 s; then lightning strikes the enemy
# nearest the cloud's middle and jumps to up to `chain` more nearby (70% each).
func _update_storm(t: Dictionary, delta: float) -> void:
	var def: Dictionary = Turrets.TURRETS.storm
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
	var def: Dictionary = Turrets.TURRETS.gravity
	return Vector2(clampf(t.pos.x, float(def.radius), FIELD_W - float(def.radius)), BASE_Y - float(def.height))

# Gravity Anchor: for the last `pull` seconds of each cycle it drags enemies near
# its well toward the middle (bosses are too heavy), then crushes everything in
# the inner circle with a pulse. With nothing in reach it keeps pulling and waits.
func _update_gravity(t: Dictionary, delta: float) -> void:
	var def: Dictionary = Turrets.TURRETS.gravity
	var c := _gravity_centre(t)
	t.cd = maxf(t.cd - delta, 0.0)
	var catching := false
	var in_crush := false
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
	var def: Dictionary = Turrets.TURRETS.swarm
	t.cd -= delta
	if t.cd > 0.0:
		return
	var any := false
	for e in enemies:
		if e.pos.y > 100.0:
			any = true
			break
	if not any:
		t.cd = 0.2
		return
	t.cd = float(def.every)
	t.fire_t = FIRE_TIME.swarm
	for i in int(def.count):
		var a: float = -PI / 2.0 + lerpf(-0.7, 0.7, float(i) / maxf(float(def.count) - 1.0, 1.0))
		drones.append({"type": "swarm", "pos": _turret_tip(t), "vel": Vector2.from_angle(a) * 120.0,
			"life": float(def.life), "age": 0.0, "dmg": _turret_dmg(t)})

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
	var def: Dictionary = Turrets.TURRETS.prism
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
	hit_t = 0.0
	_took_damage = true
	shake = maxf(shake, 0.45 if shield <= 0.0 else 0.3)
	if shield > 0.0:
		shield = maxf(shield - amount, 0.0)
	else:
		hull = maxf(hull - amount, 0.0)

func _hurt_pilot() -> void:
	if inv_t > 0.0:
		return
	inv_t = 1.5
	hearts -= 1
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
	else:
		game_over = true
	dragging = false
	var d := _read_save()
	# pilot XP: what you destroyed, plus a bonus the first time this stage is cleared
	var was := int(d.get("stage_unlocked", 1))
	var old_xp := int(d.get("pilot_xp", 0))
	_xp_bonus = Turrets.first_clear_bonus(stage) if won and not elite and stage >= was else 0
	_xp_gain = int(score / 50) + _xp_bonus
	_level_before = Turrets.pilot_level(old_xp)
	_level_after = Turrets.pilot_level(old_xp + _xp_gain)
	var patch := {"coins": int(d.get("coins", 0)) + coins_earned, "best_score": maxi(score, int(d.get("best_score", 0))),
		"best_kills": maxi(kills, int(d.get("best_kills", 0))), "pilot_xp": old_xp + _xp_gain}
	# stars for the stage map: 1 cleared, 2 base above half hull, 3 no damage at all
	if won and not elite:
		var got := 1 + (1 if hull >= hull_max * 0.5 else 0) + (1 if hull >= hull_max and hearts >= max_hearts and not _took_damage else 0)
		var st = d.get("stars", {})
		if typeof(st) != TYPE_DICTIONARY:
			st = {}
		st[str(stage)] = maxi(int(st.get(str(stage), 0)), got)
		patch["stars"] = st
		_stars_got = got
	if won:
		patch["stage_unlocked"] = maxi(stage + 1, was)
		if Turrets.mounts_open(patch["stage_unlocked"]) > Turrets.mounts_open(was):
			_new_mount = Turrets.mounts_open(patch["stage_unlocked"]) - 1
		stage_unlocked = patch["stage_unlocked"]
	_write_save(patch)
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
	# pause menu: the battle dims behind a panel in the Home style; Back to Hub lives here
	_pause_panel = Control.new()
	_pause_panel.size = get_viewport_rect().size
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.01, 0.04, 0.55)
	dim.size = _pause_panel.size
	_pause_panel.add_child(dim)
	var box := UIKit.panel(16)
	box.position = Vector2(FIELD_W * 0.5 - 130, _pause_panel.size.y * 0.5 - 130)
	box.custom_minimum_size = Vector2(260, 0)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 12)
	var title := UIKit.label("PAUSED", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_override("font", title_font)
	pv.add_child(title)
	pv.add_child(UIKit.label("%d  %s" % [stage, StageData.stage_name(stage).to_upper()], 12, UIKit.CYAN, HORIZONTAL_ALIGNMENT_CENTER))
	var resume := UIKit.gold_button("Resume")
	resume.custom_minimum_size = Vector2(0, 46)
	resume.pressed.connect(_toggle_pause)
	pv.add_child(resume)
	var quit_b := UIKit.ghost_button("Back to Hub", 14)
	quit_b.custom_minimum_size = Vector2(0, 40)
	quit_b.pressed.connect(func(): get_tree().change_scene_to_file("res://hub.tscn"))
	pv.add_child(quit_b)
	pv.add_child(UIKit.label("Leaving ends this run.", 11, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(pv)
	_pause_panel.add_child(box)
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

func _toggle_pause() -> void:
	if _cards_open:
		_toggle_cards()
		return
	if picking or game_over or stage_cleared:
		return
	paused = not paused
	_pause_panel.visible = paused
	# the tap on the pause button also started a drag; drop it so he does not keep firing
	dragging = false
	drag_id = -1
	queue_redraw()

func _open_cards() -> void:
	picking = true
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
	var picks := Cards.draw(card_levels, 3, rng)
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
	_card_panel.add_child(refresh)
	_card_panel.visible = true

func _make_card(id: String, pos: Vector2, size: Vector2) -> Control:
	var def: Dictionary = Cards.CARDS[id]
	var lvl: int = int(card_levels.get(id, 0))
	var col: Color = Cards.COLOR[def.rarity]
	var b := Button.new()
	b.position = pos
	b.size = size
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var frame := TextureRect.new()
	frame.texture = load(Cards.FRAME[def.rarity])
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(frame)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 16; v.offset_right = -16; v.offset_top = 22; v.offset_bottom = -18
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	# Luna's card picture (cards/pic_<id>.png) when there is one, else the menu icon
	var pic_path := "res://cards/pic_%s.png" % id
	if ResourceLoader.exists(pic_path):
		icon.texture = load(pic_path)
		icon.custom_minimum_size = Vector2(0, 74)
		if id == "nova_burst":
			var add := CanvasItemMaterial.new()
			add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD   # painted as light on black
			icon.material = add
	else:
		icon.texture = Icons.get_icon(def.icon)
		icon.custom_minimum_size = Vector2(0, 56)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(icon)
	var name_l := UIKit.label(def.name, 13, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(name_l)
	v.add_child(UIKit.label(String(def.rarity).to_upper() + ("  Lv.%d" % (lvl + 1)), 10, col, HORIZONTAL_ALIGNMENT_CENTER))
	var d := UIKit.label(def.desc, 11, Color(0.8, 0.88, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	b.add_child(v)
	b.pressed.connect(func(): _pick_card(id))
	return b

func _pick_card(id: String) -> void:
	card_levels[id] = int(card_levels.get(id, 0)) + 1
	match id:
		"rapid_pulse": fire_rate_mult *= 1.08
		"heavy_bolts": damage_mult *= 1.12
		"burst_fire": burst_count += 1
		"aegis":
			max_hearts = mini(max_hearts + 1, 5)
			hearts = mini(hearts + 1, max_hearts)
		"magnet":
			magnet_level += 1
			magnet_radius = MAGNET_BASE + 30.0 * magnet_level   # 120, 150, 180, 210 px
		"reinforced_hull":
			hull_max += 25.0
			hull = minf(hull + 25.0, hull_max)
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

func _show_end(won: bool) -> void:
	for c in _end_panel.get_children():
		c.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.size = Vector2(FIELD_W, FIELD_H)
	_end_panel.add_child(dim)
	var p := UIKit.panel(16)
	p.position = Vector2(FIELD_W * 0.5 - 140, FIELD_H * 0.5 - 150)
	p.size = Vector2(280, 300)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	var area_done: bool = won and StageData.boss_kind(stage) == "boss" and not elite
	var t := UIKit.label("AREA COMPLETE" if area_done else ("STAGE CLEARED" if won else "BASE LOST"), 20, UIKit.GOLD if won else Color(1.0, 0.4, 0.45), HORIZONTAL_ALIGNMENT_CENTER)
	t.add_theme_font_override("font", title_font)
	v.add_child(t)
	v.add_child(UIKit.label("%s %d: %s" % ["Elite" if elite else "Stage", stage, StageData.stage_name(stage)], 13, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	if won and not elite:
		v.add_child(UIKit.label("★".repeat(_stars_got) + "☆".repeat(3 - _stars_got), 24, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	if area_done:
		var nxt_area := StageData.area_index(stage) + 1
		v.add_child(UIKit.label("%s cleared!" % StageData.area(stage).name, 14, UIKit.CYAN, HORIZONTAL_ALIGNMENT_CENTER))
		if nxt_area < StageData.AREAS.size():
			v.add_child(UIKit.label("Next planet: %s" % StageData.AREAS[nxt_area].name, 12, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UIKit.label("Score %d    Kills %d" % [score, kills], 14, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UIKit.label("Coins +%d    Pilot XP +%d" % [coins_earned, _xp_gain], 14, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	if _xp_bonus > 0:
		v.add_child(UIKit.label("(first clear bonus +%d)" % _xp_bonus, 11, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	if _level_after > _level_before:
		v.add_child(UIKit.label("PILOT LEVEL %d!" % _level_after, 14, Color(0.85, 0.75, 1.0), HORIZONTAL_ALIGNMENT_CENTER))
		for id in Turrets.TURRETS:
			var u: int = int(Turrets.TURRETS[id].unlock)
			if u > _level_before and u <= _level_after:
				v.add_child(UIKit.label("%s unlocked" % Turrets.TURRETS[id].name, 12, UIKit.CYAN, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UIKit.label("Waves %d / %d" % [mini(wave_index + (1 if won else 1), waves.size()), waves.size()], 12, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	if won and _new_mount >= 0:
		v.add_child(UIKit.label("NEW TURRET MOUNT OPEN!", 14, UIKit.CYAN, HORIZONTAL_ALIGNMENT_CENTER))
		var on: String = turret_loadout[_new_mount] if _new_mount < turret_loadout.size() else ""
		var hint := ("Your %s stands on mount %d from the next stage." % [Turrets.TURRETS[on].name, _new_mount + 1]) if on != "" and _level_after >= int(Turrets.TURRETS[on].unlock) else ("Place a turret on mount %d in Gear." % (_new_mount + 1))
		v.add_child(UIKit.label(hint, 12, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var sp := Control.new(); sp.custom_minimum_size = Vector2(0, 6)
	v.add_child(sp)
	if won and stage < StageData.MAX_STAGE:
		var nxt := UIKit.gold_button("Next stage")
		nxt.pressed.connect(func():
			_write_save({"selected_stage": stage + 1})
			stage += 1
			_start_stage())
		v.add_child(nxt)
	var again := UIKit.teal_button("Retry" if not won else "Play again")
	again.pressed.connect(func(): _start_stage())
	v.add_child(again)
	var home := UIKit.ghost_button("Back to Hub")
	home.pressed.connect(func(): get_tree().change_scene_to_file("res://hub.tscn"))
	v.add_child(home)
	p.add_child(v)
	_end_panel.add_child(p)
	_end_panel.visible = true

# ------------------------------------------------------------------ drawing

func _draw() -> void:
	var fsize := Vector2(FIELD_W, FIELD_H)
	var sec := StageData.sector(stage)
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), sec.sky_bot)
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
		var c: Color = StageData.GEM_COLORS[g.tier]
		var p: Vector2 = g.pos
		var r: float = 4.0 + g.tier * 1.2
		var blink: float = 1.0 if g.life > 2.0 else (0.4 + 0.6 * absf(sin(g.life * 10.0)))
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
	_draw_turret_front()
	for r in rings:
		var k: float = 1.0 - r.life / r.max
		draw_arc(r.pos, r.r * k, 0.0, TAU, 20, Color(r.col, (1.0 - k) * 0.7), 2.0, true)
	for s in sparks:
		draw_circle(s.pos, 2.0, Color(s.col, clampf(s.life * 2.5, 0.0, 1.0)))
	for f in (floaters if not picking else []):
		var big: bool = f.get("big", false)
		draw_string(title_font if big else hud_font, f.pos + Vector2(-40 if big else -14, 0), f.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18 if big else 14, Color(f.col, clampf(f.life * 1.5, 0.0, 1.0)))
	_draw_hud()
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
	if e.get("hatchling", false):
		size *= lerpf(0.6, 1.0, smoothstep(0.2, 1.2, float(e.t)))   # grows out of the sac
	var a: float = clampf((e.pos.y - 60.0) / 50.0, 0.15, 1.0)   # fades in as it enters
	if e.type == "spitter":
		# the sac swells before it spits and settles right after, on smooth ramps
		var every: float = float(def.fire_every)
		var swell: float = maxf(smoothstep(0.8, 0.2, e.fire_t), smoothstep(every - 0.3, every, e.fire_t))
		if swell > 0.01:
			var pulse: float = 0.5 + 0.5 * sin(e.t * 8.0)
			draw_circle(EnemyRig.anchor("spitter", "sac", e.pos, size, ang), size * 0.16 * (1.0 + 0.4 * pulse * swell), Color(0.8, 0.4, 1.0, 0.25 * swell))
	if e.type == "hive_mother":
		EnemyRig.draw_hive_mother(self, e.pos, size * (0.4 if e.get("mini", false) else 0.5), time_alive, float(e.laying), e.hp < e.hp_max * 0.5)
	elif e.get("hatchling", false) and fold > 0.01:
		# Luna's crumpled hatchling cross-fades into the flying Scout as its wings open
		var ht: Texture2D = _tex["hive_hatchling"]
		var hs: Vector2 = ht.get_size() * (size * 0.75 / ht.get_height())
		draw_set_transform(e.pos, ang, Vector2.ONE)
		draw_texture_rect(ht, Rect2(-hs * 0.5, hs), false, Color(1, 1, 1, a * fold))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		EnemyRig.draw_bug(self, e.type, e.pos, size, time_alive, float(e.ph), ang, fold, 1.0 + float(e.speed) / 150.0, a * (1.0 - fold))
	else:
		EnemyRig.draw_bug(self, e.type, e.pos, size, time_alive, float(e.ph), ang, fold, 1.0 + float(e.speed) / 150.0, a)
	if e.hp < e.hp_max and e.type != "hive_mother":
		var w := size * 0.9
		draw_rect(Rect2(e.pos.x - w * 0.5, e.pos.y - size * 0.6, w, 3), Color(1, 1, 1, 0.15))
		draw_rect(Rect2(e.pos.x - w * 0.5, e.pos.y - size * 0.6, w * clampf(e.hp / e.hp_max, 0.0, 1.0), 3), Color(1.0, 0.5, 0.4))

func _draw_turret(t: Dictionary) -> void:
	# Luna's turret sits in its socket with a soft shadow; it falls in from above
	# when mounted (drop 0 -> 1) and lands with a flash.
	if t.drop <= 0.0:
		return
	var k: float = t.drop
	var yo: float = -90.0 * (1.0 - k) * (1.0 - k)
	var a: float = clampf(k * 4.0, 0.0, 1.0)
	draw_set_transform(t.pos + Vector2(0, 3), 0.0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.45 * k))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if t.type == "sentry":
		var bt: Texture2D = _tex["sentry_base"]
		var bs := bt.get_size() * (SENTRY_BASE_W / bt.get_width())
		draw_texture_rect(bt, Rect2(t.pos + Vector2(-bs.x * 0.5, -bs.y * 0.5 + yo), bs), false, Color(1, 1, 1, a))
		var g := _sentry_geo(t)
		var ht: Texture2D = _tex["sentry_head"]
		var hs: float = SENTRY_HEAD_H / ht.get_height()
		var hsz := ht.get_size() * hs
		draw_set_transform(g.pivot + Vector2(0, yo), g.rot, Vector2(g.face, 1.0))
		draw_texture_rect(ht, Rect2(Vector2(-hsz.x * SENTRY_HEAD_CX, -hsz.y * 0.9) + Vector2(0, g.recoil), hsz), false, Color(1, 1, 1, a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var tex: Texture2D = _tex[Turrets.TURRETS[t.type].art + "_idle"]
	var look: Dictionary = TURRET_LOOK[t.type]
	var sz := tex.get_size() * minf(float(look.h) / tex.get_height(), float(look.w) / tex.get_width())
	var bob: float = sin(time_alive * 2.2 + float(t.mount)) * float(look.bob)
	# a shot kicks the turret: it squats a little on its socket and springs back
	var kick: float = clampf(float(t.fire_t) / float(FIRE_TIME.get(t.type, 0.2)), 0.0, 1.0)
	kick = kick * kick
	var ksz := Vector2(sz.x * (1.0 + 0.03 * kick), sz.y * (1.0 - 0.05 * kick))
	draw_texture_rect(tex, Rect2(t.pos + Vector2(-ksz.x * float(look.cx), -ksz.y + 6.0 + yo + bob), ksz), false, Color(1, 1, 1, a))

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
	var rot: float = clampf(angle_difference(art_dir, t.ang), -0.6, 0.6) + lean
	var ht: Texture2D = _tex["sentry_head"]
	var hs: float = SENTRY_HEAD_H / ht.get_height()
	var recoil: float = 4.0 * float(t.fire_t) / FIRE_TIME.sentry
	var local := Vector2((0.47 - SENTRY_HEAD_CX) * ht.get_width() * face, (0.04 - 0.9) * ht.get_height()) * hs + Vector2(0, recoil)
	return {"pivot": pivot, "rot": rot, "face": face, "recoil": recoil, "muzzle": pivot + local.rotated(rot), "lift": lift, "base_top": t.pos.y - base_h * 0.28, "head_bottom": pivot.y + hs * ht.get_height() * 0.1}

# The point a turret's weapon fires from.
func _turret_tip(t: Dictionary) -> Vector2:
	if t.type == "sentry":
		return _sentry_geo(t).muzzle
	var look: Dictionary = TURRET_LOOK[t.type]
	var tex: Texture2D = _tex[Turrets.TURRETS[t.type].art + "_idle"]
	var h: float = tex.get_height() * minf(float(look.h) / tex.get_height(), float(look.w) / tex.get_width())
	return t.pos + Vector2(0, 6.0 - h * float(look.tip) + sin(time_alive * 2.2 + float(t.mount)) * float(look.bob))

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
		var BL := 26.0 * (0.85 + 0.15 * bw)
		var bth: float = BL * bt0.get_height() / bt0.get_width() * bw
		_fx.draw_set_transform(bl.pos, bl.vel.angle(), Vector2.ONE)
		_fx.draw_texture_rect(bt0, Rect2(-BL * 0.85, -bth * 0.5, BL, bth), false)
	# Swarm drones
	var dt: Texture2D = _fx_tex["drone"]
	for dr in drones:
		var da: float = minf(1.0, dr.age / 0.15) * minf(1.0, dr.life / 0.4)
		_fx.draw_set_transform(dr.pos, dr.vel.angle(), Vector2.ONE)
		_fx.draw_texture_rect(dt, Rect2(-11, -11 * dt.get_height() / dt.get_width(), 22, 22 * dt.get_height() / dt.get_width()), false, Color(1, 1, 1, da))
	for t in turrets:
		if t.drop >= 1.0 and CHARGE_COL.has(t.type):
			# charge-up: light gathers at the weapon in the last moments before a shot,
			# holds (softly pulsing) while it waits for a target, and empties when it fires
			var every: float = float(Turrets.TURRETS[t.type].every)
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
				var kc: float = clampf(t.charge / float(Turrets.TURRETS.lance.every), 0.0, 1.0)
				_fx_sprite("lance_flare", tip, 8.0 + 26.0 * kc * kc, 0.25 + 0.6 * kc)
				if t.fire_t > 0.0:
					var kf: float = t.fire_t / FIRE_TIME.lance
					var bt: Texture2D = _fx_tex["lance_beam"]
					_fx.draw_set_transform(tip, -PI / 2.0, Vector2.ONE)
					_fx.draw_texture_rect(bt, Rect2(0, -14.0 * kf, tip.y + 20.0, 28.0 * kf), false)
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
					var p: Vector2 = _turret_tip(t).lerp(Vector2(t.pos.x, BASE_Y - float(Turrets.TURRETS.prism.split_h)), kk)
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
		var def: Dictionary = Turrets.TURRETS.storm
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
	var def: Dictionary = Turrets.TURRETS.gravity
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

# Top bar, built like Home's (HomeFrame): flush with the top of the screen, dark fill,
# one thin cyan outline along its bottom that curves up into the screen edges. The
# straight part of that outline is the run's XP track; the level hangs under it on a tab.
const HUD_H := 70.0                  # bar height (its bottom line = XP track)
const PAUSE_RECT := Rect2(FIELD_W - 50, 10, 36, 30)
const SPEED_RECT := Rect2(FIELD_W - 92, 10, 36, 30)
const CARDS_RECT := Rect2(FIELD_W - 134, 10, 36, 30)

# A small chamfered frame like the pause button's (lit when active).
func _hud_frame(p: Rect2, active: bool) -> void:
	var cyan := Color(0.18, 0.9, 1.0)
	var cut := 7.0
	var frame := PackedVector2Array([p.position + Vector2(cut, 0), Vector2(p.end.x, p.position.y), Vector2(p.end.x, p.end.y - cut),
		Vector2(p.end.x - cut, p.end.y), Vector2(p.position.x, p.end.y), p.position + Vector2(0, cut), p.position + Vector2(cut, 0)])
	draw_colored_polygon(frame, Color(cyan, 0.16) if active else Color(0.05, 0.08, 0.16, 0.9))
	draw_polyline(frame, Color(cyan, 0.75), 1.2, true)

func _hud_bar_points() -> PackedVector2Array:
	var R := 20.0
	var pts := PackedVector2Array()
	pts.append(Vector2(0, HUD_H - R))
	for i in range(9):
		var a := lerpf(PI, PI * 0.5, float(i) / 8.0)
		pts.append(Vector2(R, HUD_H - R) + Vector2(cos(a), sin(a)) * R)
	for i in range(9):
		var a := lerpf(PI * 0.5, 0.0, float(i) / 8.0)
		pts.append(Vector2(FIELD_W - R, HUD_H - R) + Vector2(cos(a), sin(a)) * R)
	pts.append(Vector2(FIELD_W, HUD_H - R))
	return pts

# Luna's heart; a lost heart shows as a dark, see-through shape.
func _draw_heart(c: Vector2, s: float, on: bool) -> void:
	var ht: Texture2D = _tex["ui_heart"]
	var hw := s * 2.3
	var hh: float = hw * ht.get_height() / ht.get_width()
	draw_texture_rect(ht, Rect2(c.x - hw * 0.5, c.y - hh * 0.5, hw, hh), false, Color(1, 1, 1) if on else Color(0.25, 0.28, 0.4, 0.45))

func _draw_hud() -> void:
	var cyan := Color(0.18, 0.9, 1.0)
	var muted := Color(0.62, 0.70, 0.84)
	var pts := _hud_bar_points()
	var shape := PackedVector2Array(pts)
	shape.append(Vector2(FIELD_W, -2))
	shape.append(Vector2(0, -2))
	draw_colored_polygon(shape, Color(0.03, 0.045, 0.10, 0.82))
	draw_polyline(pts, Color(cyan, 0.55), 1.2, true)
	# row 1: stage number (white) and name (cyan), then the run time
	var num := "%d " % stage
	draw_string(title_font, Vector2(16, 30), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
	var nx: float = 16.0 + title_font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	var name_w := 250.0 - nx
	draw_string(title_font, Vector2(nx, 30), StageData.stage_name(stage).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, name_w, 13, cyan)
	var mins := int(time_alive) / 60
	var secs := int(time_alive) % 60
	draw_string(hud_font, Vector2(CARDS_RECT.position.x - 92, 30), "%02d:%02d" % [mins, secs], HORIZONTAL_ALIGNMENT_RIGHT, 80, 13, muted)
	# cards button: three small fanned cards
	_hud_frame(CARDS_RECT, _cards_open)
	var cc := CARDS_RECT.get_center()
	for k in 3:
		draw_set_transform(cc + Vector2((k - 1) * 4.0, 2.0), (k - 1) * 0.28, Vector2.ONE)
		draw_rect(Rect2(-5, -8, 10, 14), Color(0.05, 0.08, 0.16))
		draw_rect(Rect2(-5, -8, 10, 14), Color(0.85, 0.75, 1.0) if k == 1 else Color(cyan, 0.9), false, 1.2)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# game speed
	_hud_frame(SPEED_RECT, game_speed > 1.0)
	draw_string(title_font, SPEED_RECT.position + Vector2(0, 20), "x%s" % (str(game_speed) if game_speed != 1.0 else "1"), HORIZONTAL_ALIGNMENT_CENTER, SPEED_RECT.size.x, 11, Color.WHITE if _speeds().size() > 1 else Color(1, 1, 1, 0.5))
	# pause button: two thin bars (a play arrow while paused)
	var p := PAUSE_RECT
	_hud_frame(p, paused)
	var pc := p.get_center()
	if paused:
		draw_colored_polygon(PackedVector2Array([pc + Vector2(-5, -8), pc + Vector2(8, 0), pc + Vector2(-5, 8)]), Color.WHITE)
	else:
		draw_rect(Rect2(pc + Vector2(-6, -8), Vector2(3.5, 16)), Color.WHITE)
		draw_rect(Rect2(pc + Vector2(2.5, -8), Vector2(3.5, 16)), Color.WHITE)
	# row 2: score, waves as pips (text when there are many), hearts
	var y2 := 55.0
	draw_string(hud_font, Vector2(16, y2), "SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, muted)
	draw_string(hud_font, Vector2(56, y2), str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	var wave_now := mini(wave_index + 1, waves.size())
	var wx := 160.0
	draw_string(hud_font, Vector2(wx, y2), "WAVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, muted)
	wx += 36.0
	if waves.size() <= 10:
		for i in waves.size():
			var r := Rect2(wx + i * 13.0, y2 - 9.0, 9.0, 9.0)
			var dia := PackedVector2Array([Vector2(r.get_center().x, r.position.y), Vector2(r.end.x, r.get_center().y),
				Vector2(r.get_center().x, r.end.y), Vector2(r.position.x, r.get_center().y), Vector2(r.get_center().x, r.position.y)])
			if i < wave_now - 1:
				draw_colored_polygon(dia, Color(cyan, 0.85))
			elif i == wave_now - 1:
				draw_colored_polygon(dia, Color.WHITE)
			draw_polyline(dia, Color(cyan, 0.6), 1.0, true)
	else:
		draw_string(hud_font, Vector2(wx, y2), "%d/%d" % [wave_now, waves.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	for i in max_hearts:
		_draw_heart(Vector2(FIELD_W - 22 - (max_hearts - 1 - i) * 22, y2 - 2), 7.5, i < hearts)
	# XP along the bar's bottom line, and the level on a tab hanging under it
	var need := _xp_need()
	var x0 := 20.0
	var x1 := FIELD_W - 20.0
	var xp := clampf(run_xp / need, 0.0, 1.0)
	draw_line(Vector2(x0, HUD_H), Vector2(lerpf(x0, x1, xp), HUD_H), Color(0.71, 0.55, 1.0), 3.0, true)
	if xp > 0.01:
		draw_circle(Vector2(lerpf(x0, x1, xp), HUD_H), 2.2, Color(0.92, 0.86, 1.0))
	var tab := PackedVector2Array([Vector2(16, HUD_H), Vector2(16, HUD_H + 14), Vector2(22, HUD_H + 20), Vector2(64, HUD_H + 20), Vector2(70, HUD_H + 14), Vector2(70, HUD_H)])
	draw_colored_polygon(tab, Color(0.03, 0.045, 0.10, 0.82))
	draw_polyline(tab, Color(0.71, 0.55, 1.0, 0.7), 1.0, true)
	draw_string(hud_font, Vector2(16, HUD_H + 15), "LV %d" % run_level, HORIZONTAL_ALIGNMENT_CENTER, 54, 11, Color(0.88, 0.8, 1.0))
	for e in enemies:
		if e.type == "hive_mother":
			var bw := 220.0
			var by := HUD_H + 40.0
			var br := Rect2(FIELD_W * 0.5 - bw * 0.5, by, bw, 6)
			draw_rect(br, Color(0.03, 0.045, 0.10, 0.7))
			draw_rect(Rect2(br.position, Vector2(bw * clampf(e.hp / e.hp_max, 0.0, 1.0), 6)), Color(0.85, 0.35, 0.9))
			draw_rect(br, Color(0.9, 0.7, 1.0, 0.6), false, 1.0)
			draw_string(title_font, Vector2(FIELD_W * 0.5 - 100, by - 6), "YOUNG HIVE MOTHER" if e.get("mini", false) else "HIVE MOTHER", HORIZONTAL_ALIGNMENT_CENTER, 200, 11, Color(0.9, 0.7, 1.0))
	_draw_intro()

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
	draw_colored_polygon(frame, Color(0.03, 0.045, 0.10, 0.88 * a))
	draw_polyline(frame, Color(1.0, 0.55, 0.35, 0.8 * a), 1.2, true)
	# the bug itself, small, on the left
	var icon := r.position + Vector2(38.0, 37.0)
	if id == "hive_mother":
		EnemyRig.draw_hive_mother(self, icon, 26.0, time_alive, 0.0, false)
	else:
		EnemyRig.draw_bug(self, id, icon, 46.0, time_alive, 0.0, 0.0, 0.0, 1.0, a)
	draw_string(title_font, r.position + Vector2(76.0, 20.0), "NEW ENEMY", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.6, 0.4, a))
	draw_string(hud_font, r.position + Vector2(76.0, 38.0), id.replace("_", " ").capitalize(), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, a))
	draw_multiline_string(hud_font, r.position + Vector2(76.0, 54.0), String(StageData.ENEMIES[id].intro), HORIZONTAL_ALIGNMENT_LEFT, 236.0, 11, 2, Color(0.75, 0.82, 0.92, a))

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
		var def: Dictionary = Cards.CARDS[id]
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(92, 0)
		var pic := TextureRect.new()
		var pp := "res://cards/pic_%s.png" % id
		pic.texture = load(pp) if ResourceLoader.exists(pp) else Icons.get_icon(def.icon)
		if id == "nova_burst":
			var add := CanvasItemMaterial.new()
			add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD   # painted as light on black
			pic.material = add
		pic.custom_minimum_size = Vector2(0, 56)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cell.add_child(pic)
		var nl := UIKit.label(def.name, 11, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cell.add_child(nl)
		cell.add_child(UIKit.label("Lv.%d / %d" % [int(card_levels[id]), int(def.max)], 10, Cards.COLOR[def.rarity], HORIZONTAL_ALIGNMENT_CENTER))
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
	var done: Array = Array(_read_save().get("areas_briefed", []))
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
