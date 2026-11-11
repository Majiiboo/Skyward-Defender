extends Control
# The SEASON PASS page (Season, 2026-11-10). A head card (the season's name, time left, your tier
# and the bar to the next one), ONE gold button (CLAIM what is waiting, or the premium unlock when
# nothing waits), then the thirty tiers as rows: number, the free reward, the premium reward.
# It opens scrolled to the tier you are on.

var d := {}
var _col: VBoxContainer
var _scroll: ScrollContainer
var _here: Control = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	MenuBackdrop.add_to(self)
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left", "margin_right"]:
		root.add_theme_constant_override(m, 12)
	root.add_theme_constant_override("margin_top", 10 + int(SafeAreaMargin.top_inset(get_viewport())))
	root.add_theme_constant_override("margin_bottom", 16)
	add_child(root)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	root.add_child(outer)
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 10)
	outer.add_child(_col)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(_scroll)
	_fill()
	UIKit.enter(self)
	Hints.show(self, ["season"])

func _ricon(k: String) -> Texture2D:
	match k:
		"coins": return UIKit.ic("ic_coin")
		"crystals": return UIKit.ic("ic_crystal")
		"key_u": return UIKit.ic("mat_key_u")
		"key_e": return UIKit.ic("mat_key_e")
	return Parts.icon(k)

# a reward as small icon + number pairs
func _reward_box(reward: Dictionary, dim: bool) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := UIKit.SOFT if dim else UIKit.TEXT
	for k in reward:
		if typeof(reward[k]) == TYPE_INT or typeof(reward[k]) == TYPE_FLOAT:
			h.add_child(UIKit.iconed(_ricon(String(k)), UIKit.num(int(reward[k])), 12, col, 18.0))
		elif String(k) == "shards":
			var n := 0
			for hid in reward[k]:
				n += int(reward[k][hid])
			h.add_child(UIKit.iconed(UIKit.ic("mat_shard", "ic_shard"), str(n), 12, col, 18.0))
	if dim:
		h.modulate = Color(1, 1, 1, 0.55)
	return h

