extends Control
# Settings (dev159, queue 27). Opened from Home's menu button. Performance mode (Perf),
# a frame counter switch, the sound switch (Sfx; music greyed until it exists), the build and
# links to the Stage Map. Same glass look and planet wallpaper as every page.

var d := {}
var _page: VBoxContainer
var _fps: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	MenuBackdrop.add_to(self)
	d = Progress.read()
	_build()
	UIKit.enter(self)

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
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	var back := UIKit.ghost_button("Back")
	back.name = "BackButton"
	back.custom_minimum_size = Vector2(70, 32)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://hub.tscn"))
	top.add_child(back)
	top.add_child(UIKit.screen_title("SETTINGS"))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	_fps = UIKit.label("", 12, UIKit.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	top.add_child(_fps)
	col.add_child(top)
	_page = VBoxContainer.new()
	_page.add_theme_constant_override("separation", 10)
	col.add_child(_page)
	_fill()

func _fill() -> void:
	for c in _page.get_children():
		c.queue_free()
	# ---- DEV MODE (Rudy, dev172): one switch, everything open and free, for trying things out
	var dev_p := UIKit.panel(12)
	if DevTools.on:
		dev_p.add_theme_stylebox_override("panel", UIKit.box(Color(1.0, 0.6, 0.2, 0.14), Color(1.0, 0.6, 0.2, 0.7), 20))
	var dh := HBoxContainer.new()
	dh.add_theme_constant_override("separation", 10)
	var dv := VBoxContainer.new()
	dv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dv.add_theme_constant_override("separation", 1)
	dv.add_child(UIKit.title("DEV MODE  ·  UNLOCK EVERYTHING", 15, Color(1.0, 0.75, 0.3) if DevTools.on else UIKit.TEXT))
	dv.add_child(UIKit.label("Every hero, building, drone, weapon, mode and trial open; upgrades and unlocks free; no power cost. Your real progress stays as it is.", 11, UIKit.MUTED))
	dv.get_child(1).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dh.add_child(dv)
	dh.add_child(_toggle(DevTools.on, func():
		d = Progress.read()
		d["dev_mode"] = not DevTools.on
		DevTools.on = bool(d.dev_mode)
		Progress.write(d)
		_fill(), Color(1.0, 0.6, 0.2)))
	dev_p.add_child(dh)
	_page.add_child(dev_p)
	# ---- performance: three cards, the chosen one lit
	_page.add_child(UIKit.header("PERFORMANCE"))
	var cur := Perf.read(d)
	for m in Perf.MODES:
		var info: Dictionary = Perf.INFO[m]
		var on: bool = m == cur
		var p := UIKit.panel(12)
		if on:
			p.add_theme_stylebox_override("panel", UIKit.box(Color(UIKit.CYAN, 0.12), Color(UIKit.CYAN, 0.7), 20) if UIKit.CLEAN else (UIKit.nine("panel_gold", 22.0, Vector2(12, 9)) if UIKit.kit_ready("panel_gold") else UIKit.lift(UIKit.box(Color(UIKit.CYAN, 0.16), UIKit.CYAN, 12))))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 1)
		v.add_child(UIKit.label(info.name, 15, Color.WHITE if on else Color(0.85, 0.9, 1.0)))
		v.add_child(UIKit.label(info.desc, 11, UIKit.MUTED))
		h.add_child(v)
		var b: Button
		if on:
			b = UIKit.ghost_button("On", 13)
			b.disabled = true
		else:
			b = UIKit.teal_button("Use", 13)
			var pick: String = m
			b.pressed.connect(func():
				d = Progress.read()
				Perf.set_mode(d, pick)
				Progress.write(d)
				_fill())
		b.custom_minimum_size = Vector2(70, 34)
		h.add_child(b)
		p.add_child(h)
		_page.add_child(p)
	_page.add_child(_switch("Left-handed", "Swaps the AUTO and ability buttons in a fight", bool(d.get("left_hand", false)), func(v: bool):
		d = Progress.read()
		d["left_hand"] = v
		Progress.write(d)
		_fill()))
	_page.add_child(_switch("Show frame counter", "A small fps number in battle, for testing", bool(d.get("show_fps", false)), func(v: bool):
		d = Progress.read()
		d["show_fps"] = v
		Perf.show_fps = v
		Progress.write(d)
		_fill()))
	# ---- sound (Sfx, dev168: synthesized placeholders until a sound pack exists; music later)
	_page.add_child(UIKit.header("SOUND"))
	_page.add_child(_switch("Sound effects", "Shots, hits, pickups, cards and menu taps", bool(d.get("sound_on", true)), func(v: bool):
		d = Progress.read()
		d["sound_on"] = v
		Sfx.set_on(v)
		Progress.write(d)
		_fill()))
	_page.add_child(_choice("Volume", "How loud the sound effects are", [["Quiet", 0.3], ["Medium", 0.6], ["Full", 1.0]], float(d.get("sfx_vol", 1.0)), func(v):
		d = Progress.read()
		d["sfx_vol"] = float(v)
		Sfx.set_volume(float(v))
		Progress.write(d)
		Sfx.play("coin")
		_fill()))
	_page.add_child(_switch("Music", "A calm loop in the menus, a driving one in a fight", bool(d.get("music_on", true)), func(v: bool):
		d = Progress.read()
		d["music_on"] = v
		Music.set_on(v)
		if v:
			Music.play("menu")
		Progress.write(d)
		_fill()))
	# ---- the fight: how it feels (battle.gd reads these at the stage start)
	_page.add_child(UIKit.header("FIGHT"))
	_page.add_child(_switch("Vibration", "A short buzz when you or the base are hit", bool(d.get("haptics", true)), func(v: bool):
		d = Progress.read()
		d["haptics"] = v
		Progress.write(d)
		if v:
			Input.vibrate_handheld(40)
		_fill()))
	_page.add_child(_choice("Screen shake", "How hard the screen shakes on big hits", [["Off", 0.0], ["Less", 0.5], ["Full", 1.0]], float(d.get("shake", 1.0)), func(v):
		d = Progress.read()
		d["shake"] = float(v)
		Progress.write(d)
		_fill()))
	_page.add_child(_switch("Damage numbers", "Numbers over the bugs you hit", bool(d.get("dmg_numbers", true)), func(v: bool):
		d = Progress.read()
		d["dmg_numbers"] = v
		Progress.write(d)
		_fill()))
	_page.add_child(_switch("Auto-advance", "After a win the next stage starts by itself", bool(d.get("auto_next", false)), func(v: bool):
		d = Progress.read()
		d["auto_next"] = v
		Progress.write(d)
		_fill()))
	# ---- game
	_page.add_child(UIKit.header("GAME"))
	var map := UIKit.panel(12)
	var mh := HBoxContainer.new()
	mh.add_theme_constant_override("separation", 10)
	var mv := VBoxContainer.new()
	mv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mv.add_theme_constant_override("separation", 1)
	mv.add_child(UIKit.label("Stage Map", 15, Color(0.85, 0.9, 1.0)))
	mv.add_child(UIKit.label("Every stage, its stars and what it drops", 11, UIKit.MUTED))
	mh.add_child(mv)
	var mb := UIKit.teal_button("Open", 13)
	mb.custom_minimum_size = Vector2(70, 34)
	mb.pressed.connect(func(): get_tree().change_scene_to_file("res://stage_map.tscn"))
	mh.add_child(mb)
	map.add_child(mh)
	_page.add_child(map)
	var tp := UIKit.panel(12)
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 10)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_theme_constant_override("separation", 1)
	tv.add_child(UIKit.label("Show the tips again", 15, Color(0.85, 0.9, 1.0)))
	tv.add_child(UIKit.label("The first-time pointers on every screen", 11, UIKit.MUTED))
	th.add_child(tv)
	var tb := UIKit.teal_button("Reset", 13)
	tb.custom_minimum_size = Vector2(70, 34)
	tb.pressed.connect(func():
		Tips.reset()
		tb.text = "Done"
		tb.disabled = true)
	th.add_child(tb)
	tp.add_child(th)
	_page.add_child(tp)
	# ---- developer shortcuts (DevTools), only while BuildInfo.DEV is true
	if BuildInfo.DEV:
		_page.add_child(UIKit.header("DEVELOPER  ·  this build only"))
		for spec in [
			["Rich wallet", "+500k coins, +20k crystals, 999 Alloy, 500 Cells, 200 Cores, 999 power", DevTools.rich],
			["Unlock everything", "All 60 stages with 3 stars, pilot level 40, Commander suit, Elite, every turret and trial", DevTools.unlock_all],
			["Gear copies to merge", "9 Common, 3 Uncommon, 3 Rare, 3 Epic copies of every piece you own", DevTools.gear_copies],
			["Fresh save", "Deletes the save: a brand-new player, tips and all (tap twice)", DevTools.fresh],
		]:
			var p := UIKit.panel(12)
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 10)
			var v := VBoxContainer.new()
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v.add_theme_constant_override("separation", 1)
			v.add_child(UIKit.label(spec[0], 15, Color(1.0, 0.85, 0.6)))
			var hl := UIKit.label(spec[1], 11, UIKit.MUTED)
			hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			v.add_child(hl)
			h.add_child(v)
			var b := UIKit.gold_button("Do it", 13)
			b.custom_minimum_size = Vector2(76, 34)
			var fn: Callable = spec[2]
			var armed := [false]
			var fresh: bool = spec[0] == "Fresh save"
			b.pressed.connect(func():
				if fresh and not armed[0]:
					armed[0] = true
					b.text = "Sure?"
					return
				fn.call()
				b.text = "Done"
				b.disabled = true
				d = Progress.read())
			h.add_child(b)
			p.add_child(h)
			_page.add_child(p)
	# ---- about
	_page.add_child(UIKit.header("ABOUT"))
	var ab := UIKit.panel(12)
	var av := VBoxContainer.new()
	av.add_theme_constant_override("separation", 1)
	av.add_child(UIKit.label("Skybound Defender  ·  build %s%s" % [BuildInfo.BUILD, "  ·  developer build" if BuildInfo.DEV else ""], 13, Color.WHITE))
	av.add_child(UIKit.label("Art: Luna  ·  Design: Rudy  ·  Draws at your phone's own resolution", 11, UIKit.MUTED))
	var wn := UIKit.teal_button("What is new in this build", 13)
	wn.custom_minimum_size = Vector2(0, 38)
	wn.pressed.connect(func(): WhatsNew.show(self))
	av.add_child(wn)
	ab.add_child(av)
	_page.add_child(ab)
	UIKit.reveal(_page)

