# Changelog

All notable changes to **Steam Defense (BW, LÖVE2D)** are documented here.
Dates use YYYY-MM-DD. Semantic-ish versions are used for clarity.

## [1.2.1] - 2025-08-15 — Build Range Preview
### Added
- Placement cursor now shows the **attack radius** of the tower being positioned.

## [1.2.0] - 2025-08-15 — Fullscreen & UX polish
### Added
- **Start in fullscreen** (desktop fullscreen). Menu shows current display mode.
- **Fullscreen hotkeys:** **F11** and **Alt+Enter** toggle anywhere (menu, play, editor).
- **Build-mode cursor:** shows **crosshair** while placing towers; arrow otherwise.
- **Resizable window** remains supported when toggled to windowed.

### Changed
- **Selected tower info** moved to the **bottom** of the sidebar to prevent overlapping the build buttons.
- Menu footer updated with fullscreen hotkey hints.

### Fixed
- **Syntax issues** after rapid iteration:
  - Duplicate `end` and repeated cursor lines following `refreshCursor()` (blue screen).
  - Stray regex backreference artifact (`\1`) left in `love.keypressed` (syntax error near '\').
  - Orphaned keypress logic outside of `love.keypressed` (unexpected `end` / `<eof>`).
  - Guarded `setFullscreen()` to avoid calling `refreshCursor` before it exists.
- **Compatibility**:
  - `packBytes` now uses `(table.unpack or unpack)` for Lua 5.1/5.2 compatibility.
  - `clamp` corrected to return **upper bound** when `v > b`.
  - Defensive init of `blocked[c]` in `buildPathFromPaint()` to avoid nil index.

## [1.1.0] - 2025-08-15 — Maps, Codes, & Combat Updates
### Added
- **Start Menu** with retail feel: live map preview, Endless toggle, and Play.
- **Multiple built‑in maps** (Zig‑Zag Works, Grand U, Serpentine Yard, Short Dash) and a slot system.
- **Shareable map‑code strings**:
  - Base64 `SD1` header + bit‑packed 16×12 path, plus Start/Goal.
  - **Copy/Paste** in both Menu and Editor; save/load via `mapcode.txt` in LÖVE save dir.
- **Endless Mode** (auto next wave with scaling).
- **Cat‑a‑pult** tower with geometric **cat projectiles** (programmatic sprite).

### Changed
- **Tesla Coil** now **chains to up to 3 enemies** (per tick); upgrades improve DPS/range.
- **Cat‑a‑pult** shots now **slow** enemies on hit (slow % and duration scale with upgrades).

## [1.0.0] - 2025-08-15 — First public build
### Added
- Complete high‑contrast black & white **tower defense** (no image assets; all geometry).
- Towers: **Cog Turret**, **Tesla Coil**, **Steam Mortar**.
- **Economy** (place/upgrade/sell 60%), waves, cash/score/lives, pause, time scale (1×/2×/3×).
- **Map Editor** (paint path; set Start/Goal; BFS path; save/load).
- **Cat‑a‑pult** + Endless were requested and landed soon after; tracked above.
