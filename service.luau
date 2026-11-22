local PLUGIN_ID = "superjaba2000/gigactl-noctalia-plugin"
local MAX_FAN_ATTEMPTS = 3

local function sendToPanelAndWidget(event, payload)
    noctalia.runAsync({"noctalia", "msg", "plugin", PLUGIN_ID .. ":panel", "all", event, payload })
    noctalia.runAsync({"noctalia", "msg", "plugin", PLUGIN_ID .. ":widget", "all", event, payload })
end

local fanSpeedBusy = false
local pendingFanSpeed = nil

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
end

local UPDATE_INTERVAL = 2000

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
    noctalia.setUpdateInterval(UPDATE_INTERVAL)
    readProfile()
end

function update()
    readProfile()
end
