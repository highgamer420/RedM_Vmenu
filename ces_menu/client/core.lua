CES = CES or {}
CES.Perms = {}
CES.State = {
    god = false, invisible = false, stamina = false, deadeye = false, noragdoll = false,
    infAmmo = false, horseGod = false,
    coords = false, names = false, blips = false, deleteGun = false,
    noclip = false, noclipSpeed = Config.Noclip.DefaultSpeed,
    tpWithMount = true, mountOnSpawn = true, replaceSpawned = true,
}

function CES.Debug(...)
    if Config.Debug then print('[ces_menu]', ...) end
end

-- ─── Permissions ────────────────────────────────────────────
function CES.HasPerm(perm)
    if not perm then return true end
    if type(perm) == 'table' then
        for _, p in ipairs(perm) do if CES.Perms[p] then return true end end
        return false
    end
    return CES.Perms[perm] == true
end

RegisterNetEvent('ces_menu:cl:perms', function(perms)
    CES.Perms = perms or {}
    if CES.Menu and CES.Menu.Refresh then CES.Menu.Refresh() end
end)

-- ─── Server callbacks ───────────────────────────────────────
local pending, reqId = {}, 0

--- Call a server callback and wait for the result (must be called from a thread).
function CES.Callback(name, ...)
    reqId = reqId + 1
    local id = reqId
    local p = promise.new()
    pending[id] = p
    TriggerServerEvent('ces_menu:sv:cb', name, id, ...)
    SetTimeout(10000, function()
        if pending[id] then
            pending[id] = nil
            p:resolve({ false, 'Server did not respond.' })
        end
    end)
    local result = Citizen.Await(p)
    return table.unpack(result)
end

RegisterNetEvent('ces_menu:cl:cb', function(id, ...)
    local p = pending[id]
    if p then
        pending[id] = nil
        p:resolve({ ... })
    end
end)

-- ─── Notifications ──────────────────────────────────────────
function CES.Notify(msg, kind, title, duration)
    SendNUIMessage({ action = 'notify', message = msg, kind = kind or 'info', title = title, duration = duration })
end

RegisterNetEvent('ces_menu:cl:notify', function(msg, kind, title)
    CES.Notify(msg, kind, title)
end)

RegisterNetEvent('ces_menu:cl:announce', function(text, from)
    SendNUIMessage({ action = 'announce', message = text, from = from })
end)

--- Show the result of a server action as a toast. Returns ok.
function CES.Result(ok, msgOrData, successText)
    if ok then
        if successText then CES.Notify(successText, 'success') end
        return true
    end
    CES.Notify(msgOrData or 'Action failed.', 'error')
    return false
end

-- ─── Settings (per player, stored in KVP) ───────────────────
local SETTINGS_KEY = 'ces_menu:settings'
CES.Settings = {}

function CES.LoadSettings()
    local raw = GetResourceKvpString(SETTINGS_KEY)
    local saved = raw and json.decode(raw) or {}
    for k, v in pairs(Config.Defaults) do
        CES.Settings[k] = saved[k] ~= nil and saved[k] or v
    end
end

function CES.SaveSettings()
    SetResourceKvp(SETTINGS_KEY, json.encode(CES.Settings))
    SendNUIMessage({ action = 'settings', settings = CES.Settings, title = Config.MenuTitle, subtitle = Config.MenuSubtitle, mouseKey = Config.Keys.MouseMode or '' })
end

CES.LoadSettings()

RegisterNUICallback('ready', function(_, cb)
    cb({})
    SendNUIMessage({ action = 'settings', settings = CES.Settings, title = Config.MenuTitle, subtitle = Config.MenuSubtitle, mouseKey = Config.Keys.MouseMode or '' })
end)

CreateThread(function()
    TriggerServerEvent('ces_menu:sv:ready')
end)
