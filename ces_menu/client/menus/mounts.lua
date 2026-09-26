local Menu, U, S = CES.Menu, CES.Util, CES.State

local spawnedHorse, spawnedWagon = nil, nil

local function spawnPoint(dist)
    local ped = PlayerPedId()
    local c = GetOffsetFromEntityInWorldCoords(ped, 0.0, dist or 3.0, 0.0)
    return c, GetEntityHeading(ped)
end

local function spawnHorse(model, label)
    local hash = U.LoadModel(model)
    if not hash then return CES.Notify(('Invalid horse model: %s'):format(model), 'error') end
    if S.replaceSpawned and spawnedHorse and DoesEntityExist(spawnedHorse) then U.DeleteEntity(spawnedHorse) end

    local c, h = spawnPoint(3.0)
    local horse = CreatePed(hash, c.x, c.y, c.z, h, true, false, false, false)
    SetModelAsNoLongerNeeded(hash)
    if not horse or horse == 0 then return CES.Notify('Could not spawn horse.', 'error') end

    U.Invoke(0x283978A15512B2FE, horse, true)       -- SET_RANDOM_OUTFIT_VARIATION (makes the ped visible)
    U.Invoke(0x9587913B9E772D29, horse, false)      -- PLACE_ENTITY_ON_GROUND_PROPERLY
    SetEntityAsMissionEntity(horse, true, true)
    spawnedHorse = horse

    if CES.Tack then CES.Tack.OnHorseSpawned(horse) end
    if Config.Hooks.OnHorseSpawned then Config.Hooks.OnHorseSpawned(horse) end
    if S.mountOnSpawn then
        U.Invoke(0x028F76B6E78246EB, PlayerPedId(), horse, -1, true) -- SET_PED_ONTO_MOUNT
    end
    CES.Notify(('%s spawned.'):format(label or model), 'success')
end

local function spawnWagon(model, label)
    local hash = U.LoadModel(model)
    if not hash then return CES.Notify(('Invalid wagon model: %s'):format(model), 'error') end
    if S.replaceSpawned and spawnedWagon and DoesEntityExist(spawnedWagon) then U.DeleteEntity(spawnedWagon) end

    local c, h = spawnPoint(5.0)
    local veh = CreateVehicle(hash, c.x, c.y, c.z, h, true, false, false, false)
    SetModelAsNoLongerNeeded(hash)
    if not veh or veh == 0 then return CES.Notify('Could not spawn wagon.', 'error') end

    SetEntityAsMissionEntity(veh, true, true)
    U.Invoke(0x9587913B9E772D29, veh, false)
    spawnedWagon = veh
    if Config.Hooks.OnWagonSpawned then Config.Hooks.OnWagonSpawned(veh) end
    if S.mountOnSpawn then SetPedIntoVehicle(PlayerPedId(), veh, -1) end
    CES.Notify(('%s spawned.'):format(label or model), 'success')
end

local function targetHorse()
    return U.GetMount() or (spawnedHorse and DoesEntityExist(spawnedHorse) and spawnedHorse) or nil
end
CES.GetTargetHorse = targetHorse

local function targetWagon()
    return U.GetVehicle() or (spawnedWagon and DoesEntityExist(spawnedWagon) and spawnedWagon) or nil
end

