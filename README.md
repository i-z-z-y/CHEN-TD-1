
# Steam Defense (Love2D) — Start Menu • Multi-Maps • Share Codes • Chain Tesla • Slow Cats

Black & white steampunk **tower defense** — geometric-only. Now with:
- **Start Menu**: cycle built-in maps (←/→), preview, toggle Endless (N), and start (Enter).
- **Multiple Maps**: built-in set; add your own by pasting map-codes into slots.
- **Shareable Map-Codes**: single Base64 string that encodes the path + start/goal.
  - **Copy** from Menu: `C` (selected slot) or Editor: `X`
  - **Paste** from clipboard: Menu `V` (writes into selected slot) or Editor `V` (applies immediately)
- **Editor**: paint path, F/G set Start/Goal, **Enter** build path (BFS), **K** save to `mapcode.txt`, **L** load.
- **Tesla Coil chains to 3** enemies simultaneously (DPS); upgrades improve DPS/range.
- **Cat-a-pult** shots **slow enemies** on hit (slow strength/duration scale with upgrades).

## Run
1. Install [LÖVE 11.x](https://love2d.org/).
2. Run: `love steamdefense-love2d`

## Controls
**Menu**: Enter play • ←/→ change map • E edit map • C copy code • V paste code • N toggle Endless • Esc quit  
**Play**: LMB place • RMB cancel • [1/2/3/4] towers • Space start wave • Tab speed • U upgrade • S sell • M editor • N endless • P pause  
**Editor**: LMB paint • RMB erase • F start • G goal • Enter build • K save • L load • X copy-code • V paste-code • M exit

## Notes
- Map-codes use a fixed 16×12 grid and are versioned (`SD1`). They’re compatible between players.
- `mapcode.txt` is written/read from the LÖVE save directory for the game.
