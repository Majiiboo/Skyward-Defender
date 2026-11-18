# How hard is the game for a player with a fair kit?

Measured on 2026-11-18 with the test player brought up to date. First on dev335, then again on
**dev338** (buildings are cards built during the fight) after that change was merged in. The table
below is dev338; dev335 gave the same picture. Nothing in the game was changed by this work; only
`tools/balance_sim.gd`. About 1,200 simulated fights in all, 470 of them on dev338.

## The short answer

**With a fair kit the game is easy at every stage, for a manual player and for AUTO alike.**

- Manual won **84 of 84** fights and AUTO **84 of 84** (stages 5, 8, 12, 20, 30, 45, 60, 12 runs
  each, dev338). On dev335 it was 98 of 98 and 97 of 98.
- **The base was never in danger.** The hull was not touched once in those fights. The shield's
  lowest point averaged 78-97%.
- **The hero is the only one who gets hurt**, and only in the middle of the game: at stages 12 to 30
  his health drops to about half, in the worst runs to a fifth. From stage 45 on (Med Bay owned) he
  stays above 78%. Every loss seen with a fair kit, in any test, was the hero going down at stage 30.
- **The early base collapse of the last review was the test kit, not the game.** That kit carried
  a weapon at level 3 at stage 30. A stage pays about four times the coins the old test assumed,
  and at today's prices that buys weapon level 14 by stage 30.
- **How hard a stage is depends almost only on the kit.** The same test player with half the
  income wins most fights but ends them with the shield nearly gone; with a quarter he loses
  every fight from stage 30 in about a minute. Between "walkover" and "wall" there is little room.
- **Building the base during the fight did not make it harder.** The test player has every
  building he owns standing by wave 2 to 4, and placing one costs him no hero card.

## The table (dev338, fair kit, 12 runs per stage and pilot)

"Fair kit" = Rook with the pistol he comes with, having earned one and a half times the
first-clear income of the stages before (replays, lost fights, Patrol, daily rewards), spent
sensibly at the game's real prices. The buildings listed are the ones he OWNS; he builds them
during the fight from cards.

| Stage | Kit the player has | Manual won | AUTO won | Shield lowest (average / worst run) | Hull lowest | Hero health lost (manual / AUTO) | Hero health lowest (average / worst) | Hero evolutions | Buildings built / building evolutions | Stage length |
|---|---|---|---|---|---|---|---|---|---|---|
| 5 | Hero Lv.5, weapon Lv.2, no building yet | 12 of 12 | 12 of 12 | 85% / 63% | 100 | 0 / 8 | 96% / 72% | 2 | 0 / 0 | 1 min 40 |
| 8 | Hero Lv.10, weapon Lv.3, Shield Generator 2 | 12 of 12 | 12 of 12 | 81% / 55% | 100 | 0 / 3 | 99% / 76% | 3 | 1 / 0 | 2 min 20 |
| 12 | Hero Lv.13 (Uncommon), weapon Lv.4, Shield Generator 2 | 12 of 12 | 12 of 12 | 88% / 67% | 100 | 62 / 69 | 65% / 28% | 3 | 1 / 0 | 2 min 55 |
| 20 | Hero Lv.22 (Rare), weapon Lv.6, Shield Generator 3, Repair Bay 3 | 12 of 12 | 12 of 12 | 88% / 66% | 100 | 100 / 119 | 60% / 30% | 5 | 2 / 1 | 5 min |
| 30 | Hero Lv.30 (Rare), weapon Lv.14, Shield Generator 5, Repair Bay 4, Armory 4 | 12 of 12 | 12 of 12 | 92% / 82% | 100 | 119 / 179 | 50% / 19% | 5 | 3 / 2 | 5 min 20 |
| 45 | Hero Lv.40 (Epic), weapon Lv.20, four buildings at Lv.5-6 | 12 of 12 | 12 of 12 | 96% / 90% | 100 | 155 / 249 | 86% / 79% | 5 | 4 / 2 | 4 min 30 |
| 60 | Hero Lv.50 (Legendary), weapon Lv.21, four buildings at Lv.6 | 12 of 12 | 12 of 12 | 96% / 89% | 100 | 254 / 362 | 88% / 78% | 6 | 4 / 2 | 6 min 35 |

