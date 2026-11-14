extends "res://tools/cut_ui_art.gd"
# Cuts Luna's SHOT pictures (LUNA-BRIEF-frost-shots.md: light on black, flying UP) from
# art_src/shots/<element>/ into fx/shots/<element>_<piece>.png for Shots (shots.gd), and a hero's
# SIDE-VIEW weapons (art_src/heroes/<id>/<prefix>side_*.webp) into heroes/<id>/side_<class>.png
# for the Weapons screen showcase. A piece that was not delivered is skipped.
# Everything a shot uses is drawn on the battle's ADDITIVE layer, so black = nothing: no alpha
# is cut, only the faint grey of the render's background is taken off.
# Single shots are turned so the FRONT points RIGHT (+x = the way a bullet flies in battle).
# Run: godot --headless --path . --script res://tools/cut_shots.gd   (then --import)

const ELEMENTS := {"frost": "frostshot_"}
# piece -> [centre x, centre y, half size of the square taken, saved size]
const SINGLES := {
	"snowball": [495, 480, 240, 120],
	"pellet": [512, 512, 230, 128],
	"pellet_big": [512, 512, 320, 160],
	"boulder": [516, 500, 340, 176],
	"hit": [512, 512, 400, 128],
	"burst": [512, 512, 500, 256],
	"stream_end": [512, 512, 512, 256],
}
const STREAM_X := 312        # the strip taken from the stream picture: x 312 .. 712
const STREAM_W := 400
const STREAM_BLEND := 200    # rows cross-faded so the top joins the bottom
const STREAM_OUT_W := 160
const FLOOR := 0.045         # the render's background grey, taken off
const SIDES := {"frost": {"prefix": "frostfight_side_", "files": {"pistol": "sidearm", "launcher": "heavy", "streamer": "main"}}}

func _initialize() -> void:
	for el in ELEMENTS:
		var src := "res://art_src/shots/%s/%s" % [el, ELEMENTS[el]]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://fx/shots/"))
		for p in SINGLES:
			var img := _open(src + String(p) + ".webp")
			if img == null:
				continue
			var row: Array = SINGLES[p]
			var hs := int(row[2])
			var sq := Image.create(hs * 2, hs * 2, false, Image.FORMAT_RGBA8)
			sq.fill(Color(0, 0, 0, 1))
			sq.blit_rect(img, Rect2i(int(row[0]) - hs, int(row[1]) - hs, hs * 2, hs * 2), Vector2i.ZERO)
			_lift(sq, String(p) != "stream_end")
			sq.rotate_90(CLOCKWISE)
			sq.resize(int(row[3]), int(row[3]), Image.INTERPOLATE_LANCZOS)
			_save(sq, "res://fx/shots/%s_%s.png" % [el, p])
		var st := _open(src + "stream.webp")
		if st != null:
			_stream(st, "res://fx/shots/%s_stream.png" % el)
		var bits := _open(src + "bits.webp")
		if bits != null:
			for i in 4:
				var cell := bits.get_region(Rect2i((i % 2) * 512, (i / 2) * 512, 512, 512))
				_lift(cell, true)
				cell.resize(64, 64, Image.INTERPOLATE_LANCZOS)
				_save(cell, "res://fx/shots/%s_bit_%d.png" % [el, i])
	for id in SIDES:
		var spec: Dictionary = SIDES[id]
		for f in spec.files:
			var img := _open("res://art_src/heroes/%s/%s%s.webp" % [id, spec.prefix, f])
			if img == null:
				continue
			if f == "streamer":   # the mist Luna painted round the nozzle keys out as a dark smudge: painted away first
				img.fill_rect(Rect2i(0, 0, 1024, 214), Color.BLACK)
				img.fill_rect(Rect2i(0, 0, 410, 345), Color.BLACK)
				img.fill_rect(Rect2i(654, 0, 370, 345), Color.BLACK)
			_save(_trim(_solid(img), 4), "res://heroes/%s/side_%s.png" % [id, spec.files[f]])
	quit()

func _open(path: String) -> Image:
	if not FileAccess.file_exists(path):
		print("%s: not delivered yet" % path)
		return null
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	img.convert(Image.FORMAT_RGBA8)
	return img

# takes the background grey off; `round_mask` also fades the square's corners to black
func _lift(img: Image, round_mask: bool) -> void:
	var w := img.get_width(); var h := img.get_height()
	var k := 1.0 / (1.0 - FLOOR)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var m := 1.0
			if round_mask:
				var d := Vector2(x - w * 0.5, y - h * 0.5).length() / (w * 0.5)
				m = 1.0 - smoothstep(0.86, 1.0, d)
			img.set_pixel(x, y, Color(maxf(c.r - FLOOR, 0.0) * k * m, maxf(c.g - FLOOR, 0.0) * k * m, maxf(c.b - FLOOR, 0.0) * k * m, 1.0))

# the looping strip: the middle column, the top cross-faded onto the bottom, the sides faded out
func _stream(img: Image, out_path: String) -> void:
	var h := img.get_height()
	var oh := h - STREAM_BLEND
	var out := Image.create(STREAM_W, oh, false, Image.FORMAT_RGBA8)
	var k := 1.0 / (1.0 - FLOOR)
	for y in oh:
		for x in STREAM_W:
			var c := img.get_pixel(STREAM_X + x, y)
			if y < STREAM_BLEND:
				c = img.get_pixel(STREAM_X + x, oh + y).lerp(c, float(y) / STREAM_BLEND)
			var e := minf(float(x), float(STREAM_W - 1 - x)) / 70.0
			var m := smoothstep(0.0, 1.0, e)
			out.set_pixel(x, y, Color(maxf(c.r - FLOOR, 0.0) * k * m, maxf(c.g - FLOOR, 0.0) * k * m, maxf(c.b - FLOOR, 0.0) * k * m, 1.0))
	out.resize(STREAM_OUT_W, roundi(oh * float(STREAM_OUT_W) / STREAM_W), Image.INTERPOLATE_LANCZOS)
	_save(out, out_path)
