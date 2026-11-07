extends Control
# Store 2.0 (queue item 18, Rudy; dev189). Tabs:
#   Chests   - three chests opened with KEYS (keys drop on boss stages, Elite and Horde, or are
#              bought): Uncommon and Epic have one FREE open every 24 h and a PITY counter (every
#              10th Uncommon open is an Epic item, every 10th Epic open a Legendary item); the
#              Legendary chest opens only with crystals. Odds shown on the tile.
#   Offers   - the attendance calendar, then the daily / weekly / monthly packs with their FREE
#              part claimable on a timer (the paid part "coming soon"), stage packs later.
#   Shop     - one scrolling page: coins, keys, parts, a Specialty section (essences, the lines).
#   Crystals - real-money crystal packs: shown, "coming soon" until Google Play billing.
#   Exchange - event tokens traded for items (2.0, with events); "coming soon".
#   "Have a code?" (pop-up) - redeem codes (CODES; one use per player).
# Every reward goes through Progress.grant. Keys are materials (materials.gd key_u / key_e).

const OFFERS := [
	{"id": "coins_s", "name": "Coin Pouch", "text": "+600 coins", "price": 30, "reward": {"coins": 600}, "color": "rare"},
	{"id": "coins_l", "name": "Coin Chest", "text": "+2,000 coins", "price": 90, "reward": {"coins": 2000}, "color": "epic"},
	{"id": "speed", "name": "Speed Pack", "text": "Unlocks x2 game speed", "price": 300, "once": true, "flag": "speed_pack", "color": "legendary"},
]
# the old crystal crates, kept so an old Home chest overlay and saves keep working
const CHESTS := [
	{"id": "supply", "name": "Supply Crate", "price": 25, "color": "rare",
		"rolls": [[60, {"coins": 400}], [30, {"coins": 800}], [10, {"crystals": 40}]]},
	{"id": "vault", "name": "Vault Chest", "price": 80, "color": "epic",
		"rolls": [[50, {"coins": 1500}], [35, {"coins": 3000}], [15, {"crystals": 150}]]},
]
# KEY CHESTS. A roll's "ess" = that many essences of the element the selected planet is weak to;
# "gear" = a gear copy of the selected stage's set at that rarity (both resolved when opened).
const DAY_S := 86400
const KEY_CHESTS := {
	"u": {"name": "Uncommon Chest", "color": "rare", "key": "key_u", "crystals": 40, "free": true, "icon": "ic_chest_u", "pity": 10,
		"pity_text": "an Epic item", "pity_reward": {"core": 1, "ess": 1, "gear": "epic"},
		"rolls": [[45, {"coins": 600}], [22, {"alloy": 6}], [15, {"cell": 2}], [12, {"barrel": 1, "rotor": 1}], [6, {"crystals": 25}]]},
	"e": {"name": "Epic Chest", "color": "epic", "key": "key_e", "crystals": 120, "free": true, "icon": "ic_chest_e", "pity": 10,
		"pity_text": "a Legendary item", "pity_reward": {"core": 3, "ess": 3, "gear": "legendary", "crystals": 150},
		"rolls": [[32, {"coins": 2500}], [24, {"cell": 5}], [16, {"core": 1}], [16, {"ess": 1}], [12, {"crystals": 80}]]},
	"l": {"name": "Legendary Chest", "color": "legendary", "key": "", "crystals": 300, "free": false, "icon": "ic_chest_l", "pity": 0,
		"rolls": [[38, {"coins": 6000, "core": 2}], [30, {"ess": 3}], [22, {"gear": "legendary"}], [10, {"crystals": 400}]]},
}
const CHEST_ORDER := ["u", "e", "l"]
# the packs: the free part is claimable every `every` seconds; the paid part waits for billing
const PACKS_FREE := [
	{"id": "daily", "name": "Daily Pack", "every": DAY_S, "free": {"coins": 300, "key_u": 1}, "paid": "Coins x3 + 2 keys", "color": "rare"},
	{"id": "weekly", "name": "Weekly Pack", "every": 7 * DAY_S, "free": {"cell": 3, "key_e": 1}, "paid": "Cores + an Epic key", "color": "epic"},
	{"id": "monthly", "name": "Monthly Pack", "every": 30 * DAY_S, "free": {"crystals": 30, "core": 1, "ess": 1}, "paid": "Crystals x300 + a Legendary chest", "color": "legendary"},
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
# keys and the material lines for crystals (Materials.KINDS crystals x n)
const KEY_DEALS := [{"kind": "key_u", "n": 1, "color": "rare"}, {"kind": "key_e", "n": 1, "color": "epic"}, {"kind": "key_u", "n": 5, "color": "rare"}]
const SPECIALTY := [{"kind": "ess", "n": 1, "color": "legendary"}, {"kind": "barrel", "n": 3, "color": "rare"}, {"kind": "rotor", "n": 3, "color": "rare"}, {"kind": "lens", "n": 1, "color": "epic"}]

const TAB_NAMES := ["Chests", "Offers", "Shop", "Crystals", "Exchange"]

var tab := 0
var d := {}
var _page: VBoxContainer
var _wallet: HBoxContainer
var _tabs_row: HBoxContainer
var _gift_btn: Button   # the daily gift (tips)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	MenuBackdrop.add_to(self)   # the living planet wallpaper behind the page
	d = Progress.read()
	_build()
	_fade_in_overlay()

# ------------------------------------------------------------------ the rules (static: Home uses them too)
static func now_s() -> int:
	return int(Time.get_unix_time_from_system())

static func _free_block(save: Dictionary) -> Dictionary:
	var f = save.get("store_free", {})
	return f if typeof(f) == TYPE_DICTIONARY else {}

# seconds until the free open / claim `key` is ready again (0 = ready)
static func free_left_s(save: Dictionary, key: String, every: int) -> int:
	var t := int(_free_block(save).get(key, 0))
	return maxi(0, every - (now_s() - t)) if t > 0 else 0

static func _mark_free(save: Dictionary, key: String) -> void:
	var f := _free_block(save)
	f[key] = now_s()
	save["store_free"] = f

static func left_text(s: int) -> String:
	if s >= DAY_S:
		return "%dd %dh" % [s / DAY_S, (s % DAY_S) / 3600]
	return "%dh %02dm" % [s / 3600, (s % 3600) / 60] if s >= 3600 else "%dm" % maxi(1, s / 60)

static func opens_of(save: Dictionary, tier: String) -> int:
	var o = save.get("chest_opens", {})
	return int(o.get(tier, 0)) if typeof(o) == TYPE_DICTIONARY else 0

# "ess" and "gear" entries become real rewards for the selected stage
static func resolve(save: Dictionary, reward: Dictionary, rng: RandomNumberGenerator = null) -> Dictionary:
	var out := {}
	var stage := clampi(int(save.get("selected_stage", 1)), 1, StageData.MAX_STAGE)
	for k in reward:
		if k == "ess":
			out[Materials.essence_of(String(Heroes.family(stage).weak))] = int(reward[k])
		elif k == "gear":
			var r := rng if rng != null else RandomNumberGenerator.new()
			if rng == null:
				r.randomize()
			out["gear"] = [{"id": GearData.roll_drop(stage, r).id, "rarity": String(reward[k])}]
		else:
			out[k] = reward[k]
	return out

# the odds line of a chest: "45% 600 coins · 22% 6 Alloy ..."
static func odds_text(c: Dictionary) -> String:
	var bits: Array = []
	for r in c.rolls:
		bits.append("%d%% %s" % [int(r[0]), roll_text(r[1])])
	return "  ·  ".join(bits)

static func roll_text(reward: Dictionary) -> String:
	var bits: Array = []
	for k in reward:
		if k == "ess":
			bits.append("%d essence" % int(reward[k]))
		elif k == "gear":
			bits.append("a %s gear copy" % String(reward[k]))
		elif k == "coins" or k == "crystals":
			bits.append("%s %s" % [UIKit.num(int(reward[k])), k])
		else:
			bits.append("%d %s" % [int(reward[k]), Parts.kind(String(k)).name])
	return " + ".join(bits)

# Open key chest `tier` paying `how` ("free", "key" or "crystals"). Changes `save` in place.
# Returns the reward (resolved and granted; "pity": true when the pity item came), or {"why": ...}.
static func chest_open_in(save: Dictionary, tier: String, how: String, rng: RandomNumberGenerator = null) -> Dictionary:
	if not KEY_CHESTS.has(tier):
		return {"why": "No such chest"}
	var c: Dictionary = KEY_CHESTS[tier]
	if how == "free":
		if not c.free or free_left_s(save, "chest_" + tier, DAY_S) > 0:
			return {"why": "The free open is not ready"}
		_mark_free(save, "chest_" + tier)
	elif how == "key":
		if String(c.key) == "" or int(Materials.read(save).get(c.key, 0)) <= 0:
			return {"why": "No %s" % Materials.name_of(String(c.key))}
		Materials.add(save, String(c.key), -1)
	else:
		if int(save.get("crystals", 0)) < int(c.crystals) and not DevTools.on:
			return {"why": "Not enough crystals"}
		if not DevTools.on:
			save["crystals"] = int(save.get("crystals", 0)) - int(c.crystals)
	var o = save.get("chest_opens", {})
	if typeof(o) != TYPE_DICTIONARY:
		o = {}
	o[tier] = int(o.get(tier, 0)) + 1
	save["chest_opens"] = o
	var r := rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		r.randomize()
	var reward: Dictionary
	var pity := int(c.pity) > 0 and int(o[tier]) % int(c.pity) == 0
	if pity:
		reward = resolve(save, c.pity_reward, r)
	else:
		var roll := r.randi() % 100
		var picked: Dictionary = c.rolls[0][1]
		var acc := 0
		for rr in c.rolls:
			acc += int(rr[0])
			if roll < acc:
				picked = rr[1]
				break
		reward = resolve(save, picked, r)
	Progress.grant(save, reward)
	if pity:
		reward["pity"] = true
	return reward

# the old crystal crates (Home's overlay on older builds)
static func open_chest_in(save: Dictionary, c: Dictionary) -> Dictionary:
	if int(save.get("crystals", 0)) < int(c.price):
		return {}
	save["crystals"] = int(save.get("crystals", 0)) - int(c.price)
	var roll := randi() % 100
	var reward: Dictionary = c.rolls[0][1]
	var acc := 0
	for r in c.rolls:
		acc += int(r[0])
		if roll < acc:
			reward = r[1]
			break
	Progress.grant(save, reward)
	return reward

# claim a pack's free part; "" on success or why not
static func claim_pack_in(save: Dictionary, p: Dictionary) -> String:
	if free_left_s(save, "pack_" + String(p.id), int(p.every)) > 0:
		return "Not ready"
	_mark_free(save, "pack_" + String(p.id))
	Progress.grant(save, resolve(save, p.free))
	return ""

# is any free thing waiting (the Store's red dot)
static func free_waiting(save: Dictionary) -> bool:
	for t in ["u", "e"]:
		if free_left_s(save, "chest_" + t, DAY_S) == 0:
			return true
	for p in PACKS_FREE:
		if free_left_s(save, "pack_" + String(p.id), int(p.every)) == 0:
			return true
	return false

# ------------------------------------------------------------------ the page
# One screen per tab, no long lists (Rudy): picture tiles, big numbers, few words. The Shop is
# the one scrolling page, in sections.
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
	# Home's Gifts / Starter / Chest buttons can ask for a tab ("store_tab" meta on the tree root)
	if get_tree().root.has_meta("store_tab"):
		tab = int(get_tree().root.get_meta("store_tab"))
		get_tree().root.remove_meta("store_tab")
	tab = clampi(tab, 0, TAB_NAMES.size() - 1)
	_tabs_row = UIKit.tabs(TAB_NAMES, func(i): tab = i; _fill(), tab, [], [],
		[UIKit.ic("ic_chest_e"), UIKit.ic("ic_gift"), UIKit.ic("ic_coin"), UIKit.ic("ic_crystal"), UIKit.ic("ic_exchange", "ic_pack")])
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
	var chest_free := free_left_s(d, "chest_u", DAY_S) == 0 or free_left_s(d, "chest_e", DAY_S) == 0
	var pack_free := false
	for p in PACKS_FREE:
		pack_free = pack_free or free_left_s(d, "pack_" + String(p.id), int(p.every)) == 0
	UIKit.tab_dots(_tabs_row, [chest_free, Progress.attention(d).store or pack_free, false, false, false])
	match tab:
		0: _fill_chests()
		1: _fill_offers()
		2: _fill_shop()
		3: _fill_crystals()
		4: _fill_exchange()
	UIKit.reveal(_page)
	if tab == 1:
		call_deferred("_tips")

# A shop tile: a big picture, a big number, one short line, the button.
func _tile(icon: Texture2D, big: String, small: String, color: String, button: Button) -> PanelContainer:
	var col: Color = UIKit.RARITY.get(color, UIKit.CYAN)
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UIKit.lift(UIKit.box(Color(col.r * 0.12, col.g * 0.12, col.b * 0.2, 0.82), Color(col, 0.6), 14)))
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
	UIKit.depth(p, col, true, 0.3)
	return p

