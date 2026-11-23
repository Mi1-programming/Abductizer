#include "mainUI.lua"

local uiPos = Vec(0.44, -0.2, -0.5)
local uiRot = QuatEuler(270, 0, 90)

function draw()
    local toolUI = UiGetScreen()

    if GetString("game.player.tool") ~= "abductizer" then return end

    local toolUIT = GetScreenShape(toolUI)
    local toolT = GetBodyTransform(GetToolBody())

    SetShapeLocalTransform(toolUIT, 
        TransformToParentTransform(
            Transform(toolT.pos, toolT.rot),
            Transform(uiPos, uiRot)
        ) 
    )
    drawMainUI()
end