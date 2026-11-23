--A collection of common functions

--Math

--Limit value to min and max
function clamp(value, min, max)
	if value > max then
		value = max
	end
	if value < min then
		value = min
	end
	return value
end
--Progress value between A and B
function lerp(val1, val2, time)
	return val1 + (val2 - val1) * time
end
--Smoothly move a value from A to B
function damp(a, b, speed, dt)
	return lerp(a, b, 1-math.exp(-speed*dt))
end
--Smoothly move a vector from A to B
function VecDamp(vectorA, vectorB, speed, dt)
	return Vec(
		damp(vectorA[1], vectorB[1], speed, dt),
		damp(vectorA[2], vectorB[2], speed, dt),
		damp(vectorA[3], vectorB[3], speed, dt)
	)
end
--Calculate distance between two points
function VecDist(vectorA, vectorB)
    return math.sqrt((vectorB[1] - vectorA[1])^2 + (vectorB[2] - vectorA[2])^2 + (vectorB[3] - vectorA[3])^2)
end
--Generate a random vector
function VecRand(min, max, precision, xScale, yScale, zScale)
	return Vec(
		math.random(min*10^precision, max*10^precision)/10^precision*xScale,
		math.random(min*10^precision, max*10^precision)/10^precision*yScale,
		math.random(min*10^precision, max*10^precision)/10^precision*zScale
	)
end

--Shortcuts

function getBodyPos(body)
	return TransformToParentPoint(GetBodyTransform(body), GetBodyCenterOfMass(body))
end
function rotateShape(handle, newQuat, pivot, rotT)
	--Spin around current pos
    local origin = Transform(pivot)
    local handleT = TransformToLocalTransform(origin, rotT)
    origin.rot = QuatCopy(newQuat)
    local t = TransformToParentTransform(origin, handleT)

    SetShapeLocalTransform(handle, t)
end
--"Pointvalue" variables are tables which include tables which include two values:
--"point" and "value". They are meant to be between 0 and 1, and are used to define
--a linear curve with values in it.
function getFromPointValue(value, maxValue, variable)
	local relVal = value / maxValue

	for x=1, #variable do
		--If found a valid range
		if #variable >= x+1 then
			--If value is larger than a point in "pointvalue"
			if variable[x+1].point >= relVal then
				--Interpolate value from between the points

				local time = relVal

				local returnVal = lerp(variable[x].value, variable[x+1].value, time)
				/ (variable[x+1].point - variable[x].point)

				return returnVal
			end
		end
	end
	return 0
end
function isStationary(body, velocityThreshold)
	local speed = VecLength(GetBodyVelocity(body))
	if speed < velocityThreshold then return true else return false end
end
function getBodyVoxelCount(body)
	local shapes = GetBodyShapes(body)
	local voxels = 0
	for x=1, #shapes do
		voxels = voxels + GetShapeVoxelCount(shapes[x])
	end
	return voxels
end

--Common functions used in the mod

--Sets object on top of objects above it
function onTop(body, position, step, radius, staticThreshold)
	local hit = true
	local iter = 0

	local bodies = FindBodies("", true)

	while hit == true do
		iter = iter + 1

		--Reject UFO and everything moving and small
		QueryRejectBody(body)
		QueryRequire("physical large")
		for x=1, #bodies do
			--If body is moving reject
			if not isStationary(bodies[x], staticThreshold) then
				QueryRejectBody(bodies[x])
			end
		end
		--Shoot ray
		hit, dist = QueryRaycast(
			VecAdd(position, Vec(0, step*iter, 0)),
			Vec(0, -1, 0),
			step,
			radius,
			false)
	end

	--Reject UFO and everything moving and small
	QueryRejectBody(body)
	QueryRequire("physical large")
	for x=1, #bodies do
		--If body is moving reject
		if not isStationary(bodies[x], staticThreshold) then
			QueryRejectBody(bodies[x])
		end
	end
	--Shoot ray
	_, dist = QueryRaycast(
		VecAdd(position, Vec(0, step*iter, 0)),
		Vec(0, -1, 0),
		step*2,
		radius,
		false)

	local newPos = VecAdd(position, Vec(0, (step*iter) - dist - radius, 0))
	newPos[2] = math.max(newPos[2], 0)

	--Return
	return newPos
end
--Keeps object above static large objects
function floatOver(body, position, height, radius, staticThreshold)
	local bodies = FindBodies("", true)

	--Reject UFO and everything moving and small
	QueryRejectBody(body)
	QueryRequire("physical large")
	for x=1, #bodies do
		--If body is moving reject
		if not isStationary(bodies[x], staticThreshold) then
			QueryRejectBody(bodies[x])
		end
	end
	--Shoot first ray to check if below is object
	_, dist = QueryRaycast(
		position,
		Vec(0, -1, 0),
		height*2,
		radius,
		false)

	dist = dist + radius

	local newPos = Vec(0, 0, 0)
	if dist > height then newPos = VecCopy(VecSub(position, Vec(0, dist - height, 0)))
	elseif dist < height then newPos = VecCopy(VecAdd(position, Vec(0, height - dist, 0)))
	else newPos = VecCopy(position) end
	newPos[2] = math.max(newPos[2], height)
	return newPos
end
--Draws a vertical strip of sprites from the bottom up
function fillVerticallyWithSprites(posA, posB, sprite, xSize, ySize, r, g, b, alpha)
	local curHeight = posB[2]

	while curHeight < posA[2] do
		curHeight = curHeight + ySize

		local camPos = GetCameraTransform().pos
		local q = QuatLookAt(posB, camPos)
		local xx, xy, xz = GetQuatEuler(q)

		local newPos = VecCopy(posB)
		newPos[2] = curHeight
		local t = Transform(VecSub(newPos, Vec(0, ySize/2, 0)), QuatEuler(0, xy, xz))

		DrawSprite(sprite, t, xSize, ySize, r, g, b, alpha, true, false)
	end
end

--Easings

--Elastic easing applied to value
function easeInOutElastic(num)
	local c5 = (2 * math.pi) / 4.5
	
	if num == 0 then return 0
	elseif num == 1 then return 1
	elseif num < 0.5 then return -(math.pow(2, 20 * num - 10) * math.sin((20 * num - 11.125) * c5)) / 2
	else return (math.pow(2, -20 * num + 10) * math.sin((20 * num - 11.125) * c5)) / 2 + 1 end
end
--In quart easing applied to value
function easeInQuart(num)
	return num * num * num * num
end
function easeOutQuart(num)
	return 1 - math.pow(1 - num, 4)
end