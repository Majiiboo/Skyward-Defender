# Skybound Defender — source package for Rudy

This is the full Godot project for the game you have been playtesting.
Build 1.0-dev143 (version/code=143 and version/name="1.0-dev143" in export_presets.cfg). The phone installs over an existing app only if the version code is HIGHER than the installed one and the APK is signed with the same key. Each pushed update now raises the build by one.
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

## v3: new Home screen (changed in this package)

- The Home screen was rebuilt with a simpler, cleaner layout: small glass
  icon buttons, a slim BATTLE pill, a profile badge and currency pills on top,
  galactic stage names with a Standard / Elite toggle.
- The background is now a live, untouchable fake battle (afk_wallpaper.gd): a calm
  swaying soldier, planet horizon with skyline, shield arc, two base turrets
  (SHOW_TURRETS at the top of the file turns them off), waves of enemies,
  asteroids and a passing ship. It pauses and hides when you open a menu screen.
- The Home buttons are built in code from tables at the top of hub.gd
  (LEFT_RAIL, RIGHT_RAIL, STAGE_NAMES, LABELED). To change a stage name, add a
  side button, or choose which buttons show a small text label, edit those tables.
- Elite is locked until level 10 (elite_unlocked in hub.gd).
- Removed: afk_draw.gd (replaced by afk_wallpaper.gd) and four unused icons.

## v6: weapons table and more human auto-aim (battle.gd)

- WEAPONS (top of battle.gd): every gun is one entry (fire rate, speed, damage,
  shots per pull, spread, hit size). The current gun is "laser_pistol", with the
  same fire rate and speed as before. Dual mini lasers, a cannon, or special
  weapons later = new entries plus a few lines in _fire().
- Auto-aim feel (the aim_* variables right under WEAPONS): turn speed, wobble,
  lead accuracy, how sticky targeting is, and whether he stops shooting enemies
  that are already doomed. Change those numbers to make him sharper or sloppier.
- Dragging works exactly as before: move by dragging, fires straight up.
- stat_shots / stat_hits are hidden debug counters used for tuning.

## v7 (dev59): Luna's painted pilot is in the game

- pilot/ holds the four poses (idle, aim_up, lean_left, lean_right) and rifle.png.
- battle.gd picks the pose: finger down = aim_up, moving sideways = lean, otherwise
  idle. Thruster flames (centre rocket, side pushes) and the muzzle flash are
  drawn in code on top, so they can be restyled or made customisable later.
- PILOT_HEIGHT (top of battle.gd) sets his size on screen; it is 60.
- dev60: bullets start at the rifle tip of the current pose; the thrusters are
  anchored per pose (the rocket/muzzle/shoulder points in POSES) and drawn behind
  him; the aim-up pose mirrors when you drag right, so the rifle switches sides.
- The Home wallpaper and the Gear screen use pilot/idle.png.
- Removed: soldier_body.png, body_base.png and the parts/ folder (about 4 MB).

## v9 (dev61): page-by-page pass

- Home: the top bar (profile + coins + crystals) is one dock attached to the left
  edge, the menu button a dock on the right, Chest and Patrol docks at the bottom
  edges, with thin edge lines flowing into the nav bar (home_frame.gd). The
  wallpaper's city, planet, shield and turrets now come from backdrop.gd, which
  the battle uses too, so both screens are the same world.
- Gear, Modes, Store, Quests were rebuilt in code with a shared kit (ui_kit.gd):
  glass panels, cyan headers, gold = main action, teal = secondary, rarity colours
  on item tiles. Gear: pilot left, six slots right, Upgrade + detail, tabbed bag;
  equipping is saved in the save file under "gear". Modes: one card per mode with
  unlock levels. Store/Quests: tabs and tiles/rows, still show-only.
- Battle: same sky/planet/city/shield as Home, two decorative base turrets that
  track enemies, bug-shaped enemies, boss health bar, bursts and rings on hits,
  floating "+100" on kills, a drawn HUD (stage + timer, score, kills, hearts,
  base shield/hull bar). The old never-expiring particles were removed (they
  leaked memory).
- menu_style.gd is no longer used by any screen (kept for now).
- dev62: pilot_sprite.gd holds the poses and draws him for both battle and Home
  (gun tracks targets, thrusters anchored); backdrop.gd has the base dome and
  cleaner turrets; Home top bar is one continuous bar, docks tighter, edge lines gone.
- dev63: base moved to the bottom (BASE_Y), hex force-field dome around it whose
  outer arc shrinks with the shield and inner arc with the hull (draw_force_field
  in backdrop.gd; DOME_R in battle.gd), hover flame from the jetpack nozzle, XP bar
  and run level in the HUD (kills give 1 XP until gems arrive), pause button.
- dev64: top bar mirrors the nav bar (one outline curving into the edges); Chest and
  Patrol are chamfered edge tabs above the base; the force field is a wide dome
  from edge to edge (DOME_RX/DOME_RY in battle.gd); the hover flame sits between
  the legs and grows when he climbs, shrinks when he drops.
- dev65: Luna's thruster sheet is in (pilot/); the flame is anchored to the painted
  nozzle. Five propulsion styles (THRUSTERS in pilot_sprite.gd: flame, plasma,
  pressure, gravity, pixel), picked on the Gear screen's Thrusters tab and saved
  under "thruster". Add a style = one table entry + one branch in draw_thruster.
- dev66: Luna's centre-thruster sheet; the main thruster is anchored to the single
  nozzle between the legs in every pose, the shoulder pods fire when moving sideways.
  The Home wallpaper no longer draws the force field or any bars.
- dev67: the battle field now follows the real screen height (FIELD_H / BASE_Y are
  variables), so the base sits at the bottom edge on tall phones and the force
  field (DOME_RX/RY) covers the whole base. Home: tighter Chest/Patrol tabs, top
  bar raised (safe-area floor 4 px).
- dev68: Luna's painted icon set (icons/*.png; icons.gd loads PNG first, SVG as
  fallback). Inactive tabs are dimmed in code (NAV_DIM). Each tab plays its own
  activation effect (_icon_fx in hub.gd + icon_fx.gd): visor flash, rifle clash,
  crate beam, planet spin, checkmark stamp.
- dev71: Exo 2 is the game font (project.godot gui/theme/custom_font, battle HUD
  loads the same file); Orbitron is used only for the stage name on Home, the stage
  pill and BOSS/LEVEL banners in battle. Both in fonts/ under the Open Font License
  with licence texts included. To try another font, swap the .ttf and that one line.

## dev75: the gameplay slice (big one)

- battle.gd was rewritten around data files:
  - stage_data.gd: SECTORS (a planet every 5 stages with its sky colours and
    stage names), ENEMIES (scout, drifter, spitter, diver, hive_mother with HP,
    speed, movement, XP tier, coins, traits), scaling per stage, and waves(stage).
  - cards.gd: the 8 power cards, rarities (common 60 / uncommon 28 / epic 10 /
    legendary 2 percent), max levels, and the weighted draw.
- Enemies use Luna's painted sprites (enemies/). Spitters hover and fire, Divers
  dive at the pilot, the Hive Mother hovers at the top and lays Scouts (her sacs
  take double damage while she lays). She is the last wave of every 5th stage.
- XP gems drop on kills (tier by enemy), drift toward the pilot, are pulled in
  within the magnet radius, and fill the run level. Each level opens the card
  pick: 3 cards in Luna's frames (cards/), one free refresh per run. After level
  12 each level costs double.
- Deploy Sentry mounts a Sentry turret (turrets/sentry_*.png) on one of four
  mount points; it tracks and fires on its own. The other five turret pairs are
  in turrets/ ready for the turret system.
- The shield regenerates after 4 s without a hit; the pilot gets 1 s of
  invulnerability after a hit. Stage clear and Base lost screens; coins, pilot XP,
  best score and the next stage unlock are saved. Home reads the save: stage
  arrows only go up to the unlocked stage, Elite unlocks at pilot level 10,
  START plays the selected stage.
- Cleaner look: thin single lines on the top bar, nav bar and docks, no glow,
  side buttons without circles.
- Known: balance is a first pass (stage 1 is quick), no sound, turrets other
  than Sentry are art only, drone and trails not started.

## dev143: Promotion (rank trials)

- A new PROMOTION card on the Modes page: ten pilot ranks, each with its own trial. A trial
  is one hard stage of 10 waves built from a boss stage's waves (Cadet = stage 5, Pilot = 10,
  Ace = 15, Comet = 20, Meteor = 25, Nova = 30, Pulsar = 35, Quasar = 40, Supernova = 50,
  Singularity = 60): bugs x2.2 tougher than that stage (Elite is x1.85), 30% more of them,
  and the boss at the end. Each trial opens at a pilot level (3, 6, 10, 14, 18, 22, 26, 30,
  35, 40). It costs normal power tokens and can be retried.
- Win a trial once and you are PROMOTED for good: every rank gives +5% bolt damage and +5%
  base shield and hull, stacking (Singularity = +50% each), plus 250 pilot XP the first
  time. The end screen says PROMOTED! with your new rank and what it gives; a lost trial
  says TRIAL FAILED and reminds you how tough it is. Trials never unlock stages, give stars
  or the Commander suit; coins, parts and a gear copy drop as usual.
- The card shows your rank and bonus, the next trial (or the pilot level it needs), a Ranks
  button with the whole ladder (won ranks gold and ticked, the next one lit), and Challenge.
- Home shows your rank name instead of "Pilot" under the profile ring (Rookie before the
  first trial); the profile card lists rank and bonus. The Gear STATS panel includes the
  rank bonus since it goes through the same gear stats.
- Modes cards are a little shorter so all five fit on one screen.
- Dev: tools/dev/save_trial.json starts battle in the Ace trial for captures.

## dev142: red dots everywhere and the attendance calendar (from the Slayer Legend notes)

- RED DOTS: one rule in the code (Progress.attention) decides where a red dot shows, and
  every dot follows it: the Store, Gear and Quests tabs on the bottom bar; the Daily, Gifts
  and Patrol buttons on Home; the Daily / Career / Trophies tabs in Quests; the Offers tab
  in the Store; the Workshop tab in Gear and its Parts / Gear sub-tabs. A dot means
  "something to claim or do here now": a finished task, today's gift, a merge you can make,
  Patrol ready to collect. They refresh every 2 seconds on Home and after every claim.
- DAILY GIFT is now a 7-day ATTENDANCE CALENDAR on Store > Offers: seven cells across the
  top, today's lit, claimed ones ticked, day 7 in gold. One claim a day; the day advances
  each claim and the week starts again after day 7. Missing a day does NOT reset the week
  (kind on purpose). Gifts: 100 coins, 150 coins, 5 crystals, 200 coins + 3 Alloy,
  10 crystals, 300 coins + 1 Plasma Cell, then 500 coins + 25 crystals on day 7.
  A save that already took today's old gift counts as claimed today.

## dev141: Home rail and Store teasers (Rudy's picks from the dev140 list)

- Home: the Event and Promo buttons are hidden until events and deals exist (their table
  entries stay in hub.gd with "hidden": true; remove the flag to bring one back). The four
  side buttons that remain (Starter, Daily, Gifts, Ranks) all have labels now, like Chest
  and Patrol, so the rail reads as one set.
- Store: pages are no longer half empty. Offers has a "Weekly Pack · coming soon" tile next
  to the Speed Pack; Chests has "Key Chest" (opened with keys from battle) and "Gear Chest"
  (gear copies, Epic every 10th) tiles. Teasers are dimmed with a COMING SOON chip and no
  price, so nobody mistakes them for something to buy. They become real with Store 2.0.
- Dev: tools/dev/capture.gd takes CAP_META (e.g. store_tab=1) to open a page on a tab.

## dev140: polish pass (menus, notes, code)

Rudy asked for a page-by-page look at the whole game. What changed:
- Home: every pop-up (Profile, Coins, Crystals, Power, Menu, Chest stage info, Event, Promo,
  Ranks) is now a glass card in the menus' style, with a tap-outside-to-close dim, instead of
  the old grey engine panels. The four old panels (and a leftover show-only Patrol panel) were
  removed from the scene.
- Home side buttons go somewhere now: Daily opens Quests (Daily), Gifts opens the Store
  (Offers, the daily gift), Starter opens the Store (Packs). Event, Promo and Ranks say
  plainly what they will be. Profile shows a real card: XP to the next level, highest stage,
  stars, bugs, bosses, stages cleared, hours, with a Trophies button. Crystals explains where
  they come from and opens the Store; Menu has a Stage Map shortcut.
- One wallet everywhere: coins and crystals as icons at the top right of Store, Quests and
  Gear (Quests had them as words, Gear only coins).
- Every button in the menus squeezes a little while held and springs back (touch feedback).
- Stage Map's "‹ Home" is now the same Back button as every other page.
- Turret milestones show a real star instead of an asterisk.
- Modes: the rewards row shows a gear piece (in the best rarity that planet can drop).
- Quests: three new daily tasks that use the Go buttons added in dev131: "Upgrade gear 2
  times", "Upgrade a turret track", "Merge in the Workshop" (Gear counts them).
- Battle: part pickups no longer load their picture from disk every frame.
- Notes (CLAUDE.md) brought up to date: layout overhaul, glass menus, real missions and gear
  copies in Patrol are all marked done; a new queue item 22 lists the polish proposals below.

Things I would upgrade next (your call, Rudy; some need Luna):
1. Sound: there is none. Taps, bolts, hits, pickups, card picks, a music loop per planet.
   Biggest "modern game" gap by far. Needs sound files (free packs or a composer).
2. Home side rail: only Chest, Patrol, Starter and Gifts have labels (LABELED in hub.gd);
   make it all six or none. Event and Promo lead nowhere yet: hide them until events exist?
3. Fonts: Modes banners and the Stage Map title use Orbitron; the rule says Exo 2 everywhere
   except the Home stage name and battle banners. Keep Orbitron there, or switch to Exo 2?
4. Store: Offers and Chests pages are half empty. Store 2.0 (queue 18: keys, pity, offers)
   fills them; until then a "Key chests: coming" teaser tile would look less bare.
5. Trophies: medals are drawn in code (thin lines). A Luna sheet of 10 trophy pictures x 3
   tiers would make the room worth visiting.
6. Quests rows are text only; a small painted icon per task type (bugs, gems, boss, stage,
   upgrade, merge) would make them scan faster.
7. Workshop > Gear: every owned piece shows as an "x1 Common" stack, so the list is long
   once all sets are open. Option: hide single base copies unless a filter is set.
8. Settings page (sound on/off, music, language) once sound exists.
9. Battle HUD and end screens were not in this visual pass (they need a run); next time.

## dev139: gear rarity, gear copies and merging, inventory, Quick Merge, loadouts

- Every gear piece now has a RARITY: Common, Uncommon, Rare, Epic, Legendary. Rarity caps
  the upgrade level: Common Lv.10, Uncommon 15, Rare 20, Epic 25, Legendary 30 (max 30).
  Everything you own today is Common, so nothing changes until you merge.
- Gear COPIES drop: clearing a stage gives a copy about a third of the time, always on
  boss and mini-boss stages (every 5th) and in Elite. The piece comes from that planet's set
  (stages 1-10 Ion, 11-20 Scavenger...), now and then an older set. Rarity rises with the
  planet: Common only on planet 1, Uncommon from planet 2, Rare from 3, Epic from 4,
  Legendary from 5 (rare). The Stage Cleared screen shows the piece. Patrol farms copies too
  (about one every 3-4 hours at full speed), shown in its window and on Collect.
- WORKSHOP now has two sub-tabs: Parts (as before) and GEAR, your inventory of copies:
  one tile per piece and rarity ("x3 · Common"), the piece you wear outlined in white,
  MERGE marked on stacks of 3 or more. Tap a stack: Merge 3 -> 1 of the next rarity (with
  Luna's merge animation). Your piece's rarity is the best copy you hold, so merging raises
  its level cap.
- FILTER button: by rarity, slot, set, and sort by Newest / Rarity / Set.
- QUICK MERGE button: merges every Common and Uncommon stack in one go (shows how many).
  Rare and above are merged by hand only, as agreed.
- Gear page: the slot tiles show the level in the rarity colour; the detail line reads
  "Lv.10 / 15 · Uncommon"; at the cap the Upgrade button says "Merge copies in Workshop".
  Milestones now continue every 5 levels up to Lv.30.
- Parts for Lv.10-29 upgrades grow slowly (Lv.29 -> 30: 78 Alloy, 14 Cells, 7 Cores).
- LOADOUTS (KIT row at the top of the Pilot page): three saved kits of the gear you wear,
  the turrets on the mounts and the drone's body and pod. Tap "+ Save" to store what you
  wear now, tap a kit to switch to it in one go, tap the kit in use to rename it or save
  over it. Upgrade levels are never part of a kit.
- Dev: tools/dev/capture.gd (page screenshots with a made-up save, tools/dev/save_rich.json),
  tools/dev/smoke.gd now also checks gear rules, merging, drops, parts and loadouts.

## dev138: free tutorial stages and Luna's turret card pictures

- Stages 1 to 5 cost no power tokens in Normal mode (first clears and replays alike), so a
  new player learns the game before tokens matter. Elite always costs 8. The POWER pop-up on
  Home says so. From stage 6 the normal 5 applies.
- Luna's six turret power card pictures are in: Ricochet, Focused Lance, Chain Storm, Event
  Horizon, Hive Surge and Wide Prism now show her art instead of the turret's picture
  (cards/pic_<card>.png, cut by tools/cut_ui_art.gd with ONLY=cards_r2; sources in
  art_src/cards_r2).
- New dev check: tools/dev/smoke.gd loads every script and runs quick rule checks before a
  build is handed over.

## dev137: power tokens

- Playing costs power tokens: 5 for a stage (8 for Elite), whether you win or lose, and
  collecting Patrol costs 5. They refill 1 every 6 minutes up to 60 (empty to full in 6 h).
- The counter sits at the top of Home beside coins and crystals (e.g. 45/60).
- Every way into a battle pays first: Home's Play, Modes, the Stage Map, Quests' Go and the
  end screen's Next stage / Retry. Short of tokens: a box shows what you have, when the
  next one comes, and a refill of +30 for 50 crystals.

## dev136: Patrol limits

- Patrol is much stingier, so leaving it for a day doesn't give everything:
  - an hour pays about 40% of one stage clear; elements drop half as often;
  - full speed for 2 hours after collecting, half speed to 6 hours, a quarter to 8 hours;
  - at most 12 hours of farming count per day, and you can collect 3 times a day.
- Stage 24 example: 2 h away = 219 coins + 6 Alloy; 8 h (or a whole day) = 493 coins,
  14 Alloy, 1 Plasma Cell.
- The window shows the current speed, hours stored and used today, and collects left.

## dev135: Patrol farms while you are away

- Patrol (on Home) now really farms: it plays a stage you have cleared, one wave every 30 s,
  with the game open or closed, and stores what each wave drops for up to 8 hours.
- Mostly coins (an hour pays about one clear of that stage), now and then that stage's
  element: Alloy on any stage, Plasma Cells from stage 11, Void Cores (rare) from stage 21.
- The Patrol window: arrows to pick which cleared stage to farm, what an hour brings there,
  a bar of how much is stored (of 8 h), and Collect. Example: 3 h away on stage 24 =
  822 coins, 19 Alloy, 1 Plasma Cell.
- Gear copies join Patrol once gear rarities and merging are built.

## dev134: drone milestones

- The drone gets milestones too: Lv.5 = fires 20% faster, Lv.10 = +25% damage. The Drone
  page shows them, and a gold MILESTONE! banner appears when it reaches one.

## dev133: turret power cards

- Six new power cards, each only offered while its turret stands on your base. Levels 1-2
  make the turret do more of what it does; the 3rd pick (overcharge) changes how it works:
  - Ricochet (Sentry): bolts bounce to 1 more bug per level; Flak: hits splash nearby bugs.
  - Focused Lance: beam +40% wider, +30% damage; Twin Lance: fires a second beam right after.
  - Chain Storm: lightning jumps to 2 more bugs per level; Overload: zaps can stun bugs.
  - Event Horizon (Gravity): pull area +25%; Black Hole: swallows enemy shots in its pull.
  - Hive Surge (Swarm): 2 more drones per level; Kamikaze: drones explode on impact.
  - Wide Prism: 2 more beams per level; Frozen Light: beams slow bugs.
- The cards show their turret's picture until Luna paints them (LUNA-BRIEF-turret-cards.md).

## dev132: mystery rewards on Modes

- The main mode is called Normal now (a story Campaign comes later as its own mode).
- Each mode shows a REWARDS row of mystery silhouettes: the picture darkened with a "?",
  on a tile in its rarity colour (coins grey, Alloy blue, Plasma Cell purple, Void Core
  gold, crystals purple). What shows depends on your stage: Cells on mini-boss stages,
  every 5th stage and from stage 21; Cores on boss stages from stage 20.

## dev131: Go buttons on Quests

- Unfinished tasks now have a Go button that takes you to where the task is done: fight
  tasks start a battle; boss, stage, star and planet tasks open the Stage Map; upgrade and
  merge tasks (coming later) open Gear on the right tab. Finished tasks still show Claim.

## dev130: combat stats, gear milestones, Stats page

- New combat stats: crit rate (5% to start), crit damage (x1.5 to start), damage boost,
  base damage reduction and fortress HP (shield and hull).
- Gear milestones: every piece earns a bonus at Lv.5 and again at Lv.10. Weapon = crit
  rate +3%, Helmet = crit damage +15%, Chest = base damage taken -4%, Gauntlets = damage
  boost +4%, Boots = fortress HP +6%, Jetpack = crit rate +2%. A gold "MILESTONE!" shows
  when a piece reaches one; its details say what it gives.
- In battle a critical bolt hits harder and looks bigger.
- Gear page: a STATS button beside the pilot shows your damage per hit, shots per second,
  damage per second, crits, hearts, the base's shield, hull and damage reduction, and each
  turret on the base.

## dev129: level ring on Home

- The profile button (top left of Home) has a ring that fills cyan to purple as you earn
  pilot XP; when it is full you go up a level. A small badge in its corner shows your level.
- Beside it: "Pilot" and your XP into this level (e.g. 450 / 1100 XP).

## dev128: turret upgrade tracks and milestones

- Every turret now has three upgrades instead of one level: ATK (damage), Rate (fires or
  charges faster) and Range (Sentry range, Lance beam width, Storm cloud, Gravity pull,
  Swarm drone flight time, Prism fan). Each goes to Lv.20, with coins and, higher up, parts.
- A turret's level is the three added up. Every 5 levels is a milestone: +5% damage, a
  star on its card and a gold "MILESTONE!" when you reach it.
- Old saves: a turret's old level becomes its ATK level, so nothing is lost.
- Balance re-checked with the autopilot (stages 20, 35, 50, 60 all win).

## dev127: balance pass for stages 21-60

- Tested with a "typical player" autopilot that has the gear and turret levels you'd
  normally have by each stage (from the coin table, ECONOMY.md).
- Before: stages 10-35 were never a threat, and from stage 45 the base fell in the
  first minute (a wall).
- Now: bug health grows 5% a stage to stage 30, then 2%; bug numbers grow half as fast
  after stage 30; from planet 3 the extra bugs build up over the first five waves.
- Result (autopilot, 4 runs each): stages 22-50 win every time, with hearts and base
  damage from 45 on; stage 55 and the final boss at 60 win 3 times out of 4.
- tools/balance_sim.gd: SIM_KIT=auto gives the autopilot that typical gear.

## dev126: rookie suit and the Commander armour

- New players start in Luna's plainer rookie suit (grey padded flight suit, few plates,
  cyan only), in battle, on Home and in Gear.
- Beating the Area 1 boss (stage 10) earns the Commander armour (the suit he wore
  before): "NEW SUIT: COMMANDER ARMOUR" on the Area Complete screen, worn from then on.
- Gear page: a Suit button on the platform steps switches Rookie / Commander (shows
  "Commander suit: stage 10" until earned). Saves that are past stage 10 keep Commander.
- Cutters: SUIT=starter for tools/cut_pilot_art.gd and tools/cut_batch_d.gd.

## dev125: Luna's merge animation

- The Workshop merge now uses Luna's own layers: her round merge chamber (the parts start
  at its three prongs), a charge ring and a swirl that spin faster and faster, her star
  flash, a shock wave, and light rays behind the new part. All tinted to the part's colour.
- tools/cut_merge_fx.gd cuts art_src/merge into fx/merge_*.png (outer edges faded).

## dev124: menu tidy-up

- Modes: all four modes fit on one screen (shorter banners, one short line each).
- Turrets: short lines ("Twin cannons, steady fire", "ATK x1.60 -> x1.90", "Needs pilot Lv.11").
- Drone: "ATK 0.4 · every 0.54 s" and a short line for body and weapon pod.
- Quests: the bonus line is now "All 5 done: +200 coins + 10 crystals · 5 left today".

## dev123: new Store

- Four tabs that each fit on one screen: Offers, Chests, Parts, Packs. Big pictures,
  big numbers, prices with the crystal icon, coins and crystals shown as icons on top.
- Offers: the Daily Gift across the top, then the coin offers and the x2 Speed Pack.
- Chests: the coin range and the crystal jackpot chance on each chest.
- Parts (new): buy Alloy, Cells and Cores with crystals, at the same rate crystals
  already cover missing parts when upgrading.
- Codes moved into a small "Have a code?" pop-up.

## dev122: your gear shows on the pilot

- He holds the weapon you equip, at its tier: Ion Pistol, Arc Welder, Pulse Cannon,
  Railgun, Sun Rifle or Frost Rifle (in battle, on Home and on the Gear page).
- His visor and helmet lights take the helmet's set colour (red for Nightmare, gold for
  Solar...), and the chest orb takes the chest's set colour.
- His bolts take the weapon's set colour (Luna's bolts recoloured, not tinted).
- Luna brief: LUNA-BRIEF-starter-suit.md, a plainer rookie suit (same layout as her parts).

## dev121: merge animation

- Merging in the Workshop now plays a short animation: the three parts spiral into a
  swirling ring, a flash and shock wave, then the new part pops out with a halo and
  "+1 Plasma Cell". Tap to close it early.
- It uses Luna's battle effects for now; LUNA-BRIEF-merge-fx.md asks her for merge layers.

## dev120: Void and Nightmare chests re-cut

- Luna re-rendered the Void and Nightmare chests with space between the tiers, so all six
  chest pictures are whole now (no more straight edge through a shoulder pad).
- tools/cut_gear3d.gd can re-cut single renders: CUT_ONLY="void-chest".

## dev119: Workshop and a tidier Gear page

- Gear has a 4th tab, Workshop: your parts at the top (Luna's Alloy, Cell and Core
  pictures), then merging: 3 Alloy -> 1 Cell, 3 Cells -> 1 Core. Merge one, or All.
- Pilot page order: pilot, then the selected piece with Upgrade, then the six pieces to
  choose, then your set bonuses at the bottom.
- Locked sets show a padlock and the stage to clear, e.g. "Stage 40".

## dev118: six 3D gear sets

- All 36 of Luna's 3D gear pieces are in the Gear page, each with 3 pictures: Lv.1-3,
  Lv.4-7 and Lv.8-10 show Tier 1, 2 and 3, so an upgrade you can see.
- Three new sets: Nightmare (opens after stage 30), Solar (after 40) and Frost (after 50).
  - Nightmare: Railgun (piercing shots); 3 pieces = Turret ATK +15%, 6 = turrets fire 20% faster.
  - Solar: Sun Rifle (fast shots); 3 = Pilot XP +20%, 6 = +1 heart.
  - Frost: Frost Rifle (rapid shots); 3 = Shield +20%, 6 = every shot slows bugs.
- The Scavenger weapon is now the Arc Welder (still twin shots).
- Gear text is short now: "ATK +12% -> +18%", one line per set.
- Art cutter: tools/cut_gear3d.gd (art_src/gear3d -> gear/<set>_<slot>_t1..t3.png).

## dev117: a chunkier pilot in battle

- The side-view pilot (battle and Home) now uses Luna's round-3 chunky arms and legs:
  thick armoured upper arms with their shoulder pads, a heavy fist on the rifle arm, a
  big open glove, and solid thighs and boots. pilot_rig.gd CHUNKY = false switches back.
- The arm maths now measures each bone along its own direction (the new forearms are
  painted sideways).

## dev116: Gear pilot, platform, card text, quiet parts

- Gear: the pilot now faces you in his chunky chibi front pose (big helmet). Before, he
  was stuck half-turned, so he looked squeezed and skinny.
- Gear platform toned down: the deck and its grid lines glow much less.
- Power cards: the text stays inside the frame. Bigger margins and shorter descriptions,
  and an Overcharge card shows only its new bonus.
- Upgrade parts no longer drop on the field. They're counted quietly and shown on the
  Stage Cleared screen.

## dev115: upgrade parts

- Upgrades to Lv.1-4 cost coins only. From Lv.5, gear, turret and drone upgrades also
  need parts: Alloy Scrap (common), Plasma Cells (rare, from Lv.7) and Void Cores
  (epic, from Lv.9). The Upgrade button shows the coins and parts needed.
- Short of parts? A box offers crystals for the missing ones (Alloy 2, Cell 6, Core 15
  crystals each).
- Where parts come from:
  - Bugs drop parts now and then (more on later stages).
  - Young Hive Mothers drop Cells.
  - Bosses from stage 20 can drop a Void Core.
  - Stage clears give Alloy, and every 5th stage a Cell.
  - Rarer parts only start on later stages. Elite doubles every drop.
  - Boss Rush will be the Void Core mode.
- Parts float as small spinning shapes in their colour until Luna's icons arrive. They
  show on the Stage Cleared screen and are kept even if the base falls.
- Luna brief: LUNA-BRIEF-gear-tiers.md (18 gear pieces x 3 tiers, starting with Ion, plus
  the 3 part icons).

## dev114: the pilot turns around

- When the pilot switches from aiming one way to the other, he no longer just mirrors:
  he swings round through facing the camera (Luna's front-view parts) in about half a
  second, then on to the other side. In battle, on Home and in Gear.

## dev113: the drone sidekick

- Gear has a third tab, Drone, which unlocks at pilot level 8. The drone flies at your
  side in every battle.
- Bodies (Luna's art): Scout (fires 30% faster, from Lv.8), Striker (hits harder and
  reaches further, Lv.14), Warden (also blocks an enemy shot near you every 5 s, Lv.20).
- Weapon pods: Twin Blaster (two quick bolts, Lv.8), Beam (an instant purple beam that
  never misses, Lv.12), Missiles (homing, bursting on nearby bugs too, Lv.16).
- Upgrade with coins: +25% per level up to Lv.10 (140 x level coins).
- Gear shows a big hovering preview, what it does and its numbers; Luna's pod flashes
  light up as it fires.
- New file drone_data.gd holds all the drone numbers.

## dev112: Luna's two-piece turrets, new card pictures

- Lance, Storm Spire, Gravity Anchor and Prism Tower now use Luna's new art: a base in
  the socket and a separate head on top, in battle and on Home.
  - Lance: a long cannon that turns toward the nearest bug (sweeping while it waits)
    and fires its beam along that line, instead of only straight up its own column.
  - Storm Spire: its spiked lightning orb floats and pulses over the base.
  - Gravity Anchor: its swirling rings float and pulse over the base.
  - Prism Tower: the crystal in its gimbal leans a little toward its target.
- Card pictures for Piercing Rounds, Frost Rounds, Turret Overclock, Shield Recharge
  and Thunder Lance.
- tools/cut_batch_d.gd cuts all of Luna's batch D pieces (turrets, drone bodies, pods,
  flashes, card pictures).

## dev111: new screens (batch C)

- Stars explained: every stage has 3 star objectives: clear the stage, keep the base
  hull above half, lose no hearts.
  - They show on a card when the stage starts, in the pause menu (on track / missed),
    and on the Stage Cleared screen with a tick or cross.
  - The old third star, "take no damage at all", was near impossible without shield
    regeneration.
- Pause menu, rebuilt in glass and filled with the run as it is now:
  - the stage and planet, the wave and the time
  - the star objectives so far
  - your cards, with a star on overcharged ones
  - Sound and Music switches (saved; sound itself comes later)
  - Resume and Back to Hub at the same width, centred
- Battle top bar in the Home glass style: a floating glass capsule, glass buttons, a
  cyan-to-purple XP bar and a glass level chip.
- Stage Cleared / Base Lost in glass:
  - big stars that pop in one by one, with why each was earned or missed
  - coins, pilot XP and kills on glass tiles
  - unlocks, then Next stage, Play again and Back to Hub
  - the card slides up into place
- Modes redesigned:
  - big cards with a painted world banner (Campaign shows the planet you're on)
  - honest rewards (coins, pilot XP, stars)
  - Elite starts the selected stage in Elite
  - Horde and Boss Rush say "Coming soon" instead of starting a normal battle
  - fixed: Modes never read your pilot level, so Elite always looked locked

## dev110: the new card list (batch B) and Luna's bolts and muzzle flash

- Cards now (every one worth picking, 3 levels each, the 3rd is its overcharge):
  - Rapid Pulse: fire rate +10%. Overcharge: overdrive, 3 s at double speed every 8 s.
  - Heavy Bolts: damage +15%, fat glowing slugs. Overcharge: every 6th bolt hits x3.
  - Burst Fire: bursts of 2, 3, then 4 twin-strand bolts. Overcharge: the last one
    pierces.
  - Piercing Rounds (new): bolts pass through 1/2/3 bugs, drawn as a needle with a
    ring. Overcharge: +25% damage for every bug passed.
  - Chain Spark: every 5th bolt crackles and sparks to nearby bugs. Overcharge: sparks
    hit twice as hard.
  - Frost Rounds (new): hits slow bugs 15/30/45% for a moment, icy bolts. Overcharge:
    slowed bugs take +20%.
  - Turret Overclock (new, only when you have a turret): turrets work 15% faster per
    level. Overcharge: turret shots +30%.
  - Aegis: +1 heart and the light shield. Overcharge: heals a heart each wave.
  - Reinforced Hull: +30 shield and +20 hull, repaired now. Overcharge: +40 shield.
  - Shield Recharge (from your 4th card): 1/2/3% shield a second. Overcharge: slowly
    repairs the hull.
  - Magnet: pulls gems and coins from further, gems +10% XP. Overcharge: each gem
    repairs 1 shield.
  - Nova Burst (legendary): clears the screen once.
- Removed: Wingman Drone (the drone becomes a Gear sidekick) and Quick Study (folded
  into Magnet).
- Fusions: Railstorm, Gem Barrage, Bastion, and the new Thunder Lance (Chain Spark +
  Piercing Rounds: every bug a bolt passes through throws a spark).
- Luna's art: the four bolt designs show what your cards do, and the rifle has her
  4-step cyan muzzle flash instead of the round glow.
- LUNA-BRIEF-redo-1.md: the drone flashes and pods to redo, and 5 new card pictures.

## dev109: turret sockets, Shield Recharge, card pacing, balance, coin report

- Turrets now sit dead centre in their sockets, in battle and on Home. The socket
  positions in the code were off from the rings Luna painted (up to 5 pixels); they
  are now measured from her strip.
- New card, Shield Recharge (uncommon, from your 4th card on): the base shield
  recharges 1% a second, 2% and 3% with more picks; its overcharge also slowly repairs
  the hull. Picture requested from Luna.
- Cards and level build up over the whole stage (never reset per wave). Cards now come
  a bit faster (one about every 10-14 s) and keep coming up to level 18.
- Balance:
  - Base shield 140, hull 100 (no regeneration).
  - Every third Spitter glob goes for the base.
  - Fewer extra Spitters in later stages; double-shot Spitters only from stage 25.
  - Bug toughness grows 4.5% per stage after stage 10 (was 6%).
  - The boss arriving with bugs still coming, and mid-stage young Hive Mothers, now
    start on planet 3 (stage 21+).
  - Autopilot results: stages 1-18 are won; stage 21 is winnable and stage 25 is hard
    with level-1 gear, which upgrades will answer.
- ECONOMY.md: how many coins each wave, stage and boss pays, against what Gear and
  turret upgrades cost, plus suggestions (a stage-clear bonus, bigger boss coins on
  later planets).

## dev108: battle feel (batch A from Rudy's stage 1-13 playtest)

- Turrets:
  - They search with a slow sweep and turn to aim at anything in range.
  - Long-press a turret to see its range as a see-through red shape.
  - The Sentry's head is now centred on its base.
  - Turrets help at level 1 and get strong with upgrades: +30% per level, Lv.10 =
    3.7x.
- Base:
  - The shield no longer regenerates, and the hull only takes damage once the shield
    is gone.
  - Shield 100, hull 80. Spitters aim every other glob at the base.
  - The Ion 6-piece bonus is now a bigger shield (+50%), and the Reinforced Hull
    overcharge gives +40 shield.
- Pickups:
  - Gems stand out on any world: a dark backing, a pulsing light ring and a glint.
  - Bugs drop coins (gems = XP, coins = money). A boss drops 10 big coins.
  - At the end of every wave, everything left flies to the pilot.
- Aegis is now a slim band of light that closes in around his body, not the hexagon.
- Hive Mother:
  - Much bigger, with 5 health bars (3 for the young one). Same total toughness.
  - Her hatching is obvious: a big burst and "HATCHING!".
  - From stage 12 a young Hive Mother turns up mid-stage on every other stage.
  - From stage 11 the boss arrives while bugs are still coming.
- Stage end: the last pickups fly in, then he blasts off the top of the screen, behind
  the top bar, and only then does Stage Cleared appear.
- From stage 14 Spitters sometimes spit two globs. Scouts are a bit easier to kill.
- Cards: every card has 3 levels at most (the third is its overcharge) and isn't
  offered again after that. Rapid Pulse is now +10% and Heavy Bolts +15% per level.
- Art brief for Luna: LUNA-BRIEF-batch-d.md (pilot turn-around, sidekick drone, muzzle
  flash, bolt designs, turret heads, gear tiers).

## dev107: Rudy's Home and menu playtest fixes

- Pilot: his free arm no longer comes loose or crosses his chest when he aims to the
  right (an angle wasn't wrapped when he's mirrored); it now hangs naturally at his side
  both ways. His head now tilts a little toward where he aims and drifts side to side.
- Home:
  - The Sentry sits centred on its socket, in two pieces like in battle (base ring +
    floating gun head that turns to its target).
  - Chest and Patrol lost their glass tabs (the line under them); they float free,
    moved up so they don't cover the turrets.
  - START is gone: on Home the gold Battle tab reads "Play", breathes, and starts the
    battle. The base now sits right on the nav bar, no empty gap.
  - The active tab's tile now sits inside the glass bar (no bar line behind it,
    nothing sticking out above).
  - Top bar: no box any more; profile, XP, coins and crystals float over a soft shade.
    Coins and crystals lost their ovals. The + opens the Store.
- Menus (Gear, Store, Quests, Modes):
  - No Back buttons (the Battle tab goes back).
  - Frosted glass: the Home world stays behind every menu, blurred and darkened,
    instead of the plain navy.
  - All panels, tabs and tiles are see-through glass with a light-cyan edge.
- Notch / camera cutout: the game now fills the whole screen (Android edge-to-edge)
  and Home, the menus and the battle top bar keep their buttons below the cutout,
  measured on each phone.

## dev106: phone test build

- Same game as dev105, packaged for a phone playtest (project notes updated).

## dev105: the Gear platform lights up with your set

- The Gear platform now uses Luna's two layers (deck + buildings).
- Set-bonus glow: wear 3 pieces of one set and the platform's grid lines and building
  windows light up in that set's colour (cyan Ion, green Scavenger, purple Void). With
  all 6 they glow fully and slowly breathe.
- Upgrading a piece makes the lights flare.

## dev104: Luna's new cards, frames and the Gear platform

- Card pictures for Chain Spark, Wingman Drone (the cyan-thruster redo), Quick Study,
  and the four fusions (Railstorm, Gem Barrage, Bastion, Storm Wing).
- Fusion cards use Luna's pink braided frame; a card about to overcharge uses her gold
  frame. Fusion descriptions shortened so they fit.
- Gear screen: the pilot now stands on Luna's "classic" platform (round deck, cyan
  grid, buildings on the back rim, steps at the front).
- Cutting: tools/cut_ui_art.gd (sources kept in art_src/cards_r1).

## dev103: the Glass look on Home and a new Gear screen

- Home, from Luna's mockups:
  - The top bar is one floating glass capsule with "Pilot 7" and a thin XP bar toward
    your next level, then coins and crystals.
  - The side buttons sit on glass tiles, and Chest and Patrol on glass tabs at the
    screen edges.
  - The bottom nav bar is a floating glass bar. Every tab shows its name, and the
    active tab rises as a lit glass tile (gold on Battle) that glides when you switch.
  - All glass has one thin edge that shades from cyan to purple. No glow.
- Gear screen: the pilot now stands on a round platform with the six gear slots around
  him (Weapon, Helmet, Chest on the left; Gauntlets, Boots, Jetpack on the right) as
  glass tiles, lit in the set's colour when selected. The platform is a stand-in until
  Luna paints hers (LUNA-BRIEF-gear-platform.md); it switches over by itself.

## dev102: fusion cards and three new cards

- Three new power cards:
  - Chain Spark: every 5th bolt sparks lightning to nearby bugs.
  - Wingman Drone: a small drone flies beside you and shoots the nearest bug.
  - Quick Study: gems give more XP.
  Each has its own overcharge on the third pick (Chain Spark sparks twice as hard, a
  second drone joins, levels need less XP). Aegis now overcharges on its second pick
  (heals 1 heart each new wave).
- Fusion cards: overcharge both cards of a pair and a pink FUSION card appears in the
  middle of your next pick. It keeps both powers and adds a new one:
  - Railstorm (Rapid Pulse + Heavy Bolts): every 4th bolt is a rail shot, double
    damage, pierces the whole line.
  - Gem Barrage (Burst Fire + Magnet): every 10 gems fire a burst of 6 bolts.
  - Bastion (Reinforced Hull + Aegis): when the shield breaks it blasts outward,
    hurting and pushing back bugs.
  - Storm Wing (Chain Spark + Wingman Drone): drone shots chain lightning.
- Until Luna's pictures arrive, the new cards borrow icons and a fusion shows its two
  parent pictures side by side. Brief: LUNA-BRIEF-cards.md.

## dev101: Aegis shield shimmer

- Picking Aegis now puts a thin hexagon shield round the pilot: it flares when you pick
  the card, then stays faint with a light band sweeping down it every couple of seconds,
  a little brighter with the second Aegis, and it lights up when he takes a hit.

## dev100: Home shows the stage's bugs

- The live battle behind Home now uses the bugs of the stage you have selected: stage 1
  shows only Scouts, later stages add Drifters, Spitters and Divers as they appear in
  that stage. On a mini-boss or boss stage (5, 10, 15...) the Hive Mother hangs in the
  sky above the fight, drifting slowly, so you can see what is waiting for you.

## dev99: overcharged cards and boss health layers

- Overcharge: picking the same power card a third time overcharges it, with a gold
  "OVERCHARGE" card and an extra bonus on top. Rapid Pulse: fire rate +15% more. Heavy
  Bolts: every 6th bolt is a big one doing 3x damage. Burst Fire: the last bolt of each
  burst flies through bugs. Magnet: every gem repairs 1 shield. Reinforced Hull: shield
  recharges 40% faster. The "your cards" panel marks overcharged cards.
- Boss health bar: the Hive Mother's health now comes in layers (3 for a boss, 2 for the
  young mini-boss) with an "x3" counter. Each layer empties in its own colour with the
  next colour showing underneath, a white chunk trails every hit, and the bar flashes and
  the screen shakes a little when a layer breaks. It slides in under the top bar.

## dev98: the store works

- Daily: a free gift every day (150 coins + 3 crystals), Coin Pouch and Coin Chest for
  crystals, and the Speed Pack (300 crystals) that unlocks x2 game speed.
- Chests: Supply Crate and Vault Chest bought with crystals; the chest opens on screen
  (lid up, light bursts out) and shows what you got. The odds are shown on each.
- Packs: the real-money packs are listed as "coming soon" (they need the game on Google
  Play with your developer account and Google Play billing).
- Codes: type a redeem code for free rewards, each works once per player. Codes live in
  store.gd (CODES): SKYBOUND, WELCOME, LUNA for now. Add a line to make a new one.
- All rewards go through the same function as missions and trophies.

## dev97: gear rework

- Six gear slots: Weapon, Helmet, Chest, Gauntlets, Boots, Jetpack, with Luna's 18 gear
  pictures in three sets: Ion (cyan, from the start), Scavenger (green, after stage 10)
  and Void (purple, after stage 20). Colour shows the set, never strength.
- Every slot now matters in battle: Weapon = bolt damage, Helmet = auto-aim accuracy,
  Chest = hit recovery (+1 heart at Lv.5 and Lv.10), Gauntlets = fire rate, Boots = gem
  magnet, Jetpack = auto-fire speed and your thruster style.
