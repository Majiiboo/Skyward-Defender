class_name WhatsNew
extends RefCounted
# WHAT'S NEW (2026-11-10): once per build, Home shows a short list of what changed, each line
# with where to find it. Save "seen_build" = the build whose list was shown. Edit NOTES with
# every pushed build (newest things first, eight lines at most: it is a sheet, not a changelog;
# README-RUDY.md keeps the full story). Also opened from Settings > About.

const NOTES := [
	["The Magma World has its own creatures", "From stage 21: Cinder Flies, Crust Backs, Spitfires and Comets of black rock and lava. The Smelter guards stage 25 and the Caldera Queen stage 30."],
	["Expedition: build the base as you go", "Modes > Expedition: stops 3 and 6 are Field works, where you bolt an upgrade onto the base for the rest of the run. Runs are harder."],
	["Campaign", "Modes > Campaign: the trail of every stage, with the commander's story messages and a star chest at 10, 20 and 30 stars on each planet."],
	["Weapon evolutions", "Heroes > the weapon: every weapon changes shape at Lv.10 and Lv.20, and each shape fires differently."],
	["A new base", "A glowing core and four pods. Tap the core in a fight for the Core Pulse (stage 7). Heroes > Base: nine buildings, perks at level 5, pairs that link, and their own power cards."],
	["Boss Rush, special waves, abilities", "Modes: Boss Rush (stage 20). From stage 8 some waves are a Swarm, a Heavy wave, a Rush or a Gold Rush. Heroes: an Ability button with three upgrades."],
	["Research, Season Pass, daily rewards", "Heroes > Base > Research (stage 12). The trophy on Home: a 30-day Season Pass (stage 8). Store: a free spin and three deals a day."],
	["Music, settings and hints", "Settings: music, volume, vibration, screen shake. A one-line hint shows the first time a new screen opens; switch them off in Settings."],
]

static func due(save: Dictionary) -> bool:
	return String(save.get("seen_build", "")) != BuildInfo.BUILD and int(save.get("stage_unlocked", 1)) > 1

static func mark(save: Dictionary) -> void:
	save["seen_build"] = BuildInfo.BUILD

static func show(host: Control) -> void:
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(layer)
	var dim := Button.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.01, 0.024, 0.055, 0.7)
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
	dim.modulate.a = 0.0
	dim.create_tween().tween_property(dim, "modulate:a", 1.0, 0.2)
	slider.position.y = 800.0
	slider.create_tween().tween_property(slider, "position:y", 0.0, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 7)
	sheet.add_child(v)
	v.add_child(UIKit.popup_title("What's new"))
	v.add_child(UIKit.label("Build %s" % BuildInfo.BUILD, 11, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	for n in NOTES:
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", UIKit.box(Color(UIKit.CARD_HI, 0.5), Color(1, 1, 1, 0.04), 14, 1))
		var m := MarginContainer.new()
		for side in ["left", "right"]:
			m.add_theme_constant_override("margin_" + side, 12)
		for side in ["top", "bottom"]:
			m.add_theme_constant_override("margin_" + side, 6)
		var rv := VBoxContainer.new()
		rv.add_theme_constant_override("separation", 1)
		rv.add_child(UIKit.title(String(n[0]), 14, UIKit.GOLD))
		var body := UIKit.label(String(n[1]), 11, UIKit.TEXT)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rv.add_child(body)
		m.add_child(rv)
		row.add_child(m)
		v.add_child(row)
	var go := UIKit.gold_button("GOT IT", 17)
	go.custom_minimum_size = Vector2(0, 50)
	go.pressed.connect(layer.queue_free)
	v.add_child(go)
