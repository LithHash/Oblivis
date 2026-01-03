local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Remotes = require(ReplicatedStorage.shared.configs.remotes)
local Coppermind = require(ReplicatedStorage.packages.coppermind)
local DataSchemas = require(ServerScriptService.server.configs.dataSchemas)

local getDataLoaded = Remotes.oblivis.getDataLoaded
local playerDataSchema = DataSchemas.playerDataSchema

return function()
    getDataLoaded:handle(function(player: Player)
        repeat
            task.wait()
        until Coppermind.getStore(playerDataSchema, tostring(player.UserId)) ~= nil

        return
    end)

    print(`[SERVER] Oblivis has been loaded`)
end
