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
const NAV_LIFT := -3.0                           # how far the active icon rises (stays inside the bar)
const NAV_BUMP := 4.0                            # space above the nav bar (nav_dock.gd bump_h)

const CYAN := Color(0.18, 0.9, 1.0)
const PURPLE := Color(0.71, 0.55, 1.0)
const GOLD := Color(1.0, 0.8, 0.3)
const MUTED := Color(0.62, 0.70, 0.84)
const GLASS_FILL := Color(0.03, 0.045, 0.10, 0.5)
const GLASS_LINE := Color(1, 1, 1, 0.10)

# Small text under these round buttons (the ones whose icon isn't obvious).
# Add or remove node names here to try different combinations.
const LABELED := ["ChestButton", "PatrolButton", "StarterButton", "GiftsButton", "DailyButton", "RanksButton", "EventButton", "PromoButton"]   # dev141: every side button, same look

const NAV_NAMES := {"NavStore": "Store", "NavGear": "Heroes", "NavBattle": "Battle", "NavModes": "Modes", "NavQuests": "Quests"}
const NAV_ICONS := {"NavStore": "nav_store", "NavGear": "nav_gear", "NavBattle": "nav_battle",
	"NavModes": "nav_modes", "NavQuests": "nav_quests"}

# Galactic stage names. Same places in both modes; Elite is the darker twist.
const STAGE_NAMES := {
	"Normal": ["Ember Reach", "Nova Drift", "Cinder Belt", "Halo Verge", "Ion Fields"],
	"Elite": ["Void Ember Reach", "Black Nova Drift", "Hollow Cinder Belt", "Eclipsed Halo Verge", "Storm Ion Fields"],
}

# Side buttons. "dot" = red notification dot. Events, offers and promos will go here later.
# "go" = [nav tab, meta key, tab index]: the button opens that page on that tab (dev140:
# Daily -> Quests, Gifts -> Store offers, Starter -> Store packs); the rest show a pop-up.
# "hidden": not built on Home until its feature exists (dev141, Rudy: no dead buttons).
const LEFT_RAIL := [
	{"id": "EventButton", "icon": "event", "label": "Event", "dot": true, "hidden": true,
		"title": "EVENT", "body": "Seasonal events with their own stage and rewards are coming in a later update."},
	{"id": "PromoButton", "icon": "promo", "label": "Promo", "dot": false, "hidden": true,
		"title": "PROMO", "body": "Special deals and bundles will show here once the Store opens for real-money packs."},
	{"id": "StarterButton", "icon": "starter", "label": "Starter", "dot": false,
		"go": ["NavStore", "store_tab", 3]},
]
const RIGHT_RAIL := [
	{"id": "DailyButton", "icon": "daily", "label": "Daily", "dot": false,
		"go": ["NavQuests", "quests_tab", 0]},
	{"id": "GiftsButton", "icon": "gifts", "label": "Gifts", "dot": false,
		"go": ["NavStore", "store_tab", 0]},
	{"id": "RanksButton", "icon": "ranks", "label": "Ranks", "dot": false, "hidden": true,   # no dead buttons (dev168): back with the online update
		"title": "RANKS", "body": "Rankings run in 30-day seasons with rewards by rank. They need the online update (2.0)."},
]
const NAV_PATHS := {"NavStore": "res://store.tscn", "NavGear": "res://gear.tscn", "NavModes": "res://modes.tscn", "NavQuests": "res://quests.tscn"}

var stage := 1
var mode := "Normal"
var _popup_layer: Control = null   # the open glass pop-up (_side_popup)
var _dot_btns := {}                # Home buttons that can carry a red dot (_refresh_dots)
var _info_text := ""               # the selected stage's facts (Chest tap)
var elite_unlocked := false
var level := 1
var pilot_xp := 0
var coins := 0
var crystals := 0
var best_score := 0
var best_kills := 0
var stage_unlocked := 1
var elite_stage_unlocked := 1   # the Elite ladder (save "elite_unlocked"): starts at Elite stage 1 (dev167)
var _elite_tint: ColorRect

var _transitioning := false
var _nav_dock: NavDock = null
var _nav_empty: StyleBoxEmpty = null
var _nav_active := "NavBattle"
var _pulse_tween: Tween = null
var _view_container: Control = null
var _frost: ColorRect = null      # frosted glass behind menu screens (frost.gdshader)
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
var _energy_btn: Button     # power tokens (Energy)
var _tag_timer: SceneTreeTimer = null
var _frame: HomeFrame = null
var _nav_layers := {}   # tab name -> {layer name: TextureRect}

