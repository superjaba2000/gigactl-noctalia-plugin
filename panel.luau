local function sendToService(event, payload)
    noctalia.runAsync({
        "noctalia",
        "msg",
        "plugin",
        "superjaba2000/gigactl:service",
        "all",
        event,
        payload,
    })
end

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
                    sendToService("please-set-profile", "quiet") 
                end,
            }),
            ui.button({
                text = "Balanced",
                flexGrow = 1,
                selected = activeProfile == "balanced",
                onClick = function() 
                    sendToService("please-set-profile", "balanced") 
                end,
            }),
            ui.button({
                text = "Performance",
                flexGrow = 1,
                selected = activeProfile == "performance",
                onClick = function() 
                    sendToService("please-set-profile", "performance") 
                end,
            }),
            ui.button({
                text = "MAX",
                flexGrow = 1,
                selected = activeProfile == "max",
                onClick = function() 
                    sendToService("please-set-profile", "max") 
                end,
            }),
        }),

        ui.row({ gap = 18, align = "center" }, {
            ui.button({
                text = "Manual",
                flexGrow = 1,
                selected = activeProfile == "manual",
                onClick = function() 
                    sendToService("please-set-profile", "manual") 
                end,
            }),

            ui.slider({
                value = manualFanSpeed,
                min = 0,
                max = 100,
                step = 1,
                flexGrow = 2.5,

                onChange = function(value)
                    noctalia.state.set("manual-fan-speed", tonumber(value))
                end,

                onDragEnd = function()
                    local speed = noctalia.state.get("manual-fan-speed") or 0

                    sendToService("please-set-fan-speed", tostring(speed))
                end,
            }),

            ui.label({
                text = tostring(manualFanSpeed) .. "%",
                flexGrow = 0,
            }),
        }),
    })
end

function onIpc(event, payload)
    if event == "set-profile" or event == "set-fan-speed" then
        panel.render(createPanel())
    end
end

function onOpen()
    panel.render(createPanel())
end