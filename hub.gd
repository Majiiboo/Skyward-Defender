extends Control
# Home hub (v3 layout). Layers, bottom to top:
#   Background, AFK (live battle wallpaper, untouchable), Dim, ViewContainer
#   (menu screens, created in code), Safe/Home (the Home buttons, built in
#   _build_home), NavDock (the bar + notch drawing), NavBar (the tab buttons),
#   popup panels.
# The Home buttons are made in code from the tables below, so adding or
# changing a button means editing a table, not hunting through a scene.

const NAV_TABS := ["NavStore", "NavGear", "NavBattle", "NavModes", "NavQuests"]
const NAV_DIM := Color(0.42, 0.45, 0.55, 1.0)   # look of an inactive tab icon (painted icons: darker and greyer)
const NAV_LIFT := -10.0                          # how far the active icon rises
const NAV_BUMP := 14.0                           # notch height (nav_dock.gd bump_h)

const CYAN := Color(0.18, 0.9, 1.0)
const PURPLE := Color(0.71, 0.55, 1.0)
const GOLD := Color(1.0, 0.8, 0.3)
const MUTED := Color(0.62, 0.70, 0.84)
const GLASS_FILL := Color(0.03, 0.045, 0.10, 0.5)
const GLASS_LINE := Color(1, 1, 1, 0.10)

# Small text under these round buttons (the ones whose icon isn't obvious).
# Add or remove node names here to try different combinations.
const LABELED := ["ChestButton", "PatrolButton", "StarterButton", "GiftsButton"]

const NAV_ICONS := {"NavStore": "nav_store", "NavGear": "nav_gear", "NavBattle": "nav_battle",
	"NavModes": "nav_modes", "NavQuests": "nav_quests"}

# Galactic stage names. Same places in both modes; Elite is the darker twist.
const STAGE_NAMES := {
	"Normal": ["Ember Reach", "Nova Drift", "Cinder Belt", "Halo Verge", "Ion Fields"],
	"Elite": ["Void Ember Reach", "Black Nova Drift", "Hollow Cinder Belt", "Eclipsed Halo Verge", "Storm Ion Fields"],
}

# Side buttons. "dot" = red notification dot. Events, offers and promos will go here later.
const LEFT_RAIL := [
	{"id": "EventButton", "icon": "event", "label": "Event", "dot": true,
		"title": "EVENT", "body": "Seasonal event: coming soon.\nThis side slot is for events\nand promotions."},
	{"id": "PromoButton", "icon": "promo", "label": "Promo", "dot": false,
		"title": "PROMO", "body": "Special deal: coming soon.\nThis side slot is for deals\nand bundles."},
	{"id": "StarterButton", "icon": "starter", "label": "Starter", "dot": false,
		"title": "STARTER", "body": "Starter pack: test only.\nSimple card, no purchase yet."},
]
const RIGHT_RAIL := [
	{"id": "DailyButton", "icon": "daily", "label": "Daily", "dot": true,
		"title": "DAILY", "body": "Daily check-in: coming soon.\nClaim will be here."},
	{"id": "GiftsButton", "icon": "gifts", "label": "Gifts", "dot": false,
		"title": "GIFTS", "body": "Gifts: coming soon.\nClaimable gifts will list here."},
	{"id": "RanksButton", "icon": "ranks", "label": "Ranks", "dot": false,
		"title": "RANKS", "body": "Rankings: coming soon.\nLeaderboard will list here."},
]

var stage := 1
var mode := "Normal"
var elite_unlocked := false
var level := 1
var coins := 0
var crystals := 0
var best_score := 0
var best_kills := 0
var stage_unlocked := 1

var _transitioning := false
var _nav_dock: NavDock = null
var _nav_empty: StyleBoxEmpty = null
var _nav_active := "NavBattle"
var _pulse_tween: Tween = null
var _view_container: Control = null
var _current_view: Control = null
var _current_view_name := "NavBattle"

# Home widgets (built in _build_home)
var _stage_block: Control
var _action_row: Control
var _mode_tag: Label
var _stage_btn: Button
var _std_btn: Button
var _elite_btn: Button
var _coin_btn: Button
var _crystal_btn: Button
var _tag_timer: SceneTreeTimer = null
var _frame: HomeFrame = null
var _nav_layers := {}   # tab name -> {layer name: TextureRect}

func _ready() -> void:
	size = get_viewport_rect().size
	var th := load("res://game_theme.tres")
	if th: theme = th
	_load_save()
	_frame = HomeFrame.new()
	_frame.name = "HomeFrame"
	add_child(_frame)
	move_child(_frame, $Safe.get_index())
	_build_home()
	_setup_nav()
	_build_layered_nav_icons()
	MenuAnim.pop_buttons($Safe)
	_wire_panels()
	_update_stage_label()
	_hide_panels()
	_fade_in_overlay()
	_setup_view_manager()
	call_deferred("_animate_nav_in")

func _load_save() -> void:
	if FileAccess.file_exists("user://skybound_save.json"):
		var f := FileAccess.open("user://skybound_save.json", FileAccess.READ)
		if f:
			var data = JSON.parse_string(f.get_as_text())
			if typeof(data) == TYPE_DICTIONARY:
				coins = int(data.get("coins", 0))
				best_score = int(data.get("best_score", 0))
				best_kills = int(data.get("best_kills", 0))
				stage_unlocked = int(data.get("stage_unlocked", 1))
				stage = clampi(int(data.get("selected_stage", 1)), 1, stage_unlocked)
				mode = "Elite" if bool(data.get("selected_elite", false)) else "Normal"
				var px := int(data.get("pilot_xp", 0))
				level = Turrets.pilot_level(px)
				elite_unlocked = level >= 10

