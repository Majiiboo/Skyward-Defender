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
const STRIP_DROP := 16.0       # base strip bottom, below the horizon line
const WALL_TURRET_H := 64.0
const SHOW_TURRETS := true   # set to false to hide the turrets on the base strip

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
var _wall_turrets: Array = []
var _turret_cd: Array[float] = [0.5, 1.1, 0.8, 1.4]
var _turret_ang: Array[float] = [-PI / 2.0, -PI / 2.0, -PI / 2.0, -PI / 2.0]
var _wall_unlocked := 1
var _facing := 1.0
var _facing_s := 1.0   # eases toward _facing so turning round squeezes, not snaps
var _anim := PilotSprite.Anim.new()
var _rig_view: PilotRigView   # the new cut-out pilot (PilotRig.ENABLED); null = painted PilotSprite
var _etex := {}
var _hit_t := 9.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	PilotSprite.load_style()
	_load_wall_turrets()
	# Gear opens over Home: re-read the loadout when Home shows again
	visibility_changed.connect(func(): if is_visible_in_tree(): _load_wall_turrets())
	for k in ["scout_up", "scout_down", "drifter_up", "drifter_down"]:
		_etex[k] = load("res://enemies/%s.png" % k)
	_stars = Backdrop.make_stars(80, 3)
	_city = Backdrop.make_city(46, 7)
	if PilotRig.ENABLED:
		_rig_view = PilotRigView.new()
		_rig_view.height = PILOT_H
		add_child(_rig_view)

func set_elite(value: bool) -> void:
	elite = value
	queue_redraw()

# The selected stage picks the painted world behind Home (its sector's "bg"); flipping
# stages cross-fades from the old world to the new one.
var stage := 1
var _roster: Array = ["scout"]
var _boss := ""   # "mini" / "boss" on stages that end with a Hive Mother
var _world := ""
var _world_prev := ""
var _world_fade := 1.0
func set_stage(value: int) -> void:
	stage = value
	# the bugs of this stage fly in the Home battle (the boss only looms on boss stages)
	_roster.clear()
	for wave in StageData.waves(stage):
		for entry in wave:
			var kind: String = entry[0]
			if kind != "hive_mother" and not _roster.has(kind) and EnemyRig.PARTS.has(kind):
				_roster.append(kind)
	if _roster.is_empty():
		_roster = ["scout"]
	_boss = StageData.boss_kind(stage)
	var key := String(StageData.sector(stage).get("bg", ""))
	if key != _world:
		_world_prev = _world
		_world = key
		_world_fade = 0.0 if _world_prev != "" else 1.0
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
	_world_fade = minf(_world_fade + dt / 0.6, 1.0)
	var want_dir := (_aim - _soldier).normalized() if _has_aim else Vector2.UP
	_anim.update(PilotSprite.pose_for(false, 0.0, want_dir, _has_aim), dt)
	_move_soldier(dt)
	if _rig_view:
		# calm Home pilot: rifle up when idle, aims at the bug he is shooting
		var rig_aim: float = (_aim - _soldier).angle() if _has_aim else -PI / 2.0 - 0.3
		_rig_view.update(dt, _soldier, rig_aim, clampf(_bank / 0.3, -1.0, 1.0), 1.0 + sin(_t * 0.6 + 1.0) * 0.15, cos(_t * 0.6) * 5.4)
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
	var kind := "scout"
	if heavy:
		kind = "drifter" if _roster.has("drifter") else "scout"
	else:
		var light := _roster.filter(func(k): return k != "drifter")
		if not light.is_empty():
			kind = light[randi() % light.size()]
	var sz: float = float(StageData.ENEMIES[kind].size) * 1.07
	return {"pos": pos, "speed": speed, "hp": 7 if heavy else 2, "heavy": heavy, "kind": kind,
		"r": sz * 0.19, "size": sz, "ph": randf() * TAU}

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
	var muzzle := _muzzle(pose)
	_fire -= dt
	if _fire <= 0.0 and _has_aim:
		_fire = 0.32
		var dist := muzzle.distance_to(_aim)
		var lead: Vector2 = _aim + Vector2(0, float(_enemies[idx].speed) * dist / 380.0)
		_bullets.append({"pos": muzzle, "vel": (lead - muzzle).normalized() * 380.0, "col": CYAN})
		_flash = 0.07
		if _rig_view:
			_rig_view.fire()
	if SHOW_TURRETS:
		for i in _wall_turrets.size():
			var base := _wall_turret_tip(i)
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
	var shift: float = _soldier.x / maxf(size.x, 1.0) - 0.5
	if _world != "":
		var bottom := _horizon_y() + STRIP_DROP
		if _world_fade < 1.0 and _world_prev != "":
			Backdrop.draw_world(self, size, bottom, _world_prev, _stars, _t, shift)
			Backdrop.draw_world(self, size, bottom, _world, _stars, _t, shift, smoothstep(0.0, 1.0, _world_fade))
		else:
			Backdrop.draw_world(self, size, bottom, _world, _stars, _t, shift)
	else:
		Backdrop.draw_sky(self, size, elite, _stars, _t, shift)
	for s in _streaks:
		draw_line(s.pos, s.pos - s.vel.normalized() * 34.0, Color(1, 1, 1, clampf(s.life, 0.0, 0.8)), 1.5, true)
	_draw_ship()
	_draw_rocks()
	_draw_boss()
	if _world == "":
		Backdrop.draw_horizon(self, size, _horizon_y(), elite, _city, _t)
	Backdrop.draw_strip(self, size.x, _horizon_y() + STRIP_DROP)
	Backdrop.draw_base_lights(self, size.x, _horizon_y() + STRIP_DROP, _t)
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

