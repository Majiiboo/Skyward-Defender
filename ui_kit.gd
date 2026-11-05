class_name UIKit
extends RefCounted
# Shared look for every menu screen (Gear, Modes, Quests, Store), so they all match
# Home's Glass look (glass.gd): see-through dark glass over the frosted world (hub
# Frost), a thin light-cyan edge and a faint sheen, gold for the main action, teal for
# secondary actions, purple for premium, rarity colours on tiles.

const CYAN := Color(0.18, 0.9, 1.0)
const PURPLE := Color(0.71, 0.55, 1.0)
const GOLD := Color(1.0, 0.8, 0.3)
const MUTED := Color(0.62, 0.70, 0.84)
const INK := Color(0.04, 0.063, 0.172)
const RARITY := {
	"common": Color(0.55, 0.62, 0.75), "uncommon": Color(0.45, 0.95, 0.5), "rare": Color(0.25, 0.75, 1.0),
	"epic": Color(0.71, 0.55, 1.0), "legendary": Color(1.0, 0.8, 0.3),
	# gear sets (GearData.SETS): colour shows the set, never strength
	"ion": Color(0.2, 0.85, 1.0), "scavenger": Color(0.45, 1.0, 0.35), "void": Color(0.71, 0.45, 1.0),
	"nightmare": Color(1.0, 0.3, 0.3), "solar": Color(1.0, 0.85, 0.45), "frost": Color(0.6, 0.9, 1.0),
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
	var s := box(Color(0.035, 0.06, 0.14, 0.5), Color(0.55, 0.85, 1.0, 0.26), radius)
	# the sheen: a lighter top edge, like the Home glass
	s.border_width_top = 1
	s.border_color = Color(0.55, 0.85, 1.0, 0.26)
	# the same lift as the cards (dev151): a soft drop shadow under every glass panel
	s.shadow_color = Color(0, 0, 0, 0.36)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 4)
	return s

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
	press_fx(b)

# Touch feedback on every kit button (dev140): a small squeeze while held, a springy
# release. Connected once per button.
static func press_fx(b: Button) -> void:
	if b.has_meta("press_fx"):
		return
	b.set_meta("press_fx", true)
	b.button_down.connect(func():
		b.pivot_offset = b.size * 0.5
		var tw := b.create_tween()
		tw.tween_property(b, "scale", Vector2(0.95, 0.95), 0.06))
	b.button_up.connect(func():
		var tw := b.create_tween()
		tw.tween_property(b, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))

# Entrance (dev145): the children of a container rise and fade in one after another, so a
# page or a tab's content arrives instead of appearing. Call after filling the container.
static func reveal(box: Node, stagger: float = 0.035, rise: float = 14.0) -> void:
	var items: Array = []
	for c in box.get_children():
		if c is Control and c.visible:
			c.modulate.a = 0.0
			items.append(c)
	if items.is_empty() or not box.is_inside_tree():
		return
	await box.get_tree().process_frame   # let the container lay them out first
	var i := 0
	for c in items:
		if not is_instance_valid(c) or c.is_queued_for_deletion():
			continue
		var ctl: Control = c
		var tw := ctl.create_tween().set_parallel(true)
		tw.tween_property(ctl, "modulate:a", 1.0, 0.22).set_delay(i * stagger)
		# a small rise, done through position so containers can still lay out
		var y0 := ctl.position.y
		ctl.position.y = y0 + rise
		tw.tween_property(ctl, "position:y", y0, 0.28).set_delay(i * stagger).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		i += 1