# ---------------------------------------------------------------- styles

func _glass(radius: float, line: Color = GLASS_LINE, fill: Color = GLASS_FILL, shrink: float = 0.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.set_border_width_all(1)
	s.border_color = line
	s.set_corner_radius_all(int(radius))
	s.anti_aliasing = true
	# Negative expand = the drawn shape is smaller than the tappable area.
	s.expand_margin_left = -shrink
	s.expand_margin_right = -shrink
	s.expand_margin_top = -shrink
	s.expand_margin_bottom = -shrink
	return s

func _style_button(b: Button, normal: StyleBoxFlat, pressed: StyleBoxFlat) -> void:
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _icon_button(node_name: String, icon_name: String, tap: float, drawn: float, icon_px: int, line: Color = GLASS_LINE) -> Button:
	# A round glass button: `tap` px to touch, `drawn` px to look at.
	var b := Button.new()
	b.name = node_name
	b.custom_minimum_size = Vector2(tap, tap)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.icon = Icons.get_icon(icon_name)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	b.add_theme_constant_override("icon_max_width", icon_px)
	var inset := (tap - drawn) / 2.0
	_style_button(b, _glass(drawn / 2.0, line, GLASS_FILL, inset),
		_glass(drawn / 2.0, CYAN, Color(CYAN, 0.25), inset))
	return b

func _add_dot(b: Control) -> void:
	var d := Panel.new()
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1.0, 0.35, 0.42)
	s.set_corner_radius_all(5)
	s.set_border_width_all(1)
	s.border_color = Color(0.04, 0.06, 0.17)
	d.add_theme_stylebox_override("panel", s)
	d.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	d.offset_left = -13.0
	d.offset_right = -3.0
	d.offset_top = 3.0
	d.offset_bottom = 13.0
	b.add_child(d)

