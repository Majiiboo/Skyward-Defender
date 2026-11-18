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
#   SIM_PILOT   "afk"   = finger never down, MANUAL: he stands still and fires straight up
#               "auto"  = finger never down, AUTO on: the in-game autopilot plays
#               "human" = a player in MANUAL: flies under bugs, dodges, 0.25 s reactions (the others are older bots)
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
var human_x := -1.0
# per-wave log (REVIEW-base-collapse.md): one WV line per wave when SIM_WAVELOG=1
var _wl := OS.get_environment("SIM_WAVELOG") == "1"
var _w := {}
var _w_seen := {}
var _mode := "idle"
# what-if switches for the test player (sim only; the game is not changed):
#   SIM_PICK=dmg   takes the plain damage cards first, never a defensive card while one is offered
#   SIM_LOW=n      the human bot hovers n px above the base line (the game starts him at 200)
#   SIM_SHARP=1    the human bot decides every 0.13 s and never misses a decision
#   SIM_TOUGH=0    the dev272 tougher-bugs dials off (battle TOUGH_ON), to see how much they weigh
var _pick_mode := OS.get_environment("SIM_PICK")
var _low := float(OS.get_environment("SIM_LOW")) if OS.get_environment("SIM_LOW") != "" else 0.0
var _sharp := OS.get_environment("SIM_SHARP") == "1"
const DMG_FIRST := ["heavy_bolts", "rapid_pulse", "burst_fire", "split_shot", "rook_twin", "piercing_rounds", "chain_spark", "killer_instinct", "seeker", "hot_rounds", "frost_rounds", "shield_recharge", "reinforced_hull"]

