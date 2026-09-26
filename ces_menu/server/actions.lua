-- Server-side player / admin actions. Every callback is permission-checked
-- in CES.RegisterCallback before it runs, and target checks happen here.

local function coordsOf(id)
    local ped = GetPlayerPed(tostring(id))
    if not ped or ped == 0 then return nil end
    local c = GetEntityCoords(ped)
    return { x = c.x, y = c.y, z = c.z, h = GetEntityHeading(ped) }
end

local function checkTarget(src, target)
    target = tonumber(target)
    if not CES.IsOnline(target) then return nil, 'That player is no longer online.' end
    if not CES.CanTarget(src, target) then return nil, 'That player is immune.' end
    return target
end

local function clean(text, max)
    text = tostring(text or ''):gsub('[%c]', ' '):gsub('^%s+', ''):gsub('%s+$', '')
    if #text > (max or 250) then text = text:sub(1, max or 250) end
    return text
end

CES.RegisterCallback('getPlayers', 'players.view', function(src)
    local list = {}
    for _, id in ipairs(GetPlayers()) do
        local n = tonumber(id)
        list[#list + 1] = {
            id = n,
            name = GetPlayerName(id) or ('ID ' .. id),
            ping = GetPlayerPing(id),
            self = (n == src),
            immune = CES.HasPerm(n, 'players.immune'),
        }
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end)

CES.RegisterCallback('goto', 'players.goto', function(src, target)
    local t, err = checkTarget(src, target)
    if not t then return false, err end
    local c = coordsOf(t)
    if not c then return false, 'Could not find that player.' end
    CES.Log(src, 'Teleported to player', CES.Name(t))
    return true, c
end)

CES.RegisterCallback('bring', 'players.bring', function(src, target)
    local t, err = checkTarget(src, target)
    if not t then return false, err end
    local c = coordsOf(src)
    if not c then return false, 'Could not read your position.' end
    TriggerClientEvent('ces_menu:cl:teleport', t, { x = c.x + 1.0, y = c.y + 1.0, z = c.z })
    CES.Notify(t, ('You were brought to %s.'):format(CES.Name(src)), 'info', 'Staff')
    CES.Log(src, 'Brought player', CES.Name(t))
    return true
end)

CES.RegisterCallback('spectate', 'players.spectate', function(src, target)
    target = tonumber(target)
    if target == src then return false, 'You cannot spectate yourself.' end
    local t, err = checkTarget(src, target)
    if not t then return false, err end
    local c = coordsOf(t)
    if not c then return false, 'Could not find that player.' end
    CES.Log(src, 'Spectating', CES.Name(t))
    return true, c
end)

CES.RegisterCallback('freeze', 'players.freeze', function(src, target, state)
    local t, err = checkTarget(src, target)
    if not t then return false, err end
    TriggerClientEvent('ces_menu:cl:freeze', t, state and true or false)
    CES.Notify(t, state and 'You have been frozen by staff.' or 'You have been unfrozen.', 'warning', 'Staff')
    CES.Log(src, state and 'Froze player' or 'Unfroze player', CES.Name(t))
    return true
end)

CES.RegisterCallback('heal', 'players.heal', function(src, target)
    local t, err = checkTarget(src, target)
    if not t then return false, err end
    TriggerClientEvent('ces_menu:cl:heal', t)
    CES.Log(src, 'Healed player', CES.Name(t))
    return true
end)

CES.RegisterCallback('revive', 'players.revive', function(src, target)
    local t, err = checkTarget(src, target)
    if not t then return false, err end
    TriggerClientEvent('ces_menu:cl:revive', t)
    CES.Log(src, 'Revived player', CES.Name(t))
    return true
end)

CES.RegisterCallback('kill', 'players.kill', function(src, target)
    local t, err = checkTarget(src, target)
    if not t then return false, err end
    TriggerClientEvent('ces_menu:cl:kill', t)
    CES.Log(src, 'Killed player', CES.Name(t))
    return true
end)

CES.RegisterCallback('message', 'players.message', function(src, target, text)
    local t, err = checkTarget(src, target)
    if not t then return false, err end
    text = clean(text)
    if text == '' then return false, 'Message is empty.' end
    CES.Notify(t, text, 'info', ('Message from %s'):format(CES.Name(src)))
    CES.Log(src, 'Messaged player', ('%s: %s'):format(CES.Name(t), text))
    return true
end)

CES.RegisterCallback('kick', 'players.kick', function(src, target, reason)
    local t, err = checkTarget(src, target)
    if not t then return false, err end
    if t == src then return false, 'You cannot kick yourself.' end
    reason = clean(reason)
    if reason == '' then reason = 'No reason given' end
    local name = CES.Name(t)
    DropPlayer(tostring(t), ('Kicked by %s: %s'):format(CES.Name(src), reason))
    CES.Log(src, 'Kicked player', ('%s - %s'):format(name, reason))
    return true
end)

CES.RegisterCallback('ban', 'players.ban', function(src, target, hours, reason)
    local t, err = checkTarget(src, target)
    if not t then return false, err end
    if t == src then return false, 'You cannot ban yourself.' end
    hours = tonumber(hours) or 0
    reason = clean(reason)
    if reason == '' then reason = 'No reason given' end
    local name = CES.Name(t)
    local ban = CES.BanPlayer(src, t, hours, reason)
    CES.Log(src, 'Banned player', ('%s - %s (%s) [ban %s]'):format(name, reason, hours > 0 and (hours .. 'h') or 'permanent', ban.id))
    return true, ban.id
end)

CES.RegisterCallback('getBans', 'players.unban', function()
    return CES.GetBans()
end)

CES.RegisterCallback('unban', 'players.unban', function(src, banId)
    local ban = CES.Unban(tostring(banId))
    if not ban then return false, 'Ban not found.' end
    CES.Log(src, 'Unbanned', ('%s [ban %s]'):format(ban.name or '?', ban.id))
    return true
end)

CES.RegisterCallback('announce', 'players.announce', function(src, text)
    text = clean(text, 400)
    if text == '' then return false, 'Announcement is empty.' end
    TriggerClientEvent('ces_menu:cl:announce', -1, text, CES.Name(src))
    CES.Log(src, 'Announcement', text)
    return true
end)

CES.RegisterCallback('deleteEntity', { 'misc.deletegun', 'mounts.delete', 'vehicles.delete' }, function(src, netId)
    local ent = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if not ent or ent == 0 or not DoesEntityExist(ent) then return false end
    if GetEntityType(ent) == 1 and IsPedAPlayer(ent) then return false, 'You cannot delete players.' end
    DeleteEntity(ent)
    return true
end)
