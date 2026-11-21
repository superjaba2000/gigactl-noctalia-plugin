function update()
    noctalia.setUpdateInterval(1000)

    barWidget.setGlyph("gauge")
end

function onClick()
    noctalia.togglePanel("superjaba2000/gigactl:panel")
end