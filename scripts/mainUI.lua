#include "config.lua"

local animTickSpeed = 2

function drawMainUI()
    --UFO
    beamHeightSlider()
    --Color sliders
    UiPush()
        UiTranslate(UiCenter(), UiHeight()-150)
        UiColor(0, 0, 1)
		colorSlider("b")
        UiTranslate(0, -75)
        UiColor(0, 1, 0)
		colorSlider("g")
        UiTranslate(0, -75)
        UiColor(1, 0, 0)
		colorSlider("r")      
    UiPop()
    --Buttons
    UiPush()
        local borderMargins = -1
        UiButtonHoverColor(0.5, 0.5, 0.5, 1)
        UiTranslate(UiWidth() - borderMargins, borderMargins)
        UiAlign("right top")
        --CLOSE BUTTON
        if UiImageButton("MOD/ui/toolUI/icons/close.png") then
            SetPlayerScreen(0)
        end
    UiPop()
    --Setting boolean buttons
    UiPush()
        onoff("savegame.mod.abductizer.custom.ufo.autoleave", "Leave automatically", 22, UiCenter(), UiHeight())
    UiPop()
end
function colorSlider(color, width)
    UiPush()
        local sliderWidth = 100
        UiAlign("center middle")
	    UiRect(sliderWidth, 4)
	    UiTranslate(-sliderWidth / 2, -1)
        SetFloat("savegame.mod.abductizer.custom.beam.color." .. color, UiSlider(
            "MOD/ui/toolUI/icons/handle.png",
            "x",
            GetFloat("savegame.mod.abductizer.custom.beam.color." .. color) * sliderWidth,
            0,
            sliderWidth) / sliderWidth)
    UiPop()
end
function beamHeightSlider()
    UiPush()
        local red = GetFloat("savegame.mod.abductizer.custom.beam.color.r")
        local green = GetFloat("savegame.mod.abductizer.custom.beam.color.g")
        local blue = GetFloat("savegame.mod.abductizer.custom.beam.color.b")
        local maxBeamHeight = 400
        local beamHeight = GetFloat("savegame.mod.abductizer.custom.beam.height")*maxBeamHeight

        UiColor(red, green, blue)

        UiPush()
            UiAlign("left bottom")
            UiTranslate(0, UiMiddle()+100)
            UiWindow(UiWidth(), beamHeight, true, false)
            UiAlign("center middle")
            UiTranslate(UiCenter(), GetTime()*100 % 64 + 192)
            UiImage("MOD/ui/toolUI/beam.png")
        UiPop()

        UiTranslate(UiCenter(), 125)
        UiAlign("center middle")
	    UiTranslate(0, -1)

        local newSliderVal = 1-UiSlider(
            "MOD/ui/toolUI/ufos/classic.png",
            "y",
            (1-math.max(GetFloat("savegame.mod.abductizer.custom.beam.height"), 0.1)) * maxBeamHeight,
            0,
            maxBeamHeight) / maxBeamHeight
        SetFloat("savegame.mod.abductizer.custom.beam.height", newSliderVal)
    UiPop()
end
function onoff(field, desc, descFS, offsetX, offsetY)
	UiPush()
        UiAlign("center bottom")
        UiTranslate(offsetX, offsetY)
        UiPush()
            UiFont("bold.ttf", 32)
            local curValue = GetBool(field)
		    if UiTextButton(curValue == true and "ON" or "OFF") then
		    	SetBool(field, not curValue)
		    end
        UiPop()

        if UiIsMouseInRect(75, 35) then
            UiPush()
                UiFont("bold.ttf", descFS)
                UiAlign("center middle")
                UiTranslate(UiCenter()-offsetX, UiHeight()-50-offsetY)	
                UiText(desc)
            UiPop()
        end
	UiPop()
end