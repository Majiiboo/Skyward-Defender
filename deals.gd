class_name Deals
extends RefCounted
# TODAY'S DEALS (2026-11-10). Three offers that change every day, each a third or more off, each
# buyable once that day. Picked from POOL by the date, so everyone sees the same three and they
# cannot be re-rolled. One of them is always paid in coins, the others in crystals. A reason to
# look into the Store daily and a place for both currencies to go.
# Save "deals": {"day": n, "bought": [ids]}. Opens once stage DEALS_FROM is cleared.

const DEALS_FROM := 6
# "give" = the reward (hero shards go to the hero on duty: "shards_duty"); "cost" in "cur"; "was" = the usual price
const POOL := [
	{"id": "keys_u",   "name": "3 Uncommon Keys",  "give": {"key_u": 3},        "cur": "crystals", "cost": 40,   "was": 60,   "icon": "mat_key_u"},
	{"id": "key_e",    "name": "Epic Key",         "give": {"key_e": 1},        "cur": "crystals", "cost": 55,   "was": 80,   "icon": "mat_key_e"},
	{"id": "shards",   "name": "12 Hero Shards",   "give": {"shards_duty": 12}, "cur": "crystals", "cost": 90,   "was": 140,  "icon": "mat_shard"},
	{"id": "cores",    "name": "3 Power Cores",    "give": {"core": 3},         "cur": "crystals", "cost": 70,   "was": 105,  "icon": "ic_core"},
	{"id": "coins_big", "name": "6,000 Coins",     "give": {"coins": 6000},     "cur": "crystals", "cost": 45,   "was": 70,   "icon": "ic_coin"},
	{"id": "season_xp", "name": "150 Season XP",   "give": {"season_xp": 150},  "cur": "crystals", "cost": 60,   "was": 90,   "icon": "tab_trophies"},
	{"id": "alloy",    "name": "30 Alloy",         "give": {"alloy": 30},       "cur": "coins",    "cost": 1800, "was": 3000, "icon": "ic_alloy"},
	{"id": "cells",    "name": "10 Plasma Cells",  "give": {"cell": 10},        "cur": "coins",    "cost": 3500, "was": 5500, "icon": "ic_cell"},
	{"id": "key_coin", "name": "Uncommon Key",     "give": {"key_u": 1},        "cur": "coins",    "cost": 2500, "was": 4000, "icon": "mat_key_u"},
]

static func day() -> int:
	return Promotion.day()

static func open(save: Dictionary) -> bool:
	return DevTools.on or int(save.get("stage_unlocked", 1)) > DEALS_FROM

# today's three: one coin deal and two crystal deals, by the date
static func today(d: int = -1) -> Array:
	if d < 0:
		d = day()
	var coin: Array = []
	var crys: Array = []
	for p in POOL:
		if String(p.cur) == "coins":
			coin.append(p)
		else:
			crys.append(p)
	var a: int = absi(d * 7 + 3) % crys.size()
	var b: int = (a + 1 + absi(d * 5) % (crys.size() - 1)) % crys.size()
	return [crys[a], crys[b], coin[absi(d * 3 + 1) % coin.size()]]

static func bought(save: Dictionary) -> Array:
	var s = save.get("deals", {})
	if typeof(s) != TYPE_DICTIONARY or int(s.get("day", -1)) != day():
		return []
	return Array(s.get("bought", []))

static func off_percent(deal: Dictionary) -> int:
	return roundi(100.0 * (1.0 - float(deal.cost) / float(deal.was)))

static func why_not(save: Dictionary, deal: Dictionary) -> String:
	if not open(save):
		return "Opens after stage %d" % DEALS_FROM
	if bought(save).has(String(deal.id)):
		return "Bought today"
	if not DevTools.on and int(save.get(String(deal.cur), 0)) < int(deal.cost):
		return "%s %s needed" % [UIKit.num(int(deal.cost)), String(deal.cur)]
	return ""

# buy one of today's deals; "" on success
static func buy(save: Dictionary, id: String) -> String:
	for deal in today():
		if String(deal.id) != id:
			continue
		var why := why_not(save, deal)
		if why != "":
			return why
		if not DevTools.on:
			save[String(deal.cur)] = int(save.get(String(deal.cur), 0)) - int(deal.cost)
		var give: Dictionary = Dictionary(deal.give).duplicate()
		if give.has("shards_duty"):
			give["shards"] = {String(Heroes.read(save).selected): int(give.shards_duty)}
			give.erase("shards_duty")
		if give.has("season_xp"):
			Season.add_xp(save, int(give.season_xp))
			give.erase("season_xp")
		Progress.grant(save, give)
		var got := bought(save)
		got.append(id)
		save["deals"] = {"day": day(), "bought": got}
		return ""
	return "Not on offer today"
