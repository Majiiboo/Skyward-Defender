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

static func draw_turret(c: CanvasItem, base: Vector2, angle: float, t: float, recoil: float = 0.0) -> void:
	# A generic base-mounted gun: raised platform, armoured housing with a glowing
	# core, twin barrels on a pivot, and a status light. No fins or arcs above it.
	var dir := Vector2.from_angle(angle)
	var perp := Vector2(-dir.y, dir.x)
	c.draw_colored_polygon(PackedVector2Array([base + Vector2(-22, 12), base + Vector2(22, 12), base + Vector2(17, 2), base + Vector2(-17, 2)]), Color(0.06, 0.07, 0.13))
	c.draw_line(base + Vector2(-17, 2), base + Vector2(17, 2), Color(PURPLE, 0.45), 1.4, true)
	c.draw_rect(Rect2(base + Vector2(-7, -8), Vector2(14, 11)), Color(0.08, 0.09, 0.16))
	c.draw_line(base + Vector2(-7, -8), base + Vector2(7, -8), Color(CYAN, 0.3), 1.0, true)
	var pivot := base + Vector2(0, -11)
	c.draw_colored_polygon(PackedVector2Array([pivot + Vector2(-10, 6), pivot + Vector2(10, 6), pivot + Vector2(8, -7), pivot + Vector2(-8, -7)]), Color(0.11, 0.12, 0.20))
	c.draw_polyline(PackedVector2Array([pivot + Vector2(-10, 6), pivot + Vector2(-8, -7), pivot + Vector2(8, -7), pivot + Vector2(10, 6)]), Color(CYAN, 0.35), 1.2, true)
	c.draw_circle(pivot, 3.2, Color(PURPLE, 0.6 + 0.4 * sin(t * 4.0)))
	var back := dir * (-2.0 - recoil * 3.0)
	for s in [-1.0, 1.0]:
		var o: Vector2 = perp * float(s) * 2.8 + back
		c.draw_line(pivot + o, pivot + o + dir * 18.0, Color(0.10, 0.10, 0.17), 4.0, true)
		c.draw_line(pivot + o + dir * 12.0, pivot + o + dir * 18.0, Color(PURPLE, 0.9), 2.2, true)
	c.draw_line(pivot + dir * 5.0 - perp * 5.0, pivot + dir * 5.0 + perp * 5.0, Color(0.16, 0.16, 0.26), 2.0, true)
	c.draw_circle(base + Vector2(14, 7), 1.5, Color(0.3, 1.0, 0.5, 0.6 + 0.4 * sin(t * 2.0)))

static func draw_base(c: CanvasItem, centre: Vector2, t: float, elite: bool = false) -> void:
	# The home base: a low command dome on a plinth with a mast, between the turrets.
	var col := PURPLE if elite else CYAN
	c.draw_colored_polygon(PackedVector2Array([centre + Vector2(-46, 10), centre + Vector2(46, 10), centre + Vector2(40, 0), centre + Vector2(-40, 0)]), Color(0.05, 0.06, 0.12))
	c.draw_line(centre + Vector2(-40, 0), centre + Vector2(40, 0), Color(col, 0.35), 1.2, true)
	c.draw_rect(Rect2(centre + Vector2(-30, -10), Vector2(60, 10)), Color(0.07, 0.08, 0.15))
	var pts := PackedVector2Array()
	for i in 17:
		var a := PI + PI * float(i) / 16.0
		pts.append(centre + Vector2(cos(a) * 22.0, -10.0 + sin(a) * 16.0))
	var dome := PackedVector2Array(pts)
	dome.append(centre + Vector2(22, -10))
	c.draw_colored_polygon(dome, Color(0.09, 0.10, 0.19))
	c.draw_polyline(pts, Color(col, 0.6), 1.4, true)
	c.draw_line(centre + Vector2(-16, -16), centre + Vector2(16, -16), Color(col, 0.5), 2.0, true)
	c.draw_circle(centre + Vector2(0, -19), 2.5, Color(col, 0.5 + 0.5 * sin(t * 3.0)))
	c.draw_line(centre + Vector2(0, -26), centre + Vector2(0, -42), Color(0.35, 0.38, 0.5), 1.4, true)
	c.draw_circle(centre + Vector2(0, -43), 1.8, Color(1.0, 0.35, 0.42, 0.9 if fmod(t, 1.2) < 0.25 else 0.25))
	for s in [-1.0, 1.0]:
		var hx: float = float(s) * 29.0
		c.draw_rect(Rect2(centre + Vector2(hx - 5, -8), Vector2(10, 7)), Color(0.04, 0.05, 0.1))
		c.draw_line(centre + Vector2(hx - 4, -3), centre + Vector2(hx + 4, -3), Color(col, 0.35), 1.0, true)


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


static func draw_deck(c: CanvasItem, width: float, ground_y: float, deck_h: float, mounts: Array, t: float, elite: bool = false) -> void:
	# A raised deck across the base with a platform at each turret mount, so the
	# player can see where the four turrets sit even when empty.
	var col := PURPLE if elite else CYAN
	var top := ground_y - deck_h
	c.draw_colored_polygon(PackedVector2Array([Vector2(width * 0.06, ground_y), Vector2(width * 0.94, ground_y), Vector2(width * 0.90, top), Vector2(width * 0.10, top)]), Color(0.05, 0.06, 0.12))
	c.draw_line(Vector2(width * 0.10, top), Vector2(width * 0.90, top), Color(col, 0.35), 1.2, true)
	for i in mounts.size():
		var x: float = width * float(mounts[i])
		var p := Vector2(x, top)
		c.draw_colored_polygon(PackedVector2Array([p + Vector2(-20, 0), p + Vector2(20, 0), p + Vector2(16, -6), p + Vector2(-16, -6)]), Color(0.08, 0.09, 0.16))
		c.draw_line(p + Vector2(-16, -6), p + Vector2(16, -6), Color(col, 0.45), 1.2, true)
		c.draw_circle(p + Vector2(0, -3), 2.0, Color(col, 0.4 + 0.3 * sin(t * 2.0 + i)))
		c.draw_string(ThemeDB.fallback_font, p + Vector2(-4, -9), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(col, 0.5))
