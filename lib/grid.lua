local grid_lib = {}

g = grid.connect()
grid_lib.draw = {}

function grid.add()
	surfaces_dirty = true
end

function g.key(x, y, z)
	if x == 16 and y <= 14 then
		if z == 1 then
			if #snapshots[y].data == 0 then
				snapshots[y].saver_clock = clock.run(_snap.save_to_slot, y)
			elseif not _alt then
				snapshots.focus = y
				_snap.unpack(y)
			else
				snapshots[y].saver_clock = clock.run(_snap.save_to_slot, y)
			end
		else
			if snapshots[y].saver_clock ~= nil then
				clock.cancel(snapshots[y].saver_clock)
				snapshots[y].saver_clock = nil
			end
		end
	elseif x == 16 and y == 15 then
		_all = z == 1
	elseif x == 16 and y == 16 then
		_alt = z == 1
	else
		if z == 1 then
			if not _alt then
				if x <= 15 then
					y = 16 - y
					local pressed_val = ((y + 1) * 8) - 1
					_fnl.trigger(x, pressed_val, { false })
					if _all then
						for i = 1, 15 do
							if i ~= x then
								_fnl.trigger(i, pressed_val, { false })
							end
						end
					end
				end
			else
				params:set("ms_slew_" .. x, 17 - y)
				if _all then
					for i = 1, 15 do
						if i ~= x then
							params:set("ms_slew_" .. i, 17 - y)
						end
					end
				end
			end
		end
	end
	surfaces_dirty = true
end

function grid_lib.draw.standard()
	for x = 1, 15 do
		-- background:
		for y = 1, 16 do
			g:led(x, y, 3)
		end
		local _c = cc_cols[x]
		-- if not holding _alt:
		if not _alt then
			-- columns, whole numbers::
			local whole, part = math.modf(_c.value / 8)
			for y = 1, whole do
				g:led(x, 17 - y, 15)
			end
			-- columns, partial values:
			if whole + part == 0 then
				g:led(x, 16, 3)
			else
				g:led(x, 16 - whole, math.floor(util.linlin(0, 15 * 0.875, 4, 15, 15 * part)))
			end
		else
			for y = 1, 16 do
				g:led(x, y, _c.slew_idx == 17 - y and 15 or 3)
				if 17 - y < _c.slew_idx then
					g:led(x, y, 8)
				end
			end
		end
	end
	-- sidebar for snapshots:
	for y = 1, 15 do
		if #snapshots[y].data > 0 then
			g:led(16, y, snapshots.focus == y and 15 or 8)
		end
	end
	g:led(16, 15, _all and 12 or 3)
	g:led(16, 16, _alt and 15 or 5)
end

function grid_lib.draw.lowpower()
	for x = 1, 15 do
		local _c = cc_cols[x]
		-- if not holding _alt:
		if not _alt then
			-- columns, whole numbers::
			local whole, part = math.modf(_c.value / 8)
			for y = 1, whole do
				g:led(x, 17 - y, 3)
			end
			-- columns, partial values:
			if whole + part == 0 then
				g:led(x, 16, 0)
			else
				g:led(x, 16 - whole, math.floor(util.linlin(0, 15 * 0.875, 0, 8, 15 * part)))
			end
			if _c.last_pressed ~= 0 then
				g:led(x, 17 - _c.last_pressed, 8)
			end
		else
			for y = 1, 16 do
				g:led(x, y, _c.slew_idx == 17 - y and 15 or 3)
				if 17 - y < _c.slew_idx then
					g:led(x, y, 8)
				end
			end
		end
	end
	-- sidebar for snapshots:
	for y = 1, 15 do
		if #snapshots[y].data > 0 then
			g:led(16, y, snapshots.focus == y and 10 or 5)
		end
	end
	g:led(16, 15, _all and 7 or 2)
	g:led(16, 16, _alt and 10 or 3)
end

-- default grid drawing to "standard" mode
grid_lib.draw.mode = grid_lib.draw.standard

function grid_lib.draw.main()
	g:all(0)
	grid_lib.draw.mode()
	g:refresh()
end

return grid_lib
