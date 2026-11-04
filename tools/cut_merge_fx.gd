extends SceneTree
# Luna's merge-effect layers (LUNA-BRIEF-merge-fx.md; art_src/merge/*.webp, 1024 px on black)
# -> fx/merge_<name>.png at 512 px. The light layers are white light on black, drawn
# additively and tinted in code; their outer edge is faded so nothing shows a square cut.
# The chamber is solid metal: keyed off black, its empty middle stays see-through.
# Run: godot --headless --path . --script res://tools/cut_merge_fx.gd

const LIGHT := ["swirl", "flash", "shock", "rays", "ring"]
const PX := 512

func _initialize() -> void:
	for nm in LIGHT + ["chamber"]:
		var img := Image.load_from_file(ProjectSettings.globalize_path("res://art_src/merge/merge_%s.webp" % nm))
		if img == null:
			push_error("missing merge_%s" % nm)
			continue
		img.convert(Image.FORMAT_RGBA8)
		img.resize(PX, PX, Image.INTERPOLATE_LANCZOS)
		if nm == "chamber":
			img = _key(img)
		else:
			_edge_fade(img)
		img.save_png(ProjectSettings.globalize_path("res://fx/merge_%s.png" % nm))
		print("fx/merge_%s.png" % nm)
	quit()

# light fades to black from 80% of the radius to the edge
func _edge_fade(img: Image) -> void:
	var c := Vector2(img.get_width(), img.get_height()) * 0.5
	for y in img.get_height():
		for x in img.get_width():
			var r := (Vector2(x, y) - c).length() / c.x
			var k := 1.0 - smoothstep(0.8, 0.99, r)
			if k < 1.0:
				var p := img.get_pixel(x, y)
				img.set_pixel(x, y, Color(p.r * k, p.g * k, p.b * k, 1.0))

# soft black key that keeps dark metal solid
func _key(img: Image, lo: float = 5.0, span: float = 18.0) -> Image:
	var d := img.get_data()
	for i in d.size() / 4:
		var m: float = maxf(maxf(d[i * 4], d[i * 4 + 1]), d[i * 4 + 2])
		var a: float = clampf((m - lo) / span, 0.0, 1.0)
		if a > 0.0 and a < 1.0:
			for k in 3:
				d[i * 4 + k] = int(clampf(d[i * 4 + k] / a, 0.0, 255.0))
		d[i * 4 + 3] = int(a * 255.0)
	return Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, d)
