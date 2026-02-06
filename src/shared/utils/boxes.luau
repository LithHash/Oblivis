local ReplicatedStorage = game:GetService("ReplicatedStorage")

local oblivis = require(ReplicatedStorage.shared.oblivis)
local world = oblivis.world

export type BoxOpts = {
	min: Vector3,
	max: Vector3,
	initialPosition: Vector3?,
}

export type BoxObject = BoxOpts & {
	position: Vector3,
	getWorldMin: (self: BoxObject) -> Vector3,
	getWorldMax: (self: BoxObject) -> Vector3,
	move: (self: BoxObject, delta: Vector3) -> (),
	setPosition: (self: BoxObject, pos: Vector3) -> (),
	intersects: (self: BoxObject, other: BoxObject) -> boolean,
	containsPoint: (self: BoxObject, point: Vector3) -> boolean,
}

local function isPointInBox(hitbox: BoxObject, pointLocation: Vector3): boolean
	local worldMinimum = hitbox:getWorldMin()
	local worldMaximum = hitbox:getWorldMax()

	return pointLocation.X >= worldMinimum.X and pointLocation.X <= worldMaximum.X
		and pointLocation.Y >= worldMinimum.Y and pointLocation.Y <= worldMaximum.Y
		and pointLocation.Z >= worldMinimum.Z and pointLocation.Z <= worldMaximum.Z
end

local function doBoxesIntersect(firstHitbox: BoxObject, secondHitbox: BoxObject): boolean
	local firstMinimum = firstHitbox:getWorldMin()
	local firstMaximum = firstHitbox:getWorldMax()
	local secondMinimum = secondHitbox:getWorldMin()
	local secondMaximum = secondHitbox:getWorldMax()

	return (firstMinimum.X <= secondMaximum.X and firstMaximum.X >= secondMinimum.X)
		and (firstMinimum.Y <= secondMaximum.Y and firstMaximum.Y >= secondMinimum.Y)
		and (firstMinimum.Z <= secondMaximum.Z and firstMaximum.Z >= secondMinimum.Z)
end

local function getWorldMin(hitbox: BoxObject): Vector3
	return hitbox.position + hitbox.min
end

local function getWorldMax(hitbox: BoxObject): Vector3
	return hitbox.position + hitbox.max
end

local function move(hitbox: BoxObject, movementDelta: Vector3)
	hitbox.position = hitbox.position + movementDelta
end

local function setPosition(hitbox: BoxObject, newPosition: Vector3)
	hitbox.position = newPosition
end

local function newBox(options: BoxOpts): BoxObject
	local self: BoxObject = {
		min = options.min,
		max = options.max,
		position = options.initialPosition or Vector3.zero,

		getWorldMin = getWorldMin,
		getWorldMax = getWorldMax,
		move = move,
		setPosition = setPosition,
		intersects = doBoxesIntersect,
		containsPoint = isPointInBox,
	} :: any

	return self
end

local function newBoxFromLocation(centerPosition: Vector3, totalSize: Vector3): BoxObject
	local halfSize = totalSize / 2
	return newBox({
		min = -halfSize,
		max = halfSize,
		initialPosition = centerPosition,
	})
end

local function newBoxFromCorners(firstCorner: Vector3, secondCorner: Vector3): BoxObject
	local minimumCorner = Vector3.new(
		math.min(firstCorner.X, secondCorner.X),
		math.min(firstCorner.Y, secondCorner.Y),
		math.min(firstCorner.Z, secondCorner.Z)
	)
	local maximumCorner = Vector3.new(
		math.max(firstCorner.X, secondCorner.X),
		math.max(firstCorner.Y, secondCorner.Y),
		math.max(firstCorner.Z, secondCorner.Z)
	)

	return newBox({
		min = minimumCorner,
		max = maximumCorner,
		initialPosition = Vector3.zero,
	})
end

return table.freeze({
	newBox = newBox,
	newBoxFromLocation = newBoxFromLocation,
	newBoxFromCorners = newBoxFromCorners,
})
