extends SceneTree
# Plays real battle stages headless and prints how they went, for balancing.
#
# Run it with a SEPARATE save folder, so your own coins and unlocks are untouched:
# put tools/sim_override.cfg next to project.godot as override.cfg, then
#   godot --headless --path . --script res://tools/balance_sim.gd
# and delete override.cfg afterwards. The script refuses to run on the real save.
#
# Settings (environment variables):
#   SIM_STAGES  "1-10" or "1,2,5"        SIM_RUNS  runs per stage (3)
#   SIM_PILOT   "afk"   = finger never down: auto-aim only, never moves
#               "dodge" = a player who mostly lets auto-aim work, drags (firing
#                         straight up) out of the way of shots and divers, and drags
#                         over to gems that are close when it is safe
#               "skilled" = dodges only when a shot will really hit, never chases gems
#                         (the strongest way to play: auto-aim stays on almost all the time)
#               "human"   = "skilled" with a 0.25 s reaction time and about one dodge in three missed
#   SIM_TURRETS loadout, e.g. "sentry,,," (default: a new player's loadout)
#   SIM_LEVEL   turret level (1)
#   SIM_KIT     "auto" = the gear + turrets a typical player has by that stage (_auto_kit)
#   SIM_PROMO   "0-9" or "2,5": promotion trials by rank index instead of stages (dev144); the
#               kit is the one for the trial's base stage, ranks below it already won
#   SIM_KIT_PLUS n: the auto kit of a player n stages further on (a stronger player, dev144)
#   SIM_ELITE_MODE=1: play the stages in Elite (dev166; no more editing this file for it)
#
# Prints one line per run and a summary per stage.

const DT := 1.0 / 30.0
const MAX_T := 600.0
# cards a sensible player takes first
const CARD_PRIORITY := ["heavy_bolts", "rapid_pulse", "piercing_rounds", "burst_fire", "chain_spark", "frost_rounds", "aegis", "shield_recharge", "turret_overclock", "reinforced_hull", "nova_burst", "magnet"]

var stages: Array = []
var runs := 3
var pilot := "afk"
var loadout: Array = []
var tlevel := 1
var queue: Array = []          # [stage, run]
var b: Node = null
var cur: Array = []
var results := {}              # stage -> Array of run dicts
var steps := 0
var r := {}
var human_move := 0.0

func _initialize() -> void:
	if not OS.get_user_data_dir().to_lower().contains("sim"):
		push_error("balance_sim: user data dir is %s; use tools/sim_override.cfg as override.cfg so the real save is not touched" % OS.get_user_data_dir())
		quit(1)
		return
	var pr := OS.get_environment("SIM_PROMO")
	if pr != "":
		if pr.contains("-"):
			for i in range(int(pr.get_slice("-", 0)), int(pr.get_slice("-", 1)) + 1):
				promos.append(i)
		else:
			for p in pr.split(","):
				promos.append(int(p))
	var s := OS.get_environment("SIM_STAGES")
	if s == "":
		s = "1-10"
	if s.contains("-"):
		for i in range(int(s.get_slice("-", 0)), int(s.get_slice("-", 1)) + 1):
			stages.append(i)
	else:
		for p in s.split(","):
			stages.append(int(p))
	runs = int(OS.get_environment("SIM_RUNS")) if OS.get_environment("SIM_RUNS") != "" else 3
	pilot = OS.get_environment("SIM_PILOT") if OS.get_environment("SIM_PILOT") != "" else "afk"
	var lo := OS.get_environment("SIM_TURRETS")
	loadout = Array(lo.split(",")) if lo != "" else ["sentry", "", "", ""]
	while loadout.size() < 4:
		loadout.append("")
	tlevel = int(OS.get_environment("SIM_LEVEL")) if OS.get_environment("SIM_LEVEL") != "" else 1
	kit_auto = OS.get_environment("SIM_KIT") == "auto"
	if not promos.is_empty():
		stages = []
		for pi in promos:
			stages.append(1000 + pi)   # trials are listed as 1000 + rank in the summary
			for i in runs:
				queue.append([1000 + pi, i])
	else:
		for st in stages:
			for i in runs:
				queue.append([st, i])
	print("SIM pilot=%s turrets=%s lvl=%d runs=%d" % [pilot, loadout, tlevel, runs])
	_next()

