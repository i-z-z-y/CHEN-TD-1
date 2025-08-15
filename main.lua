-- SteamDefense BW — Start Menu + Multi-Maps + Share Codes + Chain Tesla + Slow Cats
-- LÖVE 11.x - high-contrast black & white, no image assets.
-- Author: ChatGPT (GPT-5 Thinking) | License: MIT

local W, H = 960, 640
local GRID_COLS, GRID_ROWS = 16, 12
local CELL = 40
local FIELD_W = GRID_COLS * CELL
local UI_W = W - FIELD_W

local game = {
  fullscreen = false,
  state = "menu", -- "menu" | "play" | "editor"
  money = 200,
  lives = 20,
  score = 0,
  wave = 0,
  waveActive = false,
  timeScale = 1.0,
  paused = false,
  selectedType = nil,
  selectedTower = nil,
  message = "",
  messageTimer = 0,
  endless = false,
  waveAutoTimer = 0,
}

local fonts = {}
local grid = {}
local blocked = {} -- path occupancy
local towers = {}
local projectiles = {}
local beams = {}
local particles = {}
local enemies = {}

-- Map data (paint grid) and endpoints
local pathPaint = {}
local startCell = {c=1, r=6}
local goalCell  = {c=16, r=7}

-- The path points used for enemy movement (built from paint via BFS)
local path = {}
local pathPoints = {}

local mouse = { x=0, y=0 }
local ui = { buttons = {} }

-- Fullscreen toggle
local function setFullscreen(on)
  game.fullscreen = on and true or false
  if on then
    love.window.setFullscreen(true, "desktop")
  else
    -- restore a sensible windowed size; keep resizable
    love.window.setFullscreen(false)
    love.window.setMode(960, 640, {resizable=true, vsync=1})
  end
  -- update layout after mode change
  W, H = love.graphics.getWidth(), love.graphics.getHeight()
  UI_W = W - FIELD_W
  if refreshCursor then refreshCursor() end
end


-- Cursor handling
local cursors = {}
local currentCursor = "arrow"
local function refreshCursor()
  local desired = "arrow"
  if game.state=="play" and game.selectedType then desired = "cross" end
  if desired ~= currentCursor and cursors[desired] then
    love.mouse.setCursor(cursors[desired])
    currentCursor = desired
  end
end

-- Utilities
local function clamp(v,a,b) if v<a then return a elseif v>b then return b else return v end end
local function dist(x1,y1,x2,y2) return ((x2-x1)^2 + (y2-y1)^2)^0.5 end
local function cellCenter(cx, cy) return (cx-0.5)*CELL, (cy-0.5)*CELL end
local function worldToCell(x, y) return math.floor(x / CELL) + 1, math.floor(y / CELL) + 1 end
local function inField(x, y) return x >= 0 and x < FIELD_W and y >= 0 and y < H end

local function resetGameStats()
  game.money, game.lives, game.score = 200, 20, 0
  game.wave, game.waveActive, game.timeScale, game.paused = 0, false, 1.0, false
  game.selectedType, game.selectedTower = nil, nil
  game.message, game.messageTimer = "", 0
  towers, projectiles, beams, particles, enemies = {}, {}, {}, {}, {}
end

-- Path helpers
local function rebuildPathPoints()
  pathPoints = {}
  for i,p in ipairs(path) do
    local x,y = cellCenter(p[1], p[2])
    pathPoints[i] = {x=x, y=y}
  end
end

local function initGrid()
  grid = {}
  blocked = {}
  for c=1,GRID_COLS do
    grid[c] = {}; blocked[c] = {}; pathPaint[c] = pathPaint[c] or {}
    for r=1,GRID_ROWS do
      grid[c][r] = false
      blocked[c][r] = false
      pathPaint[c][r] = pathPaint[c][r] and true or false
    end
  end
  for _,p in ipairs(path) do blocked[p[1]][p[2]] = true end
end

local function neighbors(c,r)
  return {{c+1,r},{c-1,r},{c,r+1},{c,r-1}}
end
local function inside(c,r) return c>=1 and c<=GRID_COLS and r>=1 and r<=GRID_ROWS end

local function buildPathFromPaint()
  if not (inside(startCell.c,startCell.r) and inside(goalCell.c,goalCell.r)) then
    return false, "Start/Goal outside grid"
  end
  if not (pathPaint[startCell.c][startCell.r] and pathPaint[goalCell.c][goalCell.r]) then
    return false, "Start and Goal must be on painted tiles"
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
    for _,n in ipairs(neighbors(cur.c,cur.r)) do
      if inside(n[1],n[2]) and pathPaint[n[1]][n[2]] and not seen[key(n[1],n[2])] then
        seen[key(n[1],n[2])] = true
        prev[key(n[1],n[2])] = cur
        table.insert(q, {c=n[1], r=n[2]})
      end
    end
  end
  if not found then return false, "No connected path from Start to Goal" end
  local out, cur = {}, {c=goalCell.c, r=goalCell.r}
  while cur do
    table.insert(out, 1, {cur.c, cur.r})
    cur = prev[key(cur.c, cur.r)]
  end
  -- reset blocked and set to path (ensure 2D table exists)
  for c=1,GRID_COLS do
    blocked[c] = blocked[c] or {}
    for r=1,GRID_ROWS do blocked[c][r] = false end
  end
  for _,p in ipairs(out) do
    blocked[p[1]] = blocked[p[1]] or {}
    blocked[p[1]][p[2]] = true
  end
  path = out
  rebuildPathPoints()
  return true
end

