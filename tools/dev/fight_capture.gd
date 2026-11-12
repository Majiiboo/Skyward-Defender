extends SceneTree
# Shows a fight hero (HeroFight) large and alone, put through his moves, 1.2 s each:
# still, right, stop, left, stop, forward, back, firing, a heavy shot, a hit, the ability.
#   cp tools/sim_override.cfg override.cfg (+ [display] 480x960 lines); CAP_SAVE as in capture.gd
#   godot --path . --script res://tools/dev/fight_capture.gd --write-movie out/f.png --fixed-fps 30 --quit-after 400
var view: PilotRigView
var t := 0.0
var at := Vector2(240, 520)
var _shot := 0.0
var _did := {}
const STEP := 1.2

func _initialize() -> void:
	var root_node := Node2D.new()
	root.add_child(root_node)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.08)
	bg.size = Vector2(480, 960)
	root_node.add_child(bg)
	var sv := Progress.read()
	PilotRig.set_gear(sv)
	HeroFight.apply_from(sv)
	HeroFight.warm(PilotRig.hero)
	view = PilotRigView.new()
	view.fight = true
	view.height = float(OS.get_environment("CAP_H")) if OS.get_environment("CAP_H") != "" else 230.0
	root_node.add_child(view)

func _process(delta: float) -> bool:
	if view == null:
		return false
	t += delta
	var ph := int(t / STEP)
	var u := fmod(t, STEP) / STEP
	var v := Vector2.ZERO
	var moving := u < 0.5
	match ph:
		1: v = Vector2(300, 0) if moving else Vector2.ZERO
		3: v = Vector2(-300, 0) if moving else Vector2.ZERO
		5: v = Vector2(0, -300) if moving else Vector2.ZERO
		6: v = Vector2(0, 300) if moving else Vector2.ZERO
	at += v * delta
	if ph == 7:
		_shot -= delta
		if _shot <= 0.0:
			_shot = 0.24
			view.fire(1.0)
	if ph == 8 and not _did.has("heavy"):
		_did["heavy"] = true
		view.fire(2.2)
	if ph == 9 and not _did.has("hit"):
		_did["hit"] = true
		view.hit()
	if ph == 10 and not _did.has("cast"):
		_did["cast"] = true
		view.cast()
	view.update(delta, at, -PI / 2.0, 0.0, 1.0, 0.0)
	return false
