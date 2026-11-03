class_name HomeProp
extends Control
# The Chest and Patrol buttons on Home, drawn from Luna's 3D layers so they move:
# "drone" = the patrol quad-drone hovering, its four rotor blades spinning (two blurred
# copies each) over a soft thruster glow; "chest" = the chest floating gently with a
# breathing rim light; open() lifts its lid off and lets the light burst out.
# Sits over a Button (mouse ignored); hub.gd clears the button's own icon.

var kind := "drone"
var t := 0.0
var _open := 0.0         # 0 closed .. 1 lid fully up (chest)
var _open_t := -1.0
var _tex := {}
var _light: Node2D        # additive layer behind the chest for its burst of light

# rotor ring centres on icons/drone_body.png (0..1)
const ROTORS := [Vector2(0.13, 0.17), Vector2(0.87, 0.17), Vector2(0.15, 0.80), Vector2(0.85, 0.80)]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for n in ["drone_body", "drone_prop", "drone_thrust", "chest3d_body", "chest3d_lid", "chest3d_burst"]:
		_tex[n] = load("res://icons/%s.png" % n)
	_light = Node2D.new()
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_light.material = add
	_light.show_behind_parent = true
	_light.draw.connect(_draw_light)
	add_child(_light)

func open() -> void:
	_open_t = 0.0

func _process(delta: float) -> void:
	t += delta
	if _open_t >= 0.0:
		_open_t += delta
		# up quickly, hold, settle back down
		_open = smoothstep(0.0, 0.25, _open_t) * (1.0 - smoothstep(1.1, 1.5, _open_t))
		if _open_t > 1.5:
			_open_t = -1.0
			_open = 0.0
	queue_redraw()
	_light.queue_redraw()

func _draw() -> void:
	if kind == "drone":
		_draw_drone()
	else:
		_draw_chest()

func _draw_drone() -> void:
	var body: Texture2D = _tex.drone_body
	var w := size.x * 1.05
	var h := w * body.get_height() / body.get_width()
	var c := size * 0.5 + Vector2(0, sin(t * 2.4) * 1.6)
	var tilt := sin(t * 1.3) * 0.06
	draw_set_transform(c, tilt, Vector2.ONE)
	var r := Rect2(-w * 0.5, -h * 0.5, w, h)
	# thruster glow under the body (drawn faint: this node is not additive)
	var th: Texture2D = _tex.drone_thrust
	var tw := w * 0.16
	draw_texture_rect(th, Rect2(-tw * 0.5, h * 0.05, tw, tw * th.get_height() / th.get_width()), false, Color(1, 1, 1, 0.35 + 0.15 * sin(t * 9.0)))
	draw_texture_rect(body, r, false)
	# rotors: blades spinning in the rings, seen from above at a slant (squashed)
	var prop: Texture2D = _tex.drone_prop
	var pw := w * 0.24
	var ph := pw * prop.get_height() / prop.get_width()
	for i in ROTORS.size():
		var p: Vector2 = r.position + ROTORS[i] * r.size
		for k in 2:
			var a := t * 26.0 * (1.0 if i % 2 == 0 else -1.0) + k * 1.1 + i
			draw_set_transform_matrix(Transform2D(tilt, c + p.rotated(tilt)) * Transform2D(0.0, Vector2(1.0, 0.55), 0.0, Vector2.ZERO) * Transform2D(a, Vector2.ZERO))
			draw_texture_rect(prop, Rect2(-pw * 0.5, -ph * 0.5, pw, ph), false, Color(1, 1, 1, 0.55 if k == 0 else 0.3))
	draw_set_transform_matrix(Transform2D.IDENTITY)

# light from inside the chest while the lid is up (Luna's burst, added as light)
func _draw_light() -> void:
	if kind != "chest" or _open <= 0.01:
		return
	var w := size.x * 0.95
	var bt: Texture2D = _tex.chest3d_burst
	var bs := w * (0.9 + 0.5 * _open)
	_light.draw_texture_rect(bt, Rect2(size.x * 0.5 - bs * 0.5, size.y * 0.35 - bs * 0.45, bs, bs), false, Color(1, 1, 1, 0.8 * _open))

func _draw_chest() -> void:
	var body: Texture2D = _tex.chest3d_body
	var lid: Texture2D = _tex.chest3d_lid
	var w := size.x * 0.95
	var h := w * body.get_height() / body.get_width()
	var c := size * 0.5 + Vector2(0, sin(t * 1.8) * 1.2 + h * 0.06)
	var r := Rect2(c.x - w * 0.5, c.y - h * 0.5, w, h)
	draw_texture_rect(body, r, false)
	# the lid sits on the rim; opening lifts it and tips it back
	var lw := w
	var lh := lw * lid.get_height() / lid.get_width()
	var lp := Vector2(c.x, r.position.y + h * 0.16 - _open * h * 0.45)
	draw_set_transform(lp, -0.35 * _open, Vector2.ONE)
	draw_texture_rect(lid, Rect2(-lw * 0.5, -lh * 0.5, lw, lh), false)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	# a faint breathing rim glow so the chest says "tap me"
	var g := 0.5 + 0.5 * sin(t * 2.2)
	draw_rect(Rect2(r.position.x + w * 0.1, r.end.y - 3.0, w * 0.8, 2.0), Color(0.18, 0.9, 1.0, 0.15 + 0.2 * g))
