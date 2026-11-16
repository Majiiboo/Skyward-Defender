class_name FightPreview
# THE TRY WINDOW (Rudy 2026-11-16): the Weapon page can open a small window in which the REAL
# fight runs (battle.tscn inside a SubViewport) with the hero, his weapon and its chips, so a
# weapon or a chip is seen doing what it really does, at fight scale, before it is fitted or
# even bought. battle.gd knows it is in the window (`_preview` = its viewport is a SubViewport):
# it reads FightPreview.save in place of the save file, writes nothing, shows no HUD, takes no
# damage, offers no cards, flies on autopilot and starts the stage over when it ends.

static var save: Dictionary = {}

const VIEW := Vector2i(480, 760)   # the fight's own size inside the window (the game is 480 wide)

# the save the window fights with: the player's own, with `chips` (three ids, "" = empty) in the
# weapon in hand whether owned or not
static func make_save(real: Dictionary, hid: String, cls: String, chips: Array) -> Dictionary:
	var d := real.duplicate(true)
	d["selected_mode"] = "normal"
	d["selected_elite"] = false
	d["game_speed"] = 1.0
	var c := Chips.read(d)
	for id in chips:
		if Chips.CHIPS.has(String(id)) and not c.owned.has(String(id)):
			c.owned.append(String(id))
	c.fit[Arsenal.key(hid, cls)] = chips.duplicate()
	d["chips"] = c
	return d

# builds the window's picture: a SubViewport with the fight in it, shown by a TextureRect
static func make_view(host: Control, width: float) -> TextureRect:
	var vp := SubViewport.new()
	vp.size = VIEW
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.disable_3d = true
	vp.gui_disable_input = true
	host.add_child(vp)
	vp.add_child(load("res://battle.tscn").instantiate())
	var tr := TextureRect.new()
	tr.texture = vp.get_texture()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.custom_minimum_size = Vector2(width, width * VIEW.y / float(VIEW.x))
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr
