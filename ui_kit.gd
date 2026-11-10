class_name UIKit
extends RefCounted
# Shared look for every menu screen (Gear, Modes, Quests, Store), so they all match
# Home's Glass look (glass.gd): see-through dark glass over the frosted world (hub
# Frost), a thin light-cyan edge and a faint sheen, gold for the main action, teal for
# secondary actions, purple for premium, rarity colours on tiles.

const CYAN := Color(0.31, 0.88, 1.0)
const PURPLE := Color(0.71, 0.55, 1.0)
const GOLD := Color(1.0, 0.784, 0.27)
const MUTED := Color(0.62, 0.70, 0.84)
const INK := Color(0.04, 0.063, 0.172)

# ---- the CLEAN look (Rudy, 2026-11-09, mock-up "Round 2 · Clean"): flat cards, no gloss, no dark
# lip under buttons, pill tabs and chips, one gold button per screen, Oxanium for titles and
# numbers, Inter for everything else. CLEAN false = the older glass + Luna kit look.
const CLEAN := true
const CARD := Color(0.055, 0.09, 0.157)       # the card colour (#0e1728)
const CARD_HI := Color(0.094, 0.145, 0.239)   # a raised button on a card (#18253d)
const TEXT := Color(0.933, 0.957, 1.0)
const SOFT := Color(0.56, 0.635, 0.74)        # small grey text
const GOLD_INK := Color(0.14, 0.094, 0.0)     # text on gold
static var _title_font: Font = null

# Oxanium 800: titles, big numbers, the main buttons
static func title_font() -> Font:
	if _title_font == null:
		_title_font = load("res://fonts/oxanium_heavy.tres")
	return _title_font

static func title(text: String, size_px: int = 22, col: Color = TEXT, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := label(text, size_px, col, align)
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_font_override("font", title_font())
	return l

# a flat pill (chips, tab strips, top-bar currencies)
static func pill(fill: Color, radius: int = 18, pad: Vector2 = Vector2(10, 4)) -> StyleBoxFlat:
	var s := box(fill, Color(0, 0, 0, 0), radius, 0)
	s.content_margin_left = pad.x
	s.content_margin_right = pad.x
	s.content_margin_top = pad.y
	s.content_margin_bottom = pad.y
	return s
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
	if CLEAN:
		# a flat card: no sheen, no bright edge, a soft shadow under it
		var c := box(Color(CARD, 0.94), Color(1, 1, 1, 0.05), maxf(radius, 16.0))
		c.shadow_color = Color(0, 0, 0, 0.25)
		c.shadow_size = 6
		c.shadow_offset = Vector2(0, 3)
		return c
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
	if CLEAN:
		p.add_theme_stylebox_override("panel", glass(maxf(radius, 20.0)))
		return p
	# Luna's panel (round 2: gloss only in the corner, so it stretches to any height); big
	# radius = a pop-up window, which uses her popup piece
	if kit_ready("panel_glass"):
		p.add_theme_stylebox_override("panel", nine("panel_glass", 22.0, Vector2(12, 9)))
	else:
		p.add_theme_stylebox_override("panel", glass(radius))
	return p

static func label(text: String, size_px: int = 14, col: Color = Color.WHITE, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size_px + (1 if size_px <= 13 else 0))   # small text one size up (Rudy: too small, too thin)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func header(text: String) -> Control:
	# Section header bar with an angled tag on the left (the style from the reference).
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	if CLEAN:   # a plain bold title, no bar
		if text == text.to_upper() and text.length() > 1:   # one case everywhere: "YOUR PARTS" reads "Your parts"
			text = text.substr(0, 1) + text.substr(1).to_lower()
		var t := title(text, 17, TEXT)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(t)
		return row
	if kit_ready("header_bar"):   # Luna's header bar: the angled tag is painted in
		var hp := PanelContainer.new()
		var hs := nine("header_bar", 10.0, Vector2(26, 2))
		hs.texture_margin_left = 56.0   # the painted angled tag stays whole
		hp.add_theme_stylebox_override("panel", hs)
		hp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hp.add_child(label(text, 15, Color(0.75, 0.97, 1.0)))
		row.add_child(hp)
		return row
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

# Depth on every kit button (Rudy, dev172: "buttons are flat"): a drop shadow under it, a
# gloss on its top half, a darker band at the bottom and a thin light line on its top edge.
static func draw_bevel(c: CanvasItem, s: Vector2) -> void:
	if CLEAN:   # flat buttons (Rudy: no gloss, no black bar)
		return
	var clear := Color(1, 1, 1, 0.0)
	c.draw_polygon(PackedVector2Array([Vector2(2, 1), Vector2(s.x - 2, 1), Vector2(s.x - 2, s.y * 0.48), Vector2(2, s.y * 0.48)]),
		PackedColorArray([Color(1, 1, 1, 0.14), Color(1, 1, 1, 0.14), clear, clear]))
	c.draw_polygon(PackedVector2Array([Vector2(2, s.y * 0.62), Vector2(s.x - 2, s.y * 0.62), Vector2(s.x - 2, s.y - 1), Vector2(2, s.y - 1)]),
		PackedColorArray([Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.2), Color(0, 0, 0, 0.2)]))
	c.draw_line(Vector2(9, 1.5), Vector2(s.x - 9, 1.5), Color(1, 1, 1, 0.26), 1.0, true)

