-- cc-canvas
-- 15 columns of MIDI CC's
-- with slew and recall
-- made for monome zero / 256
--
-- far-right column:
--  16: ALT
--   - hold reveals slew times
--  15: ALL
--   - hold to set all columns
--     to pressed value
--  1-14: snapshots
--   - long press to save
--   - short press to recall
--     + ALT: delete
--     + ALL: jump (no slew)

_snap = include("lib/snapshots")
_grid = include("lib/grid")
_fnl = include("lib/fnl")
_params = include("lib/params")

function init()
	check_redraw_flags = metro.init(function()
		if surfaces_dirty then
			_grid.draw.main()
			redraw()
			surfaces_dirty = false
		end
	end, 1 / 60, -1)
	check_redraw_flags:start()

	if seamstress then
		screen.set_size(120, 64)
	end

	cc_slews = {
		ms = {
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
		},
	}
	-- a table to track our CC values:
	cc_cols = {}
	for i = 1, 15 do
		cc_cols[i] = {}
		local _c = cc_cols[i]
		_c.value = 0
		_c.absolute = 0
		_c.slew_idx = 1
		_c.last_pressed = 0
		_c.partial_restore = false
	end

	-- initialize snapshots:
	_snap.init()

	-- grid modifiers:
	_alt = false
	_all = false

	-- MIDI:
	midi_devices = {} -- build a table of connected MIDI devices for MIDI input + output
	midi_device_names = {} -- index their names to display them in params

	function midi.add(dev)
		midi_device_names[dev.port] = dev.port .. ": " .. dev.name
		if norns then
			for i = 1, 15 do
				params:lookup_param("midi_output_device_" .. i).options = midi_device_names
			end
		elseif seamstresss then
			for i = 1, 15 do
				params:lookup_param("midi_output_device_" .. i).formatter = function(param)
					return midi_device_names[(type(param) == "table" and param:get() or param)]
				end
			end
		end
	end

	for i = 1, #midi.vports do -- for each MIDI port:
		midi_devices[i] = midi.connect(i) -- connect to the device
		midi_device_names[i] = i .. ": " .. midi.vports[i].name -- log its name
	end

	-- PARAMETERS:
	_params.init()

	surfaces_dirty = true
end

function redraw()
	screen.clear()
	for i = 1, 15 do
		if seamstress then
			screen.move((i - 1) * 8, 0)
			screen.color(
				util.linlin(0, 127, 2 * i, 255, cc_cols[i].value),
				util.linlin(0, 127, 3 * i, 100, cc_cols[i].value),
				util.linlin(0, 127, 0, 15 * i, cc_cols[i].value)
			)
			screen.rect_fill(8, 64)
		else
			screen.level(math.floor(util.linlin(0, 127, 1, 15, cc_cols[i].value)))
			screen.rect((i - 1) * 8, 0, 8, 64)
			screen.fill()
		end
	end
	screen.update()
end

function cleanup()
	g:all(0)
	g:refresh()
end
