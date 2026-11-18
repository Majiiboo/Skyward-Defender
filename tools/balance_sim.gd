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
#   SIM_KIT     "auto" = the hero, weapon and base a sensible player has by that stage (_auto_kit, rewritten 2026-11-18)
#   SIM_WEALTH  what he has earned, as a multiple of first-clear income (1.5; 1.0 = first clears only)
#   SIM_BASE    the buildings he fields, in building order ("shield_gen,repair_bay,armory,medbay"; "none")
#   SIM_HERO / SIM_WEAPON / SIM_WLV / SIM_STAR / SIM_CHIPS  another hero, weapon class, weapon level, step, chips
#   SIM_PROMO   "0-9" or "2,5": promotion trials by rank index instead of stages (dev144); the
#               kit is the one for the trial's base stage, ranks below it already won
#   SIM_KIT_PLUS n: the auto kit of a player n stages further on (a stronger player, dev144)
#   SIM_ELITE_MODE=1: play the stages in Elite (dev166; no more editing this file for it)
#
# Prints one line per run and a summary per stage.

const DT := 1.0 / 30.0
const MAX_T := 600.0

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
	_coins_in = int(d.get("coins", 0))
	_parts_in = d.get("parts", {}) if d.get("parts") is Dictionary else {}
	var f := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()

var _coins_in := 0
var _parts_in := {}

func _read_sim_save() -> Dictionary:
	var f := FileAccess.open("user://skybound_save.json", FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}

# SIM_KIT=auto: what a sensible player owns when meeting `stage` for the first time.
#
# REWRITTEN 2026-11-18 (REVIEW-base-collapse.md, option A). What changed against the old kit:
# - NO TURRETS. The old kit put 40% of its coins into turrets, which left the game on 2026-11-10.
# - THE REAL PRICES, read from the game: Heroes.level_cost, GearData.upgrade_cost (+ Parts.need and
#   Materials.weapon_need), Base.build_cost / level_cost / level_parts, Gates.need for an ascend.
#   The old kit counted a weapon level at twice its price and ignored parts.
# - THE REAL INCOME. The old coin table (ECONOMY.md, dev109) was from before the wave bounty, the
#   salvage coins and the longer stages: a stage pays about four times that today. INCOME below
#   was measured with this script (the "earned:" line of every run), 2 runs a stage, 2026-11-18.
# - HOW HE SPENDS: an ascend as soon as he is at his level cap and can pay for it, a new building as
#   soon as a slot is free and he can pay for it; otherwise always
#   the CHEAPEST next step among a hero level, a level of the weapon in hand, a new building, a
#   building level. That keeps everything growing together, the way the upgrade buttons tempt a player.
# - Parts are a wallet too (alloy, cells, cores, 3 merge into 1 of the next; barrels are crafted).
# - His pilot level is the one his XP so far gives (it used to be the maximum).
# Still ASSUMED, not derived: WEALTH (x1.5 on first-clear income, for replays, lost fights, Patrol,
# daily rewards and chests) and the stage at which he has the shards for each ascend (STAR_FROM).
# Left out: the drone s levels and the talent map (both stay at their start).
#
# One first clear of a stage: [stage, coins, alloy, cells, cores, pilot XP]. The sampled stages are
# mostly boss stages (every fifth), which pay a cell and a sure salvage; OFF_BOSS trims the others.
const INCOME := [[1, 100, 3, 0.0, 0.0, 130], [3, 150, 3.5, 0.0, 0.0, 209], [5, 350, 8, 2.0, 0.0, 375], [8, 610, 10, 2.0, 0.0, 668],
	[10, 700, 14, 3.0, 0.0, 796], [12, 940, 19, 3.0, 0.0, 965], [15, 1350, 21, 2.0, 0.0, 1338], [20, 1970, 40, 3.0, 0.5, 1890],
	[25, 1430, 34, 4.0, 0.0, 1705], [30, 2110, 50, 9.0, 0.5, 2406], [35, 2040, 36, 5.0, 0.0, 2127], [40, 3010, 65, 11.0, 0.5, 2903],
	[45, 2690, 48, 6.0, 0.0, 2372], [50, 3900, 78, 10.0, 0.5, 3245], [55, 2830, 64, 8.0, 0.0, 2767], [60, 4000, 76, 13.0, 1.0, 3333]]
