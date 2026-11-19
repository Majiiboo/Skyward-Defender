class_name StageIntel
extends RefCounted
# WHAT A STAGE THROWS AT YOU (2026-11-18): the base is a loadout picked before the fight, so Home
# shows what the selected stage contains. Everything here is read from StageData.waves(stage) and
# the enemy defs (traits, move, shot, size): no stage numbers are written down in this file.
#   StageIntel.enemies(stage)  [{id, name, count, share, boss, pic, line}] most numerous first, bosses last
#   StageIntel.short(stage, n) the same list cut to n for the Home row (a boss always keeps its place)
#   StageIntel.tags(stage)     up to three threat tags [{id, name, text}]
#   StageIntel.suggest(stage)  up to two building ids (Base.BUILDINGS) that answer those tags
# Bugs a boss lays and the pods a dying bug bursts into are not in the wave list, so not counted.

const MAX_TAGS := 3
const MAX_SUGGEST := 2
const SMALL := 36.0   # a "small bug" is this size or under (the swarm)

# a tag shows when that kind of enemy is at least this share of the stage's bugs (bosses apart);
# "boss" = any boss at all
const TAGS := {
	"boss":     {"name": "Boss", "text": "A boss turns up", "min": 0.0},
	"shooters": {"name": "Shooters", "text": "They fire at your hero", "min": 0.12},
	"divers":   {"name": "Divers", "text": "They dive at your base", "min": 0.1},
	"armoured": {"name": "Armoured", "text": "Thick shells, slow to kill", "min": 0.12},
	"swarm":    {"name": "Swarm", "text": "Many small bugs", "min": 0.5},
}
# the buildings that answer a tag, best first (base.gd): shooters hurt the hero (Med Bay), divers hit
# the base (Hull Plating, then the shield), a swarm or thick shells want more damage (Armory; a
# swarm also leaks, so the Repair Bay), a boss is a long fight won with the ability (Reactor)
const ANSWERS := {
	"boss": ["reactor", "armory"],
	"shooters": ["medbay", "repair_bay"],
	"divers": ["plating", "shield_gen"],
	"armoured": ["armory", "reactor"],
	"swarm": ["armory", "repair_bay"],
}

static var _cache := {}

# where an enemy's picture lives: its own "tex", else the whole picture of its family
# (the same rule as Codex.enemy_tex)
static func pic_path(id: String) -> String:
	var def: Dictionary = StageData.ENEMIES[id]
	var p := String(def.get("tex", ""))
	if p != "" and ResourceLoader.exists(p):
		return p
	return "res://enemies/%s/%s_whole.png" % [String(def.get("family", "scrap")), id]

static func tex(id: String) -> Texture2D:
	return Codex.enemy_tex(id)

static func name_of(id: String) -> String:
	return String(StageData.ENEMIES[id].get("name", id.capitalize()))

# the first sentence of the enemy's "intro" text ("" when it has none)
static func line(id: String) -> String:
	var s := String(StageData.ENEMIES[id].get("intro", ""))
	var cut := s.length()
	for mark in [". ", "! ", ": "]:
		var k := s.find(mark)
		if k >= 0:
			cut = mini(cut, k + 1)
	s = s.substr(0, cut).strip_edges()
	return s.trim_suffix(":").trim_suffix(".")

static func enemies(stage: int) -> Array:
	stage = clampi(stage, 1, StageData.MAX_STAGE)
	if _cache.has(stage):
		return _cache[stage]
	var counts := {}
	var total := 0
	for wave in StageData.waves(stage):
		for spec in wave:
			var id := String(spec[0])
			if not StageData.ENEMIES.has(id):
				continue
			counts[id] = int(counts.get(id, 0)) + int(spec[1])
			total += int(spec[1])
	var out: Array = []
	for id in counts:
		out.append({"id": id, "name": name_of(id), "count": int(counts[id]), "share": float(counts[id]) / float(maxi(total, 1)),
			"boss": StageData.is_boss(id), "pic": pic_path(id), "line": line(id)})
	out.sort_custom(func(a, b):
		if a.boss != b.boss:
			return b.boss
		return a.count > b.count if a.count != b.count else String(a.id) < String(b.id))
	_cache[stage] = out
	return out

# the list cut to n entries: the most numerous, and the last place kept for a boss when there is one
static func short(stage: int, n: int = 5) -> Array:
	var all := enemies(stage)
	if all.size() <= n:
		return all
	var out: Array = []
	var boss = null
	for e in all:
		if e.boss:
			if boss == null:
				boss = e
		elif out.size() < n:
			out.append(e)
	if boss != null:
		out.resize(mini(out.size(), n - 1))
		out.append(boss)
	return out

static func _kind(def: Dictionary) -> Array:
	var kinds: Array = []
	var traits := Array(def.get("traits", []))
	if def.has("shot") or traits.has("shooter"):
		kinds.append("shooters")
	if String(def.get("move", "")) == "dive":
		kinds.append("divers")
	if traits.has("armoured"):
		kinds.append("armoured")
	if traits.has("swarm") and float(def.get("size", 99.0)) <= SMALL:
		kinds.append("swarm")
	return kinds

# up to three tags, the boss first, then the kinds furthest over their threshold
static func tags(stage: int) -> Array:
	var shares := {}
	var bugs := 0
	var has_boss := false
	var all := enemies(stage)
	for e in all:
		if e.boss:
			has_boss = true
		else:
			bugs += int(e.count)
	for e in all:
		if e.boss:
			continue
		for k in _kind(StageData.ENEMIES[e.id]):
			shares[k] = float(shares.get(k, 0.0)) + float(e.count) / float(maxi(bugs, 1))
	var found: Array = []
	for k in shares:
		var need := float(TAGS[k].min)
		if float(shares[k]) >= need:
			found.append([k, float(shares[k]) / need])
	found.sort_custom(func(a, b): return a[1] > b[1] if a[1] != b[1] else String(a[0]) < String(b[0]))
	var out: Array = []
	if has_boss:
		out.append({"id": "boss", "name": String(TAGS.boss.name), "text": String(TAGS.boss.text)})
	for f in found:
		if out.size() >= MAX_TAGS:
			break
		out.append({"id": f[0], "name": String(TAGS[f[0]].name), "text": String(TAGS[f[0]].text)})
	return out

# up to two buildings: the best answer to each tag in turn, then second answers if there is room
static func suggest(stage: int) -> Array:
	var out: Array = []
	var ts := tags(stage)
	for pass_i in 2:
		for t in ts:
			var opts: Array = ANSWERS.get(String(t.id), [])
			if pass_i >= opts.size():
				continue
			var id := String(opts[pass_i])
			if Base.BUILDINGS.has(id) and not out.has(id) and out.size() < MAX_SUGGEST:
				out.append(id)
	return out
