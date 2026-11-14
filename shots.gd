class_name Shots
extends RefCounted
# WHAT EACH WEAPON FIRES (Rudy, 2026-11-14). The CLASS gives the shot its shape, the hero's ELEMENT
# decides what it is made of:
#   sidearm = PELLETS (small, quick)      twin = BALLS (round, one from each hand)
#   main    = a STREAM (bolts drawn as one flowing ribbon)      heavy = ONE BIG SHOT
# The penguin (frost): ice pellets, snowballs, a freeze stream, a boulder of ice.
# Ember (solar): embers, fireballs, a fire stream, a great fireball.
# The other four have no design of their own yet: the same shapes as plain energy in their colour.
# Everything is drawn in code on battle's ADDITIVE light layer (it only adds light: no dark edges),
# with the transform already set to the bullet (x = the way it flies).

const SHAPE := {"sidearm": "pellet", "twin": "ball", "main": "stream", "heavy": "boulder"}
const KIND := {"frost": "crystal", "solar": "flame"}          # anything else = "energy"
# what the rifle's stream does to a bug, by element ("slow" = today's chill; the others keep
# "slow" until each hero's own effect is designed)
const STREAM_FX := {"frost": "slow", "solar": "burn"}
const STREAM_GAP := 170.0      # two stream bolts further apart than this are not joined (a pause in the firing)

static func shape(cls: String) -> String:
	return String(SHAPE.get(cls, "pellet"))

static func kind(element: String) -> String:
	return String(KIND.get(element, "energy"))

static func stream_fx(element: String) -> String:
	return String(STREAM_FX.get(element, "slow"))

# [core, glow] colours
static func colours(element: String) -> Array:
	match kind(element):
		"crystal":
			return [Color(0.93, 0.98, 1.0), Color(0.45, 0.8, 1.0)]
		"flame":
			return [Color(1.0, 0.93, 0.62), Color(1.0, 0.42, 0.1)]
	var ec: Color = Heroes.element_color(element)
	return [ec.lerp(Color.WHITE, 0.7), ec]

# one line for the Weapons screen
static func text(element: String, cls: String) -> String:
	var k := kind(element)
	var words := {
		"crystal": {"pellet": "Ice pellets", "ball": "Snowballs", "stream": "Freeze stream", "boulder": "Ice boulder"},
		"flame": {"pellet": "Embers", "ball": "Fireballs", "stream": "Fire stream", "boulder": "Great fireball"},
		"energy": {"pellet": "Energy bolts", "ball": "Energy orbs", "stream": "Energy stream", "boulder": "Heavy orb"},
	}
	return String(words[k][shape(cls)])

# Draws one hero bullet. `sh` = its shape, `big` = 1 or more (charged, crit), `seed` = its own
# number, `t` = the battle clock. Returns false when this element + shape has no look of its own
# (the caller then draws Luna's bolt as before).
static func draw(c: CanvasItem, sh: String, element: String, big: float, seed: int, t: float) -> bool:
	var k := kind(element)
	if k == "energy" and sh == "pellet":
		return false
	var cols := colours(element)
	var core: Color = cols[0]
	var glow: Color = cols[1]
	var fl := 0.85 + 0.15 * sin(t * 31.0 + seed * 1.7)   # flicker
	match sh:
		"pellet":
			var L := 15.0 * big
			var W := 4.6 * big
			c.draw_line(Vector2(-L * 1.7, 0), Vector2(-L * 0.3, 0), Color(glow, 0.35), 2.0)
			if k == "crystal":   # a sharp shard of ice
				c.draw_colored_polygon(PackedVector2Array([Vector2(L * 0.55, 0), Vector2(0, -W * 0.5), Vector2(-L * 0.45, 0), Vector2(0, W * 0.5)]), Color(glow, 0.55))
				c.draw_colored_polygon(PackedVector2Array([Vector2(L * 0.42, 0), Vector2(0, -W * 0.28), Vector2(-L * 0.25, 0), Vector2(0, W * 0.28)]), core)
			else:                # an ember: a hot head, a tail of flame
				c.draw_colored_polygon(PackedVector2Array([Vector2(L * 0.3, 0), Vector2(0, -W * 0.6), Vector2(-L * 0.9 * fl, 0), Vector2(0, W * 0.6)]), Color(glow, 0.7))
				c.draw_circle(Vector2(L * 0.05, 0), W * 0.5, core)
		"ball":
			var r := 5.4 * big
			for i in 3:   # a short trail of puffs
				c.draw_circle(Vector2(-r * (1.5 + 1.3 * i), sin(t * 14.0 + seed + i) * 1.2), r * (0.55 - 0.13 * i), Color(glow, 0.22 - 0.06 * i))
			c.draw_circle(Vector2.ZERO, r * 1.7, Color(glow, 0.2))
			if k == "flame":
				c.draw_colored_polygon(PackedVector2Array([Vector2(r * 0.4, -r * 0.9), Vector2(-r * 2.6 * fl, 0), Vector2(r * 0.4, r * 0.9)]), Color(glow, 0.65))
				c.draw_circle(Vector2.ZERO, r, Color(glow.lerp(core, 0.4), 0.95))
				c.draw_circle(Vector2(r * 0.15, 0), r * 0.55, core)
			else:
				c.draw_circle(Vector2.ZERO, r, Color(core, 0.95) if k == "crystal" else Color(glow.lerp(core, 0.5), 0.95))
				c.draw_circle(Vector2(r * 0.25, -r * 0.3), r * 0.42, Color(1, 1, 1, 0.9))   # the lit side
		"stream":
			# only a glint: the stream itself is ONE ribbon through all its bolts (draw_stream)
			c.draw_circle(Vector2.ZERO, 2.2 * big, Color(core, 0.7))
		"boulder":
			var R := 12.0 * big
			for i in 4:
				c.draw_circle(Vector2(-R * (1.2 + 0.9 * i), sin(t * 9.0 + seed + i * 1.3) * 3.0), R * (0.5 - 0.1 * i), Color(glow, 0.2 - 0.04 * i))
			c.draw_circle(Vector2.ZERO, R * 1.7, Color(glow, 0.16))
			if k == "crystal":   # a jagged block of ice, turning
				var pts := PackedVector2Array()
				var inner := PackedVector2Array()
				var spin := t * 3.0 + seed
				for i in 8:
					var a := spin + TAU * i / 8.0
					var rr := R * (0.82 + 0.3 * absf(sin(seed * 3.1 + i * 2.4)))
					pts.append(Vector2(cos(a), sin(a)) * rr)
					inner.append(Vector2(cos(a + 0.3), sin(a + 0.3)) * rr * 0.55)
				c.draw_colored_polygon(pts, Color(glow.lerp(core, 0.35), 0.9))
				c.draw_colored_polygon(inner, core)
				for i in 8:
					c.draw_line(inner[i], pts[i], Color(1, 1, 1, 0.45), 1.0)
			else:
				if k == "flame":
					c.draw_colored_polygon(PackedVector2Array([Vector2(R * 0.3, -R), Vector2(-R * 2.8 * fl, 0), Vector2(R * 0.3, R)]), Color(glow, 0.6))
				c.draw_circle(Vector2.ZERO, R, Color(glow.lerp(core, 0.3), 0.95))
				c.draw_circle(Vector2(R * 0.12, 0), R * 0.6 * fl, core)
		_:
			return false
	return true

