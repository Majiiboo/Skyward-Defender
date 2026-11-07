# Luna guide: turn two of your renders into 3D models (a test)

Hi Luna! This guide has everything you need; you don't need any earlier brief or message. It's a small TEST with a new kind of tool, so take your time, and it's fine if it takes a few tries.

## Why we're doing this
In the game, the hero and the turrets are flat pictures. When you turn Rook on the Heroes page, the game fades from one of your pictures to the next, and you can see the fade. When the Lance turret aims, the game rotates a flat side-view picture, so its laser drifts away from the tip.

The fix we want to try: turn your pictures into **3D models**. A 3D model can be spun to any angle. Claude then takes "photos" of each model from many angles inside the game engine, with the same lighting every time. Every frame comes from the same model, so they line up perfectly: Rook will turn smoothly, and the Lance's beam will always come out of its tip.

**Your part:** feed four pictures (already prepared, in the zip) into an image-to-3D website and send back the 3D files. You don't model anything by hand.

## What's in the zip
| File | What it is | Taken from your render |
|---|---|---|
| `1_rook_front.png` | Rook, standing, facing the camera | `turn_commander_3` (your Commander turn frame 3) |
| `2_rook_back.png` | Rook seen from behind | `turn_commander_7` (your Commander turn frame 7) |
| `3_lance_base.png` | The Lance turret's base (the low armoured hex platform) | the top-left piece of your turret-heads sheet |
| `4_lance_head.png` | The Lance turret's head (the long twin-barrel cannon) | the top-right piece of your turret-heads sheet |

All four already have a see-through background, so the tool only sees the object.

## Step 1: pick the tool and make an account
Use **Meshy** (meshy.ai). If you don't like its results, try **Tripo** (tripo3d.ai) instead; both work the same way.
1. Open the website and sign up (a free account is enough for this test).
2. Find the **Image to 3D** option. The button names change sometimes; look for "Image to 3D".

## Step 2: make the Lance base
1. Choose **Image to 3D** and upload `3_lance_base.png`.
2. If it asks for settings, choose:
   - **Texture: ON** (the model must keep your colours and glowing lines).
   - **PBR: ON**, if there's such a switch.
   - **Detail / polycount: medium.** If it asks for a number, about **15,000**.
   - **Style:** keep the look of the picture. Don't pick "cartoon" or another style.
3. Press generate and wait.
4. Spin the result with your mouse and check:
   - From the top-front it looks like your picture.
   - The bottom is flat (it sits in a round socket on the deck).
   - No holes, and no melted or blobby areas.
5. Not good? Press **regenerate** (2 or 3 tries is normal) and keep the best one.
6. **Download as GLB** (choose "GLB" as the file type, with textures). Name it `lance_base.glb`.

## Step 3: make the Lance head
Same as Step 2, with `4_lance_head.png`, about **15,000** polycount.
- **Check:** the barrels are straight and round all the way along (not flat, not bent), and both barrels are there.
- **Download as GLB**, named `lance_head.glb`.

The base and the head must be **two separate models**, because the game turns the head on top of the base.

## Step 4: make Rook
1. Choose **Image to 3D** and upload `1_rook_front.png`.
2. **If the tool has a "multi-view" or "multiple images" option,** use it: put `1_rook_front.png` as the **front** and `2_rook_back.png` as the **back**. That gives a much better back.
3. Settings: Texture ON, PBR ON, polycount about **30,000**, keep the look of the picture.
4. **Check:**
   - From the front he looks like your render: the big round helmet, the cyan visor slit, the purple and cyan light lines, the rifle held upright.
   - From behind, the jetpack is there, not a smooth blob.
   - The head isn't squashed and the feet are flat.
5. Regenerate if needed, then **download as GLB**, named `rook.glb`.

## Step 5 (bonus, only if the tool offers it): a moving Rook
Some tools can add a **skeleton ("rig")** to a character and give him **animations** (idle, walk, shoot). If you see **"Rig"**, **"Auto-rig"** or **"Animate"** next to the Rook model:
1. Try it, picking **humanoid / biped**.
2. If it works (arms and legs move without tearing the model), download that version as **`rook_rigged.glb`**, plus the **idle** animation if you can choose one.
3. If it fails or looks broken, skip it. That's useful to know too.

## Step 6: take three quick screenshots of each model
In the tool's viewer: **front, side, back**, one screenshot each, for each model. They help Rudy and Claude judge the results before trying them in the game.

## What to send Rudy
- `lance_base.glb`
- `lance_head.glb`
- `rook.glb`
- `rook_rigged.glb` (only if Step 5 worked)
- The screenshots (front / side / back of each)
- A line on which tool you used, and anything odd you noticed.

## Mistakes to avoid
- Downloading as OBJ or FBX instead of **GLB**.
- Texture switched off (a grey model is no use).
- Base and head of the Lance merged into one model.
- Picking a different art style in the tool.
- Keeping a first try that has holes or melted parts (regenerate instead).

## Checklist
- [ ] Lance base: GLB, textured, flat bottom, no holes.
- [ ] Lance head: GLB, textured, straight round barrels, a separate model.
- [ ] Rook: GLB, textured, looks like the front render, a real jetpack on the back.
- [ ] (Bonus) Rook rigged, if the tool offered it.
- [ ] Front / side / back screenshots of each.
