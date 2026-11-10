class_name ElementsChart
extends RefCounted
# THE ELEMENTS CHART (2026-11-10; Rudy, dev209: no plain "weak to fire" text, show it). One pop-up
# that answers "who should I bring?": the six planets down the side, each with the element its
# bugs are WEAK to (green, hits 35% harder) and the one they RESIST (red, hits 25% softer), the
# planet you are on ringed, and under it your own heroes with their elements. ElementsChart.show(host, stage).

static func _icon(el: String, px: float) -> TextureRect:
	var t := TextureRect.new()
	t.texture = UIKit.element_icon(el)
	t.custom_minimum_size = Vector2(px, px)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

static func show(host: Control, stage: int) -> void:
	var save := Progress.read()
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(layer)
	var dim := Button.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.01, 0.024, 0.055, 0.66)
	for st in ["normal", "hover", "pressed", "focus"]:
		dim.add_theme_stylebox_override(st, ds)
	dim.pressed.connect(layer.queue_free)
	layer.add_child(dim)
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
	var slider := Control.new()
	slider.set_anchors_preset(Control.PRESET_FULL_RECT)
	slider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(slider)
	slider.add_child(sheet)
	dim.modulate.a = 0.0
	dim.create_tween().tween_property(dim, "modulate:a", 1.0, 0.2)
	slider.position.y = 700.0
	slider.create_tween().tween_property(slider, "position:y", 0.0, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	sheet.add_child(v)
	v.add_child(UIKit.popup_title("Elements"))
	var key := HBoxContainer.new()
	key.alignment = BoxContainer.ALIGNMENT_CENTER
	key.add_theme_constant_override("separation", 14)
	key.add_child(UIKit.label("Green: hits 35% harder", 11, Color(0.44, 0.94, 0.72)))
	key.add_child(UIKit.label("Red: hits 25% softer", 11, Color(1.0, 0.45, 0.5)))
	v.add_child(key)
	var here := StageData.area_index(stage)
	var su := int(save.get("stage_unlocked", 1))
	for p in Heroes.FAMILIES.size():
		var fam: Dictionary = Heroes.FAMILIES[p]
		var reached: bool = su > p * 10 or DevTools.on
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", UIKit.box(Color(UIKit.CARD_HI, 0.6 if p == here else 0.3), UIKit.CYAN if p == here else Color(1, 1, 1, 0.04), 16, 1))
		var m := MarginContainer.new()
		for side in ["left", "right"]:
			m.add_theme_constant_override("margin_" + side, 12)
		for side in ["top", "bottom"]:
			m.add_theme_constant_override("margin_" + side, 7)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		var nv := VBoxContainer.new()
		nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nv.add_theme_constant_override("separation", 0)
		nv.add_child(UIKit.title(String(StageData.AREAS[p].name) if reached else "Planet %d" % (p + 1), 14, UIKit.TEXT if reached else UIKit.SOFT))
		nv.add_child(UIKit.label(String(fam.name) if reached else "Not reached yet", 11, UIKit.SOFT))
		h.add_child(nv)
		for pair in [[String(fam.weak), Color(0.44, 0.94, 0.72)], [String(fam.resist), Color(1.0, 0.45, 0.5)]]:
			var chip := PanelContainer.new()
			chip.add_theme_stylebox_override("panel", UIKit.box(Color(pair[1], 0.14), Color(pair[1], 0.7), 14, 1))
			chip.custom_minimum_size = Vector2(84, 36)
			var ch := HBoxContainer.new()
			ch.alignment = BoxContainer.ALIGNMENT_CENTER
			ch.add_theme_constant_override("separation", 5)
			ch.add_child(_icon(String(pair[0]), 20.0))
			ch.add_child(UIKit.label(Heroes.element_name(String(pair[0])), 11, UIKit.TEXT))
			chip.add_child(ch)
			if not reached:
				chip.modulate = Color(1, 1, 1, 0.35)
			h.add_child(chip)
		m.add_child(h)
		row.add_child(m)
		v.add_child(row)
	# your heroes and their elements; the ones this planet is weak to are ringed green
	var hs := Heroes.read(save)
	var mine := HBoxContainer.new()
	mine.alignment = BoxContainer.ALIGNMENT_CENTER
	mine.add_theme_constant_override("separation", 12)
	var weak_here := String(Heroes.FAMILIES[here].weak)
	var resist_here := String(Heroes.FAMILIES[here].resist)
	for id in Heroes.ROSTER:
		if not Heroes.owned(hs, String(id)):
			continue
		var el := Heroes.element_of(String(id))
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		var ic := _icon(el, 26.0)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cell.add_child(ic)
		var col := UIKit.SOFT
		if el == weak_here:
			col = Color(0.44, 0.94, 0.72)
		elif el == resist_here:
			col = Color(1.0, 0.45, 0.5)
		cell.add_child(UIKit.label(String(Heroes.ROSTER[id].name), 11, col, HORIZONTAL_ALIGNMENT_CENTER))
		mine.add_child(cell)
	v.add_child(UIKit.label("Your heroes", 11, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(mine)
	var close := UIKit.ghost_button("Close", 13)
	close.custom_minimum_size = Vector2(0, 38)
	close.pressed.connect(layer.queue_free)
	v.add_child(close)