func _small_label(text: String, size_px: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _rail_item(def: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", -2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b := _icon_button(def.id, def.icon, 58.0, 50.0, 44, Color(0, 0, 0, 0))
	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	box.add_child(b)
	if def.dot:
		_add_dot(b)
	if def.id in LABELED:
		box.add_child(_small_label(def.label, 12, MUTED))
	b.pressed.connect(func(): _side_popup(def.title, def.body))
	return box

# ------------------------------------------------------------- Home build

func _build_home() -> void:
	var home: Control = $Safe/Home
	# ---- top bar: profile, currencies, menu ----
	var top := HBoxContainer.new()
	top.name = "TopBar"
	top.add_theme_constant_override("separation", 8)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	home.add_child(top)
	# Left dock group: profile + currencies sit in one tab attached to the left edge
	var dockL := HBoxContainer.new()
	dockL.name = "TopDock"
	dockL.add_theme_constant_override("separation", 6)
	dockL.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(dockL)
	var profile := _icon_button("ProfileButton", "profile", 44.0, 38.0, 30, Color(PURPLE, 0.7))
	var lv := _small_label(str(level), 11, Color.WHITE)
	lv.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	lv.offset_left = -17.0
	lv.offset_top = -17.0
	lv.offset_right = -1.0
	lv.offset_bottom = -1.0
	lv.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var lv_style := _glass(8.0, CYAN, Color(0.04, 0.06, 0.17, 0.95))
	lv.add_theme_stylebox_override("normal", lv_style)
	profile.add_child(lv)
	profile.pressed.connect(func(): _side_popup("PROFILE", "Pilot\nLevel %d\nProfile and account\nsettings will live here." % level))
	dockL.add_child(profile)
	_coin_btn = _pill_button("CoinButton", "coin", _fmt(coins))
	_coin_btn.pressed.connect(func(): _side_popup("COINS", "Coins: earned by defeating enemies.\nYou keep them between runs."))
	dockL.add_child(_coin_btn)
	_crystal_btn = _pill_button("CrystalButton", "crystal", _fmt(crystals))
	_crystal_btn.pressed.connect(func(): _side_popup("CRYSTALS", "Crystals: premium currency.\nComing soon."))
	dockL.add_child(_crystal_btn)
	var open := _icon_button("OpenCurrencyButton", "plus", 36.0, 26.0, 14, Color(CYAN, 0.4))
	open.pressed.connect(func(): _side_popup("RESOURCES", "Room for one more resource\nor currency later."))
	dockL.add_child(open)
	_frame.add_dock(top, 0, Vector2(0, 3))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)
	var menu := _icon_button("MenuButton", "menu", 44.0, 32.0, 16)
	menu.pressed.connect(func(): _side_popup("MENU", "Settings\nMail\nLog-in rewards\nCommunity\n\n(coming soon)"))
	top.add_child(menu)

	# ---- stage block: mode tag, stage name with arrows, Standard / Elite ----
	var sb := VBoxContainer.new()
	sb.name = "StageBlock"
	sb.add_theme_constant_override("separation", 0)
	sb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sb.alignment = BoxContainer.ALIGNMENT_CENTER
	sb.set_anchors_preset(Control.PRESET_CENTER_TOP)
	sb.grow_horizontal = Control.GROW_DIRECTION_BOTH
	sb.offset_top = 60.0
	home.add_child(sb)
	_stage_block = sb
	_mode_tag = _small_label("STANDARD 1", 13, CYAN)
	sb.add_child(_mode_tag)
	var name_row := HBoxContainer.new()
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	name_row.add_theme_constant_override("separation", 4)
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sb.add_child(name_row)
	var prev := _arrow_button("PrevButton", "chev_l")
	prev.pressed.connect(func(): _change_stage(-1))
	name_row.add_child(prev)
	_stage_btn = Button.new()
	_stage_btn.name = "StageNameButton"
	_stage_btn.flat = true
	_stage_btn.custom_minimum_size = Vector2(210, 42)
	_stage_btn.add_theme_font_size_override("font_size", 22)
	_stage_btn.add_theme_font_override("font", load("res://fonts/Orbitron-Variable.ttf"))
	_stage_btn.add_theme_color_override("font_color", Color.WHITE)
	_stage_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	_stage_btn.add_theme_color_override("font_pressed_color", CYAN)
	for st in ["normal", "hover", "pressed", "focus"]:
		_stage_btn.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	_stage_btn.pressed.connect(func(): _show_panel($SelectPanel))
	name_row.add_child(_stage_btn)
	var next := _arrow_button("NextButton", "chev_r")
	next.pressed.connect(func(): _change_stage(1))
	name_row.add_child(next)
	var toggle := PanelContainer.new()
	toggle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	toggle.add_theme_stylebox_override("panel", _glass(15.0))
	var seg := HBoxContainer.new()
	seg.add_theme_constant_override("separation", 0)
	toggle.add_child(seg)
	_std_btn = _segment_button("NormalButton", "Standard")
	_std_btn.pressed.connect(func(): _set_mode("Normal"))
	seg.add_child(_std_btn)
	_elite_btn = _segment_button("EliteButton", "Elite")
	_elite_btn.pressed.connect(func(): _set_mode("Elite"))
	seg.add_child(_elite_btn)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sb.add_child(gap)
	sb.add_child(toggle)

	# ---- side rails (events, offers, daily rewards) ----
	var left := VBoxContainer.new()
	left.name = "LeftRail"
	left.add_theme_constant_override("separation", 12)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.set_anchors_preset(Control.PRESET_TOP_LEFT)
	left.offset_top = 124.0
	left.offset_left = -4.0
	home.add_child(left)
	for d in LEFT_RAIL:
		left.add_child(_rail_item(d))
	var right := VBoxContainer.new()
	right.name = "RightRail"
	right.add_theme_constant_override("separation", 12)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	right.offset_top = 124.0
	right.offset_right = 4.0
	home.add_child(right)
	for d in RIGHT_RAIL:
		right.add_child(_rail_item(d))

	# ---- bottom row: START centred, Chest and Patrol docked to the screen edges ----
	var row := Control.new()
	row.name = "ActionRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	row.custom_minimum_size = Vector2(0, 62)
	row.offset_top = -62.0
	home.add_child(row)
	_action_row = row
	var chest := _action_item("ChestButton", "chest_closed", "Chest", func():
		_chest_open_fx()
		_show_panel($InfoPanel))
	chest.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	chest.grow_horizontal = Control.GROW_DIRECTION_END
	chest.grow_vertical = Control.GROW_DIRECTION_BOTH
	chest.offset_left = 2.0
	chest.offset_top = -128.0
	chest.offset_bottom = -128.0
	row.add_child(chest)
	_frame.add_dock(chest, -1, Vector2(4, 1))
	var start := _battle_button()
	start.set_anchors_preset(Control.PRESET_CENTER)
	start.grow_horizontal = Control.GROW_DIRECTION_BOTH
	start.grow_vertical = Control.GROW_DIRECTION_BOTH
	row.add_child(start)
	var patrol := _action_item("PatrolButton", "patrol", "Patrol", func(): _show_panel($PatrolPanel))
	patrol.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	patrol.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	patrol.grow_vertical = Control.GROW_DIRECTION_BOTH
	patrol.offset_right = -2.0
	patrol.offset_top = -128.0
	patrol.offset_bottom = -128.0
	row.add_child(patrol)
	_frame.add_dock(patrol, 1, Vector2(4, 1))

func _action_item(node_name: String, icon_name: String, label: String, on_press: Callable) -> Control:
	# Round button + optional small label, same size for Chest and Patrol so they line up.
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", -6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var b := _icon_button(node_name, icon_name, 46.0, 40.0, 38, Color(0, 0, 0, 0))
	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	b.pressed.connect(on_press)
	box.add_child(b)
	if node_name in LABELED:
		box.add_child(_small_label(label, 11, MUTED))
	return box

func _pill_button(node_name: String, icon_name: String, text: String) -> Button:
	var b := Button.new()
	b.name = node_name
	b.text = text
	b.icon = Icons.get_icon(icon_name)
	b.add_theme_constant_override("icon_max_width", 20)
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", Color(0.87, 0.97, 1.0))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.custom_minimum_size = Vector2(0, 36)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var n := _glass(13.0)
	n.expand_margin_top = -5.0
	n.expand_margin_bottom = -5.0
	n.content_margin_left = 10.0
	n.content_margin_right = 12.0
	var p := _glass(13.0, CYAN, Color(CYAN, 0.25))
	p.expand_margin_top = -5.0
	p.expand_margin_bottom = -5.0
	p.content_margin_left = 10.0
	p.content_margin_right = 12.0
	_style_button(b, n, p)
	return b

func _arrow_button(node_name: String, icon_name: String) -> Button:
	var b := Button.new()
	b.name = node_name
	b.flat = true
	b.icon = Icons.get_icon(icon_name)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	b.add_theme_constant_override("icon_max_width", 18)
	b.custom_minimum_size = Vector2(40, 42)
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	b.modulate = Color(1, 1, 1, 0.75)
	return b

func _segment_button(node_name: String, text: String) -> Button:
	var b := Button.new()
	b.name = node_name
	b.text = text
	b.custom_minimum_size = Vector2(100, 34)
	b.add_theme_font_size_override("font_size", 14)
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	return b

func _battle_button() -> Button:
	var b := Button.new()
	b.name = "BattleButton"
	b.custom_minimum_size = Vector2(170, 46)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var n := _glass(23.0, Color(CYAN, 0.9), Color(CYAN, 0.14))
	n.set_border_width_all(1)
	n.shadow_color = Color(CYAN, 0.18)
	n.shadow_size = 6
	var p := _glass(23.0, CYAN, Color(CYAN, 0.3))
	p.set_border_width_all(2)
	_style_button(b, n, p)
	# Icon + word, centred together, so they can never overlap.
	var content := HBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 10)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	icon.texture = Icons.get_icon("play_small")
	icon.custom_minimum_size = Vector2(18, 18)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)
	var word := Label.new()
	word.text = "START"
	word.add_theme_font_size_override("font_size", 17)
	word.add_theme_color_override("font_color", Color.WHITE)
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(word)
	b.add_child(content)
	b.pressed.connect(func(): _smooth_change_scene("res://battle.tscn"))
	# slow breathing glow
	var tw := create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(n, "shadow_size", 10, 1.4)
	tw.tween_property(n, "shadow_size", 4, 1.4)
	return b

