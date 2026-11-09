extends SceneTree
# Photographs each GLB in models/ from 8 angles (one lighting, transparent background),
# prints what is inside (meshes, triangles, textures, skeleton, animations) and writes
# out/<model>_<n>.png plus a contact sheet out/<model>_sheet.png.

const MODELS := ["rook", "rook_rigged", "lance_base", "lance_head"]
const SIZE := 512
const ANGLES := 8

var vp: SubViewport
var cam: Camera3D
var holder: Node3D

func _init() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(SIZE, SIZE)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	# a sky only for reflections and ambient light (the background stays clear): metal needs
	# something to reflect, or it photographs flat grey
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.32, 0.42, 0.62)
	sm.sky_horizon_color = Color(0.62, 0.68, 0.8)
	sm.ground_horizon_color = Color(0.36, 0.38, 0.45)
	sm.ground_bottom_color = Color(0.08, 0.08, 0.1)
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, 30, 0)
	key.light_energy = 1.5
	vp.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-10, -150, 0)
	fill.light_energy = 0.55
	vp.add_child(fill)
	cam = Camera3D.new()
	cam.fov = 28.0
	vp.add_child(cam)
	holder = Node3D.new()
	vp.add_child(holder)
	_run.call_deferred()

func _run() -> void:
	var out := ProjectSettings.globalize_path("res://out/")
	for m in MODELS:
		var path := "res://models/%s.glb" % m
		if not ResourceLoader.exists(path):
			print("MISSING ", path)
			continue
		var ps: PackedScene = load(path)
		var inst: Node3D = ps.instantiate()
		holder.rotation = Vector3.ZERO
		holder.add_child(inst)
		await process_frame
		_info(m, inst)
		var box := _aabb(inst)
		print("%s  size %.3f x %.3f x %.3f  centre %s" % [m, box.size.x, box.size.y, box.size.z, box.get_center()])
		var c := box.get_center()
		inst.position = Vector3(-c.x, 0.0, -c.z)
		c = Vector3(0.0, c.y, 0.0)
		var r: float = box.size.length() * 0.5
		var dist: float = r / tan(deg_to_rad(cam.fov * 0.5)) * 1.02
		var elev := deg_to_rad(22.0 if m.begins_with("lance") else 5.0)
		cam.position = c + Vector3(0.0, sin(elev), cos(elev)) * dist
		cam.look_at(c)
		var sheet := Image.create(SIZE * 4, SIZE * 2, false, Image.FORMAT_RGBA8)
		sheet.fill(Color(0.11, 0.14, 0.21))
		for i in ANGLES:
			holder.rotation.y = TAU * float(i) / float(ANGLES)
			for f in 4:
				await RenderingServer.frame_post_draw
			var img := vp.get_texture().get_image()
			img.convert(Image.FORMAT_RGBA8)
			img.save_png(out + "%s_%d.png" % [m, i])
			sheet.blend_rect(img, Rect2i(0, 0, SIZE, SIZE), Vector2i((i % 4) * SIZE, (i / 4) * SIZE))
		sheet.save_png(out + "%s_sheet.png" % m)
		inst.queue_free()
		await process_frame
	# Rook again with the neon photo material (dark armour, glowing lines)
	var rk: Node3D = (load("res://models/rook.glb") as PackedScene).instantiate()
	holder.rotation = Vector3.ZERO
	holder.add_child(rk)
	var sh: Shader = load("res://neon.gdshader")
	for v in _all(rk):
		if v is MeshInstance3D:
			for s in (v as MeshInstance3D).mesh.get_surface_count():
				var bm := (v as MeshInstance3D).mesh.surface_get_material(s) as BaseMaterial3D
				var nm := ShaderMaterial.new()
				nm.shader = sh
				nm.set_shader_parameter("albedo_tex", bm.albedo_texture)
				nm.set_shader_parameter("normal_tex", bm.normal_texture)
				(v as MeshInstance3D).set_surface_override_material(s, nm)
	await process_frame
	var rbox := _aabb(rk)
	var rc := rbox.get_center()
	cam.position = rc + Vector3(0.0, sin(deg_to_rad(5.0)), cos(deg_to_rad(5.0))) * (rbox.size.length() * 0.5 / tan(deg_to_rad(cam.fov * 0.5)) * 1.02)
	cam.look_at(rc)
	var rsheet := Image.create(SIZE * 4, SIZE * 2, false, Image.FORMAT_RGBA8)
	rsheet.fill(Color(0.11, 0.14, 0.21))
	for i in ANGLES:
		holder.rotation.y = TAU * float(i) / float(ANGLES)
		for f in 4:
			await RenderingServer.frame_post_draw
		var rimg := vp.get_texture().get_image()
		rimg.convert(Image.FORMAT_RGBA8)
		rimg.save_png(out + "rook_neon_%d.png" % i)
		rsheet.blend_rect(rimg, Rect2i(0, 0, SIZE, SIZE), Vector2i((i % 4) * SIZE, (i / 4) * SIZE))
	rsheet.save_png(out + "rook_neon_sheet.png")
	rk.queue_free()
	holder.rotation = Vector3.ZERO
	await process_frame

	# the Lance put together: the base still, the head on its socket turning to aim
	var base: Node3D = (load("res://models/lance_base.glb") as PackedScene).instantiate()
	var head: Node3D = (load("res://models/lance_head.glb") as PackedScene).instantiate()
	holder.rotation = Vector3.ZERO
	holder.add_child(base)
	var pivot := Node3D.new()
	pivot.position = Vector3(0, 0.5, 0)
	holder.add_child(pivot)
	pivot.add_child(head)
	head.scale = Vector3.ONE * 1.1
	head.position = Vector3(0.12, 0.0, 0.0)   # the rear third sits over the socket
	await process_frame
	var cbox := _aabb(holder)
	var cc := cbox.get_center()
	var cdist: float = cbox.size.length() * 0.5 / tan(deg_to_rad(cam.fov * 0.5)) * 1.0
	var celev := deg_to_rad(24.0)
	cam.position = cc + Vector3(0.0, sin(celev), cos(celev)) * cdist
	cam.look_at(cc)
	var csheet := Image.create(SIZE * 4, SIZE * 2, false, Image.FORMAT_RGBA8)
	csheet.fill(Color(0.11, 0.14, 0.21))
	for i in ANGLES:
		# aim from pointing left, round through pointing at the camera, to pointing right / away
		pivot.rotation.y = PI - TAU * float(i) / float(ANGLES)
		pivot.rotation.z = deg_to_rad(18.0)   # tipped up a little, as if aiming at the sky
		for f in 4:
			await RenderingServer.frame_post_draw
		var cimg := vp.get_texture().get_image()
		cimg.convert(Image.FORMAT_RGBA8)
		cimg.save_png(out + "lance_combo_%d.png" % i)
		csheet.blend_rect(cimg, Rect2i(0, 0, SIZE, SIZE), Vector2i((i % 4) * SIZE, (i / 4) * SIZE))
	csheet.save_png(out + "lance_combo_sheet.png")
	print("done")
	quit()

