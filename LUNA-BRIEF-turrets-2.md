# Luna brief: TURRETS round 2 (six new turrets, firing heads for the six we have)

Hi Luna! This brief has everything you need; no earlier brief or message is required.

## Two small leftovers first (from the cards brief)
1. `pic_rook_twin.webp` (512 x 512, black): Rook's card picture was not in the delivery.
   Two cyan bolts flying side by side, locked together by a thin bracket of light, small
   speed lines behind them. Same style as your `pic_sparks_weld.webp`.
2. `frame_common-v2.png` (300 x 444, PNG, see-through window): a Common card frame in the
   SAME tech style as your Uncommon, Epic and Legendary frames (thin band, the same window),
   with a plain grey-silver edge light instead of a colour. The old Common frame is a thick
   painted band and reads differently from the other three.

## What this is for
The base has four sockets and the player buys turrets to put on them. Today there are six
turrets, one per element. Rudy wants TWO per element, each a different job, so the choice is
about play style and never "the one Ice turret". The code draws every turret as a BASE (sits
in the socket, never moves) and a HEAD (turns, leans, recoils, pulses) and cuts the glowing
parts out of your pictures itself, exactly as it does with your six turrets today.

## Match your earlier turrets (open these first)
- `turrets/sentry_base.png` + `turrets/sentry_head.png`: a turret as two pieces.
- `turrets/lance_head.png`, `storm_head.png`, `gravity_head.png`, `prism_head.png`,
  `swarm_body_nolid.png` + `swarm_lid.png`: the other heads.
- Same camera (seen from in front and a little above, the head centred over the base),
  same rendered 3D look, same lighting (above and a little in front, cool rim light), same
  height: a whole turret is about the height of the Sentry.

## 1. Six new turrets (each as TWO pictures, 1024 x 1024, black background)
Files go in `art_src/turrets2/`. For each turret: `<id>_base.webp` (the foot that sits in
the socket, no head) and `<id>_head.webp` (the head alone, centred, as it sits on the base).
Both at the SAME size as they have on the assembled turret (it is fine to have black around).
Paint the lights (lamps, coils, lenses) IN the pictures in the element colour; the code cuts
them out as a glow layer, so do not deliver a separate light picture.

| id | Name | Element (light colour) | Job in the game | Design |
|---|---|---|---|---|
| `repair` | Repair Node | Energy (cyan, 33D9FF) | SUPPORT: does not shoot; mends the base shield while it stands | a short white-and-charcoal pylon with a round dish on top tilted toward the sky, a cyan cross symbol lit on the dish's face, two small side antennas; the head is the dish |
| `tesla` | Tesla Coil | Electric (yellow-green, 73FF59) | STRIKER: fast short-range zaps at the nearest bug | a heavy ribbed coil tower: the base is a wide ceramic insulator stack, the head is the coil with a bright ball on top and small arcs frozen in the air round it |
| `cryo` | Cryo Lens | Ice (pale blue, 9AE6FF) | CONTROL: a wide cone of cold that slows every bug in it | a frosted ring of metal holding a big round blue lens, ice crystals growing on the ring; the base is a tripod of three short legs with frost on them |
| `mines` | Mine Layer | Void (purple, B573FF) | BREAKER: drops floating mines that burst on bosses and armour for big damage | a squat dark launcher with a purple mine half out of its top hatch; the base is a flat drum with a purple seam light; the head is the hatch section with the mine |
| `beacon` | Dread Beacon | Dark (deep red, FF4D4D, on black) | SUPPORT: marks bugs so the hero crits them; hero ATK +10% while it stands | a tall thin black mast with three red eye-lamps in a row near the top and a slowly turning cage of thin blades around them; the base is a narrow black foot with a red ring |
| `flak` | Flak Battery | Fire (orange-gold, FFB347) | SWARM: airburst shells that shred many small bugs at once | two stubby mortar tubes side by side on a turning cradle, brass and dark steel, hot orange glow inside the tubes; the base is a squat ammo box |

For every new turret, also ONE shot picture (512 x 512, light on black, the code tints it):
`<id>_shot.webp`: what it fires, seen from the side, moving UP the picture. Repair: a soft
cyan ring pulse. Tesla: a short jagged arc. Cryo: a fan of frost mist. Mines: a round mine
with a purple light. Beacon: a thin red marker beam. Flak: a shell with an orange burst star.

## 2. Firing heads for the six turrets we have (1024 x 1024, black)
Today each head has one pose. The code wants a second one to blend in for the split second
it fires: `art_src/turrets2/<id>_head_fire.webp` for sentry, lance, storm, gravity, swarm,
prism. SAME size, SAME angle and SAME place in the picture as `turrets/<id>_head.png`, so the
two can cross-fade; only the firing change differs:

| id | Firing change |
|---|---|
| `sentry` | both barrels slid back into the housing, muzzles glowing hot |
| `lance` | the beam emitter opened like petals, the core white-hot |
| `storm` | the top coil flared, lightning crawling over the spire |
| `gravity` | the anchor's rings pulled in tight, the core dark with a bright edge |
| `swarm` | the hive's side vents open and lit (the lid itself is a separate piece already: keep the lid OFF in this picture, dark hole where it sits) |
| `prism` | the prism split into its five faces, each lit |

## Common mistakes to avoid
- Head and base at different sizes from each other (the code stacks them by size).
- A head drawn off-centre, or the firing head in a different place from the resting head.
- A floor, a shadow, or a socket painted under the base: the base strip already has them.
- Glow spilling far outside the metal: a lit lamp is fine, a big halo is cut off in code.

## Checklist
- [ ] Six new turrets: `<id>_base.webp`, `<id>_head.webp`, `<id>_shot.webp` each (18 files).
- [ ] Six firing heads `<id>_head_fire.webp`, lined up with the heads in `turrets/`.
- [ ] The two card leftovers at the top.
- [ ] Black backgrounds, 1024 x 1024 (shots 512), names exactly as listed.
Thank you! If time is short: the Repair Node and the Tesla Coil first, then the firing heads.