func _fmt(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out

# ----------------------------------------------------------- nav setup

func _setup_nav() -> void:
	for tab in NAV_TABS:
		var nb := _nav_btn(tab)
		nb.icon = Icons.get_icon(NAV_ICONS[tab])
		nb.modulate = Color.WHITE if tab == "NavBattle" else NAV_DIM
	# The bar's look is drawn by nav_dock.gd; the PanelContainer only keeps padding.
	var bar_box := StyleBoxEmpty.new()
	bar_box.content_margin_top = 10
	bar_box.content_margin_bottom = 8
	bar_box.content_margin_left = 8
	bar_box.content_margin_right = 8
	$NavBar.add_theme_stylebox_override("panel", bar_box)
	$NavBar/NavVBox.add_theme_constant_override("separation", -8)
	_nav_empty = StyleBoxEmpty.new()
	for tab in NAV_TABS:
		var nb := _nav_btn(tab)
		for state in ["normal", "hover", "pressed", "focus"]:
			nb.add_theme_stylebox_override(state, _nav_empty)
		nb.expand_icon = true
		var nl := _nav_label(tab)
		nl.add_theme_font_size_override("font_size", 12)
		nl.add_theme_color_override("font_color", GOLD)
		nl.custom_minimum_size.y = 16
	_nav_label("NavBattle").modulate.a = 0.0
	for tab in NAV_TABS:
		var btn := _nav_btn(tab)
		var path := ""
		match tab:
			"NavStore": path = "res://store.tscn"
			"NavGear": path = "res://gear.tscn"
			"NavModes": path = "res://modes.tscn"
			"NavQuests": path = "res://quests.tscn"
		btn.pressed.connect(func(): _on_nav_tap(tab, path))

func _setup_view_manager() -> void:
	# ViewContainer holds the Gear/Modes/Quests/Store screens. It sits above the
	# wallpaper and below the nav, so the nav + notch stay on every menu.
	_view_container = Control.new()
	_view_container.name = "ViewContainer"
	_view_container.clip_contents = true
	_view_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_view_container)
	move_child(_view_container, $Safe.get_index())
	_nav_dock = NavDock.new()
	_nav_dock.name = "NavDock"
	add_child(_nav_dock)
	move_child(_nav_dock, $NavBar.get_index())
	_nav_dock.setup($NavBar)
	_nav_dock.snap_to_tab(_nav_btn("NavBattle"), 0)

func _animate_nav_in() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_nav_active = "NavBattle"
	for tab in NAV_TABS:
		var b := _nav_btn(tab)
		var slot := b.get_parent() as Control
		b.position.x = (slot.size.x - b.size.x) / 2.0
		b.pivot_offset = b.size / 2.0
		var on: bool = tab == "NavBattle"
		b.position.y = NAV_LIFT if on else 0.0
		b.scale = Vector2.ONE * (1.08 if on else 1.0)
	_nav_dock.snap_to_tab(_nav_btn("NavBattle"), 0)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_nav_label("NavBattle"), "modulate:a", 1.0, 0.30)
	_start_nav_pulse()

# ------------------------------------------------------------ per frame