# a row with a name, one line of help and an On / Off switch (greyed when not built)
# an on/off switch (the clean look): a pill track, coloured when on, with a white knob that sits right
func _toggle(on: bool, on_press: Callable, col: Color = UIKit.CYAN) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(58, 34)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	b.draw.connect(func():
		var r := Rect2(Vector2(2.0, (b.size.y - 30.0) * 0.5), Vector2(54.0, 30.0))
		b.draw_style_box(UIKit.pill(col if on else Color(0.165, 0.22, 0.32), 15, Vector2.ZERO), r)
		var kx: float = r.position.x + (r.size.x - 15.0 if on else 15.0)
		b.draw_circle(Vector2(kx, r.get_center().y), 11.0, Color(1, 1, 1, 0.45 if b.disabled else 1.0)))
	b.pressed.connect(on_press)
	UIKit.press_fx(b)
	return b

func _switch(name: String, help: String, on: bool, on_change: Callable, soon: bool = false) -> Control:
	var p := UIKit.panel(12)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 1)
	v.add_child(UIKit.label(name, 15, Color(0.85, 0.9, 1.0) if not soon else UIKit.MUTED))
	v.add_child(UIKit.label(help, 11, UIKit.MUTED))
	h.add_child(v)
	var b := _toggle(on, func(): on_change.call(not on))
	b.disabled = soon
	h.add_child(b)
	p.add_child(h)
	if soon:
		p.modulate.a = 0.6
	return p

