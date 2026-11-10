class_name NavDock
extends Control
# The bottom bar in the Glass look (glass.gd): a floating glass capsule with a lit
# glass tile under the active tab (gold on Battle) that glides between tabs.
#
# How it is used (hub.gd does this for you):
#   dock.setup(nav_bar_node)                 # follow that bar's rectangle
#   dock.snap_to_tab(button, edge)           # place the tile instantly
#   dock.slide_to_tab(button, edge)          # glide the tile there
# edge is kept for older callers; the tile always centres on its tab.

@export var bump_h := 4.0           # space kept above the bar
@export var bump_w := 74.0          # lit tile width
@export var bar_corner := 20.0      # the glass bar's corner radius
@export var slide_time := 0.30
var play_mode := false           # Home is showing: the Battle tile is the Play button

# Left edge of the notch in this node's own pixels. Setting it redraws.
var notch_x := 0.0:
	set(v):
		notch_x = v
		queue_redraw()

var _bar: Control
var _tab: Control
var _edge := 0
var _tween: Tween

# The clean look's GLASS PILL + BLUE CAPSULE (Rudy, 2026-11-09; demo claude.ai/artifact/96yTzLebGhRXcLsRL1dcve):
# nav_glass.gdshader draws both from these rectangles; the capsule slides to the tapped tab with a
# springy stretch. hub.gd puts a BackBufferCopy right before this node so the blur sees the open page.
const PILL_SIDE := 12.0        # the pill floats this far in from the screen sides
const PILL_TOP := 8.0          # ... starts this far below the bar's top (under bump_h)
const PILL_BOTTOM := 12.0      # ... and ends this far above the screen bottom
const CAP_OUT := 8.0           # the capsule sticks out this far above and below the pill
var glass := false             # set by setup when UIKit.CLEAN
var slide_p := 1.0             # 0..1 through a slide (drives the stretch)
var _slide_from := 0.0
var _slide_to := 0.0
var _mat: ShaderMaterial

func setup(bar: Control) -> void:
	_bar = bar
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	glass = UIKit.CLEAN
	if glass:
		_mat = ShaderMaterial.new()
		_mat.shader = load("res://nav_glass.gdshader")
		material = _mat
	_follow_bar()

func snap_to_tab(tab: Control, edge: int) -> void:
	_tab = tab
	_edge = edge
	_kill_tween()
	notch_x = _target_x()
	slide_p = 1.0

func slide_to_tab(tab: Control, edge: int) -> void:
	_tab = tab
	_edge = edge
	_kill_tween()
	_tween = create_tween()
	if glass:   # a springy glide (overshoots a little) with a stretch on the way
		_slide_from = notch_x
		_slide_to = _target_x()
		slide_p = 0.0
		_tween.tween_property(self, "slide_p", 1.0, 0.45)
		return
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "notch_x", _target_x(), slide_time)

static func _back_out(t: float) -> float:   # ease with a small overshoot (like cubic-bezier .3,1.35,.5,1)
	var c := 1.6
	var u := t - 1.0
	return 1.0 + (c + 1.0) * u * u * u + c * u * u

func _glass_rects() -> Array:
	var pill := Rect2(PILL_SIDE, bump_h + PILL_TOP, size.x - PILL_SIDE * 2.0, size.y - bump_h - PILL_TOP - PILL_BOTTOM)
	var p := clampf(slide_p, 0.0, 1.0)
	var sx := NavIcon._k(p, [[0.0, 1.0], [0.35, 1.3], [0.7, 0.94], [1.0, 1.0]])
	var sy := NavIcon._k(p, [[0.0, 1.0], [0.35, 0.88], [0.7, 1.05], [1.0, 1.0]])
	var w := bump_w * sx
	var h := (pill.size.y + CAP_OUT * 2.0) * sy
	var cx := notch_x + bump_w * 0.5
	var cy := pill.get_center().y
	return [pill, Rect2(cx - w * 0.5, cy - h * 0.5, w, h)]

func _update_glass() -> void:
	var r := _glass_rects()
	var pill: Rect2 = r[0]
	var cap: Rect2 = r[1]
	_mat.set_shader_parameter("vp_size", get_viewport_rect().size)
	_mat.set_shader_parameter("pill", Vector4(pill.position.x, pill.position.y, pill.size.x, pill.size.y))
	_mat.set_shader_parameter("cap", Vector4(cap.position.x, cap.position.y, cap.size.x, cap.size.y))
	_mat.set_shader_parameter("cap_a", 1.0 if _tab != null else 0.0)

func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null

func _process(_delta: float) -> void:
	_follow_bar()
	if glass and slide_p < 1.0:
		notch_x = lerpf(_slide_from, _slide_to, _back_out(slide_p))
	# Layout can settle after first load (safe areas, tall phones). If we are
	# not mid-slide, keep the notch glued to the active tab.
	if _tab != null and (_tween == null or not _tween.is_running()):
		var x := _target_x()
		if absf(x - notch_x) > 0.5:
			notch_x = x
	if glass:
		_update_glass()

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
	# the lit tile sits centred on its tab, edge tabs included (the glass bar floats)
	var cx := _tab.get_global_rect().get_center().x - global_position.x
	return clampf(cx - bump_w * 0.5, 0.0, max_x)

# ---- drawing -------------------------------------------------------------

const INSET := 8.0          # the glass bar floats this far from the screen sides and bottom

func _draw() -> void:
	if size.x < 10.0 or size.y < 10.0:
		return
	if glass:
		# the glass pill + blue capsule: one rectangle, nav_glass.gdshader paints it all
		draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)
		return
	if UIKit.CLEAN:
		# the clean bar: flat, full width, a faint line on top. No box behind the open tab (Rudy,
		# 2026-11-09): its icon lights up (the others stay dim) and its name shows under it (hub.gd)
		var fb := Rect2(0.0, bump_h, size.x, size.y - bump_h)
		draw_rect(fb, Color(0.039, 0.071, 0.125, 0.98))
		draw_line(Vector2(0.0, bump_h), Vector2(size.x, bump_h), Color(1, 1, 1, 0.06), 1.0)
		return
	# the bar: one glass capsule
	var bar := Rect2(INSET, bump_h, size.x - INSET * 2.0, size.y - bump_h - INSET)
	if UIKit.kit_ready("nav_dock"):   # Luna's dock (dev182)
		draw_style_box(UIKit.nine("nav_dock", 40.0, Vector2.ZERO), bar.grow(2.0))
	else:
		Glass.panel(self, Glass.box(bar, bar_corner))
	# the active tab: a lit tile set INTO the bar (Rudy, dev107: no bar line behind it,
	# nothing sticking out above), gold on Battle, breathing gently when it is Play
	var tile := Rect2(notch_x, bar.position.y + 4.0, bump_w, bar.size.y - 8.0)
	var battle: bool = _tab != null and String(_tab.name) == "NavBattle"
	var col: Color = Glass.GOLD if battle else Glass.CYAN
	var breathe: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.004) if play_mode and battle else 0.0
	var fill := Color(col.r * 0.25, col.g * 0.25, col.b * 0.32, 0.85 + 0.1 * breathe)
	Glass.panel(self, Glass.box(tile, bar_corner - 4.0), 1.0, Color(col, 0.75 + 0.25 * breathe), fill)
	if play_mode and battle:
		queue_redraw()