func _write_save(stage: int) -> void:
	var promo := stage - 1000 if stage >= 1000 else -1
	if promo >= 0:
		stage = int(Promotion.RANKS[promo].stage)
	var levels := {}
	for t in loadout:
		if t != "":
			levels[t] = tlevel
	# stage_unlocked = stage: a player meeting this stage for the first time, so only the
	# mounts opened by stages before it are open (Turrets.mount_open); every turret type is
	# unlocked (pilot_xp), the loadout says which ones stand on the base
	var d := {"selected_stage": stage, "selected_elite": OS.get_environment("SIM_ELITE_MODE") == "1", "stage_unlocked": stage, "pilot_xp": 100000, "areas_briefed": [0, 1, 2, 3, 4, 5],
		"turrets": {"loadout": loadout, "levels": levels}, "coins": 0}
	if kit_auto:
		_auto_kit(d, stage)
	if promo >= 0:
		Promotion.start(d, promo)
		d["promotion"] = promo
	var f := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()

# SIM_KIT=auto: the gear and turrets a typical player has when meeting `stage`. Coins
# earned so far (ECONOMY.md first-clear table) x1.5 for daily gifts, missions and replays,
# 60% spent on the six gear pieces, 40% on the turrets on the open mounts, all levelled
# evenly (cost of Lv.L: gear 60 L(L-1) a piece, turret 75 L(L-1)).
const COINS_SO_FAR := [[1, 0], [10, 964], [15, 2171], [20, 3964], [25, 5631], [30, 7970], [40, 12816], [50, 18548], [60, 25108]]
var kit_auto := false
var promos: Array = []

static func _coins_before(stage: int) -> float:
	for i in COINS_SO_FAR.size() - 1:
		var a: Array = COINS_SO_FAR[i]
		var z: Array = COINS_SO_FAR[i + 1]
		if stage <= z[0]:
			return lerpf(float(a[1]), float(z[1]), float(stage - a[0]) / float(z[0] - a[0]))
	return float(COINS_SO_FAR[-1][1])

# the highest level L with per * L * (L-1) <= budget
static func _level_for(budget: float, per: float) -> int:
	var lv := 1
	while lv < 10 and per * (lv + 1) * lv <= budget:
		lv += 1
	return lv

func _auto_kit(d: Dictionary, stage: int) -> void:
	stage += int(OS.get_environment("SIM_KIT_PLUS")) if OS.get_environment("SIM_KIT_PLUS") != "" else 0
	var spend := _coins_before(stage) * 1.5
	# heroes (dev172): 60% of the kit goes to the hero: ATK levels and DEF levels (half each), and
	# the one weapon piece; the old armour pieces are gone
	var hero_budget := spend * 0.6
	var wlv := _level_for(hero_budget * 0.2, 120.0)
	var hl := 1
	var hb := hero_budget * 0.5
	while hl < Heroes.MAX_LEVEL and hb >= Heroes.level_cost(hl):
		hb -= Heroes.level_cost(hl)
		hl += 1
	var dl := 1
	var db := hero_budget * 0.3
	while dl < Heroes.MAX_DEF_LEVEL and db >= Heroes.def_cost(dl):
		db -= Heroes.def_cost(dl)
		dl += 1
	d["hero"] = {"selected": "rook", "owned": ["rook"], "levels": {"rook": hl}, "def": {"rook": dl}, "tiers": {}, "shards": {}}
	var glv := wlv
	var lv := {}
	for s in GearData.SLOTS:
		lv["ion_" + s.to_lower()] = glv
	d["gear"] = {"equipped": GearData.DEFAULT.duplicate(), "levels": lv}
	var types := ["sentry", "lance", "storm", "gravity"]
	var lo: Array = ["", "", "", ""]
	var n := 0
	for i in 4:
		if stage > int(Turrets.MOUNT_OPENS_AFTER[i]):
			lo[i] = types[i]
			n += 1
	# each turret's share split evenly over its three tracks (a track costs 60 x level a step)
	var tl := _level_for(spend * 0.4 / maxf(1.0, n) / 3.0, 30.0) if n > 0 else 1
	var ttr := {}
	for t in lo:
		if t != "":
			ttr[t] = {"atk": tl, "rate": tl, "range": tl}
	d["turrets"] = {"loadout": lo, "tracks": ttr}
	r_kit = "hero Lv.%d DEF %d, weapon Lv.%d, %d turrets Lv.%d" % [hl, dl, glv, n, tl]
