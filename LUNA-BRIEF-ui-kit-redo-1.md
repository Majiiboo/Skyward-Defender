# Luna brief: UI kit, round 2 (the panels, one change)

Hi Luna! Your 36 UI pieces are in the game: every button, tab, chip and header bar is yours
now, and the battle's top bar and bars too. They look great. One thing stops the big PANELS
from going in, and it is a small change to seven pictures.

## The problem
The game stretches each panel to the size it needs (a short row, a tall box). It keeps the
four corners as painted and stretches the edges and the middle. Your panels have a soft
GLOSS BAND across the upper middle (a lighter sweep of light). When a panel is stretched tall,
that band stretches with it into a pale smear across the whole box, over the text.

## The fix: paint the gloss only in the corners
Re-render these seven on the same 512 x 512 cells, same colours, same edges, with the
middle of the rectangle a FLAT, even dark glass and NO gloss band:
`ui-panel_glass`, `ui-panel_dark`, `ui-panel_gold`, `ui-panel_tile`, `ui-popup`,
`ui-topbar`, `ui-nav_dock`.
A small highlight may sit in the top-left corner only (inside the outer 60 px of the
corner); the rest of the face stays one flat shade. Edges and corner brackets as before.

## Names
Save them as `ui-panel_glass-v2.webp` and so on (`-v2` at the end), so your first versions
stay in the folder.

## Checklist
- [ ] Seven panels, 512 x 512, black background, same edge light and corner details.
- [ ] The middle of each rectangle flat; any gloss only inside the top-left corner.
- [ ] `-v2` in the file names.
Thank you! This is the last piece of the UI kit.
