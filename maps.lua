local maps = {}

local function zigzag()
  local t={}
  for c=1,6 do t[#t+1]={c,6} end
  t[#t+1]={6,5}; t[#t+1]={6,4}
  for c=7,11 do t[#t+1]={c,4} end
  t[#t+1]={11,5}; t[#t+1]={11,6}; t[#t+1]={11,7}
  for c=12,16 do t[#t+1]={c,7} end
  return t
end

local function grandU()
  local t={}
  for r=2,11 do t[#t+1]={2,r} end
  for c=2,14 do t[#t+1]={c,11} end
  for r=3,10 do t[#t+1]={14,r} end
  return t
end

local function serpentine()
  local t={}
  for r=3,9 do
    if r%2==1 then
      for c=2,15 do t[#t+1]={c,r} end
    else
      for c=15,2,-1 do t[#t+1]={c,r} end
    end
  end
  return t
end

local function shortDash()
  local t={}
  for c=1,16 do t[#t+1]={c,6} end
  return t
end

maps = {
  {name="Zig-Zag Works", paint=zigzag(), start={c=1,r=6}, goal={c=16,r=7}},
  {name="Grand U", paint=grandU(), start={c=2,r=2}, goal={c=14,r=10}},
  {name="Serpentine Yard", paint=serpentine(), start={c=2,r=3}, goal={c=15,r=9}},
  {name="Short Dash", paint=shortDash(), start={c=1,r=6}, goal={c=16,r=6}},
}

return maps

