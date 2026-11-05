# Luna brief: the pilot turning round (whole-body frames)

Hi Luna! This brief has everything you need; no earlier brief or message is required.

## What this is for
When the player drags the pilot from one side to the other he turns to face the new way.
Today the code fakes the turn: it narrows the side view a little, fades in your front view,
then fades to the mirrored side view. It reads as a flip, not a turn. Real turn frames of
the WHOLE pilot fix that: the code will show your frames one after another (cross-fading)
during the half second of the turn, then hand back to the moving rig.

## Match this picture exactly
`art_src/pilot/reference.webp` (your chibi pilot, Commander armour, gun raised in his
right hand). Same character, same armour, same size, same camera height, same lighting.
Also `art_src/starter/pilot-front-parts.webp` shows the Rookie suit; see "Both suits".

## Rules for every picture
- **1024 x 1024, pure black background**, the pilot centred, feet at the same height in
  every frame (about 90% of the way down), helmet top at the same height (about 10% down).
  If the frames do not line up, the turn will wobble; please check them over each other.
- **The gun held the SAME way in every frame:** in his right hand, barrel up, held in front
  of the chest (a "ready" pose). It must not point at the camera and must not wave about,
  because the code cannot move it during these frames.
- **Arms and legs still:** no stride, no swing. Only the body angle changes.
- **Same style and lighting** as the reference. No text, no frame, nothing cropped.
- File names exactly as below, lower case, `.webp`.

## The frames (5 for one direction; the code mirrors them for the other)

| File | What is in it |
|---|---|
| `turn_commander_1.webp` | facing the LEFT side of the picture, three-quarter view (like the reference, but with the gun in the ready pose above) |
| `turn_commander_2.webp` | turned a bit more toward the camera (an eighth turn past frame 1) |
| `turn_commander_3.webp` | facing the camera straight on |
| `turn_commander_4.webp` | an eighth turn past the camera, now starting to face RIGHT |
| `turn_commander_5.webp` | facing the RIGHT side, three-quarter view (the mirror of frame 1, with the gun still in his right hand, which is now the far hand) |

Frames 4 and 5 are needed as real renders (not mirrors) because the gun hand makes him
asymmetric: on the way round, the gun passes in front of his body and ends up on the far
side.

## Both suits
The same five frames for the Rookie suit: `turn_rookie_1.webp` to `turn_rookie_5.webp`,
matching `art_src/starter/pilot-front-parts.webp` in style.

## Checklist (each picture)
- [ ] 1024 x 1024, black background, pilot centred, feet and helmet top at the same heights.
- [ ] Gun in the right hand, barrel up, in front of the chest, same in every frame.
- [ ] Arms and legs still; only the body angle changes.
- [ ] Same style, lighting and size as the reference.
- [ ] File name exactly as in the table.

If time is short: frames 1, 3 and 5 for the Commander suit first; the code can blend
those three and add 2 and 4 later.
