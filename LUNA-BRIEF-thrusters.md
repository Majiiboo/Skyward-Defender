# Luna brief: thruster flames as layers (for the new 3D pilot)

Hi Luna! The new pilot needs flames that match his 3D look. Flames move all the time,
so please paint them as separate LAYERS, not finished frames: the game stretches,
flickers and fades the layers every frame, so the flame grows when he climbs,
shrinks when he drops, and never repeats or stutters.

## Rules for every cell
- Plain black background (the game adds the layers as light, black disappears).
- Flame pointing STRAIGHT DOWN, centred, starting at the top edge of the cell
  (that's where the nozzle is) and fading to nothing before the bottom edge.
- Soft edges, nothing cut off at the cell border.
- Plumes: 256 wide x 512 tall cells. Puffs and particles: 256 x 256 cells.

## Five styles, one row each
| Style | Cell 1: outer plume | Cell 2: inner core | Cell 3: nozzle glow | Cell 4: particle |
|---|---|---|---|---|
| Ion Flame (default) | Wide soft blue-cyan plume | Thin white-hot core | Round cyan glow | Small blue spark |
| Plasma Jet | Narrow pale-cyan jet | Needle-thin white core with a crackle | Bright white-blue ring | Tiny electric arc |
| Pressure Wave | Clear heat haze cone, faint | (none) | Pale ring of force | Ring-shaped shock wave |
| Gravity Well | Dark purple swirl, no fire | Faint violet core | Dark ring with purple rim | Falling purple speck |
| Pixel Burn | Chunky pixel-art plume (big square pixels, orange-yellow-white) | (none) | Square glow | Single square ember |

Optional, if easy: a soft grey smoke puff (256 x 256) for launch and landing.

Thank you!
