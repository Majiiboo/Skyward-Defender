# Luna brief: the STAR MAP (the pilot's talent map as a galactic chart)

Hi Luna! This brief has everything you need; no earlier brief or message is required.

## What this is
The pilot has a TALENT MAP: forty small permanent bonuses bought one after another. Rudy
wants it to look like a GALACTIC STAR CHART, not a list: four CONSTELLATIONS of ten stars,
each constellation a figure, charted star by star along its lines, the tenth star the figure's
key point. The game already draws it in code (see the two reference pictures in
`art_src/ref/talent_map_ref.png` and `talent_map_ref_next.png`: the code version, with the
constellation names and where every star sits). Your pieces replace the code stars and the
plain nebulae; the code keeps placing the stars and drawing the lines.

## The four constellations (top to bottom)
| # | name | colour of its light | the figure (an old star-chart drawing, faint, behind the stars) |
|---|---|---|---|
| 0 | THE RIFLE | cyan 33D9FF | a long laser rifle seen from the side, stock bottom-left, muzzle top-right |
| 1 | THE SENTRY | green 73FF59 | a gun turret: a round base at the bottom, a column, a head with two barrels pointing up-right |
| 2 | THE HIVE MOTHER | purple B573FF | a giant insect queen seen from above: tail at the bottom, two wide wings, a crowned head at the top |
| 3 | THE DOME | gold FFB347 | a flat deck along the bottom and a dome arching over it, an emitter beam rising from the top |

Where the ten stars of each figure sit (shares of the picture width x and height y, 0 = left /
top, 1 = right / bottom), in charting order; star 10 is the key point:

- THE RIFLE: (0.10, 0.80) (0.20, 0.72) (0.25, 0.88) (0.31, 0.67) (0.42, 0.61) (0.52, 0.56) (0.63, 0.50) (0.74, 0.44) (0.84, 0.38) (0.92, 0.28) = the muzzle
- THE SENTRY: (0.30, 0.88) (0.50, 0.93) (0.70, 0.88) (0.53, 0.76) (0.50, 0.62) (0.38, 0.52) (0.62, 0.52) (0.46, 0.38) (0.60, 0.26) (0.70, 0.12) = the barrel tip
- THE HIVE MOTHER: (0.50, 0.92) (0.50, 0.76) (0.34, 0.66) (0.12, 0.54) (0.38, 0.54) (0.62, 0.54) (0.88, 0.54) (0.66, 0.66) (0.50, 0.42) (0.50, 0.22) = the crown
- THE DOME: (0.08, 0.84) (0.27, 0.86) (0.46, 0.86) (0.65, 0.86) (0.86, 0.84) (0.82, 0.62) (0.70, 0.42) (0.50, 0.32) (0.28, 0.42) (0.50, 0.12) = the emitter

The figure drawing should pass THROUGH those points (the stars are its joints), like the
figures on an old celestial chart. Faint: the stars and lines must still read on top of it.

## 1. Four constellation skies (1024 x 1152, black background)
IMPORTANT: the top 15% and the bottom 15% of every sky must fade to pure black, because the
game overlaps each sky into the next one so the constellations blend together with no line
between them (Rudy: a gradient from one into the next, never a cut).
`art_src/talents/nebula_0.webp` .. `nebula_3.webp`, one per constellation in the order above.
Each: deep space, a soft nebula in that constellation's colour (drifting from one corner,
never a hard edge), a scatter of tiny far stars, and the FIGURE as faint ghost line art in a
lighter tint of the same colour (think ink lines on an old chart, 15-25% strength). No text,
no bright spots where the ten stars go (the game draws those). The picture is stretched to
480 x 540 on the phone, so keep the figure's proportions as in the point lists above.

## 2. The stars (512 x 512, black background, centred)
Three states of a small star and three of the key-point STAR SYSTEM:
- `node_dim.webp`: a small grey-white four-point star, unlit, no glow.
- `node_lit.webp`: the same star lit, WHITE core with a soft white glow (the game tints it
  with the constellation's colour).
- `node_next.webp`: the same star lit with a thin ring around it (the game pulses it).
- `system_dim.webp`: a small planet with a thin ring, dark and unlit.
- `system_lit.webp`: the planet lit, white-gold, its ring glowing, a soft glow round it.
- `system_next.webp`: the lit planet with a thin outer ring.
Same style as your icons (icons2): clean, rendered, light on black. Each star fills about
60% of its picture so the glow has room. The game draws small stars at 20 px and systems at
30 px on the phone, so simple shapes, no fine detail.

## Common mistakes to avoid
- A bright star painted into the sky where a node sits (the code draws every star).
- Hard edges on the nebula or the figure (everything fades into black).
- Text or numbers in the pictures.

## Checklist
- [ ] `nebula_0..3.webp` (1024 x 1152, black)
- [ ] `node_dim / node_lit / node_next.webp` (512, black)
- [ ] `system_dim / system_lit / system_next.webp` (512, black)
Thank you! If time is short: the four skies first; the code stars hold up fine.
