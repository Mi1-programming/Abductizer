ufos = {}
ufos = {
    ["tractorBeamDistance"] = 100,
    ["tractorBeamSize"] = 1.5,
    ["tractorBeamEffectSize"] = 4,
    ["tractorBeamDamping"] = 1.06,
    ["bottomBeamMargin"] = 3,
    ["colSize"] = 5,
    ["hoverHeight"] = 50,
    ["voxelHungerGain"] = 0.1,
    ["voxelsToMinPower"] = 25000,
    ["voxelsToLeave"] = 100,
    ["timeUntilGiveUp"] = 6,
    ["timeToLeave"] = 4,
    ["beamDestructionTipBias"] = 1,
    ["staticThreshold"] = 1,
    ["randOffsetSpeed"] = 2,
    ["randOffsetPower"] = 1,
    ["distancePowerCurve"] = {
        { point=0, value=0 },
        { point=0.5, value=1 },
        { point=1, value=0 },
    }
}
ufos.instances = {}

--Destroys the UFO
function ufoRemove(self)
    Delete(self.handle)
    self = {}
    table.remove(ufos.instances, self.id)
end
--Set fly path from point A to point B
function ufoSetPath(self, from, to, speed, delete, easing)
    self.flight = {}
    self.flight.startingPos = self.curPos
    self.flight.targetPos = to
    self.flight.time = speed
    self.flight.timePassed = 0
    self.flight.destroyOnReachFlightEnd = delete
    self.flight.easing = easing
    --Reset voxel time
    self.voxelsTakenByTime = ufos.voxelsToMinPower
end
--Calls the UFO
function ufoCall(self, callPos)
    --Default values
    self.voxelsTakenByTime = ufos.voxelsToMinPower
    self.giveUpTimer = ufos.timeUntilGiveUp

    ufoRefreshPos(self)

    self.isLeaving = false

    local flyPos = VecAdd(callPos, Vec(0, config.functional.beamHeight * ufos.hoverHeight, 0))

    if VecDist(flyPos, self.curPos) > 40 then
        ufoBeamState(self, false)
        ufoSetPath(self, self.curPos, flyPos, 2.5, false, easeInOutElastic)
    else
        ufoSetPath(self, self.curPos, flyPos, 4.5, false, easeOutQuart)            
    end
end
--Updates the UFO properties like beam power and size based on "power of max"
function ufoRefreshProperties(self, dt)
    --Progress UFO voxels by time value
    self.voxelsTakenByTime = clamp(
        self.voxelsTakenByTime - dt*(ufos.voxelHungerGain * ufos.voxelsToMinPower),
        0, ufos.voxelsToMinPower)    
    local powerOfMax = (ufos.voxelsToMinPower - self.voxelsTakenByTime)
        / ufos.voxelsToMinPower

    --Apply UFO properties based on voxels by time value
    self.pullPower = lerp(4, 10, powerOfMax)
    self.tractorBeamPower = lerp(14, 23, powerOfMax)
    self.pullSize = lerp(6, 28, powerOfMax)
    self.breakDistance = lerp(4, 16, powerOfMax)
    self.maxAbductVoxels = lerp(4000, 10000, powerOfMax)
end
--The init function for the UFO
function ufoInit(self, callPos, dt, newId)
    --UFO shapes
    self.handle = self.shapes[1]
    self.emitterShape = self.shapes[4]
        SetShapeEmissiveScale(self.emitterShape, 0)
        self.glowPower = 0
    
    self.frameShape = self.shapes[2]

    self.voxelsTakenByTime = 0
    self.id = newId
    ufoRefreshProperties(self, dt)

    ufoCall(self, callPos)
end
--Turn beam on or off
function ufoBeamState(self, isOn)
    if self.beamOn == isOn then return end

    --Particles
    beamOnOffParticles(VecSub(self.offsetPos, Vec(0, 0.2, 0)))

    if isOn then
        PlaySound(beamBegin, self.curPos, 1.5)
        SetShapeEmissiveScale(self.emitterShape, 10)

        self.glowPower = 500
        SetValue("self.glowPower", 65, "easeout", 0.5)

        --Shake
        shakeSet(1, 40, Vec(0, 1, 0), 0.35)
    else 
        PlaySound(beamEnd, self.curPos, 1.5)
        SetShapeEmissiveScale(self.emitterShape, 0)
    end

    self.beamOn = isOn
