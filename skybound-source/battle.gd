extends Node2D
# Skybound battle-screen SPIKE — 0.9, not v1.0.
# Scope, deliberately small: one battle only.
# No hub, no store, no save, no stages, no Codex, no Gear.
# What it proves: native touch drag (no WebView host), auto-fire,
# one enemy type, one boss pattern, base + shield arc, one element visual.
# Everything here is throwaway spike code — the v1.0 rebuild re-implements
# the full game in GDScript, it does not copy this file verbatim.

const FIELD_W := 480.0
const FIELD_H := 800.0
const BASE_Y := 740.0
const DRAG_OFFSET := 52.0

var soldier_pos := Vector2(240, 620)
var dragging := false
var drag_id := -1
var last_touch := Vector2.ZERO
var hearts := 3
var shield := 150.0
var hull := 100.0
var score := 0
var kills := 0
var time_alive := 0.0
var fire_timer := 0.0
var spawn_timer := 0.0
var boss_spawned := false
var boss_hp := 120.0
var boss_max := 120.0
var boss_pos := Vector2(240, 140)
var boss_dir := 1.0
var boss_shot_timer := 0.0
var boss_transformed := false
var game_over := false

# element: 0 = Fire (spike default, orange flame bullets)
var bullets: Array = []   # {pos, vel}
var enemy_bullets: Array = []
var enemies: Array = []   # {pos, hp, speed}
var particles: Array = []

@onready var hud: Label = $HUD
@onready var hint: Label = $Hint
@onready var hub_button: Button = $HubButton
var saved_best := false

var prev_soldier_x := 240.0
var bank_smooth := 0.0
var draw_bank := 0.0
var gun_sway := 0.0
var gun_recoil := 0.0
var gun_raise := 0.0
var idle_aiming := false
var idle_aim_ang := -PI / 2.0
var idle_power := 1.0  # Gear/chips hook: raise this later to make idle shooting stronger (1.0 = half manual DPS, 2.0 = manual DPS, higher = stronger than manual)
var trail_timer := 0.0
var trail_color := Color(0.2, 0.85, 1.0)
var trail: Array = []
var soldier_tex: Texture2D = preload("res://soldier_body.png")
var part_head: Texture2D = preload("res://parts/head.png")
var part_torso: Texture2D = preload("res://parts/torso.png")
var part_jetpack: Texture2D = preload("res://parts/jetpack.png")
var part_arm_left: Texture2D = preload("res://parts/arm_left.png")
var part_arm_right: Texture2D = preload("res://parts/arm_right.png")
var part_leg_left: Texture2D = preload("res://parts/leg_left.png")
var part_leg_right: Texture2D = preload("res://parts/leg_right.png")
var body_head: Texture2D = preload("res://parts/body_head.png")
var body_torso: Texture2D = preload("res://parts/body_torso.png")
var body_arm_left: Texture2D = preload("res://parts/body_arm_left.png")
var body_arm_right: Texture2D = preload("res://parts/body_arm_right.png")
var body_leg_left: Texture2D = preload("res://parts/body_leg_left.png")
var body_leg_right: Texture2D = preload("res://parts/body_leg_right.png")

func _ready() -> void:
	$Hint.position.y = get_viewport_rect().size.y - 40
	hub_button.pressed.connect(func(): get_tree().change_scene_to_file("res://hub.tscn"))
	hint.text = "SKYBOUND v1.0-dev18 — Hub is live\nTap HUB to go home. Tap to Battle to return.\nBoss at 30s. Tap anywhere on game over to restart."
	_update_hud()

func _update_hud() -> void:
	var boss_txt := ""
	if boss_spawned and not game_over:
		boss_txt = "\nBOSS %d / %d" % [int(boss_hp), int(boss_max)]
	hud.text = "SCORE %d  KILLS %d\nHEARTS %s  SHIELD %d  HULL %d%s" % [
		score, kills, "♥".repeat(hearts), int(shield), int(hull), boss_txt]

