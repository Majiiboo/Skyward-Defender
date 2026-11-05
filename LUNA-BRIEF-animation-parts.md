# Luna brief: parts for smooth, AAA-style animation (pilot, drone, turrets, bugs)

Hi Luna! This brief has everything you need; no earlier brief or message is required.

## What this is for
Rudy wants everything that moves in the game to move like a big-budget 3D game: smooth,
weighty, alive. Most of that is done in code by moving PIECES of a character separately
(a wing flaps, a barrel slides back, a thruster tilts). The code can only move what is cut
into separate pieces. Today the pilot is already in pieces (16 parts) and the bugs have
bodies and wings. This brief asks for the missing pieces. Nothing here is a redraw: every
piece is cut from the SAME design you already made, so it fits back together exactly.

## Rules for every picture
- **Black background**, one piece per picture, nothing cropped, no text, no frame.
- **Same style and lighting** as the existing picture of that character (the file named
  under "Matches").
- **Same canvas, same place.** For a set of pieces that belong to one character, render
  every piece on the SAME canvas size with the piece in the SAME position it has on the
  whole character. Then the code stacks them and they line up by themselves. (The simplest
  way: render the whole character once, then re-render it with only one piece visible
  each time. That is what the "Matches" picture is for.)
- **Render size:** 1024 x 1024 for a single character, unless the table says otherwise.
- **File names:** exactly as written below, lower case, `.webp`.

## 1. Drone (3 bodies): hull, two thrusters, thruster light
Matches: `drone/body_scout.png`, `drone/body_striker.png`, `drone/body_warden.png`
(and `pod_*.png` for the weapon pods, which stay as they are).

For EACH body (scout, striker, warden), four pictures on one 1024 x 1024 canvas:

| File | What is in it |
|---|---|
| `drone_<body>_hull.webp` | the drone WITHOUT its two side thrusters (fill the holes where they attach with plain hull) |
| `drone_<body>_thruster_l.webp` | only the LEFT side thruster / fin, in its place |
| `drone_<body>_thruster_r.webp` | only the RIGHT side thruster / fin, in its place |
| `drone_<body>_light.webp` | only the glowing parts (eye, ring, vents) as bright light on black, no hull |

What the code does with them: the hull bobs and banks when the drone turns, the two
thrusters tilt a little later than the hull (follow-through), the light layer pulses and
flashes when it fires.

## 2. Turrets (6): the moving piece and the light
Matches: `turrets/<name>_head.png` and `turrets/<name>_base.png` (names: sentry, lance,
storm, gravity, swarm, prism). Render on the head's canvas, same place.

| File | What is in it |
|---|---|
| `turret_sentry_barrels.webp` | only the two gun barrels of the Sentry head, so they can slide back on each shot |
| `turret_sentry_head_nobarrels.webp` | the Sentry head without the barrels (plain housing where they sit) |
| `turret_swarm_lid.webp` | only the hatch lid of the Swarm Hive |
| `turret_swarm_body_nolid.webp` | the Swarm Hive with the hatch OPEN (dark hole where the lid was) |
| `turret_<name>_light.webp` (all six) | only the glowing parts of that turret (Lance crystal, Storm rod tips, Gravity orb, Prism crystal, Sentry muzzle vents, Swarm hatch rim) as light on black |

What the code does: barrels recoil and return with a spring, the Swarm lid flips open
before drones launch, every turret's light breathes while idle, swells while charging and
flashes on fire. Today the whole turret cross-fades to a "fire" picture, which looks flat.

## 3. Bugs (5): legs, feelers and a death burst
Matches: `enemies/parts/<bug>_body.png` and `<bug>_wing.png` (scout, drifter, spitter,
diver; the Hive Mother is already in pieces). Render on the body's canvas, same place.

For EACH of scout, drifter, spitter, diver:

| File | What is in it |
|---|---|
| `bug_<name>_body_clean.webp` | the body WITHOUT legs and feelers (smooth where they attach) |
| `bug_<name>_legs_l.webp` | only the LEFT legs (all of them, one picture), in place |
| `bug_<name>_legs_r.webp` | only the RIGHT legs, in place |
| `bug_<name>_feelers.webp` | only the antennae / feelers, in place |
| `bug_<name>_chunks.webp` | 1536 x 512: SIX broken pieces of this bug side by side (a wing half, a leg, a bit of shell, a bit of body, goo, a feeler), evenly spaced, for the death burst |

Plus, for the Spitter only: `bug_spitter_sac_full.webp` and `bug_spitter_sac_empty.webp`
(its belly sac swollen with goo, and the same sac emptied), in place on the body canvas.

What the code does: legs paddle as the bug flies, feelers trail behind and whip on turns,
bodies squash when hit and stretch when they dart, the sac swells before a spit and empties
on it, and a killed bug breaks into its own chunks that tumble and fade instead of popping.

## 4. Pilot: nothing new needed
The pilot is already a 16-part rig (`pilot_rig/`, `pilot_front/`). Smooth turn-arounds,
recoil, lean, jetpack bob and breathing are all code. If anything comes up it gets its own
brief.

## Checklist (each picture)
- [ ] Black background, one piece, nothing cropped, no text.
- [ ] Same canvas size and same position as on the whole character ("Matches" picture).
- [ ] Same style and lighting as that picture.
- [ ] Light layers: ONLY the glow, on black (they are added on top like light).
- [ ] File name exactly as in the table.

Order if time is short: 2 (turrets) first, then 3 (bugs), then 1 (drone).
