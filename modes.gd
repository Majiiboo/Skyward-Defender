extends Control
# Modes screen (redesigned dev111): one big glass card per mode with a painted world
# banner (Luna's backdrops) and the title over it, what the mode is, what it pays, and
# its button. Locked modes say what unlocks them; modes not built yet say so.
# Add a mode = add an entry to MODES.

const MODES := [
	{"id": "standard", "name": "Normal", "banner": "", "tint": Color(0.2, 0.85, 1.0), "unlock": 0,
		"desc": "6 planets · bosses · up to 3 stars a stage"},
	{"id": "elite", "name": "Elite", "banner": "sentinel", "tint": Color(0.71, 0.45, 1.0), "unlock": 10,
		"desc": "Its own ladder from stage 1, never past your Standard stage · bugs x1.85 tougher"},
	# rank trials (Promotion, dev143): one hard stage per rank, win once = stronger for good
	{"id": "promotion", "name": "Promotion", "banner": "crystal", "tint": Color(1.0, 0.8, 0.3), "unlock": 0,
		"desc": "Ten rank trials · win once, stronger for good"},
	{"id": "horde", "name": "Horde", "banner": "magma", "tint": Color(1.0, 0.55, 0.25), "unlock": 5,
		"desc": "Endless waves from your best stage · a boss every 10th · beat your best"},
	{"id": "boss", "name": "Boss Rush", "banner": "plasma", "tint": Color(1.0, 0.35, 0.5), "unlock": 20, "soon": true,
		"desc": "Every boss you beat, back to back"},
]
var player_level := 1
var selected_stage := 1
var stage_unlocked := 1
var _save := {}   # the save as read on open (Promotion rank)
var _promo_btn: Control   # the Promotion card's button (tips)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	MenuBackdrop.add_to(self)   # the living planet wallpaper behind the page
	_load()
	_build()
	_fade_in_overlay()

func _load() -> void:
	if FileAccess.file_exists("user://skybound_save.json"):
		var f := FileAccess.open("user://skybound_save.json", FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if typeof(d) == TYPE_DICTIONARY:
				_save = d
				DevTools.on = bool(d.get("dev_mode", false))
				player_level = Turrets.pilot_level(int(d.get("pilot_xp", 0)))
				stage_unlocked = StageData.stage_top(d)   # dev mode: every stage
				selected_stage = clampi(int(d.get("selected_stage", 1)), 1, stage_unlocked)

func _save_patch(patch: Dictionary) -> void:
	var d := {}
	if FileAccess.file_exists("user://skybound_save.json"):
		var f := FileAccess.open("user://skybound_save.json", FileAccess.READ)
		if f:
			var p = JSON.parse_string(f.get_as_text())
			if typeof(p) == TYPE_DICTIONARY:
				d = p
	d.merge(patch, true)
	var out := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(d))

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
	col.add_theme_constant_override("separation", 10)   # five cards on one screen
	root.add_child(col)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	var back := UIKit.ghost_button("Back")
	back.name = "BackButton"
	back.custom_minimum_size = Vector2(70, 32)
	back.pressed.connect(_on_back_pressed)
	top.add_child(back)
	top.add_child(UIKit.screen_title("MODES"))
	col.add_child(top)
	if UIKit.CLEAN:
		col.add_theme_constant_override("separation", 12)
		_build_clean(col)
		UIKit.reveal(col, 0.06)
		call_deferred("_tips")
		return
	# Modes the player has not reached are not shown, except the NEXT one as a teaser
	# (Unlocks, dev168: a new player sees Normal and one card to look forward to)
	var teased := false
	for m in MODES:
		var gate: String = {"elite": "elite", "promotion": "promotion"}.get(m.id, "")
		var reached: bool = gate == "" or Unlocks.open(_save, gate)
		if m.get("soon", false) or m.id == "horde":
			reached = player_level >= int(m.unlock)
		if reached:
			col.add_child(_card(m))
		elif not teased:
			teased = true
			col.add_child(_card(m))
	UIKit.reveal(col, 0.06)
	call_deferred("_tips")

# ---- the CLEAN Modes page (Rudy, 2026-11-09, mock-up "Round 2 · Clean"): one wide card per mode,
# a picture, the name, two small lines (where you are, a hint of what it gives) and one round
# button; Campaign's is the gold one. Not reached yet = hidden, except the next one as a teaser.
const CLEAN_ORDER := ["standard", "daily", "event", "elite", "promotion", "trials", "horde"]

