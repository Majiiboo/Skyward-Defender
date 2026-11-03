extends Node2D
# Side-by-side test of the pilot: the current painted PilotSprite (left) and the new
# cut-out PilotRig (right), at battle size (PILOT_HEIGHT 60) on top and 2x below.
# Cycles through idle, aiming, leaning, firing, climbing/dropping and each thruster
# style. Run rig_test.tscn. User arg "fit" (godot ... -- fit) shows the rig large over
# Luna's reference instead, to check how the parts line up.

const H := 60.0
const PHASE_T := 2.6
# name, aim angle (null = no target), lean -1..1, vertical speed px/s, firing, thruster
const PHASES := [
	["Idle", null, 0.0, 0.0, false, "flame"],
	["Aim left", PI - 0.35, 0.0, 0.0, false, "flame"],
	["Aim right", -0.35, 0.0, 0.0, false, "flame"],
	["Aim up + fire (dragging)", -PI / 2.0, 0.0, 0.0, true, "flame"],
	["Lean left (moving left)", null, -1.0, 0.0, false, "flame"],
	["Lean right (moving right)", null, 1.0, 0.0, false, "flame"],
	["Fire up-left", -PI / 2.0 - 0.6, 0.0, 0.0, true, "flame"],
	["Fire up-right", -PI / 2.0 + 0.6, 0.0, 0.0, true, "flame"],
	["Climbing", null, 0.0, -320.0, false, "flame"],
	["Dropping", null, 0.0, 280.0, false, "flame"],
	["Thruster: Plasma Jet", null, 0.0, -120.0, false, "plasma"],
	["Thruster: Pressure Wave", null, 0.0, -120.0, false, "pressure"],
	["Thruster: Gravity Well", null, 0.0, -120.0, false, "gravity"],
	["Thruster: Pixel Burn", null, 0.0, -120.0, false, "pixel"],
	["Thruster: Ion Flame", null, 0.0, -120.0, false, "flame"],
]

var t := 0.0
var rigs: Array = []                 # one Rig per drawn copy (same inputs)
var anims: Array = []
var _stars: Array
var _behind: Node2D                  # additive, behind the pilots (flames)
var _front: Node2D                   # additive, in front (visor light, muzzle flash)
var _label: Label
var fit := false
var _ref: Texture2D
var fire_t := 0.0
var bank_s := 0.0
var vy_s := 0.0
var facing_s := 1.0
var recoil_s := 0.0

func _ready() -> void:
	fit = "fit" in OS.get_cmdline_user_args()
	_stars = Backdrop.make_stars(90, 11)
	for i in 2:
		rigs.append(PilotRig.Rig.new())
		anims.append(PilotSprite.Anim.new())
	var bg := Node2D.new()
	bg.z_index = -2
	bg.draw.connect(func(): Backdrop.draw_sky(bg, get_viewport_rect().size, false, _stars, t))
	add_child(bg)
	_behind = _add_light(-1, _draw_behind)
	_front = _add_light(1, _draw_front)
	_label = Label.new()
	_label.position = Vector2(12, 10)
	_label.add_theme_font_size_override("font_size", 18)
	add_child(_label)
	if fit:
		var img := Image.load_from_file(ProjectSettings.globalize_path("res://art_src/pilot/reference.webp"))
		_ref = ImageTexture.create_from_image(img)

func _add_light(z: int, fn: Callable) -> Node2D:
	var n := Node2D.new()
	n.z_index = z
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	n.material = m
	n.draw.connect(fn)
	add_child(n)
	return n

func phase() -> Array:
	return PHASES[int(t / PHASE_T) % PHASES.size()]

