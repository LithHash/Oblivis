local ReplicatedStorage = game:GetService("ReplicatedStorage")

local oblivis = require(ReplicatedStorage.shared.oblivis)
local coppermind = require(ReplicatedStorage.packages.coppermind)
local dataTemplate = require(script.dataTemplate)

local world = oblivis.world
local components = oblivis.components

local playerStore = coppermind.new(world, "PlayerData", dataTemplate)
playerStore:mapComponents(components:: any)

return table.freeze({playerStore = playerStore})
