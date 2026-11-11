extends Control
# The EXPEDITION page (Runs, 2026-11-10). Three states:
#   no run     - pick a planet you have reached and START (one stage's worth of power tokens)
#   a run      - what you carry (hero health, shield, hull, cards), then the stops from the boss at
#                the top down to where you are; tap one of the choices at your stop
#   run over   - how far you got, the reward, COLLECT
# A fight opens the battle (selected_mode "run"); a rest or a supply cache is settled here.

var d := {}
var _col: VBoxContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	MenuBackdrop.add_to(self)
	d = Progress.read()
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
	if not Runs.active(d).is_empty():
		Hints.show(self, ["works"])

func _fill() -> void:
	for c in _col.get_children():
		_col.remove_child(c)
		c.queue_free()
	d = Progress.read()
	var run := Runs.active(d)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	var back := UIKit.ghost_button("Back")
	back.custom_minimum_size = Vector2(70, 32)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://hub.tscn"))
	top.add_child(back)
	top.add_child(UIKit.screen_title("EXPEDITION"))
	_col.add_child(top)
	if run.is_empty():
		_fill_start()
	elif Runs.over(run):
		_fill_over(run)
	else:
		_fill_run(run)
	UIKit.reveal(_col)

# ------------------------------------------------------------------ no run: pick a planet
func _fill_start() -> void:
	var t := UIKit.label("A run of %d stops across one planet. Your cards, your hero's health and the base carry from stop to stop. Lose a fight and the run ends." % Runs.STEPS, 13, UIKit.SOFT)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_col.add_child(t)
	var open_n := Runs.planets_open(d)
	for p in StageData.AREAS.size():
		var area: Dictionary = StageData.AREAS[p]
		var open: bool = p < open_n
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 92)
		var nb := UIKit.glass(24.0)
		for st in ["normal", "hover", "disabled"]:
			b.add_theme_stylebox_override(st, nb)
		var pb := UIKit.glass(24.0)
		pb.bg_color = UIKit.CARD_HI
		b.add_theme_stylebox_override("pressed", pb)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var h := HBoxContainer.new()
		h.set_anchors_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 14.0
		h.offset_right = -14.0
		h.add_theme_constant_override("separation", 14)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pk := Backdrop.planet_of(String(StageData.sector(p * 10 + 1).get("bg", "hive_a")))
		var tr := TextureRect.new()
		tr.texture = load("res://skies/%s_planet.webp" % pk) if ResourceLoader.exists("res://skies/%s_planet.webp" % pk) else UIKit.ic("ic_base")
		tr.custom_minimum_size = Vector2(70, 70)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(tr)
		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.alignment = BoxContainer.ALIGNMENT_CENTER
		tv.add_theme_constant_override("separation", 2)
		tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tv.add_child(UIKit.title(String(area.name), 20, UIKit.TEXT))
		var w := Runs.wins(d, p)
		tv.add_child(UIKit.label(("Won %d time%s" % [w, "" if w == 1 else "s"]) if w > 0 else ("Boss: %s" % String(StageData.ENEMIES[StageData.boss_id(p * 10 + 10, false)].get("name", "?"))) if open else ("Win the %s expedition first" % String(StageData.AREAS[maxi(p - 1, 0)].name)) if p > 0 and p < StageData.area_index(clampi(int(d.get("stage_unlocked", 1)), 1, StageData.MAX_STAGE)) + 1 else "Reach this planet in the campaign", 12, UIKit.SOFT))
		h.add_child(tv)
		if open:
			var go := PanelContainer.new()
			go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			go.mouse_filter = Control.MOUSE_FILTER_IGNORE
			go.add_theme_stylebox_override("panel", UIKit.pill(UIKit.GOLD, 16, Vector2(16, 8)))
			go.add_child(UIKit.title("START", 15, UIKit.GOLD_INK))
			h.add_child(go)
		b.add_child(h)
		if open:
			var planet: int = p
			b.pressed.connect(func(): _start(planet))
			UIKit.press_fx(b)
		else:
			b.disabled = true
			b.modulate = Color(1, 1, 1, 0.5)
		_col.add_child(b)

