# NEON BRINK — MVP Scope & Missing Pieces

Goal: ship a tiny-but-complete, replayable tower defense on Steam that proves the core loop, fits the black & white + neo‑neon style, and earns the right to make Game #2. Target 60–120 minutes of curated content.

## 0) What's Already Solid
- Four core towers implemented: **Cog Turret**, **Tesla Coil**, **Steam Mortar**, **Cat-a-pult**
- Map editor with path painting, BFS validation, and map-code sharing
- Basic test maps run through the start menu
- Core HUD: lives and money bars
- Linear upgrades for all towers, loaded from external data files
- Enemy templates: Tin Scuttler, Bronze Beetle, Iron Grinder

These form a working spine. To be complete for Steam we only need a thin layer of content, UX, and framing.

## 1) Minimal Story / Framing (keep it lightweight)
Working title: **NEON BRINK**

Setup (2 sentences): A creeping Void is erasing the last human outposts—their only defense are neon-charged constructs anchored to ancient gridlines. You command a small chain of outposts; hold long enough for civilian evacuation, one map at a time.

Between-level cadence: one-line transmission per map (no cutscenes). Example:
- Map 1 — The Line: “Power’s unstable. Hold for ten minutes and we can cycle the evac relays.”
- Map 4 — Split Rails: “Void-silt blocks the east channel; expect runners.”
- Map 7 — Night Furnace: “Scouts saw shielded hulks. Prep EMP coils.”
- Final — Brinkgate: “Last convoy’s on the road. Don’t let the grid die here.”

Why this works: zero new tech, near-zero art, but gives context for names/FX and lets us theme towers/enemies.

## 2) Content Minimums for a Ship-able Game
- Levels: 10 total → 3 tutorial + 7 campaign (existing maps can be repurposed)
- Waves: ~10 per level (boss on wave 10; mini-boss on wave 5)
- Enemies: expand from current 3 to **5 base + 1 boss** (see §4)
- Towers: existing four plus **Neon Amplifier** (support) and **EMP Coil** (utility) with branching upgrades
- Difficulty: single “Normal” at launch (assist tuning under the hood)
- Run length: 6–12 minutes per map

## 3) Towers & Upgrade Trees (MVP, themed to story)
Numbers are placeholders and will be balanced later.

### 3.1 Existing Towers
- **Cog Turret** – single-target bullets; fast reload
- **Tesla Coil** – chain lightning beam
- **Steam Mortar** – long-range splash
- **Cat-a-pult** – arcing shot that slows on hit

All four already have linear upgrades. For MVP they receive branching paths:

**Tesla**
- Chain → +bounces (2→4→6) with falloff
- Overload → 10%→20%→30% stun on last bounce
- Capacitor → charges for a bigger discharge every N shots (+100%/+150%/+200%)

**Mortar**
- Incendiary → adds burn DoT (2s/4s/6s)
- Shrapnel → impact splits into 3/4/5 fragments
- Seismic → impact slows nearby foes (20%/30%/40% for 1.5s)

**Cat-a-pult**
- Boulder → +damage, short stun chance
- Tar Pot → leaves slowing puddle (15%/25%/35% for 3s)
- Scattershot → splits mid-air; good vs clusters

**Cog Turret**
- Armour Piercer → bonus vs armor
- Overclock → faster fire rate
- Gearworks → range + damage

### 3.2 New Support: Neon Amplifier (aura)
- Base: +10% damage to nearby towers; small radius
- Branches: Focused (higher single-target buff, tiny radius) / Wideband (larger radius, lower bonus) / Harmonic (small cooldown haste)

### 3.3 New Utility: EMP Coil (shield breaker / slow)
- Base: periodic pulse that hits shields hard and slows briefly
- Branches: Breaker (extra shield damage) / Dampener (longer slow) / Condenser (shorter cooldown)

*(Optional later) Static Mine trap – single-use AoE; skip if time is tight.*

Upgrade economy baseline: T1 60, T2 120, T3 200; sell refund 75%.

