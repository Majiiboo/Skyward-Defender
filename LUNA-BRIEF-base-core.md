# Luna brief: THE NEW BASE (a core, four pods, nine building pictures)

Hi Luna! This brief has everything you need; no earlier brief or message is required.
Open `base_core_ref.svg` (in the same folder as this brief; any web browser opens it) before you
start. It is a flat sketch of the LAYOUT only. Your renders should look far better than it: it
shows where things go, not how they should look.

## What this is for
At the bottom of every fight sits the player's base. The old base was a wide platform with four
sockets for turrets. The turrets are gone and Rudy wants a new, modern base in their place.

The new base is ONE GLOWING CORE at the bottom centre of the screen with FOUR ROUND PODS around
it, joined to the core by thin arms. Each pod holds one BUILDING (a Shield Generator, a Repair
Bay and so on; there are nine, the player picks four). One big see-through shield bubble covers
all of it; the game draws that bubble, you do not.

The base never shoots. It protects and supports. It should look calm, strong and high-tech,
not like a gun platform.

## How the game uses your pictures (so the rules below make sense)
- The game puts the core at the bottom centre, places four pods on a ring around it, and draws
  an arm from the core to each pod.
- It drops a building picture INSIDE each pod's round window.
- It colours the pod's lights to match the building (cyan, green, orange...). That is why the
  pod's lights must be WHITE in your render: white can be coloured, a colour cannot be changed.
- It makes the core's light pulse, so the light is a separate picture from the core's body.
- On a phone the core is about as wide as a thumb and a pod is the size of a fingertip. Bold,
  simple shapes read; tiny details vanish.

## Rules for every picture
- PLAIN BLACK background. No floor, no shadow, no stars, no text, no numbers.
- One object per picture, centred, with empty black all around it (nothing touching the edges,
  except where a piece says so).
- Camera: straight from the FRONT, lifted just a little so you see a hint of the top. The same
  camera for every picture.
- Light from above and a little in front, a cool blue rim light, the same in every picture.
- Look: the same chibi 3D look as your heroes and chests. Dark navy armour (close to #16233c),
  slightly lighter navy edges, thin light lines. Clean, smooth, modern. No rust, no rivets
  everywhere, no cables hanging off.
- Save as `.webp` with the exact names below, lower case. Files go in `art_src/base2/`.

## 0. DO THIS ONE FIRST: the style check (1 picture, 1536 x 1024)
`base2_whole.webp`: the whole base in one picture, as in the sketch: the core in the middle at
the bottom, four pods around it on arms (two low at the far left and right, two higher and
closer in), each pod with a small glowing object inside. No shield bubble.

Please send this ONE picture to Rudy before making the rest. It is only to agree on the look;
the game does not use it. Everything below should then match it.

## 1. The core (2 pictures, 1024 x 1024 each, both lined up in the same place)
| File | What it is |
|---|---|
| `base2_core.webp` | The core's BODY: a low, wide half-dome of dark navy armour, like the top half of a ball sunk into the ground. Its flat cut edge sits ON the bottom edge of the picture (this piece may touch the bottom edge). In the middle of its front is a round, dark, EMPTY socket (a ring with nothing glowing inside), about a third as wide as the dome. Two or three thin panel lines curving over the dome. A few small WHITE light dots along its base. |
| `base2_core_light.webp` | ONLY the light that sits in that socket: a bright ball of cyan-white energy with a soft glow, on black, in exactly the place of the socket in `base2_core`. No dome, no ring. |

Easiest way: render the core with its light on, then ask for "the same picture with the light
switched off and the socket dark" (that is `base2_core`) and "only the glowing ball, everything
else black" (that is `base2_core_light`).

## 2. The pod (3 pictures, 512 x 512 each, same size and place in all three)
A pod is a thick round ring of navy armour, seen from the front, like a porthole. The middle
is a round window of very dark glass, EMPTY (the game puts the building picture there). The
window is about two thirds of the pod's width. All light lines on the pod are WHITE.

| File | What it is |
|---|---|
| `base2_pod_1.webp` | The plain pod: the ring, one thin white light line running round it, the dark window. |
| `base2_pod_2.webp` | The same pod, upgraded: the same ring with four small armour plates added on the outside (top, bottom, left, right) and a second thin white line. |
| `base2_pod_3.webp` | The same pod, fully upgraded: as `_2`, plus a slim outer halo ring floating just off the pod, and brighter white lines. |

`_2` and `_3` only ADD pieces to `_1`. The ring and the window stay the same size and in the
same place, so the building picture fits all three.

## 3. The arm (1 picture, 1024 x 256)
`base2_arm.webp`: one straight strut lying flat (left to right) across the whole width of the
picture: a slim navy beam with a thin white light line along its middle. Both ends are cut
plain and straight and DO touch the left and right edges (the game hides the ends under the
core and the pod, and turns the arm to whatever angle it needs).

## 4. Nine building pictures (512 x 512 each)
Each is one small, chunky object that will sit inside a pod's window, so it must read at
fingertip size: ONE clear shape, ONE colour of light. Navy body like everything else, with its
light in the colour given. Centred, filling about two thirds of the picture.

| File | Building | Light colour | The object |
|---|---|---|---|
| `b_shield_gen.webp` | Shield Generator | cyan | a small round emitter dish pointing up, with a little see-through cyan dome of energy over it |
| `b_repair_bay.webp` | Repair Bay | green | a short robot crane arm bent over a metal plate, a bright green welding spark at its tip |
| `b_armory.webp` | Armory | orange | a rack holding three fat glowing orange energy cells, standing side by side |
| `b_medbay.webp` | Med Bay | pink-red | a rounded medical capsule standing upright, with a plus-shaped window of pink-red light |
| `b_plating.webp` | Hull Plating | white-silver | three thick armour plates overlapping like a fan, the front one with a white edge light |
| `b_hangar.webp` | Hangar | purple | a small arched hangar with its door half open, purple light spilling out, a tiny round drone just visible inside |
| `b_reactor.webp` | Reactor | yellow | a bright yellow ball of energy held inside two crossed metal rings |
| `b_radar.webp` | Radar | mint green | a radar dish on a short stand, tilted up to one side, with two curved arcs of mint light coming off it |
| `b_refinery.webp` | Refinery | gold | a squat round tank with two short pipes and a round window glowing gold |

## Common mistakes to avoid
- Coloured lights on the pods, the arm or the core's body: those lights must be WHITE (only the
  nine buildings and the core's light ball carry colour).
- Something painted inside the pod's window: it must be empty dark glass.
- The core's light ball in a different place from the socket: the two pictures must stack.
- The pod changing size between `_1`, `_2` and `_3`.
- Guns, barrels or missiles anywhere: this base does not shoot.
- A shield bubble, a floor, a shadow, stars, text or numbers.
- A side view or a view from high above: every picture is seen from the front.

## Checklist
- [ ] `base2_whole` sent to Rudy FIRST and agreed.
- [ ] `base2_core` + `base2_core_light`, lined up (2).
- [ ] `base2_pod_1`, `_2`, `_3`, same size and place, white lights, empty window (3).
- [ ] `base2_arm`, flat, ends touching left and right (1).
- [ ] Nine `b_*` building pictures, one colour of light each (9).
- [ ] 16 pictures in all, black backgrounds, exact names, in `art_src/base2/`.
