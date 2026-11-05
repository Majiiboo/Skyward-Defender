# Luna brief: DRONES round 2 (three new bodies, two support pods)

Hi Luna! This brief has everything you need; no earlier brief or message is required.

## What this is for
The drone flies beside the hero and shoots with him. Each drone BODY now has its own
element, and Rudy wants variety: three new bodies, each a completely different little
machine, plus two support pods (no guns). Each body is painted as PARTS so the code can bob,
bank and flicker it: a hull, two thrusters (one left, one right), and a glow layer.

## Match your earlier drones
Open `drone/body_scout.png`, `drone/body_striker.png`, `drone/body_warden.png` and the
parts `drone/scout_hull.png`, `drone/scout_thruster_l.png`, `drone/scout_thruster_r.png`.
Same camera (seen from slightly above and in front, nose UP in the picture), same size, same
rendered metal look. Light from above, a rim light in the body's element colour.

## The three bodies
| Body | Element (light colour) | Design (must look different from the three you made) |
|---|---|---|
| **Spark Bot** | Electric, yellow-green (73FF59) | a round junkyard ball with two stubby wings, a big single lens, a Tesla coil on top that crackles; dented scrap metal |
| **Wisp** | Void, purple (B573FF) | a smooth teardrop of dark glass with a purple core inside and three thin trailing fins, no visible engines: it glides |
| **Night Bat** | Dark, deep red (FF4D4D) on black | a sleek black stealth drone shaped like a bat: two swept wings with red light edges, a narrow head with two red eye slits |

## Pictures per body (black background, each in `art_src/drones2/<body>/`, `<body>` = `spark`, `wisp`, `bat`)
1. `whole.webp` (1024 x 1024): the complete drone, nose up, for the menu.
2. `parts.webp` (2048 x 512, 4 cells of 512 x 512): cell 1 the HULL alone (no wings or
   engines), cell 2 the LEFT wing or thruster alone, cell 3 the RIGHT one alone, cell 4 the
   GLOW: only the parts that light up (core, eyes, coil, light edges) on black, same place and
   size as in cell 1. Every part at the same size and orientation as in `whole.webp`.
3. `portrait.webp` (512 x 512): the drone from the front, filling the frame.

## The two support pods (black background, `art_src/drones2/pods/`)
Match `drone/pod_beam.png` and `drone/pod_blaster.png` in size and camera: a small
attachment seen from above, mounted on the drone's nose.
| File | Pod | Design |
|---|---|---|
| `pod_repair.webp` (512 x 512) | Repair Pod | a small white-and-teal module with a cross symbol and a short antenna; soft teal light |
| `pod_magnet.webp` (512 x 512) | Magnet Pod | a small horseshoe magnet in a metal cradle, purple light between its poles |

## Common mistakes to avoid
- A body that looks like the Scout, Striker or Warden again. These three must be new shapes.
- Parts at a different size from the whole picture (the code lines them up by size).
- Painting the glow into the hull: the glow is its own cell, dark hull in cell 1.
- Shadows or a floor painted in.

## Checklist
- [ ] Three bodies, each: whole, parts (hull / left / right / glow), portrait.
- [ ] Two pods at the beam pod's size and camera.
- [ ] Nose up, lit from above, black backgrounds, names exactly as above.
Thank you! If time is short: Spark Bot first (whole + parts), then the two pods.
