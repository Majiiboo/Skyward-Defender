class_name PilotRig
extends RefCounted
# The pilot as a cut-out rig: Luna's painted parts (pilot_rig/, cut by
# tools/cut_pilot_art.gd) put back together on her assembled reference and moved
# in code, so breathing, aiming, leaning and recoil are smooth at any speed and
# his look never changes between frames. TEST ONLY for now (rig_test.tscn): the
# battle still uses PilotSprite until Rudy decides.
#
# All positions are in REFERENCE pixels (art_src/pilot/reference.webp, 1600 px).
# Each part: tex, s = scale from texture to reference pixels, pv = its pivot inside
# the texture (0..1), at = where that pivot sits on the reference (rest pose).
# Arms are placed by aim (two-bone IK), so their `at` is only the shoulder/elbow.

const BASE_PARTS := {
	"jetpack":   {"s": 1.40, "pv": Vector2(0.5, 0.30), "at": Vector2(804, 850)},
	"thigh_r":   {"s": 0.80, "pv": Vector2(0.5, 0.14), "at": Vector2(690, 1150)},
	"thigh_l":   {"s": 0.80, "pv": Vector2(0.5, 0.12), "at": Vector2(910, 1150)},
	"shin":      {"s": 0.80, "pv": Vector2(0.5, 0.10), "at": Vector2(690, 1310)},
	"hips":      {"s": 0.95, "pv": Vector2(0.5, 0.10), "at": Vector2(800, 1030)},
	"torso":     {"s": 1.26, "pv": Vector2(0.5, 0.92), "at": Vector2(800, 1060)},
	"orb":       {"s": 0.80, "pv": Vector2(0.5, 0.50), "at": Vector2(800, 876)},
	"helmet":    {"s": 1.78, "pv": Vector2(0.5, 0.95), "at": Vector2(804, 774)},
	"visor":     {"s": 1.30, "pv": Vector2(0.5, 0.37), "at": Vector2(804, 535)},
	"upper_r":   {"s": 0.75, "pv": Vector2(0.5, 0.10), "at": Vector2(655, 815), "end": Vector2(0.5, 0.88)},
	"forearm_r": {"s": 0.75, "pv": Vector2(0.5, 0.09), "end": Vector2(0.5, 0.86)},
	"upper_l":   {"s": 0.75, "pv": Vector2(0.5, 0.10), "at": Vector2(945, 815), "end": Vector2(0.5, 0.88)},
	"forearm_l": {"s": 0.64, "pv": Vector2(0.66, 0.04), "end": Vector2(0.36, 0.80)},
	"pad_r":     {"s": 0.75, "pv": Vector2(0.5, 0.45)},
	"pad_l":     {"s": 0.75, "pv": Vector2(0.5, 0.45)},
	"rifle":     {"s": 1.30, "pv": Vector2(0.5, 0.72), "muzzle": Vector2(0.5, 0.0)},
	"rifle_side": {"s": 1.05, "pv": Vector2(0.25, 0.67), "muzzle": Vector2(0.69, 0.0)},
}
# Chunky limbs (Rudy, dev117: he looked too thin): Luna's round-3 side-view arms and legs
# (pilot_rig/r3_*.png, tools/cut_batch_d.gd) replace the long thin ones. "tex" = picture,
# pv / end = the joints in the picture, "knee" on thighs. The separate shoulder pads go
# (the new upper arms carry their own). false = the round-1 limbs again.
const CHUNKY := true
const CHUNKY_PARTS := {
	"upper_r":   {"tex": "r3_upper", "s": 0.95, "pv": Vector2(0.52, 0.16), "end": Vector2(0.62, 0.9)},
	"upper_l":   {"tex": "r3_upper", "s": 0.9, "pv": Vector2(0.52, 0.16), "end": Vector2(0.62, 0.9)},
	"forearm_r": {"tex": "r3_forearm_fist", "s": 0.8, "pv": Vector2(0.92, 0.33), "end": Vector2(0.12, 0.62)},
	"forearm_l": {"tex": "r3_forearm_open", "s": 0.66, "pv": Vector2(0.05, 0.3), "end": Vector2(0.9, 0.5)},
	"thigh_r":   {"tex": "r3_thigh", "s": 0.82, "pv": Vector2(0.42, 0.08), "knee": Vector2(0.58, 0.93)},
	"thigh_l":   {"tex": "r3_thigh", "s": 0.82, "pv": Vector2(0.42, 0.08), "knee": Vector2(0.58, 0.93)},
	"shin":      {"tex": "r3_shin", "s": 0.6, "pv": Vector2(0.33, 0.05)},
}
static var PARTS := _parts()
static func _parts() -> Dictionary:
	var p := BASE_PARTS.duplicate(true)
	if CHUNKY and ResourceLoader.exists("res://pilot_rig/r3_upper.png"):
		for k in CHUNKY_PARTS:
			p[k].merge(CHUNKY_PARTS[k], true)
	return p