func _fill() -> void:
	d = Progress.read()
	for c in _col.get_children():
		_col.remove_child(c)
		c.queue_free()
	for c in _scroll.get_children():
		_scroll.remove_child(c)
		c.queue_free()
	var st := Season.state(d)
	var tier := Season.tier(d)
	var prem: bool = bool(st.premium)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	var back := UIKit.ghost_button("Back")
	back.custom_minimum_size = Vector2(70, 32)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://hub.tscn"))
	top.add_child(back)
	top.add_child(UIKit.screen_title("SEASON"))
	_col.add_child(top)
	# the head card
	var card := UIKit.panel(22)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var big := UIKit.title(str(tier), 40, UIKit.GOLD)
	big.custom_minimum_size = Vector2(56, 0)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(big)
	var nv := VBoxContainer.new()
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nv.add_theme_constant_override("separation", 3)
	nv.add_child(UIKit.title(Season.name_of(), 20, UIKit.TEXT))
	nv.add_child(UIKit.label("Tier %d of %d  ·  ends in %s" % [tier, Season.TIERS, Season.left_text()], 12, UIKit.SOFT))
	h.add_child(nv)
	if prem:
		h.add_child(UIKit.chip("Premium", UIKit.GOLD))
	v.add_child(h)
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, 10)
	var share: float = float(Season.tier_xp(d)) / Season.TIER_XP
	bar.draw.connect(func():
		bar.draw_style_box(UIKit.pill(Color(1, 1, 1, 0.08), 5, Vector2.ZERO), Rect2(Vector2.ZERO, bar.size))
		if share > 0.0:
			bar.draw_style_box(UIKit.pill(UIKit.CYAN, 5, Vector2.ZERO), Rect2(0, 0, maxf(bar.size.x * share, 10.0), bar.size.y)))
	v.add_child(bar)
	var note := "Every tier is yours." if tier >= Season.TIERS else "%d / %d season XP to tier %d. Every fight and daily quest pays." % [Season.tier_xp(d), Season.TIER_XP, tier + 1]
	v.add_child(UIKit.label(note, 11, UIKit.SOFT))
	# the one gold button
	var wait := Season.waiting(d)
	if wait > 0:
		var go := UIKit.gold_button("CLAIM %d REWARD%s" % [wait, "" if wait == 1 else "S"], 17)
		go.custom_minimum_size = Vector2(0, 52)
		go.pressed.connect(_on_claim)
		v.add_child(go)
	elif not prem:
		var up := UIKit.gold_button("UNLOCK PREMIUM  ·  %d crystals" % Season.PREMIUM_COST, 15)
		up.custom_minimum_size = Vector2(0, 52)
		up.pressed.connect(_on_premium)
		v.add_child(up)
	if not prem and wait > 0:
		var up2 := UIKit.ghost_button("Unlock the premium track  ·  %d crystals" % Season.PREMIUM_COST, 12)
		up2.pressed.connect(_on_premium)
		v.add_child(up2)
	_col.add_child(card)
	# column names
	var names := HBoxContainer.new()
	names.add_theme_constant_override("separation", 8)
	var n0 := UIKit.label("Tier", 11, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	n0.custom_minimum_size = Vector2(44, 0)
	names.add_child(n0)
	for nm in ["Free", "Premium"]:
		var nl := UIKit.label(nm, 11, UIKit.GOLD if nm == "Premium" else UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		names.add_child(nl)
	_col.add_child(names)
	# the tiers
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	_scroll.add_child(list)
	_here = null
	for t in range(1, Season.TIERS + 1):
		var reached: bool = t <= tier
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var num := Control.new()
		num.custom_minimum_size = Vector2(44, 44)
		var tn := t
		num.draw.connect(func():
			var c := Vector2(22, 22)
			if reached:
				num.draw_circle(c, 17.0, UIKit.CYAN)
			else:
				num.draw_arc(c, 16.0, 0.0, TAU, 32, Color(1, 1, 1, 0.2), 1.5, true)
			num.draw_string(UIKit.title_font(), Vector2(0, 28.0), str(tn), HORIZONTAL_ALIGNMENT_CENTER, 44.0, 15, UIKit.GOLD_INK if reached else UIKit.SOFT))
		row.add_child(num)
		for track in 2:
			var is_p: bool = track == 1
			var taken: bool = t <= int(st.prem if is_p else st.free)
			var ready: bool = reached and not taken and (prem or not is_p)
			var cell := PanelContainer.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.custom_minimum_size = Vector2(0, 44)
			var edge := Color(1, 1, 1, 0.05)
			if ready:
				edge = UIKit.GOLD
			elif is_p and not taken:
				edge = Color(UIKit.GOLD, 0.25)
			cell.add_theme_stylebox_override("panel", UIKit.box(Color(UIKit.CARD_HI, 0.6 if not taken else 0.25), edge, 14, 1))
			var inner := HBoxContainer.new()
			inner.alignment = BoxContainer.ALIGNMENT_CENTER
			inner.add_theme_constant_override("separation", 8)
			inner.add_child(_reward_box(Season.reward(t, is_p, d), taken or (is_p and not prem)))
			if taken:
				inner.add_child(UIKit.label("Taken", 10, UIKit.SOFT))
			cell.add_child(inner)
			row.add_child(cell)
		list.add_child(row)
		if t == clampi(tier, 1, Season.TIERS):
			_here = row
	UIKit.reveal(_col)
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(_here):
		_scroll.scroll_vertical = maxi(int(_here.position.y) - 60, 0)

func _on_claim() -> void:
	d = Progress.read()
	var got := Season.claim_all(d)
	if got.is_empty():
		return
	Progress.write(d)
	Sfx.play("coin")
	var total := {}
	for r in got:
		for k in r:
			if typeof(r[k]) == TYPE_INT or typeof(r[k]) == TYPE_FLOAT:
				total[k] = int(total.get(k, 0)) + int(r[k])
	_toast("+ " + Progress.reward_text(total) + ("" if got.size() < 2 else "  (%d rewards)" % got.size()))
	_fill()

func _on_premium() -> void:
	d = Progress.read()
	var why := Season.unlock_premium(d)
	if why != "":
		_toast(why)
		return
	Progress.write(d)
	Sfx.play("level")
	_toast("Premium track unlocked for this season")
	_fill()

func _toast(text: String) -> void:
	var l := UIKit.label(text, 13, UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.pill(Color(0.02, 0.04, 0.09, 0.95), 16, Vector2(16, 10)))
	p.add_child(l)
	p.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN
	p.offset_bottom = -40.0
	p.custom_minimum_size = Vector2(300, 0)
	add_child(p)
	var tw := p.create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)