# --- Native touch drag: Godot's InputEventScreenTouch / Drag ---
# This is the whole point of the spike vs the web build: the OS hands
# touch directly to the game, no WebView host recognizer in between
# to cancel the stream mid-drag (the test1–test15 drag-bug root cause).
func _input(event: InputEvent) -> void:
	if game_over:
		if event is InputEventKey and event.pressed and event.keycode == KEY_R:
			_reset()
			return
		if event is InputEventScreenTouch and event.pressed:
			_reset()
			return
		if event is InputEventMouseButton and event.pressed:
			_reset()
			return
	if event is InputEventScreenTouch:
		if event.pressed and not dragging:
			# RELATIVE DRAG: touch ANYWHERE on screen to start. No grab
			# radius, no teleport — the soldier stays where he is, and
			# moving your finger moves him by the same amount.
			dragging = true
			drag_id = event.index
			last_touch = event.position
		elif not event.pressed and event.index == drag_id:
			dragging = false
			drag_id = -1
	elif event is InputEventScreenDrag:
		if dragging and event.index == drag_id:
			var d: Vector2 = event.position - last_touch
			last_touch = event.position
			soldier_pos.x = clamp(soldier_pos.x + d.x, 24, FIELD_W - 24)
			soldier_pos.y = clamp(soldier_pos.y + d.y, 120, BASE_Y - 60)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# Desktop / editor testing only — phone uses the touch path above.
		if not dragging:
			dragging = true
			last_touch = event.position
		else:
			var dm: Vector2 = event.position - last_touch
			last_touch = event.position
			soldier_pos.x = clamp(soldier_pos.x + dm.x, 24, FIELD_W - 24)
			soldier_pos.y = clamp(soldier_pos.y + dm.y, 120, BASE_Y - 60)

func _reset() -> void:
	hearts = 3; shield = 150.0; hull = 100.0; score = 0; kills = 0
	time_alive = 0.0; boss_spawned = false; boss_hp = boss_max
	boss_transformed = false; game_over = false
	soldier_pos = Vector2(240, 620); last_touch = Vector2.ZERO; gun_raise = 0.0; prev_soldier_x = 240.0; bank_smooth = 0.0; draw_bank = 0.0; gun_sway = 0.0; gun_recoil = 0.0; gun_raise = 0.0
	dragging = false; drag_id = -1; saved_best = false
	bullets.clear(); enemy_bullets.clear(); enemies.clear(); particles.clear(); trail.clear()
	_update_hud()

