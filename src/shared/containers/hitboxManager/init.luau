--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local oblivis = require(ReplicatedStorage.shared.oblivis)
local world = oblivis.world
local components = oblivis.components
local systems = oblivis.systems

local chunkManager = require(script.Parent.chunkManager)
local boxes = require(ReplicatedStorage.shared.utils.boxes)

export type HitResult = {
	entity: number,
	distance: number,
	hitPosition: Vector3,
}

export type CastOptions = {
	filter: ((entity: number) -> boolean)?,
	chunkRadius: number?,
}

export type ActiveHitboxOptions = {
	onHit: (hit: HitResult) -> (),
	filter: ((entity: number) -> boolean)?,
	chunkRadius: number?,
	lifetime: number?,
}

export type ActiveHitbox = {
	setPosition: (self: ActiveHitbox, position: Vector3) -> (),
	setHitbox: (self: ActiveHitbox, newHitbox: boxes.HitboxComponent) -> (),
	destroy: (self: ActiveHitbox) -> (),
	isAlive: (self: ActiveHitbox) -> boolean,
}

type ActiveHitboxInternal = ActiveHitbox & {
	_hitbox: boxes.HitboxComponent,
	_position: Vector3,
	_alreadyHit: { [number]: boolean },
	_onHit: (hit: HitResult) -> (),
	_filter: ((entity: number) -> boolean)?,
	_chunkRadius: number,
	_lifetime: number?,
	_elapsed: number,
	_destroyed: boolean,
}

local activeHitboxes: { ActiveHitboxInternal } = {}

local function buildHitResult(
	candidateEntity: number,
	candidateTransform: {position: Vector3, rotation: CFrame},
	sourcePosition: Vector3
): HitResult
	return {
		entity = candidateEntity,
		distance = (candidateTransform.position - sourcePosition).Magnitude,
		hitPosition = candidateTransform.position,
	}
end

local function gatherHits(
	sourceHitbox: boxes.HitboxComponent,
	sourcePosition: Vector3,
	chunkRadius: number,
	filter: ((entity: number) -> boolean)?,
	alreadyHit: { [number]: boolean }?
): { HitResult }
	local results: { HitResult } = {}
	local resultCount = 0

	local candidates = chunkManager.queryPosition(
		sourcePosition,
		chunkRadius,
		components.hitbox,
		components.transform
	)

	candidates:forEach(function(
		candidateEntity: number,
		candidateHitbox: boxes.HitboxComponent,
		candidateTransform: {position: Vector3, rotation: CFrame}
	)
		if alreadyHit and alreadyHit[candidateEntity] then
			return
		end

		if filter and not filter(candidateEntity) then
			return
		end

		if boxes.intersects(sourceHitbox, sourcePosition, candidateHitbox, candidateTransform.position) then
			resultCount += 1
			results[resultCount] = buildHitResult(candidateEntity, candidateTransform, sourcePosition)
		end
	end)

	return results
end

local function cast(
	sourceHitbox: boxes.HitboxComponent,
	sourcePosition: Vector3,
	options: CastOptions?
): { HitResult }
	local resolvedOptions = options or {}:: any

	return gatherHits(
		sourceHitbox,
		sourcePosition,
		resolvedOptions.chunkRadius or 1,
		resolvedOptions.filter,
		nil
	)
end

local function create(
	sourceHitbox: boxes.HitboxComponent,
	initialPosition: Vector3,
	options: ActiveHitboxOptions
): ActiveHitbox
	local self: ActiveHitboxInternal = {
		_hitbox = sourceHitbox,
		_position = initialPosition,
		_alreadyHit = {},
		_onHit = options.onHit,
		_filter = options.filter,
		_chunkRadius = options.chunkRadius or 1,
		_lifetime = options.lifetime,
		_elapsed = 0,
		_destroyed = false,

		setPosition = function(activeHitbox: ActiveHitbox, position: Vector3)
			(activeHitbox :: ActiveHitboxInternal)._position = position
		end,

		setHitbox = function(activeHitbox: ActiveHitbox, newHitbox: boxes.HitboxComponent)
			(activeHitbox :: ActiveHitboxInternal)._hitbox = newHitbox
		end,

		destroy = function(activeHitbox: ActiveHitbox)
			(activeHitbox :: ActiveHitboxInternal)._destroyed = true
		end,

		isAlive = function(activeHitbox: ActiveHitbox): boolean
			return not (activeHitbox :: ActiveHitboxInternal)._destroyed
		end,
	} :: any

	activeHitboxes[#activeHitboxes + 1] = self

	return self
end

local function update(world: oblivis.World, deltaTime: number)
	local aliveCount = 0

	for index = 1, #activeHitboxes do
		local activeHitbox = activeHitboxes[index]

		if activeHitbox._destroyed then
			continue
		end

		if activeHitbox._lifetime then
			activeHitbox._elapsed += deltaTime
			if activeHitbox._elapsed >= activeHitbox._lifetime then
				activeHitbox._destroyed = true
				continue
			end
		end

		local hits = gatherHits(
			activeHitbox._hitbox,
			activeHitbox._position,
			activeHitbox._chunkRadius,
			activeHitbox._filter,
			activeHitbox._alreadyHit
		)

		for hitIndex = 1, #hits do
			local hit = hits[hitIndex]
			activeHitbox._alreadyHit[hit.entity] = true
			activeHitbox._onHit(hit)
		end

		aliveCount += 1
		activeHitboxes[aliveCount] = activeHitbox
	end

	for tailIndex = aliveCount + 1, #activeHitboxes do
		activeHitboxes[tailIndex] = nil
	end
end

local function queryPoint(targetPoint: Vector3, chunkRadius: number?): { HitResult }
	local results: { HitResult } = {}
	local resultCount = 0

	local candidates = chunkManager.queryPosition(
		targetPoint,
		chunkRadius or 1,
		components.hitbox,
		components.transform
	)

	candidates:forEach(function(
		candidateEntity: number,
		candidateHitbox: boxes.HitboxComponent,
		candidateTransform: {position: Vector3, rotation: CFrame}
	)
		if boxes.containsPoint(candidateHitbox, candidateTransform.position, targetPoint) then
			resultCount += 1
			results[resultCount] = buildHitResult(candidateEntity, candidateTransform, targetPoint)
		end
	end)

	return results
end

local function _start()
	systems.create("updateHitboxes", {
		update = update,
		step = "Heartbeat",
		priority = 10
	})
end

return table.freeze({
	cast = cast,
	create = create,
	update = update,
	queryPoint = queryPoint,

	_start = _start,
})
