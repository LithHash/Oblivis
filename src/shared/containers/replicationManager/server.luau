--!optimize 2
--!native
--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local chunkManager = require(ReplicatedStorage.shared.containers.chunkManager)

type PlayerQueue = {
	reliable: { any },
	unreliable: { any },
}

export type ServerReplicationManager = {
	replicateEntity: (
		self: ServerReplicationManager,
		entity: number,
		components: { number },
		players: { Player }?
	) -> (),
	setUnreliable: (self: ServerReplicationManager, component: number) -> (),
	stopReplicating: (self: ServerReplicationManager, entity: number) -> (),
	reconcileVisibility: (
		self: ServerReplicationManager,
		entity: number,
		currentPlayers: { Player }
	) -> (),
	flush: (self: ServerReplicationManager) -> (),
}

type ServerReplicationManagerInternal = {
	_world: any,
	_events: any,
	_unreliableComponents: { [number]: true },
	_registeredComponents: { [number]: true },
	_entityComponents: { [number]: { [number]: true } },
	_replicatedEntities: { [number]: true },
	_targetedEntities: { [number]: { Player } },
	_entityAwarePlayers: { [number]: { [Player]: true } },
	_queues: { [Player]: PlayerQueue },
	replicateEntity: (
		self: ServerReplicationManager,
		entity: number,
		components: { number },
		players: { Player }?
	) -> (),
	setUnreliable: (self: ServerReplicationManager, component: number) -> (),
	stopReplicating: (self: ServerReplicationManager, entity: number) -> (),
	reconcileVisibility: (
		self: ServerReplicationManager,
		entity: number,
		currentPlayers: { Player }
	) -> (),
	flush: (self: ServerReplicationManager) -> (),
}

local function isMarked(self: ServerReplicationManagerInternal, entity: number): boolean
	return self._replicatedEntities[entity] ~= nil or self._targetedEntities[entity] ~= nil
end

local function getOrCreateQueue(
	self: ServerReplicationManagerInternal,
	player: Player
): PlayerQueue
	if not self._queues[player] then
		self._queues[player] = { reliable = {}, unreliable = {} }
	end

	return self._queues[player]
end

