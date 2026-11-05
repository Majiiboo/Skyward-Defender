# Luna brief: the HEROES (new playable characters)

Hi Luna! This brief has everything you need; no earlier brief or message is required.

## What this is for
The game is changing from "one pilot who collects armour pieces" to "a roster of HEROES":
six different characters the player unlocks one by one. Each hero is a complete character
you paint once, in parts, exactly the way you painted the pilot. The code moves the parts
(breathing, aiming, leaning, recoil, the turn) so every hero moves as smoothly as he does.
The pilot you already painted IS the first hero ("Rook"); nothing of yours is thrown away.

Rudy's one rule for the designs: **they must be clearly different from each other.** Not
six space soldiers. Different body shapes, different silhouettes, a different idea each,
some of them just for fun. The chibi proportions (big head, small body) and the rendered
3D look stay the same for all, so they feel like one game.

## The six heroes (paint them in this order; Sparks first)

| # | Hero | Element (light colour) | Who he is | Weapon in hand |
|---|---|---|---|---|
| 1 | **Sparks** | Electric (green-yellow) | A junkyard maintenance ROBOT: a round barrel body, one big round eye-lens for a face, stubby legs with rubber feet, two arms ending in welding torches. Dented, patched metal, a little antenna. Friendly, scrappy. | Arc Welder: the two small green torch-guns (one in each hand is fine; the code holds the right one) |
| 2 | **Captain Frost** | Ice (pale blue) | A PENGUIN in a bulky white spacesuit with a round fishbowl helmet; yellow beak, little flippers in thick gloves, big boots. Serious face, silly idea. | Frost Rifle: a long pale-blue rifle with a frosted barrel |
| 3 | **Hollow** | Void (purple) | A see-through GHOST ASTRONAUT: a hooded cloak over an old spacesuit, the visor empty and dark with two faint purple lights where eyes would be, cloak tatters trailing where the jetpack flame would be. Slightly transparent edges. | Pulse Cannon: a short wide purple cannon |
| 4 | **Nyx** | Dark (deep red on black) | A cat-eared NIGHT HUNTRESS: slim, black stealth armour with thin red light lines, a short cape, cat ears on the helmet, a long tail. Confident pose. | Dread Railgun: a long dark rifle with a red coil |
| 5 | **Ember** | Fire (orange-gold) | A small DRAGON-KIN: scales, two small horns, a tail, wings folded on the back, wearing a brass-and-leather flight harness. Fire comes out of the mouth instead of a jetpack flame. | Sun Rifle: a gold rifle with a glowing core |
| 6 | **Rook** | Energy (cyan) | The pilot you already made. Nothing to do. | Ion Pistol (done) |

## His own stance
Each hero may stand his own way on the Heroes page and on Home (Rudy): the reference pose
is still the relaxed "A" pose the code needs for the parts, but give each hero a little
attitude in it: Sparks leaning on one stubby leg, Captain Frost chest out, Hollow drifting
a hand's width off the ground (no feet contact; the code floats him), Nyx weight on one
hip, Ember wings half open. Keep arms away from the body and the weapon upright.

## Your earlier renders to match (open these first)
- `art_src/pilot/reference.webp`: the Commander pilot assembled. This sets the HEIGHT, the
  camera and the lighting for every hero.
- `art_src/pilot/parts_sheet.webp`: the pilot's 4 x 4 parts sheet. Every hero's parts sheet
  uses the same 16 cells in the same order (table below), the same cell size, the same
  black background, and parts at the same size as in the hero's own reference.
- `art_src/pilot/rifle_side.webp`: the weapon seen from the side, barrel up. Same for each
  hero's weapon.
- `art_src/turn/` (your `turn_commander_1..5.webp`): the five turn frames. Same five angles,
  same feet and head heights, for each hero.
- `art_src/starter/`: the Rookie suit, as an example of a second suit done the same way.