Notes on the columns: the shield and hero-health-lowest columns are both pilots together. Health
lost is in points and can be more than his health bar, because the Med Bay gives some back after
every wave. A late stage brings about 20 card picks, 6 or 7 of them building cards.

## The same test player with a weaker kit (dev338, 6 runs each, manual / AUTO wins)

| Stage | Income x1 (first clears only) | Half the income | A quarter of the income |
|---|---|---|---|
| 12 | 6 / 6 | 6 / 6 | 6 / 5 |
| 20 | 6 / 6 | 6 / **4** | **3 / 0** |
| 30 | 6 / 6 | 6 / **4** | **0 / 0** |
| 45 | 6 / 6 | 5 / 6 | **0 / 0** |
| 60 | 6 / 6 | 5 / **4** | **0 / 0** |

- Income x1 at stage 30 = hero Lv.28, weapon Lv.8, three buildings at Lv.3: every fight won,
  shield lowest 77% (manual), hull never touched.
- Half at stage 30 = hero Lv.19, weapon Lv.5: 52 of 60 won over the five stages, but the shield
  is down to 10-35% on average from stage 20, at zero in the worst runs, and the hull is reached.
  AUTO loses the hero at stages 20 and 30. This is the only column that plays like a fight.
- A quarter at stage 30 = hero Lv.10, weapon Lv.5, close to the kit the last review tested. The
  base is gone in the first waves, before most buildings are even placed.

So a player who upgrades as he goes walks through; a player who has spent on the wrong things, or
not at all, meets a wall between stages 20 and 30. No stage makes a properly equipped player
fight for it.

## What I tried, to see what would make it bite (fair kit, 6 runs each, stages 12 to 60)

| Change (test only) | Version | Manual | AUTO | What moved |
|---|---|---|---|---|
| No hero evolutions at all | dev338 | 29 of 30 | 29 of 30 | Hero health; each loss is the hero at stage 30 |
| Bugs with more health: +32% at stage 20, +75% at 30, 2.5 times at 45, 3.6 times at 60 | dev338 | 29 of 30 | 29 of 30 | Shield lowest 65-77% at stage 60; each loss is the hero at stage 30 |
| Hero evolutions half as often (every six hero cards) | dev335 | 30 of 30 | 30 of 30 | Almost nothing |
| No hero evolutions at all | dev335 | 30 of 30 | 30 of 30 | Hero health: AUTO down to 1% in the worst runs at stages 20 and 30 |
| Bugs +32% health at stage 20, +75% from 30 | dev335 | 30 of 30 | 30 of 30 | Shield down to 11-17% in the worst runs at 20 and 30; nothing at 45 and 60 |
| Both of the two above | dev335 | 29 of 30 | 30 of 30 | One hero lost at stage 30 |

Two things stand out:

1. **Evolutions are not what makes the game easy.** They are just very frequent: the first hero
   evolution arrives about 20 seconds into a stage (wave 2 or 3), and by the end of a late stage
   the hero holds five or six, which is nearly every one he has unlocked, plus two building
   evolutions. Whether that feels special is a question of feel, not of difficulty.
2. **Bug health alone does not make it harder.** Even bugs three and a half times as tough at
   stage 60 only dent the shield. The hero's firepower grows faster than any sensible health
   number. (The same was found on 2026-11-10.) What does hurt is the hero being hit: his health
   is the one number that moves, and stage 30 is where it runs out.

## Where it is too easy, and where too hard

- **Too easy:** everywhere with a fair kit, and most of all from stage 45, where neither the base
  nor the hero is under any pressure. The buildings have nothing to defend against: in a normal
  stage the hull is never reached, so defensive buildings and their evolutions are picked for
  nothing.