func _ready() -> void:
	size = get_viewport_rect().size
	var th := load("res://game_theme.tres")
	if th: theme = th
	# Patrol farms while the game is closed: count what it earned since last time
	var ps := Progress.read()
	Patrol.tick(ps)
	Progress.write(ps)
	Perf.apply_from(ps)   # performance mode and frame counter (Settings)
	Sfx.apply_from(ps)    # sound on/off
	_load_save()
	# the Elite hue over the live world (hidden in Standard)
	_elite_tint = ColorRect.new()
	_elite_tint.name = "EliteTint"
	_elite_tint.color = Color(0.5, 0.15, 0.9, 0.0)
	_elite_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_elite_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_elite_tint)
	move_child(_elite_tint, $AFK.get_index() + 1)
	_frame = HomeFrame.new()
	_frame.name = "HomeFrame"
	add_child(_frame)
	move_child(_frame, $Safe.get_index())
	_build_home()
	_setup_nav()
	_build_layered_nav_icons()
	MenuAnim.pop_buttons($Safe)
	_update_stage_label()
	_hide_panels()
	_fade_in_overlay()
	_setup_view_manager()
	call_deferred("_animate_nav_in")
	_on_energy_changed()   # the red dots, now that every button exists
	get_tree().create_timer(0.7).timeout.connect(_announce_new)   # NEW: a system opened since the last visit (Unlocks)
	call_deferred("_home_tips")   # guided first-time tips (Tips)

func _load_save() -> void:
	if FileAccess.file_exists("user://skybound_save.json"):
		var f := FileAccess.open("user://skybound_save.json", FileAccess.READ)
		if f:
			var data = JSON.parse_string(f.get_as_text())
			if typeof(data) == TYPE_DICTIONARY:
				coins = int(data.get("coins", 0))
				crystals = int(data.get("crystals", 0))
				best_score = int(data.get("best_score", 0))
				best_kills = int(data.get("best_kills", 0))
				stage_unlocked = int(data.get("stage_unlocked", 1))
				elite_stage_unlocked = StageData.elite_top(data)   # the Elite ladder, never past your Standard progress (dev168)
				stage = clampi(int(data.get("selected_stage", 1)), 1, elite_stage_unlocked if bool(data.get("selected_elite", false)) else stage_unlocked)
				mode = "Elite" if bool(data.get("selected_elite", false)) else "Normal"
				pilot_xp = int(data.get("pilot_xp", 0))
				level = Turrets.pilot_level(pilot_xp)
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
	UIKit.dot(b, true)

# "Pilot 7" with a thin XP bar under it (cyan to purple) toward the next level.
func _pilot_block() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hsave := Progress.read()
	var hid := Heroes.selected(Heroes.read(hsave))   # the hero on duty and his element (heroes, dev172)
	var name_l := _small_label("%s  ·  %s" % [Heroes.ROSTER[hid].name, Heroes.element_name(Heroes.element_of(hid))], 14, Color.WHITE)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(name_l)
	# XP into this level (the ring round the profile button shows the same)
	var lo := Turrets.xp_for_level(level)
	var hi := Turrets.xp_for_level(level + 1)
	var xp_l := _small_label("%d / %d XP" % [pilot_xp - lo, hi - lo], 10, MUTED)
	xp_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(xp_l)
	return v