- Weapons differ by set: Ion Pistol (steady bolts), Dual Minis (two bolts side by side),
  Pulse Cannon (slow, heavy bolts).
- Each piece adds a small set stat, and 3 / 6 pieces of one set give bonuses: Ion = gem
  XP +15% / shield recharges 50% faster; Scavenger = coins +20% / +1 card refresh; Void
  = damage +10% / every 5th bolt pierces through.
- Upgrade spends coins now (Lv.1-10, 120 coins x level).
- The Gear screen shows the live pilot, your set bonuses, each stat now and at the next
  level, and the three pieces you can wear in the selected slot.
- Fixed: the planet briefing would have shown again every time (a number mix-up in the
  save).
- Balance: with the starting gear a normal player clears stages 1-12; later planets get
  6% tougher per stage, where upgrades matter. A later-stage balance pass is queued.

## dev96: missions and trophies are real

- Quests screen: Daily, Career and Trophies tabs, all live.
  - Daily: 5 missions a day (destroy bugs, clear stages, collect gems, shoot down
    Divers, a perfect stage...), new ones every day; finishing all five pays a bonus of
    200 coins + 10 crystals.
  - Career: milestones that never reset (clear stage 5, complete each planet, destroy
    500 / 5,000 bugs, reach pilot level 5 / 10, earn 30 stars, 5 perfect stages).
  - Trophies: 10 trophies with bronze, silver and gold tiers (Bug Hunter, Boss Slayer,
    Flawless, Explorer, Star Collector, Gem Hoarder, Card Shark, Veteran, Sky Shield,
    Defender). Each tier pays crystals.
- Claim pays at once: coins, crystals and pilot XP (missions help you level up, as
  planned). Home now shows the crystals you have.
- Every battle records your stats. All rewards go through one function
  (Progress.grant), ready for redeem codes, the store and later the inbox.
- Trophy medals are drawn in code for now; Luna can paint real trophy art later.

## dev95: stage map and stars

- Tap the stage name on Home to open the STAGE MAP: a winding trail of all 60 stages
  from the bottom up, each planet on its own painted band with its name. Cleared stages
  show their stars, the next stage pulses gold, bosses and mini-bosses have bigger
  rings, locked stages are dim. Your total stars are at the top right.
- Tap a stage for its card: waves, boss, your stars, and Select (make it Home's stage)
  or Play.
- Stars: 1 for clearing the stage, 2 if the base kept more than half its hull, 3 for no
  damage at all (base and pilot). You keep your best. The end screen shows them.

## dev94: six planets

- The game is now 60 stages on six planets of 10: Hive World, Scrap Belt, Magma World,
  Crystal World, Plasma Storm, Sentinel World. Each planet has two zones of 5 stages
  with their own painted world, so the background changes every 5 stages.
- Stage 5 of each planet ends with a mini-boss (a younger, smaller Hive Mother with 60%
  of the health), stage 10 with the planet's boss.
- Beating stage 10 shows AREA COMPLETE and names the next planet.
- The first time you reach a planet, an INCOMING TRANSMISSION briefing types itself out
  before the battle (tap Launch).
- Home shows the planet name next to the stage number.
- Later planets: 10 waves in zone A, 12 in zone B. They still use the Hive bugs until
  Luna paints their own families: LUNA-BRIEF-areas.md (Scrap Belt first, plus a
  commander portrait for the briefings). Balance past stage 10 comes with the gear
  rework (stronger weapons and gear are needed there).

## dev93: game speed, your cards, more cards

- Game speed button in the battle top bar: x1, x1.5 once you have cleared stage 10,
  x2 for a store pack later. Your choice is remembered.
- "Your cards" button next to it: pauses and shows every card you picked this run with
  its picture and level.
- Power cards come more often: about 3-4 in an early stage, 6-7 in stages 6-10 (it was
  2-3 and 4-5). Tested: a normal player still wins stages 1-9 most of the time; stage 10
  (the Hive Mother) still asks for an upgraded Sentry.

## dev92: hatches, hearts, Home chest and drone

- Locked turret sockets are covered by Luna's armoured hatch (battle and Home). The
  first time you play after a mount opens, its hatch tips up with a cyan flash and folds
  away, then your turret drops in.
- The hearts in the battle top bar are Luna's red heart; a lost heart turns dark.
- Home: the Chest button is Luna's 3D chest, floating gently; tap it and the lid lifts
  off and light bursts out. The Patrol button is her quad drone, hovering with its four
  rotors spinning. Coins and crystals use her new icons.

## dev91: power card pictures

- Every power card shows Luna's picture for it (Rapid Pulse, Heavy Bolts, Burst Fire,
  Aegis, Magnet, Reinforced Hull, Nova Burst) inside her rarity frames.
- When you level up, the three cards rise in one after another and settle with a small
  bounce instead of appearing all at once.

## dev90: Luna's pickups and shots

- Gems are Luna's crystals (blue shard, purple prism, red ember, gold star); they turn
  and bob as they float.
- The pilot fires Luna's cyan energy bolt (bigger and brighter with Heavy Bolts), with
  her cyan spark where it hits.
- Spitters spit Luna's purple goo glob, wobbling as it flies.
- Nova Burst sweeps the screen with her white-gold ring and a short shake.
- Also cut and ready for the next steps: card pictures, coin / crystal / energy / heart /
  badge / padlock icons, the locked socket hatch, the 3D chest and the patrol drone
  (tools/cut_ui_art.gd).

## dev89: painted worlds

- Every battle now plays in front of Luna's painted world for its part of the game:
  stages 1-5 the Hive world from orbit, 6-10 the glowing Hive caves, 11-15 the magma
  world, 16-20 the crystal world, 21-25 the plasma storm, 26-30 the Sentinel machine
  world. The painting slides a little as the pilot moves and breathes very slowly;
  near stars still twinkle and shooting stars still cross it.
- Home shows the world of the stage you have selected and cross-fades when you flip
  stages.
- The Scrap belt painting is ready for when the areas become 10 stages each.
- Cut by tools/cut_backgrounds.gd into backdrops/ (small webp files, 350 KB total).

## dev88: Luna's 3D bugs

- Scout, Drifter, Spitter, Diver and the Hive Mother are now Luna's glossy 3D bugs,
  seen from above, head pointing at your base. Their new amber wings beat with motion
  blur as before.
- The Hive Mother's egg sacs sit on her back and burst there (the Scouts hatch from
  her back); her claws reach forward under her head and sway.
- Cut from art_src/dev87 by tools/cut_bug_art.gd (enemies/parts).

## dev87 (pushed to GitHub; Luna packages it)

Sentry: a floating gun head (your idea):
- The gun head now floats a few pixels above its ring base instead of sitting on it,
  held up by a field: a soft glow on the base, a faint column of light, and thin rings
  rising from the base to the head.
- It bobs and drifts gently, leans a little into its swings, and on each shot dips
  toward the base and springs back up (the field brightens as it dips).
- When the Sentry drops into its socket, the head powers up and lifts off the base.
- The socket ring under the Sentry glows softer than under the other turrets, so its
  base stays visible and the two pieces read clearly.
- Tune: SENTRY_GAP near the top of battle.gd (the hover height, 9 px).

Each bug has its own job now (Rudy):
- Diver = kamikaze on the base. It flies in, stops for a moment to lock on (its wings
  fold and a red dashed line shows where it will hit), then dives at the shield about
  twice as fast as other bugs. It hits harder (13 instead of 10) with a bigger blast and a
  little shake. It no longer goes for the pilot. Shoot it during the dive.
- Drifter = the tank: takes 4 hits instead of 3, and when it dies it bursts into a
  small purple spore pod that sinks slowly toward the base. The pod chips the shield
  (4) unless you shoot it (one hit).
- Spitter = the shooter: still the one bug that attacks the pilot.
- Scout = the swarm, as before.
- Hive Mother: when she is angry (below half health) she launches a Diver from her
  back every 7 seconds.
- The first time you meet each bug, a "NEW ENEMY" card slides in under the top bar for
  a few seconds with what it does. The game remembers which ones you have seen.
- All in stage_data.gd ENEMIES (base_dmg, spores, dive_mult, launch_every, intro).

Pilot levels (Rudy):
- Levels 2-5 now come fast: a player who clears each of stages 1-5 once is pilot level
  5 right as stage 5 is cleared (checked with the autopilot: 130, 314, 512, 739, 1041
  XP). After level 5 each level needs 500, 650, 800... more XP; missions will help.
- Pilot XP per run = score / 50, plus a first-clear bonus the first time you beat a
  stage (80 for stage 1, +20 per stage). The end screen shows it, and any new pilot
  level and turret it unlocks.
- Turrets unlock by pilot level: Sentry 5, Lance 8, Storm 11, Gravity 14, Swarm 18,
  Prism 22. A turret stands on the base only when its mount is open AND you have
  unlocked it. At stage 5 both arrive together: "PILOT LEVEL 5! Sentry unlocked" and
  "NEW TURRET MOUNT OPEN!".
- Elite still unlocks at pilot level 10 (now about stage 12-15).

Turret mounts open as you clear stages (Rudy):
- Two separate unlocks: your PILOT LEVEL unlocks which turrets you own; CLEARING
  STAGES opens the four mounts on the base where they stand.
