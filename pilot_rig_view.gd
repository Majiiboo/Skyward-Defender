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
var _behind: Node2D
var _front: Node2D

func _init() -> void:
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
	_behind.queue_redraw()
	_front.queue_redraw()

func fire() -> void:
	rig.fire()

func muzzle() -> Vector2:
	if X.is_empty():
		X = PilotRig.solve(rig)
	return PilotRig.muzzle_screen(rig, X, pos, height)

func _draw() -> void:
	if not X.is_empty():
		PilotRig.draw(self, rig, X, pos, height, 0.0, alpha)

func _draw_behind() -> void:
	if not X.is_empty():
		PilotRig.draw_light(_behind, rig, X, pos, height, PilotSprite.style, 0.0, alpha)

func _draw_front() -> void:
	if not X.is_empty():
		PilotRig.draw_glow(_front, rig, X, pos, height, 0.0, alpha)