# Which rifle picture he holds: "rifle_side" (Luna's side view, reads well when he aims
# sideways) or "rifle" (the parts sheet's, seen edge-on).
const RIFLE := "rifle_side"
# false = battle and Home go back to the painted PilotSprite.
const ENABLED := true
# Contrast on the dark sky (code only, Luna's art untouched): parts drawn a little
# brighter, a thin cool rim around his outline, a soft light behind him, and a touch
# bigger than the painted pilot's PILOT_HEIGHT.
const LIFT := Color(1.3, 1.3, 1.36)
const RIM := Color(0.42, 0.78, 1.0, 0.6)
const BACKLIGHT := Color(0.22, 0.5, 1.0, 0.13)
const SIZE := 1.12
const KNEE := Vector2(0.5, 0.86)          # knee ball on both thigh pictures
const NOZZLES := [Vector2(0.145, 0.96), Vector2(0.855, 0.96)]   # on the jetpack picture
const ORIGIN := Vector2(800, 820)         # reference point drawn at `pos`
const BODY_H := 1270.0                    # helmet top to soles, reference px (= `height`)

static var _tex := {}

static func tex(name: String) -> Texture2D:
	if not _tex.has(name):
		var file: String = String(PARTS[name].get("tex", name)) if PARTS.has(name) else name
		_tex[name] = load("res://pilot_rig/%s.png" % file)
	return _tex[name]

static func size_of(name: String) -> Vector2:
	return tex(name).get_size() * float(PARTS[name].s)

# a part's own point (0..1 in its picture) in rest-pose reference pixels, given where its pivot is
static func local(name: String, p: Vector2) -> Vector2:
	return (p - PARTS[name].pv) * size_of(name)

class Rig:
	# Smoothed state. update() every frame with what the pilot is doing; fire() on a shot.
	var t := 0.0
	var aim := -PI / 2.0       # rifle angle (0 = right, -PI/2 = up), smoothed
	var face := 1.0            # +1 rifle on the left of the screen, -1 mirrored; passes through 0 when turning
	var face_target := 1.0
	var lean := 0.0            # + = top leans right
	var hover := 1.0           # thruster power 0.35 .. 1.9
	var vy := 0.0              # vertical speed, px/s, + = falling
	var recoil := 0.0          # 1 on a shot, decays
	var leg_swing := 0.0       # legs trail the lean (spring)
	var leg_vel := 0.0
	var spread := 0.08         # legs apart (dropping) or together (climbing)
	var jet_lag := 0.0         # jetpack bob that lags the body
	var jet_vel := 0.0
	func update(delta: float, aim_angle: float, lean_in: float, hover_in: float, vy_in: float) -> void:
		t += delta
		var dx := cos(aim_angle)
		if dx > 0.25:
			face_target = -1.0
		elif dx < -0.25:
			face_target = 1.0
		# turning takes about half a second, passing through the front view (draw_front)
		face = move_toward(face, face_target, delta * (4.0 if PilotRig.front_ready() else 12.0))
		aim = lerp_angle(aim, aim_angle, 1.0 - exp(-delta * 16.0))
		lean = lerpf(lean, lean_in, 1.0 - exp(-delta * 8.0))
		hover = lerpf(hover, hover_in, 1.0 - exp(-delta * 6.0))
		vy = lerpf(vy, vy_in, 1.0 - exp(-delta * 5.0))
		recoil = maxf(recoil - delta * 7.0, 0.0)
		# springs: legs swing behind the lean, jetpack settles after climbs and drops
		var leg_goal := -lean * 0.55
		leg_vel += ((leg_goal - leg_swing) * 60.0 - leg_vel * 7.0) * delta
		leg_swing += leg_vel * delta
		spread = lerpf(spread, clampf(0.08 + vy / 900.0, 0.0, 0.35), 1.0 - exp(-delta * 4.0))
		var jet_goal := clampf(-vy * 0.03, -14.0, 14.0)
		jet_vel += ((jet_goal - jet_lag) * 90.0 - jet_vel * 9.0) * delta
		jet_lag += jet_vel * delta
	func fire() -> void:
		recoil = 1.0
	# the aim as seen in the unmirrored rig (rifle on the left of the screen)
	func local_aim() -> float:
		return aim if face >= 0.0 else wrapf(PI - aim, -PI, PI)   # kept in -PI..PI so arm and head maths never jump a full turn

