--Write new value or default value
function GetOrSetFloat(path, default)
    if HasKey(path) then return GetFloat(path) end

    SetBool(path, default)
    return default
end
function GetOrSetBool(path, default)
    if HasKey(path) then return GetBool(path) end

    SetBool(path, default)
    return default
end

--Gets config values
function getConfig()
    return {
        theme = {
            color_r = GetOrSetFloat("savegame.mod.abductizer.custom.beam.color.r", 0),
            color_g = GetOrSetFloat("savegame.mod.abductizer.custom.beam.color.g", 1),
            color_b = GetOrSetFloat("savegame.mod.abductizer.custom.beam.color.b", 0),
        },
        functional = {
            beamHeight = GetOrSetFloat("savegame.mod.abductizer.custom.beam.height", 0.35),
            autoLeave = GetOrSetBool("savegame.mod.abductizer.custom.ufo.autoleave", true),
        },
        controls = {
            action_1 = "usetool",
            action_2 = "grab",
            inspectMenu = "mmb",
        },
    }
end