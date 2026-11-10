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
	{"id": "d_turret1", "text": "Build or level a base building", "stat": "turret_upgrades", "goal": 1, "reward": {"coins": 80, "pilot_xp": 60}},
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
				DevTools.on = bool(d.get("dev_mode", false))   # the dev switch rides on the save
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
	for k in Parts.all_order():   # parts and materials (materials.gd) at the top level of a reward
		if int(reward.get(k, 0)) > 0:
			Parts.add(d, k, int(reward[k]))
	# materials as a block too: "materials": {id: n}
	var mb = reward.get("materials", {})
	if typeof(mb) == TYPE_DICTIONARY:
		for k in mb:
			Materials.add(d, String(k), int(mb[k]))
	# hero shards (heroes, dev172): "shards": {hero id: n}
	var sh = reward.get("shards", {})
	if typeof(sh) == TYPE_DICTIONARY and not sh.is_empty():
		var hh := Heroes.read(d)
		for hid in sh:
			Heroes.add_shards(hh, String(hid), int(sh[hid]))
		d["hero"] = Heroes.write(hh)
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
	for k in Parts.all_order():
		if int(reward.get(k, 0)) > 0:
			parts.append("%d %s" % [int(reward[k]), Parts.kind(k).name])
	var mb = reward.get("materials", {})
	if typeof(mb) == TYPE_DICTIONARY:
		for k in mb:
			if int(mb[k]) > 0:
				parts.append("%d %s" % [int(mb[k]), Materials.name_of(String(k))])
	var sh = reward.get("shards", {})
	if typeof(sh) == TYPE_DICTIONARY:
		for hid in sh:
			if Heroes.ROSTER.has(String(hid)):
				parts.append("%d %s shards" % [int(sh[hid]), Heroes.ROSTER[String(hid)].name])
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
			Season.add_xp(d, Season.XP_QUEST)   # a daily quest also moves the season pass
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

# ------------------------------------------------------------------ attendance calendar
# (dev142, from Rudy's Slayer Legend notes) Seven days, one claim a day, a bigger gift on
# day 7, then the week starts again. Missing a day does not reset the week (gentle).
# Save: "attend": {"day": the next day to claim (1-7), "last": day number of the last claim}.
# Old saves: "gift_day" == today counts as today's claim.
const ATTEND := [
	{"coins": 100}, {"coins": 150}, {"crystals": 5}, {"coins": 200, "alloy": 3},
	{"crystals": 10}, {"coins": 300, "cell": 1}, {"coins": 500, "crystals": 25},
]

# {day: 1-7 (the one to claim next, or the one claimed today), claimable, claimed_today}
static func attend(d: Dictionary) -> Dictionary:
	var a = d.get("attend", {})
	if typeof(a) != TYPE_DICTIONARY:
		a = {}
	var day := clampi(int(a.get("day", 1)), 1, ATTEND.size())
	var last := int(a.get("last", -1))
	if last < 0 and int(d.get("gift_day", -1)) == today():
		last = today()
	var done_today := last == today()
	# the cell lit today: the one just claimed, else the next to claim
	var shown := day if not done_today else (ATTEND.size() if day == 1 else day - 1)
	return {"day": shown, "next": day, "claimable": not done_today, "claimed_today": done_today}

static func claim_attend(d: Dictionary) -> Dictionary:
	var st := attend(d)
	if not st.claimable:
		return {}
	var reward: Dictionary = ATTEND[int(st.next) - 1]
	grant(d, reward)
	d["attend"] = {"day": (int(st.next) % ATTEND.size()) + 1, "last": today()}
	return reward

