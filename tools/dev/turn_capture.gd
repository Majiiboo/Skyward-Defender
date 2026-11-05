extends SceneTree
# Captures the pilot turning round (dev158 check): a PilotRigView alone on black, fed an
# aim that swings from left to right over two seconds. Run with --write-movie to get frames:
#   cp tools/sim_override.cfg override.cfg (+ [display] lines); godot --path . --script
#   res://tools/dev/turn_capture.gd --write-movie out/t.png --quit-after 90
var view: PilotRigView
var t := 0.0
func _initialize() -> void:
	var root_node := Node2D.new()
	root.add_child(root_node)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.08)
	bg.size = Vector2(480, 960)
	root_node.add_child(bg)
	PilotRig.set_gear(Progress.read())
	view = PilotRigView.new()
	view.height = 220.0
	root_node.add_child(view)
func _process(delta: float) -> bool:
	if view == null:
		return false
	t += delta
	# left for 0.5 s, then swing to the right over 1 s, hold
	var k := clampf((t - 0.5) / 1.0, 0.0, 1.0)
	var aim := lerpf(-PI / 2.0 - 0.9, -PI / 2.0 + 0.9, smoothstep(0.0, 1.0, k))
	view.update(delta, Vector2(240, 520), aim, (k - 0.5) * 0.6 if k > 0.0 and k < 1.0 else 0.0, 1.0, 0.0)
	if Engine.get_process_frames() % 3 == 0:
		print("f%03d t=%.2f aim=%.2f face=%.2f side_a=%.2f front_a=%.2f" % [Engine.get_process_frames(), t, aim, view.rig.face, view._side_a(), view._front_a()])
	return false
