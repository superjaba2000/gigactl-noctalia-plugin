function onIpc(event, payload)
    if event ~= "set-profile" then
        return
    end

    local profile = payload

    local labels = {
        quiet = "Quiet",
        balanced = "Balanced",
        performance = "Performance",
        max = "MAX",
    }

    local label = labels[profile]

    if not label then
        noctalia.notify("Unknown cooling profile: " .. tostring(profile))
        return
    end

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

    noctalia.notify("Requested cooling profile: " .. label)
end