-- Encode/Decode shareable map-code strings (base64; header "SD1"; bit-packed paint)
local function packBytes(t)
  local u = table.unpack or unpack
  return string.char(u(t))
end
local function unpackByte(s,i) return s:byte(i,i) end

local function encodeFromPaint(paint, start, goal)
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
    -- pad remaining bits with zeros
    for i=bits+1,8 do acc = acc*2 end
    table.insert(bytes, acc)
  end
  local raw = packBytes(bytes)
  return love.data.encode("string","base64", raw)
end

local function decodeToPaint(code)
  local ok, raw = pcall(function() return love.data.decode("string","base64", code) end)
  if not ok or not raw or #raw < 9 then return false, "Invalid code" end
  if raw:sub(1,3) ~= "SD1" then return false, "Unknown code header" end
  local cols = unpackByte(raw,4); local rows = unpackByte(raw,5)
  if cols ~= GRID_COLS or rows ~= GRID_ROWS then return false, "Grid size mismatch" end
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

local function encodeMapToCodeCurrent()
  return encodeFromPaint(pathPaint, startCell, goalCell)
end

local function applyMapFromDecoded(decoded)
  pathPaint = {}
  for c=1,GRID_COLS do
    pathPaint[c] = {}
    for r=1,GRID_ROWS do pathPaint[c][r] = decoded.paint[c][r] and true or false end
  end
  startCell = {c=decoded.start.c, r=decoded.start.r}
  goalCell  = {c=decoded.goal.c,  r=decoded.goal.r}
  local ok, err = buildPathFromPaint()
  if not ok then game.message = err or "Path build failed"; game.messageTimer=2 end
  initGrid()
end

local function applyMapFromCode(code)
  local ok, decoded = decodeToPaint(code)
  if not ok then game.message = decoded or "Decode failed"; game.messageTimer=2 return false end
  applyMapFromDecoded(decoded)
  return true
end

-- Save/Load via love save dir (mapcode.txt)
local function saveMapCodeToFile()
  local code = encodeMapToCodeCurrent()
  love.filesystem.write("mapcode.txt", code or "")
  game.message="Map-code saved to save dir (mapcode.txt)"; game.messageTimer=1.8
end

local function loadMapCodeFromFile()
  if not love.filesystem.getInfo("mapcode.txt") then game.message="No mapcode.txt found" game.messageTimer=1.6 return end
  local s = love.filesystem.read("mapcode.txt")
  applyMapFromCode(s or "")
end

-- Built-in maps (generated at load)
local menu = { idx=1, maps={} }
local function addMap(name, paintList, sCell, gCell)
  -- paintList: array of {c,r} cells that are path; sCell/gCell explicit
  local localPaint = {}
  for c=1,GRID_COLS do localPaint[c] = {}; for r=1,GRID_ROWS do localPaint[c][r]=false end end
  for _,p in ipairs(paintList) do localPaint[p[1]][p[2]] = true end
  local code = encodeFromPaint(localPaint, sCell, gCell)
  table.insert(menu.maps, {name=name, code=code})
end

local function defaultMaps()
  menu.maps = {}
  -- 1) Classic Zig-Zag
  local zz = {}
  for c=1,6 do table.insert(zz, {c,6}) end
  table.insert(zz,{6,5}); table.insert(zz,{6,4})
  for c=7,11 do table.insert(zz,{c,4}) end
  table.insert(zz,{11,5}); table.insert(zz,{11,6}); table.insert(zz,{11,7})
  for c=12,16 do table.insert(zz,{c,7}) end
  addMap("Zig-Zag Works", zz, {c=1,r=6}, {c=16,r=7})

  -- 2) Big U
  local uu = {}
  for r=2,11 do table.insert(uu,{2,r}) end
  for c=2,14 do table.insert(uu,{c,11}) end
  for r=3,10 do table.insert(uu,{14,r}) end
  addMap("Grand U", uu, {c=2,r=2}, {c=14,r=10})

  -- 3) Serpentine
  local sp = {}
  for r=3,9 do
    if r%2==1 then for c=2,15 do table.insert(sp,{c,r}) end else for c=15,2,-1 do table.insert(sp,{c,r}) end end
  end
  addMap("Serpentine Yard", sp, {c=2,r=3}, {c=15,r=9})

  -- 4) Short Dash
  local sd = {}
  for c=1,16 do table.insert(sd,{c,6}) end
  addMap("Short Dash", sd, {c=1,r=6}, {c=16,r=6})

  if #menu.maps==0 then
    -- fallback: use zig-zag
    addMap("Default", zz, {c=1,r=6}, {c=16,r=7})
  end
end

-- Towers
local towerTypes = {
  cog = {
    name="Cog Turret",
    cost=50, range=140, fireRate=1.0, damage=20, bulletSpeed=320,
    upgrade = {
      {cost=45, damage=28, range=150, fireRate=1.2},
      {cost=70, damage=38, range=165, fireRate=1.4},
      {cost=100, damage=52, range=180, fireRate=1.6},
    }
  },
  tesla = {
    name="Tesla Coil",
    cost=90, range=130, dps=28, chains=3,
    upgrade = {
      {cost=70, dps=40, range=145, chains=3},
      {cost=100, dps=56, range=160, chains=3},
      {cost=140, dps=78, range=175, chains=3},
    }
  },
  mortar = {
    name="Steam Mortar",
    cost=90, range=200, splash=70, damage=24, fireRate=0.6, projSpeed=220,
    upgrade = {
      {cost=70, damage=36, splash=80, range=220, fireRate=0.7},
      {cost=100, damage=52, splash=92, range=230, fireRate=0.8},
      {cost=140, damage=72, splash=105, range=240, fireRate=0.9},
    }
  },
  cat = {
    name="Cat-a-pult",
    cost=75, range=155, fireRate=1.1, damage=22, bulletSpeed=300,
    slowPct=0.35, slowDur=1.2,
    upgrade = {
      {cost=60, damage=30, range=170, fireRate=1.25, slowPct=0.40, slowDur=1.3},
      {cost=90, damage=40, range=185, fireRate=1.45, slowPct=0.45, slowDur=1.4},
      {cost=130, damage=56, range=200, fireRate=1.65, slowPct=0.50, slowDur=1.5},
    }
  }
}

