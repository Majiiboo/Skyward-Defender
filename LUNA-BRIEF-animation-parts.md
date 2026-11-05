# Luna brief: parts for smooth, AAA-style animation (drone, turrets, bugs) — ROUTE 3

Hi Luna! This brief has everything you need; no earlier brief or message is required.
(Version 2, after your note: the pieces do NOT need to stack on one canvas any more.)

## What this is for
Rudy wants everything that moves to move like a big-budget 3D game. The code does that by
moving PIECES of a character on their own (a barrel slides back, a leg paddles, a lid
flips). It only needs each piece as its OWN picture; the code places it where it belongs.
That is exactly how the pilot already works (16 separate part pictures, placed in code).

## The rules (simple now)
- **One piece per picture**, centred, filling the frame comfortably (about 70-80% of the
  picture), on a **black background**. No text, no frame, nothing cropped.
- **Same style and lighting** as the whole character it comes from (named under "From").
- **Same size as on the whole character.** If the whole turret is 1024 px tall and its
  barrels are a quarter of that, render the barrels so they would still be a quarter of
  1024 px (it is fine if the frame has empty black around them). Rough is fine: the code
  scales each piece to fit, like it did for the pilot.
- **Don't** worry about where the piece sits on the whole picture: I measure that myself.
- **Light layers are gone from your list.** I cut the glow out of the whole pictures in code.
- File names exactly as below, lower case, `.webp`, 1024 x 1024 unless the table says.

## 1. Turrets (first)
From: `turrets/<name>_head.png` and `turrets/<name>_base.png` (sentry, swarm).

| File | What is in it |
|---|---|
| `turret_sentry_barrels.webp` | only the Sentry's two gun barrels, as one piece |
| `turret_sentry_head_nobarrels.webp` | the Sentry head without the barrels (plain housing where they sit) |
| `turret_swarm_lid.webp` | only the Swarm Hive's hatch lid |
| `turret_swarm_body_nolid.webp` | the Swarm Hive with the hatch OPEN (dark hole where the lid was) |

What the code does: barrels recoil and return on a spring; the lid flips open before the
drones launch. The other four turrets move as whole heads already (turn, lean, pulse).

## 2. Bugs (second)
From: `enemies/parts/<bug>_body.png` (scout, drifter, spitter, diver).

For EACH of scout, drifter, spitter, diver:

| File | What is in it |
|---|---|
| `bug_<name>_body_clean.webp` | the body WITHOUT legs and feelers (smooth where they attach) |
| `bug_<name>_legs_l.webp` | the LEFT legs, all of them, as one piece |
| `bug_<name>_legs_r.webp` | the RIGHT legs, as one piece |
| `bug_<name>_feelers.webp` | the antennae / feelers, as one piece |
| `bug_<name>_chunks.webp` | 1536 x 512: SIX broken pieces of this bug side by side (a wing half, a leg, a bit of shell, a bit of body, goo, a feeler), evenly spaced |

Plus, Spitter only: `bug_spitter_sac_full.webp` and `bug_spitter_sac_empty.webp` (its
belly sac swollen with goo, and the same sac emptied), each on its own.

What the code does: legs paddle, feelers trail and whip on turns, the sac swells before a
spit and empties on it, and a killed bug breaks into its own chunks (today it breaks into
square cuts of its body; your chunks replace those).

## 3. Drone (third)
From: `drone/body_scout.png`, `drone/body_striker.png`, `drone/body_warden.png`.

For EACH body (scout, striker, warden):

| File | What is in it |
|---|---|
| `drone_<body>_hull.webp` | the drone WITHOUT its two side thrusters (plain hull where they attach) |
| `drone_<body>_thruster_l.webp` | the LEFT side thruster / fin, on its own |
| `drone_<body>_thruster_r.webp` | the RIGHT side thruster / fin, on its own |

What the code does: the hull banks, the thrusters tilt a beat later (follow-through).

## Checklist (each picture)
- [ ] Black background, one piece, centred, nothing cropped, no text.
- [ ] Same style and lighting as the whole character.
- [ ] Roughly the size it has on the whole character.
- [ ] File name exactly as in the table.
