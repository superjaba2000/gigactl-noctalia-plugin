local function createPanel()
    local activeProfile = noctalia.state.get("active-profile") or "unknown"
    local manualFanSpeed = noctalia.state.get("manual-fan-speed") or 0

    return ui.column({
        gap = 12,
        padding = 16,
    }, {
        ui.label({ text = "Cooling profile" }),

        ui.row({ gap = 8, align = "center" }, {
            ui.button({
                text = "Quiet",
                flexGrow = 1,
                selected = activeProfile == "quiet",
                onClick = function() 
                    pleaseSetProfile("quiet") 
                end,
            }),
            ui.button({
                text = "Balanced",
                flexGrow = 1,
                selected = activeProfile == "balanced",
                onClick = function() 
                    pleaseSetProfile("balanced") 
                end,
            }),
            ui.button({
                text = "Performance",
                flexGrow = 1,
                selected = activeProfile == "performance",
                onClick = function() 
                    pleaseSetProfile("performance") 
                end,
            }),
            ui.button({
                text = "MAX",
                flexGrow = 1,
                selected = activeProfile == "max",
                onClick = function() 
                    pleaseSetProfile("max") 
                end,
            }),
        }),

        ui.row({ gap = 18, align = "center" }, {
            ui.button({
                text = "manual",
                flexGrow = 1,
                selected = activeProfile == "manual",
                onClick = function() 
                    pleaseSetProfile("manual") 
                end,
            }),

            ui.slider({
                value = manualFanSpeed,
                min = 0,
                max = 100,
                step = 1,
                flexGrow = 3,

                onChange = function(value)
                    noctalia.state.set("manual-fan-speed", tonumber(value))
                end,

                onDragEnd = function()
                    local speed = noctalia.state.get("manual-fan-speed") or 0

                    noctalia.runAsync({
                        "noctalia",
                        "msg",
                        "plugin",
                        "superjaba2000/gigactl:service",
                        "all",
                        "set-fan-speed",
                        tostring(speed),
                    })
                end,
            })
        }),
    })
end

function pleaseSetProfile(profile)
    noctalia.runAsync({
        "noctalia",
        "msg",
        "plugin",
        "superjaba2000/gigactl:service",
        "all",
        "please-set-profile",
        profile,
    })
end

function onIpc(event, payload)
    if event ~= "set-profile" then
        return
    end

    panel.render(createPanel())
end

function onOpen()
    panel.render(createPanel())
end