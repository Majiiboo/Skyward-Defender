extends Control
# Quests: Daily missions (5 a day, a bonus for all five), Career milestones and the
# Trophy room. Progress and rewards come from progress.gd (Progress); Claim grants the
# reward at once (coins, crystals, pilot XP).

var tab := 0
var _list: VBoxContainer
var _note: Label
var _wallet: HBoxContainer
var _tabs_row: HBoxContainer
var d := {}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	MenuBackdrop.add_to(self)   # the living planet wallpaper behind the page
	d = Progress.read()
	_build()
	_fade_in_overlay()

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
	back.pressed.connect(_on_back_pressed)
	top.add_child(back)
	top.add_child(UIKit.screen_title("QUESTS"))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	_wallet = HBoxContainer.new()
	top.add_child(_wallet)
	col.add_child(top)
	# Home's Daily button can ask for a tab ("quests_tab" meta on the tree root)
	if get_tree().root.has_meta("book_cat"):   # the Collection category to open on (captures use it)
		_book_cat = String(Codex.CATS[clampi(int(get_tree().root.get_meta("book_cat")), 0, Codex.CATS.size() - 1)])
		get_tree().root.remove_meta("book_cat")
	if get_tree().root.has_meta("quests_tab"):
		tab = int(get_tree().root.get_meta("quests_tab"))
		get_tree().root.remove_meta("quests_tab")
	var hidden: Array = [] if Unlocks.open(d, "repeat") else [3]   # Repeat quests from stage 4 (Unlocks)
	if UIKit.CLEAN:
		hidden = [3]   # no Repeat tab (Rudy, 2026-11-09): repeat quests sit at the end of Career
		if tab == 3:
			tab = 1
	tab = UIKit.tab_shown([0, 1, 2, 3, 4], tab, hidden)
	_tabs_row = UIKit.tabs(["Daily", "Career", "Trophies", "Repeat", "Collection"], func(i): tab = i; _fill(), tab, [], hidden, [UIKit.ic("tab_daily"), UIKit.ic("tab_career"), UIKit.ic("tab_trophies"), UIKit.ic("tab_repeat"), UIKit.ic("ic_pack")])
	col.add_child(_tabs_row)
	_note = UIKit.label("", 12, UIKit.MUTED)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_note)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	col.add_child(_list)
	_fill()

func _fill() -> void:
	for c in _list.get_children():
		c.queue_free()
	for c in _wallet.get_children():
		c.queue_free()
	_wallet.add_child(UIKit.wallet(int(d.get("coins", 0)), int(d.get("crystals", 0))))
	UIKit.tab_dots(_tabs_row, Progress.attention(d).quests_tabs)   # a dot on each tab with a claim
	match tab:
		0:
			var ms := Progress.daily(d)
			var left := Progress.DAILY_COUNT
			for m in ms:
				if m.claimed:
					left -= 1
			_note.text = "All 5 done: +%s  ·  %d left today" % [Progress.reward_text(Progress.DAILY_ALL_BONUS), left]
			if UIKit.CLEAN:
				_note.visible = false
				_daily_card(ms)
			for m in ms:
				_row(m.def.text, m.progress, float(m.def.goal), m.def.reward, m.done, m.claimed, func(): d = Progress.claim_daily(m.def.id); Sfx.play("claim"); _fill(), String(m.def.stat))
		1:
			_note.text = "Milestones that never reset."
			_note.visible = not UIKit.CLEAN
			if Contracts.open(d):   # the three contracts of the hero on duty (Contracts): paid in his shards
				var duty := String(Heroes.read(d).selected)
				_list.add_child(UIKit.header("%s on contract" % String(Heroes.ROSTER[duty].name)))
				for ct in Contracts.list(d, duty):
					var kind := String(ct.kind)
					_row(String(ct.text), float(ct.progress), float(ct.goal), ct.reward, bool(ct.done), bool(ct.finished), func():
						d = Progress.read()
						Contracts.claim(d, duty, kind)
						Progress.write(d)
						Sfx.play("claim")
						_fill(), String(ct.stat))
				_list.add_child(UIKit.header("Milestones"))
			for m in Progress.career(d):
				_row(m.def.text, m.progress, float(m.def.goal), m.def.reward, m.done, m.claimed, func(): d = Progress.claim_career(m.def.id); Sfx.play("claim"); _fill(), String(m.def.stat))
			if UIKit.CLEAN and Unlocks.open(d, "repeat"):
				# the old Repeat tab: goals that come back bigger every time you claim them
				_list.add_child(UIKit.header("Again and again"))
				for m in Progress.repeat(d):
					_row("%s  ·  Lv.%d" % [m.text, int(m.lv)], m.progress, float(m.goal), m.reward, m.done, false, func(): d = Progress.claim_repeat(m.def.id); Sfx.play("claim"); _fill(), String(m.def.stat))
		2:
			_note.text = "Trophies have three tiers: bronze, silver and gold. Each tier pays crystals."
			_note.visible = not UIKit.CLEAN
			_trophy_grid()
		3:
			_note.text = "Goals that come back bigger every time you claim them. Always something to chase."
			for m in Progress.repeat(d):
				_row("%s  ·  Lv.%d" % [m.text, int(m.lv)], m.progress, float(m.goal), m.reward, m.done, false, func(): d = Progress.claim_repeat(m.def.id); Sfx.play("claim"); _fill(), String(m.def.stat))
		4:   # the collection book (Codex)
			_note.visible = false
			_collection()
	UIKit.reveal(_list)

