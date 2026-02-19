--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local oblivis = require(ReplicatedStorage.shared.oblivis)
local ref = oblivis.ref
local world = oblivis.world
local collect = oblivis.collect
local systems = oblivis.systems
local components = oblivis.components

local destroyedEntities = collect.new()
local mappedInstances: { [number]: Model } = {}

world:onAssign(components.renderData, function(entity, model)
    mappedInstances[entity] = model
end)

world:onRemove(components.renderData, function(entity)
    destroyedEntities:push(entity)
end)

world:onDestroy(function(entity: number)
    destroyedEntities:push(entity)
end)

return systems.create("entityJanitor", {
	update = function(world: oblivis.World, deltaTime: number)
		for entity in destroyedEntities:iter() do
			local instance = mappedInstances[entity]
			if instance then
				instance:Destroy()
				mappedInstances[entity] = nil
			end
		end
	end,

	step = "Heartbeat",
	priority = 1
})