static func _style_btn(b: Button, normal: StyleBoxFlat, pressed: StyleBoxFlat, text_col: Color) -> void:
	lift(normal)   # the drop shadow
	normal.shadow_size = 6
	normal.shadow_offset = Vector2(0, 3)
	if CLEAN:   # a soft shadow only, so a button sits on the card without a dark band
		normal.shadow_color = Color(0, 0, 0, 0.22)
		normal.shadow_size = 4
		normal.shadow_offset = Vector2(0, 2)
	if not b.has_meta("bevel"):
		b.set_meta("bevel", true)
		b.draw.connect(func(): if not b.disabled: draw_bevel(b, b.size))
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
		Sfx.play("tap")
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
	if b.has_meta("sheen") or Perf.lite():
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
	h.add_child(amount(ic("ic_coin", "ui_coin"), coins, GOLD))
	h.add_child(amount(ic("ic_crystal", "ui_crystal"), crystals, CYAN))
	return h

static func gold_button(text: String, size_px: int = 16) -> Button:
	# The main action (Claim, Upgrade, Go).
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size_px)
	b.custom_minimum_size = Vector2(0, 40)
	if CLEAN:   # flat gold, dark text in Oxanium: the one main action on a screen
		b.custom_minimum_size = Vector2(0, 46)
		b.add_theme_font_override("font", title_font())
		_style_btn(b, box(GOLD, Color(0, 0, 0, 0), 16, 0), box(GOLD.lightened(0.2), Color(0, 0, 0, 0), 16, 0), GOLD_INK)
		sheen(b)
		return b
	if kit_ready("btn_gold"):
		_kit_btn(b, "btn_gold", Color(0.12, 0.08, 0.0))
		return b
	_style_btn(b, box(Color(0.92, 0.72, 0.22), Color(1.0, 0.9, 0.5), 10), box(Color(1.0, 0.85, 0.4), Color(1, 1, 0.8), 10), Color(0.12, 0.08, 0.0))
	sheen(b)
	return b

static func teal_button(text: String, size_px: int = 14) -> Button:
	# Secondary action (Enter, Open, Equip).
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size_px)
	b.custom_minimum_size = Vector2(0, 36)
	if CLEAN:   # a raised dark button, white text
		b.custom_minimum_size = Vector2(0, 40)
		_style_btn(b, box(CARD_HI, Color(0, 0, 0, 0), 14, 0), box(CARD_HI.lightened(0.15), Color(0, 0, 0, 0), 14, 0), TEXT)
		return b
	if kit_ready("btn_teal"):
		_kit_btn(b, "btn_teal", Color(0.02, 0.1, 0.1))
		return b
	_style_btn(b, box(Color(0.16, 0.6, 0.62), Color(0.5, 0.95, 0.95), 10), box(Color(0.25, 0.8, 0.8), Color(0.8, 1, 1), 10), Color(0.02, 0.1, 0.1))
	return b

