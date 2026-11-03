# Skybound Defender: handoff for Claude Code

Read this first. It replaces the chat history this project grew up in.

## Who and what
- Owner: Rudy (non-coder; explain changes in plain English, deliver working results,
  test before saying it works). Art: Luna paints all sprites/icons with an image tool
  and builds the signed Android APK. Never redraw her art in code; ask Rudy for a
  Luna sheet (describe cells exactly: plain black background, same style/framing).
- Godot 4.7.2, GL Compatibility, portrait, base width 480 (expand stretch).
- Portrait mobile shooter: a chibi armored pilot defends a domed base. Drag anywhere to
  move (relative drag) and he fires straight up; lift the finger and he auto-aims.

## Rules that matter
- Build number: export_presets.cfg version/code and version/name ("1.0-devNN") must
  go UP every package (same signing key, install-over). Current: dev86 (code 86).
  Rudy prefers batched updates: many fixes, one bump, one package.
- Update README-RUDY.md with a short plain-English changelog each build.
- Don't copy the reference game "Galaxy Defense" (art, names, turret types).
- Fonts: Exo 2 everywhere (project.godot gui/theme/custom_font), Orbitron only for the
  stage name on Home and the battle banners. OFL licences in fonts/.
- Look: thin single lines, no glow, no circles on side buttons; painted icons dimmed in
  code when inactive.

## Map of the code
- hub.gd / hub.tscn: Home. Built in code from tables (LEFT_RAIL, RIGHT_RAIL, NAV_TABS).
  Nav tabs use layered painted icons (NAV_LAYERS) with per-tab animations (_icon_fx).
- home_frame.gd (top bar + edge docks), nav_dock.gd (bottom bar + notch),
  afk_wallpaper.gd (live battle behind Home, no force field or bars).
- battle.gd: the fight. Waves, enemy behaviours, gems, run levels, card pick, turrets,
  shield/hull, pause, end screens, HUD. FIELD_H/BASE_Y follow the screen height.
- stage_data.gd: SECTORS (planet per 5 stages, sky colours, names), ENEMIES, scaling,
  waves(stage), GEM_XP. cards.gd: power cards and weighted draw.
- pilot_sprite.gd: poses, anchor points (muzzle, nozzle, pods), CHAINS + Anim (painted
  in-between frames, idle breathing), five thruster styles.
- enemy_rig.gd: enemies drawn from Luna's parts (body + hinged wings, Hive Mother body,
  wings, sacs, claws) with smooth flap curves.
- backdrop.gd: sky, planet horizon, city, deck with 4 turret platforms, force field dome.
- gear.gd, modes.gd, store.gd, quests.gd: menu screens built with ui_kit.gd. Gear has a
  Pilot / Turrets switch; the Turrets page edits the loadout and spends coins on levels.
- turrets.gd: TURRETS table (stats, unlock pilot level, strong-vs traits, ready flag),
  level/cost rules, trait bonus, Turrets.read(save). battle.gd mounts the loadout at run
  start (_mount_turret) and runs _update_sentry/_update_lance/_update_storm.
- Save file user://skybound_save.json: coins, pilot_xp, stage_unlocked, selected_stage,
  selected_elite, gear{equipped,levels}, turrets{loadout[4],levels}, thruster, best_score,
  best_kills.

## Design decisions (full doc: Rudy's Claude Doc "Skybound Defender Game Design v1")
- Waves 5/10/20/30 by stage band; mini-boss end of 5-wave stages, later mini every 5,
  big every 10. Sectors: Hive (insects), Scrap drones, Magma, Crystal, Plasma, Sentinel AI.
- Cards: common 60/uncommon 28/epic 10/legendary 2. 3 per pick, 1 free refresh (ad and
  crystal refreshes later). Run level cap 12, slower picks after. Percent cards stack
  (Rapid Pulse +8%, Heavy Bolts +12%, Magnet +50% of the base 60 px range, Reinforced Hull +25%).
  Burst Fire replaces spread (spread is reserved for the dual-gun unlock).
