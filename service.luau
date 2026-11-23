local PLUGIN_ID = "superjaba2000/gigactl-noctalia-plugin"
local MAX_FAN_ATTEMPTS = 3
local UPDATE_INTERVAL = 1000

local function increaseSaturation(r, g, b, factor)
    r, g, b = r / 255, g / 255, b / 255

    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local delta = max - min

    local h, s, v = 0, 0, max

    if max ~= 0 then
        s = delta / max
    end

    if delta ~= 0 then
        if max == r then
            h = ((g - b) / delta) % 6
        elseif max == g then
            h = (b - r) / delta + 2
        else
            h = (r - g) / delta + 4
        end

        h = h * 60
    end

    s = math.min(1, s * factor)

    local c = v * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = v - c

    local rp, gp, bp

    if h < 60 then
        rp, gp, bp = c, x, 0
    elseif h < 120 then
        rp, gp, bp = x, c, 0
    elseif h < 180 then
        rp, gp, bp = 0, c, x
    elseif h < 240 then
        rp, gp, bp = 0, x, c
    elseif h < 300 then
        rp, gp, bp = x, 0, c
    else
        rp, gp, bp = c, 0, x
    end

    return
        math.floor((rp + m) * 255 + 0.5),
        math.floor((gp + m) * 255 + 0.5),
        math.floor((bp + m) * 255 + 0.5)
end

local function sendToPanelAndWidget(event, payload)
    noctalia.runAsync({"noctalia", "msg", "plugin", PLUGIN_ID .. ":panel", "all", event, payload })
    noctalia.runAsync({"noctalia", "msg", "plugin", PLUGIN_ID .. ":widget", "all", event, payload })
end

local fanSpeedBusy = false
local pendingFanSpeed = nil

local function pleaseSetBrightness(brightness)
    brightness = tonumber(brightness)

    if not brightness or brightness < 0 or brightness > 255 then
        noctalia.notify(noctalia.tr("messages.invalid_brightness"))
        return
    end

    brightness = math.floor(brightness)

    noctalia.runAsync({
        "busctl",
        "--system",
        "call",
        "io.github.smairio.gigactl",
        "/io/github/smairio/gigactl",
        "io.github.smairio.gigactl.Control",
        "SetKeyboardBrightness",
        "u",
        tostring(brightness),
    }, function(result)
        if result.exitCode ~= 0 then
            noctalia.notify(noctalia.tr("messages.brightness_error") .. tostring(result.stderr))
            noctalia.log("gigactl: failed to set keyboard brightness to " .. tostring(brightness) .. ": " .. tostring(result.stderr))
            return
        end

        noctalia.state.set("keyboard-brightness", brightness)
        sendToPanelAndWidget("set-keyboard-brightness", tostring(brightness))
    end)
end

local function pleaseChangeColor(color)
    if type(color) ~= "string" then
        noctalia.notify(noctalia.tr("messages.invalid_color"))
        return
    end

    local hex = color:match("^#(%x%x%x%x%x%x)$")
    if not hex then
        noctalia.notify(noctalia.tr("messages.invalid_color"))
        return
    end

    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    r, g, b = increaseSaturation(r, g, b, 1.3)
    local hex = string.format("%02X%02X%02X", r, g, b)
    local normalizedColor = "#" .. hex:upper()

    noctalia.runAsync({
        "busctl",
        "--system",
        "call",
        "io.github.smairio.gigactl",
        "/io/github/smairio/gigactl",
        "io.github.smairio.gigactl.Control",
        "SetKeyboardColor",
        "uuu",
        tostring(r),
        tostring(g),
        tostring(b),
    }, function(result)
        if result.exitCode ~= 0 then
            noctalia.notify(noctalia.tr("messages.color_error") .. tostring(result.stderr))
            noctalia.log("gigactl: failed to set keyboard color to " .. normalizedColor .. ": " .. tostring(result.stderr))
            return
        end

        noctalia.state.set("keyboard-color", normalizedColor)
        sendToPanelAndWidget("set-keyboard-color", normalizedColor)
    end)
end

