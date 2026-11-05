extends SceneTree
# Draws the four Hive bugs large on a dark background, animating, to tune EnemyRig part
# placement (dev161). Frames via --write-movie; BUG_SAC=1 shows the Spitter sac full.
#   godot --path . --script res://tools/dev/bug_capture.gd --write-movie out/b.png --quit-after 40
var node: Node2D
var t := 0.0
func _initialize() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.12, 0.2)
	bg.size = Vector2(480, 960)
	root.add_child(bg)   # behind the bugs (a child would draw over them)
	node = Node2D.new()
	root.add_child(node)
	node.draw.connect(_draw)
func _draw() -> void:
	var kinds := ["scout", "drifter", "spitter", "diver"]
	for i in kinds.size():
		var pos := Vector2(120 + (i % 2) * 240, 240 + (i / 2) * 400)
		var tilt := sin(t * 0.8 + i) * 0.25
		EnemyRig.draw_bug(node, kinds[i], pos, 230.0, t, float(i), tilt, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, (0.5 + 0.5 * sin(t * 1.5)) if kinds[i] == "spitter" else -1.0)
		node.draw_circle(pos, 3.0, Color(1, 0.3, 0.3))   # the bug's centre
func _process(delta: float) -> bool:
	t += delta
	if node:
		node.queue_redraw()
	return false
