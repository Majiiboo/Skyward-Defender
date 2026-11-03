extends Control
# Quests: Daily, Event and Career tabs. Each quest row shows progress and a
# reward; Claim is show-only until battle rewards exist.

const QUESTS := {
	"Daily": [
		["Kill 10 enemies", 0, 10, "50 coins"], ["Clear 2 waves", 0, 2, "50 coins"], ["Collect 20 gems", 0, 20, "50 coins"],
		["Survive 60 seconds", 0, 60, "75 coins"], ["Kill 25 enemies", 0, 25, "75 coins"], ["Use 1 power-up", 0, 1, "50 coins"],
		["Clear Stage 1", 0, 1, "100 coins"], ["Kill 1 Elite", 0, 1, "100 coins"], ["Collect 100 coins", 0, 100, "75 coins"], ["Defeat 1 boss", 0, 1, "150 coins"],
	],
	"Event": [["Ember Reach festival", 0, 3, "Epic crate"], ["Nova Drift trial", 0, 5, "300 coins"]],
	"Career": [["Reach pilot level 5", 1, 5, "Dual Minis"], ["Clear 5 stages", 0, 5, "500 coins"], ["Kill 500 enemies", 0, 500, "Legendary crate"]],
}
var tab := 0
var _list: VBoxContainer
var _note: Label

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
	top.add_child(UIKit.screen_title("QUESTS"))
	col.add_child(top)
	col.add_child(UIKit.tabs(["Daily", "Event", "Career"], func(i): tab = i; _fill(), 0))
	_note = UIKit.label("", 12, UIKit.MUTED)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_note)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	col.add_child(_list)
	_fill()

func _fill() -> void:
	for c in _list.get_children():
		c.queue_free()
	var key: String = ["Daily", "Event", "Career"][tab]
	_note.text = {"Daily": "10 missions a day. Finish all 10 for an epic crate + 300 coins. Crates at 3, 6 and 9.",
		"Event": "Seasonal events. Rewards claimable while the event runs.",
		"Career": "Long-term goals that never reset."}[key]
	for q in QUESTS[key]:
		var p := UIKit.panel(10)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var body := VBoxContainer.new()
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.add_theme_constant_override("separation", 3)
		body.add_child(UIKit.label(q[0], 14, Color.WHITE))
		var bar := ProgressBar.new()
		bar.min_value = 0; bar.max_value = q[2]; bar.value = q[1]
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 8)
		bar.add_theme_stylebox_override("background", UIKit.box(Color(1, 1, 1, 0.08), Color(1, 1, 1, 0.0), 4))
		bar.add_theme_stylebox_override("fill", UIKit.box(UIKit.CYAN, Color(UIKit.CYAN, 0.0), 4))
		body.add_child(bar)
		var meta := HBoxContainer.new()
		meta.add_theme_constant_override("separation", 8)
		meta.add_child(UIKit.label("%d / %d" % [q[1], q[2]], 11, UIKit.MUTED))
		meta.add_child(UIKit.chip(q[3], UIKit.GOLD))
		body.add_child(meta)
		row.add_child(body)
		var done: bool = q[1] >= q[2]
		var b := UIKit.gold_button("Claim", 13) if done else UIKit.ghost_button("Go", 13)
		b.custom_minimum_size = Vector2(70, 34)
		if done:
			b.pressed.connect(func(): _note.text = "Claim is show-only until battle rewards are in.")
		else:
			b.pressed.connect(func(): get_tree().change_scene_to_file("res://battle.tscn"))
		var av := VBoxContainer.new()
		av.alignment = BoxContainer.ALIGNMENT_CENTER
		av.add_child(b)
		row.add_child(av)
		p.add_child(row)
		_list.add_child(p)

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
