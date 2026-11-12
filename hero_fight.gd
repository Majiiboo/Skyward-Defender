class_name HeroFight
extends RefCounted
# THE HERO IN THE FIGHT, IN PIECES (2026-11-12, Rudy: "the penguin looks like a static image").
# A hero seen from straight above, built from Luna's rigid pieces (heroes/<id>/fight/, cut by
# tools/cut_frost_fight.gd, all at HALF the size they have on her 1024 "whole" picture) and moved
# here: he leans into a drag and settles, the weapon kicks back with weight, the flipper works, the
# legs drag behind him, the head looks at the nearest bug, he flinches when hit, the jets stretch.
# PilotRigView draws this in place of the turn frames when `fight` is set on it (battle, Home
# wallpaper) and the hero has a set here. The menus keep the full-body art.
#
# All places below are in pixels of Luna's whole picture, measured from ORIGIN (his neck).

static var on := true                      # Settings > Fight > "New hero motion" (save "hero_new")

const ORIGIN := Vector2(540, 560)
const BODY_LEN := 605.0                    # helmet top to boot soles on the whole picture
const SIZE := 0.95                         # that length as a share of the view's height

# piece: "at" = where its pivot sits (whole picture px), "pv" = the pivot inside the piece (0..1)
const SETS := {
	"frost": {
		"body":    {"at": Vector2(537, 440), "pv": Vector2(0.5, 0.0)},
		"helmet":  {"at": Vector2(537, 438), "pv": Vector2(0.5, 0.5)},
		"flipper": {"at": Vector2(425, 603), "pv": Vector2(0.9, 0.5)},
		"arm":     {"at": Vector2(655, 592), "pv": Vector2(0.5, 0.86), "rot": 0.49, "hand": 0.76},
		"leg_l":   {"at": Vector2(479, 680), "pv": Vector2(0.5, 0.12)},
		"leg_r":   {"at": Vector2(601, 680), "pv": Vector2(0.5, 0.12)},
		"jets":    [Vector2(505, 748), Vector2(564, 748)],
		"rifle_len": 440.0,
		"flap": 1.0,                       # how hard the flipper works (each hero flies his own way)
	},
}

static var _tex := {}

static func apply_from(save: Dictionary) -> void:
	on = bool(save.get("hero_new", true))

static func has(id: String) -> bool:
	return SETS.has(id) and ResourceLoader.exists("res://heroes/%s/fight/body.png" % id)

static func ready() -> bool:
	return on and has(PilotRig.hero)

static func tex(id: String, piece: String) -> Texture2D:
	var key := id + "/" + piece
	if not _tex.has(key):
		_tex[key] = load("res://heroes/%s/fight/%s.png" % [id, piece])
	return _tex[key]

# load every picture before the first draw (a texture first loaded inside _draw shows white)
static func warm(id: String) -> void:
	if has(id):
		for p in ["body", "helmet", "flipper", "arm", "leg_l", "leg_r", "flame"]:
			tex(id, p)

class State:
	var t := 0.0
	var prev := Vector2.INF
	var vel := Vector2.ZERO        # smoothed, screen px a second
	var lean := 0.0                # -1..1, on a spring: tips into the drag, overshoots, settles
	var lean_v := 0.0
	var leg := [0.0, 0.0]          # each leg swings behind the sideways motion on its own spring
	var leg_v := [0.0, 0.0]
	var trail := 0.0               # + = flying forward (legs stretch out behind), - = backing up (legs tuck and splay)
	var trail_v := 0.0
	var flap := 0.0                # flipper stroke phase
	var speed := 0.0               # 0..1
	var head := 0.0                # head turn toward the nearest bug
	var head_v := 0.0
	var kick := 0.0                # the weapon's recoil, whole-picture px
	var kick_v := 0.0
	var nod := 0.0                 # the head follows a kick a beat late
	var nod_v := 0.0
	var aim := 0.0                 # the weapon's angle off straight up
	var flinch := 0.0              # 1 on a hit, runs out in a third of a second
	var flinch_dir := 1.0
	var cast := 0.0                # 1 when the ability fires
	var look := Vector2.INF        # a point to look at (the nearest bug), or INF

	func update(delta: float, at: Vector2, aim_angle: float) -> void:
		var dt := minf(delta, 0.05)
		t += delta
		if prev == Vector2.INF or dt <= 0.0:
			prev = at
		var raw := (at - prev) / maxf(dt, 0.001)
		prev = at
		if raw.length() > 2400.0:     # a jump (stage start, the fly-off): not motion
			raw = Vector2.ZERO
		vel = vel.lerp(raw, 1.0 - exp(-dt * 14.0))
		var nx := clampf(vel.x / 260.0, -1.0, 1.0)
		var ny := clampf(vel.y / 240.0, -1.0, 1.0)
		speed = lerpf(speed, clampf(vel.length() / 300.0, 0.0, 1.0), 1.0 - exp(-dt * 8.0))
		lean_v += ((nx - lean) * 110.0 - lean_v * 9.0) * dt
		lean = clampf(lean + lean_v * dt, -1.4, 1.4)
		# the legs: looser than the body, and not quite alike, so they trail and overshoot
		for i in 2:
			var stiff := 42.0 if i == 0 else 52.0
			leg_v[i] += ((nx * 0.62 - leg[i]) * stiff - leg_v[i] * 5.2) * dt
			leg[i] = clampf(leg[i] + leg_v[i] * dt, -1.1, 1.1)
		trail_v += ((-ny - trail) * 60.0 - trail_v * 7.0) * dt
		trail = clampf(trail + trail_v * dt, -1.2, 1.2)
		flap += dt * (3.2 + 9.0 * speed)
		aim = lerp_angle(aim, clampf(wrapf(aim_angle + PI / 2.0, -PI, PI), -1.3, 1.3), 1.0 - exp(-dt * 16.0))
		var want := aim * 0.5
		if look != Vector2.INF:
			var d := look - at
			if d.y < -20.0:
				want = clampf(atan2(d.x, -d.y), -0.55, 0.55)
		head_v += ((want - head) * 70.0 - head_v * 11.0) * dt
		head += head_v * dt
		kick_v += (-kick * 620.0 - kick_v * 30.0) * dt
		kick = clampf(kick + kick_v * dt, -30.0, 130.0)
		nod_v += ((kick * 0.3 - nod) * 300.0 - nod_v * 16.0) * dt
		nod += nod_v * dt
		flinch = maxf(flinch - delta * 3.0, 0.0)
		cast = maxf(cast - delta * 1.3, 0.0)

	# power 1 = a normal shot; a heavy weapon or a charged shot passes more
	func fire(power: float = 1.0) -> void:
		kick_v += 1500.0 * clampf(power, 0.3, 3.0)

	func hit() -> void:
		flinch = 1.0
		flinch_dir = -flinch_dir

	func do_cast() -> void:
		cast = 1.0

# ------------------------------------------------------------------ the pose

static func _k(height: float) -> float:
	return height * SIZE / BODY_LEN

# the whole figure: where he is, his lean, the jolt of a hit, the pop of the ability
static func _root(s: State, pos: Vector2, height: float) -> Transform2D:
	var k := _k(height)
	var jolt := sin(s.flinch * PI) * 0.22 * s.flinch_dir
	var pop := 1.0 + 0.1 * sin(clampf(s.cast, 0.0, 1.0) * PI) - 0.08 * sin(s.flinch * PI)
	var squash := Vector2(1.0 - 0.05 * absf(s.lean), 1.0) * pop
	var back := Vector2(0, s.kick * 0.28 * k)
	return Transform2D(s.lean * 0.15 + jolt, squash * k, 0.0, pos + back)

static func _local(at: Vector2, rot: float, scl: Vector2 = Vector2.ONE) -> Transform2D:
	return Transform2D(rot, scl, 0.0, at - ORIGIN)

static func _put(c: CanvasItem, m: Transform2D, tx: Texture2D, pv: Vector2, col: Color) -> void:
	var size := Vector2(tx.get_size()) * 2.0     # the pieces are saved at half the whole picture
	c.draw_set_transform_matrix(m)
	c.draw_texture_rect(tx, Rect2(-pv * size, size), false, col)

static func _arm_rot(s: State, kit: Dictionary) -> float:
	return float(kit.arm.rot) + s.aim * 0.45 - 0.5 * sin(clampf(s.cast, 0.0, 1.0) * PI)

# the weapon in his mitten: [transform inside the figure, texture, grip (0..1), muzzle (0..1), drawn size]
static func _rifle(s: State, kit: Dictionary) -> Array:
	var tx: Texture2D
	var grip := Vector2(0.62, 0.6)
	var muz := Vector2(0.42, 0.0)
	if PilotRig.held != "" and PilotRig._tex.has("held"):
		tx = PilotRig._tex["held"]
		grip = PilotRig.PARTS["held"].pv
		muz = PilotRig.PARTS["held"].muzzle
	else:
		var key := PilotRig.hero + "/weapon"
		if not _tex.has(key):
			_tex[key] = load("res://heroes/%s/weapon.png" % PilotRig.hero)
		tx = _tex[key]
	var sc := float(kit.rifle_len) / tx.get_height()
	var size := Vector2(tx.get_size()) * sc
	var arm: Dictionary = kit.arm
	var arm_len := float(arm.hand) * tex(PilotRig.hero, "arm").get_height() * 2.0
	var hand: Vector2 = arm.at + Vector2(0, -arm_len).rotated(_arm_rot(s, kit)) + Vector2(0, s.kick * 0.45)
	var rot := s.aim * 0.7
	var at := hand + Vector2(0, s.kick * 0.55).rotated(rot)
	return [_local(at, rot), tx, grip, muz, size]