func _initialize() -> void:
	Promotion.TWISTS = false   # no daily stage twists in a sweep: the numbers must not change with the date
	if OS.get_environment("SIM_TOUGH") == "0":
		load("res://battle.gd").TOUGH_ON = false
	if OS.get_environment("SIM_WAVES") != "":   # what-if dials for the card rework
		StageData.WAVE_MULT = float(OS.get_environment("SIM_WAVES"))
	if OS.get_environment("SIM_STEEP") != "":
		load("res://battle.gd").XP_STEEP = int(OS.get_environment("SIM_STEEP"))
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
		"turrets": {"loadout": loadout, "levels": levels, "owned": loadout}, "coins": 0}
	d["auto_play"] = pilot == "auto"   # in the save too: the stage start reads it back (a first run used to fall to manual, standing still)
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
	# heroes (dev172): 60% of the kit goes to the hero: levels (ATK + HP + DEF in one since dev186) and
	# the one weapon piece; the old armour pieces are gone
	var hero_budget := spend * 0.6
	var wlv := _level_for(hero_budget * 0.2, 120.0)
	# stars by stage (DESIGN-stars.md): 2 from stage 10, 3 from 20, 4 from 35, 5 from 50; the star
	# caps the hero level and every turret track, and multiplies power (Gates.power_mult)
	var star := 1 + (1 if stage >= 10 else 0) + (1 if stage >= 20 else 0) + (1 if stage >= 35 else 0) + (1 if stage >= 50 else 0)
	if OS.get_environment("SIM_STAR") != "":
		star = int(OS.get_environment("SIM_STAR"))
	var hl := 1
	var hb := hero_budget * 0.8
	while hl < Gates.level_cap("hero", star) and hb >= Heroes.level_cost(hl):   # capped by the star
		hb -= Heroes.level_cost(hl)
		hl += 1
	var dl := 1
	var db := 0.0
	while dl < Heroes.MAX_DEF_LEVEL and db >= Heroes.def_cost(dl):
		db -= Heroes.def_cost(dl)
		dl += 1
	d["hero"] = {"selected": "rook", "owned": ["rook"], "levels": {"rook": hl}, "def": {"rook": dl}, "tiers": {"rook": star}, "shards": {}}
	var glv := wlv
	var lv := {}
	for s in GearData.SLOTS:
		lv["ion_" + s.to_lower()] = glv
	d["gear"] = {"equipped": GearData.DEFAULT.duplicate(), "levels": lv}
	# SIM_HERO / SIM_WEAPON (2026-11-16, weapons step 6): any hero with any of his four weapon
	# classes, at the level the kit affords (capped by his step, as in the game)
	var sim_hero := OS.get_environment("SIM_HERO")
	var sim_cls := OS.get_environment("SIM_WEAPON")
	if sim_hero != "" and Heroes.ROSTER.has(sim_hero):
		d["hero"] = {"selected": sim_hero, "owned": ["rook", sim_hero], "levels": {sim_hero: hl}, "def": {sim_hero: dl}, "tiers": {sim_hero: star}, "shards": {}}
	if sim_cls != "":
		var hid := sim_hero if sim_hero != "" else "rook"
		var wl := mini(wlv, Arsenal.cap(d, hid))
		if OS.get_environment("SIM_WLV") != "":
			wl = int(OS.get_environment("SIM_WLV"))
		d["arsenal"] = {hid: {"equipped": sim_cls, "owned": Arsenal.ORDER.duplicate(), "levels": {sim_cls: wl}}}
		# SIM_CHIPS (2026-11-16): what sits in the weapon s three slots: unset = its own chips (the default),
		# "none" = empty, or three ids by comma ("shape3,cap,over"); general chips are owned for the run
		var sim_chips := OS.get_environment("SIM_CHIPS")
		if sim_chips != "":
			var row: Array = ["", "", ""]
			var own: Array = []
			if sim_chips != "none":
				var parts := sim_chips.split(",")
				for i in mini(parts.size(), 3):
					row[i] = String(parts[i])
					if Chips.CHIPS.has(String(parts[i])):
						own.append(String(parts[i]))
			d["chips"] = {"owned": own, "fit": {Arsenal.key(hid, sim_cls): row}}
			if row.has("special"):
				d["special_test"] = true   # the Specialty chip without earning the mastery
		_wkit = " %s %s Lv.%d" % [hid, sim_cls, wl]
	var types := ["sentry", "lance", "storm", "gravity"]
	var lo: Array = ["", "", "", ""]
	var n := 0
	for i in 4:
		if stage > int(Turrets.MOUNT_OPENS_AFTER[i]):
			lo[i] = types[i]
			n += 1
	# each turret's share split evenly over its three tracks (a track costs 60 x level a step)
	var tl := mini(_level_for(spend * 0.4 / maxf(1.0, n) / 3.0, 30.0), Gates.level_cap("turret", star)) if n > 0 else 1
	var ttr := {}
	var tst := {}
	for t in lo:
		if t != "":
			ttr[t] = {"atk": tl, "rate": tl, "range": tl}
			tst[t] = star
	d["turrets"] = {"loadout": lo, "tracks": ttr, "stars": tst}
	# the base (Base, 2026-11-10, in place of turrets): a typical player fields what the stage has opened, levelled with the campaign
	var bl := clampi(1 + stage / 7, 1, Base.MAX_LEVEL)
	var bslots: Array = ["", "", "", ""]
	var blv := {}
	var bi := 0
	for bid in ["shield_gen", "armory", "medbay", "repair_bay"]:
		if bi < 4 and stage > int(Base.BUILDINGS[bid].from):
			bslots[bi] = bid
			blv[bid] = bl
			bi += 1
	d["base"] = {"slots": bslots, "levels": blv}
	r_kit = "hero Lv.%d %d-star DEF %d, weapon Lv.%d, %d turrets Lv.%d" % [hl, star, dl, glv, n, tl] + _wkit
var _wkit := ""
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
	b.auto_on = pilot == "auto"   # AUTO only for the "auto" pilot; every other bot plays in MANUAL
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

var _pk_lvl := 1
var _pk_log: Array = []

