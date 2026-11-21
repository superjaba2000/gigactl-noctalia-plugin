function onIpc(event, payload)
    print("IPC:", event, payload)

    if event == "set-profile" then
        local profile = payload

        if profile == "quiet"
            or profile == "balanced"
            or profile == "performance"
            or profile == "max"
        then
            -- Здесь будет вызов gigactl
            noctalia.notify("Set profile: " .. profile)
        end
    end
end