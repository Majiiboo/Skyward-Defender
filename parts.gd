class_name Parts
extends RefCounted
# Upgrade parts (Rudy, dev115): the first upgrade levels cost coins only; higher ones
# also need parts that drop in battle. Short of parts? Crystals stand in for them.
# Used by every upgrade: gear pieces, turrets and the drone.
# Save: "parts": {"alloy": n, "cell": n, "core": n}.

const KINDS := {
	"alloy": {"name": "Alloy Scrap", "color": Color(0.55, 0.9, 1.0), "crystals": 2, "desc": "Common: bugs sometimes drop it."},
	"cell":  {"name": "Plasma Cell", "color": Color(0.7, 0.55, 1.0), "crystals": 6, "desc": "Rare: from mini-bosses and stage clears."},
	"core":  {"name": "Void Core",   "color": Color(1.0, 0.8, 0.35), "crystals": 15, "desc": "Epic: from bosses."},
}
const ORDER := ["alloy", "cell", "core"]

# Parts needed to go from `level` to level + 1 (coins come from each system's own cost).
# Lv.1-4: none. Lv.5-6: alloy. Lv.7-8: alloy + cells. Lv.9: alloy + cells + a core.
static func need(level: int) -> Dictionary:
	var n := {}
	if level >= 4:
		n["alloy"] = 3 * (level - 3)
	if level >= 6:
		n["cell"] = level - 5
	if level >= 8:
		n["core"] = level - 7
	return n

static func read(save: Dictionary) -> Dictionary:
	var p = save.get("parts", {})
	var out := {}
	for k in ORDER:
		out[k] = int(p.get(k, 0)) if typeof(p) == TYPE_DICTIONARY else 0
	return out

# crystals that would cover what is missing
static func crystals_for_missing(have: Dictionary, needs: Dictionary) -> int:
	var c := 0
	for k in needs:
		c += maxi(0, int(needs[k]) - int(have.get(k, 0))) * int(KINDS[k].crystals)
	return c

static func has_all(have: Dictionary, needs: Dictionary) -> bool:
	for k in needs:
		if int(have.get(k, 0)) < int(needs[k]):
			return false
	return true

# "6 Alloy, 1 Cell" (empty when no parts are needed)
static func text(needs: Dictionary) -> String:
	var bits: Array = []
	for k in ORDER:
		if needs.has(k):
			bits.append("%d %s" % [int(needs[k]), String(KINDS[k].name).split(" ")[1] if k != "alloy" else "Alloy"])
	return ", ".join(bits)

# Try to pay: coins + parts (crystals cover missing parts when allowed). Changes `save`
# in place; returns "" on success or why it failed.
static func pay(save: Dictionary, coins: int, needs: Dictionary, allow_crystals: bool) -> String:
	if int(save.get("coins", 0)) < coins:
		return "Not enough coins"
	var have := read(save)
	var extra := 0
	if not has_all(have, needs):
		if not allow_crystals:
			return "Not enough parts"
		extra = crystals_for_missing(have, needs)
		if int(save.get("crystals", 0)) < extra:
			return "Not enough crystals"
	save["coins"] = int(save.get("coins", 0)) - coins
	save["crystals"] = int(save.get("crystals", 0)) - extra
	for k in needs:
		have[k] = maxi(0, int(have[k]) - int(needs[k]))
	save["parts"] = have
	return ""