static func ghost_button(text: String, size_px: int = 13) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size_px)
	b.custom_minimum_size = Vector2(0, 32)
	if CLEAN:   # an outline only
		b.custom_minimum_size = Vector2(0, 38)
		var gn := box(Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.24), 14)
		_style_btn(b, gn, box(Color(1, 1, 1, 0.08), Color(1, 1, 1, 0.4), 14), TEXT)
		gn.shadow_size = 0
		return b
	if kit_ready("btn_glass"):
		_kit_btn(b, "btn_glass", Color.WHITE)
		return b
	_style_btn(b, glass(10), box(Color(CYAN, 0.25), CYAN, 10), Color.WHITE)
	return b

static func tile(title: String, subtitle: String, rarity: String = "common", badge: String = "", icon: Texture2D = null, size: Vector2 = Vector2(104, 92)) -> Button:
	# Item tile: rarity-coloured border and tint, name, a small line under it,
	# optional badge in the top-left corner (tier, count). Icon optional.
	var col: Color = RARITY.get(rarity, RARITY["common"])
	var b := Button.new()
	b.custom_minimum_size = size
	b.clip_text = true
	if CLEAN:
		# a flat card, the item's colour as a faint tint and a thin edge (rarity still reads)
		var cn := box(Color(CARD.lerp(col, 0.12), 0.96), Color(col, 0.38), 18)
		_style_btn(b, cn, box(Color(CARD.lerp(col, 0.3), 1.0), Color(col, 0.8), 18), TEXT)
		var cv := VBoxContainer.new()
		cv.set_anchors_preset(Control.PRESET_FULL_RECT)
		cv.name = "Body"
		cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(cv)
		_fill_tile(cv, title, subtitle, badge, icon, size, col)
		return b
	if kit_ready("panel_tile"):   # Luna's tile frame (corner brackets), tinted by the item colour
		var kt := nine("panel_tile", 22.0, Vector2(4, 4), Color(col.lerp(Color.WHITE, 0.3), 1.0))
		_kit_tile(b, kt, col)
		depth(b, col, icon != null)
		var kv := VBoxContainer.new()
		kv.set_anchors_preset(Control.PRESET_FULL_RECT)
		kv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		kv.name = "Body"
		b.add_child(kv)
		_fill_tile(kv, title, subtitle, badge, icon, size, col)
		return b
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
	v.name = "Body"   # callers reach the picture through this, never by child index (dev167)
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
	# flags are indexed like `names` in tabs(); hidden tabs (Unlocks) are skipped by the map
	var map: Array = row.get_meta("tab_map", [])
	for j in row.get_child_count():
		var i: int = int(map[j]) if j < map.size() else j
		if i < flags.size():
			dot(row.get_child(j), bool(flags[i]))

# the index a hidden `selected` tab falls back to (the first shown one)
static func tab_shown(names: Array, selected: int, hidden: Array) -> int:
	if not hidden.has(selected):
		return selected
	for i in names.size():
		if not hidden.has(i):
			return i
	return 0

