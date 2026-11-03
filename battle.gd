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
const DECK_H := 34.0              # the raised deck the base and turret platforms stand on
const MOUNT_X := [0.18, 0.36, 0.64, 0.82]
const PILOT_HEIGHT := 60.0
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
var idle_fire_ratio := 1.45
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
var magnet_radius := 60.0
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
var bullets: Array = []
var enemy_bullets: Array = []
var enemies: Array = []
var gems: Array = []
var turrets: Array = []           # {type, lvl, pos, cd, fire_t, ang, flip, charge, build, bolt}
var turret_loadout: Array = []    # from the save: turret id (or "") per mount
var turret_levels := {}
var turret_mult := 1.0            # run boost from Deploy cards
var drones: Array = []            # Swarm Hive micro-drones {type, pos, vel, life, dmg}
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
		_tex[id + "_up"] = load("res://enemies/%s_up.png" % id)
		_tex[id + "_down"] = load("res://enemies/%s_down.png" % id)
	for id in Turrets.TURRETS:
		for k in ["_idle", "_fire"]:
			_tex[Turrets.TURRETS[id].art + k] = load("res://turrets/%s%s.png" % [Turrets.TURRETS[id].art, k])
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
	magnet_radius = 60.0
	magnet_level = 0
	bullets.clear(); enemy_bullets.clear(); enemies.clear(); gems.clear(); turrets.clear()
	sparks.clear(); rings.clear(); floaters.clear()
	turret_mult = 1.0
	drones.clear()
	stat_pilot_dmg = 0.0
	stat_turret_dmg = 0.0
	for i in turret_loadout.size():
		if turret_loadout[i] != "":
			_mount_turret(turret_loadout[i], i, int(turret_levels.get(turret_loadout[i], 1)), false)
	soldier_pos = Vector2(240, BASE_Y - 200.0)
	prev_soldier_x = soldier_pos.x
	prev_soldier_y = soldier_pos.y
	aim_target_id = -2
	_end_panel.visible = false
	_card_panel.visible = false
	picking = false
	paused = false
	_start_wave()

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
	var def: Dictionary = StageData.ENEMIES[id]
	var e := {"id": next_enemy_id, "type": id, "pos": Vector2(rng.randf_range(40.0, FIELD_W - 40.0), 60.0),
		"hp": float(def.hp) * StageData.hp_mult(stage, elite), "hp_max": float(def.hp) * StageData.hp_mult(stage, elite),
		"speed": float(def.speed) * StageData.speed_mult(stage), "r": float(def.size) * 0.4, "ph": rng.randf() * TAU,
		"state": "fly", "t": 0.0, "vel": Vector2.ZERO, "fire_t": rng.randf_range(1.0, 2.5), "lay_t": 3.0, "laying": 0.0,
		"dart_t": rng.randf_range(0.3, 1.0), "dart_vx": 0.0, "dodge_v": 0.0, "dodge_cd": 0.0, "feinted": false}
	if id == "hive_mother":
		e.pos = Vector2(FIELD_W * 0.5, 40.0)
		_boss_bar_max = e.hp_max
	next_enemy_id += 1
	enemies.append(e)

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
		queue_redraw()
		return
	time_alive += delta
	hit_t += delta
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
	var pose := _current_pose()
	return soldier_pos + PilotSprite.muzzle(pose, PILOT_HEIGHT, _flipped(pose)).rotated(-draw_bank * 0.6)

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
			gun_recoil = 0.9
			_fire(_muzzle_world() + burst_dir * 4.0, burst_dir, burst_tid)
	var interval: float = float(weapon.interval) / fire_rate_mult
	if burst_count > 1:
		interval *= 1.0 + 0.35 * (burst_count - 1)
	if dragging and fire_timer <= 0.0:
		fire_timer = interval
		gun_recoil = 1.0
		var ang: float = -PI / 2.0 + gun_sway - draw_bank
		var dir := Vector2(cos(ang), sin(ang))
		_fire(muzzle_base + dir * 4.0, dir)
		burst_left = burst_count - 1
		burst_timer = 0.07
		burst_dir = dir
		burst_tid = -2
	elif idle_aiming and fire_timer <= 0.0 and not target.get("doomed", false) and absf(angle_difference(idle_aim_ang, aim_goal)) <= aim_ready_angle:
		fire_timer = interval * idle_fire_ratio / idle_power
		gun_recoil = 1.0
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
				else:
					stat_pilot_dmg += minf(dmg, maxf(e.hp, 0.0))
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
				if e.state == "fly":
					e.pos.y += e.speed * 0.8 * delta
					e.pos.x += sin(e.t * 1.2 + e.ph) * 30.0 * delta
					if e.pos.y > FIELD_H * 0.22 and absf(e.pos.x - soldier_pos.x) < 70.0 and soldier_pos.y > e.pos.y:
						e.vel = (soldier_pos - e.pos).normalized()
						if hive_brains and not e.get("feinted", false) and rng.randf() < 0.6:
							# a feint: a short lunge, then it pulls back up and comes again
							e.feinted = true
							e.state = "feint"
							stat_feints += 1
							e.t_state = 0.0
							e.feint_dir = -1.0 if e.vel.x > 0.0 else 1.0
							e.vel *= e.speed * 2.6
						else:
							e.state = "dive"
							e.vel *= e.speed * 3.4
				elif e.state == "feint":
					e.t_state += delta
					if e.t_state < 0.3:
						e.pos += e.vel * delta
					else:
						# pull up and slide aside, then fly on as before
						e.pos += Vector2(float(e.feint_dir) * 70.0, -e.speed * 1.6) * delta * clampf(1.0 - (e.t_state - 0.3) / 0.7, 0.0, 1.0)
						if e.t_state > 1.0:
							e.state = "fly"
				else:
					e.pos += e.vel * delta
					if e.pos.distance_to(soldier_pos) < 22.0:
						if inv_t <= 0.0:
							stat_hit_diver += 1
						_hurt_pilot()
						e.hp = 0.0
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
						var s := {"id": next_enemy_id, "type": "scout", "pos": e.pos + Vector2(float(k - 1) * 22.0, 46.0),
							"hp": 2.0 * StageData.hp_mult(stage, elite), "hp_max": 2.0 * StageData.hp_mult(stage, elite),
							"speed": 62.0 * StageData.speed_mult(stage), "r": 13.6, "ph": rng.randf() * TAU,
							"state": "hatch", "t": 0.0, "vel": Vector2(float(k - 1) * 40.0, -30.0), "fire_t": 9.0, "lay_t": 0.0, "laying": 0.0,
							"hatchling": true, "fold": 1.0}
						next_enemy_id += 1
						live.append(s)
					_burst(e.pos + Vector2(0, 46), 22.0, Color(0.71, 0.55, 1.0), 12)
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
			_hurt_base({"scout": 10.0, "drifter": 13.0, "spitter": 14.0, "diver": 10.0}.get(e.type, 10.0))
			_burst(e.pos, 14.0, Color(0.18, 0.9, 1.0), 10)
			continue
		if e.pos.y > FIELD_H + 40.0 or e.pos.x < -60.0 or e.pos.x > FIELD_W + 60.0:
			continue
		live.append(e)
	enemies = live

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
	return e.type == "diver" and (e.state == "dive" or (e.state == "feint" and float(e.get("t_state", 1.0)) < 0.3))

