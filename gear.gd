extends Control
# Gear screen. Pilot page: the pilot (the live rig), the six gear slots (Weapon, Helmet,
# Chest, Gauntlets, Boots, Jetpack), the selected piece's stats with Upgrade (spends
# coins), the three pieces you can wear in that slot (Ion / Scavenger / Void sets),
# and the set bonuses you have. Rules and numbers: gear_data.gd. Turrets page: mounts
# and turret upgrades. Saved in user://skybound_save.json ("gear", "turrets").
# dev139: a piece's RARITY caps its level; the Workshop's Gear tab is the inventory of
# copies (filter, merge by hand, Quick Merge); LOADOUTS (Loadouts) switch whole kits.

var gear := {}             # GearData.read(save): {equipped, levels, copies, recent}
var _loadout_row: HBoxContainer
var _tabs_row: HBoxContainer       # Pilot / Turrets / Drone / Workshop (red dot on Workshop when a merge waits)
var _ws_tabs_row: HBoxContainer    # Parts / Gear
var _ws_merge_btn: Button          # the first parts Merge button (tips)
var _quick_btn: Button             # Quick Merge (tips)
var _wallet_box: HBoxContainer
var _ws_tab := 0           # Workshop sub-tab: 0 Parts, 1 Gear, 2 Craft
var _ws_craft_box: VBoxContainer
var _craft_el := "ion"     # the element picked for the essence recipe (Craft tab)
var _ws_parts_box: VBoxContainer
var _ws_gear_box: VBoxContainer
var _inv_filter := {"rarity": "", "slot": "", "set": "", "sort": "newest", "show": ""}   # "" = any; show "" = useful stacks only, "all" = everything
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
var _start_page := 0
var drone := {}            # DroneData.read(save)
var _plat                    # HeroStand (the hero floats over it; glow = his tier)
var _showcase                # PilotShowcase (swivel)
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
var t_owned: Array = []    # turrets bought (Turrets.owned, dev172)
var t_stars := {}          # turret id -> star 1-10 (Gates, DESIGN-stars.md)
var _t_star: Button
var t_focus := ""          # turret shown in the detail panel
var _mount_row: HBoxContainer
var _turret_grid: GridContainer
var _t_detail: Label
var _t_place: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	MenuBackdrop.add_to(self)   # the living planet wallpaper behind the page
	# a Quests "Go" button can ask for a tab (0 Pilot, 1 Turrets, 2 Drone, 3 Workshop)
	if get_tree().root.has_meta("gear_page"):
		_start_page = int(get_tree().root.get_meta("gear_page"))
		get_tree().root.remove_meta("gear_page")
	if get_tree().root.has_meta("gear_ws_tab"):   # Workshop sub-tab (0 Parts, 1 Gear)
		_ws_tab = int(get_tree().root.get_meta("gear_ws_tab"))
		get_tree().root.remove_meta("gear_ws_tab")
	_load()
	_start_page = UIKit.tab_shown([0, 1, 2, 3], _start_page, _hidden_pages())   # a page not reached yet falls back to Pilot
	_build()
	_select(selected_slot)
	if _start_page != 0:
		_show_page(_start_page)
	call_deferred("_page_tips", _start_page)
	_fade_in_overlay()