# The player's own turrets on the mounts they have opened (Turrets.mount_open), the
# same pictures the battle uses; closed mounts show a lock. Read from the save on Home.
const WALL_CX := {"lance": 0.481, "storm": 0.479, "gravity": 0.435, "swarm": 0.501, "prism": 0.441, "sentry": 0.5}

func _load_wall_turrets() -> void:
	_wall_turrets.clear()
	var d := {}
	if FileAccess.file_exists("user://skybound_save.json"):
		var f := FileAccess.open("user://skybound_save.json", FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				d = parsed
	_wall_unlocked = int(d.get("stage_unlocked", 1))
	PilotRig.set_gear(d)   # his weapon, visor and orb follow the gear (re-read when Home shows)
	if _rig_view:
		_rig_view.height = PILOT_H * float(Heroes.ROSTER[Heroes.selected(Heroes.read(d))].build.scale)   # his build (heroes)
	var loadout: Array = Turrets.read(d).loadout
	var plevel := Turrets.pilot_level(int(d.get("pilot_xp", 0)))
	for i in Turrets.MOUNTS:
		var id: String = loadout[i]
		if id != "" and Turrets.mount_open(i, _wall_unlocked) and plevel >= int(Turrets.TURRETS[id].unlock):
			_wall_turrets.append({"socket": i, "id": id, "tex": load("res://turrets/%s_idle.png" % Turrets.TURRETS[id].art), "cx": float(WALL_CX.get(id, 0.5))})

func _draw_turrets() -> void:
	var bottom := _horizon_y() + STRIP_DROP
	for i in Turrets.MOUNTS:
		if not Turrets.mount_open(i, _wall_unlocked):
			Backdrop.draw_socket_lock(self, i, size.x, bottom)
	for i in _wall_turrets.size():
		var w: Dictionary = _wall_turrets[i]
		if w.id == "sentry":
			_draw_wall_sentry(i, bottom)
			continue
		if WALL_SPLIT.has(w.id):
			_draw_wall_split(i, bottom)
			continue
		var tex: Texture2D = w.tex
		var s: float = _wall_turret_h() / tex.get_height()
		var sz := tex.get_size() * s
		var p := Backdrop.socket_pos(int(w.socket), size.x, bottom)
		draw_texture_rect(tex, Rect2(p + Vector2(-sz.x * float(w.cx), -sz.y + 6.0 * size.x / 480.0), sz), false)
		Backdrop.draw_socket_lip(self, int(w.socket), size.x, bottom)

# The Sentry as in battle: Luna's base ring centred on the socket, the gun head floating
# just above it and turning to its target (mirrored for targets on the right).
const SENTRY_BASE_W := 58.0
const SENTRY_HEAD_H := 66.0
const SENTRY_HEAD_CX := 0.498
const SENTRY_ART_DIR := -PI / 2.0 - 0.26
var _sentry_tex := {"base": preload("res://turrets/sentry_base.png"), "head": preload("res://turrets/sentry_head.png")}

func _sentry_pivot(i: int, bottom: float) -> Vector2:
	var k := size.x / 480.0
	var p := Backdrop.socket_pos(int(_wall_turrets[i].socket), size.x, bottom)
	var bt: Texture2D = _sentry_tex.base
	var base_h: float = bt.get_height() * (SENTRY_BASE_W * k / bt.get_width())
	return p + Vector2(sin(_t * 0.9 + i) * 1.5 * k, -base_h * 0.42 - 9.0 * k + sin(_t * 2.3 + i * 1.7) * 1.6 * k)

func _draw_wall_sentry(i: int, bottom: float) -> void:
	var k := size.x / 480.0
	var p := Backdrop.socket_pos(int(_wall_turrets[i].socket), size.x, bottom)
	Backdrop.draw_socket_shadow(self, int(_wall_turrets[i].socket), size.x, bottom)
	var bt: Texture2D = _sentry_tex.base
	var bs := bt.get_size() * (SENTRY_BASE_W * k / bt.get_width())
	draw_texture_rect(bt, Rect2(p - bs * 0.5, bs), false)
	Backdrop.draw_socket_lip(self, int(_wall_turrets[i].socket), size.x, bottom)   # seated in the ring (dev149)
	var ang: float = _turret_ang[i]
	var face := -1.0 if cos(ang) > 0.1 else 1.0
	var art_dir: float = SENTRY_ART_DIR if face > 0.0 else PI - SENTRY_ART_DIR
	var rot: float = clampf(angle_difference(art_dir, ang), -1.1, 1.1)
	var ht: Texture2D = _sentry_tex.head
	var hsz := ht.get_size() * (SENTRY_HEAD_H * k / ht.get_height())
	draw_set_transform(_sentry_pivot(i, bottom), rot, Vector2(face, 1.0))
	draw_texture_rect(ht, Rect2(Vector2(-hsz.x * SENTRY_HEAD_CX, -hsz.y * 0.9), hsz), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# Luna's two-piece turrets (same sizes as battle.gd SPLIT_LOOK): the base on the socket,
# the head floating above it; the Lance cannon turns to its target.
const WALL_SPLIT := {
	"lance":   {"base_w": 60.0, "head_h": 34.0, "gap": 2.0, "art_dir": 2.68},
	"storm":   {"base_w": 58.0, "head_h": 50.0, "gap": 10.0, "art_dir": 0.0},
	"gravity": {"base_w": 60.0, "head_h": 36.0, "gap": 8.0, "art_dir": 0.0},
	"prism":   {"base_w": 0.0, "head_h": 78.0, "gap": 0.0, "art_dir": 0.0},
}
var _split_tex := {}

func _split_head_centre(i: int, bottom: float) -> Vector2:
	var id: String = _wall_turrets[i].id
	var look: Dictionary = WALL_SPLIT[id]
	var k := size.x / 480.0
	var p := Backdrop.socket_pos(int(_wall_turrets[i].socket), size.x, bottom)
	if id == "prism":
		return p + Vector2(0, (6.0 - float(look.head_h) * 0.5) * k)
	var bt: Texture2D = _split_tex[id + "_base"]
	var base_h: float = bt.get_height() * float(look.base_w) * k / bt.get_width()
	return p + Vector2(0, -base_h * 0.55 - (float(look.gap) + float(look.head_h) * 0.5) * k + sin(_t * 2.0 + i * 1.3) * 2.0 * k)

func _draw_wall_split(i: int, bottom: float) -> void:
	var id: String = _wall_turrets[i].id
	var look: Dictionary = WALL_SPLIT[id]
	var k := size.x / 480.0
	for n in [id + "_base", id + "_head"]:
		if not _split_tex.has(n) and ResourceLoader.exists("res://turrets/%s.png" % n):
			_split_tex[n] = load("res://turrets/%s.png" % n)
	Backdrop.draw_socket_shadow(self, int(_wall_turrets[i].socket), size.x, bottom)
	var p := Backdrop.socket_pos(int(_wall_turrets[i].socket), size.x, bottom)
	if float(look.base_w) > 0.0:
		var bt: Texture2D = _split_tex[id + "_base"]
		var bs := bt.get_size() * (float(look.base_w) * k / bt.get_width())
		draw_texture_rect(bt, Rect2(p + Vector2(-bs.x * 0.5, -bs.y * 0.55), bs), false)
		Backdrop.draw_socket_lip(self, int(_wall_turrets[i].socket), size.x, bottom)
	var ht: Texture2D = _split_tex[id + "_head"]
	var hh: float = float(look.head_h) * k
	var hw: float = ht.get_width() * hh / ht.get_height()
	var rot := 0.0
	var sx := 1.0
	if id == "lance":
		var ang: float = clampf(_turret_ang[i], -PI + 0.15, -0.15)
		sx = -1.0 if cos(ang) > 0.05 else 1.0
		rot = angle_difference(float(look.art_dir) if sx > 0.0 else PI - float(look.art_dir), ang)
	draw_set_transform(_split_head_centre(i, bottom), rot, Vector2(sx, 1.0))
	draw_texture_rect(ht, Rect2(-hw * 0.5, -hh * 0.5, hw, hh), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _wall_turret_tip(i: int) -> Vector2:
	if WALL_SPLIT.has(_wall_turrets[i].id):
		return _split_head_centre(i, _horizon_y() + STRIP_DROP)
	if _wall_turrets[i].id == "sentry":
		return _sentry_pivot(i, _horizon_y() + STRIP_DROP) + Vector2(0, -SENTRY_HEAD_H * 0.6 * size.x / 480.0)
	var p := Backdrop.socket_pos(int(_wall_turrets[i].socket), size.x, _horizon_y() + STRIP_DROP)
	return p + Vector2(0, 6.0 * size.x / 480.0 - _wall_turret_h() * 0.9)

# turrets keep their size relative to the base strip, whatever the screen width
func _wall_turret_h() -> float:
	return WALL_TURRET_H * size.x / 480.0

# On a boss stage the Hive Mother hangs high in the sky, out of reach, drifting slowly.
func _draw_boss() -> void:
	if _boss == "":
		return
	var sz: float = float(StageData.ENEMIES["hive_mother"].size) * 1.35 * (0.4 if _boss == "mini" else 0.5)
	var p := Vector2(size.x * 0.5 + sin(_t * 0.35) * size.x * 0.18, fly_top + 40.0 + sin(_t * 0.9) * 8.0)
	EnemyRig.draw_hive_mother(self, p, sz, _t, 0.0, false)

func _draw_enemies() -> void:
	for e in _enemies:
		var a := clampf((e.pos.y - (fly_top - 100.0)) / 60.0, 0.0, 1.0)   # fades in as it enters
		EnemyRig.draw_bug(self, String(e.kind), e.pos, float(e.size), _t, float(e.ph), sin(_t * 1.3 + e.ph) * 0.12, 0.0, 1.0, a)

func _muzzle(pose: String) -> Vector2:
	if _rig_view:
		return _rig_view.muzzle()
	return _soldier + PilotSprite.muzzle(pose, PILOT_H, _flip(pose)).rotated(_bank)

func _pose() -> String:
	return _anim.pose()

func _flip(_pose: String) -> bool:
	if _anim.pose().begins_with("aim"):
		return _facing_s < 0.0
	return _anim.mirrored()

func _draw_soldier() -> void:
	var pose := _pose()
	if _has_aim:
		draw_line(_muzzle(pose), _aim, Color(CYAN, 0.08), 1.0, true)
	var turn: float = clampf(absf(_facing_s), 0.15, 1.0) if pose.begins_with("aim") else 1.0
	if not _rig_view:
		PilotSprite.draw(self, _soldier, PILOT_H, pose, _flip(pose), _bank, _t, 1.0, clampf(_soldier_vx * 0.02, -1.0, 1.0),
			smoothstep(0.0, 0.07, _flash), _anim.mix(), turn)