func _process(delta: float) -> void:
	if game_over:
		if not saved_best:
			saved_best = true
			var best_score := score
			var best_kills := kills
			if FileAccess.file_exists("user://skybound_save.json"):
				var f := FileAccess.open("user://skybound_save.json", FileAccess.READ)
				if f:
					var data = JSON.parse_string(f.get_as_text())
					if typeof(data) == TYPE_DICTIONARY:
						best_score = max(best_score, int(data.get("best_score", 0)))
						best_kills = max(best_kills, int(data.get("best_kills", 0)))
			var out := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
			if out:
					out.store_string(JSON.stringify({"best_score": best_score, "best_kills": best_kills, "coins": 0}))
		queue_redraw()
		return
	time_alive += delta

	# IDLE AUTO-AIM (dev16, Rudy): finger lifted + enemies on screen = he
	# aims at the nearest enemy and fires on his own, at about half manual
	# DPS (0.44s vs 0.22s). Finger down = auto-aim OFF, manual up shooting.
	# No enemies = stance, no firing. Idle alone cannot beat tougher waves:
	# enemy HP scales, idle does not dodge, and manual + turrets + weapons
	# stack on top. Later, Gear/chips raise idle_power to make idle stronger.
	idle_aiming = false
	var nearest_d: float = 1e9
	var target_pos := Vector2.ZERO
	var target_vel := Vector2.ZERO
	for e in enemies:
		var d: float = soldier_pos.distance_to(e.pos)
		if d < nearest_d:
			nearest_d = d; target_pos = e.pos; target_vel = Vector2(0, e.speed)
	if boss_spawned and boss_hp > 0:
		var bd: float = soldier_pos.distance_to(boss_pos)
		if bd < nearest_d:
			nearest_d = bd; target_pos = boss_pos; target_vel = Vector2(boss_dir * (90.0 if boss_transformed else 55.0), 0)
	if nearest_d < 1e8:
		# PREDICTIVE LEAD (dev17 fix): aim at where the enemy WILL be when
		# the bullet gets there, not where it is now. Bullet 520 px/s, enemy
		# falls at its speed. Without lead, far side enemies miss by 30-40px.
		var muzzle_base := soldier_pos + Vector2(-20, -8).rotated(-draw_bank)
		var flight_t: float = muzzle_base.distance_to(target_pos) / 520.0
		var lead_pos := target_pos + target_vel * flight_t
		idle_aim_ang = (lead_pos - muzzle_base).angle()
	if not dragging and nearest_d < 1e8:
		idle_aiming = true
		# Clamp to upward hemisphere: gun never points down at the base.
		idle_aim_ang = clamp(idle_aim_ang, -PI / 2.0 - 1.2, -PI / 2.0 + 1.2)
	fire_timer -= delta
	if dragging and fire_timer <= 0:
		fire_timer = 0.22
		gun_recoil = 1.0
		var muzzle_ang: float = -PI / 2.0 + gun_sway - draw_bank
		var muzzle_dir := Vector2(cos(muzzle_ang), sin(muzzle_ang))
		var muzzle_pos := soldier_pos + Vector2(-20, -8).rotated(-draw_bank) + muzzle_dir * 36.0
		bullets.append({"pos": muzzle_pos, "vel": muzzle_dir * 520.0})
	elif idle_aiming and fire_timer <= 0:
		fire_timer = 0.32 / idle_power
		gun_recoil = 1.0
		var idle_dir := Vector2(cos(idle_aim_ang), sin(idle_aim_ang))
		var idle_muzzle := soldier_pos + Vector2(-20, -8).rotated(-draw_bank) + idle_dir * 36.0
		bullets.append({"pos": idle_muzzle, "vel": idle_dir * 520.0})

	# One enemy type: Scout. Descends, drifts slightly, shoots rarely.
	spawn_timer -= delta
	if spawn_timer <= 0 and not boss_spawned:
		spawn_timer = 1.1
		enemies.append({"pos": Vector2(randf_range(30, FIELD_W - 30), -20),
			"hp": 2.0, "speed": randf_range(55, 85)})

	if time_alive >= 30.0 and not boss_spawned:
		boss_spawned = true
		boss_hp = boss_max

	_update_bullets(delta)
	_update_enemies(delta)
	_update_boss(delta)
	# Relative drag moves soldier_pos directly in _input, so there is
	# nothing to chase here — no teleport, no target to follow.
	# Gun raise follows the finger: dragging -> raises to firing position,
	# lifted -> lowers back to across-chest stance. About 0.3s each way.
	if dragging or idle_aiming:
		gun_raise = min(1.0, gun_raise + delta * 6.0)
	else:
		gun_raise = max(0.0, gun_raise - delta * 6.0)
	# 2D+depth: soldier faces up always, banks slightly with drag direction.
	# draw_bank is consumed by _draw() for the tilt — no 3D model involved.
	var dx: float = soldier_pos.x - prev_soldier_x
	prev_soldier_x = soldier_pos.x
	var bank_target: float = clamp(dx * 0.02, -0.30, 0.30)
	bank_smooth = lerp(bank_smooth, bank_target, min(1.0, delta * 10.0))
	draw_bank = bank_smooth
	# Gun momentum: guns lag behind the soldier (slower smoothing than the
	# body bank), swing with drag, then settle back to straight up.
	# No auto-aim, no homing — bullets still fly straight up, the guns just
	# *move* like modern guns do: pivot, sway, recoil, settle.
	var sway_target: float = clamp(dx * 0.025, -0.55, 0.55)
	gun_sway = lerp(gun_sway, sway_target, min(1.0, delta * 8.0))
	gun_recoil = gun_recoil * exp(-delta * 12.0)
	# TRAIL REMOVED FOR NOW (dev13, Rudy): jetpack trail spawned at head
	# height and read as trails coming out of the sides of his head, and
	# muddied the head stitching. Trail hook (trail_color) stays for later
	# — when it returns, it will spawn lower, from the jetpack exhaust,
	# not at shoulder/head height. No dots spawn until then.
	trail.clear()
	var next_trail: Array = []
	for tr in trail:
		tr.pos.y += 25.0 * delta
		tr.pos.x += tr.get("vx", 0.0) * delta
		tr.t -= delta
		if tr.t > 0:
			next_trail.append(tr)
	trail = next_trail
	_update_hud()
	queue_redraw()

