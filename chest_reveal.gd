class_name ChestReveal
extends RefCounted
# OPENING A CHEST (Rudy, dev265: "it just does a little ping and names what you collected; it
# should be a cool animation, then the items shown, bigger for the better chests, and an Epic or
# Legendary item hesitates, glowing, before it unlocks").
# ChestReveal.show(host, tier, reward, on_close): full screen. Rays in the chest's colour turn
# behind it; the chest shakes (longer for a better chest), the lid lifts with a flash, then the
# items come out as cards one by one. A card of Epic rarity or better arrives FACE DOWN, glows
# and trembles for a beat, then flips. When every card is up: tap to continue.
# reward = what Store.chest_open_in returned: totals + "items" [{k, n, rarity, gear?}] + "pity".

const TIER_COL := {"u": Color(0.3, 0.75, 1.0), "e": Color(0.75, 0.5, 1.0), "l": Color(1.0, 0.8, 0.3)}
const WIND := {"u": 0.5, "e": 0.85, "l": 1.25}     # seconds of shaking before the lid lifts
const RANK := ["common", "uncommon", "rare", "epic", "legendary"]

static func icon_of(item: Dictionary) -> Texture2D:
	var k := String(item.get("k", ""))
	if k == "coins":
		return UIKit.ic("ic_coin", "ui_coin")
	if k == "crystals":
		return UIKit.ic("ic_crystal", "ui_crystal")
	if k == "gear":
		var id := String(Dictionary(item.get("gear", {})).get("id", ""))
		for p in ["res://gear/%s_t1.png" % id, "res://gear/%s.png" % id]:
			if ResourceLoader.exists(p):
				return load(p)
		return UIKit.ic("ic_pack")
	return Materials.icon(k) if Materials.is_material(k) else Parts.icon(k)

static func name_of(item: Dictionary) -> String:
	var k := String(item.get("k", ""))
	if k == "coins":
		return "Coins"
	if k == "crystals":
		return "Crystals"
	if k == "gear":
		var id := String(Dictionary(item.get("gear", {})).get("id", ""))
		return String(GearData.ITEMS[id].name) if GearData.ITEMS.has(id) else "Gear"
	return String(Parts.kind(k).name)

# the same kind and rarity folded into one card (ten chests at once), gear kept apart; best last
static func merged(items: Array) -> Array:
	var out: Array = []
	var at := {}
	for it in items:
		var k := String(it.get("k", ""))
		var key := "%s/%s" % [k, String(it.get("rarity", "common"))]
		if k != "gear" and at.has(key):
			out[at[key]]["n"] = int(out[at[key]].n) + int(it.get("n", 0))
			continue
		if k != "gear":
			at[key] = out.size()
		out.append(Dictionary(it).duplicate())
	out.sort_custom(func(a, b): return RANK.find(String(a.get("rarity", "common"))) < RANK.find(String(b.get("rarity", "common"))))
	return out

