class_name HeroCards
extends RefCounted
# THE HERO S CARD PAGE (2026-11-18, Rudy: "a card page per hero, in tiers"). A bottom sheet on the
# Heroes screen for the hero being looked at: TIER 1 his basic cards (his own first), TIER 2 his
# evolutions, each a small gradient tile in the card s colour (orange attack, blue defence, green
# passive, gold-pink evolution: no type word, the colour says it). A card that opens at a higher
# hero level is dimmed with a padlock and "Lv.n". A tap on a tile names it and says what it does
# in the panel at the foot. HeroCards.show(host, hero_id, save). The rules live in cards.gd
# (UNLOCK, EVO_UNLOCK, is_hero_card, unlock_level); this file only shows them.

const COLS := 5
const TILE := Vector2(82, 98)
const GOLD := Color(1.0, 0.82, 0.32)
const LOCK_COL := Color(0.78, 0.83, 0.92)

# the basic cards of this hero, his own first, then by the level they open at
static func basics(hero_id: String) -> Array:
	var own := Cards.hero_card(hero_id)
	var out: Array = []
	for id in Cards.CARDS:
		var d: Dictionary = Cards.CARDS[id]
		if not Cards.is_hero_card(String(id)) or d.has("talent") or String(id) == own:
			continue
		if d.has("hero") and String(d.hero) != hero_id:
			continue
		out.append(String(id))
	var order: Array = Cards.CARDS.keys()
	out.sort_custom(func(a, b):
		var la := Cards.unlock_level(a)
		var lb := Cards.unlock_level(b)
		return la < lb if la != lb else order.find(a) < order.find(b))
	if own != "":
		out.push_front(own)
	return out

# his evolutions: his own signature and every shared one, by the level they open at
static func evolutions(hero_id: String) -> Array:
	var out: Array = []
	for f in Cards.FUSIONS:
		if String(f).begins_with("sig_") and String(f) != "sig_" + hero_id:
			continue
		out.append(String(f))
	var order: Array = Cards.FUSIONS.keys()
	out.sort_custom(func(a, b):
		var la := Cards.unlock_level(a)
		var lb := Cards.unlock_level(b)
		if la != lb:
			return la < lb
		var sa := String(a).begins_with("sig_")
		if sa != String(b).begins_with("sig_"):
			return sa   # his own first among the ones open from the start
		return order.find(a) < order.find(b))
	return out

# "" when the card is open for him now, else the short word for the tile ("Lv.8", "Drone")
static func lock_note(id: String, hero_level: int, has_drone: bool) -> String:
	if Cards.unlock_level(id) > hero_level:
		return "Lv.%d" % Cards.unlock_level(id)
	if (id == "drone_barrage" or id == "guardian_wing") and not has_drone:
		return "Drone"
	return ""

# the same thing in a sentence, for the panel at the foot
static func lock_text(id: String, hero_level: int, has_drone: bool) -> String:
	var parts: Array = []
	if Cards.unlock_level(id) > hero_level:
		parts.append("Opens at hero Lv.%d" % Cards.unlock_level(id))
	if (id == "drone_barrage" or id == "guardian_wing") and not has_drone:
		parts.append("Needs a drone")
	return "  ·  ".join(PackedStringArray(parts))

# the picture: Luna s own when painted, else what the card borrows; an evolution without one
# shows the card it grew from (as the pick in the fight does)
static func pic(id: String) -> Texture2D:
	var own := "res://cards/pic_%s.png" % id
	if ResourceLoader.exists(own):
		return load(own)
	if Cards.FUSIONS.has(id):
		return pic(String(Cards.FUSIONS[id].parts[0]))
	var path := String(Cards.def(id).get("pic", ""))
	return load(path) if path != "" and ResourceLoader.exists(path) else null

static func color_of(id: String) -> Color:
	return Cards.COLOR.fusion if Cards.FUSIONS.has(id) else Cards.TYPE_COLOR[Cards.type_of(id)]

