-- Applies the server's synced time & weather locally.
local U = CES.Util

local world = nil       -- last state from server
local base = nil        -- { hour, minute, at = GetGameTimer() }
local appliedWeather = nil

local function currentTime()
    if not world or not base then return nil end
    if world.freeze then return base.hour, base.minute end
    local elapsed = math.floor((GetGameTimer() - base.at) / (world.minuteDuration or 2000))
    local total = (base.hour * 60 + base.minute + elapsed) % 1440
    return math.floor(total / 60), total % 60
end
CES.GetWorldTime = currentTime

function CES.GetWorld() return world end

local function applyWeather(force)
    if not world then return end
    if force or appliedWeather ~= world.weather then
        appliedWeather = world.weather
        -- SET_WEATHER_TYPE(weatherHash, p1, p2, overrideNetwork, transitionTime, p5)
        U.Invoke(0x59174F1AFE095B5A, GetHashKey(world.weather), true, false, true, (world.transition or 0.0) + 0.0, false)
    end
end

RegisterNetEvent('ces_menu:cl:world', function(state)
    if not state or not state.enabled then return end
    world = state
    base = { hour = state.hour, minute = state.minute, at = GetGameTimer() }
    applyWeather(false)
    if CES.Menu.open and CES.Menu.current and CES.Menu.current.id == 'world' then CES.Menu.Refresh() end
end)

if Config.World.Enabled then
    CreateThread(function()
        Wait(1000)
        local state = CES.Callback('getWorld')
        if type(state) == 'table' then
            state.transition = 0.0
            TriggerEvent('ces_menu:cl:world', state)
        end
        while true do
            local h, m = currentTime()
            if h then
                U.Invoke(0x669E223E64B1903C, h, m, 0, 0, true) -- NETWORK_CLOCK_TIME_OVERRIDE
            end
            Wait(1000)
        end
    end)
end
