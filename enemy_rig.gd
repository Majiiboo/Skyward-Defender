class_name EnemyRig
extends RefCounted
# Draws enemies from painted parts instead of whole frames, so wings flap on a
# smooth curve at any speed. Each enemy = body + a wing hinged on each side
# (one painted wing, mirrored for the left). The Hive Mother adds egg sacs and
# claws. Anchors are 0..1 across the body image.

# Luna's 3D bugs (dev87): bodies seen from above with the head pointing DOWN, wings
# hinged at the shoulders behind the head and swept back (up) at rest. "sac" and
# "muzzle" are the Spitter's goo sac (on its back, top) and mouth (bottom).
const PARTS := {
	"scout":   {"hinge_l": Vector2(0.36, 0.62), "hinge_r": Vector2(0.64, 0.62), "wing_scale": 0.42, "flap": 50.0, "amp": 0.45, "rest": 0.55},
	"drifter": {"hinge_l": Vector2(0.30, 0.55), "hinge_r": Vector2(0.70, 0.55), "wing_scale": 0.62, "flap": 30.0, "amp": 0.35, "rest": 0.45},
	"spitter": {"hinge_l": Vector2(0.32, 0.62), "hinge_r": Vector2(0.68, 0.62), "wing_scale": 0.50, "flap": 42.0, "amp": 0.40, "rest": 0.55,
		"sac": Vector2(0.5, 0.16), "muzzle": Vector2(0.5, 0.97)},
	"diver":   {"hinge_l": Vector2(0.36, 0.66), "hinge_r": Vector2(0.64, 0.66), "wing_scale": 0.50, "flap": 46.0, "amp": 0.40, "rest": 0.75},
	"hive_mother": {"hinge_l": Vector2(0.24, 0.52), "hinge_r": Vector2(0.76, 0.52), "wing_scale": 0.95, "flap": 7.0, "amp": 0.25, "rest": 0.40},
}
static var _tex := {}
const WING_BLUR := [0.55, 0.42, 0.3]   # alpha of each motion-blur copy of a beating wing

# Luna's parts round 1 (dev161): a clean body (no legs or feelers painted on) plus legs as
# one piece per side, feelers as one piece, and the Spitter's sac full / empty. Each leg
# piece: pv = the joint in its own picture (0..1), at = where it attaches on the body
# (0..1 of the OLD body picture, so the wing hinges stay right), rot = its rest angle,
# s = its size as a share of the body scale. Legs paddle, feelers trail and sway.
# One piece per bug (the LEFT legs); the right side is the same piece mirrored, so both
# sides always match. pv = the hip joints in the picture, at = where they attach on the
# left side of the body, rot = rest angle (+ = legs swept back, toward the top), s = size.
const LEGS := {
	"scout":   {"pv": Vector2(0.90, 0.10), "at": Vector2(0.24, 0.42), "rot": 0.15, "s": 0.46},
	"drifter": {"pv": Vector2(0.92, 0.30), "at": Vector2(0.18, 0.44), "rot": 0.10, "s": 0.50},
	"spitter": {"pv": Vector2(0.95, 0.50), "at": Vector2(0.20, 0.48), "rot": -0.20, "s": 0.44},
	"diver":   {"pv": Vector2(0.95, 0.50), "at": Vector2(0.30, 0.48), "rot": -0.10, "s": 0.40},
}
const FEELERS := {"pv": Vector2(0.5, 0.97), "at": Vector2(0.5, 0.92), "s": 0.42}   # the V's vertex sits on the head
static var _exists := {}

static func _has(name: String) -> bool:
	if not _exists.has(name):
		_exists[name] = ResourceLoader.exists("res://enemies/parts/%s.png" % name)
	return _exists[name]

static func _t(name: String) -> Texture2D:
	if not _tex.has(name):
		_tex[name] = load("res://enemies/parts/%s.png" % name)
	return _tex[name]

# A colour every piece of the bug is drawn in (battle sets it for a frozen or burning bug,
# dev209: the effect must show ON the bug), white = as painted.
static var tint := Color.WHITE