# The level ring (Rudy): a thin ring round the profile button fills as pilot XP grows,
# cyan to purple; a small badge in its corner shows the level. Full ring = next level.
func _xp_ring(b: Button) -> void:
	var lo := Turrets.xp_for_level(level)
	var hi := Turrets.xp_for_level(level + 1)
	var f := clampf(float(pilot_xp - lo) / maxf(float(hi - lo), 1.0), 0.0, 1.0)
	var ring := Control.new()
	ring.name = "XpRing"
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.draw.connect(func():
		var c := ring.size * 0.5
		var r := minf(c.x, c.y) - 1.5
		ring.draw_arc(c, r, 0.0, TAU, 48, Color(1, 1, 1, 0.14), 2.5, true)
		if f > 0.0:
			# from the top, clockwise; the colour runs cyan to purple along the way
			var steps := maxi(2, int(48 * f))
			for i in steps:
				var a0 := -PI / 2.0 + TAU * f * float(i) / steps
				var a1 := -PI / 2.0 + TAU * f * float(i + 1) / steps
				ring.draw_arc(c, r, a0, a1, 3, CYAN.lerp(PURPLE, float(i) / steps), 2.5, true)
		# level badge, bottom-right
		var bc := c + Vector2(r * 0.72, r * 0.72)
		var txt := str(level)
		var br := 8.0 if txt.length() < 2 else 9.5
		ring.draw_circle(bc, br, Color(0.04, 0.06, 0.17))
		ring.draw_arc(bc, br, 0.0, TAU, 24, CYAN.lerp(PURPLE, f), 1.2, true)
		var font := ring.get_theme_default_font()
		var fs := 10
		var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		ring.draw_string(font, bc + Vector2(-w * 0.5, fs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE))
	b.add_child(ring)

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
	_frame.add_dock(b, 2, Vector2(-5, -5))   # a glass tile behind it
	if def.dot:
		_add_dot(b)
	_dot_btns[def.id] = b   # red dots follow Progress.attention (_refresh_dots)
	if def.id in LABELED:
		box.add_child(_small_label(def.label, 12, MUTED))
	if def.has("go"):
		b.pressed.connect(func():
			get_tree().root.set_meta(def.go[1], def.go[2])
			_on_nav_tap(def.go[0], NAV_PATHS[def.go[0]]))
	else:
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
	top.offset_left = 10.0
	top.offset_right = -8.0
	top.offset_top = 4.0
	home.add_child(top)
	# Left dock group: profile + currencies sit in one tab attached to the left edge
	var dockL := HBoxContainer.new()
	dockL.name = "TopDock"
	dockL.add_theme_constant_override("separation", 6)
	dockL.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(dockL)
	var profile := _icon_button("ProfileButton", "profile", 44.0, 38.0, 30, Color(PURPLE, 0.0))   # the XP ring is its outline
	profile.pressed.connect(func():
		# a real profile card (dev140): level, XP, how far you are, lifetime numbers
		var sv := Progress.read()
		_side_popup("%s  ·  LEVEL %d" % [Promotion.rank_name(sv).to_upper(), level], "Rank %d of %d: %s\n%d / %d XP to level %d\nHighest stage: %d of %d  ·  stars %d\nBugs destroyed: %d  ·  bosses: %d\nStages cleared: %d  ·  %.1f hours in battle" % [
			Promotion.rank(sv), Promotion.RANKS.size(), Promotion.bonus_text(Promotion.rank(sv)),
			pilot_xp - Turrets.xp_for_level(level), Turrets.xp_for_level(level + 1) - Turrets.xp_for_level(level), level + 1,
			maxi(stage_unlocked - 1, 0), StageData.MAX_STAGE, int(Progress.stat(sv, "stars")),
			int(Progress.stat(sv, "kills")), int(Progress.stat(sv, "bosses")), int(Progress.stat(sv, "stages")), Progress.stat(sv, "hours")],
			[["Trophies", func():
				get_tree().root.set_meta("quests_tab", 2)
				_on_nav_tap("NavQuests", NAV_PATHS["NavQuests"])]]))
	_xp_ring(profile)   # the level ring and badge
	dockL.add_child(profile)
	dockL.add_child(_pilot_block())
	_coin_btn = _pill_button("CoinButton", "ui_coin", _fmt(coins))
	_coin_btn.pressed.connect(func(): _side_popup("COINS", "Coins: earned by defeating enemies.\nYou keep them between runs."))
	dockL.add_child(_coin_btn)
	_crystal_btn = _pill_button("CrystalButton", "ui_crystal", _fmt(crystals))
	_crystal_btn.pressed.connect(func(): _side_popup("CRYSTALS", "Premium currency. Earned from missions, trophies, the daily gift and chests; crystal packs come with the Google Play release.", [["Open the Store", func():
		get_tree().root.set_meta("store_tab", 1)
		_on_nav_tap("NavStore", NAV_PATHS["NavStore"])]]))
	dockL.add_child(_crystal_btn)
	# power tokens: playing a stage and collecting Patrol cost them (Energy)
	_energy_btn = _pill_button("EnergyButton", "ui_energy", "")
	_energy_btn.pressed.connect(func(): _side_popup("POWER", "A stage: %d  ·  stages 1-%d free  ·  Elite: %d\nCollect Patrol: %d\n+1 every 6 min, up to %d" % [Energy.STAGE_COST, Energy.FREE_STAGES, Energy.ELITE_COST, Energy.PATROL_COST, Energy.MAX]))
	dockL.add_child(_energy_btn)
	_on_energy_changed()
	var et := Timer.new()
	et.wait_time = 2.0
	et.autostart = true
	et.timeout.connect(_on_energy_changed)
	add_child(et)
	var open := _icon_button("OpenCurrencyButton", "plus", 36.0, 26.0, 14, Color(CYAN, 0.4))
	open.pressed.connect(func(): _on_nav_tap("NavStore", "res://store.tscn"))   # + opens the Store (coins, crystals)
	dockL.add_child(open)
	_frame.add_dock(top, 0, Vector2(0, 4))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)
	var menu := _icon_button("MenuButton", "menu", 44.0, 32.0, 16)
	menu.pressed.connect(func(): _side_popup("MENU", "Build %s\nMail, log-in rewards and community come with the online update (2.0)." % BuildInfo.BUILD, [["Settings", func(): _smooth_change_scene("res://settings.tscn")], ["Stage Map", func(): _smooth_change_scene("res://stage_map.tscn")]]))
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
	_stage_btn.pressed.connect(func(): _smooth_change_scene("res://stage_map.tscn"))   # the stage map trail
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
	left.offset_left = 8.0
	home.add_child(left)
	for d in LEFT_RAIL:
		if not d.get("hidden", false):
			left.add_child(_rail_item(d))
	var right := VBoxContainer.new()
	right.name = "RightRail"
	right.add_theme_constant_override("separation", 12)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	right.offset_top = 124.0
	right.offset_right = -8.0
	home.add_child(right)
	for d in RIGHT_RAIL:
		if not d.get("hidden", false):
			right.add_child(_rail_item(d))

	# ---- bottom row: START centred, Chest and Patrol docked to the screen edges ----
	var row := Control.new()
	row.name = "ActionRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	row.custom_minimum_size = Vector2(0, 8)
	row.offset_top = -8.0
	home.add_child(row)
	_action_row = row
	var chest := _action_item("ChestButton", "chest_closed", "Chest", func():
		_chest_popup())
	chest.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	chest.grow_horizontal = Control.GROW_DIRECTION_END
	chest.grow_vertical = Control.GROW_DIRECTION_BOTH
	chest.offset_left = 2.0
	chest.offset_top = -159.0
	chest.offset_bottom = -159.0
	row.add_child(chest)
	# (no START button here since dev107: on Home the gold Battle tab IS the Play button)
	if Unlocks.open(Progress.read(), "patrol"):   # Patrol appears after stage 6 (Unlocks)
		var patrol := _action_item("PatrolButton", "patrol", "Patrol", _patrol_open)   # offline farming (Patrol)
		patrol.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		patrol.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		patrol.grow_vertical = Control.GROW_DIRECTION_BOTH
		patrol.offset_right = -2.0
		patrol.offset_top = -159.0
		patrol.offset_bottom = -159.0
		row.add_child(patrol)

