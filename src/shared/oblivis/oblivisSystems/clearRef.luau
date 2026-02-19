local ReplicatedStorage = game:GetService("ReplicatedStorage")

local oblivis = require(ReplicatedStorage.shared.oblivis)
local ref = oblivis.ref
local systems = oblivis.systems
local components = oblivis.components

return systems.create("clearRef", {
	update = function(world: oblivis.World, deltaTime: number)
		local toDelete = {}
	    for object, entity in ref._entityMapping do
	        if not object.Parent or not world:exists(entity) then
	            toDelete[#toDelete + 1] = object
	        end
	    end

    	for i = 1, #toDelete do
    	    ref._entityMapping[toDelete[i]:: any] = nil
    	end
	end,

	step = "Heartbeat",
	priority = 1
})