func _grid(into: Control = null) -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	(into if into != null else _page).add_child(g)
	return g

# a crystal price: the crystal picture and the number
func _price_button(price: int, ok: bool, gold: bool = false) -> Button:
	var b := UIKit.gold_button(str(price), 14) if gold else UIKit.teal_button(str(price), 14)
	b.icon = load("res://icons/ui_crystal.png")
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 18)
	b.disabled = not ok
	return b

# ------------------------------------------------------------------ chests
# One wide card per chest: the picture, the odds, the pity counter, and the ways to open it:
# FREE (or when it is back), a key (how many you hold), crystals.
func _fill_chests() -> void:
	var mats := Materials.read(d)
	for tier in CHEST_ORDER:
		var c: Dictionary = KEY_CHESTS[tier]
		var col: Color = UIKit.RARITY.get(String(c.color), UIKit.CYAN)
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UIKit.lift(UIKit.box(Color(col.r * 0.12, col.g * 0.12, col.b * 0.2, 0.82), Color(col, 0.6), 14)))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 6)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		var tr := TextureRect.new()
		tr.texture = UIKit.ic("chest2_%s_closed" % String(tier), String(c.icon))   # Luna's tier chest (store2) when cut, else her icon
		tr.custom_minimum_size = Vector2(72, 72)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.add_child(tr)
		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_theme_constant_override("separation", 1)
		tv.add_child(UIKit.label(String(c.name), 16, col))
		var odds := UIKit.label(odds_text(c), 10, UIKit.MUTED)
		odds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tv.add_child(odds)
		if int(c.pity) > 0:
			var left: int = int(c.pity) - opens_of(d, tier) % int(c.pity)
			tv.add_child(UIKit.iconed(UIKit.ic("ic_pity"), "%s in %d open%s" % [String(c.pity_text).capitalize(), left, "" if left == 1 else "s"], 10, UIKit.GOLD, 16.0))   # Luna's pity badge (store2)
		h.add_child(tv)
		v.add_child(h)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var t2: String = tier
		if c.free:
			var left_s := free_left_s(d, "chest_" + tier, DAY_S)
			var fb := UIKit.gold_button("FREE" if left_s == 0 else "Free in %s" % left_text(left_s), 13)
			if left_s == 0 and UIKit.ic("ic_free") != null:   # Luna's free tag (store2)
				fb.icon = UIKit.ic("ic_free")
				fb.add_theme_constant_override("icon_max_width", 20)
			fb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fb.custom_minimum_size = Vector2(0, 38)
			fb.disabled = left_s > 0
			fb.pressed.connect(func(): _open_key_chest(t2, "free"))
			row.add_child(fb)
		if String(c.key) != "":
			var have := int(mats.get(c.key, 0))
			var kb := UIKit.teal_button("Key  (%d)" % have, 13)
			kb.icon = Materials.icon(String(c.key))
			kb.expand_icon = true
			kb.add_theme_constant_override("icon_max_width", 18)
			kb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			kb.custom_minimum_size = Vector2(0, 38)
			kb.disabled = have <= 0
			kb.pressed.connect(func(): _open_key_chest(t2, "key"))
			row.add_child(kb)
		var cb := _price_button(int(c.crystals), int(d.get("crystals", 0)) >= int(c.crystals) or DevTools.on, String(c.key) == "")
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cb.custom_minimum_size = Vector2(0, 38)
		cb.pressed.connect(func(): _open_key_chest(t2, "crystals"))
		row.add_child(cb)
		v.add_child(row)
		p.add_child(v)
		UIKit.depth(p, col, true, 0.3)
		_page.add_child(p)
	_page.add_child(UIKit.label("Keys drop on boss stages, in Elite and every 10 Horde waves. Essence and gear match the planet you have selected.", 10, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	_page.get_child(_page.get_child_count() - 1).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _open_key_chest(tier: String, how: String) -> void:
	d = Progress.read()
	var reward := chest_open_in(d, tier, how)
	if reward.has("why"):
		_toast(String(reward.why))
		return
	Sfx.play("buy")
	Progress.write(d)
	Progress.bump("chests")
	_chest_fx(reward, tier)
	_fill()

# ------------------------------------------------------------------ offers
func _fill_offers() -> void:
	# the attendance calendar (Progress.ATTEND): seven days across the top, today's cell lit,
	# claimed ones ticked, day 7 in gold; FREE claims today's gift
	var at := Progress.attend(d)
	var gift := UIKit.gold_button("Tomorrow" if at.claimed_today else "FREE", 15)
	_gift_btn = gift
	gift.size_flags_vertical = Control.SIZE_SHRINK_CENTER   # its own height, so the tip ring fits it
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
	# the packs: each with a FREE part on its own timer; the paid part waits for billing
	_page.add_child(UIKit.header("PACKS"))
	for p in PACKS_FREE:
		var col: Color = UIKit.RARITY.get(String(p.color), UIKit.CYAN)
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UIKit.lift(UIKit.box(Color(col.r * 0.12, col.g * 0.12, col.b * 0.2, 0.82), Color(col, 0.6), 12)))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		var ic := TextureRect.new()
		ic.texture = UIKit.ic("pack_" + String(p.id), "ic_pack")   # Luna's crates (store2): daily, weekly, monthly
		ic.custom_minimum_size = Vector2(56, 56)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.add_child(ic)
		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_theme_constant_override("separation", 0)
		tv.add_child(UIKit.label(String(p.name), 14, col))
		tv.add_child(UIKit.label("FREE: " + Progress.reward_text(resolve(d, p.free)), 10, Color(0.55, 1.0, 0.6)))
		tv.add_child(UIKit.label("Paid: %s  ·  coming soon" % String(p.paid), 10, UIKit.MUTED))
		h.add_child(tv)
		var left_s := free_left_s(d, "pack_" + String(p.id), int(p.every))
		var b := UIKit.gold_button("Claim" if left_s == 0 else left_text(left_s), 13)
		b.custom_minimum_size = Vector2(96, 38)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.disabled = left_s > 0
		var pk: Dictionary = p
		b.pressed.connect(func():
			d = Progress.read()
			var why := claim_pack_in(d, pk)
			if why != "":
				_toast(why)
				return
			Progress.write(d)
			Sfx.play("coin")
			_toast("+ " + Progress.reward_text(resolve(d, pk.free)))
			_fill())
		h.add_child(b)
		card.add_child(h)
		_page.add_child(card)
	var g := _grid()
	g.add_child(_teaser(load("res://icons/starter.png"), "Stage Pack", "Beat stage 5: a pack for it"))
	g.add_child(_teaser(load("res://icons/gifts.png"), "Season Pass", "With events (2.0)"))

# A tile for what the Store will sell later (Store 2.0, dev141): the picture dimmed, a
# SOON chip where the price would be, so the page does not look half empty.
func _teaser(icon: Texture2D, big: String, small: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UIKit.lift(UIKit.box(Color(0.05, 0.07, 0.14, 0.62), Color(1, 1, 1, 0.14), 14)))
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
	UIKit.depth(p, UIKit.MUTED, false)
	return p

func _buy(o: Dictionary) -> void:
	d = Progress.read()
	if int(d.get("crystals", 0)) < int(o.price):
		return
	d["crystals"] = int(d.get("crystals", 0)) - int(o.price)
	Sfx.play("buy")
	if o.has("flag"):
		d[o.flag] = true
		_toast(o.text)
	else:
		Progress.grant(d, o.reward)
		_toast("+ " + Progress.reward_text(o.reward))
	Progress.write(d)
	_fill()

# ------------------------------------------------------------------ shop (one scrolling page)
func _fill_shop() -> void:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_page.add_child(scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 10)
	scroll.add_child(col)
	var have := Parts.read(d)
	var crystals := int(d.get("crystals", 0))
	# coins
	col.add_child(UIKit.header("COINS"))
	var g := _grid(col)
	for o in OFFERS:
		var owned: bool = o.get("once", false) and bool(d.get(o.flag, false))
		var b := _price_button(int(o.price), not owned and crystals >= int(o.price))
		if owned:
			b.text = "Owned"
			b.icon = null
		var offer: Dictionary = o
		b.pressed.connect(func(): _buy(offer))
		var speed: bool = o.id == "speed"
		var big: String = "x2 speed" if speed else "+" + UIKit.num(int(o.reward.coins))
		# Luna's coin piles (store2): three coins, a stack, a pile, a sack, by the size of the deal
		var oc: int = int(Dictionary(o.get("reward", {})).get("coins", 0))
		var pile: int = 1 + (1 if oc >= 1000 else 0) + (1 if oc >= 3000 else 0) + (1 if oc >= 10000 else 0)
		g.add_child(_tile(UIKit.ic("ic_energy", "ui_energy") if speed else UIKit.ic("coins_%d" % pile, "ic_coin"), big, o.name, o.color, b))
	# keys
	col.add_child(UIKit.header("KEYS"))
	var gk := _grid(col)
	for deal in KEY_DEALS:
		gk.add_child(_deal_tile(deal, have, crystals))
	# parts (once the Workshop is open)
	if Unlocks.open(d, "workshop"):
		col.add_child(UIKit.header("PARTS"))
		var gp := _grid(col)
		for deal in PART_DEALS:
			gp.add_child(_deal_tile(deal, have, crystals))
	# specialty: essences and the material lines
	col.add_child(UIKit.header("SPECIALTY"))
	var gs := _grid(col)
	for deal in SPECIALTY:
		gs.add_child(_deal_tile(deal, have, crystals))
	col.add_child(UIKit.label("Crystals stand in for what you are short of at the same rate, so buying here is a shortcut, never a better deal.", 10, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	col.get_child(col.get_child_count() - 1).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

# a tile selling n of a part, material or key ("ess" = the selected planet's essence)
func _deal_tile(deal: Dictionary, have: Dictionary, crystals: int) -> PanelContainer:
	var kind := String(deal.kind)
	var resolved := resolve(d, {kind: int(deal.n)})
	var real: String = resolved.keys()[0]
	var price: int = int(deal.n) * int(Parts.kind(real).crystals)
	var b := _price_button(price, crystals >= price)
	var dd: Dictionary = deal
	b.pressed.connect(func(): _buy_kind(dd))
	var icon: Texture2D = Materials.icon(real) if Materials.is_material(real) else Parts.icon(real)
	var color := String(deal.get("color", PART_COLOR.get(real, "rare")))
	return _tile(icon, "x%d" % int(deal.n), "%s  ·  have %d" % [Parts.kind(real).name, int(have.get(real, 0))], color, b)

func _buy_kind(deal: Dictionary) -> void:
	d = Progress.read()
	var reward := resolve(d, {String(deal.kind): int(deal.n)})
	var real: String = reward.keys()[0]
	var price: int = int(deal.n) * int(Parts.kind(real).crystals)
	if int(d.get("crystals", 0)) < price:
		return
	d["crystals"] = int(d.get("crystals", 0)) - price
	Progress.grant(d, reward)
	Progress.write(d)
	Sfx.play("buy")
	_toast("+ " + Progress.reward_text(reward))
	_fill()

# ------------------------------------------------------------------ crystals (real money, later)
func _fill_crystals() -> void:
	var g := _grid()
	for p in PACKS:
		var b := UIKit.ghost_button("%s  soon" % p[2], 13)
		b.disabled = true
		var name: String = p[0]
		# Luna's piles and crates (store2): a small pile for 300, the heap for 1400, the starter crate
		var icon: Texture2D = UIKit.ic("crystals_5" if name.contains("1400") else "crystals_1", "ui_crystal")
		if name.begins_with("Speed"):
			icon = load("res://icons/ui_energy.png")
		elif name.begins_with("Starter"):
			icon = UIKit.ic("pack_starter", "starter")
		g.add_child(_tile(icon, name, p[1], "epic", b))
	_page.add_child(UIKit.label("Opens on Google Play", 11, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))

# ------------------------------------------------------------------ exchange (events, 2.0)
func _fill_exchange() -> void:
	var g := _grid()
	g.add_child(_teaser(UIKit.ic("ic_token", "ui_coin"), "Event Tokens", "Trade them for chests and items"))
	g.add_child(_teaser(UIKit.ic("ic_exchange", "ic_pack"), "Season Shop", "Rank rewards every 30 days"))
	_page.add_child(UIKit.label("Events and seasons come with the online update (2.0)", 11, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))

# ------------------------------------------------------------------ code (pop-up)
func _code_popup() -> void:
	var layer := ColorRect.new()
	layer.color = Color(0, 0.01, 0.04, 0.75)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var p := UIKit.popup_panel()
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

# the chest opens in the middle of the screen: lid up, light out, then the reward (the pity
# item says so in gold)
func _chest_fx(reward: Dictionary, tier: String = "") -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0.01, 0.04, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	# Luna's tier chest (store2): the closed chest pops, then its open picture with the burst
	# takes over; without it, the old three-piece chest prop opens
	var closed := "res://icons/chest2_%s_closed.png" % tier
	var opened := "res://icons/chest2_%s_open.png" % tier
	if tier != "" and ResourceLoader.exists(closed) and ResourceLoader.exists(opened):
		var pic := TextureRect.new()
		pic.texture = load(closed)
		pic.size = Vector2(200, 200)
		pic.position = size * 0.5 - Vector2(100, 130)
		pic.pivot_offset = Vector2(100, 120)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		dim.add_child(pic)
		var ct := pic.create_tween()
		ct.tween_property(pic, "scale", Vector2(0.92, 1.06), 0.12)
		ct.tween_property(pic, "scale", Vector2(1.08, 0.94), 0.12)
		ct.tween_callback(func(): pic.texture = load(opened))
		ct.tween_property(pic, "scale", Vector2(1.18, 1.18), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		ct.tween_property(pic, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_SINE)
	else:
		var hp := HomeProp.new()
		hp.kind = "chest"
		hp.size = Vector2(180, 180)
		hp.position = size * 0.5 - Vector2(90, 120)
		dim.add_child(hp)
		hp.call_deferred("open")
	var shown := reward.duplicate()
	shown.erase("pity")
	var l := UIKit.label(("PITY ITEM!\n" if reward.get("pity", false) else "") + "+ " + Progress.reward_text(shown), 20, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	l.position = Vector2(0, size.y * 0.5 + 80.0)
	l.size = Vector2(size.x, 60)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.modulate.a = 0.0
	dim.add_child(l)
	var tw := dim.create_tween()
	tw.tween_interval(0.35)
	tw.tween_property(l, "modulate:a", 1.0, 0.25)
	tw.tween_interval(1.6)
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

# the page rises and fades in over the world (UIKit.enter, dev157); no more black cut
func _fade_in_overlay() -> void:
	UIKit.enter(self)

func _tips() -> void:
	Tips.first(get_tree(), [["calendar", _gift_btn]])
