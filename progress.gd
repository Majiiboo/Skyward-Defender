class_name Progress
extends RefCounted
# Long-term progress: lifetime stats, daily missions, career missions and trophies, and
# the ONE function that grants rewards (grant), so the store, codes and (2.0) the inbox
# all give rewards the same way. Everything lives in the save file:
#   "stats":   {kills, kills_<type>, stages, bosses, minis, perfect, gems, cards, seconds, coins_total, runs}
#   "daily":   {"day": n, "ids": [...], "base": {stat: value at day start}, "claimed": [...]}
#   "career_claimed": [...], "trophies_claimed": {"<id>": tier claimed (1..3)}
# battle.gd calls record_run() at the end of every run.

const SAVE := "user://skybound_save.json"

# ---- daily missions: 5 a day picked from this pool (same 5 for everyone on that day)
const DAILY_POOL := [
	{"id": "d_kill40", "text": "Destroy 40 bugs", "stat": "kills", "goal": 40, "reward": {"coins": 60, "pilot_xp": 60}},
	{"id": "d_kill120", "text": "Destroy 120 bugs", "stat": "kills", "goal": 120, "reward": {"coins": 120, "pilot_xp": 120}},
	{"id": "d_stage2", "text": "Clear 2 stages", "stat": "stages", "goal": 2, "reward": {"coins": 80, "pilot_xp": 80}},
	{"id": "d_stage5", "text": "Clear 5 stages", "stat": "stages", "goal": 5, "reward": {"coins": 150, "pilot_xp": 150}},
	{"id": "d_gems80", "text": "Collect 80 gems", "stat": "gems", "goal": 80, "reward": {"coins": 70, "pilot_xp": 60}},
	{"id": "d_cards8", "text": "Pick 8 power cards", "stat": "cards", "goal": 8, "reward": {"coins": 60, "pilot_xp": 60}},
	{"id": "d_divers10", "text": "Shoot down 10 Divers", "stat": "kills_diver", "goal": 10, "reward": {"coins": 80, "pilot_xp": 70}},
	{"id": "d_spitters15", "text": "Destroy 15 Spitters", "stat": "kills_spitter", "goal": 15, "reward": {"coins": 80, "pilot_xp": 70}},
	{"id": "d_perfect1", "text": "Win a stage with no damage", "stat": "perfect", "goal": 1, "reward": {"coins": 100, "crystals": 5}},
	{"id": "d_time10", "text": "Fight for 10 minutes", "stat": "seconds", "goal": 600, "reward": {"coins": 100, "pilot_xp": 100}},
	{"id": "d_boss1", "text": "Defeat a boss or mini-boss", "stat": "bosses_any", "goal": 1, "reward": {"coins": 150, "crystals": 5}},
	# Gear page tasks (dev140; their Go buttons open the right Gear tab): gear.gd calls bump()
	{"id": "d_upgrade2", "text": "Upgrade gear 2 times", "stat": "upgrades", "goal": 2, "reward": {"coins": 80, "pilot_xp": 60}},
	{"id": "d_turret1", "text": "Upgrade a turret track", "stat": "turret_upgrades", "goal": 1, "reward": {"coins": 80, "pilot_xp": 60}},
	{"id": "d_merge1", "text": "Merge in the Workshop", "stat": "merges", "goal": 1, "reward": {"coins": 60, "crystals": 3}},
]
const DAILY_COUNT := 5
const DAILY_ALL_BONUS := {"coins": 200, "crystals": 10}   # for finishing all five