func _process(_delta: float) -> void:
	# Base picture of each layered nav icon fades out only once the top picture is
	# over half in, so a cross-fade never shows a see-through dip or both at once.
	for tab in _nav_layers:
		var L: Dictionary = _nav_layers[tab]
		for pair in [["on", "off"], ["lit", "dim"]]:
			if L.has(pair[0]):
				L[pair[1]].modulate.a = clampf((1.0 - L[pair[0]].modulate.a) * 2.0, 0.0, 1.0)
	# Follow the real screen size (tall phones settle after first frame).
	var vp := get_viewport_rect().size
	if size != vp:
		size = vp
	var nb: Control = $NavBar
	# Keep the Home buttons above the nav bar and its notch.
	var pad := int(nb.size.y + NAV_BUMP + 10.0)
	if $Safe.get_theme_constant("margin_bottom") != pad:
		$Safe.add_theme_constant_override("margin_bottom", pad)
	# Menu screens fill the area above the nav bar.
	if _view_container != null:
		_view_container.position = Vector2.ZERO
		_view_container.size = Vector2(size.x, nb.get_global_rect().position.y)
	if _frame != null:
		_frame.visible = $Safe.visible
		_frame.line_top_y = $Safe/Home.get_node("TopBar").get_global_rect().end.y + 10.0
		_frame.line_bottom_y = nb.get_global_rect().position.y - NAV_BUMP + 2.0
	# Tell the wallpaper where the soldier may fly (between the stage name and the bottom row).
	if $Safe.visible:
		$AFK.fly_top = _stage_block.get_global_rect().end.y + 30.0
		$AFK.fly_bottom = _action_row.get_global_rect().position.y - 24.0
	# Keep each nav button centred in its slot (x only; tweens own y and scale).
	for tab in NAV_TABS:
		var btn := _nav_btn(tab)
		var cx := ((btn.get_parent() as Control).size.x - btn.size.x) / 2.0
		if absf(btn.position.x - cx) > 1.0:
			btn.position.x = cx

# ----------------------------------------------------- stage / mode / panels

func _update_stage_label() -> void:
	var is_elite := mode == "Elite"
	var sec := StageData.sector(stage)
	_mode_tag.text = "%s %d  ·  %s" % ["ELITE" if is_elite else "STANDARD", stage, String(sec.name).to_upper()]
	_mode_tag.add_theme_color_override("font_color", PURPLE if is_elite else CYAN)
	_stage_btn.text = StageData.stage_name(stage)
	_stage_btn.modulate.a = 1.0 if stage <= stage_unlocked else 0.5
	_paint_segment(_std_btn, not is_elite, true)
	_paint_segment(_elite_btn, is_elite, false)
	$AFK.set_elite(is_elite)
	var lines := PackedStringArray(["Select Stage", ""])
	for i in range(maxi(1, stage - 3), mini(30, stage + 3) + 1):
		var tail := "  (current)" if i == stage else ("" if i <= stage_unlocked else "  [locked]")
		lines.append("Stage %d: %s%s" % [i, StageData.stage_name(i), tail])
	$SelectPanel/SelectLabel.text = "\n".join(lines)
	$SelectPanel/SelectGo.text = "Go to Stage %d" % stage
	var w := StageData.waves(stage)
	var kinds := {}
	for wv in w:
		for entry in wv:
			kinds[entry[0]] = true
	$InfoPanel/InfoLabel.text = "%s %d: %s\nSector: %s\nWaves: %d\nEnemies: %s\nBest run: Score %d, Kills %d" % [
		"Elite" if is_elite else "Standard", stage, StageData.stage_name(stage), sec.name, w.size(), ", ".join(kinds.keys()).replace("_", " "), best_score, best_kills]

func _paint_segment(b: Button, selected: bool, left: bool) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(PURPLE if not left else CYAN, 0.32) if selected else Color(0, 0, 0, 0)
	s.corner_radius_top_left = 14 if left else 0
	s.corner_radius_bottom_left = 14 if left else 0
	s.corner_radius_top_right = 0 if left else 14
	s.corner_radius_bottom_right = 0 if left else 14
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, s)
	b.add_theme_color_override("font_color", Color.WHITE if selected else MUTED)
	b.add_theme_color_override("font_hover_color", Color.WHITE)

func _set_mode(m: String) -> void:
	if m == "Elite" and not elite_unlocked:
		_mode_tag.text = "ELITE UNLOCKS AT LEVEL 10"
		_mode_tag.add_theme_color_override("font_color", GOLD)
		_tag_timer = get_tree().create_timer(1.8)
		_tag_timer.timeout.connect(_update_stage_label)
		return
	mode = m
	_write_selection()
	_update_stage_label()

func _change_stage(d: int) -> void:
	stage = clampi(stage + d, 1, stage_unlocked)
	_write_selection()
	_update_stage_label()

func _write_selection() -> void:
	var data := {}
	if FileAccess.file_exists("user://skybound_save.json"):
		var f := FileAccess.open("user://skybound_save.json", FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if typeof(d) == TYPE_DICTIONARY:
				data = d
	data["selected_stage"] = stage
	data["selected_elite"] = mode == "Elite"
	var out := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(data))

