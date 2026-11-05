extends Control
# Modes screen (redesigned dev111): one big glass card per mode with a painted world
# banner (Luna's backdrops) and the title over it, what the mode is, what it pays, and
# its button. Locked modes say what unlocks them; modes not built yet say so.
# Add a mode = add an entry to MODES.

const MODES := [
	{"id": "standard", "name": "Normal", "banner": "", "tint": Color(0.2, 0.85, 1.0), "unlock": 0,
		"desc": "6 planets · bosses · up to 3 stars a stage"},
	{"id": "elite", "name": "Elite", "banner": "sentinel", "tint": Color(0.71, 0.45, 1.0), "unlock": 10,
		"desc": "Cleared stages, bugs x1.85 tougher"},
	# rank trials (Promotion, dev143): one hard stage per rank, win once = stronger for good
	{"id": "promotion", "name": "Promotion", "banner": "crystal", "tint": Color(1.0, 0.8, 0.3), "unlock": 0,
		"desc": "Ten rank trials · win once, stronger for good"},
	{"id": "horde", "name": "Horde", "banner": "magma", "tint": Color(1.0, 0.55, 0.25), "unlock": 5, "soon": true,
		"desc": "Endless waves · beat your best score"},
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
				player_level = Turrets.pilot_level(int(d.get("pilot_xp", 0)))
				stage_unlocked = int(d.get("stage_unlocked", 1))
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
	for m in MODES:
		col.add_child(_card(m))
	UIKit.reveal(col, 0.06)
	call_deferred("_tips")

func _card(m: Dictionary) -> Control:
	var locked: bool = player_level < int(m.unlock)
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
	if m.id == "promotion":
		chip_text = "RANK %d / %d" % [Promotion.rank(_save), Promotion.RANKS.size()]
	var chip := UIKit.chip(chip_text, UIKit.GOLD if (locked or soon) else tint)
	chip.position = Vector2(10, 10)
	banner.add_child(chip)
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
			_save_patch({"selected_elite": elite})
			if Energy.try_play(self, elite, int(Progress.read().get("selected_stage", 1))):   # a stage costs power tokens (stages 1-5 free)
				get_tree().change_scene_to_file("res://battle.tscn"))
	b.custom_minimum_size = Vector2(110, 38)
	row.add_child(b)
	v.add_child(row)
	return p

# ------------------------------------------------------------------ promotion (rank trials)
# The card's bottom row: your rank and what it gives, a Ranks button (the ladder), and
# Challenge for the next trial (or what unlocks it). Promotion.start sends battle into it.
func _promotion_row(row: HBoxContainer) -> HBoxContainer:
	var r := Promotion.rank(_save)
	var nxt := Promotion.next(_save)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	info.add_child(UIKit.label("%s  ·  %s" % [Promotion.rank_name(_save), Promotion.bonus_text(r)] if r > 0 else "Rookie  ·  no rank yet", 11, UIKit.GOLD))
	var next_txt := "All ranks won" if nxt < 0 else ("Next: %s trial  ·  recommended Lv.%d%s" % [Promotion.RANKS[nxt].name, int(Promotion.RANKS[nxt].level), "" if Promotion.unlocked(_save, player_level) else "  ·  opens at Lv.%d" % Promotion.open_level(nxt)])
	info.add_child(UIKit.label(next_txt, 11, UIKit.MUTED))
	row.add_child(info)
	var ladder := UIKit.ghost_button("Ranks", 12)
	ladder.custom_minimum_size = Vector2(64, 38)
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
		b = UIKit.gold_button("Challenge", 15)
		b.pressed.connect(func():
			if Energy.try_play(self, false):   # full price: a trial is never a free tutorial stage
				var s := Progress.read()
				Promotion.start(s, nxt)
				Progress.write(s)
				get_tree().change_scene_to_file("res://battle.tscn"))
	_promo_btn = b
	b.custom_minimum_size = Vector2(110, 38)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(b)
	return row

# the rank ladder: ten rows, won ones in gold with a tick, the next one lit, the rest dim
func _ladder() -> void:
	var r := Promotion.rank(_save)
	var layer := ColorRect.new()
	layer.color = Color(0, 0.01, 0.04, 0.75)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.gui_input.connect(func(ev): if (ev is InputEventMouseButton or ev is InputEventScreenTouch) and ev.pressed: layer.queue_free())
	add_child(layer)
	var p := UIKit.panel(16)
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
		var name_l := UIKit.label(rk.name, 14, Color.WHITE if won or is_next else Color(0.6, 0.66, 0.78))
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(name_l)
		var status := "Won" if won else (("Next  ·  rec. Lv.%d" if is_next and Promotion.unlocked(_save, player_level) else "Rec. Lv.%d") % int(rk.level))
		h.add_child(UIKit.label(status, 11, col, HORIZONTAL_ALIGNMENT_RIGHT))
		v.add_child(h)
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
