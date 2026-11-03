extends Control
# Store: test only, nothing can be bought yet. Three tabs (Packs, Daily, Materials)
# of product tiles with a price button under each. Tapping shows the detail.

const PACKS := [
	["Coin Pack S", "+500 coins", "$0.99", "rare"], ["Coin Pack M", "+1,500 coins", "$2.49", "rare"], ["Coin Pack L", "+5,000 coins", "$6.99", "epic"],
	["Crystals x60", "premium", "$0.99", "epic"], ["Crystals x320", "premium", "$4.99", "epic"], ["Crystals x1400", "premium", "$19.99", "legendary"],
	["Starter Pack", "coins + parts + crate", "$3.99", "legendary"], ["Boost Pack", "1 day x2 coins", "$1.99", "rare"], ["Epic Crate", "1 epic crate", "$2.99", "epic"],
]
const DAILY := [
	["Coins", "+200", "Free", "common"], ["Stamina", "+10", "Free", "common"], ["Parts", "+20", "60 crystals", "rare"],
	["Gem Pouch", "+30 gems", "120 crystals", "rare"], ["Random Blueprint", "x1", "100 crystals", "epic"], ["Reforge Crystal", "x5", "150 crystals", "epic"],
]
const MATERIALS := [
	["Alloy x100", "turret material", "100 crystals", "rare"], ["Core x1", "weapon material", "20 crystals", "epic"],
	["Nano Parts x10", "armor material", "100 crystals", "rare"], ["Amplifier x10", "pilot material", "10 crystals", "legendary"],
]
var tab := 0
var _grid: GridContainer
var _detail: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
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
	var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	top.add_child(UIKit.chip("TEST ONLY", UIKit.GOLD))
	col.add_child(top)
	col.add_child(UIKit.tabs(["Packs", "Daily", "Materials"], func(i): tab = i; _fill(), 0))
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 10)
	col.add_child(_grid)
	var dp := UIKit.panel(10)
	_detail = UIKit.label("Nothing can be bought yet. Tap a product for its detail.", 12, Color(0.85, 0.92, 1.0))
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dp.add_child(_detail)
	col.add_child(dp)
	_fill()

func _fill() -> void:
	for c in _grid.get_children():
		c.queue_free()
	var list: Array = [PACKS, DAILY, MATERIALS][tab]
	for p in list:
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 4)
		var t := UIKit.tile(p[0], p[1], p[3], "", null, Vector2(140, 76))
		t.pressed.connect(func(): _detail.text = "%s (%s): %s. Test only, no checkout yet." % [p[0], p[1], p[2]])
		v.add_child(t)
		var price := UIKit.teal_button(p[2], 13) if p[2] != "Free" else UIKit.gold_button("Free", 13)
		price.custom_minimum_size = Vector2(140, 30)
		price.pressed.connect(func(): _detail.text = "%s: %s. Buying is not enabled in this build." % [p[0], p[2]])
		v.add_child(price)
		_grid.add_child(v)

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
