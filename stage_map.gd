extends Control
# The stage map (ROADMAP 1.0): a winding trail of all stages from the bottom up, one
# painted band per planet, opened from the stage name on Home. Cleared stages show their
# stars (1 = cleared, 2 = base above half hull, 3 = perfect: no damage at all), the next
# stage pulses, locked ones are dim. Tap a stage for its card: Play starts it, Select
# makes it Home's stage. Stars are saved by battle.gd in the save's "stars".

const SAVE := "user://skybound_save.json"
const STEP := 96.0            # vertical distance between stages
const BAND_PAD := 70.0        # extra room at the start of each planet for its title
const BLEND_H := 150.0   # one planet's sky fades up into the next (no dividing line, Rudy 2026-11-06)
const CYAN := Color(0.18, 0.9, 1.0)
const GOLD := Color(1.0, 0.8, 0.3)
const MUTED := Color(0.62, 0.70, 0.84)

var unlocked := 1
var selected := 1
var stars := {}
var t := 0.0
var _scroll: ScrollContainer
var _trail: Control
var _card: Control
var _press_pos := Vector2.ZERO
var _font: Font = preload("res://fonts/exo2_semibold.tres")
var _title_font: Font = preload("res://fonts/Orbitron-Variable.ttf")
var _worlds := {}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var d := _read()
	DevTools.on = bool(d.get("dev_mode", false))   # before the gates (dev mode opens every stage)
	unlocked = StageData.stage_top(d)   # dev mode: every stage
	selected = clampi(int(d.get("selected_stage", 1)), 1, unlocked)
	var s = d.get("stars", {})
	stars = s if typeof(s) == TYPE_DICTIONARY else {}
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.012, 0.03)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll.offset_top = 64.0
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(_scroll)
	_trail = Control.new()
	_trail.custom_minimum_size = Vector2(0, _total_h())
	_trail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_trail.draw.connect(_draw_trail)
	_trail.gui_input.connect(_on_trail_input)
	_scroll.add_child(_trail)
	_build_top()
	_card = Control.new()
	_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card)
	# open on the selected stage, then fade in
	await get_tree().process_frame
	_scroll.scroll_vertical = int(_node_pos(selected).y - _scroll.size.y * 0.55)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)

func _process(delta: float) -> void:
	t += delta
	_trail.queue_redraw()

func _read() -> Dictionary:
	if FileAccess.file_exists(SAVE):
		var f := FileAccess.open(SAVE, FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if typeof(d) == TYPE_DICTIONARY:
				return d
	return {}

func _write(patch: Dictionary) -> void:
	var d := _read()
	for k in patch:
		d[k] = patch[k]
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))

func _stars_of(s: int) -> int:
	return int(stars.get(str(s), 0))

# ------------------------------------------------------------------ layout

func _total_h() -> float:
	return StageData.MAX_STAGE * STEP + StageData.AREAS.size() * BAND_PAD + 160.0

# y of the bottom of planet a's band (stage 1 sits at the bottom of the whole trail)
func _band_bottom(a: int) -> float:
	return _total_h() - 60.0 - a * (10.0 * STEP + BAND_PAD)

func _node_pos(s: int) -> Vector2:
	var a := StageData.area_index(s)
	var k := StageData.area_stage(s) - 1
	var w := maxf(size.x, 360.0)
	var y := _band_bottom(a) - 40.0 - k * STEP
	var x := w * 0.5 + sin(float(s) * 0.85) * w * 0.27
	return Vector2(x, y)

func _node_r(s: int) -> float:
	var kind := StageData.boss_kind(s)
	return 30.0 if kind == "boss" else (25.0 if kind == "mini" else 20.0)

# ------------------------------------------------------------------ drawing