func _wire_panels() -> void:
	$SelectPanel/SelectClose.pressed.connect(func(): _hide_panels())
	$SelectPanel/SelectGo.pressed.connect(func(): _smooth_change_scene("res://battle.tscn"))
	$PatrolPanel/PatrolClose.pressed.connect(func(): _hide_panels())
	$PatrolPanel/PatrolClaim.pressed.connect(func(): $PatrolPanel/PatrolLabel.text = "Auto-Patrol Gain\nCoins 34/h, Parts 8/h\nClaim will give 612 coins, 18 parts, 144 gems (show-only).\nNo granting yet: battle rewards update enables it.")
	$InfoPanel/InfoClose.pressed.connect(func(): _hide_panels())
	$SidePanel/SideClose.pressed.connect(func(): _hide_panels())

func _set_home_visible(visible: bool) -> void:
	# Home content on/off. The nav stays. The wallpaper is paused in menu views.
	$Safe.visible = visible
	$AFK.visible = visible
	$Dim.visible = visible
	if visible:
		$AFK.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		_hide_panels()
		$AFK.process_mode = Node.PROCESS_MODE_DISABLED

func _on_nav_tap(tapped: String, path: String) -> void:
	if _transitioning: return
	_transitioning = true
	_stop_nav_pulse()
	var edge := -1 if tapped == "NavStore" else (1 if tapped == "NavQuests" else 0)
	var tapped_btn := _nav_btn(tapped)
	_icon_fx(tapped, tapped_btn)
	# The notch glides along the bar; it is part of the bar's own outline.
	_nav_dock.slide_to_tab(tapped_btn, edge)
	# Icons: the tapped one lights up and lifts (small bounce), the rest dim and settle.
	var tw := create_tween().set_parallel(true)
	for tab in NAV_TABS:
		var b := _nav_btn(tab)
		var on: bool = tab == tapped
		b.pivot_offset = b.size / 2.0
		tw.tween_property(b, "modulate", Color.WHITE if on else NAV_DIM, 0.25)
		tw.tween_property(b, "position:y", NAV_LIFT if on else 0.0, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(b, "scale", Vector2.ONE * (1.08 if on else 1.0), 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var l := _nav_label(tab)
		if on:
			l.text = tab.substr(3).to_upper()
			l.modulate.a = 0.0
			tw.tween_property(l, "modulate:a", 1.0, 0.25)
		elif l.modulate.a > 0.0:
			tw.tween_property(l, "modulate:a", 0.0, 0.2)   # fades out instead of vanishing
	_nav_active = tapped
	_refresh_nav_layers(tapped)
	await tw.finished
	_transitioning = false
	if tapped == "NavBattle":
		_show_home()
		_start_nav_pulse("NavBattle")
	else:
		_show_view(tapped, path)
		_start_nav_pulse(tapped)

func _show_home() -> void:
	if _current_view != null:
		_current_view.queue_free()
		_current_view = null
	_current_view_name = "NavBattle"
	_set_home_visible(true)

func _show_view(view_name: String, path: String) -> void:
	if _current_view != null:
		_current_view.queue_free()
		_current_view = null
	var view = load(path).instantiate()
	_current_view = view
	_current_view_name = view_name
	_view_container.add_child(view)
	# Back button: views were built standalone, so their Back handler
	# reloads Hub via change_scene_to_file. Inside View Manager that
	# would lose the persistent nav, so disconnect it here (views
	# themselves are NOT edited, standalone behaviour unchanged) and
	# route Back through the nav tap to Home, which also re-lights
	# Battle, moves the notch, and restarts the pulse.
	var back = view.get_node_or_null("BackButton")
	if back != null:
		for conn in back.pressed.get_connections():
			back.pressed.disconnect(conn["callable"])
		back.pressed.connect(func(): _on_nav_tap("NavBattle", ""))
	_set_home_visible(false)

func _stop_nav_pulse() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = null

func _start_nav_pulse(tab: String = "NavBattle") -> void:
	# Gemini pulse batch, adapted: scale breathing only (1.08 -> 1.11
	# -> 1.08, 2.0s loop, dev42 slower/smaller for a smooth breath
	# instead of a bounce), NOT modulate, so it cannot fight the
	# unified dull inactive set. Dev43: pulse follows the active tab
	# (Battle on Home, Gear/Store/etc. in their views), not just
	# Battle; _on_nav_tap kills it first so it cannot fight the
	# tap tween's scale, and _show_home/_show_view restart it.
	_stop_nav_pulse()
	var _b := _nav_btn(tab)
	_b.scale = Vector2(1.08, 1.08)
	_pulse_tween = create_tween()
	_pulse_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.set_loops(1000)
	_pulse_tween.tween_property(_b, "scale", Vector2(1.11, 1.11), 1.0)
	_pulse_tween.tween_property(_b, "scale", Vector2(1.08, 1.08), 1.0)

func _spawn_spark_burst(btn: Button) -> void:
	# Gemini spark batch, adapted: code-only dot burst, not
	# GPUParticles2D (no spark texture in the project, and a particle
	# node would be cut off by the scene change anyway). Dev42:
	# bigger, faster, unmissable during the 0.35s lift — 12 dots at
	# 10px (was 6px), out 38-62px (was 26-40), fade 0.35s (was 0.45),
	# plus a central flash that expands and fades in 0.3s. Burst
	# z_index 20 sits above the fade overlay, so it stays visible
	# into the fade, until the scene change frees it.
	var _c = btn.get_global_rect().get_center()
	var burst = Control.new()
	burst.name = "SparkBurst"
	burst.position = _c
	burst.z_index = 20
	add_child(burst)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var flash = ColorRect.new()
	flash.size = Vector2(24, 24)
	flash.position = Vector2(-12, -12)
	flash.color = Color(1, 1, 1, 1)
	burst.add_child(flash)
	tw.parallel().tween_property(flash, "size", Vector2(48, 48), 0.3)
	tw.parallel().tween_property(flash, "position", Vector2(-24, -24), 0.3)
	tw.parallel().tween_property(flash, "modulate:a", 0.0, 0.3)
	for i in 12:
		var dot = ColorRect.new()
		dot.size = Vector2(10, 10)
		dot.position = Vector2(-5, -5)
		dot.color = Color(0, 0.898, 1.0) if i % 2 == 0 else Color(1, 0.8, 0.3)
		burst.add_child(dot)
		var _ang = float(i) * 0.524 + 0.3
		var _dist = 38.0 + float(i % 4) * 8.0
		var _target = Vector2(cos(_ang), sin(_ang)) * _dist
		tw.parallel().tween_property(dot, "position", _target - Vector2(5, 5), 0.35)
		tw.parallel().tween_property(dot, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func(): burst.queue_free())

func _smooth_change_scene(path: String) -> void:
	if _transitioning: return
	_transitioning = true
	# Fade WHOLE screen to black (overlay), not just MainVBox — fading
	# only MainVBox left Background/AFK/side icons visible, then the new
	# scene popped in, which looked like an overlay flash in dev34 video.
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 1)
	overlay.size = size
	overlay.modulate.a = 0.0
	add_child(overlay)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(overlay, "modulate:a", 1.0, 0.25)
	await tw.finished
	get_tree().change_scene_to_file(path)

func _hide_panels() -> void:
	$SelectPanel.visible = false
	$PatrolPanel.visible = false
	$InfoPanel.visible = false
	$SidePanel.visible = false

func _show_panel(p: Panel) -> void:
	_hide_panels()
	p.visible = true
	MenuAnim.panel_pop(p)

func _side_popup(title: String, body: String) -> void:
	$SidePanel/SideTitle.text = title
	$SidePanel/SideLabel.text = body
	_show_panel($SidePanel)

func _fade_in_overlay() -> void:
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 1)
	overlay.size = size
	add_child(overlay)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(overlay, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func(): overlay.queue_free())