# Two-bone IK: from root toward target with bone lengths a, b. bend = +1/-1 picks the
# elbow side. Returns [elbow, hand].
static func _ik(root: Vector2, target: Vector2, a: float, b: float, bend: float) -> Array:
	var d := target - root
	var L := clampf(d.length(), absf(a - b) + 1.0, a + b - 0.5)
	var dir := d.normalized() if d.length() > 0.01 else Vector2.DOWN
	var cos_a := clampf((a * a + L * L - b * b) / (2.0 * a * L), -1.0, 1.0)
	var elbow := root + dir.rotated(acos(cos_a) * bend) * a
	return [elbow, root + dir * L]

# Solves the pose: every part's transform (rest reference px -> posed reference px)
# plus the points the light layer needs. Same result for draw() and draw_light().
static func solve(r: Rig) -> Dictionary:
	var X := {}
	var t := r.t
	var breath := sin(t * TAU / 2.6)
	var kick := r.recoil * r.recoil
	var aim := r.local_aim()
	var aim_dir := Vector2(cos(aim), sin(aim))
	var lean := r.lean * (1.0 if r.face >= 0.0 else -1.0)
	# hips are the root; the body leans from there
	var hip_at: Vector2 = PARTS.hips.at
	var body_rot := lean * 0.30
	X.hips = _place("hips", hip_at, body_rot)
	var torso_rot := body_rot + lean * 0.10 + breath * 0.008 - aim_dir.x * kick * 0.04
	var torso_at: Vector2 = X.hips * _rel("torso", "hips") - aim_dir * kick * 10.0
	X.torso = _place("torso", torso_at, torso_rot, Vector2(1.0, 1.0 + breath * 0.012))
	X.orb = _child(X.torso, "torso", "orb")
	var helmet_at: Vector2 = X.torso * _rel("helmet", "torso") + Vector2(0, sin(t * TAU / 2.6 - 0.6) * 5.0)
	# the head turns a little toward the target (tilts as he looks up-left / up-right) and
	# drifts slowly side to side
	var look := clampf((aim + PI / 2.0) * 0.3, -0.26, 0.26)
	var head_rot := torso_rot * 0.6 + look + sin(t * 0.9) * 0.03
	X.helmet = _place("helmet", helmet_at, head_rot)
	X.visor = _child(X.helmet, "helmet", "visor")
	# jetpack rides on the torso, bobbing a little behind it
	X.jetpack = _place("jetpack", X.torso * _rel("jetpack", "torso") + Vector2(0, r.jet_lag + sin(t * 2.7 + 0.8) * 3.0), torso_rot)
	# legs dangle from the hips: trail the lean, spread when dropping, sway a little
	var sway := sin(t * 2.1) * 0.035
	for side in [["thigh_r", -1.0], ["thigh_l", 1.0]]:
		var nm: String = side[0]
		var sg: float = side[1]
		var th_rot: float = body_rot + r.leg_swing + sg * r.spread + sway
		X[nm] = _place(nm, X.hips * _rel(nm, "hips"), th_rot)
		var knee: Vector2 = X[nm] * local(nm, PARTS[nm].get("knee", KNEE))
		var sh_rot: float = th_rot + r.leg_swing * 0.6 - sg * r.spread * 0.5 + sin(t * 2.1 - 0.7) * 0.05
		X["shin_" + nm.substr(6)] = _place("shin", knee, sh_rot)
	# rifle arm: the grip sits out to the side of the body and swings round with the aim
	var sh_r: Vector2 = X.torso * _rel("upper_r", "torso")
	var grip: Vector2 = sh_r + Vector2(-225, 40).rotated(body_rot) + aim_dir * 150.0 - aim_dir * kick * 34.0
	var rifle_rot := aim + PI / 2.0 + kick * 0.14 * maxf(-cos(aim), 0.0)
	X.rifle = _place("rifle", grip, rifle_rot)
	var a_r: float = ((PARTS.upper_r.end - PARTS.upper_r.pv) * tex("upper_r").get_size() * float(PARTS.upper_r.s)).length()
	var b_r: float = ((PARTS.forearm_r.end - PARTS.forearm_r.pv) * tex("forearm_r").get_size() * float(PARTS.forearm_r.s)).length()
	var arm_r := _ik(sh_r, grip, a_r, b_r, -1.0)
	X.upper_r = _bone("upper_r", sh_r, arm_r[0])
	X.forearm_r = _bone("forearm_r", arm_r[0], grip)
	X.pad_r = _place("pad_r", sh_r + Vector2(-12, -4).rotated(torso_rot), torso_rot + _ang(arm_r[0] - sh_r) * 0.25 - 0.1)
	# free arm: out to the side for balance, swinging toward the aim and with the lean
	var sh_l: Vector2 = X.torso * _rel("upper_l", "torso")
	var a_l: float = ((PARTS.upper_l.end - PARTS.upper_l.pv) * tex("upper_l").get_size() * float(PARTS.upper_l.s)).length()
	var fl: Vector2 = PARTS.forearm_l.end - PARTS.forearm_l.pv
	var b_l := (fl * tex("forearm_l").get_size() * float(PARTS.forearm_l.s)).length()
	var swing := clampf((aim + PI / 2.0) * 0.18, -0.2, 0.2)
	var free_ang := PI / 2.0 - 0.38 + breath * 0.04 - lean * 0.3 + swing + kick * 0.08
	# hand a little short of full reach, so the elbow bends and the arm stays close to him
	var hand_l: Vector2 = sh_l + Vector2(cos(free_ang), sin(free_ang)) * (a_l + b_l) * 0.78
	var arm_l := _ik(sh_l, hand_l, a_l, b_l, 1.0)
	X.upper_l = _bone("upper_l", sh_l, arm_l[0])
	X.forearm_l = _bone("forearm_l", arm_l[0], arm_l[1])
	X.pad_l = _place("pad_l", sh_l + Vector2(12, -4).rotated(torso_rot), torso_rot + _ang(arm_l[0] - sh_l) * 0.25 + 0.1)
	var m: Vector2 = PARTS[RIFLE].muzzle
	X.muzzle = X.rifle * local(RIFLE, m)
	X.aim_dir = aim_dir
	return X

