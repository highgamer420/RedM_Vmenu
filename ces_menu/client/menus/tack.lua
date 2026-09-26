-- RDO-style stable: saddles, blankets, horns, stirrups, bags, bedrolls, bridles, manes, tails...
local S = CES.State
local C = CES.Customizer

S.autoTack = true
local LAST_TACK_KVP = 'ces_menu:lasttack'

local T = C.Define({
    id = 'tack',
    title = 'Horse Customization',
    perm = 'mounts.customize',
    addonList = 'horse_tack',
    savedKvp = 'ces_menu:tacksets',
    savedTitle = 'Saved Tack Sets',
    saveModel = false,
    emptyText = 'No tack available for this animal.',

    target = function()
        local horse = CES.GetTargetHorse and CES.GetTargetHorse()
        if not horse then return nil, 'Mount a horse or spawn one first.' end
        return horse
    end,
    stateKey = function(horse) return horse end,
    isMp = function() return true end,
    group = function() return 'horse' end,

    sections = {
        { label = 'Saddle', cats = { 'horse_saddles', 'horse_blankets', 'saddle_horns', 'saddle_stirrups' } },
        { label = 'Gear', cats = { 'HORSE_SADDLEBAGS', 'horse_bedrolls', 'saddle_lanterns', 'horse_bridles',
            'horse_accessories', 'horse_shoes' } },
        { label = 'Grooming', cats = { 'horse_manes', 'HORSE_TAILS', 'horse_mustache' } },
    },

    onEquip = function(state)
        local comps = {}
        for cat, h in pairs(state.equipped) do comps[cat] = h end
        C.SaveKvp(LAST_TACK_KVP, comps)
    end,

    extra = function(m, horse)
        m:separator('Options')
        m:checkbox({ label = 'Tack Newly Spawned Horses', checked = S.autoTack,
            desc = 'Horses you spawn from this menu get your last tack automatically.',
            onChange = function(v) S.autoTack = v end })
        if horse then
            m:button({ label = 'Apply Last Tack', desc = 'Put your most recent tack on this horse.',
                onSelect = function()
                    local comps = C.LoadKvp(LAST_TACK_KVP)
                    if not next(comps) then return CES.Notify('No tack saved yet.', 'error') end
                    CES.Tack.def.ApplySet(comps)
                    CES.Notify('Tack applied.', 'success')
                end })
            m:button({ label = 'Remove All Tack', desc = 'Strips saddle and gear (keeps mane and tail).',
                onSelect = function()
                    local def = CES.Tack.def
                    for _, sec in ipairs(def.sections) do
                        if sec.label ~= 'Grooming' then
                            for _, cat in ipairs(sec.cats) do
                                C.RemoveCategory(horse, cat)
                                def.state.equipped[cat] = false
                            end
                        end
                    end
                    C.Refresh(horse)
                    CES.Notify('Tack removed.', 'success')
                end })
        end
    end,
})

CES.Tack = { def = T }

function CES.Tack.OnHorseSpawned(horse)
    if not S.autoTack or not CES.HasPerm('mounts.customize') then return end
    local comps = C.LoadKvp(LAST_TACK_KVP)
    if next(comps) then
        CreateThread(function()
            Wait(250)
            T.ApplySet(comps, horse)
        end)
    end
end
