extends Control
# Store (ROADMAP 1.0). Tabs:
#   Daily   - a free gift once a day, plus crystal offers (coins, the x2 speed pack)
#   Chests  - chests bought with crystals, opened on the spot (random coins / crystals)
#   Packs   - real-money packs: shown, "coming soon" until Google Play billing is set up
#   Codes   - redeem codes (CODES below; one use per player). In 2.0 codes come from
#             the server so new ones can be added any time.
# Every reward goes through Progress.grant.

const DAILY_GIFT := {"coins": 150, "crystals": 3}
const OFFERS := [
	{"id": "coins_s", "name": "Coin Pouch", "text": "+600 coins", "price": 30, "reward": {"coins": 600}, "color": "rare"},
	{"id": "coins_l", "name": "Coin Chest", "text": "+2,000 coins", "price": 90, "reward": {"coins": 2000}, "color": "epic"},
	{"id": "speed", "name": "Speed Pack", "text": "Unlocks x2 game speed", "price": 300, "once": true, "flag": "speed_pack", "color": "legendary"},
]
const CHESTS := [
	{"id": "supply", "name": "Supply Crate", "price": 25, "color": "rare",
		"rolls": [[60, {"coins": 400}], [30, {"coins": 800}], [10, {"crystals": 40}]]},
	{"id": "vault", "name": "Vault Chest", "price": 80, "color": "epic",
		"rolls": [[50, {"coins": 1500}], [35, {"coins": 3000}], [15, {"crystals": 150}]]},
]
const PACKS := [
	["Starter Pack", "1,500 coins + 100 crystals", "$1.99"], ["Crystals x300", "premium currency", "$4.99"],
	["Crystals x1400", "premium currency", "$19.99"], ["Speed Pack", "x2 game speed forever", "$2.99"],
]
# Redeem codes (upper case). Add a code here to give everyone something free.
const CODES := {
	"SKYBOUND": {"coins": 500, "crystals": 20},
	"WELCOME": {"coins": 300},
	"LUNA": {"crystals": 30},
}

