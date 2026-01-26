local ReplicatedStorage = game:GetService("ReplicatedStorage")

local oblivis = require(ReplicatedStorage.shared.oblivis)
local ref = oblivis.ref
local world = oblivis.world
local components = oblivis.components

return world:addSystem("clearRef", "update", {
	writes = {components.lifetime},
	reads = {components.lifetime}
}, function(deltaTime: number)
	local toDelete = table.create(16)
    for object, entity in ref._entityMapping do
        if not object.Parent or not world:isAlive(entity) then
            toDelete[#toDelete + 1] = object
        end
    end

    for i = 1, #toDelete do
        ref._entityMapping[toDelete[i]] = nil
    end
end)
