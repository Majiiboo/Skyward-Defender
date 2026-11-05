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
var _tabs_row: HBoxContainer

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
	# Home's Gifts / Starter buttons can ask for a tab ("store_tab" meta on the tree root)
	if get_tree().root.has_meta("store_tab"):
		tab = int(get_tree().root.get_meta("store_tab"))
		get_tree().root.remove_meta("store_tab")
	_tabs_row = UIKit.tabs(["Offers", "Chests", "Parts", "Packs"], func(i): tab = i; _fill(), tab)
	col.add_child(_tabs_row)
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
	_wallet.add_child(UIKit.wallet(int(d.get("coins", 0)), int(d.get("crystals", 0))))
	UIKit.tab_dots(_tabs_row, [Progress.attention(d).store, false, false, false])   # today's gift waiting
	match tab:
		0: _fill_offers()
		1: _fill_chests()
		2: _fill_parts()
		3: _fill_packs()

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
	# the attendance calendar (Progress.ATTEND): seven days across the top, today's cell lit,
	# claimed ones ticked, day 7 in gold; FREE claims today's gift
	var at := Progress.attend(d)
	var gift := UIKit.gold_button("Tomorrow" if at.claimed_today else "FREE", 15)
	gift.disabled = at.claimed_today
	gift.custom_minimum_size = Vector2(100, 40)
	gift.pressed.connect(func():
		d = Progress.read()
		var got := Progress.claim_attend(d)
		Progress.write(d)
		if not got.is_empty():
			_toast("+ " + Progress.reward_text(got))
		_fill())
	var gp := PanelContainer.new()
	gp.add_theme_stylebox_override("panel", UIKit.box(Color(0.16, 0.12, 0.03, 0.8), Color(UIKit.GOLD, 0.7), 14))
	var gv := VBoxContainer.new()
	gv.add_theme_constant_override("separation", 6)
	var gh := HBoxContainer.new()
	gh.add_theme_constant_override("separation", 10)
	var chest := TextureRect.new()
	chest.texture = load("res://icons/chest3d_closed.png")
	chest.custom_minimum_size = Vector2(44, 40)
	chest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gh.add_child(chest)
	var tl := VBoxContainer.new()
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tl.alignment = BoxContainer.ALIGNMENT_CENTER
	tl.add_theme_constant_override("separation", 0)
	tl.add_child(UIKit.label("DAILY GIFT  ·  DAY %d OF %d" % [int(at.day), Progress.ATTEND.size()], 14, UIKit.GOLD))
	tl.add_child(UIKit.label("Come back every day; day 7 is the big one", 10, UIKit.MUTED))
	gh.add_child(tl)
	gh.add_child(gift)
	gv.add_child(gh)
	var cells := HBoxContainer.new()
	cells.add_theme_constant_override("separation", 4)
	for i in Progress.ATTEND.size():
		var day := i + 1
		var r: Dictionary = Progress.ATTEND[i]
		var is_today: bool = day == int(at.day)
		var done: bool = day < int(at.next) or (day == int(at.day) and at.claimed_today)
		var last: bool = day == Progress.ATTEND.size()
		var col: Color = UIKit.GOLD if last else UIKit.CYAN
		var c := PanelContainer.new()
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sb := UIKit.box(Color(col, 0.22 if is_today else 0.06), Color(col, 0.95 if is_today else 0.3), 8, 2 if is_today else 1)
		sb.set_content_margin_all(3)
		c.add_theme_stylebox_override("panel", sb)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 0)
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		cv.add_child(UIKit.label("✓" if done else "D%d" % day, 9, Color(0.5, 1.0, 0.6) if done else UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		# the main thing in the gift: crystals if any, else coins, else the part
		var icon: Texture2D
		var amount := 0
		if r.has("crystals"):
			icon = load("res://icons/ui_crystal.png")
			amount = int(r.crystals)
		elif r.has("coins"):
			icon = load("res://icons/ui_coin.png")
			amount = int(r.coins)
		var ci := TextureRect.new()
		ci.texture = icon
		ci.custom_minimum_size = Vector2(0, 20)
		ci.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ci.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ci.modulate = Color(1, 1, 1, 0.45 if done else 1.0)
		cv.add_child(ci)
		cv.add_child(UIKit.label(str(amount) + ("+" if r.size() > 1 else ""), 10, Color.WHITE if not done else UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		c.add_child(cv)
		c.tooltip_text = Progress.reward_text(r)
		cells.add_child(c)
	gv.add_child(cells)
	gp.add_child(gv)
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
		var big: String = "x2 speed" if speed else "+" + UIKit.num(int(o.reward.coins))
		g.add_child(_tile(load("res://icons/ui_energy.png") if speed else load("res://icons/ui_coin.png"), big, o.name, o.color, b))
	g.add_child(_teaser(load("res://icons/gifts.png"), "Weekly Pack", "Free items every week"))

# A tile for what the Store will sell later (Store 2.0, dev141): the picture dimmed, a
# SOON chip where the price would be, so the page does not look half empty.
func _teaser(icon: Texture2D, big: String, small: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UIKit.box(Color(0.05, 0.07, 0.14, 0.55), Color(1, 1, 1, 0.14), 14))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	var tr := TextureRect.new()
	tr.texture = icon
	tr.custom_minimum_size = Vector2(0, 92)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.modulate = Color(0.5, 0.55, 0.68, 0.8)
	v.add_child(tr)
	v.add_child(UIKit.label(big, 18, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UIKit.label(small, 11, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var chip := UIKit.chip("COMING SOON", UIKit.MUTED)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(0, 38)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(chip)
	v.add_child(box)
	p.add_child(v)
	return p

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
		g.add_child(_tile(load("res://icons/chest3d_closed.png"), "%s-%s" % [UIKit.num(lo), UIKit.num(hi)], "%s\n%s" % [c.name, jackpot], c.color, b))
	# Store 2.0 (queue 18): chests opened with keys, with a pity counter, and gear inside
	g.add_child(_teaser(load("res://icons/chest3d_closed.png"), "Key Chest", "Opened with keys from battle"))
	g.add_child(_teaser(load("res://icons/gear_on.png"), "Gear Chest", "Gear copies, Epic every 10th"))
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
