local ReplicatedStorage = game:GetService("ReplicatedStorage")

local alloyEcs = require(ReplicatedStorage.packages.alloyecs)

local world = alloyEcs.world()

return world
