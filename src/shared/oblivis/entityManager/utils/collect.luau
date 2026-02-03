export type PackedArgs = { [number]: any, n: number }

export type Collector = {
	push: (self: Collector, ...any) -> (),
	connect: (self: Collector, signal: RBXScriptSignal) -> RBXScriptConnection,
	size: (self: Collector) -> number,
	each: (self: Collector, fn: (...any) -> ()) -> number,
	drain: (self: Collector) -> { PackedArgs },
	iter: (self: Collector) -> (() -> ...any?),
	clear: (self: Collector) -> (),
	destroy: (self: Collector) -> ()
}

export type Options = {
	max: number?,
	dropOldest: boolean?
}

local function new(sources: RBXScriptSignal | {RBXScriptSignal}?, opts: Options?)
	local queue: { PackedArgs } = {}
	local conns: { RBXScriptConnection } = {}

	local max = if opts and opts.max then opts.max else nil
	local dropOldest = if opts and opts.dropOldest ~= nil then opts.dropOldest else true

	local self = {}:: any

	function self:push(...: any)
		if max and #queue >= max then
			if dropOldest then
				table.remove(queue, 1)
			else
				return
			end
		end

		table.insert(queue, table.pack(...))
	end

	function self:connect(signal: RBXScriptSignal): RBXScriptConnection
		local conn = signal:Connect(function(...)
			self:push(...)
		end)

		table.insert(conns, conn)
		return conn
	end

	function self:size(): number
		return #queue
	end

	function self:drain(): { PackedArgs }
		if #queue == 0 then
			return table.create(0):: { PackedArgs }
		end

		local drained = queue
		queue = {}
		return drained
	end

	function self:each(fn: (...any) -> ()): number
		local drained = self:drain()
		for i = 1, #drained do
			local item = drained[i]
			fn(table.unpack(item, 1, item.n))
		end

		return #drained
	end

	function self:iter()
		local drained = self:drain()
		local i = 0
		return function()
			i += 1
			local item = drained[i]
			if item then
				return table.unpack(item, 1, item.n)
			end

			return
		end
	end

	function self:clear()
		table.clear(queue)
	end

	function self:destroy()
		for _, conn in conns do
			conn:Disconnect()
		end

		table.clear(conns)
		table.clear(queue)
	end

	if sources ~= nil then
		if typeof(sources) == "RBXScriptSignal" then
			self:connect(sources:: RBXScriptSignal)
		elseif typeof(sources) == "table" then
			for _, s in sources do
				if typeof(s)  == "RBXScriptSignal" then
					self:connect(s)
				end
			end
		end
	end

	return self :: Collector
end

return {
    new = new
}
