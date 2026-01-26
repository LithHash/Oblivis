local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local oblivis = require(ReplicatedStorage.shared.oblivis)
local world = oblivis.world
local components = oblivis.components
local collect = oblivis.collect

local playersAdded = collect.new(Players.PlayerAdded)

return world:addSystem("playerAdded", "update", {
	writes = {},
	reads = {}
}, function(deltaTime: number)
	for player: Player in playersAdded:iter() do
		print(`Player: {player} detected in playerAdded`)
	end
end)
