# Luna art program (Rudy, 2026-11-05): render the look, the code places it

The rule: Luna renders the PIECES (a button, a panel edge, a hero part, a turret head, an
icon) and the code places, stretches and animates them, exactly as the pilot, the turrets and
the base strip work today. Luna never draws a whole screen; whole screens cannot be laid out
on different phones. Every package below gets its own stand-alone brief (LUNA-BRIEF-*.md) with
cell-by-cell tables, sizes, references to her own earlier renders by path, and a checklist.

Priority order (Rudy picks; the code side of each is noted):

| # | Package | Brief | What the code does with it |
|---|---|---|---|
| 1 | Heroes round 2 (the missing frames) | LUNA-BRIEF-heroes-redo-1.md (sent) | finish the five rigs |
| 1a | HERO BACK FRAMES: turn_6..8 per hero (and the pilot) so the swivel goes all the way round | LUNA-BRIEF-hero-back-frames.md | 8-frame swivel on the Heroes page |
| 1b | HERO STAND: a glowing hover disc the hero floats over (Rudy: no base look) | LUNA-BRIEF-hero-stand.md | replaces PlatformFloor on the Heroes page; code floats, pulses, spins |
| 2a | UI KIT round 2 (DELIVERED 2026-11-05): panels, popup, nav dock, top bar in | LUNA-BRIEF-ui-kit-redo-1.md | done |
| 2 | UI KIT: buttons, panels, headers, tabs, chips, nav bar, HUD frame, HP and shield bars, red dot, stars, padlock | LUNA-BRIEF-ui-kit.md | 9-slice pieces replace the code-drawn glass; UIKit keeps the layout |
| 3 | ICONS: every menu icon, currency, parts, elements, roles, grades, stats, the six element symbols | LUNA-BRIEF-icons.md | one sheet, cut into icons/ |
| 4 | DRONE BODIES: Electric spark bot, Void wisp, Dark bat (+ Repair and Magnet pods) | LUNA-BRIEF-drones-2.md | DroneData bodies by grade, pods get their own pictures |
| 5 | CARDS: six hero card pictures, Uncommon frame with the Common inset, trial twist icons | LUNA-BRIEF-cards-2.md | cards/pic_*.png, frame fix |
| 6 | TURRETS 2: a second turret per element (Repair Node, Beacon, Mine Layer, Flak, Tesla Coil, Cryo Lens) as base + head + light, and resting / firing heads for the six we have | LUNA-BRIEF-turrets-2.md | Turrets table, roles, split draw |
| 7 | HERO EVOLUTIONS: tier 2 and tier 3 looks for the six heroes (head, torso, back piece only) | LUNA-BRIEF-hero-tiers.md | Heroes.look_tier swaps those parts |
| 8 | ENEMY FAMILIES: Scrap Belt machines (5 bugs + mini-boss + boss as parts) | LUNA-BRIEF-areas.md exists, refresh | queue item 17 b |
| 9 | STORE 2.0: chest tiers, keys, pack art, crystal piles | with item 18 | store tiles |
| 10 | HOME: planet wallpapers round 2, base dome variants (super weapons), chest and patrol props | later | backdrop layers |

Rules every brief repeats: black background, flat renders (no layered files), one light
direction (above and a little in front, cool rim), chibi 3D look like the pilot, names in
lower case exactly as listed, sizes given per cell, "what the code does with it" so the
constraints make sense, a checklist at the end. Luna does not remember earlier briefs:
each brief stands alone.
