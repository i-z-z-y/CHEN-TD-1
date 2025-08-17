# Developer Onboarding

## Prerequisites
* [L\u00d6VE 11.x](https://love2d.org/) for running the game.
* Optional tooling (installed via [LuaRocks](https://luarocks.org/)):
  * `luacheck` for linting.

## Getting Started
1. Clone the repository and `cd` into it.
2. Run the game: `love .`.
3. Run linting: `luacheck .`.

## Module Layout
```text
sd.lua            \u2013 shared namespace table
config.lua        \u2013 screen and grid constants
main.lua          \u2013 menu, play and editor logic
path.lua          \u2013 BFS path construction helpers
mapcode.lua       \u2013 map encode/decode and file I/O
maps.lua          \u2013 default map definitions
data/
  towers.lua      \u2013 tower stats and upgrades
  enemies.lua     \u2013 enemy stats
ui/
  button.lua      \u2013 UI button factory
```

These modules interact through the `SD` table exposed in `sd.lua`, allowing
state sharing without relying on global variables.