func _action_item(node_name: String, icon_name: String, label: String, on_press: Callable) -> Control:
	# Round button + optional small label, same size for Chest and Patrol so they line up.
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", -6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var b := _icon_button(node_name, icon_name, 46.0, 40.0, 38, Color(0, 0, 0, 0))
	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	_dot_btns[node_name] = b
	# Chest and Patrol are Luna's 3D chest and drone, animated (home_prop.gd)
	if node_name == "ChestButton" or node_name == "PatrolButton":
		b.icon = null
		var prop := HomeProp.new()
		prop.name = "Prop"
		prop.kind = "chest" if node_name == "ChestButton" else "drone"
		prop.size = Vector2(44, 44)
		prop.position = Vector2(1, 1)
		b.add_child(prop)
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
	# no oval: icon and number float free (Rudy, dev107); a faint glass shows only while pressed
	var n := StyleBoxEmpty.new()
	n.content_margin_left = 4.0
	n.content_margin_right = 6.0
	var p := _glass(13.0, Color(CYAN, 0.5), Color(CYAN, 0.18))
	p.expand_margin_top = -5.0
	p.expand_margin_bottom = -5.0
	p.content_margin_left = 4.0
	p.content_margin_right = 6.0
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", n)
	b.add_theme_stylebox_override("pressed", p)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_constant_override("h_separation", 5)
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
	bar_box.content_margin_bottom = 14
	bar_box.content_margin_left = 14
	bar_box.content_margin_right = 14
	$NavBar.add_theme_stylebox_override("panel", bar_box)
	$NavBar/NavVBox.add_theme_constant_override("separation", -8)
	_nav_empty = StyleBoxEmpty.new()
	for tab in NAV_TABS:
		var nb := _nav_btn(tab)
		for state in ["normal", "hover", "pressed", "focus"]:
			nb.add_theme_stylebox_override(state, _nav_empty)
		nb.expand_icon = true
		var nl := _nav_label(tab)
		nl.add_theme_font_size_override("font_size", 11)
		nl.custom_minimum_size.y = 16
		nl.text = NAV_NAMES[tab]
		_paint_nav_label(tab, tab == "NavBattle")
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
	# frosted glass over the frozen Home battle, behind every menu screen
	_frost = ColorRect.new()
	_frost.name = "Frost"
	_frost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frost.set_anchors_preset(Control.PRESET_FULL_RECT)
	var fm := ShaderMaterial.new()
	fm.shader = load("res://frost.gdshader")
	_frost.material = fm
	_frost.visible = false
	add_child(_frost)
	move_child(_frost, _view_container.get_index())
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
	# Home showing: the Battle tile becomes Play (breathing gold, label "Play")
	if _nav_dock != null:
		var home := _current_view == null
		_nav_dock.play_mode = home
		_nav_label("NavBattle").text = "Play" if home else NAV_NAMES["NavBattle"]
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
		var inset := SafeAreaMargin.top_inset(get_viewport())   # below the notch / camera cutout
		_view_container.position = Vector2(0, inset)
		_view_container.size = Vector2(size.x, nb.get_global_rect().position.y - inset)
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
	_mode_tag.text = "%s %d  ·  %s  ·  WEAK TO %s" % ["ELITE" if is_elite else "STANDARD", stage, String(StageData.area(stage).name).to_upper(), Heroes.element_name(Heroes.family(stage).weak).to_upper()]   # the element to bring (heroes)
	_mode_tag.add_theme_color_override("font_color", PURPLE if is_elite else CYAN)
	_stage_btn.text = StageData.stage_name(stage)
	_stage_btn.modulate.a = 1.0 if stage <= _top_stage() else 0.5
	# Elite look (Rudy, dev167): a purple hue over the world, and the stage name in a frame
	# coloured by the mode
	if _elite_tint:
		_elite_tint.create_tween().tween_property(_elite_tint, "color:a", 0.18 if is_elite else 0.0, 0.35)
	var fc: Color = PURPLE if is_elite else CYAN
	for st in ["normal", "hover", "pressed"]:
		_stage_btn.add_theme_stylebox_override(st, UIKit.box(Color(fc, 0.10), Color(fc, 0.75), 12))
	_paint_segment(_std_btn, not is_elite, true)
	_paint_segment(_elite_btn, is_elite, false)
	$AFK.set_elite(is_elite)
	$AFK.set_stage(stage)
	var w := StageData.waves(stage)
	var kinds := {}
	for wv in w:
		for entry in wv:
			kinds[entry[0]] = true
	_info_text = "%s %d: %s\nSector: %s\nWaves: %d\nEnemies: %s\nBest run: Score %d, Kills %d" % [
		"Elite" if is_elite else "Standard", stage, StageData.stage_name(stage), sec.name, w.size(), ", ".join(kinds.keys()).replace("_", " "), best_score, best_kills]
	_info_text += "\nFamily: %s  ·  %s" % [Heroes.family(stage).name, Heroes.family_text(stage)]   # the element to bring (heroes, dev172)

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
	stage = clampi(stage, 1, _top_stage())
	_write_selection()
	_update_stage_label()

