export type SignalObject = {
	_listeners: {(any) -> ()},

	fire: (self: SignalObject, ... any) -> (),
	listen: (self: SignalObject, callback: (... any) -> ()) -> () -> ()
}

local function listen(self: SignalObject, callback: (... any) -> ()): () -> ()
	table.insert(self._listeners, callback)

	return function()
		local index = table.find(self._listeners, callback)
		if index then
			table.remove(self._listeners, index)
		end
	end
end

local function fire(self: SignalObject, ...)
	local args = {...}

	for _, callback in self._listeners do
		task.spawn(function()
			callback(table.unpack(args))
		end)
	end
end

local function new(): SignalObject
	local self: SignalObject = {
		_listeners = {},
		listen = listen,
		fire = fire
	}

	return self
end

return {
	new = new
}
