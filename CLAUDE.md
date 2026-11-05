# Skybound Defender: handoff for Claude Code

Read this first. It replaces the chat history this project grew up in. The long-term
plan (1.0 / 1.x / 2.0) is in ROADMAP.md.

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
  go UP every package (same signing key, install-over). Current: dev128 (code 128).
  Rudy (2026-11-03): work through the queue item by item; after EACH finished item
  commit, bump the build (+1) and push to GitHub. Ideas he sends mid-work: fold into the
  current batch if small, otherwise queue and say so.
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
- backdrop.gd: sky, planet horizon, city, Luna's base strip (base/base_strip.png, 4
  sockets at STRIP_SOCKETS), socket glow, force field dome.
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
  crystal refreshes later). Run level cap 18 (dev109), slower picks after; cards and level build over the whole stage, reset per stage. Percent cards stack
  (Rapid Pulse +8%, Heavy Bolts +12%, Magnet +50% of the base 60 px range, Reinforced Hull +25%).
  Burst Fire replaces spread (spread is reserved for the dual-gun unlock).
- Base: shield 100, hull 80; NEITHER regenerates (dev108); hull only takes damage once the shield is gone. Pilot has 3 hearts
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
3. CARDS: overcharge (Cards.OVERCHARGE, 3rd pick or last for max-2 cards) dev99; FUSIONS dev102 (Cards.FUSIONS, battle _offer puts a ready fusion in the middle slot, _fuse; new cards chain_spark, wingman (HomeProp.draw_drone), quick_study; Luna art: LUNA-BRIEF-cards.md). (done dev101: card visuals. Nova ring = Luna fx, Aegis = _draw_aegis hex shell; bolt thickness, hot muzzle and
   magnet ring are done).
4. dev107 Rudy playtest: top bar box removed (HomeFrame side 0 = top shade), Chest/Patrol undocked, START removed (Battle tab = Play on Home, NavDock.play_mode, hub _on_nav_tap), nav tile inside the bar (bump_h 4), menus over Frost (frost.gdshader on the frozen AFK; hub _frost), BackButton hidden in hub, UIKit glass restyle, notch: SafeAreaMargin.top_inset + export screen/edge_to_edge=true (battle node shifted by _safe_top, hub view container inset). Menu page LAYOUT overhaul (Modes especially) still to do.
4. GLASS LOOK DONE (dev103, from Luna's Home mockups): glass.gd (Glass.panel/box/rounded: fill, sheen, cyan-to-purple edge); home_frame.gd docks (0 top capsule, -1/1 edge tabs, 2 free tile); nav_dock.gd floating glass bar + lit tile (gold on Battle), all tab names shown (hub NAV_NAMES, _paint_nav_label); hub _pilot_block (name + XP bar). Gear Pilot page: PilotShowcase on PlatformFloor (Luna's "classic" design: platform_floor + platform_rim since dev105, set-bonus glow from platform_rim_lights / platform_floor_lights masks recoloured + additive halo, flash() on upgrade; platform.png = single-picture fallback; TEX_W/TEX_FEET place it), slot tiles 3 left / 3 right. Later: real background blur if it runs well on phones; Store/Quests/Modes screens in glass.
   Battle HUD done (2026-11-03): battle.gd _draw_hud draws a Home-style top bar (HUD_H,
   PAUSE_RECT), XP on its bottom line, LV tab, wave diamonds; pause menu has Back to Hub.
5. Sector 2 enemies: write Luna a parts-sheet brief (body + hinged wings or parts, a gun
   port or emitter, a charge frame).
