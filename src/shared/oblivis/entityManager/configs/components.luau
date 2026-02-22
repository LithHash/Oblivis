local ReplicatedStorage = game:GetService("ReplicatedStorage")

local alloyEcs = require(ReplicatedStorage.packages.alloyecs)
local world = require(script.Parent.world)

local components = {
    lifetime = world:component():: alloyEcs.ComponentId<number>,
    player = world:component():: alloyEcs.ComponentId<Player>,

    renderData = world:component():: alloyEcs.ComponentId<{
    	instance: Instance,
     	parent: Instance?
    }>,
    transform = world:component():: alloyEcs.ComponentId<{position: Vector3, rotation: CFrame}>,
    rigidBody = world:component():: alloyEcs.ComponentId<{
    	velocity: Vector3,
    	acceleration: Vector3,
    	mass: number,
    	grounded: boolean
    }>,
    hitbox = world:component():: alloyEcs.ComponentId<{min: Vector3, max: Vector3}>,
    chunk = world:component():: alloyEcs.ComponentId<{x: number, z: number}>
}

return table.freeze(components)
