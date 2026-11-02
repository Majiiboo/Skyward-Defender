extends Control
# Full-screen AFK underlayer for new Home Hub.
# NOT a box: this layer covers the whole screen, UI sits on top of it.
# Soldier (Hero TextureRect in hub.tscn) is at centre (240, 400), small.
# Enemies descend across the full width, hero + Wingman shoot up,
# no damage, no XP, no save writes. Original art only.
var afk_enemies: Array = []
var afk_bullets: Array = []
var afk_spawn := 0.0
var afk_fire := 0.0
var afk_coins := 0
var afk_bottom := -1.0
var afk_top := -1.0
var afk_pickups: Array = []
func _ready() -> void:
	size = get_viewport_rect().size
func _hero_centre() -> Vector2:
	var h = get_parent().get_node_or_null("Hero")
	if h: return h.position + h.size / 2.0
	return Vector2(240, 400)
func _process(delta: float) -> void:
	afk_spawn -= delta
	if afk_spawn <= 0:
		afk_spawn = 1.0
		afk_enemies.append({"pos": Vector2(randf_range(40, max(80, size.x - 40)), (afk_top if afk_top > 0 else 140)), "speed": 40.0})
	afk_fire -= delta
	if afk_fire <= 0:
		afk_fire = 0.35
		# Auto-aim: aim at nearest enemy with lead (enemy falls 40 px/s,
		# bullet 200 px/s), not straight up — straight up missed most
		# enemies in dev25, so AFK collected stayed at 0.
		var hc := _hero_centre()
		var target := Vector2.ZERO
		var best_d := 1e9
		for e in afk_enemies:
			var d := hc.distance_to(e.pos)
			if d < best_d:
				best_d = d; target = e.pos
		if target != Vector2.ZERO:
			var flight := hc.distance_to(target) / 200.0
			var lead := target + Vector2(0, 40.0) * flight
			var dir := (lead - hc).normalized()
			afk_bullets.append({"pos": hc, "vel": dir * 200.0})
			afk_bullets.append({"pos": hc + Vector2(40, -10), "vel": dir * 200.0})
		else:
			afk_bullets.append({"pos": hc, "vel": Vector2(0, -200)})
	for e in afk_enemies:
		e.pos.y += e.speed * delta
	for b in afk_bullets:
		b.pos += b.vel * delta
	var next_e: Array = []
	for e in afk_enemies:
		var hit := false
		for b in afk_bullets:
			if b.pos.distance_to(e.pos) < 22:
				hit = true
				afk_pickups.append({"pos": e.pos, "value": 5})
		if not hit and e.pos.y < (afk_bottom if afk_bottom > 0 else size.y - 180):
			next_e.append(e)
	afk_enemies = next_e
	afk_bullets = afk_bullets.filter(func(b): return b.pos.y > 130 and b.pos.x > 0 and b.pos.x < size.x)
	var next_p: Array = []
	for pk in afk_pickups:
		pk.pos.y += 60.0 * delta
		if pk.pos.y >= (afk_bottom if afk_bottom > 0 else size.y - 190):
			afk_coins += pk.value
		else:
			next_p.append(pk)
	afk_pickups = next_p
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.04, 0.12))
	draw_circle(Vector2(80, 200), 120, Color(0.1, 0.05, 0.3, 0.35))
	draw_circle(Vector2(400, 400), 140, Color(0.05, 0.2, 0.35, 0.35))
	for i in range(40):
		var sx := float((i * 97) % int(max(1, size.x)))
		var sy := float((i * 53) % int(max(1, size.y)))
		draw_circle(Vector2(sx, sy), 1.5, Color(1, 1, 1, 0.5))
	draw_arc(Vector2(_hero_centre().x, (afk_bottom if afk_bottom > 0 else size.y - 190)), 80, -PI, 0, 32, Color(0.2, 0.85, 1.0), 3.0)
	draw_circle(_hero_centre() + Vector2(40, -10), 10, Color(0.2, 0.85, 1.0))
	draw_circle(_hero_centre() + Vector2(40, -10), 4, Color(1, 1, 1))
	for e in afk_enemies:
		draw_circle(e.pos, 11, Color(1, 0.25, 0.3))
		draw_circle(e.pos, 5, Color(0.3, 0.05, 0.1))
	for b in afk_bullets:
		draw_circle(b.pos, 4, Color(1, 0.85, 0.3))
	for pk in afk_pickups:
		draw_circle(pk.pos, 5, Color(1, 0.8, 0.2))