# one tile: a gradient box (the colour bright at the top sinking to navy, like the pick in the
# fight), the picture, the name under it; a locked one dimmed under a padlock and its note
static func _tile(id: String, note: String) -> Button:
	var fusion := Cards.FUSIONS.has(id)
	var locked := note != ""
	var edge := color_of(id)
	var b := Button.new()
	b.custom_minimum_size = TILE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.clip_contents = true
	b.add_theme_stylebox_override("normal", UIKit.box(Color(0, 0, 0, 0), Color(edge, 0.3 if locked else 0.9), 12.0, 1 if locked else 2))
	b.add_theme_stylebox_override("hover", UIKit.box(Color(1, 1, 1, 0.03), Color(edge, 0.45 if locked else 1.0), 12.0, 1 if locked else 2))
	b.add_theme_stylebox_override("pressed", UIKit.box(Color(1, 1, 1, 0.1), Color.WHITE, 12.0, 2))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var grad := Control.new()
	grad.set_anchors_preset(Control.PRESET_FULL_RECT)
	grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grad.show_behind_parent = true
	var foot := Color(0.09, 0.05, 0.15) if fusion else Color(0.04, 0.065, 0.12)
	var stops: Array = [[0.0, (GOLD if fusion else edge).lerp(Color.WHITE, 0.1)], [0.24, edge.darkened(0.42)], [0.6, foot.lerp(edge, 0.16)], [1.0, foot]]
	var fade: float = 0.3 if locked else 1.0
	grad.draw.connect(func():
		var w: float = grad.size.x
		var h: float = grad.size.y
		var rad := 11.0
		var y := 1.0
		while y < h - 1.0:
			var y2: float = minf(y + 3.0, h - 1.0)
			var cols: Array = []
			for yy in [y, y2]:
				var u: float = yy / h
				var c: Color = stops[-1][1]
				for k in stops.size() - 1:
					if u <= float(stops[k + 1][0]):
						c = (stops[k][1] as Color).lerp(stops[k + 1][1], (u - float(stops[k][0])) / (float(stops[k + 1][0]) - float(stops[k][0])))
						break
				cols.append(foot.lerp(c, fade))   # a locked tile keeps only a breath of its colour
			var ym: float = (y + y2) * 0.5
			var dy: float = maxf(rad - ym, ym - (h - rad))
			var inset: float = 1.0 + (rad - sqrt(maxf(rad * rad - dy * dy, 0.0)) if dy > 0.0 else 0.0)
			grad.draw_polygon(PackedVector2Array([Vector2(inset, y), Vector2(w - inset, y), Vector2(w - inset, y2), Vector2(inset, y2)]), PackedColorArray([cols[0], cols[0], cols[1], cols[1]]))
			y = y2)
	b.add_child(grad)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 6   # names touched the tile edges at 3
	v.offset_right = -6
	v.offset_top = 7
	v.offset_bottom = -4
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var icon := TextureRect.new()
	icon.texture = pic(id)
	icon.custom_minimum_size = Vector2(0, 46)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if id == "nova_burst":
		var add := CanvasItemMaterial.new()
		add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD   # painted as light on black
		icon.material = add
	if locked:
		icon.modulate = Color(0.55, 0.6, 0.7, 0.14)
	v.add_child(icon)
	var name_l := UIKit.label(String(Cards.def(id).name), 11, Color(1, 1, 1, 0.5) if locked else Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_l.max_lines_visible = 2
	name_l.add_theme_constant_override("line_spacing", -3)
	name_l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(name_l)
	if locked:
		# the padlock and its note sit over the dimmed picture
		var lock := VBoxContainer.new()
		lock.set_anchors_preset(Control.PRESET_TOP_WIDE)
		lock.offset_top = 8
		lock.offset_bottom = 54
		lock.alignment = BoxContainer.ALIGNMENT_CENTER
		lock.add_theme_constant_override("separation", 0)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pl := TextureRect.new()
		pl.texture = UIKit.ic("ui_padlock")
		pl.custom_minimum_size = Vector2(0, 24)
		pl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pl.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pl.modulate = LOCK_COL
		pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock.add_child(pl)
		var nl := UIKit.title(note, 13, LOCK_COL, HORIZONTAL_ALIGNMENT_CENTER)
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock.add_child(nl)
		b.add_child(lock)
	# the ring of the tile you tapped
	var ring := Panel.new()
	ring.name = "Ring"
	ring.set_anchors_preset(Control.PRESET_FULL_RECT)
	ring.add_theme_stylebox_override("panel", UIKit.box(Color(1, 1, 1, 0.05), Color.WHITE, 12.0, 2))
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.visible = false
	b.add_child(ring)
	UIKit.press_fx(b)
	return b

static func _head(text: String, count: String, col: Color) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var bar := ColorRect.new()
	bar.color = col
	bar.custom_minimum_size = Vector2(3, 14)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(bar)
	var t := UIKit.title(text, 14, UIKit.TEXT)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	h.add_child(UIKit.label(count, 12, UIKit.SOFT))
	return h

static func show(host: Control, hero_id: String, save: Dictionary) -> Control:
	var hs := Heroes.read(save)
	var lvl: int = 99 if DevTools.on else Heroes.level(hs, hero_id)
	var has_drone := DroneData.unlocked(Turrets.pilot_level(int(save.get("pilot_xp", 0))))
	var layer := Control.new()
	layer.name = "HeroCards"
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(layer)
	var dim := Button.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.01, 0.024, 0.055, 0.66)
	for st in ["normal", "hover", "pressed", "focus"]:
		dim.add_theme_stylebox_override(st, ds)
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
	ss.content_margin_left = 16
	ss.content_margin_right = 16
	ss.content_margin_top = 14
	ss.content_margin_bottom = 20
	sheet.add_theme_stylebox_override("panel", ss)
	sheet.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	slider.add_child(sheet)
	dim.modulate.a = 0.0
	dim.create_tween().tween_property(dim, "modulate:a", 1.0, 0.2)
	slider.position.y = 700.0
	slider.create_tween().tween_property(slider, "position:y", 0.0, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	sheet.add_child(v)
	# the title: his name, and the one rule worth knowing
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 8)
	var el := TextureRect.new()
	el.texture = UIKit.element_icon(Heroes.element_of(hero_id))
	el.custom_minimum_size = Vector2(22, 22)
	el.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	el.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top.add_child(el)
	top.add_child(UIKit.popup_title("%s  ·  Cards" % String(Heroes.ROSTER[hero_id].name)))
	if not DevTools.on:
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", UIKit.pill(UIKit.CARD_HI, 12, Vector2(9, 2)))
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		chip.add_child(UIKit.title("Lv.%d" % lvl, 12, UIKit.CYAN))
		top.add_child(chip)
	v.add_child(top)
	v.add_child(UIKit.label("Any three hero cards in a fight earn an evolution.", 12, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	# the two tiers, in a scroll box so a short phone still reaches the foot
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 7)
	sc.add_child(inner)
	v.add_child(sc)
	var b_ids := basics(hero_id)
	var e_ids := evolutions(hero_id)
	var open_b := 0
	var open_e := 0
	for id in b_ids:
		open_b += 1 if lock_note(id, lvl, has_drone) == "" else 0
	for id in e_ids:
		open_e += 1 if lock_note(id, lvl, has_drone) == "" else 0
	# the panel at the foot: the tapped card s name, what it does, and what opens it
	var info := PanelContainer.new()
	info.add_theme_stylebox_override("panel", UIKit.box(Color(UIKit.CARD_HI, 0.55), Color(1, 1, 1, 0.05), 14, 1))
	info.custom_minimum_size = Vector2(0, 62)
	var im := MarginContainer.new()
	im.add_theme_constant_override("margin_left", 12)
	im.add_theme_constant_override("margin_right", 12)
	im.add_theme_constant_override("margin_top", 7)
	im.add_theme_constant_override("margin_bottom", 7)
	info.add_child(im)
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", 1)
	iv.alignment = BoxContainer.ALIGNMENT_CENTER
	im.add_child(iv)
	var ih := HBoxContainer.new()
	ih.add_theme_constant_override("separation", 8)
	var i_name := UIKit.title("", 15, UIKit.TEXT)
	i_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ih.add_child(i_name)
	var i_lock := UIKit.label("", 12, UIKit.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	ih.add_child(i_lock)
	iv.add_child(ih)
	var i_desc := UIKit.label("", 12, UIKit.SOFT)
	i_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	iv.add_child(i_desc)
	var tiles := {}
	var pick := func(id: String):
		for k in tiles:
			(tiles[k] as Button).get_node("Ring").visible = k == id
		i_name.text = String(Cards.def(id).name)
		i_name.add_theme_color_override("font_color", color_of(id).lerp(Color.WHITE, 0.25))
		i_desc.text = String(Cards.def(id).desc)
		i_lock.text = lock_text(id, lvl, has_drone)
	for tier in [["Basic cards", b_ids, open_b, Cards.TYPE_COLOR.off], ["Evolutions", e_ids, open_e, Cards.COLOR.fusion]]:
		var ids: Array = tier[1]
		inner.add_child(_head(String(tier[0]), "%d of %d open" % [int(tier[2]), ids.size()], tier[3]))
		var grid := GridContainer.new()
		grid.columns = COLS
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		for id in ids:
			var t := _tile(id, lock_note(id, lvl, has_drone))
			t.pressed.connect(pick.bind(id))
			tiles[id] = t
			grid.add_child(t)
		for i in (COLS - ids.size() % COLS) % COLS:   # fill the last row so its tiles keep their width
			var gap := Control.new()
			gap.custom_minimum_size = TILE
			gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
			grid.add_child(gap)
		inner.add_child(grid)
	UIKit.smooth_scroll(sc)
	var fit := func():
		if is_instance_valid(sc) and is_instance_valid(host):
			sc.custom_minimum_size.y = minf(inner.get_combined_minimum_size().y, maxf(host.size.y - 250.0, 200.0))
	inner.minimum_size_changed.connect(fit)
	fit.call()
	v.add_child(info)
	v.add_child(UIKit.label("%d of %d cards open  ·  %d of %d evolutions" % [open_b, b_ids.size(), open_e, e_ids.size()], 12, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	if not b_ids.is_empty():
		pick.call(b_ids[0])
	return layer
