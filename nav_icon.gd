class_name NavIcon
extends Control
# One bottom-bar tab icon, drawn from Luna's parts (LUNA-BRIEF-nav-icons.md round 2, cut by
# tools/cut_nav3.gd into icons/nav3/<kind>_<part>.png, every part of an icon on the same square so
# they stack). The open tab is in full colour and plays its own MOVE when opened, then a small IDLE
# move every few seconds and a gentle float; closed tabs are soft grey shapes (nav_icon.gdshader).
# Moves follow Rudy's demo (claude.ai/artifact/96yTzLebGhRXcLsRL1dcve):
#   store   latch flashes, the chest hops and opens on its gold (Luna's open picture), sparks fly out
#   heroes  the pilot drops in, looks up, a shine runs across the visor, the ear light blinks
#   battle  the four ticks spin in and lock on, the red rings pulse, a ring ripples out
#   modes   the planet bobs, a shine runs along its ring, a moon orbits (behind it, then in front)
#   quests  the clip snaps down, the ticks pop in one by one, then the third (a quest to claim)
#
# hub.gd: NavIcon.pictures_ready() (all pictures there) -> icon := NavIcon.new(); icon.setup(kind);
#         icon.set_open(on, play_move)

const DIR := "res://icons/nav3/"
const PARTS := {
	"store": ["body", "lid", "latch", "open"],
	"heroes": ["body", "head", "visor", "light"],
	"battle": ["disc", "rings", "ticks"],
	"modes": ["ring_back", "planet", "ring_front"],
	"quests": ["board", "clip", "tick_1", "tick_2", "tick_3"],
}
const MOVE_S := 1.5                     # the open move's length
const IDLE_S := {"store": 4.2, "heroes": 3.8, "battle": 3.0, "modes": 5.0, "quests": 4.6}   # idle every n s
const IDLE_LEN := 1.3
const CLOSED_K := 0.82                  # a closed icon's size against an open one
const FILL := 0.93                      # an open icon's share of this control's short side
const NECK := Vector2(0.5, 0.57)        # the pilot's head turns round this point
# the moon's path = the ring (measured on Luna's two ring halves): centre, half axes, tilt
const RING_C := Vector2(0.495, 0.503)
const RING_A := 0.468
const RING_B := 0.11
const RING_TILT := 0.3473               # 19.9 degrees: her ring dips to the right
const SPARKS := [[-0.2, -0.2, 0.42], [0.02, -0.28, 0.48], [0.21, -0.19, 0.54], [-0.11, -0.1, 0.6], [0.13, -0.09, 0.66]]
const CYAN := Color(0.31, 0.88, 1.0)

var kind := ""
var lit := 0.0                          # 0 closed (grey, small) .. 1 open (colour, full size)
var _tex := {}
var _moon: Texture2D
var _spark: Texture2D
var _box := {}                          # part -> used rect as shares of the square (pivots, shine bands)
var _open := false
var _move := -1.0                       # seconds into the open move (-1 = none)
var _idle := -1.0                       # seconds into an idle move (-1 = none)
var _idle_wait := 0.0
var _time := 0.0
var _mat: ShaderMaterial

static func pictures_ready() -> bool:
	for k in PARTS:
		for p in PARTS[k]:
			if not ResourceLoader.exists(DIR + "%s_%s.png" % [k, p]):
				return false
	return ResourceLoader.exists(DIR + "modes_moon.png") and ResourceLoader.exists(DIR + "spark.png")

func setup(k: String) -> void:
	kind = k
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for p in PARTS[k]:
		var t: Texture2D = load(DIR + "%s_%s.png" % [k, p])
		_tex[p] = t
		var img := t.get_image()
		if img != null:
			var r := img.get_used_rect()
			var s := float(img.get_width())
			_box[p] = Rect2(Vector2(r.position) / s, Vector2(r.size) / s)
	_moon = load(DIR + "modes_moon.png")
	_spark = load(DIR + "spark.png")
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://nav_icon.gdshader")
	material = _mat
	_mat.set_shader_parameter("grey", 1.0)

# on = this tab is open; play = run its open move now
func set_open(on: bool, play: bool = false) -> void:
	_open = on
	if on and play:
		_move = 0.0
		_idle = -1.0
		_idle_wait = 0.0
	if not on:
		_move = -1.0
		_idle = -1.0
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	var target := 1.0 if _open else 0.0
	if lit != target:
		lit = move_toward(lit, target, delta * 4.0)
		_mat.set_shader_parameter("grey", 1.0 - lit)
	if _move >= 0.0:
		_move += delta
		if _move > MOVE_S:
			_move = -1.0
	elif _open:
		_idle_wait += delta
		if _idle >= 0.0:
			_idle += delta
			if _idle > IDLE_LEN:
				_idle = -1.0
		elif _idle_wait > IDLE_S.get(kind, 4.0):
			_idle_wait = 0.0
			_idle = 0.0
	if _open or lit > 0.0 or _move >= 0.0:
		queue_redraw()
	else:
		set_process(false)

# ---- keyframes: [[t, value], ...], smooth between keys, held outside ----
static func _k(t: float, keys: Array) -> float:
	if t <= keys[0][0]:
		return keys[0][1]
	for i in range(1, keys.size()):
		if t <= keys[i][0]:
			var a: Array = keys[i - 1]
			var b: Array = keys[i]
			var u := (t - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.0001)
			u = u * u * (3.0 - 2.0 * u)
			return lerpf(a[1], b[1], u)
	return keys[keys.size() - 1][1]

# ---- drawing ----
var _side := 0.0
var _base := Transform2D()
var _alpha := 1.0

func _xf(pivot: Vector2, rot: float, scl: Vector2, off: Vector2 = Vector2.ZERO) -> Transform2D:
	var p := pivot * _side
	return Transform2D(rot, scl, 0.0, p + off * _side) * Transform2D(0.0, -p)

func _part(p: String, local := Transform2D(), col := Color.WHITE) -> void:
	if not _tex.has(p):
		return
	draw_set_transform_matrix(_base * local)
	col.a *= _alpha
	draw_texture_rect(_tex[p], Rect2(0, 0, _side, _side), false, col)

func _centre(p: String) -> Vector2:
	var r: Rect2 = _box.get(p, Rect2(0, 0, 1, 1))
	return r.get_center()

# a bright vertical band that sweeps across one part (the visor, the ring): the part drawn again,
# over-bright, through a moving window. u = 0..1 across the part.
func _shine(p: String, local: Transform2D, u: float) -> void:
	if u <= 0.0 or u >= 1.0 or not _tex.has(p):
		return
	var r: Rect2 = _box.get(p, Rect2(0, 0, 1, 1))
	var band := 0.1
	var x0 := r.position.x - band + (r.size.x + band) * u
	var x1 := minf(x0 + band, r.end.x)
	x0 = maxf(x0, r.position.x)
	if x1 <= x0:
		return
	var tsz: Vector2 = (_tex[p] as Texture2D).get_size()
	draw_set_transform_matrix(_base * local)
	var a := 0.85 * _alpha * sin(PI * clampf(u, 0.0, 1.0))
	draw_texture_rect_region(_tex[p], Rect2(x0 * _side, 0, (x1 - x0) * _side, _side),
		Rect2(x0 * tsz.x, 0, (x1 - x0) * tsz.x, tsz.y), Color(3.0, 3.0, 3.0, a))

