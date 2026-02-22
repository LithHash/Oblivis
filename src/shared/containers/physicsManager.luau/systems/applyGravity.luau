local ReplicatedStorage = game:GetService("ReplicatedStorage")

local config = require(script.Parent.Parent.config)
local oblivis = require(ReplicatedStorage.shared.oblivis)

local components = oblivis.components

return oblivis.systems.create("applyGravity", {
	update = function(world: oblivis.World, deltaTime: number)
		world:view(components.rigidBody):forEach(function(entity, rigidBody)
			if rigidBody.grounded then
				return
			end

			world:assign(entity, components.rigidBody, {
				velocity = rigidBody.velocity,
				acceleration = rigidBody.acceleration + config.GRAVITY,
				mass = rigidBody.mass,
				grounded = rigidBody.grounded,
			})
		end)
	end,

	step = "Heartbeat",
	priority = 1
})