func _nav_btn(tab: String) -> Button:
	return $NavBar/NavVBox/NavRow.get_node("Slot%s/%s" % [tab.substr(3), tab]) as Button

func _nav_label(tab: String) -> Label:
	return $NavBar/NavVBox/NavLabelRow.get_node("Label%s" % tab.substr(3)) as Label



# Per-tab activation animation on the painted icon: a transform on the button
# plus a small drawn effect at the icon's "live" spot.
func _icon_fx(tab: String, b: Button) -> void:
	b.pivot_offset = b.size / 2.0
	var c := b.size * 0.5
	var L: Dictionary = _nav_layers.get(tab, {})
	var tw := create_tween()
	match tab:
		"NavGear":    # visor warms up: fades in, dips once, then full on with a flash
			if L.has("on"):
				L.on.modulate.a = 0.0
				tw.tween_property(L.on, "modulate:a", 0.6, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tw.tween_property(L.on, "modulate:a", 0.4, 0.12).set_trans(Tween.TRANS_SINE)
				tw.tween_property(L.on, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
				tw.tween_callback(func(): IconFx.play(b, "flash", c + Vector2(0, -4), 0.5))
			tw.tween_property(b, "scale", Vector2(1.08, 1.08), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		"NavBattle":  # the two rifles pull apart, swing, and clash with a spark
			if L.has("a"):
				for key in ["a", "b"]:
					L[key].pivot_offset = L[key].size / 2.0
				tw.tween_property(L.a, "rotation", -0.9, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tw.parallel().tween_property(L.b, "rotation", 0.9, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tw.parallel().tween_property(L.a, "position", L.a.position + Vector2(-6, 0), 0.22)
				tw.parallel().tween_property(L.b, "position", L.b.position + Vector2(6, 0), 0.22)
				tw.tween_property(L.a, "rotation", 0.12, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				tw.parallel().tween_property(L.b, "rotation", -0.12, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				tw.parallel().tween_property(L.a, "position", L.a.position, 0.16)
				tw.parallel().tween_property(L.b, "position", L.b.position, 0.16)
				tw.tween_callback(func(): IconFx.play(b, "spark", c, 0.45))
				tw.tween_property(L.a, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.parallel().tween_property(L.b, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(b, "scale", Vector2(1.08, 1.08), 0.2)
		"NavStore":   # crate: closed, hops, opens with a beam of light
			if L.has("on"):
				L.on.modulate.a = 0.0
			tw.tween_property(b, "scale", Vector2(1.12, 0.92), 0.10)
			tw.tween_callback(func(): IconFx.play(b, "beam", c + Vector2(0, -6), 0.55))
			tw.tween_property(b, "scale", Vector2(1.02, 1.16), 0.12)
			if L.has("on"):   # the lid opens as a quick cross-fade during the hop
				tw.parallel().tween_property(L.on, "modulate:a", 1.0, 0.12)
			tw.tween_property(b, "scale", Vector2(1.08, 1.08), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		"NavModes":   # the rings spin around the planet
			if L.has("rings"):
				L.rings.pivot_offset = L.rings.size / 2.0
				tw.tween_property(L.rings, "rotation", TAU, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				tw.tween_callback(func(): L.rings.rotation = 0.0)
				tw.parallel().tween_property(L.rings, "scale", Vector2(1.18, 1.18), 0.4)
				tw.tween_property(L.rings, "scale", Vector2(1.0, 1.0), 0.4)
			tw.parallel().tween_property(b, "scale", Vector2(1.08, 1.08), 0.2)
		"NavQuests":  # the screen lights up and the check stamps in
			if L.has("lit"):
				L.lit.modulate.a = 0.0
				tw.tween_property(b, "scale", Vector2(0.94, 0.94), 0.06)
				tw.tween_callback(func(): IconFx.play(b, "ring", c + Vector2(4, -2), 0.4))
				tw.tween_property(L.lit, "modulate:a", 1.0, 0.15)
			tw.tween_property(b, "scale", Vector2(1.08, 1.08), 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ---- layered nav icons (Luna's state images) ----
const NAV_LAYERS := {
	"NavGear":   {"off": "gear_off", "on": "gear_on"},
	"NavStore":  {"off": "chest_closed", "on": "chest_open"},
	"NavModes":  {"planet": "modes_planet", "rings": "modes_rings"},
	"NavQuests": {"dim": "quests_dim", "lit": "quests_lit"},
	"NavBattle": {"a": "nav_battle_a", "b": "nav_battle_b"},
}

func _build_layered_nav_icons() -> void:
	for tab in NAV_LAYERS:
		var b := _nav_btn(tab)
		if b == null:
			continue
		b.icon = null
		var layers := {}
		for key in NAV_LAYERS[tab]:
			var tr := TextureRect.new()
			tr.texture = Icons.get_icon(NAV_LAYERS[tab][key])
			tr.set_anchors_preset(Control.PRESET_FULL_RECT)
			tr.offset_left = 6; tr.offset_right = -6; tr.offset_top = 4; tr.offset_bottom = -4
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(tr)
			layers[key] = tr
			if key == "rings":
				tr.offset_left = -6; tr.offset_right = 6; tr.offset_top = -4; tr.offset_bottom = 4
			if key == "planet":
				tr.offset_left = 12; tr.offset_right = -12; tr.offset_top = 10; tr.offset_bottom = -10
			if key == "lit":
				# a gold check drawn over the lit screen so it stands out
				var chk := Control.new()
				chk.set_anchors_preset(Control.PRESET_FULL_RECT)
				chk.mouse_filter = Control.MOUSE_FILTER_IGNORE
				chk.draw.connect(func():
					var c := chk.size * 0.5 + Vector2(2, -2)
					var pts := PackedVector2Array([c + Vector2(-9, 0), c + Vector2(-3, 6), c + Vector2(10, -7)])
					chk.draw_polyline(pts, Color(1.0, 0.8, 0.3, 0.35), 7.0, true)
					chk.draw_polyline(pts, Color(1.0, 0.85, 0.3), 3.2, true))
				tr.add_child(chk)
		_nav_layers[tab] = layers
	_refresh_nav_layers(_nav_active, false)

# The "on" picture (visor lit, crate open, screen lit) sits over the "off" one and
# fades; the off picture stays underneath, so switching tabs never cuts between
# images. The tab being opened is faded in by _icon_fx.
func _refresh_nav_layers(active: String, animate: bool = true) -> void:
	for tab in _nav_layers:
		var on: bool = active == tab
		var L: Dictionary = _nav_layers[tab]
		for key in ["on", "lit"]:
			if not L.has(key):
				continue
			var top: TextureRect = L[key]
			top.visible = true
			if not animate:
				top.modulate.a = 1.0 if on else 0.0
			elif not on and top.modulate.a > 0.0:
				create_tween().tween_property(top, "modulate:a", 0.0, 0.25)

func _chest_open_fx() -> void:
	var b := _find_button(self, "ChestButton")
	if b == null:
		return
	# The open chest fades in over the closed icon, holds, and fades back out
	# (no icon swap), with a little hop.
	var lid := TextureRect.new()
	lid.texture = Icons.get_icon("chest_open")
	lid.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lid.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var side: float = float(b.get_theme_constant("icon_max_width")) if b.has_theme_constant_override("icon_max_width") else minf(b.size.x, b.size.y)
	lid.size = Vector2(side, side)
	lid.position = (b.size - lid.size) * 0.5
	lid.modulate.a = 0.0
	b.add_child(lid)
	IconFx.play(b, "beam", b.size * 0.5 + Vector2(0, -8), 0.5)
	b.pivot_offset = b.size * 0.5
	var tw := create_tween()
	var mix := func(a: float):
		lid.modulate.a = a
		var base := Color(1, 1, 1, clampf((1.0 - a) * 2.0, 0.0, 1.0))
		for st in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
			b.add_theme_color_override(st, base)
	tw.tween_method(mix, 0.0, 1.0, 0.12)
	tw.parallel().tween_property(b, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_SINE)
	tw.tween_property(b, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.5)
	tw.tween_method(mix, 1.0, 0.0, 0.3)
	tw.tween_callback(lid.queue_free)

func _find_button(n: Node, nm: String) -> Button:
	if n.name == nm and n is Button:
		return n
	for ch in n.get_children():
		var r := _find_button(ch, nm)
		if r != null:
			return r
	return null
