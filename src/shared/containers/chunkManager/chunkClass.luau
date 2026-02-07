--!strict
export type ChunkObject = {
	chunkX: number,
	chunkZ: number,

	addEntity: (self: ChunkObject, entity: number) -> boolean,
	removeEntity: (self: ChunkObject, entity: number) -> boolean,
	addPlayer: (self: ChunkObject, player: Player) -> boolean,
	removePlayer: (self: ChunkObject, player: Player) -> boolean,
	hasEntity: (self: ChunkObject, entity: number) -> boolean,
	hasPlayer: (self: ChunkObject, player: Player) -> boolean,
	getEntities: (self: ChunkObject) -> {[number]: boolean},
	getPlayers: (self: ChunkObject) -> {[Player]: boolean},
	getEntityCount: (self: ChunkObject) -> number,
	getPlayerCount: (self: ChunkObject) -> number,
	isEmpty: (self: ChunkObject) -> boolean,
}

type ChunkInternal = ChunkObject & {
	_entities: {[number]: boolean},
	_players: {[Player]: boolean},
	_entityCount: number,
	_playerCount: number,
}

local function addEntity(self: ChunkInternal, entity: number): boolean
	if typeof(entity) ~= "number" then
		warn(`Chunk ({self.chunkX}, {self.chunkZ}): Attempted to add invalid entity`)
		return false
	end

	if self._entities[entity] then
		return false
	end

	self._entities[entity] = true
	self._entityCount += 1

	return true
end

local function removeEntity(self: ChunkInternal, entity: number): boolean
	if typeof(entity) ~= "number" then
		return false
	end

	if not self._entities[entity] then
		return false
	end

	self._entities[entity] = nil
	self._entityCount -= 1

	return true
end

local function addPlayer(self: ChunkInternal, player: Player): boolean
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		warn(`Chunk ({self.chunkX}, {self.chunkZ}): Attempted to add invalid player`)
		return false
	end

	if self._players[player] then
		return false
	end

	self._players[player] = true
	self._playerCount += 1

	return true
end

local function removePlayer(self: ChunkInternal, player: Player): boolean
	if typeof(player) ~= "Instance" then
		return false
	end

	if not self._players[player] then
		return false
	end

	self._players[player] = nil
	self._playerCount -= 1
	return true
end

local function hasEntity(self: ChunkInternal, entity: number): boolean
	return self._entities[entity] == true
end

local function hasPlayer(self: ChunkInternal, player: Player): boolean
	return self._players[player] == true
end

local function getEntities(self: ChunkInternal): {[number]: boolean}
	return self._entities
end

local function getPlayers(self: ChunkInternal): {[Player]: boolean}
	return self._players
end

local function getEntityCount(self: ChunkInternal): number
	return self._entityCount
end

local function getPlayerCount(self: ChunkInternal): number
	return self._playerCount
end

local function isEmpty(self: ChunkInternal): boolean
	return self._entityCount == 0 and self._playerCount == 0
end

local function new(chunkX: number, chunkZ: number): ChunkObject?
	if typeof(chunkX) ~= "number" or typeof(chunkZ) ~= "number" then
		warn("ChunkClass.new: Invalid chunk coordinates")
		return nil
	end

	local self: ChunkInternal = {
		chunkX = chunkX,
		chunkZ = chunkZ,

		_entities = {},
		_players = {},
		_entityCount = 0,
		_playerCount = 0,

		addEntity = addEntity,
		removeEntity = removeEntity,
		addPlayer = addPlayer,
		removePlayer = removePlayer,
		hasEntity = hasEntity,
		hasPlayer = hasPlayer,
		getEntities = getEntities,
		getPlayers = getPlayers,
		getEntityCount = getEntityCount,
		getPlayerCount = getPlayerCount,
		isEmpty = isEmpty,
	} :: any

	return self
end

return {
	new = new,
}
