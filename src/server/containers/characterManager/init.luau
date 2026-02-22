local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local oblivis = require(ReplicatedStorage.shared.oblivis)
local signal = require(ReplicatedStorage.shared.utils.signal)

local world = oblivis.world
local components = oblivis.components

export type ModelOptions = {
	description: HumanoidDescription?,
	rigType: Enum.HumanoidRigType?,
	parent: Instance?,
}

local CONFIG = {
	rigType = Enum.HumanoidRigType.R6,
	rootPartAnchored = true,
	evaluateStateMachine = false,
	displayDistanceType = Enum.HumanoidDisplayDistanceType.None,
	charactersFolder = {
		name = "Characters",
		parent = workspace,
	},
}

local function getOrCreateFolder(name: string, parent: Instance): Folder
	return (parent:FindFirstChild(name):: Folder) or (function(): Folder
		local folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
		return folder
	end)()
end

local CHARACTERS_FOLDER = getOrCreateFolder(
	CONFIG.charactersFolder.name,
	CONFIG.charactersFolder.parent
)

local function configureRootPart(model: Model)
	local rootPart = model:FindFirstChild("HumanoidRootPart"):: BasePart
	if not rootPart then
		return
	end

	model.PrimaryPart = rootPart
	rootPart.Anchored = CONFIG.rootPartAnchored
end

local function configureHumanoid(model: Model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid.EvaluateStateMachine = CONFIG.evaluateStateMachine
	humanoid.DisplayDistanceType = CONFIG.displayDistanceType

	if not humanoid:FindFirstChild("Animator") then
		Instance.new("Animator").Parent = humanoid
	end
end

local function configureModel(model: Model)
	configureRootPart(model)
	configureHumanoid(model)
end

local function createHumanoidModel(entity: number, options: ModelOptions?): signal.SignalObject
	local opts = options or {}:: ModelOptions
	local createdSignal = signal.new()

	local thread = coroutine.create(function()
		local model = Players:CreateHumanoidModelFromDescriptionAsync(
			opts.description or Instance.new("HumanoidDescription"),
			opts.rigType or CONFIG.rigType
		)

		configureModel(model)

		world:assign(entity, components.rigidBody, {
			velocity = Vector3.zero,
			acceleration = Vector3.zero,
			mass = 0,
			grounded = true,
		})

		world:assign(entity, components.transform, {
			position = Vector3.zero,
			rotation = CFrame.new(0, 0, 0)
		})

		world:assign(entity, components.hitbox, {
			min = Vector3.new(-1, -3, -0.5),
			max = Vector3.new(1, 3, 0.5)
		})

		world:assign(entity, components.renderData, {
			instance = model,
			parent = opts.parent or CHARACTERS_FOLDER,
		})

		createdSignal:fire(model)
	end)

	coroutine.resume(thread)

	return createdSignal
end

return {
	createHumanoidModel = createHumanoidModel,
}
