local PLUGIN_ID = "superjaba2000/gigactl-noctalia-plugin"

local function sendToService(event, payload)
    noctalia.runAsync({"noctalia", "msg", "plugin", PLUGIN_ID .. ":service", "all", event, payload })
end

local function createPanel()
    local activeProfile = noctalia.state.get("active-profile") or "unknown"
    local manualFanSpeed = noctalia.state.get("manual-fan-speed") or 24

    return ui.column({
        gap = 12,
        padding = 16,
    }, {
        ui.row({ gap = 8, align = "center" }, {
            ui.glyph({ name = "gauge", size = 18, color = "text-muted"}),
            ui.label({ text = noctalia.tr("panel.title"), fontStyle = "bold" }),
        }),

        ui.row({ gap = 8, align = "center" }, {
            ui.button({
                text = noctalia.tr("panel.quiet"),
                flexGrow = 1,
                selected = activeProfile == "quiet",
                onClick = function() 
                    sendToService("please-set-profile", "quiet") 
                end,
            }),
            ui.button({
                text = noctalia.tr("panel.balanced"),
                flexGrow = 1,
                selected = activeProfile == "balanced",
                onClick = function() 
                    sendToService("please-set-profile", "balanced") 
                end,
            }),
            ui.button({
                text = noctalia.tr("panel.performance"),
                flexGrow = 1,
                selected = activeProfile == "performance",
                onClick = function() 
                    sendToService("please-set-profile", "performance") 
                end,
            }),
            ui.button({
                text = noctalia.tr("panel.max"),
                flexGrow = 1,
                selected = activeProfile == "max",
                onClick = function() 
                    sendToService("please-set-profile", "max") 
                end,
            }),
        }),

        ui.row({ gap = 24, align = "center" }, {
            ui.button({
                text = noctalia.tr("panel.manual"),
                flexGrow = 1,
                selected = activeProfile == "manual",
                onClick = function() 
                    sendToService("please-set-profile", "manual") 
                end,
            }),

            ui.row({ gap = 8, align = "center", flexGrow = 3 }, {
                ui.slider({
                    value = manualFanSpeed,
                    enabled = activeProfile == "manual",
                    min = 0,
                    max = 100,
                    step = 1,
                    flexGrow = 1,

                    onChange = function(value)
                        noctalia.state.set("manual-fan-speed", tonumber(value))
                        panel.render(createPanel())
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
