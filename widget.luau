local PLUGIN_ID = "superjaba2000/gigactl-noctalia-plugin"

function update()
    noctalia.setUpdateInterval(1000)

    barWidget.setGlyph("gauge")
end

function onClick()
    noctalia.togglePanel(PLUGIN_ID .. ":panel")
end