const OFF_BOSS_COINS := 0.85    # a stage that is not a fifth stage: no sure salvage
const OFF_BOSS_PARTS := 0.15    # and almost no cells or cores (measured 0 at stages 8 and 12)
const WEALTH := 1.5             # SIM_WEALTH overrides (1.0 = first clears only, nothing else)
# the stage from which he has the shards and essences for his 2nd .. 5th step (as the old kit assumed)
const STAR_FROM := [10, 20, 35, 50]
# THE BASE HE FIELDS, in the order he builds it (SIM_BASE="a,b,c,d" overrides, "none" = no base).
# Everything about the base is in _base_start / _base_options / _base_write, so when buildings
# become cards taken during the fight only those three need to change.
const BASE_WANT := ["shield_gen", "repair_bay", "armory", "medbay"]

var kit_auto := false
var promos: Array = []
var _wkit := ""
var r_kit := ""

# what one first clear of `stage` pays: {coins, alloy, cell, core, xp}
static func _income(stage: int) -> Dictionary:
	var a: Array = INCOME[0]
	var z: Array = INCOME[-1]
	for i in INCOME.size() - 1:
		if stage >= int(INCOME[i][0]) and stage <= int(INCOME[i + 1][0]):
			a = INCOME[i]
			z = INCOME[i + 1]
			break
	var k := clampf(float(stage - int(a[0])) / maxf(float(int(z[0]) - int(a[0])), 1.0), 0.0, 1.0)
	var boss := stage % 5 == 0
	return {"coins": lerpf(a[1], z[1], k) * (1.0 if boss else OFF_BOSS_COINS), "alloy": lerpf(a[2], z[2], k),
		"cell": lerpf(a[3], z[3], k) * (1.0 if boss else OFF_BOSS_PARTS), "core": lerpf(a[4], z[4], k) * (1.0 if boss else OFF_BOSS_PARTS),
		"xp": lerpf(a[5], z[5], k)}

# everything earned before meeting `stage`, as a wallet: coins, parts, materials, and "xp"
static func _wealth_before(stage: int) -> Dictionary:
	var mult := float(OS.get_environment("SIM_WEALTH")) if OS.get_environment("SIM_WEALTH") != "" else WEALTH
	var w := {"coins": 0.0, "alloy": 0.0, "cell": 0.0, "core": 0.0, "xp": 0.0}
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var mats := {}
	for st in range(1, stage):
		var inc := _income(st)
		for k in ["coins", "alloy", "cell", "core"]:
			w[k] += float(inc[k]) * mult
		w.xp += float(inc.xp)   # no multiplier: most of it is the first-clear bonus
		var drop := Materials.stage_drop(st, false, rng)   # barrels, rotors, essences: the game s own rule
		for k in drop:
			mats[k] = float(mats.get(k, 0.0)) + float(drop[k]) * mult
	for k in ["coins", "alloy", "cell", "core"]:
		w[k] = floorf(w[k])
	for k in mats:
		w[k] = floorf(float(mats[k]))
	return w

# make sure the wallet holds `n` of `k`, merging parts (3 into 1) or crafting (Materials.RECIPES) on the way
static func _obtain(w: Dictionary, k: String, n: float) -> bool:
	var guard := 0
	while float(w.get(k, 0.0)) < n and guard < 200:
		guard += 1
		var made := false
		for src in Parts.MERGE:
			if String(Parts.MERGE[src]) == k and _obtain(w, String(src), float(Parts.MERGE_COST)):
				w[src] = float(w[src]) - float(Parts.MERGE_COST)
				w[k] = float(w.get(k, 0.0)) + 1.0
				made = true
				break
		if not made:
			for rc in Materials.RECIPES:
				if not Dictionary(rc.makes).has(k) or float(w.coins) < float(rc.coins):
					continue
				var ok := true
				for nk in rc.needs:
					if not _obtain(w, String(nk), float(rc.needs[nk])):
						ok = false
						break
				if ok:
					for nk in rc.needs:
						w[nk] = float(w[nk]) - float(rc.needs[nk])
					w.coins = float(w.coins) - float(rc.coins)
					w[k] = float(w.get(k, 0.0)) + float(rc.makes[k])
					made = true
					break
		if not made:
			return false
	return float(w.get(k, 0.0)) >= n

