class_name Backdrop
extends RefCounted
# Scenery drawing shared by the Home wallpaper and the battle screen, so both
# look like the same world. Every function draws onto the CanvasItem you pass.
#
# A "scene" dictionary holds the few numbers that differ per screen:
#   size (Vector2), horizon_y (float), elite (bool), t (float, time)
# Build a city once with make_city() and keep it; it holds the random buildings.

const CYAN := Color(0.18, 0.9, 1.0)
const PURPLE := Color(0.71, 0.55, 1.0)

# ---- Luna's base strip (base/base_strip.png, cut by tools/cut_battle_art.gd) ----
# Socket ring centres as fractions of the strip picture (x across, y down).
# socket ring centres measured on the painted strip (dev109; sockets 1/4 and 2/3 mirror each other)
const STRIP_SOCKETS := [Vector2(0.128, 0.565), Vector2(0.284, 0.565), Vector2(0.714, 0.565), Vector2(0.871, 0.565)]
static var _strip: Texture2D
static var _strip_glow: Texture2D

static func strip_rect(width: float, bottom_y: float) -> Rect2:
	if _strip == null:
		_strip = load("res://base/base_strip.png")
		_strip_glow = load("res://base/base_strip_glow.png")
	var h: float = width * _strip.get_height() / _strip.get_width()
	return Rect2(0.0, bottom_y - h, width, h)

# Where socket i's ring centre is on screen for a strip of this width.
static func socket_pos(i: int, width: float, bottom_y: float) -> Vector2:
	var r := strip_rect(width, bottom_y)
	var s: Vector2 = STRIP_SOCKETS[i]
	return r.position + Vector2(s.x * r.size.x, s.y * r.size.y)

static func draw_strip(c: CanvasItem, width: float, bottom_y: float) -> void:
	var r := strip_rect(width, bottom_y)   # loads _strip on first use, so before it is read
	c.draw_texture_rect(_strip, r, false)
	draw_dome(c, r)

# ---- the command dome as its own piece (Home round 2, dev199; base/dome_<kind>_<n>.png from
# tools/cut_home2.gd): drawn over the painted dome in the same place. kind = "standard", or a
# super weapon ("beam", "shield", "emp") with frame 1 idle / 2 charging / 3 firing (queue item
# 10, the super weapons, sets these). Every dome picture shares one canvas (the union of them),
# and the standard dome sits at DOME_IN_CANVAS inside it; on the strip the standard dome fills
# STRIP_DOME (fractions of the strip rect; y may rise above it).
const STRIP_DOME := Rect2(0.427, 0.0, 0.146, 0.85)
const DOME_IN_CANVAS := Rect2(0.0106, 0.1801, 0.9815, 0.8121)
static var dome_kind := "standard"
static var dome_frame := 1
static var _domes := {}

static func dome_tex(kind: String, frame: int) -> Texture2D:
	var name := "standard" if kind == "standard" else "%s_%d" % [kind, clampi(frame, 1, 3)]
	if not _domes.has(name):
		var p := "res://base/dome_%s.png" % name
		_domes[name] = load(p) if ResourceLoader.exists(p) else null
	return _domes[name]

static func draw_dome(c: CanvasItem, strip: Rect2, alpha: float = 1.0) -> void:
	var tex := dome_tex(dome_kind, dome_frame)
	if tex == null:
		return
	# the canvas rect on screen: the standard dome's rect scaled out by its share of the canvas
	var sw: float = STRIP_DOME.size.x * strip.size.x / DOME_IN_CANVAS.size.x
	var sh: float = STRIP_DOME.size.y * strip.size.y / DOME_IN_CANVAS.size.y
	var sx: float = strip.position.x + STRIP_DOME.position.x * strip.size.x - DOME_IN_CANVAS.position.x * sw
	var sy: float = strip.position.y + STRIP_DOME.position.y * strip.size.y - DOME_IN_CANVAS.position.y * sh
	c.draw_texture_rect(tex, Rect2(sx, sy, sw, sh), false, Color(1, 1, 1, alpha))

# The socket's front lip (dev149, Rudy: turrets looked like a layer on a layer). The lower
# half of the socket ring, cut from Luna's strip, drawn again OVER a mounted turret's foot,
# so the turret sits down inside the ring instead of on top of it. Fractions of the strip's
# width and height around the socket centre.
const SOCKET_LIP := Rect2(-0.074, 0.012, 0.148, 0.080)

