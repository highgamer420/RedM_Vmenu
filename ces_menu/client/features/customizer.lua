--[[
    Shared engine for the RDO-style shops (wardrobe + horse tack).
    Items preview as you scroll, colour variants cycle with ← →, Enter equips,
    and leaving a category without buying puts back what you had on.

    CES.Customizer.Define({
        id, title, perm,
        target   = function() return entity | nil, 'why not' end,
        group    = function(ent) return 'male_mp' | 'female_mp' | 'male_sp' | 'horse' | nil end,
        isMp     = function(ent) return bool end,
        stateKey = function(ent) return anything that changes when equipped state must reset end,
        sections = { { label = 'Clothing', cats = { 'hats', ... } }, ... },
        noNone   = { heads = true },          -- categories that can't be emptied
        addonList = 'clothing' | 'horse_tack',
        savedKvp, savedTitle, saveModel,
        onEquip  = function(state) end,        -- after any equip / set applied
        extra    = function(m, ent, state) end,
        emptyText,
    })
]]
local U, Menu = CES.Util, CES.Menu
local Customizer = {}
CES.Customizer = Customizer

-- ─── Natives ────────────────────────────────────────────────
function Customizer.ApplyItem(ent, hash, isMp)
    U.Invoke(0xD3A7B003ED343FD9, ent, hash, true, isMp and true or false, false) -- APPLY_SHOP_ITEM_TO_PED
end

function Customizer.RemoveCategory(ent, category)
    local ch = CES_COMPONENT_CATEGORY_HASH[category] or GetHashKey(category)
    U.Invoke(0xD710A5007C2AC539, ent, ch, 0) -- REMOVE_TAG_FROM_META_PED
end

function Customizer.Refresh(ent)
    U.Invoke(0xCC8CA3E88256E58F, ent, false, true, true, true, false) -- UPDATE_PED_VARIATION
end

--- Best effort: is this shop item currently worn? (nil if the native is unavailable)
local usingNativeOk = true
function Customizer.IsWearing(ent, hash)
    if not usingNativeOk then return nil end
    local ok, res = pcall(Citizen.InvokeNative, 0xFB4891BD7578CDC1, ent, hash, Citizen.ResultAsInteger()) -- IS_METAPED_USING_COMPONENT
    if not ok then usingNativeOk = false return nil end
    return res == 1 or res == true
end

-- ─── Helpers ────────────────────────────────────────────────
local CATEGORY_LABELS = {
    hats = 'Hats', eyewear = 'Eyewear', masks = 'Masks', MASKS_LARGE = 'Large Masks', neckwear = 'Neckwear',
    neckties = 'Neckties', shirts_full = 'Shirts', vests = 'Vests', coats = 'Coats (Open)', coats_closed = 'Coats (Closed)',
    ponchos = 'Ponchos', cloaks = 'Cloaks', gloves = 'Gloves', gauntlets = 'Gauntlets', suspenders = 'Suspenders',
    belts = 'Belts', belt_buckles = 'Belt Buckles', gunbelts = 'Gun Belts', gunbelt_accs = 'Gun Belt Accessories',
    holsters_left = 'Offhand Holsters', holsters_right = 'Holsters (Right)', holsters_crossdraw = 'Crossdraw Holsters',
    satchels = 'Satchels', pants = 'Pants', skirts = 'Skirts', dresses = 'Dresses', aprons = 'Aprons', chaps = 'Chaps',
    spats = 'Spats', boots = 'Boots', boot_accessories = 'Spurs & Boot Accessories', accessories = 'Accessories',
    armor = 'Armor', badges = 'Badges', jewelry_rings_left = 'Rings (Left)', jewelry_rings_right = 'Rings (Right)',
    jewelry_bracelets = 'Bracelets', hair = 'Hair', hair_accessories = 'Hair Accessories',
    beards_complete = 'Beards', beards_mustache = 'Mustaches', beards_chops = 'Mutton Chops', beards_chin = 'Chin Beards',
    heads = 'Heads', BODIES_UPPER = 'Upper Body', BODIES_LOWER = 'Lower Body', eyes = 'Eyes', teeth = 'Teeth',
    horse_saddles = 'Saddles', horse_blankets = 'Saddle Blankets', saddle_horns = 'Saddle Horns',
    saddle_stirrups = 'Stirrups', HORSE_SADDLEBAGS = 'Saddlebags', horse_bedrolls = 'Bedrolls', horse_bridles = 'Bridles',
    horse_manes = 'Manes', HORSE_TAILS = 'Tails', horse_mustache = 'Mustaches', horse_accessories = 'Masks & Accessories',
    saddle_lanterns = 'Lanterns', horse_shoes = 'Horseshoes',
}
Customizer.CategoryLabels = CATEGORY_LABELS

local function catLabel(cat) return CATEGORY_LABELS[cat] or cat end

local function loadKvp(key)
    local raw = GetResourceKvpString(key)
    local ok, v = pcall(json.decode, raw or '[]')
    return (ok and type(v) == 'table') and v or {}
