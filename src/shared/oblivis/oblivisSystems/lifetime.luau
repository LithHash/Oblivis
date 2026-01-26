local ReplicatedStorage = game:GetService("ReplicatedStorage")

local oblivis = require(ReplicatedStorage.shared.oblivis)
local world = oblivis.world
local components = oblivis.components

return world:addSystem("lifetime", "update", {
	writes = {components.lifetime},
	reads = {components.lifetime}
}, function(deltaTime: number)
	for entity, lifetime in world:query(components.lifetime):iter() do
		world:deferSet(entity, components.lifetime, lifetime - deltaTime)

		if lifetime <= 0 then
			world:deferDestroy(entity)
		end
	end
end)
