# Luna brief: the heroes' BACK frames (three more turn frames per hero)

Hi Luna! This brief has everything you need; no earlier brief or message is required.

## What this is for
On the Heroes page the player can now drag a finger across a hero to turn him. Your five
turn frames cover the front half of the turn (left side, three-quarter, camera, three-quarter,
right side). Three more frames per hero complete the circle, so the player can spin him all
the way round and see his back: the jetpack, the wings, the cloak, the tail.

## Match your own frames
Open your `turn_1.webp` to `turn_5.webp` of the hero (in `art_src/heroes/<hero>/`). Same
character, same size, same camera height, same lighting, same black background, feet at the
same height (about 90% down) and head top at the same height (about 10% down) as those five.
Weapon in the right hand, barrel up, in front of the chest, as in the five frames: on the
back frames it is mostly hidden behind the body, which is fine.

## The frames (1024 x 1024 each, names exact, lower case)
| File | What is in it |
|---|---|
| `turn_6.webp` | facing the RIGHT side and a bit AWAY from the camera (three-quarter from behind, we see his right shoulder blade and the side of the helmet) |
| `turn_7.webp` | facing straight AWAY: his back to the camera, the jetpack / wings / cloak / tail fully visible, the back of the head |
| `turn_8.webp` | facing the LEFT side and a bit away (the mirror of frame 6: three-quarter from behind on the other side) |

Do this for all six heroes: `sparks`, `frost`, `hollow`, `nyx`, `ember`, and the pilot
(`art_src/turn/turn_commander_6..8.webp` and `turn_rookie_6..8.webp`, matching your
`turn_commander_1..5.webp` and `turn_rookie_1..5.webp`).

## Checklist
- [ ] Three frames per hero, 1024 x 1024, black, feet and head at the same heights as frames 1-5.
- [ ] Frame 7 is the straight back; 6 and 8 the two three-quarter-from-behind views.
- [ ] Same scale and lighting as that hero's frames 1-5.
Thank you! Sparks and the Commander pilot first if time is short.
