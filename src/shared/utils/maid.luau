type CleanupFunction = () -> ()
type Thread = thread
type Connection = RBXScriptConnection

type DestroyableInstance = Instance & { Destroy: (self: Instance) -> () }
type Tween = Instance & { Cancel: (self: Instance) -> () }
type AnimationTrack = Instance & { Stop: (self: Instance) -> () }
type DisconnectableObject = { Disconnect: (self: any) -> () }
type CancelableObject = { Cancel: (self: any) -> () }
type StoppableObject = { Stop: (self: any) -> () }
type DestroyableObject = { Destroy: (self: any) -> () }

type PossibleTask =
	Thread
	| Tween
	| AnimationTrack
	| DestroyableInstance
	| Connection
	| CleanupFunction
	| DestroyableObject
	| DisconnectableObject
	| CancelableObject
	| StoppableObject

type InternalData = {
	indexedTasks: { [any]: PossibleTask }
}

export type MaidObject = {
	_cache: { PossibleTask },
	_internalData: InternalData,
	add: (self: MaidObject, task: PossibleTask) -> CleanupFunction,
	remove: (self: MaidObject, task: PossibleTask) -> (),
	clean: (self: MaidObject) -> (),
	destroy: (self: MaidObject) -> (),
}

local function cleanupTask(task: PossibleTask)
	local taskType = typeof(task)

	if taskType == "thread" then
		local status = coroutine.status(task :: thread)
		if status == "suspended" then
			coroutine.close(task :: thread)
		end
	elseif taskType == "function" then
		(task :: CleanupFunction)()
	elseif taskType == "RBXScriptConnection" then
		(task :: Connection):Disconnect()
	elseif taskType == "Instance" then
		local instance = task :: any
		if instance:IsA("Tween") then
			(instance :: any):Cancel()
		elseif instance:IsA("AnimationTrack") then
			(instance :: any):Stop()
		else
			instance:Destroy()
		end
	else
		local taskAny = task:: any
		if taskAny.Destroy then
			taskAny:Destroy()
		elseif taskAny.Disconnect then
			taskAny:Disconnect()
		elseif taskAny.Cancel then
			taskAny:Cancel()
		elseif taskAny.Stop then
			taskAny:Stop()
		end
	end
end

local function remove(self: MaidObject, task: PossibleTask)
	local index = table.find(self._cache, task)
	if not index then
		return
	end

	table.remove(self._cache, index)
	cleanupTask(task)
end

local function pop(self: MaidObject, task: PossibleTask)
	local index = table.find(self._cache, task)
	if not index then
		return
	end

	table.remove(self._cache, index)
end

local function add(self: MaidObject, task: PossibleTask): CleanupFunction
	if table.find(self._cache, task) then
		warn("Attempted to add a task:", task, "to a maid multiple times.")
		return function() end
	end

	table.insert(self._cache, task)

	return function()
		self:remove(task)
	end
end

local function clean(self: MaidObject)
	for i = #self._cache, 1, -1 do
		local task = self._cache[i]
		self:remove(task)
	end

	local internalData = rawget(self:: any, "_internalData") :: InternalData?
	if internalData then
		for key, task in internalData.indexedTasks do
			cleanupTask(task)
		end
		table.clear(internalData.indexedTasks)
	end
end

local function destroy(self: MaidObject)
	self:clean()

	local internalData = rawget(self:: any, "_internalData") :: InternalData?
	if internalData then
		table.clear(internalData.indexedTasks)
	end

	for key in self:: any do
		(self :: any)[key] = nil
	end
end

local MaidMethods = {
	add = add,
	remove = remove,
	clean = clean,
	destroy = destroy,
	pop = pop
}

local function new(): MaidObject
	local self = {
		_cache = {},
		_internalData = {
			indexedTasks = {}
		}
	}

	local meta = {
		__index = function(tbl, key)
			if MaidMethods[key] then
				return MaidMethods[key]
			end

			local internalData = rawget(tbl, "_internalData") :: InternalData?
			if internalData then
				return internalData.indexedTasks[key]
			end

			return nil
		end,

		__newindex = function(tbl, key, value)
			if key == "_cache" or key == "_internalData" then
				error("Cannot overwrite internal maid properties")
				return
			end

			local internalData = rawget(tbl, "_internalData") :: InternalData?
			if not internalData then
				return
			end

			local oldTask = internalData.indexedTasks[key]
			if oldTask then
				cleanupTask(oldTask)
			end

			internalData.indexedTasks[key] = value
		end
	}

	setmetatable(self, meta)

	return self :: any
end

return {
	new = new
}
