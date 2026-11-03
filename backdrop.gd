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
const STRIP_SOCKETS := [Vector2(0.144, 0.53), Vector2(0.297, 0.524), Vector2(0.701, 0.523), Vector2(0.857, 0.533)]
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
	c.draw_texture_rect(_strip, strip_rect(width, bottom_y), false)

# The lit sockets: Luna's ring glow, drawn as added light on a layer with additive
# blending. lit[i] (0..1) fades socket i's glow in.
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

static func draw_sky(c: CanvasItem, size: Vector2, elite: bool, stars: Array, t: float) -> void:
	var top_col := Color(0.10, 0.05, 0.24) if elite else Color(0.04, 0.07, 0.20)
	var bot_col := Color(0.012, 0.016, 0.045)
	c.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]),
		PackedColorArray([top_col, top_col, bot_col, bot_col]))
	var glow := Color(0.45, 0.2, 0.9, 0.16) if elite else Color(0.1, 0.4, 0.8, 0.14)
	soft_glow(c, Vector2(size.x * 0.2, size.y * 0.28), 190.0, glow)
	soft_glow(c, Vector2(size.x * 0.85, size.y * 0.5), 210.0, Color(glow, glow.a * 0.9))
	for st in stars:
		var y := fmod(st.y + t * 0.012 * st.z, 1.0)
		c.draw_circle(Vector2(st.x * size.x, y * size.y), st.z * 0.8, Color(1, 1, 1, 0.45))

static func draw_sky_palette(c: CanvasItem, size: Vector2, stars: Array, t: float, top_col: Color, bot_col: Color, glow_col: Color) -> void:
	c.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]),
		PackedColorArray([top_col, top_col, bot_col, bot_col]))
	soft_glow(c, Vector2(size.x * 0.2, size.y * 0.28), 190.0, Color(glow_col, 0.14))
	soft_glow(c, Vector2(size.x * 0.85, size.y * 0.5), 210.0, Color(glow_col, 0.12))
	for st in stars:
		var y := fmod(st.y + t * 0.012 * st.z, 1.0)
		c.draw_circle(Vector2(st.x * size.x, y * size.y), st.z * 0.8, Color(1, 1, 1, 0.45))

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