- No turrets in stages 1-5: you play them with the pilot alone. Mount 1 opens after
  stage 5, mount 2 after stage 15, mount 3 after stage 25, mount 4 after stage 40
  (MOUNT_OPENS_AFTER in turrets.gd).
- Closed mounts show a small padlock on the base, in battle and on Home. Gear shows
  them as "Locked - Clear stage N". The stage that opens a mount says "NEW TURRET
  MOUNT OPEN!" on its end screen.
- Home now shows YOUR turrets on your open mounts (it used to always show a Lance and
  a Storm).
- The Deploy Sentry card is gone.
- Tested again: hands-off still wins stages 1-5; a normal player wins 1-8.

Balance pass for stages 1-10 (tested with an autopilot that plays real stages):
- Auto-aim (finger off the screen) now fires as fast as dragging, so he is equally
  strong both ways.
- Gentler growth: bugs get 7% tougher per stage through stage 5, then 10% per stage.
- Smaller waves: stages 1-5 have 5 waves, 6-10 have 8 (stage 10 had 12). Waves grow
  by about two bugs every three waves. Bugs arrive one at a time in stage 1, in pairs
  in stages 2-5, in threes from stage 6.
- Spitters: in stage 3 they first appear in wave 3; they spit a little less often.
- Gems are pulled in from further away (90 px at the start, +30 per Magnet card), so
  you get cards without flying into danger.
- Sentry: hits harder and fires faster (about 1.6x its damage per second).
- Result, 8 test runs per stage:
  - Hands off the screen the whole time: wins stages 1-5, loses from stage 6 (you
    need to dodge Spitter shots from there).
  - A normal player who dodges shots (with the starting Sentry only): wins stages
    1-8, about 60% at stages 9-10. That is where upgrading turrets starts to matter.
  - With Sentry, Lance and Storm at level 2: wins stages 6-10 almost every time.
  - Stages last about 50-80 s (1-5) and 100-150 s (6-10).
- The test autopilot is tools/balance_sim.gd. Stages 11-30 are not tuned yet.

Livelier sky, base and hits (code only, until Luna's painted backgrounds arrive):
- Sky: stars at different depths (far ones small, dim and slow, near ones bigger and
  faster), twinkling, the coloured nebula clouds drift and breathe, a shooting star
  every few seconds, and the sky slides a little as the pilot moves (near stars more
  than far ones), on Home too.
- Base: a soft light runs round the dome's ring of window lights, the two upper lamps
  breathe, the antenna tip blinks red and the dish sends out a ping.
- Turrets: Storm Spire, Swarm Hive and Prism Tower gather light at their weapon before
  they fire; every turret squats a little on its socket when it shoots.
- Hits: a short screen shake when the shield, hull or pilot is hit, a split second of
  slow motion when a big bug dies (longer for the Hive Mother).
- Gems: a short streak as they fly to the pilot and a small pop when collected.
- Luna brief for painted backgrounds: LUNA-BRIEF-backgrounds.md.

Turrets centred on their sockets:
- Each turret picture had its painted body slightly off the middle of the image, so
  turrets sat 1 to 4 pixels left of their socket ring (the Prism and Gravity Anchor
  most). Every turret now has its own measured centre (cx in TURRET_LOOK at the top of
  battle.gd) and lands exactly on the ring centre, in battle, when a Deploy card drops
  a Sentry in, and on the Home screen. Checked with every turret on every socket.

Battle top bar, restyled to match Home:
- One bar across the top, built like the Home top bar: dark, flush with the top of the
  screen, one thin cyan line along its bottom that curves up into the screen edges.
- Top row: stage number and name, the run time, and the pause button (a small framed
  button with two bars). The HUB button is gone.
- Second row: score, the waves as little diamonds (filled = done, white = now; plain
  text on long stages), and cleaner hearts (an outline when lost).
- The XP bar is now the bar's bottom line itself, filling in purple, with the level on
  a small tab hanging under it. The Hive Mother's health bar sits below.
- Pause menu: the battle dims behind a panel with PAUSED, the stage, Resume, and Back to
  Hub ("Leaving ends this run.").
- Fixed: tapping pause could leave him firing as if your finger were still down after
  you resumed.

New pilot test (not in the game yet, nothing in battle changed):
- Luna's new 3D-style pilot parts are put together in code as a "puppet": helmet,
  visor, chest with the power orb, hips, arms, shoulder pads, legs, jetpack and rifle,
  each moving on its own joint. Because it is one set of pictures moved smoothly, he
  never flickers between frames.
- He breathes, aims the rifle where he shoots (left, right, up; the arm bends to
  follow and he turns round when the target crosses over), kicks back with a flash on
  each shot, leans into sideways moves with his legs trailing behind, spreads his legs
  when dropping and tucks them when climbing, the jetpack bobs a little behind the body,
  and the visor light pulses.
- Jetpack flames use Luna's flame layers for all five thruster styles (Ion, Plasma,
  Pressure, Gravity, Pixel): they stretch when he climbs, shrink when he drops, flicker,
  and throw sparks.
- To see it: open rig_test.tscn in Godot and press F6 (Run Current Scene). Left is the
  current painted pilot, right is the new puppet, at battle size on top and twice the
  size below. It loops through idle, aiming, leaning, firing, climbing, dropping and
  every thruster style, with the name of each step at the top.
- He is now IN THE GAME, in battle and on the Home screen, for you to play with. Bullets
  leave from his rifle tip. He holds Luna's side-view rifle, so it shows in profile
  when he aims sideways.
- To go back to the painted pilot: in pilot_rig.gd change "const ENABLED := true" to
  "const ENABLED := false". One line, nothing else to undo. The Gear screen still shows
  the painted pilot picture.
