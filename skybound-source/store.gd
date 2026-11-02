extends Control
# Store, Menus 0.5: SIMPLIFIED, TEST ONLY.
# Web store was too busy / hectic. Now: 9 items total, 3x3 grid,
# simple cards, no tabs, no long lists. Tap a card for detail.
# No purchase yet — test only.

@onready var detail_label: Label = $DetailLabel
var packs := [
	["Coin Pack S", "+500 coins"],
	["Coin Pack M", "+1,500 coins"],
	["Coin Pack L", "+5,000 coins"],
	["Parts Pack S", "+20 parts"],
	["Parts Pack M", "+60 parts"],
	["Crate Pack", "1 crate"],
	["Epic Crate", "1 epic crate"],
	["Boost Pack", "1 day boost"],
	["Starter Pack", "Coins + parts"],
]

func _ready() -> void:
	size = get_viewport_rect().size
	$Background.size = size
	_fade_in_overlay()
	MenuAnim.pop_buttons(self)
	var grid: GridContainer = $Grid
	for p in packs:
		var b := Button.new()
		b.text = "%s\n%s" % [p[0], p[1]]
		b.custom_minimum_size = Vector2(140, 80)
		b.pressed.connect(func(): _show_pack(p[0], p[1]))
		grid.add_child(b)
	MenuStyle.style_all(self)
	detail_label.text = "TEST ONLY — No purchase yet.\nTap a pack for its detail."

func _show_pack(name: String, reward: String) -> void:
	detail_label.text = "%s — %s\nTEST ONLY in Menus 0.5.\nNo purchase, no checkout yet.\nStore will be enabled with battle rewards." % [name, reward]

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://hub.tscn")

func _fade_in_overlay() -> void:
	# Destination side of Hub's fade-to-black: start black, fade out.
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 1)
	overlay.size = size
	add_child(overlay)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(overlay, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func(): overlay.queue_free())
