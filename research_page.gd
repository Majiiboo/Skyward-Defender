extends Control
# The RESEARCH LAB page (Research, 2026-11-10). On top: what the lab is doing (a project and its
# clock, with COLLECT when done or a crystal button to finish it now), or "The lab is free".
# Under it the eight projects as squares: icon, name, five pips, what the next level gives, its
# price and time. Tapping one starts it when the lab is free.

var d := {}
var _col: VBoxContainer
var _clock: Label = null
var _tick := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	MenuBackdrop.add_to(self)
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left", "margin_right"]:
		root.add_theme_constant_override(m, 12)
	root.add_theme_constant_override("margin_top", 10 + int(SafeAreaMargin.top_inset(get_viewport())))
	root.add_theme_constant_override("margin_bottom", 16)
	add_child(root)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	UIKit.smooth_scroll(scroll)   # a drag scrolls from anywhere (Rudy, dev265)
	_col = VBoxContainer.new()
	_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_col.add_theme_constant_override("separation", 10)
	scroll.add_child(_col)
	_fill()
	UIKit.enter(self)
	Hints.show(self, ["research"])

func _process(delta: float) -> void:
	_tick += delta
	if _tick < 1.0:
		return
	_tick = 0.0
	var r := Research.read(d)
	var left := Research.left_s(r)
	if left == 0 and is_instance_valid(_clock):
		_fill()   # it just finished: show COLLECT
	elif left > 0 and is_instance_valid(_clock):
		_clock.text = Research.time_text(left)

func _fill() -> void:
	d = Progress.read()
	_clock = null
	for c in _col.get_children():
		_col.remove_child(c)
		c.queue_free()
	var r := Research.read(d)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	var back := UIKit.ghost_button("Back")
	back.custom_minimum_size = Vector2(70, 32)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://hub.tscn"))
	top.add_child(back)
	var ttl := UIKit.screen_title("RESEARCH")
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(ttl)
	top.add_child(UIKit.iconed(UIKit.ic("ic_coin"), UIKit.num(int(d.get("coins", 0))), 13, UIKit.TEXT, 18.0))
	top.add_child(UIKit.iconed(UIKit.ic("ic_crystal"), UIKit.num(int(d.get("crystals", 0))), 13, UIKit.TEXT, 18.0))
	_col.add_child(top)
	# the lab right now
	var card := UIKit.panel(22)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	var left := Research.left_s(r)
	if left < 0:
		v.add_child(UIKit.title("The lab is free", 20, UIKit.TEXT))
		var hint := UIKit.label("Pick a project below. It runs while you play and while the game is closed.", 12, UIKit.SOFT)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(hint)
	else:
		var id := String(r.active)
		var def: Dictionary = Research.PROJECTS[id]
		var lv := Research.level(r, id)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		var pic := TextureRect.new()
		pic.texture = UIKit.ic(String(def.icon))
		pic.custom_minimum_size = Vector2(56, 56)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.add_child(pic)
		var nv := VBoxContainer.new()
		nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nv.add_theme_constant_override("separation", 2)
		nv.add_child(UIKit.title("%s  ·  level %d" % [String(def.name), lv + 1], 18, UIKit.TEXT))
		nv.add_child(UIKit.label(Research.text(id, lv + 1), 12, UIKit.SOFT))
		h.add_child(nv)
		if left > 0:
			_clock = UIKit.title(Research.time_text(left), 20, UIKit.CYAN)
			_clock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(_clock)
		v.add_child(h)
		if left == 0:
			var go := UIKit.gold_button("COLLECT", 17)
			go.custom_minimum_size = Vector2(0, 52)
			go.pressed.connect(_on_collect)
			v.add_child(go)
		else:
			var total: float = float(Research.time_s(lv))
			var share: float = clampf(1.0 - left / maxf(total, 1.0), 0.0, 1.0)
			var bar := Control.new()
			bar.custom_minimum_size = Vector2(0, 8)
			bar.draw.connect(func():
				bar.draw_style_box(UIKit.pill(Color(1, 1, 1, 0.08), 4, Vector2.ZERO), Rect2(Vector2.ZERO, bar.size))
				bar.draw_style_box(UIKit.pill(UIKit.CYAN, 4, Vector2.ZERO), Rect2(0, 0, maxf(bar.size.x * share, 8.0), bar.size.y)))
			v.add_child(bar)
			var rush := UIKit.teal_button("Finish now  ·  %d crystals" % Research.rush_cost(r), 14)
			rush.custom_minimum_size = Vector2(0, 46)
			rush.pressed.connect(_on_rush)
			v.add_child(rush)
	_col.add_child(card)
	# the projects
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for pid in Research.ORDER:
		grid.add_child(_project(String(pid), r))
	_col.add_child(grid)
	UIKit.reveal(_col)

