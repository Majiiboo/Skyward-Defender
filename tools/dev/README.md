# Dev helpers (headless Godot scripts used while building and checking)

Godot: C:\Users\rudyd\Desktop\Godot_v4.7.2-stable_win64_console.exe (call it G below).

- `bump_build.sh N`: sets build 1.0-devN in export_presets.cfg, CLAUDE.md and README-RUDY.md.
- `contact_sheet.gd`: images side by side on grey. Env: CDIR (folder), CFILES (comma list),
  CW (cell width px), CCOLS (columns), OUTP (output png). `G --headless --script tools/dev/contact_sheet.gd`
- `crop.gd`: crop + scale several frames side by side. Env CROP="out x y w h scale in1 in2 ...".
  Use Windows paths (C:/...) inside the env value.
- `gaps.gd`: prints empty column runs of a picture (GF=path): checks that Luna's tiers don't touch.
- `montage.gd`: MONT="dir out cols x y w h scale f0 f1 ...".

Screen captures of a scene: write a small SceneTree script that writes a test save and
changes scene, put override.cfg = tools/sim_override.cfg + "[display] window/size/mode=0"
next to project.godot (the sim save folder, so the real save is never touched), run
`G --path . --script that.gd --write-movie out/f.png --quit-after N`, then delete override.cfg.
- `smoke.gd`: loads every script and runs rule checks (energy, gear rarity/merging/drops,
  loadouts, card pictures). `G --headless --path . --script res://tools/dev/smoke.gd`; exit 1 on failure.
  Run it before every build.
- `capture.gd`: screenshot of a menu page with a made-up save (save_rich.json) in the sim save
  folder. Env CAP_SCENE, CAP_PAGE (Gear tab), CAP_WS (Workshop sub-tab), CAP_SAVE; see the file head.
