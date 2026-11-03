class_name PilotSprite
extends RefCounted
# The pilot's painted poses, the points on them (rifle tip, jetpack nozzle, side
# pods), the swappable thruster styles, and one draw call used by both the battle
# and the Home wallpaper so he looks and moves the same everywhere.

const POSES := {
	"idle":       {"tex": preload("res://pilot/idle.png"),       "body_h": 1.00, "muzzle": Vector2(0.98, 0.33),
		"rocket": Vector2(0.40, 0.86), "rocket_dir": Vector2(0, 1), "shoulders": [Vector2(0.22, 0.42), Vector2(0.80, 0.42)]},
	"aim_1":      {"tex": preload("res://pilot/aim_1.png"),      "body_h": 0.92, "muzzle": Vector2(0.97, 0.05),
		"rocket": Vector2(0.47, 0.82), "rocket_dir": Vector2(0, 1), "shoulders": [Vector2(0.20, 0.45), Vector2(0.82, 0.45)]},
	"aim_2":      {"tex": preload("res://pilot/aim_2.png"),      "body_h": 0.85, "muzzle": Vector2(0.85, 0.02),
		"rocket": Vector2(0.52, 0.80), "rocket_dir": Vector2(0, 1), "shoulders": [Vector2(0.22, 0.48), Vector2(0.84, 0.48)]},
	"aim_3":      {"tex": preload("res://pilot/aim_3.png"),      "body_h": 0.82, "muzzle": Vector2(0.92, 0.02),
		"rocket": Vector2(0.50, 0.80), "rocket_dir": Vector2(0, 1), "shoulders": [Vector2(0.22, 0.46), Vector2(0.84, 0.46)]},
	"aim_4":      {"tex": preload("res://pilot/aim_4.png"),      "body_h": 0.80, "muzzle": Vector2(0.80, 0.02),
		"rocket": Vector2(0.50, 0.82), "rocket_dir": Vector2(0, 1), "shoulders": [Vector2(0.24, 0.44), Vector2(0.84, 0.44)]},
	"idle_b":     {"tex": preload("res://pilot/idle_breath_b.png"), "body_h": 1.00, "muzzle": Vector2(0.98, 0.33),
		"rocket": Vector2(0.40, 0.86), "rocket_dir": Vector2(0, 1), "shoulders": [Vector2(0.22, 0.42), Vector2(0.80, 0.42)]},
	"lean_3":     {"tex": preload("res://pilot/lean_3.png"),     "body_h": 1.00, "muzzle": Vector2(0.98, 0.27),
		"rocket": Vector2(0.50, 0.75), "rocket_dir": Vector2(0.22, 1), "shoulders": [Vector2(0.14, 0.70), Vector2(0.62, 0.30)]},
	"lean_4":     {"tex": preload("res://pilot/lean_4.png"),     "body_h": 1.00, "muzzle": Vector2(0.98, 0.27),
		"rocket": Vector2(0.50, 0.75), "rocket_dir": Vector2(0.25, 1), "shoulders": [Vector2(0.14, 0.72), Vector2(0.62, 0.30)]},
	"right_3x":   {"tex": preload("res://pilot/right_3x.png"),   "body_h": 1.00, "muzzle": Vector2(0.98, 0.28),
		"rocket": Vector2(0.52, 0.74), "rocket_dir": Vector2(-0.22, 1), "shoulders": [Vector2(0.10, 0.50), Vector2(0.88, 0.48)]},
	"right_4x":   {"tex": preload("res://pilot/right_4x.png"),   "body_h": 1.00, "muzzle": Vector2(0.98, 0.28),
		"rocket": Vector2(0.52, 0.74), "rocket_dir": Vector2(-0.25, 1), "shoulders": [Vector2(0.10, 0.52), Vector2(0.88, 0.48)]},
	"aim_up":     {"tex": preload("res://pilot/aim_up.png"),     "body_h": 0.79, "muzzle": Vector2(0.14, 0.02),
		"rocket": Vector2(0.46, 0.90), "rocket_dir": Vector2(0, 1), "shoulders": [Vector2(0.38, 0.40), Vector2(0.85, 0.78)]},
	"lean_1":     {"tex": preload("res://pilot/lean_1.png"),     "body_h": 1.00, "muzzle": Vector2(0.98, 0.28),
		"rocket": Vector2(0.49, 0.76), "rocket_dir": Vector2(0.15, 1), "shoulders": [Vector2(0.14, 0.60), Vector2(0.70, 0.30)]},
	"lean_2":     {"tex": preload("res://pilot/lean_2.png"),     "body_h": 1.00, "muzzle": Vector2(0.98, 0.27),
		"rocket": Vector2(0.52, 0.74), "rocket_dir": Vector2(0.2, 1), "shoulders": [Vector2(0.14, 0.66), Vector2(0.66, 0.30)]},
	"lean_left":  {"tex": preload("res://pilot/lean_left.png"),  "body_h": 1.00, "muzzle": Vector2(0.98, 0.27),
		"rocket": Vector2(0.50, 0.75), "rocket_dir": Vector2(0.25, 1), "shoulders": [Vector2(0.14, 0.72), Vector2(0.62, 0.30)]},
	"right_1":    {"tex": preload("res://pilot/right_1.png"),    "body_h": 1.00, "muzzle": Vector2(0.98, 0.30),
		"rocket": Vector2(0.47, 0.80), "rocket_dir": Vector2(-0.1, 1), "shoulders": [Vector2(0.18, 0.40), Vector2(0.84, 0.42)]},
	"right_2":    {"tex": preload("res://pilot/right_2.png"),    "body_h": 1.00, "muzzle": Vector2(0.98, 0.30),
		"rocket": Vector2(0.50, 0.77), "rocket_dir": Vector2(-0.18, 1), "shoulders": [Vector2(0.14, 0.44), Vector2(0.86, 0.46)]},
	"lean_right": {"tex": preload("res://pilot/right_3.png"),    "body_h": 1.00, "muzzle": Vector2(0.98, 0.28),
		"rocket": Vector2(0.52, 0.74), "rocket_dir": Vector2(-0.25, 1), "shoulders": [Vector2(0.10, 0.52), Vector2(0.88, 0.48)]},
}
# Pose chains from idle out to each held pose. The Anim below walks along them,
# so a change of pose is a short sequence of painted frames, not a cut.
const CHAINS := {
	"aim_up":     [["idle", false], ["aim_1", false], ["aim_2", false], ["aim_3", false], ["aim_4", false], ["aim_up", false]],
	"lean_left":  [["idle", false], ["lean_1", false], ["lean_2", false], ["lean_3", false], ["lean_4", false], ["lean_left", false]],
	"lean_right": [["idle", false], ["right_1", false], ["right_2", false], ["right_3x", false], ["right_4x", false], ["lean_right", false]],
	"idle":       [["idle", false], ["idle_b", false]],
}
const STEP_TIME := 0.04
const BREATH_TIME := 0.9