# THE RIFLE'S STREAM (Rudy: a long steady stream with a range, that waves like a water gun when he
# moves). `pts` = the muzzle, then every stream bolt in the air from the newest to the oldest:
# each bolt keeps flying the way it was fired, so moving sideways bends the ribbon. Drawn with no
# transform set. `reach` = the weapon's range in px (the ribbon thins and fades toward it).
static func draw_stream(c: CanvasItem, pts: PackedVector2Array, element: String, t: float, reach: float) -> void:
	if pts.size() < 2:
		return
	var k := kind(element)
	var cols := colours(element)
	var core: Color = cols[0]
	var glow: Color = cols[1]
	# smooth the corners: two passes of corner cutting, the ends kept
	var line := pts
	for pass_i in 2:
		var sm := PackedVector2Array([line[0]])
		for i in line.size() - 1:
			sm.append(line[i].lerp(line[i + 1], 0.25))
			sm.append(line[i].lerp(line[i + 1], 0.75))
		sm.append(line[line.size() - 1])
		line = sm
	var n := line.size()
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var cl := PackedColorArray()
	var mid := PackedVector2Array()
	var along := 0.0
	for i in n:
		if i > 0:
			along += line[i].distance_to(line[i - 1])
		var u := clampf(along / maxf(reach, 1.0), 0.0, 1.0)
		var dir: Vector2 = (line[mini(i + 1, n - 1)] - line[maxi(i - 1, 0)]).normalized()
		var nrm := dir.orthogonal()
		# it leaves the barrel thin, swells into a spray, and frays out at the end of its reach
		var w := lerpf(4.0, 12.5 if k == "flame" else 10.5, smoothstep(0.0, 0.5, u)) * (1.0 - 0.45 * smoothstep(0.75, 1.0, u))
		var wave := sin(along * 0.07 - t * 16.0) * 1.8 * u
		var p: Vector2 = line[i] + nrm * wave
		w *= 0.9 + 0.1 * sin(along * 0.21 - t * 23.0)
		left.append(p - nrm * w)
		right.append(p + nrm * w)
		mid.append(p)
		cl.append(Color(glow, (0.62 if k == "flame" else 0.5) * (1.0 - 0.7 * smoothstep(0.55, 1.0, u))))
	for i in n - 1:   # a soft outer spray first, twice as wide
		var a0 := Color(cl[i], cl[i].a * 0.32)
		var a1 := Color(cl[i + 1], cl[i + 1].a * 0.32)
		c.draw_polygon(PackedVector2Array([mid[i] + (left[i] - mid[i]) * 1.9, mid[i + 1] + (left[i + 1] - mid[i + 1]) * 1.9, mid[i + 1] + (right[i + 1] - mid[i + 1]) * 1.9, mid[i] + (right[i] - mid[i]) * 1.9]), PackedColorArray([a0, a1, a1, a0]))
	for i in n - 1:
		c.draw_polygon(PackedVector2Array([left[i], left[i + 1], right[i + 1], right[i]]), PackedColorArray([cl[i], cl[i + 1], cl[i + 1], cl[i]]))
	c.draw_polyline(mid, Color(core, 0.8), 2.4, true)
	# glints riding up the stream: frost sparkle, or sparks of fire
	var total := maxf(along, 1.0)
	for g in 5:
		var want := fposmod(t * 300.0 + g * total / 5.0, total)
		var run := 0.0
		for i in range(1, n):
			var seg := mid[i].distance_to(mid[i - 1])
			if run + seg >= want:
				var gp: Vector2 = mid[i - 1].lerp(mid[i], (want - run) / maxf(seg, 0.01))
				c.draw_circle(gp + Vector2(sin(g * 2.1 + t * 9.0) * 3.0, 0), 1.5, Color(1, 1, 1, 0.85) if k != "flame" else Color(1.0, 0.95, 0.6, 0.9))
				break
			run += seg
	c.draw_circle(pts[0], 4.0, Color(core, 0.9))   # the bright mouth of the barrel