func _update_bullets(delta: float) -> void:
	var next: Array = []
	for b in bullets:
		b.pos += b.vel * delta
		if b.pos.y < -20:
			continue
		var hit := false
		for e in enemies:
			if b.pos.distance_to(e.pos) < 22:
				e.hp -= 1
				hit = true
				if e.hp <= 0:
					score += 100; kills += 1
					particles.append({"pos": e.pos, "t": 0.3})
				break
		if boss_spawned and b.pos.distance_to(boss_pos) < 42:
			boss_hp -= 1; hit = true
			if boss_hp <= 0:
				score += 1000; boss_spawned = false
		if not hit:
			next.append(b)
	bullets = next
	enemies = enemies.filter(func(e): return e.hp > 0)

func _update_enemies(delta: float) -> void:
	var next: Array = []
	for e in enemies:
		e.pos.y += e.speed * delta
		# Leak: enemy reaches the shield arc -> shield takes it first.
		if e.pos.y >= BASE_Y - 70:
			_hurt_base(10)
			particles.append({"pos": Vector2(e.pos.x, BASE_Y - 70), "t": 0.4})
			continue
		# Player contact: -1 heart, brief knockback handled by hearts only in spike.
		if e.pos.distance_to(soldier_pos) < 26:
			hearts -= 1
			particles.append({"pos": soldier_pos, "t": 0.4})
			if hearts <= 0:
				game_over = true
			continue
		next.append(e)
	enemies = next

func _hurt_base(dmg: float) -> void:
	# Shield-first, hull overflow, hull never regenerates — same 0.9C model.
	var remaining := dmg
	if shield > 0:
		var absorbed: float = min(shield, remaining)
		shield -= absorbed; remaining -= absorbed
	if remaining > 0:
		hull -= remaining
	if hull <= 0:
		hull = 0; game_over = true
	_update_hud()

func _update_boss(delta: float) -> void:
	if not boss_spawned:
		return
	# Transform under 40% HP: faster, wider spread — same 0.9C rule.
	if boss_hp < boss_max * 0.4 and not boss_transformed:
		boss_transformed = true
	boss_pos.x += (90.0 if boss_transformed else 55.0) * boss_dir * delta
	if boss_pos.x < 60 or boss_pos.x > FIELD_W - 60:
		boss_dir *= -1
	boss_shot_timer -= delta
	if boss_shot_timer <= 0:
		boss_shot_timer = 1.4 if boss_transformed else 2.0
		var angles := [-0.35, 0.0, 0.35] if boss_transformed else [-0.2, 0.2]
		for a in angles:
			enemy_bullets.append({"pos": boss_pos + Vector2(0, 30),
				"vel": Vector2(sin(a) * 180, 220)})
	var next_eb: Array = []
	for b in enemy_bullets:
		b.pos += b.vel * delta
		if b.pos.y > BASE_Y - 70:
			_hurt_base(4); continue
		if b.pos.distance_to(soldier_pos) < 22:
			hearts -= 1
			if hearts <= 0:
				game_over = true
			continue
		if b.pos.y < FIELD_H + 20:
			next_eb.append(b)
	enemy_bullets = next_eb

