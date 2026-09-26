-- RDO-style wardrobe: clothing + character (hair, beards, heads, bodies).
local Menu, S = CES.Menu, CES.State
local C = CES.Customizer

local MP_MALE, MP_FEMALE = GetHashKey('mp_male'), GetHashKey('mp_female')
S.keepOutfit = true

local function isMpModel(ent)
    local m = GetEntityModel(ent)
    return m == MP_MALE or m == MP_FEMALE
end

local W = C.Define({
    id = 'clothing',
    title = 'Clothing & Character',
    perm = 'appearance.clothing',
    addonList = 'clothing',
    savedKvp = 'ces_menu:outfits',
    savedTitle = 'Saved Outfits',
    saveModel = true,
    emptyText = 'No wardrobe items for this model. Use Online Male / Female for the full wardrobe.',
    noNone = { heads = true, BODIES_UPPER = true, BODIES_LOWER = true, eyes = true, teeth = true },

    target = function()
        local ped = PlayerPedId()
        if not IsPedHuman(ped) then return nil, 'Animals have no wardrobe - switch to a human model.' end
        return ped
    end,
    stateKey = function(ped) return GetEntityModel(ped) end,
    isMp = isMpModel,
    group = function(ped)
        local m = GetEntityModel(ped)
        if m == MP_MALE then return 'male_mp' end
        if m == MP_FEMALE then return 'female_mp' end
        return IsPedMale(ped) and 'male_sp' or 'female_sp'
    end,

    sections = {
        { label = 'Headwear', cats = { 'hats', 'eyewear', 'masks', 'MASKS_LARGE', 'neckwear', 'neckties' } },
        { label = 'Upper Body', cats = { 'shirts_full', 'vests', 'coats', 'coats_closed', 'ponchos', 'cloaks',
            'suspenders', 'gloves', 'gauntlets', 'armor', 'badges' } },
        { label = 'Belts & Holsters', cats = { 'belts', 'belt_buckles', 'gunbelts', 'gunbelt_accs', 'holsters_left',
            'holsters_right', 'holsters_crossdraw', 'satchels' } },
        { label = 'Lower Body', cats = { 'pants', 'skirts', 'dresses', 'aprons', 'chaps', 'spats', 'boots', 'boot_accessories' } },
        { label = 'Jewelry & Accessories', cats = { 'accessories', 'jewelry_rings_left', 'jewelry_rings_right', 'jewelry_bracelets' } },
        { label = 'Character', cats = { 'hair', 'hair_accessories', 'beards_complete', 'beards_mustache', 'beards_chops',
            'beards_chin', 'heads', 'eyes', 'teeth', 'BODIES_UPPER', 'BODIES_LOWER' } },
    },

    extra = function(m, ped)
        m:separator('Options')
        m:checkbox({ label = 'Keep Outfit After Respawn', checked = S.keepOutfit,
            desc = 'Re-applies what you equipped here when your character respawns.',
            onChange = function(v) S.keepOutfit = v end })
        if ped then
            m:button({ label = 'Remove All Clothing', desc = 'Strips every clothing category (keeps hair, head and body).',
                onSelect = function()
                    local def = CES.Wardrobe.def
                    for _, sec in ipairs(def.sections) do
                        if sec.label ~= 'Character' then
                            for _, cat in ipairs(sec.cats) do
                                C.RemoveCategory(ped, cat)
                                def.state.equipped[cat] = false
                            end
                        end
                    end
                    C.Refresh(ped)
                    CES.Notify('Clothing removed.', 'success')
                end })
            m:button({ label = 'Random Outfit', desc = 'Let the game dress you at random.',
                onSelect = function()
                    CES.Util.Invoke(0x283978A15512B2FE, ped, true)
                    CES.Wardrobe.def.state.key = nil
                end })
        end
    end,
})

CES.Wardrobe = { def = W }

--- Called by the appearance menu after a model swap.
function CES.Wardrobe.OnModelChanged()
    W.state.key = nil
    if isMpModel(PlayerPedId()) then
        -- give MP peds a complete base body so nothing is missing
        CES.Util.Invoke(0x77FF8D35EEC6BBC4, PlayerPedId(), 0, false) -- EQUIP_META_PED_OUTFIT_PRESET
        CES.Util.Invoke(0x283978A15512B2FE, PlayerPedId(), true)
    end
end

-- Re-apply the outfit after respawn (same model, new ped handle).
CreateThread(function()
    local lastPed = PlayerPedId()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        if ped ~= lastPed then
            lastPed = ped
            if S.keepOutfit and W.state.key == GetEntityModel(ped) then
                Wait(500)
                W.Reapply(ped)
            end
        end
    end
end)