local function pushToPlayers(
	self: ServerReplicationManagerInternal,
	players: { Player },
	event: any,
	unreliable: boolean
)
	for _, player in players do
		local queue = getOrCreateQueue(self, player)

		if unreliable then
			local unreliableQueue = queue.unreliable
			unreliableQueue[#unreliableQueue + 1] = event
		else
			local reliableQueue = queue.reliable
			reliableQueue[#reliableQueue + 1] = event
		end
	end
end

local function pushToPlayer(
	self: ServerReplicationManagerInternal,
	player: Player,
	event: any,
	unreliable: boolean
)
	local queue = getOrCreateQueue(self, player)

	if unreliable then
		local unreliableQueue = queue.unreliable
		unreliableQueue[#unreliableQueue + 1] = event
	else
		local reliableQueue = queue.reliable
		reliableQueue[#reliableQueue + 1] = event
	end
end

local function sendSnapshotToPlayer(
	self: ServerReplicationManagerInternal,
	entity: number,
	player: Player
)
	local entityComponents = self._entityComponents[entity]
	if not entityComponents then
		return
	end

	for component in entityComponents do
		local value = self._world:read(entity, component)
		if value == nil then
			continue
		end

		pushToPlayer(
			self,
			player,
			{ kind = "assign", entity = entity, component = component, value = value },
			self._unreliableComponents[component] ~= nil
		)
	end
end

local function registerComponent(self: ServerReplicationManagerInternal, component: number)
	if self._registeredComponents[component] then
		return
	end

	self._registeredComponents[component] = true

	self._world:onAssign(component, function(entity: number, value: any)
		if not isMarked(self, entity) then
			return
		end

		local entityComponents = self._entityComponents[entity]
		if not entityComponents or not entityComponents[component] then
			return
		end

		local awarePlayers = self._entityAwarePlayers[entity]
		if not awarePlayers then
			return
		end

		local awareList: { Player } = {}
		for player in awarePlayers do
			awareList[#awareList + 1] = player
		end

		pushToPlayers(
			self,
			awareList,
			{ kind = "assign", entity = entity, component = component, value = value },
			self._unreliableComponents[component] ~= nil
		)
	end)

	self._world:onRemove(component, function(entity: number)
		if not isMarked(self, entity) then
			return
		end

		local entityComponents = self._entityComponents[entity]
		if not entityComponents or not entityComponents[component] then
			return
		end

		local awarePlayers = self._entityAwarePlayers[entity]
		if not awarePlayers then
			return
		end

		local awareList: { Player } = {}
		for player in awarePlayers do
			awareList[#awareList + 1] = player
		end

		pushToPlayers(
			self,
			awareList,
			{ kind = "remove", entity = entity, component = component },
			false
		)
	end)
end

local function setUnreliable(self: ServerReplicationManager, component: number)
	local internal = self :: ServerReplicationManagerInternal
	internal._unreliableComponents[component] = true
end

local function replicateEntity(
	self: ServerReplicationManager,
	entity: number,
	components: { number },
	players: { Player }?
)
	local internal = self :: ServerReplicationManagerInternal

	local targets: { Player } = players or Players:GetPlayers()

	if players then
		internal._targetedEntities[entity] = players
	else
		internal._replicatedEntities[entity] = true
	end

	local entityComponents = internal._entityComponents[entity] or {}
	internal._entityComponents[entity] = entityComponents

	local awarePlayers = internal._entityAwarePlayers[entity] or {}
	internal._entityAwarePlayers[entity] = awarePlayers

	for _, component in components do
		registerComponent(internal, component)
		entityComponents[component] = true
	end

	for _, player in targets do
		if not awarePlayers[player] then
			awarePlayers[player] = true
			sendSnapshotToPlayer(internal, entity, player)
		end
	end
end

local function reconcileVisibility(
	self: ServerReplicationManager,
	entity: number,
	currentPlayers: { Player }
)
	local internal = self :: ServerReplicationManagerInternal
	if not isMarked(internal, entity) then
		return
	end

	local awarePlayers = internal._entityAwarePlayers[entity]
	if not awarePlayers then
		return
	end

	local currentSet: { [Player]: true } = {}
	for _, player in currentPlayers do
		currentSet[player] = true
	end

	for player in awarePlayers do
		if not currentSet[player] then
			pushToPlayer(
				internal,
				player,
				{ kind = "destroy", entity = entity },
				false
			)

			awarePlayers[player] = nil
		end
	end

	for _, player in currentPlayers do
		if not awarePlayers[player] then
			awarePlayers[player] = true
			sendSnapshotToPlayer(internal, entity, player)
		end
	end
end

local function stopReplicating(self: ServerReplicationManager, entity: number)
	local internal = self :: ServerReplicationManagerInternal
	if not isMarked(internal, entity) then
		return
	end

	local awarePlayers = internal._entityAwarePlayers[entity]
	if awarePlayers then
		local awareList: { Player } = {}
		for player in awarePlayers do
			awareList[#awareList + 1] = player
		end

		pushToPlayers(internal, awareList, { kind = "destroy", entity = entity }, false)
	end

	internal._replicatedEntities[entity] = nil
	internal._targetedEntities[entity] = nil
	internal._entityComponents[entity] = nil
	internal._entityAwarePlayers[entity] = nil
end

local function flush(self: ServerReplicationManager)
	local internal = self :: ServerReplicationManagerInternal

	for player, queue in internal._queues do
		if #queue.reliable > 0 then
			internal._events.reliable:sendTo(player, queue.reliable)
		end
		if #queue.unreliable > 0 then
			internal._events.unreliable:sendTo(player, queue.unreliable)
		end
	end

	table.clear(internal._queues)
end

local function new(world: any, events: any): ServerReplicationManager
	local self: ServerReplicationManagerInternal = {
		_world = world,
		_events = events,
		_unreliableComponents = {},
		_registeredComponents = {},
		_entityComponents = {},
		_replicatedEntities = {},
		_targetedEntities = {},
		_entityAwarePlayers = {},
		_queues = {},
		replicateEntity = replicateEntity,
		setUnreliable = setUnreliable,
		stopReplicating = stopReplicating,
		reconcileVisibility = reconcileVisibility,
		flush = flush,
	}

	world:onDestroy(function(entity: number)
		(self :: ServerReplicationManager):stopReplicating(entity)
	end)

	chunkManager.onEntityChunkChanged(function(entity, players)
	    self:reconcileVisibility(entity, players)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		self._queues[player] = nil
		for _, awarePlayers in self._entityAwarePlayers do
			awarePlayers[player] = nil
		end
	end)

	return self :: ServerReplicationManager
end

return {
	new = new,
}