- Easier to see on the dark sky (Luna's art untouched): his parts are drawn a bit
  brighter, a thin cool-blue rim traces his outline, a faint blue haze sits behind him,
  and he is drawn about 12% bigger than before. The numbers are LIFT, RIM, BACKLIGHT
  and SIZE at the top of pilot_rig.gd.
- Also fixed: the Home screen logged an error on its very first frame (the base picture
  was drawn a moment before it was loaded). Nothing visible changes.
- Luna's parts are cut by tools/cut_pilot_art.gd into the pilot_rig folder; the puppet
  is pilot_rig.gd.

New base and turrets (Luna's art):
- Battle: Luna's base strip replaces the drawn deck and dome, along the bottom of the
  screen, with the four numbered sockets. Turrets sit in the sockets at about twice
  their old size, with a shadow under them, and a socket's ring lights up when its
  turret lands. At the start of a battle the turrets drop in one after another;
  a Deploy card drops a Sentry in straight away.
- Sentry: Luna's two-piece Sentry; the gun head swivels to follow bugs and turns round
  smoothly when they cross over.
- Shots and hits use Luna's effect art, drawn as light: Sentry tracers with spark hits,
  the Lance's tip gathering light then firing a thick beam, Storm zaps on each bug the
  lightning jumps to, the Gravity well as a spinning purple ring with a crush burst,
  real little drones from the Swarm Hive with a pop on hit, and the Prism's rainbow fan
  with a burst where it splits.
- Gravity Anchor and Swarm Hive hover gently on their sockets.
- Home: the wallpaper shows the same base strip with a Lance Pylon and a Storm Spire.
- Gear: the Turrets page shows the new turret pictures.
- Luna's source sheets are in art_src/battle; tools/cut_battle_art.gd cuts them into
  the game's pictures again if she sends new versions with the same layout.
- Removed: the old drawn deck, dome and turrets, and the old turret firing pictures.

From the dev86 playtest:
- Diver: the short blue line that popped up when it dived is gone. The dive now shows
  only through the Diver itself: wings folding and the body tipping toward you.
- Gravity Anchor: its well (the circle high above the left of the base) used to sit there
  even with nothing near it. It now only opens while it is actually pulling a bug, fades
  in and out, and a faint line ties it to its turret so you can see whose it is.
- Wings: Scouts, Drifters, Spitters and Divers beat their wings about twice as fast, drawn
  with motion blur (each wing three times per frame, see-through), so they buzz like real
  insects instead of flapping slowly. The Hive Mother keeps her slow, heavy wingbeat.
- Gentler start (stages 1-3 are the tutorial):
  - The first card now comes after 3 kills (about 6 seconds into stage 1, if you pick up
    the gems).
  - Stage 1 waves start with 3 Scouts and grow by one per wave; stage 2 starts with 5.
  - Bugs arrive one at a time in stage 1, two at a time in stage 2, then threes.
  - Bugs fly slower: 75% speed in stage 1, 85% in stage 2, 95% in stage 3, normal from 4.
  - In the simulator stage 1 now lasts about 70 seconds with at most 3 to 5 bugs on screen.
  - Tune in stage_data.gd (speed_mult, group_size, spawn_gap, waves) and battle.gd
    (_xp_need).
- Battle screen shows the stage number before its name ("6 SHARD FIELD"). The Hive
  Mother is still in: she comes on the last wave of stage 5 (Ion Fields) and every 5th
  stage; the playtest video was stage 6, which has no boss.
- Storm Spire: its cloud no longer sits across the middle of the screen all the time.
  It gathers when bugs come near and thins away when the sky is clear.
- Magnet card toned down: each card adds half the starting pull range (60 px start, then
  90, 120, 150, 180 at the max of 4 cards). Before, one card added a quarter of the
  screen height, which covered most of the screen's width on a tall phone.

- Art recut from Luna's full-quality sheets in Downloads: 72 of the game's pictures were
  found inside her original sheets and cut again from them, at the same size and with
  the same outline, so nothing moves in the game. Every one was checked side by side
  against the old picture and only replaced if it came out at least as sharp. The old
  versions are kept as a backup.
- Not recut, kept as they are: pictures that were edited on purpose after Luna painted
  them (Hive Mother sac colour, the split rifle icons on the Battle tab, card frames),
  a few whose original sheet is smaller than the game picture (so there is nothing
  sharper to take), and the Lance, Storm and Prism firing frames plus one pilot lean
  frame (right_3), which no longer line up with any sheet in Downloads.
- Gear: Luna's updated gear sheet (green middle column, boots now a pair) is in
  gear/gear_sheet.webp. The set plan is agreed: free mix and match, colour sets the
  tier, and 3- and 6-piece set bonuses for Ion (cyan), Scavenger (green), Void (purple).
  Not built yet.

## dev86: turrets are real gear

- Gear has a Pilot / Turrets switch at the top. Turrets shows the four base mounts
  (left to right, like the deck) and all six turrets. Tap a mount, tap a turret, then
  Place (or Remove). A turret sits on one mount at most; placing it again moves it.
- Upgrade spends real coins now: Lv.1 to Lv.2 costs 150, then 300, 450... up to Lv.10.
  Each level is +15% turret damage. The loadout and levels are saved ("turrets" in the
  save file). New players start with a Sentry on mount 1.
- Unlocks by pilot level: Sentry 1, Lance Pylon 2, Storm Spire 3, Gravity Anchor 5,
  Swarm Hive 7, Prism Tower 9. All six now work in battle (see below).
- Your loadout is mounted at the start of every battle.
  - Lance Pylon: its tip fills while it charges, then it waits until an enemy is in its
    column and fires a spear of light straight up, hitting everything in the column and
    erasing enemy shots in it. +50% vs bosses (+30%, bosses resist a little).
  - Storm Spire: a storm cloud builds above the base over 3 s; lightning strikes the
    enemy nearest the cloud and jumps to two more nearby (70% damage each). +50% vs swarm.
  - Sentry: as before, now with levels.
  - Gravity Anchor: a well opens high over its mount and pulls nearby enemies toward
    the middle for 2 s (the Hive Mother is too heavy), then crushes everything in the
    inner circle with a pulse. +50% vs swarm and fast. Its real value is bunching bugs
    up for your shots and the other turrets.
  - Swarm Hive: every 3.5 s it lets out 4 tiny drones that chase the nearest enemies
    for up to 4 s and pop on contact. +50% vs fast.
  - Prism Tower: sends a bright orb up; at about a third of the screen it splits into a
    fan of 5 rainbow beams aimed around the nearest enemy. Each enemy in the fan is hit
    once per volley.
- Turret damage was retuned so they share the work: Sentry 0.7 (was 0.5), Lance 1.8
  (was 2.4). In the simulator four turrets at Lv.1 do about 20-30% of the damage and
  at Lv.5 about 30-40%, inside the design doc's limit.
- Deploy Sentry card: puts a Sentry on a free mount for the run; if all four mounts are
  full it gives all turrets +20% damage instead.
- Turret damage no longer grows with Heavy Bolts (that card is for the pilot's gun).
- All turret numbers live in turrets.gd.
- Simulator check (auto-aim only, no dodging): turrets do about 10-15% of the damage
  at Lv.1 on early stages and up to about 40% with three turrets at Lv.5, which is the
  limit the design doc sets.

Hive brains (same build):
- Scouts flit: quick sideways darts, then a short drift, like flies. They are harder to
  hit: stage 1 takes about 43 s instead of 37 s in the simulator.
- Spitters watch your bolts and sometimes sidestep one that would hit. The chance starts
  at 35% on stage 1 and grows 5% per stage up to 75%. They can't dodge again for about
  a second, so a quick second shot still lands.
- Spitters now spit goo globs: wobbly purple blobs with two drips that leave from the
  mouth of the sac on Luna's art. The sac swells just before it spits.
- Divers sometimes feint (60%, once each): a short lunge at you, then they pull up and
  slide aside, and the real dive follows.
- The old pink enemy dots are kept for any future enemy that shoots something else.

Smooth animation pass (same build):
- Pilot: each pose step and the idle breathing now cross-fade between Luna's frames
  instead of cutting. When he swaps sides while aiming he squeezes through the turn
  instead of flipping in one frame. The muzzle flash fades out. After a hit he pulses
  softly instead of blinking on and off.
- Bug fixed: the game was setting the see-through level for the whole battle screen
  while drawing one enemy or the pilot. Enemies never actually faded in at the top,
  and after a hit with no enemies on screen the whole battle view could pulse. Each
  enemy and the pilot now fade on their own.
- Enemies: Divers fold their wings and turn into a dive smoothly; the tilt of every bug
  eases instead of jumping. Hatchlings now use Luna's hatchling painting as they come
  out of the sac, then grow and open their wings into a flying Scout. The Spitter's
  sac glow ramps up and down. The Hive Mother's sacs swell, cross-fade to empty at the
  burst and refill smoothly.
- Turrets: the firing picture fades out over the idle picture (no picture swap).
  Storm Spire lightning keeps one shape per strike and fades, instead of jittering
  every frame.
- Home: the Gear visor warms up with one soft dip (no on/off flicker), the Store crate
  and Quests tablet cross-fade, a tab you leave fades back, the tab name fades out
  instead of vanishing, and the Chest button opens as a cross-fade with a hop.
- LUNA-BRIEF-animation.md lists 8 small sheets of in-between frames that would make
  the turn-around, turret shots, chest, sac burst and Spitter spit look painted rather
  than blended. Most useful first: the pilot turn-around (2 cells).

## dev85: smoothness and balance batch

- Enemies are drawn from Luna's parts (enemy_rig.gd): bodies with hinged wings flapping
  on a smooth curve; the Hive Mother has hinged wings, swaying claws and egg sacs that
  breathe, swell, burst and deflate. Under half health she cracks, lays every 4 s with
  four hatchlings, drifts lower and sidesteps your aim.
- Hatchlings come out of her sacs (Luna's laying frames) instead of popping in.
- Pilot pose changes run through six painted frames, idle breathing loops.
- Bigger enemies, entering below the HUD with a fade; card pick hides floating text.
- Cards: Rapid Pulse +8%, Heavy Bolts +12% (thicker bolts, hot muzzle), Burst Fire
  replaces Twin Stream, Magnet and Reinforced Hull are +25% per level (Magnet ring).
  Gems no longer drift to you on their own.
- Early stages a little harder but gentle: leaks hurt more, Spitters sometimes target
  the base, slower shield regen.
- Tabs: slower visor flicker and rifle clash, Store crate closed until active, rings
  wrap the planet, gold check on Quests.
- CLAUDE.md: handoff notes for Claude Code (rules, code map, decisions, queue).

## dev81: Godot 4.7.2

- The project is now marked for Godot 4.7 (project.godot config/features). Everything
  was imported and run under 4.7.2 here with no script errors or deprecation
  warnings. Open it in 4.7.2; if the editor offers to upgrade the export preset,
  accept.

## dev80: feel pass after the first playtest

- Pace and XP: waves are about twice as big, enemies arrive in groups of three and
  are untargetable until they are properly on screen (so they do not die at the top
  edge), Scout gems give 2 XP, levels cost 8 + 5n XP. Stage 1 now gives about 3
  card picks in 45 s; stage 5 is a real fight. Spitters and Divers start a wave
  later and come in smaller numbers at first. Tune in stage_data.gd (waves,
  GEM_XP, ENEMIES) and battle.gd (_xp_need).
- Your bolts destroy enemy shots on contact (+10 score each).
- The base stands on a raised deck with four numbered turret platforms
  (MOUNT_X, DECK_H); the force field hugs the deck (DOME_RY 112). The pilot can fly
  anywhere above the ground, including inside the field.
- Enemies flap: each has wings-up and wings-down frames from Luna's sheet
  (enemies/*_up.png, *_down.png), tilt into turns, and the Diver folds its wings
  when it dives. The Home wallpaper uses the same sprites.
- Pilot poses are sequences now (PilotSprite.CHAINS and PilotSprite.Anim): idle to
  aim-up goes through Luna's two in-between frames, same for the leans (the right
  lean mirrors the in-betweens). Pose changes no longer snap.
- Tabs use Luna's state images: the visor is dark until Gear is active and
  flickers on; the rifles split and clash; the Modes rings spin around the planet;
  the Quests tablet lights up; the Chest button opens when tapped.
- After a hit the pilot is invulnerable for 1.5 s and blinks.

Other useful files:
- battle.gd / battle.tscn — the battle screen.
- gear.gd, modes.gd, quests.gd, store.gd — the four menu screens.
- pilot/ — the pilot's painted poses and the rifle.
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
