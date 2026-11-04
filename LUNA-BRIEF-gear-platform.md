# Luna brief: the Gear screen platform (dev103)

Hi Luna! Rudy loved your mockup with the chibi pilot standing on the round platform, and it's now the Gear screen. The animated pilot stands in the middle, with the six gear slots as glass tiles around him, three on each side. Right now the game draws a simple stand-in disc under him. Your painted platform will replace it.

## What to paint

**The round platform from your mockup, empty: no pilot on it.**
- Same camera angle as your mockup: seen slightly from above, a wide oval.
- Same look: charcoal metal deck with cyan light lines, a floor grid, steps on the front.
- The little base buildings and antennas around the rim are lovely; please keep them.
- Plain black background, nothing cropped at the edges, no text.
- About 1600 px wide.

**If you can, paint it as two pieces at the same size and position:**
1. `platform_floor`: the deck and floor only (everything the pilot stands ON).
2. `platform_rim`: only the buildings and antennas on the BACK half of the rim (behind the pilot).

Then the pilot can stand between the two layers. If two pieces is too fiddly, one picture is fine.

## Optional, later
- A soft "light ring" glow on its own (cyan ring on black). The game can make it pulse when you upgrade a piece.
- A matching **turret platform**: the same deck, but square-ish with one socket in the middle, for the Turrets page.

## Where it goes
Save it as `platform.png` (or `platform_floor.png` + `platform_rim.png`). I'll drop it into gear/, and the game picks it up automatically.
