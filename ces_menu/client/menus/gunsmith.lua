-- RDO-style gunsmith for the weapon in your hands.
local Menu, U = CES.Menu, CES.Util

local KVP = 'ces_menu:gunsmith'
local saved = nil   -- [weaponName] = { [category] = componentName | false }
local autoApply = true

local function load()
    if saved then return saved end
    local ok, v = pcall(json.decode, GetResourceKvpString(KVP) or '{}')
    saved = (ok and type(v) == 'table') and v or {}
    return saved
end
local function persist() SetResourceKvp(KVP, json.encode(saved or {})) end

-- weapon hash -> name, for every weapon we know components for
local nameByHash = nil
local function weaponNames()
    if nameByHash then return nameByHash end
    nameByHash = {}
    for name in pairs(CES_WEAPON_COMPONENTS_SPECIFIC) do nameByHash[GetHashKey(name)] = name end
    for name in pairs(CES_WEAPON_SHARED_GROUPS) do nameByHash[GetHashKey(name)] = name end
    for _, a in ipairs(CES.Addons.weapon_components) do nameByHash[GetHashKey(a.weapon)] = a.weapon end
    return nameByHash
end

local function currentWeapon()
    local ped = PlayerPedId()
    local _, wep = GetCurrentPedWeapon(ped, true, 0, true)
    if not wep or wep == 0 or wep == GetHashKey('WEAPON_UNARMED') then return nil end
    return weaponNames()[wep], wep
end

local function pretty(s)
    s = s:gsub('_', ' '):lower():gsub('(%a)([%w]*)', function(a, b) return a:upper() .. b end)
    return s
end

local function componentLabel(weaponName, cat, comp)
    local short = weaponName:gsub('^WEAPON_', '')
    local s = comp:gsub('^COMPONENT_', ''):gsub('^' .. short .. '_', ''):gsub('^SHORTARM_', ''):gsub('^LONGARM_', '')
        :gsub('^SHOTGUN_', ''):gsub('^MELEE_BLADE_', ''):gsub('^' .. cat .. '_?', '')
    if s == '' then return 'Standard' end
    if s:match('^%d+$') then return 'Option ' .. s end
    return pretty(s)
end

