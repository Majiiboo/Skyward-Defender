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
| 1a | HERO BACK FRAMES (DELIVERED 2026-11-05, 20 of 21) | LUNA-BRIEF-hero-back-frames.md | done: 8-frame spin on the Heroes page |
| 1b | HERO STAND rounds 1 and 2 (DELIVERED 2026-11-05): orbit rings in | LUNA-BRIEF-hero-stand-2.md | done |
| 2a | UI KIT round 2 (DELIVERED 2026-11-05): panels, popup, nav dock, top bar in | LUNA-BRIEF-ui-kit-redo-1.md | done |
| 2 | UI KIT: buttons, panels, headers, tabs, chips, nav bar, HUD frame, HP and shield bars, red dot, stars, padlock | LUNA-BRIEF-ui-kit.md | 9-slice pieces replace the code-drawn glass; UIKit keeps the layout |
| 3 | ICONS: every menu icon, currency, parts, elements, roles, grades, stats, the six element symbols | LUNA-BRIEF-icons.md | one sheet, cut into icons/ |
| 4 | DRONE BODIES (DELIVERED 2026-11-05): Spark Bot, Wisp, Night Bat + Repair and Magnet pods | LUNA-BRIEF-drones-2.md | done: DroneData bought bodies, parts + glow in battle |
| 5 | CARDS round 2 (DELIVERED 2026-11-06, 18 of 18: pic_rook_twin came with the turrets) | LUNA-BRIEF-cards-2.md | done: five hero pictures, twist icons on ladders / HUD / pause; frame v2 in. Follow-up ask: a Common frame in the tech style of the other three (thin band, grey edge) |
| 6 | TURRETS 2 (DELIVERED 2026-11-06, all 29 usable, IN the game dev196): Repair Node, Tesla Coil, Cryo Lens, Mine Layer, Dread Beacon, Flak Battery as base + head + shot; firing heads for the six we have; the two card leftovers (pic_rook_twin, frame_common-v2) ride along | LUNA-BRIEF-turrets-2.md | Turrets table (2 per element), roles, split draw, head_fire cross-fade |
| 7 | HERO EVOLUTIONS (brief REWRITTEN 2026-11-06, resend): tier 3 as whole frames t3_turn_1..8 + portrait_t3, tier 2 = portrait_t2 + a code halo; Rook too | LUNA-BRIEF-hero-tiers.md | done: PilotRig tier folders + halo, cut_heroes _cut_tiers |
| 8 | ENEMY FAMILIES (SENT 2026-11-06, brief rewritten): Scrap Belt machines mite / hulk / rivet / dart / bolt + Wrecker mini-boss + Salvage Queen, as pieces + chunks; commander portraits optional | LUNA-BRIEF-areas.md | queue item 17 b: EnemyRig parts per machine, families stack |
| 9 | STORE 2.0 (SENT 2026-11-06): three chests as body / lid / burst, keys, five packs, crystal + coin piles, four icons | LUNA-BRIEF-store-2.md | with item 18: store tiles, chest opening per tier |
| 10 | HOME 2 (SENT 2026-11-06): planet skies as five layers (hive, then scrap), the strip without its dome + standard dome + three super-weapon domes x 3 frames | LUNA-BRIEF-home-2.md | Backdrop parallax layers; dome swap for item 10 super weapons |

Rules every brief repeats: black background, flat renders (no layered files), one light
direction (above and a little in front, cool rim), chibi 3D look like the pilot, names in
lower case exactly as listed, sizes given per cell, "what the code does with it" so the
constraints make sense, a checklist at the end. Luna does not remember earlier briefs:
each brief stands alone.
| 11 | STAR MAP (SENT 2026-11-06): the talent map as a chart: four constellation skies with ghost figures (The Rifle, The Sentry, The Hive Mother, The Dome) + star / star-system pieces | LUNA-BRIEF-talent-map.md | gear.gd StarMap picks up talents/*.png when they land |