- Base: shield regenerates after a few seconds, hull never does. Pilot has 3 hearts
  (Aegis adds one). Your bolts destroy enemy shots.
- Turrets: 4 mounts. Sentry, Lance Pylon, Gravity Anchor, Swarm Hive, Storm Spire,
  Prism Tower (Luna art in turrets/). Strong vs enemy traits (+50%). Damage budget at
  matching levels: pilot ~60%, turrets ~30%, drone ~10%. Drone unlocks at pilot level 8.
- Early stages must stay gentle; difficulty rises with the player's upgrades.

## Queue (next work)
1. (done dev86: all six turrets work; _update_gravity/_update_swarm(+drones)/_update_prism.
   Enemy traits armoured, shielded, high, wide don't exist on Hive enemies yet, so Lance,
   Swarm and Prism bonuses only matter from sector 2 on. Gravity's direct damage is
   small by design; it groups enemies.)
2. (done dev86: Hive brains. Scout move "flit", _spitter_dodge, Diver "feint" state,
   goo globs from EnemyRig.anchor(kind, "muzzle"). hive_brains=false in battle.gd turns
   them off for simulator comparisons.)
3. Card visuals still to do: Nova ring, Aegis shimmer (bolt thickness, hot muzzle and
   magnet ring are done).
4. Modernise the top bar, nav bar and edge tabs (Rudy finds them flat; mock options first).
5. Sector 2 enemies: write Luna a parts-sheet brief (body + hinged wings or parts, a gun
   port or emitter, a charge frame).
8. Gear rework (Rudy, after dev86). Exactly six upgradable slots, in this order:
   Weapon, Helmet (helmet + visor in one), Chest (armour + Power Orb as ONE piece),
   Gauntlets, Boots, Jetpack. No separate Orb slot: each chest piece has its own orb
   shape (circle, triangle, hexagon...) that changes and upgrades with it. Start with
   3 pieces per slot (18), each a different model/silhouette and colour, not recolours.
   Every slot boosts one battle stat so gear matters in a run (today gear power is
   display only): Weapon = bolt damage (+ weapon type later: dual minis, cannon),
   Helmet = auto-aim accuracy, Chest = hearts / hit recovery, Gauntlets = fire rate,
   Boots = gem magnet, Jetpack = auto-fire speed with finger lifted + thruster style
   (merge THRUSTERS into Jetpack items). The painted pilot stays one body (no per-gear
   pose sets); gear shows on him through code-drawn accents at anchor points: visor
   glow colour, the chest orb's shape and glow, thruster style. Old saves: map the
   old "Power Orb" slot away and keep coins. Needs a Luna sheet of 18 item icons (plain
   black, square, same framing) and a cleaner Gear layout with proper outlines.
   Luna's sheet is in: art_src/gear_sheet.webp (v2, 1920x1280, 6 rows x 3 columns, items
   not on an even grid, plus a bottom row of the 3 chest orbs). Columns: cyan / GREEN /
   purple (v2 repainted the middle column green, boots now a pair). v1 kept as
   art_src/gear_sheet_v1.webp. v2 is more compressed (80 KB vs 197 KB) because the middle
   column was pasted in; ask for Luna's separate middle-column render if it looks soft.
   Sets (AGREED with Rudy 2026-11-03, revised): colour NEVER means strength. A set is
   a named group of 6 pieces (one per slot) with its own look (e.g. "Nightmare":
   charcoal, dark visors); any colour. The first three sets are equal in power: same
   stat budget per piece at the same level; strength comes from upgrade level. Each
   piece gives its slot's main stat (same amount in every set, so mixing is fair) plus
   a smaller secondary stat from its set's theme, so mixing pieces shapes your build.
   Bonus at 3 and at 6 matching pieces (weapon counts):
   Ion (now cyan): 3 = +15% gem XP, 6 = faster shield recharge.
   Scavenger (now green): 3 = +20% coins from kills, 6 = +1 free card refresh per run.
   Void (now purple): 3 = +10% damage, 6 = every 5th bolt pierces.
   Later sets (white, gold, new purple/blue variants...) may be stronger, but by set,
   never by colour. Unlock sets by pilot level / stage, not by power. Show bonuses in
   battle (coins fly faster, piercing bolts) and on the Gear screen.
   Cut by bounding boxes, key black to alpha keeping glows soft (the middle column's
   background is a slightly lighter black). Gear rarity colours should follow the sheet:
   cyan, green, purple.