class Anim:
	# Keeps the pilot's current frame and walks toward the wanted pose. Each step
	# cross-fades from the previous frame (mix), and the idle breath blends between
	# idle and idle_b on a smooth curve, so no frame ever cuts.
	var chain := "idle"
	var step := 0
	var t := 0.0
	var breath := 0.0
	var prev := ""             # frame being faded out
	var blend := 1.0           # 0 = just changed, 1 = fully on the new frame
	func update(target: String, delta: float) -> void:
		t += delta
		blend = minf(blend + delta / PilotSprite.STEP_TIME, 1.0)
		var before := pose()
		if chain == "idle" and target == "idle":
			breath += delta
			step = 0
			t = 0.0
		else:
			breath = 0.0
			while t >= PilotSprite.STEP_TIME:
				t -= PilotSprite.STEP_TIME
				if target == chain:
					step = mini(step + 1, PilotSprite.CHAINS[chain].size() - 1)
				elif step > 0:
					step = (0 if chain == "idle" else step - 1)
				else:
					chain = target
					step = mini(1, PilotSprite.CHAINS[chain].size() - 1)
		if pose() != before:
			prev = before
			blend = 0.0
	func frame() -> Array:
		return PilotSprite.CHAINS[chain][step]
	func pose() -> String:
		return frame()[0]
	func mirrored() -> bool:
		return frame()[1]
	# [frame drawn over pose(), its alpha]: the fading previous frame, or the breath.
	func mix() -> Array:
		if blend < 1.0 and prev != "":
			return [prev, 1.0 - blend]
		if chain == "idle" and step == 0 and breath > 0.0:
			return ["idle_b", 0.5 - 0.5 * cos(breath * PI / PilotSprite.BREATH_TIME)]
		return ["", 0.0]

const CYAN := Color(0.2, 0.85, 1.0)
const PURPLE := Color(0.71, 0.55, 1.0)

