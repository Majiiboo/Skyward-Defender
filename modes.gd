extends Control
# Modes screen (redesigned dev111): one big glass card per mode with a painted world
# banner (Luna's backdrops) and the title over it, what the mode is, what it pays, and
# its button. Locked modes say what unlocks them; modes not built yet say so.
# Add a mode = add an entry to MODES.

const MODES := [
	{"id": "standard", "name": "Campaign", "banner": "", "tint": Color(0.2, 0.85, 1.0), "unlock": 0,
		"desc": "Clear stages across six planets, one boss at a time. Earn up to 3 stars per stage.",
		"rewards": ["Coins", "Parts", "Stars"]},
	{"id": "elite", "name": "Elite", "banner": "sentinel", "tint": Color(0.71, 0.45, 1.0), "unlock": 10,
		"desc": "Stages you have cleared, much tougher: bugs have 1.85x health. For geared pilots.",
		"rewards": ["Coins", "Double parts", "Plasma Cells"]},
	{"id": "horde", "name": "Horde", "banner": "magma", "tint": Color(1.0, 0.55, 0.25), "unlock": 5, "soon": true,
		"desc": "Endless waves with no stage end. Survive as long as you can and chase the high score.",
		"rewards": ["Score", "Crystals"]},
	{"id": "boss", "name": "Boss Rush", "banner": "plasma", "tint": Color(1.0, 0.35, 0.5), "unlock": 20, "soon": true,
		"desc": "Every boss you have beaten, back to back, with no waves in between.",
		"rewards": ["Void Cores", "Crystals"]},
]
var player_level := 1
var selected_stage := 1
var stage_unlocked := 1

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_load()
	_build()
	_fade_in_overlay()

func _load() -> void:
	if FileAccess.file_exists("user://skybound_save.json"):
		var f := FileAccess.open("user://skybound_save.json", FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if typeof(d) == TYPE_DICTIONARY:
				player_level = Turrets.pilot_level(int(d.get("pilot_xp", 0)))
				stage_unlocked = int(d.get("stage_unlocked", 1))
				selected_stage = clampi(int(d.get("selected_stage", 1)), 1, stage_unlocked)

func _save_patch(patch: Dictionary) -> void:
	var d := {}
	if FileAccess.file_exists("user://skybound_save.json"):
		var f := FileAccess.open("user://skybound_save.json", FileAccess.READ)
		if f:
			var p = JSON.parse_string(f.get_as_text())
			if typeof(p) == TYPE_DICTIONARY:
				d = p
	d.merge(patch, true)
	var out := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(d))

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
	col.add_theme_constant_override("separation", 14)
	root.add_child(col)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	var back := UIKit.ghost_button("Back")
	back.name = "BackButton"
	back.custom_minimum_size = Vector2(70, 32)
	back.pressed.connect(_on_back_pressed)
	top.add_child(back)
	top.add_child(UIKit.screen_title("MODES"))
	col.add_child(top)
	for m in MODES:
		col.add_child(_card(m))

func _card(m: Dictionary) -> Control:
	var locked: bool = player_level < int(m.unlock)
	var soon: bool = m.get("soon", false)
	var tint: Color = m.tint
	var p := UIKit.panel(16)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	# banner: a painted world, the title over its lower edge, a status chip at the right
	var banner := Control.new()
	banner.custom_minimum_size = Vector2(0, 108)
	banner.clip_contents = true
	var key: String = m.banner if m.banner != "" else String(StageData.sector(selected_stage).get("bg", "hive_a"))
	var tex: Texture2D = load("res://backdrops/%s.webp" % key)
	# the lit landscape near the bottom of the tall world painting, not its dark sky
	var crop := AtlasTexture.new()
	crop.atlas = tex
	var ch: float = tex.get_width() / 3.6
	crop.region = Rect2(0, tex.get_height() - ch * 1.25, tex.get_width(), ch)
	var pic := TextureRect.new()
	pic.texture = crop
	pic.set_anchors_preset(Control.PRESET_FULL_RECT)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if locked or soon:
		pic.modulate = Color(0.62, 0.62, 0.72)
	elif m.id == "elite":
		pic.modulate = Color(0.75, 0.6, 1.0)
	banner.add_child(pic)
	var shade := Control.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.draw.connect(func():
		var s := shade.size
		var clear := Color(0.02, 0.03, 0.08, 0.0)
		var dark := Color(0.02, 0.03, 0.08, 0.85)
		shade.draw_polygon(PackedVector2Array([Vector2(0, s.y * 0.35), Vector2(s.x, s.y * 0.35), s, Vector2(0, s.y)]),
			PackedColorArray([clear, clear, dark, dark]))
		shade.draw_line(Vector2(0, s.y - 1), Vector2(s.x, s.y - 1), Color(tint, 0.8), 2.0))
	banner.add_child(shade)
	var title := UIKit.label(String(m.name).to_upper(), 22, Color.WHITE)
	title.add_theme_font_override("font", load("res://fonts/Orbitron-Variable.ttf"))
	title.position = Vector2(12, 70)
	banner.add_child(title)
	var chip_text := "COMING SOON" if soon else ("UNLOCKS AT PILOT LV.%d" % int(m.unlock) if locked else ("STAGE %d" % selected_stage if m.id != "boss" else "READY"))
	var chip := UIKit.chip(chip_text, UIKit.GOLD if (locked or soon) else tint)
	chip.position = Vector2(10, 10)
	banner.add_child(chip)
	v.add_child(banner)
	var d := UIKit.label(m.desc, 13, Color(0.82, 0.9, 1.0))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for r in m.rewards:
		row.add_child(UIKit.chip(r, tint))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	var b: Button
	if soon or locked:
		b = UIKit.ghost_button("Coming soon" if soon else "Locked", 13)
		b.disabled = true
	else:
		b = UIKit.gold_button("Play", 15)
		var elite: bool = m.id == "elite"
		b.pressed.connect(func():
			_save_patch({"selected_elite": elite})
			get_tree().change_scene_to_file("res://battle.tscn"))
	b.custom_minimum_size = Vector2(110, 38)
	row.add_child(b)
	v.add_child(row)
	return p

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
