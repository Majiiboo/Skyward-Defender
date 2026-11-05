class_name MenuBackdrop
extends Control
# The living wallpaper behind every menu page (Rudy, dev145: menus looked plain next to
# Home). The current planet's painting (the same Backdrop world as Home and battle), drifting
# slowly with a slight zoom, darkened so the glass panels read, Luna's stars twinkling over
# it, a few motes of dust floating up, and a soft vignette. One node, added first in a page's
# _ready: MenuBackdrop.add_to(self). Cheap: one texture, 40 dots.

const DIM := Color(0.42, 0.46, 0.58)          # how dark the painting is drawn
const MOTES := 40

var _stars: Array = []
var _motes: Array = []
var _t := 0.0
var _key := "hive_a"
var _rng := RandomNumberGenerator.new()

static func add_to(page: Control) -> MenuBackdrop:
	var b := MenuBackdrop.new()
	b.name = "MenuBackdrop"
	page.add_child(b)
	page.move_child(b, 0)
	return b

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stars = Backdrop.make_stars(35 if Perf.lite() else 70, 5)
	_rng.seed = 11
	for i in (MOTES / 2 if Perf.lite() else MOTES):
		_motes.append({"x": _rng.randf(), "y": _rng.randf(), "s": _rng.randf_range(0.6, 1.6), "v": _rng.randf_range(0.004, 0.012), "ph": _rng.randf() * TAU})
	var sv := Progress.read()
	_key = String(StageData.sector(clampi(int(sv.get("selected_stage", 1)), 1, StageData.MAX_STAGE)).get("bg", "hive_a"))
	_t = _rng.randf() * 100.0
	_life_init()
	_next_shoot = _t + 2.0

func _process(delta: float) -> void:
	_t += delta
	if Perf.lite():
		# battery saver: the wallpaper only redraws a few times a second
		if Engine.get_process_frames() % 6 != 0:
			return
	queue_redraw()

# the page's size can lag a frame behind the screen when a scene opens on its own: always
# cover at least the whole screen (a container clips what it does not need)
func _sz() -> Vector2:
	var vp := get_viewport_rect().size
	return Vector2(maxf(size.x, vp.x), maxf(size.y, vp.y))

func _draw() -> void:
	# the world, slowly drifting sideways; the bottom of the painting sits under the nav bar
	var sz := _sz()
	var shift := sin(_t * 0.05) * 0.6
	draw_rect(Rect2(Vector2.ZERO, sz), Color(0.01, 0.012, 0.03))
	Backdrop.draw_world(self, sz, sz.y + 40.0, _key, _stars, _t, shift, 1.0)
	# darken so panels and text stay the subject
	draw_rect(Rect2(Vector2.ZERO, sz), Color(0.02, 0.03, 0.07, 1.0 - DIM.r))
	# dust rising through the light
	for m in _motes:
		var y: float = fposmod(float(m.y) - _t * float(m.v), 1.0)
		var x: float = float(m.x) + sin(_t * 0.4 + float(m.ph)) * 0.01
		var a: float = 0.10 + 0.10 * sin(_t * 1.3 + float(m.ph))
		draw_circle(Vector2(x * sz.x, y * sz.y), float(m.s), Color(0.6, 0.85, 1.0, a))
	_life_draw(sz, _t)
	# vignette: darker top band (under the title) and bottom (under the nav bar)
	var top := PackedVector2Array([Vector2(0, 0), Vector2(sz.x, 0), Vector2(sz.x, 140), Vector2(0, 140)])
	draw_polygon(top, PackedColorArray([Color(0.01, 0.015, 0.04, 0.55), Color(0.01, 0.015, 0.04, 0.55), Color(0.01, 0.015, 0.04, 0.0), Color(0.01, 0.015, 0.04, 0.0)]))
	var bot := PackedVector2Array([Vector2(0, sz.y - 160), Vector2(sz.x, sz.y - 160), Vector2(sz.x, sz.y), Vector2(0, sz.y)])
	draw_polygon(bot, PackedColorArray([Color(0.01, 0.015, 0.04, 0.0), Color(0.01, 0.015, 0.04, 0.0), Color(0.01, 0.015, 0.04, 0.7), Color(0.01, 0.015, 0.04, 0.7)]))

# ---- life in the sky (Rudy, dev167): a shooting star now and then, slow dark asteroids ----
var _shoot := {"t": -1.0, "x": 0.0, "y": 0.0, "dx": 0.0, "dy": 0.0}
var _next_shoot := 3.0
var _rocks: Array = []

func _life_init() -> void:
	for i in 5:
		_rocks.append({"x": _rng.randf(), "y": _rng.randf_range(0.1, 0.75), "s": _rng.randf_range(5.0, 14.0),
			"v": _rng.randf_range(0.004, 0.011) * (1.0 if _rng.randf() < 0.5 else -1.0), "spin": _rng.randf_range(-0.4, 0.4), "ph": _rng.randf() * TAU})

func _life_draw(sz: Vector2, dt_total: float) -> void:
	# asteroids: small dark lumps with a lit edge, drifting sideways and turning
	for r in _rocks:
		var x: float = fposmod(float(r.x) + dt_total * float(r.v), 1.2) - 0.1
		var p := Vector2(x * sz.x, float(r.y) * sz.y + sin(dt_total * 0.3 + float(r.ph)) * 6.0)
		var a: float = dt_total * float(r.spin) + float(r.ph)
		var pts := PackedVector2Array()
		for k in 7:
			var ang := a + TAU * k / 7.0
			var rad: float = float(r.s) * (0.75 + 0.25 * sin(float(r.ph) * 3.0 + k * 1.7))
			pts.append(p + Vector2(cos(ang), sin(ang)) * rad)
		draw_colored_polygon(pts, Color(0.06, 0.07, 0.11, 0.9))
		draw_polyline(pts, Color(0.45, 0.6, 0.8, 0.35), 1.0, true)
	# a shooting star every few seconds: a streak that fades as it crosses
	if _shoot.t >= 0.0:
		_shoot.t += 1.0 / 60.0
		var k: float = _shoot.t / 0.7
		if k > 1.0:
			_shoot.t = -1.0
			_next_shoot = dt_total + _rng.randf_range(4.0, 9.0)
		else:
			var head := Vector2(_shoot.x + _shoot.dx * k, _shoot.y + _shoot.dy * k) * sz
			var tail := head - Vector2(_shoot.dx, _shoot.dy).normalized() * 70.0 * (1.0 - k * 0.5)
			var a2 := sin(k * PI)
			draw_line(tail, head, Color(0.8, 0.95, 1.0, 0.0 + 0.6 * a2), 1.5, true)
			draw_circle(head, 2.0, Color(1, 1, 1, a2))
	elif dt_total > _next_shoot:
		_shoot = {"t": 0.0, "x": _rng.randf_range(0.1, 0.7), "y": _rng.randf_range(0.05, 0.3), "dx": _rng.randf_range(0.2, 0.4), "dy": _rng.randf_range(0.15, 0.3)}
