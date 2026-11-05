# Ideas from Rudy's Slayer Legend video (2026-11-04)

Rudy recorded 5 minutes of Slayer Legend (a pixel-art idle RPG he used to play) going through
every menu. This is what it has, what Skybound already has, and what is worth taking. Rule:
systems and flows only, never its art, names or looks.

## What the video shows, page by page

- **Login and come-back hooks.** A 20-day Attendance Check calendar (same small reward each
  day, a big one every 5th day, a reset timer); a "Returning user login event" banner;
  "Welcome Back Missions": a checklist of ten easy tasks (join a guild, use a scroll, beat
  a boss, change preset, change appearance...) filling a bar to a 20,000-diamond chest.
- **Main screen.** The fight never stops (idle). Top bar: portrait, level with XP %, two
  currencies, menu. A second row: four timed-buff icons with minutes left, the stage name
  with a BOSS button, shortcuts to Quest, Scroll (consumable) and a growing plant. A stage
  progress bar with a "?" boss-challenge button. A skill bar of eight skills with cooldown
  numbers and an AUTO toggle. Red notification dots on every tab, sub-tab and button that
  has something to claim.
- **Ad items.** Four one-hour blessings (gold x3, XP x3, enhance x3, drop rate x2) from
  rewarded ads, two a day each; a paid "ad removal" grants them without watching.
- **Select Region.** A list of stages per region: each shows its legendary drop rate, a
  Move button, a "clear benefit" (stage gold x4.3) and a region clear reward (a Blueprint,
  Owned / Unowned).
- **Character.** Enhance (ATK, HP, HP recovery, crit damage, crit rate levelled with gold,
  x1 / x10 buttons); Growth (stat points into STR / HP / VIT / CRI / LUK / ACC / DODGE,
  each with a max level, a reset button); Promotion (ranks Stone, Bronze, Iron, Silver,
  Gold, Mithril, Orichalcum, Arcanite, Adamant, Ether: each a boss CHALLENGE that unlocks a
  flat ATK/HP multiplier); Class (a collection of classes with grades, an equip effect and
  an "owned" effect for every class you hold, Batch Combine, Summon); Promotion Abilities
  (a list of locked bonuses bought with a currency); Latent Power (a wheel of five stats);
  Training Diary (training stages that pay stat points, a trainer character talking).
- **Skill.** A skill book grid on five pages plus a star page; every skill has a level
  fraction (29/152 copies), "E" when equipped, "?" for unknown ones; Combine and Learn;
  "Skill Proficiency Lv.8: all attributes damage +43%".
- **Equipment.** Weapon / Accessory / Relic / Spirit sub-tabs. Weapons by Grade 1-4 with a
  copies bar (3/5), enhance levels (+6, +150), Batch Combine, "Insufficient Combine
  Materials". Soul Weapon: Craft from a material plus a weapon, or Breakdown. Relics: a list
  with Max Lv.100 and Enhance at a 10% success rate. Spirits: a partner spirit plus a grid of
  84/100 with elements, Spirit Evolution, Summon.
- **Companion.** Four companions with levels and copies bars; an Advancement grid of
  companion classes with silhouettes for the ones you have not met.
- **Adventure.** Adventure: a world map with regions marked CLEAR. Dungeon: a map of
  dungeons (Dragon Valley, Dimensional Rift, Closed Mine, Training Cave...), each with a
  lore line, (0/3) daily entries, a Difficulty 1-5 dial with a bonus %, a ranking button.
  Guild: a hall with NPCs, Divine Beast, guild shop, requests, chat.
- **Shop.** Summon (weapon / accessory / skill card, x1 / x11, summon levels, an ad summon
  every 10 minutes, "Ellie's Summon Gift Box": milestone gifts per summon level); Package
  (stage packages, today's featured, monthly, appearance coins, nickname change, real
  money); Goods (50 diamonds for an ad, 0/10 a day; diamond packs with bonus %); Golden
  Key (keys from purchases open weekly / monthly chests).
- **Basic Info / Appearance.** A full stats sheet. Costumes in four slots (outfit, weapon
  skin, face, hat), each with a small stat bonus that applies even when not worn
  ("appearance stats apply even if not equipped"); lens and hair colours; event-only
  costumes.
- **Quest window.** Daily Quest (with a "Daily Quest Complete 3/5" meta reward of 3,000
  diamonds), Repeat Quest (repeatable goals with a level counter: Stage Clear Lv.259,
  Eliminate Monster Lv.1178 50/500...), Achievement (one-time).

