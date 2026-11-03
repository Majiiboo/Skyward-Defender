class_name AfkWallpaper
extends Control
# The "live wallpaper" behind the Home screen.
# A fake battle for atmosphere: the soldier sways above his base and shoots
# incoming enemies, small turrets on the base help, enemies burst on the shield,
# asteroids and a distant ship drift by. It cannot be touched, deals no damage,
# awards nothing and writes no saves.
#
# hub.gd tells it where it may fly (fly_top / fly_bottom) and which mood to
# use (set_elite). When a menu view opens, hub.gd hides and pauses this node.

const PILOT_H := 60.0
const SHOW_TURRETS := true   # set to false to remove the two base turrets

const CYAN := Color(0.18, 0.9, 1.0)
const PURPLE := Color(0.71, 0.55, 1.0)

var fly_top := 220.0      # soldier stays between these two heights
var fly_bottom := 600.0   # the base / horizon sits just under this
var elite := false

var _t := 0.0
var _spawn := 1.0
var _wave := 4.0
var _fire := 0.0
var _flash := 0.0
var _enemies: Array[Dictionary] = []
var _bullets: Array[Dictionary] = []
var _sparks: Array[Dictionary] = []
var _rings: Array[Dictionary] = []
var _rocks: Array[Dictionary] = []
var _streaks: Array[Dictionary] = []
var _ship: Dictionary = {}
var _ship_timer := 14.0
var _rock_timer := 1.0
var _streak_timer := 6.0
var _stars: Array = []
var _city: Array = []
var _soldier := Vector2(240, 480)
var _soldier_vx := 0.0
var _bank := 0.0
var _aim := Vector2.ZERO
var _has_aim := false
var _turret_cd: Array[float] = [0.5, 1.1]
var _turret_ang: Array[float] = [-PI / 2.0, -PI / 2.0]
var _facing := 1.0
var _facing_s := 1.0   # eases toward _facing so turning round squeezes, not snaps
var _anim := PilotSprite.Anim.new()
var _etex := {}
var _hit_t := 9.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	PilotSprite.load_style()
	for k in ["scout_up", "scout_down", "drifter_up", "drifter_down"]:
		_etex[k] = load("res://enemies/%s.png" % k)
	_stars = Backdrop.make_stars(80, 3)
	_city = Backdrop.make_city(46, 7)

func set_elite(value: bool) -> void:
	elite = value
	queue_redraw()

# ----------------------------------------------------------------- geometry

func _horizon_y() -> float:
	return fly_bottom + 14.0

func _shield_y(x: float) -> float:
	return Backdrop.shield_y(size, _horizon_y(), x)

# ------------------------------------------------------------------ update

func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	_t += dt
	_hit_t += dt
	var want_dir := (_aim - _soldier).normalized() if _has_aim else Vector2.UP
	_anim.update(PilotSprite.pose_for(false, 0.0, want_dir, _has_aim), dt)
	_move_soldier(dt)
	_spawn_enemies(dt)
	_shoot(dt)
	_step_world(dt)
	_ambient(dt)
	queue_redraw()

func _move_soldier(dt: float) -> void:
	# Slow, calm sway above the base, with only a small hover bob.
	var prev_x := _soldier.x
	var low := clampf(fly_bottom - 110.0, fly_top + 40.0, fly_bottom)
	_soldier = Vector2(
		size.x * 0.5 + sin(_t * 0.30) * size.x * 0.24 + sin(_t * 0.73) * size.x * 0.04,
		low + sin(_t * 0.6) * 9.0)
	_soldier_vx = lerpf(_soldier_vx, (_soldier.x - prev_x) / maxf(dt, 0.001), 0.1)
	# Lean toward what he is aiming at (plus a touch from his own movement).
	var aim_lean := 0.0
	if _has_aim:
		aim_lean = clampf(atan2(_aim.x - _soldier.x, _soldier.y - _aim.y) * 0.45, -0.32, 0.32)
	_bank = lerpf(_bank, aim_lean + clampf(_soldier_vx * 0.0015, -0.1, 0.1), 0.08)