# ---- career: one-time milestones
const CAREER := [
	{"id": "c_stage5", "text": "Clear stage 5", "stat": "best_stage", "goal": 5, "reward": {"coins": 300, "crystals": 10}},
	{"id": "c_planet1", "text": "Complete the Hive World", "stat": "best_stage", "goal": 10, "reward": {"coins": 600, "crystals": 20}},
	{"id": "c_planet2", "text": "Complete the Scrap Belt", "stat": "best_stage", "goal": 20, "reward": {"coins": 1000, "crystals": 30}},
	{"id": "c_planet3", "text": "Complete the Magma World", "stat": "best_stage", "goal": 30, "reward": {"coins": 1500, "crystals": 40}},
	{"id": "c_kill500", "text": "Destroy 500 bugs", "stat": "kills", "goal": 500, "reward": {"coins": 400, "pilot_xp": 300}},
	{"id": "c_kill5000", "text": "Destroy 5,000 bugs", "stat": "kills", "goal": 5000, "reward": {"coins": 1500, "crystals": 30}},
	{"id": "c_level5", "text": "Reach pilot level 5", "stat": "pilot_level", "goal": 5, "reward": {"coins": 300}},
	{"id": "c_level10", "text": "Reach pilot level 10", "stat": "pilot_level", "goal": 10, "reward": {"coins": 800, "crystals": 20}},
	{"id": "c_stars30", "text": "Earn 30 stars", "stat": "stars", "goal": 30, "reward": {"coins": 500, "crystals": 15}},
	{"id": "c_perfect5", "text": "5 perfect stages", "stat": "perfect", "goal": 5, "reward": {"coins": 600, "crystals": 15}},
]

# ---- trophies: three tiers each (bronze, silver, gold), claimed for crystals
const TROPHIES := [
	{"id": "t_hunter", "name": "Bug Hunter", "text": "Destroy bugs", "stat": "kills", "tiers": [200, 2000, 20000]},
	{"id": "t_slayer", "name": "Boss Slayer", "text": "Defeat bosses", "stat": "bosses", "tiers": [1, 5, 20]},
	{"id": "t_flawless", "name": "Flawless", "text": "Perfect stages", "stat": "perfect", "tiers": [1, 10, 40]},
	{"id": "t_explorer", "name": "Explorer", "text": "Reach planets", "stat": "planets", "tiers": [2, 4, 6]},
	{"id": "t_stars", "name": "Star Collector", "text": "Earn stars", "stat": "stars", "tiers": [30, 90, 180]},
	{"id": "t_gems", "name": "Gem Hoarder", "text": "Collect gems", "stat": "gems", "tiers": [500, 5000, 50000]},
	{"id": "t_cards", "name": "Card Shark", "text": "Pick power cards", "stat": "cards", "tiers": [50, 500, 3000]},
	{"id": "t_veteran", "name": "Veteran", "text": "Pilot level", "stat": "pilot_level", "tiers": [10, 25, 50]},
	{"id": "t_divers", "name": "Sky Shield", "text": "Shoot down Divers", "stat": "kills_diver", "tiers": [50, 500, 5000]},
	{"id": "t_time", "name": "Defender", "text": "Hours in battle", "stat": "hours", "tiers": [1, 10, 50]},
]
const TROPHY_REWARD := [{"crystals": 10}, {"crystals": 25}, {"crystals": 60}]
const TIER_NAMES := ["Bronze", "Silver", "Gold"]
const TIER_COLORS := [Color(0.85, 0.55, 0.3), Color(0.8, 0.85, 0.92), Color(1.0, 0.8, 0.3)]

# ------------------------------------------------------------------ save

static func read() -> Dictionary:
	if FileAccess.file_exists(SAVE):
		var f := FileAccess.open(SAVE, FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if typeof(d) == TYPE_DICTIONARY:
				return d
	return {}

static func write(d: Dictionary) -> void:
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))

# ------------------------------------------------------------------ rewards

