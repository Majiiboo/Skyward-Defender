extends Control
# Store (ROADMAP 1.0). Tabs:
#   Offers  - a free gift once a day, plus crystal offers (coins, the x2 speed pack)
#   Chests  - chests bought with crystals, opened on the spot (random coins / crystals)
#   Packs   - real-money packs: shown, "coming soon" until Google Play billing is set up
#   Parts   - upgrade parts for crystals (PART_DEALS)
#   "Have a code?" (pop-up) - redeem codes (CODES below; one use per player). In 2.0 codes come from
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

# Upgrade parts for crystals, at the same rate crystals stand in for missing parts
# (Parts.KINDS crystals), so buying them is a shortcut, never a better deal.
const PART_DEALS := [{"kind": "alloy", "n": 5}, {"kind": "cell", "n": 3}, {"kind": "core", "n": 1}]
const PART_COLOR := {"alloy": "rare", "cell": "epic", "core": "legendary"}

var tab := 0
var d := {}
var _page: VBoxContainer
var _wallet: HBoxContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	d = Progress.read()
	_build()
	_fade_in_overlay()

# One screen per tab, no long lists (Rudy): picture tiles, big numbers, few words.
func _build() -> void:
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left", "margin_right"]:
		root.add_theme_constant_override(m, 12)
	root.add_theme_constant_override("margin_top", 10)
	root.add_theme_constant_override("margin_bottom", 16)
	add_child(root)
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
	_wallet = HBoxContainer.new()
	_wallet.add_theme_constant_override("separation", 10)
	top.add_child(_wallet)
	col.add_child(top)
	col.add_child(UIKit.tabs(["Offers", "Chests", "Parts", "Packs"], func(i): tab = i; _fill(), 0))
	_page = VBoxContainer.new()
	_page.add_theme_constant_override("separation", 10)
	_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_page)
	var code := UIKit.ghost_button("Have a code?", 12)
	code.custom_minimum_size = Vector2(0, 32)
	code.pressed.connect(_code_popup)
	col.add_child(code)
	_fill()

func _fill() -> void:
	for c in _page.get_children():
		c.queue_free()
	for c in _wallet.get_children():
		c.queue_free()
	_wallet.add_child(_amount(load("res://icons/ui_coin.png"), int(d.get("coins", 0)), UIKit.GOLD))
	_wallet.add_child(_amount(load("res://icons/ui_crystal.png"), int(d.get("crystals", 0)), UIKit.CYAN))
	match tab:
		0: _fill_offers()
		1: _fill_chests()
		2: _fill_parts()
		3: _fill_packs()

# an icon with a number beside it
func _amount(icon: Texture2D, n: int, col: Color, px: float = 18.0, font: int = 13) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	var tr := TextureRect.new()
	tr.texture = icon
	tr.custom_minimum_size = Vector2(px, px)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(tr)
	h.add_child(UIKit.label(_num(n), font, col))
	return h

func _num(n: int) -> String:
	return str(n) if n < 10000 else "%.1fk" % (n / 1000.0)

