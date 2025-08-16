local config = {
  W = 960,
  H = 640,
  GRID_COLS = 16,
  GRID_ROWS = 12,
  CELL = 40,
}

config.FIELD_W = config.GRID_COLS * config.CELL
config.UI_W = config.W - config.FIELD_W

return config
