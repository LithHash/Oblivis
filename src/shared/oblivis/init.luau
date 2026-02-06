local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local entityManager = require(script.entityManager)
local remotes = require(script.remotes)

local runContext = if RunService:IsServer() then "SERVER" else "CLIENT"
local oblivisSystems = script.oblivisSystems
local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
assert(sharedFolder and sharedFolder:IsA("Folder"), "[OBLIVIS] Shared folder not found")

local sharedContainers = sharedFolder:FindFirstChild("containers")
assert(sharedContainers and sharedContainers:IsA("Folder"), "[OBLIVIS ]Shared Containers not found")

local function loadContainers(containerFolder: Folder)
	for _, container in containerFolder:GetChildren() do
		if not container:IsA("ModuleScript") then
			continue
		end

		if container == script then
			continue
		end

		local module = require(container):: any
		if typeof(module) == "function" then
			module()
		elseif typeof(module) == "table" and module["_start"] then
			(module["_start"]:: any)()
		end
	end
end

local function loadOblivis()
	local startTime = os.clock()

	for _, moduleScript in oblivisSystems:GetChildren() do
		local system = require(moduleScript):: any

		entityManager.systems.start(system, entityManager.world)
	end

	loadContainers(sharedContainers)

	if runContext == "SERVER" then
		local containerFolder = ServerScriptService.server:FindFirstChild("containers")
		assert(containerFolder and containerFolder:IsA("Folder"), "[OBLIVIS] Server container folder not found")

		loadContainers(containerFolder)
	end

	if runContext == "CLIENT" then
		local containerFolder = ReplicatedStorage.client:FindFirstChild("containers")
		assert(containerFolder and containerFolder:IsA("Folder"), "[OBLIVIS] Client container folder not found")

		loadContainers(containerFolder)
	end

	local finishTime = os.clock()

	print(`Oblivis [{runContext}] finished loading in {(finishTime - startTime)}s`)
end

local oblivisModule = {
	loadOblivis = loadOblivis,
}

for key, value in entityManager:: any do
	oblivisModule[key] = value
end

for key, value in remotes:: any do
	oblivisModule[key] = value
end

export type Module = typeof(oblivisModule) & typeof(entityManager) & typeof(remotes)
export type World = typeof(entityManager.world)

return oblivisModule:: Module
