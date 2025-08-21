# Project Backlog (P0–P2)

This file tracks tasks required to take the current prototype to a minimal Steam release.
`P0` = must ship, `P1` = nice to have, `P2` = later.

## P0 — Must Ship

### Shell & Navigation
- [ ] Replace debug tower buttons with polished icons and tooltips
- [ ] Add a pre-game menu for map selection, settings and quitting
- [ ] Implement an in-game pause menu with resume, restart and exit options

### HUD & Controls
- [ ] Display lives, cash, wave counter and speed toggle in HUD
- [ ] Allow 1×/2× game speed

### Placement & Build UX
- [ ] Create 10 playable levels (3 tutorial + 7 campaign)
- [ ] Build tower upgrade trees with 2–3 branches for each of the four existing towers
- [ ] Add Neon Amplifier support tower
- [ ] Add EMP Coil utility tower
- [ ] Provide one-line narrative transmissions per map

### Enemies & Waves
- [ ] Expand roster from 3 to 5 base enemy types plus boss
- [ ] Roughly 10 waves per level, mini-boss on wave 5, boss on wave 10

### Audio/Visual
- [ ] Basic SFX for placement, firing, deaths, UI, and boss roar
- [ ] Ambient music loop with tension loop near final wave
- [ ] Neon outline shader, shield break flash, burn/tar decals

### Systems
- [ ] Save player progress and unlocked levels locally
- [ ] Victory/defeat screens summarizing stats

### Steam Readiness
- [ ] Package playable build for Steam upload

## P1 — Nice to Have

### Codebase Refactor
- [ ] Break `main.lua` into modules (`menu.lua`, `gameplay.lua`, `towers.lua`, `enemy.lua`, `editor.lua`)
- [ ] Implement a state manager or `love.run` wrapper for clean transitions
- [ ] Expand `love.resize` callback to mirror `setFullscreen` updates

### Testing & Tooling
- [ ] Unit tests for map encode/decode, BFS path construction, and upgrade logic
- [ ] GitHub Actions running linting and tests on each push
- [ ] Formatting enforcement with `stylua` or `lua-format`

### Gameplay Enhancements
- [ ] Persist user settings (fullscreen, window size, volume, key binds)
- [ ] High-score saving with optional online leaderboard
- [ ] Accessibility options (font scaling, color inversion, control remapping)
- [ ] Auto-generate sidebar buttons from `towerTypes`

### Performance
- [ ] Object pools for projectiles, beams and particles
- [ ] Clamp or interpolate `dt` to smooth spikes
- [ ] Debug toggle showing frame time and entity counts
- [ ] Localize frequently used modules (`love.graphics`, `love.mouse`, etc.)
- [ ] Cache `love.graphics` color and line width state

### Packaging & Release
- [ ] Script cross-platform builds with `love-release`
- [ ] Automate release builds in CI
- [ ] Produce marketing assets (icons, screenshots, store banners)
- [ ] Embed version string and git hash in the main menu
- [ ] Provide window icon via `t.window.icon`
- [ ] Enable high-DPI rendering (`t.window.highdpi = true`)

### Security & Robustness
- [ ] Harden clipboard input validation in `applyMapFromCode`
- [ ] Wrap file read/write operations with `pcall`
- [ ] Append checksum to map codes
- [ ] Validate `settings.json` fields and cap clipboard text length

### Documentation
- [ ] Enforce changelog updates via pre-commit hook or CI check

## P2 — Later
- [ ] Generate API docs with `ldoc` and publish to GitHub Pages
- [ ] CI step running `luac -p` to catch syntax errors early
- [ ] Integrate `luacov` for coverage metrics
- [ ] Crash logging via custom `love.errorhandler`
- [ ] Level editor enhancements (brush tools, live path validator, workshop browser)
- [ ] Unlockables, daily challenges, achievements, cosmetics
- [ ] Dynamic pathfinding for multi-lane maps
- [ ] Gamepad support and photo mode
- [ ] Cloud saves and other online features

