# Skybound Defender: handoff for Claude Code

Read this first. It replaces the chat history this project grew up in. The long-term
plan (1.0 / 1.x / 2.0) is in ROADMAP.md.

## Where we are (hand-over, 2026-11-05, build dev171)
A new session picks up here. Everything is committed and pushed (github.com/Majiiboo/Skyward-Defender).
- UNPUSHED since dev171: 6 updates (next push = dev171 + that count; see the build rule). Rudy
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
- OPEN DECISION (Rudy, 2026-11-05): replace the six-slot gear with unlockable pre-built CHARACTERS
  (each its own stats)? Recommendation given in the chat (heroes as the visible collection with
  evolution looks, keep the weapon slot). Until he decides: no Gear page overhaul, no armour-parts
  Luna brief. Promotion: 10 ranks; Rudy wants each trial themed on a different enemy once the
  enemy families (item 17) exist.
- dev138-171 (Fable session): stages 1-5 free, Luna turret card pictures in, gear rarity +
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
  go UP every package (same signing key, install-over). Current: dev171 (code 171).
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
16. LONG-GAME PLAN (Rudy, 2026-11-04), in this order: (a) DONE dev128 turret tracks ATK/Rate/Range
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
   early in each planet, tier 2 creeping in, a little tier 3 near its end. (b) A boss and a
   mini-boss per planet, each with its own moves (Luna parts sheets, like the Hive Mother), plus
   each planet's own enemy family (LUNA-BRIEF-areas.md), Scrap Belt first.
   FAMILIES STACK (Rudy): families never leave. Order: 1 Hive insects, 2 Scrap Belt machines,
   3 Magma creatures, 4 Crystal shards, 5 Plasma Storm energy beings, 6 Sentinel AI. A new
   family arrives with its planet in small batches, grows over the next stages, older families
   stay in the mix. Later stages THEME EACH WAVE (e.g. insects, insects+machines, machines, then
   machines+magma...). Waves built from a threat budget so mixing never spikes difficulty. The
   planet boss still announces each new family. Campaign/story mode later tells it family by
   family in one connected world.
18. STORE 2.0 (Rudy, 2026-11-04). Tabs: Chests | Offers | Shop | Crystals | Exchange.
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
19. LATER (Rudy): a turret SKIN LIBRARY: alternate designs / themes per turret (looks only, no
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
16g DATA (dev145 sweep, SIM_KIT=auto human): Normal 1-60 never threatened; Elite 30+ unwinnable. dev164: StageData HP_A / HP_B / ELITE_HP knobs (SIM_HP_A, SIM_HP_B, SIM_ELITE) for the sim; experiments 2026-11-05: hp 1.065/1.03 + Elite 1.45 = cliff at 40+ and Elite still lost; hp 1.055/1.025 + Elite 1.35 = Elite 30-60 still 0 wins (+5 kit). Not applied; the autopilot may be the weak link (pilot dmg share 50-60%). Rudy playtests dev166 first.
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