static func _ang(v: Vector2) -> float:
	# angle away from hanging straight down
	return v.angle() - PI / 2.0

# Transform that moves a part's rest pivot to `at`, rotated by `rot` (scale optional).
static func _place(_name: String, at: Vector2, rot: float, sc: Vector2 = Vector2.ONE) -> Transform2D:
	return Transform2D(rot, sc, 0.0, at)

static func _child(parent: Transform2D, pname: String, name: String) -> Transform2D:
	return Transform2D(parent.get_rotation(), parent * _rel(name, pname))

# where a part's pivot sits relative to its parent's pivot, in the rest pose
static func _rel(name: String, pname: String) -> Vector2:
	return PARTS[name].at - PARTS[pname].at

# A limb bone from joint a toward joint b (the picture hangs down, so +y points at b).
static func _bone(name: String, a: Vector2, b: Vector2) -> Transform2D:
	var p: Dictionary = PARTS[name]
	var axis: Vector2 = (p.end - p.pv) * tex(name).get_size()
	var rest_ang := axis.angle()
	return Transform2D((b - a).angle() - rest_ang, a)

# Transforms here map the part's PIVOT frame (pivot at 0,0, rest orientation) to posed
# reference px. Draw a part: its picture with the pivot at the origin.
static func _draw_part(c: CanvasItem, base: Transform2D, xf: Transform2D, name: String, col: Color, flip_x: bool = false) -> void:
	var tx := tex(name)
	var sz := size_of(name)
	var pv: Vector2 = PARTS[name].pv
	var m := base * xf
	if flip_x:
		m = m * Transform2D(0.0, Vector2(-1, 1), 0.0, Vector2.ZERO)
	c.draw_set_transform_matrix(m)
	c.draw_texture_rect(tx, Rect2(-pv * sz, sz), false, col)