func _process(_delta: float) -> void:
	if _fps:
		_fps.text = "%d fps  ·  %s" % [Engine.get_frames_per_second(), Perf.INFO[Perf.mode].name]

# a row with a name, one line of help and a few pills to choose from: options = [[label, value], ...]
func _choice(name: String, help: String, options: Array, current: float, on_pick: Callable) -> Control:
	var p := UIKit.panel(12)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.add_child(UIKit.label(name, 15, Color(0.85, 0.9, 1.0)))
	v.add_child(UIKit.label(help, 11, UIKit.MUTED))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	for o in options:
		var on: bool = is_equal_approx(float(o[1]), current)
		var b := Button.new()
		b.text = String(o[0])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 36)
		b.add_theme_font_size_override("font_size", 13)
		b.add_theme_color_override("font_color", UIKit.GOLD_INK if on else UIKit.TEXT)
		b.add_theme_color_override("font_pressed_color", UIKit.GOLD_INK if on else UIKit.TEXT)
		b.add_theme_color_override("font_hover_color", UIKit.GOLD_INK if on else UIKit.TEXT)
		var sb := UIKit.pill(UIKit.CYAN if on else Color(UIKit.CARD_HI, 0.8), 14, Vector2(8, 4))
		for st in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(st, sb)
		var val = o[1]
		b.pressed.connect(func(): on_pick.call(val))
		h.add_child(b)
	v.add_child(h)
	p.add_child(v)
	return p
