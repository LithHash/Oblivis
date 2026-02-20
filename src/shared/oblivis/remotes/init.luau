local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.packages.packet)
local packetTypes = Packet.types

return {
    oblivis = {
        getDataLoaded = Packet.request("GetDataLoaded", {
            schema = {},
            direction = "toServer",
            returns = {}
        }),

        reliableReplication = Packet.event("ecs_replication", {
            schema = { Packet.array(Packet.struct({
                component = packetTypes.variant,
                entity = packetTypes.number,
                kind = packetTypes.string,
                value = packetTypes.variant,
            })) },
            direction = "toClient",
            polling = true,
        }),

        unreliableReplication = Packet.event("ecs_replication_fast", {
	        schema = { Packet.array(Packet.struct({
	            component = packetTypes.variant,
	            entity = packetTypes.number,
	            kind = packetTypes.string,
	            value = packetTypes.variant,
	        })) },
	        direction = "toClient",
        	unreliable = true,
        	polling = true
        }),
    }
}
