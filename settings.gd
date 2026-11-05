extends Control
# Settings (dev159, queue 27). Opened from Home's menu button. Performance mode (Perf),
# a frame counter switch, sound switches (greyed until sound exists), the build and
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
	# ---- performance: three cards, the chosen one lit
	_page.add_child(UIKit.header("PERFORMANCE"))
	var cur := Perf.read(d)
	for m in Perf.MODES:
		var info: Dictionary = Perf.INFO[m]
		var on: bool = m == cur
		var p := UIKit.panel(12)
		if on:
			p.add_theme_stylebox_override("panel", UIKit.lift(UIKit.box(Color(UIKit.CYAN, 0.16), UIKit.CYAN, 12)))
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
	_page.add_child(_switch("Show frame counter", "A small fps number in battle, for testing", bool(d.get("show_fps", false)), func(v: bool):
		d = Progress.read()
		d["show_fps"] = v
		Perf.show_fps = v
		Progress.write(d)
		_fill()))
	# ---- sound: not built yet, say so plainly
	_page.add_child(UIKit.header("SOUND"))
	_page.add_child(_switch("Sound effects", "Coming with the sound pack", true, Callable(), true))
	_page.add_child(_switch("Music", "Coming with the sound pack", true, Callable(), true))
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
	# ---- about
	_page.add_child(UIKit.header("ABOUT"))
	var ab := UIKit.panel(12)
	var av := VBoxContainer.new()
	av.add_theme_constant_override("separation", 1)
	av.add_child(UIKit.label("Skybound Defender  ·  build %s" % BuildInfo.BUILD, 13, Color.WHITE))
	av.add_child(UIKit.label("Art: Luna  ·  Design: Rudy  ·  Draws at your phone's own resolution", 11, UIKit.MUTED))
	ab.add_child(av)
	_page.add_child(ab)
	UIKit.reveal(_page)

# a row with a name, one line of help and an On / Off switch (greyed when not built)
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
	var b := UIKit.ghost_button("On" if on else "Off", 13)
	b.custom_minimum_size = Vector2(70, 34)
	if soon:
		b.disabled = true
	else:
		if on:
			b.add_theme_stylebox_override("normal", UIKit.box(Color(UIKit.CYAN, 0.25), UIKit.CYAN, 10))
		b.pressed.connect(func(): on_change.call(not on))
	h.add_child(b)
	p.add_child(h)
	if soon:
		p.modulate.a = 0.6
	return p

func _process(_delta: float) -> void:
	if _fps:
		_fps.text = "%d fps  ·  %s" % [Engine.get_frames_per_second(), Perf.INFO[Perf.mode].name]