static func tabs(names: Array, on_pick: Callable, selected: int = 0, dots: Array = [], hidden: Array = [], icons: Array = []) -> HBoxContainer:
	# A row of sub-tabs (Daily / Weekly / Monthly). Calls on_pick(index). dots: see tab_dots.
	# hidden: indices not built at all (a system the player has not reached yet, Unlocks);
	# on_pick and dots keep using the full `names` index.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	if CLEAN:
		return _clean_tabs(row, names, on_pick, selected, dots, hidden, icons)
	var buttons: Array = []
	var map: Array = []
	# five tabs or more: no icons, a size smaller, and every tab may shrink (clip_text), so the row
	# never grows wider than the phone (Rudy, dev209: the Store tabs ran off the screen)
	var crowded: bool = names.size() - hidden.size() >= 5
	if crowded:
		row.add_theme_constant_override("separation", 4)
	for i in names.size():
		if hidden.has(i):
			continue
		var b := Button.new()
		b.text = names[i]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 34)
		b.add_theme_font_size_override("font_size", 12 if crowded else 13)
		b.clip_text = true
		if not crowded and i < icons.size() and icons[i] != null:   # Luna's tab icons (dev182)
			b.icon = icons[i]
			b.add_theme_constant_override("icon_max_width", 18)
			b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.expand_icon = true
		row.add_child(b)
		buttons.append(b)
		map.append(i)
	row.set_meta("tab_map", map)
	var paint := func(sel: int):
		for j in buttons.size():
			var on: bool = int(map[j]) == sel
			if kit_ready("btn_tab"):
				_kit_btn(buttons[j], "btn_tab" if on else "btn_glass", Color.WHITE if on else MUTED)
				continue
			_style_btn(buttons[j], box(Color(CYAN, 0.2) if on else Color(0.035, 0.06, 0.14, 0.45), Color(CYAN, 0.9) if on else Color(0.55, 0.85, 1.0, 0.22), 12), box(Color(CYAN, 0.3), CYAN, 12), Color.WHITE if on else MUTED)
	for j in buttons.size():
		var i: int = int(map[j])
		buttons[j].pressed.connect(func():
			paint.call(i)
			on_pick.call(i))
	paint.call(tab_shown(names, selected, hidden))
	tab_dots(row, dots)
	return row

# The CLEAN tab strip (mock-up "Round 2 · Clean"): one dark pill, the open tab a white pill with
# dark text; with icons, the other tabs show only their icon (dimmed), so even five fit a phone.
static func _clean_tabs(row: HBoxContainer, names: Array, on_pick: Callable, selected: int, dots: Array, hidden: Array, icons: Array) -> HBoxContainer:
	row.add_theme_constant_override("separation", 2)
	var bg := pill(Color(CARD, 0.9), 22, Vector2.ZERO)
	row.draw.connect(func(): row.draw_style_box(bg, Rect2(Vector2.ZERO, row.size).grow(4.0)))
	var buttons: Array = []
	var map: Array = []
	var has_icons := false
	for i in names.size():
		if hidden.has(i):
			continue
		var b := Button.new()
		b.text = names[i]
		b.set_meta("tab_name", names[i])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 38)
		b.add_theme_font_size_override("font_size", 14)
		b.clip_text = true
		if i < icons.size() and icons[i] != null:
			b.icon = icons[i]
			b.add_theme_constant_override("icon_max_width", 26)
			b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			b.expand_icon = true
			has_icons = true
		row.add_child(b)
		buttons.append(b)
		map.append(i)
	row.set_meta("tab_map", map)
	var paint := func(sel: int):
		for j in buttons.size():
			var bj: Button = buttons[j]
			var on: bool = int(map[j]) == sel
			var on_box := pill(TEXT, 19, Vector2(8, 2))
			var off_box := pill(Color(1, 1, 1, 0.0), 19, Vector2(4, 2))
			for st in ["normal", "hover", "disabled"]:
				bj.add_theme_stylebox_override(st, on_box if on else off_box)
			bj.add_theme_stylebox_override("pressed", pill(Color(TEXT, 0.85) if on else Color(1, 1, 1, 0.08), 19, Vector2(4, 2)))
			bj.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
			var ink: Color = Color(0.043, 0.075, 0.133) if on else SOFT
			for c in ["font_color", "font_hover_color", "font_pressed_color"]:
				bj.add_theme_color_override(c, ink)
			bj.add_theme_color_override("icon_normal_color", Color.WHITE if on else Color(1, 1, 1, 0.45))
			bj.add_theme_color_override("icon_hover_color", Color.WHITE if on else Color(1, 1, 1, 0.7))
			if bj.icon != null:
				# icon-only when closed, icon + name when open (the open one takes more room)
				bj.text = String(bj.get_meta("tab_name")) if on else ""
				bj.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT if on else HORIZONTAL_ALIGNMENT_CENTER
				bj.size_flags_stretch_ratio = 2.2 if on else 1.0
			press_fx(bj)
	for j in buttons.size():
		var i: int = int(map[j])
		buttons[j].pressed.connect(func():
			paint.call(i)
			on_pick.call(i))
	paint.call(tab_shown(names, selected, hidden))
	tab_dots(row, dots)
	return row

