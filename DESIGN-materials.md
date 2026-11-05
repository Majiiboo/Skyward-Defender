# Materials and the Workshop after heroes (Rudy, 2026-11-05)

What changed: the six-slot gear is gone, so merging gear copies went with it. What stays:
the WEAPON is still gear (level, rarity, copies, merging in Workshop > Gear), PARTS merging
(Alloy -> Cells -> Cores) is still in Workshop > Parts, LOADOUTS still save hero + weapon +
turrets + drone as one kit (a planet kit: the Ice hero with the Ice drone and the Lance for
Magma World), so they stay.

## Rudy's direction: materials per domain, and the Workshop as the crafting bench
Not every material is for the same thing. Each domain has its own material line, and the
Workshop turns lower materials into higher ones and crafts the things that need them.

| Domain | Materials (low -> high) | Spent on |
|---|---|---|
| Base parts (exists) | Alloy Scrap -> Plasma Cell -> Void Core | turret tracks, weapon levels, buying turrets |
| Heroes | shards (per hero, exists) + ESSENCE per element (new): Energy Spark, Arc Charge, Frost Core, Void Fragment, Dark Ember, Solar Flare | hero tiers (evolutions), unlocking higher-grade heroes ("20,000 coins + 3 Solar Flares + 12 Cores") |
| Weapons | the element essence + a WEAPON material line: Scrap Barrel -> Focus Lens -> Prime Coil (new) | high weapon levels (from Lv.15: "one Solar Flare + 2 Focus Lenses" for the Sun Rifle), weapon VARIANTS crafted in the Workshop (a Sun Rifle variant that burns, a Frost Rifle that pierces) |
| Turrets | base parts + element essence from the turret's planet | track levels past 10, buying 3★+ turrets |
| Drones | base parts + a DRONE material: Rotor -> Gyro -> Flight Core (new) | drone levels, buying new bodies |

Where materials come from: parts from bugs and stage clears (exists); essences from boss
stages, Elite and the element trials of THAT element (a Fire trial pays Solar Flares),
Patrol on that planet; weapon and drone lines from Horde waves, chests (Store 2.0) and the
Workshop (merge 3 of a line into 1 of the next, like parts today).

## The Workshop page, next version
Sub-tabs: PARTS (merge, exists) | GEAR (weapon copies, exists) | CRAFT (new): a list of
recipes, each a card with the picture of what it makes, the materials needed with have / need
counts, and a Craft button. Recipes: essence from 3 lower essences; weapon variants; the
unlock material for a hero or turret that asks for one.

## Build order (when Rudy says go)
1. materials.gd: the material lines (ids, names, icons from the icons sheet, drop tables).
2. Costs: Heroes tiers and high-grade unlocks, weapon levels from 15, turret tracks past 10,
   drone levels take materials (Parts.need style tables).
3. Workshop > Craft tab with recipes; Progress.grant and reward_text for the new ids.
4. Drops: boss / Elite / trials / Patrol / Horde pay them; Store 2.0 sells them.
5. Luna: icons (the icons brief already has the parts; add the essences and the two new lines).
