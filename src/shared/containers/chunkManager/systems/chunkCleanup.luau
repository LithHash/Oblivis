--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local chunkManager = require(script.Parent.Parent)

local CLEANUP_INTERVAL = 30
local elapsed = 0

return function(world, deltaTime: number)
    elapsed += deltaTime

    if elapsed <= CLEANUP_INTERVAL then
	    return
    end

    elapsed = 0
    local cleaned = chunkManager.cleanupEmptyChunks()
    if cleaned > 0 then
        print(`[ChunkManager] Cleaned up {cleaned} empty chunks`)
    end
end
