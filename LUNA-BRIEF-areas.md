# Luna brief: the SCRAP BELT enemy family (planet 2), in parts

Hi Luna! This brief has everything you need; no earlier brief or message is required.
(This replaces the older "planets after the Hive world" brief; the later planets come one at
a time after this family is in.)

## What this is for
The game is six planets of ten stages. Every planet still fights your Hive bugs. The Scrap
Belt (planet 2, a ring of wrecked ships) gets its own family: salvage machines the bugs built
from junk. From here on families STACK: the Hive bugs never leave, the machines join them in
small numbers on planet 2 and grow, so both families must look right side by side.

The code moves every enemy as PIECES (body + moving parts), exactly as your Hive bugs move
today (legs paddle, feelers whip, wings flap), and breaks a killed enemy into its own chunks.

## Match your Hive bugs (open these first)
`enemies/scout.png`, `drifter.png`, `spitter.png`, `diver.png`, `hive_mother.png` and the
pieces in `enemies/parts/`. Same rules:
- Glossy rendered 3D, seen from directly ABOVE, the head or front pointing DOWN the picture.
- Plain black background, one piece per picture, centred, filling about 70-80%, nothing
  cut off. Every piece at the SAME size it has on the whole machine.
- Light from above, a cool rim light. The family's colours: rust orange and steel grey with
  CYAN sparks and lamps (the Hive bugs are green and amber, so the two read apart at a glance).
- Our own designs; never another game's.

Files go in `art_src/scrap/`. Whole pictures 512 x 512 (the boss 1024), pieces 512.

## 1. The five machines (each takes a Hive role so the game logic carries over)
| id | Name | Takes the role of | Look | Pieces (one picture each) |
|---|---|---|---|---|
| `mite` | Scrap Mite | Scout (fast swarm) | a small round drone made of a tin can, one cyan eye, two little rotors on stubby arms | `mite_whole`, `mite_body` (no rotors), `mite_rotor` (ONE rotor blade pair; the code spins two copies) |
| `hulk` | Hulk Drone | Drifter (tough, bursts when it dies) | a wide armoured box welded from hull plates, a glowing cyan reactor in the middle, two side thruster panels | `hulk_whole`, `hulk_body`, `hulk_panel_l`, `hulk_panel_r` |
| `rivet` | Rivet Gun | Spitter (shoots at the pilot) | a drone with a rivet barrel pointing DOWN under its nose and a glowing ammo pod on its back; the pod is the sac: it swells before it fires | `rivet_whole`, `rivet_body` (no pod), `rivet_pod_full`, `rivet_pod_empty` |
| `dart` | Spike Dart | Diver (locks on, dives at the base) | a long pointed missile-drone with a red warning light on the nose and three small tail fins | `dart_whole`, `dart_body`, `dart_flame` (its tail flame alone, pointing UP the picture) |
| `bolt` | Junk Bolt | Spore (the small thing the Hulk bursts into) | a tumbling cluster of bolts and nuts with one cyan spark in it, about a third of the Mite's size | `bolt_whole` only |

Plus, for mite, hulk, rivet and dart: `<id>_chunks.webp` (1536 x 512): SIX broken pieces of
that machine side by side, evenly spaced (a plate, a rotor or fin, a lamp, a bit of body, a
bolt, a spark of wiring). The code throws them when it dies.

## 2. The mini-boss: Wrecker (1024 x 1024 for the whole; pieces 512)
A crane-claw machine the size of three Hulks: a slab of hull with a cyan reactor eye, one big
grabber claw on an arm, two rotor pods. It grabs a turret's socket and must be shot off.
Pieces: `wrecker_whole`, `wrecker_body`, `wrecker_arm` (the arm with the claw CLOSED),
`wrecker_claw_open` (the claw alone, open), `wrecker_rotor` (one rotor pod).

## 3. The boss: Salvage Queen (1024 x 1024 for the whole; pieces 512, the hold 1024 wide)
A big crane-like machine with two grabber arms and a cargo hold on her back that opens to
release Mites (like the Hive Mother's hatching). Rust and steel with a row of cyan lamps,
a cracked viewport for a face.
Pieces: `queen_whole`, `queen_body` (no arms, hold CLOSED), `queen_arm_l`, `queen_arm_r`
(each arm with its claw), `queen_hold_open` (the hold section alone, doors open, lit inside;
same size and place as the closed hold on the body), `queen_chunks` (1536 x 512, six pieces).

## 4. The commander for the radio briefings (optional, when the above is done)
When the player reaches a new planet a short message plays ("INCOMING TRANSMISSION"). Two
head-and-shoulders portraits of the commander who sends it, 512 x 512, black, rendered 3D
like the pilot: a calm older officer in the pilot's charcoal-and-cyan armour style, with a
holo-screen feel (faint scanlines, cyan rim): `commander_calm.webp`, `commander_urgent.webp`
(frowning, mid-speech).

## Common mistakes to avoid
- A machine that reads as a bug (legs, feelers, shell): these are JUNK MACHINES.
- Green or amber light (that is the Hive family): cyan lamps, orange rust.
- Pieces at a different size from the whole picture.
- Seen from the side or from the front: everything from directly above, front DOWN.

## Checklist
- [ ] Five machines: whole + pieces + chunks as listed (the Bolt: whole only).
- [ ] Wrecker: 5 pictures. Salvage Queen: 6 pictures.
- [ ] Top-down, front down, black backgrounds, rust / steel / cyan, names exact.
Thank you! If time is short: the Mite, the Hulk and the Rivet Gun first (the first three
stages of the planet use only those), then the Dart, then the bosses.