# reference px -> screen, with the mirror/turn squeeze and the overall tilt
static func base_xform(r: Rig, pos: Vector2, height: float, tilt: float = 0.0) -> Transform2D:
	var k := height / BODY_H
	var w: float = clampf(absf(r.face), 0.3, 1.0) * signf(r.face if r.face != 0.0 else 1.0)
	return Transform2D(tilt, Vector2(k * w, k), 0.0, pos) * Transform2D(0.0, -ORIGIN)

# rifle tip on screen (for where bullets start)
static func muzzle_screen(r: Rig, X: Dictionary, pos: Vector2, height: float, tilt: float = 0.0) -> Vector2:
	return base_xform(r, pos, height, tilt) * Vector2(X.muzzle)

const ORDER := ["jetpack", "thigh_r", "thigh_l", "shin_r", "shin_l", "hips", "torso", "orb", "helmet", "visor",
	"upper_l", "forearm_l", "pad_l", "rifle", "upper_r", "forearm_r", "pad_r"]

# The solid pilot. Call draw_light() on an additive layer drawn BEHIND him for the
# flames, and draw_glow() on an additive layer in FRONT for visor light and muzzle flash.
static func draw(c: CanvasItem, r: Rig, X: Dictionary, pos: Vector2, height: float, tilt: float = 0.0, alpha: float = 1.0, lift: Color = LIFT) -> void:
	var base := base_xform(r, pos, height, tilt)
	var col := Color(lift.r, lift.g, lift.b, alpha)
	for nm in ORDER:
		if nm == "shin_r":
			_draw_part(c, base, X.shin_r, "shin", col)
		elif nm == "shin_l":
			_draw_part(c, base, X.shin_l, "shin", col, true)
		elif nm == "rifle":
			_draw_part(c, base, X.rifle, RIFLE, col)
		elif nm.begins_with("pad") and PARTS.upper_r.has("tex"):
			continue   # chunky upper arms carry their own shoulder pads
		else:
			_draw_part(c, base, X[nm], nm, col)
	c.draw_set_transform_matrix(Transform2D.IDENTITY)

# ------------------------------------------------------------------ light layers

const STYLE_TEX := {
	"flame":    {"plume": "ion_plume", "glow": "ion_glow", "spark": "ion_spark"},
	"plasma":   {"plume": "plasma_plume", "glow": "plasma_glow", "spark": "plasma_spark"},
	"pressure": {"plume": "", "glow": "pressure_glow", "spark": "pressure_spark"},
	"gravity":  {"plume": "gravity_plume", "glow": "gravity_glow", "spark": "gravity_spark"},
	"pixel":    {"plume": "pixel_plume", "glow": "pixel_glow", "spark": "pixel_spark"},
}

static func _ft(name: String) -> Texture2D:
	return tex("flame_" + name)

# hash noise 0..1 for flicker
static func _n(x: float) -> float:
	return fposmod(sin(x * 12.9898) * 43758.5453, 1.0)

static func _flick(t: float, seed_v: float) -> float:
	var a := floorf(t * 24.0)
	return lerpf(_n(a + seed_v), _n(a + 1.0 + seed_v), smoothstep(0.0, 1.0, fposmod(t * 24.0, 1.0)))

