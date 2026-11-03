class_name NavDock
extends Control
# The bottom bar, drawn as ONE shape: fill + outline + the active-tab notch.
#
# Why one shape: the old bar was three separate pieces (bar border, notch
# picture, cover strip) that had to line up perfectly while moving, so seams
# showed. Here the notch is part of the outline itself:
#   - on a middle tab the notch rises out of the bar with soft blended corners
#   - on the Store / Quests edge tabs the notch's outer curve IS the corner,
#     so the bar flows up into the tab with no free-floating piece
#
# How it is used (hub.gd does this for you):
#   dock.setup(nav_bar_node)                 # follow that bar's rectangle
#   dock.snap_to_tab(button, edge)           # place the notch instantly
#   dock.slide_to_tab(button, edge)          # glide the notch there
# edge: -1 = left edge tab (Store), 0 = middle tab, 1 = right edge tab (Quests)

@export var bump_h := 14.0          # how far the notch rises above the bar
@export var bump_w := 92.0          # notch width
@export var bar_corner := 20.0      # the bar's own top corner radius
@export var fillet := 6.0           # soft blend where notch meets the bar top
@export var tab_corner := 8.0       # notch's own top corners (middle tabs)
@export var edge_corner := 14.0     # outer curve of the notch on edge tabs
@export var fill_color := Color(0.03, 0.045, 0.10, 0.82)
@export var line_color := Color(0.0, 0.898, 1.0, 1.0)
@export var line_width := 1.2
@export var slide_time := 0.30

# Left edge of the notch in this node's own pixels. Setting it redraws.
var notch_x := 0.0:
	set(v):
		notch_x = v
		queue_redraw()

var _bar: Control
var _tab: Control
var _edge := 0
var _tween: Tween

func setup(bar: Control) -> void:
	_bar = bar
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_follow_bar()

func snap_to_tab(tab: Control, edge: int) -> void:
	_tab = tab
	_edge = edge
	_kill_tween()
	notch_x = _target_x()

func slide_to_tab(tab: Control, edge: int) -> void:
	_tab = tab
	_edge = edge
	_kill_tween()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "notch_x", _target_x(), slide_time)

func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null

func _process(_delta: float) -> void:
	_follow_bar()
	# Layout can settle after first load (safe areas, tall phones). If we are
	# not mid-slide, keep the notch glued to the active tab.
	if _tab != null and (_tween == null or not _tween.is_running()):
		var x := _target_x()
		if absf(x - notch_x) > 0.5:
			notch_x = x

func _follow_bar() -> void:
	if _bar == null:
		return
	var r := _bar.get_global_rect()
	var p := Vector2(r.position.x, r.position.y - bump_h)
	var s := Vector2(r.size.x, r.size.y + bump_h)
	if global_position != p:
		global_position = p
	if size != s:
		size = s
		queue_redraw()

func _target_x() -> float:
	var max_x := maxf(size.x - bump_w, 0.0)
	if _edge < 0:
		return 0.0
	if _edge > 0:
		return max_x
	var cx := _tab.get_global_rect().get_center().x - global_position.x
	return clampf(cx - bump_w * 0.5, 0.0, max_x)

# ---- drawing -------------------------------------------------------------

func _arc(pts: PackedVector2Array, c: Vector2, r: float, a0: float, a1: float) -> void:
	if r < 0.1:
		return
	var steps := 10
	for i in range(steps + 1):
		var a := lerpf(a0, a1, float(i) / float(steps))
		pts.append(c + Vector2(cos(a), sin(a)) * r)

func _build_outline() -> PackedVector2Array:
	# Local coordinates: y = 0 is the top of the notch, the bar top is y = bump_h.
	var w := size.x
	var top := bump_h
	var left := notch_x
	var right := w - notch_x - bump_w
	var edge_l := left < 0.5
	var edge_r := right < 0.5
	var pts := PackedVector2Array()
	var rt := tab_corner
	var er := minf(edge_corner, bump_h)

	# ---- left side, bottom to top ----
	if edge_l:
		pts.append(Vector2(0, er))
		_arc(pts, Vector2(er, er), er, PI, 1.5 * PI)
	else:
		var rl := minf(bar_corner, left * 0.5)
		var fl := minf(fillet, maxf(left - rl, 0.0))
		pts.append(Vector2(0, top + rl))
		_arc(pts, Vector2(rl, top + rl), rl, PI, 1.5 * PI)
		pts.append(Vector2(left - fl, top))
		_arc(pts, Vector2(left - fl, top - fl), fl, 0.5 * PI, 0.0)
		pts.append(Vector2(left, rt))
		_arc(pts, Vector2(left + rt, rt), rt, PI, 1.5 * PI)

	# ---- right side, top to bottom ----
	if edge_r:
		pts.append(Vector2(w - er, 0))
		_arc(pts, Vector2(w - er, er), er, 1.5 * PI, 2.0 * PI)
		pts.append(Vector2(w, er))
	else:
		var rr := minf(bar_corner, right * 0.5)
		var fr := minf(fillet, maxf(right - rr, 0.0))
		var nr := left + bump_w
		pts.append(Vector2(nr - rt, 0))
		_arc(pts, Vector2(nr - rt, rt), rt, 1.5 * PI, 2.0 * PI)
		pts.append(Vector2(nr, top - fr))
		_arc(pts, Vector2(nr + fr, top - fr), fr, PI, 0.5 * PI)
		pts.append(Vector2(w - rr, top))
		_arc(pts, Vector2(w - rr, top + rr), rr, 1.5 * PI, 2.0 * PI)
		pts.append(Vector2(w, top + rr))
	return _dedupe(pts)

func _dedupe(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		if out.is_empty() or out[out.size() - 1].distance_to(p) > 0.05:
			out.append(p)
	return out

func _draw() -> void:
	if size.x < 10.0 or size.y < 10.0:
		return
	var line := _build_outline()
	# Fill = outline + the two bottom corners (bar is flush with the screen bottom).
	var shape := PackedVector2Array(line)
	shape.append(Vector2(size.x, size.y))
	shape.append(Vector2(0, size.y))
	draw_colored_polygon(shape, fill_color)
	# One crisp line, no glow: the notch is the only highlight.
	draw_polyline(line, Color(line_color, 0.55), line_width, true)