end

local function saveKvp(key, value) SetResourceKvp(key, json.encode(value)) end

-- styles cache: [group .. '|' .. cat] = { { label, { hashes } }, ... }
local cache = {}
function Customizer.ClearCache() cache = {} end
table.insert(CES.AddonListeners, Customizer.ClearCache)

local function styles(def, group, cat)
    local k = group .. '|' .. cat
    if cache[k] then return cache[k] end
    local list = {}
    local base = CES_COMPONENTS[group] and CES_COMPONENTS[group][cat]
    if base then for _, s in ipairs(base) do list[#list + 1] = s end end
    local gender = group:match('^(%a+)_') -- male / female / nil for horse
    for _, a in ipairs(CES.Addons[def.addonList] or {}) do
        if a.category == cat and (not gender or a.gender == 'any' or a.gender == gender) then
            local hs = {}
            for i, h in ipairs(a.hashes) do hs[i] = CES.ToHash(h) end
            table.insert(list, 1, { a.label .. '  ★', hs })
        end
    end
    cache[k] = list
    return list
end

local function variantLabels(n)
    local out = {}
    for i = 1, n do out[i] = ('Colour %d/%d'):format(i, n) end
    return out
end

-- ─── Define a shop ──────────────────────────────────────────
function Customizer.Define(def)
    local state = { key = nil, equipped = {}, detected = {}, previewed = {} }
    def.state = state

    local function current()
        local ent, why = def.target()
        if not ent or not DoesEntityExist(ent) then return nil, why end
        local key = def.stateKey(ent)
        if key ~= state.key then
            state.key, state.equipped, state.detected, state.previewed = key, {}, {}, {}
        end
        return ent
    end
    def.current = current

    local function apply(ent, cat, hash)
        if hash then
            Customizer.ApplyItem(ent, hash, def.isMp(ent))
        else
            Customizer.RemoveCategory(ent, cat)
        end
        Customizer.Refresh(ent)
    end

    local function detect(ent, cat, group)
        if state.detected[cat] then return end
        state.detected[cat] = true
        if state.equipped[cat] ~= nil then return end
        for _, s in ipairs(styles(def, group, cat)) do
            for _, h in ipairs(s[2]) do
                local r = Customizer.IsWearing(ent, h)
                if r == nil then return end
                if r then state.equipped[cat] = h return end
            end
        end
    end

    function def.Equip(cat, hash)
        local ent = current()
        if not ent then return end
        state.equipped[cat] = hash or false
        state.previewed[cat] = nil
        apply(ent, cat, hash)
        if def.onEquip then def.onEquip(state) end
    end

    function def.ApplySet(comps, ent)
        ent = ent or current()
        if not ent then return end
        for cat, h in pairs(comps) do
            if h == false then
                Customizer.RemoveCategory(ent, cat)
            else
                Customizer.ApplyItem(ent, CES.ToHash(h), def.isMp(ent))
            end
            if ent == current() then state.equipped[cat] = h and CES.ToHash(h) or false end
        end
        Customizer.Refresh(ent)
    end

    function def.Reapply(ent)
        local comps = {}
        for cat, h in pairs(state.equipped) do comps[cat] = h end
        if next(comps) then def.ApplySet(comps, ent) end
    end

    local function preview(cat, hash)
        local ent = current()
        if not ent then return end
        state.previewed[cat] = true
        apply(ent, cat, hash)
    end

    local function revert(cat)
        if not state.previewed[cat] then return end
        state.previewed[cat] = nil
        local ent = current()
        if not ent then return end
        local eq = state.equipped[cat]
        apply(ent, cat, eq or nil)
    end

    -- Root
    Menu.Register(def.id, {
        title = def.title,
        perms = { def.perm },
        build = function(m)
            local ent, why = current()
            if not ent then
                m:button({ label = why or 'Nothing to customize', disabled = true })
                if def.extra then def.extra(m, nil, state) end
                return
            end
            local group = def.group(ent)
            local any = false
            for _, sec in ipairs(def.sections) do
                local first = true
                for _, cat in ipairs(sec.cats) do
                    local list = group and styles(def, group, cat) or {}
                    if #list > 0 then
                        if first then m:separator(sec.label) first = false end
                        any = true
                        m:submenu({
                            id = 'cat_' .. cat, label = catLabel(cat), menu = def.id .. '_cat',
                            right = tostring(#list), args = { key = cat, cat = cat },
                        })
                    end
                end
            end
            if not any then m:button({ label = def.emptyText or 'No items for this model.', disabled = true }) end

            m:separator(def.savedTitle)
            m:submenu({ label = def.savedTitle, menu = def.id .. '_saved', right = tostring(#loadKvp(def.savedKvp)) })
            if def.extra then def.extra(m, ent, state) end
        end,
    })

    -- Category
    Menu.Register(def.id .. '_cat', {
        title = function(a) return catLabel(a.cat) end,
        perms = { def.perm },
        onOpen = function(a)
            local ent = current()
            if ent then detect(ent, a.cat, def.group(ent)) end
        end,
        onLeave = function(a) revert(a.cat) end,
        build = function(m, a)
            local ent, why = current()
            if not ent then return m:button({ label = why or 'Unavailable', disabled = true }) end
            local cat = a.cat
            local group = def.group(ent)
            local eq = state.equipped[cat]

            if not (def.noNone and def.noNone[cat]) then
                m:button({ id = 'none', label = 'None', right = eq == false and 'Equipped' or nil,
                    desc = ('Remove %s.'):format(catLabel(cat):lower()),
                    onHover = function() preview(cat, nil) end,
                    onSelect = function() def.Equip(cat, nil) end })
            end

            for i, s in ipairs(group and styles(def, group, cat) or {}) do
                local label, variants = s[1], s[2]
                local eqIdx
                for vi, h in ipairs(variants) do if h == eq then eqIdx = vi break end end
                local mark = eqIdx and '  ✓' or ''
                if #variants > 1 then
                    m:list({
                        id = 's' .. i, label = label .. mark, options = variantLabels(#variants),
                        index = eqIdx, keepIndex = true, noRefreshOnChange = true,
                        desc = 'Enter to equip · ← → to change colour',
                        onHover = function(item) preview(cat, variants[item.index or 1]) end,
                        onChange = function(idx) preview(cat, variants[idx]) end,
                        onSelect = function(idx) def.Equip(cat, variants[idx]) end,
                    })
                else
                    m:button({
                        id = 's' .. i, label = label, right = eqIdx and 'Equipped' or nil,
                        onHover = function() preview(cat, variants[1]) end,
                        onSelect = function() def.Equip(cat, variants[1]) end,
                    })
                end
            end
        end,
    })

    -- Saved sets
    Menu.Register(def.id .. '_saved', {
        title = def.savedTitle,
        perms = { def.perm },
        build = function(m)
            local sets = loadKvp(def.savedKvp)
            m:button({ label = 'Save Current Look', desc = 'Saves everything you have equipped through this menu.',
                onSelect = function()
                    local ent = current()
                    if not ent then return CES.Notify('Nothing to save.', 'error') end
                    if not next(state.equipped) then return CES.Notify('Equip something first.', 'error') end
                    local name = CES.Prompt('Name this look', ('Look %d'):format(#sets + 1), 'Name', 40)
                    if not name then return end
                    local comps = {}
                    for cat, h in pairs(state.equipped) do comps[cat] = h end
                    sets[#sets + 1] = { name = name, model = def.saveModel and GetEntityModel(ent) or nil, comps = comps }
                    saveKvp(def.savedKvp, sets)
                    CES.Notify(('Saved "%s".'):format(name), 'success')
                end })
            if #sets > 0 then m:separator() end
            for i, set in ipairs(sets) do
                local n = 0
                for _ in pairs(set.comps or {}) do n = n + 1 end
                m:submenu({ id = 'set' .. i, label = set.name, right = ('%d items'):format(n),
                    menu = def.id .. '_saved_item', args = { key = i .. ':' .. set.name, index = i } })
            end
        end,
    })

    Menu.Register(def.id .. '_saved_item', {
        title = function(a) local s = loadKvp(def.savedKvp)[a.index] return s and s.name or 'Look' end,
        perms = { def.perm },
        build = function(m, a)
            local sets = loadKvp(def.savedKvp)
            local set = sets[a.index]
            if not set then return end
            m:button({ label = 'Apply', onSelect = function()
                local ent = current()
                if not ent then return CES.Notify('Nothing to apply this to.', 'error') end
                if def.saveModel and set.model and set.model ~= GetEntityModel(ent) then
                    return CES.Notify('This look was saved on a different model.', 'error')
                end
                def.ApplySet(set.comps or {})
                if def.onEquip then def.onEquip(state) end
                CES.Notify(('Applied "%s".'):format(set.name), 'success')
            end })
            m:button({ label = 'Overwrite With Current Look', onSelect = function()
                local comps = {}
                for cat, h in pairs(state.equipped) do comps[cat] = h end
                set.comps = comps
                local ent = current()
                if ent and def.saveModel then set.model = GetEntityModel(ent) end
                saveKvp(def.savedKvp, sets)
                CES.Notify('Look updated.', 'success')
            end })
            m:button({ label = 'Rename', onSelect = function()
                local name = CES.Prompt('Rename look', set.name, 'Name', 40)
                if name then set.name = name saveKvp(def.savedKvp, sets) end
            end })
            m:button({ label = 'Delete', onSelect = function()
                table.remove(sets, a.index)
                saveKvp(def.savedKvp, sets)
                CES.Notify('Look deleted.', 'success')
                Menu.Back()
            end })
        end,
    })

    return def
end

Customizer.LoadKvp, Customizer.SaveKvp = loadKvp, saveKvp
