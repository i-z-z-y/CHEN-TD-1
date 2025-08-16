# Steam Defense – Task Tracker

This file enumerates actionable tasks required to move the project from the
current prototype to a production‑ready release.  Items reference
`SUGGESTIONS.md` and should be checked off as completed.

## Codebase Refactor

- [ ] Break `main.lua` into modules: `menu.lua`, `gameplay.lua`, `towers.lua`,
      `enemy.lua`, `editor.lua`.
- [ ] Extract path helpers (`neighbors`, `buildPathFromPaint`,
      `rebuildPathPoints`) into `path.lua`.
- [ ] Move map-code logic (`encodeFromPaint`, `decodeToPaint`,
      `saveMapCodeToFile`, `loadMapCodeFromFile`) into `mapcode.lua`.
- [ ] Relocate default map generation to `maps.lua` with data tables only.
- [ ] Move `newButton` UI factory into `ui/button.lua`.
- [ ] Create a top‑level namespace table (`SD`) to hold shared state and
      exported APIs, avoiding globals.
- [ ] Implement a state manager or `love.run` wrapper for clean transitions
      between menu, play and editor modes.

## Testing & Tooling

- [ ] Introduce `luacheck` for linting; add configuration to reject unused
      variables and accidental globals.
- [ ] Add unit tests using `busted` or `luaunit` covering:
      - [ ] Map encode/decode round‑trips.
      - [ ] BFS path construction.
      - [ ] Tower upgrade cost and stat progression.
- [ ] Configure GitHub Actions to run linting and tests on every push.
- [ ] Enforce formatting with `stylua` or `lua-format` in CI.
- [ ] Generate API docs with `ldoc` and publish to GitHub Pages.

## Gameplay Enhancements

- [ ] Integrate `love.audio` and design sound effects/music cues:
      - [ ] Fire tower placement and enemy death sounds.
      - [ ] Loop background music track.
- [ ] Persist user settings (fullscreen, volume, key binds) using
      `love.filesystem`:
      - [ ] Read/write `settings.json` at startup and shutdown.
- [ ] Implement local high‑score saving; design optional online leaderboard
      API:
      - [ ] Store top scores in `scores.json` and display in menu.
- [ ] Add accessibility options: font scaling, color inversion, control
      remapping:
      - [ ] Allow font size multiplier via `love.graphics.newFont`.
      - [ ] Expose key‑binding config in settings menu.

## Performance

- [ ] Build object pools for projectiles, beams and particles.
- [ ] Add `dt` clamping or interpolation to smooth frame spikes.
- [ ] Expose a debug toggle to display frame time and entity counts.
- [ ] Localize frequently used modules (`love.graphics`, `love.mouse`, etc.) to
      locals for performance.

## Packaging & Release

- [ ] Commit a formal `LICENSE` file (MIT).
- [ ] Script cross‑platform builds using `love-release` (or equivalent) to
      output `.love`, `.exe`, `.app` and AppImage packages.
- [ ] Automate release builds in CI for tagged versions.
- [ ] Produce marketing assets: icons, screenshots, store banners.
- [ ] Implement crash logging via a custom `love.errorhandler`.
- [ ] Embed version string and git hash in the main menu.

## Security & Robustness

- [ ] Harden clipboard input validation in `applyMapFromCode` to reject overly
      long or malformed strings.
- [ ] Wrap file read/write operations with `pcall` and surface friendly
      messages on failure.
- [ ] Append a checksum to map codes and verify during decode.
- [ ] Validate `settings.json` fields and fallback to defaults on error.

## Documentation

- [ ] Write developer onboarding instructions and module diagrams.
- [ ] Ensure each change is recorded in `CHANGELOG.md` with date and version.
- [ ] Document `game` state table and entity arrays in the README.

---

_This TODO list is the single source of truth for project progress._