static func draw_socket_lip(c: CanvasItem, i: int, width: float, bottom_y: float, alpha: float = 1.0) -> void:
	var r := strip_rect(width, bottom_y)
	var s: Vector2 = STRIP_SOCKETS[i]
	var tw := float(_strip.get_width())
	var th := float(_strip.get_height())
	var src := Rect2((s.x + SOCKET_LIP.position.x) * tw, (s.y + SOCKET_LIP.position.y) * th, SOCKET_LIP.size.x * tw, SOCKET_LIP.size.y * th)
	var dst := Rect2(r.position + Vector2((s.x + SOCKET_LIP.position.x) * r.size.x, (s.y + SOCKET_LIP.position.y) * r.size.y), Vector2(SOCKET_LIP.size.x * r.size.x, SOCKET_LIP.size.y * r.size.y))
	c.draw_texture_rect_region(_strip, dst, src, Color(1, 1, 1, alpha))

# a soft dark pool under a turret's foot (contact shadow), scaled to the strip
static func draw_socket_shadow(c: CanvasItem, i: int, width: float, bottom_y: float, alpha: float = 0.5) -> void:
	var p := socket_pos(i, width, bottom_y)
	var rx := width * 0.075
	c.draw_set_transform(p + Vector2(0, width * 0.006), 0.0, Vector2(1.0, 0.34))
	for k in 3:
		c.draw_circle(Vector2.ZERO, rx * (1.0 - 0.25 * k), Color(0, 0, 0, alpha * 0.33))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# Lights painted on the command dome, in pixels of base/base_strip.png (1400 x 235):
# the ring of window lights left to right, the two upper lamps, the antenna tip and
# the dish's emitter. draw_base_lights brings them to life: a slow light chase round
# the ring, the lamps breathing, the antenna blinking red, the dish sending a ping.
const DOME_LIGHTS := [Vector2(609.5, 136.3), Vector2(623.8, 150.0), Vector2(633.8, 155.0), Vector2(644.5, 159.3),
	Vector2(659.5, 163.8), Vector2(671.8, 166.3), Vector2(727.0, 166.3), Vector2(739.3, 164.3), Vector2(754.3, 160.0),
	Vector2(764.3, 155.0), Vector2(773.8, 150.0), Vector2(788.0, 136.3)]
const DOME_LAMPS := [Vector2(636.3, 98.8), Vector2(761.8, 98.8)]
const ANTENNA_TIP := Vector2(699.5, 3.8)
const DISH_EMITTER := Vector2(743.8, 46.3)

static func draw_base_lights(c: CanvasItem, width: float, bottom_y: float, t: float) -> void:
	var r := strip_rect(width, bottom_y)
	var k: float = r.size.x / 1400.0
	var warm := Color(1.0, 0.85, 0.55)
	var n := DOME_LIGHTS.size()
	# a soft bright spot runs round the ring and back every 4 s
	var run := (0.5 - 0.5 * cos(t * TAU / 4.0)) * float(n - 1)
	for i in n:
		var p: Vector2 = r.position + DOME_LIGHTS[i] * k
		var a := exp(-pow(float(i) - run, 2.0) / 1.6)
		c.draw_circle(p, 5.0 * k * 3.0, Color(warm, 0.10 + 0.25 * a))
		c.draw_circle(p, 2.2 * k * 3.0, Color(1, 0.95, 0.85, 0.15 + 0.6 * a))
	for i in 2:
		var p: Vector2 = r.position + DOME_LAMPS[i] * k
		c.draw_circle(p, 4.0 * k * 3.0, Color(warm, 0.12 + 0.12 * sin(t * 1.7 + i * 2.0)))
	# antenna: a short red blink every 1.6 s
	var blink := smoothstep(0.25, 0.0, fposmod(t, 1.6))
	var tip: Vector2 = r.position + ANTENNA_TIP * k
	c.draw_circle(tip, 6.0 * k * 3.0 * (0.6 + 0.4 * blink), Color(1.0, 0.25, 0.3, 0.12 + 0.3 * blink))
	c.draw_circle(tip, 1.8 * k * 3.0, Color(1.0, 0.5, 0.5, 0.35 + 0.65 * blink))
	# dish: a cyan ping ring every 3 s
	var dish: Vector2 = r.position + DISH_EMITTER * k
	var ph := fposmod(t, 3.0) / 1.2
	if ph < 1.0:
		c.draw_arc(dish, (2.0 + 22.0 * ph) * k * 3.0, 0.0, TAU, 24, Color(0.18, 0.9, 1.0, 0.5 * (1.0 - ph)), 1.0, true)
	c.draw_circle(dish, 1.6 * k * 3.0, Color(0.6, 1.0, 1.0, 0.4 + 0.4 * smoothstep(0.3, 0.0, ph)))

# The lit sockets: Luna's ring glow, drawn as added light on a layer with additive
# blending. lit[i] (0..1) fades socket i's glow in.
# A locked mount: Luna's closed armoured hatch over the socket (battle.gd animates it
# opening; Home just shows it).
static var _lid: Texture2D
static func draw_socket_lock(c: CanvasItem, i: int, width: float, bottom_y: float) -> void:
	if _lid == null:
		_lid = load("res://base/lid_closed.png")
	var p := socket_pos(i, width, bottom_y)
	var w := 52.0 * width / 480.0
	var h: float = w * _lid.get_height() / _lid.get_width()
	c.draw_texture_rect(_lid, Rect2(p.x - w * 0.5, p.y - 1.0 - h * 0.5, w, h), false)

