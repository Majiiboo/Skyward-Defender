class_name Tips
extends RefCounted
# Guided first-time tips (Rudy, queue 15, dev163). The first time something new is on screen
# the game dims, spotlights the ONE control to tap, and the chibi pilot says in a small glass
# box what it is and "Tap here". Only that control works (a tap inside the spotlight presses
# it); "Got it" closes the tip without pressing. Each tip shows once: save "tips": [ids].
# Pages call Tips.first(tree, [[id, control], ...]) after they are laid out: the first unseen
# tip in the list shows (one per visit, so new players are never buried).

const TIPS := {
	"patrol":        {"title": "PATROL FARMS FOR YOU", "text": "Your pilot farms a cleared stage while you are away: coins, parts, now and then a gear copy. Collect here."},
	"stage_map":     {"title": "THE STAGE MAP", "text": "Tap the stage name to see every stage, its stars and what it drops."},
	"elite":         {"title": "ELITE UNLOCKED", "text": "Cleared stages, bugs almost twice as tough, better parts. Switch here when you feel strong."},
	"red_dots":      {"title": "A RED DOT MEANS A REWARD", "text": "Anywhere you see a red dot, something is waiting: a finished task, a gift, a merge. Tap it."},
	"gear_upgrade":  {"title": "UPGRADE YOUR GEAR", "text": "Coins make the piece you wear stronger. Every slot boosts one battle stat; every 5 levels is a milestone."},
	"gear_kits":     {"title": "SAVED KITS", "text": "Save what you wear, your turrets and your drone as a kit, and switch kits in one tap."},
	"turrets":       {"title": "TURRETS GUARD THE BASE", "text": "Pick a turret, place it on a mount, then upgrade its ATK, Rate and Range. More mounts open as you clear stages."},
	"drone":         {"title": "YOUR DRONE SIDEKICK", "text": "It flies beside you and shoots with you. Choose its body and weapon pod, and upgrade it with coins."},
	"workshop":      {"title": "THE WORKSHOP", "text": "Three parts of one kind merge into one of the next: Alloy into Cells, Cells into Cores. Higher upgrades need them."},
	"workshop_gear": {"title": "GEAR COPIES", "text": "Stages and Patrol drop copies of gear. Three copies of one rarity merge into the next rarity, which raises that piece's level cap."},
	"quick_merge":   {"title": "QUICK MERGE", "text": "Merges every Common and Uncommon stack at once. Rare and above you merge by hand, so you keep what you like."},
	"promotion":     {"title": "RANK TRIALS", "text": "One hard stage per rank. Win it once and you are promoted for good: more damage and a tougher base, forever."},
	"calendar":      {"title": "YOUR DAILY GIFT", "text": "A gift every day you come back; day 7 is the big one. Missing a day does not reset the week."},
	"cards":         {"title": "POWER CARDS", "text": "Gems fill your run level; each level offers three cards. Pick one: they stack for the whole stage."},
}
static var active := false
const ENABLED := false   # Rudy (dev166 playtest): off until the tips are redone for new elements only

static func seen(id: String) -> bool:
	var t = Progress.read().get("tips", [])
	return typeof(t) == TYPE_ARRAY and t.has(id)

static func mark(id: String) -> void:
	var d := Progress.read()
	var t = d.get("tips", [])
	if typeof(t) != TYPE_ARRAY:
		t = []
	if not t.has(id):
		t.append(id)
	d["tips"] = t
	Progress.write(d)

static func reset() -> void:
	var d := Progress.read()
	d["tips"] = []
	Progress.write(d)

# the first unseen tip of the list, shown once the page has laid out
static func first(tree: SceneTree, list: Array) -> void:
	if not ENABLED or active or tree == null:
		return
	for item in list:
		var id: String = item[0]
		if TIPS.has(id) and not seen(id):
			show(tree, id, item[1])
			return