static func chip(text: String, col: Color = CYAN) -> PanelContainer:
	var p := PanelContainer.new()
	if CLEAN:
		p.add_theme_stylebox_override("panel", pill(Color(col, 0.16), 11, Vector2(9, 2)))
		p.add_child(label(text, 11, TEXT))
		return p
	if kit_ready("chip"):
		var ks := nine("chip", 11.0, Vector2(9, 2), Color(col.lerp(Color.WHITE, 0.35), 1.0))
		p.add_theme_stylebox_override("panel", ks)
		p.add_child(label(text, 11, Color.WHITE))
		return p
	var s := box(Color(col, 0.16), Color(col, 0.6), 8)
	s.content_margin_top = 2
	s.content_margin_bottom = 2
	s.content_margin_left = 7
	s.content_margin_right = 7
	p.add_theme_stylebox_override("panel", s)
	p.add_child(label(text, 11, Color.WHITE))
	return p

static func screen_title(text: String) -> Label:
	if CLEAN:
		return title(text, 26, TEXT)
	var l := label(text, 22, Color.WHITE)
	return l

# ---- page transitions (dev157): one style everywhere, no black cuts ----
# A page arrives: it rises a little and fades in over the world behind it (the Home
# wallpaper or its own MenuBackdrop). Replaces the old fade-from-black overlays.
static func enter(page: Control) -> void:
	page.modulate.a = 0.0
	page.position.y += 28.0
	var tw := page.create_tween().set_parallel(true)
	tw.tween_property(page, "modulate:a", 1.0, 0.22)
	tw.tween_property(page, "position:y", page.position.y - 28.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# A page leaves: it sinks and fades, then frees itself. Returns at once.
static func leave(page: Control) -> void:
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in page.get_children():
		if c is Control:
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := page.create_tween().set_parallel(true)
	tw.tween_property(page, "modulate:a", 0.0, 0.16)
	tw.tween_property(page, "position:y", page.position.y + 18.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(page.queue_free)

# A floating panel (pause menu, pop-ups) pops into place: from slightly small and clear.
static func pop_in(panel: Control, from_scale: float = 0.92) -> void:
	panel.pivot_offset = panel.size * 0.5 if panel.size != Vector2.ZERO else panel.custom_minimum_size * 0.5
	panel.scale = Vector2(from_scale, from_scale)
	panel.modulate.a = 0.0
	var tw := panel.create_tween().set_parallel(true)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.16)

# ---- depth (dev149-150): every card in the game lifts the same way ----
# A sheen across the top, a shade along the bottom, a light rim on the top edge and, when
# asked, a glow in the card's colour behind its picture. draw_depth paints it into any
# CanvasItem (slot squares); depth() adds it as a layer behind a container's children.
static func draw_depth(c: CanvasItem, s: Vector2, col: Color, glow: bool, glow_y: float = 0.36) -> void:
	if CLEAN:
		# flat cards: only a soft glow of the item's colour behind its picture, no gloss
		if glow:
			var cc := Vector2(s.x * 0.5, s.y * glow_y)
			for k in 3:
				c.draw_circle(cc, s.y * (0.3 - 0.07 * k), Color(col, 0.05 + 0.03 * k))
		return
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

# ---- Luna's UI kit (dev172, LUNA-BRIEF-ui-kit.md): ui/<name>.png stretched as 9-slice boxes ----
# The corners stay as painted, the edges and the middle stretch, so one picture is every
# button of any width. KIT_ON false = the code-drawn glass again.
const KIT_ON := true
static var _kit_cache := {}

static func kit_ready(name: String) -> bool:
	return KIT_ON and ResourceLoader.exists("res://ui/%s.png" % name)

# a 9-slice box from a kit piece; `edge` = the corner size kept as painted (px of the
# picture); `pad` = the content margins; `col` tints it (chips and bars)
const BTN_LIP := 10.0
static func nine(name: String, edge: float = 40.0, pad: Vector2 = Vector2(12, 8), col: Color = Color.WHITE) -> StyleBoxTexture:
	var key := "%s|%.0f|%s|%s" % [name, edge, str(pad), str(col)]
	if _kit_cache.has(key):
		return _kit_cache[key]
	var s := StyleBoxTexture.new()
	s.texture = load("res://ui/%s.png" % name)
	s.texture_margin_left = edge
	s.texture_margin_right = edge
	s.texture_margin_top = edge
	s.texture_margin_bottom = edge
	s.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	s.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	s.content_margin_left = pad.x
	s.content_margin_right = pad.x
	s.content_margin_top = pad.y
	s.content_margin_bottom = pad.y
	# Luna's buttons are a face on a dark lip (the bottom ~11 px of the drawn button): centre the
	# text on the face, so it is never low and a second line never runs into the lip (dev209 playtest)
	if name.begins_with("btn_"):
		s.content_margin_bottom = pad.y + BTN_LIP
	s.modulate_color = col
	_kit_cache[key] = s
	return s

# a kit button: Luna's face, pressed face and the grey disabled face
static func _kit_btn(b: Button, face: String, text_col: Color) -> void:
	b.add_theme_stylebox_override("normal", nine(face, 14.0, Vector2(6, 4)))
	b.add_theme_stylebox_override("hover", nine(face, 14.0, Vector2(6, 4)))
	b.add_theme_stylebox_override("pressed", nine(face + "_pressed" if kit_ready(face + "_pressed") else face, 14.0, Vector2(6, 5)))
	b.add_theme_stylebox_override("disabled", nine("btn_off", 14.0, Vector2(6, 4)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", text_col)
	b.add_theme_color_override("font_hover_color", text_col)
	b.add_theme_color_override("font_pressed_color", text_col)
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.55, 0.65))
	press_fx(b)

# the kit tile's button styles (Luna's panel_tile, tinted) and the tile's body
static func _kit_tile(b: Button, kt: StyleBoxTexture, col: Color) -> void:
	var pressed := nine("panel_tile", 22.0, Vector2(4, 4), Color.WHITE)
	b.add_theme_stylebox_override("normal", kt)
	b.add_theme_stylebox_override("hover", kt)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", kt)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", Color.WHITE)
	press_fx(b)

