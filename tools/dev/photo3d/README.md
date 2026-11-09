# photo3d: photograph Luna's 3D models (queue item 30, the 3D test)

A tiny Godot project of its own (the main project ignores this folder: .gdignore).
It loads models/<name>.glb, frames each one, turns it through 8 angles under one
lighting setup and writes out/<name>_<n>.png (transparent) plus out/<name>_sheet.png.
It also prints what is inside each model (meshes, triangles, textures, skeleton).

neon.gdshader is the "photo" material: the image-to-3D textures come out flat grey,
so it darkens the armour toward Luna's black and lets the coloured light lines glow.

Run (from a copy outside the repo, so the GLBs and outputs never land in git):
  1. copy this folder somewhere, put the .glb files in models/
  2. godot --headless --path <copy> --import
  3. godot --path <copy> --script res://shoot.gd      (needs a window: not headless)

2026-11-09 test: rook.glb, rook_rigged.glb, lance_base.glb, lance_head.glb from Luna
(Downloads). Next step if Rudy goes ahead: more angles (32-ring turn for the hero
swivel, an aim fan for the Lance head), the head's pivot + muzzle measured, frames
cut into heroes/<id>/ and turrets/ like the 2D art.