# ---- the CLEAN Quests look (Rudy, 2026-11-09, mock-up "Round 2 · Clean") ----
# The day's progress as one card: done / 5, five segments, and the chest the fifth one opens.
func _daily_card(ms: Array) -> void:
	var done := 0
	for m in ms:
		if m.done:
			done += 1
	var p := UIKit.panel(22)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 8)
	var num := HBoxContainer.new()
	num.add_theme_constant_override("separation", 4)
	num.add_child(UIKit.title(str(done), 28, UIKit.TEXT))
	var of := UIKit.title("/ %d" % ms.size(), 20, UIKit.SOFT)
	of.size_flags_vertical = Control.SIZE_SHRINK_END
	num.add_child(of)
	v.add_child(num)
	var segs := Control.new()
	segs.custom_minimum_size = Vector2(0, 8)
	var n := ms.size()
	segs.draw.connect(func():
		var gap := 4.0
		var w: float = (segs.size.x - gap * float(n - 1)) / float(maxi(n, 1))
		for i in n:
			segs.draw_style_box(UIKit.pill(UIKit.CYAN if i < done else Color(0.1, 0.153, 0.25), 4, Vector2.ZERO), Rect2(i * (w + gap), 0.0, w, 8.0)))
	v.add_child(segs)
	var bonus := UIKit.label("All %d: +%s" % [n, Progress.reward_text(Progress.DAILY_ALL_BONUS)], 11, UIKit.SOFT)
	bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(bonus)
	h.add_child(v)
	var chest := TextureRect.new()
	chest.texture = UIKit.ic("chest_closed", "ic_gift")
	chest.custom_minimum_size = Vector2(66, 66)
	chest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chest.modulate = Color.WHITE if done >= n else Color(1, 1, 1, 0.75)
	h.add_child(chest)
	p.add_child(h)
	_list.add_child(p)

# a picture for each kind of task
const STAT_ICON := {"bosses_any": "ic_elite", "bosses": "ic_elite", "stages": "ic_trial", "best_stage": "ic_trial",
	"stars": "ic_trial", "planets": "ic_trial", "upgrades": "st_atk", "merges": "ic_core", "turret_upgrades": "ic_mount"}
func _stat_icon(stat: String) -> Texture2D:
	if stat.contains("kill") or stat.contains("bug"):
		return load("res://enemies/scout.png")
	if stat.contains("spit"):
		return load("res://enemies/spitter.png")
	return UIKit.ic(String(STAT_ICON.get(stat, "ic_rank")), "ic_rank")

