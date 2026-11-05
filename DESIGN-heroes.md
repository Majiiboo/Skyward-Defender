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

## Grades and buying (Rudy, 2026-11-05, second pass)
Heroes are not handed out by stage. They are RATED by a star grade and BOUGHT:
- Grades: 1★ Common, 2★ Uncommon, 3★ Epic, 4★ Legendary, 5★ Mythic (next-level designs,
  later). A higher grade starts stronger (base x1.0 / 1.06 / 1.13 / 1.2 / 1.3).
- Price: coins + parts (Rudy's "elements": Alloy, Cells, Cores), all needed; or the whole
  price in crystals; real-money packs with Store 2.0. A few heroes also need a stage cleared
  first ("some can be like that"); later, some can need an objective or a mission instead.
- The Heroes page: the hero BIG, front and centre on his platform; under him his panel
  (name, grade stars, element, passive, Level up, tier + Evolve, or the price + Unlock); then
  the roster as one scrolling row per grade, locked heroes dimmed with what they need.
- Later per hero (Rudy): his own weapon variant and way of shooting, maybe his own movement
  and stance; a unique POWER CARD that only shows up for him in a run, and it BUILDS UP like
  every card: the first pick is its basic form, the second more of it, the third pick (the
  overcharge) is his max specialty, so it is earned in the run, not a legendary handed over
  (Cards "hero" key, offered only when he is on duty, like the turret cards); ATK and DEF as
  separate upgrades. DEF needs the pilot on HP instead of three hearts (like the base's
  shield and hull), so damage taken can be reduced by a defence stat: a gameplay change to
  plan on its own (hearts -> HP bar, hit damage per enemy, DEF % on the hero).
- Promotion, element ladders (Rudy): inside Promotion, a sub-menu per element where only a
  hero of that element may be used, each ladder with its own stages. Needs several owned
  heroes first.

## Roster depth (Rudy, 2026-11-05)
Variety is the point of elements. The target is at least TWO heroes, two drones and two
turrets per element over time, each with a different build, passive and role, so inside one
element the choice is about play style ("this Fire hero is bulky and tanks, that one is small
and crits"), never "the one Fire hero you must use". Pairs then balance each other: a glass
cannon hero with a Repair drone, a tank with a Magnet drone. New heroes come in grade batches
with Luna's art; the sixth element always gets its pair before a seventh element appears.

## The roster (six to start)
| Hero | Grade | Element | Price | Weapon | Passive | Who |
|---|---|---|---|---|---|---|
| Rook | 1★ | Energy | free (the starter) | Ion Pistol | Gem XP +15% | the chibi pilot we have (Rookie suit; Commander armour from stage 10) |
| Sparks | 1★ | Electric | 2,500 coins + 12 Alloy, or 60 crystals | Arc Welder | Coins +20% | a junkyard robot: barrel body, one big eye, stubby legs, two welder arms |
| Cpt. Frost | 2★ | Ice | 8,000 + 20 Alloy + 6 Cells, or 160 crystals | Frost Rifle | Shots chill | a penguin in a bulky white spacesuit with a fishbowl helmet |
| Hollow | 3★ | Void | 18,000 + 12 Cells + 2 Cores, or 320 crystals | Pulse Cannon | Every 5th bolt pierces | a see-through hooded astronaut ghost, cloak tatters instead of a flame |
| Nyx | 4★ | Dark | 40,000 + 20 Cells + 6 Cores, or 650 crystals; stage 20 first | Dread Railgun | Crit rate +5% | a cat-eared night huntress in black-and-red stealth armour |
| Ember | 4★ | Fire | 40,000 + 40 Alloy + 20 Cells + 6 Cores, or 650 crystals; stage 30 first | Sun Rifle | +1 heart | a small dragon-kin in a brass flight harness, fire breath for a thruster |

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
- TIERS (his evolved looks, Luna's three): tier 2 at 30 shards, tier 3 at 90; each tier
  ATK +8% and base +8%. (Stars are the GRADE, fixed; tiers are progression.)
- Shards come from boss and Elite wins on the planet the hero is strong on, Patrol on that
  planet, chests (Store 2.0), later events. Weapons keep dropping as copies.
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
