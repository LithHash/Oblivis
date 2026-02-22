local ReplicatedStorage = game:GetService("ReplicatedStorage")

local oblivis = require(ReplicatedStorage.shared.oblivis)
local world = oblivis.world
local systems = oblivis.systems

local function _start()
	for _, systemModule in script.systems:GetChildren() do
		local system = require(systemModule):: any
		if system then
			systems.start(system, world)
		end
	end
end

return {
	_start = _start
}
