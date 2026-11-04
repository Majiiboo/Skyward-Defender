class_name SafeAreaMargin
extends MarginContainer
# Gemini safe_area_margin.gd, adapted with a 12px floor.
# Gemini used max(0, safe) — on a phone with no notch that would put
# the top bar at the very edge, so we floor at 12 (our normal margin).
# Reusable: attach to any MarginContainer, toggle sides in Inspector.
@export var apply_top: bool = true
@export var apply_bottom: bool = true
@export var apply_left: bool = true
@export var apply_right: bool = true

# How far the phone's notch / camera cutout reaches down from the top, in game units
# (0 on phones without one, or on PC). Android draws the game behind the cutout
# (export: screen/edge_to_edge), so screens keep their top buttons below this line.
static func top_inset(vp: Viewport) -> float:
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var win: Vector2i = DisplayServer.window_get_size()
	if win.y <= 0 or safe.size.y <= 0:
		return 0.0
	return maxf(0.0, safe.position.y * vp.get_visible_rect().size.y / float(win.y))

func _ready() -> void:
	_update_safe_margins()
	# Re-check if window changes size (orientation change on mobile)
	get_tree().root.size_changed.connect(_update_safe_margins)

func _update_safe_margins() -> void:
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var window_size: Vector2i = DisplayServer.window_get_size()
	if window_size.x == 0 or window_size.y == 0:
		return
	# Scale between window pixels and viewport game units — crucial
	# for Godot's stretch mode scaling.
	var scale_factor = get_viewport().get_visible_rect().size / Vector2(window_size)
	var safe_top = safe_area.position.y * scale_factor.y
	var safe_left = safe_area.position.x * scale_factor.x
	var safe_bottom = (window_size.y - (safe_area.position.y + safe_area.size.y)) * scale_factor.y
	var safe_right = (window_size.x - (safe_area.position.x + safe_area.size.x)) * scale_factor.x
	if apply_top:
		add_theme_constant_override("margin_top", int(max(4, safe_top)))
	if apply_bottom:
		add_theme_constant_override("margin_bottom", int(max(12, safe_bottom)))
	if apply_left:
		add_theme_constant_override("margin_left", int(max(12, safe_left)))
	if apply_right:
		add_theme_constant_override("margin_right", int(max(12, safe_right)))
