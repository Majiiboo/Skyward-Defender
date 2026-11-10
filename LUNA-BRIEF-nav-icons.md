# Luna brief: NAV ICONS, round 2 (five bottom-bar icons, made to MOVE)

Hi Luna! This brief has everything you need; no earlier brief or message is required.
Thank you for round 1 (the nav2_* pictures). Rudy wants a second, stronger round. This time
the icons will be ANIMATED in the game, so besides the finished icons we need the moving pieces
as separate pictures. Section 6 explains exactly how, step by step.

Reference picture (send with this brief): `art_src/ref/nav_icons_ref2.png`. It has rows A to E;
this brief points to them. Rudy can also show you a short animated demo of the moves.

---

## 1. What the icons are for
- The bottom bar of every menu has five tabs: **Store, Heroes, Battle, Modes, Quests**.
- The bar is now a floating **glass pill**: a rounded capsule of see-through dark glass, sitting a
  little above the bottom of the screen. Behind it you see the game world, blurred: a lava planet,
  an ice planet, or cards on a menu page. So the icons must read on a dark background AND on a bright,
  busy one (row A).
- **Closed tabs:** the game turns the icon into a soft grey shape (no colours, half see-through).
- **The open tab:** full colour, a little bigger, its name in cyan under it, and it plays its own
  short move (section 5).
- **Size on a phone:** about 44 to 52 pixels tall. Tiny! Every shape must be bold.

## 2. What Rudy liked and what to change
- Rudy liked a test set he made with another tool (row B). Keep its IDEAS, not its pixels:
  - chunky, rounded silhouettes;
  - a chest with a DOMED lid;
  - a target with four bold ticks;
  - a planet with a bold tilted ring;
  - a clipboard with a big clip.
- From your round 1, keep your clean flat colours and your neat edges.
- Two things to change from round 1:
  - Your chest read as a briefcase when small: give it a rounded, domed lid.
  - The helmet: Rudy did not like either of your helmets (the round 1 one with two eyes, which read
    as a robot face, and the glossy one in the game today). So Heroes gets a completely NEW design:
    a pilot seen from head to shoulders, turned a little to the side (section 4, and my rough
    sketch in rows B and D).
- Goal: **your style, better shapes.** More chunky, more character, still flat.

## 3. The style (all five icons)
- **Flat 2D game icons.** Solid colour shapes only:
  - no gradients;
  - no glossy streaks;
  - no 3D render look;
  - no drop shadow;
  - no glow halo;
  - no text or letters.
- **Colours** (row E). Each icon has a navy body in two or three tones plus its bright accent colours:
  - navy light `#3D5280`, navy mid `#2C3B5E`, navy dark `#1A2540`;
  - outline `#111830`;
  - gold `#FFC845`, cyan `#4FE0FF`, red `#FF5470`;
  - purple `#8B5CF6` with purple dark `#6A3FD4`;
  - green `#6FF0B8`;
  - paper `#C9D6EA` (a pale blue-grey, NOT pure white: white was the brightest thing in the bar).
- **One flat "top light" shape is allowed.** For example, a lighter navy patch on the upper part of
  a dome. It must be a flat shape with a clean edge, not a soft gradient.
- **A dark outline round every icon:** `#111830`, about 28 px thick on the 1024 picture, the same
  on all five. It keeps the icon readable when the glass behind it is bright lava or white ice.
- **Chunky:**
  - nothing thinner than about 40 px on the 1024 picture (it shrinks to about 48 px, and thin lines vanish);
  - big rounded corners;
  - few details.
- **One family:** each icon fills about 80% of its square, centred, and all five look equally big and heavy.
- **The silhouette test (row D):** fill your icon solid grey. Can you still tell at once what it is?
  If not, change the shape, not the colours.
- **Background:** plain pure black `#000000`, nothing else in the picture.

## 4. The five icons
For each icon this lists what it is, the files we need, and the move the game will play. Every file
is **1024 x 1024**, pure black background, .webp or .png.

### STORE: a loot chest
- **What it is:** front view.
  - a DOMED lid (a rounded top), lighter navy;
  - the box under it, darker navy;
  - a dark strap across the middle where lid and box meet;
  - ONE gold latch in the middle of the strap. The latch is the only gold.
- **Files:**
  | File | What is in it |
  |---|---|
  | `nav3_store` | the whole chest, closed |
  | `nav3_store_body` | only the box (everything below the lid line), with a thin dark gap along its top edge, as if you could see into it |
  | `nav3_store_lid` | only the domed lid, in its closed position |
  | `nav3_store_latch` | only the gold latch |
  | `nav3_store_open` | the whole chest again, OPEN: the lid tipped back so it looks shorter and higher, and flat gold light and two or three coins showing inside. Same chest, same size, same place in the square. Row C has a rough idea |
