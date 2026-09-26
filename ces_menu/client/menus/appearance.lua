local Menu, U = CES.Menu, CES.Util

local originalModel = nil
local currentScale = 1.0
local outfit = 0

local function applyScale()
    U.Invoke(0x25ACFC650B65C538, PlayerPedId(), currentScale + 0.0) -- SET_PED_SCALE
end

local function setModel(model, label)
    local hash = U.LoadModel(model)
    if not hash then return CES.Notify(('Invalid model: %s'):format(tostring(model)), 'error') end
    if not originalModel then originalModel = GetEntityModel(PlayerPedId()) end

    U.Invoke(0xED40380076A31506, PlayerId(), hash, false)  -- SET_PLAYER_MODEL
    Wait(50)
    local ped = PlayerPedId()
    U.Invoke(0x283978A15512B2FE, ped, true)                -- SET_RANDOM_OUTFIT_VARIATION
    SetModelAsNoLongerNeeded(hash)
    outfit = 0
    if CES.Wardrobe then CES.Wardrobe.OnModelChanged() end
    if currentScale ~= 1.0 then applyScale() end
    CES.Notify(('Model changed to %s.'):format(label or model), 'success')
end

local function equipOutfit(idx)
    local ped = PlayerPedId()
    U.Invoke(0x77FF8D35EEC6BBC4, ped, idx, false)             -- EQUIP_META_PED_OUTFIT_PRESET
    U.Invoke(0xCC8CA3E88256E58F, ped, false, true, true, true, false) -- UPDATE_PED_VARIATION
end

Menu.Register('appearance', {
    title = 'Appearance',
    perms = { 'appearance.model', 'appearance.clothing', 'appearance.scale' },
    build = function(m)
        for i, cat in ipairs(CES.GetPedCategories()) do
            m:submenu({ id = 'cat' .. i, label = cat.category, perm = 'appearance.model', menu = 'model_cat',
                args = { key = i, index = i } })
        end
        m:submenu({ label = 'Clothing & Character', menu = 'clothing', perm = 'appearance.clothing',
            desc = 'Red Dead Online style wardrobe: hats, coats, boots, hair, beards and more - previews as you browse.' })
        m:button({ label = 'Custom Model', perm = 'appearance.model', desc = 'Type any ped model name.',
            onSelect = function()
                local model = CES.Prompt('Ped model name', '', 'e.g. A_C_Wolf')
                if model then setModel(model) end
            end })
        m:button({ label = 'Restore Original Model', perm = 'appearance.model', disabled = originalModel == nil,
            desc = 'Go back to the model you had before using this menu.',
            onSelect = function()
                if originalModel then setModel(originalModel, 'original') originalModel = nil end
            end })

        m:separator('Outfit')
        m:slider({ id = 'outfit', label = 'Outfit Preset', perm = 'appearance.model', min = 0, max = 60, step = 1, value = outfit,
            desc = 'Cycle the preset outfits built into the current model. Not every number exists on every model.',
            onChange = function(v) outfit = v equipOutfit(v) end })
        m:button({ label = 'Random Outfit', perm = 'appearance.model',
            onSelect = function() U.Invoke(0x283978A15512B2FE, PlayerPedId(), true) end })

        m:separator('Size')
        m:slider({ id = 'scale', label = 'Ped Scale', perm = 'appearance.scale',
            min = Config.PedScale.Min, max = Config.PedScale.Max, step = 0.05, value = currentScale, format = '%.2fx',
            onChange = function(v) currentScale = v applyScale() end })
        m:button({ label = 'Reset Scale', perm = 'appearance.scale',
            onSelect = function() currentScale = 1.0 applyScale() end })
    end,
})

Menu.Register('model_cat', {
    title = function(a) local c = CES.GetPedCategories()[a.index] return c and c.category or 'Models' end,
    perms = { 'appearance.model' },
    build = function(m, a)
        local cat = CES.GetPedCategories()[a.index]
        if not cat then return end
        for i, p in ipairs(cat.items) do
            m:button({ id = 'p' .. i, label = p.label, desc = p.model,
                onSelect = function() setModel(p.model, p.label) end })
        end
    end,
})