static func _draw_tex(c: CanvasItem, tex: Texture2D, pos: Vector2, scale: float, rot: float, pivot: Vector2, flip_x: bool = false, alpha: float = 1.0, pre: Transform2D = Transform2D.IDENTITY, bright: float = 1.0) -> void:
	# pivot is 0..1 inside the texture; the texture is placed so pivot sits at pos. `pre` is an
	# extra world-space transform applied over the part (the whole-bug stretch, dev153).
	var sz := tex.get_size() * scale
	if pre == Transform2D.IDENTITY:
		c.draw_set_transform(pos, rot, Vector2(-1.0 if flip_x else 1.0, 1.0))
	else:
		c.draw_set_transform_matrix(pre * Transform2D(rot, Vector2(-1.0 if flip_x else 1.0, 1.0), 0.0, pos))
	c.draw_texture_rect(tex, Rect2(-Vector2(pivot.x * sz.x, pivot.y * sz.y), sz), false, Color(bright * tint.r, bright * tint.g, bright * tint.b, alpha))   # bright > 1 = the hit flash
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# fold: 0 = wings open and flapping, 1 = folded flat (diving, hatching). Values in
# between blend smoothly, so wings fold and unfold instead of snapping.
# alpha fades the whole bug (entering at the top, hatching). Never set the node's
# modulate inside _draw for this: it applies to everything the node draws.
# stretch (dev153): the whole bug is stretched by `stretch` along the world direction
# `stretch_ang` (its motion) and squeezed across it, around its centre: darting and diving
# bugs lengthen into their motion like a drawn animation would.
static func draw_bug(c: CanvasItem, kind: String, pos: Vector2, size: float, t: float, phase: float, tilt: float = 0.0, fold: float = 0.0, speed_mult: float = 1.0, alpha: float = 1.0, stretch: float = 0.0, stretch_ang: float = 0.0, bright: float = 1.0, sac: float = -1.0) -> void:
	var p: Dictionary = PARTS[kind]
	var parts := _has(kind + "_body_clean") and LEGS.has(kind)
	var pre := Transform2D.IDENTITY
	if stretch > 0.001:
		pre = Transform2D(0.0, pos) * Transform2D(stretch_ang, Vector2.ZERO) * Transform2D(0.0, Vector2(1.0 + stretch, 1.0 - stretch * 0.5), 0.0, Vector2.ZERO) * Transform2D(-stretch_ang, Vector2.ZERO) * Transform2D(0.0, -pos)
	var body: Texture2D = _t(kind + "_body")
	var wing: Texture2D = _t(kind + "_wing")
	var s: float = size / 220.0
	var bsz := body.get_size() * s
	var k: float = smoothstep(0.0, 1.0, fold)
	var ws: float = s * float(p.wing_scale) * lerpf(1.0, 0.3, k)
	var hl: Vector2 = Vector2(float(p.hinge_l.x) - 0.5, float(p.hinge_l.y) - 0.5) * bsz
	var hr: Vector2 = Vector2(float(p.hinge_r.x) - 0.5, float(p.hinge_r.y) - 0.5) * bsz
	# wings behind the body; the painted wing points right with its root at the left end
	c.draw_set_transform(pos, tilt, Vector2.ONE)
	var ca := cos(tilt)
	var sa := sin(tilt)
	var hl_w := pos + Vector2(hl.x * ca - hl.y * sa, hl.x * sa + hl.y * ca)
	var hr_w := pos + Vector2(hr.x * ca - hr.y * sa, hr.x * sa + hr.y * ca)
	# Insect wings beat faster than a screen can show, so each wing is drawn at three
	# moments inside one frame (motion blur): a translucent fan, not a jittery flap.
	for i in WING_BLUR.size():
		var ts: float = t - float(i) * 0.006
		var flap: float = lerpf(float(p.rest) + float(p.amp) * sin(ts * float(p.flap) * speed_mult + phase), 0.9, k)
		var wa: float = alpha * lerpf(WING_BLUR[i], 1.0 if i == 0 else 0.0, k)   # folded wings are still: one solid copy
		if wa < 0.01:
			continue
		_draw_tex(c, wing, hr_w, ws, tilt - flap, Vector2(0.02, 0.5), false, wa, pre)
		_draw_tex(c, wing, hl_w, ws, tilt + flap, Vector2(0.02, 0.5), true, wa, pre)
	if not parts:
		_draw_tex(c, body, pos, s, tilt, Vector2(0.5, 0.5), false, alpha, pre, bright)
		return
	# legs behind the body, paddling (each side half a beat apart); folded bugs tuck them in
	var spec: Dictionary = LEGS[kind]
	var legs_tex: Texture2D = _t(kind + "_legs_l")
	var paddle_amp := 0.13 * (1.0 - k)
	for side in ["l", "r"]:
		var sg: float = -1.0 if side == "l" else 1.0
		var at_rel := Vector2(spec.at) - Vector2(0.5, 0.5)
		if side == "r":
			at_rel.x = -at_rel.x
		var at_w: Vector2 = pos + (at_rel * bsz).rotated(tilt)
		var paddle: float = sin(t * 9.0 * speed_mult + phase + (0.0 if side == "l" else PI)) * paddle_amp
		var tuck: float = 0.5 * k   # fold: legs pulled in under the body
		# the left piece as painted; the right side is the same piece mirrored (rot mirrored too)
		_draw_tex(c, legs_tex, at_w, s * float(spec.s), tilt + sg * -(float(spec.rot) + paddle + tuck), spec.pv, side == "r", alpha, pre, bright)
	# the clean body, drawn the same size as the old body picture
	var clean: Texture2D = _t(kind + "_body_clean")
	var cs: float = s * body.get_height() / maxf(clean.get_height(), 1.0)
	_draw_tex(c, clean, pos, cs, tilt, Vector2(0.5, 0.5), false, alpha, pre, bright)
	# the Spitter's sac: full before a spit, empty right after (sac 0..1), over the body
	if kind == "spitter" and sac >= 0.0 and _has("spitter_sac_full"):
		var sac_at: Vector2 = pos + ((Vector2(p.sac) - Vector2(0.5, 0.5)) * bsz).rotated(tilt)
		var ss: float = s * 0.38
		_draw_tex(c, _t("spitter_sac_empty"), sac_at, ss, tilt, Vector2(0.5, 0.5), false, alpha * (1.0 - sac), pre, bright)
		_draw_tex(c, _t("spitter_sac_full"), sac_at, ss * (0.9 + 0.15 * sac), tilt, Vector2(0.5, 0.5), false, alpha * sac, pre, bright)
	# feelers in front, from the head, trailing the turn and swaying
	var f_at: Vector2 = pos + ((Vector2(FEELERS.at) - Vector2(0.5, 0.5)) * bsz).rotated(tilt)
	var sway: float = sin(t * 2.6 + phase) * 0.06 - tilt * 0.35
	_draw_tex(c, _t(kind + "_feelers"), f_at, s * float(FEELERS.s), tilt + PI + sway, FEELERS.pv, false, alpha, pre, bright)

