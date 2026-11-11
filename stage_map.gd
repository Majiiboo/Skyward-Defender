extends Control
# THE CAMPAIGN (2026-11-10; was the Stage Map): a winding trail of all sixty stages from the bottom
# up, one painted band per planet. Opened from Modes > Campaign / Elite Campaign and from the stage
# name on Home. Cleared stages show their stars (1 = cleared, 2 = base above half hull, 3 = no
# damage at all), the next stage pulses, locked ones are dim. Tap a stage for its sheet.
# Laid over the trail (rules in campaign.gd): the commander's STORY notes beside the 1st, 5th and
# 10th stage of each planet, and a STAR CHEST pill under each planet's name (10 / 20 / 30 stars).
# ELITE (root meta "campaign_elite", or the pills at the top): the same trail up to your Elite
# stage, purple, no stars or chests; Play starts the stage on Elite.

const STEP := 96.0            # vertical distance between stages
const BAND_PAD := 110.0       # extra room at the start of each planet for its title and chest pill
const BLEND_H := 150.0   # one planet's sky fades up into the next (no dividing line, Rudy 2026-11-06)
const CYAN := Color(0.31, 0.88, 1.0)
const GOLD := Color(1.0, 0.78, 0.27)
const ELITE := Color(0.73, 0.6, 1.0)
const MUTED := Color(0.62, 0.70, 0.84)

var unlocked := 1
var selected := 1
var stars := {}
var elite := false
var t := 0.0
var _top_h := 64.0
var _scroll: ScrollContainer
var _trail: Control
var _card: Control
var _press_pos := Vector2.ZERO
var _font: Font = preload("res://fonts/inter_text.tres")
var _title_font: Font = preload("res://fonts/oxanium_heavy.tres")
var _worlds := {}
var _over: Array = []      # the pills and note buttons laid over the trail
var _notes: Array = []     # [button, planet, note]

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var d := Progress.read()
	DevTools.on = bool(d.get("dev_mode", false))   # before the gates (dev mode opens every stage)
	var root := get_tree().root
	var elite_open: bool = DevTools.on or (Unlocks.open(d, "elite") and Turrets.pilot_level(int(d.get("pilot_xp", 0))) >= 10)
	elite = elite_open and bool(root.get_meta("campaign_elite", false))
	unlocked = StageData.elite_top(d) if elite else StageData.stage_top(d)   # dev mode: every stage
	selected = clampi(int(d.get("selected_stage", 1)), 1, unlocked)
	var s = d.get("stars", {})
	stars = s if typeof(s) == TYPE_DICTIONARY else {}
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.012, 0.03)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_top_h = 108.0 if elite_open else 64.0
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll.offset_top = _top_h
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(_scroll)
	_trail = Control.new()
	_trail.custom_minimum_size = Vector2(0, _total_h())
	_trail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_trail.draw.connect(_draw_trail)
	_trail.gui_input.connect(_on_trail_input)
	_scroll.add_child(_trail)
	_build_top(elite_open)
	_card = Control.new()
	_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card)
	# open on the selected stage, then fade in
	await get_tree().process_frame
	_build_overlays()
	_scroll.scroll_vertical = int(_node_pos(selected).y - _scroll.size.y * 0.55)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
	if not elite and Campaign.unread(Progress.read()).is_empty():   # not on top of a story message
		Hints.show(self, ["campaign"])
	# the newest story note nobody has read opens by itself, once
	if not elite:
		var nr := Campaign.unread(Progress.read())
		if not nr.is_empty():
			await get_tree().create_timer(0.45).timeout
			if is_inside_tree() and _card.get_child_count() == 0:
				_open_note(int(nr[0]), int(nr[1]))

func _process(delta: float) -> void:
	t += delta
	_trail.queue_redraw()
	for n in _notes:
		n[0].queue_redraw()

func _stars_of(s: int) -> int:
	return int(stars.get(str(s), 0))

