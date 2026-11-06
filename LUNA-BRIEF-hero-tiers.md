# Luna brief: HERO EVOLUTIONS (tier 2 and tier 3 looks for the six heroes)

Hi Luna! This brief has everything you need; no earlier brief or message is required.

## What this is for
Every hero collects SHARDS and evolves twice: tier 2 at 30 shards, tier 3 at 90. Each tier
makes him stronger and must SHOW on him, so the player sees what the shards bought. Rudy's
rule: an evolved hero is the same character, clearly richer, never a different character.
Only three parts change per tier: the HEAD, the TORSO and the BACK PIECE (plus the face light
that goes with the head). Arms, legs, hips and the weapon stay as they are, so the code keeps
the hero's rig and swaps those parts in.

## Match your own hero sheets (open these first)
`art_src/heroes/<hero>/parts_sheet.webp` for sparks, frost, hollow, nyx, ember: the 4 x 4
sheets you painted (512 px cells). The tier parts must be the SAME SIZE, the SAME ANGLE and
in the SAME PLACE in their cell as the base parts in cells 1, 2, 3 and 15 of that sheet, so
the code can drop them straight in. A tier 3 back piece may be bigger than the base one (big
wings, a long cloak); keep it centred on the same point where it joins the body.

## Pictures per hero
Two sheets per hero in `art_src/heroes/<hero>/`:
`tier2_sheet.webp` and `tier3_sheet.webp`, each 1024 x 1024 = 2 x 2 cells of 512, black.

| Cell | Part | Same as base sheet cell |
|---|---|---|
| 1 (top left) | Head, face DARK where it lights | 1 |
| 2 (top right) | Face light only, in the element colour | 2 |
| 3 (bottom left) | Torso | 3 |
| 4 (bottom right) | Back piece | 15 |

Plus `portrait_t2.webp` and `portrait_t3.webp` (512 x 512): head and shoulders of the
evolved hero for the roster button, like your `portrait.webp`.

## What each hero grows into
| Hero (element colour) | Tier 2 (30 shards): "veteran" | Tier 3 (90 shards): "legend" |
|---|---|---|
| **Sparks** (yellow-green) | welded-on armour plates over the dented barrel, a second small eye-lamp beside the big lens, a thicker antenna with a lit tip | a full chrome rebuild: polished barrel with yellow-green seam lights, a crown of three antennas, the lens ringed with light; back piece a small generator with a visible coil |
| **Cpt. Frost** (pale blue) | more medals and a braided cord on the chest, a fur-edged collar, frost crystals growing on the helmet rim | plates of blue ice armour over the suit, a crest of crystal on the helmet, the fishbowl frosted with a glowing blue star inside; back piece a tank wrapped in ice |
| **Hollow** (purple) | the hood torn and taller, faint purple runes glowing along the cloak edge, the eye-lights brighter | a halo of slow purple light behind the hood, the cloak made of drifting stars, the suit cracked with purple light showing through; back piece a long cloak of star-dust tatters |
| **Nyx** (deep red on black) | the red light lines doubled, a half-mask over the visor, a longer cape with a red lining | a full night-cloak with a high collar, the cat ears lit red at the tips, a red crescent on the chest; back piece the cloak flaring open with red light edges |
| **Ember** (orange-gold) | longer horns with brass caps, extra brass plates on the harness, small flames flickering at the mouth corners | gold-scaled armour over the harness, a crest of flame between the horns, the chest plate with a glowing sun; back piece the wings UNFURLED and lit along the edges |
| **Rook** (cyan) | nothing to do: tier 2 is the Commander armour you already painted | one new look, "Captain": the Commander armour in white and gold with cyan light lines, a short cape, a crest on the helmet; cells from `art_src/pilot/parts_sheet.webp` (head cell 1, visor cell 2, torso cell 3, jetpack cell 15, same sizes) |

Rook gets only `tier3_sheet.webp` + `portrait_t3.webp` in `art_src/heroes/rook/` (a new
folder). The other five get both tiers.

## Common mistakes to avoid
- Changing the hero's silhouette or colour so much he reads as someone else.
- Parts at a different size or angle from the base sheet (the rig will not line up).
- Painting the face light into the head: the light is cell 2, the head's face stays dark.
- Arms, legs or the weapon in the sheets: only the four cells above.

## Checklist
- [ ] Five heroes x (tier2_sheet, tier3_sheet, portrait_t2, portrait_t3) + Rook's tier 3.
- [ ] Every part at base-sheet size, angle and place; black backgrounds; 512 cells.
- [ ] Face dark in cell 1, light in cell 2.
Thank you! If time is short: Sparks and Captain Frost tier 2 first (the heroes players own
earliest), then the rest.
