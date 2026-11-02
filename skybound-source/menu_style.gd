class_name MenuStyle
extends RefCounted
# Look for the menu screens (Gear, Modes, Quests, Store): boxed buttons with
# an icon picked from the button's text. (Home gets its look from
# game_theme.tres instead; the colours here match it.)

# If a button's text contains the first word, it gets the second icon.
# First match wins. Icons live in res://icons/ as SVG (see icons.gd).
const ICON_BY_TEXT := [
	["Gear", "nav_gear"], ["Home", "home"], ["Modes", "nav_modes"],
	["Quests", "nav_quests"], ["Store", "nav_store"], ["BATTLE", "nav_battle"],
	["Event", "event"], ["Promo", "promo"], ["Starter", "starter"],
	["Daily", "daily"], ["Gifts", "gifts"], ["Ranks", "ranks"],
	["Chest", "chest"], ["Patrol", "patrol"],
	["Standard", "nav_modes"], ["Horde", "nav_modes"],
]
const ICON_SIZE := 32  # icons are drawn at most this wide inside menu buttons

static func style_all(root: Node) -> void:
	if root is Button:
		_style_button(root)
	elif root is Panel:
		root.add_theme_stylebox_override("panel", _box(Color(0.7, 0.5, 1.0)))
	for child in root.get_children():
		style_all(child)

static func _style_button(b: Button) -> void:
	b.add_theme_stylebox_override("normal", _box(Color(0.2, 0.85, 1.0)))
	b.add_theme_stylebox_override("hover", _box(Color(0.7, 0.5, 1.0)))
	b.add_theme_stylebox_override("pressed", _box(Color(1, 0.8, 0.3)))
	for pair in ICON_BY_TEXT:
		if pair[0] in b.text:
			b.icon = Icons.get_icon(pair[1])
			b.add_theme_constant_override("icon_max_width", ICON_SIZE)
			break

static func _box(border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.11, 0.22, 1)
	s.set_border_width_all(2)
	s.border_color = border
	s.set_corner_radius_all(12)
	s.shadow_size = 4
	s.shadow_color = Color(0, 0, 0, 0.5)
	s.shadow_offset = Vector2(0, 3)
	return s
