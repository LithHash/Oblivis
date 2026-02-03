local ReplicatedStorage = game:GetService("ReplicatedStorage")

local alloyEcs = require(ReplicatedStorage.packages.alloyecs)
local observers = require(script.Parent.Parent.utils.observers)

return observers.wrap(alloyEcs)