func _step() -> bool:
	steps += 1
	if b._supply_open:   # a supply drop: the bot takes the first offer
		b._supply_pick(0)
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
		# a player in MANUAL (2026-11-10): finger down, he flies under the bug he wants and fires straight
		# up, and slides away from shots; decides every 0.25 s and misses about one decision in three
		if (steps % 4 == 0) if _sharp else (steps % 8 == 0 and randf() > 0.3):
			_manual_decide()
		# his ability: on a crowd or a boss, as soon as it is ready
		if b._ult_t <= 0.0 and b._ability_open() and b.enemies.size() >= 5:
			b._use_ability()
		if b._pulse_t <= 0.0 and b._pulse_open() and b.shield < b.shield_max * 0.6 and b.enemies.size() >= 5:
			b._use_pulse()
		b.dragging = true
		if human_x >= 0.0:
			b._drag_by(Vector2(clampf(human_x - b.soldier_pos.x, -SPEED * DT, SPEED * DT), 0))
		if _low > 0.0:
			b._drag_by(Vector2(0, clampf(b.BASE_Y - _low - b.soldier_pos.y, -SPEED * DT, SPEED * DT)))
	b._process(DT)
	if _wl:
		_wave_log()
	if b.run_level < _pk_lvl or b.time_alive < 1.0:   # a new run: start the pick log over
		_pk_lvl = 1
		_pk_log = []
	if b.run_level > _pk_lvl:   # when each card pick lands (for the card rework: when would an evolution arrive?)
		_pk_lvl = b.run_level
		_pk_log.append("%d:%ds/w%d" % [b.run_level - 1, int(b.time_alive), b.wave_index + 1])
	if b.pilot_hp < hp_before:
		r.hearts_lost += hp_before - b.pilot_hp   # HP lost (the column keeps its name)
		if r.first_heart_wave < 0:
			r.first_heart_wave = b.wave_index + 1
	if b.hull < hull_before or b.shield < shield_before:
		r.base_hits += 1
		if r.first_base_wave < 0:
			r.first_base_wave = b.wave_index + 1
	r.min_hull = minf(r.min_hull, b.hull)
	r["min_shield"] = minf(float(r.get("min_shield", 100.0)), 100.0 * b.shield / maxf(b.shield_max, 1.0))
	if b.game_over or b.stage_cleared:
		return false
	return b.time_alive < MAX_T

func _pick() -> void:
	var offer: Array = b._offer()
	var best: String = offer[0]
	var bi := 99
	for id in offer:
		if Cards.is_evo(id):
			best = id   # a fusion always wins
			break
		var k := CARD_PRIORITY.find(id)
		if k >= 0 and k < bi:
			bi = k
			best = id
	# a player building toward an evolution: Evolve first, then deepen the offensive card already
	# held, then take its partner; only then the old priority list
	if not Cards.is_evo(best):
		var held := ""
		for id in offer:
			if Cards.CARDS.has(id) and Cards.type_of(id) == "off" and int(b.card_levels.get(id, 0)) > 0 and Cards.evolves_to(id) != "" and (held == "" or int(b.card_levels.get(id, 0)) > int(b.card_levels.get(held, 0))):
				held = id
		if held != "":
			best = held
		else:
			for id in offer:
				for f in Cards.FUSIONS:
					if String(Cards.FUSIONS[f].parts[1]) == id and int(b.card_levels.get(id, 0)) == 0 and int(b.card_levels.get(Cards.FUSIONS[f].parts[0], 0)) > 0:
						best = id
	else:
		_pk_log.append("EVOLVE %s at %ds/w%d" % [best, int(b.time_alive), b.wave_index + 1])
	if _pick_mode == "dmg" and not Cards.FUSIONS.has(best):
		var di := 99
		for id in offer:
			var dk := DMG_FIRST.find(id)
			if dk >= 0 and dk < di:
				di = dk
				best = id
	if not Cards.is_evo(best):   # a new building for a free pod is always worth it; an upgrade when nothing better is on offer
		for id in offer:
			if Cards.is_bld(String(id)) and int(b.card_levels.get(id, 0)) == 0:
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
		for s in b._strikes:   # a planet hazard about to land
			if float(s.t) < 1.3:
				worst = minf(worst, p.distance_to(s.pos) - b.STRIKE_R + 24.0)
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

