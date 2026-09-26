local Menu, U, S = CES.Menu, CES.Util, CES.State


local function give(hash, ammo, equip)
    local ped = PlayerPedId()
    -- GIVE_WEAPON_TO_PED(ped, hash, ammo, forceInHand, forceInHolster, attachPoint, allowMultiple, p7, p8, addReason, ignoreUnlocks, p11, p12)
    U.Invoke(0x5E3BDDBCB83F3D84, ped, GetHashKey(hash), ammo or 100, equip and true or false, true, 0, false, 0.5, 1.0, 752097756, false, 0.0, false)
    U.Invoke(0x14E56BC5B5DB6A19, ped, GetHashKey(hash), ammo or 100) -- SET_PED_AMMO
end

Menu.Register('weapons', {
    title = 'Weapons',
    perms = { 'weapons.spawn', 'weapons.removeall', 'weapons.refill', 'weapons.infiniteammo', 'weapons.customize' },
    build = function(m)
        m:submenu({ label = 'Gunsmith', perm = 'weapons.customize', menu = 'gunsmith',
            desc = 'Customize the weapon in your hands: barrels, grips, sights, engravings and materials.' })
        m:separator('Give Weapons')
        for i, cat in ipairs(CES.GetWeaponCategories()) do
            m:submenu({ id = 'cat' .. i, label = cat.category, perm = 'weapons.spawn', menu = 'weapon_cat',
                right = tostring(#cat.items), args = { key = i, index = i } })
        end
        m:separator()
        m:button({ label = 'Give All Weapons', perm = 'weapons.spawn',
            onSelect = function()
                for _, cat in ipairs(CES.GetWeaponCategories()) do
                    for _, w in ipairs(cat.items) do give(w.hash, 200, false) end
                end
                CES.Notify('All weapons given.', 'success')
            end })
        m:button({ label = 'Refill Ammo', perm = 'weapons.refill', desc = 'Refills every weapon you carry from this list.',
            onSelect = function()
                local ped = PlayerPedId()
                for _, cat in ipairs(CES.GetWeaponCategories()) do
                    for _, w in ipairs(cat.items) do
                        local h = GetHashKey(w.hash)
                        if HasPedGotWeapon(ped, h, 0, false) then U.Invoke(0x14E56BC5B5DB6A19, ped, h, 500) end
                    end
                end
                CES.Notify('Ammo refilled.', 'success')
            end })
        m:checkbox({ label = 'Infinite Ammo', perm = 'weapons.infiniteammo', checked = S.infAmmo,
            onChange = function(v) CES.SetToggle('infAmmo', v) end })
        m:button({ label = 'Remove All Weapons', perm = 'weapons.removeall',
            onSelect = function()
                RemoveAllPedWeapons(PlayerPedId(), true, true)
                CES.Notify('All weapons removed.', 'success')
            end })
    end,
})

Menu.Register('weapon_cat', {
    title = function(a) local c = CES.GetWeaponCategories()[a.index] return c and c.category or 'Weapons' end,
    perms = { 'weapons.spawn' },
    build = function(m, a)
        local cat = CES.GetWeaponCategories()[a.index]
        if not cat then return end
        for i, w in ipairs(cat.items) do
            local owned = HasPedGotWeapon(PlayerPedId(), GetHashKey(w.hash), 0, false)
            m:button({ id = 'w' .. i, label = w.label, right = owned and 'Owned' or nil,
                onSelect = function()
                    give(w.hash, 100, true)
                    CES.Notify(('%s given.'):format(w.label), 'success')
                end })
        end
    end,
})
