# Heroes (replaces the six-slot gear) — design, 2026-11-05

Rudy's call (2026-11-05): instead of six armour slots, sets, rarities and merging, the
player collects HEROES: complete characters, each unique, each with an ELEMENT that is
strong or weak against enemy families. Baseline; we go deeper as we build.

## What a hero is
- A complete character Luna paints (reference, parts sheet, weapon, turn frames, portrait),
  so every hero looks different on the Heroes page, on Home and in battle. No mixing of
  parts, no armour that does not show.
- One ELEMENT (what he shoots; his bolts take its colour): Energy, Electric, Ice, Void,
  Dark, Fire. Element ids are the old set ids (ion, scavenger, frost, void, nightmare,
  solar) so every colour, weapon and thruster we already have carries over.
- A signature WEAPON (the six weapons we have, with their held art). The weapon stays the
  ONE gear slot: any owned weapon can be equipped, weapons keep rarity, copies and merging.
- A PASSIVE (one line), base stats, a LEVEL (coins) and STARS (shards).
- Three LOOKS: the base, an evolved look at 3 stars, the final look at 5 stars (Luna paints
  the base first; evolutions later).

## The roster (six to start; order = the planet that unlocks them)
| Hero | Element | Unlock | Weapon | Passive | Who |
|---|---|---|---|---|---|
| Rook | Energy | stage 1 | Ion Pistol | Gem XP +15% | the chibi pilot we have (Rookie suit; Commander armour from stage 10) |
| Sparks | Electric | stage 11 | Arc Welder | Coins +20% | a junkyard robot: barrel body, one big eye, stubby legs, two welder arms |
| Captain Frost | Ice | stage 21 | Frost Rifle | Shots chill | a penguin in a bulky white spacesuit with a fishbowl helmet |
| Hollow | Void | stage 31 | Pulse Cannon | Every 5th bolt pierces | a see-through hooded astronaut ghost, cloak tatters instead of a flame |
| Nyx | Dark | stage 41 | Dread Railgun | Crit rate +5% | a cat-eared night huntress in black-and-red stealth armour |
| Ember | Fire | stage 51 | Sun Rifle | +1 heart | a small dragon-kin in a brass flight harness, fire breath for a thruster |

## Elements vs enemy families
Until the enemy families exist (queue item 17), the PLANET is the family. Weak = x1.35
damage, resists = x0.75, never immune. Energy is neutral everywhere (the starter is never
the wrong pick).
| Planet / family | Weak to | Resists |
|---|---|---|
| 1 Hive insects | Fire | Ice |
| 2 Scrap machines | Electric | Void |
| 3 Magma creatures | Ice | Fire |
| 4 Crystal shards | Void | Electric |
| 5 Plasma beings | Dark | Ice |
| 6 Sentinel AI | Electric | Dark |
Each planet unlocks the hero that is strong on it (Scrap Belt opens Sparks). Home shows the
selected stage's weakness next to the stage name so the choice is visible before Play.
Turret "strong vs" traits stay as they are for now; later they can become elements too.

## Numbers
- Level 1-60, cost 60 + 30 x level coins a step. Per level: ATK +3%, fire rate +1%,
  aim +1.5%, recovery +2%, magnet +2 px, auto-fire +1%. (The old five armour slots added
  up to about the same at matching spend.)
- Milestones every 5 levels, rotating: crit rate, crit damage, damage boost, base damage
  taken, fortress HP, a heart at 10 and 30.
- Stars 0-5 from SHARDS: 10, 20, 40, 80, 160. Each star: ATK +4% and base shield/hull +4%;
  3 stars = evolved look, 5 = final look.
- Shards come from boss and Elite wins on the hero's planet, Patrol on that planet, chests
  (Store 2.0), later events. Weapons keep dropping as copies.
- The weapon's own level (ATK +6% a level, rarity caps) stays as it is.

## What changes on the pages
- Gear tab becomes HEROES: roster row (six portraits, locked ones say their stage), the
  hero on his platform, name + element + passive, LEVEL UP, stars + shards + EVOLVE, the
  weapon tile with its CHOOSE list (weapons only) and Upgrade. Turrets, Drone and Workshop
  tabs stay. Workshop > Gear shows weapons only.
- Loadouts save the hero too.
- Home: hero's name and element under the pilot block; stage weakness by the stage name.
- Battle: hero stats in, element multiplier on his bolts, bolts in the element colour,
  "WEAK" / "RESIST" shown on the hit numbers.

## Old saves
Nothing is lost. Coins spent on the five armour pieces become Rook's level (same coins, the
new cost table). Armour copies become Rook shards (Common 1, Uncommon 3, Rare 9, Epic 27,
Legendary 81, their merge value). The weapon keeps its level, rarity and copies. The old
gear block stays in the save untouched, so this can be undone.

## Build order
1. heroes.gd: roster, elements, stats, migration, smoke checks. Battle reads hero stats +
   element. Rig: non-painted heroes use the Commander rig with their element colours and
   their weapon until Luna's art arrives (so the system is playable now).
2. Heroes page. Home line. Drops (shards). Loadouts with hero.
3. Luna: LUNA-BRIEF-heroes.md (Sparks first, then Captain Frost). Code places each hero's
   parts like the pilot's; turn frames per hero.
4. Later: per-hero evolutions, a hero on the Stage Map next to the planet weakness, Store
   2.0 chests with shards, hero trials in Promotion (one enemy family per trial, Rudy).
