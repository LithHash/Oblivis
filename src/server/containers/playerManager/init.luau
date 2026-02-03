local ReplicatedStorage = game:GetService("ReplicatedStorage")

local oblivis = require(ReplicatedStorage.shared.oblivis)
local maid = require(ReplicatedStorage.shared.utils.maid)
local signal = require(ReplicatedStorage.shared.utils.signal)

local world = oblivis.world
local components = oblivis.components

export type PlayerObject = {
	entity: number,
	states: {[string]: any},
	maid: maid.MaidObject,

	destroy: (self: PlayerObject) -> ()
}

export type PlayerCacheSchema = {[Player]: PlayerObject}

local _playerCache: PlayerCacheSchema = {}
local playerAddedSignal = signal.new()

local function destroy(self: PlayerObject)
	self.maid:destroy()
end

local function new(player: Player): PlayerObject
	if _playerCache[player] then
		return _playerCache[player]
	end

	local self: PlayerObject = {
		entity = world:entity(),
		states = {},
		maid = maid.new(),

		destroy = destroy
	}

	world:set(self.entity, components.player, player)

	self.maid:add(function()
		if _playerCache[player] then
			_playerCache[player] = nil
		end

		table.clear(self:: any)
		self = nil:: any
	end)

	playerAddedSignal:fire(self)
	_playerCache[player] = self

	return self
end

local function get(player: Player): PlayerObject?
	return _playerCache[player]
end

local function connectPlayerObject(callback: (playerObject: PlayerObject) -> ())
	playerAddedSignal:listen(callback)
end

local function _start()
	require(script.systems.playerAdded)
	require(script.systems.playerRemoved)
end

return {
	new = new,
	get = get,
	connectPlayerObject = connectPlayerObject,

	_start = _start,
}
