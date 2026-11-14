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

# LUNA'S SHOT PICTURES (tools/cut_shots.gd -> fx/shots/<element>_<piece>.png, light on black, the
# front of a single shot pointing +x). null while a piece is not painted: the code shapes stay.
const BALL_FILL := 0.6         # how much of the snowball picture the ball itself fills
const STREAM_TILE := 104.0     # px of stream one copy of the strip covers
const STREAM_FLOW := 430.0     # px a second the spray rushes along the stream
static var _cache := {}

static func tex(element: String, piece: String) -> Texture2D:
	var key := element + "_" + piece
	if not _cache.has(key):
		var p := "res://fx/shots/%s.png" % key
		_cache[key] = load(p) if ResourceLoader.exists(p) else null
	return _cache[key]

# one layer of the painted stream: the strip repeated along the ribbon and scrolled. `s` = for
# every point, how far along it is in strip lengths (rising); a piece that crosses the end of a
# strip is cut there, so the texture never has to wrap.
static func _strip(c: CanvasItem, t2: Texture2D, mid: PackedVector2Array, nrm: PackedVector2Array, hw: PackedFloat32Array, al: PackedFloat32Array, s: PackedFloat32Array, wide: float, dim: float) -> void:
	for i in mid.size() - 1:
		var a0 := s[i]
		var a1 := s[i + 1]
		if a1 - a0 < 0.0001:
			continue
		var cur := a0
		while cur < a1 - 0.0001:
			var base := floorf(cur + 0.00001)
			var nxt := minf(a1, base + 1.0)
			var f0 := (cur - a0) / (a1 - a0)
			var f1 := (nxt - a0) / (a1 - a0)
			var p0 := mid[i].lerp(mid[i + 1], f0)
			var p1 := mid[i].lerp(mid[i + 1], f1)
			var n0 := nrm[i].lerp(nrm[i + 1], f0) * lerpf(hw[i], hw[i + 1], f0) * wide
			var n1 := nrm[i].lerp(nrm[i + 1], f1) * lerpf(hw[i], hw[i + 1], f1) * wide
			var c0 := Color(1, 1, 1, lerpf(al[i], al[i + 1], f0) * dim)
			var c1 := Color(1, 1, 1, lerpf(al[i], al[i + 1], f1) * dim)
			var v0 := 1.0 - (cur - base)
			var v1 := 1.0 - (nxt - base)
			c.draw_polygon(PackedVector2Array([p0 - n0, p1 - n1, p1 + n1, p0 + n0]), PackedColorArray([c0, c1, c1, c0]), PackedVector2Array([Vector2(0, v0), Vector2(0, v1), Vector2(1, v1), Vector2(1, v0)]), t2)
			cur = nxt

