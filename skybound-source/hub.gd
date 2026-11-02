extends Control
# Home Hub, container rebuild (dev27, Gemini structure, adapted).
# Root Full Rect, MarginContainer 12px safe margins, MainVBox flow:
# Top, Stage, AFKSpacer (expands, pushes bottom to bottom),
# AFKLabel, BestLabel, ActionRow HBox, NavRow HBox (equal width).
# Side icons are LeftVBox/RightVBox (container stacking, not absolute
# per-button y). AFK hero is a live game object, not UI, so it stays
# as a dynamic layer (AFKDraw + Hero), not inside the VBox.
# Theme = MenuStyle (shared StyleBoxFlat, our reusable .theme
# equivalent). Entry animation: MainVBox fades in + slides up on load.
# Clean code connections, like Gemini's main_menu.gd example:
# Play = Battle, Gear, Modes, Quests, Store.

const NAV_TABS := ["NavStore", "NavGear", "NavBattle", "NavModes", "NavQuests"]
const NAV_DIM := Color(0.55, 0.60, 0.72, 1.0)   # look of an inactive tab icon
const HOME_ICON_SIZE := 48                       # max icon width on Home buttons
const NAV_LIFT := -12.0                          # how far the active icon rises
# Which icon goes on which button (by node name). Files: res://icons/<name>.svg
const ICONS := {
	"NavStore": "nav_store", "NavGear": "nav_gear", "NavBattle": "nav_battle",
	"NavModes": "nav_modes", "NavQuests": "nav_quests",
	"ChestButton": "chest", "PatrolButton": "patrol", "BattleButton": "play",
	"EventButton": "event", "PromoButton": "promo", "StarterButton": "starter",
	"DailyButton": "daily", "GiftsButton": "gifts", "RanksButton": "ranks",
}

@onready var hero: TextureRect = $Hero
var hero_base_y := 0.0
var t := 0.0
var stage := 1
var mode := "Normal"
var elite_unlocked := false

