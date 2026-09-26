-- Client side of addons.json + helpers that merge add-on content with the built-in lists.
CES.AddonListeners = {}
CES.Addons = { peds = {}, horses = {}, wagons = {}, weapons = {}, clothing = {}, horse_tack = {}, weapon_components = {} }

--- "0x8FFCF06B" / "8FFCF06B" / "NAME" / number -> unsigned 32-bit number
function CES.ToHash(v)
    if type(v) == 'number' then
        v = math.floor(v) -- JSON may hand back floats; natives need integers
        return v < 0 and v + 4294967296 or v
    end
    if type(v) ~= 'string' then return 0 end
    local n = tonumber(v) or (v:match('^%x+$') and #v == 8 and tonumber(v, 16))
    if not n then n = GetHashKey(v) end
    if n < 0 then n = n + 4294967296 end
    return n
end

local function setAddons(a)
    if type(a) ~= 'table' then return end
    for k in pairs(CES.Addons) do CES.Addons[k] = type(a[k]) == 'table' and a[k] or {} end
    for _, f in ipairs(CES.AddonListeners) do pcall(f) end
    if CES.Menu then CES.Menu.Refresh() end
end

RegisterNetEvent('ces_menu:cl:addons', setAddons)

CreateThread(function()
    Wait(500)
    setAddons(CES.Callback('getAddons'))
end)

local function byCategory(list, labelKey)
    local cats, order = {}, {}
    for _, e in ipairs(list) do
        local c = e.category or 'Add-ons'
        if not cats[c] then cats[c] = {} order[#order + 1] = c end
        cats[c][#cats[c] + 1] = e
    end
    local out = {}
    for _, c in ipairs(order) do out[#out + 1] = { category = c, items = cats[c] } end
    return out
end

--- Config.PedModels + add-on peds grouped by category.
function CES.GetPedCategories()
    local out = {}
    for _, c in ipairs(Config.PedModels) do out[#out + 1] = c end
    for _, c in ipairs(byCategory(CES.Addons.peds)) do out[#out + 1] = c end
    return out
end

--- Config.Weapons + add-on weapons grouped by category.
function CES.GetWeaponCategories()
    local out = {}
    for _, c in ipairs(Config.Weapons) do out[#out + 1] = c end
    for _, c in ipairs(byCategory(CES.Addons.weapons)) do out[#out + 1] = c end
    return out
end