func _spawn_enemies(dt: float) -> void:
	_spawn -= dt
	if _spawn <= 0.0:
		_spawn = randf_range(1.6, 2.6)
		_enemies.append(_make_enemy(Vector2(randf_range(50.0, size.x - 50.0), fly_top - 90.0), 38.0, false))
	_wave -= dt
	if _wave <= 0.0:
		_wave = randf_range(7.0, 10.0)
		var cx := randf_range(size.x * 0.3, size.x * 0.7)
		for i in 5:
			var off := float(i - 2)
			_enemies.append(_make_enemy(Vector2(cx + off * 34.0, fly_top - 90.0 - absf(off) * 24.0), 40.0, false))
		if elite or randf() < 0.3:
			_enemies.append(_make_enemy(Vector2(randf_range(70.0, size.x - 70.0), fly_top - 110.0), 24.0, true))

func _make_enemy(pos: Vector2, speed: float, heavy: bool) -> Dictionary:
	return {"pos": pos, "speed": speed, "hp": 7 if heavy else 2, "heavy": heavy,
		"r": 13.0 if heavy else 7.0, "ph": randf() * TAU}

func _nearest_enemy(from: Vector2, max_dist: float) -> int:
	var best := -1
	var best_d := max_dist
	for i in _enemies.size():
		var e: Dictionary = _enemies[i]
		if e.pos.y < 30.0:
			continue
		var d: float = from.distance_to(e.pos)
		if d < best_d:
			best_d = d
			best = i
	return best

func _shoot(dt: float) -> void:
	_flash = maxf(_flash - dt, 0.0)
	_facing_s = move_toward(_facing_s, _facing, dt * 8.0)
	var idx := _nearest_enemy(_soldier, 520.0)
	_has_aim = idx >= 0
	if _has_aim:
		_aim = _enemies[idx].pos
		var ax: float = _aim.x - _soldier.x
		if absf(ax) > 12.0:
			_facing = -1.0 if ax > 0.0 else 1.0
	var pose := _pose()
	var muzzle := _soldier + PilotSprite.muzzle(pose, PILOT_H, _flip(pose)).rotated(_bank)
	_fire -= dt
	if _fire <= 0.0 and _has_aim:
		_fire = 0.32
		var dist := muzzle.distance_to(_aim)
		var lead: Vector2 = _aim + Vector2(0, float(_enemies[idx].speed) * dist / 380.0)
		_bullets.append({"pos": muzzle, "vel": (lead - muzzle).normalized() * 380.0, "col": CYAN})
		_flash = 0.07
	if SHOW_TURRETS:
		for i in 2:
			var tx := size.x * (0.21 if i == 0 else 0.79)
			var base := Vector2(tx, _horizon_y() - 8.0)
			var ti := _nearest_enemy(base, 420.0)
			if ti >= 0:
				var tp: Vector2 = _enemies[ti].pos
				_turret_ang[i] = lerp_angle(_turret_ang[i], (tp - base).angle(), 0.12)
				_turret_cd[i] -= dt
				if _turret_cd[i] <= 0.0:
					_turret_cd[i] = randf_range(0.8, 1.2)
					var dir := Vector2.from_angle(_turret_ang[i])
					_bullets.append({"pos": base + dir * 16.0, "vel": dir * 320.0, "col": PURPLE})