- **About right:** stages 12 to 30 for the hero. He ends those stages on half his health, with no
  free healing, so a careless player can lose him, most likely at stage 30. This is the only
  place where the "no free healing" rule is felt.
- **Too hard:** only for an under-equipped player, and then suddenly, between stages 20 and 30.

## Options

**A. Change nothing for difficulty yet, and drop options B and C of the last review.**
Those two (a guaranteed damage card in the first picks, slower bug release in early waves) were
meant to stop the early base collapse. With a fair kit there is no collapse to stop, and both
would make an easy game easier. Cost: nothing. The phone playtest then tells whether a real
player is as well equipped as the test one. This is my advice for now.

**B. Bring the kit and the stages back together through prices or income.**
Coins now come in about four times as fast as when the prices were set (wave bounties, salvage
coins, longer stages). The "half the income" column is what a tighter economy plays like: stage
12 comfortable, stages 20 to 60 a real fight that ends with the shield nearly gone. Cost: one to
two hours (a handful of numbers for the wave bounty or for hero and weapon prices, then a
re-sweep with this test player). Risk: it is a narrow path. Half is tense, a quarter is
unwinnable, so a player who spends badly gets stuck sooner. Better done by deciding what kit a
player should have at stages 20, 30, 45 and 60 and pricing toward that, than by cutting coins
across the board.

**C. Make the bugs hurt more instead of live longer (your "tougher bugs" plan).**
More health did nothing in the tests above. What would work is pressure the hero cannot
out-shoot: more shots at him, harder hits on the base from the bugs that do get through, more
runners, bosses that attack the base. Cost: design work and half a day of building and sweeps,
in `battle.gd`. It keeps the feeling of a strong kit and gives the buildings and the defensive
cards a job, which matters more now that building the base is part of the fight.

**D. (feel, not difficulty) Make evolutions rarer.**
One every four or five hero cards, or at most three in a stage, so each one is an event. Cost: one
number in `cards.gd` and a check. The tests say it will not change who wins.

## What the test player is now, and what it still assumes

Changed in `tools/balance_sim.gd`:

- **The kit** no longer buys turrets. It spends a measured income at the game's own prices: hero
  levels, the weapon in hand (with the parts each level needs), base buildings and their levels,
  and an ascend when the hero is at his level cap. It buys a new building as soon as a slot is
  free, and otherwise always buys the cheapest next step.
- **The card picks** know today's cards: a new building whenever one is offered (it costs no hero
  card), his own signature evolution first, damage cards in the first picks of a stage, a healing
  or shield card, building upgrade or building evolution when health, shield or hull is low,
  otherwise spread over different cards.
- Every run prints what the stage paid (coins, parts, pilot XP), and the summary shows the shield,
  the hull, the hero's lowest health, evolutions, buildings built and how runs were lost.
- New what-if switches: `SIM_WEALTH` (how rich the player is), `SIM_BASE` (which buildings he
  owns), `SIM_EVO_ONE_IN` and `SIM_EVO_MAX` (fewer hero evolutions). The old ones still work
  (`SIM_PICK`, `SIM_LOW`, `SIM_SHARP`, `SIM_TOUGH`, `SIM_WAVELOG`).
- The base part of the kit sits in three small functions (`_base_start`, `_base_options`,
  `_base_write`).

Still assumed, not measured:

- The player has earned 1.5 times the first-clear income. With exactly the first-clear income
  the result is the same (every fight won), so this is not what decides it.
- The hero has the shards for his steps at stages 10, 20, 35 and 50 (as the old test assumed).
- Only Rook with his pistol was run. The drone stays at level 1 and no talents are bought, so
  the real player is, if anything, a little stronger still.
- The income table was measured on dev335; dev338 did not change what a stage pays.
- Both test players dodge well and never tire. No phone play. A real thumb will lose more hero
  health than these numbers show, mostly at stages 12 to 30.
