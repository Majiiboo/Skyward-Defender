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
var _plat                    # PlatformFloor (set-bonus glow)
const SLOT_PX := 84.0       # gear slot tiles around the pilot

# ---- turrets page ----
var coins := 0
var pilot_level := 1
var t_loadout: Array = Turrets.DEFAULT_LOADOUT.duplicate()
var t_levels := {}         # turret id -> level (1 if missing)
var t_mount := 0           # selected mount
var t_unlocked := 1        # save stage_unlocked: which mounts are open (Turrets.mount_open)
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
	coins = int(data.get("coins", 0))
	pilot_level = Turrets.pilot_level(int(data.get("pilot_xp", 0)))
	t_unlocked = int(data.get("stage_unlocked", 1))
	gear = GearData.read(data)

func _save() -> void:
	var data := _read()
	data["gear"] = {"equipped": gear.equipped, "levels": gear.levels}
	data["coins"] = coins
	# the jetpack sets the thruster style (the Home wallpaper reads "thruster")
	data["thruster"] = GearData.SETS[GearData.ITEMS[gear.equipped["Jetpack"]].set].thruster
	var out := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(data))

func _lvl(id: String) -> int:
	return GearData.level(gear, id)

func _pic(id: String) -> Texture2D:
	return load("res://gear/%s.png" % id)

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
	# set bonuses you have
	var bp := UIKit.panel(10)
	_bonus = UIKit.label("", 12, Color(0.85, 0.92, 1.0))
	_bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bp.add_child(_bonus)
	col.add_child(bp)
	# selected piece: stats + upgrade
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
	# the three pieces for this slot
	col.add_child(UIKit.header("CHOOSE"))
	_bag_grid = GridContainer.new()
	_bag_grid.columns = 3
	_bag_grid.add_theme_constant_override("h_separation", 8)
	_bag_grid.add_theme_constant_override("v_separation", 8)
	col.add_child(_bag_grid)

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
		var sub := "Wearing" if is_on else ("Lv.%d" % _lvl(id) if open else "Clear stage %d" % (int(GearData.SETS[set_id].unlock_stage) - 1))
		var t := UIKit.tile(info.name, sub, set_id, GearData.SETS[set_id].name, _pic(id), Vector2(108, 96))
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
	var next_txt := _stat_text(slot, lv + 1) if lv < GearData.MAX_LEVEL else "max level"
	_detail.text = "%s  (%s set)  Lv.%d\n%s: %s  ->  %s\nSet stat: %s" % [info.name, set_info.name, lv, st.text, _stat_text(slot, lv), next_txt, set_info.minor]
	if slot == "Weapon":
		_detail.text += "\nWeapon: %s" % {"laser_pistol": "steady single bolts", "dual_minis": "two bolts side by side", "pulse_cannon": "slow, heavy bolts"}[set_info.weapon]
	if slot == "Jetpack":
		_detail.text += "\nThruster: %s" % PilotSprite.THRUSTERS[set_info.thruster].name
	var cost := GearData.upgrade_cost(lv)
	_upgrade_btn.disabled = lv >= GearData.MAX_LEVEL or coins < cost
	_upgrade_btn.text = "MAX" if lv >= GearData.MAX_LEVEL else "Upgrade\n%d coins" % cost
	_power_label.text = "POWER %d  ·  %d coins" % [GearData.power(gear), coins]
	var lines: Array = []
	for set_id in GearData.SETS:
		var n := GearData.set_count(gear, set_id)
		if n == 0:
			continue
		var s: Dictionary = GearData.SETS[set_id]
		lines.append("%s %d/6:  %s %s  ·  %s %s" % [s.name, n, "ON" if n >= 3 else "(3)", s.bonus3, "ON" if n >= 6 else "(6)", s.bonus6])
	_bonus.text = "SET BONUSES\n" + "\n".join(lines)
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
			return "+%d%%%s" % [int(per * lv * 100.0), (", +%d heart" % hearts) if hearts > 0 else ""]
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
	coins -= cost
	gear.levels[id] = lv + 1
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
	if i == 1:
		_refresh_turrets()
	else:
		_select(selected_slot)

# The pilot standing in the Gear screen: the same live rig as in battle, idling, his
# rifle drifting, flames in the equipped jetpack's style.
class PilotShowcase extends Control:
	var view: PilotRigView
	var plat   # PlatformFloor: where his feet go
	var t := 0.0
	func _ready() -> void:
		view = PilotRigView.new()
		view.height = 156.0
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
			_light_layer.draw_texture_rect(_floor_lights, r, false, Color(glow_col, k * 0.35))
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
			draw_texture_rect(_tex, tr, false)
			if _floor_lights and k > 0.01:
				draw_texture_rect(_floor_lights, tr, false, Color(glow_col, 0.8 * k))
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
		_t_detail.text = "Mount %d opens after you clear stage %d." % [t_mount + 1, Turrets.MOUNT_OPENS_AFTER[t_mount]]
		_t_upgrade.disabled = true
		_t_upgrade.text = "Upgrade"
		_t_place.disabled = true
		_t_place.text = "Locked"
		return
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
	if not Turrets.mount_open(t_mount, t_unlocked):
		_t_detail.text = "Mount %d opens after you clear stage %d.\n\n" % [t_mount + 1, Turrets.MOUNT_OPENS_AFTER[t_mount]] + lines
		_t_place.disabled = true
		_t_place.text = "Locked"

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
