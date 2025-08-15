# Steam Defense (BW, LÖVE2D)

A steampunk, high‑contrast **black & white** tower defense — **geometry‑only sprites**, no external images.
Built for **LÖVE 11.x**. Starts **fullscreen**, supports **windowed** mode, and is fully playable with editor, maps, upgrades, and share codes.

## Features
- **All‑code art** in stark black & white (geometric shapes only).
- **Start Menu**: map carousel with live preview, display mode status, Endless toggle.
- **Multiple Maps**: bundled presets + paste your own **map‑codes** into slots.
- **Map Editor**: paint path, set Start/Goal, BFS path build, copy/paste/share, save/load `mapcode.txt`.
- **Endless Mode**: waves scale and auto‑advance.
- **Towers** *(1–4 hotkeys)*:
  - **Cog Turret** — dependable single‑target shots.
  - **Tesla Coil** — **chains to 3 enemies**; damage over time per tick.
  - **Steam Mortar** — arcing splash damage.
  - **Cat‑a‑pult** — cute geometric cats that **slow** enemies on hit.
- **Economy**: place, **upgrade**, **sell** (60% refund), money/score/lives.
- **Quality of Life**: **Fullscreen default**, **F11 / Alt+Enter** toggle, resizable window, cursor switches to **crosshair** during placement, selected tower panel at bottom.

## Install
1. Install **LÖVE 11.x** — https://love2d.org
2. Download and unzip the project.
3. Run from the folder: `love steamdefense-love2d`

> Starts in **fullscreen**. Toggle to windowed from the **start menu** using **F11** or **Alt+Enter**.

## Controls

### Start Menu
- **Enter**: Play
- **← / →**: Change map
- **E**: Edit selected map
- **C**: Copy selected map’s code
- **V**: Paste code into selected slot
- **N**: Toggle Endless
- **F11 / Alt+Enter**: Toggle fullscreen
- **Esc**: Quit

### Play
- **LMB**: Place tower
- **RMB**: Cancel placement
- **1/2/3/4**: Select Cog / Tesla / Mortar / Cat‑a‑pult
- **Space**: Start next wave
- **Tab**: Speed (1×/2×/3×)
- **U**: Upgrade selected tower
- **S**: Sell selected tower (60% refund)
- **M**: Toggle Editor
- **N**: Toggle Endless
- **P**: Pause

### Editor
- **LMB**: Paint/erase path tiles
- **RMB**: Erase tile
- **F**: Set Start at cursor
- **G**: Set Goal at cursor
- **Enter**: Build path (BFS over painted tiles)
- **X**: Copy current map to clipboard (map‑code)
- **V**: Paste code from clipboard and apply
- **K**: Save to `mapcode.txt`
- **L**: Load from `mapcode.txt`
- **M**: Exit editor

## Shareable Map‑Codes
- Versioned with header **`SD1`**.
- Encode a fixed **16×12** path grid, **Start**, and **Goal**, bit‑packed then Base64.
- Copy/Paste from **Menu** and **Editor**; `mapcode.txt` is read/written in the LÖVE save dir.
- Codes are portable between players using the same grid version.

## Towers & Upgrades
- Each tower has a base statline; upgrades improve damage/range/rate (and special stats like **chain count** or **slow**).
- **Tesla Coil** damages up to **3 targets** simultaneously within range.
- **Cat‑a‑pult** applies a **slow debuff** (percent + duration scale with upgrade level).

## Notes & Compatibility
- Requires **LÖVE 11.x**.
- Lua portability: `table.unpack`/`unpack` handled; `clamp` bounds fixed.
- Cursor mode uses system cursors (arrow/crosshair).
- If you prefer starting in **windowed** mode, set `t.window.fullscreen = false` in `conf.lua`.

## Folder Layout
```
steamdefense-love2d/
├─ main.lua
├─ conf.lua
├─ README.md
├─ CHANGELOG.md
├─ FUTURE_FEATURES.md
└─ (LÖVE save dir at runtime) mapcode.txt
```

## License
MIT — © 2025-08-15