func _draw() -> void:
	if kind == "" or size.x < 4.0:
		return
	var m := _move
	var i := _idle
	_side = minf(size.x, size.y) * FILL * lerpf(CLOSED_K, 1.0, lit)
	# the whole icon: pop / drop / hop / bob on the open move, a slow float while open
	var s := 1.0
	var sx := 1.0
	var sy := 1.0
	var dy := 0.0
	_alpha = 1.0
	if m >= 0.0:
		if kind == "heroes":
			dy = _k(m, [[0.0, -0.55], [0.33, 0.04], [0.6, 0.0]])
			sx = _k(m, [[0.0, 0.9], [0.33, 1.08], [0.6, 1.0]])
			sy = _k(m, [[0.0, 0.9], [0.33, 0.9], [0.6, 1.0]])
			_alpha = _k(m, [[0.0, 0.0], [0.2, 1.0]])
		else:
			s = _k(m, [[0.0, 0.75], [0.3, 1.12], [0.5, 1.0]])
			dy = _k(m, [[0.0, 0.09], [0.3, -0.09], [0.5, 0.0]])
		if kind == "store":
			dy += _k(m - 0.2, [[0.0, 0.0], [0.14, -0.12], [0.32, 0.0], [0.42, -0.03], [0.52, 0.0]])
		elif kind == "modes":
			dy += _k(m - 0.3, [[0.0, 0.0], [0.55, -0.07], [1.1, 0.0]])
	elif _open:
		dy = -0.025 * (0.5 - 0.5 * cos(TAU * _time / 3.2))
	var c := size * 0.5 + Vector2(0.0, dy * _side)
	_base = Transform2D(0.0, Vector2(s * sx, s * sy), 0.0, c) * Transform2D(0.0, -Vector2(_side, _side) * 0.5)
	match kind:
		"store": _draw_store(m, i)
		"heroes": _draw_heroes(m, i)
		"battle": _draw_battle(m, i)
		"modes": _draw_modes(m, i)
		"quests": _draw_quests(m, i)
	draw_set_transform_matrix(Transform2D())

func _draw_store(m: float, i: float) -> void:
	var opened := _k(m - 0.25, [[0.0, 0.0], [0.1, 1.0], [0.7, 1.0], [1.0, 0.0]]) if m >= 0.0 else 0.0
	var flash := 0.0
	if m >= 0.0:
		flash = _k(m, [[0.0, 0.0], [0.12, 1.0], [0.3, 0.0]])
	elif i >= 0.0:
		flash = _k(i, [[0.0, 0.0], [0.2, 1.0], [0.5, 0.0]])
	var shut := Color(1, 1, 1, 1.0 - opened)
	_part("body", Transform2D(), shut)
	_part("lid", Transform2D(), shut)
	var b := 1.0 + flash
	_part("latch", Transform2D(), Color(b, b, b, 1.0 - opened))
	if opened > 0.0:
		_part("open", Transform2D(), Color(1, 1, 1, opened))
	# sparks: all five on the move, one on an idle glint
	for n in SPARKS.size():
		var t := -1.0
		if m >= 0.0:
			t = (m - float(SPARKS[n][2])) / 0.8
		elif i >= 0.0 and n == 1:
			t = (i - float(SPARKS[n][2])) / 0.8
		if t <= 0.0 or t >= 1.0:
			continue
		var e := 1.0 - (1.0 - t) * (1.0 - t)
		var pos := Vector2(0.5 + float(SPARKS[n][0]) * e, 0.38 + float(SPARKS[n][1]) * e) * _side
		var sz := _side * 0.2 * lerpf(0.2, 1.0, e)
		var a := _k(t, [[0.0, 0.0], [0.25, 1.0], [1.0, 0.0]]) * _alpha
		draw_set_transform_matrix(_base * Transform2D(e * PI * 0.5, pos))
		draw_texture_rect(_spark, Rect2(-sz * 0.5, -sz * 0.5, sz, sz), false, Color(1, 1, 1, a))

func _draw_heroes(m: float, i: float) -> void:
	_part("body")
	var rot := 0.0
	var hy := 0.0
	if m >= 0.0:
		rot = _k(m - 0.35, [[0.0, 0.0], [0.25, -0.14], [0.5, 0.05], [0.7, 0.0]])
		hy = _k(m - 0.35, [[0.0, 0.0], [0.25, -0.03], [0.5, 0.0]])
	elif i >= 0.0:
		rot = _k(i, [[0.0, 0.0], [0.32, -0.07], [0.8, 0.0]])
	var head := _xf(NECK, rot, Vector2.ONE, Vector2(0.0, hy))
	_part("head", head)
	_part("visor", head)
	var blink := 1.0
	var bt := (m - 0.3) if m >= 0.0 else i
	if bt >= 0.0 and bt < 0.8 and (bt < 0.2 or (bt >= 0.4 and bt < 0.6)):
		blink = 0.1
	_part("light", head, Color(1, 1, 1, blink))
	if m >= 0.0:
		_shine("visor", head, (m - 0.6) / 0.6)
	elif i >= 0.0:
		_shine("visor", head, i / 0.7)

