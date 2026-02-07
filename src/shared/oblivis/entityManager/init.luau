local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ref = require(script.utils.ref)
local world = require(script.configs.world)
local systems = require(script.utils.systems)
local collect = require(script.utils.collect)
local components = require(script.configs.components)
local alloyEcs = require(ReplicatedStorage.packages.alloyecs)

return table.freeze({
	ref = ref,
	world = world,
	systems = systems,
	collect = collect,
	components = components,
	alloyEcs = alloyEcs
})
