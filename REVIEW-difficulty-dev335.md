# How hard is dev335 for a player with a fair kit?

Measured on 2026-11-18 with the test player brought up to date. Nothing in the game was changed;
only `tools/balance_sim.gd`. About 740 simulated fights.

## The short answer

**With a fair kit the game is easy at every stage, for a manual player and for AUTO alike.**

- Manual won **98 of 98** fights, AUTO **97 of 98** (stages 5, 8, 12, 20, 30, 45, 60, 14 runs each).
- **The base was never in danger.** The hull was not touched once in those 196 fights. The shield's
  lowest point averaged 72-97%.
- **The hero is the only one who gets hurt**, and only in the middle of the game: at stages 12 to 30
  his health drops to about half, in the worst runs to a third. The single loss was AUTO losing
  the hero in the last wave of stage 30. From stage 45 on (Med Bay built) he stays above 80%.
- **The early base collapse of the last review was the test kit, not the game.** That kit carried
  a weapon at level 3 at stage 30. A stage pays about four times the coins the old test assumed,
  and at today's prices that buys weapon level 14 by stage 30.
- **How hard a stage is depends almost only on the kit.** The same test player with half the
  income loses one fight in three from stage 30; with a quarter he loses every fight from stage
  30 in under a minute. Between "walkover" and "wall" there is very little room.

## The table (fair kit, 14 runs per stage and pilot)

"Fair kit" = Rook with the pistol he comes with, having earned one and a half times the
first-clear income of the stages before (replays, lost fights, Patrol, daily rewards), spent
sensibly at the game's real prices.

| Stage | Kit the player has | Manual won | AUTO won | Shield lowest (average / worst run) | Hull lowest | Hero health lost | Hero health lowest (average / worst) | Evolutions taken | Stage length |
|---|---|---|---|---|---|---|---|---|---|
| 5 | Hero Lv.5, weapon Lv.2, no building yet | 14 of 14 | 14 of 14 | 85% / 68% | 100 | 0 to 6 points | 95% / 72% | 2 | 1 min 40 |
| 8 | Hero Lv.10, weapon Lv.3, Shield Generator 2 | 14 of 14 | 14 of 14 | 78% / 40% | 100 | 0 | 100% | 3 | 2 min 20 |
| 12 | Hero Lv.13 (Uncommon), weapon Lv.4, Shield Generator 2 | 14 of 14 | 14 of 14 | 83% / 48% | 100 | 54 manual, 75 AUTO | 62% / 38% | 3 | 2 min 55 |
| 20 | Hero Lv.22 (Rare), weapon Lv.6, Shield Generator 3, Repair Bay 3 | 14 of 14 | 14 of 14 | 88% / 56% | 100 | 93 manual, 123 AUTO | 64% / 35% | 5 | 5 min |
| 30 | Hero Lv.30 (Rare), weapon Lv.14, Shield Generator 5, Repair Bay 4, Armory 4 | 14 of 14 | **13 of 14** | 93% / 82% | 100 | 157 manual, 186 AUTO | 50% / 35% | 6 | 5 min 20 |
| 45 | Hero Lv.40 (Epic), weapon Lv.20, four buildings at Lv.5-6 | 14 of 14 | 14 of 14 | 95% / 89% | 100 | 176 manual, 233 AUTO | 88% / 81% | 6 | 4 min 25 |
| 60 | Hero Lv.50 (Legendary), weapon Lv.21, four buildings at Lv.6 | 14 of 14 | 14 of 14 | 96% / 91% | 100 | 288 manual, 392 AUTO | 87% / 78% | 6 | 6 min 35 |

Notes on the columns: shield and hero-health-lowest are both pilots together; "hero health lowest"
comes from 6 of the 14 runs (the measure was added between batches). Health lost can be more than
his health bar because the Med Bay gives some back after every wave.

## The same test player with a weaker kit (6 runs each)

| Stage | Income x1 (first clears only) | Half the income | A quarter of the income |
|---|---|---|---|
| | manual / AUTO | manual / AUTO | manual / AUTO |
| 12 | 6 / 6 | 6 / 6 | 6 / 5 |
| 20 | 6 / 6 | 6 / 5 | 4 / 2 |
| 30 | 6 / 6 | **4 / 5** | **0 / 0** |
| 45 | 6 / 6 | **4 / 3** | **0 / 0** |
| 60 | 6 / 6 | **4 / 5** | **0 / 0** |

- Income x1 at stage 30 = hero Lv.28, weapon Lv.8, three buildings at Lv.3: still every fight won,
  shield down to 67% on average.
- Half at stage 30 = hero Lv.19, weapon Lv.5: the winning runs end with the shield nearly gone; the
  losses are the base falling.
- A quarter at stage 30 = hero Lv.10, weapon Lv.5: this is close to the kit the last review tested.
  The base is gone in waves 2 to 4.

So a player who upgrades as he goes walks through; a player who has spent on the wrong things, or
not at all, meets a wall at stage 30. There is no stage where a properly equipped player has to
fight for it.

## What I tried, to see what would make it bite (fair kit, 6 runs each, stages 12 to 60)