func _draw_trail() -> void:
	var w := _trail.size.x
	# planet bands: the painted world of each zone, darkened, with the planet's title
	for a in StageData.AREAS.size():
		var bottom := _band_bottom(a)
		var top := bottom - 10.0 * STEP - BAND_PAD
		for z in 2:
			var key: String = String(StageData.SECTORS[a * 2 + z].bg)
			if not _worlds.has(key):
				_worlds[key] = load("res://backdrops/%s.webp" % key)
			var tex: Texture2D = _worlds[key]
			var zb := bottom - z * 5.0 * STEP
			var zh := 5.0 * STEP + (BAND_PAD if z == 1 else 0.0)
			var src_h: float = tex.get_width() * zh / w
			var src := Rect2(0, tex.get_height() - src_h - 40.0, tex.get_width(), src_h)
			_trail.draw_texture_rect_region(tex, Rect2(0, zb - zh, w, zh), src, Color(0.75, 0.75, 0.8))
	# no dividing lines (Rudy, 2026-11-06): every zone's sky carries on up into the zone above
	# it and fades out there, so one world blends into the next instead of being cut off
	for a in StageData.AREAS.size():
		for z in 2:
			var q := a * 2 + z
			if q + 1 >= StageData.SECTORS.size():
				continue
			var key: String = String(StageData.SECTORS[q].bg)
			var tex: Texture2D = _worlds[key]
			var zh := 5.0 * STEP + (BAND_PAD if z == 1 else 0.0)
			var ztop := _band_bottom(a) - z * 5.0 * STEP - zh
			var src_h: float = tex.get_width() * zh / w
			var fade_src_h: float = tex.get_width() * BLEND_H / w
			var src_y: float = maxf(tex.get_height() - src_h - 40.0 - fade_src_h, 0.0)
			var uv0 := Vector2(0, src_y / tex.get_height())
			var uv1 := Vector2(1, (src_y + fade_src_h) / tex.get_height())
			var dim := Color(0.75, 0.75, 0.8, 1.0)
			_trail.draw_polygon(PackedVector2Array([Vector2(0, ztop - BLEND_H), Vector2(w, ztop - BLEND_H), Vector2(w, ztop), Vector2(0, ztop)]),
				PackedColorArray([Color(dim, 0.0), Color(dim, 0.0), dim, dim]),
				PackedVector2Array([uv0, Vector2(uv1.x, uv0.y), uv1, Vector2(uv0.x, uv1.y)]), tex)
	# the planet titles over the blended skies
	for a in StageData.AREAS.size():
		var top := _band_bottom(a) - 10.0 * STEP - BAND_PAD
		var locked_area := StageData.area_index(unlocked) < a
		_trail.draw_string(_font, Vector2(0, top + 26), "PLANET %d" % (a + 1), HORIZONTAL_ALIGNMENT_CENTER, w, 11, MUTED)
		_trail.draw_string(_title_font, Vector2(0, top + 50), String(StageData.AREAS[a].name).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, w, 18,
			Color(1, 1, 1, 0.45) if locked_area else Color.WHITE)
	# the path between stages: dots, lit up to the furthest cleared stage
	for s in range(1, StageData.MAX_STAGE):
		var p0 := _node_pos(s)
		var p1 := _node_pos(s + 1)
		var n := int(p0.distance_to(p1) / 12.0)
		var lit := s < unlocked
		for k in range(1, n):
			var q := p0.lerp(p1, float(k) / n)
			_trail.draw_circle(q, 2.2 if lit else 1.6, Color(CYAN, 0.8) if lit else Color(1, 1, 1, 0.22))
	# stage nodes
	for s in range(1, StageData.MAX_STAGE + 1):
		_draw_node(s)

func _draw_node(s: int) -> void:
	var p := _node_pos(s)
	var r := _node_r(s)
	var kind := StageData.boss_kind(s)
	var open := s <= unlocked
	var cleared := s < unlocked
	var current := s == unlocked
	var ring := GOLD if kind == "boss" else (Color(0.85, 0.6, 1.0) if kind == "mini" else CYAN)
	if current:
		var pulse := 0.5 + 0.5 * sin(t * 4.0)
		_trail.draw_circle(p, r + 8.0 + 4.0 * pulse, Color(GOLD, 0.15 + 0.15 * pulse))
	if s == selected:
		_trail.draw_arc(p, r + 6.0, 0.0, TAU, 40, Color(1, 1, 1, 0.8), 1.5, true)
	_trail.draw_circle(p, r, Color(0.03, 0.05, 0.12, 0.95) if open else Color(0.02, 0.03, 0.06, 0.85))
	_trail.draw_arc(p, r, 0.0, TAU, 40, ring if open else Color(1, 1, 1, 0.25), 2.0 if open else 1.2, true)
	var label := str(s)
	var fs := 15 if kind == "" else 17
	_trail.draw_string(_title_font, p + Vector2(-r, fs * 0.36), label, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, fs,
		Color.WHITE if open else Color(1, 1, 1, 0.35))
	if kind != "":
		_trail.draw_string(_font, p + Vector2(-50, -r - 8), "BOSS" if kind == "boss" else "MINI-BOSS", HORIZONTAL_ALIGNMENT_CENTER, 100, 10, ring if open else Color(1, 1, 1, 0.3))
	if cleared:
		var n := _stars_of(s)
		for k in 3:
			_star(p + Vector2((k - 1) * 13.0, r + 9.0 - (2.0 if k == 1 else 0.0)), 5.5, k < n)

