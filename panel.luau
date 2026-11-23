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
    local keyboardColorSync = noctalia.state.get("keyboard-color-sync") or false
    local systemColorKey = noctalia.state.get("system-color-key") or "secondary"
    local keyboardColor

    if keyboardColorSync then
        keyboardColor = noctalia.getColor(systemColorKey) or "#FFFFFF"
    else
        keyboardColor = noctalia.state.get("keyboard-color") or "#FFFFFF"
    end

    local selectedColorKeyIndex = 0

    if systemColorKey == "primary" then
        selectedColorKeyIndex = 0
    elseif systemColorKey == "secondary" then
        selectedColorKeyIndex = 1
    elseif systemColorKey == "tertiary" then
        selectedColorKeyIndex = 2
    elseif systemColorKey == "error" then
        selectedColorKeyIndex = 3
    end

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

            ui.row({ gap = 24, align = "center" }, {
                ui.label({
                    text = noctalia.tr("panel.keyboard.as_in_system"),
                    flexGrow = 0,
                }),
                ui.spacer({ flexGrow = 1 }),
                ui.select({
                    enabled = keyboardColorSync,
                    options = {
                        noctalia.tr("panel.keyboard.primary"),
                        noctalia.tr("panel.keyboard.secondary"),
                        noctalia.tr("panel.keyboard.tertiary"),
                        noctalia.tr("panel.keyboard.error"),
                    },
                    selectedIndex = selectedColorKeyIndex,
                    controlSize = "md",
                    onChange = function(index)
                        local numericIndex = tonumber(index)
                        if numericIndex == nil then
                            return
                        end

                        local colorKey = numericIndex == 0 and "primary"
                            or numericIndex == 1 and "secondary"
                            or numericIndex == 2 and "tertiary"
                            or numericIndex == 3 and "error"
                            or nil

                        if not colorKey then
                            return
                        end

                        noctalia.state.set("system-color-key", colorKey)

                        if keyboardColorSync then
                            local systemColor = noctalia.getColor(colorKey) or "#FFFFFF"
                            sendToService("please-change-keyboard-color", systemColor)
                        end

                        panel.render(createPanel())
                    end,
                }),
                ui.toggle({
                    flexGrow = 0,
                    checked = keyboardColorSync,
                    onChange = function(value)
                        noctalia.state.set("keyboard-color-sync", value)
                        sendToService("please-set-keyboard-color-sync", tostring(value))

                        if value then
                            local systemColorKey = noctalia.state.get("system-color-key") or "secondary"
                            local systemColor = noctalia.getColor(systemColorKey) or "#FFFFFF"
                            sendToService("please-change-keyboard-color", systemColor)
                        end

                        panel.render(createPanel())
                    end,
                }),
            }),

            ui.column({ height = 8 }, {}),

            ui.row({ gap = 24, align = "center" }, {
                ui.colorPicker({
                    value = keyboardColor,
                    width = 100,
                    flexGrow = 3,
                    inputs = "hex",
                    enabled = not keyboardColorSync,
                    onChange = function(color)
                        noctalia.state.set("keyboard-color", color)
                        sendToService("please-change-keyboard-color", color)
                        keyboardColor = color
                        --panel.render(createPanel())
                    end,
                    onChangeEnd = function(color)
                        noctalia.state.set("keyboard-color", color)
                        sendToService("please-change-keyboard-color", color)
                        keyboardColor = color
                        --panel.render(createPanel())
                    end,
                }),
            }),
        }),
    })
end

function onIpc(event, payload)
    if event == "set-profile"
        or event == "set-fan-speed"
        or event == "set-keyboard-brightness"
        --or event == "set-keyboard-color"
        or event == "set-keyboard-color-sync"
    then
        panel.render(createPanel())
    end
end

function onOpen()
    panel.render(createPanel())
end
