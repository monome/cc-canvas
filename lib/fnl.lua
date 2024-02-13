-- fnl is a very useful tool for calling functions repeatedly
--   over linear time. it was introduced by @Galapagoose during
--   maps season 2 episode 3: https://monome.org/docs/crow/maps/s2e3#fnl

local fnl_lib = {}

-- call a function repetitively in time
-- the arg to the function is interpolated fps times per second
-- dest_ms is a table
function fnl_lib.cycle(fn, origin, dest_ms, fps)
	return clock.run(function()
		fps = fps or 15 -- default
		local spf = 1 / fps -- seconds per frame
		fn(origin)
		for _, v in ipairs(dest_ms) do
			local count = math.floor(v[2] * fps) -- number of iterations
			local stepsize = (v[1] - origin) / count -- how much to increment by each iteration
			while count > 0 do
				clock.sleep(spf)
				origin = origin + stepsize -- move toward destination
				count = count - 1 -- count iteration
				fn(origin)
			end
		end
	end)
end

function fnl_lib.trigger(x, val, from_snapshot)
	local _c = cc_cols[x]
	if _c.partial_restore then
		clock.cancel(_c.fnl)
	end
	local target
	if from_snapshot[1] then
		target = val
	else
		target = _c.value == util.clamp(0, 127, val) and 0 or val
	end
	_c.absolute = target
	if target ~= 0 then
		local whole, part = math.modf(val / 8)
		cc_cols[x].last_pressed = whole == 0 and 0 or whole + 1
	else
		cc_cols[x].last_pressed = 0
	end
	if params:string("ms_slew_" .. x) == 0 or from_snapshot[2] then
		fnl_lib.done(x, target)
	else
		_c.partial_restore = true
		local pre_val = _c.value
		_c.fnl = fnl_lib.cycle(function(r_val)
			_c.current_value = r_val
			params:set(cc_mapval_id[x], math.floor(util.linlin(0, 1, pre_val, target, r_val)))
			if _c.current_value ~= nil and util.round(_c.current_value, 0.001) == 1 then
				fnl_lib.done(x, target)
			end
		end, 0, { { 1, params:string("ms_slew_" .. x) / 1000 } }, 60)
	end
end

function fnl_lib.done(x, val)
	if cc_cols[x].partial_restore then
		clock.cancel(cc_cols[x].fnl)
		cc_cols[x].partial_restore = false
	end
	params:set("cc_mapval_" .. x, val)
	local whole, part = math.modf(cc_cols[x].value / 8)
	cc_cols[x].last_pressed = whole == 0 and 0 or whole + 1
	surfaces_dirty = true
end

return fnl_lib
