class_name Glass
extends RefCounted
# The "Glass" look for the Home bars, side tiles and the Gear screen (Rudy picked it,
# 2026-11-03, from Luna's mockups): a see-through dark panel with a faint light tint,
# a thin sheen along the top edge and ONE thin border that shades from cyan on the
# left to purple on the right. No glow.

const CYAN := Color(0.18, 0.9, 1.0)
const PURPLE := Color(0.71, 0.55, 1.0)
const GOLD := Color(1.0, 0.8, 0.3)
const FILL := Color(0.035, 0.06, 0.14, 0.62)
const TINT := Color(0.55, 0.8, 1.0, 0.06)

# A rounded rectangle as a closed outline. radii = [top-left, top-right, bottom-right,
# bottom-left]; a radius of 0 gives a square corner (panels flush with a screen edge).
static func rounded(r: Rect2, radii: Array, steps: int = 6) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners := [
		[Vector2(r.position.x, r.position.y), PI, 1.5 * PI, Vector2(1, 1)],
		[Vector2(r.end.x, r.position.y), 1.5 * PI, 2.0 * PI, Vector2(-1, 1)],
		[Vector2(r.end.x, r.end.y), 0.0, 0.5 * PI, Vector2(-1, -1)],
		[Vector2(r.position.x, r.end.y), 0.5 * PI, PI, Vector2(1, -1)],
	]
	for i in 4:
		var rad: float = minf(float(radii[i]), minf(r.size.x, r.size.y) * 0.5)
		var c: Vector2 = corners[i][0]
		if rad < 0.5:
			pts.append(c)
			continue
		var centre: Vector2 = c + corners[i][3] * rad
		for k in steps + 1:
			var a: float = lerpf(corners[i][1], corners[i][2], float(k) / steps)
			pts.append(centre + Vector2(cos(a), sin(a)) * rad)
	pts.append(pts[0])
	return pts

static func box(r: Rect2, radius: float) -> PackedVector2Array:
	return rounded(r, [radius, radius, radius, radius])

# Fill, sheen and the cyan-to-purple border. `edge` overrides the border colour
# (a lit tile), `a` fades the whole panel.
static func panel(ci: CanvasItem, outline: PackedVector2Array, a: float = 1.0, edge: Color = Color(0, 0, 0, 0), fill: Color = FILL) -> void:
	if outline.size() < 3:
		return
	var poly := outline.slice(0, outline.size() - 1)
	ci.draw_colored_polygon(poly, Color(fill, fill.a * a))
	ci.draw_colored_polygon(poly, Color(TINT, TINT.a * a))
	var lo := INF
	var hi := -INF
	var top := INF
	for p in poly:
		lo = minf(lo, p.x)
		hi = maxf(hi, p.x)
		top = minf(top, p.y)
	# sheen: a faint light line just inside the top edge
	var sheen := PackedVector2Array()
	for p in poly:
		if p.y < top + 1.5 and p.x > lo + 8.0 and p.x < hi - 8.0:
			sheen.append(p + Vector2(0, 1.5))
	if sheen.size() >= 2:
		ci.draw_polyline(sheen, Color(1, 1, 1, 0.14 * a), 1.0, true)
	var cols := PackedColorArray()
	for p in outline:
		var c: Color = edge if edge.a > 0.0 else CYAN.lerp(PURPLE, clampf((p.x - lo) / maxf(hi - lo, 1.0), 0.0, 1.0))
		cols.append(Color(c, (edge.a if edge.a > 0.0 else 0.55) * a))
	ci.draw_polyline_colors(outline, cols, 1.2, true)