static func _fill_tile(v: VBoxContainer, title: String, subtitle: String, badge: String, icon: Texture2D, size: Vector2, col: Color) -> void:
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
	if badge != "":
		var bl := label(badge, 10, col)
		bl.position = Vector2(14, 8)   # clear of the painted corner bracket
		v.get_parent().add_child(bl)

# a pop-up window (NEW, confirm, the ladders, stats): Luna's popup piece with its notch
static func popup_panel() -> PanelContainer:
	var p := PanelContainer.new()
	if CLEAN:
		var s := glass(24.0)
		s.bg_color = Color(CARD, 0.98)
		s.border_color = Color(1, 1, 1, 0.08)
		s.shadow_color = Color(0, 0, 0, 0.45)
		s.shadow_size = 18
		s.content_margin_left = 16
		s.content_margin_right = 16
		s.content_margin_top = 16
		s.content_margin_bottom = 16
		p.add_theme_stylebox_override("panel", s)
		return p
	p.add_theme_stylebox_override("panel", nine("popup", 30.0, Vector2(14, 14)) if kit_ready("popup") else glass(16.0))
	return p

# ---- Luna's icons (dev182, LUNA-BRIEF-icons.md): icons/<name>.png, 48 of them ----
# ic(name, fallback): her icon when it exists, else the old picture by name
static func ic(name: String, fallback: String = "") -> Texture2D:
	var p := "res://icons/%s.png" % name
	if ResourceLoader.exists(p):
		return load(p)
	return load("res://icons/%s.png" % fallback) if fallback != "" and ResourceLoader.exists("res://icons/%s.png" % fallback) else null