# The tilt an enemy wants this frame; drawing uses e.tilt_s, which eases toward it.
func _enemy_tilt(e: Dictionary) -> float:
	if _lunging(e):
		return e.vel.angle() + PI / 2.0
	if e.type == "hive_mother":
		return 0.0
	return clampf(e.vel.x * 0.004, -0.35, 0.35) + sin(e.t * 6.0 + e.ph) * 0.05

func _kill(e: Dictionary) -> void:
	var def: Dictionary = StageData.ENEMIES[e.type]
	var worth: int = 100 if e.type != "hive_mother" else 1500
	score += worth
	kills += 1
	coins_earned += int(def.coins)
	_burst(e.pos, float(e.r), Color(1.0, 0.8, 0.4), 12 if e.type == "hive_mother" else 7)
	_float_text(e.pos, "+%d" % worth, Color(1.0, 0.85, 0.4))
	var tier: int = int(def.xp_tier)
	var count: int = 1
	if e.type == "hive_mother":
		count = 6
	for i in count:
		gems.append({"pos": e.pos + Vector2(rng.randf_range(-16, 16), rng.randf_range(-10, 10)), "tier": tier, "life": 16.0,
			"vel": Vector2(rng.randf_range(-30, 30), rng.randf_range(-60, -20))})

func _update_gems(delta: float) -> void:
	var live: Array = []
	for g in gems:
		g.life -= delta
		var d: float = g.pos.distance_to(soldier_pos)
		if d < magnet_radius:
			g.pos = g.pos.move_toward(soldier_pos, (320.0 + (magnet_radius - d) * 4.0) * delta)
		else:
			g.vel.y = minf(g.vel.y + 70.0 * delta, 55.0)
			g.vel.x *= 0.98
			g.pos += g.vel * delta

		if d < 16.0:
			_gain_xp(float(StageData.GEM_XP[g.tier]))
			_burst(soldier_pos, 4.0, StageData.GEM_COLORS[g.tier], 3)
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
	var base := 5.0 + 6.0 * (run_level - 1)   # the first card comes after about 3 kills
	if run_level > 12:
		base *= pow(2.0, run_level - 12)   # past the cap, picks keep coming but much slower
	return base

