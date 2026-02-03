type function GetPropertyType(tbl: type, key: type)
	if not tbl:is("table") then
		error("First argument must be a table type")
	end
	if not key:is("singleton") then
		error("Second argument must be a singleton type")
	end

	local property = tbl:readproperty(key)
	if not property then
		return types.any
	end

	return property
end

export type StateObject<T> = {
	_statesChanged: {keyof<T>},
	_onChangeListeners: {(stateChanged: keyof<T>, newValue: any, oldValue: any) -> ()},
	_states: T & {},

	read: <K>(self: StateObject<T>, stateKey: K & keyof<T>) -> GetPropertyType<T, K>,
	write: <K>(self: StateObject<T>, stateKey: K & keyof<T>, value: GetPropertyType<T, K>) -> (),
	flush: (self: StateObject<T>) -> (),
	onChange: (self: StateObject<T>, callback: (stateChanged: keyof<T>, newValue: any, oldValue: any) -> ()) -> (),
}

local function read<T, K>(self: StateObject<T>, stateKey: K & keyof<T>): GetPropertyType<T, K>
	return (self._states :: any)[stateKey]
end

local function write<T, K>(self: StateObject<T>, stateKey: K & keyof<T>, value: GetPropertyType<T, K>): ()
	local currentValue = self:read(stateKey)

	self._states[stateKey] = value
	table.insert(self._statesChanged:: any, stateKey)

	for _, callback in self._onChangeListeners do
		callback(stateKey, value, currentValue)
	end
end

local function flush<T>(self: StateObject<T>): ()
	table.clear(self._statesChanged:: any)
end

local function onChange<T>(self: StateObject<T>, callback: (stateChanged: keyof<T>, newValue: any, oldValue: any) -> ()): ()
	table.insert(self._onChangeListeners, callback)
end

local function new<T>(initialStates: T & {}): StateObject<T>
	local self = {
		_statesChanged = {},
		_onChangeListeners = {},
		_states = initialStates,

		read = read,
		write = write,
		flush = flush,
		onChange = onChange,
	}

	return self
end

return {
	new = new
}
