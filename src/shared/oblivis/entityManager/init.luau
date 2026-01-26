local ref = require(script.utils.ref)
local world = require(script.configs.world)
local collect = require(script.utils.collect)
local components = require(script.configs.components)

return {
	ref = ref,
	world = world,
	collect = collect,
	components = components
}
