# Difficulty review, dev361 (2026-11-18)

About 400 fights (403; 72 lost, every one of them the base falling) played by the test player, on the game as it stands after "Menu decisions".
Nothing in the game was changed. Only the test player got two new switches.

"Shield low" below means the lowest the base shield got during a fight (100% = never touched,
0% = the shield was gone and the hull was taking hits). Unless it says otherwise, the test player
is the "human" one (steers by hand, a little clumsy) with a fair kit for that stage.

## What matters

1. **Your AUTO rule holds.** A player eight stages behind on his kit loses stage 20 every time:
   AUTO 0 wins of 9, by hand 0 of 9, the base falls in wave 3 to 5. At stage 30 the same weak kit
   wins about one fight in three. A kit only four stages behind wins stage 20 on AUTO 6 of 6, so
   the wall is real but it is narrow.

2. **Fights are decided in waves 3 to 6, then they are over.** Every single loss in this review was
   the base falling in waves 3 to 8. Not one hero died (his health never went under about two thirds with a
   fair kit), and nobody lost late. Once the third or fourth evolution is in, nothing threatens you.
   That is why "a bit harder" is hard to hit: a setting either leaves the shield mostly full or
   breaks the base early.

3. **AUTO is now the safer way to play the late stages.** At 45 and 60 AUTO keeps the shield at
   95% on average (15 of 15 won), the hand player 67 to 73%. That is the opposite of "never a free
   win on AUTO at higher stages".

4. **Cluster Storm is too strong, and Hunter Swarm is close behind at stage 45.** Cluster Storm as
   the ONLY evolution of a fight does better than the usual five or six evolutions together
   (shield low 94% at stage 45, against 73%). It does not end the fight faster; it simply stops
   anything reaching the base. Thunder Lance is fine: about as strong as Storm Volley.

5. **A drawing fault found on the way (not fixed, outside my brief):** the gold rod of Thunder Lance
   and the little hunters of Hunter Swarm are never drawn. The game reports an error every frame they
   should appear (they are drawn from the wrong layer: `_hevo_draw` is called from the top-bar
   drawing). The effects work, you just cannot see them. This matches the note "in captures only the
   shards were picked out".

## 1. Today, fair kit

| Stage | Player | Won | Shield low, average (worst) | Hull worst | Hero health lost | Most bugs on screen | Seconds |
|---|---|---|---|---|---|---|---|
| 8  | hand | 3 / 3 | 86% (75%) | 100 | 0   | 13 | 130 |
| 20 | hand | 9 / 9 | 36% (0%)  | 20  | 86  | 28 | 193 |
| 30 | hand | 9 / 9 | 48% (0%)  | 19  | 108 | 34 | 193 |
| 45 | hand | 9 / 9 | 73% (37%) | 100 | 99  | 39 | 139 |
| 60 | hand | 9 / 9 | 67% (0%)  | 100 | 174 | 54 | 159 |
| 20 | AUTO | 9 / 9 | 50% (0%)  | 100 | 70  | 27 | 194 |
| 30 | AUTO | 6 / 6 | 66% (20%) | 100 | 114 | 39 | 196 |
| 45 | AUTO | 9 / 9 | 95% (91%) | 100 | 109 | 34 | 137 |
| 60 | AUTO | 6 / 6 | 96% (92%) | 100 | 119 | 48 | 159 |

Stages 20 and 30 are where the pressure is. 45 and 60 are soft, as you thought. The hero is never
in danger anywhere: he loses about a tenth of his health at most.

Extra stages (4 to 8 fights each, by hand): 35 won 4 / 4, shield low 28%. 40 won 4 / 4, 74%.
49 won 6 / 6, 69%. **50 won 8 of 12, 16%.** 51 won 6 / 6, 37%. 55 won 4 / 4, 60%.
Stage 50 looks like a wall, but read "What I could not measure" first: the test kit is weak there.

## 2. The under-levelled player (a kit eight stages behind)

| Stage | Player | Won | How it ended |
|---|---|---|---|
| 20 | AUTO | 0 / 9 | base down in wave 4 to 6 |
| 20 | hand | 0 / 9 | base down in wave 3 to 4 |
| 30 | AUTO | 3 / 9 | base down in wave 4 to 6, or a win with the hull damaged |
| 30 | hand | 4 / 9 | base down in wave 3 to 6, or a win |
| 20, only four stages behind | AUTO | 6 / 6 | shield low 36%, hull worst 34 |

The kit eight behind at stage 20: hero Lv.10, weapon Lv.5, three buildings at Lv.2
(the fair one: hero Lv.20, weapon Lv.9, four buildings at Lv.3).

## 3. Making 45 to 60 bite (6 fights each, by hand, fair kit)

The crowd already grows after stage 30. "Crowd growth" below is how fast: today it doubles by
stage 60.