## Match the pilot's scale
Every hero must be the SAME HEIGHT as the pilot in `art_src/pilot/reference.webp` (helmet
top to boot sole), same camera height, same lighting (light from above and a little in
front, a cool rim light in the hero's element colour instead of cyan). If a hero is
naturally short (the penguin, the robot), make him the same height anyway: chibi rules.
Not layered files: every picture is a flat render on black. The game cuts the parts out of
the sheet by their cells and the light layers (cell 2) are separate pictures, so nothing
needs to be delivered as layers.

## Pictures per hero (all on a plain black background, no text, no frame, lower-case names)
Put each hero's pictures in `art_src/heroes/<hero>/` where `<hero>` is `sparks`,
`frost`, `hollow`, `nyx`, `ember`.

### 1. `reference.webp` (1024 x 1024)
The whole hero assembled, facing the camera, relaxed "A" pose: arms a little away from
the body, legs slightly apart, the weapon held upright in the RIGHT hand (on our left),
muzzle straight up. This is the map the code uses to put the parts back together.

### 2. `parts_sheet.webp` (4 x 4 grid, every cell 512 x 512, plain black)
The same cells as the pilot's sheet, each part at EXACTLY the size it has in the
reference (do not enlarge a part to fill its cell), same angle, same lighting:

| Cell | Part | Notes |
|---|---|---|
| 1 | Head | Helmet / head with the face DARK where the light will be (visor, eye-lens, eyes); include the neck stump |
| 2 | Face light | Only the glowing part of the face (visor line, eye-lens, eyes) in the element colour, same size and place as cell 1 |
| 3 | Torso | Chest / body. For Sparks this is the barrel. For Ember include the folded wings |
| 4 | Hips | Belt / pelvis (for Sparks a short ring under the barrel) |
| 5 | Right upper arm | Shoulder to elbow |
| 6 | Right forearm + hand | Hand closed in a grip (it holds the weapon) |
| 7 | Left upper arm | Shoulder to elbow |
| 8 | Left forearm + hand | Hand open |
| 9 | Right shoulder pad | Whatever sits on that shoulder (a pad, a bolt, a scale, or empty if the hero has none) |
| 10 | Left shoulder pad | Same |
| 11 | Right thigh | Hip to knee |
| 12 | Right shin + foot | Knee to sole |
| 13 | Left thigh | Hip to knee |
| 14 | Left shin + foot | Knee to sole |
| 15 | Back piece | The jetpack, or what takes its place: Hollow's cloak tatters, Ember's tail + wings root, Sparks' antenna box |
| 16 | Weapon | Pointing straight up, grip at the bottom |

Joints: paint every joint end ROUNDED with a little extra that tucks under the next part
(shoulders, elbows, hips, knees, neck), like an action figure, so nothing gaps when a part
turns. Keep every part in the same orientation as in the reference.

### 3. `weapon_side.webp` (1024 x 1024)
The weapon alone, seen from the side, barrel pointing straight up, grip at the bottom
(like `art_src/pilot/rifle_side.webp`).

### 4. `turn_1.webp` to `turn_5.webp` (1024 x 1024 each)
The whole hero turning round, exactly like the pilot's turn frames
(`LUNA-BRIEF-pilot-turn.md`): 1 = facing the LEFT side of the picture in three-quarter
view, 2 = an eighth turn toward the camera, 3 = facing the camera, 4 = an eighth turn past
it, 5 = facing the RIGHT side in three-quarter view. Feet at the same height in every
frame (about 90% down), head top at the same height (about 10% down). Weapon in the right
hand, barrel up, in front of the chest, the same in every frame. Arms and legs still.

### 5. `portrait.webp` (512 x 512)
Head and shoulders, facing the camera, for the roster buttons. Black background.

## Checklist for one hero
- [ ] Same height and camera as the pilot reference; chibi proportions.
- [ ] Clearly different silhouette from the other heroes.
- [ ] Light parts of the face dark in cell 1, glowing in cell 2.
- [ ] Parts at reference size, rounded joints, same orientation.
- [ ] Turn frames line up (feet and head heights).
- [ ] Files named exactly as above, `.webp`, black backgrounds.

## What the game does with each file (so the rules make sense)
- `reference.webp`: the code measures where each part sits (shoulders, hips, knees) on it,
  then puts the parts from the sheet back in those places and moves them: breathing, the
  aim, the lean, recoil. That is why the parts must be at reference size and orientation.
- `parts_sheet.webp` cell 2 (the face light) is drawn on top of cell 1 with a glow in the
  element colour, pulsing. Cell 15 (the back piece) is drawn behind the body; the flame or
  cloak animation is added by the code behind it.
- `weapon_side.webp`: drawn in the right hand, turned with the aim; the muzzle flash and the
  bolts (in the element colour) come from the code.
- `turn_1..5.webp`: shown one after another when the hero turns round in a fight.
- `portrait.webp`: the roster button on the Heroes page.

## Order of delivery
1. Sparks: `reference.webp`, `parts_sheet.webp`, `weapon_side.webp` (the game can use him
   with just these three; turn frames and portrait after).
2. Sparks: `turn_1..5.webp`, `portrait.webp`.
3. Captain Frost, the same two steps. Then Hollow, Nyx, Ember.

Any flag or doubt (a part that cannot be made, a design that does not read, a cell that
does not fit): send it back through Rudy before painting the next hero and we adjust the
brief. Thank you!
