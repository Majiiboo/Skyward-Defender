# Luna brief: NAV ICONS (five icons for the bottom bar, a new flat style)

Hi Luna! This brief has everything you need; no earlier brief or message is required.

## What this is for
The bottom bar of every menu has five tabs: Store, Heroes, Battle, Modes, Quests. The game
just got a new clean look (flat cards, no gloss), and Rudy feels the current glossy 3D tab
icons no longer fit it. He picked a NEW STYLE for them: flat, two-tone game icons. You paint
the final five.

Reference picture (a quick code sketch of the idea, NOT the final art; please make yours
cleaner and nicer): `art_src/ref/nav_icons_ref.png` (Rudy sends it with this brief).

## The style (this is different from your usual 3D renders)
- FLAT 2D, like a modern mobile game icon. No 3D render, no glossy highlights, no bevels, no
  shine streaks, no drop shadow, no glow halo around the icon.
- TWO-TONE: every icon is a dark navy body plus ONE bright accent colour. You may use two
  shades of the navy (a lighter top part, a darker lower part) to give it shape; that is all
  the shading it needs.
  - navy light `#3D5280`, navy dark `#2C3B5E`, navy darkest for small lines `#1A2540`
  - the accent colours are given per icon below (gold `#FFC845`, cyan `#4FE0FF`, red
    `#FF5470`, purple `#8B5CF6` with a darker `#6A3FD4`, green `#6FF0B8`).
- BOLD, SIMPLE SHAPES with rounded corners. The game shows them SMALL (about 36 px tall on
  a phone), so no thin lines, no tiny details, no text or letters.
- All five the same size and weight, like one family: each fills about 75% of its square
  and sits in the centre.
- Plain pure black background (`#000000`), nothing else in the picture.

## The five icons (one picture each, 1024 x 1024, pure black background)
| File name (exactly) | Tab | What it is | Accent |
|---|---|---|---|
| `nav2_store.webp` | Store | a loot chest seen from the front, lid a little lighter than the body, a dark band across the middle | a GOLD latch in the middle of the band |
| `nav2_heroes.webp` | Heroes | a pilot's helmet, round dome shape, flat bottom (like Rook's helmet seen from the front) | a CYAN visor stripe across the face, a short antenna with a small cyan ball on top |
| `nav2_battle.webp` | Battle | a target: a round navy disc with a lighter ring inside | a RED inner ring with a red dot in the middle, and four short CYAN tick marks sticking out top, bottom, left and right |
| `nav2_modes.webp` | Modes | a small planet with a ring around it, tilted | the planet PURPLE (darker purple on its lower part), the ring CYAN |
| `nav2_quests.webp` | Quests | a clipboard with a list | a GOLD clip on top, two GREEN tick marks with short grey lines beside them |

## What the game does with them
- Cuts each one out of the black, shrinks it to the bar size.
- Closed tabs: the code dims them (greyer, half see-through). The open tab: shown in its
  full colours, a little bigger, with its name in cyan under it. So the colours you paint are
  the "open" look; you do not need to paint a dim version.

## Tips for the image tool (if it helps)
"flat vector game icon, two-tone, dark navy body with one bright [gold / cyan / red /
purple / green] accent, bold simple rounded shapes, centred, plain pure black background,
no text, no gradients, no 3D, no glossy highlights, no shadow"

## Checklist
- [ ] Five pictures, 1024 x 1024 each, named exactly `nav2_store`, `nav2_heroes`,
      `nav2_battle`, `nav2_modes`, `nav2_quests` (.webp or .png).
- [ ] Flat two-tone: navy body + the one accent colour listed; no gloss, no 3D, no glow.
- [ ] Bold shapes that still read when tiny; no text.
- [ ] Centred, about 75% of the square, all five the same size.
- [ ] Pure black background.
