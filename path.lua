local config = require("config")
local GRID_COLS, GRID_ROWS = config.GRID_COLS, config.GRID_ROWS
local CELL = config.CELL

local Path = {}

function Path.neighbors(c, r)
  return {{c+1, r}, {c-1, r}, {c, r+1}, {c, r-1}}
end

local function cellCenter(cx, cy)
  return (cx-0.5)*CELL, (cy-0.5)*CELL
end

function Path.rebuildPathPoints(path)
  local pathPoints = {}
  for i,p in ipairs(path) do
    local x,y = cellCenter(p[1], p[2])
    pathPoints[i] = {x=x, y=y}
  end
  return pathPoints
end

local function inside(c, r)
  return c>=1 and c<=GRID_COLS and r>=1 and r<=GRID_ROWS
end

function Path.buildPathFromPaint(pathPaint, startCell, goalCell)
  if not (inside(startCell.c,startCell.r) and inside(goalCell.c,goalCell.r)) then
    return false, nil, nil, "Start/Goal outside grid"
  end
  if not (pathPaint[startCell.c][startCell.r] and pathPaint[goalCell.c][goalCell.r]) then
    return false, nil, nil, "Start and Goal must be on painted tiles"
  end
  local q, prev, seen = {}, {}, {}
  local function key(c,r) return c..":"..r end
  table.insert(q, {c=startCell.c, r=startCell.r})
  seen[key(startCell.c,startCell.r)] = true
  prev[key(startCell.c,startCell.r)] = nil
  local found = false
  while #q>0 do
    local cur = table.remove(q, 1)
    if cur.c==goalCell.c and cur.r==goalCell.r then found=true break end
    for _,n in ipairs(Path.neighbors(cur.c,cur.r)) do
      if inside(n[1],n[2]) and pathPaint[n[1]][n[2]] and not seen[key(n[1],n[2])] then
        seen[key(n[1],n[2])] = true
        prev[key(n[1],n[2])] = cur
        table.insert(q, {c=n[1], r=n[2]})
      end
    end
  end
  if not found then return false, nil, nil, "No connected path from Start to Goal" end
  local out, cur = {}, {c=goalCell.c, r=goalCell.r}
  while cur do
    table.insert(out, 1, {cur.c, cur.r})
    cur = prev[key(cur.c, cur.r)]
  end
  local blocked = {}
  for c=1,GRID_COLS do
    blocked[c] = {}
    for r=1,GRID_ROWS do blocked[c][r] = false end
  end
  for _,p in ipairs(out) do
    blocked[p[1]] = blocked[p[1]] or {}
    blocked[p[1]][p[2]] = true
  end
  return true, out, blocked
end

return Path