# Thruster flames from both jetpack nozzles, Luna's layers stretched by hover power.
static func draw_light(c: CanvasItem, r: Rig, X: Dictionary, pos: Vector2, height: float, style: String, tilt: float = 0.0, alpha: float = 1.0) -> void:
	var base := base_xform(r, pos, height, tilt)
	var st: Dictionary = STYLE_TEX.get(style, STYLE_TEX.flame)
	var p := clampf(r.hover, 0.2, 2.2)
	var jet_sz := size_of("jetpack")
	for i in NOZZLES.size():
		var nz: Vector2 = X.jetpack * local("jetpack", NOZZLES[i])
		var down: Vector2 = X.jetpack.basis_xform(Vector2.DOWN).normalized()
		var rot := down.angle() - PI / 2.0
		var seed_v := float(i) * 7.31
		var fl := 0.85 + 0.3 * _flick(r.t, seed_v)
		var nw := jet_sz.x * 0.13               # nozzle width in reference px
		c.draw_set_transform_matrix(base * Transform2D(rot, nz))
		match style:
			"pressure":
				# shock rings pushed out of the nozzle, growing and fading
				var rt := _ft(st.spark)
				for k in 4:
					var ph := fposmod(r.t * (1.6 + 0.6 * p) + k * 0.25 + i * 0.13, 1.0)
					var w := nw * (0.9 + ph * 1.8)
					var h := w * 0.42
					c.draw_texture_rect(rt, Rect2(-w * 0.5, ph * nw * 3.2 * p - h * 0.5, w, h), false, Color(1.4, 1.4, 1.4, (1.0 - ph) * alpha))
			"pixel":
				var pt := _ft(st.plume)
				var steps := floorf(fl * 4.0) / 4.0     # chunky, stepped flicker
				var L := nw * (1.6 + 1.8 * p) * (0.85 + 0.2 * steps)
				var W := nw * 1.15
				c.draw_texture_rect(pt, Rect2(-W * 0.5, -nw * 0.1, W, L), false, Color(1, 1, 1, 0.95 * alpha))
			_:
				var pt := _ft(st.plume)
				var asp := pt.get_width() / float(pt.get_height())
				var L := nw * (1.4 + 2.2 * p) * fl
				var W := nw * (1.0 + 0.35 * p)
				if style == "flame":
					W = minf(W, L * asp * 0.55)     # Ion plume is wide and cloudy: squeeze it
				elif style == "plasma":
					W = nw * 1.1
					L *= 1.25
				elif style == "gravity":
					W = nw * 1.9
					L = nw * (1.6 + 0.8 * p)
				# two copies, the second shorter and offset in time: the plume shimmers
				c.draw_texture_rect(pt, Rect2(-W * 0.5, -nw * 0.15, W, L), false, Color(1, 1, 1, 0.85 * alpha))
				var fl2 := 0.85 + 0.3 * _flick(r.t + 0.37, seed_v + 3.0)
				c.draw_texture_rect(pt, Rect2(-W * 0.4, -nw * 0.15, W * 0.8, L * 0.7 * fl2), false, Color(1, 1, 1, 0.45 * alpha))
				if style == "flame" or style == "plasma":
					# thin hot core, drawn in code (the sheet has none)
					var cl := L * (0.45 if style == "flame" else 0.7)
					c.draw_colored_polygon(PackedVector2Array([Vector2(-nw * 0.16, 0), Vector2(nw * 0.16, 0), Vector2(0, cl)]), Color(0.85, 0.97, 1.0, 0.7 * alpha))
		# nozzle glow, seen from the side: squashed
		var gt := _ft(st.glow)
		var gw := nw * (1.5 + 0.3 * p) * (0.9 + 0.15 * fl)
		var gh := gw * (0.55 if style != "pixel" else 0.6)
		c.draw_texture_rect(gt, Rect2(-gw * 0.5, -gh * 0.5, gw, gh), false, Color(1, 1, 1, (0.55 + 0.25 * p / 2.0) * alpha))
		# drifting particles: fixed slots on a loop, so no state is needed
		if style != "pressure":
			var sp := _ft(st.spark)
			var n := 5
			for k in n:
				var ph := fposmod(r.t * (0.9 + 0.4 * p) + float(k) / n + i * 0.5, 1.0)
				var side := (_n(floorf(r.t * (0.9 + 0.4 * p) + float(k) / n + i * 0.5) + k * 3.1 + i) - 0.5) * nw * 1.6
				var d := ph * nw * (2.5 + 2.5 * p)
				var a := (1.0 - ph) * 0.9
				var sz := nw * (0.55 if style != "pixel" else 0.22) * (1.0 - ph * 0.5)
				var y := d
				if style == "gravity":
					y = (1.0 - ph) * nw * 3.5    # specks fall IN toward the nozzle
					a = ph * 0.9
				c.draw_texture_rect(sp, Rect2(side * (0.4 + ph) - sz * 0.5, y - sz * 0.5, sz, sz), false, Color(1, 1, 1, a * alpha))
	c.draw_set_transform_matrix(Transform2D.IDENTITY)