9. Base and turret redo (Rudy, dev86 playtest): base, deck, platforms and turrets look
   pasted on, too dark and small; turret shots too thin to notice. Brief for Luna:
   LUNA-BRIEF-base-turrets.md (wide base strip with 4 empty sockets, 6 turrets x
   idle/charging/firing without floor plates, shot + impact sprites). Code side, can
   start before her art: turrets ~2x bigger (about 90 px tall), contact shadow and
   socket glow, thicker brighter shots and impacts, a "deploy" drop-in when a turret
   is mounted, small idle motion. Keep the force-field dome in code.
   Luna's round-2 art is in art_src/battle/ (art_src has .gdignore so Godot skips it):
   base_strip.webp = USE THIS (round 3, 2816x880, 2 copies: sockets dark / lit, black
   bg, labels fixed, sockets ~55 px on a phone, flat dome with antenna + dish, no orb
   emitter on top: add one later for the super weapon idea). base_strip_v1.webp is the
   older one with the ring emitter. swarm_hive_compact.webp = the Swarm Hive to use
   (one frame, hovering on a round foot that plugs into a socket; drones fly out in
   code). sentry_two_pieces.webp (gun head + base ring, barrels
   up-left: rotate the head, limit the swing), turrets_sheet.webp (6 rows x idle /
   charging / firing, grey cell backgrounds, firing effects clipped at cell edges: use
   idle + charging, draw shots in code or from shots_sheet; old sideways Sentry here;
   Swarm hangar too wide for a socket), shots_sheet.webp (centred, grey cell bgs;
   rows: sentry tracer+sparks, tracer dup + lance flare, lance beam + storm zap,
   gravity rings + crush, drone + pop, prism beam + burst). MOUNT_X must move to the
   strip's socket centres. Compact Swarm Hive arrived 2026-11-03; ready to build.
10. LATER idea (Rudy, 2026-11-03), not scheduled: base super weapons. The command
   dome's top emitter (the orb/ring on the new base strip) fires a super weapon. Unlocked
   and levelled outside battle; in battle a tap button shows its cooldown ring (60-90 s
   depending on weapon and level). Level raises power and/or shortens cooldown.
   Ideas: orbital beam sweeping the sky, shield overcharge, EMP that stuns all bugs.
   Needs: a button art + per-weapon effect art from Luna, a Gear/base screen to unlock.
   The base itself changes with the equipped super weapon (Rudy): the standard dome is
   the default; a beam weapon gets an orb emitter on top that charges and fires; a
   spread weapon opens its roof and raises mini guns; etc. Plan: ask Luna for the dome
   as a SEPARATE layer (deck strip without dome + one dome per super weapon, each with
   idle / charging / firing frames, same footprint), so domes swap without repainting
   the whole base.
6. Balance pass with a headless simulator (see "Testing"). The simple sim pilot never
   dodges well and dies to Spitter goo from stage 3 on (before and after Hive brains);
   it needs a pilot that steers away from enemy shots before its win rates mean much.
7. (done dev86: smooth-animation pass. Anim.mix() cross-fades pilot frames, facing_s
   squeezes the turn, enemies use e.tilt_s / e.fold, turret fire art fades over idle,
   nav icon top layers fade with the base following in hub._process. Rule: never set
   `modulate` inside _draw (it tints the whole node); pass an alpha to the draw call.
   Waiting on Luna: LUNA-BRIEF-animation.md. When her frames arrive, swap the
   cross-fades for real frames, starting with the pilot turn-around.)

## Testing
- Headless run: godot --headless --import --path . then run scenes with a small
  SceneTree script that instantiates battle.tscn, calls _process in a loop and prints
  results; screenshots via a virtual display. Always run before handing a build over.
