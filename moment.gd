class_name Moment
extends RefCounted
# THE UNLOCK MOMENT (2026-11-10; REVIEW-2026-11-10.md, IDEAS-tap-titans-afk.md "a full unlock splash
# with art"): when something new opens, it gets the whole screen for a beat instead of a small
# pop-up. The page dims, rays turn behind the picture, a NEW chip, the name big, one line on what it
# is, and one gold button that takes you there (plus a quiet "Later").
# Moment.show(host, {"title", "text", "tex", "col", "chip", "go_text", "go": Callable}) -> the layer.
# The same look as the Ascend moment on the Heroes page (gear.gd _rarity_fx).

static func show(host: Control, o: Dictionary) -> Control:
	var col: Color = o.get("col", UIKit.CYAN)
	var layer := Control.new()
	layer.name = "Moment"
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP   # nothing behind it can be tapped
	host.add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.05, 0.95)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dim)
	layer.modulate.a = 0.0
	layer.create_tween().tween_property(layer, "modulate:a", 1.0, 0.2)
	var mid := Vector2(host.size.x * 0.5, host.size.y * 0.34)
	var rays := Control.new()
	rays.position = mid
	rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rays.draw.connect(func():
		for i in 14:
			var a := TAU * i / 14.0
			var w := 0.085 if i % 2 == 0 else 0.05
			rays.draw_colored_polygon(PackedVector2Array([Vector2.ZERO, Vector2(cos(a - w), sin(a - w)) * 420.0, Vector2(cos(a + w), sin(a + w)) * 420.0]), Color(col, 0.13 if i % 2 == 0 else 0.07))
		rays.draw_circle(Vector2.ZERO, 92.0, Color(0.055, 0.09, 0.157))
		rays.draw_circle(Vector2.ZERO, 92.0, Color(col, 0.14))
		rays.draw_arc(Vector2.ZERO, 92.0, 0.0, TAU, 64, Color(col, 0.8), 2.0, true))
	layer.add_child(rays)
	rays.scale = Vector2(0.2, 0.2)
	rays.create_tween().tween_property(rays, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not Perf.lite():
		rays.create_tween().set_loops().tween_property(rays, "rotation", TAU, 24.0).from(0.0)
	var tex: Texture2D = o.get("tex", null)
	if tex != null:
		var pic := TextureRect.new()
		pic.texture = tex
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # before the size, or the picture's own size wins
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.size = Vector2(124, 124)
		pic.position = mid - Vector2(62, 62)
		pic.pivot_offset = Vector2(62, 62)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(pic)
		pic.scale = Vector2(0.4, 0.4)
		pic.create_tween().tween_property(pic, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if not Perf.lite():
			var bob := pic.create_tween().set_loops()
			bob.tween_interval(0.5)
			bob.tween_property(pic, "position:y", mid.y - 68.0, 1.4).set_trans(Tween.TRANS_SINE)
			bob.tween_property(pic, "position:y", mid.y - 62.0, 1.4).set_trans(Tween.TRANS_SINE)
	var box := VBoxContainer.new()
	box.position = Vector2(28.0, mid.y + 120.0)
	box.size = Vector2(host.size.x - 56.0, 0.0)
	box.add_theme_constant_override("separation", 10)
	layer.add_child(box)
	var chip_row := HBoxContainer.new()
	chip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", UIKit.pill(col, 11, Vector2(12, 2)))
	chip.add_child(UIKit.title(String(o.get("chip", "NEW")), 12, Color(0.03, 0.07, 0.13)))
	chip_row.add_child(chip)
	var title := UIKit.title(String(o.get("title", "")).to_upper(), 34, UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var text := UIKit.label(String(o.get("text", "")), 14, Color(0.8, 0.85, 0.93), HORIZONTAL_ALIGNMENT_CENTER)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	var close := func():
		var out := layer.create_tween()
		out.tween_property(layer, "modulate:a", 0.0, 0.2)
		out.tween_callback(layer.queue_free)
	var items: Array = [chip_row, title, text, gap]
	var go: Callable = o.get("go", Callable())
	if go.is_valid():
		var gb := UIKit.gold_button(String(o.get("go_text", "SHOW ME")), 20)
		gb.custom_minimum_size = Vector2(0, 56)
		gb.pressed.connect(func():
			layer.queue_free()
			go.call())
		items.append(gb)
	var later := UIKit.ghost_button("Later" if go.is_valid() else "Got it", 14)
	later.custom_minimum_size = Vector2(0, 44)
	later.pressed.connect(close)
	items.append(later)
	var i := 0
	for it in items:
		box.add_child(it)
		(it as Control).modulate.a = 0.0
		var tw := (it as Control).create_tween()
		tw.tween_interval(0.25 + 0.12 * i)
		tw.tween_property(it, "modulate:a", 1.0, 0.25)
		i += 1
	Sfx.play("level", 1.2)
	return layer