| Setting | Stage 45 | Stage 60 | Other stages |
|---|---|---|---|
| Today | 9 / 9, shield low 73% | 9 / 9, 67% | see above |
| More armoured and shielded bugs leading a wave (share 0.3 to 0.6) | 6 / 6, 74% | 6 / 6, 66% | no effect at all |
| Crowd growth a third faster (30 to 20) | 6 / 6, 81% | 6 / 6, 30% | 55: 5 / 6, 44%. 50: 2 / 6 |
| **Crowd growth twice as fast (30 to 15)** | **6 / 6, 58%** | **6 / 6, 53%** | **40: 6 / 6, 70%. 55: 6 / 6, 30%. 35: 5 / 6, 54%. 50: 2 / 6** |
| Crowd growth three times as fast (30 to 10) | 6 / 6, 49% | 4 / 6, 19% | 40: 3 / 4. 55: 2 / 4. 50: 0 / 4 |
| Crowd growth four times as fast (30 to 7) | 6 / 6, 46% | 0 / 6 | - |
| Bigger crowd at every stage (1.5 to 2.0) | 6 / 6, 27% | 5 / 6, 43% | not usable: it also hits stage 20, which is already tight |
| Twice as fast + bigger crowd (1.75) | 6 / 6, 62% | 2 / 6 | - |
| Twice as fast + more armoured leaders | 6 / 6, 65% | 5 / 6, 46% | - |

On AUTO, "twice as fast" still leaves the shield at 91% (stage 45) and 80% (stage 60), 12 of 12 won.
"Three times as fast" on AUTO: 69% and 37%, 12 of 12 won.

**Recommended: crowd growth twice as fast (the dial `CROWD_LATE` from 30 to 15), nothing else.**
It brings 45, 55 and 60 down to a shield low of 58%, 30% and 53% with every fight still won
(18 of 18), and puts up to 80 bugs on screen at stage 60 instead of 54. It does not reach your
25 to 50% at stage 45, and I would not push further: the next step up starts losing stages 40, 55
and 60 outright, because of finding 2. Leave the armoured leaders where they are; doubling them
changed nothing I could measure. Stage 50 needs a look on your phone before this goes in (see below).

## 4. The three new evolutions

The test player now has a switch to take one named evolution at its first evolution pick (after the
third hero card, about 15 to 20 seconds in, wave 2 or 3). To see each one by itself, these fights
allowed ONLY that one evolution. 6 fights each, by hand, fair kit. In every fight the evolution was
taken, between second 13 and 23, in wave 2 or 3.

| Only this evolution | Stage 30: won, shield low, hero health lost, seconds | Stage 45: won, shield low, hero health lost, seconds |
|---|---|---|
| None at all | 2 / 6, 0%, 74, - | 6 / 6, 46%, 134, 152 |
| Storm Volley (an older one, as a yardstick) | 5 / 6, 56%, 130, 184 | 6 / 6, 69%, 124, 145 |
| Thunder Lance | 6 / 6, 65%, 113, 200 | 6 / 6, 65%, 129, 147 |
| Hunter Swarm | 5 / 6, 32%, 146, 182 | 6 / 6, 90%, 139, 125 |
| **Cluster Storm** | **6 / 6, 82%, 85, 184** | **6 / 6, 94%, 96, 128** |
| For comparison: the usual five or six evolutions | 9 / 9, 48%, 108, 193 | 9 / 9, 73%, 99, 139 |

Plainly:
- **Cluster Storm trivialises the base defence.** One card, taken 17 seconds in, and the shield never
  drops under 64% at stage 30 or 86% at stage 45. The most bugs on screen falls from about 35 to 24:
  it clears the screen. It also costs the hero the least health.
- **Hunter Swarm** is ordinary at stage 30 and nearly as strong as Cluster Storm at stage 45
  (and the fight is 20 seconds shorter). It seems to grow with the size of the crowd.
- **Thunder Lance** sits level with Storm Volley. Leave it.
- Stage 30 **without any evolution** is lost four times in six. Evolutions are no longer a bonus
  there; the stage counts on them.

A second set with all the other evolutions allowed as well (3 fights each) says the same, only
blurred: with five or six evolutions in every fight, one more or less hardly shows.

## What I could not measure

- **The test kit dips at stage 50.** It rebuilds its kit for every stage, and at 50 the last hero
  ascend swallows the coins: weapon Lv.12 and buildings Lv.4 at stage 50, against weapon Lv.22 and
  buildings Lv.6 at stage 49. A real player never loses weapon levels. So the stage 50 losses
  (and part of 51 to 60) are at least partly the test player's fault, not the game's. This should
  be fixed in the test player before stage 50 is tuned.
- **Six fights a setting is thin.** The same stage gave a shield low of 40% in one set of three and
  81% in the next set of six (stage 60). Treat differences under about 20 points as noise.
- Only Rook with his pistol. Other heroes and weapon classes were not run.
- Stage 30 on AUTO with a fair kit got 6 fights; stages 35 to 55 were only played by hand.
- The evolutions were measured for the base and the hero's health, not for how they look or feel.
  The test player dodges nearly every shot, so "hero health lost" is always on the low side.
- Nothing here was on a phone.

## Note on how the runs were done

Each test run got its own save folder (the save folder is fixed when the game starts, so several
could run side by side without sharing a save). The real save was never touched.
