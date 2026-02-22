local ReplicatedStorage = game:GetService("ReplicatedStorage")

local oblivis = require(ReplicatedStorage.shared.oblivis)

local components = oblivis.components

return oblivis.systems.create("integrateVelocity", {
	update = function(world: oblivis.World, deltaTime: number)
		world:view(components.rigidBody, components.transform):forEach(function(
			entity,
			rigidBody,
			transform
		)
			local newVelocity = rigidBody.velocity + rigidBody.acceleration * deltaTime
			local newPosition = transform.position + newVelocity * deltaTime

			world:assign(entity, components.transform, {
				position = newPosition,
				rotation = transform.rotation,
			})

			world:assign(entity, components.rigidBody, {
				velocity = newVelocity,
				acceleration = Vector3.zero,
				mass = rigidBody.mass,
				grounded = rigidBody.grounded,
			})
		end)
	end,

	step = "Heartbeat",
	priority = 2,
})
