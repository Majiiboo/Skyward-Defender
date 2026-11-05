extends Control
# Gear screen. Pilot page: the pilot (the live rig), the six gear slots (Weapon, Helmet,
# Chest, Gauntlets, Boots, Jetpack), the selected piece's stats with Upgrade (spends
# coins), the three pieces you can wear in that slot (Ion / Scavenger / Void sets),
# and the set bonuses you have. Rules and numbers: gear_data.gd. Turrets page: mounts
# and turret upgrades. Saved in user://skybound_save.json ("gear", "turrets").

var gear := {}             # GearData.read(save): {equipped, levels}
var selected_slot := "Weapon"
var _slot_tiles := {}
var _power_label: Label
var _detail: Label
var _bonus: Label
var _bag_grid: GridContainer
var _upgrade_btn: Button
var _pilot_box: VBoxContainer
var _turret_box: VBoxContainer
var _drone_box: VBoxContainer
var _workshop_box: VBoxContainer
var _ws_icons := {}        # part kind -> its TextureRect (merge pop)
var _suit_btn: Button
var drone := {}            # DroneData.read(save)
var _plat                    # PlatformFloor (set-bonus glow)
const SLOT_PX := 84.0       # gear slot tiles around the pilot

# ---- turrets page ----
var coins := 0
var pilot_level := 1
var t_loadout: Array = Turrets.DEFAULT_LOADOUT.duplicate()
var t_levels := {}         # turret id -> level (the three tracks added up; 1 if missing)
var t_tracks := {}         # turret id -> {atk, rate, range} (Turrets upgrade tracks)
var _t_tracks_btn := {}    # track -> its Upgrade button
var t_mount := 0           # selected mount
var t_unlocked := 1        # save stage_unlocked: which mounts are open (Turrets.mount_open)
var t_focus := ""          # turret shown in the detail panel
var _mount_row: HBoxContainer
var _turret_grid: GridContainer
var _t_detail: Label
var _t_place: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_load()
	_build()
	_select(selected_slot)
	_fade_in_overlay()

func _read() -> Dictionary:
	if FileAccess.file_exists("user://skybound_save.json"):
		var f := FileAccess.open("user://skybound_save.json", FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if typeof(d) == TYPE_DICTIONARY:
				return d
	return {}

func _load() -> void:
	var data := _read()
	var t := Turrets.read(data)
	t_loadout = t.loadout
	t_levels = t.levels
	t_tracks = t.tracks
	coins = int(data.get("coins", 0))
	pilot_level = Turrets.pilot_level(int(data.get("pilot_xp", 0)))
	t_unlocked = int(data.get("stage_unlocked", 1))
	gear = GearData.read(data)
	drone = DroneData.read(data)
	PilotRig.set_gear(data)

func _save() -> void:
	var data := _read()
	data["gear"] = {"equipped": gear.equipped, "levels": gear.levels}
	data["coins"] = coins
	# the jetpack sets the thruster style (the Home wallpaper reads "thruster")
	data["thruster"] = GearData.SETS[GearData.ITEMS[gear.equipped["Jetpack"]].set].thruster
	var out := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(data))
	PilotRig.set_gear(data)   # the showcase pilot holds the new weapon at once

func _lvl(id: String) -> int:
	return GearData.level(gear, id)

# Luna's picture of the piece at its upgrade tier (the old painted one as a fallback)
func _pic(id: String) -> Texture2D:
	var p := "res://gear/%s_t%d.png" % [id, GearData.tier(_lvl(id))]
	return load(p) if ResourceLoader.exists(p) else load("res://gear/%s.png" % id)

# ------------------------------------------------------------------ build

func _build() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var root := MarginContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for m in ["margin_left", "margin_right"]:
		root.add_theme_constant_override(m, 12)
	root.add_theme_constant_override("margin_top", 10)
	root.add_theme_constant_override("margin_bottom", 16)
	scroll.add_child(root)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	root.add_child(col)
	# title row
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	var back := UIKit.ghost_button("Back")
	back.name = "BackButton"
	back.custom_minimum_size = Vector2(70, 32)
	back.pressed.connect(_on_back_pressed)
	top.add_child(back)
	top.add_child(UIKit.screen_title("GEAR"))
	var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	_power_label = UIKit.label("", 13, UIKit.GOLD)
	top.add_child(_power_label)
	col.add_child(top)
	# Pilot / Turrets switch
	col.add_child(UIKit.tabs(["Pilot", "Turrets", "Drone", "Workshop"], _show_page, 0))
	_workshop_box = VBoxContainer.new()
	_workshop_box.add_theme_constant_override("separation", 10)
	_workshop_box.visible = false
	col.add_child(_workshop_box)
	_drone_box = VBoxContainer.new()
	_drone_box.add_theme_constant_override("separation", 10)
	_drone_box.visible = false
	col.add_child(_drone_box)
	_turret_box = VBoxContainer.new()
	_turret_box.add_theme_constant_override("separation", 10)
	_turret_box.visible = false
	col.add_child(_turret_box)
	_build_turrets(_turret_box)
	_pilot_box = VBoxContainer.new()
	_pilot_box.add_theme_constant_override("separation", 10)
	col.add_child(_pilot_box)
	col = _pilot_box
	# the pilot (live rig) on his platform, three slots on each side (Luna's mockup)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0, 318)
	col.add_child(stage)
	var plat := PlatformFloor.new()
	plat.set_anchors_preset(Control.PRESET_FULL_RECT)
	plat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(plat)
	_plat = plat
	var hero := PilotShowcase.new()
	hero.plat = plat
	hero.set_anchors_preset(Control.PRESET_FULL_RECT)
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(hero)
	for i in GearData.SLOTS.size():
		var s: String = GearData.SLOTS[i]
		var b := Button.new()
		b.size = Vector2(SLOT_PX, SLOT_PX)
		var right := i >= 3
		b.position = Vector2(-SLOT_PX if right else 0.0, (i % 3) * (SLOT_PX + 12.0) + 6.0)
		for st in ["normal", "hover", "pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		var slot: String = s
		b.pressed.connect(func(): _select(slot))
		b.draw.connect(func(): _draw_slot(b, slot))
		stage.add_child(b)
		_slot_tiles[s] = b
	stage.resized.connect(func():
		for i in GearData.SLOTS.size():
			var tb: Button = _slot_tiles[GearData.SLOTS[i]]
			tb.position.x = stage.size.x - SLOT_PX if i >= 3 else 0.0)
	plat.tiles = _slot_tiles
	# the suit switch (Rookie / Commander) on the platform steps
	_suit_btn = UIKit.ghost_button("", 11)
	_suit_btn.custom_minimum_size = Vector2(160, 28)
	_suit_btn.pressed.connect(_toggle_suit)
	stage.add_child(_suit_btn)
	stage.resized.connect(func(): _suit_btn.position = Vector2(stage.size.x * 0.5 - 80.0, stage.size.y - 30.0))
	# Stats: your numbers right now (pilot, base, turrets)
	var stats_btn := UIKit.ghost_button("STATS", 11)
	stats_btn.custom_minimum_size = Vector2(64, 26)
	stats_btn.pressed.connect(_show_stats)
	stage.add_child(stats_btn)
	stage.resized.connect(func(): stats_btn.position = Vector2(stage.size.x - SLOT_PX - 74.0, 4.0))
	_paint_suit()
	# selected piece: stats + upgrade, right under the pilot (used most)
	var up_row := HBoxContainer.new()
	up_row.add_theme_constant_override("separation", 10)
	var dp := UIKit.panel(10)
	dp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail = UIKit.label("", 12, Color(0.85, 0.92, 1.0))
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dp.add_child(_detail)
	up_row.add_child(dp)
	_upgrade_btn = UIKit.gold_button("Upgrade", 14)
	_upgrade_btn.custom_minimum_size = Vector2(118, 50)
	_upgrade_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_upgrade_btn.pressed.connect(_on_upgrade_pressed)
	up_row.add_child(_upgrade_btn)
	col.add_child(up_row)
	# the six pieces for this slot (one per set)
	col.add_child(UIKit.header("CHOOSE"))
	_bag_grid = GridContainer.new()
	_bag_grid.columns = 3
	_bag_grid.add_theme_constant_override("h_separation", 8)
	_bag_grid.add_theme_constant_override("v_separation", 8)
	col.add_child(_bag_grid)
	# set bonuses you have, last
	var bp := UIKit.panel(10)
	_bonus = UIKit.label("", 12, Color(0.85, 0.92, 1.0))
	_bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bp.add_child(_bonus)
	col.add_child(bp)

# The suit (PilotRig.suit_for): Rookie, or the Commander armour once the Area 1 boss is beaten.
func _paint_suit() -> void:
	var data := _read()
	if PilotRig.commander_unlocked(data):
		_suit_btn.text = "Suit: Commander" if PilotRig.suit_for(data) == "commander" else "Suit: Rookie"
		_suit_btn.disabled = false
	else:
		_suit_btn.text = "Commander suit: stage %d" % PilotRig.COMMANDER_STAGE
		_suit_btn.disabled = true

func _toggle_suit() -> void:
	var data := _read()
	data["suit"] = "starter" if PilotRig.suit_for(data) == "commander" else "commander"
	var out := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(data))
		out.close()
	PilotRig.set_gear(data)
	_paint_suit()
	if _plat:
		_plat.flash()

