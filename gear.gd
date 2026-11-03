extends Control
# Gear screen: pilot on the left, the six equip slots on the right, Upgrade
# under them, and the bag (inventory) below. Tapping a bag item equips it;
# the slot tile and the pilot's power update at once. Equipment is saved in
# user://skybound_save.json under "gear". Upgrades are show-only for now:
# the cost is shown, nothing is spent until battle rewards exist.

const SLOTS := ["Helmet", "Chest", "Gauntlets", "Boots", "Power Orb", "Weapon"]
# All items: slot, rarity, power. Add items here.
const ITEMS := {
	"Sleek Helmet":   {"slot": "Helmet",    "rarity": "common",    "power": 20},
	"Teal Helmet":    {"slot": "Helmet",    "rarity": "rare",      "power": 32},
	"White Helmet":   {"slot": "Helmet",    "rarity": "rare",      "power": 34},
	"Ember Helmet":   {"slot": "Helmet",    "rarity": "epic",      "power": 48},
	"Charcoal Plate": {"slot": "Chest",     "rarity": "common",    "power": 26},
	"Teal Plate":     {"slot": "Chest",     "rarity": "rare",      "power": 40},
	"White Plate":    {"slot": "Chest",     "rarity": "rare",      "power": 42},
	"Grip Gauntlets": {"slot": "Gauntlets", "rarity": "common",    "power": 14},
	"Teal Gauntlets": {"slot": "Gauntlets", "rarity": "rare",      "power": 24},
	"Hover Boots":    {"slot": "Boots",     "rarity": "common",    "power": 16},
	"Teal Boots":     {"slot": "Boots",     "rarity": "rare",      "power": 26},
	"White Boots":    {"slot": "Boots",     "rarity": "rare",      "power": 27},
	"Purple Orb":     {"slot": "Power Orb", "rarity": "common",    "power": 30},
	"Cyan Orb":       {"slot": "Power Orb", "rarity": "epic",      "power": 55},
	"Teal Orb":       {"slot": "Power Orb", "rarity": "rare",      "power": 42},
	"Laser Pistol":   {"slot": "Weapon",    "rarity": "common",    "power": 35},
	"Dual Minis":     {"slot": "Weapon",    "rarity": "rare",      "power": 52},
	"Pulse Cannon":   {"slot": "Weapon",    "rarity": "epic",      "power": 70},
	"Nova Lance":     {"slot": "Weapon",    "rarity": "legendary", "power": 95},
}
const SLOT_ICON := {"Helmet": "nav_gear", "Chest": "starter", "Gauntlets": "patrol", "Boots": "chev_r", "Power Orb": "crystal", "Weapon": "nav_battle"}

var equipped := {"Helmet": "Sleek Helmet", "Chest": "Charcoal Plate", "Gauntlets": "Grip Gauntlets",
	"Boots": "Hover Boots", "Power Orb": "Purple Orb", "Weapon": "Laser Pistol"}
var levels := {}          # item name -> level (1 if missing)
var owned: Array = ["Sleek Helmet", "Teal Helmet", "White Helmet", "Charcoal Plate", "Teal Plate", "Grip Gauntlets", "Teal Gauntlets",
	"Hover Boots", "Teal Boots", "Purple Orb", "Cyan Orb", "Teal Orb", "Laser Pistol", "Dual Minis"]
var selected_slot := "Helmet"
var bag_tab := 0           # 0 armor, 1 weapons, 2 items

var _slot_tiles := {}
var _power_label: Label
var _detail: Label
var _bag_grid: GridContainer
var _upgrade_btn: Button
var _pilot_box: VBoxContainer
var _turret_box: VBoxContainer

# ---- turrets page ----
var coins := 0
var pilot_level := 1
var t_loadout: Array = Turrets.DEFAULT_LOADOUT.duplicate()
var t_levels := {}         # turret id -> level (1 if missing)
var t_mount := 0           # selected mount
var t_focus := ""          # turret shown in the detail panel
var _mount_row: HBoxContainer
var _turret_grid: GridContainer
var _t_detail: Label
var _t_upgrade: Button
var _t_place: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_load()
	_build()
	_select(selected_slot)
	_fade_in_overlay()

