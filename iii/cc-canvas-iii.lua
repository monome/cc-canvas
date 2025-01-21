-- cc canvas (for iii devices)
-- 250121

-- cc numbers:
-- EDIT THESE!
cc_num = {
	0, -- column 1
	1, -- column 2
	2, -- column 3
	3, -- column 4
	4, -- column 5
	5, -- column 6
	6, -- column 7
	7, -- column 8
	8, -- column 9
	9, -- column 10
	10, -- column 11
	11, -- column 12
	12, -- column 13
	13, -- column 14
	14, -- column 15
}

-- cc channels:
-- EDIT THESE!
cc_ch = {
	1, -- column 1
	1, -- column 2
	1, -- column 3
	1, -- column 4
	1, -- column 5
	1, -- column 6
	1, -- column 7
	1, -- column 8
	1, -- column 9
	1, -- column 10
	1, -- column 11
	1, -- column 12
	1, -- column 13
	1, -- column 14
	1, -- column 15
}

-- EDIT THIS!
max_brightness = 10

-- ms slews:
local slews = {
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

local grid_size = grid_size_x() * grid_size_y()
local start_time = get_time()
local dirty = true
local intro_metro = 1
local intro_level = 10
local intro_duration = 1000
local intro_complete = false
local redraw_metro = 2
local snapshots_saver_metro = 3
local fnl_fps = 50

-- a table to track our CC values:
local cc_cols = {}
for i = 1, 15 do
	cc_cols[i] = {}
	local _c = cc_cols[i]
	_c.value = 0
	_c.absolute = 0
	_c.pressed_key = -1
	_c.slew_idx = 2
	_c.partial_restore = false
	_c.origin = {}
	_c.dest_ms = {}
	_c.dest_target = {}
	_c.stepsize = {}
	_c.count = {}
	_c.pre_val = {}
end

-- SNAPSHOTS //
-- a table to track our snapshots:
local snapshots = {}
for i = 1, 15 do
	snapshots[i] = {}
	snapshots[i].data = {}
end

function snapshot_pack(slot)
	for i = 1, 15 do
		snapshots[slot].data[i] = cc_cols[i].absolute
	end
end

function snapshot_unpack(slot, jump)
	for i = 1, 15 do
		cc_cols[i].pressed_key = -1
		fnl_start(i, snapshots[slot].data[i], { true, jump })
	end
end

function snapshot_save(slot)
	if not _alt then
		snapshot_pack(slot)
		snapshots.focus = slot
	else
		snapshot_clear(slot)
	end
	dirty = true
end

function snapshot_clear(slot)
	snapshots[slot].data = {}
	dirty = true
end
-- // SNAPSHOTS

-- METRO //
function metro(index, count)
	if index == intro_metro then
		if get_time() - start_time >= intro_duration then
			metro_set(intro_metro, 0)
			intro_complete = true
			dirty = true
		else
			draw_intro()
		end
	elseif index == redraw_metro and dirty then
		if intro_complete then
			redraw_grid()
			dirty = false
		end
		fnl_process_metro()
	elseif index == snapshots_saver_metro then
		if snapshot_being_saved ~= nil then
			snapshot_save(snapshot_being_saved)
			snapshot_being_saved = nil
			dirty = true
		end
	end
end
-- // METRO

-- GRID //

function change_value(x,y)
	local prev_pressed = cc_cols[x].pressed_key
	cc_cols[x].pressed_key = y
	if prev_pressed == cc_cols[x].pressed_key then
		cc_cols[x].pressed_key = -1
	end
	y = grid_size_y() - y
	local pressed_val = ((y + 1) * (grid_size == 128 and 16 or 8)) - 1
	fnl_start(x, pressed_val, { false, _alt })
end

function change_slew(x,y)
	y = grid_size_y() - y
	local change = (y + 1) * 2
	if cc_cols[x].slew_idx == change then
		cc_cols[x].slew_idx = cc_cols[x].slew_idx - 1
	else
		cc_cols[x].slew_idx = change
	end
end

function snapshot_press(x,y,z)
	if z == 1 then
		if #snapshots[y].data == 0 then
			if snapshot_being_saved == nil then
				snapshot_being_saved = y
				metro_set(snapshots_saver_metro, 250, 1)
			end
		elseif not _alt then
			if snapshots.focus == y then
				snapshot_unpack(y, true)
			else
				snapshots.focus = y
				snapshot_unpack(y, false)
			end
		else
			if snapshot_being_saved == nil then
				snapshot_being_saved = y
				metro_set(snapshots_saver_metro, 250, 1)
			end
		end
	else
		if snapshot_being_saved ~= nil then
			metro_stop(snapshots_saver_metro)
			snapshot_being_saved = nil
		end
	end
end

-- GRID KEY HANDLING:
function grid(x, y, z)
	-- CC COLUMNS:
	if x <= 15 and z == 1 then
		if not slew_toggle then
			change_value(x,y)
		else
			change_slew(x, y)
		end
	-- GRID SNAPSHOT MANAGEMENT:
	elseif x == 16 and y <= (grid_size == 128 and 6 or 14) then
		snapshot_press(x,y,z)
	-- SLEW TOGGLE:
	elseif x == 16 and y == (grid_size == 128 and 7 or 15) then
		slew_toggle = z == 1
	-- ALT KEY:
	elseif x == 16 and y == grid_size_y() then
		_alt = z == 1
	end

	dirty = true
end

-- GRID REDRAWS:
function draw_intro()
	grid_led_all(0)
	for i = 4,6 do
		grid_led(i+1, grid_size == 128 and 3 or 7, intro_level)
		grid_led(i+1, grid_size == 128 and 6 or 10, intro_level)
		grid_led(5, grid_size == 128 and i or i+4, intro_level)
		grid_led(i+6, grid_size == 128 and 3 or 7, intro_level)
		grid_led(i+6, grid_size == 128 and 6 or 10, intro_level)
		grid_led(10, grid_size == 128 and i or i+4, intro_level)
	end
	intro_level = wrap(intro_level - 1, 1, 10)
	grid_refresh()
end

function draw_ccs(x)
	local _c = cc_cols[x]
	-- pressed/destination pad:
	local bright = cc_cols[x].pressed_key >= 0 and 7 or 3
	grid_led(x, cc_cols[x].pressed_key, bright)
	-- columns, whole numbers:
	local whole, part = math.modf(_c.value / (grid_size == 128 and 16 or 8))
	for y = 1, whole do
		grid_led(x, (grid_size == 128 and 9 or 17) - y, max_brightness)
	end
	-- columns, partial values:
	if whole + part == 0 then
		grid_led(x, 0, 3)
	else
		grid_led(
			x,
			grid_size_y() - whole,
			math.floor(linlin(0, max_brightness * 0.875, 4, max_brightness, max_brightness * part))
		)
	end
end

function draw_slews(x)
	local _c = cc_cols[x]
	local whole, part = math.modf(_c.slew_idx / 2)
	for y = 1, whole do
		grid_led(x, (grid_size == 128 and 9 or 17) - y, max_brightness)
	end
	-- columns, partial values:
	if whole + part == 0 then
		grid_led(x, 0, 3)
	else
		grid_led(
			x,
			grid_size_y() - whole,
			math.floor(linlin(0, max_brightness * 0.875, 4, max_brightness, max_brightness * part))
		)
	end
end

function draw_snapshots()
	for y = 1, grid_size == 128 and 7 or 14 do
		if #snapshots[y].data > 0 then
			local unselected = max_brightness > 12 and 8 or 5
			grid_led(16, y, snapshots.focus == y and max_brightness or unselected)
		end
	end
end

function redraw_grid()
	-- clear LEDs:
	grid_led_all(0)

	for x = 1, 15 do
		-- base canvas:
		for y = 1, 16 do
			grid_led(x, y, 3)
		end
		if not slew_toggle then
			draw_ccs(x)
		else
			draw_slews(x)
		end
	end

	-- snapshots:
	draw_snapshots()

	-- slew toggle:
	grid_led(16, grid_size == 128 and 7 or 15, slew_toggle and max_brightness or 5)

	-- _alt:
	grid_led(16, grid_size == 128 and 8 or 16, _alt and max_brightness or 5)

	grid_refresh()
end
-- // GRID

function send_midi_out(x, value)
	cc_cols[x].value = value
	midi_cc(cc_num[x + 1], value, cc_ch[x + 1])
	dirty = true
end

-- FNL //
-- fnl's (funnel's) make slewed changes between two data points

