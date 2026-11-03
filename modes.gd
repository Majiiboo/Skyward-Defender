extends Control
# Modes screen: one card per mode (art, name, what it is, rewards, Enter).
# Locked modes show what unlocks them. Add a mode = add an entry to MODES.

const MODES := [
	{"id": "standard", "name": "Standard", "tint": Color(0.15, 0.55, 0.95),
		"desc": "The main campaign. Clear stages across the galaxy, one planet at a time.",
		"rewards": ["Coins", "Gems", "Parts"], "unlock": 0},
	{"id": "elite", "name": "Elite", "tint": Color(0.55, 0.25, 0.95),
		"desc": "The same stages with tougher waves: x1.85 enemy HP, x2 parts, x1.5 coins.",
		"rewards": ["Coins x1.5", "Parts x2", "Epic drops"], "unlock": 10},
	{"id": "horde", "name": "Horde", "tint": Color(0.95, 0.45, 0.2),
		"desc": "Endless waves. No stage end. Survive as long as you can and chase the score.",
		"rewards": ["Score", "Crystals"], "unlock": 5},
	{"id": "boss", "name": "Boss Rush", "tint": Color(0.9, 0.25, 0.4),
		"desc": "Every boss, back to back, with no filler waves in between.",
		"rewards": ["Legendary drops"], "unlock": 20},
]
var player_level := 1

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
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
	col.add_theme_constant_override("separation", 12)
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

func _card(m: Dictionary) -> Control:
	var locked: bool = player_level < int(m.unlock)
	var p := UIKit.panel(14)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	# art: a planet disc in the mode's colour, drawn in code (placeholder for real art)
	var art := Control.new()
	art.custom_minimum_size = Vector2(84, 84)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tint: Color = m.tint
	art.draw.connect(func():
		art.draw_rect(Rect2(Vector2.ZERO, art.size), Color(0.02, 0.03, 0.08))
		for i in 10:
			art.draw_circle(Vector2(42, 44), 38.0 - i * 2.6, Color(tint, 0.05))
		art.draw_circle(Vector2(42, 44), 26.0, Color(tint, 0.9 if not locked else 0.35))
		art.draw_circle(Vector2(35, 37), 8.0, Color(1, 1, 1, 0.18))
		art.draw_arc(Vector2(42, 44), 33.0, PI * 1.1, PI * 1.9, 24, Color(tint, 0.8), 2.0, true)
		if locked:
			art.draw_rect(Rect2(33, 41, 18, 14), Color(0.9, 0.9, 1.0, 0.9))
			art.draw_arc(Vector2(42, 41), 6.0, PI, TAU, 12, Color(0.9, 0.9, 1.0, 0.9), 3.0, true))
	row.add_child(art)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size = Vector2(0, 0)
	body.clip_contents = true
	body.add_theme_constant_override("separation", 4)
	var title := HBoxContainer.new()
	title.add_child(UIKit.label(m.name, 17, Color.WHITE))
	if locked:
		title.add_child(UIKit.chip("Unlocks at Lv.%d" % int(m.unlock), UIKit.GOLD))
	body.add_child(title)
	var d := UIKit.label(m.desc, 12, Color(0.78, 0.86, 0.98))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(d)
	var rw := HBoxContainer.new()
	rw.add_theme_constant_override("separation", 6)
	rw.add_child(UIKit.label("Rewards", 11, UIKit.MUTED))
	for r in m.rewards:
		rw.add_child(UIKit.chip(r, tint))
	body.add_child(rw)
	row.add_child(body)
	var action := VBoxContainer.new()
	action.alignment = BoxContainer.ALIGNMENT_CENTER
	var b: Button
	if locked:
		b = UIKit.ghost_button("Locked")
		b.disabled = true
	else:
		b = UIKit.teal_button("Enter")
		b.pressed.connect(func(): get_tree().change_scene_to_file("res://battle.tscn"))
	b.custom_minimum_size = Vector2(72, 36)
	action.add_child(b)
	row.add_child(action)
	p.add_child(row)
	if locked:
		p.modulate = Color(0.8, 0.8, 0.9, 1.0)
	return p

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
