extends SceneTree
# Screen capture of a menu scene with a made-up save (headless check of a page's layout).
# Uses the sim save folder, so the real save is never touched:
#   cp tools/sim_override.cfg override.cfg; printf '[display]\nwindow/size/viewport_width=480\nwindow/size/viewport_height=960\nwindow/size/mode=0\n' >> override.cfg
#   CAP_SCENE=res://gear.tscn CAP_PAGE=3 CAP_WS=1 CAP_SAVE=tools/dev/save_rich.json \
#     godot --path . --script res://tools/dev/capture.gd --write-movie out/gear.png --quit-after 40
#   rm override.cfg
# Env: CAP_SCENE (scene to open), CAP_PAGE (Gear tab 0-3), CAP_WS (Workshop sub-tab),
# CAP_SAVE (json file copied over the sim save; none = keep what is there), CAP_AUTOPICK=1
# (battle: take the first card at every pick so a --write-movie run plays on).

func _initialize() -> void:
	var sv := OS.get_environment("CAP_SAVE")
	if sv != "":
		var f := FileAccess.open(sv, FileAccess.READ)
		if f:
			var out := FileAccess.open("user://skybound_save.json", FileAccess.WRITE)
			out.store_string(f.get_as_text())
			out.close()
			print("save written from ", sv, " to ", ProjectSettings.globalize_path("user://skybound_save.json"))
	var page := OS.get_environment("CAP_PAGE")
	if page != "":
		root.set_meta("gear_page", int(page))
	var ws := OS.get_environment("CAP_WS")
	if ws != "":
		root.set_meta("gear_ws_tab", int(ws))
	# CAP_META="store_tab=1,quests_tab=2": any root metas a page reads on open
	for pair in OS.get_environment("CAP_META").split(",", false):
		root.set_meta(pair.get_slice("=", 0), int(pair.get_slice("=", 1)))
	var scene := OS.get_environment("CAP_SCENE")
	change_scene_to_file(scene if scene != "" else "res://gear.tscn")
	# CAP_CALL="method|arg|arg": call that on the scene once it has settled (opens a pop-up)
	var call := OS.get_environment("CAP_CALL")
	if call != "":
		_pending = call.split("|")

var _pending := PackedStringArray()
var _frames := 0

func _process(_delta: float) -> bool:
	# CAP_AUTOPICK=1: in a battle, take the first power card whenever the pick opens, so a
	# movie of a run plays on by itself (dev168)
	if OS.get_environment("CAP_AUTOPICK") == "1" and current_scene != null and current_scene.get("picking") == true:
		var offer: Array = current_scene._offer()
		if not offer.is_empty():
			current_scene._pick_card(offer[0])
	if _pending.is_empty() or current_scene == null:
		return false
	_frames += 1
	if _frames == 10:
		var args: Array = []
		for i in range(1, _pending.size()):
			args.append(_pending[i])
		current_scene.callv(_pending[0], args)
		_pending = PackedStringArray()
	return false