local function makeTower(tt, cx, cy)
  local x,y = cellCenter(cx, cy)
  return {type=tt, cx=cx, cy=cy, x=x, y=y, level=0, cooldown=0, totalCost=towerTypes[tt].cost}
end

-- Projectiles
local function spawnBullet(x, y, target, speed, damage, kind, extra)
  local ang = 0
  if target then ang = math.atan2((target.y - y), (target.x - x)) end
  local p = {kind=kind or "bullet", x=x, y=y, target=target, speed=speed, damage=damage, r=4, alive=true, a=ang}
  if extra then for k,v in pairs(extra) do p[k]=v end end
  table.insert(projectiles, p)
end

local function spawnMortarShell(x, y, tx, ty, speed, damage, splash)
  local ang = math.atan2(ty - y, tx - x)
  local vx, vy = math.cos(ang)*speed, math.sin(ang)*speed
  table.insert(projectiles, {kind="mortar", x=x, y=y, vx=vx, vy=vy, tx=tx, ty=ty, speed=speed, damage=damage, splash=splash, r=5, alive=true, a=ang})
end

local function spawnBeam(sx, sy, ex, ey, life)
  table.insert(beams, {sx=sx, sy=sy, ex=ex, ey=ey, t=life or 0.06})
end

local function spawnRing(x,y,r,life)
  table.insert(particles, {x=x,y=y,r=r,t=life or 0.25})
end

-- UI helpers
local function newButton(label, x,y,w,h, onclick)
  local b = {label=label, x=x,y=y,w=w,h=h, onclick=onclick}
  table.insert(ui.buttons, b)
  return b
end

local function mouseIn(b) return mouse.x>=b.x and mouse.x<=b.x+b.w and mouse.y>=b.y and mouse.y<=b.y+b.h end
local function addMoney(n) game.money = game.money + n end
local function spend(n) if game.money>=n then game.money=game.money-n return true else return false end end

-- Drawing
local function drawGrid()
  love.graphics.setColor(1,1,1,0.08)
  for c=1,GRID_COLS do love.graphics.line((c-1)*CELL, 0, (c-1)*CELL, H) end
  for r=1,GRID_ROWS do love.graphics.line(0, (r-1)*CELL, FIELD_W, (r-1)*CELL) end
end

local function drawPath()
  love.graphics.setColor(1,1,1,0.15)
  for _,p in ipairs(path) do
    local x = (p[1]-1)*CELL; local y = (p[2]-1)*CELL
    love.graphics.rectangle("fill", x+2, y+2, CELL-4, CELL-4)
  end
  love.graphics.setColor(1,1,1,0.5); love.graphics.setLineWidth(2)
  for i=1,#pathPoints-1 do local a,b=pathPoints[i],pathPoints[i+1]; love.graphics.line(a.x,a.y,b.x,b.y) end
end

local function drawEnemy(e)
  love.graphics.setColor(1,1,1,1); love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", e.x-12, e.y-12, 24, 24)
  love.graphics.circle("line", e.x-10, e.y+14, 6); love.graphics.circle("line", e.x+10, e.y+14, 6)
  -- HP
  local w = 26; local hpw = clamp((e.hp/e.maxhp)*w,0,w)
  love.graphics.setLineWidth(1)
  love.graphics.setColor(1,1,1,0.2); love.graphics.rectangle("fill", e.x - w/2, e.y-26, w, 4)
  love.graphics.setColor(1,1,1,1); love.graphics.rectangle("fill", e.x - w/2, e.y-26, hpw, 4)
  -- slow indicator
  if e.slow > 0 then
    love.graphics.setColor(1,1,1,0.6)
    love.graphics.line(e.x-12,e.y+20,e.x+12,e.y+20)
  end
end

local function drawCat(x,y,ang,scale)
  scale = scale or 1
  love.graphics.push(); love.graphics.translate(x,y); love.graphics.rotate(ang or 0); love.graphics.scale(scale, scale)
  love.graphics.setColor(1,1,1,1); love.graphics.setLineWidth(2)
  love.graphics.ellipse("line", 0, 2, 10, 7); -- body
  love.graphics.circle("line", 12, -2, 6)    -- head
  love.graphics.polygon("line", 16,-8, 18,-4, 14,-4)
  love.graphics.polygon("line", 8,-8, 10,-4, 6,-4)
  love.graphics.line(-10, 2, -16, -2); love.graphics.line(-16,-2, -18, -6) -- tail
  love.graphics.setLineWidth(1)
  love.graphics.line(16,-2, 22,-4); love.graphics.line(16,0, 22,0); love.graphics.line(16,2, 22,4) -- whiskers
  love.graphics.pop()
end