# one task: picture, name, bar with x / y, and the reward AS the button (gold when it is ready)
func _clean_row(text: String, progress: float, goal: float, reward: Dictionary, done: bool, claimed: bool, on_claim: Callable, stat: String) -> void:
	var p := UIKit.panel(22)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(56, 56)
	frame.add_theme_stylebox_override("panel", UIKit.box(Color(0.086, 0.137, 0.227), Color(0, 0, 0, 0), 16, 0))
	var tr := TextureRect.new()
	tr.texture = _stat_icon(stat)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(40, 40)
	frame.add_child(tr)
	row.add_child(frame)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 7)
	var name_l := UIKit.label(text, 15, UIKit.TEXT if not claimed else UIKit.SOFT)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(name_l)
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 8)
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = goal
	bar.value = minf(progress, goal)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 6)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("background", UIKit.pill(Color(0.1, 0.153, 0.25), 3, Vector2.ZERO))
	bar.add_theme_stylebox_override("fill", UIKit.pill(Color(0.44, 0.94, 0.72) if done else UIKit.CYAN, 3, Vector2.ZERO))
	bar_row.add_child(bar)
	var cnt := UIKit.title("%d/%d" % [int(minf(progress, goal)), int(goal)], 12, Color(0.44, 0.94, 0.72) if done else UIKit.SOFT)
	bar_row.add_child(cnt)
	body.add_child(bar_row)
	row.add_child(body)
	# the reward on the button: coins, else crystals, else XP
	var icon: Texture2D = null
	var amount := ""
	if reward.has("coins"):
		icon = UIKit.ic("ic_coin", "ui_coin")
		amount = str(int(reward.coins))
	elif reward.has("shards"):   # hero shards (Contracts): the shard picture and how many
		icon = UIKit.ic("mat_shard", "ic_shard")
		var sn := 0
		for hid in reward.shards:
			sn += int(reward.shards[hid])
		amount = str(sn)
	elif reward.has("crystals"):
		icon = UIKit.ic("ic_crystal", "ui_crystal")
		amount = str(int(reward.crystals))
	else:
		amount = Progress.reward_text(reward)
	var b: Button
	if claimed:
		b = UIKit.ghost_button("Done", 13)
		b.disabled = true
	elif done:
		b = UIKit.gold_button(amount, 15)
		b.pressed.connect(func():
			on_claim.call()
			_toast("+ " + Progress.reward_text(reward)))
	else:
		b = UIKit.teal_button(amount, 15)
		b.add_theme_font_override("font", UIKit.title_font())
		b.pressed.connect(func(): _go(stat))
	if icon != null and not claimed:
		b.icon = icon
		b.add_theme_constant_override("icon_max_width", 20)
	b.custom_minimum_size = Vector2(86, 44)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(b)
	p.add_child(row)
	if claimed:
		p.modulate.a = 0.6
	_list.add_child(p)

func _row(text: String, progress: float, goal: float, reward: Dictionary, done: bool, claimed: bool, on_claim: Callable, stat: String = "") -> void:
	if UIKit.CLEAN:
		_clean_row(text, progress, goal, reward, done, claimed, on_claim, stat)
		return
	var p := UIKit.panel(10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 3)
	body.add_child(UIKit.label(text, 14, Color.WHITE if not claimed else UIKit.MUTED))
	var bar := ProgressBar.new()
	bar.min_value = 0; bar.max_value = goal; bar.value = minf(progress, goal)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 8)
	bar.add_theme_stylebox_override("background", UIKit.box(Color(1, 1, 1, 0.08), Color(1, 1, 1, 0.0), 4))
	bar.add_theme_stylebox_override("fill", UIKit.box(UIKit.GOLD if done else UIKit.CYAN, Color(UIKit.CYAN, 0.0), 4))
	body.add_child(bar)
	var meta := HBoxContainer.new()
	meta.add_theme_constant_override("separation", 8)
	meta.add_child(UIKit.label("%d / %d" % [int(minf(progress, goal)), int(goal)], 11, UIKit.MUTED))
	meta.add_child(UIKit.chip(Progress.reward_text(reward), UIKit.GOLD))
	body.add_child(meta)
	row.add_child(body)
	var b: Button
	if claimed:
		b = UIKit.ghost_button("Done", 13)
		b.disabled = true
	elif done:
		b = UIKit.gold_button("Claim", 13)
		b.pressed.connect(func():
			on_claim.call()
			_toast("+ " + Progress.reward_text(reward)))
	else:
		b = UIKit.teal_button("Go", 13)
		b.pressed.connect(func(): _go(stat))
	b.custom_minimum_size = Vector2(76, 34)
	var av := VBoxContainer.new()
	av.alignment = BoxContainer.ALIGNMENT_CENTER
	av.add_child(b)
	row.add_child(av)
	p.add_child(row)
	if claimed:
		p.modulate.a = 0.6
	_list.add_child(p)

