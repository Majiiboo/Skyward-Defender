# Why AUTO was safer than playing by hand late, and the fix (2026-11-18)

About 250 test fights. "Shield low" = the lowest the base shield got in a fight (100% = never touched).
"Hand" is the test player that steers by hand, a little clumsy. Every fight uses a fair kit for its stage
unless it says otherwise.

## What was wrong

AUTO was meant to fire at three quarters of the hand rate. But every hero level also carries a hidden
"auto fire +1%" bonus that only AUTO uses. So AUTO's real fire rate grew with the hero:

| Hero level (stage) | AUTO's fire rate, compared with by hand |
|---|---|
| Lv.7 (stage 8) | 80% |
| Lv.20 (stage 20) | 89% |
| Lv.40 (stage 45) | 104% |
| Lv.50 (stage 60) | 112% |

So late in the game AUTO fired FASTER than a player, and on top of that every AUTO shot is aimed at a bug
anywhere on screen, while by hand you only hit what is above you. In a big crowd that is a lot.

The proof: switching that hidden bonus off, and nothing else, took AUTO from far above the hand player to
just under him (stage 45: 92% down to 62%; stage 60: 85% down to 52%; the hand player has 70% and 59%).

It is not mainly the test player being clumsy: a "perfect reflexes" hand player only reaches 81% and 63%,
still under the old AUTO.

Two other ideas I tried and did not use: AUTO only aiming in a cone above the hero (it lost stage 60 outright
in one of three), and simply cutting AUTO's fire rate everywhere (it would hurt stages 20 and 30, which are
already tight).

## What I changed (only AUTO; playing by hand is untouched)

1. The hidden level bonus no longer counts for AUTO (`AUTO_LEVEL` 1 -> 0). AUTO fires at 75% at every hero level.
2. After stage 30 AUTO's share slides down a little more, to 65% from stage 45 on (`AUTO_LATE` 0.65),
   because the crowd grows after stage 30 and aimed fire is worth more in a crowd.

Dials for the test player: `SIM_AUTO_FIRE`, `SIM_AUTO_LATE`, `SIM_AUTO_LEVEL`, and `SIM_AUTO_CONE`
(the cone idea: built, switched off).

## Before and after

| Stage | Hand: won, shield low | AUTO before: won, shield low | AUTO after: won, shield low |
|---|---|---|---|
| 5  | - | - | 6 / 6, 97% |
| 8  | 3 / 3, 81% | 3 / 3, 92% | 10 / 10, 84% |
| 12 | - | - | 6 / 6, 47% |
| 20 | 3 / 3, 34% | 3 / 3, 79% | 12 / 12, 45% |
| 30 | 5 / 6, 31% | 6 / 6, 64% | 5 / 6, 52% |
| 38 | 3 / 4, 55% | - | 3 / 4, 40% |
| 45 | 9 / 9, 70% | 9 / 9, 92% | 8 / 8, 57% |
| 60 | 8 / 9, 59% | 9 / 9, 85% | 6 / 8, 26% |

So AUTO now ends 13 points under the hand player at stage 45 and 33 under at stage 60, still winning
45 every time and 60 three times in four. Early stages are still won every time.

The under-levelled rule (a kit eight stages behind, AUTO, stage 20): 2 won of 16 after the change, both
with the shield at 0% and the hull damaged; the other 14 lost the base. With the old AUTO: 0 of 5 here
(0 of 9 in the last review). AUTO only got weaker, so I read the two wins as luck, but it is not the
clean "always loses" of before: worth a second look.

## Things to know

- The numbers jump around a lot from fight to fight. The same setting gave 62% in one set of six and 27%
  in the next (stage 20). Trust the direction, not the last digit.
- Stage 60 sits near an edge: a little less AUTO fire and it starts losing more than it wins
  (50% share: 2 of 6 won). If AUTO feels too weak there on your phone, raise `AUTO_LATE` toward 0.70.
- Stage 30 is tight for both players (each lost 1 of 6). AUTO at 30 lost the level bonus too
  (97% -> 75% of the hand rate); it lost one fight there where the old AUTO lost none.
- Stage 50 (the boss) is lost by BOTH players, 0 of 4 each. That is not from this change; it is the
  stage-50 wall the last review warned about, now with the faster crowd.
- A hero's "auto fire" number still exists in the hero data; it just does nothing now.

## What I did not measure

- A real person. The hand player is a robot; you on your phone are the real test.
- Stages between the ones in the table, Elite, Horde, trials, Boss Rush, the Expedition.
- Other heroes and weapons: every fight used the test kit's hero and pistol.
- Whether AUTO with a kit a few stages AHEAD still wins comfortably late (it should; not run).
