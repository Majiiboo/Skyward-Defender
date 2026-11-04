# Luna brief: merge effect layers (complete, standalone)

Hi Luna! This brief has everything you need; you don't need any earlier brief or message.

## What this is for
The game is a mobile shooter with a chibi armoured pilot. In the game's **Workshop**, players merge 3 of something into 1 better thing. For example, 3 Alloy Scraps become 1 Plasma Cell, and later 3 gear pieces become a stronger one.

When a merge happens, the game plays a short animation (about 2 seconds):
1. The 3 items spiral into the middle of the screen.
2. A glowing swirl spins faster and faster.
3. A bright flash and a shock wave burst out.
4. The new item pops out with light rays behind it.

The game moves, spins, grows and fades your pictures to make the animation. **You paint each glowing part as its own separate picture (a "layer")**; the game stacks them on top of each other.

## The most important rule: paint the light WHITE
Paint every glowing layer in **white and very pale silver-blue**, with no strong colour. The game tints each layer to the colour of the item being made: teal for a Plasma Cell, gold for a Void Core, purple for a Void set piece, and so on. A white layer can turn any colour, but a coloured one can't.

## Image rules (every layer)
- **Background:** pure black. Black turns see-through in the game, so the glow must fade smoothly into black, with no hard edges.
- **Centre:** each layer is centred exactly in the middle of its picture, so all the layers line up.
- **Room:** nothing touches the picture's edge. Leave black space all around.
- **Contents:** no text, no items, no pilot, no frame, no floor. Only the effect.
- **Look:** the same polished glow style as your other effects (the nova ring and the prism burst), soft and bright, not cartoon outlines.
- **Files:** one picture per layer, named as below.

## The 7 layers

### 1. `merge_swirl` (1024 × 1024)
A round **swirling vortex**, like a galaxy or a whirlpool seen from above: 4–5 curved arms of white light spiralling into a bright centre. Soft and misty, with tiny sparkles along the arms. It must look fine while spinning, so keep it roughly round with no straight edges.

### 2. `merge_ring` (1024 × 1024)
A **thin, bright energy ring**: a perfect circle of white light about as wide as 3/4 of the picture, with small evenly spaced tick marks or tiny runes around it, like a sci-fi dial. The inside of the ring is empty black.

### 3. `merge_flash` (1024 × 1024)
A **bright star flash**: a hot white centre with 8 sharp light spikes (4 long and 4 short, like a lens flare star), and a soft glow around it fading to black.

### 4. `merge_shock` (1024 × 1024)
A **shock-wave ring**: a soft, blurry ring of white light, thicker on the outside edge and fading towards the inside, like the edge of a ripple in water. Empty black in the middle. The game grows it from small to big.

### 5. `merge_rays` (1024 × 1024)
**Light rays** shining out from the centre: 12 soft rays of slightly different widths and lengths, bright at the centre and fading to nothing at their tips, like sunlight through clouds. The centre itself is just a soft glow.

### 6. `merge_sparks` (1536 × 256)
**Six small particles** in one row, each in its own 256 × 256 square, each centred:
1. a round soft spark,
2. a four-point twinkle star,
3. a thin streak (pointing up),
4. a small glowing crystal shard,
5. a tiny ring,
6. a puff of glowing dust.

All white.

### 7. `merge_chamber` (1024 × 1024): NOT white, NOT see-through
The only solid layer. A **round merge machine seen from the front**:
- A flat circular metal frame (like a big round porthole or a stargate), dark graphite metal with thin cyan light lines.
- 3 small emitter prongs pointing to the centre, at 12 o'clock, 4 o'clock and 8 o'clock (that's where the 3 items start).
- Empty black in the middle.
- The same 3D-rendered look as the pilot and the gear: real metal, bevels, small bolts, a thin cool rim light. No brush strokes.

## Mistakes to avoid
- Coloured glow (it must be white so the game can colour it).
- Glow cut off at the picture's edge.
- Text, numbers, or items drawn into the effect.
- Layers that aren't centred.

## Order
1. merge_swirl
2. merge_flash
3. merge_shock
4. merge_rays
5. merge_ring
6. merge_sparks
7. merge_chamber

## Checklist (each layer)
- [ ] Pure black background, glow fading softly to black.
- [ ] White / pale silver-blue light (except merge_chamber).
- [ ] Centred, with black space all around, nothing touching the edge.
- [ ] The right size: 1024 × 1024, or 1536 × 256 for the sparks.
- [ ] No text, no items.
