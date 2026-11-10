# Skybound Defender — source package for Rudy

This is the full Godot project for the game you have been playtesting.
Build 1.0-dev231 (version/code=231 and version/name="1.0-dev231" in export_presets.cfg). The phone installs over an existing app only if the version code is HIGHER than the installed one and the APK is signed with the same key. Each push raises the build by the number of updates it carries (dev167 + 4 updates = dev171).
Package name: com.skybound.defender. Main scene: hub.tscn (the Home screen).

## What you need to open it

- Godot 4.7.2 stable, on a PC. That is the exact version this project is built with (Luna builds
  the APK with it too).
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

## dev182: heroes, HP and DEF, hero cards, turrets and drones with elements, element trials, the look pass, turrets with weight, Luna's heroes and UI kit in, Horde, enemy variants, dev mode (eleven updates since dev171)

Update 1: HEROES replace the armour gear (your call, 2026-11-05; the plan is DESIGN-heroes.md,
Luna's brief is LUNA-BRIEF-heroes.md).
- The Gear tab is now HEROES. Six characters, rated by STAR GRADE and BOUGHT (your second
  pass): Rook (1★ Energy, the pilot you have, free), Sparks (1★ Electric, a junkyard robot:
  2,500 coins + 12 Alloy, or 60 crystals), Cpt. Frost (2★ Ice, a penguin in a spacesuit: 8,000 +
  20 Alloy + 6 Cells, or 160 crystals), Hollow (3★ Void, a ghost astronaut: 18,000 + 12 Cells +
  2 Cores, or 320 crystals), Nyx (4★ Dark, a cat-eared huntress: 40,000 + 20 Cells + 6 Cores, or
  650 crystals, and stage 20 cleared first), Ember (4★ Fire, a small dragon-kin: 40,000 + 40
  Alloy + 20 Cells + 6 Cores, or 650 crystals, stage 30 first). A higher grade starts stronger.
  5★ Mythic is the row for the next-level designs later.
- The page (your layout): the hero BIG on his platform, his panel under him (name, grade,
  element, passive, Level up, tier + Evolve; or the price and Unlock / crystals for one you do
  not own), then the roster as one scrolling row per grade, locked heroes dimmed with their
  price or the stage they need. Tap an owned hero to put him on duty.
- Builds: small heroes (Sparks, Nyx, Hollow) are drawn smaller and slide faster under your
  finger; bulky ones (Cpt. Frost, Ember) are bigger, slower, and shrug hits off longer. A real
  DEF stat waits for the HP change (see DESIGN-heroes.md).
- The hero on duty, with his weapon, shows on Home's live battle and in the fight; the same
  save line feeds all three.
- Each hero has an ELEMENT. Every planet is weak to one element (x1.35 damage) and resists
  one (x0.75): Hive World weak to Fire, Scrap Belt to Electric, Magma to Ice, Crystal to Void,
  Plasma to Dark, Sentinel to Electric. Energy is neutral everywhere. Home's stage line says
  WEAK TO ... so you know whom to bring; his bolts take his element colour.
- A hero has a LEVEL (coins: 60 + 30 x level a step; ATK +3%, fire rate, aim, recovery, magnet
  and auto-fire per level; a milestone every 5 levels: crit, a heart at 10, crit damage,
  damage boost, base damage taken, fortress HP) and a TIER (shards: tier 2 at 30, tier 3 at
  90; each tier ATK +8% and base +8%; tiers 2 and 3 will be Luna's evolved looks). Each hero
  has a passive: Rook gem XP +15%, Sparks coins +20%, Frost chills, Hollow pierces every 5th
  bolt, Nyx crit +5%, Ember +1 heart.
- SHARDS drop on boss stages and Elite wins, for the hero that planet is weak to (3 on a big
  boss, 2 on a mini-boss, +1 in Elite). They show on the end screen. Chests and Patrol later.
- The WEAPON is the one piece of gear left: it keeps its level, rarity, copies and merging,
  and any owned weapon can be equipped. Weapon drops continue; armour drops are gone.
  Workshop > Gear shows weapons only. Loadouts remember the hero.
- YOUR SAVE: nothing is lost. The coins you spent on the five armour pieces became Rook's
  level (same coins, the new cost table) and your spare armour copies became Rook shards.
  The old gear block is still in the save, untouched, so this can be undone.
- Until Luna paints the five new heroes, they wear the Commander armour with their element's
  lights and hold their own weapon, so the whole system is playable now.
- Dev: Settings > DEVELOPER > gear copies also gives 50 shards of every hero.

Update 2: HP INSTEAD OF HEARTS (your call, so defence can be a real stat).
- The pilot has an HP bar now (top right of the battle HUD, red, with the number) instead of
  three hearts. A Spitter glob takes 25 off 100, so a fresh Rook still takes four hits. Short
  invulnerability after a hit stays, so a glob cannot drain him in one go.
- Every hero has TWO upgrade tracks with coins on the Hero page: ATK up (the level: damage,
  fire rate, aim, recovery, magnet, auto-fire, milestones) and DEF up (each level takes 1.2%
  more off every hit, capped at 50%; 50 + 25 x level coins a step). The panel shows HP and DEF.
- Max HP grows with the hero's level (+2% a level), his tier (+8%), his build (bulky heroes
  start with more), the milestones that used to give a heart (now Max HP +15%), and Ember's
  passive (Max HP +20%).
- The Aegis card gives +30 max HP and heals 30 (its overcharge heals 25 HP each new wave).
  The third stage star is "Take no damage".

Update 3: HERO CARDS and DAMAGE NUMBERS.
- Each hero has ONE power card of his own that only shows up while he is on duty, and it
  builds up over its three picks like every card: pick 1 the basic form, pick 2 more of it,
  pick 3 his max specialty (the overcharge). Rook: Twin Trigger (every 4th, 3rd, then 2nd bolt
  brings a twin; overcharge: twins +15%). Sparks: Arc Weld (every 3rd bolt arcs to 1, 2, 3
  bugs; overcharge: every bolt arcs). Cpt. Frost: Deep Freeze (hits slow 20, 40, 60%; overcharge
  Shatter: a slowed bug that dies blasts its neighbours). Hollow: Phase Bolts (bolts pass
  through 1, 2, 3 more bugs; overcharge: +30% damage per bug passed). Nyx: Marked Prey (crit
  rate +10, 20, 30%; overcharge: crits hit x2.5). Ember: Afterburn (hits set bugs burning, 5%
  HP a second for longer each level, with embers and an orange glow; overcharge: a burning bug
  that dies passes the fire to the nearest bug).
- DAMAGE NUMBERS (your idea): small white numbers float off a bug as you hit it (added up over
  a quarter second so five bolts a second do not spam), orange when your element is strong on
  that planet and grey when it resists you, and a CRIT in big gold letters the moment it
  lands. Hits on you already show as red numbers.

Update 4: TURRETS AND DRONES follow the heroes (DESIGN-turrets-drones.md).
- Every turret has an ELEMENT and uses the same weak / resist table by planet as the heroes:
  Sentry Energy, Lance Pylon Fire, Storm Spire Electric, Gravity Anchor Void, Swarm Hive Dark,
  Prism Tower Ice. The old "strong vs traits" stays on top for when the enemy families come.
- Every turret has a ROLE in two words on its tile and in its details: Striker (Sentry),
  Breaker (Lance), Chain (Storm), Control (Gravity), Swarm (Hive), Support (Prism). Pick four
  roles for the planet, not four guns.
- Turrets are BOUGHT like heroes, rated by star grade: Sentry 1★ free; Lance 2★ 3,000 coins +
  15 Alloy or 80 crystals; Swarm 2★ 4,000 + 20 Alloy or 100; Storm 3★ 9,000 + 20 Alloy + 6 Cells
  or 200; Gravity 3★ 12,000 + 10 Cells + 1 Core or 260 (stage 15 first); Prism 4★ 25,000 + 16
  Cells + 4 Cores or 500 (stage 25 first). Pilot level no longer gates turrets. On the Turrets
  page a locked turret shows its price; its button says Unlock and offers crystals when parts
  are short. YOUR SAVE keeps every turret your pilot level had already unlocked.
- The DRONE has its OWN element, by body (your call): Scout Energy, Striker Fire, Warden Ice.
  A drone you own can be strong on a planet none of your heroes are, so the pair is the
  choice. Its hits and its damage numbers use its own colour. Two SUPPORT PODS join the
  attack pods: Repair Pod (no guns, patches the base shield 1.5 a second; pilot level 10) and
  Magnet Pod (no guns, gathers gems and coins near it; pilot level 12). They borrow the Beam
  and Blaster pictures until Luna paints them. The Drone page shows each body's element.
  Later: more bodies (an Electric spark bot, a Void wisp, a Dark bat), bought by grade.
- Balance: turrets have one tune knob now (Turrets.TURRET_TUNE) so the base's share of the
  damage can be set from the simulator in one place.

Update 5: ELEMENT TRIALS inside Promotion (your idea). Modes > Promotion has an ELEMENTS
button: one ladder per element, five steps each. Only a hero of that element may fight it
(Fight puts him on duty for you); without one the ladder says "Needs a Fire hero". Step 1 to
5 use the bugs of stages 10, 20, 30, 40, 50 with 20% more of them and x1.2 to x1.6 health, so
each ladder crosses every planet: your element is strong on one and resisted on another.
The first clear of a step pays that element's hero 10, 15, 20, 30, 40 shards plus 300 to
1,800 coins, and the last step 20 crystals; a replay pays half the coins. No stars, no stage
unlocks, no drops: the trial pays. The HUD says "FIRE TRIAL 2", the end screen shows the
step and the reward.
- ADVANTAGES AND DISADVANTAGES (your idea): every rank trial and every element step carries
  one or two of each, named twists the fight is built around. Advantages: Rapid fire (+25%),
  Sharpshooter (crit +20%), Fortified (base shield +50%), Reinforced (pilot HP +50%), Turret
  boost (+50%), Overcharge (cards 50% faster). Disadvantages: Swift bugs (+25% speed), Thick
  shells (+25% health), Turrets down, Double spit, Cracked shield (half). The ladders show
  them under each row ("+ Rapid fire   − Swift bugs"), the battle announces them under the
  top bar for the first seconds, and the pause menu lists them. The mix per rank and per step
  is in promotion.gd (RANK_MODS, ETRIAL_MODS): easy to change.

Update 6: THE LOOK, from your playtest notes.
- BOLDER TEXT everywhere: Exo 2 now runs at weight 600 (semibold) instead of regular, through
  one font file (fonts/exo2_semibold.tres) the whole game and the battle HUD use; the small
  text sizes (13 and under) are one size bigger.
- BUTTONS WITH DEPTH: every kit button (gold, teal, glass) has a drop shadow, a gloss on its
  top half, a darker band at the bottom and a light line on its top edge. Disabled buttons stay
  flat so they read as off.
- POWER CARDS: taller cards so three lines of the bolder text fit; the Refresh button moved
  down with them. (The cyan frame on Uncommon cards is Luna's frame picture, drawn to the
  card's edge where the Common frame has an inset; a frame with the same inset would make
  them match.)
- Modes: the Promotion row's three buttons fit the phone width again.

Update 7: TURRETS BIGGER, WITH WEIGHT, RESTING AND FIRING (your note).
- All six turrets are about a fifth bigger on the base (Sentry base 70 px wide, heads to
  match), with a darker contact shadow in the socket.
- WEIGHT: a turret that drops in now lands with a squat on its socket and springs back; the
  Sentry's floating head dips on landing; the idle bob is slower and heavier.
- REST AND FIRE: with no bug in reach a turret settles a few pixels lower, its lights dim to
  a third, the Sentry parks its head pointing up and hovers lower, the Swarm Hive keeps its
  lid shut. The moment a bug comes in reach it wakes: lights up, lifts, tracks and fires
  (Sentry barrels recoil, heads overshoot, the Lance swells as it charges). The hand-over
  takes about a quarter of a second to wake and a second to settle.
- Not changed: the battle top bar. Your note said the spacing is off and space is wasted; I
  would like a quick sketch or a screenshot with a mark of what to move, because on the PC
  frame the bar is already two rows and the notch inset on your phone changes it.

Update 8: LUNA'S FIVE HEROES ARE IN THE GAME. Sparks, Cpt. Frost, Hollow, Nyx and Ember show
on the Heroes page (big, with Luna's portraits on the roster), on Home's live battle and in
the fight, with their own weapons painted in. How: each hero is drawn from Luna's five
turn-around frames, picked by the way he faces (left, three-quarter, camera, three-quarter,
right) and cross-faded, with the rig's lean, bounce and recoil moving the whole picture and a
muzzle flash in his element colour. Hollow's frames 4 and 5 are mirrors of 2 and 1 and Ember
stands in with his reference picture until Luna's round-2 frames arrive (the cutter swaps
them in automatically). The per-part rig for the heroes (parts cut and ready in heroes/<id>/
parts/) is the next step for finer motion. Dev: tools/cut_heroes.gd.
- LUNA'S ROUND 2 is in: Ember's five real turn frames (holding the gold rifle) and portrait,
  Hollow's frames 4 and 5, Captain Frost's repainted glove. No stand-ins remain.
- THE HERO STAND: the old equipment platform with its buildings is gone from the Heroes
  page. The hero floats over a glowing hover disc in his element colour: a dark glass disc,
  an etched grid, a holographic ring turning above the rim, a soft column of light with specks
  rising. It flashes on a level-up. Luna's painted stand (LUNA-BRIEF-hero-stand.md) replaces
  the code shapes the day it lands.
- SWIVEL (your idea): drag a finger across the hero on the Heroes page and he turns left and
  right through Luna's frames (Rook through his side and front poses); he holds the angle and
  drifts back to face you after four seconds. A "drag to turn" hint fades once used. The full
  spin to his back needs three more frames per hero (LUNA-BRIEF-hero-back-frames.md).

Update 9: HORDE MODE is real (the Modes card said "coming soon"). From pilot level 5: endless
waves built from your best Standard stage's wave list, cycling through it with 15% more bugs
each lap and bug health up 4% a wave, a boss every 10th wave. The run ends when you fall;
the score is the wave you reached, saved as your best and shown on the card ("BEST: WAVE 14").
Each wave cleared pays a coin bounty on top of the drops (20 coins + 4 a wave). Costs 5 power
tokens. The HUD says "HORDE · WAVE 12"; the end screen "HORDE OVER" or "NEW BEST!".
Boss Rush stays "coming soon".
- BALANCE SWEEP with the new hero kit (simulator, a careful player with the gear of that stage):
  Normal 1-60 all won with no pilot damage and the base untouched (the bot dodges every glob,
  so this is the top end of what a player does), turrets about a quarter to a third of the
  damage late; Elite 10 won, 20 and 40 half, 30 a cliff (2 of 3), 50 and 60 won; the rank trials
  had become easy with the hero kit, so every rank got tougher (Cadet now has no turrets:
  about half the runs, the rest won but hurt). Numbers in CLAUDE.md 16g.
Update 10: ENEMY VARIANTS (queue item 17 a, code only; Luna's families come later). The same
bugs now come with a twist, mixed in more as the stages rise (about 6% of bugs at stage 6, a
third by stage 50): ARMOURED (from stage 6: a plated ring, nearly double health, slower; the
Lance Pylon is strong against it), SHIELDED (from 11: a bubble that stops bolts and beams
until it breaks with a flash; the Storm Spire is strong against it), BOOSTER (from 16: a
SUPPORT bug with an orange aura; bugs near it move 30% faster and spit sooner, with orange
lines to the bugs it boosts: kill it first), HEALER (from 21: a green aura; it heals bugs
near it 4% a second with green zaps: kill it first). Support bugs carry their name over them;
the first of each kind in a run announces itself ("BOOSTER BUG: KILL IT FIRST"). Variants pay
150 score instead of 100. Shielded bugs show a cyan shield bar over the health bar.
Update 11: LUNA'S UI KIT, DEV MODE, and the Workshop plan.
- LUNA'S UI KIT is in (36 renders, all usable): every gold, teal and glass button, the
  sub-tabs, the chips and the section headers are now her rendered pieces, stretched as
  9-slice boxes (the corners stay as painted). The battle top bar, the HP bar and the XP track
  use her frame and bar pieces. The big panels stay code glass for now: her panel renders
  carried a gloss band across the middle; her round-2 panels (gloss only in the corner, delivered
  the same day) are in: every info box, the reward rows, the item tiles with their corner
  brackets, the pop-up windows with their notch, and the Home bottom bar are hers now. (Old text:
  version with the gloss only in the top corners. Her nav
  dock, top bar, popup and nav tile pieces are cut and waiting for the same reason.
- DEV MODE (for you): Settings has a DEV MODE switch at the top. ON = every hero, turret, drone
  body and pod, weapon, mode and trial is open, all four mounts are open, every upgrade and
  unlock is free, power tokens never gate a fight. Your real progress is untouched; switch it
  OFF and the game is exactly as it was. It rides on the save, so it survives restarts.
- WORKSHOP AND MATERIALS: your idea is written up in DESIGN-materials.md: materials per
  domain (base parts as now; element ESSENCES for heroes and weapons, e.g. a Solar Flare for the
  Sun Rifle's high levels; a weapon line and a drone line), the Workshop as the crafting bench
  with a CRAFT tab (essences from lower essences, weapon variants, unlock materials), drops by
  planet and trial. Loadouts stay: a kit now saves hero + weapon + turrets + drone (a planet kit).
## dev206: Luna's turrets round 2 and their cards, the star ladder, the talent map as a star chart, hero evolutions and blended maps, the Scrap Belt family, Luna's Store art and the re-tune, stats and chain cards, the HUD card row, briefs and the efficiency pass, Luna's moving skies and the dome (eleven updates since dev195)

Update 1: LUNA'S TURRETS ROUND 2 are in (29 renders, all usable). SIX NEW TURRETS,
a second one per element with a different job, so picking a turret is a play style (your rule):
- Repair Node (Energy, Support, 2★, 3,500 coins + 15 Alloy, stage 10): does not shoot; every
  3 s it mends the base shield (the shield never heals on its own) with a ring of light rising
  from its dish. ATK is how much it mends.
- Tesla Coil (Electric, Striker, 2★, 4,500 + 20 Alloy, stage 10): fast zaps at the nearest bug,
  short reach, an arc from the ball to the bug. Strong against shielded bugs.
- Cryo Lens (Ice, Control, 3★, 10,000 + 8 Cells, stage 20): the lens leans toward the nearest
  bug and breathes a cone of cold; every bug in the cone is slowed by half and chipped.
- Mine Layer (Void, Breaker, 3★, 14,000 + 12 Cells + 2 Cores, stage 30): floats up to three
  mines that drift to the biggest bug in the sky (bosses and armoured shells first) and burst
  on it, with a blast round it. Strong against bosses and armour.
- Dread Beacon (Dark, Support, 3★, 15,000 + 12 Cells + 2 Cores + 2 Dark Embers, stage 35):
  paints a red mark on a bug; every hero bolt on a marked bug is a critical hit; and the hero's
  ATK is +10% while the beacon stands. The first price that asks for a material.
- Flak Battery (Fire, Swarm, 2★, 5,000 + 25 Alloy, stage 15): the mortar cradle turns to the
  thickest knot of bugs and lobs a shell that bursts in the air at their height, shredding
  everything round it. Strong against swarms and wide waves.
  The Range track grows each one's reach (Tesla, Beacon, Flak), cone (Cryo), blast (Mines, Flak)
  or mend (Repair). They are bought on the Turrets page like the first six; the dev switch
  gives them to you. Luna's base and head pieces are drawn the same way as the first six (base
  in the socket, head above it; the lens and the mortar lean toward their target); her shot
  pictures are the tesla arc, the frost fan, the mine, the marker flash and the flak burst.
- FIRING HEADS: the six turrets you had now have a second head picture that fades in for the
  split second they fire: Sentry barrels hot, Lance opened white-hot, Storm's coil flared,
  Gravity's rings pulled tight, the Swarm's side vents lit as the drones leave, the Prism split
  into five lit faces. Luna lined them up with the resting heads, so the cross-fade is clean.
- Rook's card picture (pic_rook_twin) arrived: Twin Shot shows it now instead of the weapon.
  Luna sent two; the cyan paired bolts (as briefed) are in, the teal one is kept as an alt.
- POWER CARDS for the six (offered in a run only while that turret stands, like the first six;
  the card shows the turret until Luna paints card art): Overdrive Node (mends +50% a pick;
  overcharge Hull Weld: mends the hull once the shield is full), Chain Coil (zaps jump to 1
  more bug a pick; Overload: zaps can stun), Deep Chill (cone +20% wider and slows +10% a pick;
  Shatter: a bug already chilled takes x2.5 from the cone), Cluster Mines (1 more mine in the
  air a pick; Shock Mines: a burst can stun), Dread Mark (marks last +1 s and hero ATK +5% a
  pick; Twin Mark: two bugs at once), Shrapnel (blast +20% a pick; Incendiary: bugs in the
  blast burn). Checked by tools/dev/card_check.gd (forces each card three times, then fights).
- Not yet: Luna icons for the six in the turret role badges (the role icons cover them).
- Archive: art_src/turrets2/ (the later re-sends of storm_head_fire, flak_shot and repair_shot
  are the ones used; the first versions kept as -v1). Cutter: tools/cut_turrets2.gd.
- Check: smoke passes (two turrets per element, every piece cut, the Beacon's material price);
  headless runs at stage 20 (Tesla + Flak) and 45 (Mines, Beacon, Repair, Cryo) without errors.

Update 2: STARS, one standard for how heroes, turrets, drones and weapons grow
(your calls today, DESIGN-stars.md). Nothing is locked behind a stage any more. A higher star is
locked behind BUILDING the thing: level it to its cap, collect for it, evolve it, and the new
star raises the cap and the power. Five gold stars, then five RED stars for the endgame.
- EVERYTHING ARRIVES AT 1 STAR. A hero's grade (Common .. Mythic) is still his price class
  and the strength he starts with, but it is a word now, not stars; the stars on a tile are
  the ones you earned. Red stars show as R★ on tiles and as red stars on the panels, and a
  red-star hero carries a red halo in battle.
- LEVEL CAPS BY STAR. Hero levels: 10 a star (Lv.50 at five gold, Lv.100 at red 5). Turret
  tracks: 4 a star on each of ATK / Rate / Range (20 at five gold, 40 at red 5). Drone: 2 a
  star (10, then 20). A capped button says "Lv.20 cap, next star". Weapons keep their own
  ladder: rarity, raised by merging copies in the Workshop.
- WHAT A STAR ASKS FOR (the thing at its cap, plus): a hero needs his own shards, essences of
  his element and coins (2 stars: 5 shards + 2 essences + 2,000; 3 stars: 15 + 5 + 6,000;
  4 stars: 40 + 10 + 15,000; 5 stars: 100 + 20 + a Prime Coil + 40,000; red: 150 to 500
  shards, 30 to 80 essences, 2 to 6 coils, 60k to 220k). A turret needs essences of its element
  and coins (2 / 5 / 10 / 20 essences, then coils), every one of its three tracks at the cap.
  A drone body needs essences, the drone line (Rotors, then Gyros, then Flight Cores) and
  coins, the drone at its cap. The panels list it; the Evolve / Star up button names the one
  thing in the way: "Pilot Lv.5 first", "Lv.10 first", or it is greyed while the shards,
  materials or coins are short (the line above says how many).
- PILOT LEVEL ONLY OPENS THE DOOR to each star: 2 stars at pilot level 5, then 12, 20, 28;
  red 1 at 35, then 40, 45, 50, 55. That is the brake on money: a paid hero still arrives at
  1 star, crystals can buy coins and essences and so SPEED, but the pilot level comes only
  from playing stages and quests, so the ceiling is play time. Dev mode opens all of it.
- STARS GIVE POWER: +8% a gold star, +12% a red star, on hero ATK, HP and fortress, turret
  damage (and the Repair Node's mend) and drone damage. A red-5 kit is about 1.9x a one-star
  kit at the same level: the endgame content (Elite 40+, Horde, Comet+ trials, more stages
  after 60) must be tuned against it before anyone gets there (DESIGN-stars.md, balance).
- PREMIUM stays: Ember is crystals only; she arrives at 1 star like everyone.
- Old saves: a hero's tier 2 / 3 is his 2 / 3 stars; shards stay; turrets and drones start at
  1 star. The afternoon's stage gates (the earlier update 2) are gone.
- Check: smoke covers the ladder (texts, power, caps, doors, needs, a hero, a turret and a drone
  stepping up, the round trips, Ember); the Gear pages were captured with a stars save.

Update 3: THE PILOT TALENT MAP (your queue item 16 e). On the Hero page, a
TALENTS button beside STATS opens the map: forty nodes in five columns, bought IN ORDER, each
a small permanent bonus for EVERY hero. Bought nodes are gold, the next one teal, the rest
dim; tap any node to read it; one button buys the next.
- The ten-node cycle: Bolt damage +1.5%, Turret damage +2%, Hero HP +2%, Crit rate +0.5%,
  Coins +3%, Base HP +2%, Fire rate +1%, Gem XP +3%, Crit damage +4%, Magnet +6 px. Four
  times round = forty nodes; the whole map is about +6% bolt damage, +8% turret damage, +8%
  HP, +2% crit, +12% coins, +8% base, +4% fire rate, +12% gem XP, +16% crit damage.
- COSTS RISE the way you asked: coins first (330 for node 1, 6,000 for node 10, 18,000 for
  node 20, 36,000 for node 30, 60,000 for node 40), then Cores from node 11, an essence of
  the node's element from node 21, Prime Coils (plus 3 essences) from node 31. Node N opens
  at pilot level N: a talent a level, so the map keeps pace with play, not with money.
- EVERY 10TH NODE UNLOCKS A NEW POWER CARD for your runs (offered only once its node is
  bought): node 10 FOCUS FIRE (bolt damage +6% a pick; overcharge crit rate +10%), node 20
  SALVAGE (bugs drop +25% coins a pick; overcharge: every 10th kill drops a part), node 30
  SECOND WIND (once a run, the blow that would finish you heals you to 50%, then 75%, then
  full), node 40 MIRROR SHELL (a bolt that stops a bug's shot throws it back as a bolt of
  yours for 50 / 75 / 100% damage; overcharge: your bolt flies on). Their pictures borrow the
  stat icons until Luna paints card art.
- A red dot on TALENTS (and on the Heroes tab) when a node is ready to buy.
- THE STAR MAP (your note the same evening): the map is a galactic chart, not a list. Four
  CONSTELLATIONS of ten stars, each a figure charted star by star along its lines, the tenth
  star the figure's key point and the card: THE RIFLE (cyan), THE SENTRY (green), THE HIVE
  MOTHER (purple), THE DOME (gold), each with a line of lore under its name. Charted stars
  shine in their constellation's colour with gold lines between them, the next star pulses cyan
  with dashes travelling toward it, the stars ahead wait dim on dotted lines, and a long faint
  jump links one constellation to the next. The chart scrolls through deep space with a nebula
  per constellation and twinkling far stars; it opens on your next star; a panel at the bottom
  reads the star you tap and charts the next one. All drawn in code today; Luna's brief
  (LUNA-BRIEF-talent-map.md) asks for the four skies with the figures as faint old-chart line
  art, plus the star and star-system pieces, and the code picks them up the moment they land.
- Check: smoke covers the costs, doors, buying, the bonuses in the hero stats and the cards'
  gating; the map and a card pick with the three talent cards were captured.

Update 4: LUNA'S HERO EVOLUTIONS are in (60 renders, all usable), and NO MORE
DIVIDING LINES on the maps (your note).
- Every hero has his tier 3 look as eight whole turn frames, plus a tier 2 and a tier 3
  portrait: Rook in white-and-gold armour with a cape, Sparks in chrome with a bigger battery,
  Cpt. Frost in ice-crystal armour, Hollow as a purple ring-haloed wraith, Nyx with a red-lit
  cape and twin katanas, Ember in gold scale with wide wings. YOUR LADDER FOR THE LOOKS (the same evening): the
  base look at 1 star; at 2, 3 and 4 stars a minor change (the tier 2 portrait on the roster, a
  crisp rim of his element's light round him and the halo, both brighter each star); at 5 stars
  the BIG change, Luna's tier 3 frames and portrait, on the Hero page, the roster, Home and in
  battle; red stars keep the five-star look with a red halo until you design their extra. Cutter: tools/cut_heroes.gd (the back frames lined up to the
- ROOK (your catch): his white-and-gold set changed his colours, and an evolution should keep  the hero's own theme and only ADD to him (Frost, Hollow, Nyx and Ember already do). So the  white-and-gold Rook is parked as his first SKIN (heroes/rook/skins/ceremonial, to unlock or  buy later with the colour skins you described: white and gold, neon green lights, a red or  blue body) and Rook shows his base look at 5 stars until Luna repaints that set in charcoal  and purple with the cape (LUNA-BRIEF-rook-5star.md, a small redo). Skins as a system are on  the queue (item 19) for after the Store and the Exchange.
  front ones, one crop per hero); archive art_src/heroes/<hero>/t3_turn_1..8, portrait_t2 / t3.
- THE STAR MAP blends: the sky of one constellation fades into the next over a long gradient,
  no line; Luna's painted skies will overlap the same way (her brief asks for black at their top
  and bottom edges).
- THE STAGE MAP blends: every zone's world carries on up into the zone above it and fades out
  there, so a planet's lava fades into the next planet's crystal instead of a cut and a cyan
  line. The planet titles stay where they were.

Update 5: THE SCRAP BELT FAMILY is in (Luna's 36 renders, all usable; queue item
17 b). Planet 2 gets its own enemies: junk machines the bugs built, and from here on families
STACK: the Hive bugs never leave, the machines join them.
- Five machines, each taking a Hive role so the fights stay fair: SCRAP MITE (a tin-can drone
  on two spinning rotors; the swarm), HULK DRONE (a reactor between two thruster panels; tough,
  bursts into two JUNK BOLTS when it dies), RIVET GUN (a nose gun and a back pod that glows
  before each rivet; the one that shoots you, rivets fly faster than goo), SPIKE DART (a missile-
  drone that locks on and dives at the base), JUNK BOLT (the tumbling cluster a Hulk leaves).
  All drawn from Luna's pieces: rotors spin with motion blur, panels sway, the pod fills and
  empties, the Dart's flame flickers, and every one breaks into its own six chunks when it dies.
- How they arrive: at stage 11 a third of each wave is machines, growing to 60% by stage 20,
  and from planet 3 on about half of every wave stays machines beside the bugs. Rivet Guns from
  stage 13, Darts from stage 15. Every machine gets its NEW ENEMY card the first time you meet it.
- THE WRECKER, planet 2's mini-boss (stage 15): a crane machine on two wheel rotors that drops
  to hover height, slides over one of your turrets and lowers its claw onto it: that turret is
  HELD and cannot fire ("TURRET GRABBED!") until you shoot a quarter of the Wrecker's health off
  it, then it lets go, lifts, and goes for another one a few seconds later. Shoot it dead and
  the turret is free.
- THE SALVAGE QUEEN, planet 2's boss (stage 20): a crane queen whose cargo hold opens on her
  back to drop Mites ("RELEASING!"); she is weak while it is open. Angry, she launches Darts
  instead of Divers. Her arms swing as she drifts. From planet 3 the mid-stage young boss
  alternates between her and the Hive Mother, and Horde brings the planet's boss every other
  time. The boss bar now names who you are fighting (Hive Mother, Wrecker, Salvage Queen).
- THE COMMANDER: Luna's portrait heads the radio briefing when you reach a new planet
  (urgent on the first two planets, calm after). Home shows the Queen or the Wrecker looming on
  the Scrap Belt's boss stages, and the machines fly in the Home battle there.
- Check: smoke covers the table, the waves, the bosses and the art; the sim won stages 11 to
  22 with the auto kit, no errors; the briefing, the Wrecker holding a turret, the Queen and Home
  on planet 2 were captured. Archive: art_src/scrap/; cutter tools/cut_scrap.gd.

Update 6: LUNA'S STORE ART (21 of 30 renders so far: three keys, the three tier
chests closed and open, five crates, four coin piles, two crystal piles, four badges; the chest
pieces body / lid / burst and crystal piles 2-4 are still to come). The crates stand on the
Offers packs (daily, weekly, monthly) and the Starter pack, the coin piles grow with the deal
in the Shop, the crystal piles on the Crystals tab, the Exchange tab and its token teaser wear
their icons, the chest cards carry the pity badge and a FREE tag. The Uncommon and Epic keys show everywhere keys do (prices, drops, the
Workshop recipe, the chest cards), the gold Legendary key is kept for later. The Chests tab
shows each chest closed in its tier's colour, and opening one pops the closed chest and swaps
to its open picture with the burst, then the reward rises. Cutter: tools/cut_store2.gd (it also picks up the rest of the brief when it
lands); archive art_src/store2/.

Update 7: THE LONG-GAME RE-TUNE, first pass (your item 16 g), after a full sweep.
- The sweep before: with the star ladder, the talent map and the twelve turrets, the auto
  kit won every Normal stage 1 to 60 with the base never touched, and Elite 15 lost both runs
  with the base down by wave 6 (an Elite Wrecker held a turret too long).
- Changes: bug health after stage 30 climbs 3.5% a stage instead of 2%; the planet boss (stage
  10, 20, ... 60) is half again as tough and arrives with its wave still coming, halfway on
  planet 2 and a third of the way in from planet 3, so each boss is a soft wall with company;
  the Wrecker lets a turret go after six seconds whatever happens.
- The sweep after: Elite 15 won 2 of 2; Elite 25 and 40 won 1 of 2 with the base down to 25
  and 50 (Elite is the hard ladder, as meant); a kit six stages behind lost half at stage 20
  and still won 40 and 60. Normal 10 to 60 still won every run with the base untouched.
- Honest note: the simulator's pilot dodges every shot and never takes damage, so Normal
  looks softer in the sim than it will on a phone. Bigger moves (more boss layers, the boss
  earlier on planet 1, chip damage in the first waves: IDEAS-rogue-defense.md) wait for your
  playtest of this build. Sim knobs: SIM_STAR (force a star), SIM_KIT_PLUS (kit stages ahead
  or behind).

Update 8: THREE SMALL THINGS FROM YOUR RECORDINGS (IDEAS-rogue-defense.md).
- DAMAGE BY SOURCE: the pause menu and the Stage Cleared screen now show who did the damage
  this run: your hero, the drone and each turret by name, biggest first, with a share bar,
  the total and the damage per second. You can see at a glance whether the Lance earns its
  mount.
- CHAIN: a card that is half of a fusion (Rapid Pulse, Heavy Bolts, Burst Fire, Magnet,
  Reinforced Hull, Aegis, Chain Spark, Piercing Rounds) now carries a small CHAIN tag naming
  the fusion it leads to, so the fusion system is visible on the pick instead of a surprise.
- COIN REFRESH: once the free refresh is used, the card pick offers another refresh for the
  coins picked up in this run: 150 coins, then 300, then 450. Spending them lowers the coins
  the stage pays out, so it is a real choice.

Update 9: YOUR BUILD ON THE TOP BAR, and the overcharge as a moment (two more
from the recordings). The cards you have taken this run sit as a row of small pictures beside
the LV chip, each with a pip per level, an overcharged one framed gold, so the build reads at
a glance without opening the cards panel (which stays for the details). And the third pick of
a card, the overcharge, now fires a gold ring off the hero, a shout, a beat of slow motion and
a shake, so it feels like the event it is instead of a third copy of the same card.

Update 10: A LUNA BRIEF FOR THE STAND-INS, and the first efficiency pass.
- LUNA-BRIEF-icons-3.md asks for the fourteen material icons (the six essences, the weapon
  and drone lines, a hero shard, an event token) as one sheet and the ten card pictures the
  new turret cards and the four talent cards borrow today. The code picks them up by name the
  moment they land.
- Efficiency (your item 27, lighter never uglier): the top bar builds its stage title and
  its clock only when they change instead of every frame, and the light-effect layer keeps a
  ceiling on live effects (180, half in Battery saver) dropping the oldest on a crowded
  screen. Nothing looks different.

Update 11: LUNA'S HOME ROUND 2 IS IN (41 renders, all usable): every planet's sky
as five layers, and the command dome as its own piece with its three super-weapon forms.
- THE SKIES MOVE. Home, the menus and the battle stand in front of a layered sky now: a deep
  star field that slides slowly and loops, a nebula layer in the planet's colours sliding a
  little faster, up to eight floaters per planet (rocks, wrecks, a far hulk, a small ship,
  debris) drifting and spinning across, the planet's curved horizon along the bottom that
  breathes, and its atmosphere rim pulsing. Everything leans opposite the pilot for depth.
  All six planets: Hive, Scrap Belt, Magma, Crystal, Plasma, Sentinel. The old flat paintings
  stay as the fallback and on the Stage Map bands.
- THE DOME IS A PIECE. Luna's standard dome sits on the strip in the exact place of the
  painted one; her Orbital Beam, Shield Overcharge and EMP Pulse domes (idle, charging,
  firing each) are cut to the same canvas and swap in place. The super weapons themselves
  (queue item 10) are not built yet; the dome kind and frame are two values to set when they
  are.
- Luna's two open questions, for you: (1) the Crystal sky follows the brief (cyan, white,
  pale blue) and does not match the older pink-and-purple crystal painting; my call: keep
  cyan, it is the Ice world (Cpt. Frost, the Cryo Lens), and the old painting now only shows
  on the Stage Map band, which can switch to the new planet layer. (2) Sparks' missing
  straight-back frame: my call: paint it from his parts sheet; today the ring fades across the
  gap, which reads as a hiccup in his spin.
- Cutter: tools/cut_home2.gd (sky layers scaled for phones, light layers keyed to alpha, the
  eight floaters cut from their sheet, the domes cut on one shared canvas). Archive:
  art_src/skies/<planet>/, art_src/home2/.

## dev195: Luna's UI kit round 2, icons, drones round 2, stand, your screenshot notes, back frames, orbit rings, cards round 2, Elite eased in, hero evolutions, materials and the Craft tab, Store 2.0 and dev mode stages (thirteen updates since dev182)

Update 12: LUNA'S ICONS are in (48, all usable). Coins, crystals and power
tokens on Home and every wallet; Alloy, Cells and Cores everywhere parts show; the six element
badges in the corner of every hero and turret tile; her tab icons on the Hero / Turrets /
Drone / Workshop, Daily / Career / Trophies / Repeat and Offers / Chests / Parts / Packs
strips; stat icons on the STATS panel; the three chests, the gift, the pack and the key in
the Store; the Elite, rank and trial badges on the Modes cards. Shards, roles and the
"weak to" shield are cut and ready for the pages that will show them (materials, turret
details).

Update 13: LUNA'S DRONES ROUND 2 are in (26 renders, all usable). Three new
bodies, each its own machine, each BOUGHT like a hero or a turret (coins + parts, or crystals)
and rated by grade: SPARK BOT (2★ Electric: a scrap ball with a crackling Tesla coil; its hits
arc to 2 more bugs; 6,000 coins + 20 Alloy + 4 Cells, or 120 crystals), WISP (3★ Void: a dark
glass teardrop with a purple core and three trailing fins; bolts pass through 1 bug; 14,000 +
10 Cells + 2 Cores, or 280), NIGHT BAT (4★ Dark: a black stealth bat with red light edges;
crit rate +15%; 30,000 + 16 Cells + 5 Cores, or 520). In battle each flies as parts: the hull
banks, the wings and fins beat, the Wisp's middle fin trails, and Luna's glow layer (coil,
core, eyes) breathes over the body and flares on a shot. The Repair and Magnet pods have their
own pictures now. Scout, Striker and Warden stay on pilot level. The Drone page shows the
grade stars and the price on a locked body; tap it to buy.

Update 14: LUNA'S HERO STAND is in. The hero floats over her rendered hover
  disc: the etched glass disc with its metal rim, the light lines and the floating ring glowing in
  his element colour and breathing, and a soft column of light with drifting specks behind him.
  The code shapes are gone.

Update 15: YOUR SCREENSHOT NOTES.
- ONE LEVEL UP for a hero (no separate DEF button): every level raises ATK, HP and DEF
  together. Milestones every 5 levels are PERKS as well as numbers: crit, Max HP, crit damage,
  damage boost, base damage taken, fortress HP, then at Lv.35 every 6th shot fires a TWIN, at
  Lv.50 bolts PASS THROUGH a bug, at Lv.60 he fires in BURSTS of 2. The next perk shows under
  the level line. Any DEF levels bought before this still count.
- SHORT PANELS: the hero panel is two lines (level and numbers, the next perk) plus the
  passive by the tier; the drone panel is two lines (what it is, its numbers). The descriptions
  live on the tiles.
- E BADGE: no more "Equipped", "Choose", "Wearing" or "On mount" words. The equipped hero
  weapon, drone body and pod carry a small E in the tile's corner in the item's colour; a
  turret on the base carries its mount number there instead. Tapping any open tile equips it.

Update 16: YOUR NEXT NOTES.
- The hero HOVERS a little above the disc, centred on it, with a slow bob.
- The stand is BLENDED into the world for now: a soft dark halo under it fading into the
  wallpaper and the disc a touch smaller and see-through. A redo brief for Luna asks for a
  stand with no metal rim and edges that fade (LUNA-BRIEF-hero-stand-2.md); her -v2 files
  will replace it by name.
- WEAPONS SCREEN: tapping the weapon tile opens your weapon inventory: a card per weapon
  (picture, element badge, level, rarity, an E on the equipped one), tap to equip, with the
  equipped weapon's details and its Upgrade button in the same window. The old CHOOSE grid
  under the hero is gone.
- The hero tiles on the roster show the hero's portrait; Rook's is cut from his turn frame
  until Luna paints one, so no tile shows a weapon that is not in his hand.
- Dev: the balance simulator's typical-player kit now spends on hero ATK and DEF levels and the
  weapon (the armour pieces are gone), so its numbers mean something again.

Update 17: LUNA'S BACK FRAMES are in (20 of 21, all usable). Every hero and
both pilot suits now turn ALL THE WAY ROUND on the Heroes page: drag past the side and you
see the jetpack, the wings, the cloak, the tail; let go and he drifts back to face you.
- Her back frames were rendered a little smaller and higher than her front frames (she
  followed the brief, the old frames were looser), so the cutter scales and lines them up to
  the front frames' body height and feet before cutting, one scale per hero. No size pop.
- Sparks' straight-back frame (7) she could not make: the ring simply fades from his left-back
  view to his right-back view across that spot, so nothing is missing on screen. The spin
  stays solid mid-turn now (the next frame dissolves in over the current one, no see-through
  ghost), in battle too.
- The hero stand brief was REWRITTEN to your taste (LUNA-BRIEF-hero-stand-2.md): no disc, no
  grid. Orbit rings: a pool of nebula haze under his feet, two thin elliptical rings of light
  circling him with beads the game will send round, and a soft column rising; everything
  dissolves into the dark, white light tinted per hero. Four files with -v2 names.
- Archive: art_src/heroes/<hero>/turn_6..8.webp and art_src/turn/turn_<suit>_6..8.webp; the
  cutters are tools/cut_heroes.gd and tools/cut_turn.gd (both now cut rings of eight).

Update 18: LUNA'S ORBIT-RING STAND is in (4 renders, all usable). The disc and
the grid are gone. Under the hero: her nebula pool breathing slowly, two thin rings of light
circling him with beads travelling round each ring (bright along the front, faint behind him),
and a soft column of light rising from the centre. Everything is tinted in the hero's element
colour and dissolves into the dark sky; nothing solid.
- Her beam was lit from a point at the top like a spotlight; the cutter ramps it so it is
  strongest at the base and gone before the top. The rings carried a faint grey box under
  their brighter half and the pool a faint rectangle; both are cut away (grey floor, soft
  ellipse mask).
- Archive: art_src/stand/stand_pool-v2 / ring_a-v2 / ring_b-v2 / beam-v2.webp; cutter
  tools/cut_stand.gd (_cut_v2 runs when the -v2 pool exists).

Update 19: LUNA'S CARDS ROUND 2 is in (17 of 18 renders usable; Rook's Twin
Trigger picture was not delivered, his card keeps the pistol until it lands).
- Five hero cards now show their power, not the gun: Arc Weld (a forked yellow arc leaping
  to a second point), Deep Freeze (a bug frozen in cracked ice, shards flying), Phase Bolts
  (a violet bolt through an unbroken ring), Marked Prey (a purple crosshair, red diamond,
  claw scratches), Afterburn (a flaming ember with a second flame catching).
- The eleven trial twists are ICONS now, green for an advantage and red for a disadvantage:
  on the Pilot Ranks ladder (under each rank's name), on the Element Trials steps, under the
  battle top bar for the first seconds of a trial, and in the pause menu. The words
  ADVANTAGE / DISADVANTAGE are gone; the colour says it.
- Luna's Uncommon frame -v2 is in (the Common frame's height, window filled dark by the
  cutter). HONEST NOTE: on screen it changes little, because the game stretches every frame
  to the card anyway; the real difference is that the Common frame has a thick inner band
  and the Uncommon, Epic and Legendary frames have thin ones. If you want the four to match,
  the small ask is a Common frame in the same tech style as the other three (thin band,
  grey edge).
- Archive: art_src/cards_r3/ (pic_*.webp, frame_uncommon-v2.png, tw_*.png, twists-sheet);
  cutter tools/cut_cards2.gd. Dev: battle _dbg_cards("a,b,c") opens a pick of those cards
  for captures (tools/dev/capture.gd CAP_CALL).

Update 20: ELITE EASED IN + ICON POLISH (code side while Luna renders).
- The "Elite stage 30 cliff" was never a cliff. The sim (typical kit, human bot, 3 runs a
  stage) won Elite 20 3/3, 25 2/3, 28 3/3, 30 1/3, 32 3/3, 35 2/3, 40 1/3: a coin flip from
  25 up, and every loss had the same shape: the hull gone by wave 4-7 while the run level
  was still 7-11, before the power cards had built up; every win ended with the hull near
  100. The Elite toughness (bugs x1.85 health) landed in full from the first bug.
  FIX: Elite health eases in over the first five waves (60% of the factor's strength at
  wave 1, full from wave 5; StageData.elite_mult). Re-run (4 runs a stage): Elite 25 2/4,
  30 3/4, 35 4/4, 40 4/4; the losses left are at stage 25 waves 6-7, where the young Hive
  Mother turns up mid-stage. Elite stays hard, it just stops killing you before you have
  any cards.
- Icons: the hero panel's shard line starts with Luna's shard icon ("0 / 30 shards · Tier 1
  · Coins +20%"); turret tiles carry their ROLE icon top left (crosshair Striker, hammer
  Breaker, chain, control, swarm, support) next to the element badge top right; Home's
  stage tag "WEAK TO ICE" shows the element symbol after the words.

Update 21: HERO EVOLUTIONS, code side, and the hero-tiers brief REWRITTEN.
- HONEST NOTE: the brief I sent you this morning asked Luna for tier looks as PARTS (head,
  torso, back piece). That only works if each hero is a parts rig like the pilot, and I
  checked her parts sheets: Sparks' arms and legs are rendered from other angles than his
  reference, and Captain Frost's sheet is a plain grey clay version. The pilot's own rig
  took three rounds of fixes. The heroes look far better as her whole turn frames, so they
  stay that way, and the brief now asks for WHOLE FRAMES: tier 3 = the hero repainted as his
  "legend" self at the same eight angles + a portrait; tier 2 = one new portrait, and the
  game adds the rest. Please send Luna the new LUNA-BRIEF-hero-tiers.md in place of the old.
- In the game now: a tier 2+ hero carries a breathing halo in his element colour (the frame
  drawn a touch larger behind himself; stronger at tier 3); the roster shows portrait_t2 /
  portrait_t3 when they exist; the rig shows heroes/<id>/t3/turn_1..8 when they exist (Rook
  too); tools/cut_heroes.gd cuts t<k>_turn_n.webp and portrait_t<k>.webp when they land.

Update 22: MATERIALS + the Workshop CRAFT tab (your DESIGN-materials.md, built).
- Twelve new materials on top of Alloy / Cells / Cores: an ESSENCE per element (Energy Spark,
  Arc Charge, Frost Core, Void Fragment, Dark Ember, Solar Flare), the WEAPON line (Scrap
  Barrel -> Focus Lens -> Prime Coil) and the DRONE line (Rotor -> Gyro -> Flight Core).
- What asks for them: hero tiers (tier 2 = 30 shards + 2 essences of his element, tier 3 =
  90 + 5), the 3-star+ heroes' price (Hollow 3 Void Fragments, Nyx 6 Dark Embers, Ember 6
  Solar Flares), weapon levels from Lv.15 (barrels; lenses from 20; a coil and an essence
  from 25), turret track levels past 10 (its element's essence), drone levels from Lv.5
  (rotors; gyros from 10; a flight core at 15). Every price shows them like parts, and
  crystals can still cover what is missing on upgrades.
- Where they come from: a boss stage drops the essence that planet is WEAK to (two in Elite;
  Elite also drops one on a third of other wins), an element trial step pays its own essence
  (two the first time), Horde pays a barrel and a rotor per 10 waves, Patrol trickles the
  two lines from planet 2 and the planet's essence very slowly, and the dev wallet gives 20
  of each.
- Workshop > CRAFT (third sub-tab): what you own, then one card per recipe with what it makes,
  what it needs with have / need counts (green when you have it) and a Craft button: 10 Alloy
  + 200 coins = a Scrap Barrel or a Rotor; 3 of a step + coins = the next step (a Core joins
  for the top step); 10 Cells + 2 Cores + 1,000 coins = one essence of the element you pick.
  The end screen lists what dropped. Luna's icons come later (icons/mat_<id>.png); until then
  the element badges and the parts icons stand in.
- NOT built from the design yet: weapon VARIANTS crafted in the Workshop (needs their art and
  their behaviour), Store 2.0 selling materials (with the Store rebuild).

Update 23: STORE 2.0 (your queue item 18) + DEV MODE opens every stage.
- Five tabs: CHESTS | OFFERS | SHOP | CRYSTALS | EXCHANGE.
- CHESTS: Uncommon, Epic and Legendary. Uncommon and Epic open with KEYS (Uncommon Key, Epic
  Key: a boss stage drops one, Elite drops the Epic one on its boss stages and an Uncommon one
  on a third of the rest, Horde pays one per 10 waves, the daily and weekly packs give one),
  and each has one FREE open every 24 hours. Crystals open any chest (40 / 120 / 300); the
  Legendary opens only with crystals. PITY: every 10th Uncommon open is an Epic item (a Core,
  an essence and an Epic gear copy), every 10th Epic open a Legendary item (3 Cores, 3
  essences, a Legendary gear copy, 150 crystals); the card says how many opens are left. The
  odds are written on every chest. Essences and gear copies match the planet you have
  selected, so you farm for what you need. The Home chest overlay opens the same chests.
  The Workshop can also turn 3 Uncommon keys into an Epic key.
- OFFERS: the attendance calendar as before, then the Daily, Weekly and Monthly packs, each
  with a FREE part you claim on its own timer (daily: 300 coins + an Uncommon key; weekly: 3
  Cells + an Epic key; monthly: 30 crystals + a Core + an essence) and the paid part marked
  coming soon. Stage Pack and Season Pass teasers.
- SHOP: one scrolling page in sections: coins (the old pouches and the speed pack), keys,
  parts (once the Workshop is open), SPECIALTY (the selected planet's essence, barrels,
  rotors, a Focus Lens), all for crystals at the stand-in rate.
- CRYSTALS: the real-money packs, "opens on Google Play". EXCHANGE: event tokens and the
  season shop, with the online update.
- DEV MODE (your note): the Developer switch now opens every stage on Home, the Stage Map and
  Modes, in Standard and Elite (and Horde runs from stage 60), Elite itself, and the Pilot
  Ranks ladder gets a Fight button on every rank so you can jump to any trial. Element
  trial steps still go in order (the step is the ladder).
- The old crystal crates (Supply Crate, Vault Chest) are gone from the page; the code keeps
  them for old saves.

## dev171: your Elite and Promotion notes, and the fun pass (four updates since dev167)

Update 1: Elite and Promotion, from your notes.
- ELITE never runs ahead of Standard: Elite stage N opens only once you have cleared Standard
  stage N (and the previous Elite stage). The Modes card says so.
- PROMOTION recommended levels are now 10, 20, 25, 30, 35, 40, 45, 50, 55, 60. Each trial uses
  the bugs of the stage a player of that level is around (level 10 is about stage 15, level 20
  about stage 30, level 25 about 40, level 30 about 55, and a player who only clears each stage
  once reaches about level 33 by stage 60, so the ranks above that are the endgame ladder on
  stage 60 bugs). A trial OPENS seven levels under its recommended level: the level is advice,
  not a gate. Difficulty was set with the simulator: a player with the gear and turrets of that
  stage wins about half the time, a player twelve stages weaker almost never (one win in
  fifteen), a player eight stages stronger nearly always. Gear and turrets carry it, not retries.

Update 2: the fun pass, part one: SYSTEMS APPEAR ONE AT A TIME (your worry that there is too
much to absorb). Nothing was removed; a new player just does not see it yet.
- A fresh player sees: Play, Gear with only the Pilot page, Quests (Daily, Career, Trophies),
  the Store (Offers, Chests, Packs) and Modes with Normal plus ONE "next up" card.
- Then, in this order: Repeat quests after stage 3; Turrets after stage 5 (the first mount);
  Patrol after stage 6; the Workshop after stage 8 (or sooner, the moment you hold a spare copy
  of a piece or enough parts to merge); Promotion at pilot level 5; the Drone at level 8;
  Elite at level 10; Loadouts (the KIT row) after stage 12. The Store's Parts tab comes with the
  Workshop.
- Each one is announced ONCE on Home with a small NEW pop-up and a Show me button that opens
  it. Your existing save takes everything it already has as seen, so you will not get a queue
  of pop-ups.
- Red dots never point at a page you cannot see yet. The Ranks button (which only said
  "needs the online update") is hidden until that update exists.
- The table is unlocks.gd; moving a system earlier or later is one number.

Update 3: the fun pass, part two: SOUND. The game had none. There is still no sound pack, so
every sound is made by code (short synthesized blips, thumps and chimes) and plays through a
small pool of players; the day a real sound file is dropped into sfx/<name>.ogg it is used
instead. What has a sound now: your shots (soft, so they never tire), turret shots, every hit,
every kill (a thump; the boss a big one), gems and coins (each quick pickup a note higher), the
card pick opening and the pick itself, a run level, shield and hull damage, losing a heart, each
new wave, the boss arriving, Stage Cleared and Game Over, menu taps on every button, gear
upgrades, merges, Store purchases and chest opens, quest claims. Settings > Sound effects and
the pause menu's Sound button switch it off. Music is still "coming". The list of sounds in
sfx.gd is the shopping list for a sound pack.

Update 4: the fun pass, part three: SEE IT COMING. A Spitter now telegraphs every spit: a
third of a second before the glob, its sac flashes, a ring closes on its mouth and a short
rising "charge" sound plays, so dodging is a decision you can make instead of luck (the
Archero rule: every attack is announced). Dev: tools/dev/capture.gd CAP_AUTOPICK=1 lets a
battle movie play on by itself (it takes the first card at every pick).

## dev167: your playtest, round one (the quick fixes)

- TURRETS PAGE WAS EMPTY: a bug of mine from dev149 (the card depth layer took the spot the
  turret tiles looked for), so the whole page aborted before drawing a tile. Fixed; the mounts
  and the six turrets are back.
- THE WEAPON WAS INVISIBLE ON THE GEAR PAGE: a bug of mine from dev158 (the gun fades out at
  the exact middle of a turn, and the Gear showcase stands at that angle). Fixed: the equipped
  weapon shows in his hand again. Note: by design the other pieces show on him only as accents
  (visor and helmet lights take the helmet set's colour, the chest orb the chest set's; bolts
  take the weapon set's colour). Full armour swaps need Luna to paint each set on the pilot.
- TIPS ARE OFF. The code stays for a later, lighter version for new elements only.
- ELITE is its own ladder: it starts at Elite stage 1 and each win opens the next Elite
  stage; Standard wins no longer unlock Elite stages. On Home, Elite tints the world purple
  and the stage name sits in a frame coloured by the mode.
- PROMOTION is harder and worth more: recommended levels 10, 13, 16, 19, 22, 25, 28, 31, 34,
  37, a trial opens at its level (no early tries), bugs much tougher (Cadet x3.4 health, half
  again as many), and each rank now gives +6% ATK and +6% base.
- PAUSE MENU: the YOUR CARDS row is gone (the HUD has the cards button).
- HOME CHEST: tapping the chest now opens a CHEST overlay (the Store's Supply Crate and Vault
  Chest, opened right there with crystals) and Luna's chest stays open until you close it.
- MENU SKIES: a shooting star now and then, slow dark asteroids drifting and turning.

## dev166: developer build for Rudy's test, and a last sweep

- Rudy chose to play this build as a new player, so the developer shortcuts are OFF in this
  zip (build_info.gd DEV = false; set it true to use them). Settings then has a DEVELOPER
  section with four buttons: Rich wallet (+500k coins, +20k crystals, 999
  Alloy, 500 Cells, 200 Cores, 999 power), Unlock everything (all 60 stages with 3 stars,
  pilot level 40, Commander suit, Elite, every turret and trial), Gear copies to merge
  (9 Common, 3 Uncommon, 3 Rare, 3 Epic of every piece you own: Quick Merge the small ones,
  merge the Epics by hand), and Fresh save (tap twice: a brand-new player, tips and all).
  Use Fresh save first to see things unlock in order, Unlock everything to see them all.
- Sweep: the Godot version in this file is now right (4.7.2), the menu wallpaper no longer
  shadows a built-in name, the balance simulator has a proper Elite switch, the dev tools
  are documented. Smoke test, headless stages and page captures all pass.
- Balance experiments (not applied): steeper bug health (1.065 / 1.03 a stage) made stage 40+
  a cliff; a gentler step with Elite at 1.35 still left Elite 30-60 unwinnable for the
  autopilot. Normal stays as it is for this test; your own feel decides the re-tune (16 g).

## dev165: repeat quests

- Quests has a fourth tab, REPEAT: five goals that come back bigger every time you claim
  them (destroy bugs, clear stages, collect gems, defeat bosses, pick power cards), each
  with a level, and a reward that grows a quarter per level. Always something small to
  chase. A fresh quest counts what you have done so far, so a veteran gets a welcome-back
  claim or two. Red dots cover the new tab.

## dev164: the boss's arrival reads on screen

- While the Hive Mother descends and cannot be hurt, a soft pulsing veil of light wraps her,
  and her health bar only slides in once she has settled and can be hit. So "my bolts do
  nothing" is visibly "she is not here yet", not a bug.
- Dev: tools/balance_sim.gd can try bug-health and Elite factors without editing the tables
  (SIM_HP_A, SIM_HP_B, SIM_ELITE), for the long-game re-tune (queue 16 g).

## dev163: guided first-time tips, and bosses cannot be hurt before they arrive

- GUIDED TIPS (Rudy's queue item 15): the first time something new is on screen the game
  dims, spotlights the one button to tap with a pulsing ring, and the chibi pilot explains it
  in a small glass box ("Tap the lit button"). Only that button works; "Got it" closes the tip
  without pressing. Each tip shows once, one per visit so new players are never buried.
  Tips so far: Patrol, the Stage Map, Elite (at pilot level 10), red dots, gear upgrades,
  saved kits, turrets, the drone, the Workshop, gear copies, Quick Merge, rank trials, the
  daily gift calendar, power cards. Settings > "Show the tips again" resets them.
- BOSSES (Rudy): the Hive Mother (and the young one mid-stage) cannot be damaged until she
  has fully descended to her hover height. Bolts pass through her, turrets, drones, Nova and
  splash do nothing to her, until she is on screen and acting.

## dev162: the Swarm Hive's hatch

- The Swarm Hive is drawn from Luna's parts: the hive with its hatch open, and the lid over
  the hole. The lid lies flat as the hive's top when idle; over the half second before a
  launch it flips up and over the back, stays open while the drones pour out, then closes.

## dev161: Luna's pilot turn frames and bug parts are in

- THE TURN IS REAL NOW (Rudy's question). Luna rendered five whole-body frames per suit
  (left three-quarter, eighth, front, eighth, right three-quarter; sources in art_src/turn,
  cut by tools/cut_turn.gd onto one shared canvas per suit so they stay aligned). When the
  pilot turns, the moving rig hands over to these frames and the code cross-fades through
  them over the 0.6 s turn, then hands back: a rotation, not a mirror. Sized and footed to
  the rig by measurement (feet match within 3 px). Rookie and Commander both.
- BUGS from Luna's parts: Scout, Drifter, Spitter and Diver are drawn as a clean body plus
  legs (one painted piece per bug, mirrored for the other side so both always match),
  feelers from the head, and the Spitter's sac full / empty. Legs paddle as they fly and
  tuck when a bug folds, feelers sway and trail behind a turn, the sac fills over the
  Spitter's cycle and empties on the spit. Wings as before. First placement; the hips and
  sizes are four numbers per bug in enemy_rig.gd (LEGS) to tune on a phone.
- Dev: tools/dev/bug_capture.gd draws the four bugs large to tune the parts.

## dev160: Luna's parts round 1 is in (chunks and drones first)

- Luna delivered everything in LUNA-BRIEF-animation-parts.md v2: 4 turret pieces, 22 bug
  pieces, 9 drone pieces (sources kept in art_src/parts_r1, cut by tools/cut_parts_r1.gd).
- Death shards are now her painted chunks: a killed bug breaks into its own shell, legs,
  wing halves and goo instead of square cuts of its body.
- The drone is drawn from her pieces: the hull banks into its motion, the two ring
  thrusters sit either side, tilt a beat behind the hull (follow-through) and the Scout's
  ring props spin. Striker and Warden use their thruster pairs.
- Not swapped yet: the Sentry head (Luna's "head without barrels" is a different angle from
  the Sentry in the game, so it would change its look; kept for a Sentry redo), the Swarm
  lid and the bug legs and feelers (next).

## dev159: Settings page with performance modes

- Home's menu button now opens SETTINGS (and shows the build number). The page has:
  - PERFORMANCE: Battery saver (30 fps, the engine rests between frames, lighter menu
    effects: fewer stars and motes, a still wallpaper, no button sheen, half the death
    shards), Balanced (60 fps, everything on; the default), Full throttle (no cap: 90 or
    120 on phones with those screens). Applied at once and remembered.
  - A frame counter switch: a small fps number in battle and on the Settings page, for
    testing on your phone.
  - SOUND: effects and music switches, greyed "coming with the sound pack".
  - GAME: a Stage Map shortcut. ABOUT: the build number (kept up to date by the build
    bump) and a line on resolution.

## dev158: the pilot's turn (Rudy: "is it a mirror flip?")

- Checked frame by frame with a new capture tool (tools/dev/turn_capture.gd). It was NOT an
  instant mirror, but close to one: the side pose narrowed like a card, Luna's front pose
  faded in, then the mirrored side pose faded back, with the gun jumping from raised to
  the hip and from one side to the other.
- Now: the HEAD turns first (the front helmet comes in while the body is still side-on, and
  on the way out the side helmet arrives before the body), the gun LOWERS to the hip as the
  turn starts (where the front pose holds it) and comes back up on the other side, the
  front pose is mirrored past the middle so the gun hand ends on the far side like a real
  turn (the gun fades across the middle instead of popping), the card-like squeeze is
  much softer, and the turn takes about 0.6 s instead of 0.5.
- It is still a cross-fade through one front picture, not a drawn rotation. The real thing
  needs Luna: LUNA-BRIEF-pilot-turn.md asks for five whole-body turn frames per suit (left
  three-quarter, eighth, front, eighth, right three-quarter), gun in a fixed ready pose, feet
  and helmet at the same heights. The code will cross-fade through them during the turn.

## dev157: menus flow (no more black cuts)

- Opening a page from Home no longer fades through black: the page rises and fades in over
  the world, and the page you leave sinks and fades out under it. Home itself fades back in
  the same way. Modes, Store, Quests and Gear all share the one transition.
- The battle's pause menu pops into place (slightly small and clear, then full) instead
  of appearing.

## dev156: hit feedback

- A bug flashes white for the blink it flinches when a bolt or turret hits it, so every
  hit lands visibly on the enemy.
- When the pilot loses a heart, a red flash rings the screen edge and fades over a third
  of a second (on top of his blink), so a hit is felt, not only counted.
- The card pick already animates (cards pop in one after another); the wave number already
  floats in at each wave. Nothing to add there.

## dev155: pilot motion pass

- The pilot's lean is a spring now: he tips into a drag, overshoots a touch and settles,
  so starting and stopping have weight. A slow weight shift while he hovers (hips drift,
  body rocks a little) so he never stands dead still.
- Jetpack flames flare up for a moment when he throttles up (a climb, a stop of a fall)
  before settling to the new power, and they trail behind a sideways move, swinging the
  opposite way to his lean.
- A sudden change of vertical speed squashes him slightly and he springs back (short and
  wide on a stop, stretched on a push), like a drawn character with weight.
- Checked headless on a stage and in captures; smoke test passes.

## dev154: the turrets' own light

- Every turret now glows with its own light: the glowing parts of Luna's turret pictures
  (crystal, vents, rods, orb, hatch rim) are cut out in code (tools/cut_turret_light.gd ->
  turrets/<name>_light.png) and drawn as light exactly over the turret: breathing while it
  waits, swelling as it charges, flashing when it fires. No Luna work needed, and it takes
  the light layers off her list for good.

## dev153: bugs stretch into their motion, turret heads overshoot

- A bug moving faster than its cruising speed (a Scout darting sideways, a Diver in its
  dive) stretches along the direction it moves and squeezes across it, like a drawn
  animation, and relaxes as it slows. Code only.
- The Sentry and Lance heads now swing to a new target on a damped spring: they arrive
  fast, overshoot a touch and settle, instead of easing in. The slow search sweep when
  nothing is in range is unchanged.

## dev152: Workshop > Gear shows what matters

- The lone Common base copy of every piece you own used to fill the inventory with "x1 ·
  Common" tiles once a few sets were open. They are hidden by default now: the list shows
  stacks you can merge and anything above Common. Filter > SHOW > Everything lists them
  all; the filter line says "lone Commons hidden" so nobody thinks pieces are missing.

## dev151: every glass panel lifts like the cards; Luna's parts brief, version 2

- Every glass panel in the game (Modes cards, Quests rows, detail panels, pop-ups) now has
  the same soft drop shadow as the item cards, so nothing sits flat on the wallpaper.
- Luna reported that her image generator reframes each piece to fill its own picture, so
  pieces cannot be stacked on one canvas. Fixed on our side: the brief is now "route 3",
  each piece as its own picture at roughly its true size, and the code places it (the way
  the pilot's 16 parts already work). Light layers are off her list: the glow is cut from
  the whole pictures in code. Order unchanged: turrets, bugs, drone.

## dev150: the same lift on every card

- The six gear slot squares around the pilot and the Store tiles (offers, chests, parts,
  packs, teasers) now carry the same depth as the item cards from dev149: drop shadow,
  top sheen, bottom shade, light rim, and a glow in the card's colour behind the picture.
  One shared routine in the UI kit, so every card in the game lifts the same way.

## dev149: turrets seated in their sockets, gear cards with depth (Rudy's two notes)

- TURRETS IN THE BASE: a mounted turret no longer sits on top of the strip like a sticker.
  The front half of its socket ring (cut from Luna's own strip) is drawn again in front of
  the turret's foot, so the foot sits down inside the ring, and a soft contact shadow pools
  under it. Same in battle and on Home. No new art.
- GEAR CARDS (and every item tile: Workshop stacks, turrets, drone parts): a soft drop
  shadow under the card, a sheen across its top, a shade along the bottom, a light rim on
  the top edge, and a glow in the card's colour behind the picture, so the piece looks lit
  and lifted instead of flat.

## dev148: the drone follows on a spring

- The drone no longer sits glued beside the pilot: it follows him on a spring, lagging a
  little when he moves, overshooting a touch and settling, bobbing on its own, and banking
  into its sideways motion with a slight squeeze (a 3D feel from a 2D picture). Stable at
  any frame rate (30 to 120).
- Checked headless on stage 12 with the drone active (no errors), smoke test passes.

## dev147: bugs flinch and shatter (first piece of the AAA motion work, no new art)

- A bug hit by a bolt or a turret shrinks for a tenth of a second and springs back, so every
  hit reads on the enemy, not only on the bullet.
- A killed Scout, Drifter, Spitter or Diver no longer pops: it breaks into six pieces cut
  from its own painted body, thrown outward from where each piece sat, tumbling and falling
  under gravity, fading in three quarters of a second. No new pictures: the pieces are cut
  from Luna's body art at run time. (Luna's chunk sheets in LUNA-BRIEF-animation-parts.md
  will replace these cuts with proper broken shell, wings and goo.)
- Checked headless on stages 3 and 12 (no errors), smoke test passes.

## dev146: what the game renders at, and the first efficiency cut

Rudy asked what the game runs at and how to make it lighter on phones.
- RESOLUTION: the layout is designed at 480 px wide, but the game DRAWS at the phone's own
  pixels (Godot stretch "canvas_items" + "expand"): a 1080 x 2340 phone renders 1080 x 2340,
  a 1440p phone 1440p. Every line and picture is sharp; nothing is upscaled. Phones are not
  4K, so "4K" does not apply.
- FRAME RATE: there is no cap and v-sync is on, so the game runs at the screen's refresh
  rate when the phone keeps up: 60 on a 60 Hz phone, 90 or 120 on those screens. A "full
  throttle" mode therefore mostly already exists; what a Settings page can add is a choice.
- RENDERER: GL Compatibility (the lightest Godot renderer, made for phones), textures
  compressed for phone GPUs (ETC2 / ASTC), linear filtering with mipmaps.
- SIZE: the game's own files are 37 MB before packaging (Luna's source renders, 32 MB, are
  not shipped). RAM on a phone is not measured yet; it needs a device (Luna's next APK).
- FIRST CUT: the frosted-glass blur behind menus (a 17-sample full-screen shader, every
  frame, at native resolution) is switched off: since dev145 the planet wallpaper covers it,
  so it was the most expensive thing in the menus for nothing visible.
- PLANNED (queue 27, with the Settings page): Battery saver (30 FPS cap, engine sleeps between
  frames in menus, fewer stars and motes, static wallpaper, no sheen), Balanced (60) and Full
  throttle (uncapped: 90 / 120 on phones that have it), plus sound on / off once sound exists.

## dev145: living wallpapers behind every menu, motion everywhere, a battle sweep

- Every menu page (Gear, Store, Quests, Modes) now sits on the SAME world as Home and
  battle: the current planet's painting, drifting slowly with a slight zoom, darkened so the
  glass panels read, stars twinkling, dust motes rising, a soft vignette (menu_backdrop.gd).
  No more flat dark pages: it all reads as one game.
- Motion: tiles, rows and cards rise and fade in one after another when a page or tab opens
  (UIKit.reveal); every gold main-action button gets a light sweep every few seconds
  (UIKit.sheen); buttons still squeeze when pressed.
- BATTLE SWEEP (autopilot, typical gear, 2 runs each): Normal stages 1-60 every fifth stage
  all won with the base never touched (hull 100 everywhere, 3 hearts lost only at 60). Elite
  10 and 20 won; Elite 30, 40, 50, 60 all lost by wave 3-4 even with the kit of a player five
  stages further on. Since dev127 the combat stats (crit, damage boost) and turret tracks
  made the player much stronger, so Normal is too easy mid-game and Elite is a wall from
  planet 3. This is queue item 16 g (the long-game re-tune), now with numbers.
- LUNA-BRIEF-animation-parts.md: the pieces Luna needs to render so the drone, turrets and
  bugs can be animated part by part (hulls, thrusters, barrels, lids, legs, feelers, light
  layers, death chunks). The pilot needs nothing new. Code plan: queue item 26.

## dev144: promotion trials tuned with the autopilot, recommended levels, faster cards

- Each rank now has its own difficulty (promotion.gd RANKS "hp" and "count"), set by running
  the "human" autopilot through every trial with the gear a typical player has there, and
  again with the gear of a player six stages further on. Target: a typical player loses most
  tries at the recommended level, a player a bit stronger wins most. Bug health on top of the
  stage's own scaling: Cadet x2.4, Pilot x2.6, Ace x1.9, Comet x2.05, Meteor x1.85, Nova x1.6,
  Pulsar x1.65, Quasar x1.6, Supernova x1.9, Singularity x1.75; bugs +30% early, +15% late.
  (The early stages are small, so they need the big multipliers; the late stages are already
  big.) Autopilot wins with a typical kit, 4 tries each: 4, 3, 2, 3, 1, 1, 2, 3, 2, 3; six
  stages stronger: 4, 4, 2, 1, 3, 4, 2, 3, 2, 1. The autopilot is noisy; Rudy's playtest decides.
- RECOMMENDED LEVEL on every trial (Rudy): Cadet Lv.4, Pilot 7, Ace 10, Comet 13, Meteor 16,
  Nova 19, Pulsar 22, Quasar 24, Supernova 27, Singularity 30 (pilot levels top out around 30
  by stage 60). A trial opens three levels under its recommendation, so you can try early.
  The card says "Next: Ace trial · recommended Lv.10" and the ladder shows each rank's level.
- Power cards come 25% faster inside a trial (run XP x1.25), so the run powers up while the
  bugs stay tanky: hard, but a good run.
- Dev: tools/balance_sim.gd takes SIM_PROMO=0-9 (trials by rank), SIM_KIT_PLUS=6 (a stronger
  player's kit), SIM_PROMO_HP / SIM_PROMO_COUNT (try a multiplier without editing the table).

## dev143: Promotion (rank trials)

- A new PROMOTION card on the Modes page: ten pilot ranks, each with its own trial. A trial
  is one hard stage of 10 waves built from a boss stage's waves (Cadet = stage 5, Pilot = 10,
  Ace = 15, Comet = 20, Meteor = 25, Nova = 30, Pulsar = 35, Quasar = 40, Supernova = 50,
  Singularity = 60): bugs much tougher than that stage and more of them (tuned per rank in
  dev144), and the boss at the end. Each trial has a recommended pilot level (dev144). It costs normal power tokens and can be retried.
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

## dev231: kill streaks, planet hazards, supply drops, a wingmate and the weekly event (four updates since dev227)

IN THE FIGHT
- KILL STREAK. Kills in quick succession build a streak (top right). Each point is 1% more coins
  from the bugs you kill, up to 50%. Getting hit, or going quiet for a couple of seconds, ends it.
- PLANET HAZARDS (from planet 2). Each planet has its own danger: falling scrap, eruptions, shard
  rain, lightning, a targeting laser. A circle lights up near the hero, closes, then lands. It
  hurts the hero if he is still inside, and the bugs inside it too, so you can lead them into it.
  Today every hazard is the same circle in a different colour.
- SUPPLY DROPS (from stage 6). At the start of every third wave a crate drifts down. Shoot it open
  and pick one of two: a shield patch, a card refresh, a medkit, a charged ability, coins, or
  sometimes a cursed offer (30% more damage for a quarter less hero health).

HEROES
- WINGMATE. Once you own a second hero, a Wingmate square shows under Loadout. The wingmate lends
  half his passive and fires his own ability by himself about once a minute. Tap the square to
  change him.

MODES
- WEEKLY EVENT (opens after stage 10). A themed week with its own pair of twists: Scrap Rush,
  Night Hunt, Iron Dome, Overdrive, in turn. Fights pay event points (30 for a clean win, 20 for a
  rough one, 5 for a loss) that fill a track of ten rewards. The track starts again each week.

WHAT I WOULD LIKE YOU TO TELL ME
- Do the hazards and runners feel fair or annoying? In my test a stage-30 run ended with the
  shield at 1%, which is the first time the base has been in danger.
- Is the wingmate's assist noticeable?
- IDEAS-2026-11-10.md in this folder lists what else could come; tell me what you like.

NOT CHECKED BY ME: none of this has been tapped by hand or seen on a phone. Each piece was run in a
real stage without a screen, and the test bot still wins stages 12 and 30.

## dev227: the Daily Challenge, the unlock moment and the collection book (three updates since dev224)

- DAILY CHALLENGE (Modes, second card; opens after stage 5). Your best cleared stage with bugs 15%
  tougher and three twists that change with the date (one advantage, two disadvantages). The first
  win of the day pays coins, 10 crystals and an Uncommon key. Replays pay only what you pick up.
  It gives no stars and opens no stages.
- THE UNLOCK MOMENT. When something new opens, it takes the whole screen: its picture in a ring of
  turning rays, the name, one line, a gold SHOW ME. The hero ability, AUTO, the Daily Challenge and
  the daily twists are announced this way too. On your save you will see those four once each, one
  per visit to Home.
- THE COLLECTION BOOK (Quests, the new Collection tab). Enemies met, heroes and turrets owned, power
  cards picked; the rest are dark shapes to find. Each category pays crystals at a quarter, half,
  three quarters and full (10 / 15 / 25 / 50). Your Cards page starts empty: until now the game
  counted how many cards you picked, not which.
- Home's next-goal line names today's challenge when it is waiting.

NOT CHECKED BY ME: whether the Daily Challenge can be won with two disadvantages (I ran it without a
screen: it loads, pays once, gives no stars), and nothing here has been on a phone.

## dev224: the fight needs you now, the Ascend ladder, and every screen in the clean look (ten updates since dev214)

WHAT TO TRY FIRST ON YOUR PHONE
- Play a stage WITHOUT touching AUTO. Lifting your finger no longer aims for you: he fires
  straight up, and you fly under what you want dead.
- Then tap AUTO (bottom right) and watch. It should play a little worse than you.
- Watch for a gold lane lighting up: a runner is about to come down it. Get under it.
- Press the round button at the bottom left when its ring is full: your hero's ability.
- Open Heroes, tap LEVEL UP and hold the gold button.
- Tell me: is it too easy, too hard, do the runners hit too hard or not enough, is AUTO too good.
  Each of those is one number for me to change.

THE FIGHT
- MANUAL and AUTO. Manual is the default. The AUTO button opens after stage 3; the autopilot aims
  and dodges for you at three quarters of the fire rate. A finger on the screen takes over at once.
  The test bot shows why: before, a phone lying on the table won the first 30 stages. Now nobody
  playing loses from stage 3 on, AUTO wins but gets hit, and a player by hand does best.
- RUNNERS (from stage 3). A small bug streaks straight down one lane for the base. A gold lane
  warns you a second before. Catch it: coins and a big gem. Miss it: it chips the shield.
- The shield mends a little (6%) after every wave you clear. This changes the old rule that
  nothing on the base comes back.
- HERO ABILITIES (after stage 2). One big move each, about every 40 seconds, faster for rarer heroes:
  Rook Volley, Sparks Overload, Frost Whiteout, Hollow Phase Storm, Nyx Execute, Ember Firestorm.
- DAILY TWISTS (from stage 11). A Standard stage carries one advantage and one disadvantage that
  change every day, and pays 20% more coins. Not on boss stages, Elite, Horde or the trials.
- Bugs are a touch tougher on stages 11 to 30 (about 20% by stage 30).
- The top bar is redrawn: no frame, bigger buttons with space between them, a wide HP bar, and the
  cards you hold on their own row. The whole battle is on the same two fonts as the menus.

HEROES
- THE ASCEND LADDER. Every hero climbs the same rarity ladder: Common, Uncommon, Rare, Epic,
  Legendary, then Mythic I to V. A rarer hero starts higher (Frost starts Uncommon, Hollow Rare,
  Nyx and Ember Epic), so a Common hero is never a dead end. The steps unlock things:
  Uncommon a stronger passive, Rare one more free card refresh every run, Epic he starts each run
  with his own card, Legendary the evolved look and a passive twice as strong, Mythic V three times.
- LEVEL UP opens its own sheet: Attack, Health and Defence as now and next, the next perk, the
  cost. Hold the button to keep levelling. At the level cap the sheet becomes ASCEND and shows what
  you have and what you need. Ascending plays a full-screen moment.
- The Evolve button and the shard line are gone from the Hero page (they live in the sheet).
- On your save: a hero you had already evolved keeps those steps on top of his new start.

HOME
- Under the stage: today's twist, and one line naming the next thing worth doing (an Ascend that
  is ready, a free chest, a level you can afford, or the next stage that unlocks something).
  Tap it and it takes you there.
- The nav bar is Luna's new animated icons on a glass pill with a sliding blue capsule.
- The PLAY button is the Reactor you picked (a turning ring of gold segments, the power cost on it).

THE OTHER PAGES
- Store: Offers, Shop, Crystals and Exchange now match the Chests tab (big flat squares; the Shop
  is split into Coins, Keys, Parts and Special instead of one long scroll).
- Turrets and Drone: rebuilt. Upgrades are buttons that carry their cost, so nothing clips onto a
  second line. Turrets and drones show the rarity names instead of stars and get the Ascend moment.
- Workshop: weapon copies as squares with the count on a badge; every craft recipe is one square
  you tap.
- Stage Map: on the game's fonts.

NOT CHECKED BY ME
- Nothing here has been on a phone. I checked pictures of every screen on the PC and ran the test
  bot, which is not a thumb.
- How a twisted stage plays is not measured (the test bot switches twists off so its numbers do
  not change with the date).
- REVIEW-2026-11-10.md in this folder has my full view of the game and the numbers behind it.

## dev214: the new look (your round-2 "clean" pick, built in four updates)

EVERYWHERE
- New fonts: Inter for text, Oxanium for titles, numbers and main buttons (bolder, easier to read).
  Both are free fonts; their licences are in the fonts folder.
- Flat style: flat cards, buttons with no dark bar underneath, one gold button for the main action,
  dark buttons for second actions, outlines for the rest. Tab strips are one pill: the open tab is
  white with its name, the others show only their icon.
- Nav bar: flat, icons only; the page you are on lights up its icon and shows its name. No box.
- The battle screen keeps its old style for now (its own pass comes later).

HOME
- Top bar: your hero's face with the level ring, then power (a green bolt, no hexagon), coins,
  crystals and the menu button (Settings, Stage Map). The profile pop-up has "Change picture".
- The stage name big at the top left, Standard / Elite and the arrows under it; the side buttons
  in one round column on the right; a big round gold PLAY above the nav.
- The Home battle plays small and dimmed far away over the horizon (no base platform).

PAGES
- Modes: one card per mode: Campaign, Elite Campaign, Promotion (the Challenge button is in its
  ladder), Trials, Horde (best wave and high score; the high score is saved from now on).
- Quests: the day's progress card on top (done / 5 and the chest), every task with a picture, its
  bar and its reward on the button (gold when ready). The Repeat tab is gone: those quests sit at
  the end of Career.
- Store, Chests tab: the daily gift strip on top (today's gift pulses in gold), big chest squares
  (keys held, pity bar, FREE / when it is back / price) and a key bundle. Tapping a chest slides
  up its panel: OPEN FREE, Open 1 or 10 with keys, Buy 1 or 10 with crystals (ten for the price
  of nine).
- Heroes: Talents and Stats squares on the right; one Loadout square under the weapon (tap = the
  next kit, hold = rename or save); no suit switch; the name, element, stars and grade centred,
  ATK and HP chips, the level bar and one big gold LEVEL UP with its cost; the roster as round
  portraits; dragging him only turns him a little left or right.
- Settings: real on/off switches; DEV MODE (unlock everything) is the first card.

NEXT: new nav icons (you said they do not fit the game), the Level Up screen and Ascend ladder,
the other Store tabs and the battle HUD in the same style.

## dev210: your dev209 playtest, batch 1 (gameplay and the broken bits)

Everything from your phone notes and screenshots that needed no style choice.

FIGHTING
- Ice and fire show ON the bugs. Slowed bugs turn icy blue with frost crystals on them; at full
  Deep Freeze a hit can freeze a bug solid for a moment (an ice block that can't move or shoot).
  Burning bugs glow red-orange with flames licking off them; from Afterburn level 2 the fire
  jumps to bugs they touch; at its overcharge a burning bug that dies leaves a burning patch that
  sets passing bugs alight.
- Bosses last much longer: big planet bosses 2.5x the health, shown as 8 layers on the bar;
  mini-bosses twice the health, 5 layers.
- Power cards come slower so each one matters: stage 5 now ends near level 5 (was 11), stage 20
  near 13 (was about 20). The autopilot still wins stages 5, 10, 20, 30 and 50.
- Card text: one short line for what THIS pick does ("3-bolt bursts", "Hits slow bugs 30%"), the
  level shown as NEW or Lv.2 in the rarity colour, the CHAIN line replaced by a small link badge
  in the corner, and nothing can spill outside the card any more.
- XP gems: no grey ring; a thin dark edge (still visible on blue worlds) and a little glitter.
- End of a stage: no more vacuum show. Coins still on screen are added at once, leftover gems
  vanish (cards reset anyway) and he flies off straight away. Between waves the pull stays.
- Bolts: the twisted "DNA" bolt (Burst Fire) and the pill bolts (Heavy Bolts) are gone. Burst
  Fire fires two thin bolts side by side; Heavy Bolts is Luna's bolt, bigger with a hot core.
- Variants show on the bug: Armoured = steel bands across its back that break off as it weakens;
  Shielded = an energy shell with a hex pattern; Booster = orange speed chevrons; Healer = a green
  cross. The first time you meet each one, the small NEW VARIANT card says what it does (no
  "kill it first").
- Turrets: the Lance is a mounted gun now (it pivots in its base, the beam leaves its muzzle, the
  base no longer vanishes as it turns), and every turret sits ON its base: no hovering heads, no
  bobbing, no Sentry energy field, in battle and on Home.

SCREENS
- Boxes wider than the phone fixed: Stage Cleared (drops are now picture tiles that wrap onto a
  second row), the Promotion card on Modes (buttons under the rank text), the Store tabs and the
  pack texts.
- Two-line buttons ("Level up / 90 coins", "Chart star 1 / 330 coins") no longer cut off; button
  text is centred on the coloured face, above the dark lip.
- The battle title now changes when you press Next stage (it used to keep stage 1's name).
- Pause menu: the damage list and the "leaving ends this run" line are gone; Back to Hub asks
  "Leave the stage? You will restart it from wave 1." The damage ranking (who did the most) is on
  the Stage Cleared screen.

FOR LUNA (sent separately)
- LUNA-BRIEF-3d-test.md + "Luna 3D test.zip": turn Rook and the Lance into 3D models with an
  image-to-3D tool, so Claude can photograph them from every angle for smooth turning and aiming.

STILL TO COME (batch 2, after you pick a style): fonts, buttons without the dark lip, big square
cards, the seamless tab strip, chest opening that shows the item, Patrol window, Hero page
(Loadout button, Level Up screen, Ascend ladder), star map, element wheel, nav highlight, top bar.

## dev209: Luna's star map art and Rook's five-star set, icons 3, and the Store art complete with chests that open as body, lid and burst (three updates since dev206)

Update 1: LUNA'S STAR MAP ART and ROOK'S FIVE-STAR REDO are in.
- The star map (Gear > TALENTS) now shows Luna's four constellation skies, each with its figure
  drawn as faint ghost lines (The Rifle, The Sentry, The Hive Mother, The Dome), and her star
  pieces: a dim star for one you have not charted, a bright one once charted (it takes the
  constellation's tint), a ringed one for the next star you can chart, and a planet-with-rings
  for the tenth star of each figure (the special one that gives a card). The code places the
  stars on the same frame she painted the lines in, so her figures pass through them. Her
  redone first sky (sent later the same night) is the one in use. Cutter: tools/cut_talents.gd.
- Rook at five stars: the new set in his own charcoal and purple (cape, crest, extra plating),
  eight turn frames and the portrait, shown on the Gear page, the roster tile and in battle.
  The second turn_4 she sent is kept as an alt. The white-and-gold set stays parked as his
  Ceremonial skin for the skin library later.
- Nothing else changed; smoke passes.

Update 2: LUNA'S ICONS 3 are in (all 24 usable).
- Fourteen material icons: the six essences (Energy Spark, Arc Charge, Frost Core, Void
  Fragment, Dark Ember, Solar Flare), the weapon line (Scrap Barrel, Focus Lens, Prime Coil),
  the drone line (Rotor, Gyro, Flight Core), the hero shard and an event token for the Exchange
  later. They show everywhere a material is named: the Workshop CRAFT tab, upgrade and star
  prices, the end-of-stage drops, Patrol. The hero panel's shard line uses the new shard.
- Ten card pictures: the six turret cards (Overdrive Node, Chain Coil, Deep Chill, Cluster
  Mines, Dread Mark, Shrapnel) and the four star-map cards (Focus Fire, Salvage, Second Wind,
  Mirror Shell) have their own art on the card instead of a borrowed turret or stat icon.
- Deep Chill was redone a few minutes later without the stray turret piece at the fan's base;
  the redo is the one on the card (the first is kept as pic_cryo_deep_v1).
- Cutter: tools/cut_icons3.gd. Luna has no open brief left except the last Store pieces.
- Also in this update: the first of the Store chest pieces, the Legendary chest BODY.

Update 3: LUNA'S STORE 2.0 ART IS COMPLETE (the last twelve pieces, all usable).
- The three key chests open for real now: Luna's chest body, its lid and its burst of light are
  three pictures painted in one frame, so the lid lifts off its hinge and tips back while the
  light pours out of the open chest, then it settles shut. Uncommon is the riveted steel box with
  a teal latch, Epic the armoured charcoal chest with a purple core window, Legendary the black-
  and-gold chest with the sun on its lid and gold specks floating round it.
- The Legendary lid first came as the whole closed chest (a box lifting off a box, as you saw);
  Luna then painted the lid on its own and that is the one in the game. The brief now says in
  plain words what a lid render is (a slab lying on black, no box under it) so the next chest
  comes right first time.
- Crystal piles: all five sizes are in (one crystal, a handful, a small pile, a big pile, the
  heap), and the Crystals tab now shows five crystal packs (x80, x300, x650, x1400, x3200) with
  the pile that matches each size. The prices there are placeholders until Google Play Billing;
  change them in store.gd PACKS.
- Luna has no open brief. Everything in LUNA-PROGRAM.md is delivered.

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
