local ReplicatedStorage = game:GetService("ReplicatedStorage")

local oblivis = require(ReplicatedStorage.shared.oblivis)
local ref = oblivis.ref
local systems = oblivis.systems
local components = oblivis.components

return systems.create("flushObserver", {
	update = function(world: oblivis.World, deltaTime: number)
		world:flush()
	end,

	step = "Heartbeat",
	priority = 1
})
