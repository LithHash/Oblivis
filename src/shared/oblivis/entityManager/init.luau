local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ref = require(script.utils.ref)
local world = require(script.configs.world)
local collect = require(script.utils.collect)
local components = require(script.configs.components)
local alloyEcs = require(ReplicatedStorage.packages.alloyecs)

return {
	ref = ref,
	world = world,
	collect = collect,
	components = components,
	alloyEcs = alloyEcs
}
