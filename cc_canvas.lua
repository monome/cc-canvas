-- cc_canvas

-- 15 columns of MIDI CC's
-- with slew and recall

_snap = include("lib/snapshots")
_grid = include("lib/grid")
_fnl = include("lib/fnl")
_params = include("lib/params")

function init()
	check_redraw_flags = metro.init(function()
		if surfaces_dirty then
			_grid.draw()
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

	for i = 1, #midi.vports do -- for each MIDI port:
		midi_devices[i] = midi.connect(i) -- connect to the device
		midi_device_names[i] = i .. ": " .. midi.vports[i].name -- log its name
	end

	-- PARAMETERS:
	_params.init()

	surfaces_dirty = true
	screen_surfaces_dirty = true
end

function redraw()
	screen.clear()
	for i = 1, 15 do
		screen.level(math.floor(util.linlin(0, 127, 1, 15, cc_cols[i].value)))
		if seamstress then
			screen.move((i - 1) * 8, 0)
			screen.rect_fill(8, 64)
		else
			screen.rect((i - 1) * 8, 0, 8, 64)
			screen.fill()
		end
	end
	screen.update()
end
