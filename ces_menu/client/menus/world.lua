local Menu = CES.Menu

local TIME_PRESETS = {
    { label = 'Dawn (05:00)',     h = 5 },
    { label = 'Morning (08:00)',  h = 8 },
    { label = 'Noon (12:00)',     h = 12 },
    { label = 'Afternoon (15:00)',h = 15 },
    { label = 'Evening (18:00)',  h = 18 },
    { label = 'Dusk (20:00)',     h = 20 },
    { label = 'Night (22:00)',    h = 22 },
    { label = 'Midnight (00:00)', h = 0 },
}

local function weatherIndex(w)
    for i, v in ipairs(Config.World.Weathers) do if v == w then return i end end
    return 1
end

local function pretty(w)
    return (w:sub(1, 1) .. w:sub(2):lower())
end

Menu.Register('world', {
    title = 'World',
    perms = { 'world.time', 'world.freezetime', 'world.weather' },
    visible = function() return Config.World.Enabled end,
    build = function(m)
        local world = CES.GetWorld() or {}
        local h, mi = CES.GetWorldTime()
        local now = h and ('%02d:%02d'):format(h, mi) or '--:--'

        m:separator(('Server time %s · %s'):format(now, pretty(world.weather or '?')))
        m:list({ id = 'preset', label = 'Set Time', perm = 'world.time', options = TIME_PRESETS,
            desc = 'Pick with ← →, press Enter to apply for everyone.',
            onSelect = function(_, opt)
                local ok, err = CES.Callback('setTime', opt.h, 0)
                CES.Result(ok, err, ('Time set to %02d:00.'):format(opt.h))
            end })
        m:slider({ id = 'hour', label = 'Hour', perm = 'world.time', min = 0, max = 23, step = 1, value = h or 12, format = '%02d:00',
            desc = 'Press Enter to apply.',
            onSelect = function(v)
                local ok, err = CES.Callback('setTime', v, 0)
                CES.Result(ok, err, ('Time set to %02d:00.'):format(v))
            end })
        m:checkbox({ label = 'Freeze Time', perm = 'world.freezetime', checked = world.freeze == true,
            onChange = function(v)
                local ok, err = CES.Callback('freezeTime', v)
                CES.Result(ok, err, v and 'Time frozen.' or 'Time unfrozen.')
            end })

        local labels = {}
        for i, w in ipairs(Config.World.Weathers) do labels[i] = pretty(w) end
        m:list({ id = 'weather', label = 'Weather', perm = 'world.weather', options = labels,
            index = weatherIndex(world.weather),
            desc = 'Pick with ← →, press Enter to apply for everyone.',
            onSelect = function(i)
                local w = Config.World.Weathers[i]
                local ok, err = CES.Callback('setWeather', w)
                CES.Result(ok, err, ('Weather changing to %s.'):format(pretty(w)))
            end })
    end,
})
