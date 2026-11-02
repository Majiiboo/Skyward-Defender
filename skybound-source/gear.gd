extends Control
# Gear, Menus 0.5: soldier on the LEFT, slots on the RIGHT.
# Equipped items show in the slots, and the soldier on the left changes
# immediately when you equip — no click-in, go-back to see him.
# Inventory is UNDERNEATH the slots. Tap an inventory item to equip it.
# Upgrades are show-only in Menus 0.5: detail + price, no spending yet.

@onready var hero_label: Label = $HeroLabel
@onready var detail_label: Label = $DetailLabel
var equipped := {
	"Helmet": "Sleek Helmet",
	"Weapon": "Single Rifle",
	"Chest": "Charcoal Plate",
	"Gauntlets": "Grip Gauntlets",
	"Boots": "Hover Boots",
	"Power Orb": "Purple Orb",
}
var slot_buttons := {}
var inventory := {
	"Helmet": ["Teal Helmet", "White Helmet", "Grey/Orange Helmet"],
	"Weapon": ["Double Rifle", "Cannon"],
	"Chest": ["Teal Plate", "White Plate"],
	"Gauntlets": ["Teal Gauntlets", "White Gauntlets"],
	"Boots": ["Teal Boots", "White Boots"],
	"Power Orb": ["Cyan Orb", "Teal Orb"],
}
var selected_slot := "Helmet"

func _ready() -> void:
	size = get_viewport_rect().size
	$Background.size = size
	_fade_in_overlay()
	MenuAnim.pop_buttons(self)
	_build_slots()
	_build_inventory()
	_show_detail("Helmet")
	MenuStyle.style_all(self)

func _build_slots() -> void:
	var container: GridContainer = $Slots
	for slot in equipped.keys():
		var b := Button.new()
		b.text = "%s\n%s Lv1" % [slot, equipped[slot]]
		b.custom_minimum_size = Vector2(130, 60)
		b.add_theme_font_size_override("font_size", 14)
		b.pressed.connect(func(): _show_detail(slot))
		container.add_child(b)
		slot_buttons[slot] = b

func _build_inventory() -> void:
	var container: GridContainer = $Inventory
	for slot in inventory.keys():
		for item in inventory[slot]:
			var b := Button.new()
			b.text = "%s\n%s" % [slot, item]
			b.custom_minimum_size = Vector2(140, 50)
			b.add_theme_font_size_override("font_size", 14)
			b.pressed.connect(func(): _equip(slot, item))
			container.add_child(b)

func _equip(slot: String, item: String) -> void:
	equipped[slot] = item
	slot_buttons[slot].text = "%s\n%s Lv1" % [slot, item]
	hero_label.text = "SOLDIER\nCharcoal / Purple\nEquipped: %s" % item
	_show_detail(slot)

func _show_detail(slot: String) -> void:
	selected_slot = slot
	var item: String = equipped[slot]
	var cost := 200
	detail_label.text = "%s — %s Lv1\nStats: +10 power, +5 defence (example, show-only)\nUpgrade cost: %d coins — No spending yet in Menus 0.5.\nBattle rewards update will enable spending." % [slot, item, cost]

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://hub.tscn")

func _on_upgrade_pressed() -> void:
	detail_label.text = "%s — %s Lv1\nUpgrade will cost 200 coins.\nNo spending yet in Menus 0.5 — detail + price only,\ndeveloping as we go, battle rewards coming next." % [selected_slot, equipped[selected_slot]]

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
