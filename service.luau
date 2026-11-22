local function sendToPanelAndWidget(event, payload)
    noctalia.runAsync({"noctalia", "msg", "plugin", "superjaba2000/gigactl:panel", "all", event, payload })
    noctalia.runAsync({"noctalia", "msg", "plugin", "superjaba2000/gigactl:widget", "all", event, payload })
end

local function pleaseSetFanSpeed(speed)
    speed = tonumber(speed)

    if not speed or speed < 0 or speed > 100 then
        noctalia.notify("Invalid fan speed")
        return
    end

    speed = math.floor(speed)

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
        if result.exitCode ~= 0 then
            noctalia.notify(tostring(result.stderr))
            return
        end

        noctalia.state.set("manual-fan-speed", speed)
        noctalia.state.set("active-profile", "manual")

        sendToPanelAndWidget("set-fan-speed", tostring(speed))
    end)
end

local function pleaseSetProfile(profile)
    local labels = {
        quiet = "Quiet",
        balanced = "Balanced",
        performance = "Performance",
        max = "MAX",
        manual = "Manual",
    }

    local label = labels[profile]

    if not label then
        noctalia.notify("Unknown cooling profile: " .. tostring(profile))
        return
    end

    noctalia.state.set("active-profile", profile)

    if profile == "manual" then
        local fanSpeed = noctalia.state.get("manual-fan-speed") or 0

        local fanSpeed = noctalia.state.get("manual-fan-speed") or 0
        setFanSpeed(fanSpeed)
    else
        local ok = noctalia.runAsync({
            "busctl",
            "--system",
            "call",
            "io.github.smairio.gigactl",
            "/io/github/smairio/gigactl",
            "io.github.smairio.gigactl.Control",
            "SetProfile",
            "s",
            profile,
        })

        if not ok then
            noctalia.notify("Failed to start busctl")
            return
        end
    end

    sendToPanelAndWidget("set-profile", profile)
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
            noctalia.notify("gigactl: failed to read active profile")
            return
        end

        local profile = result.stdout:match('"([^"]+)"')

        if profile then
            noctalia.state.set("active-profile", profile)
        end
    end)
end

function onRun()
    noctalia.setUpdateInterval(UPDATE_INTERVAL)
    readProfile()
end

function update()
    readProfile()
end