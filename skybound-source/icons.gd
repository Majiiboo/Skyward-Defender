class_name Icons
extends RefCounted
# One place that knows where icons live. Every icon is a crisp vector
# (SVG) in res://icons/, so it stays sharp on any phone screen.
# Use: button.icon = Icons.get_icon("nav_store")
static func get_icon(icon_name: String) -> Texture2D:
	return load("res://icons/%s.svg" % icon_name) as Texture2D