# World position of a named anchor on the body art ("muzzle", "sac"), for a bug
# drawn by draw_bug with the same size and tilt. Falls back to the body centre.
static func anchor(kind: String, name: String, pos: Vector2, size: float, tilt: float = 0.0) -> Vector2:
	var p: Dictionary = PARTS[kind]
	if not p.has(name):
		return pos
	var bsz := _t(kind + "_body").get_size() * (size / 220.0)
	var a: Vector2 = p[name]
	return pos + (Vector2(a.x - 0.5, a.y - 0.5) * bsz).rotated(tilt)

static func draw_hive_mother(c: CanvasItem, pos: Vector2, size: float, t: float, lay: float, cracked: bool = false) -> void:
	# lay: seconds left in the lay cycle (0 = not laying). Sacs swell as it starts,
	# burst, then show deflated until the cycle ends.
	var p: Dictionary = PARTS["hive_mother"]
	var body: Texture2D = _t("hive_body")
	var wing: Texture2D = _t("hive_wing")
	var s: float = size / 300.0
	var bsz := body.get_size() * s
	var flap: float = float(p.rest) + float(p.amp) * sin(t * float(p.flap))
	var hl := pos + Vector2(float(p.hinge_l.x) - 0.5, float(p.hinge_l.y) - 0.5) * bsz
	var hr := pos + Vector2(float(p.hinge_r.x) - 0.5, float(p.hinge_r.y) - 0.5) * bsz
	_draw_tex(c, wing, hr, s * float(p.wing_scale), -flap, Vector2(0.02, 0.5), false)
	_draw_tex(c, wing, hl, s * float(p.wing_scale), flap, Vector2(0.02, 0.5), true)
	# claws reach forward from under the head and sway, hinged at their elbows
	var sway := sin(t * 1.7) * 0.10
	_draw_tex(c, _t("hive_claw_l"), pos + Vector2(-0.28, 0.30) * bsz, s * 0.75, 0.15 + sway, Vector2(0.80, 0.12))
	_draw_tex(c, _t("hive_claw_r"), pos + Vector2(0.28, 0.30) * bsz, s * 0.75, -0.15 - sway, Vector2(0.20, 0.12))
	_draw_tex(c, body, pos, s, 0.0, Vector2(0.5, 0.5))
	# egg sacs on her back (top): breathe, swell before the burst, deflated after
	# Full and empty sacs cross-fade around the burst, and the size eases between
	# phases, so nothing pops.
	var sac_scale: float = 1.0 + 0.04 * sin(t * 2.2)
	var empty_a := 0.0
	if lay > 0.0:
		if lay > 2.2:
			sac_scale = 1.0 + 0.35 * smoothstep(3.0, 2.2, lay)
		elif lay > 1.8:
			sac_scale = 1.35
		else:
			sac_scale = lerpf(1.35, 0.85, smoothstep(1.8, 1.5, lay)) + 0.15 * smoothstep(1.2, 0.0, lay)
		empty_a = smoothstep(2.0, 1.6, lay) * smoothstep(0.0, 0.3, lay)
	var sac_pos := pos + Vector2(0.0, -0.24) * bsz
	if empty_a < 1.0:
		_draw_tex(c, _t("hive_sacs_full"), sac_pos, s * 0.66 * sac_scale, 0.0, Vector2(0.5, 0.80), false, 1.0 - empty_a)
	if empty_a > 0.0:
		_draw_tex(c, _t("hive_sacs_empty"), sac_pos, s * 0.66 * sac_scale, 0.0, Vector2(0.5, 0.80), false, empty_a)
	if lay > 1.8 and lay < 2.2:
		# the burst: purple splash around the sacs
		var k := (2.2 - lay) / 0.4
		var centre := pos + Vector2(0.0, -0.40) * bsz
		for i in 8:
			var a := TAU * float(i) / 8.0 + k
			c.draw_line(centre, centre + Vector2(cos(a), sin(a)) * (20.0 + 50.0 * k) * s, Color(0.8, 0.5, 1.0, (1.0 - k) * 0.8), 3.0 * s, true)
		c.draw_circle(centre, (14.0 + 30.0 * k) * s, Color(0.7, 0.4, 1.0, (1.0 - k) * 0.35))
	if cracked:
		# phase 2: cracks and sparks on the armour
		for i in 4:
			var a := t * 3.0 + i * 1.6
			c.draw_circle(pos + Vector2(cos(a) * 0.3, sin(a * 1.3) * 0.2) * bsz, 2.0 * s, Color(1.0, 0.6, 0.3, 0.6))

