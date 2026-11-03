class_name Icons
extends RefCounted
# One place that knows where icons live. Painted icons are PNG (Luna's sheet);
# anything without a painted version falls back to the vector SVG.
# Use: button.icon = Icons.get_icon("nav_store")
static func get_icon(icon_name: String) -> Texture2D:
	var png := "res://icons/%s.png" % icon_name
	if ResourceLoader.exists(png):
		return load(png) as Texture2D
	return load("res://icons/%s.svg" % icon_name) as Texture2D