func _draw_battle(m: float, i: float) -> void:
	_part("disc")
	var rs := 1.0
	var ts := 1.0
	var tr := 0.0
	var ta := 1.0
	if m >= 0.0:
		rs = _k(m - 0.4, [[0.0, 1.0], [0.2, 1.18], [0.5, 1.0]])
		ts = _k(m, [[0.0, 1.7], [0.3, 0.95], [0.45, 1.0]])
		tr = _k(m, [[0.0, 0.785], [0.45, 0.0]])
		ta = _k(m, [[0.0, 0.0], [0.3, 1.0]])
	elif i >= 0.0:
		ts = _k(i, [[0.0, 1.0], [0.6, 0.88], [1.2, 1.0]])
		rs = _k(i - 0.5, [[0.0, 1.0], [0.2, 1.18], [0.5, 1.0]])
	var mid := Vector2(0.5, 0.5)
	_part("rings", _xf(mid, 0.0, Vector2(rs, rs)))
	_part("ticks", _xf(mid, tr, Vector2(ts, ts)), Color(1, 1, 1, ta))
	if m >= 0.45 and m < 1.15:
		var t := (m - 0.45) / 0.7
		draw_set_transform_matrix(_base)
		draw_arc(mid * _side, _side * 0.5 * lerpf(0.45, 1.45, t), 0.0, TAU, 48, Color(CYAN, 0.9 * (1.0 - t) * _alpha), 2.0, true)

func _draw_modes(m: float, i: float) -> void:
	# the moon rides the ring: behind the planet on the top half, in front on the bottom half
	var a := _time * 1.6
	var e := Vector2(cos(a) * RING_A, sin(a) * RING_B).rotated(RING_TILT)
	var front := sin(a) > 0.0
	var su := -1.0
	if m >= 0.0:
		su = (m - 0.25) / 0.8
	elif i >= 0.0:
		su = (i - 0.25) / 0.8
	_part("ring_back")
	_shine("ring_back", Transform2D(), su)
	if not front:
		_moon_at(RING_C + e)
	_part("planet")
	_part("ring_front")
	_shine("ring_front", Transform2D(), su)
	if front:
		_moon_at(RING_C + e)

func _moon_at(p: Vector2) -> void:
	if lit <= 0.0:
		return
	draw_set_transform_matrix(_base)
	var sz := _side * 0.12
	draw_texture_rect(_moon, Rect2(p * _side - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), false, Color(1, 1, 1, lit * _alpha))

func _draw_quests(m: float, i: float) -> void:
	_part("board")
	var cy := 0.0
	var csy := 1.0
	var t := m if m >= 0.0 else i
	if t >= 0.0:
		cy = _k(t, [[0.0, -0.22], [0.3, 0.04], [0.55, 0.0]])
		csy = _k(t, [[0.0, 1.0], [0.3, 0.85], [0.55, 1.0]])
	var clip_top := Vector2(_centre("clip").x, _box.get("clip", Rect2()).position.y)
	_part("clip", _xf(clip_top, 0.0, Vector2(1.0, csy), Vector2(0.0, cy * 0.5)))
	for n in [1, 2]:
		var ts := 1.0
		if m >= 0.0:
			ts = _k(m - (0.05 + 0.25 * n), [[0.0, 0.0], [0.25, 1.15], [0.35, 1.0]])
		var p := "tick_%d" % n
		_part(p, _xf(_centre(p), 0.0, Vector2(ts, ts)))
	if m >= 0.82:
		var t3 := m - 0.82
		var s3 := _k(t3, [[0.0, 0.0], [0.16, 1.25], [0.26, 1.0]])
		var a3 := _k(t3, [[0.0, 0.0], [0.16, 1.0], [0.52, 1.0], [0.65, 0.0]])
		_part("tick_3", _xf(_centre("tick_3"), 0.0, Vector2(s3, s3)), Color(1, 1, 1, a3))