# Thruster (propulsion) styles. The pilot's "thruster" cosmetic. Add a style =
# add an entry here and a branch in draw_thruster. Saved under "thruster".
const THRUSTERS := {
	"flame":    {"name": "Ion Flame",     "desc": "Classic blue-white exhaust.",            "rarity": "common"},
	"plasma":   {"name": "Plasma Jet",    "desc": "A tight white core with crackling arcs.", "rarity": "rare"},
	"pressure": {"name": "Pressure Wave", "desc": "Rings of force pushed out from the nozzle.", "rarity": "rare"},
	"gravity":  {"name": "Gravity Well",  "desc": "Space bends and sparks fall in, no fire.", "rarity": "epic"},
	"pixel":    {"name": "Pixel Burn",    "desc": "Chunky retro puffs.",                     "rarity": "epic"},
}
static var style := "flame"

static func load_style() -> void:
	if FileAccess.file_exists("user://skybound_save.json"):
		var f := FileAccess.open("user://skybound_save.json", FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if typeof(d) == TYPE_DICTIONARY and THRUSTERS.has(d.get("thruster", "")):
				style = d["thruster"]

static func rect(pose: String, height: float) -> Rect2:
	var pd: Dictionary = POSES[pose]
	var tex: Texture2D = pd.tex
	var s: float = height / (tex.get_height() * float(pd.body_h))
	var dsize := tex.get_size() * s
	return Rect2(Vector2(-dsize.x * 0.5, height * 0.5 - dsize.y), dsize)

static func point(pose: String, height: float, p: Vector2, flip: bool) -> Vector2:
	var r := rect(pose, height)
	var x: float = (1.0 - p.x) if flip else p.x
	return r.position + Vector2(x * r.size.x, p.y * r.size.y)

static func muzzle(pose: String, height: float, flip: bool) -> Vector2:
	return point(pose, height, POSES[pose].muzzle, flip)

static func pose_for(dragging: bool, bank: float, aim_dir: Vector2, has_aim: bool) -> String:
	if dragging:
		return "aim_up"
	if bank > 0.10:
		return "lean_right"
	if bank < -0.10:
		return "lean_left"
	if has_aim:
		var ang := aim_dir.angle()
		if absf(ang + PI / 2.0) < 0.45:
			return "aim_up"
		# both leans hold the rifle to the right; lean the body toward the target
		return "lean_right" if aim_dir.x > 0.0 else "lean_left"
	return "idle"

static func draw_thruster(c: CanvasItem, origin: Vector2, dir: Vector2, power: float, t: float, k: float, width: float = 4.0) -> void:
	# origin/dir in the current transform. power ~ 0.35 (idle drift) .. 1.9 (climbing).
	var perp := Vector2(-dir.y, dir.x)
	var flick: float = 0.8 + 0.2 * sin(t * 32.0)
	var L: float = (14.0 + 6.0 * flick) * power * k
	var W: float = (width * 0.75 + width * 0.5 * power) * k
	match style:
		"plasma":
			c.draw_colored_polygon(PackedVector2Array([origin - perp * W * 0.6, origin + perp * W * 0.6, origin + dir * L * 1.1]), Color(0.75, 0.95, 1.0, 0.45))
			c.draw_colored_polygon(PackedVector2Array([origin - perp * W * 0.3, origin + perp * W * 0.3, origin + dir * L * 0.8]), Color(1, 1, 1, 0.95))
			for i in 3:
				var a := origin + dir * L * (0.25 + 0.25 * i) + perp * sin(t * 50.0 + i * 2.1) * W * 1.4
				var b := origin + dir * L * (0.45 + 0.25 * i) + perp * sin(t * 47.0 + i * 1.3 + 1.0) * W * 1.4
				c.draw_line(a, b, Color(0.6, 0.95, 1.0, 0.8), 1.2 * k, true)
			c.draw_circle(origin, W * 0.8, Color(1, 1, 1, 0.7))
		"pressure":
			for i in 4:
				var ph := fmod(t * 2.2 + float(i) * 0.25, 1.0)
				var centre := origin + dir * L * ph
				c.draw_arc(centre, W * (0.6 + ph * 1.8), dir.angle() - 1.1, dir.angle() + 1.1, 10, Color(CYAN, (1.0 - ph) * 0.8), 1.6 * k, true)
			c.draw_circle(origin, W * 0.6, Color(CYAN, 0.6))
		"gravity":
			c.draw_circle(origin + dir * L * 0.35, L * 0.45, Color(0.1, 0.02, 0.2, 0.35))
			c.draw_arc(origin + dir * L * 0.35, L * 0.45, 0.0, TAU, 20, Color(PURPLE, 0.5), 1.2 * k, true)
			for i in 6:
				var ph := fmod(t * 1.5 + float(i) * 0.167, 1.0)
				var ang := float(i) * 1.047 + t * 0.8
				var p := origin + dir * L * (0.35 + (1.0 - ph) * 0.9) + Vector2(cos(ang), sin(ang)) * L * 0.6 * (1.0 - ph)
				c.draw_circle(p, 1.6 * k, Color(0.85, 0.7, 1.0, ph))
			c.draw_circle(origin, W * 0.5, Color(PURPLE, 0.8))
		"pixel":
			var cell := 3.0 * k
			var n := int(L / cell)
			for i in n:
				var frac := float(i) / maxf(float(n), 1.0)
				var jitter: float = (float(int(t * 18.0 + i * 7) % 3) - 1.0) * cell
				var p := origin + dir * cell * i + perp * jitter * (1.0 - frac)
				var col := Color(1, 1, 1, 0.9) if frac < 0.3 else (Color(CYAN, 0.8) if frac < 0.7 else Color(0.2, 0.4, 1.0, 0.5))
				c.draw_rect(Rect2(p - Vector2(cell, cell) * (0.5 + 0.5 * (1.0 - frac)), Vector2(cell, cell) * (1.0 + (1.0 - frac))), col)
		_:
			c.draw_colored_polygon(PackedVector2Array([origin - perp * W, origin + perp * W, origin + dir * L]), Color(CYAN, 0.55))
			c.draw_colored_polygon(PackedVector2Array([origin - perp * W * 0.5, origin + perp * W * 0.5, origin + dir * L * 0.55]), Color(0.9, 1.0, 1.0, 0.8))
			c.draw_circle(origin, W * 0.9, Color(0.7, 0.95, 1.0, 0.5))

# mix = Anim.mix(): a frame drawn over the pose at an alpha (cross-fades).
# turn = 0..1 width while he turns round (the mirror flip squeezes through
# instead of snapping). flash = 0..1 muzzle flash, fades smoothly.
static func draw(c: CanvasItem, pos: Vector2, height: float, pose: String, flip: bool, tilt: float, t: float,
		hover: float = 1.0, side_push: float = 0.0, flash: float = 0.0, mix: Array = ["", 0.0], turn: float = 1.0, alpha: float = 1.0) -> void:
	var pd: Dictionary = POSES[pose]
	var r := rect(pose, height)
	var k := height / 60.0
	c.draw_set_transform(pos, tilt, Vector2.ONE)
	var rk: Vector2 = point(pose, height, pd.rocket, flip)
	var rdir: Vector2 = pd.rocket_dir
	if flip:
		rdir.x = -rdir.x
	draw_thruster(c, rk, rdir.normalized(), hover, t, k)
	var push: float = clampf(absf(side_push), 0.0, 1.0)
	if push > 0.05:
		var pods: Array = pd.shoulders
		var sp_i: int = 0 if side_push > 0.0 else 1
		if flip:
			sp_i = 1 - sp_i
		var pod: Vector2 = point(pose, height, pods[sp_i], flip)
		var out_dir := Vector2(-signf(side_push) * 0.35, 1.0).normalized()
		draw_thruster(c, pod, out_dir, push * 0.7, t, k, 2.6)
	c.draw_set_transform(pos, tilt * (-1.0 if flip else 1.0), Vector2((-1.0 if flip else 1.0) * turn, 1.0))
	c.draw_texture_rect(pd.tex, r, false, Color(1, 1, 1, alpha))
	if String(mix[0]) != "" and float(mix[1]) > 0.01 and POSES.has(mix[0]):
		c.draw_texture_rect(POSES[mix[0]].tex, rect(mix[0], height), false, Color(1, 1, 1, float(mix[1]) * alpha))
	if flash > 0.01:
		c.draw_set_transform(pos, tilt, Vector2.ONE)
		var m := point(pose, height, pd.muzzle, flip)
		c.draw_circle(m, (2.0 + 3.0 * flash) * k, Color(0.85, 1.0, 1.0, 0.9 * flash))
		c.draw_circle(m, (4.0 + 5.0 * flash) * k, Color(CYAN, 0.35 * flash))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
