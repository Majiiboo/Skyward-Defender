class_name SpinSheet
extends RefCounted
# The DAILY SPIN sheet (Spin): the wheel, a pointer at the top, ONE gold button (FREE SPIN, or
# the crystal price, or "Back tomorrow"), the odds as small print. SpinSheet.show(host, on_done).

class Wheel extends Control:
	var rot := 0.0          # radians the wheel has turned (a wedge's middle starts at the top)
	var glow := -1          # the wedge that just won (ringed)
	var glow_t := 0.0
	const R := 132.0
	var _pics: Array = []   # loaded once: a texture first loaded inside _draw shows as a white square

	func _ready() -> void:
		for seg in Spin.SEGMENTS:
			_pics.append(_icon(String(seg.reward.keys()[0])))

	func _process(delta: float) -> void:
		glow_t += delta
		queue_redraw()

	func _icon(k: String) -> Texture2D:
		match k:
			"coins": return UIKit.ic("ic_coin")
			"crystals": return UIKit.ic("ic_crystal")
			"key_u": return UIKit.ic("mat_key_u")
			"key_e": return UIKit.ic("mat_key_e")
		return Parts.icon(k)

	func _draw() -> void:
		var c := size * 0.5
		var n := Spin.SEGMENTS.size()
		var step := TAU / n
		draw_circle(c, R + 8.0, Color(0.027, 0.047, 0.094))
		draw_arc(c, R + 8.0, 0.0, TAU, 96, Color(1, 1, 1, 0.12), 2.0, true)
		for i in n:
			var seg: Dictionary = Spin.SEGMENTS[i]
			var mid := -PI / 2.0 + i * step + rot
			var pts := PackedVector2Array([c])
			for s in 13:
				var a := mid - step * 0.5 + step * s / 12.0
				pts.append(c + Vector2(cos(a), sin(a)) * R)
			var col: Color = seg.col
			var won: bool = i == glow
			draw_colored_polygon(pts, Color(col.r * 0.22 + 0.03, col.g * 0.22 + 0.04, col.b * 0.22 + 0.07) if not won else Color(col.r * 0.5, col.g * 0.5, col.b * 0.5))
			draw_arc(c, R - 3.0, mid - step * 0.5 + 0.03, mid + step * 0.5 - 0.03, 16, Color(col, 0.9), 4.0, true)
			draw_line(c, c + Vector2(cos(mid - step * 0.5), sin(mid - step * 0.5)) * R, Color(0.027, 0.047, 0.094), 2.0, true)
			# the prize: its picture and amount, upright, two thirds of the way out
			var p := c + Vector2(cos(mid), sin(mid)) * R * 0.66
			var key := String(seg.reward.keys()[0])
			var tx: Texture2D = _pics[i] if i < _pics.size() else null
			if tx != null:
				draw_texture_rect(tx, Rect2(p - Vector2(14, 20), Vector2(28, 28)), false)
			draw_string(UIKit.title_font(), p + Vector2(-30, 24), UIKit.num(int(seg.reward[key])), HORIZONTAL_ALIGNMENT_CENTER, 60.0, 13, Color.WHITE)
			if won:
				draw_arc(c, R - 3.0, mid - step * 0.5 + 0.03, mid + step * 0.5 - 0.03, 16, Color(1, 1, 1, 0.5 + 0.5 * sin(glow_t * 8.0)), 5.0, true)
		draw_circle(c, 22.0, UIKit.CARD_HI)
		draw_arc(c, 22.0, 0.0, TAU, 32, UIKit.GOLD, 2.0, true)
		# the pointer, fixed at the top
		var top := c + Vector2(0, -R - 10.0)
		draw_colored_polygon(PackedVector2Array([top + Vector2(-11, -8), top + Vector2(11, -8), top + Vector2(0, 14)]), UIKit.GOLD)

static func show(host: Control, on_done: Callable = Callable()) -> void:
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(layer)
	var dim := Button.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.01, 0.024, 0.055, 0.66)
	for st in ["normal", "hover", "pressed", "focus"]:
		dim.add_theme_stylebox_override(st, ds)
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
	slider.position.y = 700.0
	slider.create_tween().tween_property(slider, "position:y", 0.0, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	sheet.add_child(v)
	v.add_child(UIKit.popup_title("Daily spin"))
	var wheel := Wheel.new()
	wheel.custom_minimum_size = Vector2(0, 312)
	v.add_child(wheel)
	var result := UIKit.title("", 16, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	result.custom_minimum_size = Vector2(0, 22)
	v.add_child(result)
	var go := UIKit.gold_button("SPIN", 17)
	go.custom_minimum_size = Vector2(0, 54)
	v.add_child(go)
	var odds: Array = []
	for i in Spin.SEGMENTS.size():
		odds.append("%s %d%%" % [Progress.reward_text(Spin.SEGMENTS[i].reward), roundi(Spin.chance(i) * 100.0)])
	var small := UIKit.label("Odds: " + ",  ".join(odds), 10, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	small.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(small)
	var close := UIKit.ghost_button("Close", 13)
	close.custom_minimum_size = Vector2(0, 38)
	v.add_child(close)
	var busy := [false]
	var paint := func():
		var s := Progress.read()
		var why := Spin.why_not(s)
		var cost := Spin.cost(s)
		if Spin.left(s) <= 0:
			go.text = "BACK TOMORROW"
		elif cost == 0:
			go.text = "FREE SPIN"
		else:
			go.text = "SPIN  ·  %d crystals  (%d left)" % [cost, Spin.left(s)]
		go.disabled = why != "" or busy[0]
	paint.call()
	var shut := func():
		if busy[0]:
			return
		layer.queue_free()
		if on_done.is_valid():
			on_done.call()
	dim.pressed.connect(shut)
	close.pressed.connect(shut)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	go.pressed.connect(func():
		if busy[0]:
			return
		var s := Progress.read()
		var pick := Spin.spin(s, rng)
		if pick < 0:
			result.text = Spin.why_not(s)
			return
		Progress.write(s)
		busy[0] = true
		go.disabled = true
		wheel.glow = -1
		result.text = ""
		Sfx.play("tap")
		# turn so wedge `pick` ends under the pointer: a few whole turns, then the wedge, a little off centre
		var n := Spin.SEGMENTS.size()
		var target := -TAU * pick / n + rng.randf_range(-0.28, 0.28) * (TAU / n)
		var from := fposmod(wheel.rot, TAU)
		wheel.rot = from
		var to := target - TAU * 5.0
		while to > from - TAU * 4.0:
			to -= TAU
		var tw := wheel.create_tween()
		tw.tween_property(wheel, "rot", to, 3.4).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func():
			busy[0] = false
			wheel.glow = pick
			wheel.glow_t = 0.0
			result.text = "+ " + Progress.reward_text(Spin.SEGMENTS[pick].reward)
			Sfx.play("level" if float(Spin.SEGMENTS[pick].w) <= 5.0 else "coin")
			paint.call()))