# A light sweep across a gold button every few seconds (dev145): a thin bright band
# slides over it, clipped to the button, so the main action catches the eye.
static func sheen(b: Button) -> void:
	if b.has_meta("sheen"):
		return
	b.set_meta("sheen", true)
	b.clip_contents = true
	var band := Control.new()
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.set_anchors_preset(Control.PRESET_FULL_RECT)
	var x := [-0.4]
	band.draw.connect(func():
		var w := band.size.x
		var h := band.size.y
		var cx: float = x[0] * w
		var pts := PackedVector2Array([Vector2(cx - 18, 0), Vector2(cx + 10, 0), Vector2(cx - 10, h), Vector2(cx - 38, h)])
		band.draw_colored_polygon(pts, Color(1, 1, 1, 0.22)))
	b.add_child(band)
	var tw := b.create_tween().set_loops()
	tw.tween_method(func(v: float): x[0] = v; band.queue_redraw(), -0.4, 1.4, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_interval(2.6)

# an icon with a number beside it (coins, crystals, parts)
static func amount(icon: Texture2D, n: int, col: Color, px: float = 18.0, font: int = 13) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	var tr := TextureRect.new()
	tr.texture = icon
	tr.custom_minimum_size = Vector2(px, px)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(tr)
	h.add_child(label(num(n), font, col))
	return h

static func num(n: int) -> String:
	return str(n) if n < 10000 else "%.1fk" % (n / 1000.0)

# the same coins + crystals wallet at the top of every menu page (Store, Quests, Gear)
static func wallet(coins: int, crystals: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.add_child(amount(load("res://icons/ui_coin.png"), coins, GOLD))
	h.add_child(amount(load("res://icons/ui_crystal.png"), crystals, CYAN))
	return h

static func gold_button(text: String, size_px: int = 16) -> Button:
	# The main action (Claim, Upgrade, Go).
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size_px)
	b.custom_minimum_size = Vector2(0, 40)
	_style_btn(b, box(Color(0.92, 0.72, 0.22), Color(1.0, 0.9, 0.5), 10), box(Color(1.0, 0.85, 0.4), Color(1, 1, 0.8), 10), Color(0.12, 0.08, 0.0))
	sheen(b)
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
	var normal := box(Color(col.r * 0.2, col.g * 0.2, col.b * 0.28, 0.78), Color(col, 0.7), 12)
	# depth (dev149, Rudy: the cards looked flat): a soft drop shadow under the card
	normal.shadow_color = Color(0, 0, 0, 0.42)
	normal.shadow_size = 9
	normal.shadow_offset = Vector2(0, 4)
	_style_btn(b, normal, box(Color(col, 0.35), Color.WHITE, 12), Color.WHITE)
	# ...a sheen across the top, a shade along the bottom, a light rim on the top edge, and
	# a glow in the card's colour behind the picture, so the piece looks lit and lifted
	depth(b, col, icon != null)
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

# The red "something to claim" dot (dev142), the same on every page: on = add it, off =
# remove it. Any Control can carry one; Progress.attention decides where they show.
static func dot(b: Control, on: bool) -> void:
	var old := b.get_node_or_null("Dot")
	if not on:
		if old:
			old.queue_free()
		return
	if old:
		return
	var d := Panel.new()
	d.name = "Dot"
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1.0, 0.35, 0.42)
	s.set_corner_radius_all(5)
	s.set_border_width_all(1)
	s.border_color = Color(0.04, 0.06, 0.17)
	d.add_theme_stylebox_override("panel", s)
	d.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	d.offset_left = -13.0
	d.offset_right = -3.0
	d.offset_top = 3.0
	d.offset_bottom = 13.0
	b.add_child(d)

# dots on a tabs() row: flags[i] true = the i-th tab has something to claim
static func tab_dots(row: HBoxContainer, flags: Array) -> void:
	for i in mini(row.get_child_count(), flags.size()):
		dot(row.get_child(i), bool(flags[i]))

static func tabs(names: Array, on_pick: Callable, selected: int = 0, dots: Array = []) -> HBoxContainer:
	# A row of sub-tabs (Daily / Weekly / Monthly). Calls on_pick(index). dots: see tab_dots.
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
			_style_btn(buttons[j], box(Color(CYAN, 0.2) if on else Color(0.035, 0.06, 0.14, 0.45), Color(CYAN, 0.9) if on else Color(0.55, 0.85, 1.0, 0.22), 12), box(Color(CYAN, 0.3), CYAN, 12), Color.WHITE if on else MUTED)
	for i in buttons.size():
		buttons[i].pressed.connect(func():
			paint.call(i)
			on_pick.call(i))
	paint.call(selected)
	tab_dots(row, dots)
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

# ---- depth (dev149-150): every card in the game lifts the same way ----
# A sheen across the top, a shade along the bottom, a light rim on the top edge and, when
# asked, a glow in the card's colour behind its picture. draw_depth paints it into any
# CanvasItem (slot squares); depth() adds it as a layer behind a container's children.
static func draw_depth(c: CanvasItem, s: Vector2, col: Color, glow: bool, glow_y: float = 0.36) -> void:
	var clear := Color(1, 1, 1, 0.0)
	c.draw_polygon(PackedVector2Array([Vector2(1, 1), Vector2(s.x - 1, 1), Vector2(s.x - 1, s.y * 0.45), Vector2(1, s.y * 0.45)]),
		PackedColorArray([Color(1, 1, 1, 0.16), Color(1, 1, 1, 0.16), clear, clear]))
	c.draw_polygon(PackedVector2Array([Vector2(1, s.y * 0.6), Vector2(s.x - 1, s.y * 0.6), Vector2(s.x - 1, s.y - 1), Vector2(1, s.y - 1)]),
		PackedColorArray([Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.28), Color(0, 0, 0, 0.28)]))
	c.draw_line(Vector2(10, 1.5), Vector2(s.x - 10, 1.5), Color(1, 1, 1, 0.22), 1.0, true)
	if glow:
		var centre := Vector2(s.x * 0.5, s.y * glow_y)
		for k in 4:
			c.draw_circle(centre, s.y * (0.34 - 0.07 * k), Color(col, 0.07 + 0.04 * k))

static func depth(parent: Control, col: Color, glow: bool, glow_y: float = 0.36) -> void:
	var d := Control.new()
	d.name = "Depth"
	d.set_anchors_preset(Control.PRESET_FULL_RECT)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.draw.connect(func(): draw_depth(d, d.size, col, glow, glow_y))
	parent.add_child(d)
	parent.move_child(d, 0)

# the drop shadow that goes with it, on an existing flat style
static func lift(sb: StyleBoxFlat) -> StyleBoxFlat:
	sb.shadow_color = Color(0, 0, 0, 0.42)
	sb.shadow_size = 9
	sb.shadow_offset = Vector2(0, 4)
	return sb