static func show(tree: SceneTree, id: String, target: Control) -> void:
	if not ENABLED or active or not TIPS.has(id) or seen(id):
		return
	active = true
	var host: Node = tree.current_scene
	if host == null:
		active = false
		return
	var layer := Layer.new()
	layer.id = id
	layer.target = target
	host.add_child(layer)

# The overlay: a dim with a hole over the target, a pulsing ring, the pilot's box.
class Layer extends Control:
	var id := ""
	var target: Control
	var t := 0.0
	var hole := Rect2()
	var _box: PanelContainer
	var _helmet: Texture2D

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		z_index = 100
		_helmet = load("res://pilot_front/helmet.png") if ResourceLoader.exists("res://pilot_front/helmet.png") else null
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
		await get_tree().process_frame   # the page has laid out: the target's rect is right
		_layout()

	func _layout() -> void:
		var vp := get_viewport().get_visible_rect()
		global_position = Vector2.ZERO
		size = vp.size
		if target != null and is_instance_valid(target) and target.is_visible_in_tree():
			hole = target.get_global_rect().grow(8.0)
		else:
			hole = Rect2(size.x * 0.5 - 1.0, size.y * 0.45, 2.0, 2.0)
		var tip: Dictionary = Tips.TIPS[id]
		_box = UIKit.panel(14)
		var w := minf(size.x - 32.0, 400.0)
		_box.custom_minimum_size = Vector2(w, 0)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		if _helmet:
			var tr := TextureRect.new()
			tr.texture = _helmet
			tr.custom_minimum_size = Vector2(56, 56)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			h.add_child(tr)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 4)
		v.add_child(UIKit.label(tip.title, 15, UIKit.GOLD))
		var body := UIKit.label(tip.text, 13, Color.WHITE)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(body)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var hint := UIKit.label("Tap the lit button" if target != null else "", 11, UIKit.CYAN)
		hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(hint)
		var ok := UIKit.ghost_button("Got it", 12)
		ok.custom_minimum_size = Vector2(80, 30)
		ok.pressed.connect(func(): _close(false))
		row.add_child(ok)
		v.add_child(row)
		h.add_child(v)
		_box.add_child(h)
		add_child(_box)
		# below the target when there is room, else above; never off the sides
		var bx := clampf(hole.get_center().x - w * 0.5, 16.0, size.x - w - 16.0)
		var below := hole.end.y + 150.0 < size.y
		_box.position = Vector2(bx, hole.end.y + 18.0 if below else hole.position.y - 150.0)
		_box.resized.connect(func():
			if not below:
				_box.position.y = hole.position.y - _box.size.y - 18.0)
		UIKit.pop_in(_box)

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var dim := Color(0.0, 0.01, 0.04, 0.72)
		# four bands around the hole
		draw_rect(Rect2(0, 0, size.x, hole.position.y), dim)
		draw_rect(Rect2(0, hole.end.y, size.x, size.y - hole.end.y), dim)
		draw_rect(Rect2(0, hole.position.y, hole.position.x, hole.size.y), dim)
		draw_rect(Rect2(hole.end.x, hole.position.y, size.x - hole.end.x, hole.size.y), dim)
		if hole.size.x > 4.0:
			# a pulsing ring of light round the control, and a soft glow
			var k := 0.5 + 0.5 * sin(t * 4.0)
			var r := hole.grow(3.0 + 5.0 * k)
			var col := Color(UIKit.CYAN, 0.55 + 0.4 * k)
			draw_rect(r, col, false, 2.0)
			draw_rect(hole.grow(1.0), Color(1, 1, 1, 0.35), false, 1.0)

	func _gui_input(ev: InputEvent) -> void:
		var pressed: bool = (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed)
		if not pressed:
			return
		var p: Vector2 = ev.position + global_position
		if hole.has_point(p) and target != null and is_instance_valid(target):
			_close(true)

	func _close(press: bool) -> void:
		Tips.mark(id)
		Tips.active = false
		var tgt := target
		queue_free()
		if press and tgt is BaseButton:
			tgt.pressed.emit()