static func draw(c: CanvasItem, s: State, pos: Vector2, height: float, alpha: float = 1.0, lift: Color = PilotRig.LIFT) -> void:
	var id := PilotRig.hero
	var kit: Dictionary = SETS[id]
	var root := _root(s, pos, height)
	var flash := 1.0 + 1.1 * s.flinch
	var col := Color(lift.r * flash, lift.g * flash, lift.b * flash, lift.a * alpha)
	var tuck := maxf(-s.trail, 0.0)             # backing up
	var reach := maxf(s.trail, 0.0)             # flying forward
	var casting := sin(clampf(s.cast, 0.0, 1.0) * PI)
	# the legs, under everything: they swing behind a sideways move, stretch out behind a climb,
	# tuck and splay when he backs up; a slow paddle when he hangs still
	for i in 2:
		var p: Dictionary = kit["leg_l" if i == 0 else "leg_r"]
		var side := -1.0 if i == 0 else 1.0
		var paddle := sin(s.t * 2.6 + i * PI) * 0.07 * (1.0 - s.speed)
		var rot: float = s.leg[i] + paddle - side * (0.34 * tuck + 0.3 * casting) + side * 0.05 * reach
		var ln := 1.0 + 0.16 * reach - 0.2 * tuck
		_put(c, root * _local(p.at + Vector2(0, 14.0 * reach - 6.0 * tuck), rot, Vector2(1.0, ln)), tex(id, "leg_l" if i == 0 else "leg_r"), p.pv, col)
	# the flipper: it strokes as he flies (faster with speed), sweeps back in a climb or when he
	# moves toward its own side, and flings forward on the ability
	var fl: Dictionary = kit.flipper
	var amt := float(kit.flap)
	var stroke := sin(s.flap)
	var f_rot := amt * (0.1 + 0.2 * s.speed) * stroke - 0.45 * reach - 0.4 * maxf(-s.lean, 0.0) + 0.2 * tuck + 0.85 * casting
	var f_len := 1.0 - 0.14 * amt * (0.5 + 0.5 * cos(s.flap)) * (0.4 + 0.6 * s.speed)
	_put(c, root * _local(fl.at, f_rot, Vector2(f_len, 1.0)), tex(id, "flipper"), fl.pv, col)
	# the weapon, then the arm over its grip
	var rf := _rifle(s, kit)
	var rsize: Vector2 = rf[4]
	c.draw_set_transform_matrix(root * (rf[0] as Transform2D))
	c.draw_texture_rect(rf[1], Rect2(-(rf[2] as Vector2) * rsize, rsize), false, col)
	var arm: Dictionary = kit.arm
	_put(c, root * _local(arm.at + Vector2(0, s.kick * 0.45), _arm_rot(s, kit)), tex(id, "arm"), arm.pv, col)
	# the body with his pack, then the helmet: the head turns to the nearest bug, leads into a
	# lean, and nods back a beat after each shot
	_put(c, root * _local(kit.body.at, 0.0), tex(id, "body"), kit.body.pv, col)
	var hm: Dictionary = kit.helmet
	var h_at: Vector2 = hm.at + Vector2(s.lean * 9.0 + s.head * 10.0, s.nod - 8.0 * casting - 10.0 * sin(s.flinch * PI))
	_put(c, root * _local(h_at, s.head * 0.8 - s.lean * 0.1 + s.flinch * 0.2 * s.flinch_dir), tex(id, "helmet"), hm.pv, col)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# the two jets, drawn as light over him: longer when he climbs, short when he backs up, flickering,
# and trailing a little behind a sideways move
static func draw_flames(c: CanvasItem, s: State, pos: Vector2, height: float, alpha: float = 1.0) -> void:
	var id := PilotRig.hero
	var kit: Dictionary = SETS[id]
	var root := _root(s, pos, height)
	var tx := tex(id, "flame")
	for i in (kit.jets as Array).size():
		var flick := 0.86 + 0.14 * sin(s.t * 31.0 + i * 2.1) + 0.06 * sin(s.t * 53.0 + i)
		var ln := (0.5 + 0.55 * maxf(s.trail, 0.0) - 0.25 * maxf(-s.trail, 0.0) + 0.25 * s.speed + 0.5 * sin(clampf(s.cast, 0.0, 1.0) * PI)) * flick
		var size := Vector2(tx.get_width() * 1.5, tx.get_height() * 2.0 * ln)
		c.draw_set_transform_matrix(root * _local(kit.jets[i], s.leg[i] * 0.5))
		c.draw_texture_rect(tx, Rect2(-size.x * 0.5, -size.y * 0.04, size.x, size.y), false, Color(1, 1, 1, alpha * (0.75 + 0.25 * flick)))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# where his bolts start: the tip of the weapon, wherever the pose has put it
static func muzzle(s: State, pos: Vector2, height: float) -> Vector2:
	var kit: Dictionary = SETS[PilotRig.hero]
	var rf := _rifle(s, kit)
	var rsize: Vector2 = rf[4]
	return _root(s, pos, height) * ((rf[0] as Transform2D) * (((rf[3] as Vector2) - (rf[2] as Vector2)) * rsize))
