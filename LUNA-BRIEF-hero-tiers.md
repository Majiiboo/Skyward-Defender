# Luna brief: HERO EVOLUTIONS (the tier 3 "legend" look of each hero, as whole frames)

Hi Luna! This brief has everything you need; no earlier brief or message is required.
(If you received an earlier version asking for parts sheets: please use this one instead.
The heroes are shown in the game from your whole turn frames, so an evolved look must be
whole frames too.)

## What this is for
Every hero collects SHARDS and evolves twice: tier 2 at 30 shards, tier 3 at 90. Each tier
makes him stronger and must SHOW on him, so the player sees what the shards bought.
- Tier 2 is done by the game: a breathing halo of his element colour around him, plus ONE
  new portrait from you (the roster button), so the roster shows he has changed.
- Tier 3 is the big one: the hero repainted as his "legend" self, the SAME EIGHT turn frames
  you painted for his base look, plus a portrait. Rudy's rule: the same character, clearly
  richer, never a different character.

## Match your own frames (open these first)
`art_src/heroes/<hero>/turn_1.webp` to `turn_8.webp` for sparks, frost, hollow, nyx, ember,
and `art_src/turn/turn_commander_1..8.webp` for Rook. The eight angles: 1 facing the LEFT
side in three-quarter view, 2 an eighth turn toward the camera, 3 facing the camera, 4 an
eighth turn past it, 5 facing the RIGHT side, 6 a three-quarter back view on that side, 7
straight back, 8 a three-quarter back view on the left. SAME height, SAME feet line, SAME
head line, SAME camera as your base frames of that hero, so the game can swap them.

## Pictures per hero (black background, 1024 x 1024, in `art_src/heroes/<hero>/`)
| File | What is in it |
|---|---|
| `portrait_t2.webp` (512 x 512) | head and shoulders of the TIER 2 hero: his base look with the small "veteran" touches below |
| `t3_turn_1.webp` .. `t3_turn_8.webp` | the whole TIER 3 hero at the eight angles above, weapon in the right hand, barrel up, in front of the chest, arms and legs still, like the base frames |
| `portrait_t3.webp` (512 x 512) | head and shoulders of the tier 3 hero |

Rook's files go in a new folder `art_src/heroes/rook/`; his base frames are the Commander
pilot (`art_src/turn/turn_commander_*.webp`).

## What each hero grows into
| Hero (element colour) | Tier 2 portrait: "veteran" touches | Tier 3 frames: "legend" |
|---|---|---|
| **Sparks** (yellow-green) | welded-on armour plates over the dented barrel, a second small eye-lamp beside the big lens, a thicker antenna with a lit tip | a full chrome rebuild: polished barrel with yellow-green seam lights, a crown of three antennas, the lens ringed with light, a small generator with a visible coil on his back |
| **Cpt. Frost** (pale blue) | more medals and a braided cord on the chest, a fur-edged collar, frost crystals on the helmet rim | plates of blue ice armour over the suit, a crest of crystal on the helmet, the fishbowl frosted with a glowing blue star inside, the back tank wrapped in ice |
| **Hollow** (purple) | the hood torn and taller, faint purple runes glowing along the cloak edge, the eye-lights brighter | a halo of slow purple light behind the hood, the cloak made of drifting stars, the suit cracked with purple light showing through, a long cloak of star-dust tatters |
| **Nyx** (deep red on black) | the red light lines doubled, a half-mask over the visor, a longer cape with a red lining | a full night-cloak with a high collar, the cat ears lit red at the tips, a red crescent on the chest, the cloak flaring open with red light edges |
| **Ember** (orange-gold) | longer horns with brass caps, extra brass plates on the harness, small flames at the mouth corners | gold-scaled armour over the harness, a crest of flame between the horns, a glowing sun on the chest plate, the wings UNFURLED and lit along the edges |
| **Rook** (cyan) | the Commander armour with a captain's bar of light on the chest and a short cape | "Captain": the Commander armour in white and gold with cyan light lines, a short cape, a crest on the helmet |

## Common mistakes to avoid
- A tier 3 that reads as a different character (new body shape, new colours all over).
- Frames at a different height or feet line from the base frames (the swap would jump).
- A different pose: the same relaxed stance, weapon up, as the base frames.
- The halo or glow painted in: the game adds light; paint the hero solid.

## Checklist
- [ ] Six heroes x (portrait_t2, t3_turn_1..8, portrait_t3) = 60 files.
- [ ] Every tier 3 frame lines up with the base frame of the same number.
- [ ] Black backgrounds, 1024 frames, 512 portraits, names exact.
Thank you! If time is short: Sparks and Captain Frost first (the heroes players own
earliest). If Rudy later wants tier 2 painted as frames too, the same eight files named
`t2_turn_1..8.webp` drop straight in.
