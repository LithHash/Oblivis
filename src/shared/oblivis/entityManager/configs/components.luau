local world = require(script.Parent.world)

local components = {
    lifetime = world:component(),
    player = world:component()
}

return components
