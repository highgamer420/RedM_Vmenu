CES.World = {
    enabled = Config.World.Enabled,
    hour = Config.World.StartHour or 12,
    minute = 0,
    weather = Config.World.StartWeather or 'SUNNY',
    freeze = false,
    transition = 0.0,
    minuteDuration = Config.World.MinuteDuration,
}

function CES.BroadcastWorld(target)
    TriggerClientEvent('ces_menu:cl:world', target or -1, CES.World)
end

if Config.World.Enabled then
    CreateThread(function()
        local sinceBroadcast = 0
        while true do
            Wait(Config.World.MinuteDuration)
            local W = CES.World
            if not W.freeze then
                W.minute = W.minute + 1
                if W.minute >= 60 then
                    W.minute = 0
                    W.hour = (W.hour + 1) % 24
                end
            end
            sinceBroadcast = sinceBroadcast + Config.World.MinuteDuration
            if sinceBroadcast >= 30000 then
                sinceBroadcast = 0
                W.transition = 0.0
                CES.BroadcastWorld()
            end
        end
    end)
end

CES.RegisterCallback('getWorld', nil, function()
    return CES.World
end)

CES.RegisterCallback('setTime', 'world.time', function(src, hour, minute)
    if not Config.World.Enabled then return false, 'World sync is disabled.' end
    hour, minute = tonumber(hour), tonumber(minute) or 0
    if not hour or hour < 0 or hour > 23 or minute < 0 or minute > 59 then return false, 'Invalid time.' end
    CES.World.hour, CES.World.minute = math.floor(hour), math.floor(minute)
    CES.World.transition = 0.0
    CES.BroadcastWorld()
    CES.Log(src, 'Set time', ('%02d:%02d'):format(CES.World.hour, CES.World.minute))
    return true
end)

CES.RegisterCallback('freezeTime', 'world.freezetime', function(src, state)
    if not Config.World.Enabled then return false, 'World sync is disabled.' end
    CES.World.freeze = state and true or false
    CES.BroadcastWorld()
    CES.Log(src, 'Freeze time', tostring(CES.World.freeze))
    return true
end)

CES.RegisterCallback('setWeather', 'world.weather', function(src, weather)
    if not Config.World.Enabled then return false, 'World sync is disabled.' end
    local valid = false
    for _, w in ipairs(Config.World.Weathers) do if w == weather then valid = true break end end
    if not valid then return false, 'Unknown weather type.' end
    CES.World.weather = weather
    CES.World.transition = Config.World.TransitionTime
    CES.BroadcastWorld()
    CES.World.transition = 0.0
    CES.Log(src, 'Set weather', weather)
    return true
end)
