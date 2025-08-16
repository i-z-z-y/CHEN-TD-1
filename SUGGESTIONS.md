# Production Readiness Suggestions

This document lists engineering and product improvements required to ship Steam
Defense as a commercial or community‑ready release.  Items are derived from a
full review of the current source (`main.lua`, `conf.lua`, `CHANGELOG.md`,
`FUTURE_FEATURES.md`, `.gitignore`).

## Codebase Structure

1. **Modularize `main.lua`:**
   - Split the 1000‑line monolith into focused modules (`menu.lua`,
     `gameplay.lua`, `towers.lua`, `enemy.lua`, `editor.lua`).
   - Use `require` to expose clean APIs and reduce inter‑function coupling.
   - Encapsulate state into tables or classes instead of scattering locals.
2. **Establish a global namespace:** avoid polluting `_G`; expose a single table
   (e.g., `SD`) to hold shared functions and configuration.
3. **Introduce a formal `love.run` or state manager** to handle transitions
   rather than branching on `game.state` inside callbacks.

## Quality and Maintainability

1. **Add unit tests** for deterministic functions:
   - Map encode/decode round‑trips (`encodeFromPaint` ↔ `decodeToPaint`).
   - BFS path building (`buildPathFromPaint`) to ensure path validity.
   - Money/tower upgrade logic.
   Use `busted` or `luaunit` and integrate with CI.
2. **Automated linting** via `luacheck` to enforce style, unused variable and
   global checks.
3. **Document a coding style guide** (indentation, naming, module boundaries)
   for contributors.

## Gameplay Features

1. **Audio layer:** integrate `love.audio` for music, placement sounds and enemy
   cues.  Provide volume sliders in a future settings menu.
2. **Persisted settings:** store fullscreen preference, volumes and key binds in
   a config file within `love.filesystem`.
3. **High‑score storage:** save top waves/scores locally and optionally sync to
   an online leaderboard.
4. **Accessibility options:** adjustable font scale, color inversion toggle and
   remappable controls.

## Performance and Optimization

1. **Object pooling** for projectiles, beams and particles to reduce garbage
   generation during long sessions.
2. **Delta‑time smoothing:** clamp or interpolate `dt` to avoid spikes when the
   game is minimized or dragged between monitors.
3. **Profiling hooks:** expose a toggle to print frame time and counts of active
   entities for regression tracking.

## Distribution & Packaging

1. **Add a `LICENSE` file** matching the MIT reference to clarify terms.
2. **Versioned builds:** script releases using `love-release` or similar to
   produce `.love`, Windows `.exe`, macOS `.app` and Linux AppImage packages.
3. **CI pipeline:** use GitHub Actions to run tests/linters and generate release
   artifacts on tagged commits.
4. **Metadata and branding:** create high‑resolution icon, store banner and
   screenshots for itch.io/Steam listings.
5. **Crash reporting:** wrap `love.errorhandler` with custom logging to capture
   stack traces and user environment details.

## Security & Robustness

1. **Validate clipboard input** in `applyMapFromCode` beyond Base64 errors to
   prevent extremely long strings from causing allocation spikes.
2. **Guard file I/O** with `pcall` to handle read/write errors (e.g. read‑only
   directories or permission issues).
3. **Checksum map codes** to detect corruption and reject incompatible versions
   gracefully.

## Documentation

1. **Expand developer documentation** with build instructions, module diagrams
   and contribution guidelines.
2. **Changelog discipline:** ensure every feature/fix lands with a version entry
   and date.

These suggestions aim to bridge the gap between a functional prototype and a
market‑ready product.

