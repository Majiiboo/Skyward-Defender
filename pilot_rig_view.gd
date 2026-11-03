class_name PilotRigView
extends Node2D
# Draws one PilotRig with its three layers in the right order: the flames as light
# BEHIND him, the pilot himself, then the visor light and muzzle flash in FRONT.
# Add it where the pilot should appear (battle, Home wallpaper); each frame call
# update() with what he is doing, then read muzzle() for where bullets start.

var rig := PilotRig.Rig.new()
var X := {}
var pos := Vector2.ZERO
var height := 60.0
var alpha := 1.0
var _rim: Node2D
var _behind: Node2D
var _front: Node2D

func _init() -> void:
	# rim: his whole outline in one flat cool colour, nudged a pixel each way, behind him
	_rim = Node2D.new()
	var sm := ShaderMaterial.new()
	sm.shader = Shader.new()
	sm.shader.code = "shader_type canvas_item;
uniform vec4 rim : source_color;
void fragment() { COLOR = vec4(rim.rgb, texture(TEXTURE, UV).a * rim.a * COLOR.a); }"
	sm.set_shader_parameter("rim", PilotRig.RIM)
	_rim.material = sm
	_rim.show_behind_parent = true
	_rim.draw.connect(_draw_rim)
	add_child(_rim)
	_behind = _light_layer(_draw_behind)
	_behind.show_behind_parent = true
	_front = _light_layer(_draw_front)

func _light_layer(fn: Callable) -> Node2D:
	var n := Node2D.new()
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	n.material = m
	n.draw.connect(fn)
	add_child(n)
	return n

# aim: rifle angle (0 = right, -PI/2 = up). lean -1..1 (+ = moving right).
# hover: thruster power 0.35..1.9. vy: vertical speed px/s (+ = falling).
func update(delta: float, at: Vector2, aim: float, lean: float, hover: float, vy: float, a: float = 1.0) -> void:
	pos = at
	alpha = a
	rig.update(delta, aim, lean, hover, vy)
	X = PilotRig.solve(rig)
	queue_redraw()
	_rim.queue_redraw()
	_behind.queue_redraw()
	_front.queue_redraw()

func fire() -> void:
	rig.fire()

func muzzle() -> Vector2:
	if X.is_empty():
		X = PilotRig.solve(rig)
	return PilotRig.muzzle_screen(rig, X, pos, height * PilotRig.SIZE)

func _draw() -> void:
	if not X.is_empty():
		PilotRig.draw(self, rig, X, pos, height * PilotRig.SIZE, 0.0, alpha)

func _draw_rim() -> void:
	if X.is_empty():
		return
	var d := maxf(1.0, height * PilotRig.SIZE / 60.0)
	for o in [Vector2(0, -d), Vector2(-d, 0), Vector2(d, 0), Vector2(0, d * 0.6)]:
		PilotRig.draw(_rim, rig, X, pos + o, height * PilotRig.SIZE, 0.0, alpha, Color(1, 1, 1))

func _draw_behind() -> void:
	if not X.is_empty():
		var h := height * PilotRig.SIZE
		Backdrop.soft_glow(_behind, pos + Vector2(0, -h * 0.1), h * 0.5, Color(PilotRig.BACKLIGHT, PilotRig.BACKLIGHT.a * alpha))
		PilotRig.draw_light(_behind, rig, X, pos, h, PilotSprite.style, 0.0, alpha)

func _draw_front() -> void:
	if not X.is_empty():
		PilotRig.draw_glow(_front, rig, X, pos, height * PilotRig.SIZE, 0.0, alpha)
