--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local oblivis = require(ReplicatedStorage.shared.oblivis)
local components = oblivis.components
local chunkManager = require(script.Parent.Parent)

return function(world, deltaTime)
    for entity, transform in world:view(components.transform) do
        chunkManager.updateEntity(entity, transform.position)
    end
end