# the six element badges by element id (Heroes.ELEMENTS keys = GearData.SETS keys)
const ELEMENT_ICON := {"ion": "el_energy", "scavenger": "el_electric", "frost": "el_ice", "void": "el_void", "nightmare": "el_dark", "solar": "el_fire"}
static func element_icon(el: String) -> Texture2D:
	return ic(ELEMENT_ICON.get(el, "el_any"))

const ROLE_ICON := {"Striker": "role_striker", "Breaker": "role_breaker", "Chain": "role_chain", "Control": "role_control", "Swarm": "role_swarm", "Support": "role_support"}
static func role_icon(role: String) -> Texture2D:
	return ic(ROLE_ICON.get(role, "role_striker"))

# a small icon + text row (stats, costs)
static func iconed(icon: Texture2D, text: String, size_px: int = 13, col: Color = Color.WHITE, px: float = 18.0) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 5)
	if icon != null:
		var tr := TextureRect.new()
		tr.texture = icon
		tr.custom_minimum_size = Vector2(px, px)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(tr)
	h.add_child(label(text, size_px, col))
	return h

# a small badge stuck in a tile's top-right corner (an element, a role)
static func corner_icon(parent: Control, icon: Texture2D, px: float = 22.0, left: bool = false) -> void:
	if icon == null:
		return
	var tr := TextureRect.new()
	tr.texture = icon
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.set_anchors_preset(Control.PRESET_TOP_LEFT if left else Control.PRESET_TOP_RIGHT)
	tr.offset_left = 5.0 if left else -px - 5.0
	tr.offset_right = px + 5.0 if left else -5.0
	tr.offset_top = 5.0
	tr.offset_bottom = px + 5.0
	parent.add_child(tr)

# The E badge (Rudy, dev186): a small "E" in a tile's corner marks what is equipped, instead of
# "Equipped" / "Wearing" / "On mount" words. It sits in the item's colour, low-key, bottom right.
static func equipped_badge(parent: Control, col: Color = CYAN, text: String = "E") -> void:
	var b := Panel.new()
	b.name = "EBadge"
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := StyleBoxFlat.new()
	s.bg_color = Color(col, 0.85)
	s.set_corner_radius_all(4)
	s.border_color = Color(1, 1, 1, 0.35)
	s.set_border_width_all(1)
	b.add_theme_stylebox_override("panel", s)
	b.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	b.offset_left = -22.0
	b.offset_right = -4.0
	b.offset_top = -22.0
	b.offset_bottom = -4.0
	var l := label(text, 10, Color(0.05, 0.08, 0.14), HORIZONTAL_ALIGNMENT_CENTER)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	b.add_child(l)
	parent.add_child(b)

# ---- one look for every pop-up title and sub-tab row (consistency pass, 2026-11-10) ----
# A pop-up's title: Oxanium, white, centred, the same on every page (they were a mix of gold
# Inter capitals and gold Oxanium).
static func popup_title(text: String) -> Label:
	return title(text, 20, TEXT, HORIZONTAL_ALIGNMENT_CENTER)

# A row of SUB-TABS under a page's main tab strip: dark pills, the open one lighter. One style for
# the Workshop (Parts / Gear / Craft), the Shop sections and the Collection categories, so a
# second white strip never sits under the first. `dots` = red dots by index. tab_dots() works on it.
static func sub_tabs(names: Array, selected: int, on_pick: Callable, dots: Array = []) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var map: Array = []
	for i in names.size():
		var b := Button.new()
		b.text = String(names[i])
		b.custom_minimum_size = Vector2(0, 36)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 13)
		var on: bool = i == selected
		var sb := pill(CARD_HI if on else Color(CARD, 0.6), 18, Vector2(8, 2))
		for st in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(st, sb)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		for c in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(c, TEXT if on else SOFT)
		var k: int = i
		b.pressed.connect(func(): on_pick.call(k))
		press_fx(b)
		row.add_child(b)
		map.append(i)
	row.set_meta("tab_map", map)
	tab_dots(row, dots)
	return row