- **The move:** the latch flashes, the chest hops, the lid pops open with gold light and sparkles,
  then it closes with a bounce. Idle: the latch glints now and then.

### HEROES: a pilot bust (NEW design)
- **The idea:** not a helmet on its own, but a little PILOT: head and shoulders, like a character
  portrait or a chess piece. Head + shoulders is the shape everyone reads as "a character", even
  as a grey blob. My rough sketch is in rows B and D of the picture; please make your own, nicer.
- **The view:** three-quarter view. The pilot is turned a little to OUR RIGHT, so we see the front of
  the helmet and a bit of its left side. Not straight on (that gave the robot face), not a full
  side profile.
- **From top to bottom:**
  1. **A crest.** A short, thick fin running over the top of the helmet from the forehead toward the
     back, like a fighter pilot's or a knight's crest. Navy mid. It gives the head a sporty
     silhouette that no robot or bell has.
  2. **The helmet.** A rounded, slightly egg-shaped helmet, a little fuller at the back. Navy light,
     with one flat lighter "top light" patch if you like.
  3. **The visor.** A BIG cyan window covering the front of the face and wrapping round toward the
     right side (like a motorbike or astronaut visor), with rounded corners. It is the biggest
     bright shape in the icon. Add ONE small flat highlight shape (pale cyan `#C8F7FF`) near its top
     edge. No eyes, no mouth, nothing drawn on or behind the visor.
  4. **A side light.** A small round ear disc on the visible side of the helmet (navy dark) with a
     small cyan light in its middle, like a radio.
  5. **A chin guard.** A dark navy band under the visor, following the jaw.
  6. **A collar.** A short dark ring between the helmet and the shoulders.
  7. **Shoulders.** Broad, chunky armour: two rounded shoulder pads (navy light) on a chest piece
     (navy mid). The shoulders are wider than the helmet, and the bottom edge is a straight line
     (the bust is cut off there).
- **Proportions:** the helmet is about half the icon's height. The shoulders fill the bottom third
  and the full width. Keep it chunky and chibi, like the game's heroes.
- **Silhouette check:** in solid grey it must read as "a pilot from the shoulders up" (row D).
- **Files:**
  | File | What is in it |
  |---|---|
  | `nav3_heroes` | the whole pilot bust |
  | `nav3_heroes_body` | only the shoulders, shoulder pads, chest piece and collar (no head). Paint the collar complete where the head would cover it |
  | `nav3_heroes_head` | only the head: helmet, crest, ear disc and chin guard. The visor window is painted as an EMPTY dark window (navy dark), and the ear disc's light is left out (navy dark too) |
  | `nav3_heroes_visor` | only the cyan visor, with its small highlight |
  | `nav3_heroes_light` | only the small cyan light from the ear disc |
- **The move:** the pilot pops up from the shoulders and the head turns to look at us for a moment,
  a light sweeps across the visor, and the ear light blinks. Idle: a small nod and the visor sweep.

### BATTLE: a target
- **What it is:**
  - a round navy disc with one lighter ring groove;
  - a RED inner ring with a red dot in the middle;
  - four short, thick CYAN ticks (top, bottom, left, right) that cross the edge of the disc.
- **Files:**
  | File | What is in it |
  |---|---|
  | `nav3_battle` | the whole target |
  | `nav3_battle_disc` | only the navy disc, complete, with nothing red or cyan on it |
  | `nav3_battle_rings` | only the red ring and the red dot |
  | `nav3_battle_ticks` | only the four cyan ticks, each in its place |
- **The move:** the four ticks spin in from outside and lock on, the red rings pulse, and a ring
  ripples out. Idle: the ticks tighten for a moment.

### MODES: a planet with a ring
- **What it is:**
  - a PURPLE planet, with darker purple on its lower part and two or three flat craters or bands;
  - a bold CYAN ring around it, tilted about 20 degrees (rising to the right).
  - The top half of the ring goes BEHIND the planet; the bottom half passes IN FRONT of it.
- **Files:**
  | File | What is in it |
  |---|---|
  | `nav3_modes` | the whole planet with its ring |
  | `nav3_modes_planet` | only the planet, a complete round ball with no ring on it |
  | `nav3_modes_ring_back` | only the TOP half of the ring (the part behind the planet), drawn complete, as if the planet were not there |
  | `nav3_modes_ring_front` | only the BOTTOM half of the ring (the part in front of the planet) |
  | `nav3_modes_moon` | a small round moon, about one eighth of the planet's width, pale cyan-white, alone in the middle of the picture |
  | `nav3_modes_surface` (nice to have) | the planet's craters and bands painted as a flat strip, twice as wide as the planet and the same height, whose left and right ends join up seamlessly. The game slides it inside the ball to make the planet turn slowly |
- **The move:** the planet bobs, a light runs along the ring, and the moon orbits: behind the planet on
  the top half, in front of it on the bottom half. Idle: the moon keeps orbiting.

