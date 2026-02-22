local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TextChatService = game:GetService("TextChatService")

local characterManager = require(script.Parent.characterManager)
local oblivis = require(ReplicatedStorage.shared.oblivis)
local maid = require(ReplicatedStorage.shared.utils.maid)
local signal = require(ReplicatedStorage.shared.utils.signal)
local dataManager = require(ServerScriptService.server.containers.dataManager)
local chunkManager = require(ReplicatedStorage.shared.containers.chunkManager)
local replicationManager = require(ReplicatedStorage.shared.containers.replicationManager)

local world = oblivis.world
local components = oblivis.components
local systems = oblivis.systems
local collect = oblivis.collect

local manager = replicationManager.manager
local playerStore = dataManager.playerStore

export type PlayerObject = {
	entity: number,
	states: {[string]: any},
	maid: maid.MaidObject,

	destroy: (self: PlayerObject) -> ()
}

export type PlayerCacheSchema = {[Player]: PlayerObject}

local _playerCache: PlayerCacheSchema = {}
local playerAddedSignal = signal.new()

local function connectPlayerObject(callback: (playerObject: PlayerObject) -> ())
	playerAddedSignal:listen(callback)
end

local function destroy(self: PlayerObject)
	self.maid:destroy()
end

local function get(player: Player): PlayerObject?
	return _playerCache[player]
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

	playerStore:loadSession(player, self.entity):andThen(function()
		print("Data loaded.")

		characterManager.createHumanoidModel(self.entity):listen(function(characterCreated: Model)
			print("Created character for player:", characterCreated)
		end)
	end)

	world:assign(self.entity, components.player, player)
	manager:replicateEntity(self.entity, {components.player})

	self.maid:add(function()
		if _playerCache[player] then
			_playerCache[player] = nil
		end

		manager:stopReplicating(self.entity)
		chunkManager.removeEntity(self.entity)
		chunkManager.removePlayer(player)
		world:destroy(self.entity)

		table.clear(self:: any)
		self = nil:: any
	end)

	playerAddedSignal:fire(self)
	_playerCache[player] = self

	return self
end

return table.freeze({
	new = new,
	get = get,
	connectPlayerObject = connectPlayerObject,

	_start = function()
		local playersAdded = collect.new(Players.PlayerAdded)
		local playersRemoved = collect.new(Players.PlayerRemoving)

		local addedSystem = systems.create("playerAdded", {
			update = function(world: oblivis.World, deltaTime: number)
				for player: Player in playersAdded:iter() do
					new(player)
				end
			end,

			step = "Heartbeat",
			priority = 10,
		})

		local removedSystem = systems.create("playerRemoved", {
			update = function(world: oblivis.World, deltaTime: number)
				for player: Player in playersRemoved:iter() do
					local playerObject = get(player)
					if not playerObject then
						continue
					end

					playerObject:destroy()
				end
			end,

			step = "Heartbeat",
			priority = 10,
		})

		local playerCharacterAttach = systems.create("playerCharacterAttach", {
			update = function(world: oblivis.World, deltaTime: number)
				world:view(components.player, components.renderData):forEach(function(
					entity: number,
					player: Player,
					renderData: {instance: Instance}
				)
					player.Character = renderData.instance
				end)
			end,

			step = "Heartbeat",
			priority = 10,
		})


		oblivis.systems.start(addedSystem, world)
		oblivis.systems.start(removedSystem, world)
		oblivis.systems.start(playerCharacterAttach, world)
	end,
})
