local ReplicatedStorage = game:GetService("ReplicatedStorage")

local oblivis = require(ReplicatedStorage.shared.oblivis)
local ref = oblivis.ref
local systems = oblivis.systems
local components = oblivis.components

return systems.create("clearRef", {
	update = function(world: typeof(oblivis.world), deltaTime: number)
		world:view(components.lifetime):forEach(function(entity, lifetime)
			world:assign(entity, components.lifetime, lifetime - deltaTime)

			if lifetime <= 0 then
				world:destroy(entity)
			end
		end)
	end,

	step = "Heartbeat",
	priority = 1
})