func _draw() -> void:
	# Full-screen background: fill the whole viewport, not just 480x800,
	# so expand stretch shows dark space, not black letterbox bars.
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.02, 0.04, 0.08))
	# Starfield background + soft nebula blobs = depth without 3D.
	draw_rect(Rect2(0, 0, FIELD_W, FIELD_H), Color(0.02, 0.04, 0.08))
	draw_circle(Vector2(90, 180), 110, Color(0.15, 0.2, 0.5, 0.18))
	draw_circle(Vector2(390, 320), 130, Color(0.3, 0.15, 0.5, 0.15))
	draw_circle(Vector2(240, 560), 90, Color(0.1, 0.4, 0.4, 0.12))
	# Base deck + shield arc: thick arc = shield, thin arc = hull, no number.
	var shield_a := Color(0.2, 0.8, 1.0, 0.9) if shield > 45 else Color(1.0, 0.6, 0.2, 0.9)
	draw_arc(Vector2(FIELD_W / 2, BASE_Y), 190, PI, 2 * PI, 48, shield_a, 10.0)
	draw_arc(Vector2(FIELD_W / 2, BASE_Y), 170, PI, 2 * PI, 48, Color(0.4, 0.9, 0.5, 0.9), 4.0)
	draw_rect(Rect2(40, BASE_Y, FIELD_W - 80, 40), Color(0.15, 0.2, 0.3))
	draw_line(Vector2(40, BASE_Y), Vector2(FIELD_W - 40, BASE_Y), Color(0.45, 0.6, 0.7), 2.0)
	# Trail dots, behind the soldier, fading out.
	for tr in trail:
		draw_circle(tr.pos, 4.0 * (tr.t / 0.5), Color(trail_color.r, trail_color.g, trail_color.b, tr.t / 0.5))
	# ANIMATED 2D SOLDIER — v4: bob, squash, alternating legs, pop-out shadow,
	# and DETAILED GUNS WITH MOMENTUM (not auto-aim, not homing).
	# Guns pivot smoothly with drag (gun_sway, slower than the body bank),
	# recoil back on every shot, then settle. That lag + settle is the
	# modern feel Rudy pointed to in the reference video.
	var bob: float = sin(time_alive * 6.0) * 3.5
	var squash: float = 1.0 + sin(time_alive * 6.0) * 0.05
	# Legs move TOGETHER with the bob — this soldier hovers on thrusters,
	# he is not walking, so alternating walking legs looked wrong.
	var leg_lift: float = bob * 0.3
	# Shadow stays grounded under the soldier and pulses opposite the bob,
	# so the figure reads as popped off the 2D image.
	draw_set_transform(soldier_pos + Vector2(0, 42), 0.0, Vector2(1.4 - bob * 0.01, 0.45))
	draw_circle(Vector2.ZERO, 16, Color(0, 0, 0, 0.45))
	# LAYERED RIG, done right from the start: BODY underneath, ARMOR on top.
	# Body pieces (face, plain suit) move with the same rig, armor pieces sit
	# over them. A future half-visor helmet only needs a top-half armor piece
	# — the face underneath already shows through. Head, torso, orb, jetpack, arms, legs are
	# separate pieces (overlapping crops of the chibi), each with its own
	# offset/rotation, so they can move independently. Draw order:
	# jetpack (behind) -> legs -> torso -> head -> arms -> orb -> gun.
	# Battle scale: 44px wide / 815px original = 0.054, centre (407, 741).
	var rig_s: float = 44.0 / 815.0
	var leg_flutter_l: float = sin(time_alive * 10.0) * 1.5
	var leg_flutter_r: float = sin(time_alive * 10.0 + PI) * 1.5
	var lift_r: float = max(0.0, draw_bank) * 15.0
	var lift_l: float = max(0.0, -draw_bank) * 15.0
	# Jetpack, behind everything, tilts a little more than the body.
	draw_set_transform(soldier_pos + Vector2(0, bob * 0.5), -draw_bank * 1.2, Vector2(2.0 - squash, squash))
	draw_texture_rect(part_jetpack, Rect2(-22, -4.9, 44, 27), false)
	# Legs: flutter while hovering, one knee lifts on the side you move to.
	draw_set_transform(soldier_pos + Vector2(0, bob), -draw_bank, Vector2(2.0 - squash, squash))
	draw_texture_rect(body_leg_left, Rect2(-22, 17.3 - lift_l + leg_flutter_l, 23.3, 23.9), false)
	draw_texture_rect(body_leg_right, Rect2(-1.4, 17.3 - lift_r + leg_flutter_r, 23.4, 23.9), false)
	draw_texture_rect(part_leg_left, Rect2(-22, 16.7 - lift_l + leg_flutter_l, 23.2, 23.4), false)
	draw_texture_rect(part_leg_right, Rect2(-1.2, 16.7 - lift_r + leg_flutter_r, 23.2, 23.4), false)
	# Torso: leans with drag, squashes with bob.
	draw_set_transform(soldier_pos + Vector2(0, bob), -draw_bank, Vector2(2.0 - squash, squash))
	draw_texture_rect(body_torso, Rect2(-14.1, -4.9, 28.2, 30.4), false)
	draw_texture_rect(part_torso, Rect2(-13.9, -4.9, 27.8, 29.7), false)
	# Head: separate from torso, looks side to side with drag.
	draw_set_transform(soldier_pos + Vector2(draw_bank * 8.0, bob), -draw_bank * 1.5, Vector2(2.0 - squash, squash))
	draw_texture_rect(body_head, Rect2(-21, -40.5, 42, 42.5), false)
	draw_texture_rect(part_head, Rect2(-22, -40, 44, 43.2), false)
	# Arms: move with the gun — raise with gun_raise, sway with drag.
	draw_set_transform(soldier_pos + Vector2(gun_sway * 4.0, bob - gun_raise * 4.0), -draw_bank + gun_sway * 0.5, Vector2(2.0 - squash, squash))
	draw_texture_rect(body_arm_left, Rect2(-22, -4.9, 23.3, 28.0), false)
	draw_texture_rect(body_arm_right, Rect2(-1.4, -4.9, 23.4, 28.0), false)
	draw_texture_rect(part_arm_left, Rect2(-22, -4.9, 23.2, 27), false)
	draw_texture_rect(part_arm_right, Rect2(-1.2, -4.9, 23.2, 27), false)
	# Reset to body transform for orb / flames / gun below.
	draw_set_transform(soldier_pos + Vector2(0, bob), -draw_bank, Vector2(2.0 - squash, squash))
	# ANIMATION LAYERS on top of the static sprite, so he never reads as
	# a pasted picture: orb pulses, visor glows, body breathes (squash).
	var orb_pulse: float = 0.5 + 0.5 * sin(time_alive * 4.0)
	draw_circle(Vector2(0, -10), 5.0 + orb_pulse * 1.5, Color(0.65, 0.35, 1.0, 0.25 + orb_pulse * 0.25))
	draw_circle(Vector2(0, -25), 7.0, Color(0.2, 0.85, 1.0, 0.12 + orb_pulse * 0.12))
	# THRUSTERS, done the way Rudy described: the big code flames at the
	# sides of his head/torso are GONE — they made no sense there.
	# Instead: (1) the sprite's own small torso-side thrusters get a little
	# blue glow, slightly bigger, so they read as hovering thrusters;
	# (2) top thrusters are very subtle, and only flare when moving
	# left/right, popping up with the movement, not glowing all the time.
	# No extra glow orbs at the torso sides (dev15): the sprite's own small
	# thrusters are enough. Extra glow circles just floated as orbs.
	var move_flare: float = clamp(abs(draw_bank) * 4.0, 0.0, 1.0)
	if move_flare > 0.05:
		var top_flame: float = 3.0 + 2.0 * sin(time_alive * 20.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-20, -12), Vector2(-15, -12), Vector2(-17, -12 - top_flame * move_flare)]), Color(0.2, 0.85, 1.0, 0.6 * move_flare))
		draw_colored_polygon(PackedVector2Array([
			Vector2(15, -12), Vector2(20, -12), Vector2(17, -12 - top_flame * move_flare)]), Color(0.2, 0.85, 1.0, 0.6 * move_flare))
	# Ankle side rockets: small boost flames on the side that pushes you.
	if draw_bank < -0.05:
		draw_colored_polygon(PackedVector2Array([
			Vector2(13, 33), Vector2(13, 38), Vector2(18, 35)]), Color(1.0, 0.6, 0.2))
	elif draw_bank > 0.05:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-13, 33), Vector2(-13, 38), Vector2(-18, 35)]), Color(1.0, 0.6, 0.2))
	# SINGLE TWO-HANDED GUN: starts across the chest (gun_raise=0, angled
	# about -45deg), raises to firing position (gun_raise=1, angled up
	# about 10deg off vertical, not perfectly straight up) when shooting
	# starts, and leans with drag (gun_sway + body bank).
	# Both hands on the grip — that is the battle stance, not a menu pose.
	var gun_ang: float = lerp(-0.25, -PI / 2.0 + gun_sway, gun_raise)
	if idle_aiming:
		gun_ang = idle_aim_ang
	var gun_dir := Vector2(cos(gun_ang), sin(gun_ang))
	var gun_base_pos := Vector2(-8, 12).lerp(Vector2(-20, -8), gun_raise)
	var gun_base := gun_base_pos + gun_dir * gun_recoil * 2.5
	var gun_tip := gun_base + gun_dir * 36.0
	draw_circle(gun_base, 7, Color(0.04, 0.08, 0.12))
	draw_line(gun_base, gun_tip, Color(0.05, 0.08, 0.12), 7.0)
	draw_line(gun_base, gun_tip, Color(0.35, 0.45, 0.55), 2.0)
	var gun_perp := Vector2(-gun_dir.y, gun_dir.x)
	var gun_mid := gun_base + gun_dir * 18.0
	draw_line(gun_mid - gun_perp * 4.0, gun_mid + gun_perp * 4.0, Color(0.15, 0.2, 0.25), 2.0)
	draw_circle(gun_tip, 4, Color(0.25, 0.35, 0.45))
	if gun_recoil > 0.7:
		draw_circle(gun_tip + gun_dir * 4.0, 6, Color(1.0, 0.85, 0.4))
	# Hands on the gun: two grip circles along the barrel.
	draw_circle(gun_base + gun_dir * 8.0, 3, Color(0.15, 0.25, 0.30))
	draw_circle(gun_base + gun_dir * 16.0, 3, Color(0.15, 0.25, 0.30))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Fire bullets: orange flame teardrops (element visual, same idea as web).
	for b in bullets:
		draw_circle(b.pos, 5, Color(1.0, 0.5, 0.1))
		draw_circle(b.pos + Vector2(0, 6), 3, Color(1.0, 0.8, 0.3))
	for e in enemies:
		draw_circle(e.pos, 12, Color(0.9, 0.2, 0.3))
	for b in enemy_bullets:
		draw_circle(b.pos, 5, Color(1.0, 0.2, 0.6))
	if boss_spawned:
		var bc := Color(0.7, 0.2, 0.9) if boss_transformed else Color(0.5, 0.3, 0.8)
		draw_circle(boss_pos, 38, bc)
		draw_circle(boss_pos, 20, Color(0.1, 0.1, 0.2))
	for p in particles:
		draw_circle(p.pos, 10, Color(1.0, 0.8, 0.2))
	if game_over:
		draw_string(ThemeDB.get_default_theme().default_font, Vector2(170, 380),
			"GAME OVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
		draw_string(ThemeDB.get_default_theme().default_font, Vector2(110, 410),
			"Tap anywhere to restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