# The one place rewards are given: {coins, crystals, pilot_xp}. Returns the save.
static func grant(d: Dictionary, reward: Dictionary) -> Dictionary:
	d["coins"] = int(d.get("coins", 0)) + int(reward.get("coins", 0))
	d["crystals"] = int(d.get("crystals", 0)) + int(reward.get("crystals", 0))
	d["pilot_xp"] = int(d.get("pilot_xp", 0)) + int(reward.get("pilot_xp", 0))
	# upgrade parts (Store, chests)
	for k in Parts.ORDER:
		if int(reward.get(k, 0)) > 0:
			var p: Dictionary = Parts.read(d)
			p[k] = int(p[k]) + int(reward[k])
			d["parts"] = p
	# gear copies (dev139): "gear": [{"id": item id, "rarity": r}, ...]
	var gl = reward.get("gear", [])
	if typeof(gl) == TYPE_ARRAY and not gl.is_empty():
		var g := GearData.read(d)
		for piece in gl:
			if typeof(piece) == TYPE_DICTIONARY:
				GearData.add_copy(g, String(piece.get("id", "")), String(piece.get("rarity", "common")))
		d["gear"] = GearData.write(g)
	return d

static func reward_text(reward: Dictionary) -> String:
	var parts: Array = []
	if int(reward.get("coins", 0)) > 0:
		parts.append("%d coins" % int(reward.coins))
	if int(reward.get("crystals", 0)) > 0:
		parts.append("%d crystals" % int(reward.crystals))
	if int(reward.get("pilot_xp", 0)) > 0:
		parts.append("%d XP" % int(reward.pilot_xp))
	for k in Parts.ORDER:
		if int(reward.get(k, 0)) > 0:
			parts.append("%d %s" % [int(reward[k]), Parts.KINDS[k].name])
	var gl = reward.get("gear", [])
	if typeof(gl) == TYPE_ARRAY:
		for piece in gl:
			if typeof(piece) == TYPE_DICTIONARY and GearData.ITEMS.has(String(piece.get("id", ""))):
				parts.append("%s %s" % [GearData.rarity_name(String(piece.get("rarity", "common"))), GearData.ITEMS[String(piece.id)].name])
	return " + ".join(parts)

# ------------------------------------------------------------------ stats

# run: {kills, kills_by_type {type: n}, won, stage, boss ("", "mini", "boss"), perfect,
# gems, cards, seconds, coins}
static func record_run(run: Dictionary) -> void:
	var d := read()
	_roll_daily(d)
	var s: Dictionary = d.get("stats", {})
	var add := func(k: String, n: float): s[k] = float(s.get(k, 0.0)) + n
	add.call("runs", 1)
	add.call("kills", float(run.get("kills", 0)))
	var by: Dictionary = run.get("kills_by_type", {})
	for k in by:
		add.call("kills_" + String(k), float(by[k]))
	add.call("gems", float(run.get("gems", 0)))
	add.call("cards", float(run.get("cards", 0)))
	add.call("seconds", float(run.get("seconds", 0.0)))
	add.call("coins_total", float(run.get("coins", 0)))
	if run.get("won", false):
		add.call("stages", 1)
		if run.get("perfect", false):
			add.call("perfect", 1)
		if run.get("boss", "") == "boss":
			add.call("bosses", 1)
		if run.get("boss", "") != "":
			add.call("bosses_any", 1)
	d["stats"] = s
	write(d)

# Count a menu action (upgrades, turret_upgrades, merges) for missions. Reads and writes
# the save, so call it after the screen has saved its own changes.
static func bump(key: String, n: int = 1) -> void:
	var d := read()
	var s: Dictionary = d.get("stats", {})
	s[key] = float(s.get(key, 0.0)) + n
	d["stats"] = s
	write(d)

# A stat's current value; some are worked out from the save, not counted.
static func stat(d: Dictionary, key: String) -> float:
	var s: Dictionary = d.get("stats", {})
	match key:
		"best_stage":
			return float(int(d.get("stage_unlocked", 1)) - 1)
		"pilot_level":
			return float(Turrets.pilot_level(int(d.get("pilot_xp", 0))))
		"planets":
			return float(StageData.area_index(int(d.get("stage_unlocked", 1))) + 1)
		"hours":
			return float(s.get("seconds", 0.0)) / 3600.0
		"stars":
			var total := 0
			var st = d.get("stars", {})
			if typeof(st) == TYPE_DICTIONARY:
				for k in st:
					total += int(st[k])
			return float(total)
	return float(s.get(key, 0.0))

