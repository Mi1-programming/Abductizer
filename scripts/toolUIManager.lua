--This script is responsible for spawning the screens and the placeholder tool

local isToolInHand = false
placeholderTool = nil
local toolUIPreview = nil

function tickToolUIManager()
    --If tool is being used create or destroy UI and stop if not using tool
    if GetString("game.player.tool") ~= "abductizer" then
        if isToolInHand == true then destroyPreviewUI() end
        isToolInHand = false
        return
    end
    if isToolInHand == false then createPreviewUI() end
    isToolInHand =  true

    --Delete placeholder tool when no longer used
    if GetPlayerScreen() == 0 and placeholderTool ~= nil then 
        for x=1, #placeholderTool do
            Delete(placeholderTool[x])
        end
        placeholderTool = nil
    end

    if not GetBool("game.player.canusetool") then return end

    if InputPressed(config.controls.inspectMenu) or PauseMenuButton("Abductizer") then
        openMenu()
    end
end
--Opens the UI menu
function openMenu()
    local tool = GetToolBody()
    local toolT = GetBodyTransform(tool)
    local toolShapes = GetBodyShapes(tool)

    --Spawn placeholder tool and set it's transform to resemble the original
    placeholderTool = Spawn("MOD/vox/xmlTool.xml", toolT, true)
    for x=1, #toolShapes do
        SetShapeLocalTransform(placeholderTool[x], GetShapeWorldTransform(toolShapes[x]))
    end

    --Find screen from placeholder
    SetPlayerScreen(FindScreen("abductizerUI", true))
end
--Creates tool UI
function createPreviewUI()
    --Preview UI works without interference from this script
    toolUIPreview = Spawn("MOD/vox/ui.xml", Transform())
end
--Destroy tool UI
function destroyPreviewUI()
    for x=1, #toolUIPreview do
        Delete(toolUIPreview[x])
    end 
end