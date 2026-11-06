extends "res://tools/cut_ui_art.gd"
# Cuts Luna's turrets round 2 (art_src/turrets2, LUNA-BRIEF-turrets-2.md):
#   <id>_base.webp / <id>_head.webp (1024, on black) for the six NEW turrets (repair, tesla,
#       cryo, mines, beacon, flak) -> turrets/<id>_base.png + <id>_head.png (256 longest side,
#       keyed off black), turrets/<id>_light.png (the head's glow, same canvas as the head: the
#       cut_turret_light rule), turrets/<id>_idle.png (head stacked on base: the tile picture)
#   <id>_shot.webp (512, light on black) -> fx/shot_<id>.png 128 px (additive)
#   <id>_head_fire.webp for the six turrets we had -> turrets/<id>_head_fire.png on the SAME
#       canvas as turrets/<id>_head.png (scaled to the resting head's size, centred) so battle
#       can cross-fade it in while the turret fires, plus turrets/<id>_fire_light.png
#   art_src/cards_r3/pic_rook_twin.webp (the cards leftover) -> cards/pic_rook_twin.png
# Run: godot --headless --path . --script res://tools/cut_turrets2.gd   (then --import)

const SRC2 := "res://art_src/turrets2/"
const NEW := ["repair", "tesla", "cryo", "mines", "beacon", "flak"]
const OLD := {"sentry": "sentry_head", "lance": "lance_head", "storm": "storm_head", "gravity": "gravity_head",
	"swarm": "swarm_body_nolid", "prism": "prism_head"}
const OVERLAP := 0.18   # the head sinks this share of the base's height into it on the tile picture

func _initialize() -> void:
	for id in NEW:
		var base := _trim(_solid(_img(SRC2 + "%s_base.webp" % id)), 2)
		var head := _trim(_solid(_img(SRC2 + "%s_head.webp" % id)), 2)
		print("%-7s base %dx%d  head %dx%d  head/base width %.2f  head/base height %.2f" % [id, base.get_width(), base.get_height(), head.get_width(), head.get_height(),
			float(head.get_width()) / base.get_width(), float(head.get_height()) / base.get_height()])
		var hf := _fit(head, 256)
		_save(_fit(base, 256), "res://turrets/%s_base.png" % id)
		_save(hf, "res://turrets/%s_head.png" % id)
		_save(_glow(hf), "res://turrets/%s_light.png" % id)
		_save(_fit(_stack(base, head), 256), "res://turrets/%s_idle.png" % id)
		var shot := SRC2 + "%s_shot.webp" % id
		if FileAccess.file_exists(shot):
			_save(_fit(_light(_img(shot)), 128), "res://fx/shot_%s.png" % id)
	for id in OLD:
		var p := SRC2 + "%s_head_fire.webp" % id
		if not FileAccess.file_exists(p):
			print("%s_head_fire: missing" % id)
			continue
		var rest := _img("res://turrets/%s.png" % OLD[id])
		var fire := _trim(_solid(_img(p)), 2)
		var rt := _trim(rest, 0)   # the resting head's own used box inside its canvas
		var sx := float(rt.get_width()) / fire.get_width()
		var sy := float(rt.get_height()) / fire.get_height()
		print("%-7s fire head %dx%d vs rest %dx%d  scale x %.3f y %.3f%s" % [id, fire.get_width(), fire.get_height(), rt.get_width(), rt.get_height(), sx, sy,
			"" if absf(sx - sy) < 0.08 * maxf(sx, sy) else "  (shape differs: fitted by the smaller side)"])
		var s := minf(sx, sy) if absf(sx - sy) >= 0.08 * maxf(sx, sy) else (sx + sy) * 0.5
		var scaled: Image = fire.duplicate()
		scaled.resize(maxi(1, roundi(fire.get_width() * s)), maxi(1, roundi(fire.get_height() * s)), Image.INTERPOLATE_LANCZOS)
		var out := Image.create(rest.get_width(), rest.get_height(), false, Image.FORMAT_RGBA8)
		var used := rest.get_used_rect()
		var at := used.position + (used.size - scaled.get_size()) / 2
		out.blit_rect(scaled, Rect2i(Vector2i.ZERO, scaled.get_size()), at)
		_save(out, "res://turrets/%s_head_fire.png" % id)
		_save(_glow(out), "res://turrets/%s_fire_light.png" % id)
	var rook := "res://art_src/cards_r3/pic_rook_twin.webp"
	if FileAccess.file_exists(rook):
		_save(_fit(_trim(_solid(_img(rook))), 256), "res://cards/pic_rook_twin.png")
	quit()

func _img(path: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	img.convert(Image.FORMAT_RGBA8)
	return img

# the head over the base, centred, sunk a little into it: the one-picture turret for tiles
func _stack(base: Image, head: Image) -> Image:
	var sink := roundi(base.get_height() * OVERLAP)
	var w := maxi(base.get_width(), head.get_width())
	var h := base.get_height() + head.get_height() - sink
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.blend_rect(base, Rect2i(Vector2i.ZERO, base.get_size()), Vector2i((w - base.get_width()) / 2, h - base.get_height()))
	out.blend_rect(head, Rect2i(Vector2i.ZERO, head.get_size()), Vector2i((w - head.get_width()) / 2, 0))
	return out

# the glow cut from a turret picture (tools/cut_turret_light.gd rule): bright AND coloured
# pixels with soft edges, on a transparent canvas of the same size
func _glow(img: Image) -> Image:
	var w := img.get_width()
	var h := img.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var hi := maxf(maxf(c.r, c.g), c.b)
			var lo := minf(minf(c.r, c.g), c.b)
			var sat := (hi - lo) / maxf(hi, 0.001)
			var keep := smoothstep(0.62, 0.95, hi) * clampf((sat - 0.18) / 0.35, 0.0, 1.0) * c.a
			out.set_pixel(x, y, Color(c.r, c.g, c.b, keep))
	return out