func _aabb(n: Node) -> AABB:
	var box := AABB()
	var first := true
	for v in _all(n):
		if v is VisualInstance3D:
			var b: AABB = (v as VisualInstance3D).global_transform * (v as VisualInstance3D).get_aabb()
			if first:
				box = b
				first = false
			else:
				box = box.merge(b)
	return box

func _all(n: Node) -> Array:
	var list: Array = [n]
	for ch in n.get_children():
		list.append_array(_all(ch))
	return list

func _info(m: String, n: Node) -> void:
	var meshes := 0
	var tris := 0
	var verts := 0
	var tex := []
	var skel := false
	var anims := []
	for v in _all(n):
		if v is MeshInstance3D and v.mesh != null:
			meshes += 1
			var mesh: Mesh = v.mesh
			for s in mesh.get_surface_count():
				var arr := mesh.surface_get_arrays(s)
				var vv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				verts += vv.size()
				var idx = arr[Mesh.ARRAY_INDEX]
				tris += (idx.size() / 3) if idx != null and idx.size() > 0 else vv.size() / 3
				var mat := mesh.surface_get_material(s)
				if v.get_surface_override_material(s) != null:
					mat = v.get_surface_override_material(s)
				if mat is BaseMaterial3D:
					var bm: BaseMaterial3D = mat
					for t in [bm.albedo_texture, bm.normal_texture, bm.metallic_texture, bm.roughness_texture, bm.emission_texture, bm.orm_texture if bm is ORMMaterial3D else null]:
						if t != null:
							tex.append("%dx%d" % [t.get_width(), t.get_height()])
					tex.append("metal %.2f rough %.2f emission %s" % [bm.metallic, bm.roughness, bm.emission_enabled])
		if v is Skeleton3D:
			skel = true
			print("  skeleton bones: ", (v as Skeleton3D).get_bone_count())
		if v is AnimationPlayer:
			anims.append_array((v as AnimationPlayer).get_animation_list())
	print("%s: meshes %d, verts %d, tris %d, skeleton %s, animations %s" % [m, meshes, verts, tris, skel, anims])
	print("  textures/materials: ", tex)
