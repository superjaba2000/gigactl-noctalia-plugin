local PLUGIN_ID = "superjaba2000/gigactl-noctalia-plugin"

local ALWAYS_USE_GAUGE_GLYPH = true

function update()
    noctalia.setUpdateInterval(1000)

    glyphs = {
        ["quiet"] = "car-fan",
        ["balanced"] = "car-fan-1",
        ["performance"] = "car-fan-2",
        ["max"] = "car-fan-3",
        ["manual"] = "car-fan",
    }

    local activeProfile = noctalia.state.get("active-profile") or "unknown"
    local glyph = glyphs[activeProfile] or "gauge"
    
    if ALWAYS_USE_GAUGE_GLYPH then
        glyph = "gauge"
    end

    barWidget.setGlyph(glyph)
end

function onClick()
    noctalia.togglePanel(PLUGIN_ID .. ":panel")
end