# A shop tile: a big picture, a big number, one short line, the button.
func _tile(icon: Texture2D, big: String, small: String, color: String, button: Button) -> PanelContainer:
	var col: Color = UIKit.RARITY.get(color, UIKit.CYAN)
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UIKit.box(Color(col.r * 0.12, col.g * 0.12, col.b * 0.2, 0.75), Color(col, 0.6), 14))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	var tr := TextureRect.new()
	tr.texture = icon
	tr.custom_minimum_size = Vector2(0, 92)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(tr)
	v.add_child(UIKit.label(big, 22, col, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UIKit.label(small, 11, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	button.custom_minimum_size = Vector2(0, 38)
	v.add_child(button)
	p.add_child(v)
	return p

func _grid() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	_page.add_child(g)
	return g

# a crystal price: the crystal picture and the number
func _price_button(price: int, ok: bool, gold: bool = false) -> Button:
	var b := UIKit.gold_button(str(price), 14) if gold else UIKit.teal_button(str(price), 14)
	b.icon = load("res://icons/ui_crystal.png")
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 18)
	b.disabled = not ok
	return b

# ------------------------------------------------------------------ offers
func _fill_offers() -> void:
	# the daily gift, big across the top
	var got_today := int(d.get("gift_day", -1)) == Progress.today()
	var gift := UIKit.gold_button("Tomorrow" if got_today else "FREE", 15)
	gift.disabled = got_today
	gift.custom_minimum_size = Vector2(110, 44)
	gift.pressed.connect(func():
		d = Progress.read()
		d["gift_day"] = Progress.today()
		Progress.grant(d, DAILY_GIFT)
		Progress.write(d)
		_toast("+ " + Progress.reward_text(DAILY_GIFT))
		_fill())
	var gp := PanelContainer.new()
	gp.add_theme_stylebox_override("panel", UIKit.box(Color(0.16, 0.12, 0.03, 0.8), Color(UIKit.GOLD, 0.7), 14))
	var gh := HBoxContainer.new()
	gh.add_theme_constant_override("separation", 10)
	var chest := TextureRect.new()
	chest.texture = load("res://icons/chest3d_closed.png")
	chest.custom_minimum_size = Vector2(84, 76)
	chest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gh.add_child(chest)
	var gv := VBoxContainer.new()
	gv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gv.alignment = BoxContainer.ALIGNMENT_CENTER
	gv.add_child(UIKit.label("DAILY GIFT", 16, UIKit.GOLD))
	var gr := HBoxContainer.new()
	gr.add_theme_constant_override("separation", 12)
	gr.add_child(_amount(load("res://icons/ui_coin.png"), int(DAILY_GIFT.coins), Color.WHITE, 20.0, 15))
	gr.add_child(_amount(load("res://icons/ui_crystal.png"), int(DAILY_GIFT.crystals), Color.WHITE, 20.0, 15))
	gv.add_child(gr)
	gh.add_child(gv)
	var gb := VBoxContainer.new()
	gb.alignment = BoxContainer.ALIGNMENT_CENTER
	gb.add_child(gift)
	gh.add_child(gb)
	gp.add_child(gh)
	_page.add_child(gp)
	var g := _grid()
	for o in OFFERS:
		var owned: bool = o.get("once", false) and bool(d.get(o.flag, false))
		var b := _price_button(int(o.price), not owned and int(d.get("crystals", 0)) >= int(o.price))
		if owned:
			b.text = "Owned"
			b.icon = null
		var offer: Dictionary = o
		b.pressed.connect(func(): _buy(offer))
		var speed: bool = o.id == "speed"
		var big: String = "x2 speed" if speed else "+" + _num(int(o.reward.coins))
		g.add_child(_tile(load("res://icons/ui_energy.png") if speed else load("res://icons/ui_coin.png"), big, o.name, o.color, b))

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

# ------------------------------------------------------------------ chests
func _fill_chests() -> void:
	var g := _grid()
	for c in CHESTS:
		var b := _price_button(int(c.price), int(d.get("crystals", 0)) >= int(c.price), true)
		var chest: Dictionary = c
		b.pressed.connect(func(): _open_chest(chest))
		# what can come out: the coin range, and the crystal jackpot's chance
		var lo := 1 << 30
		var hi := 0
		var jackpot := ""
		for r in c.rolls:
			if r[1].has("coins"):
				lo = mini(lo, int(r[1].coins))
				hi = maxi(hi, int(r[1].coins))
			else:
				jackpot = "%d%%: %d crystals" % [int(r[0]), int(r[1].crystals)]
		g.add_child(_tile(load("res://icons/chest3d_closed.png"), "%s-%s" % [_num(lo), _num(hi)], "%s\n%s" % [c.name, jackpot], c.color, b))
	_page.add_child(UIKit.label("Coins, or the crystal jackpot", 11, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))

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

# ------------------------------------------------------------------ parts
func _fill_parts() -> void:
	var have := Parts.read(d)
	var g := _grid()
	for deal in PART_DEALS:
		var k: String = deal.kind
		var price: int = int(deal.n) * int(Parts.KINDS[k].crystals)
		var b := _price_button(price, int(d.get("crystals", 0)) >= price)
		var dd: Dictionary = deal
		b.pressed.connect(func(): _buy_parts(dd))
		g.add_child(_tile(Parts.icon(k), "x%d" % int(deal.n), "%s  ·  have %d" % [Parts.KINDS[k].name, int(have[k])], PART_COLOR[k], b))

func _buy_parts(deal: Dictionary) -> void:
	d = Progress.read()
	var price: int = int(deal.n) * int(Parts.KINDS[deal.kind].crystals)
	if int(d.get("crystals", 0)) < price:
		return
	d["crystals"] = int(d.get("crystals", 0)) - price
	var reward := {deal.kind: int(deal.n)}
	Progress.grant(d, reward)
	Progress.write(d)
	_toast("+ " + Progress.reward_text(reward))
	_fill()

# ------------------------------------------------------------------ packs
func _fill_packs() -> void:
	var g := _grid()
	for p in PACKS:
		var b := UIKit.ghost_button("%s  soon" % p[2], 13)
		b.disabled = true
		var name: String = p[0]
		var icon: Texture2D = load("res://icons/ui_crystal.png")
		if name.begins_with("Speed"):
			icon = load("res://icons/ui_energy.png")
		elif name.begins_with("Starter"):
			icon = load("res://icons/starter.png")
		g.add_child(_tile(icon, name, p[1], "epic", b))
	_page.add_child(UIKit.label("Opens on Google Play", 11, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))

# ------------------------------------------------------------------ code (pop-up)
func _code_popup() -> void:
	var layer := ColorRect.new()
	layer.color = Color(0, 0.01, 0.04, 0.75)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var p := UIKit.panel(14)
	var w := minf(size.x - 40.0, 380.0)
	p.custom_minimum_size = Vector2(w, 0)
	p.position = Vector2((size.x - w) * 0.5, size.y * 0.3)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.add_child(UIKit.label("ENTER CODE", 16, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var input := LineEdit.new()
	input.placeholder_text = "CODE"
	input.custom_minimum_size = Vector2(0, 44)
	input.add_theme_font_size_override("font_size", 18)
	input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	input.max_length = 20
	v.add_child(input)
	var msg := UIKit.label("", 13, UIKit.CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(msg)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var close := UIKit.ghost_button("Close", 14)
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close.custom_minimum_size = Vector2(0, 42)
	close.pressed.connect(layer.queue_free)
	row.add_child(close)
	var go := UIKit.gold_button("Redeem", 14)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.custom_minimum_size = Vector2(0, 42)
	row.add_child(go)
	v.add_child(row)
	p.add_child(v)
	layer.add_child(p)
	var redeem := func():
		var code := input.text.strip_edges().to_upper()
		d = Progress.read()
		var used: Array = d.get("codes_used", [])
		if not CODES.has(code):
			msg.text = "Not a valid code"
			msg.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
		elif used.has(code):
			msg.text = "Already used"
			msg.add_theme_color_override("font_color", Color(1.0, 0.75, 0.4))
		else:
			used.append(code)
			d["codes_used"] = used
			Progress.grant(d, CODES[code])
			Progress.write(d)
			msg.text = "+ " + Progress.reward_text(CODES[code])
			msg.add_theme_color_override("font_color", UIKit.GOLD)
			_fill()
	go.pressed.connect(redeem)
	input.text_submitted.connect(func(_t): redeem.call())
	input.grab_focus()

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
