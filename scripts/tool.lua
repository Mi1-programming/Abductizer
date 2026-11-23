--Tool values
tool = {}
    tool["range"] = 100
    tool["callingUfoOff"] = false
    tool["timeToCallUfoOff"] = 1.5
    tool["timeToCallUfoOffLeft"] = tool.timeToCallUfoOff
    tool["fireOffset"] = Vec(0.175, 0.275, 0.275)
    tool["fireCurveFactor"] = 15
    tool["headAngle"] = 0
    tool["handleAngle"] = 0

local bullets = {}
local signalEndAnimationProperties = {}
    signalEndAnimationProperties["duration"] = (math.pi*3)/10
    signalEndAnimationProperties["animSpeed"] = 10

local signalEnds = {}

--Gets the end of the ray cast in front of the camera
function getCameraRayEnd()
    local camT = GetPlayerCameraTransform()
    local lookDir = TransformToParentVec(camT, Vec(0, 0, -1))
    if ufos[1] ~= nil then QueryRejectBody(ufos[1].handle) end
    QueryRequire("large")
    local hit, dist = QueryRaycast(
        camT.pos,
        lookDir,
        tool.range,
        0)
    if hit then
        --Get hit pos
        local callPos = VecAdd(VecScale(lookDir, dist), camT.pos)
        return callPos, dist
    else return nil end
end
function drawIcon(sprite, pos)
    --Create and animate the UFO sprite

    local newPos = VecCopy(pos)
    newPos[2] = pos[2] + 1.5 + math.sin(GetTime()*3)/2

    --Draw shadow

    local camPos = GetPlayerCameraTransform().pos
	local q = QuatLookAt(newPos, camPos)
	local xx, xy, xz = GetQuatEuler(q)

	local t = Transform(newPos, QuatEuler(xx, xy, xz))

    DrawSprite(glowSprite,
        t, 
        2.5, 2.5,
        config.theme.color_r+0.5, config.theme.color_g+0.5, config.theme.color_b+0.5, 0.01,
        false,
        false)

    --Draw sprite

    DrawSprite(sprite,
        Transform(newPos, QuatEuler(0, GetTime()*150, 0)), 
        2, 2,
        config.theme.color_r, config.theme.color_g, config.theme.color_b, 0.5,
        false,
        false)
end
--Visualizes first call position
function drawSignalEnd(position, time)
    --Animates the signal sprite
    local signalSize = 8
    local animSignalSize = (time * signalEndAnimationProperties.animSpeed % 
    signalEndAnimationProperties.animSpeed) / signalEndAnimationProperties.animSpeed * signalSize
    
    DrawSprite(signalSprite, 
        Transform(position, QuatEuler(90, 0, 0)), 
        animSignalSize, animSignalSize, 
        config.theme.color_r, config.theme.color_g, config.theme.color_b, 1-(animSignalSize/signalSize),
        false, 
        false)
end
--Gets a position on a curved path
function getPositionOnPath(start, dest, dist, point)
    return VecAdd( 
        VecLerp(start, dest, point),
        Vec(0, math.sin(point*math.pi)*(dist/tool.fireCurveFactor), 0))
end
--Progress signal drawings
function tickSignalEndAnimations(dt)
    for x=#signalEnds, 1, -1 do
        if signalEnds[x].time <= signalEndAnimationProperties.duration then
            drawSignalEnd(signalEnds[x].position, signalEnds[x].time)
            signalEnds[x].time = signalEnds[x].time + dt*1.5
        else table.remove(signalEnds, x) end
    end
end
--Refreshes the bulletlike signals
function updateSignals(dt)
    for k, v in ipairs(bullets) do     
        --Add particles between particles
        local particles = 8
        for x=1, particles do
            local curPoint = (v.aliveTime + (x/particles)*dt) / v.duration  
            local newPos = getPositionOnPath(v.start, v.destination, v.distance, curPoint)
        
            signalTrailParticle(newPos)
        end
        
        v.aliveTime = v.aliveTime + dt

        if v.aliveTime > v.duration then
            local properties = {}
            properties["position"] = v.destination
            properties["time"] = 0

            table.insert(signalEnds, properties)
            PlaySound(signalEndSnd, v.destination, 1)

            if ufos.instances[1] then ufoCall(ufos.instances[1], v.destination)
            else ufoSpawn(v.destination, dt) end

            table.remove(bullets, k)
        end
    end 
