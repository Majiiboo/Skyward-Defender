class_name Contracts
extends RefCounted
# HERO CONTRACTS (2026-11-10). Each hero keeps his own tally of what he has done on duty (fights
# won, bugs put down, abilities fired) and is paid in HIS OWN shards at five marks along each
# tally. Shards feed his Ascend and his ability upgrades, so a contract is the steady way to grow
# a hero you like, and a reason to take the others out too. Quests > Career shows the three
# contracts of the hero on duty. Opens once stage CONTRACTS_FROM is cleared.
# Save "contracts": {hero: {"wins": n, "kills": n, "ability": n, "c_wins": marks paid, "c_kills": .., "c_ability": ..}}.

const CONTRACTS_FROM := 6
const KINDS := {
	"wins":    {"text": "Win %d fights with %s",          "marks": [3, 10, 25, 50, 100],          "shards": [5, 8, 12, 18, 30], "stat": "stages"},
	"kills":   {"text": "Put down %d bugs with %s",       "marks": [200, 1000, 3000, 8000, 20000], "shards": [4, 6, 10, 15, 25], "stat": "kills"},
	"ability": {"text": "Fire %2$s's ability %1$d times", "marks": [10, 40, 100, 250, 500],        "shards": [4, 6, 10, 15, 25], "stat": "stages"},
}
const ORDER := ["wins", "kills", "ability"]

static func open(save: Dictionary) -> bool:
	return DevTools.on or int(save.get("stage_unlocked", 1)) > CONTRACTS_FROM

static func _of(save: Dictionary, hero: String) -> Dictionary:
	var all = save.get("contracts", {})
	var h = all.get(hero, {}) if typeof(all) == TYPE_DICTIONARY else {}
	return h if typeof(h) == TYPE_DICTIONARY else {}

# after a fight: what the hero on duty did
static func add(save: Dictionary, hero: String, won: bool, kills: int, abilities: int) -> void:
	if not open(save) or not Heroes.ROSTER.has(hero):
		return
	var all = save.get("contracts", {})
	if typeof(all) != TYPE_DICTIONARY:
		all = {}
	var h := _of(save, hero).duplicate()
	h["wins"] = int(h.get("wins", 0)) + (1 if won else 0)
	h["kills"] = int(h.get("kills", 0)) + maxi(kills, 0)
	h["ability"] = int(h.get("ability", 0)) + maxi(abilities, 0)
	all[hero] = h
	save["contracts"] = all

# the hero's three contracts as they stand: [{"kind", "text", "progress", "goal", "reward", "done", "finished"}]
# ("finished" = all five marks paid; then progress / goal show the last mark)
static func list(save: Dictionary, hero: String) -> Array:
	var out: Array = []
	var h := _of(save, hero)
	var hname := String(Heroes.ROSTER[hero].name)
	for k in ORDER:
		var def: Dictionary = KINDS[k]
		var paid := clampi(int(h.get("c_" + k, 0)), 0, def.marks.size())
		var finished: bool = paid >= def.marks.size()
		var i := mini(paid, def.marks.size() - 1)
		var goal := int(def.marks[i])
		var prog := int(h.get(k, 0))
		var txt := String(def.text)
		txt = (txt % [goal, hname]) if not txt.contains("%2$s") else txt.replace("%2$s", hname).replace("%1$d", str(goal))
		out.append({"kind": k, "text": txt, "progress": prog, "goal": goal, "reward": {"shards": {hero: int(def.shards[i])}},
			"done": prog >= goal and not finished, "finished": finished, "stat": String(def.stat)})
	return out

static func claimable(save: Dictionary) -> bool:
	if not open(save):
		return false
	var hero := String(Heroes.read(save).selected)
	for c in list(save, hero):
		if c.done:
			return true
	return false

# take a finished contract's shards; returns the reward ({} = not ready)
static func claim(save: Dictionary, hero: String, kind: String) -> Dictionary:
	for c in list(save, hero):
		if String(c.kind) == kind and c.done:
			var all = save.get("contracts", {})
			var h := _of(save, hero).duplicate()
			h["c_" + kind] = int(h.get("c_" + kind, 0)) + 1
			all[hero] = h
			save["contracts"] = all
			Progress.grant(save, c.reward)
			return c.reward
	return {}
