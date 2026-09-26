local RES = GetCurrentResourceName()
local BAN_FILE = 'data/bans.json'
local Bans = {}

local function load()
    local raw = LoadResourceFile(RES, BAN_FILE)
    Bans = (raw and json.decode(raw)) or {}
end

local function save()
    SaveResourceFile(RES, BAN_FILE, json.encode(Bans, { indent = true }), -1)
end

local function purgeExpired()
    local now, changed = os.time(), false
    for i = #Bans, 1, -1 do
        if Bans[i].expires ~= 0 and Bans[i].expires <= now then
            table.remove(Bans, i)
            changed = true
        end
    end
    if changed then save() end
end

local function newId()
    return ('%X%03X'):format(os.time(), math.random(0, 4095))
end

function CES.CollectIdentifiers(src)
    local ids, tokens = {}, {}
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if Config.Bans.MatchIP or not id:find('^ip:') then ids[#ids + 1] = id end
    end
    if Config.Bans.UseTokens and GetNumPlayerTokens then
        for i = 0, GetNumPlayerTokens(src) - 1 do
            tokens[#tokens + 1] = GetPlayerToken(src, i)
        end
    end
    return ids, tokens
end

local function findBan(ids, tokens)
    purgeExpired()
    local lookup = {}
    for _, v in ipairs(ids) do lookup[v] = true end
    for _, v in ipairs(tokens) do lookup[v] = true end
    for _, ban in ipairs(Bans) do
        for _, v in ipairs(ban.identifiers or {}) do if lookup[v] then return ban end end
        for _, v in ipairs(ban.tokens or {}) do if lookup[v] then return ban end end
    end
end

local function formatRemaining(ban)
    if ban.expires == 0 then return 'permanently' end
    local s = ban.expires - os.time()
    local d, h, m = math.floor(s / 86400), math.floor(s % 86400 / 3600), math.floor(s % 3600 / 60)
    if d > 0 then return ('for %dd %dh more'):format(d, h) end
    if h > 0 then return ('for %dh %dm more'):format(h, m) end
    return ('for %dm more'):format(math.max(m, 1))
end

local function banMessage(ban)
    return ('You are banned %s.\nReason: %s\nBan ID: %s\n%s'):format(
        formatRemaining(ban), ban.reason, ban.id, Config.Bans.AppealText or '')
end

function CES.BanPlayer(src, target, hours, reason)
    local ids, tokens = CES.CollectIdentifiers(target)
    local ban = {
        id = newId(),
        name = CES.Name(target),
        identifiers = ids,
        tokens = tokens,
        reason = reason,
        by = CES.Name(src),
        created = os.time(),
        expires = (hours and hours > 0) and (os.time() + math.floor(hours * 3600)) or 0,
    }
    Bans[#Bans + 1] = ban
    save()
    DropPlayer(tostring(target), banMessage(ban))
    return ban
end

function CES.Unban(banId)
    for i, ban in ipairs(Bans) do
        if ban.id == banId then
            table.remove(Bans, i)
            save()
            return ban
        end
    end
end

function CES.GetBans()
    purgeExpired()
    local list = {}
    for _, b in ipairs(Bans) do
        list[#list + 1] = {
            id = b.id, name = b.name, reason = b.reason, by = b.by,
            created = os.date('%Y-%m-%d %H:%M', b.created),
            expires = b.expires == 0 and 'Permanent' or os.date('%Y-%m-%d %H:%M', b.expires),
        }
    end
    return list
end

AddEventHandler('playerConnecting', function(_, _, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)
    deferrals.update('Checking ban list...')
    local ids, tokens = CES.CollectIdentifiers(src)
    local ban = findBan(ids, tokens)
    if ban then
        deferrals.done(banMessage(ban))
    else
        deferrals.done()
    end
end)

load()
