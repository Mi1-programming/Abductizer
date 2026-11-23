function dissipateParticles(shape)

    --Setup particle settings
    ParticleTile(4)
    ParticleColor(config.theme.color_r+0.5, config.theme.color_g+0.5, config.theme.color_b+0.5, 0, 0, 0)
    ParticleRadius(0.1, 0, "easein")
    ParticleEmissive(0.25)
    ParticleAlpha(1)
    ParticleCollide(0)
    ParticleDrag(1)
    ParticleGravity(0)
    ParticleStretch(0)
    ParticleRotation(0)

    local bodyVel = GetBodyVelocity(GetShapeBody(shape))
    bodyVel[2] = 0
    local flyDir = VecScale(VecNormalize(bodyVel), 100)

    --Get shape transform
    local shapeT = GetShapeWorldTransform(shape)

    local xs, ys, zs, voxSize = GetShapeSize(shape)
    for x=0, xs do
        for y=0, ys do
            for z=0, zs do
                --Logic for each voxel

                local mat = GetShapeMaterialAtIndex(shape, x, y, z)

                --If not air
                if mat ~= "" then
                    local particlePos =
                    TransformToParentPoint(shapeT, VecScale(Vec(x, y, z), voxSize))

                    SpawnParticle(particlePos, flyDir, 1.5)
                end
            end
        end
    end
end
function signalTrailParticle(position)

    --Setup particle settings
    ParticleTile(6)
    ParticleColor(config.theme.color_r+0.5, config.theme.color_g+0.5, config.theme.color_b+0.5)
    ParticleRadius(0.1, 0.05, "linear", 0.5, 0.5)
    ParticleEmissive(0.25)
    ParticleAlpha(0, 1)
    ParticleCollide(0)
    ParticleDrag(0)
    ParticleGravity(10)
    ParticleStretch(0)
    ParticleRotation(0)

    SpawnParticle(
        position,
        Vec(0, 0, 0),
        0.25) 
end
function pullParticles(position, size, speed)

    --Setup particle settings
    ParticleTile(0)
    ParticleColor(1, 1, 1)
    ParticleRadius(0, 0.5, "easeout")
    ParticleEmissive(0)
    ParticleAlpha(0, 0.65, "linear", 0, 0.35)
    ParticleCollide(0)
    ParticleDrag(0)
    ParticleGravity(0)
    ParticleStretch(0)
    ParticleRotation(0)

    local particlePosition =
    VecAdd(position,
        VecScale(
            VecNormalize(
                Vec(math.random(-10, 10), 0, math.random(-10, 10))), size*2))

    SpawnParticle(
        VecAdd(particlePosition, Vec(0, 0.5, 0)),
        VecScale(VecSub(particlePosition, position), -0.05*speed),
        20/speed) 
end
function beamEndParticles(position)
    --Setup particle settings
    ParticleTile(4)
    ParticleColor(config.theme.color_r+0.25, config.theme.color_g+0.25, config.theme.color_b+0.25)
    ParticleRadius(0.75, 0, "easeout")
    ParticleEmissive(0.25)
    ParticleAlpha(0.5, 0.25, "easeout")
    ParticleCollide(0)
    ParticleDrag(0.25)
    ParticleGravity(0)
    ParticleStretch(5)
    ParticleRotation(0)

    local particleVelocity =
    VecScale(
        VecNormalize(
            Vec(math.random(-10, 10), 0, math.random(-10, 10))),
    40)

    SpawnParticle(
        position,
        particleVelocity,
        math.random(1, 2)/2) 
end
function tractorBeamParticles(position, height)
    local newHeight = math.random(0, height*10)/10
    
    --Setup particle settings
    ParticleTile(4)
    ParticleColor(config.theme.color_r+0.25, config.theme.color_g+0.25, config.theme.color_b+0.25)
    ParticleRadius(0.5, 0, "easein")
    ParticleEmissive(4)
    ParticleAlpha(0.35)
    ParticleCollide(0)
    ParticleDrag(0)
    ParticleGravity(0)
    ParticleStretch(5)
    ParticleRotation(0)

    SpawnParticle(
        VecAdd(position, 
            Vec(math.random(-100, 100)/100, newHeight, math.random(-100, 100)/100)),
        Vec(0, 40, 0),
        0.025*(height - newHeight)) 
end
function beamOnOffParticles(position)

    --Setup particle settings
    ParticleTile(4)
    ParticleColor(config.theme.color_r+0.25, config.theme.color_g+0.25, config.theme.color_b+0.25)
    ParticleRadius(0.5, 0, "easeout")
    ParticleEmissive(1)
    ParticleAlpha(0.5)
    ParticleCollide(0)
    ParticleDrag(0.5)
    ParticleGravity(-5)
    ParticleStretch(15)
    ParticleRotation(0)

    --Create a circle of particles
    local res = 100
    local size = 1.5
    for x=1, res do
        local offsetT = Transform(position, QuatEuler(0, 360/res*x, 0))
        local newPosition = TransformToParentPoint(offsetT, Vec(size, 0, 0))
        local dir = VecSub(newPosition, position)

        SpawnParticle(
            newPosition,
            VecScale(dir, math.random(20, 30)),
            1.5) 
    end
end
function beamBeginParticles(position, size, offset)

    --Setup particle settings
    ParticleTile(6)
    ParticleColor(1, 1, 1, config.theme.color_r+0.25, config.theme.color_g+0.25, config.theme.color_b+0.25, "easeout")
    ParticleRadius(1.25, 0, "easein", 0.25)
    ParticleEmissive(0.5)
    ParticleAlpha(0.5, 0, "easeout")
    ParticleCollide(0)
    ParticleDrag(0)
    ParticleGravity(0)
    ParticleStretch(0)
    ParticleRotation(180)

    for x=0, 1 do
        local newPos = VecAdd(
            VecScale(VecNormalize(VecRand(-1, 1, 3, 1, 0, 1)),
                math.random(0, size*2*10)/10),
            VecAdd(
                position,
                offset))

        SpawnParticle(
            newPos,
            Vec(0, -3, 0),
            0.25) 
        end
end
function signalBeginParticles(position)

    --Setup particle settings
    ParticleTile(4)
    ParticleColor(config.theme.color_r+0.25, config.theme.color_g+0.25, config.theme.color_b+0.25)
    ParticleRadius(0.05, 0, "easeout")
    ParticleEmissive(0.25)
    ParticleAlpha(0.5, 0.25, "easeout")
    ParticleCollide(0)
    ParticleDrag(0.25)
    ParticleGravity(0)
    ParticleStretch(5)
    ParticleRotation(0)

    for x=1, 100 do
        SpawnParticle(
            position,
            VecRand(-2, 2, 3, 1, 1, 1),
            0.25) 
    end
end