# ------------------------------------------------------------------ turrets

# Turrets from the Gear loadout are mounted at the start of every run (mount =
# index into MOUNT_X); a Deploy card fills a free mount during the run. Each
# type's numbers live in turrets.gd.
func _mount_turret(type: String, mount: int = -1, lvl: int = 1, fx: bool = true) -> bool:
	if mount < 0:
		for i in MOUNT_X.size():
			var taken := false
			for t in turrets:
				if t.mount == i:
					taken = true
			if not taken:
				mount = i
				break
	if mount < 0:
		return false
	var x: float = FIELD_W * float(MOUNT_X[mount])
	turrets.append({"type": type, "lvl": lvl, "mount": mount, "pos": Vector2(x, BASE_Y - DECK_H - 4.0), "cd": 0.5 + 0.3 * mount,
		"fire_t": 0.0, "ang": -PI / 2.0, "flip": x > FIELD_W * 0.5, "charge": 0.0, "build": 0.0, "bolt": []})
	if fx:
		_burst(Vector2(x, BASE_Y - 30.0), 16.0, Color(0.2, 0.85, 1.0), 10)
	return true

func _turret_dmg(t: Dictionary) -> float:
	return float(Turrets.TURRETS[t.type].damage) * Turrets.level_mult(int(t.lvl)) * turret_mult

func _turret_hit(t: Dictionary, e: Dictionary, dmg: float) -> void:
	dmg *= Turrets.trait_mult(t.type, StageData.ENEMIES[e.type].traits)
	stat_turret_dmg += minf(dmg, maxf(e.hp, 0.0))
	e.hp -= dmg

