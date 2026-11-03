# Luna brief: art for the next build (dev87)

Hi Luna! Your new pilot, base and turrets set the look of the whole game now:
rendered 3D style, charcoal armour with cyan and purple light lines, light from above
and a little in front, a cool cyan rim. This list is everything still drawn in code or
still in the older style, most important first. Do as many as you like; each one is
used on its own as soon as it arrives.

Rules for every sheet (same as always):
- Plain black background, nothing cropped at the cell edges, one object per cell.
- Same style, light and camera angle as your base and turrets.
- No text or numbers painted in (the game adds them).
- Our own designs: please don't copy other games.

## 1. Battle backgrounds (biggest change)
See LUNA-BRIEF-backgrounds.md. Area 1 (the Hive world), Zone A first.

## 2. Power card pictures (seen many times every run)
The cards you pick on each level-up still borrow menu icons. One picture per card,
centred, square 512 x 512 cells, the object filling about 70% of the cell. The game
puts them inside your existing card frames (common / uncommon / epic / legendary).

| Card | What it does | Picture idea |
|---|---|---|
| Rapid Pulse | fires faster | the rifle's barrel with a spinning cyan energy ring around it |
| Heavy Bolts | bolts hit harder | one big glowing cyan bolt, chunky and heavy |
| Burst Fire | fires 2-4 bolts at once | three bolts side by side in a tight fan |
| Aegis | +1 heart | a heart-shaped energy shield with an armour frame |
| Magnet | pulls gems from further | a horseshoe-style magnet pulling small gems in |
| Reinforced Hull | stronger base | an armour plate with rivets and a cyan edge |
| Nova Burst | clears the screen | a white-gold explosion ring, the rarest card |

## 3. Battle pickups and shots (on screen all the time)
- Gems the bugs drop, four kinds, 256 x 256 cells: blue shard (small), purple prism,
  red ember, gold star (biggest, rarest). Faceted crystals with a soft inner glow.
- The pilot's bolt: a cyan energy bolt pointing RIGHT, 512 x 128, bright core.
- Bolt hitting a bug: a small cyan impact spark, 256 x 256.
- Spitter goo: a purple goo glob, 256 x 256 (the shot the Spitter bugs spit).

## 4. Locked turret socket (new feature)
The four turret sockets on the base now open one by one as the player clears stages
(after stages 5, 15, 25, 40). A locked socket needs a cover:
- An armoured shutter or hatch that sits over ONE socket ring, same camera angle as
  your base strip, sized to the socket ring with a little margin. 512 x 512 cell.
- Three cells: closed (a small lock light glowing), half open, fully open (folded
  away into the deck). The game plays them when a socket unlocks.

## 5. Home screen buttons that move
The Chest and Patrol buttons beside START should come alive, like the nav icons do.
Paint them as LAYERS so the game can animate them, 512 x 512 cells, same framing:
- Patrol: a small scout drone. Cell 1: the drone body with no propellers. Cell 2: one
  propeller blade on its own (the game spins it, so draw it seen from above, centred).
  Cell 3: a soft thruster glow under the drone.
- Chest: cell 1 the chest body with no lid, cell 2 the lid alone in its closed place,
  cell 3 the light that spills out when it opens.

## 6. Small UI icons in the new style (256 x 256 each)
Coin, crystal (premium currency), energy bolt (stamina), heart, the pilot level
badge frame (empty inside, the game writes the number), and a small padlock.

## 7. Pilot parts, round 3 (after Rudy has played with the new pilot)
The game now builds the pilot from your parts and they look great. Two things don't
quite match your assembled reference picture:
- The arms and legs on the parts sheet are longer and thinner than the short, chunky
  ones in the reference, so they had to be shrunk. Please repaint: right upper arm,
  right forearm with fist, left upper arm, left forearm with open hand, one thigh, one
  shin with boot. At EXACTLY the size they have in the reference picture.
- Cover the knees and elbows with armour so no ball joint shows when they bend.

## 8. Later, after the backgrounds: the Hive bugs in the 3D style
Scout, Drifter, Spitter, Diver and the Hive Mother as parts, laid out like your
current ones (a body and one wing each; the Hive Mother with body, wing, full sacs,
empty sacs and both claws), so they match the new pilot and backgrounds. Also two
frames from the old animation list: the Hive Mother's sacs bursting, and the Spitter
with its sac squeezed and a glob leaving its mouth.

Not needed any more from LUNA-BRIEF-animation.md: the pilot turn-around and the
turret in-between frames (the new pilot and turrets move in code now).

Thank you!
