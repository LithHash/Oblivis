local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ECS = require(ReplicatedStorage.shared.configs.ecs)

local world = ECS.world
local serverFolder = script.Parent
local preloadFunctionsFolder = serverFolder.preloadFunctions
local loadedFunctionsFolder = serverFolder.loadedFunctions
local serverSystemsFolder = serverFolder.systems
local serverContainersFolder = serverFolder.containers

local sharedFolder = ReplicatedStorage.shared
local sharedSystemsFolder = sharedFolder.systems

for _, module in preloadFunctionsFolder:GetChildren() do
    local success, error = pcall(function()
        return require(module)()
    end)

    if not success then
        warn(`[SERVER ENTRY-POINT] {module.Name} failed to preload properly. {error}`)
    end
end

for _, module in loadedFunctionsFolder:GetChildren() do
    local success, error = pcall(function()
        return require(module)()
    end)

    if not success then
        warn(`[SERVER ENTRY-POINT] {module.Name} failed to load properly. {error}`)
    end
end

for _, systemModule in serverSystemsFolder:GetChildren() do
    local module = require(systemModule)

    world:addSystem(module.systemName, module.systemPhase, module.dependencies, module.callback)
end

for _, systemModule in sharedSystemsFolder:GetChildren() do
    local module = require(systemModule)

    world:addSystem(module.systemName, module.systemPhase, module.dependencies, module.callback)
end

RunService.Heartbeat:Connect(function(deltaTime: number)
    world:step(deltaTime)
end)


for _, containerFolder in serverContainersFolder:GetChildren() do
    local containerModule: ModuleScript? = containerFolder:FindFirstChild(`{containerFolder.Name}Manager`)
    if not containerModule then
        warn("Container Module not found for", containerFolder.Name)
        continue
    end

    local container = require(containerModule)
    local success, error = pcall(function()
        return container['containerInit']()
    end)

    if not success then
        warn(`Container {containerFolder.Name} failed to initialize. {error}`)
        continue
    end
end