static func draw_socket_glow(c: CanvasItem, width: float, bottom_y: float, lit: Array) -> void:
	var r := strip_rect(width, bottom_y)
	var tw: float = _strip_glow.get_width()
	var th: float = _strip_glow.get_height()
	for i in mini(lit.size(), STRIP_SOCKETS.size()):
		var a: float = float(lit[i])
		if a < 0.01:
			continue
		var s: Vector2 = STRIP_SOCKETS[i]
		var src := Rect2((s.x - 0.08) * tw, (s.y - 0.32) * th, 0.16 * tw, 0.64 * th)
		var dst := Rect2(r.position + Vector2(src.position.x / tw * r.size.x, src.position.y / th * r.size.y),
			Vector2(src.size.x / tw * r.size.x, src.size.y / th * r.size.y))
		c.draw_texture_rect_region(_strip_glow, dst, src, Color(1, 1, 1, a))

static func make_city(count: int = 46, seed_value: int = 7) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var city: Array = []
	for i in count:
		city.append({"x": rng.randf(), "h": rng.randf_range(6.0, 30.0), "w": rng.randf_range(6.0, 16.0),
			"ph": rng.randf() * TAU, "kind": rng.randi() % 4, "lit": rng.randf()})
	return city

static func make_stars(count: int = 80, seed_value: int = 3) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var stars: Array = []
	for i in count:
		stars.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(0.6, 1.8)))
	return stars

static func planet_radius(size: Vector2) -> float:
	return size.x * 1.35

static func limb_y(size: Vector2, horizon_y: float, x: float) -> float:
	# Height of the planet's curved edge at screen x.
	var pr := planet_radius(size)
	var dx := x - size.x * 0.5
	return horizon_y + pr - sqrt(maxf(pr * pr - dx * dx, 0.0))

static func shield_y(size: Vector2, horizon_y: float, x: float, lift: float = 44.0) -> float:
	var u := (x - size.x * 0.5) / (size.x * 0.5)
	return horizon_y - lift * (1.0 - u * u)

static func soft_glow(c: CanvasItem, centre: Vector2, radius: float, col: Color) -> void:
	for i in 14:
		var t := float(i) / 13.0
		c.draw_circle(centre, lerpf(radius, radius * 0.12, t), Color(col, col.a * 0.16))

static func draw_sky(c: CanvasItem, size: Vector2, elite: bool, stars: Array, t: float, shift: float = 0.0) -> void:
	var top_col := Color(0.10, 0.05, 0.24) if elite else Color(0.04, 0.07, 0.20)
	var bot_col := Color(0.012, 0.016, 0.045)
	var glow := Color(0.45, 0.2, 0.9) if elite else Color(0.1, 0.4, 0.8)
	draw_sky_palette(c, size, stars, t, top_col, bot_col, glow, shift)

# The sky until Luna's painted layers arrive (LUNA-BRIEF-backgrounds.md). Depth comes from
# motion: stars in three depths (far = small, slow, dim; near = bigger, faster),
# twinkling, nebula clouds that drift and breathe, the odd shooting star, and a little
# parallax: `shift` (-0.5..0.5, where the pilot is across the screen) slides near
# layers more than far ones.
static func draw_sky_palette(c: CanvasItem, size: Vector2, stars: Array, t: float, top_col: Color, bot_col: Color, glow_col: Color, shift: float = 0.0) -> void:
	c.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]),
		PackedColorArray([top_col, top_col, bot_col, bot_col]))
	# nebula: three soft clouds on slow loops, the third a cooler tint
	var n1 := Vector2(size.x * (0.2 + 0.05 * sin(t * 0.031)), size.y * (0.28 + 0.03 * sin(t * 0.023 + 1.0))) - Vector2(shift * 10.0, 0)
	var n2 := Vector2(size.x * (0.85 + 0.04 * sin(t * 0.027 + 2.0)), size.y * (0.5 + 0.04 * cos(t * 0.019))) - Vector2(shift * 10.0, 0)
	var n3 := Vector2(size.x * (0.6 + 0.06 * cos(t * 0.017 + 0.5)), size.y * (0.12 + 0.03 * sin(t * 0.029))) - Vector2(shift * 7.0, 0)
	soft_glow(c, n1, 190.0 * (1.0 + 0.06 * sin(t * 0.11)), Color(glow_col, 0.14))
	soft_glow(c, n2, 210.0 * (1.0 + 0.06 * sin(t * 0.09 + 1.3)), Color(glow_col, 0.12))
	soft_glow(c, n3, 150.0, Color(glow_col.lerp(Color(0.5, 0.3, 1.0), 0.5), 0.08))
	draw_sky_extras(c, size, stars, t, shift, 1.0)

