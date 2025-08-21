# Production Readiness Suggestions

This document lists engineering and product improvements required to ship Steam
Defense as a commercial or community‑ready release. Items are derived from a
full review of **every file** in the repository (`main.lua`, `conf.lua`,
`CHANGELOG.md`, `FUTURE_FEATURES.md`, `.gitignore`, existing docs).

## Codebase Structure

1. **Modularize `main.lua`:**
   - Split the 1000‑line monolith into focused modules (`menu.lua`,
     `gameplay.lua`, `towers.lua`, `enemy.lua`, `editor.lua`).
   - Extract **pathfinding** helpers (`neighbors`, `buildPathFromPaint`,
     `rebuildPathPoints`) into `path.lua`.
   - Extract **map‑code** helpers (`encodeFromPaint`, `decodeToPaint`,
     `saveMapCodeToFile`, `loadMapCodeFromFile`) into `mapcode.lua`.
   - Move `defaultMaps` and map slot logic into `maps.lua` with pure data tables.
   - Use `require` to expose clean APIs and reduce inter‑function coupling.
   - Encapsulate state into tables or classes instead of scattering locals.
2. **Establish a global namespace:** avoid polluting `_G`; expose a single table
   (e.g., `SD`) to hold shared functions and configuration.
3. **Introduce a formal `love.run` or state manager** to handle transitions
   rather than branching on `game.state` inside callbacks.
4. **Isolate UI widgets:** place the `newButton` factory and related draw logic
   into `ui/button.lua` to simplify unit testing and reuse.
5. **Centralize configuration constants:** move `W`, `H`, `GRID_COLS`,
   `GRID_ROWS` and `CELL` from the top of `main.lua` into a dedicated
   `config.lua` module so window and grid sizes can be adjusted without
   touching gameplay logic【F:main.lua†L5-L9】.
6. **Data‑drive tower and enemy stats:** load tower definitions and enemy
   templates from external Lua or JSON tables (e.g., `data/towers.lua`,
   `data/enemies.lua`) instead of hard‑coding them in `main.lua` to enable
   balancing without code changes【F:main.lua†L305-L344】【F:main.lua†L552-L568】.
7. **Enhance `love.resize` handling:** expand the existing callback to refresh
   the cursor and mirror `setFullscreen`’s layout updates so manual window
   resizes behave consistently【F:main.lua†L50-L64】【F:main.lua†L1004-L1007】.

## Quality and Maintainability

1. **Add unit tests** for deterministic functions:
   - Map encode/decode round‑trips (`encodeFromPaint` ↔ `decodeToPaint`).
   - BFS path building (`buildPathFromPaint`) to ensure path validity.
   - Money/tower upgrade logic.
   Use `busted` or `luaunit` and integrate with CI.
2. **Automated linting** via `luacheck` to enforce style, unused variable and
   global checks.
3. **Document a coding style guide** (indentation, naming, module boundaries)
   for contributors and enforce it with `stylua` or `lua-format`.
4. **Generate API documentation** using [LDoc](https://stevedonovan.github.io/ldoc/) for all modules.
5. **Continuous syntax checks**: run `luac -p` on every Lua file in CI to fail
   early on parse errors, complementing linting tools.
6. **Coverage tracking:** integrate `luacov` to generate code‑coverage reports
   and surface them in CI for regression detection.

## Gameplay Features

1. **Audio layer:** integrate `love.audio` for music, placement sounds and enemy
   cues. Provide volume sliders in a future settings menu and load audio assets
   via `love.audio.newSource`.
2. **Persisted settings:** store fullscreen preference, volumes and key binds in
   a `settings.json` file using `love.filesystem`; include last window
   dimensions so desktop sessions reopen at the previous size.
3. **High‑score storage:** save top waves/scores locally in `scores.json` and
   optionally sync to an online leaderboard.
4. **Accessibility options:** adjustable font scale (via
   `love.graphics.newFont`), color inversion toggle and remappable controls.
5. **Dynamic button layout:** auto‑generate sidebar buttons from `towerTypes`
   to prevent label duplication and ensure new towers appear without manual UI
   updates【F:main.lua†L630-L653】.

## Performance and Optimization

1. **Object pooling** for projectiles, beams and particles to reduce garbage
   generation during long sessions.
2. **Delta‑time smoothing:** clamp or interpolate `dt` to avoid spikes when the
   game is minimized or dragged between monitors.
3. **Profiling hooks:** expose a toggle to print frame time and counts of active
   entities for regression tracking.
4. **Localize LÖVE modules:** cache `love.graphics`, `love.mouse` and others in
   locals at the top of modules to avoid repeated table lookups each frame.
5. **State change minimization:** cache current `love.graphics` colors and line
   widths to avoid redundant `setColor`/`setLineWidth` calls inside draw loops,
   reducing GPU state churn【F:main.lua†L386-L399】【F:main.lua†L840-L846】.

## Distribution & Packaging

1. **Add a `LICENSE` file** clarifying proprietary rights and usage terms.
2. **Versioned builds:** script releases using `love-release` or similar to
   produce `.love`, Windows `.exe`, macOS `.app` and Linux AppImage packages.
3. **CI pipeline:** use GitHub Actions to run tests/linters and generate release
   artifacts on tagged commits.
4. **Embed version strings:** display semantic version and git hash on the menu
   screen using data from `CHANGELOG.md` and tags.
5. **Metadata and branding:** create high‑resolution icon, store banner and
   screenshots for itch.io/Steam listings.
6. **Crash reporting:** wrap `love.errorhandler` with custom logging to capture
   stack traces and user environment details.
7. **Embed window icon and metadata:** supply `t.window.icon` in `conf.lua`
   alongside the existing window fields and include desktop metadata files
   (`.desktop`, `.app`, `Info.plist`) for each platform【F:conf.lua†L1-L9】.
8. **High‑DPI support:** set `t.window.highdpi = true` in `conf.lua` and bundle
   scaled icons so the game renders crisply on retina/4K displays.

## Security & Robustness

1. **Validate clipboard input** in `applyMapFromCode` beyond Base64 errors to
   prevent extremely long strings from causing allocation spikes (cap length and
   reject non‑ASCII characters).
2. **Guard file I/O** with `pcall` to handle read/write errors (e.g. read‑only
   directories or permission issues).
3. **Checksum map codes** to detect corruption and reject incompatible versions
   gracefully.
4. **Sanitize user config**: when loading `settings.json`, validate JSON fields
   and fallback to defaults on parse errors.
5. **Clipboard length cap:** limit `love.system.getClipboardText` to a maximum
   length (e.g., 256 characters) before attempting `decodeToPaint` to avoid
   allocating enormous strings.【F:main.lua†L923-L933】【F:main.lua†L996-L997】

## Documentation

1. **Expand developer documentation** with build instructions, module diagrams
   and contribution guidelines.
2. **Changelog discipline:** ensure every feature/fix lands with a version entry
   and date.
3. **Explain data structures**: detail `game`, `towers`, `enemies`, etc. in the
   README so new contributors understand state layout.
4. **CHANGELOG gatekeeping:** add a commit hook ensuring any change touching
   `main.lua` or gameplay code comes with a corresponding dated entry in
   `CHANGELOG.md`.

These suggestions aim to bridge the gap between a functional prototype and a
market‑ready product.

