local params_lib = {}

function params_lib.init()
	params:add_separator("meta")

	params:add_option("display_mode", "display mode", { "standard", "low-power" }, 1)
	params:set_action("display_mode", function(value)
		display_mode = value == 1 and "standard" or "low-power"
		surfaces_dirty = true
	end)

	params:add_binary("morph", "morph", "trigger")
	params:set_action("morph", function()
		for i = 1, 15 do
			local morphed = util.clamp(cc_cols[i].value + math.random(-10, 10), 0, 127)
			local whole, part = math.modf(morphed / 8)
			if i == 1 then
				print(morphed, cc_cols[i].value, whole, part)
			end
			_fnl.trigger(i, morphed, { true, _all })
		end
	end)

	params:add_separator("MIDI output")
	for i = 1, 15 do
		params:add_group("column " .. i, 5)
		params:add_option("ms_slew_" .. i, "slew (in ms)", cc_slews.ms, 1)
		params:set_action("ms_slew_" .. i, function(value)
			cc_cols[i].slew_idx = value
		end)
		params:add_option("midi_output_device_" .. i, "port", midi_device_names, 1)
		params:add_number("midi_ch_" .. i, "channel", 1, 16, 1)
		params:add_number("cc_num_" .. i, "CC number", 0, 127, 101 + i)
		params:add_number("cc_mapval_" .. i, "CC value", 0, 127, 0)
		params:set_action("cc_mapval_" .. i, function(value)
			local port = params:get("midi_output_device_" .. i)
			local cc_num = params:get("cc_num_" .. i)
			local midi_ch = params:get("midi_ch_" .. i)
			cc_cols[i].value = value
			midi_devices[port]:cc(cc_num, value, midi_ch)
			surfaces_dirty = true
		end)
	end

	params.action_write = function(filename, name, number)
		local environment = seamstress ~= nil and seamstress or norns
		os.execute("mkdir -p " .. environment.state.data .. "/" .. number .. "/")
		local snap_save = {
			focus = snapshots.focus,
			data = {},
		}
		for i = 1, 15 do
			snap_save.data[i] = snapshots[i].data
		end
		tab.save(snap_save, environment.state.data .. "/" .. number .. "/snapshots.data")
		print("cc-canvas: finished writing snapshot data to PSET " .. number)
	end

	params.action_read = function(filename, silent, number)
		local environment = seamstress ~= nil and seamstress or norns
		local snap_load = {}
		snap_load = tab.load(environment.state.data .. "/" .. number .. "/snapshots.data")
		snapshots.focus = snap_load.focus
		for i = 1, 15 do
			snapshots[i].data = snap_load.data[i]
		end
		surfaces_dirty = true
		print("cc-canvas: finished reading snapshot data from PSET " .. number)
	end

	params.action_delete = function(filename, name, number)
		local environment = seamstress ~= nil and seamstress or norns
		norns.system_cmd("rm -r " .. environment.state.data .. "/" .. number .. "/")
		print("cc-canvas: snapshot data deleted from PSET " .. number)
	end

	params:bang()
end

return params_lib