func _update_turrets(delta: float) -> void:
	for t in turrets:
		t.pos.y = BASE_Y - DECK_H - 4.0   # follows the screen height
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
	var best := -1
	var bd: float = float(def.range)
	for i in enemies.size():
		var d: float = t.pos.distance_to(enemies[i].pos)
		if enemies[i].pos.y > 100.0 and d < bd:
			bd = d
			best = i
	if best >= 0:
		t.ang = lerp_angle(t.ang, (enemies[best].pos - t.pos).angle(), 0.12)
		t.cd -= delta
		if t.cd <= 0.0:
			t.cd = float(def.every)
			t.fire_t = FIRE_TIME.sentry
			var dir := Vector2.from_angle(t.ang)
			bullets.append({"pos": t.pos + Vector2(0, -22) + dir * 26.0, "vel": dir * 320.0, "dmg": _turret_dmg(t), "r": 18.0, "tid": -2, "col": "purple", "src": t.type})

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
				sparks.append({"pos": e.pos, "vel": Vector2(rng.randf_range(-90, 90), rng.randf_range(-90, 90)), "life": 0.3, "col": Color(def.glow)})
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
		_burst(p, 5.0, Color(def.glow), 3)

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
	_burst(c, float(def.crush_r) * 0.4, Color(def.glow), 10)

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
		drones.append({"type": "swarm", "pos": t.pos + Vector2(0, -28), "vel": Vector2.from_angle(a) * 120.0,
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
				_burst(dr.pos, 3.0, Color(Turrets.TURRETS.swarm.glow), 3)
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
	if shield > 0.0:
		shield = maxf(shield - amount, 0.0)
	else:
		hull = maxf(hull - amount, 0.0)

func _hurt_pilot() -> void:
	if inv_t > 0.0:
		return
	inv_t = 1.5
	hearts -= 1
	_burst(soldier_pos, 16.0, Color(1.0, 0.35, 0.42), 10)
	_float_text(soldier_pos + Vector2(0, -30), "-1 HEART", Color(1.0, 0.4, 0.45))

func _burst(p: Vector2, radius: float, col: Color, count: int = 7) -> void:
	rings.append({"pos": p, "life": 0.4, "max": 0.4, "r": radius * 2.6, "col": col})
	for k in count:
		sparks.append({"pos": p, "vel": Vector2(rng.randf_range(-120, 120), rng.randf_range(-120, 120)), "life": 0.4, "col": col})

func _float_text(p: Vector2, text: String, col: Color, big: bool = false) -> void:
	floaters.append({"pos": p + Vector2(rng.randf_range(-6, 6), 0), "text": text, "life": 1.1 if big else 0.9, "col": col, "big": big})

func _step_effects(delta: float) -> void:
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
	var patch := {"coins": int(d.get("coins", 0)) + coins_earned, "best_score": maxi(score, int(d.get("best_score", 0))),
		"best_kills": maxi(kills, int(d.get("best_kills", 0))), "pilot_xp": int(d.get("pilot_xp", 0)) + int(score / 50)}
	if won:
		patch["stage_unlocked"] = maxi(stage + 1, int(d.get("stage_unlocked", 1)))
	_write_save(patch)
	_show_end(won)

# ------------------------------------------------------------------ UI

func _build_ui() -> void:
	_pause_btn = Button.new()
	_pause_btn.text = "II"
	_pause_btn.position = Vector2(FIELD_W - 110, 14)
	_pause_btn.size = Vector2(34, 30)
	_style_small(_pause_btn)
	_pause_btn.pressed.connect(_toggle_pause)
	add_child(_pause_btn)
	var hub_btn := Button.new()
	hub_btn.text = "HUB"
	hub_btn.position = Vector2(FIELD_W - 70, 14)
	hub_btn.size = Vector2(56, 30)
	_style_small(hub_btn)
	hub_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://hub.tscn"))
	add_child(hub_btn)
	# pause panel
	_pause_panel = UIKit.panel(16)
	_pause_panel.position = Vector2(FIELD_W * 0.5 - 110, 300)
	_pause_panel.size = Vector2(220, 150)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 10)
	pv.add_child(UIKit.label("PAUSED", 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	var resume := UIKit.gold_button("Resume")
	resume.pressed.connect(_toggle_pause)
	pv.add_child(resume)
	var quit_b := UIKit.ghost_button("Back to base")
	quit_b.pressed.connect(func(): get_tree().change_scene_to_file("res://hub.tscn"))
	pv.add_child(quit_b)
	_pause_panel.add_child(pv)
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

func _style_small(b: Button) -> void:
	b.add_theme_stylebox_override("normal", UIKit.glass(8))
	b.add_theme_stylebox_override("hover", UIKit.glass(8))
	b.add_theme_stylebox_override("pressed", UIKit.box(Color(UIKit.CYAN, 0.3), UIKit.CYAN, 8))
	b.add_theme_font_size_override("font_size", 13)

func _toggle_pause() -> void:
	if picking or game_over or stage_cleared:
		return
	paused = not paused
	_pause_panel.visible = paused
	_pause_btn.text = ">" if paused else "II"

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
			magnet_radius = 60.0 * (1.0 + 0.5 * magnet_level)   # 90, 120, 150, 180 px
		"reinforced_hull":
			hull_max += 25.0
			hull = minf(hull + 25.0, hull_max)
		"deploy_sentry":
			# a free mount gets a Sentry for this run; with all four taken, turrets hit harder
			if not _mount_turret("sentry", -1, int(turret_levels.get("sentry", 1))):
				turret_mult *= 1.2
		"nova_burst":
			for e in enemies.duplicate():
				if e.type != "hive_mother":
					e.hp = 0.0
					_kill(e)
			enemies = enemies.filter(func(e): return e.type == "hive_mother")
			_burst(soldier_pos, 60.0, Color(1.0, 0.9, 0.6), 24)
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
	var t := UIKit.label("STAGE CLEARED" if won else "BASE LOST", 20, UIKit.GOLD if won else Color(1.0, 0.4, 0.45), HORIZONTAL_ALIGNMENT_CENTER)
	t.add_theme_font_override("font", title_font)
	v.add_child(t)
	v.add_child(UIKit.label("%s %d: %s" % ["Elite" if elite else "Stage", stage, StageData.stage_name(stage)], 13, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UIKit.label("Score %d    Kills %d" % [score, kills], 14, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UIKit.label("Coins +%d    Pilot XP +%d" % [coins_earned, int(score / 50)], 14, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UIKit.label("Waves %d / %d" % [mini(wave_index + (1 if won else 1), waves.size()), waves.size()], 12, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var sp := Control.new(); sp.custom_minimum_size = Vector2(0, 6)
	v.add_child(sp)
	if won:
		var nxt := UIKit.gold_button("Next stage")
		nxt.pressed.connect(func():
			_write_save({"selected_stage": stage + 1})
			stage += 1
			_start_stage())
		v.add_child(nxt)
	var again := UIKit.teal_button("Retry" if not won else "Play again")
	again.pressed.connect(func(): _start_stage())
	v.add_child(again)
	var home := UIKit.ghost_button("Back to base")
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
	Backdrop.draw_sky_palette(self, fsize, _stars, time_alive, sec.sky_top, sec.sky_bot, sec.glow)
	Backdrop.draw_horizon(self, fsize, BASE_Y, elite, _city, time_alive, sec.rim)
	Backdrop.draw_force_field(self, Vector2(FIELD_W * 0.5, BASE_Y), DOME_RX, DOME_RY, clampf(shield / shield_max, 0.0, 1.0), clampf(hull / hull_max, 0.0, 1.0), time_alive, elite, hit_t)
	Backdrop.draw_deck(self, FIELD_W, BASE_Y, DECK_H, MOUNT_X, time_alive, elite)
	Backdrop.draw_base(self, Vector2(FIELD_W * 0.5, BASE_Y - DECK_H - 2.0), time_alive, elite)
	for t in turrets:
		_draw_turret(t)
	_draw_turret_back()
	# gems
	for g in gems:
		var c: Color = StageData.GEM_COLORS[g.tier]
		var p: Vector2 = g.pos
		var r: float = 4.0 + g.tier * 1.2
		var blink: float = 1.0 if g.life > 2.0 else (0.4 + 0.6 * absf(sin(g.life * 10.0)))
		draw_circle(p, r * 2.2, Color(c, 0.12 * blink))
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r * 1.3), p + Vector2(r, 0), p + Vector2(0, r * 1.3), p + Vector2(-r, 0)]), Color(c, blink))
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r * 1.3), p + Vector2(r * 0.5, -r * 0.3), p + Vector2(-r * 0.5, -r * 0.3)]), Color(1, 1, 1, 0.5 * blink))
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
	PilotSprite.draw(self, soldier_pos + Vector2(0, bob), PILOT_HEIGHT, pose, _flipped(pose), -draw_bank * 0.6, time_alive,
		clampf(1.0 - vy_smooth / 260.0, 0.35, 1.9), clampf(draw_bank * 5.0, -1.0, 1.0), smoothstep(0.3, 1.0, gun_recoil), anim.mix(), turn, pilot_a)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# bullets
	var bolt_w: float = 1.0 + (damage_mult - 1.0) * 1.6   # Heavy Bolts: thicker, brighter bolts
	for bl in bullets:
		var dir: Vector2 = bl.vel.normalized()
		var purple: bool = bl.col == "purple"
		var w: float = 1.0 if purple else bolt_w
		draw_line(bl.pos - dir * (10.0 + 4.0 * (w - 1.0)), bl.pos + dir * 4.0, Color(0.71, 0.55, 1.0, 0.5) if purple else Color(0.2, 0.85, 1.0, 0.5), 5.0 * w, true)
		draw_line(bl.pos - dir * (10.0 + 4.0 * (w - 1.0)), bl.pos + dir * 4.0, Color(0.95, 0.9, 1.0) if purple else Color(0.9, 1.0, 1.0), 2.0 * w, true)
	# Rapid Pulse: the muzzle stays hot between shots
	if fire_rate_mult > 1.01:
		var heat: float = clampf((fire_rate_mult - 1.0) / 0.5, 0.0, 1.0)
		draw_circle(_muzzle_world(), 3.0 + 4.0 * heat, Color(1.0, 0.75, 0.5, 0.25 + 0.35 * heat))
	for eb in enemy_bullets:
		if eb.get("kind", "") == "goo":
			# a wobbling glob stretched along its flight, with two drips behind
			var gd: Vector2 = eb.vel.normalized()
			var wob: float = sin(time_alive * 14.0 + float(eb.ph))
			draw_circle(eb.pos - gd * 8.0, 2.2, Color(0.62, 0.3, 0.95, 0.8))
			draw_circle(eb.pos - gd * 13.0, 1.4, Color(0.62, 0.3, 0.95, 0.6))
			draw_set_transform(eb.pos, gd.angle(), Vector2(1.3 + 0.15 * wob, 0.85 - 0.1 * wob))
			draw_circle(Vector2.ZERO, 5.0, Color(0.68, 0.32, 1.0))
			draw_circle(Vector2(1.5, -1.5), 2.0, Color(0.9, 0.75, 1.0, 0.9))
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

