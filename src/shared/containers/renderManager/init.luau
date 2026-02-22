local ReplicatedStorage = game:GetService("ReplicatedStorage")

local oblivis = require(ReplicatedStorage.shared.oblivis)
local ref = oblivis.ref
local world = oblivis.world
local collect = oblivis.collect
local systems = oblivis.systems
local components = oblivis.components

local destroyedEntities = collect.new()
local mappedInstances: { [number]: Model } = {}

local function _start()
	world:onAssign(components.renderData, function(entity, renderData)
	    mappedInstances[entity] = renderData.instance
	end)

	world:onRemove(components.renderData, function(entity)
	    destroyedEntities:push(entity)
	end)

	world:onDestroy(function(entity: number)
	    destroyedEntities:push(entity)
	end)

	local renderParent = oblivis.systems.create("renderParent", {
		update = function(world: oblivis.World, deltaTime: number)
			world:view(components.renderData):forEach(function(entity, renderData)
				local renderInstance: Instance = renderData.instance
				local parentInstance: Instance? = renderData.parent

				if
					renderInstance and
					parentInstance and
					renderInstance.Parent ~= parentInstance
				then
					renderInstance.Parent = parentInstance
				end
			end)
		end,

		priority = 1,
		step = "Heartbeat"
	})

	local renderCleanup = oblivis.systems.create("renderCleanup", {
		update = function(world: oblivis.World, deltaTime: number)
			for entity in destroyedEntities:iter() do
				local instance = mappedInstances[entity]
				if instance and instance.Parent then
					instance:Destroy()
					mappedInstances[entity] = nil
				end
			end
		end,

		step = "Heartbeat",
		priority = 1
	})


	oblivis.systems.start(renderCleanup, oblivis.world)
	oblivis.systems.start(renderParent, oblivis.world)
end

return {
	_start = _start
}