# Stars in three depths (twinkling, parallax) and the odd shooting star. Drawn over the
# code sky, and faintly over Luna's painted worlds so they still sparkle.
static func draw_sky_extras(c: CanvasItem, size: Vector2, stars: Array, t: float, shift: float, strength: float) -> void:
	# stars: z (0.6..1.8) is depth
	for st in stars:
		var z: float = st.z
		var d: float = (z - 0.6) / 1.2                      # 0 far .. 1 near
		var y := fmod(st.y + t * 0.004 * (1.0 + d * 5.0), 1.0)
		var x := fposmod(st.x * size.x - shift * (3.0 + d * 16.0), size.x)
		var tw := 0.75 + 0.25 * sin(t * (1.3 + d * 2.0) + st.x * 61.0)
		var a := lerpf(0.25, 0.7, d) * tw * strength
		if strength < 1.0 and d < 0.5:
			continue   # over a painting only the nearer stars show
		var col := Color(0.8, 0.9, 1.0, a) if d > 0.7 else Color(1, 1, 1, a)
		c.draw_circle(Vector2(x, y * size.y), lerpf(0.5, 1.4, d), col)
	# a shooting star every ~9 s, somewhere across the top half
	var slot := floorf(t / 9.0)
	var ph := (t - slot * 9.0) / 0.8
	if ph < 1.0:
		var hx := fposmod(sin(slot * 12.9898) * 43758.5453, 1.0)
		var hy := fposmod(sin(slot * 78.233) * 12345.678, 1.0)
		var dir := Vector2(-1.0 if hx > 0.5 else 1.0, 0.45).normalized()
		var p0 := Vector2(size.x * (0.2 + 0.6 * hx), size.y * (0.08 + 0.3 * hy))
		var head := p0 + dir * ph * 170.0
		var fade := sin(ph * PI)
		c.draw_line(head - dir * 46.0, head, Color(0.8, 0.9, 1.0, 0.0), 1.0, true)
		c.draw_line(head - dir * 26.0, head, Color(0.85, 0.95, 1.0, 0.55 * fade * strength), 1.2, true)
		c.draw_circle(head, 1.3, Color(1, 1, 1, 0.9 * fade * strength))

# Luna's painted world for an area (backdrops/<key>.webp), covering the screen with its
# bottom edge at bottom_y (the base strip sits on its ground). It is a little wider than
# the screen and slides slightly opposite the pilot (shift -0.5..0.5) for depth, and
# breathes very slowly so the sky never looks frozen.
static var _worlds := {}

# ---- Luna's LAYERED skies (Home round 2, dev199; tools/cut_home2.gd): skies/<planet>_stars
# (loops), _clouds (alpha from light), _planet, _glow (pulsing) and up to eight _float_N
# pieces that drift past. Parallax: the stars slide slowest, the clouds a little more, the
# floaters most; everything leans opposite the pilot (shift). draw_world uses them when they
# exist for the world's planet, else the flat painting.
const PLANET_OF := {"hive_a": "hive", "hive_b": "hive", "scrap": "scrap", "magma": "magma", "crystal": "crystal", "plasma": "plasma", "sentinel": "sentinel"}
static var _sky_tex := {}
static var _sky_has := {}

static func planet_of(key: String) -> String:
	return String(PLANET_OF.get(key, key))

static func has_sky_layers(key: String) -> bool:
	var p := planet_of(key)
	if not _sky_has.has(p):
		_sky_has[p] = ResourceLoader.exists("res://skies/%s_stars.webp" % p) and ResourceLoader.exists("res://skies/%s_planet.webp" % p)
	return _sky_has[p]

static func _sky(name: String) -> Texture2D:
	if not _sky_tex.has(name):
		var path := "res://skies/%s" % name
		_sky_tex[name] = load(path) if ResourceLoader.exists(path) else null
	return _sky_tex[name]

# the floaters' lanes: eight pieces, each on its own slow path across the sky (a sine on x,
# a crawl on y), the big one (cell 3) far and slow, the ship (cell 4) fast and small
const FLOAT_LANES := [
	{"y": 0.14, "spd": 0.012, "px": 44.0, "spin": 0.10, "phase": 0.0},
	{"y": 0.30, "spd": 0.016, "px": 36.0, "spin": -0.14, "phase": 2.1},
	{"y": 0.08, "spd": 0.010, "px": 40.0, "spin": 0.08, "phase": 4.0},
	{"y": 0.22, "spd": 0.005, "px": 96.0, "spin": 0.02, "phase": 1.2},
	{"y": 0.18, "spd": 0.040, "px": 30.0, "spin": 0.0, "phase": 3.3},
	{"y": 0.36, "spd": 0.020, "px": 20.0, "spin": 0.3, "phase": 0.7},
	{"y": 0.12, "spd": 0.024, "px": 18.0, "spin": -0.25, "phase": 5.0},
	{"y": 0.42, "spd": 0.018, "px": 22.0, "spin": 0.2, "phase": 2.8},
]

