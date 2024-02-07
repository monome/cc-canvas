local snapshot_lib = {}

function snapshot_lib.init()
	snapshots = {}
	for i = 1, 15 do
		snapshots[i] = {}
		snapshots[i].data = {}
	end
end

function snapshot_lib.pack(slot)
	for i = 1, 15 do
		snapshots[slot].data[i] = cc_cols[i].absolute
	end
end

function snapshot_lib.unpack(slot)
	for i = 1, 15 do
		_fnl.trigger(i, snapshots[slot].data[i], { true, _all })
	end
end

function snapshot_lib.save_to_slot(slot)
	clock.sleep(0.25)
	if not _alt then
		snapshot_lib.pack(slot)
		snapshots.focus = slot
	else
		snapshot_lib.clear(slot)
	end
	surfaces_dirty = true
end

function snapshot_lib.clear(slot)
	snapshots[slot].data = {}
	surfaces_dirty = true
end

return snapshot_lib
