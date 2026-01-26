local World = require(script.Parent.world)

local components = {
    lifetime = World:component(),

    player = World:component()
}

return components