func _load() -> void:
	if FileAccess.file_exists("user://skybound_save.json"):
		var f := FileAccess.open("user://skybound_save.json", FileAccess.READ)
		if f:
			var data = JSON.parse_string(f.get_as_text())
			if typeof(data) == TYPE_DICTIONARY:
				var t := Turrets.read(data)
				t_loadout = t.loadout
				t_levels = t.levels
				coins = int(data.get("coins", 0))
				pilot_level = Turrets.pilot_level(int(data.get("pilot_xp", 0)))
			if typeof(data) == TYPE_DICTIONARY and data.has("gear"):
				var g: Dictionary = data["gear"]
				for s in SLOTS:
					if g.get("equipped", {}).has(s) and ITEMS.has(g["equipped"][s]):
						equipped[s] = g["equipped"][s]
				levels = g.get("levels", {})

func _save() -> void:
	var data := {}
	if FileAccess.file_exists("user://skybound_save.json"):
		var f := FileAccess.open("user://skybound_save.json", FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if typeof(d) == TYPE_DICTIONARY:
				data = d
	data["gear"] = {"equipped": equipped, "levels": levels}
	var out := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(data))

func _lvl(item: String) -> int:
	return int(levels.get(item, 1))

func _power() -> int:
	var p := 0
	for s in SLOTS:
		var it: String = equipped[s]
		p += int(ITEMS[it].power) * (1.0 + 0.12 * (_lvl(it) - 1))
	return p

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
	_power_label = UIKit.label("", 15, UIKit.GOLD)
	top.add_child(_power_label)
	col.add_child(top)

	# Pilot / Turrets switch
	col.add_child(UIKit.tabs(["Pilot", "Turrets"], _show_page, 0))
	_turret_box = VBoxContainer.new()
	_turret_box.add_theme_constant_override("separation", 10)
	_turret_box.visible = false
	col.add_child(_turret_box)
	_build_turrets(_turret_box)
	_pilot_box = VBoxContainer.new()
	_pilot_box.add_theme_constant_override("separation", 10)
	col.add_child(_pilot_box)
	col = _pilot_box

	# pilot + slots
	var hero_row := HBoxContainer.new()
	hero_row.add_theme_constant_override("separation", 10)
	var hero_panel := UIKit.panel()
	hero_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hv := VBoxContainer.new()
	hv.alignment = BoxContainer.ALIGNMENT_CENTER
	var pic := TextureRect.new()
	pic.texture = load("res://pilot/idle.png")
	pic.custom_minimum_size = Vector2(0, 170)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hv.add_child(pic)
	hv.add_child(UIKit.label("PILOT", 13, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	hero_panel.add_child(hv)
	hero_row.add_child(hero_panel)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for s in SLOTS:
		var t := _make_slot_tile(s)
		grid.add_child(t)
		_slot_tiles[s] = t
	hero_row.add_child(grid)
	col.add_child(hero_row)

	# upgrade + detail
	var up_row := HBoxContainer.new()
	up_row.add_theme_constant_override("separation", 10)
	_upgrade_btn = UIKit.gold_button("Upgrade")
	_upgrade_btn.custom_minimum_size = Vector2(130, 40)
	_upgrade_btn.pressed.connect(_on_upgrade_pressed)
	up_row.add_child(_upgrade_btn)
	var dp := UIKit.panel(10)
	dp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail = UIKit.label("", 12, Color(0.85, 0.92, 1.0))
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dp.add_child(_detail)
	up_row.add_child(dp)
	col.add_child(up_row)

	# bag
	col.add_child(UIKit.header("BAG"))
	col.add_child(UIKit.tabs(["Armor", "Weapons", "Thrusters"], func(i): bag_tab = i; _fill_bag(), 0))
	_bag_grid = GridContainer.new()
	_bag_grid.columns = 4
	_bag_grid.add_theme_constant_override("h_separation", 8)
	_bag_grid.add_theme_constant_override("v_separation", 8)
	col.add_child(_bag_grid)
	_fill_bag()

func _make_slot_tile(slot: String) -> Button:
	var it: String = equipped[slot]
	var t := UIKit.tile(it, "%s  Lv.%d" % [slot, _lvl(it)], ITEMS[it].rarity, "", Icons.get_icon(SLOT_ICON[slot]), Vector2(118, 86))
	t.pressed.connect(func(): _select(slot))
	return t

func _refresh_slot(slot: String) -> void:
	var old: Button = _slot_tiles[slot]
	var idx := old.get_index()
	var parent := old.get_parent()
	old.queue_free()
	var t := _make_slot_tile(slot)
	parent.add_child(t)
	parent.move_child(t, idx)
	_slot_tiles[slot] = t
	if slot == selected_slot:
		t.add_theme_stylebox_override("normal", UIKit.box(Color(UIKit.RARITY[ITEMS[equipped[slot]].rarity], 0.25), Color.WHITE, 10, 2))

func _fill_bag() -> void:
	for c in _bag_grid.get_children():
		c.queue_free()
	var want_weapon := bag_tab == 1
	if bag_tab == 2:
		for key in PilotSprite.THRUSTERS:
			var th: Dictionary = PilotSprite.THRUSTERS[key]
			var on: bool = PilotSprite.style == key
			var tt := UIKit.tile(th.name, "(on)" if on else th.desc, th.rarity, "", null, Vector2(104, 72))
			tt.pressed.connect(func(): _pick_thruster(key))
			_bag_grid.add_child(tt)
		return
	for name in owned:
		var info: Dictionary = ITEMS[name]
		if (info.slot == "Weapon") != want_weapon:
			continue
		var is_on: bool = equipped[info.slot] == name
		var t := UIKit.tile(name, info.slot + ("  (on)" if is_on else ""), info.rarity, "Lv.%d" % _lvl(name), null, Vector2(104, 72))
		t.pressed.connect(func(): _equip(info.slot, name))
		_bag_grid.add_child(t)

# ------------------------------------------------------------------ actions

func _select(slot: String) -> void:
	selected_slot = slot
	for s in SLOTS:
		var t: Button = _slot_tiles[s]
		var col: Color = UIKit.RARITY[ITEMS[equipped[s]].rarity]
		if s == slot:
			t.add_theme_stylebox_override("normal", UIKit.box(Color(col, 0.25), Color.WHITE, 10, 2))
		else:
			t.add_theme_stylebox_override("normal", UIKit.box(Color(col, 0.13), Color(col, 0.85), 10))
	var it: String = equipped[slot]
	var info: Dictionary = ITEMS[it]
	var cost := 150 * _lvl(it)
	_detail.text = "%s (%s, %s)\nPower %d at Lv.%d. Upgrade to Lv.%d: %d coins.\nSpending comes with battle rewards." % [
		it, slot, info.rarity, int(info.power * (1.0 + 0.12 * (_lvl(it) - 1))), _lvl(it), _lvl(it) + 1, cost]
	_upgrade_btn.text = "Upgrade  (%d)" % cost
	_power_label.text = "POWER %d" % _power()

func _equip(slot: String, item: String) -> void:
	equipped[slot] = item
	_save()
	_refresh_slot(slot)
	_select(slot)
	_fill_bag()

func _pick_thruster(key: String) -> void:
	PilotSprite.style = key
	var data := {}
	if FileAccess.file_exists("user://skybound_save.json"):
		var f := FileAccess.open("user://skybound_save.json", FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if typeof(d) == TYPE_DICTIONARY:
				data = d
	data["thruster"] = key
	var out := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(data))
	_detail.text = "Thruster: %s. %s" % [PilotSprite.THRUSTERS[key].name, PilotSprite.THRUSTERS[key].desc]
	_fill_bag()

func _on_upgrade_pressed() -> void:
	var it: String = equipped[selected_slot]
	_detail.text = "%s: upgrade to Lv.%d would cost %d coins.\nNo spending yet; battle rewards enable it." % [it, _lvl(it) + 1, 150 * _lvl(it)]

# ------------------------------------------------------------------ turrets page
# Four mounts across the top (left to right, as on the base deck), the six
# turrets below. Tap a mount, then a turret to place it there; a turret stands
# on one mount at most, so placing it again moves it. Upgrades spend coins.

func _show_page(i: int) -> void:
	_pilot_box.visible = i == 0
	_turret_box.visible = i == 1
	if i == 1:
		_refresh_turrets()
	else:
		_power_label.text = "POWER %d" % _power()

func _save_turrets() -> void:
	var data := {}
	if FileAccess.file_exists("user://skybound_save.json"):
		var f := FileAccess.open("user://skybound_save.json", FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if typeof(d) == TYPE_DICTIONARY:
				data = d
	data["turrets"] = {"loadout": t_loadout, "levels": t_levels}
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
	var btns := VBoxContainer.new()
	btns.add_theme_constant_override("separation", 8)
	_t_upgrade = UIKit.gold_button("Upgrade", 14)
	_t_upgrade.custom_minimum_size = Vector2(130, 40)
	_t_upgrade.pressed.connect(_on_turret_upgrade)
	btns.add_child(_t_upgrade)
	_t_place = UIKit.teal_button("Place")
	_t_place.custom_minimum_size = Vector2(130, 36)
	_t_place.pressed.connect(_on_turret_place)
	btns.add_child(_t_place)
	row.add_child(btns)
	var dp := UIKit.panel(10)
	dp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_t_detail = UIKit.label("", 12, Color(0.85, 0.92, 1.0))
	_t_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_t_detail.custom_minimum_size = Vector2(0, 84)
	dp.add_child(_t_detail)
	row.add_child(dp)
	box.add_child(row)
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
		if id == "":
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
	if t_focus == "":
		_t_detail.text = "Mount %d is empty.\nPick a turret below, then Place." % (t_mount + 1)
		_t_upgrade.disabled = true
		_t_upgrade.text = "Upgrade"
		_t_place.disabled = true
		_t_place.text = "Place"
		return
	var def: Dictionary = Turrets.TURRETS[t_focus]
	var lvl := _t_lvl(t_focus)
	var locked: bool = pilot_level < int(def.unlock)
	var lines := "%s  Lv.%d  (%s)\n%s" % [def.name, lvl, Turrets.strong_text(t_focus), def.desc]
	if locked:
		lines += "\nUnlocks at pilot level %d (you are %d)." % [def.unlock, pilot_level]
	elif not def.ready:
		lines += "\nIn development: coming in a later build."
	elif lvl < Turrets.MAX_LEVEL:
		lines += "\nDamage x%.2f now, x%.2f at Lv.%d." % [Turrets.level_mult(lvl), Turrets.level_mult(lvl + 1), lvl + 1]
	_t_detail.text = lines
	var cost := Turrets.upgrade_cost(lvl)
	var usable: bool = not locked and def.ready
	_t_upgrade.disabled = not usable or lvl >= Turrets.MAX_LEVEL or coins < cost
	_t_upgrade.text = "MAX" if lvl >= Turrets.MAX_LEVEL else "Upgrade  (%d)" % cost
	var here: bool = t_loadout[t_mount] == t_focus
	_t_place.disabled = not usable
	_t_place.text = "Remove" if here else "Place on %d" % (t_mount + 1)

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

func _on_turret_upgrade() -> void:
	var lvl := _t_lvl(t_focus)
	var cost := Turrets.upgrade_cost(lvl)
	if t_focus == "" or coins < cost or lvl >= Turrets.MAX_LEVEL:
		return
	coins -= cost
	t_levels[t_focus] = lvl + 1
	_save_turrets()
	_refresh_turrets()

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
