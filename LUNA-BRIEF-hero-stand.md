# Luna brief: the HERO STAND (the glowing hover disc under the hero)

Hi Luna! This brief has everything you need; no earlier brief or message is required.

## What this is for
On the Heroes page the chosen hero floats in the middle of the screen, big. Under him there
is no longer a base or a building (the old platform with the little buildings is gone). In
its place: a glowing hover disc, like a holographic display stand, that he floats above.
The code floats the hero up and down over it, pulses the glow in the hero's element colour,
and spins the rings slowly. So the stand is painted as three separate layers on black.

## The look
A flat round disc seen from a low three-quarter angle (we see its top as an ellipse about
2.6 times wider than tall), dark blue-black glass and bevelled metal, with thin light lines.
Match the materials of `art_src/battle/base_strip.webp` and `gear/platform_floor.png`
(the old stand: same metal and glass, but THIS one has no buildings, no walls, nothing on
top; it is a thin disc with light).

## Pictures (all 1024 x 512, black background, the disc centred, about 900 px wide)
| File | What is in it |
|---|---|
| `stand_disc.webp` | the disc itself: the glass top (opaque dark, a faint grid of fine lines etched in it), the metal rim with a soft bevel, a thinner second ring floating 20 px above the rim's edge (a holographic ring). Light from above. NO glow colour here: paint all light lines in plain WHITE (the code colours them) |
| `stand_glow.webp` | ONLY the light: the etched grid lines, the rim light and the floating ring, glowing white on black, exactly in the same place and size as in stand_disc. The code draws this on top in the element colour and pulses it |
| `stand_beam.webp` | a soft column of light rising from the disc, 1024 x 1024 for this one: a vertical cone of faint white light, wide at the bottom (the disc's width), narrowing to nothing at the top of the picture, with a few small floating specks. Black background. The code tints it and fades it behind the hero |

## Common mistakes to avoid
- Buildings, walls, antennas or any object on the disc. A thin disc only.
- Colour in the light lines (white only; the game colours them per hero).
- The glow painted into the disc picture (it is its own file).
- A floor or shadow around the disc (black everywhere outside it).

## Checklist
- [ ] stand_disc (disc, metal, white light lines), stand_glow (lights only), stand_beam (cone).
- [ ] Low three-quarter angle, ellipse about 2.6 : 1, centred, black background.
Thank you! A small job: the disc and the glow first; the beam can follow.
