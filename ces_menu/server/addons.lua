-- Loads addons.json (vMenu-style add-on content) and hands it to clients.
local RES = GetCurrentResourceName()
local FILE = 'addons.json'

CES.Addons = {}

local LISTS = { 'peds', 'horses', 'wagons', 'weapons', 'clothing', 'horse_tack', 'weapon_components' }

local function str(v) return type(v) == 'string' and v ~= '' and v or nil end

local function hashes(v)
    local out = {}
    if type(v) == 'string' then v = { v } end
    if type(v) ~= 'table' then return out end
    for _, h in ipairs(v) do
        if type(h) == 'string' or type(h) == 'number' then out[#out + 1] = h end
    end
    return out
end

local normalize = {
    model = function(e, kind)
        if type(e) == 'string' then e = { model = e } end
        if type(e) ~= 'table' or not str(e.model) then return nil end
        return { model = e.model, label = str(e.label) or e.model, category = str(e.category) or ('Addon ' .. kind) }
    end,
    weapons = function(e)
        if type(e) == 'string' then e = { hash = e } end
        if type(e) ~= 'table' or not str(e.hash) then return nil end
        return { hash = e.hash:upper(), label = str(e.label) or e.hash, category = str(e.category) or 'Addon Weapons' }
    end,
    comps = function(e)
        if type(e) ~= 'table' or not str(e.category) then return nil end
        local h = hashes(e.hashes or e.hash)
        if #h == 0 then return nil end
        local gender = str(e.gender) and e.gender:lower() or 'any'
        if gender ~= 'male' and gender ~= 'female' then gender = 'any' end
        return { category = e.category, label = str(e.label) or 'Addon item', hashes = h, gender = gender }
    end,
    weapon_components = function(e)
        if type(e) ~= 'table' or not str(e.weapon) or not str(e.component) then return nil end
        return {
            weapon = e.weapon:upper(), component = e.component,
            category = str(e.category) and e.category:upper() or 'ADDON', label = str(e.label) or e.component,
        }
    end,
}

local function normalizeList(name, list)
    local out = {}
    if type(list) ~= 'table' then return out end
    for i, e in ipairs(list) do
        local n
        if name == 'peds' then n = normalize.model(e, 'Peds')
        elseif name == 'horses' then n = normalize.model(e, 'Horses')
        elseif name == 'wagons' then n = normalize.model(e, 'Wagons')
        elseif name == 'weapons' then n = normalize.weapons(e)
        elseif name == 'clothing' or name == 'horse_tack' then n = normalize.comps(e)
        elseif name == 'weapon_components' then n = normalize.weapon_components(e)
        end
        if n then
            out[#out + 1] = n
        else
            print(('[%s] addons.json: skipped invalid %s entry #%d'):format(RES, name, i))
        end
    end
    return out
end

function CES.LoadAddons()
    local raw = LoadResourceFile(RES, FILE)
    local data = {}
    if raw then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' then
            data = decoded
        else
            print(('[%s] ^1addons.json is not valid JSON - add-ons disabled until it is fixed.^0'):format(RES))
        end
    end
    local addons, counts = {}, {}
    for _, name in ipairs(LISTS) do
        addons[name] = normalizeList(name, data[name])
        if #addons[name] > 0 then counts[#counts + 1] = ('%d %s'):format(#addons[name], name) end
    end
    CES.Addons = addons
    print(('[%s] add-ons loaded: %s'):format(RES, #counts > 0 and table.concat(counts, ', ') or 'none'))
end

CES.RegisterCallback('getAddons', nil, function()
    return CES.Addons
end)

RegisterCommand('cesmenu_reloadaddons', function(src)
    if src ~= 0 and not IsPlayerAceAllowed(tostring(src), 'command.cesmenu_reloadaddons') then return end
    CES.LoadAddons()
    TriggerClientEvent('ces_menu:cl:addons', -1, CES.Addons)
end, true)

CES.LoadAddons()