# A slot tile: the piece's picture, slot name and level, in its set's colour.
func _paint_slot(s: String) -> void:
	var b: Button = _slot_tiles[s]
	for c in b.get_children():
		c.queue_free()
	var id: String = gear.equipped[s]
	b.queue_redraw()
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	var tr := TextureRect.new()
	tr.texture = _pic(id)
	tr.custom_minimum_size = Vector2(0, 42)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(tr)
	v.add_child(UIKit.label(s, 10, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UIKit.label("Lv.%d" % _lvl(id), 11, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	b.add_child(v)

# the tile itself: a glass square, lit in its set's colour when selected
func _draw_slot(b: Button, s: String) -> void:
	var on := s == selected_slot
	var col: Color = UIKit.RARITY[GearData.ITEMS[gear.equipped[s]].set]
	var edge := Color(col, 0.95) if on else Color(col, 0.45)
	var fill := Color(col.r * 0.2, col.g * 0.2, col.b * 0.28, 0.8) if on else Glass.FILL
	Glass.panel(b, Glass.box(Rect2(Vector2.ZERO, b.size), 12.0), 1.0, edge, fill)

func _fill_bag() -> void:
	for c in _bag_grid.get_children():
		c.queue_free()
	for set_id in GearData.SETS:
		var id: String = "%s_%s" % [set_id, selected_slot.to_lower()]
		var info: Dictionary = GearData.ITEMS[id]
		var open := GearData.set_unlocked(set_id, t_unlocked)
		var is_on: bool = gear.equipped[selected_slot] == id
		var sub := "Wearing" if is_on else ("Lv.%d" % _lvl(id) if open else "Stage %d" % (int(GearData.SETS[set_id].unlock_stage) - 1))
		var t := UIKit.tile(info.name, sub, set_id, GearData.SETS[set_id].name, _pic(id) if open else load("res://icons/ui_padlock.png"), Vector2(108, 88))
		if not open:
			t.tooltip_text = "Clear stage %d" % (int(GearData.SETS[set_id].unlock_stage) - 1)
		if not open:
			t.modulate = Color(0.55, 0.55, 0.65, 0.8)
		var item: String = id
		t.pressed.connect(func():
			if open:
				_equip(item))
		_bag_grid.add_child(t)

# ------------------------------------------------------------------ actions

func _select(slot: String) -> void:
	selected_slot = slot
	for s in GearData.SLOTS:
		_paint_slot(s)
	_fill_bag()
	var id: String = gear.equipped[slot]
	var info: Dictionary = GearData.ITEMS[id]
	var lv := _lvl(id)
	var st: Dictionary = GearData.SLOT_STAT[slot]
	var set_info: Dictionary = GearData.SETS[info.set]
	# short and plain (Rudy): name, the main stat with its next level, the set's extra
	var next_txt := ("  ->  " + _stat_text(slot, lv + 1)) if lv < GearData.MAX_LEVEL else "  (max)"
	_detail.text = "%s  Lv.%d\n%s %s%s\n%s" % [info.name, lv, st.text, _stat_text(slot, lv), next_txt, set_info.minor]
	# its milestone (Lv.5 and Lv.10): what it gives, and how many it has reached
	var gms: Dictionary = GearData.MILESTONE[slot]
	var got := GearData.milestones(lv)
	if got >= 2:
		_detail.text += "\n%s  x2 (max)" % gms.text
	else:
		_detail.text += "\n%s  %s" % [gms.text, ("x%d, next Lv.10" % got) if got > 0 else "at Lv.5"]
	if slot == "Weapon":
		_detail.text += "\n" + GearData.WEAPON_TEXT[set_info.weapon]
	var cost := GearData.upgrade_cost(lv)
	_upgrade_btn.disabled = lv >= GearData.MAX_LEVEL or coins < cost
	_upgrade_btn.text = "MAX" if lv >= GearData.MAX_LEVEL else _upgrade_text(cost, lv)
	_power_label.text = "POWER %d  ·  %d coins" % [GearData.power(gear), coins]
	var lines: Array = []
	for set_id in GearData.SETS:
		var n := GearData.set_count(gear, set_id)
		if n == 0:
			continue
		var s: Dictionary = GearData.SETS[set_id]
		var b3: String = s.bonus3 if n >= 3 else "3: " + s.bonus3
		var b6: String = s.bonus6 if n >= 6 else "6: " + s.bonus6
		lines.append("%s %d/6  ·  %s  ·  %s" % [s.name, n, b3, b6])
	_bonus.text = "SETS\n" + "\n".join(lines)
	# the platform's buildings light up in the colour of your strongest set
	if _plat:
		var best := ""
		var best_n := 0
		for set_id in GearData.SETS:
			var n := GearData.set_count(gear, set_id)
			if n > best_n:
				best = set_id
				best_n = n
		_plat.glow = 1.0 if best_n >= 6 else (0.5 if best_n >= 3 else 0.0)
		if best != "":
			_plat.glow_col = UIKit.RARITY[best]

func _stat_text(slot: String, lv: int) -> String:
	var per: float = float(GearData.SLOT_STAT[slot].per)
	match slot:
		"Boots":
			return "+%d px" % int(per * lv)
		"Chest":
			var hearts := (1 if lv >= 5 else 0) + (1 if lv >= 10 else 0)
			return "+%d%%%s" % [int(per * lv * 100.0), ("  +%d heart%s" % [hearts, "s" if hearts > 1 else ""]) if hearts > 0 else ""]
	return "+%d%%" % int(round(per * lv * 100.0))

func _equip(id: String) -> void:
	gear.equipped[selected_slot] = id
	_save()
	_select(selected_slot)

func _on_upgrade_pressed() -> void:
	var id: String = gear.equipped[selected_slot]
	var lv := _lvl(id)
	var cost := GearData.upgrade_cost(lv)
	if lv >= GearData.MAX_LEVEL or coins < cost:
		return
	if not await _pay_upgrade(cost, lv):
		return
	gear.levels[id] = lv + 1
	if GearData.milestones(lv + 1) > GearData.milestones(lv):
		_milestone_toast("%s reached Lv.%d: %s" % [GearData.ITEMS[id].name, lv + 1, GearData.MILESTONE[selected_slot].text])
	_save()
	_select(selected_slot)
	if _plat:
		_plat.glow_col = UIKit.RARITY[GearData.ITEMS[id].set] if _plat.glow <= 0.0 else _plat.glow_col
		_plat.flash()
	var b: Button = _slot_tiles[selected_slot]
	b.pivot_offset = b.size * 0.5
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2(1.12, 1.12), 0.1)
	tw.tween_property(b, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _show_page(i: int) -> void:
	_pilot_box.visible = i == 0
	_turret_box.visible = i == 1
	_drone_box.visible = i == 2
	_workshop_box.visible = i == 3
	if i == 1:
		_refresh_turrets()
	elif i == 2:
		_refresh_drone()
	elif i == 3:
		_refresh_workshop()
	else:
		_select(selected_slot)


# ------------------------------------------------------------------ stats panel
# Your numbers right now (Rudy): the pilot's damage, crits and fire rate; the base's shield,
# hull and damage reduction; each turret on the base. Power cards in a run add to these.
const BATTLE := preload("res://battle.gd")

func _show_stats() -> void:
	var data := _read()
	var gs := GearData.stats(data)
	var w: Dictionary = BATTLE.WEAPONS[gs.weapon]
	var hit: float = float(w.damage) * float(gs.damage) * (1.0 + float(gs.dmg_boost))
	var per_s: float = float(w.projectiles) * float(gs.fire_rate) / float(w.interval)
	var crit_avg: float = 1.0 + float(gs.crit_rate) * (float(gs.crit_dmg) - 1.0)
	var layer := ColorRect.new()
	layer.color = Color(0, 0.01, 0.04, 0.78)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var p := UIKit.panel(14)
	var pw := minf(size.x - 32.0, 420.0)
	p.custom_minimum_size = Vector2(pw, 0)
	p.position = Vector2((size.x - pw) * 0.5, 70.0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.add_child(UIKit.label("STATS", 18, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UIKit.header("PILOT"))
	_stat_rows(v, [
		["Damage per hit", "%.2f" % hit],
		["Shots per second", "%.1f" % per_s],
		["Damage per second", "%.1f" % (hit * per_s * crit_avg)],
		["Crit rate", "%d%%" % roundi(float(gs.crit_rate) * 100.0)],
		["Crit damage", "x%.2f" % float(gs.crit_dmg)],
		["Damage boost", "+%d%%" % roundi(float(gs.dmg_boost) * 100.0)],
		["Hearts", str(3 + int(gs.hearts))],
	])
	v.add_child(UIKit.header("BASE"))
	_stat_rows(v, [
		["Shield", "%d" % roundi(BATTLE.BASE_SHIELD * float(gs.shield) * float(gs.fortress))],
		["Hull (fortress HP)", "%d" % roundi(BATTLE.BASE_HULL * float(gs.fortress))],
		["Damage taken", "-%d%%" % roundi(float(gs.base_dr) * 100.0)],
	])
	v.add_child(UIKit.header("TURRETS"))
	var tdat := Turrets.read(data)
	var rows: Array = []
	for i in Turrets.MOUNTS:
		var id: String = tdat.loadout[i]
		if id == "" or not Turrets.mount_open(i, t_unlocked) or pilot_level < int(Turrets.TURRETS[id].unlock):
			continue
		var tr := Turrets.one_tracks(tdat.tracks, id)
		var s := Turrets.stats(id, tr)
		var dmg: float = float(s.damage) * float(gs.turret_dmg)
		var every: float = float(s.every) / float(gs.turret_rate)
		rows.append(["%s Lv.%d" % [Turrets.TURRETS[id].name, Turrets.level_of(tr)], "%.1f every %.2f s" % [dmg, every]])
	if rows.is_empty():
		rows.append(["No turrets on the base", "-"])
	_stat_rows(v, rows)
	v.add_child(UIKit.label("Power cards in a run add to these", 11, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var close := UIKit.ghost_button("Close", 14)
	close.custom_minimum_size = Vector2(0, 40)
	close.pressed.connect(layer.queue_free)
	v.add_child(close)
	p.add_child(v)
	layer.add_child(p)

# label on the left, value on the right
func _stat_rows(box: VBoxContainer, rows: Array) -> void:
	for r in rows:
		var h := HBoxContainer.new()
		var l := UIKit.label(r[0], 13, Color(0.82, 0.9, 1.0))
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		h.add_child(UIKit.label(r[1], 13, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT))
		box.add_child(h)

# ------------------------------------------------------------------ workshop page
# Merging (Rudy): 3 of a part -> 1 of the next (Parts.MERGE). Your parts in a row, then
# one card per merge with Merge (one) and All. Gear and turret merging come later.
func _refresh_workshop(pop: String = "") -> void:
	for c in _workshop_box.get_children():
		c.queue_free()
	_ws_icons = {}
	var have := Parts.read(_read())
	_workshop_box.add_child(UIKit.header("YOUR PARTS"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for k in Parts.ORDER:
		var p := UIKit.panel(10)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		var tr := _part_icon(k, 52)
		_ws_icons[k] = tr
		v.add_child(tr)
		v.add_child(UIKit.label(String(Parts.KINDS[k].name), 11, Parts.KINDS[k].color, HORIZONTAL_ALIGNMENT_CENTER))
		v.add_child(UIKit.label("x%d" % int(have[k]), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
		p.add_child(v)
		row.add_child(p)
	_workshop_box.add_child(row)
	_workshop_box.add_child(UIKit.header("MERGE"))
	for k in Parts.MERGE:
		var to: String = Parts.MERGE[k]
		var n: int = int(have[k]) / Parts.MERGE_COST
		var p := UIKit.panel(10)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_child(_part_icon(k, 40))
		h.add_child(UIKit.label("x%d" % Parts.MERGE_COST, 16, Color.WHITE))
		h.add_child(UIKit.label("  ->  ", 16, UIKit.MUTED))
		h.add_child(_part_icon(to, 40))
		h.add_child(UIKit.label("x1", 16, Color.WHITE))
		var sp := Control.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(sp)
		var one := UIKit.gold_button("Merge", 14)
		one.custom_minimum_size = Vector2(84, 40)
		one.disabled = n <= 0
		var kind: String = k
		one.pressed.connect(func(): _merge(kind, 1))
		h.add_child(one)
		var all := UIKit.ghost_button("All (%d)" % n, 13)
		all.custom_minimum_size = Vector2(70, 40)
		all.disabled = n <= 1
		all.pressed.connect(func(): _merge(kind, -1))
		h.add_child(all)
		p.add_child(h)
		_workshop_box.add_child(p)
	_workshop_box.add_child(UIKit.label("Gear and turret merging: coming soon", 12, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	if pop != "" and _ws_icons.has(pop):
		var tr: TextureRect = _ws_icons[pop]
		await get_tree().process_frame
		tr.pivot_offset = tr.size * 0.5
		var tw := tr.create_tween()
		tw.tween_property(tr, "scale", Vector2(1.35, 1.35), 0.1)
		tw.tween_property(tr, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _part_icon(kind: String, px: float) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = Parts.icon(kind)
	tr.custom_minimum_size = Vector2(px, px)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr

func _merge(kind: String, times: int) -> void:
	var data := _read()
	var made := Parts.merge(data, kind, times)
	if made <= 0:
		return
	var out := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(data))
		out.close()
	var to: String = Parts.MERGE[kind]
	var fx := MergeFX.new()
	fx.src = Parts.icon(kind)
	fx.dst = Parts.icon(to)
	fx.col = Parts.KINDS[to].color
	fx.title = "+%d %s%s" % [made, Parts.KINDS[to].name, "s" if made > 1 else ""]
	add_child(fx)
	await fx.finished
	_refresh_workshop(to)

# ------------------------------------------------------------------ drone page
# The drone sidekick (DroneData): a big preview, its body and weapon pod to choose,
# what it does, and Upgrade (coins). Locked until pilot level 8.
func _refresh_drone() -> void:
	for c in _drone_box.get_children():
		c.queue_free()
	if not DroneData.unlocked(pilot_level):
		var lp := UIKit.panel(14)
		var lv := VBoxContainer.new()
		lv.add_child(UIKit.label("DRONE SIDEKICK", 16, UIKit.CYAN, HORIZONTAL_ALIGNMENT_CENTER))
		var t := UIKit.label("A drone that flies beside you and shoots with you. It unlocks at pilot level %d (you are level %d)." % [DroneData.UNLOCK_LEVEL, pilot_level], 13, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lv.add_child(t)
		lp.add_child(lv)
		_drone_box.add_child(lp)
		return
	var body: Dictionary = DroneData.BODIES[drone.body]
	var pod: Dictionary = DroneData.PODS[drone.pod]
	# preview: the drone hovering, turning a little
	var pv := Control.new()
	pv.custom_minimum_size = Vector2(0, 170)
	var bt: Texture2D = load("res://drone/body_%s.png" % drone.body)
	var pt: Texture2D = load("res://drone/pod_%s.png" % drone.pod)
	var tm := [0.0]
	pv.draw.connect(func():
		var c := pv.size * 0.5 + Vector2(0, sin(tm[0] * 2.0) * 5.0)
		Glass.panel(pv, Glass.box(Rect2(Vector2.ZERO, pv.size), 16.0))
		pv.draw_set_transform(c, sin(tm[0] * 0.8) * 0.25, Vector2.ONE)
		var bw := 130.0
		var bh: float = bw * bt.get_height() / bt.get_width()
		var pw := 52.0
		var ph: float = pw * pt.get_height() / pt.get_width()
		pv.draw_texture_rect(pt, Rect2(-pw * 0.5, -bh * 0.35 - ph * 0.5, pw, ph), false)
		pv.draw_texture_rect(bt, Rect2(-bw * 0.5, -bh * 0.5, bw, bh), false)
		pv.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE))
	var tw := pv.create_tween().set_loops()
	tw.tween_method(func(v): tm[0] = v; pv.queue_redraw(), 0.0, TAU * 2.0, 8.0)
	_drone_box.add_child(pv)
	var lvl: int = int(drone.level)
	var dmg: float = float(pod.damage) * float(body.dmg) * DroneData.level_mult(lvl)
	var info := UIKit.label("%s + %s  Lv.%d\nATK %.1f  ·  every %.2f s\n%s  ·  %s" % [body.name, pod.name, lvl, dmg, float(pod.every) / float(body.rate), body.desc, pod.desc], 12, Color(0.85, 0.92, 1.0))
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var ip := UIKit.panel(10)
	ip.add_child(info)
	var urow := HBoxContainer.new()
	urow.add_theme_constant_override("separation", 10)
	ip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	urow.add_child(ip)
	var up := UIKit.gold_button("MAX" if lvl >= DroneData.MAX_LEVEL else _upgrade_text(DroneData.upgrade_cost(lvl), lvl), 13)
	up.custom_minimum_size = Vector2(118, 50)
	up.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	up.disabled = lvl >= DroneData.MAX_LEVEL or coins < DroneData.upgrade_cost(lvl)
	up.pressed.connect(func():
		var cost := DroneData.upgrade_cost(int(drone.level))
		if coins >= cost and int(drone.level) < DroneData.MAX_LEVEL and await _pay_upgrade(cost, int(drone.level)):
			drone.level = int(drone.level) + 1
			_save_drone()
			_refresh_drone())
	urow.add_child(up)
	_drone_box.add_child(urow)
	for spec in [["BODY", DroneData.BODIES, "body"], ["WEAPON POD", DroneData.PODS, "pod"]]:
		_drone_box.add_child(UIKit.header(spec[0]))
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 8)
		for id in spec[1]:
			var def: Dictionary = spec[1][id]
			var open: bool = pilot_level >= int(def.unlock)
			var on: bool = drone[spec[2]] == id
			var sub := "Equipped" if on else ("Choose" if open else "Pilot Lv.%d" % int(def.unlock))
			var tile := UIKit.tile(def.name, sub, "ion" if on else "common", "", load("res://drone/%s_%s.png" % [spec[2], id]), Vector2(108, 92))
			if not open:
				tile.modulate = Color(0.55, 0.55, 0.65, 0.8)
			var key: String = spec[2]
			var pick: String = id
			tile.pressed.connect(func():
				if open:
					drone[key] = pick
					_save_drone()
					_refresh_drone())
			grid.add_child(tile)
		_drone_box.add_child(grid)
	_power_label.text = "DRONE Lv.%d  ·  %d coins" % [lvl, coins]

func _save_drone() -> void:
	var data := _read()
	data["drone"] = drone
	data["coins"] = coins
	var out := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(data))

# The pilot standing in the Gear screen: the same live rig as in battle, idling, his
# rifle drifting, flames in the equipped jetpack's style.
class PilotShowcase extends Control:
	var view: PilotRigView
	var plat   # PlatformFloor: where his feet go
	var t := 0.0
	func _ready() -> void:
		view = PilotRigView.new()
		view.height = 156.0
		view.front_only = true   # facing you, chunky and big-headed (Rudy)
		add_child(view)
	func _process(delta: float) -> void:
		t += delta
		var aim := -PI / 2.0 - 0.3 + sin(t * 0.7) * 0.35
		# hovering just above the platform floor
		var feet: float = plat.feet_y() if plat else size.y - 40.0
		view.update(delta, Vector2(size.x * 0.5, feet - 84.0 + sin(t * 1.6) * 3.0), aim, sin(t * 0.5) * 0.2, 1.0 + sin(t * 0.9) * 0.2, 0.0)

# The round platform he stands on: Luna's two layers (gear/platform_floor.png + the
# buildings on the back rim, platform_rim.png), else her single picture (platform.png),
# else a code stand-in. Thin lines link each slot tile to the platform. Set-bonus glow:
# with 3 pieces of one set the rim's windows light up in that set's colour, with all 6
# they glow fully and breathe (platform_rim_lights.png on an additive layer); flash()
# makes them flare when a piece is upgraded.
class PlatformFloor extends Control:
	const FLOOR_UP := 34.0     # stand-in disc centre, up from the bottom of the stage
	const TEX_W := 262.0       # Luna's platform: drawn width, bottom on the stage bottom
	const TEX_FEET := 0.56     # where he stands, as a share of her picture's height
	var tiles := {}
	var t := 0.0
	var _tex: Texture2D        # the floor (or the single picture)
	var _rim: Texture2D
	var _lights: Texture2D       # rim windows (with halo)
	var _floor_lights: Texture2D # the deck's grid lines
	var _light_layer: Control
	var glow := 0.0               # 0 no set bonus, 0.5 three pieces, 1.0 all six
	var glow_col := Glass.CYAN
	var _flash := 0.0
	func _ready() -> void:
		if ResourceLoader.exists("res://gear/platform_floor.png") and ResourceLoader.exists("res://gear/platform_rim.png"):
			_tex = load("res://gear/platform_floor.png")
			_rim = load("res://gear/platform_rim.png")
			if ResourceLoader.exists("res://gear/platform_rim_lights.png"):
				_lights = load("res://gear/platform_rim_lights.png")
			if ResourceLoader.exists("res://gear/platform_floor_lights.png"):
				_floor_lights = load("res://gear/platform_floor_lights.png")
		elif ResourceLoader.exists("res://gear/platform.png"):
			_tex = load("res://gear/platform.png")
		_light_layer = Control.new()
		_light_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		_light_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var add := CanvasItemMaterial.new()
		add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_light_layer.material = add
		_light_layer.draw.connect(_draw_lights)
		add_child(_light_layer)
	func flash() -> void:
		_flash = 1.0
	func _process(delta: float) -> void:
		t += delta
		_flash = maxf(_flash - delta * 1.5, 0.0)
		queue_redraw()
		_light_layer.queue_redraw()
	# how strongly the set colour shows: steady at 3 pieces, breathing at 6, a flare on
	# upgrade
	func _glow_k() -> float:
		return minf(glow * (0.75 + 0.25 * sin(t * 2.4) if glow >= 1.0 else 1.0) + _flash, 1.0)
	# light added on top: the rim windows' halo, a little on the deck lines
	func _draw_lights() -> void:
		var k := _glow_k()
		if _lights == null or not _tex or k <= 0.01:
			return
		var r := _tex_rect()
		_light_layer.draw_texture_rect(_lights, r, false, Color(glow_col, k))
		if _floor_lights:
			_light_layer.draw_texture_rect(_floor_lights, r, false, Color(glow_col, k * 0.12))
	func _tex_rect() -> Rect2:
		var h := TEX_W * _tex.get_height() / _tex.get_width()
		return Rect2(size.x * 0.5 - TEX_W * 0.5, size.y - h, TEX_W, h)
	func feet_y() -> float:
		if _tex:
			var r := _tex_rect()
			return r.position.y + r.size.y * TEX_FEET
		return size.y - FLOOR_UP
	func _draw() -> void:
		var c := Vector2(size.x * 0.5, size.y - FLOOR_UP)
		var rx := minf(size.x * 0.3, 130.0)
		var ry := rx * 0.24
		# links from the tiles to the platform rim
		for s in tiles:
			var b: Button = tiles[s]
			var left: bool = b.position.x < size.x * 0.5
			var from := Vector2(b.position.x + (b.size.x if left else 0.0), b.position.y + b.size.y * 0.5)
			var to := c + Vector2((-rx if left else rx) * 0.8, -ry * 0.4)
			draw_line(from, from.lerp(to, 0.35), Color(Glass.CYAN, 0.25), 1.0, true)
		if _tex:
			# the lit lines and windows are repainted in the set colour (over Luna's cyan)
			var tr := _tex_rect()
			var k := _glow_k()
			draw_texture_rect(_tex, tr, false, Color(0.56, 0.58, 0.66))   # toned down: the grid was too bright (Rudy)
			if _floor_lights and k > 0.01:
				draw_texture_rect(_floor_lights, tr, false, Color(glow_col, 0.45 * k))
			if _rim:
				draw_texture_rect(_rim, tr, false)
			if _lights and k > 0.01:
				draw_texture_rect(_lights, tr, false, Color(glow_col, 0.6 * k))
			return
		# stand-in: side band, top disc, rings, grid, and a slow light sweeping round
		_ellipse(c + Vector2(0, 9), rx, ry, Color(0.03, 0.05, 0.11, 0.95))
		_ellipse(c, rx, ry, Color(0.06, 0.1, 0.2, 0.95))
		for k in 3:
			_ring(c, rx * (1.0 - k * 0.22), ry * (1.0 - k * 0.22), Color(Glass.CYAN, 0.55 - k * 0.15))
		for k in range(-3, 4):
			var x := k * rx * 0.22
			var hy := ry * sqrt(maxf(0.0, 1.0 - pow(x / (rx * 0.78), 2.0))) * 0.78
			draw_line(c + Vector2(x, -hy), c + Vector2(x, hy), Color(Glass.CYAN, 0.12), 1.0, true)
		var a := t * 0.8
		var sweep := PackedVector2Array()
		for i in 13:
			var k := a + 0.9 * i / 12.0
			sweep.append(c + Vector2(cos(k) * rx, sin(k) * ry))
		draw_polyline(sweep, Color(Glass.PURPLE, 0.7), 2.0, true)
		_ring(c + Vector2(0, 9), rx, ry, Color(Glass.PURPLE, 0.35))
	func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 40:
			var a := TAU * i / 40.0
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		draw_colored_polygon(pts, col)
	func _ring(c: Vector2, rx: float, ry: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 41:
			var a := TAU * i / 40.0
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		draw_polyline(pts, col, 1.2, true)

# ------------------------------------------------------------------ turrets page
func _save_turrets() -> void:
	var data := {}
	if FileAccess.file_exists("user://skybound_save.json"):
		var f := FileAccess.open("user://skybound_save.json", FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if typeof(d) == TYPE_DICTIONARY:
				data = d
	data["turrets"] = {"loadout": t_loadout, "levels": t_levels, "tracks": t_tracks}
	data["coins"] = coins
	var out := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(data))

func _t_lvl(id: String) -> int:
	return int(t_levels.get(id, 1))

func _build_turrets(box: VBoxContainer) -> void:
	box.add_child(UIKit.header("BASE MOUNTS"))
	_mount_row = HBoxContainer.new()
	_mount_row.add_theme_constant_override("separation", 8)
	_mount_row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_mount_row)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var dp := UIKit.panel(10)
	dp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_t_detail = UIKit.label("", 12, Color(0.85, 0.92, 1.0))
	_t_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_t_detail.custom_minimum_size = Vector2(0, 66)
	dp.add_child(_t_detail)
	row.add_child(dp)
	_t_place = UIKit.teal_button("Place")
	_t_place.custom_minimum_size = Vector2(110, 40)
	_t_place.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_t_place.pressed.connect(_on_turret_place)
	row.add_child(_t_place)
	box.add_child(row)
	# the three upgrade tracks (Turrets.TRACKS): ATK, Rate, Range
	var tracks := HBoxContainer.new()
	tracks.add_theme_constant_override("separation", 8)
	for k in Turrets.TRACKS:
		var tb := UIKit.gold_button(Turrets.TRACK_NAMES[k], 12)
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.custom_minimum_size = Vector2(0, 58)
		var key: String = k
		tb.pressed.connect(func(): _on_track_upgrade(key))
		tracks.add_child(tb)
		_t_tracks_btn[k] = tb
	box.add_child(tracks)
	box.add_child(UIKit.header("TURRETS"))
	_turret_grid = GridContainer.new()
	_turret_grid.columns = 3
	_turret_grid.add_theme_constant_override("h_separation", 8)
	_turret_grid.add_theme_constant_override("v_separation", 8)
	box.add_child(_turret_grid)
	t_focus = t_loadout[t_mount]

func _turret_tile(id: String, subtitle: String, badge: String, size: Vector2, dim: bool) -> Button:
	var def: Dictionary = Turrets.TURRETS[id]
	var tex: Texture2D = load("res://turrets/%s_idle.png" % def.art)
	var t := UIKit.tile(def.name, subtitle, def.rarity, badge, tex, size)
	var pic: TextureRect = t.get_child(0).get_child(0)
	pic.custom_minimum_size = Vector2(0, size.y - 44.0)
	if dim:
		pic.modulate = Color(0.45, 0.45, 0.55, 0.8)
	return t

func _refresh_turrets() -> void:
	_power_label.text = "COINS %d" % coins
	for c in _mount_row.get_children():
		c.queue_free()
	for i in Turrets.MOUNTS:
		var id: String = t_loadout[i]
		var t: Button
		if not Turrets.mount_open(i, t_unlocked):
			t = UIKit.tile("Locked", "Clear stage %d" % Turrets.MOUNT_OPENS_AFTER[i], "common", "", null, Vector2(104, 112))
			t.modulate = Color(1, 1, 1, 0.55)
		elif id == "":
			t = UIKit.tile("Empty", "Mount %d" % (i + 1), "common", "", null, Vector2(104, 112))
		else:
			t = _turret_tile(id, "Mount %d" % (i + 1), "Lv.%d" % _t_lvl(id), Vector2(104, 112), false)
		if i == t_mount:
			var col: Color = UIKit.RARITY[Turrets.TURRETS[id].rarity] if id != "" else UIKit.CYAN
			t.add_theme_stylebox_override("normal", UIKit.box(Color(col, 0.25), Color.WHITE, 10, 2))
		var mi := i
		t.pressed.connect(func():
			t_mount = mi
			if t_loadout[mi] != "":
				t_focus = t_loadout[mi]
			_refresh_turrets())
		_mount_row.add_child(t)
	for c in _turret_grid.get_children():
		c.queue_free()
	for id in Turrets.TURRETS:
		var def: Dictionary = Turrets.TURRETS[id]
		var locked: bool = pilot_level < int(def.unlock)
		var sub := "Pilot Lv.%d" % def.unlock if locked else ("In development" if not def.ready else ("On mount %d" % (t_loadout.find(id) + 1) if t_loadout.has(id) else Turrets.strong_text(id)))
		var t := _turret_tile(id, sub, "Lv.%d" % _t_lvl(id), Vector2(144, 116), locked or not def.ready)
		if id == t_focus:
			t.add_theme_stylebox_override("normal", UIKit.box(Color(UIKit.RARITY[def.rarity], 0.25), Color.WHITE, 10, 2))
		var tid: String = id
		t.pressed.connect(func():
			t_focus = tid
			_refresh_turrets())
		_turret_grid.add_child(t)
	_refresh_turret_detail()

func _refresh_turret_detail() -> void:
	if t_focus == "" and not Turrets.mount_open(t_mount, t_unlocked):
		_t_detail.text = "Mount %d opens after stage %d" % [t_mount + 1, Turrets.MOUNT_OPENS_AFTER[t_mount]]
		_set_tracks_off()
		_t_place.disabled = true
		_t_place.text = "Locked"
		return
	if t_focus == "":
		_t_detail.text = "Mount %d is empty\nPick a turret, then Place" % (t_mount + 1)
		_set_tracks_off()
		_t_place.disabled = true
		_t_place.text = "Place"
		return
	var def: Dictionary = Turrets.TURRETS[t_focus]
	var tr := Turrets.one_tracks(t_tracks, t_focus)
	var lvl := Turrets.level_of(tr)
	var locked: bool = pilot_level < int(def.unlock)
	var ms := Turrets.milestones(lvl)
	# name and level, its milestone stars, then the next milestone (every 5 levels)
	var lines := "%s  Lv.%d  %s\n%s" % [def.name, lvl, "*".repeat(ms), def.desc]
	if locked:
		lines += "\nNeeds pilot Lv.%d" % def.unlock
	elif not def.ready:
		lines += "\nComing soon"
	else:
		lines += "\nNext milestone Lv.%d: ATK +5%%" % ((ms + 1) * 5)
	_t_detail.text = lines
	var usable: bool = not locked and def.ready
	for k in Turrets.TRACKS:
		var b: Button = _t_tracks_btn[k]
		var l: int = int(tr[k])
		if l >= Turrets.MAX_TRACK:
			b.text = "%s %d\nMAX" % [Turrets.TRACK_NAMES[k], l]
			b.disabled = true
			continue
		var cost := Turrets.track_cost(l)
		var needs := Turrets.track_parts(l)
		b.text = "%s %d -> %d\n%d coins%s" % [Turrets.TRACK_NAMES[k], l, l + 1, cost, ("\n" + Parts.text(needs)) if not needs.is_empty() else ""]
		b.disabled = not usable or coins < cost
	var here: bool = t_loadout[t_mount] == t_focus
	_t_place.disabled = not usable
	_t_place.text = "Remove" if here else "Place on %d" % (t_mount + 1)
	if not Turrets.mount_open(t_mount, t_unlocked):
		_t_detail.text = "Mount %d opens after stage %d\n\n" % [t_mount + 1, Turrets.MOUNT_OPENS_AFTER[t_mount]] + lines
		_t_place.disabled = true
		_t_place.text = "Locked"

func _set_tracks_off() -> void:
	for k in Turrets.TRACKS:
		var b: Button = _t_tracks_btn[k]
		b.text = Turrets.TRACK_NAMES[k]
		b.disabled = true

func _on_turret_place() -> void:
	if t_focus == "":
		return
	if t_loadout[t_mount] == t_focus:
		t_loadout[t_mount] = ""
	else:
		var old := t_loadout.find(t_focus)
		if old >= 0:
			t_loadout[old] = ""
		t_loadout[t_mount] = t_focus
	_save_turrets()
	_refresh_turrets()

func _on_track_upgrade(k: String) -> void:
	if t_focus == "":
		return
	var tr: Dictionary = Turrets.one_tracks(t_tracks, t_focus).duplicate()
	var l: int = int(tr[k])
	var cost := Turrets.track_cost(l)
	if coins < cost or l >= Turrets.MAX_TRACK:
		return
	# parts for a track level follow Parts.need on a 1-10 scale (Turrets.track_parts)
	if not await _pay_upgrade(cost, l / 2):
		return
	var was := Turrets.milestones(Turrets.level_of(tr))
	tr[k] = l + 1
	t_tracks[t_focus] = tr
	t_levels[t_focus] = Turrets.level_of(tr)
	_save_turrets()
	_refresh_turrets()
	var b: Button = _t_tracks_btn[k]
	b.pivot_offset = b.size * 0.5
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2(1.1, 1.1), 0.08)
	tw.tween_property(b, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if Turrets.milestones(Turrets.level_of(tr)) > was:
		_milestone_toast("%s reached Lv.%d: ATK +5%%" % [Turrets.TURRETS[t_focus].name, Turrets.level_of(tr)])

# a gold line that rises over the screen when something reaches a milestone
func _milestone_toast(text: String) -> void:
	var l := UIKit.label("MILESTONE!  " + text, 15, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	l.position = Vector2(0, size.y * 0.42)
	l.size = Vector2(size.x, 30)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 70.0, 1.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.6).set_delay(1.0)
	tw.chain().tween_callback(l.queue_free)

# ------------------------------------------------------------------ upgrade costs
# Every upgrade: coins, and from Lv.5 also parts (Parts.need). The button shows both,
# with what you have; short of parts, it offers crystals for the rest.
func _upgrade_text(coin_cost: int, level: int) -> String:
	var needs := Parts.need(level)
	if needs.is_empty():
		return "Upgrade
%d coins" % coin_cost
	return "Upgrade
%d coins
%s" % [coin_cost, Parts.text(needs)]

# Pays for an upgrade (coins + parts, or crystals for missing parts after asking).
# Returns true when paid; the save already has the new coins, crystals and parts.
func _pay_upgrade(coin_cost: int, level: int) -> bool:
	var data := _read()
	var needs := Parts.need(level)
	var have := Parts.read(data)
	var use_crystals := false
	if not Parts.has_all(have, needs):
		var c := Parts.crystals_for_missing(have, needs)
		var lines: Array = []
		for k in needs:
			lines.append("%s: %d / %d" % [Parts.KINDS[k].name, int(have.get(k, 0)), int(needs[k])])
		use_crystals = await _confirm("NOT ENOUGH PARTS", "
".join(lines) + "

Use %d crystals for the missing parts?
(You have %d.)" % [c, int(data.get("crystals", 0))],
			"Use %d crystals" % c, int(data.get("crystals", 0)) >= c)
		if not use_crystals:
			return false
	var why := Parts.pay(data, coin_cost, needs, use_crystals)
	if why != "":
		return false
	var out := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(data))
		out.close()   # before anything re-reads the save
	coins = int(data.get("coins", 0))
	return true

# A small glass yes/no box over the screen; returns true on yes.
signal _confirm_done(yes: bool)
func _confirm(title: String, body: String, yes_text: String, yes_ok: bool) -> bool:
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0.01, 0.04, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var p := UIKit.panel(16)
	p.custom_minimum_size = Vector2(300, 0)
	p.position = Vector2(size.x * 0.5 - 150, size.y * 0.3)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.add_child(UIKit.label(title, 16, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var b := UIKit.label(body, 13, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(b)
	var yes := UIKit.gold_button(yes_text if yes_ok else "Not enough crystals", 14)
	yes.disabled = not yes_ok
	yes.pressed.connect(func(): _confirm_done.emit(true))
	v.add_child(yes)
	var no := UIKit.ghost_button("Cancel", 13)
	no.pressed.connect(func(): _confirm_done.emit(false))
	v.add_child(no)
	p.add_child(v)
	layer.add_child(p)
	add_child(layer)
	var ans: bool = await _confirm_done
	layer.queue_free()
	return ans

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://hub.tscn")

func _fade_in_overlay() -> void:
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 1)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	var tw := create_tween()
	tw.tween_property(overlay, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func(): overlay.queue_free())

# The merge animation (Workshop): three copies of the part spiral into a swirling ring,
# a flash and a shock ring, then the new part pops out with a halo and "+1 Plasma Cell".
# Luna's merge layers (fx/merge_*.png, tools/cut_merge_fx.gd): her round merge chamber with
# its three prongs where the parts start, a charge ring and a swirl that spin up, a star
# flash, a shock wave, light rays behind the new part. The light is white, tinted to the
# result's colour. Tap to close once the result shows; closes itself at 2.4 s.
class MergeFX extends Control:
	const FX_CHAMBER := preload("res://fx/merge_chamber.png")
	const FX_SWIRL := preload("res://fx/merge_swirl.png")
	const FX_RING := preload("res://fx/merge_ring.png")
	const FX_FLASH := preload("res://fx/merge_flash.png")
	const FX_SHOCK := preload("res://fx/merge_shock.png")
	const FX_RAYS := preload("res://fx/merge_rays.png")
	const CHAMBER_PX := 340.0
	var src: Texture2D
	var dst: Texture2D
	var col := Color.WHITE
	var title := ""
	var t := 0.0
	var _glow: Control
	var _front: Control
	signal finished

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		_glow = Control.new()
		_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var add := CanvasItemMaterial.new()
		add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_glow.material = add
		_glow.draw.connect(_draw_glow)
		add_child(_glow)
		_front = Control.new()   # the parts, drawn over the light
		_front.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_front.draw.connect(_draw_front)
		add_child(_front)
		var lbl := UIKit.label(title, 22, col, HORIZONTAL_ALIGNMENT_CENTER)
		lbl.name = "Title"
		lbl.set_anchors_preset(Control.PRESET_CENTER)
		lbl.modulate.a = 0.0
		add_child(lbl)

	func _process(delta: float) -> void:
		t += delta
		var lbl: Label = get_node("Title")
		lbl.position = Vector2(size.x * 0.5 - lbl.size.x * 0.5, _center().y + CHAMBER_PX * 0.5 + 14.0)
		lbl.modulate.a = clampf((t - 1.0) / 0.25, 0.0, 1.0)
		queue_redraw()
		_glow.queue_redraw()
		_front.queue_redraw()
		if t > 2.4:
			_close()

	func _gui_input(e: InputEvent) -> void:
		if t > 1.0 and ((e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed)):
			_close()

	func _close() -> void:
		if is_queued_for_deletion():
			return
		finished.emit()
		queue_free()

	func _center() -> Vector2:
		return Vector2(size.x * 0.5, size.y * 0.42)

	func _icon(tex: Texture2D, c: Vector2, px: float, a: float, rot: float = 0.0) -> void:
		if tex == null or px <= 0.5:
			return
		var s := px / maxf(tex.get_width(), tex.get_height())
		_front.draw_set_transform(c, rot, Vector2(s, s))
		_front.draw_texture(tex, -tex.get_size() * 0.5, Color(1, 1, 1, a))
		_front.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# the dim behind everything, and the chamber (solid metal) under the light
	func _draw() -> void:
		var a := clampf(t / 0.25, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.02, 0.06, 0.8 * a))
		var c := _center()
		var s := CHAMBER_PX * (0.9 + 0.1 * a) / FX_CHAMBER.get_width()
		draw_set_transform(c, 0.0, Vector2(s, s))
		draw_texture(FX_CHAMBER, -FX_CHAMBER.get_size() * 0.5, Color(1, 1, 1, a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# front layer: the three parts flying in, then the result
	func _draw_front() -> void:
		var c := _center()
		if t < 0.85:
			var k := clampf(t / 0.8, 0.0, 1.0)
			var ease_in := k * k * k
			for i in 3:
				var a := -PI * 0.5 + i * TAU / 3.0 + ease_in * TAU * 0.9
				var r := 100.0 * (1.0 - ease_in)   # from the chamber's prongs to the middle
				_icon(src, c + Vector2(cos(a), sin(a)) * r, 64.0 * (1.0 - 0.45 * ease_in), 1.0 - 0.6 * maxf(0.0, k - 0.8) / 0.2, ease_in * 2.0)
		if t > 0.85:
			var p := clampf((t - 0.85) / 0.3, 0.0, 1.0)
			# overshoot pop (ease out back), then a slow bob
			var pop := 1.0 + 2.7 * pow(p - 1.0, 3) + 1.7 * pow(p - 1.0, 2)
			_icon(dst, c + Vector2(0, sin(t * 2.4) * 4.0 * p), 118.0 * pop, 1.0)

	# light layer (additive): charge ring and swirl spinning up, the flash, the shock wave,
	# then the rays behind the new part
	func _draw_glow() -> void:
		var c := _center()
		var k := clampf(t / 0.8, 0.0, 1.0)
		var fade := 1.0 - clampf((t - 0.8) / 0.3, 0.0, 1.0)
		if t < 1.1:
			# the ring tightens and spins faster as the parts close in
			_glow_tex(FX_RING, c, 300.0 - 70.0 * k * k, col * Color(1, 1, 1, minf(t * 3.0, 1.0) * fade), t * (1.0 + 4.0 * k))
			_glow_tex(FX_SWIRL, c, 70.0 + 200.0 * k, col * Color(1, 1, 1, 0.85 * minf(k * 1.6, 1.0) * fade), -t * (3.0 + 9.0 * k * k))
		if t > 0.8 and t < 1.25:
			var f := (t - 0.8) / 0.45
			_glow_tex(FX_FLASH, c, 120.0 + 380.0 * f, Color(1, 1, 1, 1.0 - f * f), f * 0.3)
		if t > 0.8 and t < 1.55:
			var n := (t - 0.8) / 0.75
			_glow_tex(FX_SHOCK, c, 90.0 + 470.0 * n, col * Color(1, 1, 1, 1.0 - n), 0.0)
		if t > 0.9:
			var h := clampf((t - 0.9) / 0.3, 0.0, 1.0)
			_glow_tex(FX_RAYS, c, 330.0 + sin(t * 3.0) * 16.0, col * Color(1, 1, 1, 0.6 * h), t * 0.35)

	func _glow_tex(tex: Texture2D, c: Vector2, px: float, mod: Color, rot: float) -> void:
		var s := px / maxf(tex.get_width(), tex.get_height())
		_glow.draw_set_transform(c, rot, Vector2(s, s))
		_glow.draw_texture(tex, -tex.get_size() * 0.5, mod)
		_glow.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