local function drawBullet(p)
  love.graphics.setColor(1,1,1,1)
  if p.kind=="mortar" then
    love.graphics.circle("line", p.x, p.y, p.r)
  elseif p.kind=="cat" then
    drawCat(p.x, p.y, p.a, 0.9)
  else
    love.graphics.circle("fill", p.x, p.y, p.r)
  end
end

local function drawTower(t)
  love.graphics.setColor(1,1,1,1); love.graphics.setLineWidth(2)
  -- range fill
  local tt = towerTypes[t.type]
  local range = tt.range
  for i=1,t.level do local u=tt.upgrade[i]; range = u.range or range end
  love.graphics.setColor(1,1,1,0.05); love.graphics.circle("fill", t.x, t.y, range)
  love.graphics.setColor(1,1,1,1)
  if t.type=="cog" then
    love.graphics.circle("line", t.x, t.y, 12)
    for i=1,6 do local ang=(i/6)*math.pi*2; love.graphics.line(t.x+math.cos(ang)*12,t.y+math.sin(ang)*12,t.x+math.cos(ang)*16,t.y+math.sin(ang)*16) end
  elseif t.type=="tesla" then
    love.graphics.rectangle("line", t.x-8, t.y-16, 16, 32); love.graphics.circle("line", t.x, t.y-20, 6)
  elseif t.type=="mortar" then
    love.graphics.polygon("line", t.x-14,t.y+10, t.x+14,t.y+10, t.x+10,t.y-10, t.x-10,t.y-10); love.graphics.line(t.x-8,t.y-10, t.x+8,t.y-10)
  elseif t.type=="cat" then
    love.graphics.rectangle("line", t.x-12, t.y-8, 24, 16); love.graphics.polygon("line", t.x-12, t.y-8, t.x-6, t.y-16, t.x, t.y-8)
    drawCat(t.x+0, t.y-18, 0, 0.6)
  end
  for i=1,t.level do love.graphics.rectangle("fill", t.x-12+(i-1)*6, t.y+18, 4, 6) end
end

local function drawUI()
  love.graphics.setColor(1,1,1,1); love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", FIELD_W, 0, UI_W, H)
  love.graphics.setFont(fonts.h2); love.graphics.print("STEAM DEFENSE", FIELD_W+16, 16)
  love.graphics.setFont(fonts.base)
  love.graphics.print("Money: $"..game.money, FIELD_W+16, 56)
  love.graphics.print("Lives: "..game.lives, FIELD_W+16, 80)
  love.graphics.print("Wave: "..game.wave..(game.waveActive and " (active)" or ""), FIELD_W+16, 104)
  local spd = (game.timeScale==1 and "1x" or (game.timeScale==2 and "2x" or "3x"))
  love.graphics.print("Speed: "..spd, FIELD_W+16, 128)
  love.graphics.print("Endless: "..(game.endless and "ON" or "OFF").." [N]", FIELD_W+16, 148)
  if game.messageTimer>0 then love.graphics.setColor(1,1,1,0.9); love.graphics.printf(game.message, FIELD_W+16, 170, UI_W-32) end

  for _,b in ipairs(ui.buttons) do
    local hovered = mouseIn(b)
    love.graphics.setColor(1,1,1, hovered and 0.25 or 0.12); love.graphics.rectangle("fill", b.x, b.y, b.w, b.h)
    love.graphics.setColor(1,1,1,1); love.graphics.rectangle("line", b.x, b.y, b.w, b.h); love.graphics.printf(b.label, b.x+6, b.y+8, b.w-12, "center")
  end
  -- Selected tower panel (bottom, non-overlapping)
  if game.selectedTower then
    local t = game.selectedTower
    local tt = towerTypes[t.type]
    local y = H - 72
    love.graphics.setColor(1,1,1,1)
    love.graphics.setFont(fonts.base)
    love.graphics.print(tt.name, FIELD_W+16, y)
    love.graphics.print("Level: "..t.level, FIELD_W+16, y+18)
    love.graphics.print("Invested: $"..t.totalCost, FIELD_W+16, y+36)
  end
end

-- Menu preview
local function drawPreviewFromCode(code, cx, cy, scale)
  local ok, decoded = decodeToPaint(code)
  if not ok then love.graphics.print("Invalid map-code", cx-60, cy) return end
  local size = 12 * (scale or 1)
  love.graphics.setColor(1,1,1,0.1); love.graphics.rectangle("fill", cx-GRID_COLS*size/2, cy-GRID_ROWS*size/2, GRID_COLS*size, GRID_ROWS*size)
  for r=1,GRID_ROWS do
    for c=1,GRID_COLS do
      if decoded.paint[c][r] then
        love.graphics.setColor(1,1,1,0.5)
        love.graphics.rectangle("fill", cx + (c-1)*size - GRID_COLS*size/2 + 2, cy + (r-1)*size - GRID_ROWS*size/2 + 2, size-4, size-4)
      end
    end
  end
  love.graphics.setColor(1,1,1,1)
  -- Start/Goal markers
  local sx = cx + (decoded.start.c-0.5)*size - GRID_COLS*size/2
  local sy = cy + (decoded.start.r-0.5)*size - GRID_ROWS*size/2
  local gx = cx + (decoded.goal.c-0.5)*size - GRID_COLS*size/2
  local gy = cy + (decoded.goal.r-0.5)*size - GRID_ROWS*size/2
  love.graphics.circle("line", sx, sy, 6); love.graphics.rectangle("line", gx-6, gy-6, 12, 12)
end