# pay `coins` and `need` out of the wallet if it can (parts merged or crafted as needed); true = paid
static func _pay(w: Dictionary, coins: float, need: Dictionary) -> bool:
	var t := w.duplicate()
	if float(t.coins) < coins:
		return false
	t.coins = float(t.coins) - coins
	var keys: Array = need.keys()
	keys.sort_custom(func(x, y): return _rank(String(x)) > _rank(String(y)))   # the rarest first, so a merge does not eat what a cheaper line needs
	for k in keys:
		if not _obtain(t, String(k), float(need[k])):
			return false
		t[k] = float(t[k]) - float(need[k])
	for k in t:
		w[k] = t[k]
	return true

static func _rank(k: String) -> int:
	return 3 if Materials.is_material(k) else Parts.ORDER.find(k)

# ---- the base of the kit (the only part that knows how buildings are owned and placed)
func _base_want() -> Array:
	var e := OS.get_environment("SIM_BASE")
	if e == "none":
		return []
	return Array(e.split(",")) if e != "" else BASE_WANT.duplicate()

func _base_start(stage: int) -> Dictionary:
	var base := {"slots": ["", "", "", ""], "levels": {}}
	_base_options(base, stage, true)   # what costs nothing (the Shield Generator) is simply there
	return base

# the next things he could buy for the base: [{coins, parts, kind "build" / "blevel", id}]; with
# `free_only`, buildings that cost nothing are built on the spot instead
func _base_options(base: Dictionary, stage: int, free_only: bool = false) -> Array:
	var out: Array = []
	var slot := -1
	for i in Base.SLOTS:
		if Base.slot_open(i, stage) and String(base.slots[i]) == "":
			slot = i
			break
	if slot >= 0:
		for id in _base_want():
			if not Base.BUILDINGS.has(id) or base.levels.has(id) or stage <= int(Base.BUILDINGS[id].from):
				continue
			if Base.build_cost(id) == 0:
				base.levels[id] = 1
				base.slots[slot] = id
				return _base_options(base, stage, free_only)
			if not free_only:
				out.append({"coins": float(Base.build_cost(id)), "parts": {}, "kind": "build", "id": id, "slot": slot})
			break   # one at a time, in his order
	if not free_only:
		for id in base.levels:
			var lv := int(base.levels[id])
			if lv < Base.MAX_LEVEL and base.slots.has(id):
				out.append({"coins": float(Base.level_cost(lv)), "parts": Base.level_parts(lv), "kind": "blevel", "id": id})
	return out

func _base_buy(base: Dictionary, o: Dictionary) -> void:
	if String(o.kind) == "build":
		base.levels[o.id] = 1
		base.slots[int(o.slot)] = o.id
	else:
		base.levels[o.id] = int(base.levels[o.id]) + 1

func _base_write(d: Dictionary, base: Dictionary) -> String:
	d["base"] = {"slots": base.slots, "levels": base.levels}
	var bits: Array = []
	for id in base.slots:
		if String(id) != "":
			bits.append("%s %d" % [String(id), int(base.levels[id])])
	return "base " + (" + ".join(bits) if not bits.is_empty() else "none")

