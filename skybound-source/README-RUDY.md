# Skybound Defender — source package for Rudy

This is the full Godot project for the game you have been playtesting.
Source package v2, built on 1.0-dev53 (versionCode 53 in export_presets.cfg is unchanged; the next build must be 54 or higher).
Package name: com.skybound.defender. Main scene: hub.tscn (the Home screen).

## What you need to open it

- Godot 4.3 stable, on a PC. That is the exact version this project was built with.
- Open Godot, choose Import, and pick the project.godot file in this folder.
- Let it finish importing (it takes a minute the first time), then press Play.
  You will see the Home screen on your PC, and you can click the bottom tabs
  with a mouse. Touch/drag in battle works with a mouse too.

## Where the bottom bar and notch live (changed in this package)

The bar and the notch are now ONE drawn shape, so the notch flows into the
bar (and into the rounded corner on the Store and Quests edges) with no seams.

- nav_dock.gd: draws the bar fill, outline and notch as a single shape.
  The numbers at the top (bump_h, bump_w, fillet, edge_corner, colours,
  line_width) are exported, so you can tweak the look in the Inspector or by
  editing those lines. Search nav_dock.gd for "@export".
- hub.gd: _on_nav_tap() slides the notch; search for "_nav_dock".
- The three notch pictures and the cover strip are gone (no longer needed).

Other useful files:
- battle.gd / battle.tscn — the battle screen.
- gear.gd, modes.gd, quests.gd, store.gd — the four menu screens.
- soldier_body.png — the current soldier sprite.
- icons/ — all icons, now crisp vector files (.svg). One file per icon; the
  dim look of inactive tabs is done in code (NAV_DIM in hub.gd).
- icons.gd — tells the game where icons live.
- menu_style.gd / menu_anim.gd — shared button look and press animation.
- export_presets.cfg — the Android export settings. Do not change the
  version code to a lower number; the next build must be 54 or higher.

## How sending work back works

Yes, exactly like you said: you just send the files back here.

- Send back only the files you changed, if that is easier, or the whole
  folder again — either way works.
- Luna will drop your files into the same project, re-import, test that
  it still loads and that the notch still swaps on Store/Gear/Quests,
  and then rebuild the APK with the same signing key as all the other
  builds. That way the new APK installs right over the one on your phone,
  no uninstall needed.
- If you build an APK yourself on your own PC, Godot will sign it with
  your own debug key, which is different from Luna's. That APK will NOT
  install over the current one — your phone will ask you to uninstall
  first, which also wipes the saved best score and coins (that save is
  only best score, best kills and coins, nothing else). And after that,
  Luna's builds will not install over yours either, until you send the
  source back and Luna rebuilds it. So for testing, the cleanest loop is:
  you edit, you send the changed files back, Luna rebuilds and sends one APK.

## Current state, in plain words

- Home, bottom bar, and all four menus open and the bar stays on screen.
- Battle works with relative drag, manual fire while dragging, and
  auto-aim when your finger is lifted.
- v2 changes: new one-piece bar + notch, new vector icon set, one shared button
  animation (the unused animated_button.gd was removed), and about 17 MB of
  leftover icon experiments were deleted. Needs testing on the phone.
- Everything else in the game is still test-only: no real purchases,
  no real ads, coins and packs are show-only.
