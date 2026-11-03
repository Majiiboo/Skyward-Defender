# Luna brief: the pilot in parts (3D look)

Hi Luna! We want the pilot to move like a modern game: smooth breathing, aiming,
leaning and recoil at any speed. Instead of many full poses, please paint him once,
in the new 3D-rendered style of the base and turrets, split into separate parts.
The game moves the parts itself (like the bug wings), so every motion stays perfectly
smooth and his look never changes between frames.

## Style
- Same character as now: chibi armoured pilot, big helmet, charcoal armour with
  purple and cyan light lines, jetpack. Rendered 3D look like your new turrets.
- Light from above and slightly in front, a cool cyan rim light. No floor shadow.
- Plain black background in every cell. No glow spilling outside a part (the game adds
  the glows).

## Sheet 1: the assembled reference (one 1024 x 1024 cell)
The whole pilot put together, facing the camera, standing in a relaxed "A" pose:
arms held a little away from the body, legs slightly apart, rifle held upright in his
right hand (on our left), muzzle pointing straight up. This is the map the game uses to
put the parts back together, so the parts in sheet 2 must match it exactly.

## Sheet 2: the parts (4 x 4 grid, every cell 512 x 512, plain black)
VERY IMPORTANT: every part at exactly the same size as in the reference (do not
scale parts up to fill their cell), same angle, same lighting.

| Cell | Part | Notes |
|---|---|---|
| 1 | Helmet (head) | Visor painted DARK, the game lights it. Include the neck stump. |
| 2 | Visor glow | Just the visor shape, glowing cyan, on black (same size/place as cell 1). |
| 3 | Torso | Chest armour with the round orb socket in the middle (empty, dark). |
| 4 | Hips | Belt / pelvis armour. |
| 5 | Right upper arm | Shoulder to elbow. |
| 6 | Right forearm + hand | Hand closed in a grip (it holds the rifle). |
| 7 | Left upper arm | Shoulder to elbow. |
| 8 | Left forearm + hand | Hand open in a supporting grip. |
| 9 | Right shoulder pad | Sits over the shoulder joint. |
| 10 | Left shoulder pad | Sits over the shoulder joint. |
| 11 | Right thigh | Hip to knee. |
| 12 | Right shin + boot | Knee to sole, nozzle-ready sole. |
| 13 | Left thigh | Hip to knee. |
| 14 | Left shin + boot | Knee to sole. |
| 15 | Jetpack | Seen from the front-behind the body, nozzle at the bottom. |
| 16 | Rifle | Pointing straight up, grip at the bottom. |

## Joints (so nothing shows a gap when parts turn)
- Paint each joint end ROUNDED with a little extra armour that tucks under the next
  part: shoulders, elbows, hips, knees, neck. Like an action figure's ball joints.
- Upper arms and thighs: round tops. Forearms and shins: round tops that slide under
  the elbow and knee.
- Keep the parts in the same orientation as in the reference (don't rotate them to fit
  the cell).

Thank you! If this test looks good in the game, the bugs come next in the same way.
