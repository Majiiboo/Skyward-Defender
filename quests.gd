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
	if get_tree().root.has_meta("quests_tab"):
		tab = int(get_tree().root.get_meta("quests_tab"))
		get_tree().root.remove_meta("quests_tab")
	_tabs_row = UIKit.tabs(["Daily", "Career", "Trophies"], func(i): tab = i; _fill(), tab)
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
			for m in ms:
				_row(m.def.text, m.progress, float(m.def.goal), m.def.reward, m.done, m.claimed, func(): d = Progress.claim_daily(m.def.id); _fill(), String(m.def.stat))
		1:
			_note.text = "Milestones that never reset."
			for m in Progress.career(d):
				_row(m.def.text, m.progress, float(m.def.goal), m.def.reward, m.done, m.claimed, func(): d = Progress.claim_career(m.def.id); _fill(), String(m.def.stat))
		2:
			_note.text = "Trophies have three tiers: bronze, silver and gold. Each tier pays crystals."
			_trophy_grid()

func _row(text: String, progress: float, goal: float, reward: Dictionary, done: bool, claimed: bool, on_claim: Callable, stat: String = "") -> void:
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

func _fade_in_overlay() -> void:
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 1)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	var tw := create_tween()
	tw.tween_property(overlay, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func(): overlay.queue_free())

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