## 4) Enemy Roster (MVP)
Current templates: Tin Scuttler, Bronze Beetle, Iron Grinder. Expand to:

- **Grunt** — baseline HP/damage.
- **Runner** — fast, low HP; slow capped at 50%.
- **Tank** — high armor; resistant to small hits.
- **Shielded** — regenerating energy shield; best countered by Tesla/EMP.
- **Swarm** — spawns 3 minis on death; weak to AoE.
- **Boss** — big HP, spawns adds at 70%/40%; immune to stuns but not slows.

Damage tags: Physical (Cog, Cat-a-pult, Mortar), Energy (Tesla, EMP). Armor resists Physical; shields resist Energy until broken.

## 5) Level Design Targets
- Tutorial 1–3: single path, generous build spots, scripted tips
- Campaign 4–10: introduce splits, choke points, elevation for arcing weapons
- Per-map spice: one simple modifier (e.g., extra runners, reduced build sites)

## 6) Core Loop & Economy
- Pre-place a couple towers (optional); start with $100
- Earn bounties per kill and wave clear bonuses
- No interest or meta-currency
- Selling refunds 75%
- Waves last 90–120s with 5–10s prep
- Allow 1×/2× speed toggle

## 7) UI/UX Minimums
- Main menu with Tutorial, Campaign, Settings, Exit
- In-game pause with Resume, Restart, Settings, Quit
- Placement UX: valid/invalid tiles, cost tooltip, range preview, refund indicator
- Upgrade panel: branching paths, stat deltas, locks, sell button
- HUD: lives, cash, wave #/total, next wave preview, speed toggle
- End screens: victory/defeat, time, lives, cash spent, retry/next

## 8) Audio/Visual Minimums
- SFX: place/upgrade/sell tower, three enemy death types, tesla zap, mortar thump, catapult thunk, boss roar
- Music: 1 ambient loop + 1 tension loop (crossfade near final wave)
- FX: neon outline shader, shield break flash, simple burn/tar decals

## 9) Tech & Scalability
- Data-driven towers, enemies, waves in Lua tables
- Save settings + level stars to local file
- Object pooling for projectiles/enemies; cap particles; simple FX LOD
- Steam: achievements optional post-launch

## 10) Price & Positioning
- Launch price: **$5.99** (placeholder; intro discount possible)
- No in-game currency at launch; potential DLC map pack later
- Optional neon skins as cosmetic DLC post-launch

## 11) 10-Day Production Snapshot (starts 2025-08-22)
Day 1 (2025-08-22): CEO approvals
Day 2 (2025-08-23): Menus, pause, placement UX, basic upgrade panel
Day 3 (2025-08-24): HUD polish, end screens, speed control, save/settings
Day 4 (2025-08-25): Enemies (5 + boss), spawn logic, tags/traits
Day 5 (2025-08-26): Towers → branch logic for existing four + Amplifier + EMP Coil
Day 6 (2025-08-27): Tutorial maps (3) + teaching copy
Day 7 (2025-08-28): Campaign maps (4) + first balance pass
Day 8 (2025-08-29): Campaign maps (3) + audio pass + VFX polish
Day 9 (2025-08-30): Full balance, bugfix, packaging, page assets
Day 10 (2025-08-31): Play testing and CEO approval

## 12) Definition of Done
- All 10 maps beatable; no softlocks; stable framerate
- Tutorial teaches place, upgrade, sell, speed, preview
- At least one viable build each for Tesla-centric and Physical-centric paths
- No debug UI in shipping build; prompts consistent
- Steam build uploads; settings persist

## 13) Nice-to-Have (defer)
Endless mode refinements, daily seeds, meta progression, talents, achievements, cloud saves, photo mode, cosmetics, multi-lane pathfinding, story cutscenes

## 14) CEO Action Items
- [ ] Confirm or revise working title **NEON BRINK**
- [ ] Approve placeholder launch price **$5.99**
- [ ] Review and approve 10-day MVP plan (includes start/end approval days)
- [ ] Provide one-line studio tagline for Steam page

