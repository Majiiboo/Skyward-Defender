# Skybound Defender: handoff for Claude Code

Read this first. It replaces the chat history this project grew up in. The long-term
plan (1.0 / 1.x / 2.0) is in ROADMAP.md.

## Where we are (hand-over, 2026-11-07, build dev210)
A new session picks up here. Everything is committed and pushed (github.com/Majiiboo/Skyward-Defender).
- UNPUSHED since dev210: 0 updates. dev210 = Rudy's dev209 playtest BATCH 1 (queue item 29: gameplay + broken
  bits, README-RUDY dev210). NEXT: batch 2 = the style pass (Rudy shared a "menu ideas" folder on his
  Desktop + an article: big square cards, one dominant action, icons over text, micro-animations,
  glass); then the Hero page + Ascend ladder (item 30); Luna is on the 3D test (item 30).
  dev209 (pushed 2026-11-07, Fable 5.1 session) carried the three updates listed next (README-RUDY dev209):
  Luna's star map art + Rook 5-star, icons 3, Store 2.0 art complete. Luna has NO open brief.
  1. LUNA STAR MAP + ROOK 5-STAR in (unpushed update 1): art_src/talents/ (nebula_0..3, the redone
     nebula_0 in use, _v1 kept; node_/system_ dim/lit/next), tools/cut_talents.gd -> talents/nebula_<s>.png
     640x720 alpha-from-light + node_* / system_* 128 keyed; gear.gd StarMap: node_pos = shares of the
     WHOLE sector box (Luna painted her figure lines in that frame), nebula drawn exactly over its box
     (alpha 0.95, the code gradient blends), _lit pieces tinted toward the constellation colour.
     Rook: art_src/heroes/rook/t3_turn_1..8 + portrait_t3 (+ t3_turn_4_alt), cut_heroes -> heroes/rook/t3/
     + portrait_t3.png; no code change (PilotRig hero_mode picks the folder up). LUNA-PROGRAM rows 11, 12
     DELIVERED; open: 13 icons 3, Store leftovers (chest body/lid/burst x3, crystals_2..4). Rudy: the
     Genesis recording (a lane tower defense) has nothing for us; not written up.
  2. LUNA ICONS 3 in (unpushed update 2; art_src/icons3/ materials_sheet.webp 4x4 of 256 + pic_<card>.webp x10;
     tools/cut_icons3.gd MATS order = the brief's cells -> icons/mat_<id>.png 96 (Materials.icon picks them up;
     mat_shard on the hero panel via UIKit.ic("mat_shard", "ic_shard"); mat_token unused until the Exchange),
     cards/pic_<id>.png 256 (battle _card_pic prefers them); pic_cryo_deep redone the same night (v1 kept). LUNA-PROGRAM row 13 DELIVERED; Luna's only open
     work: Store leftovers (row 9).
     STORE PIECE 1 (same update): art_src/store2/chest_l_body.webp -> icons/chest3d_l_body.png (cut_store2 already
     handled it); HomeProp.tier + has_tier(k) (all three chest3d_<k>_body/_lid/_burst exist) + _stacked lid draw
     (Luna's pieces share one frame: lid over the body rect, hinge at the back); store _chest_fx opens a
     HomeProp with the tier when has_tier, else the chest2 closed/open pop. Tested with stand-in lid/burst
     (removed); tune the lid hinge when her lid lands. Still owed: chest_u/e/l lid + burst, chest_u/e body, crystals_2..4.
  3. LUNA STORE 2.0 COMPLETE (unpushed update 3): the last twelve pieces (chest_u/e/l body + lid + burst, crystals_2..4)
     in art_src/store2/, cut_store2 -> icons/chest3d_<t>_body/_lid/_burst.png 256 + crystals_2..4.png 192. HomeProp
     _stacked: the burst drawn in the body's frame from the chest mouth (_draw_light), lid over the body rect
     tipping from its back hinge; store _chest_fx uses it for all three tiers (captured, good). store.gd PACKS
     = five crystal packs (x80..x3200, placeholder prices) + Starter + Speed, crystal_pile(n) picks crystals_1..5.
     LUNA-PROGRAM: every row delivered; no open brief. Next brief when needed: super weapons (queue 10).
     LID LESSON (Rudy): chest_l_lid came as the whole closed chest; Luna redid it as a slab the same night
     (closed render kept as art_src/store2/chest_l_lid_closed.webp). cut_store2 LID_FROM_CLOSED + _lid_from_closed
     (warp a closed render's seam onto the body rim, cut below) exist but are unused; a first try with rough
     corners looked wrong, so prefer a real lid render. LUNA-BRIEF-store-2.md reworded: a lid = a slab on black.
  dev206 (pushed 2026-11-06, Fable 5.1 session) carried the eleven updates listed next (README-RUDY
  dev206). STATE FOR THE NEXT SESSION: 7 Luna briefs went out today, none still open (LUNA-PROGRAM.md
  rows 9, 11, 12, 13 all landed in unpushed updates 1-3; Luna is free for the next brief); Rudy's rules of the day: stars not stage
  gates (DESIGN-stars.md), evolutions keep the theme / skins are named themes, no dividing lines
  on maps, Luna art never redrawn in code; nothing has been played on a phone since dev166, so the
  balance moves after the re-tune (more boss layers, boss earlier on planet 1, chip damage early)
  wait for his playtest. Next in line: IDEAS-tap-titans-afk.md 1 (the next goal named on Home) and
  2 (the gain on every Level up button); then the super weapons (queue 10) now that the domes exist.
  11. LUNA HOME 2 in (41 renders; art_src/skies/<p>/ stars / clouds / planet / glow / floaters +
     art_src/home2/ strip_nodome, dome_standard, dome_<beam|shield|emp>_<1..3>; tools/cut_home2.gd
     -> skies/<p>_stars.webp 640x1280, _clouds.webp (alpha from light), _planet.webp 800x500 (keyed),
     _glow.webp, _float_0..7.png; base/strip_nodome.png (unused: the painted strip stays), base/
     dome_<kind>.png on ONE union canvas 406x480): Backdrop.PLANET_OF / planet_of / has_sky_layers /
     draw_sky_layers (stars loop t*3, clouds t*5.5, FLOAT_LANES x8, planet zoom, glow pulse) called
     from draw_world when the layers exist (all three callers: afk_wallpaper, battle, menu_backdrop);
     draw_strip -> draw_dome (STRIP_DOME Rect2(0.427, 0, 0.146, 0.85), DOME_IN_CANVAS, dome_kind /
     dome_frame statics for queue item 10). Stage map bands still use backdrops/<bg>.webp.
     IDEAS-tap-titans-afk.md: Rudy's two recordings (next goal chip, gain on the button, hold to
     level, unlock splash, prestige later, auto-advance, progress bundles).
  10. LUNA-BRIEF-icons-3.md (materials sheet mat_<id> x14 incl. mat_shard / mat_token, ten pic_<card>)
     + program row 13; EFFICIENCY pass 1 (27): battle _hud_title / _hud_num / _hud_nx / _hud_clock
     cached (rebuilt on wave change in horde, per second for the clock), _fx_add cap 180 / 90 lite.
  9. HUD CARD ROW + OVERCHARGE MOMENT (IDEAS-rogue-defense.md, Undead 2 / 3): battle _card_tex
     (cached card pictures), _draw_card_row(at) beside the LV chip (18 px pictures, rarity frame,
     gold when Cards.overcharged, pips per level, "+n" overflow); _pick_card overcharge: nova,
     burst, "OVERCHARGE!" text, hitstop 0.12, shake, Sfx level.
  8. FROM THE RECORDINGS (IDEAS-rogue-defense.md 1, 3, Undead 1): battle _dmg_by + _count_dmg at
     every hit (b.src / t.type / "hero" / "drone"), _dmg_rows(compact) on the pause menu and the
     end screen (share bar, total, per second); Cards.chain_of(id) + CHAIN tag in _make_card;
     coin refreshes after the free ones (_coin_refreshes, 150 x n run coins, _coins_f).
  7. RE-TUNE pass 1 (16 g, dev198 sweeps in README update 7): StageData.HP_B 1.02 -> 1.035; battle
     BOSS_WALL 1.5 on the planet boss (stage % 10 == 0, not mini, not horde) in _spawn; the boss
     inserted halfway into the queue from stage 11 (a third from 21); WRECKER_HOLD_MAX 6 s (e.hold_t).
     Sim: _auto_kit stars by stage (SIM_STAR), turret stars; sweeps: Normal 1-60 all won, hull
     untouched (the bot never gets hit); Elite 15 fixed, 25 / 40 half; kit -6 loses half at 20.
     NEXT after Rudy's phone playtest: more boss layers, boss earlier on planet 1, chip damage early.
  6. LUNA STORE ART part 1 (keys + chest stack checks; art_src/store2/, tools/cut_store2.gd ->
     icons/mat_key_u / mat_key_e.png (Materials.icon picks them up), icons/key_l.png, icons/
     chest2_<t>_closed / _open.png from the stack checks; the cutter also handles chest pieces,
     packs, piles and ic_* when delivered). store.gd chest cards UIKit.ic("chest2_<t>_closed", icon),
     _chest_fx(reward, tier) closed -> open pop (HomeProp fallback); the Home chest overlay stays text;
     packs pack_<id>, coins_N by deal size, crystals_1 / _5 + pack_starter, ic_pity line, ic_free on
     the FREE button. IDEAS-rogue-defense.md: Rudy's two recordings (stats panel, boss as half the
     stage, chain cards, coin rerolls, card row on the HUD).
     SIM: balance_sim _auto_kit stars by stage (SIM_STAR override), turret stars in the kit.
  5. SCRAP BELT FAMILY in (queue 17 b; Luna 36 renders, art_src/scrap/, tools/cut_scrap.gd ->
     enemies/scrap/<id>_whole + pieces at the whole's scale, enemies/parts/<id>_chunk_N, ui/
     commander_calm / _urgent): StageData.ENEMIES mite / hulk / rivet / dart / bolt / wrecker /
     queen ("family" scrap, tex "", "name" on bosses, hulk spawns_on_death bolt, rivet "shot" rivet,
     queen spawns mite / launches dart), SCRAP, is_boss(id), boss_id(stage, mini), MACHINE_FOR +
     machine_share (waves split each role from stage 11; rivet 13, dart 15; mid-stage young boss
     alternates queen / hive_mother). EnemyRig.MACHINES (anchors on the whole), is_machine,
     machine_anchor, draw_machine (rotors, panels, pod sac, flame, Wrecker arm ext + claw, Queen
     arms + hold open). battle: _is_boss / _is_boss_id (all e.type == "hive_mother" checks),
     _muzzle_of, "wrecker" move (seek / drop / hold / lift, t.held_by; _update_turrets skips a held
     turret), boss brood / launches by def, hulk bolts, rivet shots drawn, dart lunges, shards +
     variants for machines, boss bar name, commander portrait in _maybe_brief; afk_wallpaper boss
     + machines; promotion / patrol use is_boss; smoke _check_scrap. NOT built: Queen / Wrecker
     specific sounds, the Wrecker wrecking a mount for good (it only holds), planets 3-6 families.
  4. LUNA HERO EVOLUTIONS in (60 renders: <hero>-t3_turn_1..8, portrait_t2, portrait_t3 for all
     six incl. Rook; archived art_src/heroes/<id>/t3_turn_n.webp + portrait_tk.webp; cut_heroes
     _cut_tiers now makes heroes/<id>/ first; heroes/<id>/t3/turn_1..8.png + portrait_t2/t3.png;
     PilotRig.LOOK_AT_STARS {2: 2, 3: 5} + look_tier(): t3 frames and portrait_t3 from 5 stars,
     portrait_t2 from 2, a rim pass at 2-4 in draw_hero; gear _hero_portrait via look_tier).
     RULE (Rudy 2026-11-06): an evolution keeps the hero's theme and colours and only ADDS pieces;
     palette changes are SKINS. Rook's white-gold t3 moved to heroes/rook/skins/ceremonial/ (+
     art_src same path; no code reads it yet), LUNA-BRIEF-rook-5star.md asks for the set in his
     charcoal + purple; Rook at 5 stars = base look until it lands. NO DIVIDING LINES (Rudy): gear StarMap BLEND 260
     gradient quads between constellation skies (Luna skies drawn overlapping, brief says fade
     edges); stage_map BLEND_H 150: every zone's texture drawn again above its top as a
     draw_polygon with per-vertex alpha (1 -> 0) and uvs, the cyan line removed, titles drawn
     after. Remember: run --import after cutting, or ResourceLoader.exists is false for new PNGs.
  3. TALENT MAP (queue 16 e, dev197): talents.gd Talents (SIZE 40, CYCLE of 10 stats, CARD_AT
     {10 focus_fire, 20 salvage, 30 second_wind, 40 mirror_shell}, node / text / bonus_text, cost
     (coins 300 n (1 + n/10); core from 11, essence by ELEMENTS cycle from 21, coil + 3 essences
     from 31), door(n) = n (pilot level), why_not / affordable / buy, bonus() applied at the end of
     Heroes.stats, cards()); save "talents" = nodes bought. cards.gd talent cards ("talent": node,
     "pic" = stat icons) + OVERCHARGE; Cards.draw(.., talents) gates them; battle _talents,
     _salvage / _salvage_n (10th kill part in _kill), _second_wind (_hurt_pilot), _mirror /
     _mirror_through (enemy_bullets clash spawns a "mirrored" bolt), reset per run. gear.gd
     _talent_btn (TALENTS beside STATS) + _talents_screen (5-column grid, detail, Buy, dot);
     Progress.attention gear dot. smoke _check_talents. Luna: card art for the four later.
     STAR MAP (Rudy, same evening): gear.gd class StarMap (SECTORS = four constellations with
     name / col / lore, SHAPES = ten points per figure in charting order, node_pos(n, w),
     _draw: sector skies + soft_glow nebulae (talents/nebula_<s>.png when painted), twinkling
     dots, gold / dashed cyan / dotted lines, a dotted jump between constellations, _star()
     code stars or talents/node_* / system_* pieces); _talents_screen = full page (header,
     ScrollContainer + StarMap with tap buttons, tags and constellation labels, detail panel
     with the Chart star button; opens scrolled to the next star). LUNA-BRIEF-talent-map.md
     (skies with ghost figures + star pieces), art_src/ref/talent_map_ref*.png.
  2. STARS (Rudy 2026-11-06, DESIGN-stars.md; replaces the afternoon's stage gates): gates.gd Gates =
     the star standard: MAX_STAR 10 (1-5 gold, 6-10 red), power_mult (+8% gold / +12% red),
     level_cap(kind, star) (hero 10 / turret track 4 / drone 2 a star; Heroes.MAX_LEVEL 100,
     Turrets.MAX_TRACK 40, DroneData.MAX_LEVEL 20), DOOR pilot levels [5,12,20,28,35,40,45,50,55],
     NEED tables (coins / shards / essence / coil / rotor / gyro / flightcore), need(kind, star, el),
     need_text, why_not (door, level cap, shards, mats, coins in that order), pay, text / badge
     ("R★★") / long_text / color, premium. Heroes: save "tiers" = the star; star_need / next_tier_cost /
     tier_need / why_not_evolve / can_evolve(h, id, save) / evolve pay via Gates; level_cap(h, id);
     stats use power_mult; gate() 0 / gate_open true; migrate tier 1. Turrets: read "stars",
     stats(id, tr, star), star / track_cap(star) / lowest_track / star_need / why_not_star / star_up.
     DroneData: read "stars" per body, star / level_cap(dr) / star_mult / star_need / why_not_star /
     star_up. battle: turret_stars -> Turrets.stats, DroneData.star_mult on drone damage. gear.gd:
     hero name = earned stars (grade a word), roster rows without stars, tiles "Lv.n ★★" / "Lv.n R★",
     Level up "Lv.N cap next star", Evolve button = why_not; Turrets page _t_star Star up button +
     _on_turret_star, next-star line, tracks "Lv.N cap: next star"; Drone page Star up + _on_drone_star
     + next-star line; weapons keep the rarity cap. pilot_rig halo grows per star, red for red stars;
     HeroStand glow per star; balance_sim kit stops at Lv.50. smoke _check_gates rewritten. OPEN: a
     balance pass against red-star kits (sim with a maxed kit) before dev200; premium weapons.
  1. LUNA TURRETS ROUND 2 in (29 renders, all usable; art_src/turrets2/, tools/cut_turrets2.gd ->
     turrets/<id>_base / _head / _light / _idle (head stacked on base for tiles), fx/shot_<id>,
     turrets/<id>_head_fire + _fire_light aligned to the resting heads, cards/pic_rook_twin):
     Turrets.TURRETS + ROUND2 repair / tesla / cryo / mines / beacon / flak (two per element,
     "heal" scaled by ATK, REACH keys, parts_needed over all_order so a price can ask for a
     material), battle SPLIT_LOOK entries (negative gap, "lean", "tip"), _fire_k + the fire head
     drawn over the resting head (sentry / split / swarm) and fire_light_<id> on the light layer,
     _update_repair / _tesla / _cryo / _mine_layer (+ mines array, _update_mines, _mine_target) /
     _beacon (e.mark_t, t.mark_id, _beacon_mult on hero bolts, marked bugs always crit) / _flak
     (bullet "fuse" + _burst_at), shells + mines drawn in _draw_fx, tesla arcs + beacon beams in
     _draw_turret_front; afk_wallpaper WALL_SPLIT entries; balance_sim owns its loadout; smoke
     round 2 checks; cards.gd repair_overdrive / tesla_chain / cryo_deep / mines_cluster /
     beacon_dread / flak_shrapnel ("pic" = the turret idle picture) + OVERCHARGE texts, battle
     _pick_card / _overcharge entries (hull_mend, chain, shatter, double_mark -> t.mark_ids,
     embers in _burst_at); tools/dev/card_check.gd (forces each card x3, fights headless).
  dev195 (pushed 2026-11-06) carried the thirteen updates listed below (README-RUDY dev195). Rudy
  13. STORE 2.0 (queue 18) + DEV MODE STAGES: store.gd rewritten: KEY_CHESTS u / e / l (rolls, "ess" =
     the selected planet's weakness essence, "gear" = a copy at that rarity, resolve()), chest_open_in
     (save, tier, "free" | "key" | "crystals") with save "chest_opens" (pity every 10th) and
     "store_free" {chest_u, chest_e, pack_daily/weekly/monthly: unix t}, free_left_s / left_text /
     odds_text / claim_pack_in / free_waiting; tabs Chests | Offers (calendar + PACKS_FREE) | Shop
     (ScrollContainer sections: OFFERS, KEY_DEALS, PART_DEALS, SPECIALTY via _deal_tile / _buy_kind) |
     Crystals (PACKS) | Exchange (teasers); keys = Materials key_u / key_e (stage_drop / horde_drop,
     recipe key_e from 3 key_u); hub _chest_popup / _open_home_chest on the key chests, Home metas
     store_tab 1 = Offers, 0 = Chests; smoke _check_store. DEV MODE: StageData.stage_top(save) (MAX in
     dev) + elite_top MAX in dev; hub / stage_map / modes read DevTools.on before the gates; hub
     elite_unlocked or dev; modes ladder per-rank Fight button in dev. Luna: brief 9 art (chest
     pieces, keys, packs, piles) drops into icons when it lands.
  12. MATERIALS + CRAFT (DESIGN-materials.md built): materials.gd Materials (KINDS 6 essences +
     barrel / lens / coil + rotor / gyro / flightcore, save "materials", icon() mat_<id> else element /
     parts icons, weapon_need / turret_need / drone_need / tier_need, RECIPES + craft(), stage_drop /
     horde_drop); Parts.read merges materials, Parts.write splits, Parts.kind / all_order / add,
     text + pay + crystals_for_missing know materials; Progress.grant "materials" block + top-level
     ids; Heroes ROSTER essences on hollow / nyx / ember, parts_needed over all_order, tier_need,
     can_evolve / evolve(h, id, save); gear _pay_upgrade / _upgrade_text `extra`, weapon / drone /
     track call sites, _on_evolve pays, Workshop tab 3 _refresh_ws_craft / _craft / _craft_el;
     battle _mats_got (end screen iconed rows; patch "parts" keeps only parts); Patrol per_wave
     barrel / rotor / essence; etrial_reward essence; dev wallet; smoke _check_materials. Luna:
     icons/mat_<id>.png later (add to a Luna icons brief). Not built: weapon variants, Store sales.
  11. HERO EVOLUTIONS code side: PilotRig.hero_tier (set_gear), _hero_dir() (heroes/<id>/t<k>/
     when its turn_1 exists, else the base), hero_mode / hero_ring / hero_tex through it (Rook
     joins hero_mode once heroes/rook/t3 exists), draw_hero tier halo (frame x1.06 behind, element
     colour, breathing); gear _hero_portrait prefers portrait_t<k>; cut_heroes _cut_tiers.
     DECISION (2026-11-06): NO per-hero parts rigs: Luna's parts sheets do not match her
     references (Sparks' limbs other angles, Frost a grey clay pass); heroes stay frame-based.
     LUNA-BRIEF-hero-tiers.md REWRITTEN for whole frames (t3_turn_1..8 + portrait_t3, portrait_t2
     only for tier 2); Rudy must send the new one in place of the morning's.
  10. ELITE EASED IN (16g): StageData.elite_mult(wave_index) = ELITE_HP ^ clamp(0.6 + 0.1 w) used by
     battle._hp_mult (hp_mult(stage, false) * elite_mult); sweep before: Elite 25-40 ~half won, every
     loss a hull collapse in waves 4-7 at run level 7-11; after: 25 2/4, 30 3/4, 35 4/4, 40 4/4.
     ICON POLISH: hero panel shard line = UIKit.iconed(ic_shard) (shards first), turret tiles
     corner_icon(role_icon, left=true) (UIKit.corner_icon `left` param), hub _weak_icon after the
     mode tag (tag_row HBox). Unused icons left: ic_mount, st_magnet / st_aim / st_xp, el_any.
  9. LUNA CARDS ROUND 2 in (17 of 18; pic_rook_twin NOT delivered): art_src/cards_r3/,
     tools/cut_cards2.gd (pics keyed like the first set -> cards/pic_<id>.png 256; frame v2 window
     flood-filled with the Common frame's dark -> cards/frame_uncommon.png 300x444; tw_*.png ->
     icons/tw_*.png 96); battle _card_pic prefers cards/pic_<id>.png over the "pic" key (Rook keeps
     the weapon art); Promotion.mod_icon / mods_row / GOOD_COL / BAD_COL; modes.gd ranks ladder +
     etrial steps show icon rows; battle HUD banner draws the icon (preloaded into _tex: a load()
     inside _draw gave a white square) + pause menu rows; _dbg_cards capture hook. Frames are
     stretched to the card, so the v2 frame changes little: the Common frame's thick band is the
     odd one (ask Luna for a tech-style Common frame if Rudy wants them to match).
  8. LUNA STAND ROUND 2 in (orbit rings): art_src/stand/stand_{pool,ring_a,ring_b,beam}-v2.webp,
     tools/cut_stand.gd _cut_v2 (brightness -> alpha with a grey floor 0.2 on the rings, pool x2.2
     under an ellipse mask, beam vertical ramp; prints the rings' ellipses) -> gear/stand_pool /
     stand_ring_a / stand_ring_b / stand_beam.png; gear.gd HeroStand _pool / _ring_a / _ring_b,
     RING_A / RING_B (centre + radii as picture shares), _v2_w (outer ring = r.x*1.1/0.442),
     pool on the normal layer tinted toward the element, _draw_v2_lights (rings pulsing, beads
     orbiting 6 / 4, beam 0.42 k). Old disc code kept as the fallback.
  7. LUNA BACK FRAMES in (20 of 21: Sparks turn_7 she cannot make): art_src/heroes/<id>/turn_6..8,
     art_src/turn/turn_<suit>_6..8; cut_ui_art _body_top / _match_back (back frames scaled to the
     front frames' body height + feet, one median scale per figure), cut_heroes + cut_turn rings
     of 8 (a missing frame is skipped); PilotRig Rig.spin (0..1 round, -1 off), _ring / hero_ring /
     turn_ring / spin_ready / _ring_pick (frame n at (n-1)/8), draw_turn + draw_hero pick from the
     ring, next frame dissolves OVER the current (solid mid-turn); PilotRigView.spin_override
     (face = cos(spin*TAU), Rook spins through draw_turn); gear PilotShowcase swivel wraps -2..2
     when spin_ready, spin = fposmod((1-swivel)*0.25, 1). LUNA-BRIEF-hero-stand-2.md REWRITTEN
     (Rudy: no grid): orbit rings = pool + ring_a + ring_b + beam, -v2 names; code to draw them
     (beads orbiting, pool breathing) when they land.
  6. Hero hover (showcase feet - 162), HeroStand blended (halo + alpha 0.82, x0.98), Luna
     stand-2 brief (no rim, fading edges); gear.gd _weapons_screen (inventory by element, equip,
     details + Upgrade row) opened by the weapon tile, CHOOSE grid + up_row hidden; Rook roster
     portrait = AtlasTexture of pilot_turn/commander_3. NOTE for Rudy: LUNA-PROGRAM.md is OUR
     planning list, never sent to Luna; only LUNA-BRIEF-*.md files go to her.
  5. RUDY'S SCREENSHOT NOTES: one Level up (Heroes DEF_PER 0.008 per LEVEL, old def levels count
     half; gear _def_btn hidden, _on_def_up kept), MILESTONES extended with perks twin_shot (35),
     pierce1 (50), burst2 (60) applied in battle (_perk_twin, pierce_level, burst_count); hero and
     drone panels shortened; UIKit.equipped_badge (E, or the mount number on turrets) replaces
     "Equipped" / "Choose" / "Wearing" / "On mount" words on weapon, drone and turret tiles.
  4. LUNA HERO STAND in (art_src/stand/, tools/cut_stand.gd -> gear/stand_disc / stand_glow /
     stand_beam.png at half size, one crop for disc + glow); gear.gd HeroStand draws them when
     present (glow and beam tinted by the element, pulsing). Back frames: update 7.
  3. LUNA DRONES 2 in (art_src/drones2/<body>/ whole, portrait, hull, wing_l/r or fin_l/r/mid,
     glow; pods/; tools/cut_drones2.gd -> drone/body_<b>, <b>_hull / _thruster_l / _thruster_r /
     _extra / _glow / _portrait, pod_repair / pod_magnet): DroneData BODIES spark / wisp / bat
     (grade, cost, crystals, element, arc / phase / crit flags NOT yet applied in battle), read()
     "owned", is_bought / body_open / unlock / cost_text; battle DRONE_PARTS entries with "flap",
     extra fin, _draw_drone_light glow; gear.gd _on_drone_unlock; body passives in _update_drone
     (bat crit via "lucky", wisp pierce_left 1, spark "weld" arcs + beam _chain).
  2. LUNA ICONS in (art_src/icons2/<name>.webp x48 + alts; tools/cut_icons2.gd -> icons/<name>.png
     96 px): UIKit.ic(name, fallback), ELEMENT_ICON / element_icon, ROLE_ICON / role_icon, iconed(),
     corner_icon(); tabs(.., icons); wallet + hub pills + Parts.icon + store chests / gift / pack /
     key; gear STAT_ICON rows; hero + turret tiles corner element badge; modes card badges.
     Unused so far: ic_shard, ic_weak, ic_mount, role_*, st_magnet / st_aim / st_xp, el_any.
  1. UI kit round 2 in: art_src/ui/ui-*-v2.webp (cutter prefers -v2), UIKit.panel -> panel_glass,
     popup_panel() (popup piece) on the pop-up sites, tile() -> panel_tile tinted + _kit_tile /
     _fill_tile, settings selected row panel_gold, nav_dock.gd draws nav_dock. Not used yet: topbar
     (Home top bar is a shade, dev107), nav_tile.
  dev182 carried the eleven updates listed below (README-RUDY dev182). Rudy
  11. LUNA UI KIT in (art_src/ui/ui-*.webp, 36; tools/cut_ui_kit.gd -> ui/*.png at on-screen SCALE):
     UIKit KIT_ON, kit_ready, nine() (StyleBoxTexture 9-slice, cached), _kit_btn (gold / teal /
     glass / off / tab), chip, header_bar (left margin 56 keeps the tag); battle _draw_hud
     hud_frame + bar_track + bar_fill_red via draw_style_box. Panels / popup / nav_dock / topbar
     NOT used yet (gloss band smears when stretched tall: ask Luna for gloss-in-corners versions).
     DEV MODE: DevTools.on (save "dev_mode", set in Progress.read and the pages' own readers),
     Settings switch; gates: Heroes.owned / gate_open / level_up / def_up / can_evolve,
     Turrets.owned / mount_open / gate_open, DroneData.unlocked, GearData.owned, Energy.try_play,
     Parts.pay, gear _pay_upgrade, Unlocks.open, Promotion.unlocked, modes locked, battle drone
     unlocks. DESIGN-materials.md: materials per domain + Workshop CRAFT tab (not built).
  10. ENEMY VARIANTS (17 a): battle VARIANTS table (armoured 6 / shielded 11 / booster 16 /
     healer 21), _roll_variant in _make_enemy (p 0.06 + 0.006/stage, cap 0.32), _traits(e) feeds
     Turrets.trait_mult (armoured / shielded / support), _through_shield on pilot and turret hits,
     _update_auras (boost_t speed x1.3 + spit sooner, heal 4%/s with green zaps), _draw_variant
     (plates, bubble + shield bar, auras + links + name), first-of-kind banner, worth 150.
  9. HORDE (battle `horde` from selected_mode "horde": _horde_wave(k) cycles the best stage's
     non-boss waves, +15% count per lap, HORDE_HP_PER_WAVE 0.04, boss every 10th, bounty per
     wave, save "best_horde", HUD / end screen; modes.gd card live, shown from Lv.5). Sim auto
     kit buys hero ATK / DEF levels + weapon (balance_sim _auto_kit). Sweep after: see 16g DATA.
  (2026-11-05): do NOT push to Luna for now.
  2. HP INSTEAD OF HEARTS (Rudy): battle pilot_hp / pilot_hp_max / _def / _hp_lost, GOO_DMG 25,
     _hurt_pilot(amount) x (1 - _def), HUD HP bar, star 3 "Take no damage", Aegis +30 HP (heal
     25 a wave overcharged); Heroes BASE_HP 100 x build.tough x (1 + 2%/level) x tier x hp_mult
     (milestone "Max HP +15%", Ember +20%), DEF track (save hero.def, def_level / def_cost /
     def_up, DEF_PER 1.2% capped 50%); Hero page ATK up + DEF up buttons, HP / DEF line; sim
     column "hp lost".
  3. HERO CARDS + DAMAGE NUMBERS: Cards "hero" key (draw(.., hero)), rook_twin / sparks_weld /
     frost_freeze / hollow_phase / nyx_mark / ember_burn with OVERCHARGE texts; battle _twin_every,
     _weld_count / _weld_every, _freeze_level / _shatter, _phase_bonus, _burn_level / _burn_spread
     (e.burn_t / burn_dps, orange glow + embers), _show_dmg / _flush_dmg (DMG_BATCH 0.25 s, crits
     big gold, element colour).
  4. TURRETS + DRONES pass (DESIGN-turrets-drones.md): turrets.gd TURRETS element / role / grade /
     cost / crystals / stage, read() "owned" (migrates by the old pilot-level unlock), owned /
     unlock / cost_text / element_mult, TURRET_TUNE knob; battle mounts by owned, turret damage x
     element, drone damage x the hero element, support pods (DroneData PODS repair / magnet with
     "job" + borrowed "art", battle _update_drone jobs); gear.gd Turrets page element colours,
     role + stars, price + Unlock (_on_turret_unlock), t_owned saved; Drone page element line.
     Later ideas in the design doc (Repair Node, Beacon, Mark pod, Decoy, turret skins).
     Drone element = its BODY's own (DroneData body_element: scout ion, striker solar, warden
     frost; battle _drone_mult on "drone" bullets and the beam; _show_dmg(.., mult)), Rudy: a
     drone you own can cover a planet your heroes cannot. More bodies by grade later.
  5. ELEMENT TRIALS (Rudy): promotion.gd ETRIAL_* (stages 10..50, hp 1.2..1.6, count 1.2,
     shards / coins / crystals), etrial_steps / why_not / owned_hero / reward / waves / hp /
     start_etrial / take_etrial / etrial_won (save "etrials" {el: steps}, selected_mode
     "etrial"); battle `etrial` + _is_trial() (replaces every `promo < 0` check), rewards via
     Progress.grant, HUD + end screen; modes.gd _etrials pop-up (Elements button). ROSTER
     DEPTH rule (Rudy): two heroes / drones / turrets per element over time, different builds.
     TRIAL MODS (Rudy): Promotion.MODS (6 good, 5 bad), RANK_MODS per rank, ETRIAL_MODS per step,
     mods_for / mods_short / mods_lines; battle _mods applied after stats (_bug_speed,
     _spit_mult, no_turrets in the mount loop, thick_shells in _hp_mult), HUD banner 7 s, pause
     lines; ladders show them. Hero cards carry "pic" (weapon art) until Luna paints card art.
  6. LOOK PASS (Rudy's playtest): fonts/exo2_semibold.tres (FontVariation wght 600) as the
     project custom_font + battle hud_font + stage_map; UIKit.label +1 px for sizes <= 13;
     UIKit.draw_bevel on every kit button via _style_btn (lift shadow 6 / 3, gloss, band, top
     line; disabled stays flat); card pick ch 228, refresh lower; Modes promotion row 62/54/94.
     Luna: the Uncommon card frame has no inset (reads taller than Common); ask for one later.
  7. TURRETS bigger + weight + rest / fire poses: TURRET_LOOK swarm 88, SENTRY_BASE_W 70 /
     HEAD_H 78, SPLIT_LOOK x1.2; t.squash on landing (squat in _draw_split_turret / _draw_turret),
     t.alert (any enemy within reach, 4.0 up / 1.4 down) -> lights x(0.35 + 0.65 a), heads 4-5 px
     lower at rest, slower bob, Sentry lift 0.5 + 0.5 a and parks at -PI/2. Battle top bar NOT
     changed (asked Rudy for a sketch).
  1. HEROES replace the six-slot gear (DESIGN-heroes.md, LUNA-BRIEF-heroes.md): heroes.gd Heroes
     (ROSTER x6, ELEMENTS keyed like GearData.SETS, FAMILIES by planet, stats() = the old
     GearData.stats keys from hero level / stars / passive + the weapon slot, read() migrates old
     saves, level_up / evolve / add_shards); battle Heroes.stats, _elem_mult, _bolt_set = element,
     shards on boss / Elite wins (_shards_got); gear.gd Hero page (_paint_roster / _paint_hero /
     _select_hero / _on_level_up / _on_evolve, one Weapon tile, hero milestones text, Workshop
     weapons only); PilotRig.suit_for -> commander for heroes without art, element lights;
     Progress.grant "shards"; Loadouts "hero"; hub pilot block + WEAK TO tag; dev_tools shards;
     smoke _check_heroes. GearData's armour ITEMS / SETS stay (colours, weapons, thrusters, old
     saves). Luna: five hero art sets (parts, weapon, turn frames, portrait) -> art_src/heroes/.
     SECOND PASS the same day (Rudy): heroes are BOUGHT, not stage-unlocked: GRADES 1-5 stars
     (Common .. Mythic, base mult), ROSTER cost {coins + parts} or crystals, optional stage gate,
     "build" {scale, speed, tough}; save "hero" {selected, owned, levels, tiers, shards}; TIERS
     (30 / 90 shards) instead of stars; Hero page = big hero + panel (Unlock / crystals for a
     locked one, _view_id) + grade rows under it; battle _move_mult + rig height by build; afk
     rig height. OPEN (Rudy's ideas, DESIGN-heroes.md): per-hero weapon variants / shooting /
     movement / stance, a unique power card each, ATK + DEF upgrades which need the pilot on HP
     instead of hearts, element-locked Promotion ladders, objective / mission unlocks.
  dev171 carried (README-RUDY dev171):
  1. Elite capped by Standard progress (StageData.elite_top) + Promotion ladder 10/20/25..60 retuned.
  2. FUN PASS part one: unlocks.gd Unlocks (progressive disclosure: UNLOCKS table by stage / level,
     open / fresh / mark_seen / settle, save "seen_new"); UIKit.tabs hidden list + tab_map meta +
     tab_shown; gear _hidden_pages, store Parts tab, quests Repeat tab, modes teaser card, hub
     Patrol dock + _announce_new NEW pop-up, Progress.attention gated. Rudy's fear (2026-11-05):
     "too much to absorb, not enough fun gameplay" -> research in the chat (Vampire Survivors /
     Brotato / Archero loops, staggered unlocks, game feel); plan: hide-not-remove (done), sound
     (done), fight decisions (Spitter telegraph done; reasons to move still open), measure the
     first 10 minutes on a phone (Rudy).
  3. SOUND: sfx.gd Sfx (DEFS synthesized layers -> AudioStreamWAV cache, Pool node under root,
     play / play_rising, gap throttle, res://sfx/<name>.ogg overrides, save "sound_on" via
     apply_from / set_on); hooks in battle (shot, hit, turret, kill, coin, gem, level, shield, hull,
     hurt, wave, boss, win, lose, card_open, card), UIKit.press_fx tap, hub nav tap, gear upgrade /
     merge, store buy / chest, quests claim; Settings sound switch live. No music yet.
  4. Spitter telegraph (battle SPIT_WARN 0.35: Sfx "spit", sac flash, closing ring at the mouth
     in _draw_enemy); capture.gd CAP_AUTOPICK. Headless sims now print "6-8 ObjectDB instances
     leaked" at exit: AudioStreamWAV playbacks the dummy audio driver never finishes; harmless.
- NO per-hero parts rigs (2026-11-06, see update 11); the "NEXT: per-hero PARTS rigs" line below is void.
- 16g note (dev189): Elite eased in over waves 1-5; the stage 30 "cliff" was early-wave hull collapse, not a wall.
- OPEN DECISION (Rudy, 2026-11-05): replace the six-slot gear with unlockable pre-built CHARACTERS
  (each its own stats)? Recommendation given in the chat (heroes as the visible collection with
  evolution looks, keep the weapon slot). Until he decides: no Gear page overhaul, no armour-parts
  Luna brief. Promotion: 10 ranks; Rudy wants each trial themed on a different enemy once the
  enemy families (item 17) exist.
- dev138-182 (Fable session): stages 1-5 free, Luna turret card pictures in, gear rarity +
- dev166 is a DEVELOPER BUILD (build_info.gd DEV = true: Settings > DEVELOPER shortcuts, dev_tools.gd). Set DEV false for a store build. Zip for Luna: git archive without art_src (see README-RUDY dev166).
  copies + Workshop merging + inventory + Quick Merge + loadouts (16 f), polish pass (item 22).
  Dev checks: tools/dev/smoke.gd (run before every build), tools/dev/capture.gd (page shots).
- Done in the last long session (details in README-RUDY.md dev118-dev137 and the queue below):
  six 3D gear sets with tier art, Workshop + merge animation (Luna's layers), gear on the
  pilot (weapon in hand, visor/orb/bolt colours), rookie starter suit + Commander unlock,
  new Store tabs, menu tidy-up, balance pass 21-60 (SIM_KIT=auto), turret tracks
  ATK/Rate/Range + milestones, turret power cards, combat stats (crit, damage boost, base
  reduction, fortress HP) + gear/drone milestones + Gear STATS panel, Home XP ring, Quests Go
  buttons, Modes mystery rewards, Patrol offline farming with limits, power tokens.
- DECIDED (Rudy, 2026-11-04, dev138): Normal stages 1-5 are free of power tokens (Energy.FREE_STAGES);
  Elite always pays.
- HEROES (2026-11-05, Rudy): the six-slot gear is replaced by a roster of unique characters with
  elements (DESIGN-heroes.md; code in heroes.gd; Luna brief LUNA-BRIEF-heroes.md, five art sets
  wanted, Sparks first). Queue items 8 / 8b / 8c (gear slots, sets, gear on the pilot) and 16 f
  (gear rarity) are superseded except for the WEAPON, which stays the one gear slot. Heroes must
  look clearly different from each other, some off-theme for fun (penguin, dragon-kin).
- LUNA ART PROGRAM (Rudy, 2026-11-05): "put her to work": she renders pieces, the code places them.
  LUNA-PROGRAM.md lists ten packages in order. Delivered 2026-11-05: ALL FIVE HERO SETS
  (art_src/heroes/<id>/ reference, parts_sheet, weapon_side, turn_1..5, portrait; alts kept).
  Round 2 DELIVERED the same day (Ember frames + portrait, Hollow 4 + 5, Frost cell 8, Nyx grey
  alts): every hero set is complete; no stand-ins left. gear.gd class HeroStand (code disc +
  Luna's gear/stand_disc / stand_glow / stand_beam.png when present) replaced PlatformFloor.
  SWIVEL: PilotRigView.face_override (-1..1, 2 = off), PilotShowcase _gui_input drag -> swivel,
  drifts back after 4 s, hint; gear _dbg_swivel for captures. Back frames turn_6..8 briefed
  (LUNA-BRIEF-hero-back-frames.md): draw_hero needs an 8-frame ring once they land.
  Sent to Rudy: that redo brief + LUNA-BRIEF-ui-kit.md (9-slice
  buttons / panels / bars / small), LUNA-BRIEF-icons.md (48-cell sheet), LUNA-BRIEF-drones-2.md
  (Spark Bot / Wisp / Night Bat as hull + thrusters + glow, Repair + Magnet pods).
  DONE (update 8): tools/cut_heroes.gd -> heroes/<id>/turn_1..5.png (640 tall, one union crop),
  portrait.png, ref.png, weapon.png, parts/p01..16.png (fallbacks: missing frames mirrored or the
  reference); PilotRig.hero (set in set_gear), hero_mode(), draw_hero (frames by turn_u, lean tilt,
  bounce squash, recoil kick, HERO_SCALE 1.08, HERO_FEET 0.645), hero_muzzle; PilotRigView draws
  hero_mode instead of the rig (no flames / glow layers, a muzzle flash). NEXT: per-hero PARTS
  rigs from heroes/<id>/parts (pivots per hero), then the stand (LUNA-BRIEF-hero-stand.md).
- Luna delivered: turret card pictures (dev138, art_src/cards_r2), animation parts round 1 (dev160-162,
  art_src/parts_r1: drone hull/thrusters, Swarm lid, bug legs/feelers/sac/chunks; Sentry head_nobarrels
  unused, wrong angle), pilot turn frames (dev161, art_src/turn). Still waiting: merge sparks sheet.
- Next in the queue (Rudy picks): item 16 (e) pilot talent map, (g) long-game difficulty re-tune ((f) gear rarity DONE dev139);
  item 17 enemy variants/support enemies/families; item 18 Store 2.0 (key chests with pity);
  items 15, 19, 20 later. Luna briefs: always standalone, exact render names (memory).
- Helpers: tools/dev/ (build bump, contact sheets, crops, captures; see its README).

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
  go UP every package (same signing key, install-over). Current: dev210 (code 210).
  Rudy (2026-11-05, replaces the per-item push): finish an item, COMMIT locally, but do NOT
  push every build. Push every 2-3 finished updates (or at once after a big overhaul, or
  when Rudy asks), and then bump the build by the number of updates since the last push
  (3 updates since dev167 -> dev170). Keep the tally in "Where we are" (UNPUSHED below).
  Each pushed build gets one README-RUDY changelog block listing all its updates.
  Ideas he sends mid-work: fold into the current batch if small, otherwise queue and say so.
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
4. dev107 Rudy playtest: top bar box removed (HomeFrame side 0 = top shade), Chest/Patrol undocked, START removed (Battle tab = Play on Home, NavDock.play_mode, hub _on_nav_tap), nav tile inside the bar (bump_h 4), menus over Frost (frost.gdshader on the frozen AFK; hub _frost), BackButton hidden in hub, UIKit glass restyle, notch: SafeAreaMargin.top_inset + export screen/edge_to_edge=true (battle node shifted by _safe_top, hub view container inset). Menu page LAYOUT overhaul done (dev111, dev124).
4. GLASS LOOK DONE (dev103, from Luna's Home mockups): glass.gd (Glass.panel/box/rounded: fill, sheen, cyan-to-purple edge); home_frame.gd docks (0 top capsule, -1/1 edge tabs, 2 free tile); nav_dock.gd floating glass bar + lit tile (gold on Battle), all tab names shown (hub NAV_NAMES, _paint_nav_label); hub _pilot_block (name + XP bar). Gear Pilot page: PilotShowcase on PlatformFloor (Luna's "classic" design: platform_floor + platform_rim since dev105, set-bonus glow from platform_rim_lights / platform_floor_lights masks recoloured + additive halo, flash() on upgrade; platform.png = single-picture fallback; TEX_W/TEX_FEET place it), slot tiles 3 left / 3 right. Store/Quests/Modes in glass done (dev111); real background blur later if it runs well on phones.
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
16. LONG-GAME PLAN (Rudy, 2026-11-04), in this order ((e) talent map DONE dev197, talents.gd; (g) re-tune pass 1 dev198, see hand-over item 7): (a) DONE dev128 turret tracks ATK/Rate/Range
   Lv.1-20 (Turrets.TRACKS, stats() -> battle t.def, level_of = sum, milestone every 5 = +5% dmg;
   save turrets.tracks; gear.gd _on_track_upgrade, _milestone_toast). (b) DONE dev133: 6 turret cards (Cards "turret" key, draw(mounted),
   battle _turret_mod, flags flak/twin/stun/horizon/boom/frost_light, Sentry "bounce"). Was: Turret power cards, only
   offered when that turret is mounted: some CHANGE what it does, some EXTEND it and grow per
   level (e.g. Sentry bolts bounce to 1, 2, 3 more bugs); Luna card art later. (c) DONE dev130 for gear (GearData.MILESTONE at Lv.5/10 feed
   crit_rate, crit_dmg, dmg_boost, base_dr, fortress; battle _crit_rate/_base_dr; Gear STATS panel
   _show_stats). Drone milestones DONE dev134 (DroneData.MILESTONES Lv.5 rate, Lv.10 dmg). Was: Milestones for
   gear pieces and the drone too. (d) AFK farming per stage: Patrol earns while the game is
   closed (and while open); pick a cleared stage, capped storage. MOSTLY COINS (by stage), plus
   that stage's element (early Alloy, later Cells, then Cores, slowly), plus RARE gear copies for
   merging (Rudy: common weapons/pieces on low stages, better rarities only on high stages, rare
   and spread out). Gear copies need (f). Rewards come PER WAVE CLEARED (Rudy): the Home
   AFK battle plays the chosen stage wave by wave; each cleared wave adds that wave's drops to the
   Patrol store; offline time is counted as simulated waves (waves per hour from that stage's
   length). Farm older stages for their element. DONE dev135 (patrol.gd Patrol: WAVE_S 30, CAP 8 h,
   per_wave(stage), tick/claim/set_stage; hub _patrol_open window); dev136 limits: COIN_RATE 0.4, speed 1/0.5/0.25
   (2 h/6 h/8 h), DAY_CAP 12 h, MAX_COLLECTS 3 a day; gear copies dev139 (per_wave "gear"). (e) PILOT TALENT MAP (Rudy): a path/map of nodes you buy in order,
   each a small permanent % (bolt damage, turret damage, crit rate e.g. +0.5%, crit damage, base
   HP...). Costs rise: coins first, then crystals and a new in-game currency that is harder to
   collect later (e.g. Star Shards from bosses). Every 10th node unlocks a NEW power card for runs
   or a new pilot power. Needs more power cards first. A Gear sub-tab or its own page. (f) DONE dev139: GearData.RARITY caps (10/15/20/25/30), copies {id: {rarity: n}} + recent, merge/quick_merge, roll_drop(stage) by planet (DROP_WEIGHTS), drop_chance (boss/elite 100%, else 35%); battle _gear_got on the end screen; Patrol per_wave "gear"; Progress.grant "gear" list; gear.gd Workshop sub-tabs Parts/Gear (_refresh_ws_gear, _inv_filter, _stack_box, _quick_merge, _filter_box); loadouts.gd Loadouts (3 kits, gear.gd _paint_loadouts). Was: Gear rarity: max level 30, rarity caps the level, raised by
   merging copies in the Workshop (needs gear drops). INVENTORY (Rudy): a filter button (by rarity, slot,
   set, newest) because players collect a lot; a QUICK MERGE button that merges all Common and
   Uncommon copies automatically, while Epic and above are merged by hand only (players keep
   copies they like for their stats). LOADOUTS (Rudy): save named presets (e.g. 3 slots) of the
   equipped gear, turrets on mounts and drone, and switch between them in one tap (Gear page). (g) Re-tune: gentle to 15, then each boss a
   soft wall; target 30-40 hours to stage 60; replays pay half coins.
17. ENEMY VARIETY (Rudy, 2026-11-04): today all 6 planets use the same Hive bugs (scout, drifter,
   spitter, diver, spore) and the ONLY boss is the Hive Mother (mini at x5, big at x10, young one
   mid-stage from 22). Plan: (a) code-only first: enemy tiers / variants (armoured shell, shielded,
   fast, splitting...) using the turret traits that no enemy has yet, and a gradual mix: tier 1
   ROLES, not only attackers (Rudy): support variants that buff bugs NEAR them (health boost,
   attack boost, speed boost, each its own variant with a visible aura linking them), a healer,
   a force-field projector (bubble over neighbours that stops bolts until broken), armoured shells
   (several hits to crack), plus attack variants. Kill the support first = the strategy.
   early in each planet, tier 2 creeping in, a little tier 3 near its end. (b) SCRAP BELT DONE
   dev198 (five machines, the Wrecker, the Salvage Queen, the commander; see hand-over item 5);
   the other planets wait for their Luna sets. Was: A boss and a
   mini-boss per planet, each with its own moves (Luna parts sheets, like the Hive Mother), plus
   each planet's own enemy family (LUNA-BRIEF-areas.md), Scrap Belt first.
   FAMILIES STACK (Rudy): families never leave. Order: 1 Hive insects, 2 Scrap Belt machines,
   3 Magma creatures, 4 Crystal shards, 5 Plasma Storm energy beings, 6 Sentinel AI. A new
   family arrives with its planet in small batches, grows over the next stages, older families
   stay in the mix. Later stages THEME EACH WAVE (e.g. insects, insects+machines, machines, then
   machines+magma...). Waves built from a threat budget so mixing never spikes difficulty. The
   planet boss still announces each new family. Campaign/story mode later tells it family by
   family in one connected world.
18. STORE 2.0 DONE dev189 (update 13; real money still "coming soon"). Was (Rudy, 2026-11-04). Tabs: Chests | Offers | Shop | Crystals | Exchange.
   Chests: Uncommon / Epic / Legendary chests opened with KEYS (keys drop in battle or bought);
   pity: every 10th Uncommon open = an Epic item, every 10th Epic open = a Legendary item;
   one free Uncommon and one free Epic open every 24 h, Legendary only with crystals; a
   chest-opening animation; odds shown. Contents: coins, parts, crystals, later gear copies.
   Offers: daily / weekly / monthly packs, each with 1-2 FREE items (reasons to come back).
   Stage packs: real-money pack unlocked by beating a stage (every 5th stage), better and
   pricier higher up, buyable later. Shop (one scroll page, sections): coins, elements/parts
   (crystals), keys, a Specialty section (high elements, keys, level-up items).
   Crystals: real-money crystal packs at several prices. Exchange: event tokens and other
   collected items traded for chests/items (event shops). Real money needs Google Play Billing
   (until then "coming soon"). Keep the premium currency called Crystals: "gems" are the XP
   pickups in battle.
19. LATER (Rudy): a SKIN LIBRARY for turrets, HEROES and the BASE PLATFORM (2026-11-06; platform skins = Luna strips with the four sockets and the dome spot in the SAME places, STRIP_SOCKETS / STRIP_DOME fractions, e.g. a junk deck, an ice deck, a gold ceremonial deck; unlocked per planet or bought; hero skins are NAMED ICONIC THEMES, never colour labels: "Ceremonial" (the white-and-gold Rook), "The Prophet", a nightfall look, an ironclad look...; each a full look, maybe the cape as its own piece; heroes/<id>/skins/<skin>/turn_1..8 + portrait, worn at any star; Rook ceremonial is the first set): alternate designs / themes per turret (looks only, no
   stats), unlocked or bought (crystals, events, Exchange). Needs Luna art per skin.
20. LATER (Rudy): RANKINGS with weekly rewards: leaderboards (e.g. highest stage, Horde score,
   Boss Rush time) run in 30-DAY SEASONS (Rudy) with a visible countdown ("Ends in 29 days");
   rewards by rank band when the season ends, then everyone starts fresh. Needs a
   server (2.0 online), like codes and events.
21. POWER TOKENS DONE (dev137, Rudy): energy.gd Energy (MAX 60, +1 per 6 min, STAGE_COST 5, ELITE_COST 8,
   PATROL_COST 5, crystal REFILL 30 for 50; save "energy"/"energy_t"). Energy.try_play() gates every
   way into battle (hub nav + SelectGo, modes, stage_map, quests _go, battle Next/Retry); hub
   _energy_btn counter (refreshes every 2 s). Stages 1-5 free in Normal (dev138).
22. POLISH PASS dev140 (Rudy, 2026-11-04: cleaner, modern, cohesive menus; point out what does
   not fit). Done: hub _side_popup glass pop-ups (old tscn panels removed), rail "go" targets
   (Daily -> Quests, Gifts/Starter -> Store via root metas quests_tab / store_tab), Profile card,
   UIKit.wallet / amount / num on Store, Quests, Gear; UIKit.press_fx on every kit button;
   Progress.bump("upgrades" | "turret_upgrades" | "merges") from gear.gd + 3 daily tasks;
   Modes rewards show gear (GearData.best_drop_rarity); battle part pickup textures cached.
   DONE dev141: rail labels on all + Event/Promo hidden ("hidden" in LEFT_RAIL), Store teaser
   tiles (store.gd _teaser). dev157: UIKit.enter / leave / pop_in (page transitions, pause menu). PROPOSED (Rudy picks; README-RUDY dev140 has the plain list): sound
   (none exists), Orbitron on Modes/Stage Map vs the Exo 2 rule, Luna trophy art, quest task icons, hide "x1 Common"
   base stacks in Workshop > Gear (DONE dev152, _inv_filter.show), a Settings page after sound, battle HUD/end-screen visual pass.
23c. IDEAS FROM TAP TITANS 2 + AFK ARENA (2026-11-06): IDEAS-tap-titans-afk.md, ranked: the next
   goal always named on Home, the gain shown on every Level up button, hold to level, a full
   unlock splash with art, prestige as a 2.0 loop, auto-advance after a win, progress bundles.
23b. IDEAS FROM ROGUE DEFENSE + UNDEAD SLAYER (Rudy's recordings, 2026-11-06): IDEAS-rogue-defense.md,
   ranked: stats per source on pause / clear, the boss as half the stage, Chain tags on fusion
   cards, base HP as a number with slow leaks, coin-cost rerolls, the taken-cards row on the HUD.
23. IDEAS FROM SLAYER LEGEND (Rudy's video, 2026-11-04): IDEAS-slayer-legend.md lists what that
   game has, what we already have, and 12 things worth taking, ranked: red dots everywhere,
   attendance calendar, welcome-back missions, repeat quests, daily meta bar, stage drops on
   the map, Breakdown (copies -> parts), rank challenges (with 16 e), timed boosts, dungeon
   entries + difficulty dial (Horde / Boss Rush), collection bonuses (19), chest milestones (18).
   Rudy picks; systems only, never its art or names.
   DONE dev165: repeat quests (Progress.REPEAT / repeat / claim_repeat, Quests tab 4). DONE dev142: red dots (Progress.attention, UIKit.dot / tab_dots, hub _refresh_dots) and the
   attendance calendar (Progress.ATTEND / attend / claim_attend, store.gd Offers).
24. PROMOTION DONE (dev143-144, Rudy's pick from the Slayer Legend video): promotion.gd Promotion
   (RANKS x10 with recommended level, base stage, per-rank "hp" / "count" tuned by the sim in dev144,
   OPEN_EARLY 3, GEM_XP_MULT 1.25, WAVES 10, PER_RANK 0.05,
   waves(i), start/take/won; save "promotion" = ranks beaten, "selected_mode"/"promotion_rank"
   one-shot). battle.gd promo (_load via Promotion.take, _start_stage waves, _hp_mult(), _end_run
   no stars/unlock/suit, end screen PROMOTED!, HUD "TRIAL · NAME"); GearData.stats applies
   Promotion.bonus to damage and fortress; modes.gd card _promotion_row + _ladder; hub rank
   name. Later: Luna rank badges (10), a PROMOTED banner in battle, rank as a talent-map gate.
25. HOME BASE building (Rudy idea, 2026-11-04, SIDELINED to 1.x by agreement): a side screen where
   you build and level buildings (oxygen, water, mine, alliance hall...) on the planet, for looks
   and small perks. Claude's advice: do not add a second economy before 1.0 is polished (gear,
   turrets, drone, cards, parts, kits, ranks, Patrol, missions, trophies, calendar, plus the
   talent map and Store 2.0 already planned = enough decisions). If it comes: make the EXISTING
   base the base (Backdrop base strip): buildings = the dome (super weapons, item 10), the four
   sockets (turrets), a hangar (drone + Patrol), a workshop (merging); each building's look
   levels up from what the player already does (no new currency), with Luna painting the
   building tiers. A separate "build your base" screen with its own costs is the version to avoid.
26. AAA MOTION (Rudy, 2026-11-04: pilot, drone, turrets, enemies must move like a big-budget
   game; renders if needed, else code). Luna: LUNA-BRIEF-animation-parts.md v2 (ROUTE 3 after her note 2026-11-05: separate sprites at true
   size, code places them like the pilot parts; light layers cut in code from the whole pictures).
   CODE (can start before the art, with the pieces we have): (a) a shared Motion helper:
   spring (pos, vel, stiffness, damping), follow-through lag, squash-stretch from velocity;
   (b) pilot: bank into drags, jetpack flame lag, rifle recoil spring (exists), landing /
   lift-off squash, head look-at nearest bug, idle weight shift; (c) drone: bob + bank + lag
   behind the pilot with a spring, roll on fire, thruster flicker; (d) turrets: barrel recoil
   spring, head overshoot when tracking, charge swell on the light layer, lid flip; (e) bugs:
   squash on hit (0.85/1.15 for 0.12 s), stretch when darting, feeler whip, death chunks
   tumbling with gravity + fade, hatching pop; (f) hit-stop 40 ms on boss hits, screen
   shake exists; (g) menus: done dev145 (wallpaper, reveal, sheen). DONE dev147: (e) bug flinch (e.hit_t, HIT_FLINCH_T) + death shards (_spawn_shards / _update_shards / _draw_shards, AtlasTexture cuts of the body). DONE dev148: (c) drone spring (_drone_p / _drone_v, DRONE_K / DRONE_DAMP, _drone_bank). DONE dev149: turrets seated (Backdrop.draw_socket_lip / draw_socket_shadow), UIKit.tile depth; dev150 UIKit.draw_depth / depth / lift on slot squares + Store tiles. DONE dev153: (e) stretch on dart / dive (EnemyRig.draw_bug stretch + stretch_ang, e.stretch_s), (d) turret head overshoot (_spring_ang). DONE dev154: light layers (tools/cut_turret_light.gd, battle _draw_turret_lights, _split_pose). DONE dev155: (b) pilot lean spring (Rig.lean_vel), flare (Rig.flare), squash (Rig.bounce), weight shift, flames trail the lean. DONE dev156: bug hit flash (draw_bug bright), pilot hurt edge (_draw_hurt_edge). dev157 menu transitions (UIKit.enter/leave/pop_in). dev158 pilot turn: head leads (_head_face, side_head_weight / front_head_weight), gun lowers (solve turn), front pose mirrored past the middle, squeeze 0.6, face speed 3.2; tools/dev/turn_capture.gd. LUNA: LUNA-BRIEF-pilot-turn.md (5 whole-body turn frames per suit) -> code cross-fades through them. LUNA PARTS R1 ARRIVED 2026-11-05 (art_src/parts_r1, tools/cut_parts_r1.gd): dev160 chunks (shards) + drone hull/thrusters (DRONE_PARTS). dev161: bug legs / feelers / sac (EnemyRig.LEGS, FEELERS, draw_bug sac), Luna turn frames (art_src/turn, tools/cut_turn.gd, pilot_turn/, PilotRig.draw_turn / turn_weight, TURN_SCALE / TURN_FEET measured). dev162: Swarm lid flip (t.lid, _draw_turret lidded). dev163: bosses untouchable until arrived (battle _can_hurt, e.arrived). NEXT: Sentry head_nobarrels is a different angle (kept, not used); tune LEGS on a phone. (f) hit-stop + shake already exist in battle._process (hitstop, shake). Then LUNA-BRIEF-animation.md
   (older in-between list) is mostly superseded by the parts approach.
16g DATA (dev172 sweep, hero kit: Normal 1-60 all won, hp lost 0, hull 100, pilot dmg share
   68-78% late (turrets ~25-30%); Elite 10 won, 20 half, 30 lost (hull 0 by wave 4-5), 40 half,
   50-60 won: a cliff at stage 30 only; trials with the hero kit: Cadet / Pilot / Ace / Meteor
   3 of 3, Comet 0 of 3 (Turrets down at stage 55 was a wall) -> ranks +0.15 hp, no_turrets moved
   to Cadet only (stage 15); after: Cadet 1.3 + no turrets (1.45 was 1 of 4), Pilot 1.45, Ace 1.65, Comet 1.6,
   Meteor 1.7, later +0.05 steps to 1.95: sim Cadet ~half, Pilot 2 of 3, Ace-Meteor won with HP
   lost and hull down to 66-84 (threatened). The bot dodges every goo, so Normal "never
   threatened" is partly the bot. OLDER
   (dev145 sweep, SIM_KIT=auto human): Normal 1-60 never threatened; Elite 30+ unwinnable. dev164: StageData HP_A / HP_B / ELITE_HP knobs (SIM_HP_A, SIM_HP_B, SIM_ELITE) for the sim; experiments 2026-11-05: hp 1.065/1.03 + Elite 1.45 = cliff at 40+ and Elite still lost; hp 1.055/1.025 + Elite 1.35 = Elite 30-60 still 0 wins (+5 kit). Not applied; the autopilot may be the weak link (pilot dmg share 50-60%). Rudy playtests dev166 first.
32. AUTO + SPEED BUTTONS (Rudy idea, 2026-11-07, not scheduled; my view given in the chat): two small
   battle buttons at the bottom right, AUTO above, SPEED (x1 / x1.5 / x2) below. MANUAL (Auto off): drag =
   move + shoot; finger lifted = he keeps shooting STRAIGHT UP (my advice, not "no shooting"), no auto-aim:
   this finally gives a reason to move (fun-pass item "reasons to move"). AUTO on: a full autopilot that
   flies around, dodges and aims (brain = balance_sim "human" bot: 0.25 s reaction, misses ~1 dodge in 3,
   so a good player beats it); dragging takes over, letting go hands back to Auto; the choice is saved.
   Today battle.gd idle_fire_ratio 1.0 + idle aim = lifted finger auto-aims as strong as dragging.
   SPEED = time scale for the fight only (card picks / pause at x1); unlocks by stage (e.g. x1.5 from 5,
   x2 from 15) or later a pass. Mock-up the two buttons with the style pass; mind the 4th socket and
   left-handed players (mirror option). Rebalance after (manual aim drops in strength).
31. STYLE PASS research (Rudy, 2026-11-07): Desktop/menu ideas (10 images) + an article on modern mobile
   menus. TAKE: one dominant action per screen (gold), secondary smaller; bold rounded readable font
   with hierarchy; FLAT panels (no gloss / no dark lip) with a solid header strip; square item tiles
   with the price under (purple flat kit); active nav tab that RISES out of the bar (Kingdom map hub);
   dark navy + one accent (cyan) + gold, cut-corner sci-fi shapes (Commander phones); hero big on a
   podium with a slim stat panel at the side (shooter collage); rounded cards, pill badges, generous
   spacing (purple social app); micro-interactions (press bounce, count-ups, pop-ins); frosted glass
   kept but flat. SKIP: kids/fantasy ornate wood/gold frames, AI-generated glossy phones. MOCK-UP DONE
   (2026-11-07): claude.ai/artifact/8n6AMuMVhhrpAqGyP1kswD (Design canvas; source in the session
   scratchpad): Store + Home each in A Command Deck (Oxanium, cut corners), B Arcade Pop (Baloo 2,
   rounded rarity-filled cards; my pick), C Frosted Glass (Outfit); Home = live battle, next-goal line,
   stage card with first-clear reward + fire icon (no WEAK TO text), gold PLAY raised in the nav centre
   (base platform removed at Rudy's ask). Rudy STILL DECIDING (2026-11-09).
   FROM RUDY'S CHATGPT/CODEX PAGES (Documents/Codex/2026-11-07/.../outputs: home.html, index.html,
   skybound-ui-system.html), "take what we like": TAKE one shared frame (same top bar + nav on every
   page; button ranks gold main / cyan second / dark third), Modes = one full-width card per mode with
   one entry button, Quests = task cards (progress bar + reward + Go; Claim turns gold), Heroes = big
   hero on the stand + one upgrade card + roster + sub-tabs Hero / Turrets / Drones / Gear, Store = a
   7-day gift strip on top, first-clear reward on the Home stage card, page content fades + lifts in
   ~200 ms while the backdrop stays. SKIP its 8-10 px text, emoji icons, glow edges, gradient fills,
   filler lines ("Outpost secure", "Fleet 3/3"), the static Home (keep the live battle), long Store
   rows (Rudy likes big squares), WEAK TO text. (Its Play page has the planet over the stage name.)
   NEXT: Rudy picks a style; then fonts into fonts/ (OFL) and the page-by-page pass.
30. 3D TEST (Rudy, 2026-11-07): heroes and turrets read as flat pictures (swivel cross-fades, the
   Lance rotates a side-view picture). DECIDED: option 3 first = Luna makes 3D models from her
   renders with an image-to-3D tool (Meshy / Tripo), Claude PHOTOGRAPHS them in Godot at many
   angles (one lighting, frames that line up, turret heads one frame per aim angle), game stays
   2D. Test with ONE hero (Rook) and ONE turret (Lance, base + head as two models); if Rudy likes
   it, all turrets then heroes; if not, option 2 = live 3D models. Brief: LUNA-BRIEF-3d-test.md
   (zip on the Desktop with 1_rook_front / 2_rook_back / 3_lance_base / 4_lance_head PNGs).
   ALSO DECIDED: hero ladder ASCEND: rarity = the step (Common .. Legendary, Mythic = red),
   every hero can reach the top, a rarer hero starts higher, each step unlocks a hero power-up
   (build after batch 1 with the Hero page cleanup + Level Up screen).
29. RUDY PLAYTEST dev209 (2026-11-07, phone; screenshots to come; "step by step"). His notes:
   GAMEPLAY: status effects must SHOW on bugs (ice: bluish, frost building up, slow -> freeze
   at high levels; fire: burning, spreads bug to bug on touch later, burning ground patches);
   boss needs MORE health layers (Hive Mother went down at once, kit was strong); cards come
   too fast (lower gem XP so picks are rarer and worth more); weapon bolts + their animation
   need a rework (the hero bolt that looks like a DNA strand); XP gems: no ring, a small
   glitter, never confusable with enemy shots; the end-of-wave vacuum of coins / gems is
   pointless: fly away only at the end of a STAGE, not every wave (check what counts);
   Lance laser does not line up (fires from a random spot, not the tip) and its base vanishes
   while turning: turrets "throw him off", wants ideas; Stage Cleared box went off-screen once.
   TURRETS may stay ATTACHED to their base (no floating heads) if it reads better (Rudy).
   POWER CARDS: text spills out of the boxes; say only what THIS pick does ("2 extra bolts per
   burst"), no "then 3, then 4", no next-level text; chain text maybe too much; bigger icons.
   PAUSE: drop "leaving ends this run" text and the damage list; Back to Hub asks "Are you
   sure? The stage restarts"; damage by source on the END screen only (ranked).
   LOOK (overall): font too thin/crumpled (wants bold, fun); icons too small with too much text
   under them; buttons have a black bar under them, text not centred, gold button weak; BIG
   SQUARE cards (like Store's stage pack / season pass) wanted across the game instead of long
   bars; menus feel "2000s": consider leaving the 3D/bevel look for a polished, smooth, animated
   modern style (research modern games, propose). Battle top bar squished, card row / x1 /
   pause touching edges.
   PAGES: Patrol window: no stage arrows, just Patrol (collect what built up) + maybe an auto
   patrol that feeds on power tokens; collect button has the black bar, text off-centre, plain
   ("written in Word"). Store: seamless tab bar (one strip, not separate bubbles), bigger icons,
   less text, chest opening needs a real animation that shows the item won, blue buttons too.
   Top bar: Power / coins / crystals look typed-in; power icon looks like a coin (drop the
   hexagon). Nav bar: the active tab's blue square overlay looks pasted on, not part of the bar.
   HERO PAGE: replace "KIT + SAVE" with one Loadout button (Loadout 1/2/3); hero lower so he
   stands on the platform (head behind TALENTS now); drop "Suit: Commander" (name elsewhere or
   just the name); TALENTS + STATS to the right, stacked; rethink the weapon button (line points
   to the weapon, button elsewhere); the swivel shows cross-fading frames (not 3D-looking);
   too much info: show name, grade, element, ATK, level + a LEVEL UP button opening its own
   screen (hero big, what you get, what it costs, animated level-up). RARITY QUESTION: heroes
   locked to a grade make Commons useless; he suggests merging hero cards / shards to raise a
   hero's rarity so any hero can become Legendary; wants my view. Star map: idea perfect, look
   plain (straight lines), needs oomph; reward text only when tapped. Stats panel lines squished.
   Modes cards wider than the screen. Quests: look not working. Home "STANDARD 1 · HIVE WORLD ·
   WEAK TO FIRE": no plain weakness text; an ELEMENT WHEEL (circle of element icons, arrows for
   who beats whom) under Heroes instead. Menu > Stage Map should not be there: the stage map
   becomes the CAMPAIGN mode (story, Candy Crush trail).
   VARIANTS: the grey ring round some bugs (= ARMOURED, battle _draw_variant draw_arc) reads as
   nothing; needs a major rework (all four variants: show it ON the bug, not a ring round it).
   FROM HIS SCREENSHOTS (checked in code): (1) OFF-SCREEN boxes = one-line texts / rows wider than
   480: Stage Cleared "grow" HBox (gear + shards + every material in one row, battle ~3555),
   Modes _promotion_row (rank text + Elements + Ranks + Challenge), Store tabs (5 with icons) and
   Offers pack lines, the Store wallet cut at the right. (2) HUD title STALE after Next stage:
   _hud_title_key = -1 outside horde, never rebuilt (stage 5 showed "1 EMBER REACH"; pause
   showed the real stage). (3) Two-line buttons clip line 2 ("Level up / 90 coins", "Chart star 1
   / 330 coins", Quests "Go" sits low). (4) "Black bar" = the button 3D lip (Luna kit art +
   draw_bevel bottom shade + lift shadow 6/3). (5) DNA bolt = bolt_twin (Burst Fire), pill bolts =
   bolt_heavy. (6) Gems sit in grey rings (dev108 outline). (7) Star map: Luna's skies and ghost
   figures barely visible; The Rifle reads as a straight diagonal. (8) Stats icons repeat (one
   bolt icon for hit and DPS, one shield for three rows). (9) Card pick: text spills past frames,
   Common frame differs (thick grey). (10) Power icon = gold hexagon like the coin.
28. RUDY PLAYTEST dev166 (2026-11-05, phone, old save with Commander suit). His notes, in his order:
   - A Patrol tip pops the moment the game opens: bad first impression. Tip boxes are huge for
     one or two sentences; in Modes the spotlight sat on a random area. VERDICT: tips OFF (keep the
     code; redo later only for new elements like gear, not basics). DONE dev167 (Tips.ENABLED).
   - Everything is on the small side: fonts, lettering, pictures; text is thin. Wants bolder /
     bigger, maybe another font. (global font weight/size pass, with screenshots)
   - Power-card pick: the blue outline is not centred on the cards, cuts them off; font too thin.
   - Buttons and info boxes are flat (pause, menu, gear icons, upgrade buttons): wants 3D, layered,
     shadows, popping (UIKit._style_btn gradient + bevel + shadow; boxes layered).
   - Standard vs Elite on Home look identical: Elite needs a purple hue / changed background and a
     border around the stage name. (dev167: Elite tints the Home world + stage name frame)
   - Pilot: movement must be perfectly smooth when dragging (check on phone).
   - GEAR PAGE overhaul: the showcase pilot looks like a SKELETON (not the chunky chibi body);
     writing too small, too much info (3-5 lines to understand an upgrade), buttons flat; KIT row
     disliked: wants a LOADOUTS button at the side that cycles Loadout 1/2/3 and saves what is
     equipped; the equipment grid at the bottom is jumbled ("ugh"); merge maybe a button inside
     the equipment area leading to a merge screen (auto / manual). Rudy wants ideas.
   - EQUIPPED GEAR DOES NOT SHOW on the pilot (Gear page nor battle): weapon, chest, boots... and
     Arc Welder gives no green bolts. (regression or Android texture issue: needs screenshots)
   - Menu backgrounds: a bit more alive: sparkling stars, a shooting star, asteroids. (dev167)
   - TURRETS page: nothing shows, no placeholders, no turret pictures. Drone page: overhaul too.
   - Promotion Cadet was easy: must be very hard but worth it; recommended level min 10 for the
     first trial, rising. (dev168: recommended 10, 20, 25 ... 60; base stage from the level sweep
     (Lv.10 ~ stage 15, Lv.20 ~ 30, Lv.25 ~ 40, Lv.30 ~ 55, Lv.33+ ~ 60); OPEN_EARLY 7; hp 1.3-1.8
     tuned by sim: a cliff, the stage kit wins about half, a kit 12 stages under almost never.)
   - Elite must be its own ladder: unlock at level 10, start at Elite stage 1, each Elite stage
     needs the previous Elite stage beaten. (dev167: save "elite_unlocked"; dev168: never past the
     Standard stage you have cleared, StageData.elite_top)
   - Turrets: bigger, with weight; cock back and shoot, lasers spread, pillars move; a resting
     pose when nothing is in range and a firing pose when a bug is; he may change some powers.
   - Battle top bar: spacing off, wasted space; keep simple. Pause menu: too much; drop YOUR CARDS
     (the cards button on the HUD exists). (dev167: cards row removed from pause)
   - Home chest icon opens "stage info" (wrong); the chest closes itself after seconds: keep it
     open while its overlay shows. (dev167: Chest = a chest overlay, open while shown)
   Screenshots coming from Rudy; the visual overhauls wait for them.
27. PERFORMANCE MODES + SETTINGS PAGE DONE dev159 (perf.gd Perf: saver/balanced/full, apply_from at hub start, lite() read by MenuBackdrop, UIKit.sheen, battle shards; settings.gd/tscn from the Home menu pop-up; build_info.gd BUildInfo.BUILD bumped by bump_build.sh; show_fps in the battle HUD). Was: Facts: draws at native phone
   resolution (stretch canvas_items/expand from 480 wide), no FPS cap + vsync = screen refresh
   (60/90/120), GL Compatibility, ETC2/ASTC. dev146 switched the frost blur off (covered by
   MenuBackdrop). TO BUILD: settings.gd page (Menu button on Home): Performance = Battery saver
   (Engine.max_fps 30, OS.low_processor_usage_mode in menus, MenuBackdrop static + half the
   motes/stars, no UIKit.sheen, fewer battle particles) | Balanced (60) | Full throttle (0 = uncapped);
   save "perf"; apply at startup (hub _ready) and when changed. Sound toggles when sound exists.
   Efficiency pass still to do (Rudy: lighter, never uglier): profile battle _draw on a phone,
   cache per-frame string formatting in the HUD, pool _fx dicts, cap enemy_bullets draw calls.
15. GUIDED FIRST-TIME TIPS DONE dev163 (tips.gd Tips.TIPS / first / show, Layer overlay; hooks: hub _home_tips, gear _page_tips, modes _tips, store _tips, battle _open_cards, settings reset). Was (Rudy idea, queued 2026-11-04; reminded 2026-11-05: "a lot was added"):
   when something unlocks or is used the first time, a short guided tip. LIST (dev147): first
   gear upgrade, first turret mount, Workshop (parts merge), Workshop > Gear (copies, Quick Merge,
   rarity caps), KIT row (loadouts), drone unlock, Patrol (farming + gear copies), Promotion
   (rank trials, recommended level), attendance calendar, red dots, Elite unlock, Stage Map,
   each new planet / enemy family, power cards (first pick), turret cards, suits. Format: dim the screen,
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
