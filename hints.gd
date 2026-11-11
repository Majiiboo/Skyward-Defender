class_name Hints
extends RefCounted
# HINTS (2026-11-10): the first-time tips, redone the way Rudy asked after dev166 ("tip boxes are
# huge, the spotlight sat on a random area, a tip pops the moment the game opens": tips went OFF).
# A hint is ONE small card that slides up at the bottom of a page the first time you open it once
# its feature is yours: a gold name and one line. It never dims the screen, never blocks a tap,
# never appears on Home, goes away on a tap or after HOLD seconds, and shows once (save "hints":
# [ids]). Only the systems a player would not guess are covered, not the basics.
# A page calls Hints.show(self, [ids it may show now]); the first unseen one shows, one a visit.
# Settings: a "Hints" switch (save "hints_on", default on) and Reset.
# (tips.gd, the old spotlight tips, stays switched off.)

const HOLD := 9.0
const HINTS := {
	# Heroes
	"ability":   {"title": "Ability upgrades", "text": "The Ability square: three upgrades for his special move, bought with his own shards."},
	"wingmate":  {"title": "Wingmate", "text": "A second hero you own flies in support: half his passive, and his ability fires by itself."},
	"weapon":    {"title": "Weapon shapes", "text": "A weapon changes shape at Lv.10 and Lv.20. Each shape fires differently."},
	"base":      {"title": "Your base", "text": "Field four buildings. Each gives a bonus, a perk at Lv.5, and some pairs link for more."},
	"research":  {"title": "Research Lab", "text": "One project at a time. It keeps running while the game is closed."},
	"support":   {"title": "Support drone", "text": "With a Hangar on the base, a second drone guards, heals or collects for you."},
	# Store
	"spin":      {"title": "Daily Spin", "text": "One free spin a day, under Offers."},
	"deals":     {"title": "Today's deals", "text": "Shop > Today: three offers a day, a third or more off, each once."},
	# Modes
	"daily":     {"title": "Daily Challenge", "text": "Your best stage with three twists. One reward a day."},
	"event":     {"title": "Weekly event", "text": "A themed week. Every fight earns points toward ten rewards."},
	"run":       {"title": "Expedition", "text": "Eight stops across a planet. Cards, health and the base carry from fight to fight."},
	"bossrush":  {"title": "Boss Rush", "text": "Every boss you have beaten, in a row, against the clock."},
	# Quests
	"contracts": {"title": "Hero contracts", "text": "Career: fight with a hero to fill his contracts. They pay his own shards."},
	"codex":     {"title": "Collection", "text": "Everything you have met. Each quarter of a category pays crystals."},
	# pages of their own
	"season":    {"title": "Season Pass", "text": "Fights and daily quests earn season XP. Every 100 XP is a tier with a reward."},
	"campaign":  {"title": "Stars and chests", "text": "Three stars a stage. 10, 20 and 30 stars on a planet each open a chest."},
	"works":     {"title": "Field works", "text": "Stops 3 and 6: bolt an upgrade onto the base for the rest of the run."},
}

static func on(save: Dictionary) -> bool:
	return bool(save.get("hints_on", true))

static func seen(save: Dictionary, id: String) -> bool:
	var h = save.get("hints", [])
	return typeof(h) == TYPE_ARRAY and h.has(id)

static func mark(save: Dictionary, id: String) -> void:
	var h = save.get("hints", [])
	if typeof(h) != TYPE_ARRAY:
		h = []
	if not h.has(id):
		h.append(id)
	save["hints"] = h

static func reset() -> void:
	var d := Progress.read()
	d["hints"] = []
	Progress.write(d)

# the first of `ids` not shown yet ("" = none, or hints are off)
static func next(save: Dictionary, ids: Array) -> String:
	if not on(save):
		return ""
	for id in ids:
		if HINTS.has(String(id)) and not seen(save, String(id)):
			return String(id)
	return ""

# show the first unseen hint of `ids` on this page; returns the id shown ("" = none)
static func show(host: Control, ids: Array) -> String:
	if host == null or not is_instance_valid(host) or not host.is_inside_tree():
		return ""
	if host.has_meta("hint_card") and is_instance_valid(host.get_meta("hint_card")):
		return ""   # one at a time
	var d := Progress.read()
	var id := next(d, ids)
	if id == "":
		return ""
	mark(d, id)
	Progress.write(d)
	var card := _card(id)
	host.add_child(card)
	host.set_meta("hint_card", card)
	return id

static func _card(id: String) -> Control:
	var def: Dictionary = HINTS[id]
	var wrap := Control.new()
	wrap.name = "Hint"
	wrap.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	wrap.offset_left = 12.0
	wrap.offset_right = -12.0
	wrap.offset_top = -90.0
	wrap.offset_bottom = -14.0
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.z_index = 20
	var b := Button.new()
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb := UIKit.box(Color(0.055, 0.09, 0.16, 0.97), Color(UIKit.GOLD, 0.55), 18, 1)
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	wrap.add_child(b)
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 14.0
	h.offset_right = -12.0
	h.offset_top = 8.0
	h.offset_bottom = -8.0
	h.add_theme_constant_override("separation", 10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var bar := ColorRect.new()   # a gold mark at the left: this is a hint, not a button
	bar.color = UIKit.GOLD
	bar.custom_minimum_size = Vector2(3, 0)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(bar)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(UIKit.title(String(def.title), 14, UIKit.GOLD))
	var body := UIKit.label(String(def.text), 12, UIKit.TEXT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(body)
	h.add_child(v)
	var x := UIKit.label("OK", 12, UIKit.SOFT)
	x.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	x.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(x)
	# slides up, waits, slides away; a tap sends it away at once
	var close := func():
		if not is_instance_valid(wrap) or wrap.has_meta("closing"):
			return
		wrap.set_meta("closing", true)
		var tw := wrap.create_tween().set_parallel(true)
		tw.tween_property(wrap, "modulate:a", 0.0, 0.2)
		tw.tween_property(wrap, "position:y", wrap.position.y + 20.0, 0.2)
		tw.chain().tween_callback(wrap.queue_free)
	b.pressed.connect(close)
	wrap.modulate.a = 0.0
	wrap.ready.connect(func():
		var y0 := wrap.position.y
		wrap.position.y = y0 + 30.0
		var tw := wrap.create_tween().set_parallel(true)
		tw.tween_interval(0.5)
		tw.chain().tween_property(wrap, "modulate:a", 1.0, 0.25)
		tw.parallel().tween_property(wrap, "position:y", y0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		var tm := Timer.new()
		tm.one_shot = true
		tm.wait_time = HOLD
		tm.autostart = true
		tm.timeout.connect(close)
		wrap.add_child(tm))
	return wrap
