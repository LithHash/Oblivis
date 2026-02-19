--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local oblivis = require(ReplicatedStorage.shared.oblivis)

local world = oblivis.world
local components = oblivis.components
local systems = oblivis.systems

local chunkClass = require(script.chunkClass)

local CHUNK_SIZE = 128
local CHUNK_SIZE_INV = 1 / CHUNK_SIZE

local registeredChunks: { [string]: chunkClass.ChunkObject } = {}
local playerChunks: { [Player]: { x: number, z: number } } = {}

local chunkChangedCallbacks: { [number]: (entity: number, players: { Player }) -> () } = {}
local nextCallbackId = 0

local function chunkKey(chunkX: number, chunkZ: number): string
	return `{chunkX},{chunkZ}`
end

local function worldToChunk(position: Vector3): (number, number)
	if not position then
		warn("worldToChunk: Invalid position (nil)")
		return 0, 0
	end

	return math.floor(position.X * CHUNK_SIZE_INV), math.floor(position.Z * CHUNK_SIZE_INV)
end

local function getChunk(chunkX: number, chunkZ: number): chunkClass.ChunkObject?
	if typeof(chunkX) ~= "number" or typeof(chunkZ) ~= "number" then
		warn("getChunk: Invalid chunk coordinates")
		return nil
	end

	local key = chunkKey(chunkX, chunkZ)
	local chunk = registeredChunks[key]

	if not chunk then
		chunk = chunkClass.new(chunkX, chunkZ)
		if chunk then
			registeredChunks[key] = chunk
		end
	end

	return chunk
end

local function getExistingChunk(chunkX: number, chunkZ: number): chunkClass.ChunkObject?
	if typeof(chunkX) ~= "number" or typeof(chunkZ) ~= "number" then
		return nil
	end

	return registeredChunks[chunkKey(chunkX, chunkZ)]
end

local function getPlayersInRadius(centerX: number, centerZ: number, radius: number?): { Player }
	local chunks = {}
	local resolvedRadius = radius or 1
	if resolvedRadius < 0 then
		resolvedRadius = 0
	end

	local chunkCount = 0
	for offsetX = -resolvedRadius, resolvedRadius do
		for offsetZ = -resolvedRadius, resolvedRadius do
			local chunk = getChunk(centerX + offsetX, centerZ + offsetZ)
			if chunk then
				chunkCount += 1
				chunks[chunkCount] = chunk
			end
		end
	end

	local seen: { [Player]: boolean } = {}
	local result: { Player } = {}
	local resultCount = 0

	for i = 1, chunkCount do
		for player in chunks[i]:getPlayers() do
			if not seen[player] then
				seen[player] = true
				resultCount += 1
				result[resultCount] = player
			end
		end
	end

	return result
end

local function fireChunkChanged(entity: number, chunkX: number, chunkZ: number)
	if not next(chunkChangedCallbacks) then
		return
	end

	local nearbyPlayers = getPlayersInRadius(chunkX, chunkZ, 16)
	for _, fn in chunkChangedCallbacks do
		fn(entity, nearbyPlayers)
	end
end

local function updateEntity(entity: number, position: Vector3): chunkClass.ChunkObject?
	if typeof(entity) ~= "number" or not position then
		warn("updateEntity: Invalid entity or position")
		return nil
	end

	local chunkX, chunkZ = worldToChunk(position)
	local oldChunkData: { x: number, z: number }? = world:read(entity, components.chunk)

	if not oldChunkData then
		local chunk = getChunk(chunkX, chunkZ)
		if chunk then
			chunk:addEntity(entity)
			world:assign(entity, components.chunk, { x = chunkX, z = chunkZ })
			fireChunkChanged(entity, chunkX, chunkZ)
		end
		return nil
	end

	if oldChunkData.x == chunkX and oldChunkData.z == chunkZ then
		return nil
	end

	local oldChunk = getExistingChunk(oldChunkData.x, oldChunkData.z)
	if oldChunk then
		oldChunk:removeEntity(entity)
	end

	local newChunk = getChunk(chunkX, chunkZ)
	if newChunk then
		newChunk:addEntity(entity)
		world:assign(entity, components.chunk, { x = chunkX, z = chunkZ })
		fireChunkChanged(entity, chunkX, chunkZ)
	end

	return newChunk
end

local function removeEntity(entity: number): boolean
	if typeof(entity) ~= "number" then
		warn("removeEntity: Invalid entity")
		return false
	end

	local chunkData = world:read(entity, components.chunk)
	if not chunkData then
		return false
	end

	local chunk = getExistingChunk(chunkData.x, chunkData.z)
	if chunk then
		chunk:removeEntity(entity)
		world:remove(entity, components.chunk)
		return true
	end

	return false
end

local function updatePlayer(player: Player, position: Vector3): chunkClass.ChunkObject?
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		warn("updatePlayer: Invalid player")
		return nil
	end

	if not position then
		warn("updatePlayer: Invalid position")
		return nil
	end

	local chunkX, chunkZ = worldToChunk(position)
	local oldChunkData = playerChunks[player]

	if not oldChunkData then
		local chunk = getChunk(chunkX, chunkZ)
		if chunk then
			chunk:addPlayer(player)
			playerChunks[player] = { x = chunkX, z = chunkZ }
		end
		return nil
	end

	if oldChunkData.x == chunkX and oldChunkData.z == chunkZ then
		return nil
	end

	local oldChunk = getExistingChunk(oldChunkData.x, oldChunkData.z)
	if oldChunk then
		oldChunk:removePlayer(player)
	end

	local newChunk = getChunk(chunkX, chunkZ)
	if newChunk then
		newChunk:addPlayer(player)
		playerChunks[player] = { x = chunkX, z = chunkZ }
	end

	return newChunk
