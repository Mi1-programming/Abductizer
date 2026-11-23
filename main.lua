#include "scripts/extras.lua".
#include "scripts/particles.lua"
#include "scripts/shake.lua"
#include "scripts/ufo.lua"
#include "scripts/tool.lua"
#include "scripts/toolUIManager.lua"
#include "scripts/config.lua"

--Called at the beginning
function init()
    RegisterTool("abductizer", "Abductizer", "MOD/vox/model.vox", 6)
    SetBool("game.tool.abductizer.enabled", true)
    SetString("game.tool.abductizer.ammo.display", "")

    --Sounds
    hoverSnd = LoadLoop("MOD/snd/ufo_hover.ogg")
    beamSnd = LoadLoop("MOD/snd/ufo_tractorbeam.ogg")
    motorSnd = LoadLoop("MOD/snd/motor.ogg")
    beamBegin = LoadSound("MOD/snd/ufo_beam_begin.ogg")
    beamEnd = LoadSound("MOD/snd/ufo_beam_end.ogg")
    destroySnd = LoadSound("MOD/snd/ufo_destroy.ogg")
    signalSnd = LoadSound("MOD/snd/signal.ogg")
    signalEndSnd = LoadSound("MOD/snd/signal_end.ogg")

    --Sprites
    beamSprite = LoadSprite("MOD/sprite/tractorbeam.png")
    signalSprite = LoadSprite("MOD/sprite/signal.png")
    ufoSprite = LoadSprite("MOD/sprite/ufo.png")
    arrowSprite = LoadSprite("MOD/sprite/arrow.png")
    glowSprite = LoadSprite("MOD/sprite/glow.png")

    --Config
    config = getConfig()
end
--Called every frame
function tick(dt)
    --Update the config if the placeholder tool exists
    if placeholderTool ~= nil then config = getConfig() end
    
    for x=1, #ufos.instances do
        ufoTick(ufos.instances[x], dt)
    end

    tickSignalEndAnimations(dt)
    tickToolUIManager()

    --If tool should work continue
    if GetString("game.player.tool") ~= "abductizer" then return end
    if not GetBool("game.player.canusetool") then return end

    tickTool(dt)

    --Process shaking if needed
    processShake(dt)
end
--Beam particles
function update(dt)
    updateSignals(dt)
    
    for x=1, #ufos.instances do
        ufoUpdate(ufos.instances[x], dt)
    end
end
--Draws UI
function draw()
    for x=1, #ufos.instances do
        ufoDraw(ufos.instances[x], dt)
    end
end