func _trophy_grid() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for t in Progress.trophies(d):
		var p := UIKit.panel(10)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 4)
		var medal := Medal.new()
		medal.tier = t.reached
		medal.custom_minimum_size = Vector2(0, 46)
		v.add_child(medal)
		v.add_child(UIKit.label(t.def.name, 14, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
		var next := mini(t.reached, 2)
		var goal: float = float(t.def.tiers[next])
		var shown := "%s %d / %d" % [t.def.text, int(minf(t.value, goal)), int(goal)] if t.reached < 3 else "%s: gold!" % t.def.text
		v.add_child(UIKit.label(shown, 11, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		if t.claimed < t.reached:
			var reward := {"crystals": 0}
			for tier in range(t.claimed, t.reached):
				reward.crystals += int(Progress.TROPHY_REWARD[tier].crystals)
			var b := UIKit.gold_button("Claim %d crystals" % reward.crystals, 12)
			b.custom_minimum_size = Vector2(0, 32)
			var tid: String = t.def.id
			b.pressed.connect(func():
				d = Progress.claim_trophy(tid)
				Sfx.play("claim")
				_toast("+ %d crystals" % reward.crystals)
				_fill())
			v.add_child(b)
		elif t.reached > 0:
			v.add_child(UIKit.label(Progress.TIER_NAMES[t.reached - 1], 11, Progress.TIER_COLORS[t.reached - 1], HORIZONTAL_ALIGNMENT_CENTER))
		p.add_child(v)
		grid.add_child(p)
	_list.add_child(grid)

# a reward message that floats up and fades
func _toast(text: String) -> void:
	var l := UIKit.label(text, 16, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	l.set_anchors_preset(Control.PRESET_CENTER)
	l.position = Vector2(size.x * 0.5 - 150.0, size.y * 0.5)
	l.size = Vector2(300, 30)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 60.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.4)
	tw.chain().tween_callback(l.queue_free)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://hub.tscn")

# the page rises and fades in over the world (UIKit.enter, dev157); no more black cut
func _fade_in_overlay() -> void:
	UIKit.enter(self)

# A trophy medal drawn in thin lines: a star in a ring, in the tier's colour (dim when
# no tier is reached yet). Luna can paint real trophy art later (LUNA-BRIEF).
class Medal extends Control:
	var tier := 0
	func _draw() -> void:
		var c := Vector2(size.x * 0.5, size.y * 0.5)
		var col: Color = Progress.TIER_COLORS[tier - 1] if tier > 0 else Color(1, 1, 1, 0.2)
		draw_circle(c, 20.0, Color(col, 0.15))
		draw_arc(c, 20.0, 0.0, TAU, 40, col, 2.0, true)
		var pts := PackedVector2Array()
		for i in 10:
			var a := -PI / 2.0 + i * PI / 5.0
			pts.append(c + Vector2(cos(a), sin(a)) * (12.0 if i % 2 == 0 else 5.0))
		draw_colored_polygon(pts, col)
		for i in 3:
			draw_circle(c + Vector2((i - 1) * 9.0, 26.0), 2.5, Progress.TIER_COLORS[i] if i < tier else Color(1, 1, 1, 0.15))

# "Go" (Rudy): takes you to where the task is done. Fight tasks start a battle; boss,
# stage, star and planet tasks open the Stage Map to pick one; upgrade and merge tasks
# open Gear on the right tab (Gear reads the "gear_page" meta on the tree root).
const GO := {
	"bosses_any": "map", "bosses": "map", "best_stage": "map", "stars": "map", "planets": "map",
	"upgrades": "gear:0", "turret_upgrades": "gear:1", "merges": "gear:3",
}

func _go(stat: String) -> void:
	var where: String = GO.get(stat, "battle")
	if where == "map":
		get_tree().change_scene_to_file("res://stage_map.tscn")
	elif where.begins_with("gear:"):
		get_tree().root.set_meta("gear_page", int(where.get_slice(":", 1)))
		get_tree().change_scene_to_file("res://gear.tscn")
	elif Energy.try_play(self, bool(Progress.read().get("selected_elite", false)), int(Progress.read().get("selected_stage", 1))):   # power tokens (stages 1-5 free)
		get_tree().change_scene_to_file("res://battle.tscn")

# ---- the COLLECTION tab (Codex, 2026-11-10) ----
# Four pills pick the category (a dot on one with a reward waiting). One card: how many you have,
# a bar to the next reward, and Claim. Then the entries as small squares: yours in full colour
# with their name, the rest a dark shape with a question mark.
var _book_cat := "enemies"

func _collection() -> void:
	var cat_names: Array = []
	var cat_dots: Array = []
	for c in Codex.CATS:
		cat_names.append(String(Codex.NAMES[c]))
		cat_dots.append(Codex.claimable(d, String(c)))
	_list.add_child(UIKit.sub_tabs(cat_names, Codex.CATS.find(_book_cat), func(i: int):   # the shared sub-tab row
		_book_cat = String(Codex.CATS[i])
		_fill(), cat_dots))
	# the progress card
	var cnt := Codex.count(d, _book_cat)
	var goal := Codex.next_goal(d, _book_cat)
	var can := Codex.claimable(d, _book_cat)
	var p := UIKit.panel(22)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 8)
	var num := HBoxContainer.new()
	num.add_theme_constant_override("separation", 4)
	num.add_child(UIKit.title(str(int(cnt[0])), 28, UIKit.TEXT))
	var of := UIKit.title("/ %d" % int(cnt[1]), 20, UIKit.SOFT)
	of.size_flags_vertical = Control.SIZE_SHRINK_END
	num.add_child(of)
	v.add_child(num)
	var bar := ProgressBar.new()
	bar.max_value = maxi(int(goal.need) if int(goal.need) > 0 else int(cnt[1]), 1)
	bar.value = mini(int(cnt[0]), int(bar.max_value))
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 6)
	bar.add_theme_stylebox_override("background", UIKit.pill(Color(0.1, 0.153, 0.25), 3, Vector2.ZERO))
	bar.add_theme_stylebox_override("fill", UIKit.pill(UIKit.GOLD if can else UIKit.CYAN, 3, Vector2.ZERO))
	v.add_child(bar)
	v.add_child(UIKit.label("Complete" if int(goal.need) == 0 else ("Reward ready" if can else "%d more for the next reward" % (int(goal.need) - int(cnt[0]))), 12, UIKit.GOLD if can else UIKit.SOFT))
	h.add_child(v)
	if int(goal.need) > 0:
		var cb := UIKit.gold_button("", 14) if can else UIKit.teal_button("", 14)
		cb.custom_minimum_size = Vector2(104, 50)
		cb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cb.disabled = not can
		var ci := UIKit.iconed(UIKit.ic("ic_crystal", "ui_crystal"), "+%d" % int(goal.crystals), 15, UIKit.GOLD_INK if can else UIKit.SOFT, 20.0)
		ci.set_anchors_preset(Control.PRESET_FULL_RECT)
		ci.alignment = BoxContainer.ALIGNMENT_CENTER
		ci.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cb.add_child(ci)
		cb.pressed.connect(func():
			d = Progress.read()
			var got := Codex.claim(d, _book_cat)
			if got > 0:
				Progress.write(d)
				Sfx.play("claim")
				_toast("+ %d crystals" % got)
			_fill())
		h.add_child(cb)
	p.add_child(h)
	_list.add_child(p)
	# the entries
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for e in Codex.entries(d, _book_cat):
		var cell := PanelContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.custom_minimum_size = Vector2(0, 96)
		var cs := UIKit.box(Color(UIKit.CARD, 0.94 if e.have else 0.55), Color(1, 1, 1, 0.05), 16)
		cs.set_content_margin_all(5)
		cell.add_theme_stylebox_override("panel", cs)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 1)
		var holder := Control.new()
		holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var tr := TextureRect.new()
		tr.texture = e.tex
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if not e.have:
			tr.modulate = Color(0.0, 0.0, 0.0, 0.55)   # a dark shape: something to find
		holder.add_child(tr)
		if not e.have:
			var q := UIKit.title("?", 22, Color(1, 1, 1, 0.35), HORIZONTAL_ALIGNMENT_CENTER)
			q.set_anchors_preset(Control.PRESET_FULL_RECT)
			q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			holder.add_child(q)
		cv.add_child(holder)
		var nl := UIKit.label(String(e.name) if e.have else "???", 9, UIKit.TEXT if e.have else UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		nl.clip_text = true
		cv.add_child(nl)
		cell.add_child(cv)
		grid.add_child(cell)
	_list.add_child(grid)
