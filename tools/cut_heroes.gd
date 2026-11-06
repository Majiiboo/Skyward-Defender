extends "res://tools/cut_ui_art.gd"
# Cuts Luna's hero render sets (art_src/heroes/<id>/, LUNA-BRIEF-heroes.md) into heroes/<id>/:
#   turn_1..8.png   the whole-body turn frames (1-5 the front half, 6-8 the back, dev188), keyed
#                   off black, all cropped to ONE
#                   rectangle (the union of their used areas) so they stay aligned, 640 px tall;
#                   a back frame that was not delivered is skipped (the ring fades across it)
#   portrait.png    the roster picture, keyed, 256 px
#   ref.png         the assembled reference, keyed (the fallback frame)
#   weapon.png      the side-view weapon, keyed, trimmed
#   parts/pNN.png   the 16 parts-sheet cells, keyed (for the per-hero rig later)
# Missing frames (LUNA-BRIEF-heroes-redo-1.md): Hollow 4 and 5 are made by mirroring 2 and 1;
# Ember has no frames yet, so all five come from the reference (mirrored past the middle).
# Run: godot --headless --path . --script res://tools/cut_heroes.gd   (then --import)

const HEROES := ["sparks", "frost", "hollow", "nyx", "ember"]
const TARGET_H := 640
const PORTRAIT := 256

func _initialize() -> void:
	for id in HEROES:
		_cut_hero(id)
	for id in HEROES + ["rook"]:   # evolution tiers, when their renders exist
		_cut_tiers(id)
	quit()

func _src(id: String, name: String) -> String:
	return ProjectSettings.globalize_path("res://art_src/heroes/%s/%s" % [id, name])

func _keyed(path: String) -> Image:
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(path)
	img.convert(Image.FORMAT_RGBA8)
	return _solid(img)

func _cut_hero(id: String) -> void:
	var out := "res://heroes/%s/" % id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out + "parts"))
	# the turn frames (fallbacks for the ones not delivered yet)
	var frames: Array = []
	for n in range(1, 9):
		frames.append(_keyed(_src(id, "turn_%d.webp" % n)))
	var ref := _keyed(_src(id, "reference.webp"))
	for n in 8:
		if frames[n] != null:
			continue
		# a frame she could not make: its mirror if there is one (5 <- 1, 4 <- 2, 8 <-> 6), else the
		# reference for the front half, else the ring simply skips it (the straight back, 7)
		var mirror_of := -1
		if n == 3 or n == 4:
			mirror_of = 4 - n
		elif n == 5 or n == 7:
			mirror_of = 12 - n
		if mirror_of >= 0 and frames[mirror_of] != null:
			var m: Image = frames[mirror_of].duplicate()
			m.flip_x()
			frames[n] = m
			print("%s turn_%d: mirrored from turn_%d (missing)" % [id, n + 1, mirror_of + 1])
		elif n < 5 and ref != null:
			var m2: Image = ref.duplicate()
			if n >= 3:
				m2.flip_x()
			frames[n] = m2
			print("%s turn_%d: the reference stands in (missing)" % [id, n + 1])
		elif n >= 5:
			print("%s turn_%d: missing, the ring fades across it" % [id, n + 1])
	for n in 8:
		if frames[n] != null:
			var u0: Rect2i = frames[n].get_used_rect()
			print("%s %d: bounds x %d-%d  y %d-%d" % [id, n + 1, u0.position.x, u0.end.x, u0.position.y, u0.end.y])
	_match_back(frames, id)
	var union := Rect2i()
	for f in frames:
		if f == null:
			continue
		var used: Rect2i = f.get_used_rect()
		union = used if union.size == Vector2i.ZERO else union.merge(used)
	for n in 8:
		var f: Image = frames[n]
		if f == null:
			continue
		var crop := union.grow(6).intersection(Rect2i(Vector2i.ZERO, f.get_size()))
		var o: Image = f.get_region(crop)
		var s := float(TARGET_H) / o.get_height()
		o.resize(maxi(1, roundi(o.get_width() * s)), TARGET_H, Image.INTERPOLATE_LANCZOS)
		_save(o, out + "turn_%d.png" % (n + 1))
	# portrait, reference, weapon
	var por := _keyed(_src(id, "portrait.webp"))
	if por == null and ref != null:
		por = ref.get_region(Rect2i(ref.get_width() / 4, 0, ref.get_width() / 2, ref.get_height() / 2))
		print("%s portrait: cut from the reference (missing)" % id)
	if por != null:
		var pr := por.get_used_rect().grow(4).intersection(Rect2i(Vector2i.ZERO, por.get_size()))
		var p2 := por.get_region(pr)
		var side := maxi(p2.get_width(), p2.get_height())
		var sq := Image.create(side, side, false, Image.FORMAT_RGBA8)
		sq.blit_rect(p2, Rect2i(Vector2i.ZERO, p2.get_size()), Vector2i((side - p2.get_width()) / 2, (side - p2.get_height()) / 2))
		sq.resize(PORTRAIT, PORTRAIT, Image.INTERPOLATE_LANCZOS)
		_save(sq, out + "portrait.png")
	if ref != null:
		var r2 := ref.get_region(ref.get_used_rect().grow(6).intersection(Rect2i(Vector2i.ZERO, ref.get_size())))
		var s2 := float(TARGET_H) / r2.get_height()
		r2.resize(maxi(1, roundi(r2.get_width() * s2)), TARGET_H, Image.INTERPOLATE_LANCZOS)
		_save(r2, out + "ref.png")
	var wp := _keyed(_src(id, "weapon_side.webp"))
	if wp != null:
		var w2 := wp.get_region(wp.get_used_rect().grow(4).intersection(Rect2i(Vector2i.ZERO, wp.get_size())))
		var s3 := 480.0 / w2.get_height()
		w2.resize(maxi(1, roundi(w2.get_width() * s3)), 480, Image.INTERPOLATE_LANCZOS)
		_save(w2, out + "weapon.png")
	# the 16 parts cells (4 x 4 of 512) for the later rig
	var sheet_path := _src(id, "parts_sheet.webp")
	if FileAccess.file_exists(sheet_path):
		var sheet := Image.load_from_file(sheet_path)
		sheet.convert(Image.FORMAT_RGBA8)
		var cell := sheet.get_width() / 4
		for i in 16:
			var cx := (i % 4) * cell
			var cy := (i / 4) * cell
			var c := _solid(sheet.get_region(Rect2i(cx, cy, cell, cell)))
			var used := c.get_used_rect()
			if used.size.x < 4 or used.size.y < 4:
				continue
			_save(c.get_region(used.grow(3).intersection(Rect2i(Vector2i.ZERO, c.get_size()))), out + "parts/p%02d.png" % (i + 1))