# ------------------------------------------------------------------ attention (red dots)
# One rule for every red dot in the game (dev142): what has something to claim or do right
# now. Pages and Home read this; nothing else decides where a dot shows.
#   quests / quests_tabs [daily, career, trophies]: a finished task to claim
#   store: today's attendance gift
#   gear / gear_ws [parts, gear]: a merge is possible in the Workshop
#   patrol: something farmed and a collect left today
static func attention(d: Dictionary) -> Dictionary:
	var q := [false, false, false, false]
	for m in daily(d):
		if m.done and not m.claimed:
			q[0] = true
	for m in career(d):
		if m.done and not m.claimed:
			q[1] = true
	for t in trophies(d):
		if t.claimed < t.reached:
			q[2] = true
	for m in repeat(d):
		if m.done:
			q[3] = true
	var parts := Parts.read(d)
	var parts_merge := false
	for k in Parts.MERGE:
		if int(parts[k]) >= Parts.MERGE_COST:
			parts_merge = true
	var g := GearData.read(d)
	var gear_merge := false
	for id in g.copies:
		for r in g.copies[id]:
			if GearData.can_merge(g, id, r):
				gear_merge = true
	var p := Patrol.tick(d.duplicate(true))   # a copy: looking must not count time
	var patrol: bool = not Patrol.ready(p).is_empty() and Patrol.collects_left(p) > 0 and Unlocks.open(d, "patrol")
	if not Unlocks.open(d, "workshop"):   # no dot for a page the player cannot see yet (Unlocks)
		parts_merge = false
		gear_merge = false
	if not Unlocks.open(d, "repeat"):
		q[3] = false
	q.append(Codex.claimable(d))   # the Collection tab: a category reward is waiting
	return {"quests": q[0] or q[1] or q[2] or q[3] or q[4], "quests_tabs": q, "store": bool(attend(d).claimable),
		"gear": parts_merge or gear_merge or Talents.affordable(d) or Research.ready(d), "gear_ws": [parts_merge, gear_merge], "patrol": patrol}   # a talent node ready to buy (dev197)

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
	for m in repeat(d):
		if m.done:
			return true
	return false

# ------------------------------------------------------------------ repeat quests
# (dev165, from the Slayer Legend notes) Goals that come back bigger each time they are
# claimed, so there is always a small target. A fresh quest counts the lifetime stat toward
# its first level (a veteran gets a welcome-back claim or two).
# Save: "repeat": {id: {"lv": n, "base": the stat's value when this level started}}.
const REPEAT := [
	{"id": "r_kills",  "text": "Destroy %d bugs",      "stat": "kills",      "goal": 150, "step": 100, "coins": 60,  "xp": 40},
	{"id": "r_stages", "text": "Clear %d stages",      "stat": "stages",     "goal": 3,   "step": 1,   "coins": 90,  "xp": 60},
	{"id": "r_gems",   "text": "Collect %d gems",      "stat": "gems",       "goal": 250, "step": 150, "coins": 50,  "xp": 40},
	{"id": "r_bosses", "text": "Defeat %d bosses",     "stat": "bosses_any", "goal": 2,   "step": 1,   "coins": 120, "crystals": 2},
	{"id": "r_cards",  "text": "Pick %d power cards",  "stat": "cards",      "goal": 25,  "step": 15,  "coins": 50,  "xp": 40},
]

# the reward grows a quarter per level, rounded to tens
static func repeat_reward(m: Dictionary, lv: int) -> Dictionary:
	var k := 1.0 + 0.25 * (lv - 1)
	var r := {"coins": int(round(float(m.coins) * k / 10.0)) * 10}
	if m.has("xp"):
		r["pilot_xp"] = int(round(float(m.xp) * k / 10.0)) * 10
	if m.has("crystals"):
		r["crystals"] = int(m.crystals) + (lv - 1) / 2
	return r

# [{def, lv, goal, progress, done, claimed (always false), reward, text}]
static func repeat(d: Dictionary) -> Array:
	var rp = d.get("repeat", {})
	if typeof(rp) != TYPE_DICTIONARY:
		rp = {}
	var out: Array = []
	for m in REPEAT:
		var st = rp.get(m.id, {})
		var lv: int = int(st.get("lv", 1)) if typeof(st) == TYPE_DICTIONARY else 1
		var base: float = float(st.get("base", 0.0)) if typeof(st) == TYPE_DICTIONARY else 0.0
		var goal: int = int(m.goal) + int(m.step) * (lv - 1)
		var p: float = stat(d, m.stat) - base
		out.append({"def": m, "lv": lv, "goal": goal, "progress": p, "done": p >= float(goal), "claimed": false,
			"reward": repeat_reward(m, lv), "text": String(m.text) % goal})
	return out

static func claim_repeat(id: String) -> Dictionary:
	var d := read()
	for m in repeat(d):
		if m.def.id == id and m.done:
			grant(d, m.reward)
			var rp = d.get("repeat", {})
			if typeof(rp) != TYPE_DICTIONARY:
				rp = {}
			rp[id] = {"lv": int(m.lv) + 1, "base": stat(d, m.def.stat)}
			d["repeat"] = rp
	write(d)
	return d