func _manual_decide() -> void:
	var p: Vector2 = b.soldier_pos
	var here := _threat_dist(p, p.x)
	human_x = -1.0
	_mode = "idle"
	if here < 24.0:
		_mode = "dodge"
		var best_d := here
		for i in range(-10, 11):
			var tx := clampf(p.x + i * 18.0, 30.0, b.FIELD_W - 30.0)
			var d := _threat_dist(p, tx) - absf(tx - p.x) * 0.02 - absf(tx - b.FIELD_W * 0.5) * 0.01
			if d > best_d:
				best_d = d
				human_x = tx
				_mode = "hunt"
		return
	# the bug to line up on: the lowest one, the near ones first
	var best_s := -1e9
	var speed: float = float(b.WEAPONS[b.weapon_id].speed)
	for e in b.enemies:
		if e.pos.y < 100.0 or e.pos.y > p.y - 20.0:
			continue
		var s: float = e.pos.y - absf(e.pos.x - p.x) * 0.6
		if s > best_s:
			var tx: float = clampf(e.pos.x + e.vel.x * ((p.y - e.pos.y) / speed), 30.0, b.FIELD_W - 30.0)
			if _threat_dist(p, tx) >= 24.0:
				best_s = s
				human_x = tx
				_mode = "hunt"

func _finish() -> void:
	if _wl:
		_wave_flush()
		print("RUN stage %d run %d %s cards %s" % [cur[0], cur[1], "WIN" if b.stage_cleared else ("hp" if b.pilot_hp <= 0.0 else "hull"), ",".join(r.cards)])
		_w = {}
	r.won = b.stage_cleared
	r.t = b.time_alive
	r.wave = b.wave_index + (0 if b.stage_cleared else 1)
	r.waves = b.waves.size()
	r.kills = b.kills
	r.lvl = b.run_level
	print("    picks (n:time/wave): " + " ".join(_pk_log))
	r.pilot_dmg = b.stat_pilot_dmg
	r.turret_dmg = b.stat_turret_dmg
	if b.stat_special_dmg > 0.0:
		print("    specialty: %.1f%% of the hero damage" % (100.0 * b.stat_special_dmg / maxf(b.stat_pilot_dmg, 0.001)))
	r.hit_bullet = b.stat_hit_bullet
	r.hit_diver = b.stat_hit_diver
	r.pxp = b._xp_gain
	var why := "WIN" if r.won else ("hp" if b.pilot_hp <= 0.0 else ("hull" if b.hull <= 0.0 else "timeout"))
	if why == "timeout":   # what was left on screen (a stuck bug shows up here)
		for e in b.enemies:
			print("  left: %s %s at %s hp %.1f/%.1f state %s shield %.1f queue %d" % [e.type, e.get("variant", "-"), str(Vector2(e.pos).round()), e.hp, e.hp_max, e.state, float(e.get("shield_hp", 0.0)), b.wave_queue.size()])
	print(("[%s] " % r_kit if kit_auto else "") + "stage %2d run %d  %-7s wave %2d/%2d  %5.0fs  hp lost %3.0f (shots %d, divers %d)  hull min %3.0f  first heart w%s base w%s  kills %3d  lvl %2d  pilot %3.0f%%  cards %s" % [
		r.stage, cur[1], why, r.wave, r.waves, r.t, r.hearts_lost, r.hit_bullet, r.hit_diver, r.min_hull,
		str(r.first_heart_wave), str(r.first_base_wave), r.kills, r.lvl,
		100.0 * r.pilot_dmg / maxf(r.pilot_dmg + r.turret_dmg, 0.001), ",".join(r.cards.slice(0, 6))])
	print("    shield min %3.0f%%  runners caught %d, hits on the base %d" % [float(r.get("min_shield", 100.0)), b._runners_caught, r.base_hits])
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

# ---- per-wave log (SIM_WAVELOG=1), written for REVIEW-base-collapse.md: what arrived in each wave,
# how fast the hero dealt with it, where he stood, and what the base and he had left at its end.
# The "base:" part needs the dbg_base counter in battle.gd (not in the game by default): without
# it that part is simply empty.
func _wave_reset() -> void:
	_w = {"w": b.wave_index, "t0": b.time_alive, "k0": b.kills, "d0": b.stat_pilot_dmg, "n": 0, "sx": 0.0, "sxx": 0.0,
		"lost": 0, "pot": 0.0, "dodge": 0, "hunt": 0, "idle": 0, "en": 0, "off": 0.0, "offn": 0, "hp_in": 0.0, "bugs": 0, "run": 0, "low": 0,
		"dr0": float(b.get("dbg_drain")) if b.get("dbg_drain") != null else 0.0, "rc0": b._runners_caught, "hb0": b.stat_hit_bullet, "hd0": b.stat_hit_diver}

