extends Control
# Quests, Menus 0.5: Daily, Event, Career tabs.
# Daily: each mission gives coins when claimed, finish all 10 gives
# a crate (crate at 3/6/9, epic at 10, as in web). Claims are show-only
# in Menus 0.5: reward shown, no granting yet.
# Career: chains, current step ONLY, not a list of all steps.
# When a step is claimed (in future), it is REPLACED by the next step
# in the same chain — e.g. Kill 10 -> Kill 25 -> Kill 100 -> Kill 1000.

@onready var content_label: Label = $ContentLabel
var current_tab := "Daily"

func _ready() -> void:
	size = get_viewport_rect().size
	$Background.size = size
	_fade_in_overlay()
	MenuAnim.pop_buttons(self)
	MenuStyle.style_all(self)
	_show_daily()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://hub.tscn")

func _on_daily_pressed() -> void:
	current_tab = "Daily"
	_show_daily()

func _on_event_pressed() -> void:
	current_tab = "Event"
	content_label.text = "EVENT\nWinter Event — coming with the battle update.\n\nEvent missions (show-only):\n- Clear 3 waves in Winter theme — 100 coins\n- Defeat 1 Winter boss — 200 coins\n- Collect 50 gems — 150 coins"

func _on_career_pressed() -> void:
	current_tab = "Career"
	content_label.text = "CAREER — CHAINS (current step only, next replaces it)\n\nKills Chain: Kill 10 enemies — 0/10 — 50 coins\n  Next: Kill 25 enemies\n\nStages Chain: Clear Stage 1 — 0/1 — 100 coins\n  Next: Clear Stage 3\n\nCoins Chain: Earn 500 coins — 0/500 — 75 coins\n  Next: Earn 2,000 coins\n\nClaiming a step replaces it with the next step\nin the same chain. No list of all steps at once."

func _show_daily() -> void:
	content_label.text = "DAILY — 10 missions, coins per mission\nFinish all 10: Epic crate + 300 coins\nCrate at 3, 6, 9 missions\n\n1. Kill 10 enemies — 50 coins\n2. Clear 2 waves — 50 coins\n3. Collect 20 gems — 50 coins\n4. Survive 60 seconds — 75 coins\n5. Kill 25 enemies — 75 coins\n6. Use 1 power-up — 50 coins\n7. Clear Stage 1 — 100 coins\n8. Kill 1 Elite — 100 coins\n9. Collect 100 coins — 75 coins\n10. Defeat 1 boss — 150 coins\n\nClaim buttons are show-only in Menus 0.5:\nreward shown, no granting yet."

func _on_claim_pressed() -> void:
	content_label.text = "%s\n\nClaim will give the reward shown above.\nNo granting yet in Menus 0.5 —\nbattle rewards update will enable claiming." % content_label.text

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
