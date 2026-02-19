--!optimize 2
--!native
--!strict

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local server = require(script.server)
local client = require(script.client)
local oblivis = require(ReplicatedStorage.shared.oblivis)

export type ServerReplicationManager = server.ServerReplicationManager
export type ClientReplicationManager = client.ClientReplicationManager

local remotes = oblivis.remotes
local world = oblivis.world
local components = oblivis.components
local systems = oblivis.systems

local reliable = remotes.oblivis.reliableReplication
local unreliable = remotes.oblivis.unreliableReplication

local events = {
	reliable = reliable,
	unreliable = unreliable,
}

local function new(world: any): ServerReplicationManager & ClientReplicationManager
	if RunService:IsServer() then
		return server.new(world, events):: any
	end

	return client.new(world, events):: any
end

local manager = new(world)

return {
	manager = manager,
	_start = function()
		local flushReplication = systems.create("flushReplication", {
			update = function()
				manager:flush()
			end,

			step = "Heartbeat",
			priority = 100
		})

		systems.start(flushReplication, world)
	end
}