func _draw_enemy(e: Dictionary) -> void:
	var def: Dictionary = StageData.ENEMIES[e.type]
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
		EnemyRig.draw_hive_mother(self, e.pos, size * 0.5, time_alive, float(e.laying), e.hp < e.hp_max * 0.5)
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
	# The idle art is always drawn; the firing art fades out over it, so a shot is
	# a flash that settles rather than a swap between two pictures.
	var art: String = Turrets.TURRETS[t.type].art
	var tex: Texture2D = _tex[art + "_idle"]
	var fire_a: float = smoothstep(0.0, float(FIRE_TIME.get(t.type, 0.14)), float(t.fire_t))
	var h := 54.0 if t.type == "lance" else 44.0
	var s: float = h / tex.get_height()
	var dsize := tex.get_size() * s
	var flip: bool = t.flip
	draw_set_transform(t.pos, 0.0, Vector2(-1.0 if flip else 1.0, 1.0))
	draw_texture_rect(tex, Rect2(Vector2(-dsize.x * 0.5, -dsize.y + 6.0), dsize), false)
	if fire_a > 0.01:
		var ft: Texture2D = _tex[art + "_fire"]
		var fsize := ft.get_size() * (h / ft.get_height())
		draw_texture_rect(ft, Rect2(Vector2(-fsize.x * 0.5, -fsize.y + 6.0), fsize), false, Color(1, 1, 1, fire_a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if t.type == "lance":
		# the tip fills up while it charges
		var k: float = clampf(t.charge / float(Turrets.TURRETS.lance.every), 0.0, 1.0)
		var tip: Vector2 = t.pos + Vector2(0, -h + 8.0)
		var r: float = 2.0 + 2.5 * k
		draw_colored_polygon(PackedVector2Array([tip + Vector2(0, -r * 1.4), tip + Vector2(r, 0), tip + Vector2(0, r * 1.4), tip + Vector2(-r, 0)]),
			Color(0.75, 0.9, 1.0, 0.2 + 0.7 * k))

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
			draw_line(t.pos + Vector2(0, -40), c, Color(col, 0.35), 1.0, true)

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
	draw_line(t.pos + Vector2(0, -30), c, Color(col, 0.18 * a), 1.0, true)
	for i in 3:
		var ph: float = fmod(time_alive * 0.8 + float(i) / 3.0, 1.0)
		var r: float = float(def.radius) * (1.0 - ph)
		draw_arc(c, r, time_alive * 1.5 + i * 2.1, time_alive * 1.5 + i * 2.1 + 2.2, 24, Color(col, 0.35 * a * ph), 1.2, true)
	draw_circle(c, 3.0 + 2.0 * pulling, Color(col.darkened(0.2), 0.7 * a))
	if after > 0.0:
		draw_arc(c, float(def.crush_r) * (1.2 - 0.5 * after), 0.0, TAU, 40, Color(col, 0.6 * after), 1.5, true)

# In front of the enemies: lance spears, storm lightning, prism orb and beams,
# swarm drones.
func _draw_turret_front() -> void:
	for dr in drones:
		var a: float = minf(1.0, dr.age / 0.15) * minf(1.0, dr.life / 0.4)
		var dir: Vector2 = dr.vel.normalized()
		var side := Vector2(-dir.y, dir.x)
		draw_line(dr.pos - dir * 9.0, dr.pos, Color(0.2, 0.85, 1.0, 0.35 * a), 1.5, true)
		draw_colored_polygon(PackedVector2Array([dr.pos + dir * 4.0, dr.pos - dir * 3.0 + side * 2.5, dr.pos - dir * 3.0 - side * 2.5]), Color(0.75, 0.97, 1.0, a))
	for t in turrets:
		if t.type == "prism" and float(t.get("orb_t", 0.0)) > 0.0:
			var k: float = smoothstep(0.0, 1.0, 1.0 - float(t.orb_t) / 0.25)
			var p: Vector2 = (t.pos + Vector2(0, -42)).lerp(Vector2(t.pos.x, BASE_Y - float(Turrets.TURRETS.prism.split_h)), k)
			draw_circle(p, 3.0, Color(1, 1, 1, 0.95))
			draw_arc(p, 6.0, 0.0, TAU, 16, Color(1.0, 0.9, 0.7, 0.6), 1.0, true)
		if t.type == "prism" and t.fire_t > 0.0 and t.has("beams"):
			var fa: float = smoothstep(0.0, FIRE_TIME.prism, float(t.fire_t))
			for i in t.beams.size():
				var s: Array = t.beams[i]
				var hue := Color.from_hsv(float(i) / float(t.beams.size()) * 0.8, 0.55, 1.0)
				draw_line(s[0], s[1], Color(hue, 0.45 * fa), 3.0, true)
				draw_line(s[0], s[1], Color(1, 1, 1, 0.8 * fa), 1.0, true)
		if t.fire_t <= 0.0:
			continue
		if t.type == "lance":
			var k: float = t.fire_t / FIRE_TIME.lance
			var top := Vector2(t.pos.x, 0.0)
			var foot: Vector2 = t.pos + Vector2(0, -46)
			draw_line(foot, top, Color(0.55, 0.8, 1.0, 0.35 * k), 9.0 * k + 2.0, true)
			draw_line(foot, top, Color(0.95, 0.98, 1.0, k), 2.5, true)
		elif t.type == "storm" and t.bolt.size() > 1:
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

func _draw_hud() -> void:
	var pill := Rect2(12, 14, 200, 30)
	draw_rect(pill, Color(0.04, 0.063, 0.172, 0.65))
	draw_rect(pill, Color(1, 1, 1, 0.14), false, 1.0)
	# stage number in white, then the name, so a stage is never mistaken for another
	var num := "%d " % stage
	draw_string(title_font, Vector2(20, 35), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
	var nx: float = 20.0 + title_font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	draw_string(title_font, Vector2(nx, 35), StageData.stage_name(stage).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 162.0 - nx - 6.0, 11, Color(0.18, 0.9, 1.0))
	var mins := int(time_alive) / 60
	var secs := int(time_alive) % 60
	draw_string(hud_font, Vector2(162, 35), "%02d:%02d" % [mins, secs], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	draw_string(hud_font, Vector2(14, 64), "SCORE %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
	draw_string(hud_font, Vector2(160, 64), "WAVE %d/%d" % [mini(wave_index + 1, waves.size()), waves.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.8, 0.9, 1.0))
	for i in max_hearts:
		var hp := Vector2(FIELD_W - 30 - (max_hearts - 1 - i) * 20, 62)
		var on: bool = i < hearts
		draw_circle(hp + Vector2(-3, -3), 4.0, Color(1.0, 0.35, 0.45) if on else Color(1, 1, 1, 0.15))
		draw_circle(hp + Vector2(3, -3), 4.0, Color(1.0, 0.35, 0.45) if on else Color(1, 1, 1, 0.15))
		draw_colored_polygon(PackedVector2Array([hp + Vector2(-7, -1), hp + Vector2(7, -1), hp + Vector2(0, 7)]), Color(1.0, 0.35, 0.45) if on else Color(1, 1, 1, 0.15))
	var need := _xp_need()
	draw_rect(Rect2(12, 74, FIELD_W - 24, 5), Color(1, 1, 1, 0.10))
	draw_rect(Rect2(12, 74, (FIELD_W - 24) * clampf(run_xp / need, 0.0, 1.0), 5), Color(0.71, 0.55, 1.0))
	draw_string(hud_font, Vector2(12, 92), "LV %d" % run_level, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.85, 0.75, 1.0))
	for e in enemies:
		if e.type == "hive_mother":
			var bw := 200.0
			draw_rect(Rect2(FIELD_W * 0.5 - bw * 0.5, 104, bw, 6), Color(1, 1, 1, 0.12))
			draw_rect(Rect2(FIELD_W * 0.5 - bw * 0.5, 104, bw * clampf(e.hp / e.hp_max, 0.0, 1.0), 6), Color(0.85, 0.35, 0.9))
			draw_string(title_font, Vector2(FIELD_W * 0.5 - 52, 100), "HIVE MOTHER", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.9, 0.7, 1.0))