8b. 3D GEAR DONE (dev118): six sets (ion 1, scavenger 11, void 21, nightmare 31, solar 41, frost 51
   = unlock_stage), 36 ITEMS, Luna 3D renders art_src/gear3d/<set>-<slot>.webp cut by
   tools/cut_gear3d.gd into gear/<id>_t1..t3.png; GearData.tier(level) picks Lv.1-3/4-7/8-10;
   gear.gd _pic falls back to the old painted gear/<id>.png. New weapons in battle.gd WEAPONS:
   railgun (rail: every bolt pierces), laser_rifle, frost_rifle; Scavenger weapon = Arc Welder
   (dual_minis). New stats: turret_dmg, turret_rate, pilot_xp (_pilot_xp_mult), shield, chill
   (frost_level >= 1). Gear text kept SHORT (Rudy): "ATK +12% -> +18%", one line per set.
   Void/Nightmare chests re-rendered spaced (dev120); CUT_ONLY re-cuts single renders.
   Luna uses Canva only to edit (LUNA-GUIDE-canva.md).
   WORKSHOP (dev119): 4th Gear tab, gear.gd _refresh_workshop / _merge; Parts.MERGE (3 alloy ->
   1 cell, 3 cells -> 1 core), Parts.icon (parts/*.png from tools/cut_part_icons.gd). Next:
   merging gear pieces and turret/drone modules (needs duplicates/rarities first).
   MERGE FX (dev125): gear.gd class MergeFX uses Luna's fx/merge_* (chamber solid under the light,
   swirl/ring/flash/shock/rays white, tinted by the result colour); merge_sparks not delivered yet.
8c. GEAR ON THE PILOT (dev122): PilotRig.set_gear(save) from battle, afk_wallpaper, gear.gd;
   held weapon = gear/held/<id>_t<n>.png (cut_gear3d.gd _save_held, upright + mirrored, grip and
   muzzle in gear/held/held_points.gd HeldPoints), PilotRig.gun(), HELD_LEN; front view draws it
   mirrored at the fist. PilotRig.tinted(tex, set) recolours cyan/purple light (clear_mipmaps,
   recolour, generate_mipmaps: the small mip copies kept the old colours) for visor, helmet
   (side + front), orb and battle bolts (_bolt_set). Starter suit art: LUNA-BRIEF-starter-suit.md.
8d. SUITS (dev126): PilotRig.suit "starter" (pilot_rig_starter/, pilot_front_starter/, art_src/starter,
   SUIT=starter in cut_pilot_art.gd + cut_batch_d.gd; STARTER_FIX knee, STARTER_LIFT) or "commander"
   (save stage_unlocked > COMMANDER_STAGE 10; save "suit" = player choice; suit_for(save) in
   set_gear). Gear _suit_btn toggles; battle Area Complete says NEW SUIT once ("commander_seen").
6b. Balance pass 2 DONE (dev127, stages 21-60): SIM_KIT=auto in tools/balance_sim.gd (_auto_kit: coins
   so far x1.5, 60% gear / 40% turrets on open mounts, even levels). hp_mult +5%/stage 11-30, +2%
   after; waves(): extra = (min(stage,30)-1)/2 + (stage-30)/4, and from stage 21 extra ramps 60%..100%
   over waves 1-5. Human bot: 22-50 win 4/4, 55 and 60 win 3/4. Turrets still ~15-25% of damage.
16. LONG-GAME PLAN (Rudy, 2026-11-04), in this order: (a) DONE dev128 turret tracks ATK/Rate/Range
   Lv.1-20 (Turrets.TRACKS, stats() -> battle t.def, level_of = sum, milestone every 5 = +5% dmg;
   save turrets.tracks; gear.gd _on_track_upgrade, _milestone_toast). (b) Turret power cards, only
   offered when that turret is mounted: some CHANGE what it does, some EXTEND it and grow per
   level (e.g. Sentry bolts bounce to 1, 2, 3 more bugs); Luna card art later. (c) Milestones for
   gear pieces and the drone too. (d) AFK farming per stage: Patrol earns while the game is
   closed (and while open); pick a cleared stage, capped storage. MOSTLY COINS (by stage), plus
   that stage's element (early Alloy, later Cells, then Cores, slowly), plus RARE gear copies for
   merging (Rudy: common weapons/pieces on low stages, better rarities only on high stages, rare
   and spread out). Gear copies need (f). (e) Pilot talent points (Offense / Defense /
   Utility tree, a Gear sub-tab). (f) Gear rarity: max level 30, rarity caps the level, raised by
   merging copies in the Workshop (needs gear drops). (g) Re-tune: gentle to 15, then each boss a
   soft wall; target 30-40 hours to stage 60; replays pay half coins.
15. GUIDED FIRST-TIME TIPS (Rudy idea, queued 2026-11-04): when something unlocks or is used
   the first time (gear, turrets, Workshop, drone...), a short guided tip: dim the screen,
   spotlight the one button to tap (only it works), a small animated box "Tap here" with
   the tiny chibi pilot beside it, step by step across screens; saved so each shows once.
8. GEAR REWORK DONE (dev97): gear_data.gd (GearData: SLOTS, SETS ion/scavenger/void unlocked at
   stages 1/11/21, ITEMS 18, stats() -> battle, read() maps old saves), gear/ cut by
   tools/cut_gear_art.gd, WEAPONS dual_minis + pulse_cannon, Void pierce5, Gear page
   rewritten with PilotShowcase (live rig). Gear art is Luna's older painted style: a 3D
   re-render can come later. Orb pictures cut (gear/orb_*.png), not yet shown on the rig.
   Original spec (Rudy, after dev86). Exactly six upgradable slots, in this order:
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
9a. (dev87) Sentry hover (Rudy's idea): head floats SENTRY_GAP above the base with bob,
   drift, swing lean (t.swing), a shot-dip spring (t.hov_y/hov_v) and lift-off after
   landing (t.lift); _draw_sentry_field draws the field on _fx. Rudy will send more
   turret ideas.
9. (done for dev87: base strip in battle and Home via Backdrop.draw_strip /
   socket_pos / draw_socket_glow; turrets on sockets with TURRET_LOOK sizes, two-piece
   Sentry (_sentry_geo), additive effect layer _fx/_draw_fx with Luna's fx/*.png, drop-in
   on mount. Re-cut art with tools/cut_battle_art.gd.) Original notes:
   Base and turret redo (Rudy, dev86 playtest): base, deck, platforms and turrets look
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
11. Pilot rig test (Rudy, 2026-11-03): Luna paints the pilot in a 3D-rendered look as
   parts (LUNA-BRIEF-pilot-parts.md: assembled reference + 16 parts at the same
   scale). Build a cut-out rig (Node2D bones or a code rig like enemy_rig.gd): pivots
   measured from the reference, idle breathing, aim arms + rifle at the target, lean
   by tilting torso/legs, recoil, jetpack bob, visor glow, legs dangling with the
   hover. Show it side by side with the current painted pilot in a test scene first;
   Rudy decides before it replaces PilotSprite. If it works, bugs follow the same way.
   Luna's round 1 is in art_src/pilot/ (reference.webp, parts_sheet.webp 4x4 on black,
   rifle_side.webp, power_orb.webp). Parts are smaller than the reference (~0.56-0.63
   and not uniform): fit each part to its place on the reference. Sheet has: helmet,
   visor (glow baked in), torso (empty orb socket), hips, R upper arm, R forearm+fist,
   L upper arm, L open hand, 2 shoulder pads, 2 thighs, ONE shin+boot (mirror it),
   jetpack (flames baked in: crop), rifle. Round 2 (2026-11-03): left_arm.webp = the
   WHOLE left arm in one piece (shoulder pad, upper arm, elbow pad, forearm, open hand),
   larger scale, slight 3/4 turn: crop below the elbow pad for the left forearm+hand,
   scale to the reference. jetpack_no_flames.webp = use instead of the sheet's jetpack.
   All parts are in: ready to build the rig test.
   Thrusters: LUNA-BRIEF-thrusters.md asks for painted flame LAYERS per style (outer
   plume, core, nozzle glow, particle; black bg, pointing down). Draw them on an
   additive layer, scaled by hover power, with flicker/scroll in code. Until they
   arrive, keep PilotSprite.draw_thruster's code flames.
   BUILT (2026-11-03) and IN GAME behind PilotRig.ENABLED (false = painted PilotSprite
   again): pilot_rig_view.gd (PilotRigView node: flames layer behind, solid, glow
   layer in front) is added in battle.gd before _fx and in afk_wallpaper.gd; battle
   feeds aim (drag direction or idle_aim_ang), draw_bank / 0.3, hover, vy; _kick()
   triggers recoil; _muzzle_world() uses the rig muzzle. PilotRig.RIFLE = "rifle_side"
   (Luna's side view, cut upright). Gear still shows pilot/idle.png. Contrast pass: LIFT
   (parts drawn x1.3), RIM (flat-colour outline via a shader on a layer behind him,
   4 one-pixel offsets), BACKLIGHT (faint soft_glow), SIZE (x1.12 of PILOT_HEIGHT;
   visual only, hit size unchanged). Rudy is playtesting;
   then a Luna brief for whatever he notices (likely chunkier legs/arms at reference scale).
   Details:
   tools/cut_pilot_art.gd cuts parts + flames into pilot_rig/ (parts keyed off black
   with dark insides kept solid, all at the parts sheet's pixel scale; helmet cut
   without its neck ball; left forearm = left_arm.webp below the elbow x0.575; jetpack
   = jetpack_no_flames x0.44; power_orb drawn in the torso socket; visor_light.png =
   the visor line only, for the additive pulse). pilot_rig.gd: PARTS table (scale to
   reference px, pivot in the picture, pivot's place on the reference), Rig state class
   (update(delta, aim, lean, hover, vy), fire()), solve() -> transforms, then draw()
   (solid), draw_light() (flames, additive layer BEHIND him) and draw_glow() (visor +
   muzzle flash, additive layer IN FRONT). Arms are two-bone IK: rifle grip out to the
   side swinging with the aim, free left arm for balance. He mirrors when aiming right
   (squeeze min 0.3). Part scales were fitted against reference.webp (helmet 1.78 and
   torso 1.26 by correlation, the rest by eye); legs and arms on the sheet are longer
   and thinner than the chibi reference, so they don't match it exactly.
   rig_test.tscn compares old and new (60 px + 2x) through 15 phases; run it with the
   user arg "fit" (godot ... -- fit, wide override.cfg viewport) to see the rig over the
   reference. Rig is drawn ~1270 reference px = `height`. To adopt: replace the
   PilotSprite.draw call in battle.gd/afk_wallpaper.gd, add an additive node behind
   the pilot for draw_light, and use X.muzzle for the bullet start.
   Flames arrived: art_src/pilot/flames_sheet.webp (1920x1280, uneven grid). Columns:
   plume, nozzle glow, particle. Rows: Ion (cloudy wide plume with core baked in; blue
   glow; blue sparks), Plasma (tall jet with lightning, spans 2 rows; white-blue ring;
   electric arc), Pressure (no plume; grey ring; shock ring), Gravity (purple swirl;
   double ring; falling specks), Pixel (pixel plume; square glow; ember), plus a grey
   smoke puff. No separate cores (draw a thin core in code). The Ion glow and the
   Plasma/Pressure rings sit on faint coloured boxes: when cutting, multiply by a soft
   radial mask so no square edge shows. Ion plume is wide and cloudy: squeeze it
   horizontally and stretch with hover power. A Gemini sheet was
   compared and rejected (baked-in labels, sticker outlines, different design).
11c. PILOT LEVELS (done dev87): Turrets.LEVEL_XP_EARLY [0,150,330,560,850] then +500,+650,...
   (xp_for_level); first_clear_bonus = 60 + 20*stage (normal mode, first win only);
   unlocks Sentry 5, Lance 8, Storm 11, Gravity 14, Swarm 18, Prism 22; battle and Home
   need mount open AND pilot level. Next: real missions (quests.gd is show-only) paying
   pilot XP and coins.
11b. MOUNTS (done dev87): Turrets.MOUNT_OPENS_AFTER [5, 15, 25, 40] = stage that must be
   cleared to open mount i (save stage_unlocked > N); battle mounts only open mounts
   and draws Backdrop.draw_socket_lock on closed ones; Gear/Home follow; Deploy Sentry
   card removed (turret_mult gone). Pilot level still unlocks turret TYPES.
11f. 3D BUGS (dev88): tools/cut_bug_art.gd cuts art_src/dev87 (bug_*.webp, hive_mother_pieces,
   bug_wings) into enemies/parts; EnemyRig.PARTS re-tuned for head-down bodies (rest > 0
   sweeps wings back); Hive Mother sacs on her back (sac_pos -0.24, pivot 0.5,0.80),
   claws at the front, hatchlings spawn from her back. hive_hatchling.png is still the old
   2D art (cross-fades into the new Scout).
11e. ENEMY ROLES (done dev87): Diver states fly -> aim (0.6 s, e.target on the dome, red
   dashed line) -> dive (e.dive_v = speed x dive_mult 2.0; e.vel is re-measured every frame,
   never store motion in it) -> base_dmg 13, ignores the pilot (feint removed). Drifter
   hp 4, "spores": 1 -> "spore" enemies (code-drawn, move "spore",
   no gem, base_dmg 5) via battle.spawned. Hive Mother launches Divers when enraged
   (launch_every 7). _meet() shows the NEW ENEMY card (save "seen_enemies").
   Luna round 3 art (all usable) is in Downloads: hive-mother-pieces, bug-wings-single,
   locked-socket-lid-only, icons-badge-padlock; plus round 2 (bugs top-down organic
   3D singles, 6 backgrounds, bolt/goo, icons, quad drone, chest lid) and round 1
   (cards, gems, impact, nova, hive zone A #915d, chest). NOT yet in the game.
11d. LUNA-BRIEF-dev87.md (2026-11-03): the art list for this batch, in order: backgrounds,
   power card pictures (cards.gd "icon" still borrows nav icons), gems/bolt/impact/goo,
   locked socket shutter (3 frames), Home Chest/Patrol as layers, UI icons, pilot
   parts round 3 (chunky arms/legs at reference scale), Hive bugs in 3D (later).
12. AREAS DONE (dev94): StageData.AREAS (6, name/boss/brief) + SECTORS = 12 zones; area(),
   area_stage(), boss_kind() mini/boss; MAX_STAGE 60; _maybe_brief (save areas_briefed);
   AREA COMPLETE on the end screen. Later areas reuse Hive bugs: LUNA-BRIEF-areas.md.
   Original plan: an area =
   a planet + an enemy family, 10 stages, big boss at stage 10; two zones of 5 (A orbit,
   B descent; mini-boss at stage 5) so the background changes every 5 stages and the
   world every 10. Areas: 1 Hive, 2 Scrap belt, 3 Magma, 4 Crystal, 5 Plasma storm,
   6 Sentinel. Needs SECTORS reworked from 5 to 10 stages per planet (+ zone), an
   "Area complete" screen after each boss, new enemies per area. Luna brief for the
   painted layers: LUNA-BRIEF-backgrounds.md (Area 1 first).
13. STAGE MAP DONE (dev95): stage_map.gd/tscn from Home's stage name; save "stars" {stage: 1-3}
   written in battle._end_run (_took_damage). Story briefing done as _maybe_brief.
   Original idea (Rudy, Candy Crush style): a scrolling trail of stage nodes on the
   Home "stages" button, grouped by area with a themed backdrop per area, boss nodes
   bigger, cleared stages replayable (best score / stars), the next stage pulsing.
   Light STORY (Claude's suggestion): a short comms briefing card at the start of each
   area and after its boss (commander portrait + 2-3 lines), not cutscenes.
14. RUDY PLAYTEST dev107 (stages 1-13, 2026-11-03). Agreed plan, in batches:
   A DONE (dev108; Luna brief LUNA-BRIEF-batch-d.md). Was: turrets track targets in range (smooth search sweep),
   long-press a turret = red see-through range ring, turrets much stronger ("now I can
   handle this"), Sentry centring in battle; shield does NOT regenerate, hull only takes
   damage once the shield is gone, lower base HP / more bug damage so the base matters;
   gems stand out on blue worlds (dark outline + bright core / pulse); Aegis = a slim
   light that forms around his body (rim outline), not the hex box; Hive Mother much
   bigger, 5 health layers (same total toughness), hatching made obvious; mid-wave
   mini-bosses in later stages, more small bugs alongside bosses as stages rise; bugs drop
   COINS too (gems = XP), everything left flies to him at the end of each wave and at
   the end of the stage; stage end: last bug dies -> pickups vacuum in -> pilot turns to
   a flying pose and flies off the top -> Stage Cleared (no reward icons popping at the
   final kill); some bugs double-shoot in later stages; weak bugs die faster; cards stop
   being offered once maxed (every card: 3 levels, 3rd = overcharge, then gone).
   B DONE (dev110, Rudy approved). Was: every card worth taking, cut the
   dull ones, remove Wingman Drone card (drone becomes a Gear sidekick), redo fusions,
   cards that change how bolts LOOK (shape/colour/trail), not only size. Legendary
   (Nova Burst) is one-shot.
   C DONE (dev111; Store / Quests / Gear page layouts still to redesign). Was: pause menu in the glass style (Resume / Back to Hub centred, sound toggle
   placeholder, stage info, row of your cards), battle top bar overhaul, Stage Cleared
   screen overhaul, 3 stage objectives shown at start / in pause / on the clear screen
   (stars explained), menu page layouts.
   D DONE dev112-114 (two-piece turrets, drone sidekick drone_data.gd, front-view turn PilotRig.draw_front; gear tier art waits on Rudy). Was: drone sidekick (unlock later, upgrade + customise looks/weapon, in
   Gear), pilot turn-around frames (no more instant mirror), muzzle flash, bolt variants
   for cards, turret heads as separate pieces (to rotate), gear tiers that look
   different when upgraded.
   Answers given: leaving mid-stage restarts the stage from wave 1; Spitter goo aims at
   the pilot (flies sideways when he is level with it).
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
6. Balance pass 1 DONE (dev87, stages 1-10) with tools/balance_sim.gd (see Testing).
   Changes: hp_mult +7%/stage to 5 then +10%; waves 5 (st 1-5), 8 (6-10); scouts
   4 + 2w/3 + extra/2, drifters 1 + w/3 + extra/3; Spitters from wave 3 in stage 3,
   fire_every 3.4; group 1/2/3 (st 1, 2-5, 6+), gap 2.0/1.8/1.7; idle_fire_ratio 1.0
   (Rudy: auto-aim as strong as dragging); MAGNET_BASE 90 (+30 per Magnet card);
   Sentry 0.9 dmg every 0.85 s. Result (8 runs each): afk wins 1-5, fails from 6;
   "human" bot with starting Sentry wins 1-8, ~60% at 9-10; with sentry+lance+storm
   lvl 2 wins 6-10 ~95%. Next: Rudy's playtest; stages 11-30 not tuned yet; Sentry
   still only ~5% of damage (range 430 from the base, the pilot kills most bugs first).
   Rudy may screen-record the reference game on autopilot for pacing (stage length,
   counts), not for its cards/turrets; extract frames to compare.
7. (done dev86: smooth-animation pass. Anim.mix() cross-fades pilot frames, facing_s
   squeezes the turn, enemies use e.tilt_s / e.fold, turret fire art fades over idle,
   nav icon top layers fade with the base following in hub._process. Rule: never set
   `modulate` inside _draw (it tints the whole node); pass an alpha to the draw call.
   Waiting on Luna: LUNA-BRIEF-animation.md. When her frames arrive, swap the
   cross-fades for real frames, starting with the pilot turn-around.)

## Testing
- Balance: cp tools/sim_override.cfg override.cfg (separate save dir "skybound_sim"),
  SIM_STAGES=1-10 SIM_RUNS=8 SIM_PILOT=afk|dodge|skilled|human [SIM_TURRETS=sentry,lance,,
  SIM_LEVEL=2] godot --headless --path . --script res://tools/balance_sim.gd, then
  delete override.cfg. "human" = best guess at a real player. Movie captures:
  override.cfg with [display] window/size/mode=0 and --write-movie; do NOT run test
  harnesses that end a stage without the sim override (they write the real save).
- Headless run: godot --headless --import --path . then run scenes with a small
  SceneTree script that instantiates battle.tscn, calls _process in a loop and prints
  results; screenshots via a virtual display. Always run before handing a build over.
