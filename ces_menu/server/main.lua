CES = CES or {}
local RES = GetCurrentResourceName()

-- ─── Permissions ────────────────────────────────────────────
function CES.HasPerm(src, perm)
    if src == 0 then return true end
    if Config.DisabledPermissions[perm] then return false end
    if Config.PublicPermissions[perm] then return true end
    return IsPlayerAceAllowed(tostring(src), 'ces_menu.' .. perm)
end

function CES.HasAnyPerm(src, perms)
    if type(perms) ~= 'table' then return CES.HasPerm(src, perms) end
    for _, p in ipairs(perms) do
        if CES.HasPerm(src, p) then return true end
    end
    return false
end

function CES.GetPermTable(src)
    local t = {}
    for _, p in ipairs(CES_PERMISSIONS) do
        if CES.HasPerm(src, p.name) then t[p.name] = true end
    end
    return t
end

-- Staff cannot act on "immune" players unless they are immune themselves.
function CES.CanTarget(src, target)
    if src == target then return true end
    if CES.HasPerm(target, 'players.immune') and not CES.HasPerm(src, 'players.immune') then
        return false
    end
    return true
end

function CES.IsOnline(id)
    id = tonumber(id)
    return id ~= nil and GetPlayerName(tostring(id)) ~= nil
end

function CES.Name(src)
    if src == 0 then return 'Console' end
    return GetPlayerName(tostring(src)) or ('ID ' .. tostring(src))
end

function CES.Notify(target, msg, kind, title)
    TriggerClientEvent('ces_menu:cl:notify', target, msg, kind or 'info', title)
end

-- ─── Logging ────────────────────────────────────────────────
function CES.Log(src, action, details)
    local line = ('[%s] %s (%s) -> %s%s'):format(RES, CES.Name(src), tostring(src), action, details and (': ' .. details) or '')
    if Config.Logging.Console then print(line) end
    if Config.Logging.Webhook and Config.Logging.Webhook ~= '' then
        PerformHttpRequest(Config.Logging.Webhook, function() end, 'POST', json.encode({
            username = Config.Logging.WebhookName,
            embeds = {{
                title = action,
                description = details or '',
                color = 11740700,
                footer = { text = ('%s (ID %s)'):format(CES.Name(src), tostring(src)) },
                timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
            }},
        }), { ['Content-Type'] = 'application/json' })
    end
end

-- ─── Callbacks ──────────────────────────────────────────────
local Callbacks = {}

--- Register a client->server callback guarded by a permission (string, list = any-of, or nil = public).
function CES.RegisterCallback(name, perm, fn)
    Callbacks[name] = { perm = perm, fn = fn }
end

RegisterNetEvent('ces_menu:sv:cb', function(name, reqId, ...)
    local src = source
    local cb = Callbacks[name]
    if not cb then return end
    if cb.perm and not CES.HasAnyPerm(src, cb.perm) then
        CES.Log(src, 'Permission denied', ('callback "%s"'):format(tostring(name)))
        TriggerClientEvent('ces_menu:cl:cb', src, reqId, false, 'You do not have permission for that.')
        return
    end
    local args = { ... }
    CreateThread(function()
        local results = { pcall(cb.fn, src, table.unpack(args)) }
        if not results[1] then
            print(('[%s] callback %s errored: %s'):format(RES, name, tostring(results[2])))
            TriggerClientEvent('ces_menu:cl:cb', src, reqId, false, 'Server error.')
            return
        end
        TriggerClientEvent('ces_menu:cl:cb', src, reqId, table.unpack(results, 2))
    end)
end)

CES.RegisterCallback('getPerms', nil, function(src)
    return CES.GetPermTable(src)
end)

RegisterNetEvent('ces_menu:sv:ready', function()
    local src = source
    TriggerClientEvent('ces_menu:cl:perms', src, CES.GetPermTable(src))
end)

-- Refresh everyone's permissions (handy after editing ACEs live).
RegisterCommand('cesmenu_refreshperms', function(src)
    if src ~= 0 and not IsPlayerAceAllowed(tostring(src), 'command.cesmenu_refreshperms') then return end
    for _, id in ipairs(GetPlayers()) do
        TriggerClientEvent('ces_menu:cl:perms', id, CES.GetPermTable(tonumber(id)))
    end
    print(('[%s] permissions refreshed for all players'):format(RES))
end, true)
