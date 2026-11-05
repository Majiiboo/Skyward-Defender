# Luna brief: the UI KIT (buttons, panels, bars, tabs, icons on them)

Hi Luna! This brief has everything you need; no earlier brief or message is required.

## What this is for
Today every button, box and bar in the menus is drawn by code: flat colours with a thin
line. Rudy wants them to look like the rest of your art: rendered, 3D, with depth, glass and
light. You paint the PIECES; the code stretches them to any size (a technique called
9-slice: the corners stay as painted, the edges and the middle are stretched), so one
button picture becomes every button in the game, at every width. That is why the shapes
below must be simple rectangles with rounded corners and NO decoration in the middle
(decoration only in the corners and along the edges).

## The look to match
- `art_src/battle/base_strip.webp` and `turrets/*.png`: your rendered metal, glass and
  cyan light. The UI is the same material: dark blue-black glass panels, thin bevelled metal
  edges, cyan light lines (hex 33D9FF) and purple accents (B573FF), gold (EBB83A) for the
  main action. Light from above.
- Background of every picture: plain black. Rounded corners, radius about 1/10 of the height.
- Every piece is a flat render on black; the code keys the black to transparent, so glass
  must be painted OPAQUE dark (not see-through black).

## Sheet 1: `ui_buttons.webp` (2048 x 1024, 4 columns x 2 rows, every cell 512 x 512)
Each cell: ONE wide rounded rectangle, 400 x 140 px, centred. Nothing inside it (no text,
no icon, no symbol): the code writes the words.

| Cell | File name after cutting | What it is |
|---|---|---|
| 1 | `btn_gold.png` | the main action button: brushed gold metal face, a lighter gloss on the top half, a darker band at the bottom, a thin bright edge on top |
| 2 | `btn_gold_pressed.png` | the same, pushed in: a touch darker, the gloss gone, the bottom band thinner |
| 3 | `btn_teal.png` | the second action: teal-cyan metal face (hex 29999E), same gloss and bands |
| 4 | `btn_teal_pressed.png` | pushed in |
| 5 | `btn_glass.png` | the quiet button: dark blue-black glass face, a thin cyan light line all round the edge, a faint gloss on top |
| 6 | `btn_glass_pressed.png` | the same, the cyan edge a little brighter and the face a touch lighter |
| 7 | `btn_off.png` | a disabled button: dark grey face, no gloss, a thin grey edge |
| 8 | `btn_tab.png` | a sub-tab (the "Daily / Career / Trophies" strip): a flatter rounded rectangle, dark glass, a cyan light line along its BOTTOM edge only |

## Sheet 2: `ui_panels.webp` (2048 x 1024, 4 x 2, cells 512 x 512)
Each cell: ONE rounded rectangle, 440 x 440 px, centred, decoration only at the corners and
edges, the middle plain (it gets stretched a lot).

| Cell | File | What it is |
|---|---|---|
| 1 | `panel_glass.png` | the standard info box: dark blue-black glass, thin cyan-to-purple edge light (cyan on the left edge fading to purple on the right), a faint sheen in the top-left corner |
| 2 | `panel_dark.png` | a darker box for text on top of a picture (the stage objectives box): nearly black glass, thin cyan edge |
| 3 | `panel_gold.png` | a box that holds something earned (the reward row, milestones): dark glass with a thin GOLD edge |
| 4 | `panel_tile.png` | the item tile (the small square cards for turrets, heroes, weapons): dark glass, a slightly brighter 2-pixel edge, a small metal corner bracket in the top-left and bottom-right corners |
| 5 | `header_bar.png` | a section header bar, 440 x 70 px in this cell: a dark glass strip with an angled cyan tag on its LEFT end (like a folder tab) |
| 6 | `chip.png` | a small rounded pill, 300 x 90 px in this cell: dark glass, thin cyan edge (the code colours it) |
| 7 | `popup.png` | the pop-up window (NEW, confirm, ladders): dark glass with a thicker bevelled metal edge, a small notch at the top centre |
| 8 | `topbar.png` | the Home top bar: 440 x 110 px in this cell, dark glass, a thin cyan line along its bottom edge, rounded only on the bottom corners |

## Sheet 3: `ui_bars.webp` (2048 x 1024, 4 x 2, cells 512 x 512)
| Cell | File | What it is |
|---|---|---|
| 1 | `bar_track.png` | an empty progress bar track, 440 x 48 px: a dark recessed groove with a thin metal rim |
| 2 | `bar_fill_cyan.png` | the fill for XP bars: 440 x 40 px, glowing cyan with a bright core line, rounded ends |
| 3 | `bar_fill_red.png` | the fill for the pilot's HP bar: red-pink glow |
| 4 | `bar_fill_blue.png` | the fill for the base shield: ice-blue glow |
| 5 | `bar_fill_gold.png` | the fill for coins / quests: gold glow |
| 6 | `nav_dock.png` | the Home bottom bar, 480 x 150 px: dark glass with a bevelled metal top edge and a soft cyan underglow; five equal spaces are implied, draw NO icons |
| 7 | `nav_tile.png` | the lit tile behind the active bottom-bar button, 140 x 130 px: a gold-edged glass square |
| 8 | `hud_frame.png` | the battle top bar, 480 x 110 px: the same glass as topbar but with slightly cut corners (chamfered), a thin cyan line at the bottom |

## Sheet 4: `ui_small.webp` (2048 x 512, 8 x 1, cells 256 x 256)
Small pictures, each centred, about 180 px tall:
| Cell | File | What it is |
|---|---|---|
| 1 | `dot_red.png` | the red notification dot: a small glossy red sphere with a highlight |
| 2 | `star_on.png` | a lit five-point star, gold, glossy |
| 3 | `star_off.png` | the same star unlit: dark grey metal |
| 4 | `padlock.png` | a small closed padlock, dark metal with a cyan keyhole light |
| 5 | `tick.png` | a check mark in a round cyan badge |
| 6 | `arrow.png` | a chevron pointing RIGHT, cyan light (the code mirrors it) |
| 7 | `plus.png` | a plus sign in a round glass badge |
| 8 | `close.png` | an X in a round glass badge |

## Common mistakes to avoid
- Text, numbers or icons inside a button or panel (the code adds them).
- Decoration in the MIDDLE of a panel (it stretches and smears). Corners and edges only.
- See-through black glass (it disappears when the black background is keyed out).
- Different light directions between cells. All lit from above.
- Drop shadows painted into the picture (the code adds the shadow).

## Checklist
- [ ] Four sheets at the sizes above, black backgrounds, cells in the order listed.
- [ ] Every rectangle plain in the middle, decoration at corners and edges.
- [ ] Glass painted opaque dark; one light direction.
- [ ] No text, icons or shadows inside the pieces.
Thank you! If time is short: sheet 1 (buttons) and sheet 2 cells 1, 4 and 7 first.
