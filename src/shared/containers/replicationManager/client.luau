--!optimize 2
--!native
--!strict

export type ClientReplicationManager = {
	flush: (self: ClientReplicationManager) -> (),
	getLocalEntity: (self: ClientReplicationManager, serverEntity: number) -> number?,
	getServerEntity: (self: ClientReplicationManager, localEntity: number) -> number?,
}

type ClientReplicationManagerInternal = {
	_world: any,
	_events: any,
	_serverToClient: { [number]: number },
	_clientToServer: { [number]: number },
	flush: (self: ClientReplicationManager) -> (),
	getLocalEntity: (self: ClientReplicationManager, serverEntity: number) -> number?,
	getServerEntity: (self: ClientReplicationManager, localEntity: number) -> number?,
}

local function resolveEntity(
	self: ClientReplicationManagerInternal,
	serverEntity: number
): number
	local existing = self._serverToClient[serverEntity]
	if existing then
		return existing
	end

	local localEntity = self._world:entity()
	self._serverToClient[serverEntity] = localEntity
	self._clientToServer[localEntity] = serverEntity

	return localEntity
end

local function applyBatch(self: ClientReplicationManagerInternal, batch: { any })
	for _, event in batch do
		local kind = event.kind

		print(event, kind)

		if kind == "assign" then
			local localEntity = resolveEntity(self, event.entity)
			self._world:assign(localEntity, event.component, event.value)

		elseif kind == "remove" then
			local localEntity = self._serverToClient[event.entity]
			if localEntity then
				self._world:remove(localEntity, event.component)
			end

		elseif kind == "destroy" then
			local localEntity = self._serverToClient[event.entity]
			if localEntity then
				self._world:destroy(localEntity)
				self._serverToClient[event.entity] = nil
				self._clientToServer[localEntity] = nil
			end
		end
	end
end

local function flush(self: ClientReplicationManager)
	local internal = self :: ClientReplicationManagerInternal

	for _, _, batch in internal._events.reliable:iterate() do
		applyBatch(internal, batch)
	end

	for _, _, batch in internal._events.unreliable:iterate() do
		applyBatch(internal, batch)
	end
end

local function getLocalEntity(self: ClientReplicationManager, serverEntity: number): number?
	local internal = self :: ClientReplicationManagerInternal

	return internal._serverToClient[serverEntity]
end

local function getServerEntity(self: ClientReplicationManager, localEntity: number): number?
	local internal = self :: ClientReplicationManagerInternal

	return internal._clientToServer[localEntity]
end

local function new(world: any, events: any): ClientReplicationManager
	local self: ClientReplicationManagerInternal = {
		_world = world,
		_events = events,
		_serverToClient = {},
		_clientToServer = {},
		flush = flush,
		getLocalEntity = getLocalEntity,
		getServerEntity = getServerEntity,
	}

	return self :: ClientReplicationManager
end

return {
	new = new,
}