func _start(planet: int) -> void:
	if not Energy.try_play(self, false, 99):   # a run costs one stage's power tokens, once
		return
	d = Progress.read()
	d["run"] = Runs.new_run(planet, randi() % 1000000 + 1)
	Progress.write(d)
	Sfx.play("buy")
	_fill()

# ------------------------------------------------------------------ a run under way
func _chip(icon: Texture2D, text: String, col: Color = UIKit.TEXT) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.pill(Color(UIKit.CARD, 0.9), 15, Vector2(10, 4)))
	p.add_child(UIKit.iconed(icon, text, 13, col, 20.0))
	return p

func _fill_run(run: Dictionary) -> void:
	var step := int(run.step)
	var head := HBoxContainer.new()
	head.add_child(UIKit.title(String(StageData.AREAS[int(run.planet)].name), 22, UIKit.TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	head.add_child(UIKit.title("Stop %d / %d" % [step + 1, Runs.STEPS], 15, UIKit.SOFT))
	_col.add_child(head)
	# what you carry
	var carry := HBoxContainer.new()
	carry.add_theme_constant_override("separation", 8)
	var hp := float(run.get("hp", 1.0))
	carry.add_child(_chip(UIKit.ic("st_hp"), "%d%%" % roundi(hp * 100.0), UIKit.TEXT if hp > 0.35 else Color(1.0, 0.55, 0.55)))
	carry.add_child(_chip(UIKit.ic("st_def"), "%d%%" % roundi(float(run.get("shield", 1.0)) * 100.0)))
	carry.add_child(_chip(UIKit.ic("ic_base", "st_def"), "%d%%" % roundi(float(run.get("hull", 1.0)) * 100.0)))
	var ncards := 0
	for id in Dictionary(run.get("cards", {})):
		ncards += int(run.cards[id])
	carry.add_child(_chip(UIKit.ic("ic_pack"), str(ncards)))
	_col.add_child(carry)
	# what was built onto the base during this run (Field works)
	var bo := Runs.boosts(run)
	if not bo.is_empty():
		var brow := HFlowContainer.new()
		brow.add_theme_constant_override("h_separation", 6)
		brow.add_theme_constant_override("v_separation", 6)
		for id in bo:
			if Runs.UPGRADES.has(id):
				var n := Runs.boost(run, String(id))
				brow.add_child(_chip(UIKit.ic(String(Runs.UPGRADES[id].icon)), String(Runs.UPGRADES[id].name) + ("  x%d" % n if n > 1 else ""), Color(0.62, 0.84, 1.0)))
		_col.add_child(brow)
	# the stops, the boss at the top, where you are marked
	for s in range(Runs.STEPS - 1, -1, -1):
		var kinds: Array = Runs.nodes(run, s)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var num := UIKit.title(str(s + 1), 14, UIKit.CYAN if s == step else UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		num.custom_minimum_size = Vector2(22, 0)
		num.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(num)
		for k in kinds:
			row.add_child(_node_square(run, s, String(k)))
		if s < step:
			row.modulate = Color(1, 1, 1, 0.35)
		_col.add_child(row)
	var quit := UIKit.ghost_button("Abandon the run", 12)
	quit.pressed.connect(func():
		d = Progress.read()
		var r := Runs.active(d)
		if not r.is_empty():
			r["alive"] = false
			d["run"] = r
			Progress.write(d)
		_fill())
	_col.add_child(quit)

func _node_square(run: Dictionary, s: int, kind: String) -> Button:
	var def: Dictionary = Runs.KINDS[kind]
	var here: bool = s == int(run.step)
	var col: Color = def.col
	var b := Button.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 74 if here else 54)
	var nb := UIKit.box(Color(UIKit.CARD, 0.94), Color(col, 0.9) if here else Color(1, 1, 1, 0.05), 18, 2 if here else 1)
	nb.set_content_margin_all(0)
	for st in ["normal", "hover", "disabled"]:
		b.add_theme_stylebox_override(st, nb)
	var pb := UIKit.box(UIKit.CARD_HI, col, 18, 2)
	b.add_theme_stylebox_override("pressed", pb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 10.0
	h.offset_right = -8.0
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tr := TextureRect.new()
	tr.texture = UIKit.ic(String(def.icon))
	tr.custom_minimum_size = Vector2(30, 30) if here else Vector2(22, 22)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(tr)
	var tv := VBoxContainer.new()
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.add_theme_constant_override("separation", 0)
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_child(UIKit.title(String(def.name), 14 if here else 12, UIKit.TEXT if here else UIKit.SOFT))
	if here:
		var tl := UIKit.label(String(def.text), 10, UIKit.SOFT)
		tl.clip_text = true
		tv.add_child(tl)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(tv)
	b.add_child(h)
	if here:
		b.pressed.connect(func(): _take(kind))
		UIKit.press_fx(b)
	else:
		b.disabled = true
	return b

func _take(kind: String) -> void:
	d = Progress.read()
	var run := Runs.active(d)
	if run.is_empty() or Runs.over(run):
		_fill()
		return
	if Runs.is_fight(kind):
		run["node"] = kind
		d["run"] = run
		d["selected_mode"] = "run"
		Progress.write(d)
		Sfx.play("tap")
		get_tree().change_scene_to_file("res://battle.tscn")
		return
	if kind == "rest":
		Runs.take_rest(run)
		d["run"] = run
		Progress.write(d)
		Sfx.play("claim")
		_fill()
		return
	if kind == "works":
		_works_popup(run)
		return
	_cache_popup(run)

# a supply cache: two offers, take one
func _cache_popup(run: Dictionary) -> void:
	var layer := ColorRect.new()
	layer.color = Color(0.01, 0.024, 0.055, 0.75)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var title := UIKit.title("SUPPLY CACHE", 24, Color(1.0, 0.85, 0.45), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(0, size.y * 0.5 - 190.0)
	title.size = Vector2(size.x, 30)
	layer.add_child(title)
	var offers := Runs.cache_offers(run)
	var w := (size.x - 24.0 - 14.0) * 0.5
	for i in offers.size():
		var def: Dictionary = Runs.CACHE[offers[i]]
		var b := Button.new()
		b.position = Vector2(12.0 + i * (w + 14.0), size.y * 0.5 - 130.0)
		b.size = Vector2(w, 200.0)
		for st in ["normal", "hover"]:
			b.add_theme_stylebox_override(st, UIKit.box(Color(UIKit.CARD, 0.97), Color(UIKit.GOLD, 0.6), 22, 1))
		b.add_theme_stylebox_override("pressed", UIKit.box(UIKit.CARD_HI, UIKit.GOLD, 22, 2))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var v := VBoxContainer.new()
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 12.0
		v.offset_right = -12.0
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_theme_constant_override("separation", 8)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tr := TextureRect.new()
		tr.texture = UIKit.ic(String(def.icon))
		tr.custom_minimum_size = Vector2(0, 64)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(tr)
		v.add_child(UIKit.title(String(def.name), 18, UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
		var tl := UIKit.label(String(def.text), 13, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(tl)
		b.add_child(v)
		var id := String(offers[i])
		b.pressed.connect(func():
			d = Progress.read()
			var r := Runs.active(d)
			if not r.is_empty():
				Runs.take_cache(d, r, id)
				d["run"] = r
				Progress.write(d)
				Sfx.play("claim")
			layer.queue_free()
			_fill())
		layer.add_child(b)

# ------------------------------------------------------------------ the run is over
func _fill_over(run: Dictionary) -> void:
	var won: bool = bool(run.get("won", false))
	var p := UIKit.panel(24)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	v.add_child(UIKit.title("EXPEDITION WON" if won else "EXPEDITION OVER", 26, UIKit.GOLD if won else Color(1.0, 0.5, 0.55), HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UIKit.label("%s  ·  %d of %d stops cleared" % [String(StageData.AREAS[int(run.planet)].name), int(run.get("cleared", 0)), Runs.STEPS], 14, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	var reward := Runs.reward(run)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	for k in reward:
		var kk := String(k)
		var icon: Texture2D = UIKit.ic("ic_coin", "ui_coin") if kk == "coins" else (UIKit.ic("ic_crystal", "ui_crystal") if kk == "crystals" else (Materials.icon(kk) if Materials.is_material(kk) else Parts.icon(kk)))
		row.add_child(_chip(icon, UIKit.num(int(reward[k])), UIKit.GOLD))
	v.add_child(row)
	var cb := UIKit.gold_button("COLLECT", 20)
	cb.custom_minimum_size = Vector2(0, 56)
	cb.pressed.connect(func():
		d = Progress.read()
		var got := Runs.collect(d)
		Progress.write(d)
		if not got.is_empty():
			Sfx.play("claim")
		_fill())
	v.add_child(cb)
	_col.add_child(p)

# capture hooks (tools/dev/capture.gd CAP_CALL)
func _dbg_cache() -> void:
	var run := Runs.active(Progress.read())
	if not run.is_empty():
		_cache_popup(run)

# a Field works stop: three upgrades for the base, take one (it stays for the rest of the run)
func _works_popup(run: Dictionary) -> void:
	var layer := ColorRect.new()
	layer.color = Color(0.01, 0.024, 0.055, 0.8)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var offers := Runs.works_offers(run)
	var top := size.y * 0.5 - 60.0 * offers.size() - 40.0
	var title := UIKit.title("FIELD WORKS", 24, Color(0.62, 0.84, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(0, top - 46.0)
	title.size = Vector2(size.x, 30)
	layer.add_child(title)
	var sub := UIKit.label("Build one onto the base. It stays for the rest of this run.", 12, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	sub.position = Vector2(0, top - 14.0)
	sub.size = Vector2(size.x, 18)
	layer.add_child(sub)
	for i in offers.size():
		var id := String(offers[i])
		var def: Dictionary = Runs.UPGRADES[id]
		var have := Runs.boost(run, id)
		var b := Button.new()
		b.position = Vector2(14.0, top + 16.0 + i * 108.0)
		b.size = Vector2(size.x - 28.0, 96.0)
		for st in ["normal", "hover"]:
			b.add_theme_stylebox_override(st, UIKit.box(Color(UIKit.CARD, 0.97), Color(0.55, 0.8, 1.0, 0.55), 22, 1))
		b.add_theme_stylebox_override("pressed", UIKit.box(UIKit.CARD_HI, Color(0.55, 0.8, 1.0), 22, 2))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var h := HBoxContainer.new()
		h.set_anchors_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 16.0
		h.offset_right = -16.0
		h.add_theme_constant_override("separation", 14)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tr := TextureRect.new()
		tr.texture = UIKit.ic(String(def.icon))
		tr.custom_minimum_size = Vector2(52, 52)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(tr)
		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.alignment = BoxContainer.ALIGNMENT_CENTER
		tv.add_theme_constant_override("separation", 2)
		tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tv.add_child(UIKit.title(String(def.name), 18, UIKit.TEXT))
		tv.add_child(UIKit.label(String(def.text), 13, UIKit.SOFT))
		h.add_child(tv)
		var lv := UIKit.title("%d / %d" % [have + 1, Runs.UPGRADE_MAX], 14, UIKit.GOLD)
		lv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(lv)
		b.add_child(h)
		b.pressed.connect(func():
			d = Progress.read()
			var r := Runs.active(d)
			if not r.is_empty():
				Runs.take_works(r, id)
				d["run"] = r
				Progress.write(d)
				Sfx.play("upgrade")
			layer.queue_free()
			_fill())
		UIKit.press_fx(b)
		layer.add_child(b)

func _dbg_works() -> void:
	var run := Runs.active(Progress.read())
	if not run.is_empty():
		_works_popup(run)