func _star(c: Vector2, rad: float, on: bool) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * (rad if i % 2 == 0 else rad * 0.45))
	_trail.draw_colored_polygon(pts, GOLD if on else Color(1, 1, 1, 0.15))

# ------------------------------------------------------------------ input and UI

func _on_trail_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			_press_pos = ev.position
		elif ev.position.distance_to(_press_pos) < 12.0:
			for s in range(1, StageData.MAX_STAGE + 1):
				if ev.position.distance_to(_node_pos(s)) < _node_r(s) + 10.0:
					_open_card(s)
					return

func _build_top() -> void:
	var bar := ColorRect.new()
	bar.color = Color(0.03, 0.045, 0.10, 0.92)
	bar.position = Vector2.ZERO
	bar.size = Vector2(4000, 64)
	add_child(bar)
	var line := ColorRect.new()
	line.color = Color(CYAN, 0.55)
	line.position = Vector2(0, 63)
	line.size = Vector2(4000, 1.2)
	add_child(line)
	var back := UIKit.ghost_button("Back", 13)   # the same Back as every other page
	back.position = Vector2(10, 14)
	back.size = Vector2(84, 36)
	back.pressed.connect(_go_home)
	add_child(back)
	var title := UIKit.label("STAGE MAP", 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_override("font", _title_font)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 18.0
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	var total := 0
	for k in stars:
		total += int(stars[k])
	var st := UIKit.label("★ %d / %d" % [total, StageData.MAX_STAGE * 3], 13, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	st.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	st.offset_left = -120.0
	st.offset_right = -14.0
	st.offset_top = 22.0
	add_child(st)

func _open_card(s: int) -> void:
	for c in _card.get_children():
		c.queue_free()
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0.01, 0.04, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed: _close_card())
	_card.add_child(dim)
	var box := UIKit.panel(16)
	box.custom_minimum_size = Vector2(minf(size.x - 32.0, 420.0), 0)
	box.position = Vector2((size.x - box.custom_minimum_size.x) * 0.5, size.y - 290.0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	var kind := StageData.boss_kind(s)
	v.add_child(UIKit.label("PLANET %d · %s" % [StageData.area_index(s) + 1, String(StageData.area(s).name).to_upper()], 11, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var name_l := UIKit.label("%d  %s" % [s, StageData.stage_name(s)], 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	name_l.add_theme_font_override("font", _title_font)
	v.add_child(name_l)
	var info := "%d waves" % StageData.wave_count(s)
	if kind == "boss":
		info += "  ·  BOSS: %s" % StageData.area(s).boss
	elif kind == "mini":
		info += "  ·  mini-boss"
	v.add_child(UIKit.label(info, 12, CYAN, HORIZONTAL_ALIGNMENT_CENTER))
	if s > unlocked:
		v.add_child(UIKit.label("Locked: clear stage %d first." % (s - 1), 13, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	else:
		var n := _stars_of(s)
		var stars_l := UIKit.label("★".repeat(n) + "☆".repeat(3 - n), 22, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		v.add_child(stars_l)
		v.add_child(UIKit.label("★ clear   ★★ base above half   ★★★ no damage", 10, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var sel := UIKit.teal_button("Select")
		sel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sel.custom_minimum_size = Vector2(0, 42)
		sel.pressed.connect(func():
			_select(s)
			_go_home())
		row.add_child(sel)
		var play := UIKit.gold_button("Play")
		play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		play.custom_minimum_size = Vector2(0, 42)
		play.pressed.connect(func():
			_select(s)
			if Energy.try_play(self, false, s):   # a stage costs power tokens (stages 1-5 free)
				_leave("res://battle.tscn"))
		row.add_child(play)
		v.add_child(row)
	box.add_child(v)
	_card.add_child(box)
	box.modulate.a = 0.0
	box.position.y += 30.0
	var tw := box.create_tween().set_parallel(true)
	tw.tween_property(box, "modulate:a", 1.0, 0.18)
	tw.tween_property(box, "position:y", box.position.y - 30.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _close_card() -> void:
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in _card.get_children():
		c.queue_free()

func _select(s: int) -> void:
	selected = s
	_write({"selected_stage": s, "selected_elite": false})

func _go_home() -> void:
	_leave("res://hub.tscn")

func _leave(path: String) -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func(): get_tree().change_scene_to_file(path))
