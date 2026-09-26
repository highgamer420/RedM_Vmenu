CES.Util = {}
local U = CES.Util

--- pcall-wrapped native call so one bad native never kills a thread.
function U.Invoke(hash, ...)
    local ok, a, b, c = pcall(Citizen.InvokeNative, hash, ...)
    if ok then return a, b, c end
    CES.Debug(('native 0x%X failed: %s'):format(hash, tostring(a)))
end

function U.Hash(v)
    if type(v) == 'number' then return v end
    return GetHashKey(v)
end

function U.LoadModel(model, timeout)
    local hash = U.Hash(model)
    if not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local deadline = GetGameTimer() + (timeout or 5000)
    while not HasModelLoaded(hash) do
        if GetGameTimer() > deadline then return nil end
        Wait(10)
    end
    return hash
end

-- ─── Entities ───────────────────────────────────────────────
function U.GetMount(ped)
    ped = ped or PlayerPedId()
    if IsPedOnMount(ped) then return GetMount(ped) end
    return nil
end

function U.GetVehicle(ped)
    ped = ped or PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return GetVehiclePedIsIn(ped, false) end
    return nil
end

--- The entity that should move when teleporting / nocliping.
function U.GetMoveEntity(includeMount)
    local ped = PlayerPedId()
    if includeMount == false then return ped end
    local veh = U.GetVehicle(ped)
    if veh and GetPedInVehicleSeat(veh, -1) == ped then return veh end
    local mount = U.GetMount(ped)
    if mount then return mount end
    return ped
end

function U.RequestControl(ent, timeout)
    if not NetworkGetEntityIsNetworked(ent) then return true end
    local deadline = GetGameTimer() + (timeout or 1000)
    NetworkRequestControlOfEntity(ent)
    while not NetworkHasControlOfEntity(ent) and GetGameTimer() < deadline do
        Wait(10)
        NetworkRequestControlOfEntity(ent)
    end
    return NetworkHasControlOfEntity(ent)
end

function U.DeleteEntity(ent)
    if not ent or not DoesEntityExist(ent) then return end
    if GetEntityType(ent) == 1 and IsPedAPlayer(ent) then return end
    local networked = NetworkGetEntityIsNetworked(ent)
    local netId = networked and NetworkGetNetworkIdFromEntity(ent) or nil
    U.RequestControl(ent, 750)
    SetEntityAsMissionEntity(ent, true, true)
    DeleteEntity(ent)
    if DoesEntityExist(ent) and netId then
        CES.Callback('deleteEntity', netId)
    end
end

-- ─── Health / cores ─────────────────────────────────────────
function U.FillCores(ped)
    for core = 0, 2 do -- 0 health, 1 stamina, 2 dead eye
        U.Invoke(0xC6258F41D86676E0, ped, core, 100) -- SET_ATTRIBUTE_CORE_VALUE
    end
end

function U.Heal(ped)
    ped = ped or PlayerPedId()
    if ped == PlayerPedId() and Config.Hooks.Heal then return Config.Hooks.Heal() end
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    U.FillCores(ped)
    U.Invoke(0x675680D089BFA21F, ped, 100.0) -- RESTORE_PED_STAMINA
end

function U.Clean(ped)
    ped = ped or PlayerPedId()
    U.Invoke(0x6585D955A68452A5, ped) -- CLEAR_PED_ENV_DIRT
    U.Invoke(0x8FE22675A5A45817, ped) -- CLEAR_PED_BLOOD_DAMAGE
    U.Invoke(0x9C720776DAA43E7E, ped) -- CLEAR_PED_WETNESS
end

function U.Revive()
    if Config.Hooks.Revive then return Config.Hooks.Revive() end
    local ped = PlayerPedId()
    if IsEntityDead(ped) then
        local c, h = GetEntityCoords(ped), GetEntityHeading(ped)
        NetworkResurrectLocalPlayer(c.x, c.y, c.z, h, true, false)
        Wait(250)
        ped = PlayerPedId()
    end
    U.Invoke(0x66560A0D4C64FD21) -- ANIMPOSTFX_STOP_ALL (clear death screen effects)
    ClearPedTasksImmediately(ped)
    U.Heal(ped)
end

-- ─── Teleport ───────────────────────────────────────────────
local teleporting = false

--- Teleport the player (and their mount / wagon). If z is nil the ground height is found.
function U.Teleport(x, y, z, heading, opts)
    if teleporting then return false end
    teleporting = true
    opts = opts or {}
    local fade = opts.fade ~= false
    local ent = U.GetMoveEntity(CES.State.tpWithMount)

    if fade then
        DoScreenFadeOut(250)
        while not IsScreenFadedOut() do Wait(0) end
    end

    FreezeEntityPosition(ent, true)
    if z == nil then
        local found = false
        SetEntityCoordsNoOffset(ent, x, y, 800.0, false, false, false)
        for h = 800.0, -100.0, -25.0 do
            RequestCollisionAtCoord(x, y, h)
            SetEntityCoordsNoOffset(ent, x, y, h, false, false, false)
            Wait(20)
            local ok, gz = GetGroundZFor_3dCoord(x, y, h, false)
            if ok and gz and gz ~= 0.0 then
                z = gz + 0.5
                found = true
                break
            end
        end
        if not found then z = opts.fallbackZ or 150.0 end
    else
        RequestCollisionAtCoord(x, y, z)
    end

    SetEntityCoords(ent, x, y, z, false, false, false, false)
    if heading then SetEntityHeading(ent, heading) end
    Wait(100)
    FreezeEntityPosition(ent, false)
    if fade then DoScreenFadeIn(250) end
    teleporting = false
    return true
end

-- ─── Drawing ────────────────────────────────────────────────
function U.DrawText3D(x, y, z, text, scale)
    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(x, y, z)
    if not onScreen then return end
    scale = scale or 0.32
    SetTextScale(scale, scale)
    SetTextFontForCurrentCommand(1)
    SetTextColor(255, 255, 255, 230)
    SetTextCentre(true)
    SetTextDropshadow(1, 0, 0, 0, 255)
    DisplayText(CreateVarString(10, 'LITERAL_STRING', text), sx, sy)
end

function U.Round(n, d)
    local m = 10 ^ (d or 2)
    return math.floor(n * m + 0.5) / m
end

-- ─── Events the server can send ─────────────────────────────
RegisterNetEvent('ces_menu:cl:teleport', function(c)
    U.Teleport(c.x, c.y, c.z, c.h)
end)

RegisterNetEvent('ces_menu:cl:freeze', function(state)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, state)
    local mount = U.GetMount(ped)
    if mount then FreezeEntityPosition(mount, state) end
end)

RegisterNetEvent('ces_menu:cl:heal', function()
    U.Heal()
    CES.Notify('You were healed by staff.', 'success')
end)

RegisterNetEvent('ces_menu:cl:revive', function()
    U.Revive()
    CES.Notify('You were revived by staff.', 'success')
end)

RegisterNetEvent('ces_menu:cl:kill', function()
    local ped = PlayerPedId()
    SetEntityInvincible(ped, false)
    CES.State.god = false
    SetEntityHealth(ped, 0)
end)