func _auto_kit(d: Dictionary, stage: int) -> void:
	stage += int(OS.get_environment("SIM_KIT_PLUS")) if OS.get_environment("SIM_KIT_PLUS") != "" else 0
	var w := _wealth_before(stage)
	var plevel := Turrets.pilot_level(int(w.xp))
	d["pilot_xp"] = int(w.xp)
	# SIM_HERO / SIM_WEAPON: any hero with any of his four weapon classes (default: Rook, the pistol he comes with)
	var hid := OS.get_environment("SIM_HERO")
	if not Heroes.ROSTER.has(hid):
		hid = "rook"
	var cls := OS.get_environment("SIM_WEAPON")
	if not Arsenal.ORDER.has(cls):
		cls = String(Arsenal.first(hid))
	var el := Heroes.element_of(hid)
	# his step: he starts on his grade s step and ascends when he is at the cap, the stage has given
	# him the shards (STAR_FROM), his pilot level opens the door (Gates.door) and he can pay
	var star := Heroes.grade(hid)
	var star_max := star
	for i in STAR_FROM.size():
		if stage >= int(STAR_FROM[i]) and plevel >= Gates.door(i + 2):
			star_max = maxi(star_max, i + 2)
	if OS.get_environment("SIM_STAR") != "":   # a forced step costs nothing
		star = int(OS.get_environment("SIM_STAR"))
		star_max = star
	var hl := 1
	var wl := 1
	var base := _base_start(stage)
	var guard := 0
	while guard < 2000:
		guard += 1
		if hl >= Gates.level_cap("hero", star) and star < star_max:
			var nd := Gates.need("hero", star + 1, el)
			if _pay(w, float(nd.coins), {}):   # the shards and essences are what STAR_FROM stands for
				star += 1
				continue
		var opts: Array = _base_options(base, stage)
		if hl < Gates.level_cap("hero", star):
			opts.append({"coins": float(Heroes.level_cost(hl)), "parts": {}, "kind": "hero"})
		if wl < mini(int(Arsenal.CAPS[clampi(star, 1, Arsenal.CAPS.size()) - 1]), GearData.MAX_LEVEL):
			var need := Parts.need(wl)
			need.merge(Materials.weapon_need(wl, el))
			opts.append({"coins": float(GearData.upgrade_cost(wl)), "parts": need, "kind": "weapon"})
		# a new building goes first when a slot is free (a big step a player takes as soon as he can);
		# after that, the cheapest next level of anything
		opts.sort_custom(func(x, y): return (float(x.coins) if String(x.kind) != "build" else -1.0) < (float(y.coins) if String(y.kind) != "build" else -1.0))
		var bought := false
		for o in opts:
			if _pay(w, float(o.coins), o.parts):
				match String(o.kind):
					"hero": hl += 1
					"weapon": wl += 1
					_: _base_buy(base, o)
				bought = true
				break
		if not bought:
			break
	if OS.get_environment("SIM_WLV") != "":
		wl = int(OS.get_environment("SIM_WLV"))
	# the save: "tiers" holds the steps climbed (1 = none), Heroes.tier adds his grade
	d["hero"] = {"selected": hid, "owned": ["rook", hid] if hid != "rook" else ["rook"], "levels": {hid: hl}, "def": {hid: 1},
		"tiers": {hid: maxi(star - Heroes.grade(hid) + 1, 1)}, "shards": {}}
	d["arsenal"] = {hid: {"equipped": cls, "owned": Arsenal.ORDER.duplicate(), "levels": {cls: wl}}}
	d["turrets"] = {"loadout": ["", "", "", ""]}
	_wkit = ""
	if OS.get_environment("SIM_HERO") != "" or OS.get_environment("SIM_WEAPON") != "":
		_wkit = " %s %s" % [hid, cls]
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
		d["chips"] = {"owned": own, "fit": {Arsenal.key(hid, cls): row}}
		if row.has("special"):
			d["special_test"] = true   # the Specialty chip without earning the mastery
	var btxt := _base_write(d, base)
	# the same opening as the old kit line ("hero Lv.n n-star DEF n, weapon Lv.n, ..."), the base in the turrets place
	r_kit = "hero Lv.%d %d-star DEF 1, weapon Lv.%d, %s, pilot Lv.%d, %d coins spare" % [hl, star, wl, btxt, plevel, int(w.coins)] + _wkit

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
	_evo_seen = 0
	_evo_taken = 0
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

# what-if switches for the evolutions (sim only): SIM_EVO_ONE_IN=2 takes only every second evolution pick
# earned (as if it took six hero cards, not three), SIM_EVO_MAX=n takes at most n in a stage
var _evo_one_in := maxi(int(OS.get_environment("SIM_EVO_ONE_IN")), 1)
var _evo_max := int(OS.get_environment("SIM_EVO_MAX")) if OS.get_environment("SIM_EVO_MAX") != "" else 99
var _evo_seen := 0
var _evo_taken := 0
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
	r["min_hp"] = minf(float(r.get("min_hp", 100.0)), 100.0 * maxf(b.pilot_hp, 0.0) / maxf(b.pilot_hp_max, 1.0))   # the lowest his health got, as a share
	if b.game_over or b.stage_cleared:
		return false
	return b.time_alive < MAX_T