func _wave_log() -> void:
	if _w.is_empty():
		_w_seen = {}
		_wave_reset()
	if b.wave_index != int(_w.w) and not (b.game_over or b.stage_cleared):
		_wave_flush()
		_wave_reset()
	var p: Vector2 = b.soldier_pos
	for g in b.gems:   # XP gems about to blink out uncollected
		if not g.get("coin", false) and float(g.life) <= DT * 1.01 and b._vacuum_t <= 0.0:
			_w.lost += 1
			pass
	var wp: Dictionary = b._weapon()
	_w.pot += float(wp.damage) * b.damage_mult * (1.0 + (2.0 / float(wp.charge) if int(wp.get("charge", 0)) > 0 else 0.0)) / (float(wp.interval) / b.fire_rate_mult) * DT
	_w.n += 1
	_w.sx += p.x
	_w.sxx += p.x * p.x
	_w[_mode] += 1
	_w.en += b.enemies.size()
	var low_y := -1.0
	var low_x := 0.0
	var near := false
	for e in b.enemies:
		if not _w_seen.has(e.id):
			_w_seen[e.id] = true
			_w.hp_in += float(e.hp_max)
			_w.bugs += 1
			if e.has("runner"):
				_w.run += 1
		if e.pos.y > b.BASE_Y - 260.0 and String(e.type) != "crate":
			near = true
		if e.pos.y > low_y and e.pos.y > 100.0 and e.pos.y < p.y - 20.0 and String(e.type) != "crate":
			low_y = e.pos.y
			low_x = e.pos.x
	if near:
		_w.low += 1
	if low_y >= 0.0:
		_w.off += absf(low_x - p.x)
		_w.offn += 1

func _wave_flush() -> void:
	if _w.is_empty() or int(_w.n) == 0:
		return
	var n := float(_w.n)
	var dur: float = maxf(b.time_alive - float(_w.t0), 0.01)
	var mx: float = float(_w.sx) / n
	var base := ""
	var dbg: Variant = b.get("dbg_base")
	if dbg != null:
		for k in dbg:
			if String(k).begins_with("%d|" % (int(_w.w) + 1)):
				base += " %s=%dx/%.0f" % [String(k).get_slice("|", 1), int(dbg[k][0]), float(dbg[k][1])]
		var dr: float = float(b.get("dbg_drain")) - float(_w.dr0)
		if dr > 0.05:
			base += " wrecker_drain=%.0f" % dr
	print("WV st %d run %d w %d/%d kind %s dur %.0f kills %d dps %.1f hp_in %.0f bugs %d runners %d caught %d meanx %.0f sdx %.0f dodge %.0f hunt %.0f idle %.0f en %.1f off %.0f near %.0f shield %.0f hull %.0f hp %.0f herohits %d+%d lvl %d xplost %d potdps %.1f | base:%s" % [
		cur[0], cur[1], int(_w.w) + 1, b.waves.size(), (String(b._wave_kind_for(int(_w.w))) if String(b._wave_kind_for(int(_w.w))) != "" else "-"), dur,
		b.kills - int(_w.k0), (b.stat_pilot_dmg - float(_w.d0)) / dur, float(_w.hp_in), int(_w.bugs), int(_w.run), b._runners_caught - int(_w.rc0),
		mx, sqrt(maxf(float(_w.sxx) / n - mx * mx, 0.0)), 100.0 * _w.dodge / n, 100.0 * _w.hunt / n, 100.0 * _w.idle / n,
		float(_w.en) / n, float(_w.off) / maxf(float(_w.offn), 1.0), 100.0 * _w.low / n,
		100.0 * b.shield / maxf(b.shield_max, 1.0), 100.0 * b.hull / maxf(b.hull_max, 1.0), 100.0 * b.pilot_hp / maxf(b.pilot_hp_max, 1.0),
		b.stat_hit_bullet - int(_w.hb0), b.stat_hit_diver - int(_w.hd0), b.run_level, int(_w.lost), float(_w.pot) / dur, base])