func _ready() -> void:
	size = get_viewport_rect().size
	$Background.size = size
	# Dev41 seamless dock (Gemini, adapted): bar is flush with the
	# bottom edge (margin 0, not 12), so the dock meets the screen
	# edge instead of floating above it. Top/left/right safe margins kept.
	$Margin.add_theme_constant_override("margin_bottom", 0)
	for _n in [self, $Margin, $Margin/MainVBox, $Margin/MainVBox/NavBar, $Margin/MainVBox/NavBar/NavVBox, $Margin/MainVBox/NavBar/NavVBox/NavRow]:
		_n.clip_contents = false
	_fade_in_overlay()
	# Safe area is now owned by safe_area_margin.gd on the Margin
	# node (Gemini script, reusable, re-checks on size change).
	# Margin _ready runs before Hub _ready, so read its result here.
	var _bottom_pad: int = $Margin.get_theme_constant("margin_bottom")
	MenuAnim.pop_buttons(self)
	# Gemini Part 1: Theme cascades from root, no per-button styleboxes.
	var th := load("res://game_theme.tres")
	if th: theme = th
	# Icons: one crisp vector (SVG) per button, found by node name (see ICONS).
	for node_name in ICONS:
		var icon_btn := find_child(node_name, true, false) as Button
		if icon_btn != null:
			icon_btn.icon = Icons.get_icon(ICONS[node_name])
			if not node_name.begins_with("Nav"):
				icon_btn.add_theme_constant_override("icon_max_width", HOME_ICON_SIZE)
	# Only the active tab is lit (Battle on Home); the others are dimmed.
	for tab in NAV_TABS:
		_nav_btn(tab).modulate = Color.WHITE if tab == "NavBattle" else NAV_DIM
	# Hero centred in AFK area: between stage header (~200) and bottom
	# rows (~size.y-180). AFKSpacer in the VBox is what creates that
	# area, so hero follows the same math, not a fixed y.
	var action_y := size.y - 180.0 - float(_bottom_pad - 12)
	var hero_y := (200.0 + action_y) / 2.0 - 67.0
	hero.position = Vector2(size.x / 2.0 - 35.0, hero_y)
	hero_base_y = hero_y
	var coins := 0
	var best_score := 0
	var best_kills := 0
	if FileAccess.file_exists("user://skybound_save.json"):
		var f := FileAccess.open("user://skybound_save.json", FileAccess.READ)
		if f:
			var data = JSON.parse_string(f.get_as_text())
			if typeof(data) == TYPE_DICTIONARY:
				coins = int(data.get("coins", 0))
				best_score = int(data.get("best_score", 0))
				best_kills = int(data.get("best_kills", 0))
	$Margin/MainVBox/TopBar/LVLabel.text = "1"
	$Margin/MainVBox/TopBar/CoinLabel.text = "%d" % coins
	$Margin/MainVBox/TopBar/PartsLabel.text = "0"
	# Two lines, not one 70-char line — a single long label forced the
	# whole VBox wider than the screen in dev27, pushing Nav/Patrol/
	# right-side buttons off the right edge.
	$Margin/MainVBox/BestLabel.text = "BEST RUN: Score %d  •  Kills %d\nEQUIPPED: Single Rifle, Charcoal Plate" % [best_score, best_kills]
	_update_stage_label()
	_hide_panels()
	# Entry animation: fade in only. dev46: the old slide-up tween on
	# MainVBox.position.y broke Margin layout - it tweened from the
	# pre-layout position (0), so MainVBox stayed at y=0 instead of
	# the margin position, and the container never re-sorted it until
	# the first menu tap (visibility change) forced a layout pass.
	# That is why Home's bar sat high on first open and dropped on
	# the first menu tap, every launch. Fade does not move layout.
	var main_vbox: Control = $Margin/MainVBox
	main_vbox.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(main_vbox, "modulate:a", 1.0, 0.4)
	# Clean button connections.
	$Margin/MainVBox/ActionRow/BattleButton.pressed.connect(func(): _smooth_change_scene("res://battle.tscn"))
	$Margin/MainVBox/StageVBox/ModeRow/NormalButton.pressed.connect(func(): _set_mode("Normal"))
	$Margin/MainVBox/StageVBox/ModeRow/EliteButton.pressed.connect(func(): _set_mode("Elite"))
	$Margin/MainVBox/StageVBox/StageRow/PrevButton.pressed.connect(func(): _change_stage(-1))
	$Margin/MainVBox/StageVBox/StageRow/NextButton.pressed.connect(func(): _change_stage(1))
	$Margin/MainVBox/StageVBox/StageRow/StageLabelButton.pressed.connect(func(): _show_panel($SelectPanel))
	$Margin/MainVBox/ActionRow/ChestButton.pressed.connect(func(): _show_panel($InfoPanel))
	$Margin/MainVBox/ActionRow/PatrolButton.pressed.connect(func(): _show_panel($PatrolPanel))
	$LeftVBox/EventButton.pressed.connect(func(): _side_popup("EVENT", "Seasonal event — coming soon.\nThis side slot is for events\nand promotions."))
	$LeftVBox/PromoButton.pressed.connect(func(): _side_popup("PROMO", "Special deal — coming soon.\nThis side slot is for deals\nand bundles."))
	$LeftVBox/StarterButton.pressed.connect(func(): _side_popup("STARTER", "Starter pack — test only.\nSimple card, no purchase yet."))
	$RightVBox/DailyButton.pressed.connect(func(): _side_popup("DAILY", "Daily check-in — coming soon.\nClaim will be here."))
	$RightVBox/GiftsButton.pressed.connect(func(): _side_popup("GIFTS", "Gifts — coming soon.\nClaimable gifts will list here."))
	$RightVBox/RanksButton.pressed.connect(func(): _side_popup("RANKS", "Rankings — coming soon.\nLeaderboard will list here."))
	$SelectPanel/SelectClose.pressed.connect(func(): _hide_panels())
	$SelectPanel/SelectGo.pressed.connect(func(): _smooth_change_scene("res://battle.tscn"))
	$PatrolPanel/PatrolClose.pressed.connect(func(): _hide_panels())
	$PatrolPanel/PatrolClaim.pressed.connect(func(): $PatrolPanel/PatrolLabel.text = "Auto-Patrol Gain\nCoins 34/h, Parts 8/h\nClaim will give 612 coins, 18 parts, 144 gems (show-only).\nNo granting yet — battle rewards update enables it.")
	$InfoPanel/InfoClose.pressed.connect(func(): _hide_panels())
	$SidePanel/SideClose.pressed.connect(func(): _hide_panels())
	# Unified inactive set (dev42): ALL inactive tabs use their dull
	# slate texture, modulate white. No dimmed-lit Store/Quests, which
	# stayed cyan/gold and looked brighter than the grey Gear/Modes.
	$Margin/MainVBox/NavBar/NavVBox/NavRow/SlotStore/NavStore.pressed.connect(func(): _on_nav_tap("NavStore", "res://store.tscn"))
	$Margin/MainVBox/NavBar/NavVBox/NavRow/SlotGear/NavGear.pressed.connect(func(): _on_nav_tap("NavGear", "res://gear.tscn"))
	$Margin/MainVBox/NavBar/NavVBox/NavRow/SlotModes/NavModes.pressed.connect(func(): _on_nav_tap("NavModes", "res://modes.tscn"))
	$Margin/MainVBox/NavBar/NavVBox/NavRow/SlotQuests/NavQuests.pressed.connect(func(): _on_nav_tap("NavQuests", "res://quests.tscn"))
	$Margin/MainVBox/NavBar/NavVBox/NavRow/SlotBattle/NavBattle.pressed.connect(func(): _on_nav_tap("NavBattle", ""))
	# Bottom bar: the look (fill, outline, notch) is ONE drawn shape, see
	# nav_dock.gd. The PanelContainer only keeps the layout padding.
	var bar_box := StyleBoxEmpty.new()
	bar_box.content_margin_top = 12
	bar_box.content_margin_bottom = 8
	bar_box.content_margin_left = 8
	bar_box.content_margin_right = 8
	$Margin/MainVBox/NavBar.add_theme_stylebox_override("panel", bar_box)
	# Label row overlaps the button row a little so the word sits right under the lifted icon.
	$Margin/MainVBox/NavBar/NavVBox.add_theme_constant_override("separation", -10)
	_nav_empty = StyleBoxEmpty.new()
	for tab in NAV_TABS:
		var nb := _nav_btn(tab)
		for state in ["normal", "hover", "pressed", "focus"]:
			nb.add_theme_stylebox_override(state, _nav_empty)
		# The icon files are big; expand_icon keeps the button at its set size.
		nb.expand_icon = true
		var nl := _nav_label(tab)
		nl.add_theme_font_size_override("font_size", 14)
		nl.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
	_nav_label("NavBattle").modulate.a = 0.0
	# View Manager (dev43): persistent Hub shell. ViewContainer holds
	# Gear/Modes/Quests/Store views; NavBar stays in MainVBox above it
	# (tree order after Background, z 0), so nav + notch + lit tab persist on every
	# menu. Battle stays a separate game scene, not a view.
	_view_container = Control.new()
	_view_container.name = "ViewContainer"
	_view_container.clip_contents = true
	# dev44 fix: was -10, which drew the view BEHIND Hub's opaque
	# full-screen Background (z 0) on the phone, so every menu looked
	# empty. z 0 + tree order after Background (move_child 3, before
	# Margin) puts the view above Background but below Margin/NavBar.
	_view_container.z_index = 0
	_view_container.size = size
	add_child(_view_container)
	move_child(_view_container, 3)
	# Notch + lift + label fade, smooth (Tween, not instant jump).
	# Deferred so containers have laid out first, then animate in.
	# The one-piece bar. Sits above the menu views, below the bar's buttons.
	_nav_dock = NavDock.new()
	_nav_dock.name = "NavDock"
	add_child(_nav_dock)
	move_child(_nav_dock, _view_container.get_index() + 1)
	_nav_dock.setup($Margin/MainVBox/NavBar)
	_nav_dock.snap_to_tab(_nav_btn("NavBattle"), 0)
	call_deferred("_animate_nav_in")