func _read() -> Dictionary:
	if FileAccess.file_exists("user://skybound_save.json"):
		var f := FileAccess.open("user://skybound_save.json", FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if typeof(d) == TYPE_DICTIONARY:
				return d
				DevTools.on = bool(d.get("dev_mode", false))
	return {}

func _load() -> void:
	var data := _read()
	var t := Turrets.read(data)
	t_loadout = t.loadout
	t_levels = t.levels
	t_tracks = t.tracks
	t_owned = t.owned
	t_stars = t.get("stars", {})
	coins = int(data.get("coins", 0))
	pilot_level = Turrets.pilot_level(int(data.get("pilot_xp", 0)))
	t_unlocked = int(data.get("stage_unlocked", 1))
	gear = GearData.read(data)
	hero = Heroes.read(data)   # heroes (dev172)
	drone = DroneData.read(data)
	PilotRig.set_gear(data)

func _save() -> void:
	var data := _read()
	data["gear"] = GearData.write(gear)
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
	UIKit.smooth_scroll(scroll)   # a drag that starts on a card or a button still scrolls the page (Rudy, dev271: the Base page would not scroll)
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
	top.add_child(UIKit.screen_title("HEROES"))
	var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	_power_label = UIKit.label("", 13, UIKit.GOLD)
	top.add_child(_power_label)
	_wallet_box = HBoxContainer.new()
	top.add_child(_wallet_box)
	col.add_child(top)
	# Pilot / Turrets switch
	# pages the player has not reached yet are not built (Unlocks: turrets, drone, workshop)
	_tabs_row = UIKit.tabs(["Hero", "Base", "Drone", "Workshop"], _show_page, _start_page, [], _hidden_pages(), [UIKit.ic("tab_hero"), UIKit.ic("ic_base"), UIKit.ic("tab_drone"), UIKit.ic("tab_workshop")])
	col.add_child(_tabs_row)
	_paint_dots()
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
	# loadouts (Rudy): three saved kits, one tap to switch; tap the one in use to rename / overwrite
	_loadout_row = HBoxContainer.new()
	_loadout_row.add_theme_constant_override("separation", 6)
	col.add_child(_loadout_row)
	_loadout_row.visible = Unlocks.open(_read(), "loadouts")   # kits appear once a second set is in reach (Unlocks)
	_paint_loadouts()
	if UIKit.CLEAN:
		_loadout_row.visible = false   # one Loadout button beside the hero instead (Rudy, dev209 playtest)
	# the pilot (live rig) on his platform, three slots on each side (Luna's mockup)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0, 350)   # the hero big, front and centre (Rudy)
	col.add_child(stage)
	var plat := HeroStand.new()   # the glowing hover disc (Rudy: no base look under the heroes)
	plat.set_anchors_preset(Control.PRESET_FULL_RECT)
	plat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(plat)
	_plat = plat
	var hero := PilotShowcase.new()
	hero.plat = plat
	hero.set_anchors_preset(Control.PRESET_FULL_RECT)
	# (the showcase takes touches: drag to swivel him, dev172)
	stage.add_child(hero)
	_showcase = hero
	for i in 1:   # heroes (dev172): the weapon is the only gear slot left; armour is the hero himself
		var s: String = GearData.SLOTS[i]
		var b := Button.new()
		b.size = Vector2(SLOT_PX, SLOT_PX)
		var right := i >= 3
		b.position = Vector2(-SLOT_PX if right else 0.0, (i % 3) * (SLOT_PX + 12.0) + 6.0)
		for st in ["normal", "hover", "pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		var slot: String = s
		b.pressed.connect(func(): _select(slot); _weapons_screen())   # the tile opens the WEAPONS screen (Rudy, dev186)
		b.draw.connect(func(): _draw_slot(b, slot))
		stage.add_child(b)
		_slot_tiles[s] = b
	stage.resized.connect(func():
		for i in 1:
			var tb: Button = _slot_tiles[GearData.SLOTS[i]]
			tb.position.x = stage.size.x - SLOT_PX if i >= 3 else 0.0)
	plat.tiles = {} if UIKit.CLEAN else _slot_tiles   # (clean: no line from the weapon tile to the hero)
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
	# the pilot talent map (Talents, dev197): a path of permanent bonuses for every hero
	_talent_btn = UIKit.ghost_button("TALENTS", 11)
	_talent_btn.custom_minimum_size = Vector2(76, 26)
	_talent_btn.pressed.connect(_talents_screen)
	stage.add_child(_talent_btn)
	stage.resized.connect(func(): _talent_btn.position = Vector2(stage.size.x - SLOT_PX - 156.0, 4.0))
	if UIKit.CLEAN:
		# the clean page (mock-up "Round 2 · Clean"): Talents and Stats as squares stacked on the right,
		# the Loadout square under the weapon on the left (tap = the next kit, hold = rename / save)
		stats_btn.visible = false
		_talent_btn.visible = false
		var tal := _side_square("Talents", "talents")
		tal.pressed.connect(_talents_screen)
		stage.add_child(tal)
		_talent_btn = tal
		var sts := _side_square("Stats", "stats")
		sts.pressed.connect(_show_stats)
		stage.add_child(sts)
		_kit_btn = _side_square("Loadout", "loadout")
		_kit_btn.visible = Unlocks.open(_read(), "loadouts")
		var held := [false]
		_kit_btn.button_down.connect(func():
			held[0] = false
			get_tree().create_timer(0.55).timeout.connect(func():
				if is_instance_valid(_kit_btn) and _kit_btn.button_pressed:
					held[0] = true
					_loadout_box(Loadouts.active(_read()))))
		_kit_btn.pressed.connect(func():
			if held[0]:
				return
			_on_loadout((Loadouts.active(_read()) + 1) % Loadouts.SLOTS))
		stage.add_child(_kit_btn)
		# the wingmate (Heroes.wing): a second owned hero who lends half his passive and fires his ability by himself; tap = the next one, then none
		_wing_btn = _side_square("Wingmate", "wing")
		_wing_btn.pressed.connect(_on_wing)
		stage.add_child(_wing_btn)
		# the ability and its three upgrades (Heroes.ABILITY_UPS): a sheet
		_abl_btn = _side_square("Ability", "ability")
		_abl_btn.pressed.connect(func(): _ability_sheet())
		stage.add_child(_abl_btn)
		stage.resized.connect(func():
			tal.position = Vector2(stage.size.x - 56.0, 6.0)
			sts.position = Vector2(stage.size.x - 56.0, 92.0)
			_kit_btn.position = Vector2(0.0, SLOT_PX + 30.0)
			_abl_btn.position = Vector2(stage.size.x - 56.0, 178.0)
			_wing_btn.position = Vector2(0.0, SLOT_PX + 30.0 + 84.0))
	_paint_suit()
	# the hero (heroes, dev172): name + element, passive and level, LEVEL UP, stars + EVOLVE
	_hero_panel = UIKit.panel(10)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 4)
	_hero_name = UIKit.label("", 16, Color.WHITE)
	if UIKit.CLEAN:
		# centred: the name big, a tag row (element, stars, grade), the numbers as chips, the level bar
		hv.add_theme_constant_override("separation", 8)
		_hero_name = UIKit.title("", 30, UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		_hero_tags = HBoxContainer.new()
		_hero_tags.alignment = BoxContainer.ALIGNMENT_CENTER
		_hero_tags.add_theme_constant_override("separation", 8)
		_hero_chips = HBoxContainer.new()
		_hero_chips.alignment = BoxContainer.ALIGNMENT_CENTER
		_hero_chips.add_theme_constant_override("separation", 10)
		_hero_bar = HBoxContainer.new()
		_hero_bar.add_theme_constant_override("separation", 10)
	hv.add_child(_hero_name)
	if UIKit.CLEAN:
		hv.add_child(_hero_tags)
		hv.add_child(_hero_chips)
		hv.add_child(_hero_bar)
	_hero_line = UIKit.label("", 12, Color(0.85, 0.92, 1.0))
	_hero_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hv.add_child(_hero_line)
	var hrow := HBoxContainer.new()
	hrow.add_theme_constant_override("separation", 6)
	hrow.alignment = BoxContainer.ALIGNMENT_END
	var srow := UIKit.iconed(UIKit.ic("mat_shard", "ic_shard"), "", 13, UIKit.GOLD, 18.0)   # Luna's hero shard (icons 3), the old badge until it lands
	_stars_l = srow.get_child(srow.get_child_count() - 1)
	_stars_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # never wider than the phone (the line grew with materials)
	_stars_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_child(srow)   # tier + shards on its own line; the buttons fit the phone width under it
	_unlock_btn = UIKit.gold_button("Unlock", 13)
	_unlock_btn.custom_minimum_size = Vector2(104, 42)
	_unlock_btn.pressed.connect(func(): _on_unlock(false))
	_crystal_btn = UIKit.teal_button("", 13)
	_crystal_btn.custom_minimum_size = Vector2(104, 42)
	_crystal_btn.pressed.connect(func(): _on_unlock(true))
	_evolve_btn = UIKit.teal_button("Evolve", 13)
	_evolve_btn.custom_minimum_size = Vector2(80, 42)
	_evolve_btn.pressed.connect(_on_evolve)
	hrow.add_child(_evolve_btn)
	_level_btn = UIKit.gold_button("Level up", 13)
	_level_btn.custom_minimum_size = Vector2(104, 42)
	_level_btn.pressed.connect(_on_level_btn)   # clean: opens the LEVEL UP sheet
	_def_btn = UIKit.teal_button("", 13)
	_def_btn.visible = false   # (one Level up track since dev186: ATK, HP and DEF rise together)
	_def_btn.custom_minimum_size = Vector2(92, 42)
	_def_btn.pressed.connect(_on_def_up)
	hrow.add_child(_def_btn)
	hrow.add_child(_level_btn)
	hrow.add_child(_crystal_btn)
	hrow.add_child(_unlock_btn)
	hv.add_child(hrow)
	if UIKit.CLEAN:
		# one big gold LEVEL UP with its cost; Evolve beside it; the shard line small under them
		hv.move_child(srow, hv.get_child_count() - 1)
		_stars_l.add_theme_font_size_override("font_size", 11)
		_stars_l.add_theme_color_override("font_color", UIKit.SOFT)
		_level_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_level_btn.custom_minimum_size = Vector2(0, 56)
		_level_btn.add_theme_font_size_override("font_size", 20)
		_level_btn.icon = UIKit.ic("ic_coin", "ui_coin")
		_level_btn.add_theme_constant_override("icon_max_width", 22)
		_level_btn.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_evolve_btn.custom_minimum_size = Vector2(96, 56)
		_evolve_btn.visible = false   # ASCEND lives in the LEVEL UP sheet
		srow.visible = false          # ... and so do the shards and the next perk
		hrow.alignment = BoxContainer.ALIGNMENT_CENTER
	_hero_panel.add_child(hv)
	col.add_child(_hero_panel)
	# the roster under him (Rudy's layout): grade rows, scrolling sideways, locked ones dimmed
	if not UIKit.CLEAN:
		col.add_child(UIKit.header("HEROES"))
	_roster_row = VBoxContainer.new()
	_roster_row.add_theme_constant_override("separation", 4)
	col.add_child(_roster_row)
	_paint_roster()
	_paint_hero()
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
	up_row.visible = false   # the weapon's details and Upgrade live on the WEAPONS screen (Rudy, dev186)
	# the six pieces for this slot (one per set)
	# (the CHOOSE grid left the page in dev186: the weapon tile opens the WEAPONS screen)
	_bag_grid = GridContainer.new()
	_bag_grid.columns = 3
	_bag_grid.add_theme_constant_override("h_separation", 8)
	_bag_grid.add_theme_constant_override("v_separation", 8)
	_bag_grid.visible = false
	# set bonuses you have, last
	var bp := UIKit.panel(10)
	_bonus = UIKit.label("", 12, Color(0.85, 0.92, 1.0))
	_bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bp.add_child(_bonus)
	col.add_child(bp)
	bp.visible = not UIKit.CLEAN   # (the old gear-set bonuses: not on the clean page)

# The suit (PilotRig.suit_for): Rookie, or the Commander armour once the Area 1 boss is beaten.
func _paint_suit() -> void:
	_suit_btn.visible = _hero_id() == Heroes.DEFAULT and not UIKit.CLEAN   # only Rook has two suits (heroes, dev172); the clean page drops the switch (Rudy)
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
	# the level in the piece's rarity colour (Common grey ... Legendary gold)
	v.add_child(UIKit.label("Lv.%d" % _lvl(id), 11, GearData.rarity_color(GearData.rarity(gear, id)), HORIZONTAL_ALIGNMENT_CENTER))
	b.add_child(v)

# the tile itself: a glass square, lit in its set's colour when selected
func _draw_slot(b: Button, s: String) -> void:
	var on := s == selected_slot
	var col: Color = UIKit.RARITY[GearData.ITEMS[gear.equipped[s]].set]
	var edge := Color(col, 0.95) if on else Color(col, 0.45)
	var fill := Color(col.r * 0.2, col.g * 0.2, col.b * 0.28, 0.8) if on else Glass.FILL
	Glass.panel(b, Glass.box(Rect2(Vector2.ZERO, b.size), 12.0), 1.0, edge, fill)
	UIKit.draw_depth(b, b.size, col, true, 0.38)   # the same lift as every card (dev150)

func _fill_bag() -> void:
	for c in _bag_grid.get_children():
		c.queue_free()
	for set_id in GearData.SETS:
		var id: String = "%s_%s" % [set_id, selected_slot.to_lower()]
		var info: Dictionary = GearData.ITEMS[id]
		var open := GearData.set_unlocked(set_id, t_unlocked) or GearData.owned(gear, id)
		var is_on: bool = gear.equipped[selected_slot] == id
		var rn := GearData.rarity_name(GearData.rarity(gear, id))
		var sub := ("Lv.%d · %s" % [_lvl(id), rn]) if open else "Stage %d" % (int(GearData.SETS[set_id].unlock_stage) - 1)
		var t := UIKit.tile(info.name, sub, set_id, GearData.SETS[set_id].name, _pic(id) if open else load("res://icons/ui_padlock.png"), Vector2(108, 88))
		if not open:
			t.tooltip_text = "Clear stage %d" % (int(GearData.SETS[set_id].unlock_stage) - 1)
		if not open:
			t.modulate = Color(0.55, 0.55, 0.65, 0.8)
		var item: String = id
		t.pressed.connect(func():
			if open:
				_equip(item))
		if is_on:
			UIKit.equipped_badge(t, UIKit.RARITY[set_id])   # the E badge (Rudy)
		_bag_grid.add_child(t)
	UIKit.reveal(_bag_grid, 0.03, 10.0)

# ------------------------------------------------------------------ actions

func _select(slot: String) -> void:
	selected_slot = slot
	for s in ["Weapon"]:
		_paint_slot(s)
	_fill_bag()
	var id: String = gear.equipped[slot]
	var info: Dictionary = GearData.ITEMS[id]
	var lv := _lvl(id)
	var st: Dictionary = GearData.SLOT_STAT[slot]
	var set_info: Dictionary = GearData.SETS[info.set]
	# short and plain (Rudy): name, level over its rarity's cap, the main stat with its next
	# level, the set's extra
	var rar := GearData.rarity(gear, id)
	var cap := GearData.level_cap(rar)   # the rarity cap: copies merged in the Workshop are the weapon stars (DESIGN-stars.md)
	var next_txt := ("  ->  " + _stat_text(slot, lv + 1)) if lv < cap else "  (cap)"
	_detail.text = "%s  Lv.%d / %d  ·  %s\n%s %s%s\n%s" % [info.name, lv, cap, GearData.rarity_name(rar), st.text, _stat_text(slot, lv), next_txt, set_info.minor]
	# its milestone (every 5 levels): what it gives, and how many it has reached
	var gms: Dictionary = GearData.MILESTONE[slot]
	var got := GearData.milestones(lv)
	if got >= GearData.max_milestones():
		_detail.text += "\n%s  x%d (max)" % [gms.text, got]
	else:
		_detail.text += "\n%s  %s" % [gms.text, ("x%d, next Lv.%d" % [got, (got + 1) * GearData.MILESTONE_EVERY]) if got > 0 else "at Lv.%d" % GearData.MILESTONE_EVERY]
	if slot == "Weapon":
		_detail.text += "\n" + GearData.WEAPON_TEXT[set_info.weapon]
	var cost := GearData.upgrade_cost(lv)
	_upgrade_btn.disabled = lv >= cap or coins < cost
	if lv >= GearData.MAX_LEVEL:
		_upgrade_btn.text = "MAX"
	elif lv >= cap:
		_upgrade_btn.text = "Lv.%d cap\nMerge copies\nin Workshop" % cap   # a higher rarity raises it
	else:
		_upgrade_btn.text = _upgrade_text(cost, lv, Materials.weapon_need(lv, String(GearData.ITEMS[gear.equipped[selected_slot]].set)))
	if _wing_btn:
		_wing_btn.visible = not Heroes.wing_choices(hero).is_empty()
		_wing_btn.queue_redraw()
	if _abl_btn:
		_abl_btn.visible = Unlocks.open(_read(), "ability")
		_abl_btn.queue_redraw()
		UIKit.dot(_abl_btn, Heroes.owned(hero, _view_id) and Heroes.ability_ups(hero, _view_id) < 3 and Heroes.why_not_ability_up(hero, _view_id) == "")
	_power_label.text = "POWER %d" % Heroes.power(_read())
	if _talent_btn:
		UIKit.dot(_talent_btn, Talents.affordable(_read()))   # a node is ready to buy (dev197)
	_paint_wallet()
	# the hero's milestones so far (every 5 levels), in place of the old set bonuses
	var hid := _hero_id()
	var hlv := Heroes.level(hero, hid)
	var hgot: Array = []
	for m in Heroes.milestones(hlv):
		hgot.append(String(Heroes.MILESTONES[m % Heroes.MILESTONES.size()].text))
	_bonus.text = "%s MILESTONES\n%s" % [String(Heroes.ROSTER[hid].name).to_upper(), ", ".join(hgot) if not hgot.is_empty() else "First at Lv.%d: %s" % [Heroes.MILESTONE_EVERY, Heroes.MILESTONES[0].text]]

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
	if lv >= GearData.cap_of(gear, id) or coins < cost:
		return
	Sfx.play("upgrade")
	if not await _pay_upgrade(cost, lv, Materials.weapon_need(lv, String(GearData.ITEMS[id].set))):
		return
	gear.levels[id] = lv + 1
	if GearData.milestones(lv + 1) > GearData.milestones(lv):
		_milestone_toast("%s reached Lv.%d: %s" % [GearData.ITEMS[id].name, lv + 1, GearData.MILESTONE[selected_slot].text])
	_save()
	Progress.bump("upgrades")
	_select(selected_slot)
	if _plat:
		_plat.glow_col = UIKit.RARITY[GearData.ITEMS[id].set] if _plat.glow <= 0.0 else _plat.glow_col
		_plat.flash()
	var b: Button = _slot_tiles[selected_slot]
	b.pivot_offset = b.size * 0.5
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2(1.12, 1.12), 0.1)
	tw.tween_property(b, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Gear pages the player has not reached (Unlocks): 1 Turrets, 2 Drone, 3 Workshop
func _hidden_pages() -> Array:
	var d := _read()
	var out: Array = []
	for pair in [[1, "turrets"], [2, "drone"], [3, "workshop"]]:
		if not Unlocks.open(d, pair[1]):
			out.append(pair[0])
	return out

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
	call_deferred("_page_tips", i)


# ------------------------------------------------------------------ stats panel
# Your numbers right now (Rudy): the pilot's damage, crits and fire rate; the base's shield,
# hull and damage reduction; each turret on the base. Power cards in a run add to these.
const BATTLE := preload("res://battle.gd")

func _show_stats() -> void:
	var data := _read()
	var gs := Heroes.stats(data)
	var w: Dictionary = BATTLE.WEAPONS[gs.weapon]
	var hit: float = float(w.damage) * float(gs.damage) * (1.0 + float(gs.dmg_boost))
	var per_s: float = float(w.projectiles) * float(gs.fire_rate) / float(w.interval)
	var crit_avg: float = 1.0 + float(gs.crit_rate) * (float(gs.crit_dmg) - 1.0)
	var layer := ColorRect.new()
	layer.color = Color(0, 0.01, 0.04, 0.78)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var p := UIKit.popup_panel()
	var pw := minf(size.x - 32.0, 420.0)
	p.custom_minimum_size = Vector2(pw, 0)
	p.position = Vector2((size.x - pw) * 0.5, 70.0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.add_child(UIKit.popup_title("STATS"))
	v.add_child(UIKit.header(String(Heroes.ROSTER[_hero_id()].name).to_upper()))
	_stat_rows(v, [
		["Damage per hit", "%.2f" % hit],
		["Shots per second", "%.1f" % per_s],
		["Damage per second", "%.1f" % (hit * per_s * crit_avg)],
		["Crit rate", "%d%%" % roundi(float(gs.crit_rate) * 100.0)],
		["Crit damage", "x%.2f" % float(gs.crit_dmg)],
		["Damage boost", "+%d%%" % roundi(float(gs.dmg_boost) * 100.0)],
		["HP", "%d" % roundi(float(gs.hp))],
		["Defence", "-%d%% damage taken" % roundi(float(gs.def) * 100.0)],
	])
	v.add_child(UIKit.header("BASE"))
	_stat_rows(v, [
		["Shield", "%d" % roundi(BATTLE.BASE_SHIELD * float(gs.shield) * float(gs.fortress))],
		["Hull (fortress HP)", "%d" % roundi(BATTLE.BASE_HULL * float(gs.fortress))],
		["Damage taken", "-%d%%" % roundi(float(gs.base_dr) * 100.0)],
	])
	# the buildings on the base (Base): what each one is giving
	v.add_child(UIKit.header("Buildings"))
	var bsd := Base.read(data)
	var rows: Array = []
	for bid in Base.stats(data).on:
		rows.append(["%s Lv.%d" % [String(Base.BUILDINGS[bid].name), Base.level(bsd, String(bid))], Base.text(String(bid), Base.level(bsd, String(bid)))])
	if rows.is_empty():
		rows.append(["No buildings on the base", "-"])
	_stat_rows(v, rows)
	v.add_child(UIKit.label("Power cards in a run add to these", 11, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var close := UIKit.ghost_button("Close", 14)
	close.custom_minimum_size = Vector2(0, 40)
	close.pressed.connect(layer.queue_free)
	v.add_child(close)
	p.add_child(v)
	layer.add_child(p)

# label on the left, value on the right
# Luna'"'"'s stat icons on the STATS panel (dev182)
const STAT_ICON := {"Damage per hit": "st_atk", "Shots per second": "st_rate", "Damage per second": "st_atk", "Crit rate": "st_crit", "Crit damage": "st_crit", "Damage boost": "st_atk", "HP": "st_hp", "Defence": "st_def", "Shield": "st_def", "Hull (fortress HP)": "ic_base", "Damage taken": "st_def"}
func _stat_rows(box: VBoxContainer, rows: Array) -> void:
	for r in rows:
		var h := HBoxContainer.new()
		var l: Control = UIKit.iconed(UIKit.ic(String(STAT_ICON.get(r[0], ""))), r[0], 13, Color(0.82, 0.9, 1.0)) if STAT_ICON.has(r[0]) else UIKit.label(r[0], 13, Color(0.82, 0.9, 1.0))
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		h.add_child(UIKit.label(r[1], 13, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT))
		box.add_child(h)

# ------------------------------------------------------------------ workshop page
# Two sub-tabs (Rudy: sub-tabs, not long scrolls). PARTS: 3 of a part -> 1 of the next
# (Parts.MERGE), one card per merge with Merge (one) and All. GEAR: the inventory of gear
# copies, a Filter, Quick Merge (Common and Uncommon) and merging by hand (any rarity).
func _refresh_workshop(pop: String = "") -> void:
	for c in _workshop_box.get_children():
		c.queue_free()
	var on_tab := func(i: int):
		_ws_tab = i
		_ws_parts_box.visible = i == 0
		_ws_gear_box.visible = i == 1
		_ws_craft_box.visible = i == 2
		if i == 1:
			_refresh_ws_gear()
		elif i == 2:
			_refresh_ws_craft()
	_ws_tabs_row = UIKit.sub_tabs(["Parts", "Gear", "Craft"], _ws_tab, func(i: int):   # sub-tabs in the shared dark-pill style
		_ws_tab = i
		_refresh_workshop())
	_workshop_box.add_child(_ws_tabs_row)
	_paint_dots()
	_ws_parts_box = VBoxContainer.new()
	_ws_parts_box.add_theme_constant_override("separation", 10)
	_ws_parts_box.visible = _ws_tab == 0
	_workshop_box.add_child(_ws_parts_box)
	_ws_gear_box = VBoxContainer.new()
	_ws_gear_box.add_theme_constant_override("separation", 10)
	_ws_gear_box.visible = _ws_tab == 1
	_workshop_box.add_child(_ws_gear_box)
	_ws_craft_box = VBoxContainer.new()
	_ws_craft_box.add_theme_constant_override("separation", 10)
	_ws_craft_box.visible = _ws_tab == 2
	_workshop_box.add_child(_ws_craft_box)
	_refresh_ws_parts(pop)
	if _ws_tab == 1:
		_refresh_ws_gear()
	elif _ws_tab == 2:
		_refresh_ws_craft()

func _refresh_ws_parts(pop: String = "") -> void:
	for c in _ws_parts_box.get_children():
		c.queue_free()
	_ws_icons = {}
	var have := Parts.read(_read())
	_ws_parts_box.add_child(UIKit.header("Your parts"))
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
	_ws_parts_box.add_child(row)
	_ws_parts_box.add_child(UIKit.header("Merge 3 into 1"))
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
		if k == "alloy":
			_ws_merge_btn = one
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
		_ws_parts_box.add_child(p)
	if not UIKit.CLEAN:
		_ws_parts_box.add_child(UIKit.label("Gear copies: the Gear tab  ·  turret modules: coming soon", 12, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	if pop != "" and _ws_icons.has(pop):
		var tr: TextureRect = _ws_icons[pop]
		await get_tree().process_frame
		tr.pivot_offset = tr.size * 0.5
		var tw := tr.create_tween()
		tw.tween_property(tr, "scale", Vector2(1.35, 1.35), 0.1)
		tw.tween_property(tr, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _part_icon(kind: String, px: float) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = Materials.icon(kind) if Materials.is_material(kind) else Parts.icon(kind)
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
	Sfx.play("merge")
	var out := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(data))
		out.close()
	Progress.bump("merges", made)
	var to: String = Parts.MERGE[kind]
	var fx := MergeFX.new()
	fx.src = Parts.icon(kind)
	fx.dst = Parts.icon(to)
	fx.col = Parts.KINDS[to].color
	fx.title = "+%d %s%s" % [made, Parts.KINDS[to].name, "s" if made > 1 else ""]
	add_child(fx)
	await fx.finished
	_refresh_workshop(to)

# ---- gear inventory (Workshop > Gear) ----
# Every stack of copies you hold (one tile per piece and rarity, "x3"), filtered and
# sorted (Rudy: by rarity, slot, set, newest). Tap a stack to merge 3 -> 1 of the next
# rarity by hand; QUICK MERGE does every Common and Uncommon stack at once.
const INV_SORTS := ["newest", "rarity", "set"]
const INV_SORT_NAMES := {"newest": "Newest", "rarity": "Rarity", "set": "Set"}

func _inv_stacks() -> Array:
	var out: Array = []
	for id in gear.copies:
		var info: Dictionary = GearData.ITEMS[id]
		if String(info.slot) != "Weapon":
			continue   # heroes (dev172): only weapons are gear now; old armour copies became shards
		if _inv_filter.slot != "" and info.slot != _inv_filter.slot:
			continue
		if _inv_filter.set != "" and info.set != _inv_filter.set:
			continue
		for r in gear.copies[id]:
			if _inv_filter.rarity != "" and r != _inv_filter.rarity:
				continue
			# the lone Common base copy of every owned piece is noise (dev152): hidden unless asked
			if _inv_filter.show == "" and _inv_filter.rarity == "" and r == "common" and int(gear.copies[id][r]) == 1 and GearData.rarity(gear, id) == "common":
				continue
			out.append({"id": id, "rarity": r, "n": int(gear.copies[id][r]), "recent": gear.recent.rfind(id)})
	match String(_inv_filter.sort):
		"newest":
			out.sort_custom(func(a, b): return a.recent > b.recent if a.recent != b.recent else GearData.rarity_index(a.rarity) > GearData.rarity_index(b.rarity))
		"rarity":
			out.sort_custom(func(a, b): return GearData.rarity_index(a.rarity) > GearData.rarity_index(b.rarity) if a.rarity != b.rarity else a.id < b.id)
		"set":
			out.sort_custom(func(a, b):
				var sa := GearData.SET_ORDER.find(GearData.ITEMS[a.id].set)
				var sb := GearData.SET_ORDER.find(GearData.ITEMS[b.id].set)
				return sa < sb if sa != sb else (GearData.SLOTS.find(GearData.ITEMS[a.id].slot) < GearData.SLOTS.find(GearData.ITEMS[b.id].slot) if a.id != b.id else GearData.rarity_index(a.rarity) > GearData.rarity_index(b.rarity)))
	return out

func _filter_text() -> String:
	var bits: Array = []
	if _inv_filter.rarity != "":
		bits.append(GearData.rarity_name(_inv_filter.rarity))
	if _inv_filter.slot != "":
		bits.append(_inv_filter.slot)
	if _inv_filter.set != "":
		bits.append(GearData.SETS[_inv_filter.set].name)
	return ("All" if bits.is_empty() else " · ".join(bits)) + "  ·  " + INV_SORT_NAMES[_inv_filter.sort] + ("" if _inv_filter.show == "all" else "  ·  lone Commons hidden")

func _refresh_ws_gear() -> void:
	for c in _ws_gear_box.get_children():
		c.queue_free()
	if UIKit.CLEAN:
		_refresh_ws_gear_clean()
		return
	gear = GearData.read(_read())
	var total := 0
	for id in gear.copies:
		total += GearData.total_copies(gear, id)
	# Filter and Quick Merge on one row, the filter in words under it
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var fb := UIKit.ghost_button("Filter", 13)
	fb.custom_minimum_size = Vector2(90, 40)
	fb.pressed.connect(_filter_box)
	row.add_child(fb)
	var ft := UIKit.label(_filter_text(), 11, UIKit.MUTED)
	ft.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ft.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(ft)
	var qn := GearData.quick_merge_count(gear)
	var qb := UIKit.gold_button("Quick Merge" + ((" (%d)" % qn) if qn > 0 else ""), 13)
	_quick_btn = qb
	qb.custom_minimum_size = Vector2(118, 40)
	qb.disabled = qn <= 0
	qb.pressed.connect(_quick_merge)
	row.add_child(qb)
	_ws_gear_box.add_child(row)
	_ws_gear_box.add_child(UIKit.label("Quick Merge: Common and Uncommon. Rare and up: by hand (tap a stack).  ·  %d copies" % total, 10, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var stacks := _inv_stacks()
	if stacks.is_empty():
		var lp := UIKit.panel(12)
		var t := UIKit.label("Nothing here yet.\nGear copies drop when you clear a stage (always on boss stages) and from Patrol." if total == 0 else "Nothing matches this filter.", 12, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lp.add_child(t)
		_ws_gear_box.add_child(lp)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for s in stacks:
		grid.add_child(_inv_tile(s))
	_ws_gear_box.add_child(grid)
	UIKit.reveal(grid, 0.02, 10.0)
	_power_label.text = "%d copies" % total
	_paint_wallet()

# a stack tile: the piece in its rarity colour, "x3", the set name as the badge
func _inv_tile(s: Dictionary) -> Button:
	var info: Dictionary = GearData.ITEMS[s.id]
	var worn: bool = gear.equipped[info.slot] == s.id and GearData.rarity(gear, s.id) == s.rarity
	var sub := "x%d  ·  %s" % [int(s.n), GearData.rarity_name(s.rarity)]
	var t := UIKit.tile(info.name, sub, s.rarity, GearData.SETS[info.set].name, _pic(s.id), Vector2(108, 96))
	if worn:
		t.add_theme_stylebox_override("normal", UIKit.box(Color(GearData.rarity_color(s.rarity), 0.28), Color.WHITE, 12, 2))
	if GearData.can_merge(gear, s.id, s.rarity):
		var m := UIKit.label("MERGE", 9, UIKit.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
		m.position = Vector2(108 - 44, 3)
		m.size = Vector2(40, 12)
		t.add_child(m)
	var stack := s
	t.pressed.connect(func(): _stack_box(stack))
	return t

# the stack's box: picture, what it is, Merge 3 -> 1 (any rarity, by hand)
func _stack_box(s: Dictionary) -> void:
	var info: Dictionary = GearData.ITEMS[s.id]
	var layer := ColorRect.new()
	layer.color = Color(0, 0.01, 0.04, 0.7)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var p := UIKit.popup_panel()
	var w := minf(size.x - 40.0, 340.0)
	p.custom_minimum_size = Vector2(w, 0)
	p.position = Vector2((size.x - w) * 0.5, size.y * 0.22)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	var pic := TextureRect.new()
	pic.texture = _pic(s.id)
	pic.custom_minimum_size = Vector2(0, 96)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(pic)
	v.add_child(UIKit.label(info.name, 17, GearData.rarity_color(s.rarity), HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UIKit.label("%s %s  ·  %s  ·  x%d" % [GearData.rarity_name(s.rarity), info.slot, GearData.SETS[info.set].name, int(s.n)], 12, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	var worn_r := GearData.rarity(gear, s.id)
	v.add_child(UIKit.label("Your %s is %s: cap Lv.%d" % [info.name, GearData.rarity_name(worn_r), GearData.level_cap(worn_r)], 11, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var nxt := GearData.next_rarity(s.rarity)
	var mb := UIKit.gold_button(("Merge %d  ->  1 %s" % [GearData.MERGE_COST, GearData.rarity_name(nxt)]) if nxt != "" else "Top rarity", 14)
	mb.custom_minimum_size = Vector2(0, 44)
	mb.disabled = not GearData.can_merge(gear, s.id, s.rarity)
	mb.pressed.connect(func():
		layer.queue_free()
		_merge_gear(s.id, s.rarity))
	v.add_child(mb)
	if nxt != "" and int(s.n) < GearData.MERGE_COST:
		v.add_child(UIKit.label("Need %d copies (you have %d)" % [GearData.MERGE_COST, int(s.n)], 11, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var close := UIKit.ghost_button("Close", 13)
	close.pressed.connect(layer.queue_free)
	v.add_child(close)
	p.add_child(v)
	layer.add_child(p)

func _merge_gear(id: String, r: String) -> void:
	var data := _read()
	var g := GearData.read(data)
	var to := GearData.merge(g, id, r)
	if to == "":
		return
	data["gear"] = GearData.write(g)
	var out := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(data))
		out.close()
	Progress.bump("merges")
	gear = g
	var fx := MergeFX.new()
	fx.src = _pic(id)
	fx.dst = _pic(id)
	fx.col = GearData.rarity_color(to)
	fx.title = "+1 %s %s" % [GearData.rarity_name(to), GearData.ITEMS[id].name]
	add_child(fx)
	await fx.finished
	_refresh_ws_gear()
	_paint_dots()

func _quick_merge() -> void:
	var data := _read()
	var g := GearData.read(data)
	var made := GearData.quick_merge(g)
	if made <= 0:
		return
	Sfx.play("merge")
	data["gear"] = GearData.write(g)
	var out := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(data))
		out.close()
	Progress.bump("merges", made)
	gear = g
	var fx := MergeFX.new()
	fx.src = load("res://parts/alloy.png") if ResourceLoader.exists("res://parts/alloy.png") else null
	fx.dst = load("res://icons/gear_on.png")
	fx.col = GearData.rarity_color("rare")
	fx.title = "%d merge%s" % [made, "s" if made > 1 else ""]
	add_child(fx)
	await fx.finished
	_refresh_ws_gear()
	_paint_dots()

# the Filter box: rows of chips for rarity, slot, set and sort order; Done closes it
func _filter_box() -> void:
	var layer := ColorRect.new()
	layer.color = Color(0, 0.01, 0.04, 0.7)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var p := UIKit.popup_panel()
	var w := minf(size.x - 24.0, 440.0)
	p.custom_minimum_size = Vector2(w, 0)
	p.position = Vector2((size.x - w) * 0.5, 60.0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.add_child(UIKit.popup_title("FILTER"))
	var rows := [
		["rarity", "RARITY", [["", "Any"]] + GearData.RARITIES.map(func(r): return [r, GearData.rarity_name(r)])],
		["set", "SET", [["", "Any"]] + GearData.SET_ORDER.filter(func(s): return GearData.set_unlocked(s, t_unlocked)).map(func(s): return [s, GearData.SETS[s].name])],
		["sort", "SORT", INV_SORTS.map(func(s): return [s, INV_SORT_NAMES[s]])],
		["show", "SHOW", [["", "Useful stacks"], ["all", "Everything"]]],
	]
	for spec in rows:
		v.add_child(UIKit.header(spec[1]))
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 6)
		flow.add_theme_constant_override("v_separation", 6)
		var key: String = spec[0]
		for opt in spec[2]:
			var b := UIKit.ghost_button(opt[1], 12)
			b.custom_minimum_size = Vector2(0, 30)
			var val: String = opt[0]
			var on: bool = _inv_filter[key] == val
			if on:
				b.add_theme_stylebox_override("normal", UIKit.box(Color(UIKit.CYAN, 0.25), UIKit.CYAN, 10))
			b.pressed.connect(func():
				_inv_filter[key] = val
				layer.queue_free()
				_filter_box())
			flow.add_child(b)
		v.add_child(flow)
	var done := UIKit.gold_button("Done", 14)
	done.custom_minimum_size = Vector2(0, 42)
	done.pressed.connect(func():
		layer.queue_free()
		_refresh_ws_gear())
	v.add_child(done)
	p.add_child(v)
	layer.add_child(p)

# ---- loadouts (Pilot page top row) ----
# Three kits (Loadouts): tap an empty one to save what you wear now; tap a saved one to
# wear it (gear, turrets, drone); tap the one in use to rename it or save over it.
func _paint_loadouts() -> void:
	if _kit_btn != null:
		_kit_btn.queue_redraw()   # (clean) the Loadout square shows the kit in use
	for c in _loadout_row.get_children():
		c.queue_free()
	var data := _read()
	var slots := Loadouts.read(data)
	var act := Loadouts.active(data)
	_loadout_row.add_child(UIKit.label("KIT", 11, UIKit.MUTED))
	for i in Loadouts.SLOTS:
		var s: Dictionary = slots[i]
		var b := UIKit.ghost_button(String(s.name) if s.set else "+ Save", 12)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 32)
		if i == act:
			b.add_theme_stylebox_override("normal", UIKit.box(Color(UIKit.GOLD, 0.22), UIKit.GOLD, 10))
		elif not s.set:
			b.modulate = Color(1, 1, 1, 0.7)
		var idx := i
		b.pressed.connect(func(): _on_loadout(idx))
		_loadout_row.add_child(b)

func _on_loadout(i: int) -> void:
	var data := _read()
	var slots := Loadouts.read(data)
	if not slots[i].set:
		Loadouts.save_slot(data, i)
		_write_data(data)
		_paint_loadouts()
		_toast("%s saved" % Loadouts.read(data)[i].name)
		return
	if Loadouts.active(data) == i:
		_loadout_box(i)
		return
	if Loadouts.apply(data, i):
		_write_data(data)
		_load()
		_paint_loadouts()
		_select(selected_slot)
		if _plat:
			_plat.flash()

# the kit in use: rename (a text box) or save what you wear now over it
func _loadout_box(i: int) -> void:
	var data := _read()
	var s: Dictionary = Loadouts.read(data)[i]
	var layer := ColorRect.new()
	layer.color = Color(0, 0.01, 0.04, 0.7)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var p := UIKit.popup_panel()
	var w := minf(size.x - 40.0, 320.0)
	p.custom_minimum_size = Vector2(w, 0)
	p.position = Vector2((size.x - w) * 0.5, size.y * 0.22)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.add_child(UIKit.popup_title("LOADOUT"))
	var input := LineEdit.new()
	input.text = String(s.name)
	input.max_length = 14
	input.placeholder_text = "Name"
	input.add_theme_font_size_override("font_size", 14)
	input.custom_minimum_size = Vector2(0, 38)
	v.add_child(input)
	var ren := UIKit.teal_button("Rename", 13)
	ren.pressed.connect(func():
		var d2 := _read()
		Loadouts.rename(d2, i, input.text)
		_write_data(d2)
		layer.queue_free()
		_paint_loadouts())
	v.add_child(ren)
	var over := UIKit.gold_button("Save what I wear now", 13)
	over.pressed.connect(func():
		var d2 := _read()
		Loadouts.save_slot(d2, i, input.text)
		_write_data(d2)
		layer.queue_free()
		_paint_loadouts()
		_toast("%s saved" % Loadouts.read(d2)[i].name))
	v.add_child(over)
	var close := UIKit.ghost_button("Cancel", 13)
	close.pressed.connect(layer.queue_free)
	v.add_child(close)
	p.add_child(v)
	layer.add_child(p)

# red dots (Progress.attention): Workshop when a parts or gear merge is possible, and the
# matching Workshop sub-tab
func _paint_dots() -> void:
	var at := Progress.attention(_read())
	if _tabs_row:
		UIKit.tab_dots(_tabs_row, [false, false, false, at.gear])
	if _ws_tabs_row and is_instance_valid(_ws_tabs_row):
		UIKit.tab_dots(_ws_tabs_row, at.gear_ws)

# coins and crystals as icons at the top right (the same wallet as Store and Quests)
func _paint_wallet() -> void:
	if _wallet_box == null:
		return
	for c in _wallet_box.get_children():
		c.queue_free()
	_wallet_box.add_child(UIKit.wallet(coins, int(_read().get("crystals", 0))))

func _write_data(data: Dictionary) -> void:
	var out := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(data))
		out.close()

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
	if UIKit.CLEAN:
		_refresh_drone_clean()
		return
	var body: Dictionary = DroneData.BODIES[drone.body]
	var pod: Dictionary = DroneData.PODS[drone.pod]
	# preview: the drone hovering, turning a little
	var pv := Control.new()
	pv.custom_minimum_size = Vector2(0, 170)
	var bt: Texture2D = load("res://drone/body_%s.png" % drone.body)
	var pt: Texture2D = load("res://drone/pod_%s.png" % DroneData.pod_art(drone.pod))
	var tm := [0.0]
	pv.draw.connect(func():
		var c := pv.size * 0.5 + Vector2(0, sin(tm[0] * 2.0) * 5.0)
		Glass.panel(pv, Glass.box(Rect2(Vector2.ZERO, pv.size), 16.0))
		pv.draw_set_transform(c, sin(tm[0] * 0.8) * 0.25, Vector2.ONE)
		var bw: float = minf(130.0, 150.0 * bt.get_width() / bt.get_height())   # tall bodies (the Wisp) fit the box
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
	var hero_el := Heroes.element_name(DroneData.body_element(drone.body))   # the body has its own element (Rudy)
	# short (Rudy, dev186): what it is and its numbers; the body and pod lines are on their tiles
	var info := UIKit.label("%s + %s  ·  Lv.%d  ·  %s\nATK %.1f every %.2f s" % [body.name, pod.name, lvl, hero_el, dmg * DroneData.dmg_bonus(lvl),
		float(pod.every) / float(body.rate) / DroneData.rate_bonus(lvl)], 12, Color(0.85, 0.92, 1.0))
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var ip := UIKit.panel(10)
	ip.add_child(info)
	var urow := HBoxContainer.new()
	urow.add_theme_constant_override("separation", 10)
	ip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	urow.add_child(ip)
	var dcap := DroneData.level_cap(drone)   # capped by the body's star (Gates, DESIGN-stars.md)
	var up := UIKit.gold_button("MAX" if lvl >= DroneData.MAX_LEVEL else (("Lv.%d cap\nnext star" % dcap) if lvl >= dcap else _upgrade_text(DroneData.upgrade_cost(lvl), lvl, Materials.drone_need(lvl))), 13)
	up.custom_minimum_size = Vector2(118, 50)
	up.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	up.disabled = lvl >= dcap or coins < DroneData.upgrade_cost(lvl)
	up.pressed.connect(func():
		var cost := DroneData.upgrade_cost(int(drone.level))
		if coins >= cost and int(drone.level) < DroneData.level_cap(drone) and await _pay_upgrade(cost, int(drone.level), Materials.drone_need(int(drone.level))):
			drone.level = int(drone.level) + 1
			for m in DroneData.MILESTONES:
				if int(drone.level) == int(m[0]):
					_milestone_toast("Drone reached Lv.%d: %s" % [m[0], m[1]])
			_save_drone()
			Progress.bump("upgrades")
			_refresh_drone())
	urow.add_child(up)
	# the body's next star (Gates): the level at its cap + essences, the drone line, coins
	var dstar := DroneData.star(drone)
	var dwhy := DroneData.why_not_star(_read(), drone)
	var sb := UIKit.teal_button("Star up" if dwhy == "" else (dwhy.replace(" first", "\nfirst") if (dwhy.begins_with("Lv.") or dwhy.begins_with("Pilot")) else ("Max" if dwhy == "Max stars" else "Star up")), 12)
	sb.custom_minimum_size = Vector2(96, 50)
	sb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sb.disabled = dwhy != ""
	sb.tooltip_text = Gates.need_text(DroneData.star_need(drone))
	sb.pressed.connect(_on_drone_star)
	urow.add_child(sb)
	_drone_box.add_child(urow)
	if dstar < Gates.MAX_STAR:
		var nl := UIKit.label("%s now  ·  next star: Lv.%d + %s" % [Gates.long_text(dstar), DroneData.level_cap(drone), Gates.need_text(DroneData.star_need(drone))], 11, UIKit.MUTED)
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_drone_box.add_child(nl)
	for spec in [["BODY", DroneData.BODIES, "body"], ["WEAPON POD", DroneData.PODS, "pod"]]:
		_drone_box.add_child(UIKit.header(spec[0]))
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 8)
		for id in spec[1]:
			var def: Dictionary = spec[1][id]
			var open: bool = (DroneData.body_open(drone, id, pilot_level) if spec[2] == "body" else (pilot_level >= int(def.unlock) or DevTools.on))
			var on: bool = drone[spec[2]] == id
			var sub := "" if (on or open) else ((("Stage %d first" % DroneData.gate(id)) if not DroneData.gate_open(_read(), id) else (DroneData.cost_text(id) if DroneData.premium(id) else "%s coins" % UIKit.num(int(def.cost.get("coins", 0))))) if DroneData.is_bought(id) else "Pilot Lv.%d" % int(def.unlock))   # no "Choose" / "Equipped" words (Rudy): an E badge marks the equipped one; stars gate the bought bodies (Gates)
			if spec[2] == "body":
				sub = ("%s %s" % [Gates.badge(DroneData.star(drone, id)), Heroes.element_name(DroneData.body_element(id))]) + (("  ·  " + sub) if sub != "" else "")   # the stars it earned (Gates)
			var tile := UIKit.tile(def.name, sub, (DroneData.body_element(id) if spec[2] == "body" else "ion") if on else "common", "", load("res://drone/%s_%s.png" % [spec[2], DroneData.pod_art(id) if spec[2] == "pod" else id]), Vector2(108, 92))
			if not open:
				tile.modulate = Color(0.55, 0.55, 0.65, 0.8)
			var key: String = spec[2]
			var pick: String = id
			tile.pressed.connect(func():
				if not open and key == "body" and DroneData.is_bought(pick):   # buy it (coins + parts, crystals as the fallback)
					_on_drone_unlock(pick)
					return
				if open:
					drone[key] = pick
					_save_drone()
					_refresh_drone())
			if on:
				UIKit.equipped_badge(tile, UIKit.RARITY.get(DroneData.body_element(id) if spec[2] == "body" else "ion", UIKit.CYAN))
			grid.add_child(tile)
		_drone_box.add_child(grid)
	_power_label.text = "DRONE Lv.%d" % lvl
	_paint_wallet()

# the drone body's next star (Gates)
func _on_drone_star() -> void:
	var data := _read()
	var why := DroneData.star_up(data, drone)
	if why != "":
		_toast(why)
		return
	data["drone"] = drone
	_write_data(data)
	coins = int(data.get("coins", 0))
	Sfx.play("merge")
	Progress.bump("upgrades")
	if UIKit.CLEAN:
		var ds := DroneData.star(drone)
		_rarity_fx(String(DroneData.BODIES[drone.body].name), load("res://drone/body_%s.png" % drone.body), ds - 1, ds, "Power +%d%%" % roundi((Gates.RED_STEP if Gates.is_red(ds) else Gates.GOLD_STEP) * 100.0), "Level cap %d" % DroneData.level_cap(drone))
	else:
		_toast("%s: %s" % [DroneData.BODIES[drone.body].name, Gates.long_text(DroneData.star(drone))])
	_refresh_drone()

func _save_drone() -> void:
	var data := _read()
	data["drone"] = drone
	data["coins"] = coins
	var out := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(data))

# The pilot standing in the Gear screen: the same live rig as in battle, idling, his
# rifle drifting, flames in the equipped jetpack's style. SWIVEL (Rudy, dev172): drag a
# finger across him to turn him left and right through Luna's turn frames (or Rook's side and
# front poses); he holds the angle, then drifts back to face you after a few seconds.
class PilotShowcase extends Control:
	var view: PilotRigView
	var plat   # HeroStand: where his feet go
	var t := 0.0
	var swivel := 0.0          # -1 facing right .. 0 the camera .. 1 facing left; past 1 or -1 round the back (dev188), wraps at 2
	var _drag := false
	var _idle := 0.0           # seconds since the finger left
	var _hint := 1.0           # "drag to turn" fades once used
	func _ready() -> void:
		view = PilotRigView.new()
		view.height = 200.0   # big on the platform (heroes, dev172)
		view.front_only = true   # facing you, chunky and big-headed (Rudy)
		view.face_override = 0.0
		add_child(view)
		mouse_filter = Control.MOUSE_FILTER_STOP
	func _gui_input(ev: InputEvent) -> void:
		if (ev is InputEventScreenTouch or ev is InputEventMouseButton):
			_drag = ev.pressed
			if not ev.pressed:
				_idle = 0.0
		elif (ev is InputEventScreenDrag or ev is InputEventMouseMotion) and _drag:
			if UIKit.CLEAN:
				# only a slight turn left or right, never his back (Rudy, 2026-11-09)
				swivel = clampf(swivel - ev.relative.x * 0.008, -0.35, 0.35)
			elif PilotRig.spin_ready():
				swivel = wrapf(swivel - ev.relative.x * 0.011, -2.0, 2.0)   # the full circle: Luna's back frames
			else:
				swivel = clampf(swivel - ev.relative.x * 0.011, -1.0, 1.0)
			_hint = 0.0
			queue_redraw()
	func _process(delta: float) -> void:
		t += delta
		if not _drag:
			_idle += delta
			if _idle > (1.2 if UIKit.CLEAN else 4.0):
				swivel = move_toward(swivel, 0.0, delta * 0.8)   # drifts back to face you
		if PilotRig.spin_ready():
			view.face_override = 2.0
			view.spin_override = fposmod((1.0 - swivel) * 0.25, 1.0)
		else:
			view.spin_override = -1.0
			view.face_override = swivel
		var aim := -PI / 2.0 - 0.3 + sin(t * 0.7) * 0.35
		# hovering just above the platform floor
		var feet: float = plat.feet_y() if plat else size.y - 40.0
		view.update(delta, Vector2(size.x * 0.5, feet - 162.0 + sin(t * 1.1) * 7.0), aim, sin(t * 0.5) * 0.2 + swivel * 0.1, 1.0 + sin(t * 0.9) * 0.2, 0.0)   # hovering a little above the disc, centred on it (Rudy)
		if _hint > 0.0:
			queue_redraw()
	func _draw() -> void:
		if _hint <= 0.0:
			return
		var a: float = _hint * (0.45 + 0.25 * sin(t * 3.0))
		var y := size.y - 14.0
		draw_string(ThemeDB.fallback_font, Vector2(0, y), "<  drag to turn  >" if UIKit.CLEAN else "<  drag to spin  >", HORIZONTAL_ALIGNMENT_CENTER, size.x, 11, Color(0.6, 0.85, 1.0, a))

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
	data["turrets"] = {"loadout": t_loadout, "levels": t_levels, "tracks": t_tracks, "owned": t_owned, "stars": t_stars}
	data["coins"] = coins
	var out := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(data))

func _t_lvl(id: String) -> int:
	return int(t_levels.get(id, 1))

func _build_turrets(box: VBoxContainer) -> void:
	if UIKit.CLEAN:   # the clean page builds itself in _refresh_turrets_clean
		t_focus = t_loadout[t_mount]
		return
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
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 6)
	pv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pv.add_child(_t_place)
	_t_star = UIKit.gold_button("Star up", 12)   # the next star (Gates, DESIGN-stars.md)
	_t_star.custom_minimum_size = Vector2(110, 40)
	_t_star.pressed.connect(_on_turret_star)
	pv.add_child(_t_star)
	row.add_child(pv)
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
	var t := UIKit.tile(def.name, subtitle, Turrets.element(id), badge, tex, size)   # coloured by its element (dev172)
	if size.x > 120.0:
		UIKit.corner_icon(t, UIKit.element_icon(Turrets.element(id)), 22.0)   # the element badge
		UIKit.corner_icon(t, UIKit.role_icon(Turrets.role(id)), 20.0, true)   # its role, top left (dev189)
	var pic: TextureRect = t.get_node("Body").get_child(0)   # the depth layer sits at child 0 since dev149
	pic.custom_minimum_size = Vector2(0, size.y - 44.0)
	if dim:
		pic.modulate = Color(0.45, 0.45, 0.55, 0.8)
	return t

func _refresh_turrets() -> void:
	if UIKit.CLEAN:
		_refresh_base()   # the base you build took the turrets' place (Base, 2026-11-10)
		return
	_power_label.text = ""
	_paint_wallet()
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
			var col: Color = UIKit.RARITY[Turrets.element(id)] if id != "" else UIKit.CYAN
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
		var locked: bool = not Turrets.owned({"owned": t_owned}, id)
		var price_sub: String = ("Stage %d first" % Turrets.gate(id)) if not Turrets.gate_open(_read(), id) else ("%s coins" % UIKit.num(int(def.cost.get("coins", 0))) if int(def.cost.get("coins", 0)) > 0 else "Unlock")
		var sub := price_sub if locked else ("In development" if not def.ready else "%s  ·  %s" % [Turrets.role(id), Heroes.element_name(Turrets.element(id))])
		var t := _turret_tile(id, sub, "Lv.%d %s" % [_t_lvl(id), Gates.badge(Turrets.star({"stars": t_stars}, id))], Vector2(144, 116), locked or not def.ready)   # the stars it earned (Gates), after the level so the role icon never covers them
		if t_loadout.has(id):
			UIKit.equipped_badge(t, UIKit.RARITY[Turrets.element(id)], str(t_loadout.find(id) + 1))   # the mount it stands on
		if id == t_focus:
			t.add_theme_stylebox_override("normal", UIKit.box(Color(UIKit.RARITY[Turrets.element(id)], 0.25), Color.WHITE, 10, 2))
		var tid: String = id
		t.pressed.connect(func():
			t_focus = tid
			_refresh_turrets())
		_turret_grid.add_child(t)
	_refresh_turret_detail()
	UIKit.reveal(_turret_grid, 0.03, 10.0)

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
	var locked: bool = not Turrets.owned({"owned": t_owned}, t_focus)
	var ms := Turrets.milestones(lvl)
	# name and level, its milestone stars, then the next milestone (every 5 levels)
	var tstar := Turrets.star({"stars": t_stars}, t_focus)
	var lines := "%s  %s  ·  %s  ·  %s\nLv.%d  %s  ·  %s" % [def.name, Gates.text(tstar) + (" red" if Gates.is_red(tstar) else ""), Turrets.role(t_focus), Heroes.element_name(Turrets.element(t_focus)), lvl, "★".repeat(ms), def.desc]
	if locked:
		lines += "\n%s%s%s" % [Turrets.cost_text(t_focus), ("  ·  or %d crystals" % Turrets.crystal_price(t_focus)) if Turrets.crystal_price(t_focus) > 0 else "", ("\nClear stage %d first" % Turrets.gate(t_focus)) if not Turrets.gate_open(_read(), t_focus) else ""]
	elif not def.ready:
		lines += "\nComing soon"
	else:
		var sn := Turrets.star_need({"stars": t_stars}, t_focus)   # the next star (Gates)
		lines += "\nNext milestone Lv.%d: ATK +5%%" % ((ms + 1) * 5)
		if tstar < Gates.MAX_STAR:
			lines += "\nNext star: every track Lv.%d + %s" % [Turrets.track_cap(tstar), Gates.need_text(sn)]
	_t_detail.text = lines
	var usable: bool = not locked and def.ready
	_t_star.visible = usable
	if usable:
		var why := Turrets.why_not_star(_read(), {"stars": t_stars, "tracks": t_tracks}, t_focus)
		_t_star.disabled = why != ""
		_t_star.text = "Star up" if why == "" else (why.replace(" first", "\nfirst") if (why.begins_with("Lv.") or why.begins_with("Pilot") or why == "Max stars") else "Star up")
	if locked:   # the Place button buys it (coins + parts, crystals as the fallback)
		for k in Turrets.TRACKS:
			var lb: Button = _t_tracks_btn[k]
			lb.text = Turrets.TRACK_NAMES[k]
			lb.disabled = true
		_t_place.disabled = false
		_t_place.text = "Unlock"
		return
	var tcap := Turrets.track_cap(tstar)   # its star caps every track (Gates)
	for k in Turrets.TRACKS:
		var b: Button = _t_tracks_btn[k]
		var l: int = int(tr[k])
		if l >= Turrets.MAX_TRACK:
			b.text = "%s %d\nMAX" % [Turrets.TRACK_NAMES[k], l]
			b.disabled = true
			continue
		if l >= tcap:
			b.text = "%s %d\nLv.%d cap: next star" % [Turrets.TRACK_NAMES[k], l, tcap]
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
	if t_focus != "" and not Turrets.owned({"owned": t_owned}, t_focus):
		_on_turret_unlock()
		return
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
	if coins < cost or l >= Turrets.track_cap(Turrets.star({"stars": t_stars}, t_focus)):   # capped by its star (Gates)
		return
	# parts for a track level follow Parts.need on a 1-10 scale (Turrets.track_parts)
	if not await _pay_upgrade(cost, l / 2, Materials.turret_need(l, Turrets.element(t_focus))):
		return
	var was := Turrets.milestones(Turrets.level_of(tr))
	tr[k] = l + 1
	t_tracks[t_focus] = tr
	t_levels[t_focus] = Turrets.level_of(tr)
	_save_turrets()
	Progress.bump("turret_upgrades")
	_refresh_turrets()
	if not _t_tracks_btn.has(k):
		return
	var b: Button = _t_tracks_btn[k]
	b.pivot_offset = b.size * 0.5
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2(1.1, 1.1), 0.08)
	tw.tween_property(b, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if Turrets.milestones(Turrets.level_of(tr)) > was:
		_milestone_toast("%s reached Lv.%d: ATK +5%%" % [Turrets.TURRETS[t_focus].name, Turrets.level_of(tr)])

# the turret's next star (Gates): every track at its cap + essences, coils, coins
func _on_turret_star() -> void:
	if t_focus == "":
		return
	var data := _read()
	var t := {"stars": t_stars.duplicate(), "tracks": t_tracks}
	var why := Turrets.star_up(data, t, t_focus)
	if why != "":
		_toast(why)
		return
	t_stars = t.stars
	_write_data(data)
	coins = int(data.get("coins", 0))
	_save_turrets()
	Sfx.play("merge")
	Progress.bump("turret_upgrades")
	if UIKit.CLEAN:
		var ts := Turrets.star(t, t_focus)
		_rarity_fx(String(Turrets.TURRETS[t_focus].name), load("res://turrets/%s_idle.png" % Turrets.TURRETS[t_focus].art), ts - 1, ts, "Power +%d%%" % roundi((Gates.RED_STEP if Gates.is_red(ts) else Gates.GOLD_STEP) * 100.0), "Every track can reach Lv.%d" % Turrets.track_cap(ts))
	else:
		_toast("%s: %s" % [Turrets.TURRETS[t_focus].name, Gates.long_text(Turrets.star(t, t_focus))])
	_refresh_turrets()

# a gold line that rises over the screen when something reaches a milestone
func _milestone_toast(text: String) -> void:
	_toast("MILESTONE!  " + text)

# a gold line that rises over the screen (kit saved, milestone...)
func _toast(text: String) -> void:
	var l := UIKit.label(text, 15, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
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
func _upgrade_text(coin_cost: int, level: int, extra: Dictionary = {}) -> String:
	var needs := Parts.need(level)
	needs.merge(extra)   # the domain's materials (materials.gd, dev189)
	if needs.is_empty():
		return "Upgrade
%d coins" % coin_cost
	return "Upgrade
%d coins
%s" % [coin_cost, Parts.text(needs)]

# Pays for an upgrade (coins + parts, or crystals for missing parts after asking).
# Returns true when paid; the save already has the new coins, crystals and parts.
func _pay_upgrade(coin_cost: int, level: int, extra: Dictionary = {}) -> bool:
	if DevTools.on:
		return true   # dev mode: free
	var data := _read()
	var needs := Parts.need(level)
	needs.merge(extra)
	var have := Parts.read(data)
	var use_crystals := false
	if not Parts.has_all(have, needs):
		var c := Parts.crystals_for_missing(have, needs)
		var lines: Array = []
		for k in needs:
			lines.append("%s: %d / %d" % [Parts.kind(k).name, int(have.get(k, 0)), int(needs[k])])
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
	var p := UIKit.popup_panel()
	p.custom_minimum_size = Vector2(300, 0)
	p.position = Vector2(size.x * 0.5 - 150, size.y * 0.3)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.add_child(UIKit.popup_title(title))
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

# the page rises and fades in over the world (UIKit.enter, dev157); no more black cut
func _fade_in_overlay() -> void:
	UIKit.enter(self)

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

# Guided first-time tips per Gear tab (Tips, dev163): the first unseen one shows
func _page_tips(i: int) -> void:
	var list: Array = []
	match i:
		0:
			list = [["gear_upgrade", _upgrade_btn], ["gear_kits", _loadout_row]]
		1:
			if Turrets.mount_open(0, t_unlocked):
				list = [["turrets", _t_place]]
		2:
			if DroneData.unlocked(pilot_level):
				list = [["drone", null]]
		3:
			list = [["workshop", _ws_merge_btn]]
			if _ws_tabs_row and is_instance_valid(_ws_tabs_row) and _ws_tabs_row.get_child_count() > 1:
				list.append(["workshop_gear", _ws_tabs_row.get_child(1)])
			if _ws_tab == 1 and _quick_btn and is_instance_valid(_quick_btn):
				list.append(["quick_merge", _quick_btn])
	Tips.first(get_tree(), list)
	# the small one-line hints (Hints, 2026-11-10): one a visit, only for what is open
	var sv := Progress.read()
	var hl: Array = []
	match i:
		0:
			if _abl_btn != null and is_instance_valid(_abl_btn) and _abl_btn.visible:
				hl.append("ability")
			if _wing_btn != null and is_instance_valid(_wing_btn) and _wing_btn.visible:
				hl.append("wingmate")
		1:
			hl.append("base")
			if Research.open(sv):
				hl.append("research")
		2:
			if DroneData.support_open(sv):
				hl.append("support")
	Hints.show(self, hl)

# ------------------------------------------------------------------ heroes (dev172)
# The Pilot tab became the HERO page (DESIGN-heroes.md): a roster of complete characters
# instead of armour slots, rated by star grade and BOUGHT (coins + parts, or crystals), a
# few gated by a stage. Roster row (six heroes), the hero on duty on his platform, name +
# grade + element + passive, LEVEL UP (coins), tier + shards + EVOLVE; a locked hero shows
# his price and Unlock buttons instead. The weapon stays as the one gear slot under it.
var hero := {}                 # Heroes.read(save): {selected, owned, levels, tiers, shards}
var _view_id := ""             # the hero the panel talks about (the one on duty, or a locked one you tapped)
var _roster_row: VBoxContainer   # the grade rows (one scrolling row per star grade)
var _hero_panel: PanelContainer
var _hero_name: Label
var _hero_tags: HBoxContainer    # (clean) element, stars, grade
var _hero_chips: HBoxContainer   # (clean) ATK and HP as chips
var _hero_bar: HBoxContainer     # (clean) Lv.N ---- cap
var _kit_btn: Button             # (clean) the Loadout square
var _wing_btn: Button            # (clean) the Wingmate square
var _hero_line: Label
var _level_btn: Button
var _stars_l: Label
var _evolve_btn: Button
var _unlock_btn: Button
var _crystal_btn: Button
var _def_btn: Button           # the DEF track (HP instead of hearts, dev172)

func _hero_id() -> String:
	return Heroes.selected(hero)

# The roster under the platform (Rudy's layout): one row per star grade (Common, Uncommon,
# Epic ...), scrolling sideways, every hero a tile: name, "Lv.N · T2" when yours, else what
# he needs (price, or the stage first); locked ones dimmed; the hero on duty lit.
func _paint_roster() -> void:
	for c in _roster_row.get_children():
		c.queue_free()
	var data := _read()
	if UIKit.CLEAN:
		_paint_roster_clean()
		return
	for g in Heroes.GRADES.size():
		var ids: Array = []
		for id in Heroes.ORDER:
			if Heroes.grade(String(id)) == g + 1:
				ids.append(String(id))
		var gi: Dictionary = Heroes.GRADES[g]
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 8)
		head.add_child(UIKit.label(String(gi.name).to_upper(), 11, gi.color))   # the grade is a word now; stars are earned (Gates)
		_roster_row.add_child(head)
		if ids.is_empty():
			head.add_child(UIKit.label("coming", 11, UIKit.MUTED))
			continue
		var scroll := ScrollContainer.new()
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.custom_minimum_size = Vector2(0, 100)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		for hid in ids:
			var h: Dictionary = Heroes.ROSTER[hid]
			var el: String = h.element
			var own: bool = Heroes.owned(hero, hid)
			var on: bool = hid == _hero_id()
			var sub: String
			if own:
				sub = "Lv.%d  ·  %s" % [Heroes.level(hero, hid), Gates.badge(Heroes.tier(hero, hid))]
			elif not Heroes.gate_open(data, hid):
				sub = "Stage %d first" % Heroes.gate(hid)
			elif Heroes.premium(hid):
				sub = "%d crystals" % Heroes.crystal_price(hid)   # premium (Gates): crystals only
			else:
				sub = "%s coins" % UIKit.num(int(h.cost.get("coins", 0))) if int(h.cost.get("coins", 0)) > 0 else "Unlock"
			var pic: Texture2D = _hero_portrait(hid) if own else UIKit.ic("ui_padlock")
			var t := UIKit.tile(h.name, sub, el, "", pic, Vector2(104, 92))
			UIKit.corner_icon(t, UIKit.element_icon(el), 22.0)   # the element badge (Luna's icons)
			if not own:
				t.modulate = Color(0.6, 0.6, 0.7, 0.85)
			elif not on:
				t.modulate = Color(0.8, 0.85, 0.95, 0.9)
			var tap: String = hid
			t.pressed.connect(func(): _tap_hero(tap))
			row.add_child(t)
		scroll.add_child(row)
		_roster_row.add_child(scroll)

# (clean) the roster as one row of round portraits: the hero on duty ringed in cyan, the one you are
# looking at in white, locked ones dimmed with a padlock; the grade colour as a thin ring
func _paint_roster_clean() -> void:
	var scroll := ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.custom_minimum_size = Vector2(0, 66)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for hid in Heroes.ORDER:
		var id := String(hid)
		var own: bool = Heroes.owned(hero, id)
		var duty: bool = id == _hero_id()
		var looking: bool = id == _view_id and not duty
		var gc: Color = Gates.step_color(Heroes.tier(hero, id))   # his rarity step (ASCEND)
		var face: Texture2D = _hero_portrait(id)
		var b := Button.new()
		b.custom_minimum_size = Vector2(58, 58)
		b.tooltip_text = String(Heroes.ROSTER[id].name)
		for st in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		b.draw.connect(func():
			var c := b.size * 0.5
			b.draw_circle(c, 28.0, Color(0.086, 0.141, 0.239))
			if face != null:
				var fs := Vector2(46, 46)
				b.draw_texture_rect(face, Rect2(c - fs * 0.5, fs), false, Color(1, 1, 1, 1.0 if own else 0.35))
			b.draw_arc(c, 27.0, 0.0, TAU, 48, UIKit.CYAN if duty else (Color.WHITE if looking else Color(gc, 0.55)), 3.0 if duty or looking else 1.5, true)
			if not own:   # a padlock
				b.draw_arc(c + Vector2(0, -4), 6.0, PI, TAU, 12, Color.WHITE, 2.4, true)
				b.draw_rect(Rect2(c + Vector2(-8, -3), Vector2(16, 12)), Color.WHITE))
		var tap := id
		b.pressed.connect(func(): _tap_hero(tap))
		UIKit.press_fx(b)
		row.add_child(b)
	scroll.add_child(row)
	_roster_row.add_child(scroll)

# Luna's portrait when it exists, else his weapon picture as a stand-in
func _hero_portrait(id: String) -> Texture2D:
	# an evolved hero shows his tier portrait when Luna has painted it (dev189)
	for k in range(PilotRig.look_tier(Heroes.tier(hero, id)), 1, -1):   # tier 2 portrait from 2 stars, tier 3 from 5 (Rudy)
		var tp := "res://heroes/%s/portrait_t%d.png" % [id, k]
		if ResourceLoader.exists(tp):
			return load(tp)
	var p := "res://heroes/%s/portrait.png" % id
	if ResourceLoader.exists(p):
		return load(p)
	# Rook: head and shoulders cut from his turn frame (no portrait render yet)
	if id == Heroes.DEFAULT and ResourceLoader.exists("res://pilot_turn/commander_3.png"):
		var tf: Texture2D = load("res://pilot_turn/commander_3.png")
		var at := AtlasTexture.new()
		at.atlas = tf
		var s := tf.get_size()
		at.region = Rect2(s.x * 0.18, 0.0, s.x * 0.64, s.y * 0.42)
		return at
	return _pic(String(Heroes.ROSTER[id].weapon))

# an owned hero goes on duty; a locked one is shown with his price
func _tap_hero(id: String) -> void:
	if Heroes.owned(hero, id):
		_select_hero(id)
	else:
		_view_id = id
		_paint_hero()

func _select_hero(id: String) -> void:
	hero.selected = id
	_view_id = id
	var data := _read()
	data["hero"] = Heroes.write(hero)
	_write_data(data)
	PilotRig.set_gear(data)   # the showcase swaps to him at once
	_paint_roster()
	_paint_hero()
	_paint_suit()

# name + grade + element, passive and level, LEVEL UP, tier + EVOLVE; or the price + Unlock
func _paint_hero() -> void:
	if _view_id == "" or not Heroes.ROSTER.has(_view_id):
		_view_id = _hero_id()
	var id := _view_id
	var data := _read()
	var h: Dictionary = Heroes.ROSTER[id]
	var el: String = h.element
	var col := Heroes.element_color(el)
	var own := Heroes.owned(hero, id)
	var hstar := Heroes.tier(hero, id)   # the stars he earned (Gates); the grade stays a word
	_hero_name.text = "%s  %s  ·  %s %s" % [h.name, (Gates.text(hstar) + (" red" if Gates.is_red(hstar) else "")) if own else "", Heroes.grade_name(id), Heroes.element_name(el)]
	_hero_name.add_theme_color_override("font_color", col)
	_level_btn.visible = own
	_def_btn.visible = false
	_evolve_btn.visible = own
	_stars_l.visible = own
	_unlock_btn.visible = not own
	_crystal_btn.visible = not own and Heroes.crystal_price(id) > 0
	if own:
		var lv := Heroes.level(hero, id)
		var t := Heroes.tier(hero, id)
		var dl := Heroes.def_level(hero, id)
		var next_lv := ((lv / Heroes.MILESTONE_EVERY) + 1) * Heroes.MILESTONE_EVERY
		var ms := Heroes.milestone_at(next_lv)
		var next_ms := ("next Lv.%d: %s" % [next_lv, ms.text]) if not ms.is_empty() else ""
		var gm: float = float(Heroes.GRADES[Heroes.grade(id) - 1].mult)
		var atk := roundi(((gm * (1.0 + float(Heroes.PER_LEVEL.atk) * (lv - 1)) * Gates.power_mult(t)) - 1.0) * 100.0)
		var st := Heroes.stats(data) if id == _hero_id() else {}
		var hp_txt := ("HP %d  ·  DEF %d%%" % [roundi(float(st.get("hp", 0.0))), roundi(float(st.get("def", 0.0)) * 100.0)]) if not st.is_empty() else ""
		# short (Rudy, dev186): one line of numbers, one line for the next perk
		_hero_line.text = "Lv.%d  ·  ATK +%d%%  ·  %s\n%s" % [lv, atk, hp_txt, next_ms]
		var cost := Heroes.level_cost(lv)
		var hcap := Heroes.level_cap(hero, id)   # capped by his star (Gates)
		_level_btn.disabled = lv >= hcap or coins < cost
		_level_btn.text = "MAX" if lv >= Heroes.MAX_LEVEL else (("Lv.%d cap\nnext star" % hcap) if lv >= hcap else "Level up\n%d coins" % cost)
		var dcost := Heroes.def_cost(dl)
		_def_btn.disabled = dl >= Heroes.MAX_DEF_LEVEL or coins < dcost
		_def_btn.text = "DEF max" if dl >= Heroes.MAX_DEF_LEVEL else "DEF up\n%d coins" % dcost
		# the next star (Gates, DESIGN-stars.md): shards first behind their icon, then the materials
		# and coins it asks for, then what he is now; the button says the one thing in the way
		var need := Heroes.next_tier_cost(hero, id)
		var have := Heroes.shards(hero, id)
		var sn := Heroes.star_need(hero, id)
		_stars_l.text = "%s  ·  %s  ·  %s" % [("%d / %d shards + %s" % [have, need, Gates.need_text({"mats": sn.mats, "coins": sn.coins})]) if t < Gates.MAX_STAR else "max stars", Gates.long_text(t), h.passive]
		var why := Heroes.why_not_evolve(hero, id, data)
		_evolve_btn.disabled = why != ""
		_evolve_btn.text = "Evolve" if why == "" else (why.replace(" first", "\nfirst") if (why.begins_with("Lv.") or why.begins_with("Pilot")) else ("Max" if why == "Max stars" else "Evolve"))
	else:
		var gate_txt := "" if Heroes.gate_open(data, id) else "\nClear stage %d first" % Heroes.gate(id)
		_hero_line.text = "%s\n%s%s" % [h.passive, Heroes.cost_text(id), gate_txt]
		_unlock_btn.text = "Unlock"
		_unlock_btn.disabled = not (Heroes.gate_open(data, id) and Heroes.can_afford(data, id))
		_crystal_btn.text = "%d crystals" % Heroes.crystal_price(id)
		_crystal_btn.disabled = not Heroes.gate_open(data, id) or int(data.get("crystals", 0)) < Heroes.crystal_price(id)
	if UIKit.CLEAN:
		_paint_hero_clean(id, own)
	_power_label.text = "POWER %d" % Heroes.power(_read())
	if _talent_btn:
		UIKit.dot(_talent_btn, Talents.affordable(_read()))   # a node is ready to buy (dev197)
	_paint_wallet()
	# the platform's buildings light up with the duty hero's tier, in his element colour
	if _plat:
		var dt := Heroes.tier(hero, _hero_id())
		_plat.glow = clampf((dt - 1) / 4.0, 0.0, 1.0)   # brighter with every star (Gates)
		_plat.glow_col = Heroes.element_color(Heroes.element_of(_hero_id()))

# the clean panel (mock-up "Round 2 · Clean"): the name alone, a tag row (element icon, the stars
# he earned, his grade), ATK and HP chips, the level bar to his cap, and LEVEL UP with its cost
func _paint_hero_clean(id: String, own: bool) -> void:
	var h: Dictionary = Heroes.ROSTER[id]
	var el: String = h.element
	_hero_name.text = String(h.name)
	_hero_name.add_theme_color_override("font_color", UIKit.TEXT)
	for box in [_hero_tags, _hero_chips, _hero_bar]:
		for c in box.get_children():
			c.queue_free()
	var ei := TextureRect.new()
	ei.texture = UIKit.element_icon(el)
	ei.custom_minimum_size = Vector2(24, 24)
	ei.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ei.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hero_tags.add_child(ei)
	# his rarity step (ASCEND): one chip in the step's colour; a locked hero shows where he starts
	var hs := Heroes.tier(hero, id)
	_hero_tags.add_child(UIKit.chip(Gates.step_name(hs), Gates.step_color(hs)))
	_hero_line.visible = not own   # a locked hero: his passive and price stay as text
	_evolve_btn.visible = false   # ASCEND lives in the LEVEL UP sheet
	_hero_chips.visible = own
	_hero_bar.visible = own
	if not own:
		return
	var data := _read()
	var lv := Heroes.level(hero, id)
	var t := Heroes.tier(hero, id)
	var gm: float = float(Heroes.GRADES[Heroes.grade(id) - 1].mult)
	var atk := roundi(((gm * (1.0 + float(Heroes.PER_LEVEL.atk) * (lv - 1)) * Gates.power_mult(t)) - 1.0) * 100.0)
	var ss := _stat_strs(_hero_preview(id, 0, 0))   # the same numbers the LEVEL UP sheet shows
	for chip in [[UIKit.ic("st_atk"), "ATK " + String(ss[0])], [UIKit.ic("st_hp"), "HP " + String(ss[1])]]:
		if chip.is_empty():
			continue
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UIKit.pill(UIKit.CARD_HI, 17, Vector2(12, 4)))
		p.add_child(UIKit.iconed(chip[0], chip[1], 16, UIKit.TEXT, 22.0))
		_hero_chips.add_child(p)
	var cap := Heroes.level_cap(hero, id)
	_hero_bar.add_child(UIKit.title("Lv.%d" % lv, 14, UIKit.TEXT))
	var bar := ProgressBar.new()
	bar.max_value = maxi(cap, 1)
	bar.value = lv
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 6)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("background", UIKit.pill(Color(0.1, 0.153, 0.25), 3, Vector2.ZERO))
	bar.add_theme_stylebox_override("fill", UIKit.pill(UIKit.CYAN, 3, Vector2.ZERO))
	_hero_bar.add_child(bar)
	_hero_bar.add_child(UIKit.title(str(cap), 14, UIKit.SOFT))
	# LEVEL UP with the cost beside the coin, or what is in the way
	# one gold button: it opens the LEVEL UP sheet (stats now -> next, the cost, hold to repeat); at
	# his level cap it reads ASCEND, with a red dot when everything for the next rarity is in hand
	var can_ascend: bool = lv >= cap and Heroes.why_not_evolve(hero, id, data) == ""
	_level_btn.icon = null
	_level_btn.disabled = false
	_level_btn.text = "MAX" if (lv >= Heroes.MAX_LEVEL and t >= Gates.MAX_STAR) else ("ASCEND" if lv >= cap else "LEVEL UP")
	UIKit.dot(_level_btn, can_ascend)
	# the shard line: only the next star's shards (the rest is in Stats / the Evolve button)
	var need := Heroes.next_tier_cost(hero, id)
	_stars_l.text = ("%d / %d shards to the next star" % [Heroes.shards(hero, id), need]) if t < Gates.MAX_STAR else "Max stars"
	# the next milestone, small, under the bar
	var next_lv := ((lv / Heroes.MILESTONE_EVERY) + 1) * Heroes.MILESTONE_EVERY
	var ms := Heroes.milestone_at(next_lv)
	if not ms.is_empty():
		_stars_l.text += "   ·   Lv.%d: %s" % [next_lv, ms.text]

# a square side button on the hero page (Talents, Stats, Loadout): a dark rounded square with a
# drawn icon (the loadout's number) and its name under it
func _side_square(text: String, kind: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(56, 74)
	b.size = Vector2(56, 74)
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	b.draw.connect(func():
		var r := Rect2(0, 0, 56, 56)
		b.draw_style_box(UIKit.pill(Color(UIKit.CARD, 0.92), 18, Vector2.ZERO), r)
		var c := r.get_center()
		match kind:
			"talents":
				var pts := PackedVector2Array()
				for i in 10:
					var a := -PI / 2.0 + i * PI / 5.0
					pts.append(c + Vector2(cos(a), sin(a)) * (14.0 if i % 2 == 0 else 6.0))
				b.draw_colored_polygon(pts, UIKit.GOLD)
			"stats":
				for i in 4:
					var hgt: float = [10.0, 18.0, 13.0, 22.0][i]
					var x: float = c.x - 13.0 + i * 8.7
					b.draw_line(Vector2(x, c.y + 11.0), Vector2(x, c.y + 11.0 - hgt), UIKit.CYAN, 4.0, true)
			"wing":
				var wid := Heroes.wing(hero)
				if wid != "":
					b.draw_texture_rect(_hero_portrait(wid), Rect2(c - Vector2(22, 22), Vector2(44, 44)), false)
					b.draw_arc(c, 25.0, 0.0, TAU, 32, Heroes.element_color(Heroes.element_of(wid)), 2.0, true)
				else:
					b.draw_line(c + Vector2(-9, 0), c + Vector2(9, 0), UIKit.SOFT, 3.0, true)
					b.draw_line(c + Vector2(0, -9), c + Vector2(0, 9), UIKit.SOFT, 3.0, true)
			"ability":
				b.draw_texture_rect(UIKit.element_icon(Heroes.element_of(_view_id)), Rect2(c - Vector2(15, 18), Vector2(30, 30)), false)
				for i in 3:   # a pip per upgrade bought
					b.draw_circle(Vector2(c.x - 9.0 + i * 9.0, c.y + 19.0), 2.6, UIKit.GOLD if i < Heroes.ability_ups(hero, _view_id) else Color(1, 1, 1, 0.18))
			"loadout":
				var n := str(Loadouts.active(_read()) + 1)
				b.draw_string(UIKit.title_font(), Vector2(0, c.y + 9.0), n, HORIZONTAL_ALIGNMENT_CENTER, 56.0, 26, UIKit.CYAN)
		b.draw_string(get_theme_default_font(), Vector2(0, 70.0), text, HORIZONTAL_ALIGNMENT_CENTER, 56.0, 11, UIKit.SOFT))
	UIKit.press_fx(b)
	return b

func _on_level_up() -> bool:
	var data := _read()
	var id := _view_id
	if not Heroes.owned(hero, id):
		return false
	var before := Heroes.level(hero, id)
	if not Heroes.level_up(data, hero, id):
		return false
	coins = int(data.coins)
	data["hero"] = Heroes.write(hero)
	_write_data(data)
	Sfx.play("upgrade")
	Progress.bump("upgrades")
	var ms := Heroes.milestone_at(before + 1)
	if not ms.is_empty():
		_milestone_toast("%s reached Lv.%d: %s" % [Heroes.ROSTER[id].name, before + 1, ms.text])
	if _plat:
		_plat.flash()
	_paint_roster()
	_paint_hero()
	return true

# the DEF track: each level takes a little more off every hit (Heroes.DEF_PER, capped)
func _on_def_up() -> void:
	var data := _read()
	var id := _view_id
	if not Heroes.owned(hero, id) or not Heroes.def_up(data, hero, id):
		return
	coins = int(data.coins)
	data["hero"] = Heroes.write(hero)
	_write_data(data)
	Sfx.play("upgrade")
	Progress.bump("upgrades")
	if _plat:
		_plat.flash()
	_paint_hero()

func _on_evolve() -> void:
	var id := _view_id
	var data := _read()
	if not Heroes.evolve(hero, id, data):   # the level cap, shards, essences, coils, coins (Gates)
		var why := Heroes.why_not_evolve(hero, id, data)
		_toast(why if why != "" else "Not yet")
		return
	coins = int(data.get("coins", 0))
	data["hero"] = Heroes.write(hero)
	_write_data(data)
	Sfx.play("merge")
	if not UIKit.CLEAN:   # (the clean page shows the ASCEND moment instead)
		_toast("%s: %s" % [Heroes.ROSTER[id].name, Gates.step_name(Heroes.tier(hero, id))])
	if _plat:
		_plat.flash()
	_paint_roster()
	_paint_hero()

# buy the hero shown: coins + parts, or the crystal price
func _on_unlock(with_crystals: bool) -> void:
	var id := _view_id
	if Heroes.owned(hero, id):
		return
	var h: Dictionary = Heroes.ROSTER[id]
	var body := "%s\n\n%s" % [h.blurb, ("%d crystals" % Heroes.crystal_price(id)) if with_crystals else Heroes.cost_text(id)]
	if not await _confirm("UNLOCK %s?" % String(h.name).to_upper(), body, "Unlock", true):
		return
	var data := _read()
	var why := Heroes.unlock(data, hero, id, with_crystals)
	if why != "":
		_toast(why)
		return
	data["hero"] = Heroes.write(hero)
	_write_data(data)
	coins = int(data.get("coins", 0))
	Sfx.play("buy")
	Progress.bump("upgrades")
	_toast("%s joins the roster" % h.name)
	PilotRig.set_gear(data)
	if _plat:
		_plat.flash()
	_paint_roster()
	_paint_hero()
	_paint_suit()

# buy the turret in focus (dev172, the heroes model): coins + parts; when parts or coins are
# short, offer the crystal price instead
func _on_turret_unlock() -> void:
	var id := t_focus
	var def: Dictionary = Turrets.TURRETS[id]
	var data := _read()
	var t := {"owned": t_owned.duplicate()}
	var why := Turrets.unlock(data, t, id, false)
	if why != "":
		var price := Turrets.crystal_price(id)
		if why.begins_with("Clear stage") or price <= 0:
			_toast(why)
			return
		var ok := await _confirm("UNLOCK %s?" % String(def.name).to_upper(), "%s\n\nPrice: %s\n(%s)\n\nUse %d crystals instead? You have %d." % [def.desc, Turrets.cost_text(id), why, price, int(data.get("crystals", 0))], "Use %d crystals" % price, int(data.get("crystals", 0)) >= price)
		if not ok:
			return
		data = _read()
		t = {"owned": t_owned.duplicate()}
		why = Turrets.unlock(data, t, id, true)
		if why != "":
			_toast(why)
			return
	t_owned = t.owned
	t_stars = t.get("stars", {})
	data["turrets"] = {"loadout": t_loadout, "levels": t_levels, "tracks": t_tracks, "owned": t_owned, "stars": t_stars}
	_write_data(data)
	coins = int(data.get("coins", 0))
	Sfx.play("buy")
	Progress.bump("turret_upgrades")
	_toast("%s is yours" % def.name)
	_refresh_turrets()

# The HERO STAND (Rudy, dev172: no base under the heroes): a glowing hover disc the hero floats
# over. Code-drawn for now in the hero's element colour (the disc, an etched grid, a floating
# ring, a soft light column); Luna's painted layers (gear/stand_disc.png, stand_glow.png,
# stand_beam.png, LUNA-BRIEF-hero-stand.md) replace the code shapes the moment they exist.
# Same API as the old PlatformFloor: feet_y(), glow, glow_col, flash(), tiles.
class HeroStand extends Control:
	const FLOOR_UP := 40.0       # the disc's centre, up from the bottom of the stage
	const DISC_W := 300.0
	var tiles := {}
	var t := 0.0
	var glow := 0.0               # the hero's tier: 0 / 0.5 / 1 (brighter rings)
	var glow_col := Glass.CYAN
	var _flash := 0.0
	var _disc: Texture2D
	var _lights: Texture2D
	var _beam: Texture2D
	var _pool: Texture2D       # round 2 (orbit rings): the nebula pool and the two rings
	var _ring_a: Texture2D
	var _ring_b: Texture2D
	var _light_layer: Control
	func _ready() -> void:
		for spec in [["_disc", "stand_disc"], ["_lights", "stand_glow"], ["_beam", "stand_beam"], ["_pool", "stand_pool"], ["_ring_a", "stand_ring_a"], ["_ring_b", "stand_ring_b"]]:
			var p := "res://gear/%s.png" % spec[1]
			if ResourceLoader.exists(p):
				set(spec[0], load(p))
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
		_flash = maxf(_flash - delta * 1.6, 0.0)
		queue_redraw()
		_light_layer.queue_redraw()
	func _centre() -> Vector2:
		return Vector2(size.x * 0.5, size.y - FLOOR_UP)
	func _radii() -> Vector2:
		var rx := minf(size.x * 0.36, DISC_W * 0.5)
		return Vector2(rx, rx * 0.36)
	# where his feet hover: a little above the disc
	func feet_y() -> float:
		return _centre().y - _radii().y * 0.6
	func _draw() -> void:
		var c := _centre()
		var r := _radii()
		if _pool:
			# ROUND 2 (Rudy: no disc, no grid): the hero is the planet. Luna's nebula pool breathes under
			# him on this layer; the rings, the beads and the column go on the additive layer
			var w := _v2_w(r)
			var h := w * 0.5
			var br := 1.0 + 0.03 * sin(t * 0.9)
			draw_set_transform(c, 0.0, Vector2(br, br))
			draw_texture_rect(_pool, Rect2(-w * 0.5, -h * 0.5, w, h), false, Color(glow_col, 1.0).lerp(Color(0.9, 0.92, 1.0, 1.0), 0.55))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		elif _disc:
			# blended in (Rudy: it did not sit in the world): a soft dark halo under it fading into
			# the wallpaper, the disc itself a little smaller and see-through
			draw_set_transform(c + Vector2(0, 8.0), 0.0, Vector2(1.0, 0.4))
			for k in 4:
				draw_circle(Vector2.ZERO, r.x * (1.55 - 0.2 * k), Color(0.0, 0.01, 0.04, 0.16))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			var w := r.x * 2.0 * 0.98
			var h := w * _disc.get_height() / _disc.get_width()
			draw_texture_rect(_disc, Rect2(c.x - w * 0.5, c.y - h * 0.5, w, h), false, Color(0.85, 0.9, 1.0, 0.82))
		else:
			# the disc: a dark glass ellipse with a metal rim, a thin lighter edge on top
			draw_set_transform(c, 0.0, Vector2(1.0, r.y / r.x))
			draw_circle(Vector2(0, 6), r.x * 1.02, Color(0.02, 0.03, 0.07, 0.9))   # the underside
			draw_circle(Vector2.ZERO, r.x, Color(0.05, 0.08, 0.16, 0.95))
			draw_arc(Vector2.ZERO, r.x, 0.0, TAU, 72, Color(0.5, 0.62, 0.8, 0.55), 2.0, true)
			draw_arc(Vector2.ZERO, r.x * 0.86, 0.0, TAU, 64, Color(glow_col, 0.25), 1.0, true)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# thin lines from the slot tiles to the disc (the weapon tile)
		for s in tiles:
			var b: Button = tiles[s]
			if not is_instance_valid(b):
				continue
			var from := b.position + Vector2(b.size.x * 0.5, b.size.y)
			draw_line(from, Vector2(c.x - r.x * 0.7, c.y), Color(glow_col, 0.18), 1.0, true)
	# ---- round 2: orbit rings (Luna's -v2 layers, dev188) ----
	# the three flat layers (1024 x 512 as rendered) are drawn in one rectangle `w` wide centred
	# on c, so they stack exactly as she painted them; the rings' ellipses measured by the cutter
	const RING_A := [0.501, 0.471, 0.428, 0.245]   # centre x, y and radii, as shares of the picture
	const RING_B := [0.499, 0.484, 0.282, 0.168]
	const BEAM_W := 0.447                            # the cut column's width as a share of the picture
	func _v2_w(r: Vector2) -> float:
		return r.x * 1.1 / 0.442   # the outer ring a little wider than the old disc
	func _draw_v2_lights(c: Vector2, r: Vector2, k: float) -> void:
		var w := _v2_w(r)
		var h := w * 0.5
		var rect := Rect2(c.x - w * 0.5, c.y - h * 0.5, w, h)
		var L := _light_layer
		if _beam:
			var bw := w * BEAM_W
			var bh := bw * _beam.get_height() / _beam.get_width()
			L.draw_texture_rect(_beam, Rect2(c.x - bw * 0.5, c.y + h * 0.02 - bh, bw, bh), false, Color(glow_col, 0.42 * k))
		if _ring_a:
			L.draw_texture_rect(_ring_a, rect, false, Color(glow_col, clampf(0.7 * k + 0.12 * sin(t * 1.3), 0.0, 1.0)))
		if _ring_b:
			L.draw_texture_rect(_ring_b, rect, false, Color(glow_col, clampf(0.6 * k + 0.12 * sin(t * 1.3 + 2.0), 0.0, 1.0)))
		# the beads travel round each ring, bright and larger along the front, faint behind him
		for spec in [[RING_A, 6, 0.35], [RING_B, 4, -0.55]]:
			var g: Array = spec[0]
			var cen := Vector2(rect.position.x + g[0] * w, rect.position.y + g[1] * h)
			var rad := Vector2(g[2] * w, g[3] * h)
			var n: int = spec[1]
			for i in n:
				var a: float = t * spec[2] + TAU * i / n
				var p := cen + Vector2(cos(a) * rad.x, sin(a) * rad.y)
				var front: float = 0.5 + 0.5 * sin(a)   # 1 at the front of the ring (lower on screen)
				var al: float = k * (0.25 + 0.7 * front)
				L.draw_circle(p, 1.6 + 2.6 * front, Color(glow_col, al * 0.35))
				L.draw_circle(p, 0.9 + 1.2 * front, Color(1.0, 1.0, 1.0, al))
	func _draw_lights() -> void:
		var c := _centre()
		var r := _radii()
		var k: float = 0.55 + 0.25 * glow + 0.2 * sin(t * 2.0) + _flash * 0.8
		var col := Color(glow_col, clampf(k, 0.0, 1.0))
		if _pool:
			_draw_v2_lights(c, r, k)
			return
		if _beam:
			var bw := r.x * 2.2
			var bh := bw * _beam.get_height() / _beam.get_width()
			_light_layer.draw_texture_rect(_beam, Rect2(c.x - bw * 0.5, c.y - bh, bw, bh), false, Color(glow_col, 0.35 * k))
		else:
			# the light column: a soft cone fading up from the disc
			var top: float = c.y - size.y * 0.78
			_light_layer.draw_polygon(PackedVector2Array([Vector2(c.x - r.x * 0.9, c.y), Vector2(c.x + r.x * 0.9, c.y), Vector2(c.x + r.x * 0.45, top), Vector2(c.x - r.x * 0.45, top)]),
				PackedColorArray([Color(glow_col, 0.16 * k), Color(glow_col, 0.16 * k), Color(glow_col, 0.0), Color(glow_col, 0.0)]))
		if _lights:
			var w := r.x * 2.0 * 0.98
			var h := w * _lights.get_height() / _lights.get_width()
			_light_layer.draw_texture_rect(_lights, Rect2(c.x - w * 0.5, c.y - h * 0.5, w, h), false, col)
			return
		_light_layer.draw_set_transform(c, 0.0, Vector2(1.0, r.y / r.x))
		# the etched grid: rings and spokes, faint
		for i in 3:
			_light_layer.draw_arc(Vector2.ZERO, r.x * (0.3 + 0.25 * i), 0.0, TAU, 48, Color(glow_col, 0.12 * k), 1.0, true)
		for i in 8:
			var a := TAU * i / 8.0 + t * 0.15
			_light_layer.draw_line(Vector2.ZERO, Vector2.from_angle(a) * r.x * 0.84, Color(glow_col, 0.08 * k), 1.0, true)
		# the rim light and a holographic ring floating above it, slowly turning
		_light_layer.draw_arc(Vector2.ZERO, r.x, 0.0, TAU, 72, Color(glow_col, 0.5 * k), 2.5, true)
		var ring_y: float = -r.x * 0.16 - sin(t * 1.3) * r.x * 0.02
		var a0 := t * 0.6
		for seg in 6:
			var s0 := a0 + TAU * seg / 6.0
			_light_layer.draw_arc(Vector2(0, ring_y), r.x * 0.92, s0, s0 + TAU / 6.0 * 0.7, 16, Color(glow_col, 0.7 * k), 2.0, true)
		# a few specks rising in the column
		for i in 7:
			var ph := fmod(t * 0.25 + i * 0.137, 1.0)
			var px := sin(i * 2.1 + t * 0.7) * r.x * 0.5
			_light_layer.draw_circle(Vector2(px, -ph * r.x * 2.4 / (r.y / r.x)), 1.6, Color(glow_col, (1.0 - ph) * 0.5 * k))
		_light_layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# dev capture hook (tools/dev/capture.gd CAP_CALL="_dbg_swivel|0.8"): turn the showcase hero
func _dbg_swivel(v: String) -> void:
	if _showcase:
		_showcase.swivel = float(v)
		_showcase._idle = -999.0
		_showcase._hint = 0.0

# buy a drone body (round 2, dev184): coins + parts, or the crystal price when short
func _on_drone_unlock(body: String) -> void:
	var def: Dictionary = DroneData.BODIES[body]
	var data := _read()
	var dr := DroneData.read(data)
	var why := DroneData.unlock(data, dr, body, false)
	if why != "":
		var price := DroneData.crystal_price(body)
		if price <= 0:
			_toast(why)
			return
		var ok := await _confirm("UNLOCK %s?" % String(def.name).to_upper(), "%s\n\nPrice: %s\n(%s)\n\nUse %d crystals instead? You have %d." % [def.desc, DroneData.cost_text(body), why, price, int(data.get("crystals", 0))], "Use %d crystals" % price, int(data.get("crystals", 0)) >= price)
		if not ok:
			return
		data = _read()
		dr = DroneData.read(data)
		why = DroneData.unlock(data, dr, body, true)
		if why != "":
			_toast(why)
			return
	dr.body = body
	drone = dr
	data["drone"] = dr
	_write_data(data)
	coins = int(data.get("coins", 0))
	Sfx.play("buy")
	Progress.bump("upgrades")
	_toast("%s joins the hangar" % def.name)
	_refresh_drone()

# WEAPONS screen (Rudy, dev186): tapping the weapon tile opens your weapon inventory, a card
# per weapon you own (picture, name, element, level, rarity), grouped by element, tap to
# equip. The old CHOOSE grid under the hero is gone.
# The STAR MAP (Rudy, 2026-11-06: the talent map as a galactic chart, not a list). The forty
# nodes are stars along a winding route through four sectors of space; bought stars shine in
# their sector's colour, the next one pulses cyan, the rest wait dim; every 10th node is a star
# SYSTEM (the card node). Tap a star to read it; the panel below buys the next one. Everything
# is drawn in code today; Luna's pieces replace the code stars and nebulae when they land
# (talents/node_dim|lit|next.png, system_dim|lit|next.png, nebula_0..3.png; LUNA-BRIEF-talent-map.md).
class StarMap extends Control:
	const SECTOR_H := 540.0
	const TOP := 54.0
	const STEP := 46.0
	const BLEND := 260.0   # the gradient between two constellations' skies
	# four CONSTELLATIONS of ten stars (Rudy): each a figure from the game, charted star by star
	# in the order the lines are drawn; the tenth star is the figure's key point and the card
	const SECTORS := [
		{"name": "THE RIFLE",       "col": Color(0.2, 0.85, 1.0),  "lore": "Every cadet of the Guard learns to shoot before learning to fly."},
		{"name": "THE SENTRY",      "col": Color(0.45, 1.0, 0.5),  "lore": "The first gun on the deck. It never sleeps."},
		{"name": "THE HIVE MOTHER", "col": Color(0.75, 0.5, 1.0),  "lore": "Charted the night she first came out of the dark."},
		{"name": "THE DOME",        "col": Color(1.0, 0.8, 0.3),   "lore": "Home. Everything the Guard has ever defended."},
	]
	# the ten stars of each figure, as shares of the sector's box, in charting order
	const SHAPES := [
		[Vector2(0.10, 0.80), Vector2(0.20, 0.72), Vector2(0.25, 0.88), Vector2(0.31, 0.67), Vector2(0.42, 0.61), Vector2(0.52, 0.56), Vector2(0.63, 0.50), Vector2(0.74, 0.44), Vector2(0.84, 0.38), Vector2(0.92, 0.28)],
		[Vector2(0.30, 0.88), Vector2(0.50, 0.93), Vector2(0.70, 0.88), Vector2(0.53, 0.76), Vector2(0.50, 0.62), Vector2(0.38, 0.52), Vector2(0.62, 0.52), Vector2(0.46, 0.38), Vector2(0.60, 0.26), Vector2(0.70, 0.12)],
		[Vector2(0.50, 0.92), Vector2(0.50, 0.76), Vector2(0.34, 0.66), Vector2(0.12, 0.54), Vector2(0.38, 0.54), Vector2(0.62, 0.54), Vector2(0.88, 0.54), Vector2(0.66, 0.66), Vector2(0.50, 0.42), Vector2(0.50, 0.22)],
		[Vector2(0.08, 0.84), Vector2(0.27, 0.86), Vector2(0.46, 0.86), Vector2(0.65, 0.86), Vector2(0.86, 0.84), Vector2(0.82, 0.62), Vector2(0.70, 0.42), Vector2(0.50, 0.32), Vector2(0.28, 0.42), Vector2(0.50, 0.12)],
	]
	var have := 0
	var nxt := 1
	var picked := 1
	var map_w := 480.0
	var t := 0.0
	var _dots: Array = []
	var _tex := {}

	func _init(width: float) -> void:
		map_w = width
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		for i in 240:
			_dots.append({"pos": Vector2(rng.randf() * width, rng.randf() * (TOP + SECTOR_H * 4.0 + 80.0)), "r": rng.randf_range(0.6, 1.8), "ph": rng.randf() * TAU})
		for n in ["node_dim", "node_lit", "node_next", "system_dim", "system_lit", "system_next"]:
			if ResourceLoader.exists("res://talents/%s.png" % n):
				_tex[n] = load("res://talents/%s.png" % n)
		for s in 4:
			if ResourceLoader.exists("res://talents/nebula_%d.png" % s):
				_tex["nebula_%d" % s] = load("res://talents/nebula_%d.png" % s)
		custom_minimum_size = Vector2(0, TOP + SECTOR_H * 4.0 + 80.0)
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	# where star n (1-based) sits: its constellation's figure, scaled into the sector's box
	static func node_pos(n: int, width: float) -> Vector2:
		var s: int = clampi((n - 1) / 10, 0, 3)
		var i: int = (n - 1) % 10
		var pt: Vector2 = SHAPES[s][i]
		# shares of the WHOLE sector box, the same frame Luna painted the figure lines in
		# (LUNA-BRIEF-talent-map.md), so her ghost figures pass through the stars
		return Vector2(pt.x * width, TOP + s * SECTOR_H + pt.y * SECTOR_H)

	static func sector_of(n: int) -> int:
		return clampi((n - 1) / 10, 0, 3)

	func _draw() -> void:
		var w := map_w
		# space: each constellation's sky in its own dark tint, and between two constellations a
		# long gradient from one tint into the next (Rudy: no dividing lines, a seamless blend)
		var H: float = TOP + SECTOR_H * 4.0 + 80.0
		var skies: Array = []
		for s in 4:
			var col: Color = SECTORS[s].col
			skies.append(Color(0.012 + 0.02 * col.r, 0.014 + 0.02 * col.g, 0.03 + 0.035 * col.b))
		draw_rect(Rect2(0, 0, w, H), skies[0])
		for s in range(1, 4):
			var yb: float = TOP + s * SECTOR_H   # the boundary
			var y1: float = yb - BLEND * 0.5
			var y2: float = yb + BLEND * 0.5
			draw_polygon(PackedVector2Array([Vector2(0, y1), Vector2(w, y1), Vector2(w, y2), Vector2(0, y2)]),
				PackedColorArray([skies[s - 1], skies[s - 1], skies[s], skies[s]]))
			draw_rect(Rect2(0, y2, w, H - y2), skies[s])
		for s in 4:
			var col: Color = SECTORS[s].col
			var y0: float = TOP + s * SECTOR_H
			if _tex.has("nebula_%d" % s):
				# Luna's sky exactly over the sector box (her figure lines meet the stars there); it
				# fades to black at its edges, and the gradient underneath carries the blend
				draw_texture_rect(_tex["nebula_%d" % s], Rect2(0, y0, w, SECTOR_H), false, Color(1, 1, 1, 0.95))
			else:
				Backdrop.soft_glow(self, Vector2(w * (0.28 + 0.44 * (s % 2)), y0 + SECTOR_H * 0.42), w * 0.6, Color(col, 0.16))
				Backdrop.soft_glow(self, Vector2(w * (0.7 - 0.4 * (s % 2)), y0 + SECTOR_H * 0.8), w * 0.35, Color(col.lerp(Color(1, 0.6, 0.9), 0.4), 0.1))
		for d in _dots:
			draw_circle(d.pos, float(d.r), Color(1, 1, 1, 0.3 + 0.35 * (0.5 + 0.5 * sin(t * 1.4 + float(d.ph)))))
		# the figure lines: charted (gold), the next leg (cyan, dashes travelling), the legs ahead
		# (faint dots); between two constellations a long faint jump
		for n in range(1, Talents.SIZE):
			var a := node_pos(n, w)
			var b := node_pos(n + 1, w)
			if n % 10 == 0:
				var L := a.distance_to(b)
				var k := 0.0
				while k < L:
					draw_circle(a.lerp(b, k / L), 1.0, Color(UIKit.GOLD if n < have else Color(0.7, 0.78, 0.95), 0.22))
					k += 14.0
				continue
			if n < have:
				draw_line(a, b, Color(UIKit.GOLD, 0.18), 6.0, true)
				draw_line(a, b, Color(UIKit.GOLD, 0.85), 2.0, true)
			elif n == have:
				var dir := (b - a).normalized()
				var L := a.distance_to(b)
				var off := fmod(t * 40.0, 16.0)
				var x := off
				while x < L:
					draw_line(a + dir * x, a + dir * minf(x + 8.0, L), Color(UIKit.CYAN, 0.9), 2.0, true)
					x += 16.0
			else:
				var L := a.distance_to(b)
				var k := 0.0
				while k < L:
					draw_circle(a.lerp(b, k / L), 1.2, Color(0.7, 0.78, 0.95, 0.28))
					k += 9.0
		# the stars
		for n in range(1, Talents.SIZE + 1):
			var p := node_pos(n, w)
			var c := Talents.node(n)
			var system: bool = String(c.card) != ""
			var scol: Color = SECTORS[sector_of(n)].col
			var pulse: float = 0.5 + 0.5 * sin(t * 3.0 + float(n))
			if n <= have:
				_star(p, 30.0 if system else 20.0, scol, 1.0, "system_lit" if system else "node_lit", system)
			elif n == nxt:
				_star(p, (30.0 if system else 20.0) * (1.0 + 0.08 * pulse), UIKit.CYAN, 0.8 + 0.2 * pulse, "system_next" if system else "node_next", system)
				draw_arc(p, (24.0 if system else 16.0) + 4.0 * pulse, 0.0, TAU, 40, Color(UIKit.CYAN, 0.5 + 0.4 * pulse), 1.5, true)
			else:
				_star(p, 24.0 if system else 14.0, Color(0.55, 0.6, 0.75), 0.5, "system_dim" if system else "node_dim", system)
			if n == picked:
				draw_arc(p, (28.0 if system else 19.0), 0.0, TAU, 40, Color(1, 1, 1, 0.85), 1.5, true)

	# a star: Luna's piece when it exists, else a glow, a four-point star and a bright core;
	# a star SYSTEM adds a planet ring
	func _star(p: Vector2, px: float, col: Color, a: float, tex_name: String, system: bool) -> void:
		if _tex.has(tex_name):
			var tx: Texture2D = _tex[tex_name]
			# Luna's white star takes the constellation's tint once charted (lit), stays white while next
			var tint: Color = col.lerp(Color.WHITE, 0.35) if tex_name.ends_with("_lit") else Color.WHITE
			draw_texture_rect(tx, Rect2(p - Vector2(px, px), Vector2(px, px) * 2.0), false, Color(tint, a))
			return
		var r: float = px * 0.5
		Backdrop.soft_glow(self, p, r * 3.0, Color(col, a * 0.45))
		if system:
			draw_set_transform(p, -0.5, Vector2(1.0, 0.38))
			draw_arc(Vector2.ZERO, r * 1.7, 0.0, TAU, 48, Color(col.lerp(Color.WHITE, 0.3), a * 0.8), 1.5, true)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_circle(p, r * 0.75, Color(col.lerp(Color.BLACK, 0.35), a))
			draw_circle(p, r * 0.75, Color(col.lerp(Color.WHITE, 0.4), a * 0.5))
			draw_circle(p + Vector2(-r * 0.25, -r * 0.25), r * 0.3, Color(1, 1, 1, a * 0.6))
			return
		var pts := PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.28, -r * 0.28), p + Vector2(r, 0), p + Vector2(r * 0.28, r * 0.28),
			p + Vector2(0, r), p + Vector2(-r * 0.28, r * 0.28), p + Vector2(-r, 0), p + Vector2(-r * 0.28, -r * 0.28)])
		draw_colored_polygon(pts, Color(col.lerp(Color.WHITE, 0.45), a))
		draw_circle(p, r * 0.3, Color(1, 1, 1, a))

var _talent_btn: Button

func _talents_screen() -> void:
	var layer := ColorRect.new()
	layer.color = Color(0.008, 0.01, 0.03, 1.0)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var data := _read()
	var have := Talents.count(data)
	var nxt := Talents.next(data)
	var w := size.x
	var page := VBoxContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("separation", 0)
	layer.add_child(page)
	# header
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var back := UIKit.ghost_button("Back", 12)
	back.custom_minimum_size = Vector2(70, 34)
	back.pressed.connect(layer.queue_free)
	head.add_child(back)
	var title := UIKit.popup_title("STAR MAP  ·  %d / %d" % [have, Talents.SIZE])
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(70, 0)
	head.add_child(spacer)
	var hp := UIKit.panel(6)
	hp.add_child(head)
	page.add_child(hp)
	# the chart
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var map := StarMap.new(w)
	map.have = have
	map.nxt = nxt
	map.picked = mini(nxt, Talents.SIZE)
	map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(map)
	page.add_child(sc)
	# the detail panel: the star picked (the next one at first) and the one button
	var dp := UIKit.panel(10)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 4)
	var dname := UIKit.label("", 14, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	var dtext := UIKit.label("", 12, Color(0.85, 0.92, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	dtext.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dtext.custom_minimum_size = Vector2(0, 48)
	dv.add_child(dname)
	dv.add_child(dtext)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var why := Talents.why_not(data)
	var buy := UIKit.gold_button(("CHART STAR %d  ·  %s" % [nxt, Talents.cost_text(nxt)]) if why == "" else (why if nxt <= Talents.SIZE else "Map complete"), 15)
	buy.custom_minimum_size = Vector2(0, 46)
	buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy.disabled = why != ""
	buy.pressed.connect(func():
		var d2 := _read()
		var err := Talents.buy(d2)
		if err != "":
			_toast(err)
			return
		_write_data(d2)
		coins = int(d2.get("coins", 0))
		Sfx.play("upgrade")
		Progress.bump("upgrades")
		var bought := Talents.count(d2)
		_toast("Star %d charted: %s" % [bought, Talents.text(bought)])
		layer.queue_free()
		_paint_hero()
		_talents_screen())
	row.add_child(buy)
	dv.add_child(row)
	dp.add_child(dv)
	page.add_child(dp)
	var show := func(n: int):
		map.picked = n
		var c := Talents.node(n)
		var state := "charted" if n <= have else ("next" if n == nxt else "ahead")
		dname.text = "STAR %d  ·  %s  ·  %s" % [n, String(StarMap.SECTORS[StarMap.sector_of(n)].name).capitalize(), state]
		dtext.text = "%s\n%s%s" % [Talents.text(n), Talents.cost_text(n), "" if n <= have else "  ·  pilot Lv.%d" % Talents.door(n)]
		if String(c.card) != "":
			dtext.text += "\n%s: %s" % [Cards.CARDS[c.card].name, Cards.CARDS[c.card].desc]
	# a tap target and a tag under every star, and a name over every sector
	for n in range(1, Talents.SIZE + 1):
		var p := StarMap.node_pos(n, w)
		var c := Talents.node(n)
		var b := Button.new()
		b.flat = true
		b.position = p - Vector2(24, 24)
		b.size = Vector2(48, 48)
		b.focus_mode = Control.FOCUS_NONE
		var nn: int = n
		b.pressed.connect(func(): show.call(nn))
		map.add_child(b)
		var tag := UIKit.label("%s %s" % [c.tag, Talents.bonus_text(n)], 9, UIKit.GOLD if n <= have else (UIKit.CYAN if n == nxt else UIKit.MUTED), HORIZONTAL_ALIGNMENT_CENTER)
		tag.position = p + Vector2(-44, 16.0 if String(c.card) == "" else 22.0)
		tag.size = Vector2(88, 14)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map.add_child(tag)
	for s in 4:
		var sl := UIKit.label(String(StarMap.SECTORS[s].name), 12, StarMap.SECTORS[s].col, HORIZONTAL_ALIGNMENT_CENTER)
		sl.position = Vector2(0, StarMap.TOP + s * StarMap.SECTOR_H + 14.0)
		sl.size = Vector2(w, 16)
		sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map.add_child(sl)
		var sub := UIKit.label(String(StarMap.SECTORS[s].lore), 9, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		sub.position = Vector2(0, StarMap.TOP + s * StarMap.SECTOR_H + 32.0)
		sub.size = Vector2(w, 12)
		sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map.add_child(sub)
	show.call(mini(nxt, Talents.SIZE))
	# open on the next star
	await get_tree().process_frame
	if is_instance_valid(sc):
		sc.scroll_vertical = maxi(0, int(StarMap.node_pos(mini(nxt, Talents.SIZE), w).y - size.y * 0.38))

func _weapons_screen() -> void:
	var layer := ColorRect.new()
	layer.color = Color(0, 0.01, 0.04, 0.78)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.gui_input.connect(func(ev): if (ev is InputEventMouseButton or ev is InputEventScreenTouch) and ev.pressed: layer.queue_free())
	add_child(layer)
	var p := UIKit.popup_panel()
	var w := minf(size.x - 24.0, 420.0)
	p.custom_minimum_size = Vector2(w, 0)
	p.position = Vector2((size.x - w) * 0.5, 50.0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.add_child(UIKit.title("Weapons", 22, UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	Hints.show(self, ["weapon"])
	var eq: String = gear.equipped["Weapon"]
	var eq_el: String = GearData.ITEMS[eq].set
	v.add_child(UIKit.iconed(UIKit.element_icon(eq_el), "%s  ·  Lv.%d  ·  %s" % [GearData.ITEMS[eq].name, _lvl(eq), GearData.rarity_name(GearData.rarity(gear, eq))], 12, Heroes.element_color(eq_el)))
	# how the weapon in hand shoots (GearData.WEAPON_STYLE): the six play differently
	var est: Dictionary = GearData.weapon_style(eq)
	if not est.is_empty():
		var srow := HBoxContainer.new()
		srow.alignment = BoxContainer.ALIGNMENT_CENTER
		srow.add_theme_constant_override("separation", 8)
		srow.add_child(UIKit.chip(String(est.style), Heroes.element_color(eq_el)))
		var now_fi: Dictionary = GearData.form_info(eq, GearData.weapon_form(_lvl(eq)))   # form II / III: say what it does NOW
		srow.add_child(UIKit.label(String(now_fi.get("text", est.text)), 12, UIKit.TEXT))
		v.add_child(srow)
	# its three shapes (GearData.WEAPON_FORMS): the one it is in lit, the next with its level
	var form_now := GearData.weapon_form(_lvl(eq))
	var frow := HBoxContainer.new()
	frow.alignment = BoxContainer.ALIGNMENT_CENTER
	frow.add_theme_constant_override("separation", 6)
	for f in [1, 2, 3]:
		var fname: String = String(est.get("style", "")) if f == 1 else String(GearData.form_info(eq, f).get("name", ""))
		var fc := UIKit.chip("%s  %s" % [GearData.FORM_NAMES[f - 1], fname], UIKit.GOLD if f == form_now else (Heroes.element_color(eq_el) if f < form_now else UIKit.SOFT))
		fc.modulate.a = 1.0 if f <= form_now else 0.6
		frow.add_child(fc)
	v.add_child(frow)
	if form_now < 3:
		var nf: Dictionary = GearData.form_info(eq, form_now + 1)
		var nl := UIKit.label("Next shape at Lv.%d: %s" % [int(GearData.FORM_LEVELS[form_now]), String(nf.get("text", ""))], 11, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(nl)
	elif form_now == 3:
		v.add_child(UIKit.label(String(GearData.form_info(eq, 3).get("text", "")), 11, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for set_id in GearData.SET_ORDER:
		var id: String = "%s_weapon" % set_id
		var info: Dictionary = GearData.ITEMS[id]
		var open := GearData.set_unlocked(set_id, t_unlocked) or GearData.owned(gear, id)
		var rn := GearData.rarity_name(GearData.rarity(gear, id))
		var sub := ("Lv.%d · %s" % [_lvl(id), rn]) if open else "Stage %d" % (int(GearData.SETS[set_id].unlock_stage) - 1)
		var wst: Dictionary = GearData.weapon_style(id)
		var t := _pick_square(_pic(id), String(info.name), 118.0, id == eq, UIKit.RARITY[set_id], not open, String(wst.get("style", "")) if open else sub)
		UIKit.corner_icon(t, UIKit.element_icon(set_id), 20.0)
		var item: String = id
		t.pressed.connect(func():
			if open:
				_equip(item)
				layer.queue_free()
				_weapons_screen())
		grid.add_child(t)
	v.add_child(grid)
	# the equipped weapon's details and its Upgrade button (the same ones the Hero page kept)
	var urow := HBoxContainer.new()
	urow.add_theme_constant_override("separation", 8)
	var ul := UIKit.label(_detail.text, 11, Color(0.85, 0.92, 1.0))
	ul.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ul.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	urow.add_child(ul)
	var ub := UIKit.gold_button(_upgrade_btn.text, 12)
	ub.custom_minimum_size = Vector2(110, 46)
	ub.disabled = _upgrade_btn.disabled
	ub.pressed.connect(func():
		var item_was: String = gear.equipped["Weapon"]
		var form_was := GearData.weapon_form(_lvl(item_was))
		await _on_upgrade_pressed()
		layer.queue_free()
		_weapons_screen()
		var form_is := GearData.weapon_form(_lvl(item_was))
		if form_is > form_was:   # it changed shape: say so, full screen
			var fi: Dictionary = GearData.form_info(item_was, form_is)
			Moment.show(self, {"title": "%s %s" % [String(GearData.ITEMS[item_was].name), GearData.FORM_NAMES[form_is - 1]],
				"text": "%s: %s." % [String(fi.get("name", "")), String(fi.get("text", ""))], "tex": _pic(item_was),
				"col": Heroes.element_color(String(GearData.ITEMS[item_was].set)), "chip": "EVOLVED", "go_text": "GOT IT"}))
	urow.add_child(ub)
	v.add_child(urow)
	v.add_child(UIKit.label("Spare copies merge in the Workshop.", 11, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	v.get_child(v.get_child_count() - 1).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var close := UIKit.ghost_button("Close", 13)
	close.custom_minimum_size = Vector2(0, 38)
	close.pressed.connect(layer.queue_free)
	v.add_child(close)
	p.add_child(v)
	layer.add_child(p)

# ------------------------------------------------------------------ Workshop > CRAFT (materials.gd, dev189)
# Rudy's crafting bench: what you own, then one card per recipe (what it makes, what it needs
# with have / need counts, a Craft button). The essence recipe lets you pick the element.
func _refresh_ws_craft() -> void:
	for c in _ws_craft_box.get_children():
		c.queue_free()
	if UIKit.CLEAN:
		_refresh_ws_craft_clean()
		return
	var data := _read()
	var have := Parts.read(data)
	_ws_craft_box.add_child(UIKit.header("YOUR MATERIALS"))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 6)
	var shown := 0
	for k in Materials.ORDER:
		if int(have.get(k, 0)) <= 0:
			continue
		flow.add_child(UIKit.iconed(Materials.icon(k), "%s  x%d" % [Materials.name_of(k), int(have[k])], 11, Materials.color_of(k), 20.0))
		shown += 1
	if shown == 0:
		var hint := UIKit.label("None yet. Boss stages and Elite wins drop that planet's essence, element trials their own, Horde and Patrol drop barrels and rotors. Or craft them here.", 11, UIKit.MUTED)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_ws_craft_box.add_child(hint)
	else:
		_ws_craft_box.add_child(flow)
	_ws_craft_box.add_child(UIKit.header("CRAFT"))
	for r in Materials.RECIPES:
		var rec: Dictionary = r
		var mk := Materials.makes(rec, _craft_el)
		var mk_id := String(mk.keys()[0])
		var p := UIKit.panel(10)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 5)
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 8)
		top.add_child(_part_icon(mk_id, 40))
		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_theme_constant_override("separation", 1)
		tv.add_child(UIKit.label("%s  x%d" % [Materials.name_of(mk_id), int(mk[mk_id])], 14, Materials.color_of(mk_id)))
		var d := UIKit.label(String(rec.desc), 10, UIKit.MUTED)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tv.add_child(d)
		top.add_child(tv)
		v.add_child(top)
		# what it needs, have / need, green when you have it
		var nrow := HFlowContainer.new()
		nrow.add_theme_constant_override("h_separation", 10)
		for k in rec.needs:
			var hv := int(have.get(k, 0))
			var nd := int(rec.needs[k])
			nrow.add_child(UIKit.iconed(_part_tex(String(k)), "%d / %d" % [hv, nd], 11, Color(0.55, 1.0, 0.6) if hv >= nd else Color(1.0, 0.5, 0.55), 18.0))
		var cc := int(rec.get("coins", 0))
		if cc > 0:
			nrow.add_child(UIKit.iconed(UIKit.ic("ic_coin"), UIKit.num(cc), 11, Color.WHITE if coins >= cc else Color(1.0, 0.5, 0.55), 18.0))
		v.add_child(nrow)
		# the essence recipe: pick the element
		if rec.get("pick", false):
			var erow := HBoxContainer.new()
			erow.add_theme_constant_override("separation", 4)
			for el in Heroes.ELEMENTS:
				var b := UIKit.ghost_button("", 11)
				b.icon = UIKit.element_icon(String(el))
				b.expand_icon = true
				b.custom_minimum_size = Vector2(44, 36)
				b.modulate = Color(1, 1, 1, 1.0 if String(el) == _craft_el else 0.45)
				var elid := String(el)
				b.pressed.connect(func():
					_craft_el = elid
					_refresh_ws_craft())
				erow.add_child(b)
			v.add_child(erow)
		var btn := UIKit.gold_button("Craft", 13)
		btn.custom_minimum_size = Vector2(0, 38)
		btn.disabled = not Materials.can_craft(data, rec)
		btn.pressed.connect(func(): _craft(rec))
		v.add_child(btn)
		p.add_child(v)
		_ws_craft_box.add_child(p)

func _part_tex(k: String) -> Texture2D:
	return Materials.icon(k) if Materials.is_material(k) else Parts.icon(k)

func _craft(r: Dictionary) -> void:
	var data := _read()
	var why := Materials.craft(data, r, _craft_el)
	if why != "":
		_toast(why)
		return
	_write_data(data)
	coins = int(data.get("coins", 0))
	_paint_wallet()
	Sfx.play("merge")
	Progress.bump("merges")
	var mk := Materials.makes(r, _craft_el)
	_toast("Crafted: %s" % Materials.name_of(String(mk.keys()[0])))
	_refresh_ws_craft()

# ------------------------------------------------------------------ LEVEL UP sheet + ASCEND (2026-11-10)
# Rudy (dev209 playtest + the go-ahead of 2026-11-10): the Hero page shows only the name, rarity,
# element, ATK and level; LEVEL UP opens this sheet. It slides up like the chest sheet in the Store:
# the face of the hero, his place on the rarity ladder (ten pips), the level bar, three stats as
# "now -> next", the next perk, the cost. HOLD the gold button to keep levelling. At the level cap
# the same sheet turns into ASCEND: the next rarity, what it unlocks, what it asks for (have / need),
# and a full-screen moment when he steps up.
var _lv_ui := {}            # the nodes of the sheet while it is open
var _lvl_layer: Control
var _lvl_token := 0       # a new number every press: an old hold loop stops
var _lvl_did := false     # this press levelled him (so releasing on a fresh ASCEND button does nothing)
const GOOD := Color(0.44, 0.94, 0.72)
const SHORT := Color(1.0, 0.55, 0.55)

func _on_level_btn() -> void:
	if UIKit.CLEAN:
		_level_sheet()
	else:
		_on_level_up()

# his battle stats if he were `dlevel` levels and `dstep` rarity steps further on
func _hero_preview(id: String, dlevel: int, dstep: int) -> Dictionary:
	var data := _read().duplicate(true)
	var hh: Dictionary = hero.duplicate(true)
	hh.selected = id
	hh.levels[id] = Heroes.level(hero, id) + dlevel
	hh.tiers[id] = Heroes.ascends(hero, id) + dstep
	data["hero"] = Heroes.write(hh)
	return Heroes.stats(data)

func _lvl_row(icon: Texture2D, name: String, a: String, b: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.pill(Color(UIKit.CARD_HI, 0.6), 14, Vector2(14, 8)))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var tr := TextureRect.new()
	tr.texture = icon
	tr.custom_minimum_size = Vector2(22, 22)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(tr)
	var nl := UIKit.label(name, 14, UIKit.SOFT)
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(nl)
	h.add_child(UIKit.title(a, 16, UIKit.TEXT))
	if b != a:
		h.add_child(UIKit.label("→", 14, UIKit.SOFT))
		h.add_child(UIKit.title(b, 16, GOOD))
	p.add_child(h)
	return p

func _need_chip(icon: Texture2D, text: String, ok: bool) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.pill(Color(UIKit.CARD_HI, 0.6), 14, Vector2(10, 6)))
	p.add_child(UIKit.iconed(icon, text, 13, GOOD if ok else SHORT, 20.0))
	return p

func _level_sheet() -> void:
	var id := _view_id
	if not Heroes.owned(hero, id):
		return
	if is_instance_valid(_lvl_layer):
		_lvl_layer.queue_free()
	var layer := Control.new()
	_lvl_layer = layer
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var dim := Button.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.01, 0.024, 0.055, 0.62)
	for st in ["normal", "hover", "pressed", "focus"]:
		dim.add_theme_stylebox_override(st, ds)
	dim.pressed.connect(layer.queue_free)
	layer.add_child(dim)
	dim.modulate.a = 0.0
	dim.create_tween().tween_property(dim, "modulate:a", 1.0, 0.2)
	var slider := Control.new()
	slider.set_anchors_preset(Control.PRESET_FULL_RECT)
	slider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(slider)
	var sheet := PanelContainer.new()
	var ss := UIKit.box(UIKit.CARD, Color(1, 1, 1, 0.06), 28)
	ss.corner_radius_bottom_left = 0
	ss.corner_radius_bottom_right = 0
	ss.content_margin_left = 18
	ss.content_margin_right = 18
	ss.content_margin_top = 14
	ss.content_margin_bottom = 22
	sheet.add_theme_stylebox_override("panel", ss)
	sheet.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	slider.add_child(sheet)
	slider.position.y = 700.0
	slider.create_tween().tween_property(slider, "position:y", 0.0, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	sheet.add_child(v)
	# the head: his face, name, element + rarity, Close
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var face := TextureRect.new()
	face.texture = _hero_portrait(id)
	face.custom_minimum_size = Vector2(64, 64)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.pivot_offset = Vector2(32, 32)
	head.add_child(face)
	var nv := VBoxContainer.new()
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nv.alignment = BoxContainer.ALIGNMENT_CENTER
	nv.add_theme_constant_override("separation", 4)
	nv.add_child(UIKit.title(String(Heroes.ROSTER[id].name), 24, UIKit.TEXT))
	var tags := HBoxContainer.new()
	tags.add_theme_constant_override("separation", 8)
	var ei := TextureRect.new()
	ei.texture = UIKit.element_icon(Heroes.element_of(id))
	ei.custom_minimum_size = Vector2(22, 22)
	ei.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ei.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tags.add_child(ei)
	var rar := HBoxContainer.new()
	tags.add_child(rar)
	nv.add_child(tags)
	head.add_child(nv)
	var x := UIKit.ghost_button("Close", 13)
	x.custom_minimum_size = Vector2(80, 34)
	x.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	x.pressed.connect(layer.queue_free)
	head.add_child(x)
	v.add_child(head)
	# the ladder: ten pips, Common to Mythic V, his step ringed
	var ladder := Control.new()
	ladder.custom_minimum_size = Vector2(0, 24)
	ladder.draw.connect(func():
		var star := Heroes.tier(hero, id)
		var gap := ladder.size.x / Gates.MAX_STAR
		for i in Gates.MAX_STAR:
			var s := i + 1
			var c := Vector2(gap * (i + 0.5), 12.0)
			var col := Gates.step_color(s)
			if i < Gates.MAX_STAR - 1:
				ladder.draw_line(c + Vector2(12, 0), c + Vector2(gap - 12, 0), Color(col, 0.7) if s < star else Color(1, 1, 1, 0.12), 2.0, true)
			if s < star:
				ladder.draw_circle(c, 5.0, col)
			elif s == star:
				ladder.draw_circle(c, 6.5, col)
				ladder.draw_arc(c, 10.0, 0.0, TAU, 32, Color(col, 0.6), 1.5, true)
			else:
				ladder.draw_arc(c, 5.0, 0.0, TAU, 24, Color(col, 0.45), 1.5, true))
	v.add_child(ladder)
	# his ability (the battle button bottom left): name, what it does, how often
	var ab_l := UIKit.label("", 12, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	ab_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(ab_l)
	# the level bar
	var lrow := HBoxContainer.new()
	lrow.add_theme_constant_override("separation", 10)
	var lv_l := UIKit.title("", 26, UIKit.TEXT)
	lv_l.custom_minimum_size = Vector2(84, 0)
	lrow.add_child(lv_l)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 8)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("background", UIKit.pill(Color(0.1, 0.153, 0.25), 4, Vector2.ZERO))
	bar.add_theme_stylebox_override("fill", UIKit.pill(UIKit.CYAN, 4, Vector2.ZERO))
	lrow.add_child(bar)
	var cap_l := UIKit.title("", 15, UIKit.SOFT)
	lrow.add_child(cap_l)
	v.add_child(lrow)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 6)
	v.add_child(rows)
	# the next perk (a level milestone) or what the next rarity unlocks
	var perk := PanelContainer.new()
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 2)
	var perk_t := UIKit.title("", 16, UIKit.GOLD)
	var perk_s := UIKit.label("", 13, UIKit.TEXT)
	perk_s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pv.add_child(perk_t)
	pv.add_child(perk_s)
	perk.add_child(pv)
	v.add_child(perk)
	var needs := HBoxContainer.new()
	needs.alignment = BoxContainer.ALIGNMENT_CENTER
	needs.add_theme_constant_override("separation", 8)
	v.add_child(needs)
	var go := UIKit.gold_button("", 20)
	go.custom_minimum_size = Vector2(0, 58)
	# the cost rides inside the button: LEVEL UP, the coin, the number, centred together
	var gb := HBoxContainer.new()
	gb.set_anchors_preset(Control.PRESET_FULL_RECT)
	gb.alignment = BoxContainer.ALIGNMENT_CENTER
	gb.add_theme_constant_override("separation", 8)
	gb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gb.add_child(UIKit.title("LEVEL UP", 20, UIKit.GOLD_INK))
	var gsp := Control.new()
	gsp.custom_minimum_size = Vector2(6, 0)
	gb.add_child(gsp)
	var gcoin := TextureRect.new()
	gcoin.texture = UIKit.ic("ic_coin", "ui_coin")
	gcoin.custom_minimum_size = Vector2(24, 24)
	gcoin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gcoin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gcoin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gb.add_child(gcoin)
	var gcost := UIKit.title("", 20, UIKit.GOLD_INK)
	gb.add_child(gcost)
	go.add_child(gb)
	go.button_down.connect(_lvl_press_down)
	go.button_up.connect(func(): _lvl_token += 1)
	go.pressed.connect(_lvl_pressed)
	v.add_child(go)
	var hint := UIKit.label("", 12, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(hint)
	_lv_ui = {"id": id, "face": face, "rar": rar, "ladder": ladder, "lv": lv_l, "bar": bar, "cap": cap_l, "rows": rows,
		"perk": perk, "perk_t": perk_t, "perk_s": perk_s, "needs": needs, "go": go, "go_box": gb, "go_cost": gcost, "hint": hint, "ab": ab_l}
	_lvl_refresh(false)

func _stat_strs(st: Dictionary) -> Array:
	return ["+%d%%" % roundi((float(st.damage) - 1.0) * 100.0), str(roundi(float(st.hp))), "%.1f%%" % (float(st.def) * 100.0)]

func _lvl_refresh(pop: bool) -> void:
	if not is_instance_valid(_lvl_layer) or _lv_ui.is_empty():
		return
	var id := String(_lv_ui.id)
	var data := _read()
	var lv := Heroes.level(hero, id)
	var star := Heroes.tier(hero, id)
	var cap := Heroes.level_cap(hero, id)
	var maxed := lv >= Heroes.MAX_LEVEL and star >= Gates.MAX_STAR
	var at_cap := lv >= cap and not maxed
	for box in [_lv_ui.rar, _lv_ui.rows, _lv_ui.needs]:
		for c in box.get_children():
			box.remove_child(c)
			c.queue_free()
	_lv_ui.rar.add_child(UIKit.chip(Gates.step_name(star), Gates.step_color(star)))
	_lv_ui.ladder.queue_redraw()
	var abil: Dictionary = Heroes.ABILITIES.get(id, {})
	_lv_ui.ab.text = "%s: %s  ·  every %d s" % [String(abil.get("name", "")), String(abil.get("text", "")), roundi(Heroes.ability_cd(star))]
	var lv_l: Label = _lv_ui.lv
	lv_l.text = "Lv.%d" % lv
	var bar: ProgressBar = _lv_ui.bar
	bar.max_value = maxi(cap, 1)
	if pop:
		bar.create_tween().tween_property(bar, "value", float(mini(lv, cap)), 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		lv_l.pivot_offset = Vector2(30, 16)
		lv_l.scale = Vector2(1.28, 1.28)
		lv_l.create_tween().tween_property(lv_l, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var face: TextureRect = _lv_ui.face
		face.scale = Vector2(1.12, 1.12)
		face.create_tween().tween_property(face, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_SINE)
	else:
		bar.value = mini(lv, cap)
	_lv_ui.cap.text = str(cap)
	# now -> next: one level on, or (at the cap) one rarity on
	var now := _stat_strs(_hero_preview(id, 0, 0))
	var nxt := now if maxed else _stat_strs(_hero_preview(id, 0, 1) if at_cap else _hero_preview(id, 1, 0))
	var names := ["Attack", "Health", "Defence"]
	var icons := ["st_atk", "st_hp", "st_def"]
	for i in 3:
		_lv_ui.rows.add_child(_lvl_row(UIKit.ic(icons[i], "st_atk"), names[i], now[i], nxt[i]))
	var go: Button = _lv_ui.go
	var perk_t: Label = _lv_ui.perk_t
	var perk_s: Label = _lv_ui.perk_s
	var hint: Label = _lv_ui.hint
	_lv_ui.needs.visible = at_cap
	if maxed:
		_lv_ui.perk.add_theme_stylebox_override("panel", UIKit.pill(Color(Gates.RED_COL, 0.14), 16, Vector2(14, 10)))
		perk_t.text = "Fully ascended"
		perk_t.add_theme_color_override("font_color", Gates.RED_COL)
		perk_s.text = Heroes.passive_text(id, star)
		go.text = "MAX"
		_lv_ui.go_box.visible = false
		go.disabled = true
		hint.text = ""
	elif at_cap:
		var nc := Gates.step_color(star + 1)
		_lv_ui.perk.add_theme_stylebox_override("panel", UIKit.pill(Color(nc, 0.14), 16, Vector2(14, 10)))
		perk_t.text = "%s  →  %s" % [Gates.step_name(star), Gates.step_name(star + 1)]
		perk_t.add_theme_color_override("font_color", nc.lerp(Color.WHITE, 0.25))
		var lines: Array = [Heroes.step_perk(star + 1), "Level cap %d → %d" % [cap, Gates.level_cap("hero", star + 1)]]
		if Heroes.passive_text(id, star) != Heroes.passive_text(id, star + 1):
			lines.append("%s  →  %s" % [Heroes.passive_text(id, star), Heroes.passive_text(id, star + 1)])
		perk_s.text = "\n".join(lines)
		var nd := Heroes.star_need(hero, id)
		var have := Parts.read(data)
		if int(nd.shards) > 0:
			_lv_ui.needs.add_child(_need_chip(UIKit.ic("mat_shard", "ic_shard"), "%d/%d" % [Heroes.shards(hero, id), int(nd.shards)], Heroes.shards(hero, id) >= int(nd.shards) or DevTools.on))
		for k in nd.mats:
			var kk := String(k)
			_lv_ui.needs.add_child(_need_chip(Materials.icon(kk) if Materials.is_material(kk) else Parts.icon(kk), "%d/%d" % [int(have.get(kk, 0)), int(nd.mats[k])], int(have.get(kk, 0)) >= int(nd.mats[k]) or DevTools.on))
		if int(nd.coins) > 0:
			_lv_ui.needs.add_child(_need_chip(UIKit.ic("ic_coin", "ui_coin"), UIKit.num(int(nd.coins)), coins >= int(nd.coins) or DevTools.on))
		var why := Heroes.why_not_evolve(hero, id, data)
		go.text = "ASCEND"
		_lv_ui.go_box.visible = false
		go.disabled = why != ""
		hint.text = why if (why.begins_with("Pilot") or why == "") else "Collect what is in red"
	else:
		_lv_ui.perk.add_theme_stylebox_override("panel", UIKit.pill(Color(UIKit.CARD_HI, 0.6), 16, Vector2(14, 10)))
		var next_lv := ((lv / Heroes.MILESTONE_EVERY) + 1) * Heroes.MILESTONE_EVERY
		var ms := Heroes.milestone_at(next_lv)
		perk_t.text = "Lv.%d perk" % next_lv
		perk_t.add_theme_color_override("font_color", UIKit.GOLD)
		perk_s.text = String(ms.get("text", ""))
		var cost := 0 if DevTools.on else Heroes.level_cost(lv)
		go.text = ""
		_lv_ui.go_cost.text = UIKit.num(cost)
		_lv_ui.go_box.visible = true
		_lv_ui.go_box.modulate.a = 0.45 if coins < cost else 1.0
		go.disabled = coins < cost
		hint.text = "Hold to keep levelling" if coins >= cost else "Not enough coins"

func _lvl_step() -> bool:
	if not _on_level_up():
		return false
	_lvl_did = true
	_lvl_refresh(true)
	return true

# LEVEL UP acts the moment the finger lands, then repeats faster and faster while it stays down
func _lvl_press_down() -> void:
	_lvl_did = false
	if _lv_ui.is_empty() or Heroes.level(hero, String(_lv_ui.id)) >= Heroes.level_cap(hero, String(_lv_ui.id)):
		return   # ASCEND waits for the release (_lvl_pressed)
	_lvl_token += 1
	var token := _lvl_token
	if not _lvl_step():
		return
	await get_tree().create_timer(0.4).timeout
	var wait := 0.13
	while token == _lvl_token and is_instance_valid(_lvl_layer) and is_instance_valid(_lv_ui.go) and (_lv_ui.go as Button).button_pressed:
		if not _lvl_step():
			break
		await get_tree().create_timer(wait).timeout
		wait = maxf(wait * 0.9, 0.045)

func _lvl_pressed() -> void:
	if _lvl_did:   # the press that just levelled him to the cap is not also an ASCEND
		_lvl_did = false
		return
	if _lv_ui.is_empty():
		return
	var id := String(_lv_ui.id)
	if Heroes.level(hero, id) < Heroes.level_cap(hero, id):
		return
	var before := Heroes.tier(hero, id)
	_on_evolve()
	if Heroes.tier(hero, id) > before:
		_lvl_refresh(false)
		_ascend_fx(id, before)

# the ASCEND moment: the page dims, rays in the colour of the new rarity turn behind his face, the
# old rarity gives way to the new one, and the power-up it unlocked is named. Tap to go on.
func _ascend_fx(id: String, from_star: int) -> void:
	var star := Heroes.tier(hero, id)
	_rarity_fx(String(Heroes.ROSTER[id].name), _hero_portrait(id), from_star, star, Heroes.step_perk(star), "Level cap %d  ·  %s" % [Heroes.level_cap(hero, id), Heroes.passive_text(id, star)])

# the same moment for anything on the rarity ladder (a hero, a turret, a drone body)
func _rarity_fx(who: String, tex: Texture2D, from_star: int, star: int, perk_text: String, more_text: String) -> void:
	var col := Gates.step_color(star)
	var layer := Button.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ls := StyleBoxFlat.new()
	ls.bg_color = Color(0.01, 0.02, 0.05, 0.95)
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		layer.add_theme_stylebox_override(st, ls)
	layer.disabled = true   # no skipping the first beat
	add_child(layer)
	layer.modulate.a = 0.0
	layer.create_tween().tween_property(layer, "modulate:a", 1.0, 0.18)
	var mid := Vector2(size.x * 0.5, size.y * 0.4)
	var rays := Control.new()
	rays.position = mid
	rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rays.draw.connect(func():
		for i in 14:
			var a := TAU * i / 14.0
			var w := 0.085 if i % 2 == 0 else 0.05
			rays.draw_colored_polygon(PackedVector2Array([Vector2.ZERO, Vector2(cos(a - w), sin(a - w)) * 420.0, Vector2(cos(a + w), sin(a + w)) * 420.0]), Color(col, 0.13 if i % 2 == 0 else 0.07))
		rays.draw_circle(Vector2.ZERO, 96.0, Color(col, 0.16))
		rays.draw_arc(Vector2.ZERO, 96.0, 0.0, TAU, 64, Color(col, 0.8), 2.0, true))
	layer.add_child(rays)
	rays.scale = Vector2(0.2, 0.2)
	rays.create_tween().tween_property(rays, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not Perf.lite():
		rays.create_tween().set_loops().tween_property(rays, "rotation", TAU, 24.0).from(0.0)
	var face := TextureRect.new()
	face.texture = tex
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # before the size, or the picture's own size wins
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.size = Vector2(170, 170)
	face.position = mid - Vector2(85, 85)
	face.pivot_offset = Vector2(85, 85)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(face)
	face.scale = Vector2(0.5, 0.5)
	face.create_tween().tween_property(face, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var col_box := VBoxContainer.new()
	col_box.position = Vector2(24.0, mid.y + 118.0)
	col_box.size = Vector2(size.x - 48.0, 0.0)
	col_box.add_theme_constant_override("separation", 8)
	col_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(col_box)
	var was := UIKit.label("%s  ·  %s" % [who, Gates.step_name(from_star)], 14, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	var now_l := UIKit.title(Gates.step_name(star).to_upper(), 40, col.lerp(Color.WHITE, 0.2), HORIZONTAL_ALIGNMENT_CENTER)
	var perk := UIKit.label(perk_text, 16, UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	var more := UIKit.label(more_text, 13, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	var tap := UIKit.label("Tap to continue", 12, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	var i := 0
	for l in [was, now_l, perk, more, tap]:
		(l as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col_box.add_child(l)
		l.modulate.a = 0.0
		var tw := (l as Label).create_tween()
		tw.tween_interval(0.25 + 0.16 * i + (0.5 if l == tap else 0.0))
		tw.tween_property(l, "modulate:a", 1.0, 0.25)
		i += 1
	Sfx.play("level", 1.2)
	if _plat:
		_plat.flash()
	get_tree().create_timer(0.9).timeout.connect(func():
		if is_instance_valid(layer):
			layer.disabled = false)
	layer.pressed.connect(func():
		var out := layer.create_tween()
		out.tween_property(layer, "modulate:a", 0.0, 0.2)
		out.tween_callback(layer.queue_free))

# capture hook (tools/dev/capture.gd CAP_CALL="_dbg_ascend"): the ASCEND moment for the hero in view
func _dbg_ascend() -> void:
	_ascend_fx(_view_id, maxi(Heroes.tier(hero, _view_id) - 1, 1))

# ------------------------------------------------------------------ the CLEAN Turrets + Drone pages (2026-11-10)
# The same family as the Hero page and the Store: flat squares with a picture and a short name, one
# card for the thing in focus (picture, name, element + role + rarity chips), upgrades as buttons
# that carry their cost as a coin and a number (no two-line text to clip), and the rarity ladder of
# the heroes (Gates.step_name) in place of stars. The rules and handlers are the old ones.
func _pick_square(tex: Texture2D, name: String, h: float, selected: bool, col: Color, dim: bool, sub: String = "") -> Button:
	var b := Button.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, h)
	var nb := UIKit.box(Color(UIKit.CARD, 0.94), Color(col, 0.95) if selected else Color(1, 1, 1, 0.05), 18, 2 if selected else 1)
	if selected:
		nb.bg_color = Color(0.04 + col.r * 0.14, 0.07 + col.g * 0.14, 0.12 + col.b * 0.14, 0.96)
	nb.set_content_margin_all(0)
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, nb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 6.0
	v.offset_right = -6.0
	v.offset_top = 6.0
	v.offset_bottom = -6.0
	v.add_theme_constant_override("separation", 1)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if dim:
		tr.modulate = Color(0.45, 0.48, 0.6, 0.75)
	v.add_child(tr)
	var nl := UIKit.label(name, 10, UIKit.SOFT if dim else UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	nl.clip_text = true
	v.add_child(nl)
	if sub != "":
		var sl := UIKit.label(sub, 10, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		sl.clip_text = true
		v.add_child(sl)
	b.add_child(v)
	UIKit.press_fx(b)
	return b

func _mat_icon(k: String) -> Texture2D:
	if k == "coins":
		return UIKit.ic("ic_coin", "ui_coin")
	return Materials.icon(k) if Materials.is_material(k) else Parts.icon(k)

# a button with a title and, under it, what it costs as small pictures with numbers
func _cost_btn(title_text: String, coin_cost: int, needs: Dictionary, note: String, gold: bool, size_px: int = 15) -> Button:
	var b := UIKit.gold_button("", 12) if gold else UIKit.teal_button("", 12)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 62)
	var ink: Color = UIKit.GOLD_INK if gold else UIKit.TEXT
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(UIKit.title(title_text, size_px, ink, HORIZONTAL_ALIGNMENT_CENTER))
	if note != "":
		v.add_child(UIKit.label(note, 10, Color(ink, 0.7), HORIZONTAL_ALIGNMENT_CENTER))
	elif coin_cost > 0 or not needs.is_empty():
		var have := Parts.read(_read())
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if coin_cost > 0:
			row.add_child(UIKit.iconed(_mat_icon("coins"), UIKit.num(coin_cost), 11, ink if (coins >= coin_cost or gold) else SHORT, 14.0))
		for k in needs:
			var ok: bool = int(have.get(k, 0)) >= int(needs[k])
			row.add_child(UIKit.iconed(_mat_icon(String(k)), str(int(needs[k])), 11, ink if (ok or gold) else SHORT, 14.0))
		v.add_child(row)
	b.add_child(v)
	return b

func _tag_row(el: String, role: String, star: int, extra: String = "") -> HBoxContainer:
	var tags := HBoxContainer.new()
	tags.add_theme_constant_override("separation", 8)
	var ei := TextureRect.new()
	ei.texture = UIKit.element_icon(el)
	ei.custom_minimum_size = Vector2(20, 20)
	ei.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ei.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tags.add_child(ei)
	if role != "":
		tags.add_child(UIKit.iconed(UIKit.role_icon(role), role, 12, UIKit.SOFT, 18.0))
	if star > 0:
		tags.add_child(UIKit.chip(Gates.step_name(star), Gates.step_color(star)))
	if extra != "":
		tags.add_child(UIKit.title(extra, 13, UIKit.TEXT))
	return tags

# what the next rarity step asks for, as have / need chips
func _need_row(nd: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	var have := Parts.read(_read())
	for k in Dictionary(nd.get("mats", {})):
		var kk := String(k)
		row.add_child(_need_chip(_mat_icon(kk), "%d/%d" % [int(have.get(kk, 0)), int(nd.mats[k])], int(have.get(kk, 0)) >= int(nd.mats[k]) or DevTools.on))
	if int(nd.get("coins", 0)) > 0:
		row.add_child(_need_chip(_mat_icon("coins"), UIKit.num(int(nd.coins)), coins >= int(nd.coins) or DevTools.on))
	return row

# the gold ASCEND button of a turret or a drone body: ready, or the one thing in the way
func _ascend_btn(why: String, cap_text: String) -> Button:
	var ready := why == ""
	var txt := "ASCEND" if ready else ("MAX" if why == "Max stars" else (cap_text if why.begins_with("Lv.") else (why.replace(" first", "") if why.begins_with("Pilot") else "ASCEND")))
	var b := UIKit.gold_button(txt, 15) if ready else UIKit.ghost_button(txt, 12)
	b.custom_minimum_size = Vector2(132, 50)
	b.disabled = not ready
	UIKit.dot(b, ready)
	return b

func _refresh_turrets_clean() -> void:
	_power_label.text = ""
	_paint_wallet()
	var box := _turret_box
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	_t_tracks_btn.clear()
	# the four mounts on the base
	var mounts := HBoxContainer.new()
	mounts.add_theme_constant_override("separation", 8)
	for i in Turrets.MOUNTS:
		var id: String = t_loadout[i]
		var open: bool = Turrets.mount_open(i, t_unlocked)
		var col: Color = UIKit.RARITY[Turrets.element(id)] if id != "" else UIKit.CYAN
		var tex: Texture2D = load("res://turrets/%s_idle.png" % Turrets.TURRETS[id].art) if id != "" else null
		var b := _pick_square(tex, ("Stage %d" % Turrets.MOUNT_OPENS_AFTER[i]) if not open else (String(Turrets.TURRETS[id].name) if id != "" else "Empty"), 100.0, i == t_mount, col, not open)
		_num_badge(b, col if open else UIKit.SOFT, str(i + 1))
		var mi: int = i
		b.pressed.connect(func():
			t_mount = mi
			if t_loadout[mi] != "":
				t_focus = t_loadout[mi]
			_refresh_turrets())
		mounts.add_child(b)
	box.add_child(mounts)
	box.add_child(_turret_card())
	# every turret: yours bright, the rest dim with their price
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for id in Turrets.TURRETS:
		var def: Dictionary = Turrets.TURRETS[id]
		var locked: bool = not Turrets.owned({"owned": t_owned}, id)
		var col: Color = UIKit.RARITY[Turrets.element(id)]
		var price := int(def.cost.get("coins", 0))
		var sub := (UIKit.num(price) if price > 0 else "Unlock") if locked else ("Soon" if not def.ready else "")
		var b := _pick_square(load("res://turrets/%s_idle.png" % def.art), String(def.name), 104.0, id == t_focus, col, locked or not def.ready, sub)
		UIKit.corner_icon(b, UIKit.element_icon(Turrets.element(id)), 18.0, true)
		if t_loadout.has(id):
			_num_badge(b, col, str(t_loadout.find(id) + 1))   # the mount it stands on
		var tid: String = id
		b.pressed.connect(func():
			t_focus = tid
			_refresh_turrets())
		grid.add_child(b)
	box.add_child(grid)
	UIKit.reveal(grid, 0.02, 8.0)

# the turret in focus: who it is, its three tracks, Place / Remove and ASCEND (or its price)
func _turret_card() -> PanelContainer:
	var p := UIKit.panel(22)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	if t_focus == "":
		var open: bool = Turrets.mount_open(t_mount, t_unlocked)
		var l := UIKit.label(("Mount %d is empty: pick a turret below" % (t_mount + 1)) if open else ("Mount %d opens after stage %d" % [t_mount + 1, Turrets.MOUNT_OPENS_AFTER[t_mount]]), 13, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		l.custom_minimum_size = Vector2(0, 60)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		v.add_child(l)
		return p
	var def: Dictionary = Turrets.TURRETS[t_focus]
	var el := Turrets.element(t_focus)
	var tr := Turrets.one_tracks(t_tracks, t_focus)
	var lvl := Turrets.level_of(tr)
	var locked: bool = not Turrets.owned({"owned": t_owned}, t_focus)
	var tstar := Turrets.star({"stars": t_stars}, t_focus)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var pic := TextureRect.new()
	pic.texture = load("res://turrets/%s_idle.png" % def.art)
	pic.custom_minimum_size = Vector2(84, 84)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(pic)
	var nv := VBoxContainer.new()
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nv.alignment = BoxContainer.ALIGNMENT_CENTER
	nv.add_theme_constant_override("separation", 5)
	nv.add_child(UIKit.title(String(def.name), 22, UIKit.TEXT))
	nv.add_child(_tag_row(el, Turrets.role(t_focus), 0 if locked else tstar, "" if locked else "Lv.%d" % lvl))
	var dl := UIKit.label(String(def.desc), 12, UIKit.SOFT)
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nv.add_child(dl)
	head.add_child(nv)
	v.add_child(head)
	if locked:
		var ub := _cost_btn("UNLOCK", int(def.cost.get("coins", 0)), Turrets.parts_needed(t_focus), "", true, 18)
		ub.pressed.connect(_on_turret_place)   # (Place buys a turret you do not own; crystals as the fallback)
		v.add_child(ub)
		return p
	if not def.ready:
		v.add_child(UIKit.label("Coming soon", 13, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER))
		return p
	var tcap := Turrets.track_cap(tstar)
	var tracks := HBoxContainer.new()
	tracks.add_theme_constant_override("separation", 8)
	for k in Turrets.TRACKS:
		var l: int = int(tr[k])
		var note := "MAX" if l >= Turrets.MAX_TRACK else ("at its cap" if l >= tcap else "")
		var needs: Dictionary = Parts.need(l / 2)
		needs.merge(Materials.turret_need(l, el))
		var tb := _cost_btn("%s %d" % [String(Turrets.TRACK_NAMES[k]), l], Turrets.track_cost(l), needs, note, false)
		tb.disabled = note != "" or coins < Turrets.track_cost(l)
		var key: String = k
		tb.pressed.connect(func(): _on_track_upgrade(key))
		tracks.add_child(tb)
		_t_tracks_btn[k] = tb
	v.add_child(tracks)
	var act := HBoxContainer.new()
	act.add_theme_constant_override("separation", 8)
	var here: bool = t_loadout[t_mount] == t_focus
	var mount_open: bool = Turrets.mount_open(t_mount, t_unlocked)
	var place := UIKit.teal_button("Mount locked" if not mount_open else ("Remove" if here else "Place on %d" % (t_mount + 1)), 14)
	place.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	place.custom_minimum_size = Vector2(0, 50)
	place.disabled = not mount_open
	place.pressed.connect(_on_turret_place)
	act.add_child(place)
	var why := Turrets.why_not_star(_read(), {"stars": t_stars, "tracks": t_tracks}, t_focus)
	var asc := _ascend_btn(why, "Tracks to Lv.%d" % tcap)
	asc.pressed.connect(_on_turret_star)
	act.add_child(asc)
	v.add_child(act)
	# at the cap: what the next rarity asks for
	if tstar < Gates.MAX_STAR and Turrets.lowest_track(tr) >= tcap:
		v.add_child(_need_row(Turrets.star_need({"stars": t_stars}, t_focus)))
	return p

func _refresh_drone_clean() -> void:
	var box := _drone_box
	var body: Dictionary = DroneData.BODIES[drone.body]
	var pod: Dictionary = DroneData.PODS[drone.pod]
	var el := DroneData.body_element(drone.body)
	var col: Color = UIKit.RARITY.get(el, UIKit.CYAN)
	var lvl: int = int(drone.level)
	var dstar := DroneData.star(drone)
	var dcap := DroneData.level_cap(drone)
	# the card: the drone hovering on the left, who it is and its numbers on the right
	var p := UIKit.panel(22)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var pv := Control.new()
	pv.custom_minimum_size = Vector2(130, 120)
	var bt: Texture2D = load("res://drone/body_%s.png" % drone.body)
	var pt: Texture2D = load("res://drone/pod_%s.png" % DroneData.pod_art(drone.pod))
	var tm := [0.0]
	pv.draw.connect(func():
		var c := pv.size * 0.5 + Vector2(0, sin(tm[0] * 2.0) * 4.0)
		pv.draw_set_transform(c, sin(tm[0] * 0.8) * 0.2, Vector2.ONE)
		var bw: float = minf(104.0, 112.0 * bt.get_width() / bt.get_height())   # tall bodies (the Wisp) fit the box
		var bh: float = bw * bt.get_height() / bt.get_width()
		var pw := 42.0
		var ph: float = pw * pt.get_height() / pt.get_width()
		pv.draw_texture_rect(pt, Rect2(-pw * 0.5, -bh * 0.35 - ph * 0.5, pw, ph), false)
		pv.draw_texture_rect(bt, Rect2(-bw * 0.5, -bh * 0.5, bw, bh), false)
		pv.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE))
	if not Perf.lite():
		var tw := pv.create_tween().set_loops()
		tw.tween_method(func(val): tm[0] = val; pv.queue_redraw(), 0.0, TAU * 2.0, 8.0)
	head.add_child(pv)
	var nv := VBoxContainer.new()
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nv.alignment = BoxContainer.ALIGNMENT_CENTER
	nv.add_theme_constant_override("separation", 6)
	nv.add_child(UIKit.title(String(body.name), 22, UIKit.TEXT))
	nv.add_child(_tag_row(el, "", dstar, "Lv.%d" % lvl))
	var dmg: float = float(pod.damage) * float(body.dmg) * DroneData.level_mult(lvl) * DroneData.dmg_bonus(lvl)
	var every: float = float(pod.every) / float(body.rate) / DroneData.rate_bonus(lvl)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 8)
	for chip in [[UIKit.ic("st_atk"), "%.1f" % dmg], [UIKit.ic("st_rate", "st_atk"), "%.2f s" % every]]:
		var cp := PanelContainer.new()
		cp.add_theme_stylebox_override("panel", UIKit.pill(UIKit.CARD_HI, 15, Vector2(10, 3)))
		cp.add_child(UIKit.iconed(chip[0], chip[1], 13, UIKit.TEXT, 18.0))
		chips.add_child(cp)
	nv.add_child(chips)
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 8)
	var bar := ProgressBar.new()
	bar.max_value = maxi(dcap, 1)
	bar.value = mini(lvl, dcap)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 6)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("background", UIKit.pill(Color(0.1, 0.153, 0.25), 3, Vector2.ZERO))
	bar.add_theme_stylebox_override("fill", UIKit.pill(UIKit.CYAN, 3, Vector2.ZERO))
	bar_row.add_child(bar)
	bar_row.add_child(UIKit.title(str(dcap), 13, UIKit.SOFT))
	nv.add_child(bar_row)
	head.add_child(nv)
	v.add_child(head)
	# one gold button: LEVEL UP with its cost, or ASCEND at the cap
	var dwhy := DroneData.why_not_star(_read(), drone)
	if lvl >= DroneData.MAX_LEVEL and dstar >= Gates.MAX_STAR:
		var mx := UIKit.ghost_button("MAX", 14)
		mx.disabled = true
		v.add_child(mx)
	elif lvl >= dcap:
		var asc := _ascend_btn(dwhy, "Lv.%d first" % dcap)
		asc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		asc.pressed.connect(_on_drone_star)
		v.add_child(asc)
		v.add_child(_need_row(DroneData.star_need(drone)))
	else:
		var cost := DroneData.upgrade_cost(lvl)
		var needs: Dictionary = Parts.need(lvl)
		needs.merge(Materials.drone_need(lvl))
		var up := _cost_btn("LEVEL UP", cost, needs, "", true, 18)
		up.disabled = coins < cost and not DevTools.on
		up.pressed.connect(func():
			var c2 := DroneData.upgrade_cost(int(drone.level))
			if (coins >= c2 or DevTools.on) and int(drone.level) < DroneData.level_cap(drone) and await _pay_upgrade(c2, int(drone.level), Materials.drone_need(int(drone.level))):
				drone.level = int(drone.level) + 1
				for m in DroneData.MILESTONES:
					if int(drone.level) == int(m[0]):
						_milestone_toast("Drone reached Lv.%d: %s" % [m[0], m[1]])
				_save_drone()
				Sfx.play("upgrade")
				Progress.bump("upgrades")
				_refresh_drone())
		v.add_child(up)
	box.add_child(p)
	# bodies, then pods: squares, yours bright, the one in use ringed
	for spec in [["Body", DroneData.BODIES, "body"], ["Weapon pod", DroneData.PODS, "pod"]]:
		box.add_child(UIKit.header(spec[0]))
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		for id in spec[1]:
			var def: Dictionary = spec[1][id]
			var is_body: bool = spec[2] == "body"
			var open: bool = (DroneData.body_open(drone, id, pilot_level) if is_body else (pilot_level >= int(def.unlock) or DevTools.on))
			var on: bool = drone[spec[2]] == id
			var sub := ""
			if not open:
				sub = (DroneData.cost_text(id) if DroneData.premium(id) else UIKit.num(int(def.cost.get("coins", 0)))) if (is_body and DroneData.is_bought(id)) else "Pilot Lv.%d" % int(def.unlock)
			var sc: Color = UIKit.RARITY.get(DroneData.body_element(id), UIKit.CYAN) if is_body else UIKit.CYAN
			var sq := _pick_square(load("res://drone/%s_%s.png" % [spec[2], DroneData.pod_art(id) if not is_body else id]), String(def.name), 98.0, on, sc, not open, sub)
			if is_body:
				UIKit.corner_icon(sq, UIKit.element_icon(DroneData.body_element(id)), 18.0, true)
			var key: String = spec[2]
			var pick: String = id
			sq.pressed.connect(func():
				if not open and key == "body" and DroneData.is_bought(pick):   # buy it (coins + parts, crystals as the fallback)
					_on_drone_unlock(pick)
					return
				if open:
					drone[key] = pick
					_save_drone()
					_refresh_drone())
			grid.add_child(sq)
		box.add_child(grid)
		UIKit.reveal(grid, 0.02, 8.0)
	# the support drone: a second drone with a job, flown while a Hangar stands on the base
	box.add_child(UIKit.header("Support drone"))
	var sdata := _read()
	if not DroneData.support_open(sdata):
		var hint := UIKit.label("Put a Hangar on your base and a second drone flies with you: a Guard, a Collector or a Medic.", 12, UIKit.SOFT)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(hint)
	else:
		var hl := DroneData.hangar_level(sdata)
		var sgrid := GridContainer.new()
		sgrid.columns = 3
		sgrid.add_theme_constant_override("h_separation", 8)
		for sid in DroneData.SUPPORT_ORDER:
			var sdef: Dictionary = DroneData.SUPPORT[sid]
			var son: bool = String(drone.get("support", "")) == String(sid)
			var ssq := _pick_square(load("res://drone/%s.png" % String(sdef.art)), String(sdef.name), 98.0, son, sdef.col, false)
			var spick := String(sid)
			ssq.pressed.connect(func():
				drone["support"] = "" if String(drone.get("support", "")) == spick else spick   # tap the one in use to send it home
				_save_drone()
				Sfx.play("tap")
				_refresh_drone())
			sgrid.add_child(ssq)
		box.add_child(sgrid)
		var cur := String(drone.get("support", ""))
		var sl := UIKit.label(DroneData.support_text(cur, hl) + "  ·  Hangar Lv.%d" % hl if cur != "" else "Pick one. A higher Hangar level makes it better at its job.", 12, UIKit.SOFT)
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(sl)
	_power_label.text = ""
	_paint_wallet()

# a small number in the top right corner of a square (the mount a turret stands on)
func _num_badge(parent: Control, col: Color, text: String) -> void:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", UIKit.pill(Color(col, 0.9), 8, Vector2(6, 0)))
	p.add_child(UIKit.title(text, 11, Color(0.04, 0.07, 0.13), HORIZONTAL_ALIGNMENT_CENTER))
	p.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	p.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	p.offset_right = -6.0
	p.offset_top = 6.0
	parent.add_child(p)

# ------------------------------------------------------------------ the CLEAN Workshop (2026-11-10)
# Gear: the stacks as the same flat squares as the Turrets page (the count on a badge in the rarity
# colour, a red dot on a stack that can merge), Filter and Quick Merge on one row. Craft: every
# recipe is one square you tap (picture, what it takes as have / need, the coin price), instead
# of a long list of cards with a gold button each.
func _refresh_ws_gear_clean() -> void:
	gear = GearData.read(_read())
	var total := 0
	for id in gear.copies:
		total += GearData.total_copies(gear, id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var fb := UIKit.ghost_button("Filter", 13)
	fb.custom_minimum_size = Vector2(84, 42)
	fb.pressed.connect(_filter_box)
	row.add_child(fb)
	var bits: Array = []
	if _inv_filter.rarity != "":
		bits.append(GearData.rarity_name(_inv_filter.rarity))
	if _inv_filter.set != "":
		bits.append(GearData.SETS[_inv_filter.set].name)
	var ft := UIKit.label(("All" if bits.is_empty() else " · ".join(bits)) + "  ·  " + String(INV_SORT_NAMES[_inv_filter.sort]), 12, UIKit.SOFT)
	ft.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ft.clip_text = true
	row.add_child(ft)
	var qn := GearData.quick_merge_count(gear)
	var qb := UIKit.gold_button("Quick Merge" + ((" %d" % qn) if qn > 0 else ""), 14)
	_quick_btn = qb
	qb.custom_minimum_size = Vector2(150, 42)
	qb.disabled = qn <= 0
	qb.pressed.connect(_quick_merge)
	row.add_child(qb)
	_ws_gear_box.add_child(row)
	var stacks := _inv_stacks()
	if stacks.is_empty():
		var t := UIKit.label("Weapon copies drop when you clear a stage and from Patrol." if total == 0 else "Nothing matches this filter.", 13, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size = Vector2(0, 80)
		t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_ws_gear_box.add_child(t)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for s in stacks:
		var info: Dictionary = GearData.ITEMS[s.id]
		var rc: Color = GearData.rarity_color(s.rarity)
		var worn: bool = gear.equipped[info.slot] == s.id and GearData.rarity(gear, s.id) == s.rarity
		var b := _pick_square(_pic(s.id), String(info.name), 104.0, worn, rc, false)
		_num_badge(b, rc, "x%d" % int(s.n))
		UIKit.dot(b, GearData.can_merge(gear, s.id, s.rarity))
		var stack: Dictionary = s
		b.pressed.connect(func(): _stack_box(stack))
		grid.add_child(b)
	_ws_gear_box.add_child(grid)
	UIKit.reveal(grid, 0.02, 8.0)
	_power_label.text = ""
	_paint_wallet()

func _refresh_ws_craft_clean() -> void:
	var data := _read()
	var have := Parts.read(data)
	# what you hold, as small chips
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	for k in Materials.ORDER:
		if int(have.get(k, 0)) <= 0:
			continue
		var cp := PanelContainer.new()
		cp.add_theme_stylebox_override("panel", UIKit.pill(Color(UIKit.CARD, 0.9), 14, Vector2(10, 4)))
		cp.tooltip_text = Materials.name_of(k)
		cp.add_child(UIKit.iconed(Materials.icon(k), str(int(have[k])), 12, UIKit.TEXT, 20.0))
		flow.add_child(cp)
	if flow.get_child_count() > 0:
		_ws_craft_box.add_child(flow)
	# the essence recipe makes the element you pick here
	var erow := HBoxContainer.new()
	erow.add_theme_constant_override("separation", 6)
	erow.alignment = BoxContainer.ALIGNMENT_CENTER
	erow.add_child(UIKit.label("Essence", 12, UIKit.SOFT))
	for el in Heroes.ELEMENTS:
		var eb := Button.new()
		eb.custom_minimum_size = Vector2(44, 38)
		eb.icon = UIKit.element_icon(String(el))
		eb.expand_icon = true
		eb.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var on: bool = String(el) == _craft_el
		var es := UIKit.pill(UIKit.CARD_HI if on else Color(UIKit.CARD, 0.6), 14, Vector2(6, 4))
		for st in ["normal", "hover", "pressed"]:
			eb.add_theme_stylebox_override(st, es)
		eb.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		eb.modulate = Color(1, 1, 1, 1.0 if on else 0.5)
		var elid := String(el)
		eb.pressed.connect(func():
			_craft_el = elid
			_refresh_ws_craft())
		erow.add_child(eb)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	var has_pick := false
	for r in Materials.RECIPES:
		var rec: Dictionary = r
		has_pick = has_pick or bool(rec.get("pick", false))
		var mk := Materials.makes(rec, _craft_el)
		var mk_id := String(mk.keys()[0])
		var ok: bool = Materials.can_craft(data, rec)
		var b := Button.new()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 168)
		var nb := UIKit.glass(22.0)
		for st in ["normal", "hover", "disabled"]:
			b.add_theme_stylebox_override(st, nb)
		var pb := UIKit.glass(22.0)
		pb.bg_color = UIKit.CARD_HI
		b.add_theme_stylebox_override("pressed", pb)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var v := VBoxContainer.new()
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 10.0
		v.offset_right = -10.0
		v.offset_top = 8.0
		v.offset_bottom = -10.0
		v.add_theme_constant_override("separation", 5)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var top := HBoxContainer.new()
		top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var nm := UIKit.label(Materials.name_of(mk_id), 13, UIKit.TEXT if ok else UIKit.SOFT)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.clip_text = true
		top.add_child(nm)
		top.add_child(UIKit.title("x%d" % int(mk[mk_id]), 14, UIKit.CYAN))
		v.add_child(top)
		var pic := _part_icon(mk_id, 54)
		pic.size_flags_vertical = Control.SIZE_EXPAND_FILL
		if not ok:
			pic.modulate = Color(0.6, 0.62, 0.72, 0.85)
		v.add_child(pic)
		var nrow := HBoxContainer.new()
		nrow.alignment = BoxContainer.ALIGNMENT_CENTER
		nrow.add_theme_constant_override("separation", 10)
		nrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for k in rec.needs:
			var hv := int(have.get(k, 0))
			var nd := int(rec.needs[k])
			nrow.add_child(UIKit.iconed(_part_tex(String(k)), "%d/%d" % [hv, nd], 12, GOOD if hv >= nd else SHORT, 18.0))
		v.add_child(nrow)
		var cc := int(rec.get("coins", 0))
		var state := PanelContainer.new()
		state.custom_minimum_size = Vector2(0, 34)
		state.mouse_filter = Control.MOUSE_FILTER_IGNORE
		state.add_theme_stylebox_override("panel", UIKit.pill(UIKit.GOLD if ok else UIKit.CARD_HI, 12, Vector2(6, 0)))
		var sl := UIKit.iconed(UIKit.ic("ic_coin", "ui_coin"), UIKit.num(cc), 14, UIKit.GOLD_INK if ok else (UIKit.TEXT if coins >= cc else SHORT), 18.0)
		sl.alignment = BoxContainer.ALIGNMENT_CENTER
		sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		state.add_child(sl)
		v.add_child(state)
		b.add_child(v)
		UIKit.press_fx(b)
		b.pressed.connect(func():
			if not Materials.can_craft(_read(), rec):
				_toast("Short of what is in red")
				return
			_craft(rec))
		grid.add_child(b)
	if has_pick:
		_ws_craft_box.add_child(erow)
	_ws_craft_box.add_child(grid)
	UIKit.reveal(grid, 0.02, 8.0)

# the Wingmate square: the next owned hero rides along, then nobody
func _on_wing() -> void:
	hero["wing"] = Heroes.wing_next(hero)
	var data := _read()
	data["hero"] = Heroes.write(hero)
	_write_data(data)
	Sfx.play("tap")
	var wid := Heroes.wing(hero)
	if wid == "":
		_toast("No wingmate")
	else:
		_toast("%s flies with you: half of %s, and %s" % [String(Heroes.ROSTER[wid].name), Heroes.passive_text(wid, Heroes.tier(hero, wid)), String(Heroes.ABILITIES[wid].name)])
	_paint_hero()

# ------------------------------------------------------------------ the BASE page (Base, 2026-11-10)
# It takes the Turrets tab's place (Rudy: scrap the turrets; the base is defensive and gives
# power-ups; pick four buildings; each has its own level). The four slots across the top, one card
# for the building in focus (what it gives now and at the next level, BUILD or LEVEL UP, Place /
# Remove), then every building: yours bright, the rest dim with their price or the stage that opens
# them. The first visit pays back what was spent on turrets (Base.migrate).
var b_slot := 0
var b_focus := ""

func _refresh_base() -> void:
	_power_label.text = ""
	var data := _read()
	var back := Base.migrate(data)
	if back > 0 or not data.has("base"):
		data["base"] = Base.write(Base.read(data))
		_write_data(data)
		coins = int(data.get("coins", 0))
		if back > 0:
			_milestone_toast("Turrets retired: %s coins back for your base" % UIKit.num(back))
	_paint_wallet()
	var b := Base.read(data)
	if b_focus == "" or not Base.BUILDINGS.has(b_focus):
		b_focus = String(b.slots[b_slot]) if String(b.slots[b_slot]) != "" else "shield_gen"
	var box := _turret_box
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	if Research.open(data):   # the Research Lab (Research): its own page
		var lab := Research.read(data)
		var lleft := Research.left_s(lab)
		var ltext := "Research  ·  the lab is free" if lleft < 0 else ("Research  ·  done, collect it" if lleft == 0 else "Research  ·  %s left" % Research.time_text(lleft))
		var rb := UIKit.teal_button(ltext, 13)
		rb.custom_minimum_size = Vector2(0, 40)
		rb.pressed.connect(func(): get_tree().change_scene_to_file("res://research_page.tscn"))
		box.add_child(rb)
		UIKit.dot(rb, lleft <= 0)
	var intro := UIKit.label("The base never shoots. Each building gives one kind of help. Field four.", 12, UIKit.SOFT)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(intro)
	# the four slots
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 8)
	for i in Base.SLOTS:
		var id := String(b.slots[i])
		var open: bool = Base.slot_open(i, t_unlocked) or DevTools.on
		var col: Color = Base.BUILDINGS[id].col if id != "" else UIKit.CYAN
		var sq := _pick_square(Base.pic(id) if id != "" else null, ("Stage %d" % Turrets.MOUNT_OPENS_AFTER[i]) if not open else (String(Base.BUILDINGS[id].name) if id != "" else "Empty"), 100.0, i == b_slot, col, not open)
		_num_badge(sq, col if open else UIKit.SOFT, str(i + 1))
		var si: int = i
		sq.pressed.connect(func():
			b_slot = si
			var here := String(Base.read(_read()).slots[si])
			if here != "":
				b_focus = here
			_refresh_base())
		slots.add_child(sq)
	box.add_child(slots)
	# the links live right now (Base.links): gold chips; none yet = a quiet hint
	var live: Array = Base.links(data)
	var lrow := HFlowContainer.new()
	lrow.add_theme_constant_override("h_separation", 6)
	lrow.add_theme_constant_override("v_separation", 6)
	if live.is_empty():
		lrow.add_child(UIKit.label("No links yet. Some buildings give a bonus when fielded together.", 11, UIKit.SOFT))
	for l in live:
		lrow.add_child(UIKit.chip("Link: " + String(Base.LINKS[l].name), UIKit.GOLD))
	box.add_child(lrow)
	box.add_child(_base_card(data, b))
	# every building
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for bid in Base.ORDER:
		var id := String(bid)
		var def: Dictionary = Base.BUILDINGS[id]
		var own: bool = Base.owned(b, id)
		var sub := ""
		if not own:
			sub = ("Stage %d" % int(def.from)) if not Base.can_build(data, id) else (UIKit.num(Base.build_cost(id)) if Base.build_cost(id) > 0 else "Free")
		var sq := _pick_square(Base.pic(id), String(def.name), 104.0, id == b_focus, def.col, not own, sub)
		if own:
			_num_badge(sq, def.col, ("Lv.%d" % Base.level(b, id)) if not b.slots.has(id) else ("%d · Lv.%d" % [b.slots.find(id) + 1, Base.level(b, id)]))
		var pick := id
		sq.pressed.connect(func():
			b_focus = pick
			_refresh_base())
		grid.add_child(sq)
	box.add_child(grid)
	UIKit.reveal(grid, 0.02, 8.0)

func _base_card(data: Dictionary, b: Dictionary) -> PanelContainer:
	var p := UIKit.panel(22)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	var id := b_focus
	var def: Dictionary = Base.BUILDINGS[id]
	var own: bool = Base.owned(b, id)
	var lv := Base.level(b, id)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var pic := TextureRect.new()
	pic.texture = Base.pic(id)
	pic.custom_minimum_size = Vector2(72, 72)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not own:
		pic.modulate = Color(0.6, 0.62, 0.72, 0.85)
	head.add_child(pic)
	var nv := VBoxContainer.new()
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nv.alignment = BoxContainer.ALIGNMENT_CENTER
	nv.add_theme_constant_override("separation", 5)
	nv.add_child(UIKit.title(String(def.name), 22, UIKit.TEXT))
	var tags := HBoxContainer.new()
	tags.add_theme_constant_override("separation", 8)
	tags.add_child(UIKit.chip(String(def.kind), def.col))
	if own:
		tags.add_child(UIKit.title("Lv.%d" % lv, 13, UIKit.TEXT))
	nv.add_child(tags)
	var now := UIKit.label(Base.text(id, maxi(lv, 1)), 13, UIKit.TEXT)
	now.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nv.add_child(now)
	if own and lv < Base.MAX_LEVEL:
		var nxt := UIKit.label("Next level: " + Base.text(id, lv + 1), 12, GOOD)
		nxt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nv.add_child(nxt)
	# its level-5 perk (Base.PERKS): gold once earned, a promise before
	var has_pk: bool = own and Base.has_perk(b, id)
	var pk := UIKit.label(("Perk: " if has_pk else "At Lv.%d: " % Base.PERK_LEVEL) + Base.perk_text(id), 12, UIKit.GOLD if has_pk else UIKit.SOFT)
	pk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nv.add_child(pk)
	# who it links with (Base.LINKS): gold when both are fielded
	var live_l: Array = Base.links(data)
	for lk in Base.links_of(id):
		var on_l: bool = live_l.has(String(lk.id))
		var ll := UIKit.label("%s with %s: %s" % [String(lk.name), String(Base.BUILDINGS[String(lk.with)].name), String(lk.text)], 12, UIKit.GOLD if on_l else UIKit.SOFT)
		ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nv.add_child(ll)
	head.add_child(nv)
	v.add_child(head)
	if not own:
		if not Base.can_build(data, id):
			var lock := UIKit.ghost_button("Clear stage %d to build it" % int(def.from), 13)
			lock.disabled = true
			v.add_child(lock)
		else:
			var bb := _cost_btn("BUILD", Base.build_cost(id), {}, "", true, 18)
			bb.disabled = coins < Base.build_cost(id) and not DevTools.on
			bb.pressed.connect(func(): _on_base_build(id))
			v.add_child(bb)
		return p
	var act := HBoxContainer.new()
	act.add_theme_constant_override("separation", 8)
	var why := Base.why_not_level(data, b, id)
	var up := _cost_btn("LEVEL UP", Base.level_cost(lv), Base.level_parts(lv), "MAX" if lv >= Base.MAX_LEVEL else "", true, 17)
	up.disabled = why != ""
	up.pressed.connect(func(): _on_base_level(id))
	act.add_child(up)
	var here: bool = String(b.slots[b_slot]) == id
	var open: bool = Base.slot_open(b_slot, t_unlocked) or DevTools.on
	var place := UIKit.teal_button("Slot locked" if not open else ("Remove" if here else "Place on %d" % (b_slot + 1)), 14)
	place.custom_minimum_size = Vector2(132, 62)
	place.disabled = not open
	place.pressed.connect(func():
		var d2 := _read()
		var b2 := Base.read(d2)
		Base.place(b2, b_slot, "" if String(b2.slots[b_slot]) == id else id)
		d2["base"] = Base.write(b2)
		_write_data(d2)
		Sfx.play("tap")
		_refresh_base())
	act.add_child(place)
	v.add_child(act)
	return p

func _on_base_build(id: String) -> void:
	var data := _read()
	var b := Base.read(data)
	var why := Base.build(data, b, id)
	if why != "":
		_toast(why)
		return
	if not b.slots.has(id) and String(b.slots[b_slot]) == "" and (Base.slot_open(b_slot, t_unlocked) or DevTools.on):
		Base.place(b, b_slot, id)   # a new building goes straight onto the slot you are looking at, if it is free
	data["base"] = Base.write(b)
	_write_data(data)
	coins = int(data.get("coins", 0))
	Sfx.play("buy")
	Progress.bump("turret_upgrades")
	_rarity_fx_plain(String(Base.BUILDINGS[id].name), Base.pic(id), Base.BUILDINGS[id].col, "BUILT", Base.text(id, 1))
	_refresh_base()

func _on_base_level(id: String) -> void:
	var data := _read()
	var b := Base.read(data)
	var why := Base.level_up(data, b, id)
	if why != "":
		_toast(why)
		return
	data["base"] = Base.write(b)
	_write_data(data)
	coins = int(data.get("coins", 0))
	Sfx.play("upgrade")
	Progress.bump("turret_upgrades")
	_milestone_toast("%s Lv.%d: %s" % [String(Base.BUILDINGS[id].name), Base.level(b, id), Base.text(id, Base.level(b, id))])
	_refresh_base()

# the unlock moment (moment.gd) for something built here
func _rarity_fx_plain(who: String, tex: Texture2D, col: Color, chip: String, line: String) -> void:
	Moment.show(self, {"title": who, "text": line, "tex": tex, "col": col, "chip": chip})

# capture hook (CAP_CALL="_dbg_weapons"): the Weapons screen
func _dbg_weapons() -> void:
	_weapons_screen()

# ------------------------------------------------------------------ ABILITY UPGRADES (Heroes.ABILITY_UPS, 2026-11-10)
# The Ability square on the right of the hero opens this sheet: the move, its cooldown, and his
# three upgrades in order. One gold button: the next upgrade and its price in his shards.
var _abl_layer: Control = null
var _abl_btn: Button = null

func _ability_sheet(slide: bool = true) -> void:
	var id := _view_id
	if not Heroes.owned(hero, id):
		_toast("Unlock him first")
		return
	if is_instance_valid(_abl_layer):
		_abl_layer.queue_free()
	var layer := Control.new()
	_abl_layer = layer
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var dim := Button.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.01, 0.024, 0.055, 0.62)
	for st in ["normal", "hover", "pressed", "focus"]:
		dim.add_theme_stylebox_override(st, ds)
	dim.pressed.connect(layer.queue_free)
	layer.add_child(dim)
	var slider := Control.new()
	slider.set_anchors_preset(Control.PRESET_FULL_RECT)
	slider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(slider)
	var sheet := PanelContainer.new()
	var ss := UIKit.box(UIKit.CARD, Color(1, 1, 1, 0.06), 28)
	ss.corner_radius_bottom_left = 0
	ss.corner_radius_bottom_right = 0
	ss.content_margin_left = 18
	ss.content_margin_right = 18
	ss.content_margin_top = 14
	ss.content_margin_bottom = 22
	sheet.add_theme_stylebox_override("panel", ss)
	sheet.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	slider.add_child(sheet)
	if slide:
		dim.modulate.a = 0.0
		dim.create_tween().tween_property(dim, "modulate:a", 1.0, 0.2)
		slider.position.y = 700.0
		slider.create_tween().tween_property(slider, "position:y", 0.0, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	sheet.add_child(v)
	var el := Heroes.element_of(id)
	var col := Heroes.element_color(el)
	var ab: Dictionary = Heroes.ABILITIES.get(id, {})
	var have := Heroes.ability_ups(hero, id)
	# the head: the element, the move's name, whose it is and its cooldown, Close
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var ei := TextureRect.new()
	ei.texture = UIKit.element_icon(el)
	ei.custom_minimum_size = Vector2(48, 48)
	ei.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ei.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(ei)
	var nv := VBoxContainer.new()
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nv.alignment = BoxContainer.ALIGNMENT_CENTER
	nv.add_theme_constant_override("separation", 2)
	nv.add_child(UIKit.title(String(ab.get("name", "Ability")), 22, UIKit.TEXT))
	nv.add_child(UIKit.label("%s  ·  ready every %d s" % [String(Heroes.ROSTER[id].name), roundi(Heroes.ability_cd(Heroes.tier(hero, id)))], 12, UIKit.SOFT))
	head.add_child(nv)
	var x := UIKit.ghost_button("Close", 13)
	x.custom_minimum_size = Vector2(80, 34)
	x.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	x.pressed.connect(layer.queue_free)
	head.add_child(x)
	v.add_child(head)
	var what := UIKit.label(String(ab.get("text", "")), 13, UIKit.TEXT)
	what.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(what)
	# the three upgrades, in order: bought (tick), next (ringed), later (dim)
	var ups: Array = Heroes.ABILITY_UPS.get(id, [])
	for i in ups.size():
		var u: Dictionary = ups[i]
		var got: bool = i < have
		var next: bool = i == have
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", UIKit.box(Color(UIKit.CARD_HI, 0.6 if (got or next) else 0.3), Color(col, 0.8) if next else Color(1, 1, 1, 0.05), 18, 1))
		var m := MarginContainer.new()
		for side in ["left", "right"]:
			m.add_theme_constant_override("margin_" + side, 12)
		for side in ["top", "bottom"]:
			m.add_theme_constant_override("margin_" + side, 9)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		var mark := Control.new()
		mark.custom_minimum_size = Vector2(30, 30)
		mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var n := i + 1
		mark.draw.connect(func():
			var c := Vector2(15, 15)
			if got:
				mark.draw_circle(c, 14.0, col)
				mark.draw_polyline(PackedVector2Array([c + Vector2(-6, 0), c + Vector2(-2, 5), c + Vector2(7, -5)]), UIKit.GOLD_INK, 3.0, true)
			else:
				mark.draw_arc(c, 13.0, 0.0, TAU, 32, Color(col, 0.9 if next else 0.35), 2.0, true)
				mark.draw_string(UIKit.title_font(), Vector2(0, 21.0), str(n), HORIZONTAL_ALIGNMENT_CENTER, 30.0, 15, Color(1, 1, 1, 0.95 if next else 0.4)))
		h.add_child(mark)
		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_theme_constant_override("separation", 1)
		tv.add_child(UIKit.title(String(u.name), 15, UIKit.TEXT if (got or next) else UIKit.SOFT))
		var tl := UIKit.label(String(u.text), 12, UIKit.SOFT if (got or next) else Color(UIKit.SOFT, 0.6))
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tv.add_child(tl)
		h.add_child(tv)
		if not got:
			var price := UIKit.iconed(UIKit.ic("mat_shard", "ic_shard"), str(int(Heroes.ABILITY_UP_COST[i])), 13, UIKit.TEXT if next else UIKit.SOFT, 18.0)
			price.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(price)
		m.add_child(h)
		row.add_child(m)
		v.add_child(row)
	# what he holds, and the one gold button
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	var held := UIKit.iconed(UIKit.ic("mat_shard", "ic_shard"), "%d shards" % Heroes.shards(hero, id), 13, UIKit.TEXT, 20.0)
	held.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	held.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	foot.add_child(held)
	var why := Heroes.why_not_ability_up(hero, id)
	var go := UIKit.gold_button("UPGRADE" if have < 3 else "ALL THREE BOUGHT", 16)
	go.custom_minimum_size = Vector2(210, 50)
	go.disabled = why != ""
	if why == "":
		go.pressed.connect(_on_ability_up)
	foot.add_child(go)
	v.add_child(foot)
	if why != "" and have < 3:
		v.add_child(UIKit.label("%s. Shards also pay for Ascend, so choose." % why, 11, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	elif have < 3:
		v.add_child(UIKit.label("Shards also pay for Ascend, so choose.", 11, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER))

func _on_ability_up() -> void:
	var id := _view_id
	var n := Heroes.ability_ups(hero, id)
	var why := Heroes.ability_up(hero, id)
	if why != "":
		_toast(why)
		return
	var data := _read()
	data["hero"] = Heroes.write(hero)
	_write_data(data)
	Sfx.play("level")
	_toast("%s: %s" % [String(Heroes.ABILITIES[id].name), String(Heroes.ABILITY_UPS[id][n].name)])
	_paint_hero()
	_ability_sheet(false)

# capture hook (tools/dev/capture.gd CAP_CALL="_dbg_ability")
func _dbg_ability() -> void:
	_ability_sheet()
