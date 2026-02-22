local ReplicatedStorage = game:GetService("ReplicatedStorage")

local config = require(script.Parent.Parent.config)
local oblivis = require(ReplicatedStorage.shared.oblivis)
local components = oblivis.components

local mapFolder = workspace:FindFirstChild("Map")
if not mapFolder then
	mapFolder = Instance.new("Folder")
	mapFolder.Name = "Map"
	mapFolder.Parent = workspace
end

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include
raycastParams.FilterDescendantsInstances = {mapFolder}

return oblivis.systems.create("groundDetection", {
	update = function(world: oblivis.World, deltaTime: number)
	    world:view(
	        components.rigidBody,
	        components.transform,
	        components.hitbox
	    ):forEach(function(entity, rigidBody, transform, hitbox)
	        local pos = transform.position
	        local halfHeight = (hitbox.max.Y - hitbox.min.Y) / 2

	        local rayOrigin = pos
	        local rayLength = halfHeight + config.GROUND_SKIN_WIDTH
	        local rayDirection = Vector3.new(0, -rayLength, 0)

	        local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	        local isGrounded = result ~= nil

	        local newVelocityY = rigidBody.velocity.Y
	        local newPositionY = pos.Y

	        if isGrounded then
	            newPositionY = result.Position.Y + halfHeight
	            if rigidBody.velocity.Y < 0 then
	                newVelocityY = 0
	            end
	        end

	        if isGrounded ~= rigidBody.grounded or isGrounded then
	            world:assign(entity, components.transform, {
	                position = Vector3.new(pos.X, newPositionY, pos.Z),
	                rotation = transform.rotation,
	            })

	            world:assign(entity, components.rigidBody, {
	                velocity = Vector3.new(
						rigidBody.velocity.X,
						newVelocityY,
						rigidBody.velocity.Z
					),
	                acceleration = rigidBody.acceleration,
	                mass = rigidBody.mass,
	                grounded = isGrounded,
	            })
	        end
	    end)
	end,

	step = "Heartbeat",
	priority = 3,
})
