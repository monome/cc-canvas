-- no init?
-- grid is 0-indexed

-- cc numbers:
ccnum = {
	0,
	1,
	2,
	3,
	4,
	5,
	6,
	7,
	8,
	9,
	10,
	11,
	12,
	13,
	14,
}

-- ms slews:
slews = {
	0,
	250,
	650,
	1130,
	1590,
	2090,
	2650,
	3240,
	3870,
	4540,
	5250,
	5980,
	6750,
	7550,
	8380,
	10120,
}

print('cc canvas')
dirty = true

ccval = {}
slewidx = {}
pressed_key = {}
for i = 1,#ccnum do
  ccval[i] = 0
  slewidx[i] = 3
  pressed_key[i] = -1
end

-- a table to track our CC values:
cc_cols = {}
for i = 0, 14 do
  cc_cols[i] = {}
  local _c = cc_cols[i]
  _c.value = 0
  _c.absolute = 0
  _c.last_pressed = 0
end

-- index 1: redraw grid
function metro(index, count)
  if index == 1 and dirty then
		redraw_grid()
    dirty = false
  end
end

function grid(x,y,z)
  if x <= 14 and z == 1 then
		pressed_key[x + 1] = y
    y = 7-y
    local pressed_val = ((y+1) * 16)-1
		if ccval[x + 1] == pressed_val then
			ccval[x + 1] = 0
      pressed_key[x+1] = -1
		else
			ccval[x + 1] = pressed_val
		end
    midi_tx(0, 0xb0, ccnum[x+1], ccval[x+1])
    dirty = true
  end
end

function redraw_grid()
  grid_led_all(0)
  for x = 0,14 do
    -- if y >= 11 grid freezes...
    for y = 0,15 do
      grid_led(x,y,3)
    end
    local bright = pressed_key[x+1] >= 0 and 15 or 3
    grid_led(x, pressed_key[x+1], bright)
  end
  grid_refresh()
end

function fn_cycle(fn, origin, dest_ms, fps)
	fn(origin)
	for _, v in ipairs(dest_ms) do
		local count = math.floor(v[2] * 60) -- number of iterations
		local stepsize = (v[1] - origin) / count -- how much to increment by each iteration
		while count > 0 do
			origin = origin + stepsize -- move toward destination
			count = count - 1 -- count iteration
			fn(origin)
		end
	end
end

function fn_done(x,val)
	print('done!')
  run_fnl = false
end

redraw_grid()

metro_set(1, 10)
metro_set(2, (1000/60)) -- 60fps