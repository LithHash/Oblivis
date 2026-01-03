local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ECS = require(ReplicatedStorage.shared.configs.ecs)
local Coppermind = require(ReplicatedStorage.packages.coppermind)
local DataSchemas = require(ServerScriptService.server.configs.dataSchemas)

local ref = ECS.ref
local world = ECS.world
local collector = ECS.collect
local components = ECS.components
local playerDataSchema = DataSchemas.playerDataSchema

local playerAdded = collector.new(Players.PlayerAdded, { max = 256, dropOldest = false })

local function onPlayerAdded(player: Player)
    Coppermind.loadStore(playerDataSchema, tostring(player.UserId), {
        sessionLocked = true,
        autoSave = 30
    })

    local playerEntity = world:entity()
    world:set(playerEntity, components.player, player)

    ref.set(player, playerEntity)
end

for _, player in Players:GetPlayers() do
   onPlayerAdded(player)
end

return {
    systemName = "playerAdded",
    systemPhase = "update",
    dependencies = {
        writes = {
            components.player
        },
        reads = {}
    },
    callback = function(deltaTime: number)
        playerAdded:each(function(player: Player)
            onPlayerAdded(player)
        end)
    end
}
