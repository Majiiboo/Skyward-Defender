# Luna brief: new power cards and fusion cards (dev102)

Hi Luna! The power cards got two new layers:
- **Overcharge:** the third pick of the same card adds a bonus.
- **Fusion:** two overcharged cards that belong together unlock a rare fusion card. It keeps both powers and adds a new one.

There are also three brand-new cards. Right now the new cards borrow menu icons, and each fusion shows its two parent pictures side by side.

Same rules as your first card set:
- Plain black background, one picture per cell, nothing cropped at the edges.
- Square 512 x 512 cells, with the object filling about 70% of the cell.
- Same 3D style, light and camera angle as your other card pictures (Rapid Pulse, Heavy Bolts, etc.).
- No text or numbers painted in. The game adds names and descriptions.
- Our own designs: please don't copy other games.

## 1. Three new card pictures

| File name | Card | What it does | Picture idea |
|---|---|---|---|
| pic_chain_spark | Chain Spark | every 5th bolt sparks lightning to nearby bugs | a cyan bolt with forked lightning jumping off it to two or three small points |
| pic_wingman | Wingman Drone | a small drone flies beside the pilot and shoots | the little quad drone (the Patrol drone from Home) seen from the front, with a muzzle flash under it |
| pic_quick_study | Quick Study | gems give more XP | a glowing gem with an upward arrow or rising sparkles in purple light |

## 2. Four fusion card pictures (the rarest cards, so make them feel special)

Each one should clearly look like its two parent cards merged into one object, with a hot pink/magenta energy accent. That colour is the fusion colour in the game.

| File name | Fusion | Made from | What it does | Picture idea |
|---|---|---|---|---|
| pic_railstorm | Railstorm | Rapid Pulse + Heavy Bolts | every 4th bolt is a rail shot that pierces the whole line | the spinning energy ring from Rapid Pulse wrapped around a long, heavy rail bolt |
| pic_gem_barrage | Gem Barrage | Burst Fire + Magnet | every 10 gems fire a burst of 6 bolts | the magnet with gems turning into a fan of bolts as they fly in |
| pic_bastion | Bastion | Reinforced Hull + Aegis | when the shield breaks it blasts outward | the armour plate and heart shield fused into one fortress shield, with a shockwave ring bursting outwards |
| pic_storm_wing | Storm Wing | Chain Spark + Wingman Drone | the drone's shots chain lightning | the quad drone crackling with forked lightning between its rotors |

## 3. Card frames (two new frames)

Same size and shape as your existing card frames: 300 x 450, PNG, with a transparent window in the middle where the picture and text go. Please keep the window in the same place as on the other frames.

- **frame_fusion:** the frame for fusion cards. Your legendary frame with a hot pink/magenta edge, maybe two thin lines braided together to show two cards fused. It must look rarer than legendary.
- **frame_overcharge (optional):** a gold overlay or variant shown when a card is about to overcharge. Today the game draws a thin breathing gold line instead, so this one is a nice-to-have.

## Where they go
Save them with the file names above. I'll cut and drop them into cards/; each picture replaces its stand-in as soon as it arrives.
