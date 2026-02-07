local world = require(script.Parent.world)

local components = {
    lifetime = world:component(), --// number
    player = world:component(), --// Player

    chunk = world:component() --// {x: number, z: number}
}

return table.freeze(components)