Menu.Register('mounts', {
    title = 'Horses & Wagons',
    perms = { 'mounts.spawn', 'mounts.customize', 'mounts.delete', 'mounts.godmode', 'mounts.care', 'vehicles.spawn', 'vehicles.delete', 'vehicles.repair' },
    build = function(m)
        m:separator('Horses')
        m:submenu({ label = 'Spawn Horse', perm = 'mounts.spawn', menu = 'horse_list' })
        m:submenu({ label = 'Horse Customization', perm = 'mounts.customize', menu = 'tack',
            desc = 'Saddles, blankets, stirrups, bags, bedrolls, bridles, manes and tails - like the Red Dead Online stable.' })
        m:button({ label = 'Spawn Custom Horse Model', perm = 'mounts.spawn',
            onSelect = function()
                local model = CES.Prompt('Horse model name', 'A_C_Horse_', 'e.g. A_C_Horse_Arabian_White')
                if model then spawnHorse(model) end
            end })
        m:checkbox({ label = 'Horse God Mode', perm = 'mounts.godmode', checked = S.horseGod,
            desc = 'Makes the horse you ride invincible.',
            onChange = function(v) CES.SetToggle('horseGod', v) end })
        m:button({ label = 'Heal & Clean Horse', perm = 'mounts.care',
            desc = 'Works on the horse you ride, or your last spawned horse.',
            onSelect = function()
                local horse = targetHorse()
                if not horse then return CES.Notify('No horse found.', 'error') end
                U.Heal(horse)
                U.Clean(horse)
                CES.Notify('Horse healed and cleaned.', 'success')
            end })
        m:button({ label = 'Delete Horse', perm = 'mounts.delete',
            onSelect = function()
                local horse = targetHorse()
                if not horse then return CES.Notify('No horse found.', 'error') end
                U.DeleteEntity(horse)
                if horse == spawnedHorse then spawnedHorse = nil end
                CES.Notify('Horse deleted.', 'success')
            end })

        m:separator('Wagons')
        m:submenu({ label = 'Spawn Wagon', perm = 'vehicles.spawn', menu = 'wagon_list' })
        m:button({ label = 'Spawn Custom Wagon Model', perm = 'vehicles.spawn',
            onSelect = function()
                local model = CES.Prompt('Wagon model name', '', 'e.g. wagon02x')
                if model then spawnWagon(model) end
            end })
        m:button({ label = 'Repair Wagon', perm = 'vehicles.repair',
            onSelect = function()
                local veh = targetWagon()
                if not veh then return CES.Notify('No wagon found.', 'error') end
                U.RequestControl(veh)
                U.Invoke(0x79811282A9D1AE56, veh) -- SET_VEHICLE_FIXED
                CES.Notify('Wagon repaired.', 'success')
            end })
        m:button({ label = 'Delete Wagon', perm = 'vehicles.delete',
            onSelect = function()
                local veh = targetWagon()
                if not veh then return CES.Notify('No wagon found.', 'error') end
                U.DeleteEntity(veh)
                if veh == spawnedWagon then spawnedWagon = nil end
                CES.Notify('Wagon deleted.', 'success')
            end })

        m:separator('Options')
        m:checkbox({ label = 'Mount / Drive On Spawn', checked = S.mountOnSpawn,
            onChange = function(v) S.mountOnSpawn = v end })
        m:checkbox({ label = 'Replace Previous Spawn', checked = S.replaceSpawned,
            desc = 'Delete your last spawned horse / wagon when you spawn a new one.',
            onChange = function(v) S.replaceSpawned = v end })
    end,
})

Menu.Register('horse_list', {
    title = 'Spawn Horse',
    perms = { 'mounts.spawn' },
    build = function(m)
        for i, h in ipairs(Config.Horses) do
            m:button({ id = 'h' .. i, label = h.label, onSelect = function() spawnHorse(h.model, h.label) end })
        end
        if #CES.Addons.horses > 0 then m:separator('Add-on Horses') end
        for i, h in ipairs(CES.Addons.horses) do
            m:button({ id = 'ah' .. i, label = h.label, desc = h.model, onSelect = function() spawnHorse(h.model, h.label) end })
        end
    end,
})

Menu.Register('wagon_list', {
    title = 'Spawn Wagon',
    perms = { 'vehicles.spawn' },
    build = function(m)
        for i, w in ipairs(Config.Wagons) do
            m:button({ id = 'v' .. i, label = w.label, onSelect = function() spawnWagon(w.model, w.label) end })
        end
        if #CES.Addons.wagons > 0 then m:separator('Add-on Wagons') end
        for i, w in ipairs(CES.Addons.wagons) do
            m:button({ id = 'av' .. i, label = w.label, desc = w.model, onSelect = function() spawnWagon(w.model, w.label) end })
        end
    end,
})
