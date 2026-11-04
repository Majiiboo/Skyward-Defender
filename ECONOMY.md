# Coin economy (dev109 snapshot)

What a player earns in coins, measured from the real wave lists in `stage_data.gd`, next to what things cost. Rudy asked for this so store, Gear and turret prices can be set sensibly as the game grows. Re-run the numbers after changing waves or coin values. (Script: `tools/econ.gd`. It sums `ENEMIES.coins` × count over `waves(stage)`.)

## Where coins come from today
- **Bugs drop coin pickups** (since dev108), which fly to the pilot at the end of every wave:
  - Scout: 1
  - Drifter: 1
  - Spitter: 2
  - Diver: 2
  - Spore pod: 0
- **Hive Mother:** 40, as 10 big coins. Each of her hatchlings is a Scout worth 1 more (not counted below).
- **Scavenger set:** +4% per piece, +20% with 3 pieces.
- **Outside battle:**
  - Daily gift: 150 coins.
  - Missions and trophies.
  - Store: Coin Pouch 600 and Coin Chest 2,000, both bought with crystals.

There is **no stage-clear coin bonus**: what you pick up is what you get.

## Coins per stage (first clear, every pickup collected, no set bonus)

| Stage | Waves | Coins per wave (min to max) | Boss | Stage total | Total so far |
|---|---|---|---|---|---|
| 1 | 5 | 3 to 7 | - | 25 | 25 |
| 2 | 5 | 5 to 11 | - | 42 | 67 |
| 3 | 5 | 4 to 13 | - | 43 | 110 |
| 5 | 5 | 5 to 56 | 40 | 96 | 257 |
| 6 | 8 | 5 to 23 | - | 119 | 376 |
| 10 | 8 | 6 to 67 | 40 | 188 | 964 |
| 11 | 10 | 6 to 33 | - | 222 | 1186 |
| 15 | 10 | 7 to 75 | 40 | 281 | 2171 |
| 20 | 12 | 8 to 84 | 40 | 404 | 3964 |
| 25 | 10 | 10 to 86 | 40 | 379 | 5631 |
| 30 | 12 | 11 to 92 | 40 | 491 | 7970 |
| 40 | 12 | 13 to 100 | 40 | 577 | 12816 |
| 50 | 12 | 16 to 111 | 40 | 697 | 18548 |
| 60 | 12 | 18 to 118 | 40 | 772 | 25108 |

The biggest wave per stage is the boss wave on stages 5, 10, 15 and so on.

## What things cost today

| Item | Cost | Max level |
|---|---|---|
| Gear piece upgrade (Lv.N to N+1) | 120 × N | Lv.10 |
| One gear piece, Lv.1 to 10 | 5,400 | |
| A full set of 6 pieces to Lv.10 | 32,400 | |
| Turret upgrade (Lv.N to N+1) | 150 × N | Lv.10 |
| One turret, Lv.1 to 10 | 6,750 | |
| All 6 turrets to Lv.10 | 40,500 | |

## What this means
- **By stage 10** a player has earned about **1,000 coins**: a few early gear levels and a turret level or two. That's about right for the start.
- **By stage 30**, about **8,000**; **by stage 60**, about **25,000**. Maxing one set plus all turrets costs about **73,000**, so replays, Elite, missions and the store have to make up the rest.
- That gap is normal for this kind of game. Still, first clears should feel more rewarding later on.

## Suggestions (not built yet, for Rudy to decide)
1. **A stage-clear coin bonus** of 20 + 10 × stage (stage 10: 120; stage 60: 620). That adds about 19,000 over the campaign.
2. **Boss coins that grow with the planet:** 40 × planet number (planet 6 boss: 240).
3. **Replays pay half** of the first-clear coins, so farming works but doesn't replace progress.
4. **Early costs stay as they are.** Later, make the steps from Lv.6 to Lv.10 steeper and add crystals as a second cost for the top levels.

## Upgrade parts (dev115)
Higher upgrade levels also need parts (`parts.gd`). Crystals can stand in for missing parts: Alloy 2, Cell 6, Core 15 crystals each.

| Upgrade | Coins | Parts |
|---|---|---|
| Lv.1 to 4 | coins only | none |
| Lv.4 to 5 | coins | 3 Alloy |
| Lv.5 to 6 | coins | 6 Alloy |
| Lv.6 to 7 | coins | 9 Alloy + 1 Cell |
| Lv.7 to 8 | coins | 12 Alloy + 2 Cells |
| Lv.8 to 9 | coins | 15 Alloy + 3 Cells + 1 Core |
| Lv.9 to 10 | coins | 18 Alloy + 4 Cells + 2 Cores |

Where parts come from:
- **Alloy Scrap:**
  - Bugs drop it now and then: about 2.5% per kill, rising on later stages.
  - A stage clear gives 2, plus 1 per 10 stages.
- **Plasma Cell:**
  - A young Hive Mother drops 1, and a boss drops 2.
  - Every 5th stage clear gives 1.
  - From stage 21, regular bugs drop them rarely.
- **Void Core:** a boss on stage 20 or later (35–60% chance). Boss Rush will be the main source once it's built.
- **Elite:** every drop is doubled, and bugs can drop Cells on any stage.

Autopilot sample: stages 10 and 22 together gave 18 Alloy and 4 Cells.
