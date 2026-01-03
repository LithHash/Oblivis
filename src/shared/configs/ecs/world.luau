local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AlloyECS = require(ReplicatedStorage.packages.alloyecs)

return require(ReplicatedStorage.packages.alloyecs).createWorld():: AlloyECS.World