static func draw_sky_layers(c: CanvasItem, size: Vector2, bottom_y: float, key: String, t: float, shift: float = 0.0, alpha: float = 1.0) -> void:
	var p := planet_of(key)
	var stars: Texture2D = _sky(p + "_stars.webp")
	var clouds: Texture2D = _sky(p + "_clouds.webp")
	var planet: Texture2D = _sky(p + "_planet.webp")
	var glow: Texture2D = _sky(p + "_glow.webp")
	if alpha >= 1.0:
		c.draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.012, 0.03))
	var col := Color(1, 1, 1, alpha)
	# the far stars: a little wider than the screen, looping downward very slowly
	var w: float = size.x * 1.12
	var h: float = w * stars.get_height() / stars.get_width()
	var x0: float = (size.x - w) * 0.5 - shift * size.x * 0.02
	var y0: float = fmod(t * 3.0, h)
	c.draw_texture_rect(stars, Rect2(x0, y0 - h, w, h), false, col)
	c.draw_texture_rect(stars, Rect2(x0, y0, w, h), false, col)
	if clouds != null:
		# the nebula: wider still, a touch faster, leaning more with the pilot
		var cw: float = size.x * 1.22
		var chh: float = cw * clouds.get_height() / clouds.get_width()
		var cx: float = (size.x - cw) * 0.5 - shift * size.x * 0.05
		var cy: float = fmod(t * 5.5, chh)
		var ccol := Color(1, 1, 1, 0.92 * alpha)
		c.draw_texture_rect(clouds, Rect2(cx, cy - chh, cw, chh), false, ccol)
		c.draw_texture_rect(clouds, Rect2(cx, cy, cw, chh), false, ccol)
	# the floaters, behind the planet (they pass behind the horizon)
	for i in FLOAT_LANES.size():
		var ft: Texture2D = _sky("%s_float_%d.png" % [p, i])
		if ft == null:
			continue
		var lane: Dictionary = FLOAT_LANES[i]
		var k: float = fposmod(t * float(lane.spd) + float(lane.phase) * 0.17, 1.0)   # 0..1 across
		var fx: float = lerpf(-0.12, 1.12, k) * size.x - shift * size.x * (0.08 if float(lane.px) < 60.0 else 0.03)
		var fy: float = (float(lane.y) + 0.03 * sin(t * 0.23 + float(lane.phase))) * size.y
		var px: float = float(lane.px) * size.x / 480.0
		var fs: Vector2 = ft.get_size() * (px / maxf(ft.get_width(), ft.get_height()))
		c.draw_set_transform(Vector2(fx, fy), t * float(lane.spin) + float(lane.phase), Vector2.ONE)
		c.draw_texture_rect(ft, Rect2(-fs * 0.5, fs), false, Color(1, 1, 1, alpha * (0.85 if float(lane.px) < 60.0 else 0.7)))
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# the planet along the bottom, breathing very slowly, and its atmosphere rim pulsing
	var zoom := 1.0 + 0.012 * sin(t * 0.07)
	var pw: float = size.x * 1.1 * zoom
	var ph: float = pw * planet.get_height() / planet.get_width()
	var prect := Rect2((size.x - pw) * 0.5 - shift * size.x * 0.04, bottom_y + 10.0 - ph, pw, ph)
	c.draw_texture_rect(planet, prect, false, col)
	if glow != null:
		c.draw_texture_rect(glow, prect, false, Color(1, 1, 1, alpha * (0.55 + 0.35 * (0.5 + 0.5 * sin(t * 0.8)))))
static func draw_world(c: CanvasItem, size: Vector2, bottom_y: float, key: String, stars: Array, t: float, shift: float = 0.0, alpha: float = 1.0) -> void:
	if has_sky_layers(key):   # Luna's layered sky when it exists (Home round 2)
		draw_sky_layers(c, size, bottom_y, key, t, shift, alpha)
		draw_sky_extras(c, size, stars, t, shift, 0.35 * alpha)
		return
	if not _worlds.has(key):
		_worlds[key] = load("res://backdrops/%s.webp" % key)
	var tex: Texture2D = _worlds[key]
	var aspect: float = tex.get_width() / float(tex.get_height())
	var zoom := 1.0 + 0.012 * sin(t * 0.07)
	var w := maxf(size.x * 1.08, (bottom_y + 10.0) * aspect) * zoom
	var h := w / aspect
	var x := (size.x - w) * 0.5 - shift * size.x * 0.04
	if alpha >= 1.0:
		c.draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.012, 0.03))
	c.draw_texture_rect(tex, Rect2(x, bottom_y + 10.0 - h, w, h), false, Color(1, 1, 1, alpha))
	draw_sky_extras(c, size, stars, t, shift, 0.6 * alpha)