var _transitioning := false
var _nav_dock: NavDock = null
var _nav_empty: StyleBoxEmpty = null
var _nav_active := "NavBattle"
var _pulse_tween: Tween = null
var _view_container: Control = null
var _current_view: Control = null
var _current_view_name := "NavBattle"

# Short helpers so the long node paths live in exactly one place.
func _nav_btn(tab: String) -> Button:
	return $Margin/MainVBox/NavBar/NavVBox/NavRow.get_node("Slot%s/%s" % [tab.substr(3), tab]) as Button

func _nav_label(tab: String) -> Label:
	return $Margin/MainVBox/NavBar/NavVBox/NavLabelRow.get_node("Label%s" % tab.substr(3)) as Label

func _on_nav_tap(tapped: String, path: String) -> void:
	if _transitioning: return
	_transitioning = true
	_stop_nav_pulse()
	var edge := -1 if tapped == "NavStore" else (1 if tapped == "NavQuests" else 0)
	var tapped_btn := _nav_btn(tapped)
	_spawn_spark_burst(tapped_btn)
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
		l.text = tab.substr(3).to_upper() if on else ""
		if on:
			l.modulate.a = 0.0
			tw.tween_property(l, "modulate:a", 1.0, 0.25)
	_nav_active = tapped
	await tw.finished
	_transitioning = false
	if tapped == "NavBattle":
		_show_home()
		_start_nav_pulse("NavBattle")
	else:
		_show_view(tapped, path)
		_start_nav_pulse(tapped)

