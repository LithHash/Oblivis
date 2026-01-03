local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ECS = require(ReplicatedStorage.shared.configs.ecs)

local ref = ECS.ref
local world = ECS.world

return {
    systemName = "clearRef",
    systemPhase = "postUpdate",
    dependencies = {},
    callback = function(deltaTime: number)
        local toDelete = table.create(16)
        for object, entity in ref._entityMapping do
            if not object.Parent or not world:isAlive(entity) then
                toDelete[#toDelete + 1] = object
            end
        end

        for i = 1, #toDelete do
            ref._entityMapping[toDelete[i]] = nil
        end
    end
}
