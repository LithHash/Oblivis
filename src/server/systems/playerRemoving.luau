local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ECS = require(ReplicatedStorage.shared.configs.ecs)
local Coppermind = require(ReplicatedStorage.packages.coppermind)
local DataSchemas = require(ServerScriptService.server.configs.dataSchemas)

local ref = ECS.ref
local world = ECS.world
local collector = ECS.collect
local playerDataSchema = DataSchemas.playerDataSchema

local playerRemoving = collector.new(Players.PlayerRemoving, { max = 256, dropOldest = false })

local function onPlayerRemoving(player: Player)
    Coppermind.unloadStore(playerDataSchema, tostring(player.UserId))

    local entity = ref.get(player)
    if entity then
        world:destroy(entity)
    end
end

return {
    systemName = "playerRemoving",
    systemPhase = "update",
    dependencies = {
        writes = {},
        reads = {}
    },
    callback = function(deltaTime: number)
        playerRemoving:each(function(player: Player)
            onPlayerRemoving(player)
        end)
    end
}
