class_name IconFx
extends Control
# A short one-off effect drawn over a button's icon when a tab activates:
#   "flash"  a soft light that swells and fades (visor powering on)
#   "spark"  a star burst (rifles clashing)
#   "beam"   a light beam rising from a point (chest / crate opening)
#   "ring"   an expanding ring (planet, checkmark)
# Frees itself when done. Use IconFx.play(parent_control, kind, local_point).

var kind := "flash"
var at := Vector2.ZERO
var life := 0.45
var t := 0.0
const CYAN := Color(0.2, 0.85, 1.0)

static func play(parent: Control, which: String, point: Vector2, dur: float = 0.45) -> void:
	var fx := IconFx.new()
	fx.kind = which
	fx.at = point
	fx.life = dur
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(fx)

func _process(delta: float) -> void:
	t += delta
	if t >= life:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var k := clampf(t / life, 0.0, 1.0)
	var fade := 1.0 - k
	match kind:
		"flash":
			draw_circle(at, 6.0 + 18.0 * k, Color(CYAN, 0.35 * fade))
			draw_circle(at, 3.0 + 8.0 * k, Color(1, 1, 1, 0.8 * fade))
		"spark":
			var pts := PackedVector2Array()
			for i in 16:
				var a := TAU * float(i) / 16.0
				var r := (14.0 if i % 2 == 0 else 5.0) * (0.3 + 1.2 * k)
				pts.append(at + Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(pts, Color(1, 1, 1, 0.9 * fade))
			draw_circle(at, 20.0 * k, Color(1.0, 0.85, 0.4, 0.3 * fade))
		"beam":
			var h := 40.0 * k
			draw_colored_polygon(PackedVector2Array([at + Vector2(-6, 0), at + Vector2(6, 0), at + Vector2(10, -h), at + Vector2(-10, -h)]), Color(CYAN, 0.35 * fade))
			draw_circle(at, 5.0, Color(1, 1, 1, 0.7 * fade))
		"ring":
			draw_arc(at, 8.0 + 26.0 * k, 0.0, TAU, 24, Color(CYAN, 0.8 * fade), 2.5, true)
