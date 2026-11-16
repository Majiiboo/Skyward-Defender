# Ideas and future plans (from Rudy's Wing Fighter recordings, 2026-11-14 and 2026-11-16)

Rudy recorded three sessions of a plane shooter he likes (Wing Fighter). This is what is worth
taking, what is already done, and where each idea belongs. Systems only: never its art, names
or pay screens.

## Done
- **Refundable weapon levels.** Its gear has "Level down" buttons that give back what was spent.
  Built 2026-11-16 as "Reset for a full refund" on the Weapons screen (Arsenal.refund / reset):
  a weapon goes back to Lv.1, coins, parts and materials come back, mastery stays.

## For the POWER-CARD rework (Rudy wants to redo cards after weapons)
1. **Cards are almost wordless.** A big icon, a short name, a row of stars. The description only
   appears under the cards when one is tapped, then a Confirm button. Fixes the old note about
   text spilling out of our cards.
2. **A "Recommended" tag** on one card per pick, so a new player is never stuck.
3. **Cards that need another card.** "Required" plus a small icon of the card you must own
   first. A visible build path inside a run.
4. **Attack and defence slots.** A bar over the cards shows what was picked, in two groups with
   a limited number of slots. The build is readable at a glance.
5. **A fifth, red-star tier.** A maxed skill can turn into a "super" version that changes the
   weapon outright. Same idea as our weapon Lv.30 capstones, but inside one run.
6. **A mid-stage gate.** Halfway through a stage the plane flies into a hangar and picks one of
   two skills. Breaks a long stage in two.
7. **The pause screen** shows only the picked skills (two groups, with stars), sound switches,
   Quit and Back.
8. **Power cards that read differently per weapon class** (agreed with Rudy 2026-11-13): e.g.
   Burst Fire = pistol double tap, twins fire together, rifle a wider stream, cannon a second
   small shell. The hero's element then decides what the shot is.

## For the FIGHT screen
9. (done 2026-11-16 as "n left" on the HUD) **A kill counter per wave** ("5 / 14") beside the wave number. Small, and it tells the player
   how close the wave is to ending.

## For the MENUS (any time, cheap)
10. **"Where do I get this?"** Tapping a currency you are short of lists where to earn it, each
    with a Go button. We have coins, crystals, parts, materials, shards, keys and tokens and
    nothing like this. Good candidate for the polish round.
11. **Lucky upgrades.** A level-up sometimes rolls "Bonus x2 / x3 / x5". Turns a plain button
    into a small thrill. Would need care so costs stay fair.
12. **Chests state their guarantee** and count down ("a fighter within 8 opens"). Ours has pity
    every 10th open; it could show the countdown the same way.

## For the HERO RARITY system (parked until weapons are finished)
13. **Heroes evolve from their own shards, and unwanted shards can be fused** into something
    useful. Matches the direction already suggested to Rudy: rare heroes unlocked by shards
    never by luck, a small permanent bonus for all heroes per step climbed, unwanted shards ->
    star dust -> any hero's shards, twelve heroes over time.
14. **A second fighter that plays differently** (its second plane fires two curving streams of
    fire). Confirms the path we are on: each hero's weapons fire their own way.

## Not taking
- VIP cards, weekly pack stacks, "watch an ad to double it" on a free skill.
- The gear inventory grid: Rudy chose four weapons per hero to get away from sorting piles of gear.

## Weapon area: what is still open (2026-11-16)
- **Luna art owed:** shots for Rook, Sparks, Hollow and Nyx (four briefs written, nine pictures
  each). Ember's pistol, twin pistols and cannon (only her rifle is painted) and her top-view
  fight pieces. The same for the other four heroes.
- **The Specialty weapon.** The slot is earned (all four weapons at mastery step 3) but the
  weapon itself is not designed. Proposal to put to Rudy: one unique weapon per hero that
  breaks the four classes, tied to who he is, e.g. Frost = a snow-globe grenade that freezes a
  whole area, Ember = dragon breath (a wide cone, very short), Sparks = a tesla coil he drops
  that zaps on its own, Rook = an orbital marker that calls a beam down, Hollow = a rift that
  swallows small bugs, Nyx = a thrown glaive that returns.
- (done 2026-11-16) The twin pistols trick is by element now (Shots.TWIN_TRICK): only Sparks arcs.
  second bug). It suits Sparks; for the penguin's snowballs it is odd. Each element could get
  its own (ice: a small splash of frost, fire: a flare-up...).
- **Sounds are generated and unheard.** Each class has its own shot and hit sound; a pass per
  element (ice tinkle, fire whoosh, electric crackle) would come after Rudy has heard them.
- **Balance** was done by simulator: Frost fully, the other five at stages 20 and 30 with a
  Lv.20 weapon. The simulator's player buys far fewer weapon levels than a real one would.
- **Phone verdict.** Nothing since build dev276 has been played on a phone.

## After weapons (the agreed order)
1. Power cards (Rudy's rework, using the list above).
2. Hero rarity and unlocking.
3. The other five heroes rebuilt from above in moving pieces, like the penguin.
4. The polish round from Rudy's phone notes (heat, music, text sizes).