end
--The tick function for the UFO
function ufoTick(self, dt)
    if self.handle == nil then return end

    --Update position and offset
    ufoRefreshPos(self)

    --Set as non dynamic
    SetBodyDynamic(self.handle, false)
        
    --Rotates UFO beam frame around it's center
    rotateShape(self.frameShape,
        QuatEuler(0, GetTime()*150, 0),
        Vec(0, 0, -0.1),
        Transform(Vec(-3.7, 0.3, 3.6), QuatEuler(-90, 0, 0)))

    --Define UFO position
    local newUfoPos = Vec(0, 0, 0)
    --Move UFO if not at destination
    if self.flight.timePassed < self.flight.time then

        --Progress UFO flight
        function fly(dt)
            --Progress time
            self.flight.timePassed = self.flight.timePassed + dt

            if self.flight.timePassed >= self.flight.time then
                --End reached
                if self.flight.destroyOnReachFlightEnd then
                    ufoRemove(self)
                    return nil
                end
                ufoBeamState(self, true)    
            end

            --Create new pos
            return
            VecLerp(
                self.flight.startingPos,
                self.flight.targetPos,
                self.flight.easing(self.flight.timePassed / self.flight.time))
        end

        local newFlightPos = fly(dt)

        if newFlightPos == nil then return end
        newUfoPos = VecCopy(newFlightPos)

    --Pre beam
    elseif self.beamOn then
        --Make UFO give up if necessary
        if config.functional.autoLeave then
            if self.voxelsTakenByTime <= ufos.voxelsToLeave then
                self.giveUpTimer = self.giveUpTimer - dt
            
                if self.giveUpTimer <= 0 then
                    ufoLeave(self)
                    return
                end
            else self.giveUpTimer = ufos.timeUntilGiveUp end
        else self.giveUpTimer = ufos.timeUntilGiveUp end

        ufoRefreshProperties(self, dt)
        
        --Move ufo up or down based on objects below it, DON'T include offset
        newUfoPos = VecDamp(
            self.curPos,
            floatOver(self.handle, self.curPos, config.functional.beamHeight * ufos.hoverHeight, ufos.colSize, 1, dt, ufos.staticThreshold),
            0.25,
            dt)
    end
    
    --Apply and add offset and rotate UFO based on time
    local newT = Transform(VecAdd(newUfoPos, self.lastOffset), QuatEuler(0, GetTime()*50, 0))
    SetBodyTransform(self.handle, newT)

    --Fire beam
    if self.beamOn then
        function tickBeam(curPos, dt)
            --Casually make light weaker
            self.glowPower = damp(self.glowPower, 65, 3, dt)
            --Create point light
            PointLight(
                VecAdd(self.offsetPos, Vec(0, 0.3, 0)),
                config.theme.color_r,
                config.theme.color_g,
                config.theme.color_b,
                self.glowPower)

            --Play UFO beam sound
            PlayLoop(beamSnd, curPos, 3)

            --Get every object in the scene
            local bodies = FindBodies("", true)

            --Filter out every moving body in the scene
            local movingBodies = {}
            for x=1, #bodies do
                if not isStationary(bodies[x], ufos.staticThreshold) then
                    table.insert(movingBodies, bodies[x])
                end
            end

            --Calculates the end of the UFO tractor beam
            function getBeamEnd(curPos, bodies)
                --Get beam end pos
                QueryRejectBody(self.handle)
                for x=1, #bodies do QueryRejectBody(bodies[x]) end
                QueryRequire("physical large")
                local _, dist = QueryRaycast(curPos,
                    Vec(0, -1, 0), ufos.tractorBeamDistance, ufos.tractorBeamSize, false)   
                    self.beamEnd = VecSub(curPos, Vec(0, dist + ufos.tractorBeamSize, 0))
                self.beamDist = dist + ufos.tractorBeamSize
            end
            getBeamEnd(curPos, movingBodies)

            --Renders the tractor beam
            function renderTractorBeam(start, over)
                --NOTE PARTICLES NOT INCLUDED
                --Beam sprites
                fillVerticallyWithSprites(
                    start,
                    over, 
                    beamSprite, 
                    6, 
                    3, 
                    config.theme.color_r + 0.75, 
                    config.theme.color_g + 0.75,
                    config.theme.color_b + 0.75,
                    (((math.sin(GetTime() * 6) + 1) / 4) + 0.5) * 0.5)
            end
            renderTractorBeam(curPos, self.beamEnd)

            --Get objects inside beam pull distance
            QueryRejectBody(self.handle)
            QueryRequire("physical dynamic")
            local foundBodies = QueryAabbBodies(
                VecSub(self.beamEnd,
                Vec(self.pullSize, ufos.bottomBeamMargin, self.pullSize)),
                VecAdd(curPos,
                    Vec(self.pullSize, 0, self.pullSize))
            )
            --Filter out too large objects
            local unpullable = {}
            for k, v in ipairs(foundBodies) do
                if IsBodyDynamic(v) then
                    local voxels = getBodyVoxelCount(v)

                    if self.maxAbductVoxels < voxels then
                        --It wasn't pullable, add to unpullables...
                        table.insert(unpullable, v)
                    end
                    --It was pullable
                end
            end

            --Get objects in the tractor beam distance
            --Make ray not hit the UFO
            QueryRejectBody(self.handle)
            for x=1, #unpullable do
                QueryRejectBody(unpullable[x])
            end
            QueryRequire("physical dynamic")
            
            local tractorBeamTargetBodies = QueryAabbBodies(
                VecSub(self.beamEnd,
                Vec(ufos.tractorBeamEffectSize, ufos.bottomBeamMargin, ufos.tractorBeamEffectSize)),
                VecAdd(curPos,
                    Vec(ufos.tractorBeamEffectSize, 0, ufos.tractorBeamEffectSize))
            )
            --Hit objects, objects which hit the UFO deletion box
            --Make ray not hit the UFO
            QueryRejectBody(self.handle)
            for x=1, #unpullable do
                QueryRejectBody(unpullable[x])
            end
            QueryRequire("physical dynamic")
            
            local hitShapes = QueryAabbShapes(
                VecSub(curPos,
                Vec(ufos.colSize, 1, ufos.colSize)),
                VecAdd(curPos,
                    Vec(ufos.colSize, 0, ufos.colSize))
            )

            --Apply velocities and abduct objects

            for x=1, #tractorBeamTargetBodies do
                local oldVel = GetBodyVelocity(tractorBeamTargetBodies[x])
                SetBodyVelocity(tractorBeamTargetBodies[x],
                    Vec(oldVel[1] / ufos.tractorBeamDamping, 
                        oldVel[2] + self.tractorBeamPower * dt,
                        oldVel[3] / ufos.tractorBeamDamping))
            end
            --Pull all bodies in range
            for x=1, #foundBodies do
                local bodyPos = getBodyPos(foundBodies[x])
                local distanceModifier = getFromPointValue(
                    VecDist(Vec(self.beamEnd[1], bodyPos[2], self.beamEnd[3]), bodyPos),
                    self.pullSize,
                    ufos.distancePowerCurve)

                SetBodyVelocity(foundBodies[x],
                    VecAdd(
                        GetBodyVelocity(foundBodies[x]), 
                        VecScale(
                            Vec(curPos[1] - bodyPos[1], 0, curPos[3] - bodyPos[3]),
                            self.pullPower * dt * distanceModifier)))
            end

            --Abduct sound
            if #hitShapes > 0 then
                PlaySound(destroySnd, curPos, 0.5)
            end
            for x=1, #hitShapes do
                local body = GetShapeBody(hitShapes[x])
                
                local vehicle = GetBodyVehicle(body)

                local voxCount = GetShapeVoxelCount(hitShapes[x])
                self.voxelsTakenByTime = self.voxelsTakenByTime + voxCount

                dissipateParticles(hitShapes[x])

                --Delete shapes if selection is not a vehicle
                if vehicle + 1 ~= body then      
                    local joints = GetShapeJoints(hitShapes[x])
                    for x=0, #joints do
                        Delete(joints[x])
                    end
                    Delete(hitShapes[x])      
                end
                --Delete vehicle if vehicle
                if vehicle + 1 == body then
                    Delete(vehicle)
                end
            end
            
            --Break static objects
            local breakDir = VecNormalize(
                Vec(math.random(-100, 100), math.random(-100, 100), math.random(-100, 100)))
            local breakStartPos = VecLerp(
                VecLerp(curPos, self.beamEnd, math.random(0, 100)/100),
                self.beamEnd,
                math.min(math.random(0, ufos.beamDestructionTipBias*100)/100, 1))

            QueryRejectBody(self.handle)
            QueryRequire("physical large")
            for x=1, #movingBodies do
                QueryRejectBody(movingBodies[x])
            end
            local hit, dist = QueryRaycast(
                breakStartPos,
                breakDir,
                self.breakDistance,
                1,
                false)   
            if hit then
                local breakPos = VecAdd(VecScale(breakDir, dist), breakStartPos)
                if breakPos[2] >= self.beamEnd[2] - 1 then
                    MakeHole(breakPos, 3, 2, 1, false)
                end
            end 
        end
        --Logic for UFO beam
        tickBeam(newT.pos, dt)
    end

    --Play UFO hover sound (louder if beam not on)
    PlayLoop(hoverSnd, newUfoPos, (self.beamOn) and 0.25 or 1)