func _step_world(dt: float) -> void:
	for e in _enemies:
		e.pos.y += e.speed * dt
		e.pos.x += sin(_t * 1.6 + e.ph) * 9.0 * dt
	for b in _bullets:
		b.pos += b.vel * dt
	var live_bullets: Array[Dictionary] = []
	for b in _bullets:
		var hit := false
		for e in _enemies:
			if b.pos.distance_to(e.pos) < e.r + 3.0:
				e.hp -= 1
				hit = true
				for k in 3:
					_sparks.append({"pos": b.pos, "vel": Vector2(randf_range(-90, 90), randf_range(-90, 90)), "life": 0.28, "col": b.col})
				break
		if not hit and b.pos.y > -20.0 and b.pos.y < size.y + 20.0 and b.pos.x > -20.0 and b.pos.x < size.x + 20.0:
			live_bullets.append(b)
	_bullets = live_bullets
	var live_enemies: Array[Dictionary] = []
	for e in _enemies:
		if e.hp <= 0:
			_burst(e.pos, e.r, Color(1.0, 0.8, 0.4))
		elif e.pos.y >= Backdrop.limb_y(size, _horizon_y(), e.pos.x) - 6.0:
			_burst(e.pos, e.r * 1.6, CYAN)
			_hit_t = 0.0
		else:
			live_enemies.append(e)
	_enemies = live_enemies
	var live_sparks: Array[Dictionary] = []
	for s in _sparks:
		s.pos += s.vel * dt
		s.life -= dt
		if s.life > 0.0:
			live_sparks.append(s)
	_sparks = live_sparks
	var live_rings: Array[Dictionary] = []
	for r in _rings:
		r.life -= dt
		if r.life > 0.0:
			live_rings.append(r)
	_rings = live_rings

func _burst(p: Vector2, radius: float, col: Color) -> void:
	_rings.append({"pos": p, "life": 0.4, "max": 0.4, "r": radius * 2.6, "col": col})
	for k in 7:
		_sparks.append({"pos": p, "vel": Vector2(randf_range(-110, 110), randf_range(-110, 110)), "life": 0.4, "col": col})

func _ambient(dt: float) -> void:
	# slow asteroids
	_rock_timer -= dt
	if _rock_timer <= 0.0:
		_rock_timer = randf_range(4.0, 7.0)
		var shape: Array[float] = []
		for k in 8:
			shape.append(randf_range(0.65, 1.0))
		_rocks.append({"pos": Vector2(randf_range(20.0, size.x - 20.0), -30.0), "vel": Vector2(randf_range(-6.0, 6.0), randf_range(9.0, 17.0)),
			"r": randf_range(9.0, 20.0), "rot": randf() * TAU, "spin": randf_range(-0.4, 0.4), "shape": shape})
	var live_rocks: Array[Dictionary] = []
	for r in _rocks:
		r.pos += r.vel * dt
		r.rot += r.spin * dt
		if r.pos.y < _horizon_y() - 30.0:
			live_rocks.append(r)
	_rocks = live_rocks
	# a distant ship now and then
	_ship_timer -= dt
	if _ship.is_empty() and _ship_timer <= 0.0:
		var dir := 1.0 if randf() < 0.5 else -1.0
		_ship = {"x": -90.0 if dir > 0.0 else size.x + 90.0, "y": size.y * 0.14, "dir": dir}
	if not _ship.is_empty():
		_ship.x += _ship.dir * 9.0 * dt
		if _ship.x < -130.0 or _ship.x > size.x + 130.0:
			_ship = {}
			_ship_timer = randf_range(25.0, 40.0)
	# rare shooting stars
	_streak_timer -= dt
	if _streak_timer <= 0.0:
		_streak_timer = randf_range(6.0, 12.0)
		_streaks.append({"pos": Vector2(randf_range(0.0, size.x), randf_range(20.0, size.y * 0.3)), "vel": Vector2(randf_range(-160, -90), randf_range(120, 190)), "life": 0.7})
	var live_streaks: Array[Dictionary] = []
	for s in _streaks:
		s.pos += s.vel * dt
		s.life -= dt
		if s.life > 0.0:
			live_streaks.append(s)
	_streaks = live_streaks

# ------------------------------------------------------------------- drawing

func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 12:
		var a := TAU * float(i) / 12.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)

func _soft_glow(c: Vector2, radius: float, col: Color) -> void:
	for i in 14:
		var t := float(i) / 13.0
		draw_circle(c, lerpf(radius, radius * 0.12, t), Color(col, col.a * 0.16))

