# Luna brief: HOME round 2 (planet skies in layers, the base dome as its own piece)

Hi Luna! This brief has everything you need; no earlier brief or message is required.

## What this is for
Home, the menus and the battle all stand in front of your planet paintings
(`backdrops/hive_a.webp`, `hive_b`, `scrap`, `magma`, `crystal`, `plasma`, `sentinel`). They
are one flat picture each, so the sky cannot move. Rudy wants the sky ALIVE: stars that slide
slower than the clouds, a planet that drifts, pieces that float past. The code does that when
each sky comes as LAYERS. And the base's command dome will change with the super weapon the
player equips, so the dome must become its own piece on the base strip.

## Part A: one planet sky as layers (start with the Hive world, then the Scrap Belt)
Match the colours and feel of your own painting of that planet. The pilot and the bugs fly
in the middle of the screen, so the MIDDLE and LOWER MIDDLE of the sky must stay DARK and
CALM: nothing bright or busy there. Interesting things near the top and the sides, the
planet at the bottom. No text, no characters, no enemies, light from above.

Files go in `art_src/skies/<planet>/` with `<planet>` = `hive`, `scrap`, `magma`, `crystal`,
`plasma`, `sentinel`.

| File | Size | Background | What is in it |
|---|---|---|---|
| `stars.webp` | 1600 x 3200 | filled (the darkest layer) | deep space: stars of different sizes, a faint distant galaxy band. The TOP and BOTTOM edges must match exactly, so it can scroll in a loop |
| `clouds.webp` | 1600 x 3200 | black | nebula gas and dust in the planet's colours, soft edges, mostly at the top and the sides, thin in the middle; top and bottom edges match (it loops too); the code adds it as light, so black disappears |
| `planet.webp` | 1600 x 1000 | black above the planet | the planet's curved horizon across the bottom with surface detail in the planet's theme; the top of the curve about a third of the way down the picture |
| `glow.webp` | 1600 x 1000 | black | only the atmosphere rim of that planet, same place as in `planet.webp`; the code pulses it |
| `floaters.webp` | 2048 x 1024 (4 x 2 cells of 512) | black | pieces the code drifts and spins past: cells 1-3 three rocks or wrecks of different shapes, cell 4 one big slow distant object (a moon, a station, a hulk), cell 5 a small ship seen from the side, cells 6-8 three small bits of debris |

Planet themes (one line each, your paintings already have the colours):
- hive: dark jungle-coral world, hive spires, amber and green bioluminescence; sky navy and teal.
- scrap: rings of wrecked ships and junk, rusted stations; rust orange, steel grey, cyan sparks.
- magma: cracked crust, lava rivers, ash clouds; orange, red, black.
- crystal: ice and crystal spires, frozen seas; cyan, white, pale blue.
- plasma: a gas giant wrapped in lightning; violet, electric green.
- sentinel: a dead machine planet covered in glowing grids; teal, black, white.

## Part B: the base dome as its own piece (for the super weapons)
Open `base/base_strip.png`: your base strip with the command dome in the middle and the four
turret sockets. The dome will swap with the super weapon the player equips, so we need:

| File | Size | What is in it |
|---|---|---|
| `strip_nodome.webp` | same as `base_strip` (2816 x 880) | the base strip EXACTLY as it is, but with the dome removed: a flat landing pad with a ring of lights where the dome stood |
| `dome_standard.webp` | 1024 x 1024 | the dome alone, exactly as it is on the strip, same size (the code puts it back in the same place) |
| `dome_beam_1.webp`, `dome_beam_2.webp`, `dome_beam_3.webp` | 1024 x 1024 each | the dome with an orb emitter on top (the "Orbital Beam" weapon): 1 idle (orb dark), 2 charging (orb lit, rings of light gathering), 3 firing (orb white-hot, a thin beam leaving straight up and cut off at the top edge) |
| `dome_shield_1..3.webp` | 1024 x 1024 each | the dome with a ring of small emitter fins round its rim (the "Shield Overcharge" weapon): 1 idle, 2 charging (fins lit cyan), 3 firing (a bright hex pattern over the dome) |
| `dome_emp_1..3.webp` | 1024 x 1024 each | the dome opened at the top with an antenna array rising out (the "EMP Pulse" weapon): 1 closed, 2 open and charging (array lit yellow-green), 3 firing (a ring of light leaving the array) |

Every dome picture at the SAME size and in the SAME place in its picture as `dome_standard`,
so the code can swap them without moving anything.

## Common mistakes to avoid
- A bright or busy middle of the sky (the fight must stay readable).
- Sky layers whose top and bottom edges do not match (a visible seam when they loop).
- A dome drawn bigger or shifted between its frames.
- Painting the planet into the stars layer: the planet is its own picture.

## Checklist
- [ ] Hive sky: stars, clouds, planet, glow, floaters (then the Scrap Belt the same way).
- [ ] The strip without its dome, the standard dome, three weapons x three frames.
- [ ] Sizes exact, black where the table says, names exact.
Thank you! If time is short: Part B first (the dome pieces are small), then the Hive sky.
