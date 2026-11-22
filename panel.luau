local PLUGIN_ID = "superjaba2000/gigactl-noctalia-plugin"

local function sendToService(event, payload)
    noctalia.runAsync({"noctalia", "msg", "plugin", PLUGIN_ID .. ":service", "all", event, payload })
end

local function formatPercentage(value)
    local text = tostring(value) .. "%"
    return string.rep(" ", 4 - #text) .. text
end

local function createPanel()
    local activeProfile = noctalia.state.get("active-profile") or "unknown"
    local manualFanSpeed = noctalia.state.get("manual-fan-speed") or 24
    local keyboardBrightness = noctalia.state.get("keyboard-brightness") or 0

    return ui.column({
        gap = 8,
        padding = 16,
    }, {

        -- COOLING PROFILES

        ui.row({ gap = 8, align = "center" }, {
            ui.glyph({ name = "car-fan", size = 18, color = "text-muted"}),
            ui.label({ text = noctalia.tr("panel.cooling.title"), fontWeight = "bold", fontSize = 14 }),
        }),

        ui.row({ gap = 8, align = "center" }, {
            ui.button({
                text = noctalia.tr("panel.cooling.quiet"),
                flexGrow = 1,
                selected = activeProfile == "quiet",
                onClick = function() 
                    sendToService("please-set-profile", "quiet") 
                end,
            }),
            ui.button({
                text = noctalia.tr("panel.cooling.balanced"),
                flexGrow = 1,
                selected = activeProfile == "balanced",
                onClick = function() 
                    sendToService("please-set-profile", "balanced") 
                end,
            }),
            ui.button({
                text = noctalia.tr("panel.cooling.performance"),
                flexGrow = 1,
                selected = activeProfile == "performance",
                onClick = function() 
                    sendToService("please-set-profile", "performance") 
                end,
            }),
            ui.button({
                text = noctalia.tr("panel.cooling.max"),
                flexGrow = 1,
                selected = activeProfile == "max",
                onClick = function() 
                    sendToService("please-set-profile", "max") 
                end,
            }),
        }),

        ui.row({ gap = 24, align = "center" }, {
            ui.button({
                text = noctalia.tr("panel.cooling.manual"),
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
                    text = formatPercentage(manualFanSpeed),
                    flexGrow = 0,
                }),
            }),
        }),

        -- KEYBOARD BACKLIGHT

        ui.column({ height = 12 }, {}),

        ui.column({ gap = 0 }, {
            ui.row({ gap = 8, align = "center" }, {
                ui.glyph({ name = "keyboard", size = 18, color = "text-muted"}),
                ui.label({ text = noctalia.tr("panel.keyboard.title"), fontWeight = "bold", fontSize = 14 }),
            }),

            ui.row({ gap = 24, align = "center" }, {
                ui.label({
                    text = noctalia.tr("panel.keyboard.brightness"),
                    align = "center",
                    flexGrow = 1,
                }),

                ui.row({ gap = 8, align = "center", flexGrow = 3 }, {
                    ui.slider({
                        value = noctalia.state.get("keyboard-brightness") or 0,
                        min = 0,
                        max = 100,
                        step = 1,
                        flexGrow = 3,
                        onChange = function(value)
                            noctalia.state.set("keyboard-brightness", tonumber(value))
                            panel.render(createPanel())
                            sendToService("please-set-keyboard-brightness", tostring(value))
                        end,
                    }),
                    ui.label({
                        text = formatPercentage(keyboardBrightness),
                        flexGrow = 0,
                    }),
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