-- metro callback to process each fnl
function fnl_process_metro()
	for i = 1, #cc_cols do
		local _c = cc_cols[i]
		if _c.fnl_metro_running then
			if _c.count > 0 then
				_c.origin = _c.origin + _c.stepsize -- move toward destination
				_c.count = _c.count - 1 -- count iteration
				fnl_step(i, _c.origin)
			end
		end
	end
end

-- step through each fnl:
function fnl_step(x, r_val)
	local _c = cc_cols[x]
	_c.current_value = r_val
	local scaled = math.floor(linlin(0, 1, _c.pre_val, _c.dest_target, r_val))
	-- send midi for each scaled step:
	send_midi_out(x, scaled)
	-- if we're at the end of the fnl, call it 'done' and stop the metro iteration:
	if _c.current_value ~= nil and round(_c.current_value, 0.001) == 1 then
		fnl_done(x, _c.dest_target)
		_c.fnl_metro_running = false
	end
end

-- start the fnl:
function fnl_start(x, val, from_snapshot)
	local _c = cc_cols[x]
	-- if the fnl is interrupted, kill the metro as we reset:
	if _c.partial_restore then
		_c.fnl_metro_running = false
	end
	local target
	if from_snapshot[1] then
		target = val
	else
		target = _c.value == clamp(0, 127, val) and 0 or val
	end
	_c.absolute = target
	-- if there's no slew, then just jump to done:
	if _c.slew_idx == 1 or from_snapshot[2] then
		fnl_done(x, target)
	else
		_c.partial_restore = true
		_c.pre_val = _c.value
		_c.origin = 0
		_c.dest_ms = slews[_c.slew_idx] / 1000
		_c.dest_target = target
		fnl_step(x, _c.origin)
		_c.count = math.floor(_c.dest_ms * fnl_fps) -- number of iterations
		_c.stepsize = (1 - _c.origin) / _c.count -- how much to increment by each iteration
		_c.fnl_metro_running = true
	end
end

-- when the fnl is done, reset everything and push the last cc value:
function fnl_done(x, val)
	local _c = cc_cols[x]
	-- ps("%s",_c.partial_restore)
	if _c.partial_restore then
		_c.fnl_metro_running = false
		_c.partial_restore = false
	end
	send_midi_out(x, val)
	if _c.value == 0 then
		_c.pressed_key = -1
	end
end
-- // FNL

metro_set(intro_metro, 50)
metro_set(redraw_metro, 20) -- (1000/50), 50fps in ms [needed as of 241203]