# ---- the SCRAP BELT machines (Luna's family, dev198; tools/cut_scrap.gd): a body and moving
# pieces placed by shares of the WHOLE picture's box (anchors measured on <id>_whole), every
# piece at the whole's scale. Rotors spin, panels sway, the Rivet Gun's pod fills and empties
# (sac), the Dart's flame flickers, the Wrecker lowers its claw arm (ext), the Queen's arms
# swing and her hold opens to release Mites (lay). Front points DOWN like the bugs.
const MACHINES := {
	"mite":    {"whole": Vector2(256, 205), "rotors": [Vector2(0.13, 0.46), Vector2(0.87, 0.46)], "muzzle": Vector2(0.5, 0.95)},
	"hulk":    {"whole": Vector2(256, 246), "panels": [Vector2(0.22, 0.36), Vector2(0.78, 0.36)]},
	"rivet":   {"whole": Vector2(190, 256), "pod": Vector2(0.5, 0.17), "muzzle": Vector2(0.5, 0.96)},
	"dart":    {"whole": Vector2(63, 256), "flame": Vector2(0.5, 0.06)},
	"bolt":    {"whole": Vector2(128, 125)},
	"wrecker": {"whole": Vector2(288, 400), "rotors": [Vector2(0.27, 0.16), Vector2(0.73, 0.16)], "arm": Vector2(0.5, 0.60), "claw": Vector2(0.5, 0.88)},
	"queen":   {"whole": Vector2(480, 479), "arms": [Vector2(0.31, 0.44), Vector2(0.69, 0.44)], "hold": Vector2(0.5, 0.19), "muzzle": Vector2(0.5, 0.92)},
}
static var _mex := {}

