# Luna brief: STORE 2.0 art (chest tiers, keys, packs, crystal and coin piles)

Hi Luna! This brief has everything you need; no earlier brief or message is required.

## What this is for
The Store is being rebuilt with five tabs: Chests, Offers, Shop, Crystals, Exchange. Chests
are opened with KEYS, in three tiers; packs are bought or given free daily / weekly / monthly;
crystals and coins are sold in piles of five sizes. Each tile shows one picture, and a chest
OPENS on screen (lid lifts, light bursts, the reward rises), so the chests come as pieces.

## Match your earlier Store pieces (open these first)
- `icons/chest3d_body.png`, `icons/chest3d_lid.png`, `icons/chest3d_burst.png`: the chest
  as three pieces (body, lid, burst of light). The code lifts the lid and fades the burst in.
  Same camera (from in front and above), same scale and the same split for the new chests.
- `icons/ic_chest_u.png`, `ic_chest_e.png`, `ic_chest_l.png`, `ic_key.png`, `ic_pack.png`,
  `ic_crystal.png`, `ic_coin.png`: your 48-cell icon set, for the small icons.

Files go in `art_src/store2/`. Black backgrounds. Light from above and a little in front.

## 1. Three chests, each as three pieces (512 x 512 each piece, same place in the cell)
| Tier | Colour | Design | Files |
|---|---|---|---|
| Uncommon | teal-green light, steel body | a plain steel strongbox with riveted corners, a teal latch light | `chest_u_body`, `chest_u_lid`, `chest_u_burst` |
| Epic | purple light, dark charcoal body with purple seams | a heavier chest with angled armour plates, a purple core window in the front | `chest_e_body`, `chest_e_lid`, `chest_e_burst` |
| Legendary | gold light, black-and-gold body | an ornate chest with gold edges, a glowing gold sun emblem on the lid, small floating gold specks | `chest_l_body`, `chest_l_lid`, `chest_l_burst` |

`_body` = the chest without its lid (dark inside). `_lid` = ONLY THE LID, like a tray lying on
black: a flat slab with the top design on it and its thin gold edge, seen from the same camera
as the body, floating in the place it would sit on the open body. There is NO box under it: if
you can see the front of the chest, the latch, or the dark inside, it is a closed chest, not a
lid. The easiest way to get it: render the open body first, then ask for "the lid of that
chest alone, lifted straight off and shown by itself at the same angle" (the Uncommon and
Legendary lids you made are exactly right: a slab, no box). `_burst` = only the light that
comes out when it opens (rays and glow, the tier's colour, on black). All three at the same
size and place as the pieces in `icons/`: the code stacks the lid over the body's rim.

## 2. Three keys (256 x 256 each)
`key_u.webp`, `key_e.webp`, `key_l.webp`: a chunky stylised key, the same shape in all three,
coloured and lit like its chest (teal / purple / gold). Seen at a slight angle, floating.

## 3. Packs (512 x 512 each): a box or bundle, closed, with its tier shown by light and size
| File | Pack | Design |
|---|---|---|
| `pack_daily` | Daily pack | a small cyan-lit supply crate with a "1" dot of light |
| `pack_weekly` | Weekly pack | a medium purple-lit crate, two straps |
| `pack_monthly` | Monthly pack | a big gold-lit crate with a sun emblem |
| `pack_stage` | Stage pack | a steel crate stencilled with a star, a red tag of light |
| `pack_starter` | Starter pack | a cyan crate with a small pilot helmet sitting on it |

## 4. Crystal piles and coin piles (256 x 256 each)
Five crystal sizes, same purple-magenta crystal as `icons/ic_crystal.png`:
`crystals_1` (one crystal), `crystals_2` (a handful of three), `crystals_3` (a small pile),
`crystals_4` (a big pile), `crystals_5` (a chest-sized heap with a glow under it).
Four coin sizes, same gold coin as `icons/ic_coin.png`:
`coins_1` (three coins), `coins_2` (a stack), `coins_3` (a pile), `coins_4` (a sack of coins
spilling open).

## 5. Small icons for the new tabs and tokens (256 x 256 each, simple bold shapes, white core)
`ic_exchange` (two curved arrows forming a ring, teal), `ic_token` (a round event token with
a star, orange), `ic_pity` (a chest with a small progress ring round it, grey with a gold
tick), `ic_free` (a plain bright ribbon tag with no text, green).

## Common mistakes to avoid
- The lid or the burst in a different place from the body: the three must stack.
- Text or numbers painted in (the game writes "x50", "FREE" and the prices).
- A pack that looks like a chest: packs are closed crates, chests have lids.
- A floor or a shadow under a pile.

## Checklist
- [ ] Three chests x three pieces (9), stacked like `icons/chest3d_*.png`.
- [ ] Three keys, five packs, five crystal piles, four coin piles, four icons.
- [ ] Black backgrounds, sizes as listed, names exact, lower case.
Thank you! If time is short: the three chests and keys first (the Chests tab), then the piles.
