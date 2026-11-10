class_name Research
extends RefCounted
# THE RESEARCH LAB (2026-11-10). Slow, permanent upgrades that run on REAL time: start a project,
# come back when it is done, collect it, start the next. One runs at a time. Each project has
# MAX_LEVEL levels; a level costs coins and takes longer than the one before (half an hour up to
# twelve hours). Crystals finish a project at once (1 crystal for every RUSH_MIN minutes left).
# It is a reason to open the game again, and a place for crystals to go.
# Opens once stage RESEARCH_FROM is cleared. Save "research": {"levels": {id: n}, "active": id,
# "done_at": unix seconds}.

const RESEARCH_FROM := 12
const MAX_LEVEL := 5
const TIME_S := [1800, 7200, 14400, 28800, 43200]        # seconds for level 1..5
const COST := [500, 1500, 4000, 9000, 20000]             # coins for level 1..5
const RUSH_MIN := 3                                      # minutes one crystal buys
const RUSH_FLOOR := 5
# "per" = what one level gives; "stat" = what the fight reads (Research.bonus)
const PROJECTS := {
	"shield_cells": {"name": "Shield Cells",   "icon": "st_def",    "stat": "shield",  "per": 0.03, "text": "Base shield +%d%%"},
	"hull_alloy":   {"name": "Hull Alloy",     "icon": "ic_base",   "stat": "hull",    "per": 0.03, "text": "Base hull +%d%%"},
	"ammunition":   {"name": "Ammunition",     "icon": "st_atk",    "stat": "damage",  "per": 0.02, "text": "Hero damage +%d%%"},
	"field_medic":  {"name": "Field Medicine", "icon": "st_hp",     "stat": "hp",      "per": 0.03, "text": "Hero health +%d%%"},
	"optics":       {"name": "Optics",         "icon": "st_aim",    "stat": "crit",    "per": 0.01, "text": "Crit rate +%d%%"},
	"drone_ai":     {"name": "Drone Brains",   "icon": "tab_drone", "stat": "drone",   "per": 0.05, "text": "Drone damage +%d%%"},
	"power_grid":   {"name": "Power Grid",     "icon": "ic_energy", "stat": "ability", "per": 0.03, "text": "The ability charges %d%% faster"},
	"salvage":      {"name": "Salvage Crews",  "icon": "ic_coin",   "stat": "coins",   "per": 0.03, "text": "Coins from fights +%d%%"},
}
const ORDER := ["shield_cells", "hull_alloy", "ammunition", "field_medic", "optics", "drone_ai", "power_grid", "salvage"]

static func now() -> int:
	return int(Time.get_unix_time_from_system())

static func open(save: Dictionary) -> bool:
	return DevTools.on or int(save.get("stage_unlocked", 1)) > RESEARCH_FROM

static func read(save: Dictionary) -> Dictionary:
	var out := {"levels": {}, "active": "", "done_at": 0}
	var r = save.get("research", {})
	if typeof(r) != TYPE_DICTIONARY:
		return out
	var lv = r.get("levels", {})
	if typeof(lv) == TYPE_DICTIONARY:
		for id in lv:
			if PROJECTS.has(id):
				out.levels[id] = clampi(int(lv[id]), 0, MAX_LEVEL)
	if PROJECTS.has(String(r.get("active", ""))):
		out.active = String(r.active)
		out.done_at = int(r.get("done_at", 0))
	return out

static func level(r: Dictionary, id: String) -> int:
	return int(r.levels.get(id, 0))

static func text(id: String, lv: int) -> String:
	return String(PROJECTS[id].text) % roundi(float(PROJECTS[id].per) * lv * 100.0)

static func cost(lv: int) -> int:
	return int(COST[clampi(lv, 0, MAX_LEVEL - 1)])

static func time_s(lv: int) -> int:
	return int(TIME_S[clampi(lv, 0, MAX_LEVEL - 1)])

# seconds left on the running project (0 = ready to collect, -1 = nothing running)
static func left_s(r: Dictionary) -> int:
	if String(r.active) == "":
		return -1
	return maxi(int(r.done_at) - now(), 0)

static func ready(save: Dictionary) -> bool:
	return open(save) and left_s(read(save)) == 0

static func idle(save: Dictionary) -> bool:
	return open(save) and left_s(read(save)) < 0

static func why_not_start(save: Dictionary, r: Dictionary, id: String) -> String:
	if String(r.active) != "":
		return "The lab is busy"
	if level(r, id) >= MAX_LEVEL:
		return "Finished"
	if not DevTools.on and int(save.get("coins", 0)) < cost(level(r, id)):
		return "%s coins needed" % UIKit.num(cost(level(r, id)))
	return ""

static func start(save: Dictionary, id: String) -> String:
	var r := read(save)
	var why := why_not_start(save, r, id)
	if why != "":
		return why
	if not DevTools.on:
		save["coins"] = int(save.get("coins", 0)) - cost(level(r, id))
	r.active = id
	r.done_at = now() + time_s(level(r, id))
	save["research"] = r
	return ""

# take a finished project: its level goes up, the lab is free again. Returns the project id ("" = not ready)
static func collect(save: Dictionary) -> String:
	var r := read(save)
	if left_s(r) != 0:
		return ""
	var id := String(r.active)
	r.levels[id] = mini(level(r, id) + 1, MAX_LEVEL)
	r.active = ""
	r.done_at = 0
	save["research"] = r
	return id

static func rush_cost(r: Dictionary) -> int:
	var s := left_s(r)
	if s <= 0:
		return 0
	return maxi(int(ceil(s / 60.0 / RUSH_MIN)), RUSH_FLOOR)

# finish the running project now with crystals; "" on success
static func rush(save: Dictionary) -> String:
	var r := read(save)
	var c := rush_cost(r)
	if c <= 0:
		return "Nothing to hurry"
	if not DevTools.on:
		if int(save.get("crystals", 0)) < c:
			return "%d crystals needed" % c
		save["crystals"] = int(save.get("crystals", 0)) - c
	r.done_at = now()
	save["research"] = r
	return ""

# what the finished levels give a fight
static func bonus(save: Dictionary) -> Dictionary:
	var out := {"shield": 0.0, "hull": 0.0, "damage": 0.0, "hp": 0.0, "crit": 0.0, "drone": 0.0, "ability": 0.0, "coins": 0.0}
	var r := read(save)
	for id in r.levels:
		out[String(PROJECTS[id].stat)] = float(out[String(PROJECTS[id].stat)]) + float(PROJECTS[id].per) * int(r.levels[id])
	return out

# "2h 05m" / "14m" / "40s"
static func time_text(s: int) -> String:
	if s >= 3600:
		return "%dh %02dm" % [s / 3600, (s % 3600) / 60]
	if s >= 60:
		return "%dm" % int(ceil(s / 60.0))
	return "%ds" % s
