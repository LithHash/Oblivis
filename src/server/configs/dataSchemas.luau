local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Coppermind = require(ReplicatedStorage.packages.coppermind)

local playerDataSchema = Coppermind.registerSchema({
   	name = "PlayerData_V1",
	dataTemplate = {
		coins = 0,
	},
	migrations = {},
})

return {
    playerDataSchema = playerDataSchema
}
