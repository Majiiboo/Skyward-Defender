# Luna brief: battle backgrounds as layers (areas and zones)

Hi Luna! Your 3D pilot, base and turrets are in the game and they look great. Now the
sky behind them looks flat next to them: it's still a code-drawn colour fade with dots
for stars. We'd like painted backgrounds in the same rendered 3D style, split into
LAYERS that the game moves at different speeds. That makes the sky feel deep, and it
keeps moving gently even when nothing else does.

## How the game is split up (why there are several backgrounds)
- The game is a journey through AREAS. Each area is a new planet with its own look and
  its own enemies, and lasts 10 stages, ending with a big boss.
- Each area has two ZONES of 5 stages: Zone A is high above the planet (orbit, open
  space), Zone B is lower and closer to the surface (bigger planet, weather, the
  planet's own light). So the sky changes every 5 stages and the world changes every 10.
- Please start with AREA 1 only (both zones). The other areas are listed at the end so
  you can keep the style consistent; we'll ask for them one at a time.

## The scene
- Portrait phone screen. The player's base strip sits along the bottom; the pilot and
  the bugs fly in the middle and top half.
- VERY IMPORTANT: keep the middle and the lower middle of the sky DARK and CALM (no
  bright spots, no busy detail there). That's where the pilot, bugs, bullets and gems
  are, and they must stay easy to see. Put the interesting things near the top and the
  sides, and the planet at the bottom.
- Light from above and slightly in front, like your base. No text, no UI, no
  characters, no enemies in the paintings.
- Our own world: please don't copy other games' backgrounds.

## The layers for ONE zone (back to front)
All sizes are for the full screen; extra width is so the game can slide the layers a
little sideways when the pilot moves.

| # | Layer | Size | Background | Notes |
|---|---|---|---|---|
| 1 | Deep space | 1600 x 3200 | solid (fills the frame) | Stars of different sizes, a faint galaxy band or distant nebula. The darkest layer. TOP AND BOTTOM EDGES MUST MATCH so it can scroll in a loop. |
| 2 | Nebula / clouds | 1600 x 3200 | plain black | Coloured gas and dust in the area's colours, soft edges. Mostly at the top and sides, thin in the middle. Top and bottom edges must match (it loops too). The game adds it as light, so black disappears. |
| 3 | Planet | 1600 x 1000 | plain black above the planet | The planet's curved horizon across the bottom, with its atmosphere glow along the edge and surface details (cities, terrain, the area's theme). The top of the curve sits about 1/3 down this image. |
| 4 | Atmosphere glow | 1600 x 1000 | plain black | Just the glowing rim of the planet from layer 3, same place. The game pulses it softly. |
| 5 | Floating objects | 512 x 512 cells | plain black | Separate pieces the game drifts, spins and flies past: 3 asteroids or rocks (different shapes and sizes), 1 big slow distant object (a moon, station or wreck), 1 small ship seen from the side, 4 small debris bits. |

For Zone B (lower, closer to the planet) we only need a new layer 2 (different
clouds or weather) and a new layer 3 + 4 (the planet bigger and closer, filling more of
the bottom). Layers 1 and 5 can be shared with Zone A.

## Area 1: the Hive world (start here)
The first planet, where the bug swarms come from. A living world: dark jungle or
coral-like terrain with hive spires and bioluminescent glow (amber and green lights),
a thick hazy atmosphere. Sky in deep navy and teal, with warm amber accents.
- Zone A "orbit": the planet's curve low at the bottom, wide open space, a moon.
- Zone B "descent": the planet much closer, hive spires and glowing swamps visible on
  the surface, drifting spores or pollen in the clouds layer.

## Later areas (for consistent style; not needed yet)
| Area | Planet | Colours |
|---|---|---|
| 2 | Scrap belt: rings of wrecked ships and junk, rusted stations | rust orange, steel grey, sparks |
| 3 | Magma world: cracked crust, lava rivers, ash clouds | orange, red, black |
| 4 | Crystal world: ice and crystal spires, frozen seas | cyan, white, pale blue |
| 5 | Plasma storm: a gas giant with lightning storms | violet, electric green |
| 6 | Sentinel world: a dead machine planet covered in glowing grids | teal, black, white |

Thank you! If the layers for Area 1 look good in the game, we'll ask for the next area.
