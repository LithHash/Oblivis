local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AlloyECS = require(ReplicatedStorage.packages.alloyecs)
local World = require(script.world)
local Components = require(script.components)
local Ref = require(ReplicatedStorage.shared.utils.ref)
local Collect = require(ReplicatedStorage.shared.utils.collect)

return {
    world = World,
    ecs = AlloyECS,
    components = Components,
    ref = Ref,
    collect = Collect
}