static func draw_horizon(c: CanvasItem, size: Vector2, horizon_y: float, elite: bool, city: Array, t: float, rim_in: Color = Color(0, 0, 0, 0)) -> void:
	var pr := planet_radius(size)
	var cx := size.x * 0.5
	var centre := Vector2(cx, horizon_y + pr)
	var rim := Color(0.45, 0.2, 0.9, 0.5) if elite else Color(0.15, 0.55, 0.95, 0.5)
	if rim_in.a > 0.0:
		rim = Color(rim_in, 0.5)
	# the planet: a huge dark disc with a lit edge
	c.draw_circle(centre, pr, Color(0.015, 0.02, 0.05))
	c.draw_arc(centre, pr, PI * 1.18, PI * 1.82, 48, Color(rim, 0.07), 14.0, true)
	c.draw_arc(centre, pr, PI * 1.18, PI * 1.82, 48, Color(rim, 0.22), 5.0, true)
	c.draw_arc(centre, pr, PI * 1.18, PI * 1.82, 48, rim, 1.6, true)
	# skyline: towers, spires and domes standing on the curve, with lit windows
	for b in city:
		var x: float = b.x * size.x
		var y := limb_y(size, horizon_y, x)
		var w: float = b.w
		var h: float = b.h
		var body := Color(0.035, 0.05, 0.11)
		match int(b.kind):
			0:  # block tower
				c.draw_rect(Rect2(x - w * 0.5, y - h, w, h + 3.0), body)
			1:  # stepped tower
				c.draw_rect(Rect2(x - w * 0.5, y - h * 0.6, w, h * 0.6 + 3.0), body)
				c.draw_rect(Rect2(x - w * 0.3, y - h, w * 0.6, h), body)
			2:  # spire
				c.draw_rect(Rect2(x - w * 0.5, y - h * 0.5, w, h * 0.5 + 3.0), body)
				c.draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.5, y - h * 0.5), Vector2(x + w * 0.5, y - h * 0.5), Vector2(x, y - h * 1.3)]), body)
				c.draw_circle(Vector2(x, y - h * 1.3), 1.4, Color(1.0, 0.35, 0.42, 0.5 + 0.5 * sin(t * 2.0 + b.ph)))
			3:  # dome
				c.draw_rect(Rect2(x - w * 0.5, y - h * 0.5, w, h * 0.5 + 3.0), body)
				c.draw_circle(Vector2(x, y - h * 0.5), w * 0.5, body)
		c.draw_line(Vector2(x - w * 0.5, y - h * (0.5 if int(b.kind) > 1 else 1.0)), Vector2(x + w * 0.5, y - h * (0.5 if int(b.kind) > 1 else 1.0)), Color(rim, 0.3), 1.2)
		if sin(t * 0.5 + b.ph * 3.0) > -0.2:
			var rows := int(h / 6.0)
			for r in rows:
				if fmod(b.lit * 7.0 + float(r) * 1.7, 1.0) < 0.55:
					c.draw_rect(Rect2(x - 1.0, y - h + 3.0 + r * 6.0, 2.0, 2.0), Color(1.0, 0.85, 0.5, 0.6))

static func draw_shield(c: CanvasItem, size: Vector2, horizon_y: float, elite: bool, strength: float = 1.0, lift: float = 44.0) -> void:
	var pts := PackedVector2Array()
	var x := 0.0
	while x <= size.x + 12.0:
		pts.append(Vector2(x, shield_y(size, horizon_y, x, lift)))
		x += 12.0
	var col := PURPLE if elite else CYAN
	c.draw_polyline(pts, Color(col, 0.06 * strength), 12.0, true)
	c.draw_polyline(pts, Color(col, 0.14 * strength), 5.0, true)
	c.draw_polyline(pts, Color(col, 0.2 + 0.3 * strength), 1.6, true)

