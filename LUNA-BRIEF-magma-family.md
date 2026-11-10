# Luna brief: the MAGMA WORLD enemy family (planet 3), in parts

Hi Luna! This brief has everything you need; no earlier brief or message is required.

## What this is for
The game is six planets of ten stages. Planet 1 has your Hive bugs. Planet 2 added your Scrap
Belt machines. Planet 3 is the Magma World, and it gets its own family: creatures of living
rock and lava. Families STACK: the bugs and the machines never leave, the magma creatures join
them in small numbers on planet 3 and grow, so all three families must look right side by side
and be told apart at a glance.

The game moves every enemy as PIECES (a body plus its moving parts), exactly as your bugs and
machines move today, and breaks a killed enemy into its own chunks. That is why each creature
below is asked for whole AND in pieces.

## Match your earlier families (open these first)
`enemies/scout.png`, `enemies/hive_mother.png`, and in `enemies/scrap/`: `mite_whole.png`,
`hulk_whole.png`, `queen_whole.png`. Same rules as those:
- Glossy rendered 3D, seen from directly ABOVE, the head or front pointing DOWN the picture.
- Plain black background, one piece per picture, centred, filling about 70-80% of the picture,
  nothing cut off. Every piece at the SAME size it has on the whole creature.
- Light from above, a cool rim light so the dark rock still has an edge.
- THE FAMILY'S COLOURS: near-black basalt rock, split by glowing cracks that are RED-ORANGE at
  the edges and YELLOW-WHITE in the hottest middle. (The Hive bugs are green and amber, the
  machines are rust and steel with cyan lamps. So: no green, no cyan, no smooth metal, and keep
  most of each body BLACK rock so it does not read as an amber bug.)
- Our own designs; never another game's.

Files go in `art_src/magma/`. Whole pictures 512 x 512 (the two bosses 1024 x 1024), pieces 512.

## 1. The five creatures (each takes a role the game already knows)
| id | Name | Role in the fight | Look | Pictures (one each) |
|---|---|---|---|---|
| `cinder` | Cinder Fly | fast, weak, comes in swarms | a small round lump of black rock with one glowing eye-crack, and two short wings of thin glowing lava-glass | `cinder_whole`, `cinder_body` (no wings), `cinder_wing` (ONE wing alone, the left one; the game mirrors it and flaps two) |
| `crust` | Crust Back | slow, tough, bursts into small pieces when it dies | a wide flat beetle-shape of rock with two thick shell plates on its back; between the plates a line of bright lava | `crust_whole`, `crust_body` (no plates, the lava back showing), `crust_plate_l`, `crust_plate_r` (each plate alone) |
| `spitfire` | Spitfire | hangs back and spits lava at the pilot | a rock creature with a short snout pointing DOWN and a round sac of lava on its back; the sac swells before it spits | `spitfire_whole`, `spitfire_body` (no sac), `spitfire_sac_full` (the sac alone, swollen and bright), `spitfire_sac_empty` (the sac alone, small and dim) |
| `comet` | Comet | locks on and dives at the base | a long pointed shard of rock with a white-hot tip and a cracked, glowing body | `comet_whole`, `comet_body`, `comet_flame` (its fire trail alone, pointing UP the picture) |
| `coal` | Hot Coal | the small piece a Crust Back bursts into | a tumbling lump of glowing coal, about a third of the Cinder Fly's size | `coal_whole` only |

Plus, for cinder, crust, spitfire and comet: `<id>_chunks.webp` (1536 x 512): SIX broken pieces
of that creature in a row, evenly spaced, not touching (a slab of rock, a piece of wing or
plate, a glowing shard, a lump of body, a pebble, a drop of lava). The game throws them when
it dies.

## 2. The mini-boss: the Smelter (1024 x 1024 for the whole; pieces 512 x 512)
A heavy crab-like creature of rock the size of three Crust Backs: a broad domed back with a
glowing furnace mouth at the front (pointing DOWN the picture), and two thick crusher claws.
When its mouth opens it pours lava.
Pictures: `smelter_whole`, `smelter_body` (no claws, mouth CLOSED), `smelter_claw_l`,
`smelter_claw_r` (each claw alone, with its arm), `smelter_mouth_open` (ONLY the mouth
section, open and white-hot inside, at the same size and place as the closed mouth on the
body), `smelter_chunks` (1536 x 512, six pieces).

## 3. The boss: the Caldera Queen (1024 x 1024 for the whole; pieces 512, the vent 1024 wide)
A huge living volcano: a ring-shaped body of black rock around an open crater on her back,
two long arms of rock ending in three-fingered hands, a cracked face of lava at the front
(pointing DOWN). Her crater opens to throw Cinder Flies into the fight (like the Hive Mother
hatching and the Salvage Queen's cargo hold).
Pictures: `caldera_whole`, `caldera_body` (no arms, the crater CLOSED by a rock lid),
`caldera_arm_l`, `caldera_arm_r` (each arm alone with its hand), `caldera_vent_open` (ONLY
the crater section, open, bright lava inside, at the same size and place as the closed lid
on the body), `caldera_chunks` (1536 x 512, six pieces).

## Common mistakes to avoid
- A creature that reads as a bug or a machine: no legs with joints, no feelers, no metal
  plates, no rotors. These are ROCK and LAVA.
- Too much glow: if the whole body glows orange it looks like an amber Hive bug. Mostly black
  rock, with the lava only in the cracks, the eye, the sac and the mouth.
- Green or cyan light anywhere.
- Pieces at a different size from the whole picture.
- A view from the side or from the front: everything from directly above, front DOWN.
- A floor, a shadow, smoke that reaches the edge of the picture, text.

## Checklist
- [ ] Cinder Fly: 3 pictures + chunks. Crust Back: 4 + chunks. Spitfire: 4 + chunks.
      Comet: 3 + chunks. Hot Coal: 1.
- [ ] Smelter: 6 pictures. Caldera Queen: 6 pictures.
- [ ] 31 pictures in all, top-down, front down, black backgrounds, black rock with red-orange
      and yellow-white lava, exact names, in `art_src/magma/`.

Thank you! If time is short: the Cinder Fly, the Crust Back and the Spitfire first (the first
stages of the planet use only those), then the Comet, then the two bosses.
