class_name WhatsNew
extends RefCounted
# WHAT'S NEW (2026-11-10): once per build, Home shows a short list of what changed, each line
# with where to find it. Save "seen_build" = the build whose list was shown. Edit NOTES with
# every pushed build (newest things first, eight lines at most: it is a sheet, not a changelog;
# README-RUDY.md keeps the full story). Also opened from Settings > About.

const NOTES := [
	["New power cards", "The cards are rebuilt: a colour that says the kind (orange attack, blue defence, green passive), the picture, a dot per level, one line. A tap takes the card. Hold a card to read more."],
	["Evolutions", "Take any three hero cards in a fight and an Evolution pick opens: choose one of the gold cards your hero has unlocked. His own comes first; more open at hero Lv.5, 10, 15, 20, 25 and 30."],
	["Cards unlock as he levels", "A new hero starts with a few basic cards. More join his picks as he levels up, so a build comes together fast early on."],
	["No free healing", "The base shield no longer mends after a wave and the hero's health does not come back. Earn it: the Field Medic card, a Repair Bay or Med Bay, Shield Recharge."],
	["Longer stages", "About a third more waves per stage, so a build has time to grow. Stages 1 to 3 are as short as before."],
	["Five new cards", "Split Shot, Seeker, Drone Barrage, Killer Instinct and Field Medic. Attack cards now have five levels."],
	["Burst Fire per weapon", "The pistol fires follow-up shots, twin pistols throw their extra balls together, the rifle's stream fires faster, the launcher adds small shells."],
	["Every hero moves", "Rook, Sparks, Hollow, Nyx and Ember are rebuilt for the fight like the penguin, each with his own pistol, rifle and launcher. Settings > New hero motion switches back."],
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
	v.add_child(UIKit.label("Build %s" % BuildInfo.BUILD, 12, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	# big, easy text; the list scrolls (Rudy, dev265: small writing in a lot of boxes)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(0, minf(host.size.y * 0.58, 520.0))
	v.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	sc.add_child(list)
	for n in NOTES:
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", UIKit.box(Color(UIKit.CARD_HI, 0.5), Color(1, 1, 1, 0.04), 18, 1))
		var m := MarginContainer.new()
		for side in ["left", "right"]:
			m.add_theme_constant_override("margin_" + side, 16)
		for side in ["top", "bottom"]:
			m.add_theme_constant_override("margin_" + side, 12)
		var rv := VBoxContainer.new()
		rv.add_theme_constant_override("separation", 5)
		var head := UIKit.title(String(n[0]), 18, UIKit.GOLD)
		head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rv.add_child(head)
		var body := UIKit.label(String(n[1]), 15, UIKit.TEXT)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rv.add_child(body)
		m.add_child(rv)
		row.add_child(m)
		list.add_child(row)
	var go := UIKit.gold_button("GOT IT", 17)
	go.custom_minimum_size = Vector2(0, 50)
	go.pressed.connect(layer.queue_free)
	v.add_child(go)
