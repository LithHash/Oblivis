local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local oblivis = require(ReplicatedStorage.shared.oblivis)
local systems = oblivis.systems
local components = oblivis.components
local collect = oblivis.collect

local playersRemoved = collect.new(Players.PlayerRemoving)

return systems.create("playerRemoved", {
	update = function(world: oblivis.World, deltaTime: number)
		for player: Player in playersRemoved:iter() do
			print(`Player: {player} detected in playerRemoved`)
		end
	end,

	step = "Heartbeat",
	priority = 10,
})
