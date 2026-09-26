-- Persistent self / weapon / horse toggles. Values are applied once when changed,
-- re-applied if the player ped changes (respawn, model swap), and continuous
-- effects (cores, ammo) run in a light 1s loop.
local U = CES.Util
local S = CES.State

local appliers = {
    god       = function(ped, v) SetEntityInvincible(ped, v) end,
    invisible = function(ped, v) SetEntityVisible(ped, not v) end,
    noragdoll = function(ped, v) SetPedCanRagdoll(ped, not v) end,
}

function CES.SetToggle(name, value)
    S[name] = value
    local f = appliers[name]
    if f then f(PlayerPedId(), value) end
    if name == 'infAmmo' and not value then
        local ped = PlayerPedId()
        local _, wep = GetCurrentPedWeapon(ped, true, 0, true)
        if wep then U.Invoke(0x3EDCB0505123623B, ped, false, wep) end -- SET_PED_INFINITE_AMMO
        U.Invoke(0xFBAA1E06B6BCA741, ped, false)                       -- SET_PED_INFINITE_AMMO_CLIP
    end
    if name == 'horseGod' and not value then
        local mount = U.GetMount()
        if mount then SetEntityInvincible(mount, false) end
    end
end

-- Drop toggles the player lost permission for.
local permFor = {
    god = 'self.godmode', invisible = 'self.invisible', noragdoll = 'self.noragdoll',
    stamina = 'self.infinitestamina', deadeye = 'self.infinitedeadeye',
    infAmmo = 'weapons.infiniteammo', horseGod = 'mounts.godmode',
}

CreateThread(function()
    local lastPed, lastWeapon = 0, 0
    while true do
        local ped = PlayerPedId()

        for name, perm in pairs(permFor) do
            if S[name] and not CES.HasPerm(perm) then CES.SetToggle(name, false) end
        end

        if ped ~= lastPed then
            lastPed = ped
            for name, f in pairs(appliers) do
                if S[name] then f(ped, true) end
            end
        end

        if S.stamina then
            U.Invoke(0xC6258F41D86676E0, ped, 1, 100)  -- stamina core
            U.Invoke(0x675680D089BFA21F, ped, 100.0)   -- stamina bar
        end
        if S.deadeye then
            U.Invoke(0xC6258F41D86676E0, ped, 2, 100)  -- dead eye core
        end

        if S.infAmmo then
            local _, wep = GetCurrentPedWeapon(ped, true, 0, true)
            if wep and wep ~= lastWeapon then
                lastWeapon = wep
                U.Invoke(0x3EDCB0505123623B, ped, true, wep)
            end
            U.Invoke(0xFBAA1E06B6BCA741, ped, true)
        else
            lastWeapon = 0
        end

        if S.horseGod then
            local mount = U.GetMount(ped)
            if mount then SetEntityInvincible(mount, true) end
        end

        Wait(1000)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    local ped = PlayerPedId()
    if S.god then SetEntityInvincible(ped, false) end
    if S.invisible then SetEntityVisible(ped, true) end
    if S.noragdoll then SetPedCanRagdoll(ped, true) end
end)
