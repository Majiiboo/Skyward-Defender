class_name Welcome
extends RefCounted
# WELCOME BACK (2026-11-10). When you open the game after AWAY_S or more away, Home shows one
# sheet: how long you were gone, a small gift for every day away (up to MAX_DAYS), and the list
# of what is waiting (Patrol loot, finished research, the free chest, the free spin, today's
# challenge, season rewards, quests). It ties the come-back systems together so nothing is missed.
# Save "last_seen": unix seconds of the last time Home opened.
#   Welcome.check(save) -> {} or {"away_s", "gift", "items"} (it stamps last_seen and grants the gift)
#   Welcome.show(host, info)

const AWAY_S := 4 * 3600
const GIFT_FROM_S := 20 * 3600
const MAX_DAYS := 3
const GIFT_DAY := {"coins": 300, "crystals": 5}

static func gift_for(away_s: int) -> Dictionary:
	if away_s < GIFT_FROM_S:
		return {}
	var days := clampi(int(floor(away_s / 86400.0 + 0.2)), 1, MAX_DAYS)
	return {"coins": int(GIFT_DAY.coins) * days, "crystals": int(GIFT_DAY.crystals) * days}

# what is waiting right now: [[icon name, text], ...]
static func items(save: Dictionary) -> Array:
	var out: Array = []
	var at := Progress.attention(save)
	if bool(at.patrol):
		out.append(["tab_drone", "Patrol has loot to collect"])
	if Research.ready(save):
		out.append(["st_aim", "Research is done"])
	elif Research.idle(save):
		out.append(["st_aim", "The research lab is free"])
	if load("res://store.gd").free_waiting(save):
		out.append(["ic_chest_u", "A free chest is waiting"])
	if Spin.free_ready(save):
		out.append(["ic_gift", "Your free spin is ready"])
	if Promotion.daily_open(save) and not Promotion.daily_done(save):
		out.append(["tab_daily", "A new Daily Challenge"])
	if Season.claimable(save):
		out.append(["tab_trophies", "Season rewards to claim"])
	if bool(at.quests):
		out.append(["tab_career", "Quests to claim"])
	if Events.open(save):
		out.append(["event", "%s: ends in %s" % [String(Events.theme().name), Events.left_text()]])
	return out

static func check(save: Dictionary) -> Dictionary:
	var now := int(Time.get_unix_time_from_system())
	var last := int(save.get("last_seen", 0))
	save["last_seen"] = now
	if last <= 0 or now - last < AWAY_S or int(save.get("stage_unlocked", 1)) <= 3:
		return {}
	var away := now - last
	var gift := gift_for(away)
	if not gift.is_empty():
		Progress.grant(save, gift)
	return {"away_s": away, "gift": gift, "items": items(save)}

static func away_text(s: int) -> String:
	if s >= 86400:
		return "%d day%s" % [s / 86400, "" if s / 86400 == 1 else "s"]
	return "%dh %02dm" % [s / 3600, (s % 3600) / 60]

static func show(host: Control, info: Dictionary) -> void:
	var layer := Control.new()
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
	ss.content_margin_left = 18
	ss.content_margin_right = 18
	ss.content_margin_top = 14
	ss.content_margin_bottom = 22
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
	v.add_child(UIKit.popup_title("Welcome back"))
	v.add_child(UIKit.label("You were away %s" % away_text(int(info.away_s)), 12, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	var gift: Dictionary = info.get("gift", {})
	if not gift.is_empty():
		var gp := PanelContainer.new()
		gp.add_theme_stylebox_override("panel", UIKit.box(Color(UIKit.GOLD, 0.12), Color(UIKit.GOLD, 0.7), 16, 1))
		var gm := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			gm.add_theme_constant_override("margin_" + side, 10)
		var gh := HBoxContainer.new()
		gh.alignment = BoxContainer.ALIGNMENT_CENTER
		gh.add_theme_constant_override("separation", 14)
		gh.add_child(UIKit.title("A gift for coming back", 14, UIKit.GOLD))
		gh.add_child(UIKit.iconed(UIKit.ic("ic_coin"), UIKit.num(int(gift.get("coins", 0))), 13, UIKit.TEXT, 18.0))
		gh.add_child(UIKit.iconed(UIKit.ic("ic_crystal"), str(int(gift.get("crystals", 0))), 13, UIKit.TEXT, 18.0))
		gm.add_child(gh)
		gp.add_child(gm)
		v.add_child(gp)
	var list: Array = info.get("items", [])
	if list.is_empty():
		v.add_child(UIKit.label("Nothing is waiting. Back to the fight.", 12, UIKit.SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	for it in list:
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", UIKit.box(Color(UIKit.CARD_HI, 0.5), Color(1, 1, 1, 0.04), 14, 1))
		var m := MarginContainer.new()
		for side in ["left", "right"]:
			m.add_theme_constant_override("margin_" + side, 12)
		for side in ["top", "bottom"]:
			m.add_theme_constant_override("margin_" + side, 6)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		var ic := TextureRect.new()
		var tx: Texture2D = UIKit.ic(String(it[0]))
		ic.texture = tx if tx != null else Icons.get_icon(String(it[0]))
		ic.custom_minimum_size = Vector2(26, 26)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.add_child(ic)
		h.add_child(UIKit.label(String(it[1]), 13, UIKit.TEXT))
		m.add_child(h)
		row.add_child(m)
		v.add_child(row)
	var go := UIKit.gold_button("LET'S GO", 17)
	go.custom_minimum_size = Vector2(0, 52)
	go.pressed.connect(layer.queue_free)
	v.add_child(go)