# the highest stage you may pick in this mode: Elite has its own ladder
func _top_stage() -> int:
	return elite_stage_unlocked if mode == "Elite" else stage_unlocked

func _change_stage(d: int) -> void:
	stage = clampi(stage + d, 1, _top_stage())
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
				DevTools.on = bool(d.get("dev_mode", false))
	data["selected_stage"] = stage
	data["selected_elite"] = mode == "Elite"
	var out := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(data))

func _set_home_visible(visible: bool) -> void:
	# Home content on/off. The nav stays. In menu views the wallpaper stays on screen,
	# frozen, under the frosted glass (_frost), so every menu sits in the game's world.
	$Safe.visible = visible
	$Dim.visible = visible
	# dev146: the frosted-glass blur (a 17-tap full-screen shader every frame) stays OFF now
	# that every menu page draws its own planet wallpaper over it (MenuBackdrop); the biggest
	# single GPU cost in the menus, for nothing visible. The node stays for pop-ups later.
	if _frost != null:
		_frost.visible = false
	if visible:
		$AFK.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		_hide_panels()
		$AFK.process_mode = Node.PROCESS_MODE_DISABLED

func _on_nav_tap(tapped: String, path: String) -> void:
	if _transitioning: return
	Sfx.play("tap")
	# on Home, the gold Battle tile is the Play button: tapping it starts the battle
	if tapped == "NavBattle" and _current_view == null:
		if not Energy.try_play(self, mode == "Elite", stage):   # a stage costs power tokens (stages 1-5 free)
			return
		_spawn_spark_burst(_nav_btn("NavBattle"))
		_smooth_change_scene("res://battle.tscn")
		return
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
		_paint_nav_label(tab, on)
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
		UIKit.leave(_current_view)   # sinks and fades out (dev157), then frees itself
		_current_view = null
	_current_view_name = "NavBattle"
	_set_home_visible(true)
	call_deferred("_home_tips")
	# Home itself comes back with a short fade so the hand-off is seamless
	$Safe.modulate.a = 0.0
	$Safe.create_tween().tween_property($Safe, "modulate:a", 1.0, 0.22)

func _show_view(view_name: String, path: String) -> void:
	if _current_view != null:
		UIKit.leave(_current_view)
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
	# Inside Home the Back button is hidden (Rudy, dev107): the Battle tab goes back. It
	# stays wired to Home in case a screen shows it again.
	var back = view.find_child("BackButton", true, false)
	if back != null:
		back.visible = false
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
	if _popup_layer != null and is_instance_valid(_popup_layer):
		_popup_layer.queue_free()
	_popup_layer = null
	var cb := _find_button(self, "ChestButton")
	if cb != null:
		var prop := cb.get_node_or_null("Prop") as HomeProp
		if prop:
			prop.close()   # the chest settles shut once its overlay is gone