# ------------------------------------------------------------------ daily

static func today() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0)

# New day: pick 5 missions by the day number, and remember today's starting values.
static func _roll_daily(d: Dictionary) -> void:
	var day := today()
	var dl: Dictionary = d.get("daily", {})
	if int(dl.get("day", -1)) == day:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = day * 7919
	var pool := DAILY_POOL.duplicate()
	var ids: Array = []
	while ids.size() < DAILY_COUNT and not pool.is_empty():
		var m: Dictionary = pool.pop_at(rng.randi() % pool.size())
		ids.append(m.id)
	var base := {}
	for m in DAILY_POOL:
		base[m.stat] = stat(d, m.stat)
	d["daily"] = {"day": day, "ids": ids, "base": base, "claimed": []}

# today's missions: [{def, progress, done, claimed}]
static func daily(d: Dictionary) -> Array:
	_roll_daily(d)
	var dl: Dictionary = d.daily
	var out: Array = []
	for id in dl.ids:
		for m in DAILY_POOL:
			if m.id == id:
				var p: float = stat(d, m.stat) - float(dl.base.get(m.stat, 0.0))
				out.append({"def": m, "progress": p, "done": p >= float(m.goal), "claimed": Array(dl.claimed).has(id)})
	return out

static func claim_daily(id: String) -> Dictionary:
	var d := read()
	for m in daily(d):
		if m.def.id == id and m.done and not m.claimed:
			d.daily.claimed.append(id)
			grant(d, m.def.reward)
			if d.daily.claimed.size() == DAILY_COUNT:
				grant(d, DAILY_ALL_BONUS)
	write(d)
	return d

# ------------------------------------------------------------------ career and trophies

static func career(d: Dictionary) -> Array:
	var claimed: Array = d.get("career_claimed", [])
	var out: Array = []
	for m in CAREER:
		var p := stat(d, m.stat)
		out.append({"def": m, "progress": p, "done": p >= float(m.goal), "claimed": claimed.has(m.id)})
	return out

static func claim_career(id: String) -> Dictionary:
	var d := read()
	for m in career(d):
		if m.def.id == id and m.done and not m.claimed:
			var c: Array = d.get("career_claimed", [])
			c.append(id)
			d["career_claimed"] = c
			grant(d, m.def.reward)
	write(d)
	return d

# tier reached (0..3) and tier claimed for each trophy
static func trophies(d: Dictionary) -> Array:
	var claimed: Dictionary = d.get("trophies_claimed", {})
	var out: Array = []
	for t in TROPHIES:
		var v := stat(d, t.stat)
		var reached := 0
		for i in 3:
			if v >= float(t.tiers[i]):
				reached = i + 1
		out.append({"def": t, "value": v, "reached": reached, "claimed": int(claimed.get(t.id, 0))})
	return out

static func claim_trophy(id: String) -> Dictionary:
	var d := read()
	for t in trophies(d):
		if t.def.id == id and t.claimed < t.reached:
			var c: Dictionary = d.get("trophies_claimed", {})
			for tier in range(t.claimed, t.reached):
				grant(d, TROPHY_REWARD[tier])
			c[id] = t.reached
			d["trophies_claimed"] = c
	write(d)
	return d

# anything waiting to be claimed (for a red dot on Home)
static func has_claimable(d: Dictionary) -> bool:
	for m in daily(d):
		if m.done and not m.claimed:
			return true
	for m in career(d):
		if m.done and not m.claimed:
			return true
	for t in trophies(d):
		if t.claimed < t.reached:
			return true
	return false
