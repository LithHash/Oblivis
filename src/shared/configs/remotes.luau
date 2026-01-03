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

        pingServer = Packet.event("PingServer", {
            schema = {},
            direction = "toServer",
            polling = true,
        }),

        pingClient = Packet.event("PingClient", {
            schema = {packetTypes.number},
            direction = "toClient",
            polling = true,
        })
    }
}
