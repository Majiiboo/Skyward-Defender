# Luna brief: QUEST TICKS, bigger (a small fix to the Quests nav icon)

Hi Luna! This brief has everything you need; no earlier brief or message is required.

Your round 2 nav icons are in and look great: thank you! They are already running, animated, in
Rudy's demo of the new glass bar. One small fix is left: the green ticks on the **Quests** clipboard
(`nav3_quests`) are too small. In the game the whole icon is only about 52 pixels tall, so each tick
ends up about 6 pixels tall, and on the pale paper they disappear. The rows just look like grey lines.

Reference picture (send with this brief): `art_src/ref/nav_quest_ticks_ref.png`.
- **Section 1:** your icon now (left) next to the size and shape we want (right).
- **Section 2:** both at the real size in the bar.
- The ticks on the right are only a code sketch. Please paint your own.

## What to change
Only the ticks. Keep everything else exactly as it is: the board, the paper, the gold clip, the three
small boxes and the grey lines all stay the same, in the same places, the same size.

**The new ticks:**
- **Shape:** a classic check mark (a short stroke down, then a long stroke up to the right), like the sketch.
- **Size:** more than **twice as big** as now. On the 1024 picture each tick, outline included, is
  about **190 px wide and 150 px tall**.
- **Stroke:** thick, about **45 px**, with rounded ends.
- **Where:** each tick starts inside its little box. Its long stroke sweeps up and OUT past the box's
  top-right corner, a bit over the start of the grey line. It's fine if the left tip pokes slightly
  past the paper's edge.
- **Colour:** a deeper green **`#2FD07A`** (the old light green blended into the pale paper).
- **Outline:** the same dark navy outline as the rest of the icon, **`#111830`**, about **14 px** all round.
- **Flat:** no gradient, no shine, no shadow, no glow.

## Files (1024 x 1024, pure black background, .png or .webp)
Use the SAME canvas and positions as your round 2 files, so the new ticks drop straight in.
| File | What is in it |
|---|---|
| `nav3_quests` | the whole clipboard again, with the two NEW big ticks in rows 1 and 2 (row 3's box stays empty) |
| `nav3_quests_tick_1` | only the new tick of row 1, in its place |
| `nav3_quests_tick_2` | only the new tick of row 2, in its place |
| `nav3_quests_tick_3` | only a new tick for row 3, in its place (the game pops it in when a quest is ready to claim) |

How to make the three tick files: paint the whole picture with all three ticks first, then make a copy
for each tick and paint everything black except that one tick. Don't move or resize anything.
Remove tick 3 for the whole picture `nav3_quests`.

You do NOT need to resend the board or the clip (`nav3_quests_board`, `nav3_quests_clip`): they stay as they are.

## Checklist
- [ ] 4 pictures: `nav3_quests`, `nav3_quests_tick_1`, `nav3_quests_tick_2`, `nav3_quests_tick_3`.
- [ ] 1024 x 1024, pure black background, same canvas and positions as round 2.
- [ ] Ticks about 190 x 150 px, stroke about 45 px, green `#2FD07A`, dark outline `#111830` about 14 px.
- [ ] Each tick starts in its box and breaks out past the box's top-right corner.
- [ ] Board, paper, clip, boxes and grey lines unchanged.