# A glass pop-up over Home in the menus' look (dev140; replaces the old grey scene panels):
# a title, a few lines, optional buttons [[label, callable], ...] and Close. A tap outside
# closes it too.
func _side_popup(title: String, body: String, actions: Array = []) -> void:
	_hide_panels()
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0.01, 0.04, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev): if (ev is InputEventMouseButton or ev is InputEventScreenTouch) and ev.pressed: _hide_panels())
	layer.add_child(dim)
	var p := UIKit.panel(16)
	var w := minf(size.x - 40.0, 360.0)
	p.custom_minimum_size = Vector2(w, 0)
	p.position = Vector2((size.x - w) * 0.5, size.y * 0.28)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.add_child(UIKit.label(title, 17, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var b := UIKit.label(body, 13, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(b)
	for a in actions:
		var ab := UIKit.teal_button(a[0], 14)
		ab.custom_minimum_size = Vector2(0, 40)
		var fn: Callable = a[1]
		ab.pressed.connect(func():
			_hide_panels()
			fn.call())
		v.add_child(ab)
	var close := UIKit.ghost_button("Close", 13)
	close.custom_minimum_size = Vector2(0, 36)
	close.pressed.connect(_hide_panels)
	v.add_child(close)
	p.add_child(v)
	layer.add_child(p)
	add_child(layer)
	_popup_layer = layer
	p.pivot_offset = Vector2(w * 0.5, 0.0)
	p.scale = Vector2(0.9, 0.9)
	p.modulate.a = 0.0
	var tw := p.create_tween().set_parallel(true)
	tw.tween_property(p, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(p, "modulate:a", 1.0, 0.15)

func _fade_in_overlay() -> void:
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 1)
	overlay.size = size
	add_child(overlay)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(overlay, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func(): overlay.queue_free())

# Every tab keeps its name under it (Luna's mockup): the active one bright (gold on
# Battle, cyan elsewhere), the others muted.
func _paint_nav_label(tab: String, on: bool) -> void:
	var l := _nav_label(tab)
	l.add_theme_color_override("font_color", (GOLD if tab == "NavBattle" else CYAN) if on else MUTED)
	l.modulate.a = 1.0 if on else 0.7

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

func _chest_open_fx(hold: bool = false) -> void:
	var b := _find_button(self, "ChestButton")
	if b == null:
		return
	# Luna's chest lifts its lid and lets the light out (HomeProp.open), with a beam
	# and a little hop. hold = stays open until _hide_panels closes it.
	var prop := b.get_node_or_null("Prop") as HomeProp
	if prop:
		prop.open(hold)
	IconFx.play(b, "beam", b.size * 0.5 + Vector2(0, -8), 0.5)
	b.pivot_offset = b.size * 0.5
	var tw := create_tween()
	tw.tween_property(b, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_SINE)
	tw.tween_property(b, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _find_button(n: Node, nm: String) -> Button:
	if n.name == nm and n is Button:
		return n
	for ch in n.get_children():
		var r := _find_button(ch, nm)
		if r != null:
			return r
	return null

# the power counter: tokens / max, and the next one's countdown when not full
func _on_energy_changed() -> void:
	if _energy_btn == null:
		return
	var s := Progress.read()
	var e := Energy.update(s)
	_energy_btn.text = "%d/%d" % [e, Energy.MAX]
	_load_save()
	_crystal_btn.text = _fmt(crystals)
	_refresh_dots(s)

# Red dots (dev142): one rule, Progress.attention, feeds the nav tabs (Store, Gear, Quests)
# and the Home buttons (Daily = Quests, Gifts = today's gift, Patrol = something to collect).
# Called every 2 s with the energy counter and whenever Home comes back.
func _refresh_dots(s: Dictionary) -> void:
	var at := Progress.attention(s)
	UIKit.dot(_nav_btn("NavQuests"), at.quests)
	UIKit.dot(_nav_btn("NavStore"), at.store)
	UIKit.dot(_nav_btn("NavGear"), at.gear)
	var want := {"DailyButton": at.quests, "GiftsButton": at.store, "PatrolButton": at.patrol}
	for id in want:
		if _dot_btns.has(id) and is_instance_valid(_dot_btns[id]):
			UIKit.dot(_dot_btns[id], want[id])

# ------------------------------------------------------------- Patrol (offline farming)
# Patrol farms a cleared stage wave by wave while you're away (Patrol class). This window:
# pick the stage, see what an hour brings, see what is stored (up to 8 h), collect it.
var _patrol_layer: Control

func _patrol_open() -> void:
	var save := Progress.read()
	Patrol.tick(save)
	Progress.write(save)
	if _patrol_layer and is_instance_valid(_patrol_layer):
		_patrol_layer.queue_free()
	_patrol_layer = ColorRect.new()
	(_patrol_layer as ColorRect).color = Color(0, 0.01, 0.04, 0.75)
	_patrol_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_patrol_layer)
	_patrol_fill()

func _patrol_fill() -> void:
	for c in _patrol_layer.get_children():
		c.queue_free()
	var save := Progress.read()
	var p := Patrol.tick(save)
	Progress.write(save)
	var best := maxi(1, int(save.get("stage_unlocked", 1)) - 1)
	var cleared := int(save.get("stage_unlocked", 1)) > 1
	var panel := UIKit.panel(16)
	var w := minf(size.x - 32.0, 400.0)
	panel.custom_minimum_size = Vector2(w, 0)
	panel.position = Vector2((size.x - w) * 0.5, size.y * 0.2)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.add_child(UIKit.label("PATROL", 18, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	if not cleared:
		v.add_child(UIKit.label("Clear stage 1 to start a patrol", 13, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	else:
		# the stage it farms: arrows through the stages you have cleared
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 10)
		var st: int = int(p.stage)
		var prev := UIKit.ghost_button("<", 16)
		prev.custom_minimum_size = Vector2(44, 36)
		prev.disabled = st <= 1
		prev.pressed.connect(func(): _patrol_stage(st - 1))
		row.add_child(prev)
		var name_l := UIKit.label("Stage %d  ·  %s" % [st, StageData.stage_name(st)], 14, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		name_l.custom_minimum_size = Vector2(200, 0)
		row.add_child(name_l)
		var nxt := UIKit.ghost_button(">", 16)
		nxt.custom_minimum_size = Vector2(44, 36)
		nxt.disabled = st >= best
		nxt.pressed.connect(func(): _patrol_stage(st + 1))
		row.add_child(nxt)
		v.add_child(row)
		# what an hour brings here
		v.add_child(UIKit.label("PER HOUR", 10, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		var pw := Patrol.per_wave(st)
		var rate := HBoxContainer.new()
		rate.alignment = BoxContainer.ALIGNMENT_CENTER
		rate.add_theme_constant_override("separation", 14)
		for k in ["coins", "alloy", "cell", "core", "gear"]:
			if pw.has(k):
				var per_h: float = float(pw[k]) * Patrol.WAVES_PER_HOUR
				rate.add_child(_patrol_amount(k, ("%d" % roundi(per_h)) if k == "coins" else ("%.2f" if k == "gear" else "%.1f") % per_h))
		v.add_child(rate)
		# it slows down the longer it waits (Patrol.speed_at), and has daily limits
		var spd := Patrol.speed_at(float(p.stored_s))
		v.add_child(UIKit.label("Full speed 2 h, then slower  ·  now %s" % ("full" if spd >= 1.0 else ("half" if spd >= 0.5 else "quarter")), 10, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		# stored so far, as a bar to the 8 hour cap
		var hrs := float(p.stored_s) / 3600.0
		var day_h := float(p.day_s) / 3600.0
		v.add_child(UIKit.label("STORED  %dh %02dm / 8h   ·   TODAY  %dh / 12h" % [int(hrs), int(fmod(hrs, 1.0) * 60.0), int(day_h)], 10, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		var bar := ProgressBar.new()
		bar.max_value = Patrol.CAP_S
		bar.value = float(p.stored_s)
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 8)
		bar.add_theme_stylebox_override("background", UIKit.box(Color(1, 1, 1, 0.08), Color(1, 1, 1, 0.0), 4))
		bar.add_theme_stylebox_override("fill", UIKit.box(GOLD if float(p.stored_s) >= Patrol.CAP_S else CYAN, Color(CYAN, 0.0), 4))
		v.add_child(bar)
		var got := Patrol.ready(p)
		var have := HBoxContainer.new()
		have.alignment = BoxContainer.ALIGNMENT_CENTER
		have.add_theme_constant_override("separation", 14)
		for k in ["coins", "alloy", "cell", "core", "gear"]:
			if got.has(k):
				have.add_child(_patrol_amount(k, str(got[k])))
		if got.is_empty():
			have.add_child(UIKit.label("Nothing yet: a wave every 30 s", 12, MUTED))
		v.add_child(have)
		var left := Patrol.collects_left(p)
		var claim := UIKit.gold_button(("Collect  ·  %d power  (%d left today)" % [Energy.PATROL_COST, left]) if left > 0 else "Back tomorrow", 15)
		claim.custom_minimum_size = Vector2(0, 44)
		claim.disabled = got.is_empty() or left <= 0
		claim.pressed.connect(func():
			var s := Progress.read()
			if not Energy.try_spend(s, Energy.PATROL_COST):   # collecting costs power tokens
				Energy.show_short(self, Energy.PATROL_COST)
				return
			var g := Patrol.claim(s)
			Progress.write(s)
			_load_save()
			_coin_btn.text = _fmt(coins)
			_crystal_btn.text = _fmt(crystals)
			_patrol_fill()
			_on_energy_changed()
			_patrol_toast("+ " + Progress.reward_text(g)))
		v.add_child(claim)
	var close := UIKit.ghost_button("Close", 14)
	close.custom_minimum_size = Vector2(0, 38)
	close.pressed.connect(func(): _patrol_layer.queue_free())
	v.add_child(close)
	panel.add_child(v)
	_patrol_layer.add_child(panel)

func _patrol_stage(stage: int) -> void:
	var s := Progress.read()
	Patrol.set_stage(s, stage)
	Progress.write(s)
	_patrol_fill()

# an icon with a number (coins, or an upgrade part)
func _patrol_amount(kind: String, text: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	var tr := TextureRect.new()
	tr.texture = load("res://icons/ui_coin.png") if kind == "coins" else (load("res://icons/gear_on.png") if kind == "gear" else Parts.icon(kind))
	tr.custom_minimum_size = Vector2(22, 22)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(tr)
	h.add_child(UIKit.label(text, 14, Color.WHITE))
	return h

func _patrol_toast(text: String) -> void:
	var l := UIKit.label(text, 16, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	l.position = Vector2(0, size.y * 0.15)
	l.size = Vector2(size.x, 30)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 50.0, 1.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.8)
	tw.chain().tween_callback(l.queue_free)

# Guided first-time tips on Home (Tips, dev163): one per visit, the first unseen of these
func _home_tips() -> void:
	if _current_view != null or _popup_layer != null:
		return
	var s := Progress.read()
	var lvl := Turrets.pilot_level(int(s.get("pilot_xp", 0)))
	var list: Array = []
	if int(s.get("stage_unlocked", 1)) >= 2 and _dot_btns.has("PatrolButton"):
		list.append(["patrol", _dot_btns["PatrolButton"]])
	list.append(["stage_map", _stage_btn])
	if lvl >= 10:
		list.append(["elite", _elite_btn])
	if Progress.attention(s).quests:
		list.append(["red_dots", _nav_btn("NavQuests")])
	Tips.first(get_tree(), list)

# The Home chest (dev167): Luna's chest opens and STAYS open while this overlay shows the
# Store's chests, opened right here with crystals; it closes when the overlay goes.
const STORE := preload("res://store.gd")

func _chest_popup() -> void:
	_chest_open_fx(true)
	var sv := Progress.read()
	var lines: Array = []
	var actions: Array = []
	for c in STORE.CHESTS:
		var lo := 1 << 30
		var hi := 0
		var jackpot := ""
		for r in c.rolls:
			if r[1].has("coins"):
				lo = mini(lo, int(r[1].coins))
				hi = maxi(hi, int(r[1].coins))
			else:
				jackpot = "%d%% chance of %d crystals" % [int(r[0]), int(r[1].crystals)]
		lines.append("%s: %d-%d coins, %s" % [c.name, lo, hi, jackpot])
		var chest: Dictionary = c
		actions.append(["Open %s  ·  %d crystals" % [c.name, int(c.price)], func(): _open_home_chest(chest)])
	_side_popup("CHEST", "\n".join(lines) + "\nYou have %d crystals." % int(sv.get("crystals", 0)), actions)

func _open_home_chest(c: Dictionary) -> void:
	var sv := Progress.read()
	var reward: Dictionary = STORE.open_chest_in(sv, c)
	if reward.is_empty():
		_side_popup("CHEST", "Not enough crystals for the %s (%d)." % [c.name, int(c.price)])
		return
	Progress.write(sv)
	_load_save()
	_coin_btn.text = _fmt(coins)
	_crystal_btn.text = _fmt(crystals)
	_patrol_toast("+ " + Progress.reward_text(reward))
	_chest_popup()   # stays open for another go

# ------------------------------------------------------------- NEW (Unlocks)
# Systems appear one at a time (Unlocks). The first one opened since the last visit gets
# one glass pop-up with a Show me button that opens it; an old save takes what it already
# has as seen (Unlocks.settle), so a veteran is not greeted with a queue of pop-ups.
func _announce_new() -> void:
	if not is_inside_tree() or _current_view != null or _popup_layer != null:
		return
	var s := Progress.read()
	Unlocks.settle(s)
	var fresh := Unlocks.fresh(s)
	if fresh.is_empty():
		Progress.write(s)
		return
	var id: String = fresh[0]
	Unlocks.mark_seen(s, id)
	Progress.write(s)
	var u: Dictionary = Unlocks.UNLOCKS[id]
	var actions: Array = []
	var go: Array = u.get("go", [])
	if not go.is_empty():
		actions.append(["Show me", func():
			if String(go[1]) != "":
				get_tree().root.set_meta(go[1], go[2])
			_on_nav_tap(go[0], NAV_PATHS[go[0]])])
	elif id == "patrol":
		actions.append(["Show me", _patrol_open])
	_side_popup("NEW: %s" % String(u.name).to_upper(), String(u.text), actions)
