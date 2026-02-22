local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.packages.packet)
local packetTypes = Packet.types

return {
    oblivis = {
        getDataLoaded = Packet.request("getDataLoaded", {
            schema = {},
            direction = "toServer",
            returns = {}
        }),

        sendSnapshot = Packet.event("sendSnapshot", {
		   	schema = { Packet.struct({
					currentTime = packetTypes.number,
					sequenceId = packetTypes.number,
					command = Packet.struct({
						commandName = packetTypes.string,
						step = packetTypes.variant, --// "Begin" "End" "Update" "Cancel"
						args = packetTypes.variant
					})
				})
			},
			direction = "toServer",
			polling = true
        })
    }
}