end
--Makes UFO leave
function ufoLeave(self)
    self.isLeaving = true

    ufoBeamState(self, false)

    ufoSetPath(self, self.curPos, VecAdd(self.curPos, Vec(0, 100, 0)), ufos.timeToLeave, true, easeInQuart)
end
--Update UFO offset
function ufoRefreshPos(self)
    local bodyPos = getBodyPos(self.handle)
    self.curPos = VecSub(bodyPos, self.lastOffset)
    self.offsetPos = VecCopy(bodyPos)
    self.lastOffset = Vec(0, math.sin(GetTime() * ufos.randOffsetSpeed) * ufos.randOffsetPower, 0)
end
--The update function for the UFO
function ufoUpdate(self, dt)
    if self.handle == nil then return end
    if not self.beamOn then return end

    --Particles
    pullParticles(self.beamEnd, self.pullSize, self.pullPower)
    beamEndParticles(self.beamEnd)
    tractorBeamParticles(self.beamEnd, self.beamDist)
    beamBeginParticles(self.offsetPos, ufos.tractorBeamSize, Vec(0, 0.25, 0))
end
--Draws the timer that appears when you are calling the UFO off
function ufoDraw(self)
    if self.handle ~= nil and tool.callingUfoOff then
        UiPush()
            local x, y, dist = UiWorldToPixel(VecAdd(self.offsetPos, Vec(0, 1, 0)))
            UiTranslate(x, y)
            UiAlign("center middle")
            UiScale(math.max(20 / dist, 0))

            local split = 2
            local sprites = 8
            local progress = (tool.timeToCallUfoOffLeft - math.floor(tool.timeToCallUfoOffLeft*split)/split)*split

            --Create circle
            UiPush()
                local col = VecLerp(
                    Vec(config.theme.color_r-0.25, config.theme.color_g-0.25, config.theme.color_b-0.25),
                    Vec(1, 1, 1),
                    progress)
                UiColor(col[1], col[2], col[3])
                UiScale(lerp(0.5, 1, progress))
                UiImage("ui/world/circle/" .. 
                    tostring(
                        math.ceil(progress*sprites)
                    )
                    .. ".png")
            UiPop()

            --Create countdown
            UiTextShadow(0, 0, 0, 0.5, progress*5, 0)
            UiFont("bold.ttf", 84)
            UiText(tostring(math.ceil(tool.timeToCallUfoOffLeft*split)))
        UiPop()
    end
end
--Adds the UFO to the UFO list
function ufoAdd(shapes)
    self = {}
    self.shapes = shapes
    table.insert(ufos.instances, self)

    return #ufos.instances
end
--Spawns a new UFO
function ufoSpawn(callPos, dt)
    local newRandomPos = VecAdd(
        VecScale(
        --Make spawn points circular around the called point
        VecNormalize(
            Vec(math.random(-100, 100), 100, math.random(-100, 100))),
        100),
        callPos)
        
    --Create UFO
    local new = Spawn("MOD/vox/ufo/ufo.xml", Transform(newRandomPos))

    --Add to collection and call
    local i = ufoAdd(new)
    ufoInit(ufos.instances[i], callPos, dt, 0)
end
