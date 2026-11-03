class_name HomeFrame
extends Control
# The Home screen's "frame": docks attached to the screen edges (behind the top
# bar, the menu button, Chest and Patrol) and a thin line down both edges that
# flows into the nav bar outline, so the buttons read as part of one piece.
# hub.gd registers each docked control with add_dock(control, side, pad).

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

func _dock_shape(r: Rect2, side: int, _radius: float) -> PackedVector2Array:
	# A tab flush with the screen edge, with an angled cut on its inner top corner
	# and a short chamfer on the bottom, so it reads as a hangar panel rather than a box.
	var cut := minf(14.0, r.size.y * 0.4)
	var pts := PackedVector2Array()
	if side < 0:
		pts.append(Vector2(0, r.position.y))
		pts.append(Vector2(r.end.x - cut, r.position.y))
		pts.append(Vector2(r.end.x, r.position.y + cut))
		pts.append(Vector2(r.end.x, r.end.y - 6.0))
		pts.append(Vector2(r.end.x - 6.0, r.end.y))
		pts.append(Vector2(0, r.end.y))
	else:
		pts.append(Vector2(size.x, r.end.y))
		pts.append(Vector2(r.position.x + 6.0, r.end.y))
		pts.append(Vector2(r.position.x, r.end.y - 6.0))
		pts.append(Vector2(r.position.x, r.position.y + cut))
		pts.append(Vector2(r.position.x + cut, r.position.y))
		pts.append(Vector2(size.x, r.position.y))
	return pts

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
		if side == 0:
			# Top bar: a mirror of the nav bar. Flush with the top of the screen, one
			# outline along its bottom that curves up into the screen edges.
			var R := 20.0
			var yb := r.end.y
			var pts := PackedVector2Array()
			pts.append(Vector2(0, yb - R))
			for i in range(9):
				var a2 := lerpf(PI, PI * 0.5, float(i) / 8.0)
				pts.append(Vector2(R, yb - R) + Vector2(cos(a2), sin(a2)) * R)
			for i in range(9):
				var a3 := lerpf(PI * 0.5, 0.0, float(i) / 8.0)
				pts.append(Vector2(size.x - R, yb - R) + Vector2(cos(a3), sin(a3)) * R)
			pts.append(Vector2(size.x, yb - R))
			var shape := PackedVector2Array(pts)
			shape.append(Vector2(size.x, -2))
			shape.append(Vector2(0, -2))
			draw_colored_polygon(shape, Color(0.03, 0.045, 0.10, 0.82))
			draw_polyline(pts, Color(CYAN, 0.55), 1.2, true)
			continue
		if side < 0:
			r = Rect2(Vector2(0, r.position.y), Vector2(r.end.x, r.size.y))
		else:
			r = Rect2(Vector2(r.position.x, r.position.y), Vector2(size.x - r.position.x, r.size.y))
		var radius: float = minf(16.0, r.size.y * 0.45)
		var shape := _dock_shape(r, side, radius)
		draw_colored_polygon(shape, Color(0.03, 0.045, 0.10, 0.82))
		var edge := PackedVector2Array(shape)
		draw_polyline(edge, Color(CYAN, 0.5), 1.2, true)
