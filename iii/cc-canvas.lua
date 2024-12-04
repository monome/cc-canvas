-- cc numbers:
cc_num = {
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

-- cc channels:
cc_ch = {
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
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

local function util_round(number, quant)
	if quant == 0 then
		return number
	else
		return math.floor(number / (quant or 1) + 0.5) * (quant or 1)
	end
end

local function util_clamp(n, min, max)
  return math.min(max,(math.max(n,min)))
end

local function util_linlin(slo, shi, dlo, dhi, f)
  if f <= slo then
    return dlo
  elseif f >= shi then
    return dhi
  else
    return (f-slo) / (shi-slo) * (dhi-dlo) + dlo
  end
end

print("cc canvas")
dirty = true
redraw_metro = 1
grid_fps = 50

-- a table to track our CC values:
cc_cols = {}
for i = 0, 14 do
	cc_cols[i] = {}
	local _c = cc_cols[i]
	_c.value = 0
	_c.absolute = 0
	_c.pressed_key = -1
	_c.last_pressed = 0
	_c.slew_idx = 6
	_c.partial_restore = false
	_c.fnl_metro = 2+i
	_c.origin = {}
	_c.dest_ms = {}
	_c.dest_target = {}
	_c.stepsize = {}
	_c.count = {}
	_c.pre_val = {}
end

-- index 1: redraw grid
-- indexes 2-15: fnl steppers
function metro(index, count)
	if index == redraw_metro and dirty then
		redraw_grid()
		dirty = false
	elseif index ~= redraw_metro then
		process_fnl_metro(index-2)
	end
end

function process_fnl_metro(x)
	local _c = cc_cols[x]
	if _c.count > 0 then
		_c.origin = _c.origin + _c.stepsize -- move toward destination
		_c.count = _c.count - 1 -- count iteration
		fnl_step(x, _c.origin)
	end
end

function grid(x, y, z)
	if x <= 14 and z == 1 then
		local prev_pressed = cc_cols[x].pressed_key
		cc_cols[x].pressed_key = y
		if prev_pressed == cc_cols[x].pressed_key then
			cc_cols[x].pressed_key = -1
		end
		y = 7 - y
		local pressed_val = ((y + 1) * 16) - 1
		fnl_trigger(x, pressed_val, {false})
	end
	dirty = true
end

function redraw_grid()
	grid_led_all(0)
	for x = 0, 14 do
		local _c = cc_cols[x]
		for y = 0, 15 do
			grid_led(x, y, 3)
		end

		local bright = cc_cols[x].pressed_key >= 0 and 7 or 3
		grid_led(x, cc_cols[x].pressed_key, bright)

		-- columns, whole numbers::
		-- local whole, part = math.modf(_c.value / 8) -- this is for 256...
		local whole, part = math.modf(_c.value / 16) -- this is for 256...
		for y = 1, whole do
			grid_led(x, 8 - y, 15)
		end
		-- columns, partial values:
		if whole + part == 0 then
			grid_led(x, 0, 3)
		else
			-- g:led(x, 16 - whole, math.floor(util.linlin(0, 15 * 0.875, 4, 15, 15 * part)))
			grid_led(x, 7 - whole, math.floor(util_linlin(0, 15 * 0.875, 4, 15, 15 * part)))
		end

	end
	grid_refresh()
end

function send_midi_out(x,value)
	cc_cols[x].value = value
	midi_tx(0, 0xb0+(cc_ch[x+1] - 1), cc_num[x+1], value)
	dirty = true
end

function fnl_step(x, r_val)
	local _c = cc_cols[x]
	_c.current_value = r_val
	local scaled = math.floor(util_linlin(0, 1, _c.pre_val, _c.dest_target, r_val))
	send_midi_out(x,scaled)
	if _c.current_value ~= nil and util_round(_c.current_value, 0.001) == 1 then
		fnl_done(x, _c.dest_target)
		metro_stop(_c.fnl_metro)
	end
end

function fnl_trigger(x, val, from_snapshot)
	local _c = cc_cols[x]
	if _c.partial_restore then
		metro_stop(_c.fnl_metro)
	end
	local target
	if from_snapshot[1] then
		target = val
	else
		target = _c.value == util_clamp(0, 127, val) and 0 or val
	end
	_c.absolute = target
	if target ~= 0 then
		local whole, part = math.modf(val / 8)
		_c.last_pressed = whole == 0 and 0 or whole + 1
	else
		_c.last_pressed = 0
	end
	if _c.slew_idx == 1 or from_snapshot[2] then
		fnl_done(x, target)
	else
		_c.partial_restore = true
		_c.pre_val = _c.value
		_c.origin = 0
		_c.dest_ms = slews[_c.slew_idx] / 1000
		_c.dest_target = target
		fnl_step(x, _c.origin)
		_c.count = math.floor(_c.dest_ms * grid_fps) -- number of iterations
		_c.stepsize = (1 - _c.origin) / _c.count -- how much to increment by each iteration
		metro_set(_c.fnl_metro, 1000/50) -- 50fps in ms (needed as of 241203)
	end
end

function fnl_done(x, val)
	local _c = cc_cols[x]
	if _c.partial_restore then
		metro_stop(_c.fnl_metro)
		_c.partial_restore = false
	end
	if _c.value == 0 then
		_c.pressed_key = -1
	end
	send_midi_out(x,val)
end

redraw_grid()
metro_set(redraw_metro, 10)