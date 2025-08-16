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

| File | Lines | Description |
| --- | --- | --- |
| `main.lua` | 1007 | Monolithic game logic. Implements menu, editor, wave
system, enemy AI, projectile handling and rendering. Handles
encoding/decoding of map codes, UI widgets, tower definitions and gameplay
loops. |
| `conf.lua` | 10 | LÖVE configuration callback. Sets default window title,
desktop fullscreen, resolution (960×640), vsync and save directory identifier
(`steamdefense_bw`). |
| `CHANGELOG.md` | 52 | Release notes for every public build. Documents new
features, bug fixes and compatibility tweaks. |
| `FUTURE_FEATURES.md` | 41 | Roadmap ideas grouped by priority/effort (e.g.
boss waves, new towers, workshop map browser). |
| `SUGGESTIONS.md` | 82 | Production‑readiness recommendations derived from
source review. |
| `TODO.md` | 67 | Task tracker translating suggestions into actionable work. |
| `.gitignore` | 150 | Filters out compiled Lua, build artifacts, OS junk and
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
* `love.keyboard` – reading hotkeys for menu navigation, tower selection and editor commands.
* `love.event` – quitting the game from the menu via `love.event.quit`.

No third‑party Lua modules are required, keeping distribution simple.

---

## Technical Details

### Internal Data Structures

* `game` – central mutable state (fullscreen flag, current state, currency,
  lives, score, wave counters, speed, pause flag and messaging).
* `fonts` – preloaded `love.graphics.newFont` objects used across UI draws.
* `grid` and `blocked` – 16×12 boolean matrices tracking tower occupancy and
  path cells.
* `towers`, `enemies`, `projectiles`, `beams`, `particles` – arrays of live
  entities updated each frame.
* `pathPaint` – editable paint grid backing the map editor; `startCell` and
  `goalCell` store endpoints.
* `path`/`pathPoints` – ordered tables of path cells and their pixel centres for
  enemy movement.
* `ui.buttons` – sidebar button definitions; `menu.maps` – default map slot
  data including Base64 codes.

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

### LÖVE Callback Flow

* **`love.conf`** (in `conf.lua`) – defines window size, resizability, vsync,
  desktop fullscreen and the save directory identifier.
* **`love.load`** – initializes fonts, cursors, default maps, sidebar buttons and
  window mode; seeds RNG and applies the first map.
* **`love.update`** – processes messages, wave timers, enemy movement, tower
  firing, projectile trajectories, particle decay and wave completion via
  `endWaveIfDone`.
* **`love.draw`** – renders grid, path, entities, UI panels, range previews and
  editor overlay; prints control helper text.
* **`love.mousepressed`** – handles UI button clicks, tower placement, map
  editing toggles and cancellation with right click.
* **`love.keypressed`** – processes fullscreen toggles, menu navigation, tower
  hotkeys, editor shortcuts and global commands like pause and speed cycling.
* **`love.resize`** – updates cached dimensions when the window size changes.

### Internal Function Reference

For contributors needing deeper insight, notable local functions within
`main.lua` include:

* `setFullscreen(on)` — wraps `love.window.setFullscreen` and `love.window.setMode`
  to toggle desktop fullscreen while recalculating `W`, `H` and sidebar width; it
  also refreshes the cursor to avoid stale state【F:main.lua†L50-L64】.
* `refreshCursor()` — swaps between arrow and crosshair system cursors via
  `love.mouse.setCursor` depending on build mode state【F:main.lua†L67-L77】.
* `resetGameStats()` — clears currency, lives, wave counters and entity arrays
  when starting a new session【F:main.lua†L86-L92】.
* `buildPathFromPaint()` — performs a breadth‑first search over `pathPaint`
  to ensure a contiguous route from `startCell` to `goalCell`, rebuilds
  `pathPoints` and marks `blocked` cells used by the path【F:main.lua†L122-L164】.
* `encodeFromPaint()` / `decodeToPaint()` — serialize the 16×12 grid with an
  `SD1` header into Base64 using `love.data.encode` and decode it back, fully
  reconstructing path, start and goal positions【F:main.lua†L166-L219】.
* `saveMapCodeToFile()` / `loadMapCodeFromFile()` — persist map codes to
  `mapcode.txt` in the LÖVE save directory using `love.filesystem` with a
  status message displayed in `game.message`【F:main.lua†L245-L256】.
* `addMap()` / `defaultMaps()` — generate four built‑in layouts and insert them
  into the menu map list, each represented by a Base64 code【F:main.lua†L258-L301】.
* `towerTypes` table — defines cog, tesla, mortar and cat towers with cost,
  range, damage stats and per‑level upgrade tables【F:main.lua†L305-L344】.
* `spawnBullet`, `spawnMortarShell`, `spawnBeam`, `spawnRing` — construction
  helpers for projectiles, beam effects and particle rings appended to their
  respective arrays【F:main.lua†L351-L372】.
* `placeSelectedAt(cx, cy)` — validates placement coordinates, subtracts cost
  via `spend()` and inserts a new tower into the grid【F:main.lua†L519-L527】.
* `nearestEnemy()` / `nearestNEnemies()` — targeting utilities used by tower
  logic to pick optimal foes within range【F:main.lua†L530-L550】.
* `makeEnemy(waveNum)` — constructs a randomised enemy table per wave using
  `love.math.random`, scaling HP and speed by wave index【F:main.lua†L552-L568】.
* `startNextWave()` and `endWaveIfDone(dt)` — manage wave progression, spawn
  cadence and cash bonuses once all enemies are eliminated【F:main.lua†L570-L596】.
* `love.update(dt)` — central game loop handling enemy movement, tower firing,
  projectile collision, beam decay and wave completion each frame【F:main.lua†L683-L821】.
* `love.keypressed(key)` — covers fullscreen toggles, menu navigation,
  tower hotkeys, editor shortcuts and saving/loading map codes through clipboard
  interactions【F:main.lua†L882-L999】.

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