static func show(host: Control, tier: String, reward: Dictionary, on_close: Callable = Callable()) -> void:
	var items := merged(Array(reward.get("items", [])))
	if items.is_empty():   # an old-style reward: one card per key
		for k in reward:
			if k != "pity" and k != "items" and k != "gear":
				items.append({"k": k, "n": int(reward[k]), "rarity": "common"})
	var col: Color = TIER_COL.get(tier, Color(0.3, 0.75, 1.0))
	var wind: float = float(WIND.get(tier, 0.5))
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.z_index = 60
	host.add_child(layer)
	var dim := Button.new()   # swallows every tap until the reveal is done
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.008, 0.016, 0.04, 0.93)
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		dim.add_theme_stylebox_override(st, ds)
	layer.add_child(dim)
	layer.modulate.a = 0.0
	layer.create_tween().tween_property(layer, "modulate:a", 1.0, 0.18)
	var w: float = host.size.x
	var h: float = host.size.y
	var chest_c := Vector2(w * 0.5, h * 0.27)
	# turning rays behind the chest: more of them, wider and brighter for a better chest
	var rays := Rays.new()
	rays.col = col
	rays.count = {"u": 10, "e": 14, "l": 18}.get(tier, 10)
	rays.reach = {"u": 190.0, "e": 240.0, "l": 300.0}.get(tier, 190.0)
	rays.position = chest_c
	rays.modulate.a = 0.0
	rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rays)
	# the chest
	var chest: Control
	var csz := 210.0 if tier == "l" else 190.0
	if tier != "" and HomeProp.has_tier(tier):
		var hp := HomeProp.new()
		hp.kind = "chest"
		hp.tier = tier
		chest = hp
	else:
		var hp2 := HomeProp.new()
		hp2.kind = "chest"
		chest = hp2
	chest.size = Vector2(csz, csz)
	chest.position = chest_c - Vector2(csz * 0.5, csz * 0.55)
	chest.pivot_offset = Vector2(csz * 0.5, csz * 0.8)
	chest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(chest)
	if bool(reward.get("pity", false)):
		var pl := UIKit.title("PITY ITEM", 18, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		pl.position = Vector2(0, chest_c.y - csz * 0.75)
		pl.size = Vector2(w, 24)
		layer.add_child(pl)
	# 1. the wind-up: it shakes harder and harder
	var tw := layer.create_tween()
	tw.tween_interval(0.2)
	var shakes: int = int(wind / 0.09)
	for i in shakes:
		var k: float = float(i + 1) / float(shakes)
		tw.tween_property(chest, "rotation", (0.05 + 0.07 * k) * (1.0 if i % 2 == 0 else -1.0), 0.045)
		tw.parallel().tween_property(chest, "scale", Vector2(1.0 + 0.06 * k, 1.0 - 0.04 * k), 0.045)
		tw.tween_property(chest, "rotation", 0.0, 0.045)
		if i % 3 == 0:
			tw.tween_callback(func(): Sfx.play("tap", 0.8 + 0.5 * k))
	tw.parallel().tween_property(rays, "modulate:a", 0.5, wind)
	# 2. the lid lifts: a flash, the rays flare
	tw.tween_callback(func():
		chest.call("open", true)
		Sfx.play("merge" if tier != "u" else "claim")
		var flash := ColorRect.new()
		flash.color = Color(col.lightened(0.6), 0.55 if tier == "l" else 0.3)
		flash.set_anchors_preset(Control.PRESET_FULL_RECT)
		flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(flash)
		var ft := flash.create_tween()
		ft.tween_property(flash, "modulate:a", 0.0, 0.45)
		ft.tween_callback(flash.queue_free))
	tw.tween_property(chest, "scale", Vector2(1.14, 1.14), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(rays, "modulate:a", 1.0, 0.15)
	tw.tween_property(chest, "scale", Vector2.ONE, 0.3)
	tw.tween_interval(0.25)
	# 3. the cards
	var cols: int = 3 if items.size() <= 9 else 4
	var cw: float = minf((w - 32.0 - 10.0 * (cols - 1)) / cols, 132.0)
	var ch: float = cw * 1.22
	var rows: int = ceili(float(items.size()) / cols)
	var top: float = minf(h * 0.47, h - 86.0 - rows * (ch + 10.0))
	var grid_w: float = cols * cw + (cols - 1) * 10.0
	var delay := 0.2 + wind + 0.75   # the cards wait for the lid
	var cards: Array = []
	for i in items.size():
		var it: Dictionary = items[i]
		var row_n: int = mini(cols, items.size() - (i / cols) * cols)   # the last row is centred
		var row_w: float = row_n * cw + (row_n - 1) * 10.0
		var pos := Vector2((w - row_w) * 0.5 + (i % cols) * (cw + 10.0), top + (i / cols) * (ch + 10.0))
		var card := _card(it, Vector2(cw, ch))
		card.position = pos
		card.pivot_offset = Vector2(cw, ch) * 0.5
		card.scale = Vector2(0.2, 0.2)
		card.modulate.a = 0.0
		layer.add_child(card)
		cards.append(card)
		var rare: bool = RANK.find(String(it.get("rarity", "common"))) >= 3
		var rc: Color = GearData.RARITY.get(String(it.get("rarity", "common")), GearData.RARITY.common).color
		var face: Control = card.get_node("Face")
		var back: Control = card.get_node("Back")
		face.visible = not rare
		back.visible = rare
		var ct := card.create_tween()
		ct.tween_interval(delay)
		ct.tween_callback(func(): Sfx.play("coin", 1.0 + 0.05 * float(i)))
		ct.tween_property(card, "modulate:a", 1.0, 0.12)
		ct.parallel().tween_property(card, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		delay += 0.2
		if rare:
			# the hesitation: face down, trembling and glowing brighter, then the flip
			var hold: float = 0.9 if String(it.rarity) == "epic" else 1.3
			var n_tr: int = int(hold / 0.08)
			for j in n_tr:
				var kk: float = float(j + 1) / float(n_tr)
				ct.tween_property(card, "rotation", 0.05 * kk * (1.0 if j % 2 == 0 else -1.0), 0.04)
				ct.parallel().tween_property(back, "modulate", Color(1.0 + 0.9 * kk, 1.0 + 0.9 * kk, 1.0 + 0.9 * kk), 0.04)
				ct.tween_property(card, "rotation", 0.0, 0.04)
			ct.tween_property(card, "scale:x", 0.0, 0.1)
			ct.tween_callback(func():
				back.visible = false
				face.visible = true
				Sfx.play("level")
				var ring := Rays.new()
				ring.col = rc
				ring.count = 12
				ring.reach = cw * 1.1
				ring.burst = true
				ring.position = card.position + card.pivot_offset
				ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
				layer.add_child(ring)
				layer.move_child(ring, card.get_index()))
			ct.tween_property(card, "scale:x", 1.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			ct.parallel().tween_property(card, "scale:y", 1.12, 0.1)
			ct.tween_property(card, "scale:y", 1.0, 0.15)
			delay += hold + 0.45
	# 4. done: tap to continue
	var tip := UIKit.title("TAP TO CONTINUE", 14, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	tip.position = Vector2(0, h - 56.0)
	tip.size = Vector2(w, 22)
	tip.modulate.a = 0.0
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(tip)
	var total_t: float = delay + 0.3
	var done := [false]
	var endt := layer.create_tween()
	endt.tween_interval(total_t)
	endt.tween_callback(func(): done[0] = true)
	endt.tween_property(tip, "modulate:a", 1.0, 0.3)
	dim.pressed.connect(func():
		if not done[0]:
			return
		done[0] = false
		var out := layer.create_tween()
		out.tween_property(layer, "modulate:a", 0.0, 0.2)
		out.tween_callback(func():
			layer.queue_free()
			if on_close.is_valid():
				on_close.call()))

static func _card(it: Dictionary, sz: Vector2) -> Control:
	var rarity := String(it.get("rarity", "common"))
	var rc: Color = GearData.RARITY.get(rarity, GearData.RARITY.common).color
	var card := Control.new()
	card.size = sz
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var face := PanelContainer.new()
	face.name = "Face"
	face.set_anchors_preset(Control.PRESET_FULL_RECT)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_theme_stylebox_override("panel", UIKit.box(Color(rc.r * 0.16 + 0.03, rc.g * 0.16 + 0.04, rc.b * 0.16 + 0.07, 0.98), Color(rc, 0.9), 18, 2))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 3)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tr := TextureRect.new()
	tr.texture = icon_of(it)
	tr.custom_minimum_size = Vector2(0, sz.y * 0.44)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(tr)
	var amount := UIKit.title("x%s" % UIKit.num(int(it.get("n", 1))) if String(it.get("k", "")) != "gear" else String(GearData.RARITY.get(rarity, GearData.RARITY.common).name), 17, UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(amount)
	var nm := UIKit.label(name_of(it), 11, rc.lightened(0.25), HORIZONTAL_ALIGNMENT_CENTER)
	nm.clip_text = true
	v.add_child(nm)
	face.add_child(v)
	card.add_child(face)
	var back := PanelContainer.new()
	back.name = "Back"
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_theme_stylebox_override("panel", UIKit.box(Color(rc.r * 0.3, rc.g * 0.3, rc.b * 0.3, 0.98), rc, 18, 3))
	var q := UIKit.title("?", 40, rc.lightened(0.4), HORIZONTAL_ALIGNMENT_CENTER)
	q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	back.add_child(q)
	card.add_child(back)
	return card

# turning rays of light (behind the chest), or one outward burst (behind a card as it flips)
class Rays extends Control:
	var col := Color.WHITE
	var count := 12
	var reach := 200.0
	var burst := false
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		if burst and t > 0.6:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k: float = clampf(t / 0.6, 0.0, 1.0) if burst else 0.0
		var r0: float = reach * (0.3 + 0.5 * k) if burst else 24.0
		var r1: float = reach * (0.7 + 0.6 * k) if burst else reach * (0.92 + 0.08 * sin(t * 2.0))
		var a: float = (1.0 - k) * 0.6 if burst else 0.2
		for i in count:
			var ang: float = TAU * float(i) / float(count) + (0.0 if burst else t * 0.35)
			var half: float = (0.05 if burst else 0.11) * (1.0 if i % 2 == 0 else 0.6)
			var p0 := Vector2.from_angle(ang) * r0
			draw_polygon(PackedVector2Array([p0, Vector2.from_angle(ang - half) * r1, Vector2.from_angle(ang + half) * r1]),
				PackedColorArray([Color(col, a), Color(col, 0.0), Color(col, 0.0)]))
		if not burst:
			draw_circle(Vector2.ZERO, reach * 0.34, Color(col, 0.07))
