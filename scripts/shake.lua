--Shaking variables
shake = {}
    shake["magnitude"] = 0
    shake["frequency"] = 0
    shake["duration"] = 0
    shake["time"] = 0
    shake["dir"] = Vec(0, 0, 0)

--Shakes screen
function processShake(dt)
	if shake.time >= shake.duration then return end

	shake.time = shake.time + dt

	local t = Transform(Vec(), QuatAxisAngle(shake.dir,
		math.sin(shake.time*shake.frequency)*shake.magnitude*(1-(shake.time/shake.duration)))
	)
    
	SetPlayerCameraOffsetTransform(t)	
end
--Prepares shake
function shakeSet(magnitude, frequency, dir, duration)
	shake.magnitude = magnitude
	shake.frequency = frequency
	shake.dir = VecCopy(dir)
	shake.duration = duration
	shake.time = 0
end