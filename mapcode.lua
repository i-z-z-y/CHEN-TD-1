local config = require("config")
local GRID_COLS, GRID_ROWS = config.GRID_COLS, config.GRID_ROWS

local Mapcode = {}

local function packBytes(t)
  local u = table.unpack or unpack
  return string.char(u(t))
end

local function unpackByte(s,i) return s:byte(i,i) end

function Mapcode.encodeFromPaint(paint, start, goal)
  local bytes = { string.byte('S'), string.byte('D'), string.byte('1'),
                  GRID_COLS, GRID_ROWS, start.c, start.r, goal.c, goal.r }
  local acc, bits = 0, 0
  for r=1,GRID_ROWS do
    for c=1,GRID_COLS do
      local b = (paint[c] and paint[c][r]) and 1 or 0
      acc = acc*2 + b; bits = bits + 1
      if bits==8 then table.insert(bytes, acc); acc, bits = 0, 0 end
    end
  end
  if bits>0 then
    for _=bits+1,8 do acc = acc*2 end
    table.insert(bytes, acc)
  end
  local raw = packBytes(bytes)
  return love.data.encode("string","base64", raw)
end

function Mapcode.decodeToPaint(code)
  local ok, raw = pcall(function() return love.data.decode("string","base64", code) end)
  if not ok or not raw or #raw < 9 then return false end
  if raw:sub(1,3) ~= 'SD1' then return false end
  local cols = unpackByte(raw,4); local rows = unpackByte(raw,5)
  if cols ~= GRID_COLS or rows ~= GRID_ROWS then return false end
  local start = {c=unpackByte(raw,6), r=unpackByte(raw,7)}
  local goal  = {c=unpackByte(raw,8), r=unpackByte(raw,9)}
  local paint = {}
  for c=1,GRID_COLS do paint[c] = {} end
  local idxByte = 10
  local total = GRID_COLS*GRID_ROWS
  local count = 0
  while count < total and idxByte <= #raw do
    local b = unpackByte(raw, idxByte); idxByte = idxByte + 1
    for bit=7,0,-1 do
      if count >= total then break end
      local mask = 2^bit
      local v = (math.floor(b / mask) % 2)==1
      local r = math.floor(count / GRID_COLS) + 1
      local c = (count % GRID_COLS) + 1
      paint[c][r] = v
      count = count + 1
    end
  end
  return true, {paint=paint, start=start, goal=goal}
end

function Mapcode.saveMapCodeToFile(paint, start, goal)
  local code = Mapcode.encodeFromPaint(paint, start, goal)
  return love.filesystem.write("mapcode.txt", code or "")
end

function Mapcode.loadMapCodeFromFile()
  return love.filesystem.read("mapcode.txt")
end

return Mapcode