# HERO EVOLUTIONS (LUNA-BRIEF-hero-tiers.md, dev189): a tier's whole-hero frames
# art_src/heroes/<id>/t<k>_turn_1..8.webp -> heroes/<id>/t<k>/turn_n.png (same height as the
# base frames, the ring skips a missing frame) and portrait_t<k>.webp -> portrait_t<k>.png.
func _cut_tiers(id: String) -> void:
	var out := "res://heroes/%s/" % id
	for k in [2, 3]:
		var frames: Array = []
		var any := false
		for n in range(1, 9):
			var f := _keyed(_src(id, "t%d_turn_%d.webp" % [k, n]))
			frames.append(f)
			any = any or f != null
		if any:
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out + "t%d" % k))
			_match_back(frames, "%s t%d" % [id, k])
			var union := Rect2i()
			for f in frames:
				if f == null:
					continue
				var used: Rect2i = f.get_used_rect()
				union = used if union.size == Vector2i.ZERO else union.merge(used)
			for n in 8:
				var f: Image = frames[n]
				if f == null:
					print("%s t%d turn_%d: missing, the ring fades across it" % [id, k, n + 1])
					continue
				var crop := union.grow(6).intersection(Rect2i(Vector2i.ZERO, f.get_size()))
				var o: Image = f.get_region(crop)
				var s := float(TARGET_H) / o.get_height()
				o.resize(maxi(1, roundi(o.get_width() * s)), TARGET_H, Image.INTERPOLATE_LANCZOS)
				_save(o, out + "t%d/turn_%d.png" % [k, n + 1])
		var por := _keyed(_src(id, "portrait_t%d.webp" % k))
		if por != null:
			var pr := por.get_used_rect().grow(4).intersection(Rect2i(Vector2i.ZERO, por.get_size()))
			var p2 := por.get_region(pr)
			var side := maxi(p2.get_width(), p2.get_height())
			var sq := Image.create(side, side, false, Image.FORMAT_RGBA8)
			sq.blit_rect(p2, Rect2i(Vector2i.ZERO, p2.get_size()), Vector2i((side - p2.get_width()) / 2, (side - p2.get_height()) / 2))
			sq.resize(PORTRAIT, PORTRAIT, Image.INTERPOLATE_LANCZOS)
			_save(sq, out + "portrait_t%d.png" % k)
