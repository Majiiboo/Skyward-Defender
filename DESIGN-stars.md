# Stars: how heroes, turrets, drones and weapons grow (Rudy, 2026-11-06)

Rudy's rule: nothing is locked behind reaching a stage. Higher stars are locked behind
BUILDING the thing: level it to its cap, then collect for it, then evolve it to the next star,
which raises the cap again. Each star asks for more. After five gold stars comes the RED ladder
(red 1 to red 5), the endgame, balanced against endgame content (Elite, Horde, rank trials,
and more stages added later). Pilot level only opens the door to each star, so a new player
meets levelling first and stars second.

## The ladder
| star | gold 1 | gold 2 | gold 3 | gold 4 | gold 5 | red 1 | red 2 | red 3 | red 4 | red 5 |
|---|---|---|---|---|---|---|---|---|---|---|
| hero level cap | 10 | 20 | 30 | 40 | 50 | 60 | 70 | 80 | 90 | 100 |
| turret track cap (each of ATK / Rate / Range) | 4 | 8 | 12 | 16 | 20 | 24 | 28 | 32 | 36 | 40 |
| drone level cap | 2 | 4 | 6 | 8 | 10 | 12 | 14 | 16 | 18 | 20 |
| power step | - | +8% | +8% | +8% | +8% | +12% | +12% | +12% | +12% | +12% |
| pilot level door | - | 5 | 12 | 20 | 28 | 35 | 40 | 45 | 50 | 55 |

Weapons keep their own ladder: RARITY (Common .. Legendary = 1 to 5 stars) raised by merging
copies in the Workshop, which caps the weapon level 10 / 15 / 20 / 25 / 30. A red ladder for
weapons comes with the premium weapon packs (not built).

## What a star asks for (the item at its level cap, plus)
Hero (his own shards, his element's essence, coins; a Prime Coil from 5 stars):
| to | shards | essences | coins | extra |
|---|---|---|---|---|
| gold 2 | 5 | 2 | 2,000 | |
| gold 3 | 15 | 5 | 6,000 | |
| gold 4 | 40 | 10 | 15,000 | |
| gold 5 | 100 | 20 | 40,000 | 1 Prime Coil |
| red 1..5 | 150 / 200 / 300 / 400 / 500 | 30 / 40 / 50 / 60 / 80 | 60k / 90k / 130k / 170k / 220k | 2 / 3 / 4 / 5 / 6 Prime Coils |

Turret (its element's essence, coins; coils from 5 stars): essences 2 / 5 / 10 / 20, coins
1,500 / 4,000 / 10,000 / 25,000; red: essences 30 / 40 / 50 / 60 / 80, coils 2..6, coins 40k..150k.

Drone body (its element's essence, the drone line, coins): gold 2 = 2 essences + 2 Rotors +
1,500; gold 3 = 5 + 2 Gyros + 4,000; gold 4 = 10 + 1 Flight Core + 10,000; gold 5 = 20 + 2 Flight
Cores + 25,000; red: 30..80 essences, 3..7 Flight Cores, 40k..150k.

Where it comes from: hero shards drop on boss stages and Elite wins for the planet's strong hero
(battle), element trials pay shards and essences, chests roll essences of the selected planet,
Patrol trickles essences, the Workshop crafts essences and coils. Nothing new to paint: the shard
icon and the essence badges exist. Stars show as gold ★ on tiles and panels; red stars as red ★.

## Grades
A hero's grade (Common .. Mythic) stays what it was: the price class and the base strength he
arrives with. It is no longer shown as stars; the stars on a tile are the ones you earned.

## Balance (to do once red stars exist)
Red-star kits are 1.6x a five-star kit at the cap. Endgame content must grow with it: Elite 40-60,
Horde laps, rank trials Comet+, and more stages after 60 (StageData.MAX_STAGE). Re-run the sim
with a red-star kit before dev200 and retune TURRET_TUNE, StageData HP knobs and the trial hp.
