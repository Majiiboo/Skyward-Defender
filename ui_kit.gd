class_name UIKit
extends RefCounted
# Shared look for every menu screen (Gear, Modes, Quests, Store), so they all
# match the Home screen: dark glass panels, cyan outlines, gold for the main
# action, teal for secondary actions, purple for premium, rarity colours on tiles.

const CYAN := Color(0.18, 0.9, 1.0)
const PURPLE := Color(0.71, 0.55, 1.0)
const GOLD := Color(1.0, 0.8, 0.3)
const MUTED := Color(0.62, 0.70, 0.84)
const INK := Color(0.04, 0.063, 0.172)
const RARITY := {
	"common": Color(0.55, 0.62, 0.75), "rare": Color(0.25, 0.75, 1.0),
	"epic": Color(0.71, 0.55, 1.0), "legendary": Color(1.0, 0.8, 0.3),
	# gear sets (GearData.SETS): colour shows the set, never strength
	"ion": Color(0.2, 0.85, 1.0), "scavenger": Color(0.45, 1.0, 0.35), "void": Color(0.71, 0.45, 1.0),
}

static func box(fill: Color, line: Color, radius: float = 12.0, width: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.set_border_width_all(width)
	s.border_color = line
	s.set_corner_radius_all(int(radius))
	s.anti_aliasing = true
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

static func glass(radius: float = 12.0) -> StyleBoxFlat:
	return box(Color(INK, 0.55), Color(1, 1, 1, 0.14), radius)

static func panel(radius: float = 14.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", glass(radius))
	return p

static func label(text: String, size_px: int = 14, col: Color = Color.WHITE, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func header(text: String) -> Control:
	# Section header bar with an angled tag on the left (the style from the reference).
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	var tag := Control.new()
	tag.custom_minimum_size = Vector2(10, 26)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.draw.connect(func():
		tag.draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 26), Vector2(4, 26)]), Color(CYAN, 0.8)))
	row.add_child(tag)
	var p := PanelContainer.new()
	var s := box(Color(CYAN, 0.10), Color(CYAN, 0.0), 0)
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_right = 8
	s.content_margin_top = 3
	s.content_margin_bottom = 3
	p.add_theme_stylebox_override("panel", s)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_child(label(text, 15, Color(0.75, 0.97, 1.0)))
	row.add_child(p)
	return row

static func _style_btn(b: Button, normal: StyleBoxFlat, pressed: StyleBoxFlat, text_col: Color) -> void:
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", box(Color(0.1, 0.1, 0.14, 0.6), Color(1, 1, 1, 0.08), 10))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", text_col)
	b.add_theme_color_override("font_hover_color", text_col)
	b.add_theme_color_override("font_pressed_color", text_col)
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.55, 0.65))

static func gold_button(text: String, size_px: int = 16) -> Button:
	# The main action (Claim, Upgrade, Go).
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size_px)
	b.custom_minimum_size = Vector2(0, 40)
	_style_btn(b, box(Color(0.92, 0.72, 0.22), Color(1.0, 0.9, 0.5), 10), box(Color(1.0, 0.85, 0.4), Color(1, 1, 0.8), 10), Color(0.12, 0.08, 0.0))
	return b

static func teal_button(text: String, size_px: int = 14) -> Button:
	# Secondary action (Enter, Open, Equip).
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size_px)
	b.custom_minimum_size = Vector2(0, 36)
	_style_btn(b, box(Color(0.16, 0.6, 0.62), Color(0.5, 0.95, 0.95), 10), box(Color(0.25, 0.8, 0.8), Color(0.8, 1, 1), 10), Color(0.02, 0.1, 0.1))
	return b

static func ghost_button(text: String, size_px: int = 13) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size_px)
	b.custom_minimum_size = Vector2(0, 32)
	_style_btn(b, glass(10), box(Color(CYAN, 0.25), CYAN, 10), Color.WHITE)
	return b

static func tile(title: String, subtitle: String, rarity: String = "common", badge: String = "", icon: Texture2D = null, size: Vector2 = Vector2(104, 92)) -> Button:
	# Item tile: rarity-coloured border and tint, name, a small line under it,
	# optional badge in the top-left corner (tier, count). Icon optional.
	var col: Color = RARITY.get(rarity, RARITY["common"])
	var b := Button.new()
	b.custom_minimum_size = size
	b.clip_text = true
	_style_btn(b, box(Color(col, 0.13), Color(col, 0.85), 10), box(Color(col, 0.35), Color.WHITE, 10), Color.WHITE)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 1)
	if icon != null:
		var tr := TextureRect.new()
		tr.texture = icon
		tr.custom_minimum_size = Vector2(0, 34)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(tr)
	v.add_child(label(title, 13, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	if subtitle != "":
		v.add_child(label(subtitle, 11, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	b.add_child(v)
	if badge != "":
		var bl := label(badge, 10, col)
		bl.position = Vector2(6, 3)
		b.add_child(bl)
	return b

static func tabs(names: Array, on_pick: Callable, selected: int = 0) -> HBoxContainer:
	# A row of sub-tabs (Daily / Weekly / Monthly). Calls on_pick(index).
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var buttons: Array = []
	for i in names.size():
		var b := Button.new()
		b.text = names[i]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 34)
		b.add_theme_font_size_override("font_size", 13)
		row.add_child(b)
		buttons.append(b)
	var paint := func(sel: int):
		for j in buttons.size():
			var on: bool = j == sel
			_style_btn(buttons[j], box(Color(CYAN, 0.22) if on else Color(INK, 0.5), CYAN if on else Color(1, 1, 1, 0.14), 9), box(Color(CYAN, 0.3), CYAN, 9), Color.WHITE if on else MUTED)
	for i in buttons.size():
		buttons[i].pressed.connect(func():
			paint.call(i)
			on_pick.call(i))
	paint.call(selected)
	return row

static func chip(text: String, col: Color = CYAN) -> PanelContainer:
	var p := PanelContainer.new()
	var s := box(Color(col, 0.16), Color(col, 0.6), 8)
	s.content_margin_top = 2
	s.content_margin_bottom = 2
	s.content_margin_left = 7
	s.content_margin_right = 7
	p.add_theme_stylebox_override("panel", s)
	p.add_child(label(text, 11, Color.WHITE))
	return p

static func screen_title(text: String) -> Label:
	var l := label(text, 22, Color.WHITE)
	return l