end
function shootSignal(from, to, dist)
    PlaySound(signalSnd, from, 0.25)
    signalBeginParticles(from)

    local properties = {}
    properties["start"] = VecCopy(from)
    properties["destination"] = VecCopy(to)
    properties["duration"] = dist/100
    properties["distance"] = dist
    properties["aliveTime"] = 0

    table.insert(bullets, properties)
end
function tickTool(dt)
    --On ray hit
    local camRay, dist = getCameraRayEnd()

    local toolHead = GetBodyShapes(GetToolBody())[2]
    local headT = GetShapeWorldTransform(toolHead)
    headT.pos = VecAdd(TransformToParentVec(headT, tool.fireOffset), headT.pos)
        
    if camRay ~= nil then
        local rayEnd = onTop(
            (ufos.instances[1]) and ufos.instances[1].handle or nil,
            camRay, 
            ufos.hoverHeight, 
            ufos.colSize, 
            ufos.staticThreshold)

        if ufos[1] == nil then drawIcon(ufoSprite, rayEnd)
        else drawIcon(arrowSprite, rayEnd)
        end

        local headX, _, _ = GetQuatEuler(QuatLookAt(
            headT.pos, 
            rayEnd
            ))

        --Smoothing
        local lastHeadAngle = tool.headAngle
        tool.headAngle = damp(tool.headAngle, clamp(headX, -40, 40), 16, dt)
        --Sounds
        local volume = math.abs(lastHeadAngle - tool.headAngle)
        PlayLoop(motorSnd, headT.pos, math.min(volume, 2)/8)
        --Apply
        rotateShape(
            toolHead, 
            QuatEuler(tool.headAngle, 0, 0),
            Vec(0, -0.15, -1),
            Transform(Vec(0.55, -0.2, -0.95), QuatEuler(0, 180, 0))
        )
        --Apply
        rotateShape(
            GetBodyShapes(GetToolBody())[4], 
            QuatEuler(tool.headAngle, 0, 0),
            Vec(0, -0.175, -0.975),
            Transform(Vec(0.35, -0.25, -0.9), QuatEuler(0, 180, 0))
        )

        --Draws a line between the raycast end and the height adjusted position
        DrawLine(camRay, rayEnd, config.theme.color_r, config.theme.color_g, config.theme.color_b, 0.5)

        --On left click
        if InputPressed(config.controls.action_1) then
            --Call UFO
            shootSignal(headT.pos, rayEnd, dist)  
            --Animation
            tool.headAngle = tool.headAngle + 25
            tool.handleAngle = 45
        end
    end
    local toolHandle = GetBodyShapes(GetToolBody())[3]

    --Tool handle animation smoothing
    local lastHandleAngle = tool.handleAngle
    tool.handleAngle = damp(tool.handleAngle, 0, 6, dt)
    --Apply
    rotateShape(
        toolHandle, 
        QuatEuler(tool.handleAngle, 0, 0),
        Vec(0.35, -0.25, -0.9),
        Transform(Vec(0.35, -0.35, -0.75), QuatEuler(90, 180, 180))
    )

    --On right click
    if ufos.instances[1] then
        if InputDown(config.controls.action_2) and not ufos.instances[1].isLeaving then
            DrawBodyOutline(ufos.instances[1].handle, config.theme.color_r, config.theme.color_g, config.theme.color_b, 1)
            DrawLine(headT.pos, ufos.instances[1].offsetPos, config.theme.color_r, config.theme.color_g, config.theme.color_b, 0.5)

            tool.callingUfoOff = true
            tool.timeToCallUfoOffLeft = math.max(tool.timeToCallUfoOffLeft - dt, 0)
            if tool.timeToCallUfoOffLeft == 0 then
                ufoLeave(ufos.instances[1])    
                tool.timeToCallUfoOffLeft = tool.timeToCallUfoOff
                tool.callingUfoOff = false
            end
        else
            tool.timeToCallUfoOffLeft = tool.timeToCallUfoOff
            tool.callingUfoOff = false
        end
    end
end