-- Placement & clicks
local function placeSelectedAt(cx, cy)
  if not game.selectedType then return end
  if cx<1 or cy<1 or cx>GRID_COLS or cy>GRID_ROWS then return end
  if blocked[cx][cy] or grid[cx][cy] then return end
  local tt = towerTypes[game.selectedType]
  if not spend(tt.cost) then game.message="Not enough money!" game.messageTimer=1.2 return end
  local t = makeTower(game.selectedType, cx, cy)
  table.insert(towers, t); grid[cx][cy] = true; game.selectedTower = t; refreshCursor()
end

-- Targeting helpers
local function nearestEnemy(x, y, r)
  local dmin, chosen = 1e9, nil
  for _,e in ipairs(enemies) do
    if not e.dead then
      local d = dist(x,y,e.x,e.y)
      if d <= r and d < dmin then dmin = d; chosen = e end
    end
  end
  return chosen
end

local function nearestNEnemies(x, y, r, n)
  local list = {}
  for _,e in ipairs(enemies) do
    if not e.dead and dist(x,y,e.x,e.y) <= r then table.insert(list, e) end
  end
  table.sort(list, function(a,b) return dist(x,y,a.x,a.y) < dist(x,y,b.x,b.y) end)
  local out = {}; for i=1,math.min(n,#list) do out[i]=list[i] end
  return out
end

-- Enemy factory
local function makeEnemy(waveNum)
  local scaling = 1 + (waveNum-1)*0.06
  local baseHP = 30 * scaling + waveNum * 10
  local baseSpd = 55 * (1 + (waveNum*0.01))
  local types = {
    {name="Tin Scuttler", hp=baseHP, speed=baseSpd, reward=8},
    {name="Bronze Beetle", hp=baseHP*1.35, speed=baseSpd*0.9, reward=10},
    {name="Iron Grinder", hp=baseHP*0.75, speed=baseSpd*1.22, reward=9},
  }
  local t = types[ love.math.random(1, #types) ]
  return {
    name=t.name, hp=t.hp, maxhp=t.hp, speed=t.speed, baseSpeed=t.speed, reward=t.reward,
    x=pathPoints[1].x, y=pathPoints[1].y, i=1, dead=false, reached=false, r=14,
    slow=0, slowTimer=0,
  }
end

-- Waves
local wave = { spawnTimer=0, remaining=0, cooldown=1.0 }

local function startNextWave()
  if game.waveActive then return end
  if #pathPoints < 2 then game.message="Invalid path. Use the editor."; game.messageTimer=2 return end
  game.wave = game.wave + 1; game.waveActive = true
  wave.remaining = 8 + math.floor(game.wave * 1.8)
  wave.spawnTimer = 0.2; wave.cooldown = math.max(0.15, 0.9 - game.wave * 0.02)
  game.message = "Wave "..game.wave.." begins!"; game.messageTimer = 2.0
end

local function endWaveIfDone(dt)
  if game.waveActive then
    if wave.remaining <= 0 and #enemies == 0 then
      game.waveActive = false
      local bonus = 25 + game.wave*2; game.money = game.money + bonus
      game.message = "Wave "..game.wave.." cleared! +$"..bonus; game.messageTimer = 2.0
      if game.endless then game.waveAutoTimer = 2.5 end
    end
  else
    if game.endless then
      game.waveAutoTimer = math.max(0, game.waveAutoTimer - dt)
      if game.waveAutoTimer == 0 and game.lives > 0 then startNextWave() end
    end
  end
end

-- Love callbacks
function love.load()
  love.window.setMode(W,H); love.window.setTitle("Steam Defense - Black & White"); love.graphics.setBackgroundColor(0,0,0)
  love.math.setRandomSeed(os.time())

  -- System cursors
  cursors.arrow = love.mouse.getSystemCursor('arrow')
  cursors.cross  = love.mouse.getSystemCursor('crosshair')
  love.mouse.setCursor(cursors.arrow)
  currentCursor = 'arrow'
  game.fullscreen = love.window.getFullscreen() or false
  fonts.base = love.graphics.newFont(14); fonts.h2 = love.graphics.newFont(18); fonts.big = love.graphics.newFont(28)
  love.graphics.setFont(fonts.base)

  -- Build default map set
  defaultMaps()
  -- Apply the first map into play memory (so preview shows something if entering game right away)
  local first = menu.maps[1]; applyMapFromCode(first.code)

  -- Sidebar UI (active during play)
  local x0 = FIELD_W + 16
  newButton("Start Wave (Space)", x0, 200, UI_W-32, 36, function() if game.state=="play" then startNextWave() end end)
  newButton("Speed x1/x2/x3 (Tab)", x0, 244, UI_W-32, 32, function() if game.state=="play" then game.timeScale = (game.timeScale==1 and 2) or (game.timeScale==2 and 3) or 1 end end)
  newButton("Cog Turret  $50 [1]", x0, 300, UI_W-32, 32, function() if game.state=="play" then game.selectedType="cog"; refreshCursor() end end)
  newButton("Tesla Coil  $90 [2]", x0, 336, UI_W-32, 32, function() if game.state=="play" then game.selectedType="tesla"; refreshCursor() end end)
  newButton("Steam Mortar $90 [3]", x0, 372, UI_W-32, 32, function() if game.state=="play" then game.selectedType="mortar"; refreshCursor() end end)
  newButton("Cat-a-pult  $75 [4]", x0, 408, UI_W-32, 32, function() if game.state=="play" then game.selectedType="cat"; refreshCursor() end end)
  newButton("Upgrade (U)", x0, 456, UI_W-32, 30, function()
    if game.state~="play" or not game.selectedTower then return end
    local t = game.selectedTower; local tt = towerTypes[t.type]
    if t.level >= #tt.upgrade then game.message="Max level reached"; game.messageTimer=1.0; return end
    local nxt = tt.upgrade[t.level+1]
    if spend(nxt.cost) then t.level=t.level+1; t.totalCost=t.totalCost+nxt.cost; game.message="Upgraded!"; game.messageTimer=1.0
    else game.message="Not enough money"; game.messageTimer=1.0 end
  end)
  newButton("Sell (S)", x0, 490, UI_W-32, 30, function()
    if game.state~="play" or not game.selectedTower then return end
    local t = game.selectedTower; addMoney(math.floor(t.totalCost*0.6)); grid[t.cx][t.cy] = false
    for i=#towers,1,-1 do if towers[i]==t then table.remove(towers,i) break end end
    game.selectedTower=nil; game.message="Sold for 60%"; game.messageTimer=1.2
  end)
  newButton("Toggle Editor (M)", x0, 526, UI_W-32, 30, function() if game.state=="play" then game.state="editor" else game.state="play" end end)
  newButton("Endless ON/OFF (N)", x0, 560, UI_W-32, 30, function() if game.state~="menu" then game.endless = not game.endless end end)
end

-- MENU drawing
local function drawMenu()
  love.graphics.setColor(1,1,1,1)
  love.graphics.setFont(fonts.big)
  love.graphics.printf("STEAM DEFENSE", 0, 80, W, "center")
  love.graphics.setFont(fonts.base)
  local m = menu.maps[menu.idx]
  love.graphics.printf("Select Map:  ["..menu.idx.."/"..#menu.maps.."]  "..m.name.."   |   Display: "..(game.fullscreen and "Fullscreen" or "Windowed"), 0, 130, W, "center")
  drawPreviewFromCode(m.code, W/2, H/2 - 10, 1.2)
  love.graphics.printf("Enter: Play   ←/→: Change Map   E: Edit   C: Copy Code   V: Paste Code", 0, H-140, W, "center")
  love.graphics.printf("N: Toggle Endless ("..(game.endless and "ON" or "OFF")..")   F11 / Alt+Enter: Fullscreen   Esc: Quit", 0, H-115, W, "center")
end

-- EDITOR overlay
local function drawEditor()
  if game.state~="editor" then return end
  love.graphics.setColor(1,1,1,0.1); love.graphics.rectangle("fill", 0, 0, FIELD_W, H)
  for c=1,GRID_COLS do for r=1,GRID_ROWS do if pathPaint[c][r] then love.graphics.setColor(1,1,1,0.24); love.graphics.rectangle("fill", (c-1)*CELL+2, (r-1)*CELL+2, CELL-4, CELL-4) end end end
  local sx,sy = cellCenter(startCell.c,startCell.r); local gx,gy = cellCenter(goalCell.c,goalCell.r)
  love.graphics.setLineWidth(2); love.graphics.setColor(1,1,1,1)
  love.graphics.circle("line", sx, sy, 12); love.graphics.print("S", sx-4, sy-8)
  love.graphics.rectangle("line", gx-10, gy-10, 20, 20); love.graphics.print("G", gx-4, gy-8)
  love.graphics.setFont(fonts.base); love.graphics.setColor(1,1,1,1)
  love.graphics.printf("EDITOR: LMB paint/erase path • F set Start • G set Goal • Enter: Build • K Save • L Load • X CopyCode • V PasteCode • M Exit",
    0, H-22, FIELD_W, "center")
end

function love.update(dt)
  mouse.x, mouse.y = love.mouse.getPosition()
  if game.messageTimer>0 then game.messageTimer = game.messageTimer - dt; if game.messageTimer<0 then game.message="" end end

  if game.state=="menu" then return end
  if game.state=="editor" then return end
  if game.paused then return end

  dt = dt * game.timeScale

  -- spawn enemies
  if game.waveActive then
    wave.spawnTimer = wave.spawnTimer - dt
    if wave.spawnTimer <= 0 and wave.remaining > 0 then
      table.insert(enemies, makeEnemy(game.wave)); wave.remaining = wave.remaining - 1; wave.spawnTimer = wave.cooldown
    end
  end

  -- enemies move (with slow)
  for i=#enemies,1,-1 do
    local e = enemies[i]
    if not e.dead and not e.reached then
      if e.slowTimer>0 then e.slowTimer = e.slowTimer - dt; if e.slowTimer<=0 then e.slow=0 end end
      local effSpeed = e.speed * (1 - clamp(e.slow,0,0.9))
      local tgt = pathPoints[e.i+1]
      if not tgt then
        e.reached = true; game.lives = game.lives - 1
        if game.lives <= 0 then game.lives=0; game.paused=true; game.message="Game Over. Final Wave: "..game.wave; game.messageTimer=5.0 end
      else
        local dx,dy = tgt.x - e.x, tgt.y - e.y
        local d = (dx*dx+dy*dy)^0.5
        if d < 2 then e.i = e.i + 1 else e.x = e.x + (dx/d)*effSpeed * dt; e.y = e.y + (dy/d)*effSpeed * dt end
      end
    end
  end

  -- towers update
  for _,t in ipairs(towers) do
    local tt = towerTypes[t.type]
    t.cooldown = math.max(0, t.cooldown - dt)

    local baseRange = tt.range
    local baseDamage = tt.damage or tt.dps or 0
    local baseFireRate = tt.fireRate or 0
    local baseSpeed = tt.bulletSpeed or tt.projSpeed or 0
    local baseSplash = tt.splash or 0
    local chains = tt.chains or 1
    local slowPct = tt.slowPct or 0
    local slowDur = tt.slowDur or 0

    for i=1,t.level do
      local u = tt.upgrade[i]
      baseRange = u.range or baseRange
      baseDamage = (u.damage or u.dps or baseDamage)
      baseFireRate = u.fireRate or baseFireRate
      baseSpeed = u.bulletSpeed or u.projSpeed or baseSpeed
      baseSplash = u.splash or baseSplash
      chains = u.chains or chains
      slowPct = u.slowPct or slowPct
      slowDur = u.slowDur or slowDur
    end

    if t.type=="cog" then
      if t.cooldown<=0 then
        local target = nearestEnemy(t.x, t.y, baseRange)
        if target then spawnBullet(t.x, t.y, target, baseSpeed, baseDamage, "bullet"); t.cooldown = 1.0 / baseFireRate end
      end
    elseif t.type=="tesla" then
      -- Chain to up to 'chains' enemies each frame
      local targets = nearestNEnemies(t.x, t.y, baseRange, chains)
      for _,e in ipairs(targets) do
        e.hp = e.hp - baseDamage * dt
        spawnBeam(t.x, t.y, e.x, e.y, 0.06)
      end
    elseif t.type=="mortar" then
      if t.cooldown<=0 then
        local target = nearestEnemy(t.x, t.y, baseRange)
        if target then spawnMortarShell(t.x, t.y, target.x, target.y, baseSpeed, baseDamage, baseSplash); t.cooldown = 1.0 / baseFireRate end
      end
    elseif t.type=="cat" then
      if t.cooldown<=0 then
        local target = nearestEnemy(t.x, t.y, baseRange)
        if target then spawnBullet(t.x, t.y, target, baseSpeed, baseDamage, "cat", {slowPct=slowPct, slowDur=slowDur}); t.cooldown = 1.0 / baseFireRate end
      end
    end
  end

  -- projectiles
  for i=#projectiles,1,-1 do
    local p = projectiles[i]
    if not p.alive then table.remove(projectiles,i) goto continue end
    if p.kind=="mortar" then
      p.x = p.x + p.vx * dt; p.y = p.y + p.vy * dt
      if dist(p.x,p.y,p.tx,p.ty) < 8 then
        spawnRing(p.x,p.y,p.splash,0.18)
        for _,e in ipairs(enemies) do
          if not e.dead then
            local d = dist(p.x,p.y,e.x,e.y)
            if d <= p.splash then local falloff = 1 - (d / p.splash)*0.35; e.hp = e.hp - p.damage * falloff end
          end
        end
        p.alive=false
      end
    else
      if p.target and not p.target.dead and not p.target.reached then
        local dx,dy = p.target.x - p.x, p.target.y - p.y
        local d = (dx*dx+dy*dy)^0.5 + 1e-6
        p.a = math.atan2(dy, dx)
        p.x = p.x + (dx/d) * p.speed * dt; p.y = p.y + (dy/d) * p.speed * dt
        if d < 10 then
          p.target.hp = p.target.hp - p.damage
          if p.kind=="cat" then
            p.target.slow = math.max(p.target.slow or 0, p.slowPct or 0.35)
            p.target.slowTimer = math.max(p.target.slowTimer or 0, p.slowDur or 1.2)
          end
          spawnRing(p.target.x, p.target.y, 12, 0.12); p.alive=false
        end
      else
        p.alive=false
      end
    end
    ::continue::
  end

  -- beams
  for i=#beams,1,-1 do local b=beams[i]; b.t=b.t-dt; if b.t<=0 then table.remove(beams,i) end end
  -- particles
  for i=#particles,1,-1 do local p=particles[i]; p.t=p.t-dt; p.r=p.r+100*dt; if p.t<=0 then table.remove(particles,i) end end

  -- deaths & rewards
  for i=#enemies,1,-1 do
    local e = enemies[i]
    if e.hp <= 0 and not e.dead then
      e.dead = true; spawnRing(e.x,e.y,28,0.25); addMoney(e.reward); game.score = game.score + 10; table.remove(enemies,i)
    elseif e.reached then table.remove(enemies,i) end
  end

  endWaveIfDone(dt)
end

function love.draw()
  if game.state=="menu" then
    drawMenu(); return
  end

  -- play/editor field
  drawGrid(); drawPath()

  love.graphics.setColor(1,1,1,1); love.graphics.setLineWidth(2)
  for _,b in ipairs(beams) do love.graphics.line(b.sx, b.sy, b.ex, b.ey) end

  for _,t in ipairs(towers) do drawTower(t) end
  for _,e in ipairs(enemies) do drawEnemy(e) end
  for _,p in ipairs(projectiles) do drawBullet(p) end
  for _,p in ipairs(particles) do love.graphics.setColor(1,1,1,0.25); love.graphics.circle("line", p.x, p.y, p.r) end

  drawUI(); if game.state=="editor" then drawEditor() end

  love.graphics.setFont(fonts.base); love.graphics.setColor(1,1,1,1)
  local msg = "(LMB) place • (RMB) cancel • [1/2/3/4] towers • Space: Start • Tab: Speed • U: Upgrade • S: Sell • M: Editor • N: Endless • P: Pause"
  love.graphics.printf(msg, 0, 8, FIELD_W-8, "center")

  if game.paused and game.state=="play" then love.graphics.setFont(fonts.big); love.graphics.setColor(1,1,1,0.95); love.graphics.printf("PAUSED", 0, H/2-20, FIELD_W, "center") end
end

function love.mousepressed(x,y,btn)
  if game.state=="menu" then return end

  if btn==2 then
    if game.state=="editor" then if inField(x,y) then local cx,cy=worldToCell(x,y); if not grid[cx][cy] then pathPaint[cx][cy]=false end end
    else game.selectedType=nil; refreshCursor() end
    return
  end
  if btn ~= 1 then return end

  for _,b in ipairs(ui.buttons) do if mouseIn(b) then b.onclick(); return end end

  if game.state=="editor" then
    if inField(x,y) then local cx,cy=worldToCell(x,y); if not grid[cx][cy] then pathPaint[cx][cy]=not pathPaint[cx][cy] end end
    return
  end

  if inField(x,y) then
    local cx,cy = worldToCell(x,y)
    for _,t in ipairs(towers) do if t.cx==cx and t.cy==cy then game.selectedTower=t; refreshCursor(); return end end
    placeSelectedAt(cx,cy)
  end
end


function love.keypressed(key)
  -- Alt+Enter toggles fullscreen universally
  if (key=="return" or key=="kpenter") and (love.keyboard.isDown('lalt') or love.keyboard.isDown('ralt')) then
    setFullscreen(not game.fullscreen)
    return
  end

  -- F11: toggle fullscreen
  if key=="f11" then
    setFullscreen(not game.fullscreen)
    return
  end

  -- ESC: quit from menu, otherwise back to menu
  if key=="escape" then
    if game.state=="menu" then
      love.event.quit()
    else
      game.state="menu"
      resetGameStats()
    end
    refreshCursor()
    return
  end

  -- MENU controls
  if game.state=="menu" then
    if key=="left" then
      menu.idx = (menu.idx - 2) % #menu.maps + 1
    elseif key=="right" then
      menu.idx = (menu.idx) % #menu.maps + 1
    elseif key=="return" or key=="kpenter" then
      -- Note: if Alt was held, we already returned above.
      resetGameStats()
      applyMapFromCode(menu.maps[menu.idx].code)
      game.state="play"
    elseif key=="n" then
      game.endless = not game.endless
    elseif key=="e" then
      applyMapFromCode(menu.maps[menu.idx].code)
      game.state="editor"
    elseif key=="c" then
      love.system.setClipboardText(menu.maps[menu.idx].code)
      game.message="Map code copied"; game.messageTimer=1.4
    elseif key=="v" then
      local code = love.system.getClipboardText() or ""
      local ok,_ = decodeToPaint(code)
      if ok then
        menu.maps[menu.idx].code = code
        game.message="Slot updated from clipboard"; game.messageTimer=1.4
      else
        game.message="Invalid code"; game.messageTimer=1.4
      end
    end
    return
  end

  -- PLAY/EDITOR global
  if key=="tab" then
    game.timeScale = (game.timeScale==1 and 2) or (game.timeScale==2 and 3) or 1
  elseif key=="n" then
    if game.state~="menu" then game.endless = not game.endless end
  elseif key=="m" then
    if game.state=="play" then game.state="editor"
    elseif game.state=="editor" then game.state="play" end
    refreshCursor()
  end

  -- PLAY controls
  if game.state=="play" then
    if key=="space" then startNextWave() end
    if key=="p" then game.paused = not game.paused; refreshCursor() end
    if key=="1" then game.selectedType="cog"; refreshCursor() end
    if key=="2" then game.selectedType="tesla"; refreshCursor() end
    if key=="3" then game.selectedType="mortar"; refreshCursor() end
    if key=="4" then game.selectedType="cat"; refreshCursor() end
    if key=="u" and game.selectedTower then
      local t = game.selectedTower; local tt = towerTypes[t.type]
      if t.level < #tt.upgrade then
        local nxt = tt.upgrade[t.level+1]
        if spend(nxt.cost) then
          t.level=t.level+1; t.totalCost=t.totalCost+nxt.cost; game.message="Upgraded!"; game.messageTimer=1.0
        else
          game.message="Not enough money"; game.messageTimer=1.0
        end
      else
        game.message="Max level reached"; game.messageTimer=1.0
      end
    end
    if key=="s" and game.selectedTower then
      local t = game.selectedTower
      addMoney(math.floor(t.totalCost*0.6))
      grid[t.cx][t.cy] = false
      for i=#towers,1,-1 do if towers[i]==t then table.remove(towers,i) break end end
      game.selectedTower = nil; game.message="Sold for 60%"; game.messageTimer=1.2
    end
    return
  end

  -- EDITOR controls
  if game.state=="editor" then
    if key=="f" and inField(mouse.x, mouse.y) then
      startCell.c, startCell.r = worldToCell(mouse.x, mouse.y)
    elseif key=="g" and inField(mouse.x, mouse.y) then
      goalCell.c, goalCell.r = worldToCell(mouse.x, mouse.y)
    elseif key=="return" or key=="kpenter" then
      local ok, err = buildPathFromPaint()
      if not ok then game.message=err or "Path build failed"; game.messageTimer=2 else game.message="Path built"; game.messageTimer=1.2 end
    elseif key=="k" then
      saveMapCodeToFile()
    elseif key=="l" then
      loadMapCodeFromFile()
    elseif key=="x" then
      local code=encodeMapToCodeCurrent(); love.system.setClipboardText(code); game.message="Map code copied"; game.messageTimer=1.4
    elseif key=="v" then
      local code=love.system.getClipboardText() or ""; applyMapFromCode(code)
    end
    return
  end
end


function love.resize(w,h)
  W, H = w, h
  UI_W = W - FIELD_W
end
