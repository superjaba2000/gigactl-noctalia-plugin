local function setProfile(profile)
    noctalia.runAsync({
        "noctalia",
        "msg",
        "plugin",
        "superjaba2000/gigactl:service",
        "all",
        "set-profile",
        profile,
    })
end

local function createPanel()
    return ui.column({
        gap = 12,
        padding = 16,
    }, {
        ui.label({
            text = "Cooling profile",
        }),

        ui.row({
            gap = 8,
            align = "center",
        }, {
            ui.button({
                text = "Quiet",
                flexGrow = 1,
                onClick = function()
                    setProfile("quiet")
                end,
            }),

            ui.button({
                text = "Balanced",
                flexGrow = 1,
                onClick = function()
                    setProfile("balanced")
                end,
            }),

            ui.button({
                text = "Performance",
                flexGrow = 1,
                onClick = function()
                    setProfile("performance")
                end,
            }),

            ui.button({
                text = "MAX",
                flexGrow = 1,
                onClick = function()
                    setProfile("max")
                end,
            }),
        }),
    })
end

function onOpen()
    panel.render(createPanel())
end