func _build_clean(col: VBoxContainer) -> void:
	var teased := false
	for id in CLEAN_ORDER:
		var reached := true
		match id:
			"elite": reached = Unlocks.open(_save, "elite") and player_level >= 10
			"promotion", "trials": reached = Unlocks.open(_save, "promotion")
			"horde": reached = player_level >= 5
			"daily": reached = Promotion.daily_open(_save)
			"event": reached = Events.open(_save)
		if DevTools.on:
			reached = true
		if reached:
			col.add_child(_clean_card(id, false))
		elif not teased:
			teased = true
			col.add_child(_clean_card(id, true))

func _clean_card(id: String, locked: bool) -> Button:
	var title_txt := ""
	var line1 := ""
	var line2 := ""
	var line2_col := UIKit.SOFT
	var pic: Texture2D = null
	var pic_bg := Color(0.09, 0.14, 0.24)
	var action := Callable()
	match id:
		"standard":
			title_txt = "Campaign"
			line1 = "Stage %d" % selected_stage
			line2 = StageData.stage_name(selected_stage)
			var pk := Backdrop.planet_of(String(StageData.sector(selected_stage).get("bg", "hive_a")))
			pic = load("res://skies/%s_planet.webp" % pk) if ResourceLoader.exists("res://skies/%s_planet.webp" % pk) else UIKit.ic("ic_base")
			action = func(): _play(false)
		"elite":
			var es := StageData.elite_top(_save)
			title_txt = "Elite Campaign"
			line1 = "Stage %d" % es
			line2 = StageData.stage_name(es)
			line2_col = Color(0.73, 0.64, 1.0)
			pic = UIKit.ic("ic_elite")
			pic_bg = Color(0.11, 0.086, 0.25)
			action = func(): _play(true)
		"promotion":
			title_txt = "Promotion"
			line1 = "Rank %d of %d" % [Promotion.rank(_save), Promotion.RANKS.size()]
			line2 = "Permanent upgrades"
			pic = UIKit.ic("ic_rank")
			pic_bg = Color(0.16, 0.13, 0.06)
			action = _ladder
		"trials":
			var started := 0
			for el in Heroes.ELEMENTS:
				if Promotion.etrial_steps(_save, String(el)) > 0:
					started += 1
			title_txt = "Trials"
			line1 = "%d of %d elements" % [started, Heroes.ELEMENTS.size()]
			line2 = "Shards for your heroes"
			pic = UIKit.ic("ic_trial")
			pic_bg = Color(0.09, 0.094, 0.23)
			action = _etrials
		"daily":
			# the Daily Challenge (Promotion.daily_*): three twists, one reward a day
			var done := Promotion.daily_done(_save)
			title_txt = "Daily Challenge"
			line1 = "Stage %d  ·  3 twists" % Promotion.daily_stage(_save)
			line2 = "Done today: back tomorrow" if done else ("Reward: " + Progress.reward_text(Promotion.daily_reward(_save)))
			line2_col = UIKit.SOFT if done else UIKit.GOLD
			pic = UIKit.ic("ic_gift")
			pic_bg = Color(0.16, 0.13, 0.06)
			action = func(): _play_daily()
		"event":
			# the weekly event (Events): a themed week with a track of ten rewards
			var eth := Events.theme()
			var est := Events.state(_save)
			title_txt = String(eth.name)
			line1 = "Weekly event  ·  ends in %s" % Events.left_text()
			line2 = "Reward ready" if Events.claimable(_save) else "%d / %d points" % [int(est.points), int(Events.TRACK[-1].points)]
			line2_col = UIKit.GOLD if Events.claimable(_save) else UIKit.SOFT
			pic = UIKit.ic(String(eth.icon))
			pic_bg = Color(Color(eth.col).r * 0.2, Color(eth.col).g * 0.2, Color(eth.col).b * 0.25)
			action = _event_sheet
		"horde":
			var bw := int(_save.get("best_horde", 0))
			var hs := int(_save.get("best_horde_score", 0))
			title_txt = "Horde"
			line1 = "Best wave %d" % bw if bw > 0 else "Endless waves"
			line2 = "High score %s" % _thousands(hs) if hs > 0 else "Beat your best"
			pic = load("res://enemies/spitter.png")
			pic_bg = Color(0.16, 0.08, 0.08)
			action = func(): _play_horde()
	if locked:
		line1 = "Locked"
		line2 = {"elite": "Opens at pilot Lv.10", "horde": "Opens at pilot Lv.5", "daily": "Opens after stage %d" % Promotion.DAILY_FROM, "event": "Opens after stage %d" % Events.EVENT_FROM}.get(id, "Opens as you play")
		line2_col = UIKit.SOFT
	var b := Button.new()
	b.name = "Mode_" + id
	b.custom_minimum_size = Vector2(0, 106)
	var nb := UIKit.glass(24.0)
	for st in ["normal", "hover", "disabled"]:
		b.add_theme_stylebox_override(st, nb)
	var pb := UIKit.glass(24.0)
	pb.bg_color = UIKit.CARD_HI
	b.add_theme_stylebox_override("pressed", pb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 12.0
	h.offset_right = -12.0
	h.offset_top = 12.0
	h.offset_bottom = -12.0
	h.add_theme_constant_override("separation", 14)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(82, 82)
	frame.add_theme_stylebox_override("panel", UIKit.box(pic_bg, Color(0, 0, 0, 0), 18, 0))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tr := TextureRect.new()
	tr.texture = pic
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(62, 62)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(tr)
	h.add_child(frame)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.add_theme_constant_override("separation", 2)
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_child(UIKit.title(title_txt, 20, UIKit.TEXT))
	tv.add_child(UIKit.label(line1, 14, Color(0.87, 0.9, 0.97)))
	var l2 := UIKit.label(line2, 12, line2_col)
	l2.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tv.add_child(l2)
	h.add_child(tv)
	var gold: bool = id == "standard" and not locked
	var disc := Control.new()
	disc.custom_minimum_size = Vector2(52, 52)
	disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.draw.connect(func():
		var c := disc.size * 0.5
		disc.draw_circle(c, 26.0, UIKit.GOLD if gold else UIKit.CARD_HI)
		if gold:   # play
			disc.draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -10), c + Vector2(-6, 10), c + Vector2(11, 0)]), UIKit.GOLD_INK)
		else:      # an arrow
			disc.draw_polyline(PackedVector2Array([c + Vector2(-3, -8), c + Vector2(5, 0), c + Vector2(-3, 8)]), UIKit.TEXT, 3.0, true))
	h.add_child(disc)
	if locked:
		b.disabled = true
		b.modulate = Color(1, 1, 1, 0.55)
	elif action.is_valid():
		b.pressed.connect(action)
	UIKit.press_fx(b)
	if id == "promotion":
		_promo_btn = b
	return b

