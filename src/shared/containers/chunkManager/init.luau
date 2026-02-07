--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local oblivis = require(ReplicatedStorage.shared.oblivis)
local world = oblivis.world
local components = oblivis.components

local chunkClass = require(script.chunkClass)

local CHUNK_SIZE = 128
local CHUNK_SIZE_INV = 1 / CHUNK_SIZE

local registeredChunks: {[string]: chunkClass.ChunkObject} = {}

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

local function updateEntity(entity: number, position: Vector3): chunkClass.ChunkObject?
	if typeof(entity) ~= "number" or not position then
		warn("updateEntity: Invalid entity or position")
		return nil
	end

	local chunkX, chunkZ = worldToChunk(position)
	local oldChunkData: {x: number, z: number} = world:read(entity, components.chunk)

	if not oldChunkData then
		local chunk = getChunk(chunkX, chunkZ)
		if chunk then
			chunk:addEntity(entity)
			world:assign(entity, components.chunk, {x = chunkX, z = chunkZ})
		end
		return nil
	end

	if oldChunkData.x == chunkX and oldChunkData.z == chunkZ then
		return nil
	end

	local oldChunk = getChunk(oldChunkData.x, oldChunkData.z)
	if oldChunk then
		oldChunk:removeEntity(entity)
	end

	local newChunk = getChunk(chunkX, chunkZ)
	if newChunk then
		newChunk:addEntity(entity)
		world:assign(entity, components.chunk, {x = chunkX, z = chunkZ})
	end

	return newChunk
end

local function getNeighborChunks(chunkX: number, chunkZ: number, radius: number?): {chunkClass.ChunkObject}
	if typeof(chunkX) ~= "number" or typeof(chunkZ) ~= "number" then
		warn("getNeighborChunks: Invalid chunk coordinates")
		return {}
	end

	radius = radius or 1
	if radius < 0 then
		radius = 0
	end

	local result: {chunkClass.ChunkObject} = {}
	local resultCount = 0

	for offsetX = -radius, radius do
		for offsetZ = -radius, radius do
			local key = chunkKey(chunkX + offsetX, chunkZ + offsetZ)
			local chunk = registeredChunks[key]
			if chunk then
				resultCount += 1
				result[resultCount] = chunk
			end
		end
	end

	return result
end

local function getExistingChunk(chunkX: number, chunkZ: number): chunkClass.ChunkObject?
	if typeof(chunkX) ~= "number" or typeof(chunkZ) ~= "number" then
		return nil
	end

	local key = chunkKey(chunkX, chunkZ)
	return registeredChunks[key]
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

local function cleanupEmptyChunks(): number
	local cleanedCount = 0

	for key, chunk in registeredChunks do
		local entities = chunk:getEntities()
		local players = chunk:getPlayers()

		local isEmpty = next(entities) == nil and next(players) == nil
		if isEmpty then
			registeredChunks[key] = nil
			cleanedCount += 1
		end
	end

	return cleanedCount
end

local function queryChunk(chunkX: number, chunkZ: number, ...: number)
	local chunk = getExistingChunk(chunkX, chunkZ)
	if not chunk then
		return world:view(...)
	end

	local componentIds = {...}
	local baseView = world:view(table.unpack(componentIds))
	local chunkEntities = chunk:getEntities()

	local filteredView = {}

	function filteredView:forEach(fn: (...any) -> ())
		baseView:forEach(function(entity: number, ...)
			if chunkEntities[entity] then
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

	function filteredView:entities(): {number}
		local result: {number} = {}
		local resultCount = 0

		baseView:forEach(function(entity: number)
			if chunkEntities[entity] then
				resultCount += 1
				result[resultCount] = entity
			end
		end)

		return result
	end

	function filteredView:empty(): boolean
		return filteredView:count() == 0
	end

	return filteredView:: any
end

local function queryRadius(centerX: number, centerZ: number, radius: number, ...: number)
	local componentIds = {...}
	local baseView = world:view(table.unpack(componentIds))
	local chunks = getNeighborChunks(centerX, centerZ, radius)

	local validEntities: {[number]: boolean} = {}
	for i = 1, #chunks do
		local chunkEntities = chunks[i]:getEntities()
		for entity in chunkEntities do
			validEntities[entity] = true
		end
	end

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

	function filteredView:entities(): {number}
		local result: {number} = {}
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

	return filteredView
end

local function queryPosition(position: Vector3, radius: number, ...: number)
	local chunkX, chunkZ = worldToChunk(position)
	return queryRadius(chunkX, chunkZ, radius, ...)
end

return {
	updateEntity = updateEntity,
	getChunk = getChunk,
	getExistingChunk = getExistingChunk,
	getNeighborChunks = getNeighborChunks,
	removeEntity = removeEntity,
	cleanupEmptyChunks = cleanupEmptyChunks,
	worldToChunk = worldToChunk,

	queryChunk = queryChunk,
	queryRadius = queryRadius,
	queryPosition = queryPosition,

	CHUNK_SIZE = CHUNK_SIZE,
}