# the painted skies: dimmed so the trail reads, with a purple cast on Elite
func _sky_dim() -> Color:
	return Color(0.62, 0.52, 0.86) if elite else Color(0.75, 0.75, 0.8)

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
			_trail.draw_texture_rect_region(tex, Rect2(0, zb - zh, w, zh), src, _sky_dim())
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
			var dim := _sky_dim()
			_trail.draw_polygon(PackedVector2Array([Vector2(0, ztop - BLEND_H), Vector2(w, ztop - BLEND_H), Vector2(w, ztop), Vector2(0, ztop)]),
				PackedColorArray([Color(dim, 0.0), Color(dim, 0.0), dim, dim]),
				PackedVector2Array([uv0, Vector2(uv1.x, uv0.y), uv1, Vector2(uv0.x, uv1.y)]), tex)
	# the planet titles over the blended skies
	for a in StageData.AREAS.size():
		var top := _band_bottom(a) - 10.0 * STEP - BAND_PAD
		var locked_area := StageData.area_index(unlocked) < a
		_trail.draw_string(_font, Vector2(0, top + 26), "Planet %d" % (a + 1), HORIZONTAL_ALIGNMENT_CENTER, w, 11, MUTED)
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
			_trail.draw_circle(q, 2.2 if lit else 1.6, Color(ELITE if elite else CYAN, 0.8) if lit else Color(1, 1, 1, 0.22))
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
	var ring := GOLD if kind == "boss" else (Color(0.85, 0.6, 1.0) if kind == "mini" else (ELITE if elite else CYAN))
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
	if cleared and not elite:
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

