--!strict
export type HitboxComponent = {
	min: Vector3,
	max: Vector3,
}

local function getWorldMin(hitbox: HitboxComponent, worldPosition: Vector3): Vector3
	return worldPosition + hitbox.min
end

local function getWorldMax(hitbox: HitboxComponent, worldPosition: Vector3): Vector3
	return worldPosition + hitbox.max
end

local function containsPoint(hitbox: HitboxComponent, worldPosition: Vector3, targetPoint: Vector3): boolean
	local worldMin = getWorldMin(hitbox, worldPosition)
	local worldMax = getWorldMax(hitbox, worldPosition)

	return targetPoint.X >= worldMin.X and targetPoint.X <= worldMax.X
		and targetPoint.Y >= worldMin.Y and targetPoint.Y <= worldMax.Y
		and targetPoint.Z >= worldMin.Z and targetPoint.Z <= worldMax.Z
end

local function intersects(
	hitboxA: HitboxComponent, worldPositionA: Vector3,
	hitboxB: HitboxComponent, worldPositionB: Vector3
): boolean
	local worldMinA = getWorldMin(hitboxA, worldPositionA)
	local worldMaxA = getWorldMax(hitboxA, worldPositionA)
	local worldMinB = getWorldMin(hitboxB, worldPositionB)
	local worldMaxB = getWorldMax(hitboxB, worldPositionB)

	return (worldMinA.X <= worldMaxB.X and worldMaxA.X >= worldMinB.X)
		and (worldMinA.Y <= worldMaxB.Y and worldMaxA.Y >= worldMinB.Y)
		and (worldMinA.Z <= worldMaxB.Z and worldMaxA.Z >= worldMinB.Z)
end

local function fromSize(size: Vector3): HitboxComponent
	local halfSize = size * 0.5
	return {
		min = -halfSize,
		max = halfSize,
	}
end

local function fromCorners(cornerA: Vector3, cornerB: Vector3): HitboxComponent
	return {
		min = Vector3.new(
			math.min(cornerA.X, cornerB.X),
			math.min(cornerA.Y, cornerB.Y),
			math.min(cornerA.Z, cornerB.Z)
		),
		max = Vector3.new(
			math.max(cornerA.X, cornerB.X),
			math.max(cornerA.Y, cornerB.Y),
			math.max(cornerA.Z, cornerB.Z)
		),
	}
end

return table.freeze({
	fromSize = fromSize,
	fromCorners = fromCorners,
	getWorldMin = getWorldMin,
	getWorldMax = getWorldMax,
	containsPoint = containsPoint,
	intersects = intersects,
})
