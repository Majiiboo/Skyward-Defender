# Luna brief: CARDS round 2 (six hero cards, the Uncommon frame, eleven trial icons)

Hi Luna! This brief has everything you need; no earlier brief or message is required.

## What this is for
In a fight the player picks POWER CARDS. Each hero now has his own signature card, which
today borrows the picture of his weapon. You paint the six real pictures. The Uncommon card
frame needs a small fix. And the rank trials show "twists" (a good one and a bad one per
trial) as plain words today: eleven small icons make them readable at a glance.

## The style to match
Your earlier card pictures: `cards/pic_heavy_bolts.png`, `pic_rapid_pulse`, `pic_magnet`,
`pic_chain_spark` in the project (the first card set). Same 3D chibi look, same light (from
above and a little in front, cool rim light), one object floating on plain black, nothing
touching the cell edges, NO text or numbers painted in (the game writes the names).
Our own designs, never another game's.

## 1. Six hero card pictures (512 x 512 each, the object filling about 70% of the cell)
Each hero's element colour runs through his picture so the card reads as his:
Rook cyan, Sparks yellow-green, Cpt. Frost ice blue, Hollow violet, Nyx deep purple with red,
Ember orange-red.

| File | Card (hero) | What it does in the game | Picture idea |
|---|---|---|---|
| `pic_rook_twin.webp` | Twin Trigger (Rook) | every few bolts a second bolt fires beside the first | two cyan bolts flying side by side, locked together by a thin bracket of light, small speed lines behind them |
| `pic_sparks_weld.webp` | Arc Weld (Sparks) | his bolts jump as lightning arcs to the next bug | a yellow-green bolt with a forked welding arc leaping off it to a second point, hot white at the fork |
| `pic_frost_freeze.webp` | Deep Freeze (Cpt. Frost) | hits slow bugs; at full power a slowed bug that dies shatters into its neighbours | a bug-shaped ice block with a crack running through it and shards flying off, ice-blue glow inside |
| `pic_hollow_phase.webp` | Phase Bolts (Hollow) | his bolts pass straight through bugs | a violet bolt half dissolved into mist passing through a translucent ring, the ring unbroken |
| `pic_nyx_mark.webp` | Marked Prey (Nyx) | more critical hits, which hit much harder | a deep purple crosshair with a red diamond at its centre and three claw scratches across it |
| `pic_ember_burn.webp` | Afterburn (Ember) | hits set bugs on fire; the fire spreads | an orange flame curling off a small ember, with a second smaller flame catching beside it |

## 2. The Uncommon frame (300 x 450, PNG with a transparent window)
Your `cards/frame_uncommon.png` has no inner inset, so it reads taller than the Common frame
when the two sit side by side at a card pick. Please paint `frame_uncommon-v2.png` the same
size and shape as `frame_common.png`, with the same inner window and the same inset band
around it, keeping the Uncommon green edge colour. Nothing else changes.

## 3. Eleven trial twist icons: one sheet `twists_sheet.webp` (1024 x 768, 4 columns x 3 rows, cells 256 x 256)
Simple, bold symbols centred in their cells, filling about 75%. Good twists in cool GREEN
light, bad twists in RED light, white core, on black. Read the cells left to right, top row
first; the twelfth cell stays empty.

| Cell | File | Twist | Symbol |
|---|---|---|---|
| 1 | `tw_rapid.png` | Rapid fire (good) | three stacked bolts with speed lines |
| 2 | `tw_sharpshooter.png` | Sharpshooter (good) | a crosshair with a bright spark at its centre |
| 3 | `tw_fortified.png` | Fortified (good) | a shield shape with a plus sign |
| 4 | `tw_reinforced.png` | Reinforced (good) | a heart inside a shield outline |
| 5 | `tw_turret_boost.png` | Turret boost (good) | a small turret head with an upward arrow |
| 6 | `tw_overcharge.png` | Overcharge (good) | a card shape with a lightning bolt on it |
| 7 | `tw_swift_bugs.png` | Swift bugs (bad) | a bug silhouette with speed lines |
| 8 | `tw_thick_shells.png` | Thick shells (bad) | a bug silhouette with a thick plated shell outline |
| 9 | `tw_no_turrets.png` | Turrets down (bad) | a turret head with a red bar across it |
| 10 | `tw_double_spit.png` | Double spit (bad) | two green goo drops falling |
| 11 | `tw_weak_shield.png` | Cracked shield (bad) | a shield shape with a crack through it |
| 12 | (empty) | | |

## Common mistakes to avoid
- Text, numbers or labels painted into a picture.
- A picture touching or cropped by its cell edge.
- Cards that look like a weapon: the pictures show the EFFECT, not the gun.
- Icons that differ in size from cell to cell.

## Checklist
- [ ] Six `pic_*.webp` at 512 x 512, black, no text, the hero's colour in each.
- [ ] `frame_uncommon-v2.png` the same shape and window as the Common frame.
- [ ] `twists_sheet.webp` 1024 x 768, eleven icons in the cells above, green for good, red for bad.
Thank you!