### QUESTS: a clipboard
- **What it is:**
  - a navy board with pale paper on it (paper `#C9D6EA`, not white);
  - a big GOLD clip at the top;
  - three rows, each a small square box with a grey line beside it;
  - the first two boxes have GREEN ticks, the third box is empty.
- **Files:**
  | File | What is in it |
  |---|---|
  | `nav3_quests` | the whole clipboard, with two ticks |
  | `nav3_quests_board` | the board, paper, three empty boxes and grey lines: no clip, no ticks |
  | `nav3_quests_clip` | only the gold clip |
  | `nav3_quests_tick_1` | only the green tick of row 1, in its place |
  | `nav3_quests_tick_2` | only the green tick of row 2, in its place |
  | `nav3_quests_tick_3` | only a green tick for row 3, sitting in the third box (that box is empty in the whole picture) |
- **The move:** the clip snaps down and the ticks "write" themselves in one by one. When a quest is
  ready to claim, the third tick pops in. Idle: the clip snaps.

### One shared extra
- `nav3_spark`: a small four-pointed star sparkle, gold-white, flat, alone in the middle of the
  picture. The game scatters copies of it when the chest opens and when a quest is done.

## 5. What the game does (so you know what NOT to paint)
- The game cuts every picture out of the black, shrinks it, stacks the parts and moves them.
- The code makes all of these, so you don't need to paint any of them:
  - the grey look of closed tabs;
  - the hops, squashes and bounces;
  - the light sweeps;
  - the ripple ring;
  - the moon's path;
  - the sparkle bursts.
- The only "action" picture you paint is the open chest (`nav3_store_open`).

## 6. How to make the parts (step by step)
Rule number one: a part must sit in EXACTLY the same spot and size as in the whole icon. If we put all
the parts of an icon on top of each other, we must get the whole icon back, pixel on pixel (row C).
1. Paint the whole icon first (for example `nav3_store`). Get it right and approved in your head before the parts.
2. Make a copy of that same picture. Do NOT move, resize, crop or re-render it.
3. In the copy, paint everything black EXCEPT the one part you want (for example, keep only the gold
   latch). Save it with the part's name (`nav3_store_latch`).
4. Repeat for every part, always starting from a fresh copy of the whole picture.
5. Some parts hide something behind them: the planet behind the ring, the empty window behind the
   visor, the collar behind the head, the disc behind the red rings. In those files, paint the hidden area complete, the way it would
   look without the part on top. If that is hard, leave it: the game can patch small holes itself.
6. Keep the colour rule: each moving part has a colour that appears nowhere else in that icon. The
   latch is the only gold, the visor and the ear light are the only cyan on the pilot, the rings are
   the only red. That way the game can also find the parts by colour.
7. For the open chest (`nav3_store_open`), paint a new picture, but keep the box exactly where it is in
   `nav3_store`. Only the lid moves.

## 7. Tips for the image tool (if it helps)
> flat vector game icon, chunky rounded shapes, front view (for the Heroes pilot bust: three-quarter
> view, turned slightly right), dark navy body in two tones with a dark
> navy outline, one bright [gold / cyan / red / purple / green] accent, centred, plain pure black
> background, no text, no gradients, no 3D, no glossy highlights, no shadow, no glow

## 8. Checklist
- [ ] 26 pictures (27 with the nice-to-have), 1024 x 1024, pure black background, .webp or .png,
      named exactly:
  - [ ] Store (5): `nav3_store`, `nav3_store_body`, `nav3_store_lid`, `nav3_store_latch`, `nav3_store_open`
  - [ ] Heroes (5): `nav3_heroes`, `nav3_heroes_body`, `nav3_heroes_head`, `nav3_heroes_visor`,
        `nav3_heroes_light`
  - [ ] Battle (4): `nav3_battle`, `nav3_battle_disc`, `nav3_battle_rings`, `nav3_battle_ticks`
  - [ ] Modes (5, plus 1 nice to have): `nav3_modes`, `nav3_modes_planet`, `nav3_modes_ring_back`,
        `nav3_modes_ring_front`, `nav3_modes_moon` (+ `nav3_modes_surface`)
  - [ ] Quests (6): `nav3_quests`, `nav3_quests_board`, `nav3_quests_clip`, `nav3_quests_tick_1`,
        `nav3_quests_tick_2`, `nav3_quests_tick_3`
  - [ ] Shared (1): `nav3_spark`
- [ ] Flat: navy body + its accent colours from section 3, a dark outline, no gloss, no 3D, no glow, no text.
- [ ] Chunky shapes, nothing thinner than about 40 px at 1024; all five the same size and weight.
- [ ] Each icon passes the silhouette test (filled solid grey, it still reads at once).
- [ ] Every part sits in exactly the same spot as in its whole icon (stacking the parts rebuilds the icon).