# Visor light (pulsing, brighter on a shot) and the muzzle flash. Additive, in front.
static func draw_glow(c: CanvasItem, r: Rig, X: Dictionary, pos: Vector2, height: float, tilt: float = 0.0, alpha: float = 1.0) -> void:
	var base := base_xform(r, pos, height, tilt)
	var pulse := 0.55 + 0.3 * (0.5 + 0.5 * sin(r.t * 2.2)) + 0.4 * r.recoil
	_visor_light(c, base, X.visor, pulse * alpha)
	if r.recoil > 0.02:
		# Luna's muzzle flash in 4 steps as the recoil fades: star burst, big cone, fading
		# cone, sparks (pointing along the shot)
		var k := 1.0 - r.recoil
		var frame := mini(int(k * 4.0), 3)
		var fl := tex("muzzle_%d" % frame)
		var flen: float = 330.0 * [0.7, 1.0, 0.9, 0.9][frame]
		var hgt := flen * fl.get_height() / fl.get_width()
		c.draw_set_transform_matrix(base * Transform2D(X.aim_dir.angle(), X.muzzle))
		c.draw_texture_rect(fl, Rect2(-flen * 0.08, -hgt * 0.5, flen, hgt), false, Color(1, 1, 1, alpha * (1.0 if frame < 3 else 0.8)))
	c.draw_set_transform_matrix(Transform2D.IDENTITY)

static func _visor_light(c: CanvasItem, base: Transform2D, xf: Transform2D, a: float) -> void:
	var tx := tex("visor_light")
	var sz := tx.get_size() * float(PARTS.visor.s)
	var pv: Vector2 = PARTS.visor.pv
	c.draw_set_transform_matrix(base * xf)
	c.draw_texture_rect(tx, Rect2(-pv * sz, sz), false, Color(1, 1, 1, a))

# ------------------------------------------------------------------ front view (turn)
# Luna's front-facing parts (pilot_front/, batch D). While he turns from one side to the
# other, the rig passes through this front pose instead of mirroring on the spot.
# FRONT: part -> [centre in front px (origin at the chest like the side rig, y down), scale, mirror].
# The pose is about as tall as the side rig (FRONT_K matches their heights).
const FRONT_K := 1.0
const FRONT := [
	["jet", Vector2(-182, 10), 0.85, false], ["jet", Vector2(182, 10), 0.85, true],
	["thigh_r", Vector2(-70, 350), 0.85, false], ["thigh_l", Vector2(70, 355), 0.85, false],
	["shin", Vector2(-72, 580), 0.85, false], ["shin", Vector2(72, 580), 0.85, true],
	["hips", Vector2(0, 210), 1.05, false],
	["torso", Vector2(0, 40), 1.1, false],
	["rifle", Vector2(-200, 140), 0.75, false],
	["upper", Vector2(-185, 60), 0.7, false], ["upper", Vector2(185, 60), 0.7, true],
	["forearm_fist", Vector2(-192, 270), 0.7, false], ["forearm_open", Vector2(195, 280), 0.7, true],
	["pad_r", Vector2(-165, -50), 0.95, false], ["pad_l", Vector2(165, -50), 0.95, false],
	["helmet", Vector2(0, -370), 1.6, false],
]
static var _ftex := {}

static func front_ready() -> bool:
	return ResourceLoader.exists("res://pilot_front/helmet.png")

static func draw_front(c: CanvasItem, r: Rig, pos: Vector2, height: float, alpha: float = 1.0, lift: Color = LIFT) -> void:
	var k := height / BODY_H * FRONT_K
	var breath := sin(r.t * TAU / 2.6)
	var col := Color(lift.r, lift.g, lift.b, alpha)
	for part in FRONT:
		var nm: String = part[0]
		if not _ftex.has(nm):
			_ftex[nm] = load("res://pilot_front/%s.png" % nm)
		var tx: Texture2D = _ftex[nm]
		var s: float = float(part[2])
		var sz := tx.get_size() * s
		var at: Vector2 = part[1]
		# a little life: he breathes, the helmet nods, the hands sway
		if nm == "helmet":
			at += Vector2(0, breath * 6.0)
		elif nm.begins_with("forearm") or nm == "rifle":
			at += Vector2(0, sin(r.t * 2.1) * 4.0)
		c.draw_set_transform(pos + Vector2(0, sin(r.t * TAU / 2.6) * 2.0), 0.0, Vector2(k * (-1.0 if part[3] else 1.0), k))
		var p := Vector2((-at.x if part[3] else at.x), at.y) - sz * 0.5
		c.draw_texture_rect(tx, Rect2(p, sz), false, col)
	c.draw_set_transform_matrix(Transform2D.IDENTITY)

# How much of the front pose shows (0 side view, 1 facing the camera), from rig.face.
static func front_weight(r: Rig) -> float:
	return 1.0 - smoothstep(0.42, 0.52, absf(r.face))