var r_kit := ""

func _next() -> void:
	if b:
		b.queue_free()
		b = null
	if queue.is_empty():
		_summary()
		quit()
		return
	cur = queue.pop_front()
	_write_save(cur[0])
	b = load("res://battle.tscn").instantiate()
	if b.get_script() == null or not b.has_method("_start_stage"):
		push_error("balance_sim: battle.gd failed to load (script error), stopping")
		quit(1)
		return
	root.add_child(b)
	b.set_process(false)
	b.set_process_input(false)
	steps = 0
	r = {"stage": cur[0], "won": false, "t": 0.0, "wave": 0, "waves": 0, "hearts_lost": 0.0, "min_hull": 100.0,
		"first_heart_wave": -1, "first_base_wave": -1, "kills": 0, "lvl": 1, "cards": [], "pilot_dmg": 0.0, "turret_dmg": 0.0,
		"hit_bullet": 0, "hit_diver": 0, "base_hits": 0}

func _process(_d: float) -> bool:
	if b == null or not b.is_inside_tree():
		return false
	if steps == 0 and b.waves.is_empty():
		return false   # _ready not run yet
	for i in 300:      # 10 s of game time per frame
		if not _step():
			_finish()
			_next()
			return false
	return false

func _step() -> bool:
	steps += 1
	if b.picking:
		_pick()
	var hp_before: float = b.pilot_hp
	var hull_before: float = b.hull
	var shield_before: float = b.shield
	if b.paused:
		push_error("balance_sim: battle is paused (briefing/menu), stopping")
		return false
	if pilot == "dodge" or pilot == "skilled":
		_dodge()
	elif pilot == "human":
		# like "skilled", but decides only every 0.25 s (reaction time) and misses about
		# one dodge in three; between decisions the finger keeps doing what it was doing
		if steps % 8 == 0:
			human_move = 0.0
			var before: Vector2 = b.soldier_pos
			if randf() > 0.3:
				_dodge()
			else:
				b.dragging = false
			human_move = b.soldier_pos.x - before.x
		elif human_move != 0.0:
			b.dragging = true
			b._drag_by(Vector2(human_move, 0))
		else:
			b.dragging = false
	b._process(DT)
	if b.pilot_hp < hp_before:
		r.hearts_lost += hp_before - b.pilot_hp   # HP lost (the column keeps its name)
		if r.first_heart_wave < 0:
			r.first_heart_wave = b.wave_index + 1
	if b.hull < hull_before or b.shield < shield_before:
		r.base_hits += 1
		if r.first_base_wave < 0:
			r.first_base_wave = b.wave_index + 1
	r.min_hull = minf(r.min_hull, b.hull)
	if b.game_over or b.stage_cleared:
		return false
	return b.time_alive < MAX_T

func _pick() -> void:
	var offer: Array = b._offer()
	var best: String = offer[0]
	var bi := 99
	for id in offer:
		if Cards.FUSIONS.has(id):
			best = id   # a fusion always wins
			break
		var k := CARD_PRIORITY.find(id)
		if k >= 0 and k < bi:
			bi = k
			best = id
	r.cards.append(best)
	b._pick_card(best)

# A human-ish player: lets auto-aim work, and when an enemy shot or a diving bug will
# come close in the next 0.7 s, puts a finger down and slides sideways to the safest
# spot (firing straight up while dragging), then lifts the finger again. When nothing
# is coming, it drags over to gems that are close.
const SPEED := 420.0     # how fast a thumb slides him (px/s)
const SAFE := 30.0       # how close a shot may pass (his hit size is 14)

func _threat_dist(p0: Vector2, target_x: float) -> float:
	# smallest distance between him (sliding toward target_x) and any shot or diving bug
	var worst := 9999.0
	for k in 15:
		var t := 0.05 * k
		var px := move_toward(p0.x, target_x, SPEED * t)
		var p := Vector2(px, p0.y)
		for eb in b.enemy_bullets:
			worst = minf(worst, (eb.pos + eb.vel * t).distance_to(p))
		for e in b.enemies:
			if e.type == "diver" and e.state != "fly":
				worst = minf(worst, (e.pos + e.vel * t).distance_to(p) - 8.0)
			elif e.type != "hive_mother":
				worst = minf(worst, (e.pos + e.vel * t).distance_to(p) - 6.0)
	return worst