## Already in Skybound (and how it compares)

| Theirs | Ours | Verdict |
|---|---|---|
| Daily / Repeat / Achievement quests | Quests: Daily / Career / Trophies | Same shape. Theirs adds REPEAT quests and a visible meta-reward bar. |
| Attendance calendar | Store daily gift (1 day) | Theirs builds a streak; ours resets every day. |
| Batch Combine, copies 3/5 | Workshop: Quick Merge, copies x3 | Same idea, ours since dev139. |
| Change Battle Preset | Gear KIT row (3 loadouts) | Same, ours since dev139. |
| Adventure map with CLEAR | Stage Map with stars | Ours is better (stars, trail). Theirs shows drop rates per stage. |
| Companions, Spirits | Turrets, drone | Ours are gameplay; theirs are stat sticks. |
| Skill bar | Power cards per run | Different design; ours is the roguelite pick. |
| Promotion ranks | Commander suit, talent map (planned 16 e) | Theirs ties rank to a boss CHALLENGE. |
| Red dots | Red dots on four Home buttons | Theirs are on every tab and sub-tab. |
| Golden keys, chests | Store 2.0 plan (item 18) | Already planned, with pity. |
| Guild, ranking | 2.0 plan | Already planned. |

## Worth taking (ranked by fit and effort)

1. **Red dots everywhere (cheap, big).** A dot on a nav tab, a sub-tab and a button whenever
   something is claimable there: Quests (a done task), Store (daily gift ready), Gear >
   Workshop (a merge possible), Patrol (collect ready), Chest. One rule in code
   (Progress.has_claimable per page) feeding every dot.
2. **Attendance calendar (cheap).** 7 or 14 days, a small gift each day, a big one on day 7
   / 14, a reset timer; replaces or sits beside the daily gift on Store > Offers. The streak
   is the hook.
3. **Welcome-back missions (cheap).** When the player has been away 3+ days: a card with 6-8
   easy tasks (play a stage, upgrade a piece, merge, collect Patrol, switch a kit...) filling
   a bar to a crystal chest. Reuses the quest rows.
4. **Repeat quests (cheap).** A fourth Quests tab: goals that reset and level up when
   claimed ("Destroy 500 bugs Lv.12"), paying a little each time. Endless small goals.
5. **Daily meta bar (tiny).** The "All 5 done" line becomes a bar with a chest at the end,
   like theirs. We already pay the bonus; just show it.
6. **Stage drops on the Stage Map (tiny).** Each stage card says what it drops: the set, the
   rarities possible there, and the planet's clear reward (the Commander suit on planet 1;
   later planets need one each).
7. **Breakdown (cheap).** In Workshop > Gear: dismantle spare copies into parts (a Common
   copy = 2 Alloy, Uncommon = 1 Cell...). Gives the "x1 Common" stacks a use.
8. **Rank challenges (medium, pairs with 16 e).** Pilot ranks (Cadet, Pilot, Ace, Commander,
   Captain...) unlocked by beating a special rank boss, each a flat +5% ATK / base HP and a
   badge on the profile. A reason for Boss Rush, and a clean place for the talent map's
   "every 10th node unlocks a power".
9. **Timed boosts (medium).** One-hour boosts (coins x2, XP x2, drop rate x2) bought with
   crystals (and rewarded ads later), shown as timer icons under Home's top bar.
10. **Dungeons with daily entries and a difficulty dial (medium).** For Horde and Boss
    Rush: 3 entries a day, Difficulty 1-5 with a reward bonus %, a best-score line (local
    until 2.0).
11. **Collection bonuses (later, with item 19 skins).** Every skin or costume owned gives a
    tiny permanent stat even when not worn, so collecting matters.
12. **Chest milestone track (with item 18).** Every N chest opens gives a milestone gift,
    on top of the pity rule.

## Skip, and why

- Enhance with a 10% success rate: random failure on a paid upgrade feels bad; our upgrades
  always succeed.
- Idle auto-battle as the main screen: Skybound is a played shooter; the Home AFK battle
  already gives the "alive" feel without taking the game away.
- Forty-digit numbers: our numbers stay readable.
- Ten currencies (diamonds, emeralds, feathers, coins, appearance coins, keys...): we keep
  coins, crystals, parts and power tokens.
- Guild hall and chat: 2.0, needs a server.