var tab := 0
var d := {}
var _list: VBoxContainer
var _wallet: Label

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
	top.add_child(UIKit.screen_title("STORE"))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	_wallet = UIKit.label("", 12, UIKit.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	top.add_child(_wallet)
	col.add_child(top)
	col.add_child(UIKit.tabs(["Daily", "Chests", "Packs", "Codes"], func(i): tab = i; _fill(), 0))
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	col.add_child(_list)
	_fill()

func _fill() -> void:
	for c in _list.get_children():
		c.queue_free()
	_wallet.text = "%d coins  ·  %d crystals" % [int(d.get("coins", 0)), int(d.get("crystals", 0))]
	match tab:
		0: _fill_daily()
		1: _fill_chests()
		2: _fill_packs()
		3: _fill_codes()

func _row(title: String, sub: String, color: String, button: Button, icon: Texture2D = null) -> void:
	var p := UIKit.panel(10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	if icon:
		var tr := TextureRect.new()
		tr.texture = icon
		tr.custom_minimum_size = Vector2(52, 44)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(tr)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(UIKit.label(title, 15, UIKit.RARITY.get(color, Color.WHITE)))
	body.add_child(UIKit.label(sub, 12, UIKit.MUTED))
	row.add_child(body)
	button.custom_minimum_size = Vector2(110, 40)
	var av := VBoxContainer.new()
	av.alignment = BoxContainer.ALIGNMENT_CENTER
	av.add_child(button)
	row.add_child(av)
	p.add_child(row)
	_list.add_child(p)

func _fill_daily() -> void:
	var got_today := int(d.get("gift_day", -1)) == Progress.today()
	var gift := UIKit.gold_button("Claimed" if got_today else "Free!", 14)
	gift.disabled = got_today
	gift.pressed.connect(func():
		d = Progress.read()
		d["gift_day"] = Progress.today()
		Progress.grant(d, DAILY_GIFT)
		Progress.write(d)
		_toast("+ " + Progress.reward_text(DAILY_GIFT))
		_fill())
	_row("Daily Gift", Progress.reward_text(DAILY_GIFT) + ", free every day", "legendary", gift, load("res://icons/chest3d_closed.png"))
	for o in OFFERS:
		var owned: bool = o.get("once", false) and bool(d.get(o.flag, false))
		var b := UIKit.teal_button("Owned" if owned else "%d crystals" % o.price, 13)
		b.disabled = owned or int(d.get("crystals", 0)) < int(o.price)
		var offer: Dictionary = o
		b.pressed.connect(func(): _buy(offer))
		_row(o.name, o.text, o.color, b, load("res://icons/ui_coin.png") if o.id.begins_with("coins") else load("res://icons/ui_energy.png"))

func _buy(o: Dictionary) -> void:
	d = Progress.read()
	if int(d.get("crystals", 0)) < int(o.price):
		return
	d["crystals"] = int(d.get("crystals", 0)) - int(o.price)
	if o.has("flag"):
		d[o.flag] = true
		_toast(o.text)
	else:
		Progress.grant(d, o.reward)
		_toast("+ " + Progress.reward_text(o.reward))
	Progress.write(d)
	_fill()

func _fill_chests() -> void:
	for c in CHESTS:
		var b := UIKit.gold_button("%d crystals" % c.price, 13)
		b.disabled = int(d.get("crystals", 0)) < int(c.price)
		var chest: Dictionary = c
		b.pressed.connect(func(): _open_chest(chest))
		var odds: Array = []
		for r in c.rolls:
			odds.append("%d%%: %s" % [r[0], Progress.reward_text(r[1])])
		_row(c.name, "  ·  ".join(odds), c.color, b, load("res://icons/chest3d_closed.png"))

func _open_chest(c: Dictionary) -> void:
	d = Progress.read()
	if int(d.get("crystals", 0)) < int(c.price):
		return
	d["crystals"] = int(d.get("crystals", 0)) - int(c.price)
	var roll := randi() % 100
	var reward: Dictionary = c.rolls[0][1]
	var acc := 0
	for r in c.rolls:
		acc += int(r[0])
		if roll < acc:
			reward = r[1]
			break
	Progress.grant(d, reward)
	Progress.write(d)
	_chest_fx(reward)
	_fill()

# the chest opens in the middle of the screen: lid up, light out, then the reward
func _chest_fx(reward: Dictionary) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0.01, 0.04, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var prop := HomeProp.new()
	prop.kind = "chest"
	prop.size = Vector2(180, 180)
	prop.position = size * 0.5 - Vector2(90, 120)
	dim.add_child(prop)
	var l := UIKit.label("+ " + Progress.reward_text(reward), 20, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	l.position = Vector2(0, size.y * 0.5 + 80.0)
	l.size = Vector2(size.x, 30)
	l.modulate.a = 0.0
	dim.add_child(l)
	prop.call_deferred("open")
	var tw := dim.create_tween()
	tw.tween_interval(0.35)
	tw.tween_property(l, "modulate:a", 1.0, 0.25)
	tw.tween_interval(1.4)
	tw.tween_property(dim, "modulate:a", 0.0, 0.3)
	tw.tween_callback(dim.queue_free)

func _fill_packs() -> void:
	_list.add_child(UIKit.label("Real-money packs open when the game is on Google Play.", 12, UIKit.MUTED))
	for p in PACKS:
		var b := UIKit.ghost_button(p[2], 13)
		b.disabled = true
		_row(p[0], p[1] + "  (coming soon)", "epic", b, load("res://icons/ui_crystal.png"))

func _fill_codes() -> void:
	_list.add_child(UIKit.label("Got a code? Enter it here for free rewards. Each code works once.", 12, UIKit.MUTED))
	var p := UIKit.panel(10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var input := LineEdit.new()
	input.placeholder_text = "ENTER CODE"
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.custom_minimum_size = Vector2(0, 42)
	input.add_theme_font_size_override("font_size", 16)
	input.max_length = 20
	row.add_child(input)
	var go := UIKit.gold_button("Redeem", 14)
	go.custom_minimum_size = Vector2(110, 42)
	row.add_child(go)
	p.add_child(row)
	_list.add_child(p)
	var msg := UIKit.label("", 13, UIKit.CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	_list.add_child(msg)
	var redeem := func():
		var code := input.text.strip_edges().to_upper()
		d = Progress.read()
		var used: Array = d.get("codes_used", [])
		if not CODES.has(code):
			msg.text = "That code isn't valid."
			msg.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
		elif used.has(code):
			msg.text = "You've already used that code."
			msg.add_theme_color_override("font_color", Color(1.0, 0.75, 0.4))
		else:
			used.append(code)
			d["codes_used"] = used
			Progress.grant(d, CODES[code])
			Progress.write(d)
			msg.text = "Redeemed: + " + Progress.reward_text(CODES[code])
			msg.add_theme_color_override("font_color", UIKit.GOLD)
			_wallet.text = "%d coins  ·  %d crystals" % [int(d.get("coins", 0)), int(d.get("crystals", 0))]
	go.pressed.connect(redeem)
	input.text_submitted.connect(func(_t): redeem.call())

func _toast(text: String) -> void:
	var l := UIKit.label(text, 16, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
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