static func _ell_pts(centre: Vector2, rx: float, ry: float, a0: float, a1: float, steps: int = 40) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(steps + 1):
		var a := lerpf(a0, a1, float(i) / steps)
		pts.append(centre + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

static func inside_field(centre: Vector2, rx: float, ry: float, p: Vector2) -> bool:
	var dx := (p.x - centre.x) / rx
	var dy := (p.y - centre.y) / ry
	return dx * dx + dy * dy <= 1.0

static func draw_force_field(c: CanvasItem, centre: Vector2, rx: float, ry: float, shield: float, hull: float, t: float, elite: bool = false, hit_t: float = 0.0) -> void:
	# The base's force field: a wide translucent dome (half ellipse rx by ry) with
	# a hex lattice, an outer arc that shortens as the shield drains (symmetric
	# from the top) and an inner warm arc for the hull. shield/hull are 0..1.
	var col := PURPLE if elite else CYAN
	if shield > 0.0:
		var fill := _ell_pts(centre, rx, ry, PI, TAU)
		c.draw_colored_polygon(fill, Color(col, 0.05 + 0.05 * shield))
		var hs := 15.0
		var row := 0
		var y := centre.y - ry + 6.0
		while y < centre.y:
			var x := centre.x - rx + (hs * 0.75 if row % 2 == 1 else 0.0)
			while x < centre.x + rx:
				var p := Vector2(x, y)
				if inside_field(centre, rx - 7.0, ry - 7.0, p):
					var hexa := PackedVector2Array()
					for k in 7:
						var ang := TAU * float(k) / 6.0
						hexa.append(p + Vector2(cos(ang), sin(ang)) * hs * 0.5)
					var shimmer := 0.06 + 0.05 * sin(t * 2.0 + x * 0.05 + y * 0.03)
					c.draw_polyline(hexa, Color(col, shimmer * (0.4 + 0.6 * shield)), 1.0, true)
				x += hs * 1.5
			y += hs * 0.5
			row += 1
	c.draw_polyline(_ell_pts(centre, rx, ry, PI, TAU), Color(col, 0.12), 1.0, true)
	var half := PI * 0.5 * shield
	if shield > 0.0:
		var arc := _ell_pts(centre, rx, ry, -PI / 2.0 - half, -PI / 2.0 + half)
		c.draw_polyline(arc, Color(col, 0.10), 14.0, true)
		c.draw_polyline(arc, Color(col, 0.25), 6.0, true)
		c.draw_polyline(arc, Color(col, 0.95), 2.2, true)
	var hhalf := PI * 0.5 * hull
	c.draw_polyline(_ell_pts(centre, rx - 10.0, ry - 10.0, PI, TAU), Color(1.0, 0.55, 0.25, 0.12), 1.0, true)
	if hull > 0.0:
		c.draw_polyline(_ell_pts(centre, rx - 10.0, ry - 10.0, -PI / 2.0 - hhalf, -PI / 2.0 + hhalf), Color(1.0, 0.55, 0.25, 0.9), 2.0, true)
	if hit_t >= 0.0 and hit_t < 0.5:
		var k := hit_t / 0.5
		c.draw_polyline(_ell_pts(centre, rx * (1.0 + 0.08 * k), ry * (1.0 + 0.12 * k), PI, TAU), Color(1, 1, 1, (1.0 - k) * 0.5), 3.0, true)

# ---- THE CORE BASE (2026-11-10; Rudy picked "core and pods" over a skyline deck and a carrier hull).
# One core at the bottom centre, four round pods on arms around it, all under the force field. It
# takes the painted strip's place in the fight. Everything here is a STAND-IN drawn in code until
# Luna's pieces land (LUNA-BRIEF-base-core.md: base2_core + _core_light, base2_pod_1..3, base2_arm,
# nine b_<id> building pictures); the layout numbers stay, the shapes get swapped for her art.
# Offsets are from the field's centre point (width / 2, base_y), for a 480-wide screen.
const POD_OFFS := [Vector2(-175, -30), Vector2(-95, -66), Vector2(95, -66), Vector2(175, -30)]
const POD_R := 23.0
const CORE_R := 60.0
const CORE_EYE := Vector2(0, -16)   # the core's light, from the same centre point
const BASE_NAVY := Color(0.055, 0.09, 0.157)
const BASE_EDGE := Color(0.165, 0.24, 0.39)

static func pod_pos(i: int, width: float, base_y: float) -> Vector2:
	return Vector2(width * 0.5, base_y) + POD_OFFS[i] * (width / 480.0)

static func core_eye(width: float, base_y: float) -> Vector2:
	return Vector2(width * 0.5, base_y) + CORE_EYE * (width / 480.0)

# pods: one entry per slot {"open": bool, "col": Color, "tex": Texture2D or null, "level": int,
# "flash": 0..1}; an entry without "tex" is an empty slot. power = the shield's share (0 = the
# shield is down: the core turns amber and the pulses along the arms stop).
static func draw_core_base(c: CanvasItem, width: float, base_y: float, bottom_y: float, t: float, pods: Array, power: float) -> void:
	var k := width / 480.0
	var eye := core_eye(width, base_y)
	var live := power > 0.0
	var core_col := CYAN if live else Color(1.0, 0.55, 0.25)
	# arms first, so the core and the pods sit on their ends
	for i in mini(pods.size(), POD_OFFS.size()):
		var pd: Dictionary = pods[i]
		var p := pod_pos(i, width, base_y)
		var on: bool = bool(pd.get("open", false)) and pd.get("tex") != null
		c.draw_line(eye, p, BASE_NAVY, 7.0 * k, true)
		c.draw_line(eye, p, BASE_EDGE if not on else Color(Color(pd.col), 0.45), 1.5, true)
		if on and live:   # a bead of light runs from the core out to the pod
			var u := fposmod(t * 0.55 + i * 0.27, 1.0)
			c.draw_circle(eye.lerp(p, u), 2.2 * k, Color(Color(pd.col), 0.9 * sin(u * PI)))
	# the core: a low dome sunk into the bottom edge
	var dome := _ell_pts(Vector2(width * 0.5, bottom_y), CORE_R * k, CORE_R * k, PI, TAU, 36)
	c.draw_colored_polygon(dome, BASE_NAVY)
	c.draw_polyline(dome, BASE_EDGE, 1.5, true)
	c.draw_arc(Vector2(width * 0.5, bottom_y), CORE_R * k * 0.78, PI * 1.12, PI * 1.38, 12, Color(BASE_EDGE, 0.8), 1.2, true)
	c.draw_arc(Vector2(width * 0.5, bottom_y), CORE_R * k * 0.78, PI * 1.62, PI * 1.88, 12, Color(BASE_EDGE, 0.8), 1.2, true)
	var beat := 0.5 + 0.5 * sin(t * 2.4)
	c.draw_circle(eye, 21.0 * k, Color(0.027, 0.047, 0.094))
	c.draw_arc(eye, 21.0 * k, 0.0, TAU, 40, Color(core_col, 0.55 + 0.35 * beat), 1.6, true)
	c.draw_arc(eye, (21.0 + 5.0 * beat) * k, 0.0, TAU, 40, Color(core_col, 0.22 * (1.0 - beat)), 1.0, true)
	c.draw_circle(eye, (9.0 + 1.6 * beat) * k * (0.55 + 0.45 * clampf(power, 0.0, 1.0) if live else 0.7), core_col)
	c.draw_circle(eye, 3.6 * k, Color(1, 1, 1, 0.95))
	# the pods
	for i in mini(pods.size(), POD_OFFS.size()):
		var pd: Dictionary = pods[i]
		var p := pod_pos(i, width, base_y)
		var r := POD_R * k
		if not bool(pd.get("open", false)):   # a slot not opened yet: a dim, dashed ring
			c.draw_circle(p, r, Color(BASE_NAVY, 0.9))
			for s in 10:
				c.draw_arc(p, r, TAU * s / 10.0, TAU * (s + 0.55) / 10.0, 5, Color(0.45, 0.55, 0.72, 0.8), 1.3, true)
			continue
		c.draw_circle(p, r, BASE_NAVY)
		if pd.get("tex") == null:   # open, nothing built on it
			c.draw_arc(p, r, 0.0, TAU, 40, BASE_EDGE, 1.5, true)
			c.draw_line(p - Vector2(5 * k, 0), p + Vector2(5 * k, 0), BASE_EDGE, 1.5, true)
			c.draw_line(p - Vector2(0, 5 * k), p + Vector2(0, 5 * k), BASE_EDGE, 1.5, true)
			continue
		var col: Color = pd.col
		var fl: float = clampf(float(pd.get("flash", 0.0)), 0.0, 1.0)
		var lv: int = int(pd.get("level", 1))
		c.draw_circle(p, r - 4.0 * k, Color(0.027, 0.047, 0.094))
		c.draw_arc(p, r, 0.0, TAU, 40, col.lerp(Color.WHITE, fl), 2.0 + 1.5 * fl, true)
		if lv >= 5:    # four plates round the ring (the pod's second look)
			for s in 4:
				var a := TAU * s / 4.0 - PI / 4.0
				c.draw_arc(p, r + 4.0 * k, a - 0.28, a + 0.28, 8, Color(col, 0.9), 3.0 * k, true)
		if lv >= 10:   # a halo floating off it (the third look)
			c.draw_arc(p, r + 9.0 * k, t * 0.6, t * 0.6 + TAU * 0.8, 36, Color(col, 0.55), 1.2, true)
		if fl > 0.0:
			c.draw_arc(p, r + (4.0 + 14.0 * (1.0 - fl)) * k, 0.0, TAU, 40, Color(col, 0.7 * fl), 1.5, true)
		var tx: Texture2D = pd.tex
		var half := 13.0 * k * (1.0 + 0.12 * fl)
		c.draw_texture_rect(tx, Rect2(p - Vector2(half, half), Vector2(half, half) * 2.0), false)

# a dark wash under the force field so the core and pods read against a busy planet surface
static func draw_base_shade(c: CanvasItem, centre: Vector2, rx: float, ry: float) -> void:
	c.draw_colored_polygon(_ell_pts(centre, rx, ry, PI, TAU), Color(0.02, 0.04, 0.09, 0.5))
