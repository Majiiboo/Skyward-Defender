# Luna brief: in-between frames for smoother animation (dev86)

Everything below already moves smoothly in code (cross-fades, squeezes, eased
motion). These frames would replace those code tricks with real painted motion.
Listed most useful first. Same rules for every cell: plain black background,
same style, same framing and scale as the existing image it sits between, one
object per cell, nothing cropped.

| # | Sheet | Cells | Sits between | What changes |
|---|-------|-------|--------------|--------------|
| 1 | Pilot turn-around | 2 | `pilot/aim_up.png` and its mirror | Rifle still raised. Cell 1: body a quarter turned toward the camera. Cell 2: facing the camera head-on. The game plays 1, 2, then the mirrored pose. Replaces the "squeeze" when he swaps sides. |
| 2 | Sentry shot | 2 | `turrets/sentry_idle.png` and `sentry_fire.png` | Cell 1: barrels pulled back halfway (recoil). Cell 2: barrels sliding forward again, small muzzle smoke. |
| 3 | Lance Pylon charge | 3 | `turrets/lance_idle.png` and `lance_fire.png` | Crystal tip glowing a third, two thirds, then fully charged. Same pylon, only the light changes. |
| 4 | Storm Spire shot | 2 | `turrets/storm_idle.png` and `storm_fire.png` | Cell 1: the spire's rods start to crackle, a little smoke at the tips. Cell 2: smoke clearing, the rods dimming back. (Right now the fire frame is mostly smoke, so the spire nearly disappears.) |
| 5 | Chest opening | 1 | `chest_closed` and `chest_open` icons | The lid half open, a thin line of light from inside. Used by the Store tab and the Chest button on Home. |
| 6 | Hive Mother sacs bursting | 1 | `enemies/parts/hive_sacs_full.png` and `hive_sacs_empty.png` | Sacs tearing open, purple goo spraying out, same position and size as the full sacs. |
| 7 | Spitter spit | 1 | `enemies/parts/spitter_body.png` | Same body with the sac squeezed smaller and the mouth at the bottom of the sac open, a goo glob just leaving. |
| 8 | Other three turrets | 2 each | Gravity Anchor, Swarm Hive, Prism Tower idle and fire | Same idea as the Sentry: one wind-up cell, one settle cell. Gravity: orb brightening, then dimming. Swarm: hatch lid opening, then closing. Prism: crystal charging, then dimming. All three now fire in battle. |

Already used, no new art needed: the pilot's aim and lean in-betweens, idle
breathing, every enemy wing (drawn from parts), the hatchling (Luna's
`hive_hatchling.png` now shows as the Scout comes out of the sac), the Gear visor
and Quests tablet (they cross-fade cleanly).

Not used yet: `enemies/hive_lay_1.png` to `hive_lay_4.png` (whole-body laying
frames). The Hive Mother is drawn from parts now, so these are only needed if a
laying pose for the body itself is wanted later.
