class_name HomeFrame
extends Control
# The Home screen's "frame": Glass panels (glass.gd) behind the top bar, Chest and
# Patrol (flush with the screen edges) and the side rail tiles, so the buttons read
# as part of one glass set with the nav bar.
# hub.gd registers each control with add_dock(control, side, pad): side 0 = top bar,
# -1 / 1 = left / right edge tab, 2 = free tile.

const CYAN := Color(0.18, 0.9, 1.0)

var line_bottom_y := 0.0     # where the edge lines end (the nav bar's top line)
var line_top_y := 0.0        # where they start (just under the top docks)
var _docks: Array = []       # {ctrl, side (-1 left / 1 right), pad}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

func add_dock(ctrl: Control, side: int, pad: Vector2 = Vector2(10, 6)) -> void:
	_docks.append({"ctrl": ctrl, "side": side, "pad": pad})

func _process(_d: float) -> void:
	var p := get_parent() as Control
	if p != null and size != p.size:
		size = p.size
		position = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	if size.x < 10.0:
		return
	for d in _docks:
		var ctrl: Control = d.ctrl
		if ctrl == null or not ctrl.is_visible_in_tree():
			continue
		var g := ctrl.get_global_rect()
		var pad: Vector2 = d.pad
		var r := Rect2(g.position - pad - global_position, g.size + pad * 2.0)
		var side: int = d.side
		var a: float = ctrl.modulate.a
		match side:
			0:
				# top bar: no box (Rudy, dev107), the buttons float free over a soft shade
				# that fades out below them, so they read on any world
				var y1: float = r.end.y + 26.0
				var top := Color(0.0, 0.01, 0.04, 0.6 * a)
				var clear := Color(0.0, 0.01, 0.04, 0.0)
				draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, y1), Vector2(0, y1)]),
					PackedColorArray([top, top, clear, clear]))
			-1:
				# a glass tab flush with the left edge, rounded on its inner side
				Glass.panel(self, Glass.rounded(Rect2(-2.0, r.position.y, r.end.x + 2.0, r.size.y), [0, 14, 14, 0]), a)
			1:
				Glass.panel(self, Glass.rounded(Rect2(r.position.x, r.position.y, size.x - r.position.x + 2.0, r.size.y), [14, 0, 0, 14]), a)
			_:
				# a free glass tile (side rail buttons)
				Glass.panel(self, Glass.box(r, 12.0), a)
