# Skybound Defender — source package for Rudy

This is the full Godot project for the game you have been playtesting.
Build 1.0-dev108 (version/code=108 and version/name="1.0-dev108" in export_presets.cfg). The phone installs over an existing app only if the version code is HIGHER than the installed one and the APK is signed with the same key. Each pushed update now raises the build by one.
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