func _draw() -> void:
	Backdrop.draw_sky(self, size, elite, _stars, _t)
	for s in _streaks:
		draw_line(s.pos, s.pos - s.vel.normalized() * 34.0, Color(1, 1, 1, clampf(s.life, 0.0, 0.8)), 1.5, true)
	_draw_ship()
	_draw_rocks()
	Backdrop.draw_horizon(self, size, _horizon_y(), elite, _city, _t)
	Backdrop.draw_deck(self, size.x, _horizon_y(), 26.0, [0.18, 0.36, 0.64, 0.82], _t, elite)
	Backdrop.draw_base(self, Vector2(size.x * 0.5, _horizon_y() - 28.0), _t, elite)
	if SHOW_TURRETS:
		_draw_turrets()
	_draw_enemies()
	for b in _bullets:
		draw_line(b.pos, b.pos - b.vel.normalized() * 11.0, b.col, 2.0, true)
	for r in _rings:
		var k: float = 1.0 - r.life / r.max
		draw_arc(r.pos, r.r * k, 0.0, TAU, 20, Color(r.col, (1.0 - k) * 0.7), 2.0, true)
	for s in _sparks:
		draw_circle(s.pos, 1.6, Color(s.col, clampf(s.life * 3.0, 0.0, 1.0)))
	_draw_soldier()

func _draw_ship() -> void:
	if _ship.is_empty():
		return
	var p := Vector2(_ship.x, _ship.y)
	var d: float = _ship.dir
	var pts := PackedVector2Array([p + Vector2(-70 * d, 0), p + Vector2(-30 * d, -10), p + Vector2(40 * d, -8),
		p + Vector2(84 * d, 3), p + Vector2(40 * d, 12), p + Vector2(-30 * d, 10)])
	draw_colored_polygon(pts, Color(0.03, 0.045, 0.11, 0.7))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3]]), Color(CYAN, 0.16), 1.2, true)
	draw_circle(p + Vector2(-72 * d, -3), 3.0, Color(CYAN, 0.55))
	draw_circle(p + Vector2(-72 * d, 4), 3.0, Color(CYAN, 0.55))
	draw_circle(p + Vector2(20 * d, -1), 1.6, Color(1.0, 0.4, 0.4, 0.7))

func _draw_rocks() -> void:
	for r in _rocks:
		var pts := PackedVector2Array()
		var shape: Array = r.shape
		for i in shape.size():
			var a: float = r.rot + TAU * float(i) / float(shape.size())
			pts.append(r.pos + Vector2(cos(a), sin(a)) * r.r * float(shape[i]))
		draw_colored_polygon(pts, Color(0.06, 0.07, 0.13, 0.85))
		var edge := PackedVector2Array(pts)
		edge.append(pts[0])
		draw_polyline(edge, Color(CYAN, 0.18), 1.2, true)

func _draw_turrets() -> void:
	for i in 2:
		var tx := size.x * (0.18 if i == 0 else 0.82)
		Backdrop.draw_turret(self, Vector2(tx, _horizon_y() - 34.0), _turret_ang[i], _t, maxf(0.0, 1.0 - _turret_cd[i] * 2.5))

func _draw_enemies() -> void:
	for e in _enemies:
		var a := clampf((e.pos.y - (fly_top - 100.0)) / 60.0, 0.0, 1.0)   # fades in as it enters
		EnemyRig.draw_bug(self, "drifter" if e.heavy else "scout", e.pos, e.r * 2.6 * 2.0, _t, float(e.ph), sin(_t * 1.3 + e.ph) * 0.12, 0.0, 1.0, a)

func _pose() -> String:
	return _anim.pose()

func _flip(_pose: String) -> bool:
	if _anim.pose().begins_with("aim"):
		return _facing_s < 0.0
	return _anim.mirrored()

func _draw_soldier() -> void:
	var pose := _pose()
	if _has_aim:
		draw_line(_soldier + PilotSprite.muzzle(pose, PILOT_H, _flip(pose)).rotated(_bank), _aim, Color(CYAN, 0.08), 1.0, true)
	var turn: float = clampf(absf(_facing_s), 0.15, 1.0) if pose.begins_with("aim") else 1.0
	PilotSprite.draw(self, _soldier, PILOT_H, pose, _flip(pose), _bank, _t, 1.0, clampf(_soldier_vx * 0.02, -1.0, 1.0),
		smoothstep(0.0, 0.07, _flash), _anim.mix(), turn)