end

local function removePlayer(player: Player): boolean
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		warn("removePlayer: Invalid player")
		return false
	end

	local chunkData = playerChunks[player]
	if not chunkData then
		return false
	end

	local chunk = getExistingChunk(chunkData.x, chunkData.z)
	if chunk then
		chunk:removePlayer(player)
	end

	playerChunks[player] = nil
	return true
end

local function getPlayerChunk(player: Player): chunkClass.ChunkObject?
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return nil
	end

	local chunkData = playerChunks[player]
	if not chunkData then
		return nil
	end

	return getExistingChunk(chunkData.x, chunkData.z)
end

local function getNeighborChunks(
	chunkX: number, chunkZ: number, radius: number?
): { chunkClass.ChunkObject }
	if typeof(chunkX) ~= "number" or typeof(chunkZ) ~= "number" then
		warn("getNeighborChunks: Invalid chunk coordinates")
		return {}
	end

	local resolvedRadius = radius or 1
	if resolvedRadius < 0 then
		resolvedRadius = 0
	end

	local result: { chunkClass.ChunkObject } = {}
	local resultCount = 0

	for offsetX = -resolvedRadius, resolvedRadius do
		for offsetZ = -resolvedRadius, resolvedRadius do
			local chunk = getChunk(chunkX + offsetX, chunkZ + offsetZ)
			if chunk then
				resultCount += 1
				result[resultCount] = chunk
			end
		end
	end

	return result
end

local function cleanupEmptyChunks(): number
	local cleanedCount = 0

	for key, chunk in registeredChunks do
		if chunk:isEmpty() then
			registeredChunks[key] = nil
			cleanedCount += 1
		end
	end

	return cleanedCount
end

local function buildFilteredView(
	baseView: oblivis.View, validEntities: { [number]: boolean }
): oblivis.View
	local filteredView = {}

	function filteredView:forEach(fn: (...any) -> ())
		baseView:forEach(function(entity: number, ...)
			if validEntities[entity] then
				fn(entity, ...)
			end
		end)
	end

	function filteredView:exclude(...: number)
		baseView = baseView:exclude(...)
		return filteredView
	end

	function filteredView:count(): number
		local count = 0
		filteredView:forEach(function()
			count += 1
		end)
		return count
	end

	function filteredView:entities(): { number }
		local result: { number } = {}
		local resultCount = 0
		baseView:forEach(function(entity: number)
			if validEntities[entity] then
				resultCount += 1
				result[resultCount] = entity
			end
		end)
		return result
	end

	function filteredView:empty(): boolean
		return filteredView:count() == 0
	end

	return filteredView :: any
end

local function queryChunk(chunkX: number, chunkZ: number, ...: number): oblivis.View
	local chunk = getExistingChunk(chunkX, chunkZ)
	local chunkEntities: { [number]: boolean } = chunk and chunk:getEntities() or {}
	local baseView = world:view(...)
	return buildFilteredView(baseView, chunkEntities)
end

local function queryRadius(
	centerX: number, centerZ: number, radius: number, ...: number
): oblivis.View
	local baseView = world:view(...)
	local chunks = getNeighborChunks(centerX, centerZ, radius)

	local validEntities: { [number]: boolean } = {}
	for i = 1, #chunks do
		for entity in chunks[i]:getEntities() do
			validEntities[entity] = true
		end
	end

	return buildFilteredView(baseView, validEntities)
end

local function queryPosition(position: Vector3, radius: number, ...: number): oblivis.View
	local chunkX, chunkZ = worldToChunk(position)
	return queryRadius(chunkX, chunkZ, radius, ...)
end

local function getPlayersNearPosition(position: Vector3, radius: number?): { Player }
	local chunkX, chunkZ = worldToChunk(position)
	return getPlayersInRadius(chunkX, chunkZ, radius)
end

local function onEntityChunkChanged(
	fn: (entity: number, players: { Player }) -> ()
): () -> ()
	nextCallbackId += 1
	local id = nextCallbackId
	chunkChangedCallbacks[id] = fn

	return function()
		chunkChangedCallbacks[id] = nil
	end
end

local function _start()
	systems.create("chunkUpdate", {
		update = require(script.systems.chunkUpdate) :: any,
		step = "Heartbeat",
		priority = 10,
	})

	systems.create("chunkCleanup", {
		update = require(script.systems.chunkCleanup) :: any,
		step = "Heartbeat",
		priority = 20,
	})
end

return table.freeze({
	updateEntity = updateEntity,
	removeEntity = removeEntity,

	updatePlayer = updatePlayer,
	removePlayer = removePlayer,
	getPlayerChunk = getPlayerChunk,
	getPlayersInRadius = getPlayersInRadius,
	getPlayersNearPosition = getPlayersNearPosition,

	getChunk = getChunk,
	getExistingChunk = getExistingChunk,
	getNeighborChunks = getNeighborChunks,
	cleanupEmptyChunks = cleanupEmptyChunks,
	worldToChunk = worldToChunk,

	queryChunk = queryChunk,
	queryRadius = queryRadius,
	queryPosition = queryPosition,

	onEntityChunkChanged = onEntityChunkChanged,

	CHUNK_SIZE = CHUNK_SIZE,

	_start = _start,
})