func _project(id: String, r: Dictionary) -> Button:
	var def: Dictionary = Research.PROJECTS[id]
	var lv := Research.level(r, id)
	var running: bool = String(r.active) == id
	var maxed: bool = lv >= Research.MAX_LEVEL
	var why := Research.why_not_start(d, r, id)
	var can: bool = why == ""
	var b := Button.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 150)
	var edge := Color(1, 1, 1, 0.05)
	if running:
		edge = UIKit.CYAN
	elif can:
		edge = Color(UIKit.GOLD, 0.6)
	var nb := UIKit.box(Color(UIKit.CARD_HI, 0.55), edge, 20, 1)
	for st in ["normal", "hover", "disabled"]:
		b.add_theme_stylebox_override(st, nb)
	b.add_theme_stylebox_override("pressed", UIKit.box(UIKit.CARD_HI, UIKit.GOLD, 20, 2))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var bv := VBoxContainer.new()
	bv.set_anchors_preset(Control.PRESET_FULL_RECT)
	bv.offset_left = 10.0
	bv.offset_right = -10.0
	bv.offset_top = 8.0
	bv.offset_bottom = -8.0
	bv.add_theme_constant_override("separation", 4)
	bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pic := TextureRect.new()
	pic.texture = UIKit.ic(String(def.icon))
	pic.custom_minimum_size = Vector2(34, 34)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(pic)
	var nl := UIKit.title(String(def.name), 14, UIKit.TEXT)
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(nl)
	bv.add_child(top)
	var pips := Control.new()
	pips.custom_minimum_size = Vector2(0, 12)
	pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pips.draw.connect(func():
		for i in Research.MAX_LEVEL:
			var c := Vector2(6.0 + i * 16.0, 6.0)
			if i < lv:
				pips.draw_circle(c, 5.0, UIKit.CYAN)
			else:
				pips.draw_arc(c, 4.5, 0.0, TAU, 20, Color(UIKit.CYAN, 0.45 if not (running and i == lv) else 1.0), 1.5, true))
	bv.add_child(pips)
	var now := UIKit.label(Research.text(id, lv) if lv > 0 else "Not started", 11, UIKit.SOFT)
	now.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bv.add_child(now)
	if not maxed:
		var nx := UIKit.label("Next: " + Research.text(id, lv + 1), 11, UIKit.TEXT)
		nx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nx.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bv.add_child(nx)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bv.add_child(gap)
	var state := PanelContainer.new()
	state.custom_minimum_size = Vector2(0, 30)
	state.mouse_filter = Control.MOUSE_FILTER_IGNORE
	state.add_theme_stylebox_override("panel", UIKit.pill(UIKit.GOLD if can else Color(UIKit.CARD, 0.9), 12, Vector2(6, 0)))
	var st_text := "Finished" if maxed else ("Running" if running else ("%s  ·  %s" % [UIKit.num(Research.cost(lv)), Research.time_text(Research.time_s(lv))]))
	var sl := UIKit.title(st_text, 12, UIKit.GOLD_INK if can else UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	state.add_child(sl)
	bv.add_child(state)
	b.add_child(bv)
	b.pressed.connect(func(): _on_start(id))
	UIKit.press_fx(b)
	return b

func _on_start(id: String) -> void:
	d = Progress.read()
	var why := Research.start(d, id)
	if why != "":
		_toast(why)
		return
	Progress.write(d)
	Sfx.play("upgrade")
	_toast("%s started" % String(Research.PROJECTS[id].name))
	_fill()

func _on_collect() -> void:
	d = Progress.read()
	var id := Research.collect(d)
	if id == "":
		return
	Progress.write(d)
	Sfx.play("level")
	var r := Research.read(d)
	_toast("%s level %d: %s" % [String(Research.PROJECTS[id].name), Research.level(r, id), Research.text(id, Research.level(r, id))])
	_fill()

func _on_rush() -> void:
	d = Progress.read()
	var why := Research.rush(d)
	if why != "":
		_toast(why)
		return
	Progress.write(d)
	Sfx.play("coin")
	_fill()

func _toast(text: String) -> void:
	var l := UIKit.label(text, 13, UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.pill(Color(0.02, 0.04, 0.09, 0.95), 16, Vector2(16, 10)))
	p.add_child(l)
	p.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN
	p.offset_bottom = -40.0
	p.custom_minimum_size = Vector2(300, 0)
	add_child(p)
	var tw := p.create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)