--- Categories for a weapon: { { cat, label, comps = { names } , shared = bool } }
local function categories(weaponName)
    local out = {}
    local specific = CES_WEAPON_COMPONENTS_SPECIFIC[weaponName] or {}
    local keys = {}
    for cat in pairs(specific) do if cat ~= 'FRAME_VERTDATA' then keys[#keys + 1] = cat end end
    table.sort(keys)
    for _, cat in ipairs(keys) do out[#out + 1] = { cat = cat, label = pretty(cat), comps = specific[cat] } end

    for _, grp in ipairs(CES_WEAPON_SHARED_GROUPS[weaponName] or {}) do
        local shared = CES_WEAPON_COMPONENTS_SHARED[grp] or {}
        local sk = {}
        for cat in pairs(shared) do sk[#sk + 1] = cat end
        table.sort(sk)
        for _, cat in ipairs(sk) do
            out[#out + 1] = { cat = grp .. ':' .. cat, label = pretty(cat), comps = shared[cat], shared = true }
        end
    end

    local addonCats = {}
    for _, a in ipairs(CES.Addons.weapon_components) do
        if a.weapon == weaponName then
            local key = 'ADDON:' .. a.category
            if not addonCats[key] then
                addonCats[key] = { cat = key, label = pretty(a.category) .. '  ★', comps = {}, labels = {} }
                out[#out + 1] = addonCats[key]
            end
            local c = addonCats[key]
            c.comps[#c.comps + 1] = a.component
            c.labels[a.component] = a.label
        end
    end
    return out
end

local function loadComponentModel(compHash)
    local model = U.Invoke(0x59DE03442B6C9598, compHash) -- GET_WEAPON_COMPONENT_TYPE_MODEL
    if model and model ~= 0 then
        RequestModel(model)
        local deadline = GetGameTimer() + 3000
        while not HasModelLoaded(model) and GetGameTimer() < deadline do Wait(0) end
        return model
    end
end

local function removeComponent(ped, weaponHash, comp)
    U.Invoke(0x19F70C4D80494FF8, ped, GetHashKey(comp), weaponHash) -- REMOVE_WEAPON_COMPONENT_FROM_PED
end

local function applyComponent(ped, weaponName, weaponHash, comp, isShared)
    if isShared then
        -- FRAME_VERTDATA breaks colours of shared parts - strip it first
        for _, v in ipairs((CES_WEAPON_COMPONENTS_SPECIFIC[weaponName] or {}).FRAME_VERTDATA or {}) do
            removeComponent(ped, weaponHash, v)
        end
    end
    local h = GetHashKey(comp)
    local model = loadComponentModel(h)
    U.Invoke(0x74C9090FDD1BB48E, ped, h, weaponHash, true) -- GIVE_WEAPON_COMPONENT_TO_ENTITY
    if model then SetModelAsNoLongerNeeded(model) end
end

local function applySaved(weaponName, weaponHash)
    local cfg = load()[weaponName]
    if not cfg then return end
    local ped = PlayerPedId()
    for cat, comp in pairs(cfg) do
        if comp then applyComponent(ped, weaponName, weaponHash, comp, cat:find(':') ~= nil and not cat:find('^ADDON:')) end
    end
end

Menu.Register('gunsmith', {
    title = 'Gunsmith',
    perms = { 'weapons.customize' },
    build = function(m)
        local name, hash = currentWeapon()
        if not hash then
            return m:button({ label = 'Hold a weapon to customize it.', disabled = true })
        end
        if not name then
            return m:button({ label = 'This weapon has no known parts.', disabled = true })
        end
        m:separator(pretty(name:gsub('^WEAPON_', '')))
        local cfg = load()[name] or {}
        for _, c in ipairs(categories(name)) do
            local chosen = cfg[c.cat]
            m:submenu({ id = c.cat, label = c.label, menu = 'gunsmith_cat',
                right = chosen and (c.labels and c.labels[chosen] or componentLabel(name, c.cat:gsub('^.-:', ''), chosen)) or tostring(#c.comps),
                args = { key = name .. '|' .. c.cat, weapon = name, cat = c.cat } })
        end
        m:separator('Options')
        m:button({ label = 'Reset To Factory', desc = 'Removes every part applied here.',
            onSelect = function()
                local ped = PlayerPedId()
                for cat, comp in pairs(load()[name] or {}) do
                    if comp then removeComponent(ped, hash, comp) end
                end
                saved[name] = nil
                persist()
                CES.Notify('Weapon reset.', 'success')
            end })
        m:checkbox({ label = 'Re-apply When Equipped', checked = autoApply,
            desc = 'Puts your saved parts back on whenever you draw this weapon.',
            onChange = function(v) autoApply = v end })
    end,
})

Menu.Register('gunsmith_cat', {
    title = function(a) return pretty((a.cat or ''):gsub('^.-:', '')) end,
    perms = { 'weapons.customize' },
    build = function(m, a)
        local name, hash = currentWeapon()
        if name ~= a.weapon then
            return m:button({ label = 'Switch back to the weapon you were customizing.', disabled = true })
        end
        local cat
        for _, c in ipairs(categories(name)) do if c.cat == a.cat then cat = c break end end
        if not cat then return end
        local cfg = load()
        local chosen = cfg[name] and cfg[name][cat.cat]

        m:button({ id = 'default', label = 'Default', right = not chosen and 'Equipped' or nil,
            onSelect = function()
                if chosen then removeComponent(PlayerPedId(), hash, chosen) end
                cfg[name] = cfg[name] or {}
                cfg[name][cat.cat] = nil
                persist()
            end })
        for i, comp in ipairs(cat.comps) do
            local label = (cat.labels and cat.labels[comp]) or componentLabel(name, cat.cat:gsub('^.-:', ''), comp)
            m:button({ id = 'c' .. i, label = label, right = chosen == comp and 'Equipped' or nil, desc = comp,
                onSelect = function()
                    local ped = PlayerPedId()
                    if chosen then removeComponent(ped, hash, chosen) end
                    applyComponent(ped, name, hash, comp, cat.shared)
                    cfg[name] = cfg[name] or {}
                    cfg[name][cat.cat] = comp
                    persist()
                end })
        end
    end,
})

-- Re-apply saved parts when a customized weapon is drawn.
CreateThread(function()
    local last = 0
    while true do
        Wait(750)
        if autoApply and CES.HasPerm('weapons.customize') then
            local name, hash = currentWeapon()
            if hash and hash ~= last then
                last = hash
                if name then applySaved(name, hash) end
            elseif not hash then
                last = 0
            end
        end
    end
end)

table.insert(CES.AddonListeners, function() nameByHash = nil end)
