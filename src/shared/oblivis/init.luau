local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local entityManager = require(script.entityManager)
local remotes = require(script.remotes)

local runContext = if RunService:IsServer() then "SERVER" else "CLIENT"
local oblivisSystems = script.oblivisSystems
local sharedContainers = ReplicatedStorage.shared.containers

local function loadContainers(containerFolder: Folder)
	for _, container in containerFolder:GetChildren() do
		if not container:IsA("ModuleScript") then
			continue
		end

		if container == script then
			continue
		end

		local module = require(container)
		if typeof(module) == "function" then
			module()
		elseif typeof(module) == "table" and module["start"] then
			module["start"]()
		end
	end
end

local function loadOblivis()
	local startTime = os.clock()

	for _, moduleScript in oblivisSystems:GetChildren() do
		require(moduleScript)
	end

	loadContainers(sharedContainers)

	if runContext == "SERVER" then
		local containerFolder = ServerScriptService.server.containers
		loadContainers(containerFolder)
	end

	if runContext == "CLIENT" then
		local containerFolder = ReplicatedStorage.client.containers
		loadContainers(containerFolder)
	end

	local finishTime = os.clock()

	RunService.Heartbeat:Connect(function(dt: number)
		entityManager.world:step(dt)
	end)

	print(`Oblivis [{runContext}] finished loading in {(finishTime - startTime)}s`)

end

local oblivisModule = {
	loadOblivis = loadOblivis,
}

for key, value in entityManager do
	oblivisModule[key] = value
end

for key, value in remotes do
	oblivisModule[key] = value
end

export type MODULE = typeof(oblivisModule) & typeof(entityManager) & typeof(remotes)

return oblivisModule:: MODULE