local function pleaseSetFanSpeed(speed, attempt)
    speed = tonumber(speed)
    attempt = attempt or 1

    if not speed or speed < 0 or speed > 100 then
        noctalia.notify(noctalia.tr("messages.invalid_speed"))
        return
    end

    speed = math.floor(speed)

    if fanSpeedBusy then
        pendingFanSpeed = speed
        return
    end

    fanSpeedBusy = true

    local function finish()
        if pendingFanSpeed ~= nil then
            local nextSpeed = pendingFanSpeed
            pendingFanSpeed = nil
            fanSpeedBusy = false
            pleaseSetFanSpeed(nextSpeed, 1)
        else
            fanSpeedBusy = false
        end
    end

    local executeWithAttempt

    local function execute()
        noctalia.runAsync({
            "busctl",
            "--system",
            "call",
            "io.github.smairio.gigactl",
            "/io/github/smairio/gigactl",
            "io.github.smairio.gigactl.Control",
            "SetFanDuty",
            "uu",
            "0",
            tostring(speed),
        }, function(result)
            if result.exitCode == 0 then
                noctalia.state.set("manual-fan-speed", speed)
                noctalia.state.set("active-profile", "manual")
                sendToPanelAndWidget("set-fan-speed", tostring(speed))
                sendToPanelAndWidget("set-profile", "manual")
                finish()
                return
            end

            if pendingFanSpeed ~= nil then
                local nextSpeed = pendingFanSpeed
                pendingFanSpeed = nil
                speed = nextSpeed
                executeWithAttempt(1)
                return
            end

            if attempt < MAX_FAN_ATTEMPTS then
                executeWithAttempt(attempt + 1)
                return
            end

            noctalia.notify(noctalia.tr("messages.fan_error"))
            noctalia.log("gigactl: failed to set fan speed to " .. tostring(speed) .. ": " .. tostring(result.stderr))

            finish()
        end)
    end

    executeWithAttempt = function(nextAttempt)
        attempt = nextAttempt
        execute()
    end

    execute()
end

local function pleaseSetProfile(profile)
    local profiles = {
        quiet = true,
        balanced = true,
        performance = true,
        max = true,
        manual = true,
    }

    if not profiles[profile] then
        noctalia.notify(noctalia.tr("messages.unknown_profile") .. tostring(profile))
        return
    end

    if profile == "manual" then
        local fanSpeed = noctalia.state.get("manual-fan-speed") or 0
        pleaseSetFanSpeed(fanSpeed)
    else
        pendingFanSpeed = nil
        noctalia.runAsync({
            "busctl",
            "--system",
            "call",
            "io.github.smairio.gigactl",
            "/io/github/smairio/gigactl",
            "io.github.smairio.gigactl.Control",
            "SetProfile",
            "s",
            profile,
        }, function(result)
            if result.exitCode ~= 0 then
                noctalia.notify(noctalia.tr("messages.profile_error") .. tostring(result.stderr))
                return
            end

            noctalia.state.set("active-profile", profile)
            sendToPanelAndWidget("set-profile", profile)
        end)
        return
    end
end


function onIpc(event, payload)
    if event == "please-set-profile" then
        pleaseSetProfile(payload)
        return
    end

    if event == "please-set-fan-speed" then
        pleaseSetFanSpeed(payload)
        return
    end

    if event == "please-set-keyboard-brightness" then
        pleaseSetBrightness(payload)
        return
    end

    if event == "please-change-keyboard-color" then
        pleaseChangeColor(payload)
        return
    end

    if event == "please-set-keyboard-color-sync" then
        noctalia.state.set("keyboard-color-sync", payload == "true")
        sendToPanelAndWidget("set-keyboard-color-sync", payload)
        return
    end
end

local function readProfile()
    noctalia.runAsync({
        "busctl",
        "--system",
        "get-property",
        "io.github.smairio.gigactl",
        "/io/github/smairio/gigactl",
        "io.github.smairio.gigactl.Control",
        "ActiveProfile",
    }, function(result)
        if result.exitCode ~= 0 then
            noctalia.notify(noctalia.tr("messages.read_profile_error"))
            return
        end

        local profile = result.stdout:match('"([^"]+)"')

        if profile then
            noctalia.state.set("active-profile", profile)
        end
    end)
end

function onEnable()
    readProfile()
end

function update()
    noctalia.setUpdateInterval(UPDATE_INTERVAL)

    -- readProfile()
    local system_color= noctalia.getColor(noctalia.getConfig("system-color-key")) or "#FFFFFF"
    local keyboardColorSync = noctalia.state.get("keyboard-color-sync") or false
    local keyboardColor = noctalia.state.get("keyboard-color") or "#FFFFFF"

    if keyboardColorSync and keyboardColor ~= system_color then
        pleaseChangeColor(system_color)
    end
end