# THE CARD PICKS OF THE TEST PLAYER, rewritten 2026-11-18 for the cards of dev335 (types, five-level
# offensive cards, any three hero cards earn an evolution pick). The old wish list put Aegis and the
# base cards ahead of damage cards it did not know, and fed one card blindly. Now:
# - an evolution pick: his own signature first, then EVO_ORDER, with a lift for one that builds on
#   a card he already holds;
# - a normal pick: every card on offer gets a score = what it is worth (CARD_VALUE: damage cards
#   high, defence low), plus a lift for damage in the first picks of a stage, plus a NEED lift for
#   a defensive card when the hero s health, the shield or the hull is low (nothing heals for free
#   any more), minus a little for each level already held, so he spreads; one more nudge toward a
#   hero card when it is the third one (it brings the evolution pick).
const CARD_VALUE := {
	"heavy_bolts": 9.0, "burst_fire": 9.0, "rapid_pulse": 8.5, "split_shot": 7.5, "hot_rounds": 7.5, "focus_fire": 7.0,
	"piercing_rounds": 7.0, "chain_spark": 6.5, "killer_instinct": 5.5, "radar_sweep": 5.5, "seeker": 5.5, "frost_rounds": 5.0,
	"drone_barrage": 4.5, "drone_uplink": 4.0, "magnet": 4.0, "nova_burst": 4.0, "reactor_surge": 3.5, "core_overload": 3.0, "mirror_shell": 3.0,
	"aegis": 3.5, "shield_recharge": 3.5, "field_medic": 3.0, "reinforced_hull": 3.0, "shield_surge": 3.0, "stim_pack": 3.0, "second_wind": 3.0,
	"nanobots": 2.5, "plate_up": 2.5, "rich_seam": 1.0, "salvage": 1.0,
}
const HERO_CARD_VALUE := 9.0    # his own five-level card
const EVO_ORDER := ["storm_volley", "railstorm", "thunder_lance", "flak_wall", "gem_barrage", "guardian_wing"]
const EARLY_PICKS := 4          # "early in a stage": damage first

func _evo_score(id: String) -> float:
	var v := 10.0 if id.begins_with("sig_") else 8.0 - float(maxi(EVO_ORDER.find(id), 0))
	var off := String(Cards.FUSIONS[id].parts[0])
	if int(b.card_levels.get(off, 0)) > 0:   # it builds on a card he holds
		v += 2.0 + 0.5 * int(b.card_levels.get(off, 0))
	if id == "guardian_wing" and b.shield < b.shield_max * 0.4:
		v += 3.0
	return v

func _card_score(id: String) -> float:
	if not Cards.CARDS.has(id):
		return 0.0
	var lv := int(b.card_levels.get(id, 0))
	var v := HERO_CARD_VALUE if id == Cards.hero_card(b._hero_id) else float(CARD_VALUE.get(id, 3.0))
	var hp: float = b.pilot_hp / maxf(b.pilot_hp_max, 1.0)
	var sh: float = b.shield / maxf(b.shield_max, 1.0)
	var hu: float = b.hull / maxf(b.hull_max, 1.0)
	var left := 1.0 - float(b.wave_index) / maxf(float(b.waves.size()), 1.0)   # how much of the stage is still to come
	var need_hp := clampf((0.8 - hp) / 0.5, 0.0, 1.0)      # 0 above 80% health, 1 at 30% and under
	var need_sh := clampf((0.6 - sh) / 0.5, 0.0, 1.0)      # 0 above 60% shield, 1 at 10% and under
	var need_hu := clampf((1.0 - hu) / 0.5, 0.0, 1.0)      # the hull only loses points once the shield is gone
	match id:
		"field_medic": v += 10.0 * need_hp * (0.4 + 0.6 * left)    # slow healing: worth most with a long way to go
		"aegis", "stim_pack": v += 9.0 * need_hp                   # health back now
		"second_wind": v += 6.0 * need_hp
		"reinforced_hull": v += 9.0 * maxf(need_sh, need_hu)       # repaired now
		"shield_surge": v += 9.0 * need_sh
		"shield_recharge": v += 10.0 * need_sh * (0.4 + 0.6 * left)
		"nanobots", "plate_up": v += 9.0 * need_hu
	if Cards.type_of(id) != "def" and v >= 5.0 and r.cards.size() < EARLY_PICKS:
		v += 2.0   # firepower first: his weakest minutes meet the full stream of bugs
	v -= 0.6 * lv   # spread
	if int(Cards.CARDS[id].max) >= 5 and lv == int(Cards.CARDS[id].max) - 1:
		v += 2.0    # the next pick is its top level
	if Cards.is_hero_card(id) and b._hero_picks % Cards.EVO_EVERY == Cards.EVO_EVERY - 1:
		v += 1.5    # the third hero card brings an evolution pick
	return v

