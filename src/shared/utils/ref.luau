local _entityMapping: {[Instance]: number} = {}

local function get(object: Instance): number?
    local entity = _entityMapping[object]

    return entity
end

local function set(object: Instance, entityId: number)
    _entityMapping[object] = entityId
end

return {
    get = get,
    set = set,

    _entityMapping = _entityMapping
}
