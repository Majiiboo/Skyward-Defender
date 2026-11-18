# Why the base falls early at stages 12, 20 and 30

Investigation of 2026-11-18. Nothing in the game was changed. About 520 simulated fights.

## The short answer

**No single enemy breaks the base. The hero simply cannot kill fast enough in waves 2 to 6, and the
base has no way to get those points back.**

- From wave 2 on, bugs arrive at a steady pace (three every 1.7 seconds) whatever the wave number.
  The hero starts every stage with no cards, so his weakest minutes meet the full stream.
- Every bug he does not kill reaches the dome and takes 10 to 15 points; every enemy shot that lands
  takes 8. The shield is about 100 points and no longer refills. One bug in five getting past for
  four waves is enough to empty it.
- Winning runs go through the very same dip (shield down to 10-45% by wave 8) and then recover once
  7 to 9 cards are in. Losing runs are the ones that kill 10 to 20% slower in waves 2 to 5.
  It is a knife edge, not a wall.

**Is it the game or the test player? Mostly the test set-up, but the game's margin is thin.**

1. **The test kit is out of date (the biggest factor).** It gives the hero a weapon at level 2-3 at
   stage 30. It still spends 40% of its coins on turrets, which no longer exist, and it counts
   weapon levels at twice their real price. With the weapon at level 10 (what those same coins
   buy at stage 30) the result goes from 5 wins in 32 to 10 in 12.
2. **The test player picks cards badly.** Its wish list predates the card rework. Smarter picks
   alone take stage 12 from 21 of 32 to 12 of 12.
3. **It is not the way the test player flies.** The in-game AUTO button collapses the same way
   (stage 30: 9 of 24). So a real player with a weak weapon who taps AUTO will see this too.
4. **The losses are more common than the small sweeps showed:** not one run in three, but one in
   three at stage 12, one in two at stage 20, and five in six at stage 30 with this kit.

## The numbers

Test player "human", auto kit, 24 runs per stage (a second batch of 8 gave the same picture).

### Stage 12 (hero Lv.7, weapon Lv.2) : won 15 of 24

| | Winning runs | Losing runs |
|---|---|---|
| Lost because | | base 6, hero 3, in waves 8-12 |
| Shield left after wave 4 | 63% | 51% |
| Shield left after wave 8 | 40% | 10% |
| Hull left after wave 8 | 98% | 42% |
| Bugs that got past in wave 3 | 16% | 28% |
| Base damage taken, waves 1-8 | 79 | 105 |
| Runners caught (of 2 a wave) | 1.5 | 1.0 |

Who did the damage in losing runs: bugs walking into the dome 46%, runners 21%, enemy shots 19%,
divers 11%, spores 3%.

### Stage 20 (hero Lv.12, weapon Lv.2) : won 10 of 24

| | Winning runs | Losing runs |
|---|---|---|
| Lost because | | base 8 (waves 5-9), hero 6 (waves 9-15) |
| Shield left after wave 4 | 44% | 25% |
| Shield left after wave 8 | 12% | 7% |
| Hull left after wave 8 | 89% | 45% |
| Bugs that got past in wave 5 | 7% | 20% |
| Base damage taken, waves 1-8 | 132 | 208 |

Who did the damage in losing runs: bugs walking into the dome 61%, enemy shots 19%, runners 9%,
divers 7%, spores and bolts 4%.

Stage 20 has a **second, separate problem**: 6 of the 14 losses are the hero dying late (waves 9 to
15, the Salvage Queen wave), after the base survived. His health never comes back now, and it runs
out. Even with everything else fixed, this one stays (see the what-if table).

### Stage 30 (hero Lv.18, weapon Lv.3) : won 2 of 24

| | Winning runs | Losing runs |
|---|---|---|
| Lost because | | base 22 of 22; 12 of them in waves 4-5 |
| Shield left after wave 2 | 70% | 58% |
| Shield left after wave 3 | 52% | 27% |
| Shield left after wave 4 | 45% | 5% |
| Bugs that got past in wave 4 | 12% | 29% |
| Base damage taken, waves 1-8 | 168 | 354 |
| Hero health when the base fell | | 85-95% (he is barely touched) |

Who did the damage in losing runs: bugs walking into the dome 57% (Cinder Flies the most, then Mites
and Crust Backs), enemy shots 25% (rivets, lava), divers 7%, runners 5%, coals and bolts 5%.

At stage 30 the gap is in plain arithmetic. Health arriving per second against what his gun can
deal if every shot landed (cards for damage and fire rate counted):

| Wave | Cards held | Bug health arriving | His gun at best | Really dealt | Bugs past him |
|---|---|---|---|---|---|
| 2 | 2 | 14.6 a second | 15.4 | 12.5 | 27% |
| 4 | 6 | 20.3 | 17.7 | 16.7 | 26% |
| 6 | 9 | 21.3 | 19.2 | 19.9 | 16% |
| 8 | 11 | 22.8 | 21.8 | 22.8 | 6% |

The same table at stage 12 shows room to spare (6 arriving, 8 to 10 possible), but about a third
of his fire misses or is wasted on a bug already dying, so the margin is gone there too.

