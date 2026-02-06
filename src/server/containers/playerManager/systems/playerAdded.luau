local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local oblivis = require(ReplicatedStorage.shared.oblivis)
local systems = oblivis.systems
local components = oblivis.components
local collect = oblivis.collect

local playersAdded = collect.new(Players.PlayerAdded)

return systems.create("playerAdded", {
	update = function(world: oblivis.World, deltaTime: number)
		for player: Player in playersAdded:iter() do
			print(`Player: {player} detected in playerAdded`)
		end
	end,

	step = "Heartbeat",
	priority = 10,
})
