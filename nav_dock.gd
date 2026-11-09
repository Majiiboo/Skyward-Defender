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
	# the lit tile sits centred on its tab, edge tabs included (the glass bar floats)
	var cx := _tab.get_global_rect().get_center().x - global_position.x
	return clampf(cx - bump_w * 0.5, 0.0, max_x)

# ---- drawing -------------------------------------------------------------

const INSET := 8.0          # the glass bar floats this far from the screen sides and bottom

func _draw() -> void:
	if size.x < 10.0 or size.y < 10.0:
		return
	if UIKit.CLEAN:
		# the clean bar (mock-up "Round 2 · Clean"): flat, full width, a faint line on top; the open
		# tab sits in a soft cyan pill that slides from tab to tab (no gold, no glass)
		var fb := Rect2(0.0, bump_h, size.x, size.y - bump_h)
		draw_rect(fb, Color(0.039, 0.071, 0.125, 0.98))
		draw_line(Vector2(0.0, bump_h), Vector2(size.x, bump_h), Color(1, 1, 1, 0.06), 1.0)
		var pr := Rect2(notch_x + 4.0, bump_h + 5.0, bump_w - 8.0, fb.size.y - 14.0)
		var ps := StyleBoxFlat.new()
		ps.bg_color = Color(UIKit.CYAN, 0.13)
		ps.set_corner_radius_all(18)
		ps.anti_aliasing = true
		draw_style_box(ps, pr)
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
