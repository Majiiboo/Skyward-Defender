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

static func _draw_tex(c: CanvasItem, tex: Texture2D, pos: Vector2, scale: float, rot: float, pivot: Vector2, flip_x: bool = false, alpha: float = 1.0, pre: Transform2D = Transform2D.IDENTITY, bright: float = 1.0) -> void:
	# pivot is 0..1 inside the texture; the texture is placed so pivot sits at pos. `pre` is an
	# extra world-space transform applied over the part (the whole-bug stretch, dev153).
	var sz := tex.get_size() * scale
	if pre == Transform2D.IDENTITY:
		c.draw_set_transform(pos, rot, Vector2(-1.0 if flip_x else 1.0, 1.0))
	else:
		c.draw_set_transform_matrix(pre * Transform2D(rot, Vector2(-1.0 if flip_x else 1.0, 1.0), 0.0, pos))
	c.draw_texture_rect(tex, Rect2(-Vector2(pivot.x * sz.x, pivot.y * sz.y), sz), false, Color(bright, bright, bright, alpha))   # bright > 1 = the hit flash
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