func _pick() -> void:
	var offer: Array = b._offer()
	var best: String = offer[0]
	var top := -1e9
	var evo := false
	for id in offer:
		if Cards.FUSIONS.has(id):
			evo = true
	for id in offer:
		var s := _evo_score(id) if Cards.FUSIONS.has(id) else (-1.0 if evo else _card_score(id))
		if s > top:
			top = s
			best = id
	if evo:   # the what-if switches SIM_EVO_ONE_IN / SIM_EVO_MAX: this evolution pick is passed over, as if it had not been earned
		_evo_seen += 1
		if _evo_seen % _evo_one_in != 0 or _evo_taken >= _evo_max:
			b._evo_due = maxi(b._evo_due - 1, 0)
			b._card_panel.visible = false
			b.picking = false
			return
		_evo_taken += 1
	if Cards.FUSIONS.has(best):
		_pk_log.append("EVOLVE %s at %ds/w%d" % [best, int(b.time_alive), b.wave_index + 1])
	if _pick_mode == "dmg" and not Cards.FUSIONS.has(best):
		var di := 99
		for id in offer:
			var dk := DMG_FIRST.find(id)
			if dk >= 0 and dk < di:
				di = dk
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
	r["why"] = why
	if why == "timeout":   # what was left on screen (a stuck bug shows up here)
		for e in b.enemies:
			print("  left: %s %s at %s hp %.1f/%.1f state %s shield %.1f queue %d" % [e.type, e.get("variant", "-"), str(Vector2(e.pos).round()), e.hp, e.hp_max, e.state, float(e.get("shield_hp", 0.0)), b.wave_queue.size()])
	print(("[%s] " % r_kit if kit_auto else "") + "stage %2d run %d  %-7s wave %2d/%2d  %5.0fs  hp lost %3.0f (shots %d, divers %d)  hull min %3.0f  first heart w%s base w%s  kills %3d  lvl %2d  pilot %3.0f%%  cards %s" % [
		r.stage, cur[1], why, r.wave, r.waves, r.t, r.hearts_lost, r.hit_bullet, r.hit_diver, r.min_hull,
		str(r.first_heart_wave), str(r.first_base_wave), r.kills, r.lvl,
		100.0 * r.pilot_dmg / maxf(r.pilot_dmg + r.turret_dmg, 0.001), ",".join(r.cards.slice(0, 6))])
	print("    shield min %3.0f%%  hero health min %3.0f%%  runners caught %d, hits on the base %d" % [float(r.get("min_shield", 100.0)), float(r.get("min_hp", 100.0)), b._runners_caught, r.base_hits])
	r["kit"] = r_kit
	r["evos"] = 0
	for c in r.cards:
		if Cards.FUSIONS.has(c):
			r.evos += 1
	# what the stage paid (the save the fight wrote, against what the sim put in it): the income
	# table INCOME below was measured from these lines
	var after := _read_sim_save()
	var pa: Dictionary = after.get("parts", {}) if after.get("parts") is Dictionary else {}
	print("    earned: coins %d, alloy %d, cell %d, core %d, pilot XP %d" % [int(after.get("coins", 0)) - _coins_in, int(pa.get("alloy", 0)) - int(_parts_in.get("alloy", 0)),
		int(pa.get("cell", 0)) - int(_parts_in.get("cell", 0)), int(pa.get("core", 0)) - int(_parts_in.get("core", 0)), int(r.pxp)])
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
		var sm := 0.0; var sw := 100.0; var hw := 100.0; var ev := 0.0; var lh := 0; var lb := 0
		var hm2 := 0.0; var hw2 := 100.0
		for x in rs:
			sm += float(x.get("min_shield", 100.0)); sw = minf(sw, float(x.get("min_shield", 100.0))); hw = minf(hw, x.min_hull); ev += float(x.get("evos", 0))
			hm2 += float(x.get("min_hp", 100.0)); hw2 = minf(hw2, float(x.get("min_hp", 100.0)))
			lh += 1 if String(x.get("why", "")) == "hp" else 0
			lb += 1 if String(x.get("why", "")) == "hull" else 0
		print("       shield min avg %3.0f%% (worst %3.0f%%)  hull worst %3.0f  hero health min avg %3.0f%% (worst %3.0f%%)  evolutions avg %.1f  lost: hero %d, base %d  kit: %s" % [sm / n, sw, hw, hm2 / n, hw2, ev / n, lh, lb, String(rs[0].get("kit", ""))])

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
