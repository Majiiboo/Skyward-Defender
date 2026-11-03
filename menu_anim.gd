class_name MenuAnim
extends RefCounted
# Shared button feel for every screen. Call MenuAnim.pop_buttons(self) in a
# scene's _ready.
#  - Press: quick squash to 0.95 and spring back (after the press is
#    confirmed, never on button_down, so it can't cancel a tap).
#  - Hover grow (1.04) only when there is no touchscreen: phones have no hover.
#  - Bottom-bar tabs (names starting with "Nav") are skipped: hub.gd animates
#    those itself and two animations fighting over scale looked janky.

static func pop_buttons(root: Node) -> void:
	if root is Button and not String(root.name).begins_with("Nav"):
		_setup(root)
	for child in root.get_children():
		pop_buttons(child)

static func _setup(b: Button) -> void:
	# Keep the pivot at the centre even after the layout settles or resizes.
	var centre := func(): b.pivot_offset = b.size / 2.0
	b.resized.connect(centre)
	centre.call()
	if not DisplayServer.is_touchscreen_available():
		b.mouse_entered.connect(func(): _scale_to(b, 1.04, 0.10))
		b.mouse_exited.connect(func(): _scale_to(b, 1.0, 0.10))
	b.pressed.connect(func(): _pulse(b))

static func _fresh_tween(b: Button) -> Tween:
	# One tween per button at a time, so quick taps can't stack up.
	if b.has_meta("pop_tween"):
		var old = b.get_meta("pop_tween")
		if old is Tween and old.is_valid():
			old.kill()
	var tw := b.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	b.set_meta("pop_tween", tw)
	return tw

static func _scale_to(b: Button, target: float, dur: float) -> void:
	_fresh_tween(b).tween_property(b, "scale", Vector2(target, target), dur)

static func _pulse(b: Button) -> void:
	var tw := _fresh_tween(b)
	tw.tween_property(b, "scale", Vector2(0.95, 0.95), 0.05)
	tw.tween_property(b, "scale", Vector2.ONE, 0.10)

static func panel_pop(panel: Control) -> void:
	panel.scale = Vector2(0.9, 0.9)
	panel.pivot_offset = panel.size / 2.0
	panel.create_tween().tween_property(panel, "scale", Vector2.ONE, 0.25)
