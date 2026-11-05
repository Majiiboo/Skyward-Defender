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
var _shield: Node2D
# Aegis card (battle sets these): a thin band of light that hugs his outline.
var shield := 0.0          # 0 off .. 1 full strength (brighter with more Aegis, flares on hits)
var shield_form := 1.0     # 0 -> 1 as the band closes in around him after the card is picked
var shield_col := Color(0.55, 0.85, 1.0)
var front_only := false     # always face the camera (Gear showcase): the chunky chibi front pose
var face_override := 2.0    # Heroes page swivel (Rudy, dev172): -1..1 sets the facing by hand; 2 = off

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
	# shield: his silhouette in one light colour, spread a few pixels round him, added as
	# light behind him so only a thin band shows past his edges
	_shield = Node2D.new()
	var shm := ShaderMaterial.new()
	shm.shader = Shader.new()
	shm.shader.code = "shader_type canvas_item;
render_mode blend_add;
uniform vec4 col : source_color;
void fragment() { COLOR = vec4(col.rgb, texture(TEXTURE, UV).a * col.a * COLOR.a); }"
	_shield.material = shm
	_shield.show_behind_parent = true
	_shield.draw.connect(_draw_shield)
	add_child(_shield)
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
	if face_override >= -1.0 and face_override <= 1.0:
		rig.face = face_override
		rig.face_target = face_override
	elif front_only and PilotRig.front_ready():
		rig.face = 0.0
	X = PilotRig.solve(rig)
	queue_redraw()
	_rim.queue_redraw()
	_shield.queue_redraw()
	_behind.queue_redraw()
	_front.queue_redraw()

func fire() -> void:
	rig.fire()

func muzzle() -> Vector2:
	if X.is_empty():
		X = PilotRig.solve(rig)
	if PilotRig.hero_mode():
		return PilotRig.hero_muzzle(rig, pos, height * PilotRig.SIZE)
	return PilotRig.muzzle_screen(rig, X, pos, height * PilotRig.SIZE)

# The pilot: the side rig, and while he turns, the front pose taking over (Luna's
# front parts) so he swings round through facing the camera instead of mirroring.
func _side_a() -> float:
	return alpha * (smoothstep(0.38, 0.47, absf(rig.face)) if PilotRig.front_ready() else 1.0)

func _front_a() -> float:
	return alpha * PilotRig.front_weight(rig) if PilotRig.front_ready() else 0.0

func _draw_figure(c: CanvasItem, at: Vector2, lift: Color = PilotRig.LIFT) -> void:
	var h := height * PilotRig.SIZE
	if PilotRig.hero_mode():   # a hero from Luna's frames (dev172)
		PilotRig.draw_hero(c, rig, at, h, alpha, lift)
		return
	var sa := _side_a()
	var fa := _front_a()
	if not PilotRig.front_ready() or front_only:
		if sa > 0.01:
			PilotRig.draw(c, rig, X, at, h, 0.0, sa, lift)
		if fa > 0.01:
			PilotRig.draw_front(c, rig, at, h, fa, lift, -1.0, front_only)
		return
	if PilotRig.turn_ready():
		# Luna's turn-around frames (dev161): the rig hands over to them for the turn
		var tw := PilotRig.turn_weight(rig)
		if tw < 0.995:
			PilotRig.draw(c, rig, X, at, h, 0.0, alpha * (1.0 - tw), lift)
		if tw > 0.005:
			PilotRig.draw_turn(c, rig, at, h, alpha * tw, lift)
		return
	# the turn (dev158): the head goes first, the body follows; each on its own alpha
	var sha := alpha * PilotRig.side_head_weight(rig)
	var fha := alpha * PilotRig.front_head_weight(rig)
	if sa > 0.01 or sha > 0.01:
		PilotRig.draw(c, rig, X, at, h, 0.0, sa, lift, sha)
	if fa > 0.01 or fha > 0.01:
		PilotRig.draw_front(c, rig, at, h, fa, lift, fha)

func _draw() -> void:
	if not X.is_empty():
		_draw_figure(self, pos)

func _draw_rim() -> void:
	if X.is_empty():
		return
	var d := maxf(1.0, height * PilotRig.SIZE / 60.0)
	for o in [Vector2(0, -d), Vector2(-d, 0), Vector2(d, 0), Vector2(0, d * 0.6)]:
		_draw_figure(_rim, pos + o, Color(1, 1, 1))

func _draw_shield() -> void:
	if X.is_empty() or shield <= 0.01:
		return
	var h := height * PilotRig.SIZE
	var f := smoothstep(0.0, 1.0, shield_form)
	# the band starts wide and faint, then tightens onto his outline
	var d := lerpf(h * 0.22, maxf(2.0, h / 24.0), f)
	var a := shield * lerpf(0.25, 1.0, f) * (0.75 + 0.25 * sin(rig.t * 3.0))
	(_shield.material as ShaderMaterial).set_shader_parameter("col", Color(shield_col, 0.32 * a))
	for k in 8:
		var o := Vector2.from_angle(TAU * k / 8.0) * d
		_draw_figure(_shield, pos + o, Color(1, 1, 1))

func _draw_behind() -> void:
	if not X.is_empty():
		var h := height * PilotRig.SIZE
		Backdrop.soft_glow(_behind, pos + Vector2(0, -h * 0.1), h * 0.5, Color(PilotRig.BACKLIGHT, PilotRig.BACKLIGHT.a * alpha))
		if not PilotRig.hero_mode():   # heroes carry their own flames in the frames
			PilotRig.draw_light(_behind, rig, X, pos, h, PilotSprite.style, 0.0, alpha)

func _draw_front() -> void:
	if not X.is_empty():
		if PilotRig.hero_mode():
			if rig.recoil > 0.2:   # the muzzle flash at the weapon's barrel
				var m := PilotRig.hero_muzzle(rig, pos, height * PilotRig.SIZE)
				_front.draw_circle(m, height * 0.09 * rig.recoil, Color(Heroes.element_color(Heroes.element_of(PilotRig.hero)), 0.7 * alpha))
			return
		PilotRig.draw_glow(_front, rig, X, pos, height * PilotRig.SIZE, 0.0, alpha)
