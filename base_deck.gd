class_name BaseDeck
extends Control
# The base as it stands in the fight (Luna's core and four pods, drawn by Backdrop.draw_core_base),
# shown on top of the Base page: tap a pod to pick that slot. Slot 1 is joined to the core by a lit
# line with a PULSE mark, because the building there shapes the Core Pulse (Base.PULSE).

signal pod_tapped(i: int)

const H := 168.0
const BASE_Y := 122.0

var pods: Array = []        # as Backdrop.draw_core_base wants them
var links: Array = []       # [slot, slot] pairs that are linked
var sel := 0                # the slot picked
var locked: Array = []      # per slot: "" or the words under a closed pod ("Stage 10")
var pulse := ""             # "" = no mark; "on" = slot 1 shapes the pulse; "off" = the pulse is not open yet
var _t := 0.0

func _init() -> void:
	custom_minimum_size = Vector2(0, H)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _pod(i: int) -> Vector2:
	return Backdrop.pod_pos(i, size.x, BASE_Y)

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var k := size.x / 480.0
		for i in pods.size():
			if ev.position.distance_to(_pod(i)) < 40.0 * k:
				pod_tapped.emit(i)
				accept_event()
				return

func _draw() -> void:
	var k := size.x / 480.0
	var font := UIKit.title_font()
	var eye := Backdrop.core_eye(size.x, BASE_Y)
	# slot 1's conduit to the core: a row of gold beads running pod -> core, behind everything
	if pulse != "" and pods.size() > 0:
		var a := _pod(0)
		var col := UIKit.GOLD if pulse == "on" else UIKit.SOFT
		var bow := (a + eye) * 0.5 + Vector2(0, 26.0 * k)
		for j in 9:
			var u := fposmod(j / 9.0 + (_t * 0.25 if pulse == "on" else 0.0), 1.0)
			var p := a.lerp(bow, u).lerp(bow.lerp(eye, u), u)
			draw_circle(p, 2.0 * k, Color(col, 0.25 + 0.55 * sin(u * PI)))
	Backdrop.draw_core_base(self, size.x, BASE_Y, size.y, _t, pods, 1.0, links)
	for i in pods.size():
		var p := _pod(i)
		var pd: Dictionary = pods[i]
		if i == sel:   # the slot picked: a thin white ring that breathes
			draw_arc(p, (39.0 + 1.5 * sin(_t * 3.0)) * k, 0.0, TAU, 48, Color(1, 1, 1, 0.9), 1.5, true)
		# its number, on a small dark disc at the top left of the pod
		var n := p + Vector2(-27.0, -27.0) * k
		draw_circle(n, 9.0, Color(0.04, 0.07, 0.13, 0.95))
		draw_arc(n, 9.0, 0.0, TAU, 20, Color(Color(pd.get("col", UIKit.CYAN)), 0.9) if bool(pd.get("open", false)) else UIKit.SOFT, 1.0, true)
		draw_string(font, n + Vector2(-9.0, 4.0), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 18.0, 11, UIKit.TEXT)
		var words: String = String(locked[i]) if i < locked.size() else ""
		if words != "":
			draw_string(font, p + Vector2(-40.0, 5.0), words, HORIZONTAL_ALIGNMENT_CENTER, 80.0, 10, UIKit.SOFT)
	if pulse != "" and pods.size() > 0:   # the PULSE mark under slot 1
		var at := _pod(0) + Vector2(-22.0, 40.0 * k)
		var col2 := UIKit.GOLD if pulse == "on" else UIKit.SOFT
		draw_style_box(UIKit.pill(Color(col2, 0.95), 8, Vector2.ZERO), Rect2(at, Vector2(44.0, 15.0)))
		draw_string(font, at + Vector2(0.0, 11.5), "PULSE", HORIZONTAL_ALIGNMENT_CENTER, 44.0, 10, Color(0.04, 0.07, 0.13))