func _dodge() -> void:
	var p: Vector2 = b.soldier_pos
	var here := _threat_dist(p, p.x)
	var safe: float = 24.0 if pilot != "dodge" else SAFE
	if here < safe:
		var best_x := p.x
		var best_d := here
		for i in range(-10, 11):
			var tx := clampf(p.x + i * 18.0, 30.0, b.FIELD_W - 30.0)
			# prefer small moves and the middle of the screen a little
			var d := _threat_dist(p, tx) - absf(tx - p.x) * 0.02 - absf(tx - b.FIELD_W * 0.5) * 0.01
			if d > best_d:
				best_d = d
				best_x = tx
		b.dragging = true
		b._drag_by(Vector2(clampf(best_x - p.x, -SPEED * DT, SPEED * DT), 0))
		return
	# safe: go and get a gem that is close and above the base (moving means a finger on
	# the screen, so auto-aim pauses), as long as no shot is anywhere near
	var best: Variant = null
	var bd := 150.0
	if here > 90.0 and pilot == "dodge":
		for g in b.gems:
			var dg: float = g.pos.distance_to(p)
			if dg < bd and g.pos.y < b.BASE_Y - 90.0:
				bd = dg
				best = g.pos
	if best != null and bd > 12.0:
		b.dragging = true
		b._drag_by((best - p).limit_length(360.0 * DT))
	else:
		b.dragging = false

func _finish() -> void:
	r.won = b.stage_cleared
	r.t = b.time_alive
	r.wave = b.wave_index + (0 if b.stage_cleared else 1)
	r.waves = b.waves.size()
	r.kills = b.kills
	r.lvl = b.run_level
	r.pilot_dmg = b.stat_pilot_dmg
	r.turret_dmg = b.stat_turret_dmg
	r.hit_bullet = b.stat_hit_bullet
	r.hit_diver = b.stat_hit_diver
	r.pxp = b._xp_gain
	var why := "WIN" if r.won else ("hp" if b.pilot_hp <= 0.0 else ("hull" if b.hull <= 0.0 else "timeout"))
	print(("[%s] " % r_kit if kit_auto else "") + "stage %2d run %d  %-7s wave %2d/%2d  %5.0fs  hp lost %3.0f (shots %d, divers %d)  hull min %3.0f  first heart w%s base w%s  kills %3d  lvl %2d  pilot %3.0f%%  cards %s" % [
		r.stage, cur[1], why, r.wave, r.waves, r.t, r.hearts_lost, r.hit_bullet, r.hit_diver, r.min_hull,
		str(r.first_heart_wave), str(r.first_base_wave), r.kills, r.lvl,
		100.0 * r.pilot_dmg / maxf(r.pilot_dmg + r.turret_dmg, 0.001), ",".join(r.cards.slice(0, 6))])
	if not results.has(r.stage):
		results[r.stage] = []
	results[r.stage].append(r)

func _summary() -> void:
	print("\nSUMMARY pilot=%s" % pilot)
	print("stage  win  avg time  avg wave  hp lost  hull min  pilot dmg share  pilot XP  (sum of wins, level)")
	var total_xp := 0.0
	for st in stages:
		var rs: Array = results.get(st, [])
		if rs.is_empty():
			continue
		var w := 0; var t := 0.0; var wv := 0.0; var hl := 0.0; var hm := 0.0; var ps := 0.0; var px := 0.0; var pw := 0
		for x in rs:
			w += 1 if x.won else 0
			t += x.t; wv += x.wave; hl += x.hearts_lost; hm += x.min_hull
			ps += x.pilot_dmg / maxf(x.pilot_dmg + x.turret_dmg, 0.001)
			if x.won:
				px += x.pxp
				pw += 1
		var n := float(rs.size())
		# pilot XP of a winning run here, and the running total for a player who wins each stage once
		var avg_xp := px / maxf(pw, 1)
		total_xp += avg_xp
		print("%5d  %d/%d  %7.0fs  %4.1f/%-3d  %11.1f  %8.0f  %14.0f%%  %8.0f  (%5.0f, Lv %d)" % [st, w, rs.size(), t / n, wv / n, rs[0].waves, hl / n, hm / n, 100.0 * ps / n, avg_xp, total_xp, Turrets.pilot_level(int(total_xp))])
