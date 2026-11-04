# Skybound Defender roadmap

Rudy's goal (2026-11-03): a complete, visually stunning game people want to play an
hour or two a day. Luna's rendered 3D look everywhere; original, unique enemies and
worlds; AAA-smooth menus and animation; lots to unlock, upgrade and collect; a store
worth visiting; and, later, a social side (inbox, codes, chat, clans).

Versions: 1.0 is the launch. 1.0x are fixes and small additions, 1.x are bigger content
updates, 2.0 adds whole new systems (the online ones). Everything below is built so it
can grow: tables in code (stages, enemies, cards, turrets, gear, trophies, store) and a
save file with a version number, so updates add entries instead of rewriting.

## 1.0: the complete offline game (now -> launch)
Look and feel
- Luna's 3D art for every screen: pilot, bugs, turrets, base, painted world per area,
  icons, cards, pickups. Code adds the motion: rigs, light, particles, parallax.
- Menus that flow: one shared transition style (slides, fades, depth), animated icons,
  no hard cuts anywhere. Battle HUD and Home in the same frame style.
Game
- 6 areas x 10 stages (two zones of 5 each, mini-boss at 5, boss at 10), each area a
  new planet with its own enemy family and tricks. Area-complete screen and a short
  comms briefing per area (light story).
- Stage map (Candy Crush style trail), 3 stars per stage (clear / clear above half
  hull / perfect), replay for better stars. Elite mode later in the trail.
- Balance by simulator (tools/balance_sim.gd) for every area.
Progression (reasons to come back)
- Pilot level (fast to 5, then slower), turrets by pilot level, mounts by stages.
- Gear: 6 slots, sets with 3/6 bonuses, upgrade levels; weapons to unlock (dual minis,
  cannon...) and upgrade.
- Daily missions, career missions, events: pilot XP, coins, crystals.
- Trophies: a trophy room for achievements (kill counts, perfect clears, bosses, sets
  collected...), each with a reward and a badge to show off.
- Collectibles: a bug codex (every enemy you have met, with its art and lore),
  thruster styles, pilot skins, base skins.
- Card power-ups: three picks of a card unlock an overcharged version (done dev99); two overcharged cards of a pair unlock a fusion card (done dev102, 4 pairs; add pairs with new cards in 1.x).
- Game speed x1 / x1.5 (unlocked) / x2 (store pack).
Store and rewards
- In-game currencies: coins (earned), crystals (premium, also earned slowly).
- Store worth visiting: daily free item, rotating offers, chests, skins, speed pack,
  starter pack. Real-money purchases through Google Play Billing (needs Rudy's Play
  Console account and a privacy policy).
- Redemption codes: in 1.0 a fixed list of codes inside the game (simple, offline);
  in 2.0 codes come from the server so new ones can be added any time.
- Optional rewarded ads (double rewards) only if Rudy wants them.

## 1.x: content updates after launch
- New areas (planets 7+), new bug families, new bosses, new turrets and weapons.
- Seasonal events with their own stage and rewards.
- Base super weapons (the dome emitter idea).
- More gear sets, skins and trophies.

## 2.0: online systems (needs a server)
These need a backend service (accounts, storage, messages). Recommended: one hosted
service that does accounts, cloud saves, inbox, chat and groups together (for example
Nakama, PlayFab or Firebase); Rudy picks one with Claude when we get there (cost and
hosting decision).
- Account + cloud save (play on a new phone without losing progress).
- Inbox: developer messages with attached rewards; server-side redemption codes.
- Leaderboards (per stage, per event).
- Friends, clans, clan chat, clan quests and clan events, shared clan rewards.
- Live events scheduled from the server.
Prepare now: keep the save in one file with a version field and all rewards granted
through one function, so the inbox and codes can call it later.

## Publishing (guidance when we get there)
- Google Play first (Luna already builds signed APKs; Play needs an AAB build, a
  Play Console account, store listing art from Luna, a privacy policy, content rating).
- Soft launch in a few countries, watch retention (D1, D7), tune, then wide launch.

## Campaign mode (Rudy, 2026-11-04, planned)
- A story campaign, separate from the stage list: a Candy Crush-style trail of levels, each one a single level with its own waves, then on to the next.
- A written story told through the briefings (the commander) between levels.
- Planet order and enemy families follow the 6 planets: Hive, Scrap Belt, Magma, Crystal, Plasma, Sentinel.
- To decide with Rudy: how it differs from today's stages (story beats, set pieces, unique bosses) and whether the stage list becomes "Endless / Free play".

## Merging (Rudy, 2026-11-04, queued)
- Merge 3 of the same item into 1 of the next rarity: Common, Uncommon, Rare, Epic, Legendary.
- For: parts (3 Alloy into 1 Cell-tier), gear pieces, turret upgrade modules and drone parts.
- Proposal: a Workshop screen (its own Home button or a Gear tab) for all merging; Gear stays for equipping and upgrading.
- Needs before building: Rudy to OK the rarity ladder per system; Luna to paint rarity frames and a merge animation.
