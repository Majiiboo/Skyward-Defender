class_name PlayReactor
extends Button
# Home's round gold PLAY, the "Reactor" (Rudy's pick, 2026-11-10, option A on
# claude.ai/artifact/9ZyH2NVPEENFPc9XagXKct): a ring of gold segments turns slowly round a flat
# two-tone gold disc (Luna's icon style: dark outline, lighter top half, dark triangle) that
# breathes; a badge at its lower right shows what the stage costs (green bolt + power tokens, or
# FREE). Press: the disc squashes; launch() spins the ring up and sends a shock ring out.
# The tap area is the disc (SIZE); the ring and the badge are drawn outside it.

const SIZE := 104.0
const R_OUT := 52.0        # dark outline
const R_DISC := 48.0       # gold disc
const R_RING := 66.0       # the turning ring
const SEGMENTS := 14
const RING_W := 5.0
const TURN_S := 24.0       # seconds for one slow turn
const GOLD := Color(1.0, 0.784, 0.27)
const GOLD_HI := Color(1.0, 0.824, 0.36)
const GOLD_LO := Color(0.94, 0.68, 0.17)
const OUTLINE := Color(0.067, 0.094, 0.188)
const INK := Color(0.14, 0.094, 0.0)
const BADGE_BG := Color(0.043, 0.078, 0.149)
const FREE_COL := Color(0.435, 0.94, 0.72)

var cost_fn: Callable      # -> int, the stage's power-token cost (0 = free)
var _time := 0.0
var _press := -1.0         # seconds into the press squash
var _launch := -1.0        # seconds into the launch spin + shock
var _bolt: Texture2D
var _badge: StyleBoxFlat

func _init() -> void:
	name = "PlayButton"
	custom_minimum_size = Vector2(SIZE, SIZE)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	focus_mode = Control.FOCUS_NONE
	for st in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(st, StyleBoxEmpty.new())
	_bolt = Icons.get_icon("ic_bolt")
	button_down.connect(func():
		Sfx.play("tap")
		_press = 0.0)

# the ring spins up and a shock ring goes out (the battle is starting)
func launch() -> void:
	_launch = 0.0

func _process(delta: float) -> void:
	_time += delta
	if _press >= 0.0:
		_press += delta
		if _press > 0.5:
			_press = -1.0
	if _launch >= 0.0:
		_launch += delta
		if _launch > 0.9:
			_launch = -1.0
	queue_redraw()

func _draw() -> void:
	var c := size * 0.5
	# the ring: slow turn, plus 1.5 turns that ease out on launch
	var spin := 0.0
	if _launch >= 0.0:
		var u := clampf(_launch / 0.8, 0.0, 1.0)
		spin = TAU * 1.5 * (1.0 - pow(1.0 - u, 3.0))
	var a0 := TAU * _time / TURN_S + spin
	var seg := TAU / SEGMENTS
	for i in SEGMENTS:
		var s0 := a0 + i * seg
		var s1 := s0 + seg * 0.64
		var col := Color(GOLD, 0.85)
		draw_arc(c, R_RING, s0, s1, 8, col, RING_W, true)
		draw_circle(c + Vector2.from_angle(s0) * R_RING, RING_W * 0.5, col)
		draw_circle(c + Vector2.from_angle(s1) * R_RING, RING_W * 0.5, col)
	# shock ring on launch
	if _launch >= 0.0 and _launch < 0.7:
		var t := _launch / 0.7
		draw_arc(c, R_OUT * lerpf(0.7, 1.6, t), 0.0, TAU, 64, Color(GOLD, 0.9 * (1.0 - t)), 3.0, true)
	# the disc: breathing, squashing on press
	var k := 1.0 + 0.035 * (0.5 - 0.5 * cos(TAU * _time / 2.8))
	if _press >= 0.0:
		k = NavIcon._k(_press, [[0.0, 1.0], [0.15, 0.88], [0.33, 1.08], [0.5, 1.0]])
	draw_set_transform(c, 0.0, Vector2(k, k))
	draw_circle(Vector2.ZERO, R_OUT, OUTLINE)
	draw_circle(Vector2.ZERO, R_DISC, GOLD_LO)
	# lighter top half (flat two-tone, no gradient)
	var top := PackedVector2Array()
	for i in 33:
		top.append(Vector2.from_angle(PI + PI * i / 32.0) * R_DISC)
	draw_colored_polygon(top, GOLD_HI)
	# the triangle, with rounded corners (a thick outline in the same ink)
	var tri := PackedVector2Array([Vector2(-11.5, -20.0), Vector2(-11.5, 20.0), Vector2(22.0, 0.0)])
	draw_colored_polygon(tri, INK)
	draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0], tri[1]]), INK, 5.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_badge(c + Vector2(28.0, 40.0))

func _draw_badge(at: Vector2) -> void:
	var cost: int = cost_fn.call() if cost_fn.is_valid() else 0
	var font := UIKit.title_font()
	var fs := 14
	var text := "FREE" if cost <= 0 else str(cost)
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var icon_w := 0.0 if cost <= 0 or _bolt == null else 18.0
	var w := 9.0 + icon_w + (3.0 if icon_w > 0.0 else 0.0) + tw + 9.0
	var r := Rect2(at, Vector2(w, 26.0))
	if _badge == null:
		_badge = StyleBoxFlat.new()
		_badge.bg_color = BADGE_BG
		_badge.set_border_width_all(1)
		_badge.border_color = Color(1, 1, 1, 0.16)
		_badge.set_corner_radius_all(13)
		_badge.anti_aliasing = true
	draw_style_box(_badge, r)
	var x := at.x + 8.0
	if icon_w > 0.0:
		draw_texture_rect(_bolt, Rect2(x, at.y + 4.0, 18.0, 18.0), false)
		x += icon_w + 3.0
	draw_string(font, Vector2(x, at.y + 18.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
		FREE_COL if cost <= 0 else Color.WHITE)