func _build_top(elite_open: bool) -> void:
	var bar := ColorRect.new()
	bar.color = Color(0.027, 0.047, 0.094, 0.96)
	bar.position = Vector2.ZERO
	bar.size = Vector2(4000, _top_h)
	add_child(bar)
	var back := UIKit.ghost_button("Back", 13)   # the same Back as every other page
	back.position = Vector2(12, 14)
	back.size = Vector2(76, 36)
	back.pressed.connect(_go_home)
	add_child(back)
	var title := UIKit.title("CAMPAIGN", 20, UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 19.0
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	var st := UIKit.label("★ %d / %d" % [Campaign.total_stars(Progress.read()), StageData.MAX_STAGE * 3], 13, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	st.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	st.offset_left = -120.0
	st.offset_right = -14.0
	st.offset_top = 23.0
	add_child(st)
	if elite_open:
		# Standard | Elite: the same trail, two ladders
		var tabs := UIKit.sub_tabs(["Standard", "Elite"], 1 if elite else 0, func(i: int):
			if (i == 1) != elite:
				get_tree().root.set_meta("campaign_elite", i == 1)
				get_tree().reload_current_scene())
		tabs.set_anchors_preset(Control.PRESET_TOP_WIDE)
		tabs.offset_left = 14.0
		tabs.offset_right = -14.0
		tabs.offset_top = 62.0
		tabs.offset_bottom = 98.0
		add_child(tabs)

# the chest pills and the story notes, laid over the trail (rebuilt after a claim or a read)
func _build_overlays() -> void:
	for c in _over:
		if is_instance_valid(c):
			c.queue_free()
	_over.clear()
	_notes.clear()
	if elite:
		return
	var d := Progress.read()
	var w := maxf(_trail.size.x, 360.0)
	for a in StageData.AREAS.size():
		if StageData.area_index(unlocked) < a:
			continue   # a planet not reached yet: nothing to show
		var top := _band_bottom(a) - 10.0 * STEP - BAND_PAD
		var have := Campaign.planet_stars(d, a)
		var ready := Campaign.chest_ready(d, a)
		var mark := Campaign.next_mark(d, a)
		var pill := Button.new()
		pill.text = ("CLAIM CHEST   ★ %d" % mark) if ready else (("★ %d / 30   ·   chest at %d" % [have, mark]) if mark > 0 else "★ 30 / 30   ·   all chests opened")
		pill.add_theme_font_size_override("font_size", 12)
		var sb := UIKit.pill(UIKit.GOLD if ready else Color(0.027, 0.047, 0.094, 0.82), 16, Vector2(12, 4))
		for stn in ["normal", "hover", "pressed", "disabled"]:
			pill.add_theme_stylebox_override(stn, sb)
		pill.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		for cn in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
			pill.add_theme_color_override(cn, UIKit.GOLD_INK if ready else GOLD)
		pill.size = Vector2(220, 30)
		pill.position = Vector2(w * 0.5 - 110.0, top + 62.0)
		pill.mouse_filter = Control.MOUSE_FILTER_STOP if ready else Control.MOUSE_FILTER_IGNORE
		if ready:
			var pa: int = a
			pill.pressed.connect(func(): _claim_chest(pa))
			UIKit.press_fx(pill)
		_trail.add_child(pill)
		_over.append(pill)
		# the story notes of this planet that have opened
		for i in Campaign.STORY[a].size():
			if not Campaign.note_open(d, a, i):
				continue
			var np := _node_pos(Campaign.note_stage(a, i))
			var nb := Button.new()
			nb.flat = true
			nb.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
			nb.size = Vector2(44, 44)
			nb.position = Vector2(np.x + (-82.0 if np.x > w * 0.5 else 82.0) - 22.0, np.y - 22.0 + (34.0 if int(Campaign.STORY[a][i].at) == 0 else 0.0))
			var fresh: bool = not Campaign.note_read(d, a, i)
			nb.draw.connect(func(): _draw_note_btn(nb, fresh))
			var na: int = a
			var ni: int = i
			nb.pressed.connect(func(): _open_note(na, ni))
			_trail.add_child(nb)
			_over.append(nb)
			_notes.append([nb, a, i])

# a comms note on the trail: a small speech bubble in a ring; gold and breathing until it is read
func _draw_note_btn(b: Control, fresh: bool) -> void:
	var c := b.size * 0.5
	var col := GOLD if fresh else Color(1, 1, 1, 0.55)
	if fresh:
		var pulse := 0.5 + 0.5 * sin(t * 4.0)
		b.draw_circle(c, 19.0 + 3.0 * pulse, Color(GOLD, 0.12 + 0.12 * pulse))
	b.draw_circle(c, 16.0, Color(0.03, 0.05, 0.12, 0.95))
	b.draw_arc(c, 16.0, 0.0, TAU, 32, col, 1.6, true)
	var r := Rect2(c + Vector2(-8, -7), Vector2(16, 11))
	b.draw_rect(r, col, false, 1.6)
	b.draw_colored_polygon(PackedVector2Array([c + Vector2(-4, 4), c + Vector2(-5, 9), c + Vector2(1, 4)]), col)
	b.draw_line(c + Vector2(-4, -3), c + Vector2(4, -3), col, 1.4)
	b.draw_line(c + Vector2(-4, 0), c + Vector2(2, 0), col, 1.4)

# the shared bottom sheet: returns its VBox (tap outside closes it)
func _sheet() -> VBoxContainer:
	for c in _card.get_children():
		c.queue_free()
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := Button.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.01, 0.024, 0.055, 0.6)
	for stn in ["normal", "hover", "pressed", "focus"]:
		dim.add_theme_stylebox_override(stn, ds)
	dim.pressed.connect(_close_card)
	_card.add_child(dim)
	var slider := Control.new()
	slider.set_anchors_preset(Control.PRESET_FULL_RECT)
	slider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(slider)
	var sheet := PanelContainer.new()
	var ss := UIKit.box(UIKit.CARD, Color(1, 1, 1, 0.06), 28)
	ss.corner_radius_bottom_left = 0
	ss.corner_radius_bottom_right = 0
	ss.content_margin_left = 18
	ss.content_margin_right = 18
	ss.content_margin_top = 16
	ss.content_margin_bottom = 24
	sheet.add_theme_stylebox_override("panel", ss)
	sheet.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	slider.add_child(sheet)
	dim.modulate.a = 0.0
	dim.create_tween().tween_property(dim, "modulate:a", 1.0, 0.18)
	slider.position.y = 500.0
	slider.create_tween().tween_property(slider, "position:y", 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	sheet.add_child(v)
	return v

func _open_card(s: int) -> void:
	var v := _sheet()
	var kind := StageData.boss_kind(s)
	v.add_child(UIKit.label("Planet %d  ·  %s%s" % [StageData.area_index(s) + 1, String(StageData.area(s).name), "  ·  Elite" if elite else ""], 12, ELITE if elite else UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UIKit.title("%d  %s" % [s, StageData.stage_name(s)], 22, UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation", 8)
	chips.add_child(UIKit.chip("%d waves" % StageData.wave_count(s), CYAN))
	if kind == "boss":
		chips.add_child(UIKit.chip("Boss", GOLD))
	elif kind == "mini":
		chips.add_child(UIKit.chip("Mini-boss", Color(0.85, 0.6, 1.0)))
	v.add_child(chips)
	if s > unlocked:
		v.add_child(UIKit.label("Locked: clear %sstage %d first." % ["Elite " if elite else "", s - 1], 13, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER))
		return
	if not elite:
		var n := _stars_of(s)
		v.add_child(UIKit.label("★".repeat(n) + "☆".repeat(3 - n), 24, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
		v.add_child(UIKit.label("★ clear    ★★ base above half    ★★★ no damage", 11, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	var cost := 0 if DevTools.on else Energy.cost(elite, s)
	var play := UIKit.gold_button("PLAY" if cost <= 0 else "PLAY   ·   %d power" % cost, 18)
	play.custom_minimum_size = Vector2(0, 52)
	play.pressed.connect(func():
		_select(s)
		if Energy.try_play(self, elite, s):   # a stage costs power tokens (stages 1-5 free)
			_leave("res://battle.tscn"))
	v.add_child(play)
	var sel := UIKit.ghost_button("Set as my stage on Home", 13)
	sel.custom_minimum_size = Vector2(0, 40)
	sel.pressed.connect(func():
		_select(s)
		_leave("res://hub.tscn"))
	v.add_child(sel)

# a story note: the commander, a title, a few lines. Reading it marks it read.
func _open_note(a: int, i: int) -> void:
	var note: Dictionary = Campaign.STORY[a][i]
	var d := Progress.read()
	if not Campaign.note_read(d, a, i):
		Campaign.mark_read(d, a, i)
		Progress.write(d)
	var v := _sheet()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var who := "res://ui/commander_%s.png" % ("urgent" if int(note.at) == 5 else "calm")
	if ResourceLoader.exists(who):
		var frame := PanelContainer.new()
		frame.add_theme_stylebox_override("panel", UIKit.box(UIKit.CARD_HI, Color(CYAN, 0.5), 16, 1))
		frame.custom_minimum_size = Vector2(84, 84)
		frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var tr := TextureRect.new()
		tr.texture = load(who)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		frame.add_child(tr)
		row.add_child(frame)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_theme_constant_override("separation", 4)
	tv.add_child(UIKit.label("Commander  ·  %s" % String(StageData.AREAS[a].name), 11, CYAN))
	tv.add_child(UIKit.title(String(note.title), 19, UIKit.TEXT))
	var body := UIKit.label(String(note.text), 13, Color(0.87, 0.9, 0.97))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(body)
	row.add_child(tv)
	v.add_child(row)
	var go := UIKit.gold_button("GOT IT", 17)
	go.custom_minimum_size = Vector2(0, 50)
	go.pressed.connect(func():
		_close_card()
		_build_overlays())
	v.add_child(go)

# a planet's next star chest: pay it out and say what was in it
func _claim_chest(a: int) -> void:
	var d := Progress.read()
	var r := Campaign.claim(d, a)
	if r.is_empty():
		return
	Progress.write(d)
	Sfx.play("claim")
	_build_overlays()
	var v := _sheet()
	v.add_child(UIKit.label("%s  ·  star chest" % String(StageData.AREAS[a].name), 12, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UIKit.title("Chest opened", 22, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var body := UIKit.label(Progress.reward_text(r), 15, UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(body)
	var nm := Campaign.next_mark(d, a)
	if nm > 0:
		v.add_child(UIKit.label("Next chest at %d stars on this planet." % nm, 12, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	var go := UIKit.gold_button("GOT IT", 17)
	go.custom_minimum_size = Vector2(0, 50)
	go.pressed.connect(_close_card)
	v.add_child(go)

func _close_card() -> void:
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in _card.get_children():
		c.queue_free()

func _select(s: int) -> void:
	selected = s
	var d := Progress.read()
	d["selected_stage"] = s
	d["selected_elite"] = elite
	Progress.write(d)

func _go_home() -> void:
	var back := String(get_tree().root.get_meta("campaign_back", "res://hub.tscn"))
	if get_tree().root.has_meta("campaign_back"):
		get_tree().root.remove_meta("campaign_back")
	_leave(back)

func _leave(path: String) -> void:
	if get_tree().root.has_meta("campaign_elite"):   # the next visit starts on Standard unless Modes says Elite
		get_tree().root.remove_meta("campaign_elite")
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func(): get_tree().change_scene_to_file(path))

# capture hooks (tools/dev/capture.gd passes strings)
func _dbg_card(s) -> void:
	_open_card(int(s))

func _dbg_note(a, i) -> void:
	_open_note(int(a), int(i))

func _dbg_chest(a) -> void:
	_claim_chest(int(a))