| Change (test only) | Manual | AUTO | What moved |
|---|---|---|---|
| Evolutions half as often (every six hero cards) | 30 of 30 | 30 of 30 | Almost nothing |
| No evolutions at all | 30 of 30 | 30 of 30 | Hero health: AUTO down to 1% left in the worst runs at stages 20 and 30 |
| Bugs with more health: +32% at stage 20, +75% from stage 30 | 30 of 30 | 30 of 30 | Shield down to 11-17% in the worst runs at stages 20 and 30; nothing at 45 and 60 |
| Both of the above | 29 of 30 | 30 of 30 | One hero lost at stage 30 |
| Bugs with 2.2 times the health at stage 45, 2.7 times at 60 | 18 of 18 | 18 of 18 | Shield down to 71% in the worst run at stage 60 |
| Bugs with 2.5 times the health at stage 45, 3.6 times at 60 | 18 of 18 | 18 of 18 | Shield down to 41% in the worst run at stage 60 |

Two things stand out:

1. **Evolutions are not what makes the game easy.** They are just very frequent: the first one
   arrives about 20 seconds into a stage (wave 2 or 3), and by the end of a late stage the hero
   holds six, which is every evolution he has unlocked. Whether that feels special is a question
   of feel, not of difficulty.
2. **Bug health alone does not make it harder.** Even bugs three and a half times as tough at
   stage 60 only dent the shield. The hero's firepower grows faster than any sensible health
   number. (The same was found on 2026-11-10.) What does hurt him is being hit: hero health is
   the one number that moves.

## Where it is too easy, and where too hard

- **Too easy:** everywhere with a fair kit, and most of all from stage 45, where neither the base
  nor the hero is under any pressure. The base buildings have nothing to defend against: in a
  normal stage the hull is never reached.
- **About right:** stages 12 to 30 for the hero. He ends those stages on half his health, with no
  free healing, so a careless player can lose him. This is the only place where the "no free
  healing" rule is felt.
- **Too hard:** only for an under-equipped player, and then suddenly: stage 30 is the wall. That
  player gets no warning before it (stage 20 is still fine with half a kit).

## Options

**A. Change nothing for difficulty yet, and drop options B and C of the last review.**
Those two (a guaranteed damage card in the first picks, slower bug release in early waves) were
meant to stop the early base collapse. With a fair kit there is no collapse to stop, and both
would make an easy game easier. Cost: nothing. The phone playtest then tells whether a real
player is as well equipped as the test one. This is my advice for now.

**B. Bring the kit and the stages back together through prices or income.**
Coins now come in about four times as fast as when the prices were set (wave bounties, salvage
coins, longer stages). The "half the income" column is what a tighter economy plays like: stage
20 comfortable, stages 30 to 60 a real fight with the shield at zero by the end. Cost: one to two
hours (a handful of numbers for the wave bounty or for hero and weapon prices, then a re-sweep
with this test player). Risk: it is a narrow path. Half is tense, a quarter is unwinnable, so a
player who spends badly gets stuck sooner. Better done by deciding what kit a player should have
at stages 20, 30, 45 and 60 and pricing toward that, than by cutting coins across the board.

**C. Make the bugs hurt more instead of live longer (your "tougher bugs" plan).**
More health did nothing in the tests above. What would work is pressure the hero cannot
out-shoot: more shots at him, harder hits on the base from the bugs that do get through, more
runners, bosses that attack the base. Cost: design work and half a day of building and sweeps,
in `battle.gd`. It keeps the feeling of a strong kit and gives the base buildings and the
defensive cards a job, which matters now that buildings are about to become cards.

**D. (feel, not difficulty) Make evolutions rarer.**
One every four or five hero cards, or at most three in a stage, so each one is an event. Cost: one
number in `cards.gd` and a check. The tests say it will not change who wins.

## What the test player is now, and what it still assumes

Changed in `tools/balance_sim.gd`:

- **The kit** no longer buys turrets. It spends a measured income at the game's own prices: hero
  levels, the weapon in hand (with the parts each level needs), base buildings and their levels,
  and an ascend when the hero is at his level cap. It builds a new building as soon as a slot is
  free, and otherwise always buys the cheapest next step.
- **The card picks** know today's cards: his own signature evolution first, damage cards in the
  first picks of a stage, a healing or shield card when health or shield is low, otherwise spread
  over different cards.
- Every run prints what the stage paid (coins, parts, pilot XP), and the summary shows the shield,
  the hull, the hero's lowest health, the evolutions taken and how runs were lost.
- New what-if switches: `SIM_WEALTH` (how rich the player is), `SIM_BASE` (which buildings),
  `SIM_EVO_ONE_IN` and `SIM_EVO_MAX` (fewer evolutions). The old ones still work (`SIM_PICK`,
  `SIM_LOW`, `SIM_SHARP`, `SIM_TOUGH`, `SIM_WAVELOG`).
- The base part of the kit sits in three small functions (`_base_start`, `_base_options`,
  `_base_write`), so it is quick to adapt when buildings become cards.

Still assumed, not measured:

- The player has earned 1.5 times the first-clear income. With exactly the first-clear income
  the result is the same (every fight won), so this is not what decides it.
- The hero has the shards for his steps at stages 10, 20, 35 and 50 (as the old test assumed).
- Only Rook with his pistol was run. The drone stays at level 1 and no talents are bought, so
  the real player is, if anything, a little stronger still.
- Both test players dodge well and never tire. No phone play. A real thumb will lose more hero
  health than these numbers show, mostly at stages 12 to 30.