func _set_home_visible(visible: bool) -> void:
	# View Manager: Home content on/off, NavBar always stays. When a
	# view is shown, MainVBox alignment END pushes the lone visible
	# NavBar to the bottom (otherwise a VBox with only NavBar visible
	# would put it at the top). AFK is paused in view mode.
	var main = $Margin/MainVBox
	main.alignment = BoxContainer.ALIGNMENT_BEGIN if visible else BoxContainer.ALIGNMENT_END
	for n in [$Margin/MainVBox/TopBar, $Margin/MainVBox/StageVBox, $Margin/MainVBox/AFKSpacer, $Margin/MainVBox/AFKLabel, $Margin/MainVBox/BestLabel, $Margin/MainVBox/ActionRow]:
		n.visible = visible
	$Hero.visible = visible
	$AFKDraw.visible = visible
	$LeftVBox.visible = visible
	$RightVBox.visible = visible
	if visible:
		$AFKDraw.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		_hide_panels()
		$AFKDraw.process_mode = Node.PROCESS_MODE_DISABLED

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

func _animate_nav_in() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_nav_active = "NavBattle"
	# Centre each button in its slot (a plain Control, so the position sticks).
	# Battle starts lifted and slightly bigger; the others rest.
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

func _process(delta: float) -> void:
	# dev45 first-load gap: Hub size was set once in _ready, but on a
	# tall phone the viewport's visible size can settle after that,
	# leaving Hub (and its bar) short of the screen bottom until the
	# first menu tap re-laid things out. Follow the viewport every
	# frame so the bar is flush from the very first frame, not after
	# the first tap. Margin (anchors 0,0,1,1) follows Hub size.
	var _vp = get_viewport_rect().size
	if size != _vp:
		size = _vp
	# Dev42 edge-to-edge + flush bottom: safe_area_margin.gd resets
	# margin_bottom to max(12, safe) on size_changed, which put a gap
	# below the bar on the phone (headless never sees it, window 0).
	# Re-assert 0 every frame, and force NavBar alone to full screen
	# width (upper rows keep their 12px Margin inset).
	if $Margin.get_theme_constant("margin_bottom") != 0:
		$Margin.add_theme_constant_override("margin_bottom", 0)
	var _bar2 = $Margin/MainVBox/NavBar
	var _ml = $Margin.get_theme_constant("margin_left")
	if _bar2.position.x != -float(_ml) or _bar2.size.x != size.x:
		_bar2.position.x = -float(_ml)
		_bar2.size.x = size.x
	# dev46 first-load bar height, part 2 (corrected after headless
	# proof): MarginContainer sizes itself to its child minimum,
	# NOT to Hub, so forcing Margin/MainVBox size to the viewport
	# in _process is undone by the next container sort - Margin
	# reverts to content height (headless: 956 for an 800 viewport).
	# The only way to push the bar to the screen bottom on first
	# load is to grow the content itself: size AFKSpacer to fill
	# the viewport height minus margins and the other Home rows.
	# On the phone the viewport is taller than the content, so the
	# spacer grows by exactly the gap that used to sit below the
	# bar; on Home the top rows do not move, only the AFK area
	# grows. After a menu tap the bar no longer drops, because it
	# was already at the bottom. Headless cannot prove this (its
	# 800px viewport is already shorter than the content minimum),
	# so the phone test is the verdict.
	if _current_view == null and $Margin/MainVBox/TopBar.visible:
		var _main2 = $Margin/MainVBox
		var _other2 := 0.0
		for _n in [$Margin/MainVBox/TopBar, $Margin/MainVBox/StageVBox, $Margin/MainVBox/AFKLabel, $Margin/MainVBox/BestLabel, $Margin/MainVBox/ActionRow, _bar2]:
			if _n.visible:
				_other2 += _n.size.y
		_other2 += float(_main2.get_theme_constant("separation")) * 6.0
		var _target2 = size.y - float($Margin.get_theme_constant("margin_top")) - float($Margin.get_theme_constant("margin_bottom")) - _other2
		var _spacer2 = $Margin/MainVBox/AFKSpacer
		if _target2 > 260.0 and abs(_spacer2.custom_minimum_size.y - _target2) > 1.0:
			_spacer2.custom_minimum_size.y = _target2
	# MainVBox position only (size is set by MarginContainer from
	# content, see above): the old entry-animation tween left it
	# at y=0 instead of the margin position.
	var _mt2 = float($Margin.get_theme_constant("margin_top"))
	if $Margin/MainVBox.position != Vector2(_ml, _mt2):
		$Margin/MainVBox.position = Vector2(_ml, _mt2)
	# View Manager: container fills the area above the nav bar, so a
	# view is clipped at the bar top and never covers the nav.
	if _view_container != null:
		_view_container.position = Vector2.ZERO
		_view_container.size = Vector2(size.x, _bar2.get_global_rect().position.y)
	# Re-centre buttons horizontally if slot width changed (e.g. safe-area
	# / layout settle after load) — x only, never y/scale, so it cannot
	# fight the Tween that controls lift/scale, and cannot cut off the
	# leftmost/rightmost icons by leaving them off-centre in their slots.
	for _slot_name in ["SlotStore", "SlotGear", "SlotBattle", "SlotModes", "SlotQuests"]:
		var _slot = $Margin/MainVBox/NavBar/NavVBox/NavRow.get_node(_slot_name)
		var _btn = _slot.get_child(0)
		var _cx = (_slot.size.x - _btn.size.x) / 2.0
		if abs(_btn.position.x - _cx) > 1.0:
			_btn.position.x = _cx
	if _current_view != null:
		return
	t += delta
	# Hero lives in the AFKSpacer, not at a viewport-calculated y.
	# Spacer rect is the real AFK area between stage and AFK ticker,
	# so hero can never overlap Best text or sit below nav again.
	var _sp = $Margin/MainVBox/AFKSpacer.get_global_rect()
	var _cx = _sp.position.x + _sp.size.x / 2.0
	var _cy = _sp.position.y + _sp.size.y / 2.0
	hero.position.x = _cx - 35.0 + sin(t * 0.7) * 80.0
	hero.position.y = _cy - 67.0 + sin(t * 1.3) * 25.0 + sin(t * 3.0) * 6.0
	$AFKDraw.afk_bottom = _sp.position.y + _sp.size.y
	$AFKDraw.afk_top = _sp.position.y
	var afk = $AFKDraw
	$Margin/MainVBox/AFKLabel.text = "AFK collected this session: %d coins (show-only)" % afk.afk_coins
	$Margin/MainVBox/ActionRow/BattleButton.modulate = Color(1, 1, 1) if sin(t * 3.0) > 0 else Color(0.9, 1, 0.95)

func _update_stage_label() -> void:
	var locked := stage > 1
	$Margin/MainVBox/StageVBox/StageLabel.text = "STAGE %d — %s" % [stage, "First Flight" if stage == 1 else "Locked" if locked else "Next Stage"]
	$Margin/MainVBox/StageVBox/StageRow/StageLabelButton.text = "%s STAGE %d" % [mode.to_upper(), stage]

func _set_mode(m: String) -> void:
	if m == "Elite" and not elite_unlocked:
		$Margin/MainVBox/StageVBox/StageLabel.text = "ELITE — LOCKED until Level 10"
		return
	mode = m
	_update_stage_label()

func _change_stage(d: int) -> void:
	stage = clamp(stage + d, 1, 5)
	_update_stage_label()

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