func _thousands(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

# Campaign / Elite Campaign: the selected stage (clamped to that ladder), as the old Play buttons did
func _play(elite: bool) -> void:
	var sv := Progress.read()
	var top: int = StageData.elite_top(sv) if elite else stage_unlocked
	_save_patch({"selected_elite": elite, "selected_stage": clampi(int(sv.get("selected_stage", 1)), 1, top)})
	if Energy.try_play(self, elite, int(Progress.read().get("selected_stage", 1))):   # a stage costs power tokens (stages 1-5 free)
		get_tree().change_scene_to_file("res://battle.tscn")

func _play_daily() -> void:
	if Energy.try_play(self, false, 99):
		_save_patch({"selected_mode": "daily"})   # your best stage with today's three twists (battle daily); set only once the fight is paid for
		get_tree().change_scene_to_file("res://battle.tscn")

func _play_horde() -> void:
	_save_patch({"selected_mode": "horde"})   # endless waves from your best Standard stage (battle horde)
	if Energy.try_play(self, false, 99):
		get_tree().change_scene_to_file("res://battle.tscn")

func _card(m: Dictionary) -> Control:
	var locked: bool = player_level < int(m.unlock) and not DevTools.on
	var soon: bool = m.get("soon", false)
	var tint: Color = m.tint
	var p := UIKit.panel(16)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	# banner: a painted world, the title over its lower edge, a status chip at the right
	var banner := Control.new()
	banner.custom_minimum_size = Vector2(0, 70)
	banner.clip_contents = true
	var key: String = m.banner if m.banner != "" else String(StageData.sector(selected_stage).get("bg", "hive_a"))
	var tex: Texture2D = load("res://backdrops/%s.webp" % key)
	# the lit landscape near the bottom of the tall world painting, not its dark sky
	var crop := AtlasTexture.new()
	crop.atlas = tex
	var ch: float = tex.get_width() / 3.6
	crop.region = Rect2(0, tex.get_height() - ch * 1.25, tex.get_width(), ch)
	var pic := TextureRect.new()
	pic.texture = crop
	pic.set_anchors_preset(Control.PRESET_FULL_RECT)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if locked or soon:
		pic.modulate = Color(0.62, 0.62, 0.72)
	elif m.id == "elite":
		pic.modulate = Color(0.75, 0.6, 1.0)
	banner.add_child(pic)
	var shade := Control.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.draw.connect(func():
		var s := shade.size
		var clear := Color(0.02, 0.03, 0.08, 0.0)
		var dark := Color(0.02, 0.03, 0.08, 0.85)
		shade.draw_polygon(PackedVector2Array([Vector2(0, s.y * 0.35), Vector2(s.x, s.y * 0.35), s, Vector2(0, s.y)]),
			PackedColorArray([clear, clear, dark, dark]))
		shade.draw_line(Vector2(0, s.y - 1), Vector2(s.x, s.y - 1), Color(tint, 0.8), 2.0))
	banner.add_child(shade)
	var title := UIKit.label(String(m.name).to_upper(), 22, Color.WHITE)
	title.add_theme_font_override("font", load("res://fonts/Orbitron-Variable.ttf"))
	title.position = Vector2(12, 36)
	banner.add_child(title)
	var chip_text := "COMING SOON" if soon else ("UNLOCKS AT PILOT LV.%d" % int(m.unlock) if locked else ("STAGE %d" % selected_stage if m.id != "boss" else "READY"))
	if m.id == "horde" and not locked:
		chip_text = ("BEST: WAVE %d" % int(_save.get("best_horde", 0))) if int(_save.get("best_horde", 0)) > 0 else "READY"
	if m.id == "promotion":
		chip_text = "RANK %d / %d" % [Promotion.rank(_save), Promotion.RANKS.size()]
	var chip := UIKit.chip(chip_text, UIKit.GOLD if (locked or soon) else tint)
	chip.position = Vector2(10, 10)
	banner.add_child(chip)
	var mi: Texture2D = UIKit.ic({"elite": "ic_elite", "promotion": "ic_rank", "horde": "ic_trial", "boss": "ic_trial"}.get(String(m.id), ""))   # Luna's mode badges
	if mi != null:
		var mt := TextureRect.new()
		mt.texture = mi
		mt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mt.custom_minimum_size = Vector2(40, 40)
		mt.position = Vector2(banner.custom_minimum_size.x - 52.0 if banner.custom_minimum_size.x > 0.0 else 400.0, 8.0)
		mt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		banner.add_child(mt)
		banner.resized.connect(func(): mt.position = Vector2(banner.size.x - 52.0, 8.0))
	v.add_child(banner)
	var d := UIKit.label(m.desc, 13, Color(0.82, 0.9, 1.0))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	if m.id == "promotion":
		v.add_child(_promotion_row(row))
		return p
	# what you can win here: mystery silhouettes in their rarity colour (Rudy)
	row.add_child(UIKit.label("REWARDS", 10, UIKit.MUTED))
	for r in _rewards(String(m.id)):
		row.add_child(_mystery(r[0], r[1]))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	var b: Button
	if soon or locked:
		b = UIKit.ghost_button("Coming soon" if soon else "Locked", 13)
		b.disabled = true
	else:
		b = UIKit.gold_button("Play", 15)
		var elite: bool = m.id == "elite"
		b.pressed.connect(func():
			var sv := Progress.read()
			var top: int = StageData.elite_top(sv) if elite else stage_unlocked
			if m.id == "horde":   # endless waves from your best Standard stage (battle horde)
				_save_patch({"selected_mode": "horde"})
				if Energy.try_play(self, false, 99):
					get_tree().change_scene_to_file("res://battle.tscn")
				return
			_save_patch({"selected_elite": elite, "selected_stage": clampi(int(sv.get("selected_stage", 1)), 1, top)})
			if Energy.try_play(self, elite, int(Progress.read().get("selected_stage", 1))):   # a stage costs power tokens (stages 1-5 free)
				get_tree().change_scene_to_file("res://battle.tscn"))
	b.custom_minimum_size = Vector2(110, 38)
	row.add_child(b)
	v.add_child(row)
	return p

# ------------------------------------------------------------------ promotion (rank trials)
# The card's bottom row: your rank and what it gives, a Ranks button (the ladder), and
# Challenge for the next trial (or what unlocks it). Promotion.start sends battle into it.
# the rank text on its own lines (wrapping), the buttons on a row under it, so the card never
# grows wider than the phone (Rudy, dev209 playtest: the Modes cards ran off the screen)
func _promotion_row(row: HBoxContainer) -> Control:
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	var r := Promotion.rank(_save)
	var nxt := Promotion.next(_save)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	info.add_child(UIKit.label("%s  ·  %s" % [Promotion.rank_name(_save), Promotion.bonus_text(r)] if r > 0 else "Rookie  ·  no rank yet", 11, UIKit.GOLD))
	var next_txt := "All ranks won" if nxt < 0 else ("Next: %s trial  ·  recommended Lv.%d%s" % [Promotion.RANKS[nxt].name, int(Promotion.RANKS[nxt].level), "" if Promotion.unlocked(_save, player_level) else "  ·  opens at Lv.%d" % Promotion.open_level(nxt)])
	info.add_child(UIKit.label(next_txt, 11, UIKit.MUTED))
	for l in info.get_children():
		(l as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(info)
	row.alignment = BoxContainer.ALIGNMENT_END
	outer.add_child(row)
	var elems := UIKit.ghost_button("Elements", 11)   # the element ladders (dev172)
	elems.custom_minimum_size = Vector2(62, 36)
	elems.pressed.connect(_etrials)
	row.add_child(elems)
	var ladder := UIKit.ghost_button("Ranks", 11)
	ladder.custom_minimum_size = Vector2(54, 36)
	ladder.pressed.connect(_ladder)
	row.add_child(ladder)
	var b: Button
	if nxt < 0:
		b = UIKit.ghost_button("Done", 13)
		b.disabled = true
	elif not Promotion.unlocked(_save, player_level):
		b = UIKit.ghost_button("Pilot Lv.%d" % Promotion.open_level(nxt), 13)
		b.disabled = true
	else:
		b = UIKit.gold_button("Challenge", 13)
		b.pressed.connect(func():
			if Energy.try_play(self, false):   # full price: a trial is never a free tutorial stage
				var s := Progress.read()
				Promotion.start(s, nxt)
				Progress.write(s)
				get_tree().change_scene_to_file("res://battle.tscn"))
	_promo_btn = b
	b.custom_minimum_size = Vector2(94, 38)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(b)
	return outer

# the rank ladder: ten rows, won ones in gold with a tick, the next one lit, the rest dim
func _ladder() -> void:
	var r := Promotion.rank(_save)
	var layer := ColorRect.new()
	layer.color = Color(0, 0.01, 0.04, 0.75)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.gui_input.connect(func(ev): if (ev is InputEventMouseButton or ev is InputEventScreenTouch) and ev.pressed: layer.queue_free())
	add_child(layer)
	var p := UIKit.popup_panel()
	var w := minf(size.x - 32.0, 400.0)
	p.custom_minimum_size = Vector2(w, 0)
	p.position = Vector2((size.x - w) * 0.5, 40.0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.add_child(UIKit.label("PILOT RANKS", 18, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UIKit.label("Each trial: one hard stage, bugs %s tougher and more of them; power cards come 25%% faster. Win it once: +%d%% ATK and +%d%% base shield and hull, for good." % [Promotion.hp_range_text(), roundi(Promotion.PER_RANK * 100.0), roundi(Promotion.PER_RANK * 100.0)], 11, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	v.get_child(1).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for i in Promotion.RANKS.size():
		var rk: Dictionary = Promotion.RANKS[i]
		var won: bool = i < r
		var is_next: bool = i == r
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var badge := Control.new()
		badge.custom_minimum_size = Vector2(30, 30)
		var col: Color = UIKit.GOLD if won else (UIKit.CYAN if is_next else Color(0.5, 0.55, 0.68))
		var idx := i
		badge.draw.connect(func():
			badge.draw_circle(Vector2(15, 15), 13.0, Color(col, 0.18 if not won else 0.5))
			badge.draw_arc(Vector2(15, 15), 13.0, 0.0, TAU, 32, col, 1.5, true)
			badge.draw_string(ThemeDB.fallback_font, Vector2(0, 20), "✓" if won else str(idx + 1), HORIZONTAL_ALIGNMENT_CENTER, 30.0, 13, Color.WHITE if won or is_next else col))
		h.add_child(badge)
		var name_box := VBoxContainer.new()   # the rank's name over its twists as Luna's icons (dev189)
		name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_box.add_theme_constant_override("separation", 1)
		name_box.add_child(UIKit.label(rk.name, 14, Color.WHITE if won or is_next else Color(0.6, 0.66, 0.78)))
		var twists := Promotion.mods_row(Promotion.RANK_MODS[i], 10, 18.0)
		if not (won or is_next):
			twists.modulate = Color(1, 1, 1, 0.7)
		name_box.add_child(twists)
		h.add_child(name_box)
		var status := "Won" if won else (("Next  ·  rec. Lv.%d" if is_next and Promotion.unlocked(_save, player_level) else "Rec. Lv.%d") % int(rk.level))
		h.add_child(UIKit.label(status, 11, col, HORIZONTAL_ALIGNMENT_RIGHT))
		if DevTools.on and not won:   # dev mode: fight any rank straight from the ladder (Rudy)
			var fb := UIKit.gold_button("Fight", 11)
			fb.custom_minimum_size = Vector2(56, 30)
			fb.pressed.connect(func():
				if Energy.try_play(self, false):
					var s2 := Progress.read()
					Promotion.start(s2, idx)
					Progress.write(s2)
					get_tree().change_scene_to_file("res://battle.tscn"))
			h.add_child(fb)
		v.add_child(h)
	if UIKit.CLEAN:
		# the Challenge button moved here from the old card (the clean card just opens this ladder)
		var nxt := Promotion.next(_save)
		var cb: Button
		if nxt < 0:
			cb = UIKit.ghost_button("All ranks won", 13)
			cb.disabled = true
		elif not Promotion.unlocked(_save, player_level):
			cb = UIKit.ghost_button("Next trial at pilot Lv.%d" % Promotion.open_level(nxt), 13)
			cb.disabled = true
		else:
			cb = UIKit.gold_button("Challenge: %s" % Promotion.RANKS[nxt].name, 16)
			cb.pressed.connect(func():
				if Energy.try_play(self, false):   # full price: a trial is never a free tutorial stage
					var s := Progress.read()
					Promotion.start(s, nxt)
					Progress.write(s)
					get_tree().change_scene_to_file("res://battle.tscn"))
		v.add_child(cb)
	var close := UIKit.ghost_button("Close", 13)
	close.custom_minimum_size = Vector2(0, 38)
	close.pressed.connect(layer.queue_free)
	v.add_child(close)
	p.add_child(v)
	layer.add_child(p)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://hub.tscn")

# the page rises and fades in over the world (UIKit.enter, dev157); no more black cut
func _fade_in_overlay() -> void:
	UIKit.enter(self)

# ------------------------------------------------------------------ rewards preview
# What a mode can give at your stage, shown as mystery silhouettes (picture darkened, a
# "?" on it, the tile in its rarity colour). [icon, rarity]: coins, then the parts that can
# drop there (Parts: Cells from mini-boss / every 5th stage / from stage 21, Cores from
# bosses on stage 20+), crystals for the modes that pay them.
const COIN := "res://icons/ui_coin.png"
const CRYSTAL := "res://icons/ui_crystal.png"

func _rewards(id: String) -> Array:
	var s := selected_stage
	var boss := StageData.boss_kind(s)
	var out: Array = [[COIN, "common"], ["res://parts/alloy.png", "rare"]]
	match id:
		"standard":
			if boss != "" or s % 5 == 0 or s >= 21:
				out.append(["res://parts/cell.png", "epic"])
			if boss == "boss" and s >= 20:
				out.append(["res://parts/core.png", "legendary"])
			out.append(["res://icons/gear_on.png", GearData.best_drop_rarity(s)])   # a gear copy (dev139)
		"elite":
			out.append(["res://parts/cell.png", "epic"])
			if boss == "boss" and s >= 20:
				out.append(["res://parts/core.png", "legendary"])
			out.append(["res://icons/gear_on.png", GearData.best_drop_rarity(s)])
		"horde":
			out = [[COIN, "common"], [CRYSTAL, "epic"]]
		"boss":
			out = [["res://parts/core.png", "legendary"], [CRYSTAL, "epic"]]
	return out

func _mystery(icon: String, rarity: String) -> Control:
	var col: Color = UIKit.RARITY.get(rarity, UIKit.RARITY.common)
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(38, 38)
	var sb := UIKit.box(Color(col.r * 0.25, col.g * 0.25, col.b * 0.32, 0.9), Color(col, 0.9), 8, 1)
	sb.set_content_margin_all(3)
	p.add_theme_stylebox_override("panel", sb)
	var tr := TextureRect.new()
	tr.texture = load(icon)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.modulate = Color(col.r * 0.35, col.g * 0.35, col.b * 0.45, 0.95)   # a silhouette in its colour
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(tr)
	var q := UIKit.label("?", 18, Color(col.lerp(Color.WHITE, 0.5)), HORIZONTAL_ALIGNMENT_CENTER)
	q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	q.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(q)
	return p

func _tips() -> void:
	Tips.first(get_tree(), [["promotion", _promo_btn]])

# ELEMENT TRIALS (Rudy, dev172): one ladder per element inside Promotion; only a hero of that
# element may fight it. Six rows: element, the hero it needs, steps cleared, and Fight.
func _etrials() -> void:
	var layer := ColorRect.new()
	layer.color = Color(0, 0.01, 0.04, 0.75)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.gui_input.connect(func(ev): if (ev is InputEventMouseButton or ev is InputEventScreenTouch) and ev.pressed: layer.queue_free())
	add_child(layer)
	var p := UIKit.popup_panel()
	var w := minf(size.x - 32.0, 400.0)
	p.custom_minimum_size = Vector2(w, 0)
	p.position = Vector2((size.x - w) * 0.5, 40.0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.add_child(UIKit.label("ELEMENT TRIALS", 18, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var intro := UIKit.label("One ladder per element, %d steps each, across every planet. Only a hero of that element may fight it. The first clear of a step pays that hero's shards and coins; the last step pays crystals too." % Promotion.ETRIAL_STEPS, 11, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(intro)
	for el in Heroes.ELEMENTS:
		var elid: String = String(el)
		var col := Heroes.element_color(elid)
		var steps := Promotion.etrial_steps(_save, elid)
		var why := Promotion.etrial_why_not(_save, elid)
		var hid := Promotion.etrial_owned_hero(_save, elid)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var pips := Control.new()
		pips.custom_minimum_size = Vector2(70, 30)
		pips.draw.connect(func():
			for i in Promotion.ETRIAL_STEPS:
				var c := Vector2(8.0 + i * 14.0, 15.0)
				pips.draw_circle(c, 5.0, Color(col, 0.9) if i < steps else Color(col, 0.15))
				pips.draw_arc(c, 5.0, 0.0, TAU, 16, Color(col, 0.7), 1.0, true))
		h.add_child(pips)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 0)
		info.add_child(UIKit.label("%s  ·  %d / %d" % [Heroes.element_name(elid), steps, Promotion.ETRIAL_STEPS], 14, col))
		var sub := why if why != "" else ("Fight with %s  ·  step %d: stage %d bugs x%.1f" % [Heroes.ROSTER[hid].name, steps + 1, int(Promotion.ETRIAL_STAGES[steps]), Promotion.etrial_hp(steps)])
		info.add_child(UIKit.label(sub, 10, UIKit.MUTED))
		if why == "":
			info.add_child(Promotion.mods_row(Promotion.ETRIAL_MODS[steps], 10, 16.0))   # the step's twists as icons
		h.add_child(info)
		var b: Button
		if why != "":
			b = UIKit.ghost_button("Done" if steps >= Promotion.ETRIAL_STEPS else "Locked", 12)
			b.disabled = true
		else:
			b = UIKit.gold_button("Fight", 13)
			var step := steps
			b.pressed.connect(func():
				if Energy.try_play(self, false):
					var s := Progress.read()
					Promotion.start_etrial(s, elid, step)
					Progress.write(s)
					get_tree().change_scene_to_file("res://battle.tscn"))
		b.custom_minimum_size = Vector2(72, 34)
		h.add_child(b)
		v.add_child(h)
	var close := UIKit.ghost_button("Close", 13)
	close.custom_minimum_size = Vector2(0, 38)
	close.pressed.connect(layer.queue_free)
	v.add_child(close)
	p.add_child(v)
	layer.add_child(p)

# ---- the WEEKLY EVENT (Events, 2026-11-10) ----
# Its card opens a sheet: the week's name and what it does, the two twists, the track of ten
# rewards (taken ones ticked, the next one gold when its points are in), FIGHT and Claim.
func _play_event() -> void:
	if Energy.try_play(self, false, 99):
		_save_patch({"selected_mode": "event"})   # your best stage under the week's twists (battle event_run)
		get_tree().change_scene_to_file("res://battle.tscn")

func _event_sheet() -> void:
	_save = Progress.read()
	var th := Events.theme()
	var st := Events.state(_save)
	var col: Color = th.col
	var layer := Control.new()
	layer.name = "EventSheet"
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var dim := Button.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.01, 0.024, 0.055, 0.62)
	for s in ["normal", "hover", "pressed", "focus"]:
		dim.add_theme_stylebox_override(s, ds)
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
	slider.position.y = 700.0
	slider.create_tween().tween_property(slider, "position:y", 0.0, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	sheet.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var pic := TextureRect.new()
	pic.texture = UIKit.ic(String(th.icon))
	pic.custom_minimum_size = Vector2(56, 56)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(pic)
	var nv := VBoxContainer.new()
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nv.alignment = BoxContainer.ALIGNMENT_CENTER
	nv.add_theme_constant_override("separation", 2)
	nv.add_child(UIKit.title(String(th.name), 24, col.lerp(Color.WHITE, 0.35)))
	nv.add_child(UIKit.label("Ends in %s" % Events.left_text(), 12, UIKit.SOFT))
	head.add_child(nv)
	var x := UIKit.ghost_button("Close", 13)
	x.custom_minimum_size = Vector2(80, 34)
	x.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	x.pressed.connect(layer.queue_free)
	head.add_child(x)
	v.add_child(head)
	var tl := UIKit.label(String(th.text), 13, Color(0.85, 0.9, 0.97))
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(tl)
	v.add_child(Promotion.mods_row(Array(th.mods), 12, 20.0))
	# the points and the track
	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", 6)
	prow.add_child(UIKit.title(str(int(st.points)), 24, UIKit.TEXT))
	var of := UIKit.title("/ %d points" % int(Events.TRACK[-1].points), 14, UIKit.SOFT)
	of.size_flags_vertical = Control.SIZE_SHRINK_END
	prow.add_child(of)
	v.add_child(prow)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for i in Events.TRACK.size():
		var t: Dictionary = Events.TRACK[i]
		var taken: bool = i < int(st.claimed)
		var ready: bool = not taken and int(st.points) >= int(t.points)
		var cell := PanelContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.custom_minimum_size = Vector2(0, 74)
		var cs := UIKit.box(UIKit.GOLD if ready else UIKit.CARD_HI, Color(col, 0.6) if i == int(st.claimed) and not ready else Color(0, 0, 0, 0), 14, 1)
		cs.set_content_margin_all(4)
		cell.add_theme_stylebox_override("panel", cs)
		var cv := VBoxContainer.new()
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		cv.add_theme_constant_override("separation", 1)
		var ink: Color = UIKit.GOLD_INK if ready else UIKit.TEXT
		if taken:
			cv.add_child(UIKit.title("✓", 20, Color(0.44, 0.94, 0.72), HORIZONTAL_ALIGNMENT_CENTER))
			cell.modulate.a = 0.55
		else:
			var first := true
			for k in t.reward:
				var kk := String(k)
				var icon: Texture2D = UIKit.ic("ic_coin", "ui_coin") if kk == "coins" else (UIKit.ic("ic_crystal", "ui_crystal") if kk == "crystals" else (Materials.icon(kk) if Materials.is_material(kk) else Parts.icon(kk)))
				var row := UIKit.iconed(icon, UIKit.num(int(t.reward[k])), 11, ink, 18.0 if first else 14.0)
				row.alignment = BoxContainer.ALIGNMENT_CENTER
				cv.add_child(row)
				first = false
		cv.add_child(UIKit.label(str(int(t.points)), 9, Color(ink, 0.7), HORIZONTAL_ALIGNMENT_CENTER))
		cell.add_child(cv)
		grid.add_child(cell)
	v.add_child(grid)
	var act := HBoxContainer.new()
	act.add_theme_constant_override("separation", 8)
	var fight := UIKit.gold_button("FIGHT  ·  Stage %d" % Events.stage(_save), 18)
	fight.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fight.custom_minimum_size = Vector2(0, 56)
	fight.pressed.connect(_play_event)
	act.add_child(fight)
	if Events.claimable(_save):
		var cb := UIKit.teal_button("Claim", 15)
		cb.custom_minimum_size = Vector2(110, 56)
		UIKit.dot(cb, true)
		cb.pressed.connect(func():
			var sv := Progress.read()
			var got := Events.claim_next(sv)
			if not got.is_empty():
				Progress.write(sv)
				Sfx.play("claim")
			layer.queue_free()
			_event_sheet())
		act.add_child(cb)
	v.add_child(act)
	v.add_child(UIKit.label("A win: %d points, +5 with the hull above half, +5 untouched. A loss: 5." % Events.EVENT_WIN, 11, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER))

# capture hook (CAP_CALL="_dbg_event"): the weekly event sheet
func _dbg_event() -> void:
	_event_sheet()