### What changes the result (test player "human", 12 runs per stage)

| Change (test only, the game untouched) | Stage 12 | Stage 20 | Stage 30 |
|---|---|---|---|
| As it is today (32 runs) | 21 of 32 | 15 of 32 | 5 of 32 |
| In-game AUTO instead (24 runs) | 20 of 24 | 9 of 24 | 9 of 24 |
| Picks damage cards first | 12 of 12 | 8 | 5 |
| Flies lower, nearer the dome | 11 | 7 | 5 |
| Reacts twice as fast, never hesitates | 10 | 7 | 5 |
| All three of the above | 9 | 6 | 10 |
| Weapon at level 10 | 12 | 10 | 10 |
| The kit of a player ten stages further on | 12 | 12 | 12 |
| "Tougher bugs" dials of dev272 switched off | 11 | 11 | 2 |

Twelve runs is a small sample: read 5 against 7 as "about the same". In the "all three" row and
the weapon row, every stage-20 loss is the late hero death, not the base.

## The four questions

**1. What hits the base in waves 1-8?** Everything, in proportion to how common it is. Half or more
is ordinary bugs flying into the dome because nobody shot them. Enemy shots are a fifth to a third.
Runners matter at stage 12 (a fifth) and hardly later. Divers are under a tenth. The Wrecker's
shield drain never showed up in these waves, and planet hazards hit the hero, never the base.

**2. Is the test player doing something a real player would not?**
- Flying: no. It hunts a bug 85-90% of the time, dodges 3-5% of the time, uses the whole width of
  the screen, catches half to three quarters of the runners, and lets no XP gem expire. It never
  moves up or down (a player could sit lower and shoot a little longer), but that made no real
  difference when tried.
- Picking cards: yes. Its wish list is from before the rework. It puts Aegis, Shield Recharge and
  Reinforced Hull ahead of the new damage cards (Split Shot, Twin Trigger, Killer Instinct are not
  on the list at all, so when none of its old favourites is offered it takes the left card blind).
  And once it holds any card that can evolve, it keeps feeding that card, even Chain Spark or Drone
  Barrage on the first pick.

**3. Do losing runs differ early?** Yes, in the cards, not in the flying. Hero health and position
are the same in both groups. At stage 30, runs with a defensive or utility card among the first
three picks won 2 of 27; runs with none won 9 of 21 (both pilots together). At stage 12, runs whose first four picks were
all plain damage won 4 of 4 (human) and 3 of 3 (AUTO).

**4. Does it happen with AUTO?** Yes: 20 of 24, 9 of 24, 9 of 24. Same waves, same causes. AUTO
does a little better at 30 and loses the hero more at 20 (10 of its 15 losses).

## Options

**A. Bring the test kit up to date (my advice: do this first).**
Move the turret money to the weapon, charge the real weapon price, and give the test player a
card wish list that matches today's cards. Cost: under an hour, only `tools/balance_sim.gd`, no
game change. It tells us whether the game is in fact fine for a real player. Expect stage 30 near
10 of 12. One caution: weapon level 10 is right for stage 30; the fair level is about 4 at stage 12
and 7 at stage 20, and those two were not run.

**B. Guarantee firepower in the first picks of a stage.**
For example: the first two card offers of a stage always include one plain damage card, or each
stage starts with one damage card already held. Cost: a small rule in the card draw (the file the
card rework is in now) plus a re-sweep, about an hour. This is the test above that fixed stage 12
outright and helped 20 and 30. It also takes away the "bad first hand means a lost stage" feeling
without giving any healing back.

**C. Let the first waves of a stage arrive more slowly.**
Today wave 2 comes as fast as wave 12; only its length differs. Spacing the bugs out in waves 1-4
(say half as fast in wave 1-2, rising to full by wave 5) gives the cards time to arrive. Cost: one
small change in how bugs are released plus a re-sweep, about an hour; the risk is that openings feel
slow, and stages get 10-15 seconds longer. Worth doing only if a phone playtest with a fair weapon
still shows the early collapse.

**Not advised:** switching the "tougher bugs" dials off. It fixes 12 and 20 in the test but does
nothing at 30, and Rudy asked for tougher bugs.

**Separate, for later:** the hero dying at the stage-20 boss now that nothing heals him. That is a
question about hero health and Field Medic, not about the base.

## What was added to measure this

- `tools/balance_sim.gd` (kept, test-only): `SIM_WAVELOG=1` prints one line per wave (what arrived,
  kills, damage dealt, where he stood, shield, hull, hero health); what-if switches `SIM_PICK=dmg`,
  `SIM_LOW=n`, `SIM_SHARP=1`, `SIM_TOUGH=0`.
- `battle.gd`: a temporary counter of who hit the base, by wave. **Removed again**; the game file is
  as it was. The eight lines are kept as `tools/dev/base_damage_counter.patch` in case it is wanted
  again (`git apply` it, run, `git checkout battle.gd`).
- Not verified: no real phone play, only the two bots. The "gun at best" column leaves out Burst
  Fire, Chain Spark and piercing, so from wave 5 on it reads a little low.
