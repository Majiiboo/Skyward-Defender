extends Control
# Modes, Menus 0.5: Standard, Elite (locked until Lv 10, worth it),
# and Horde (endless, score chase). Player level is 1 in Menus 0.5,
# so Elite shows locked. Battle update will unlock it at Lv 10.

@onready var detail_label: Label = $DetailLabel

func _ready() -> void:
	size = get_viewport_rect().size
	$Background.size = size
	_fade_in_overlay()
	MenuAnim.pop_buttons(self)
	MenuStyle.style_all(self)
	detail_label.text = "Tap a mode to see its detail."

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://hub.tscn")

func _on_standard_pressed() -> void:
	detail_label.text = "STANDARD\nNormal waves, normal rewards.\nPlay Stage 1 in battle now."

func _on_standard_play_pressed() -> void:
	get_tree().change_scene_to_file("res://battle.tscn")

func _on_elite_pressed() -> void:
	detail_label.text = "ELITE — LOCKED\nLocked until Level 10 (you are Level 1).\nWorth it: x1.85 enemy HP, x2 parts, x1.5 coins.\nTougher enemies, bigger rewards."

func _on_horde_pressed() -> void:
	detail_label.text = "HORDE\nEndless waves, score chase.\nSurvive as long as you can. No stage end.\nHorde waves come in the battle update —\nPlay button below plays the current battle for now."

func _on_horde_play_pressed() -> void:
	get_tree().change_scene_to_file("res://battle.tscn")

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