func _process(delta: float) -> void:
	t += delta
	var ph := phase()
	var has_aim: bool = ph[1] != null
	var aim: float = ph[1] if has_aim else -PI / 2.0 - 0.3
	# gentle hover drift so nothing is ever perfectly still, like the battle
	var vy: float = ph[3] + sin(t * 1.3) * 25.0
	bank_s = lerpf(bank_s, float(ph[2]) * 0.3, minf(1.0, delta * 10.0))
	vy_s = lerpf(vy_s, vy, minf(1.0, delta * 6.0))
	var hover := clampf(1.0 - vy_s / 260.0, 0.35, 1.9)
	if has_aim:
		facing_s = move_toward(facing_s, -1.0 if cos(aim) > 0.0 else 1.0, delta * 8.0)
	fire_t -= delta
	var shot := false
	if ph[4] and fire_t <= 0.0:
		fire_t = 0.22
		shot = true
	recoil_s = recoil_s * exp(-delta * 12.0)
	if shot:
		recoil_s = 1.0
	PilotSprite.style = ph[5]
	for r in rigs:
		r.update(delta, aim, bank_s / 0.3, hover, vy_s)
		if shot:
			r.fire()
	var pose := PilotSprite.pose_for(ph[4], bank_s, Vector2(cos(aim), sin(aim)), has_aim)
	for a in anims:
		a.update(pose, delta)
	_label.text = "%s\nleft: painted now   right: new rig" % ph[0] if not fit else "fit: rig over Luna's reference"
	queue_redraw()
	_behind.queue_redraw()
	_front.queue_redraw()
	get_child(0).queue_redraw()

# where each copy is drawn: [pilot sprite pos, rig pos, height]
func _spots() -> Array:
	var w := get_viewport_rect().size.x
	if fit:
		var hh := get_viewport_rect().size.y * 0.8
		return [[Vector2(-999, -999), Vector2(w * 0.5, hh * 0.58), hh], [Vector2(-999, -999), Vector2(w * 0.83, hh * 0.58), hh]]
	return [[Vector2(w * 0.28, 230), Vector2(w * 0.72, 230), H], [Vector2(w * 0.28, 520), Vector2(w * 0.72, 520), H * 2.0]]

func _draw() -> void:
	var spots := _spots()
	if fit:
		# reference alone (left) and under the rig (middle); rig alone on the right
		var s: float = spots[0][2] / PilotRig.BODY_H
		for c in [Vector2(get_viewport_rect().size.x * 0.17, spots[0][1].y), spots[0][1]]:
			draw_set_transform(c - PilotRig.ORIGIN * s, 0.0, Vector2(s, s))
			draw_texture(_ref, Vector2.ZERO, Color(1, 1, 1, 1.0 if c != spots[0][1] else 0.6))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in spots.size():
		var sp: Array = spots[i]
		var a: PilotSprite.Anim = anims[i]
		var pose := a.pose()
		var flip: bool = facing_s < 0.0 if pose.begins_with("aim") else a.mirrored()
		var turn: float = clampf(absf(facing_s), 0.15, 1.0) if pose.begins_with("aim") else 1.0
		PilotSprite.draw(self, sp[0], sp[2], pose, flip, -bank_s * 0.6, t, clampf(1.0 - vy_s / 260.0, 0.35, 1.9),
			clampf(bank_s * 5.0, -1.0, 1.0), smoothstep(0.3, 1.0, recoil_s), a.mix(), turn)
		var r: PilotRig.Rig = rigs[i]
		PilotRig.draw(self, r, PilotRig.solve(r), sp[1], sp[2], 0.0, 0.55 if fit and i == 0 else 1.0)

func _draw_behind() -> void:
	for i in _spots().size():
		var sp: Array = _spots()[i]
		var r: PilotRig.Rig = rigs[i]
		PilotRig.draw_light(_behind, r, PilotRig.solve(r), sp[1], sp[2], PilotSprite.style)

func _draw_front() -> void:
	for i in _spots().size():
		var sp: Array = _spots()[i]
		var r: PilotRig.Rig = rigs[i]
		PilotRig.draw_glow(_front, r, PilotRig.solve(r), sp[1], sp[2])