static func is_machine(kind: String) -> bool:
	return MACHINES.has(kind)

static func _mhas(name: String) -> bool:
	if not _mex.has(name):
		_mex[name] = ResourceLoader.exists("res://enemies/scrap/%s.png" % name)
	return _mex[name]

static func _m(name: String) -> Texture2D:
	var key := "scrap/" + name
	if not _tex.has(key):
		_tex[key] = load("res://enemies/scrap/%s.png" % name)
	return _tex[key]

# a point on the whole picture (0..1) -> world, for a machine drawn at `size` with `tilt`
static func machine_anchor(kind: String, name: String, pos: Vector2, size: float, tilt: float = 0.0) -> Vector2:
	var spec: Dictionary = MACHINES[kind]
	if not spec.has(name):
		return pos
	var s: float = size / 220.0
	var a: Vector2 = spec[name]
	return pos + ((a - Vector2(0.5, 0.5)) * Vector2(spec.whole) * s).rotated(tilt)

# size = the machine's on-screen scale (like draw_bug: 220 picture px = `size`); sac = the
# Rivet pod 0 empty .. 1 full (-1 = none); ext = the Wrecker's arm reach 0..1; lay = the Queen's
# hold cycle (seconds left, 0 = closed), like the Hive Mother's
static func draw_machine(c: CanvasItem, kind: String, pos: Vector2, size: float, t: float, phase: float, tilt: float = 0.0, alpha: float = 1.0, bright: float = 1.0, sac: float = -1.0, ext: float = 0.0, lay: float = 0.0, stretch: float = 0.0, stretch_ang: float = 0.0) -> void:
	var spec: Dictionary = MACHINES[kind]
	var s: float = size / 220.0
	var wsz: Vector2 = Vector2(spec.whole) * s
	var pre := Transform2D.IDENTITY
	if stretch > 0.001:
		pre = Transform2D(0.0, pos) * Transform2D(stretch_ang, Vector2.ZERO) * Transform2D(0.0, Vector2(1.0 + stretch, 1.0 - stretch * 0.5), 0.0, Vector2.ZERO) * Transform2D(-stretch_ang, Vector2.ZERO) * Transform2D(0.0, -pos)
	var at := func(a: Vector2) -> Vector2:
		return pos + ((a - Vector2(0.5, 0.5)) * wsz).rotated(tilt)
	if not _mhas(kind + "_body"):
		# no pieces: the whole picture (the Junk Bolt tumbles)
		var spin: float = t * 2.4 + phase if kind == "bolt" else 0.0
		_draw_tex(c, _m(kind + "_whole"), pos, s, tilt + spin, Vector2(0.5, 0.5), false, alpha, pre, bright)
		return
	# pieces BEHIND the body
	match kind:
		"mite", "wrecker":
			# rotors: a blurred spin (three copies a few degrees apart), the Wrecker's are wheels
			var rt: Texture2D = _m(kind + "_rotor")
			for r in spec.rotors:
				for i in 3:
					var ang: float = t * (28.0 if kind == "mite" else 9.0) + phase + float(i) * 0.5
					_draw_tex(c, rt, at.call(r), s, tilt + ang, Vector2(0.5, 0.5), false, alpha * (0.55 if i == 0 else 0.3), pre, bright)
		"hulk":
			# the two thruster panels, swaying a touch, slung at the sides
			var i := 0
			for p in spec.panels:
				var tx: Texture2D = _m(kind + ("_panel_l" if i == 0 else "_panel_r"))
				_draw_tex(c, tx, at.call(p), s, tilt + sin(t * 2.0 + phase + float(i) * PI) * 0.05, Vector2(0.5, 0.42), false, alpha, pre, bright)
				i += 1
		"dart":
			# the tail flame: flickers and stretches with the engine
			var fl: Texture2D = _m("dart_flame")
			var k: float = 0.85 + 0.25 * absf(sin(t * 23.0 + phase)) + 0.3 * stretch
			c.draw_set_transform_matrix(pre * Transform2D(tilt, Vector2(1.0, k), 0.0, at.call(spec.flame)))
			var fs := fl.get_size() * s
			c.draw_texture_rect(fl, Rect2(-fs.x * 0.5, -fs.y * 0.86, fs.x, fs.y), false, Color(1, 1, 1, alpha * 0.95))
			c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"queen":
			# the two claw arms hinged at the shoulders, swinging out and in
			var i := 0
			for a in spec.arms:
				var tx: Texture2D = _m("queen_arm_l" if i == 0 else "queen_arm_r")
				var swing: float = sin(t * 1.3 + phase + float(i) * 1.7) * 0.18 + (0.35 if lay > 1.8 else 0.0) * (1.0 if i == 0 else -1.0)
				_draw_tex(c, tx, at.call(a), s, tilt + (-0.35 if i == 0 else 0.35) + swing, Vector2(0.5, 0.06), false, alpha, pre, bright)
				i += 1
	# the body
	_draw_tex(c, _m(kind + "_body"), pos, s, tilt, Vector2(0.5, 0.5), false, alpha, pre, bright)
	# pieces IN FRONT of the body
	match kind:
		"rivet":
			if sac >= 0.0 and _mhas("rivet_pod_full"):
				var pod_at: Vector2 = at.call(spec.pod)
				_draw_tex(c, _m("rivet_pod_empty"), pod_at, s, tilt, Vector2(0.5, 0.5), false, alpha * (1.0 - sac), pre, bright)
				_draw_tex(c, _m("rivet_pod_full"), pod_at, s * (0.9 + 0.15 * sac), tilt, Vector2(0.5, 0.5), false, alpha * sac, pre, bright)
		"wrecker":
			# the claw arm hangs under the body and reaches down (ext) to grab a turret; the
			# claw opens as it reaches
			var arm: Texture2D = _m("wrecker_arm")
			var reach: float = 0.9 + 0.5 * ext
			var arm_at: Vector2 = at.call(spec.arm)
			c.draw_set_transform_matrix(pre * Transform2D(tilt + PI * 0.5, Vector2(reach, 1.0), 0.0, arm_at))
			var asz := arm.get_size() * s
			c.draw_texture_rect(arm, Rect2(-asz.x * 0.05, -asz.y * 0.5, asz.x, asz.y), false, Color(bright * tint.r, bright * tint.g, bright * tint.b, alpha))
			c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			var claw_at: Vector2 = arm_at + Vector2(0, asz.x * 0.95 * reach).rotated(tilt)
			_draw_tex(c, _m("wrecker_claw_open"), claw_at, s * 0.75 * (0.8 + 0.4 * ext), tilt + sin(t * 3.0) * 0.1 * ext, Vector2(0.5, 0.2), false, alpha * clampf(ext * 2.0, 0.0, 1.0), pre, bright)
		"queen":
			# the hold on her back opens while she releases Mites (lay > 0), lit inside
			if lay > 0.0 and _mhas("queen_hold_open"):
				var open: float = smoothstep(3.0, 2.4, lay) * smoothstep(0.0, 0.4, lay)
				_draw_tex(c, _m("queen_hold_open"), at.call(spec.hold), s, tilt, Vector2(0.5, 0.5), false, alpha * open, pre, bright)
				if open > 0.5:
					c.draw_circle(at.call(spec.hold), 16.0 * s * (1.0 + 0.2 * sin(t * 9.0)), Color(0.3, 0.9, 1.0, 0.25 * open * alpha))