# the stream from Luna's strip: thin at the barrel, a wide rushing spray, fading out at its reach
static func _draw_stream_tex(c: CanvasItem, line: PackedVector2Array, t2: Texture2D, t: float, reach: float, element: String = "") -> void:
	var n := line.size()
	var mid := PackedVector2Array()
	var nrm := PackedVector2Array()
	var hw := PackedFloat32Array()
	var al := PackedFloat32Array()
	var s1 := PackedFloat32Array()
	var s2 := PackedFloat32Array()
	var total := 0.0
	for i in range(1, n):
		total += line[i].distance_to(line[i - 1])
	var along := 0.0
	for i in n:
		if i > 0:
			along += line[i].distance_to(line[i - 1])
		var u := clampf(along / maxf(reach, 1.0), 0.0, 1.0)
		var dir: Vector2 = (line[mini(i + 1, n - 1)] - line[maxi(i - 1, 0)]).normalized()
		var nn := dir.orthogonal()
		mid.append(line[i] + nn * sin(along * 0.05 - t * 11.0) * 2.2 * u)
		nrm.append(nn)
		hw.append(lerpf(7.0, 23.0, smoothstep(0.0, 0.4, u)) * (1.0 + 0.3 * smoothstep(0.7, 1.0, u)))
		al.append(smoothstep(0.0, 0.05, u + 0.02) * (1.0 - smoothstep(0.74, 1.0, u)) * smoothstep(0.0, 34.0, total - along))   # the tip always fades out: never a cut edge
		s1.append((along + 4000.0 - fposmod(t * STREAM_FLOW, STREAM_TILE * 400.0) + STREAM_TILE * 400.0) / STREAM_TILE)
		s2.append((along + 4000.0 - fposmod(t * STREAM_FLOW * 0.62, STREAM_TILE * 400.0) + STREAM_TILE * 400.0) / STREAM_TILE * 0.8 + 0.37)
	_strip(c, t2, mid, nrm, hw, al, s2, 1.4, 0.45)   # a wider, slower layer underneath hides the repeat
	_strip(c, t2, mid, nrm, hw, al, s1, 1.0, 1.0)
	# where the stream runs out it breaks up into mist and flakes (Luna's stream_end: the spray
	# comes in at the back of the picture as wide as the strip, so the two join)
	var se := tex(element, "stream_end")
	if se != null and n >= 2 and total > 40.0:
		var ea := maxf(smoothstep(0.5, 0.82, along / maxf(reach, 1.0)) * 0.9, 0.6)
		var ed: Vector2 = (mid[n - 1] - mid[n - 3 if n >= 3 else n - 2]).normalized()
		var es := hw[n - 1] * 2.0 * 1024.0 / 330.0
		var eo: Vector2 = mid[n - 1] - ed * (es * 0.3 + 14.0)
		var ex := ed * es
		var ey := ed.orthogonal() * es * 0.5
		var ec := Color(1, 1, 1, ea)
		c.draw_polygon(PackedVector2Array([eo - ey, eo + ex - ey, eo + ex + ey, eo + ey]), PackedColorArray([ec, ec, ec, ec]), PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]), se)

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
			var pt := tex(element, "pellet_big" if big > 1.2 else "pellet")
			if pt != null:   # Luna's ice shard, its mist trailing behind
				var PS := (46.0 if big > 1.2 else 34.0) * maxf(big, 1.0) * (0.8 if big > 1.2 else 1.0)
				c.draw_texture_rect(pt, Rect2(-PS * 0.55, -PS * 0.5, PS, PS), false, Color.WHITE)
				return true
			c.draw_line(Vector2(-L * 1.7, 0), Vector2(-L * 0.3, 0), Color(glow, 0.35), 2.0)
			if k == "crystal":   # a sharp shard of ice
				c.draw_colored_polygon(PackedVector2Array([Vector2(L * 0.55, 0), Vector2(0, -W * 0.5), Vector2(-L * 0.45, 0), Vector2(0, W * 0.5)]), Color(glow, 0.55))
				c.draw_colored_polygon(PackedVector2Array([Vector2(L * 0.42, 0), Vector2(0, -W * 0.28), Vector2(-L * 0.25, 0), Vector2(0, W * 0.28)]), core)
			else:                # an ember: a hot head, a tail of flame
				c.draw_colored_polygon(PackedVector2Array([Vector2(L * 0.3, 0), Vector2(0, -W * 0.6), Vector2(-L * 0.9 * fl, 0), Vector2(0, W * 0.6)]), Color(glow, 0.7))
				c.draw_circle(Vector2(L * 0.05, 0), W * 0.5, core)
		"ball":
			var r := 5.4 * big
			var bt := tex(element, "snowball")
			if bt != null:   # Luna's snowball: its loose flakes trail behind it
				var S := 21.0 * big / BALL_FILL
				c.draw_circle(Vector2(-r * 1.9, sin(t * 14.0 + seed) * 1.2), r * 0.7, Color(glow, 0.14))
				c.draw_texture_rect(bt, Rect2(-S * 0.5, -S * 0.5, S, S), false, Color(1, 1, 1, 0.96))
				return true
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
			var bo := tex(element, "boulder")
			if bo != null:   # Luna's block of ice: it tumbles as it flies, a trail of frost behind it
				for i in 3:
					c.draw_circle(Vector2(-R * (1.3 + 0.9 * i), sin(t * 9.0 + seed + i * 1.3) * 3.0), R * (0.5 - 0.12 * i), Color(glow, 0.14 - 0.035 * i))
				var BS := R * 3.3
				var spin_a := t * 2.6 + seed
				var bx := Vector2(cos(spin_a), sin(spin_a)) * BS * 0.5
				var by := bx.orthogonal()
				c.draw_polygon(PackedVector2Array([-bx - by, bx - by, bx + by, -bx + by]), PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]), PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]), bo)
				return true
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
	var st := tex(element, "stream")
	if st != null:
		_draw_stream_tex(c, line, st, t, reach, element)
		c.draw_circle(pts[0], 3.0, Color(core, 0.75))
		return
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

# THE FEEL OF FIRING (step 4, 2026-11-14): each class sounds, flashes and lands its own way.
#   snd = the sound of a shot        flash = size of the burst of light at the barrel (0 = none)
#   hit = size of the hit splash     hit_every = show the splash on every Nth bolt only (the stream)
#   hit_snd = the sound of a hit     shake = screen shake when it fires / when it lands
const FEEL := {
	"pellet":  {"snd": "shot_pellet", "flash": 15.0, "hit": 22.0, "hit_every": 1, "hit_snd": "hit", "shake": 0.0, "hit_shake": 0.0},
	"ball":    {"snd": "shot_ball", "flash": 21.0, "hit": 34.0, "hit_every": 1, "hit_snd": "hit_puff", "shake": 0.0, "hit_shake": 0.0},
	"stream":  {"snd": "stream", "flash": 0.0, "hit": 17.0, "hit_every": 3, "hit_snd": "hit_soft", "shake": 0.0, "hit_shake": 0.0},
	"boulder": {"snd": "shot_heavy", "flash": 40.0, "hit": 48.0, "hit_every": 1, "hit_snd": "boom", "shake": 0.16, "hit_shake": 0.3},
}

static func feel(sh: String) -> Dictionary:
	return FEEL.get(sh, FEEL["pellet"])
