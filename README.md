# Steam Defense (Black & White, LÖVE 11.x)

Steam Defense is a complete tower‑defense game built entirely in Lua for the
**LÖVE 11.x** framework.  All visuals are vector geometry drawn at runtime – no
sprites, textures or external assets are required.  The project renders in
high‑contrast black and white and ships with a map editor, encoded map sharing,
multiple tower types and an endless wave mode.

This repository contains the full source that powers the desktop build.  Every
file is pure Lua or Markdown and can be inspected or modified without external
tooling.

---

## Architecture and File Overview

| File | Description |
| --- | --- |
| `main.lua` | Monolithic game logic (~1000 lines).  Implements menu, map
editor, wave system, enemy AI, projectile handling and rendering.  Handles
encoding/decoding of map codes, UI widgets, tower definitions and gameplay
loops. |
| `conf.lua` | LÖVE configuration callback.  Sets default window title, desktop
fullscreen, resolution (960×640), vsync and save directory identifier
(`steamdefense_bw`). |
| `CHANGELOG.md` | Release notes for every public build.  Documents new
features, bug fixes and compatibility tweaks. |
| `FUTURE_FEATURES.md` | Roadmap ideas grouped by priority/effort (e.g. boss
waves, new towers, workshop map browser). |
| `.gitignore` | Filters out compiled Lua, build artifacts, OS junk and common
editor files. |

All runtime data, such as `mapcode.txt`, is written to the user’s LÖVE save
directory (`love.filesystem.getSaveDirectory()`), leaving the repo workspace
unchanged during play.

---

## Runtime Dependencies

Steam Defense only relies on **LÖVE 11.x** and the standard Lua 5.1/5.2
libraries.  The following LÖVE modules are used explicitly:

* `love.window` – toggling desktop fullscreen, setting window size and title.
* `love.graphics` – all vector rendering, font management and canvas size
queries.
* `love.mouse` – cursor management (arrow ↔ crosshair during build mode).
* `love.data` – Base64 encoding/decoding for compact map codes.
* `love.system` – clipboard integration for map‑code copy/paste.
* `love.filesystem` – persisting `mapcode.txt` in the user save folder.
* `love.math` – pseudo‑random number generation (seeding waves and enemies).

No third‑party Lua modules are required, keeping distribution simple.

---

## Technical Details

### Grid and Pathing

* The play field is a fixed **16 × 12** grid; each cell is 40 pixels square.
* Path data is stored in `pathPaint[c][r]` and converted to an ordered waypoint
list using **breadth‑first search (BFS)** (`buildPathFromPaint`).  BFS ensures a
connected route from Start to Goal while preventing diagonal movement.
* The resultant path is cached in `pathPoints` for efficient enemy movement.

### Map Code Encoding

* `encodeFromPaint` packs the 16×12 grid into a bit stream, prefixes the header
`SD1`, then encodes to Base64 via `love.data.encode`.
* `decodeToPaint` validates the header, unpacks bits back into a paint table and
extracts Start/Goal coordinates.
* `saveMapCodeToFile` and `loadMapCodeFromFile` persist these codes as
`mapcode.txt` in the LÖVE save directory, enabling simple sharing between
players.

### Towers

Four tower archetypes are hard‑coded in `towerTypes` with base stats and
per‑level upgrades:

1. **Cog Turret** – single‑target bullets, fast reload.
2. **Tesla Coil** – chain‑lightning beam damaging up to three enemies per tick.
3. **Steam Mortar** – arcing shells with splash damage.
4. **Cat‑a‑pult** – launches geometric cats that slow on impact.

Each tower draws its attack radius while being placed and when selected.  Tower
stats (range, damage, fire rate, slow percentage, etc.) are modified per level
as defined in the upgrade table.

### Enemies and Waves

* Enemies spawn along the BFS path.  Three enemy templates (Tin Scuttler,
Bronze Beetle, Iron Grinder) are randomly selected per spawn with stats scaled
by wave number.
* `startNextWave` sets up the spawn cadence; `endWaveIfDone` awards bonus cash
and automatically starts the next wave if Endless mode is enabled.

### User Interface

* **Start Menu:** Carousel of built‑in maps with live miniature preview,
fullscreen indicator and Endless toggle.
* **Sidebar Buttons:** Implemented via a lightweight button factory (`newButton`)
for starting waves, toggling speed, selecting towers, upgrading, selling and
entering the editor.
* **Editor Overlay:** Paint path tiles, set Start/Goal, build BFS path,
copy/paste map codes and save/load `mapcode.txt`.
* On‑screen messages (`game.message`) provide feedback for actions such as
errors or successful saves.

---

## Installation and Execution

1. Install [LÖVE 11.x](https://love2d.org/).
2. Clone or download this repository.
3. From the repo root, run `love .` or `love /path/to/CHEN-TD-1`.

By default the game starts in desktop fullscreen.  Press **F11** or
**Alt + Enter** to toggle windowed mode at any time.  If you prefer starting
windowed, change `t.window.fullscreen = false` in `conf.lua` before launching.

---

## Controls

### Start Menu
* **Enter** – play on the selected map.
* **← / →** – cycle through bundled map slots.
* **E** – open the built‑in editor with the selected map.
* **C** – copy the slot’s map code to the system clipboard.
* **V** – paste clipboard text into the current slot.
* **N** – toggle Endless mode globally.
* **F11** or **Alt + Enter** – toggle fullscreen.
* **Esc** – exit the game.

### Play Mode
* **LMB** – place the currently selected tower.
* **RMB** – cancel placement.
* **1‑4** – select Cog / Tesla / Mortar / Cat‑a‑pult.
* **Space** – start the next wave.
* **Tab** – cycle game speed (1× / 2× / 3×).
* **U** – upgrade the selected tower.
* **S** – sell the selected tower for 60 % of invested cost.
* **M** – enter/exit the map editor.
* **N** – toggle Endless mode while playing.
* **P** – pause/resume.

### Editor Mode
* **LMB** – paint/erase path tiles.
* **RMB** – erase tile (when no tower occupies it).
* **F** – set Start at cursor.
* **G** – set Goal at cursor.
* **Enter** – build path via BFS over painted tiles.
* **X** – copy current map code to clipboard.
* **V** – paste code from clipboard and apply.
* **K** – save code to `mapcode.txt`.
* **L** – load code from `mapcode.txt`.
* **M** – return to play mode.

---

## Default Maps

Four presets are generated at load time in `defaultMaps`:

1. **Zig‑Zag Works** – serpentine route demonstrating turns and timing.
2. **Grand U** – large U‑shaped loop encouraging long‑range towers.
3. **Serpentine Yard** – snake‑like path that alternates direction each row.
4. **Short Dash** – straight shot from left to right.

Each slot stores its layout as a Base64 map code and can be overwritten by the
player via copy/paste.

---

## Encoding Format Reference

```
Byte sequence before Base64:

00‑02:  'S','D','1'          -- format header
03:     GRID_COLS (16)
04:     GRID_ROWS (12)
05‑06:  start.c, start.r
07‑08:  goal.c, goal.r
09‑..:  bit‑packed path data (left→right, top→bottom)
```

Any code failing header or grid validation is rejected with an “Invalid code”
message.

---

## License

Steam Defense is released under the **MIT License**.  See `main.lua` header for
authorship notice.  A formal `LICENSE` file is recommended for distribution.

---

## Project Status

The game is playable but not yet production ready.  See `SUGGESTIONS.md` for
engineering recommendations and `TODO.md` for actionable tasks on the path to a
public release.

