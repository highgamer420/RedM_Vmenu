local U = CES.Util
local S = CES.State

local K = {
    fwd = 0x8FD015D8, back = 0xD27782E3, left = 0x7065027D, right = 0xB4E465B4, -- W S A D
    up = 0xCEFD9220, down = 0xDE794E3E,                                        -- E Q
    fast = 0x8FFC75D6, slow = 0xDB096B85,                                      -- SHIFT CTRL
    jump = 0xD9D0E1C0,
}

local entity = nil

local function setEntityState(ent, on)
    FreezeEntityPosition(ent, on)
    SetEntityCollision(ent, not on, not on)
    SetEntityInvincible(ent, on or (ent == PlayerPedId() and S.god))
    if Config.Noclip.Invisible then
        local hide = on or (ent == PlayerPedId() and S.invisible)
        SetEntityVisible(ent, not hide)
    end
end

function CES.SetNoclip(state)
    if state and not CES.HasPerm('noclip') then
        return CES.Notify('You do not have permission to use noclip.', 'error')
    end
    if state == S.noclip then return end
    S.noclip = state

    if state then
        entity = U.GetMoveEntity(true)
        setEntityState(entity, true)
        if entity ~= PlayerPedId() then setEntityState(PlayerPedId(), true) end
        SendNUIMessage({ action = 'noclip', value = true, speed = S.noclipSpeed })
        CreateThread(function()
            while S.noclip do
                local ent = entity
                if not DoesEntityExist(ent) then
                    ent = PlayerPedId()
                    entity = ent
                    setEntityState(ent, true)
                end
                for _, h in pairs(K) do DisableControlAction(0, h, true) end

                local speed = Config.Noclip.Speeds[S.noclipSpeed] or 1.0
                if IsDisabledControlPressed(0, K.fast) then speed = speed * Config.Noclip.FastMultiplier end
                if IsDisabledControlPressed(0, K.slow) then speed = speed * Config.Noclip.SlowMultiplier end

                local rot = GetGameplayCamRot(2)
                local pitch, yaw = math.rad(rot.x), math.rad(rot.z)
                local fwd = vector3(-math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch), math.sin(pitch))
                local right = vector3(math.cos(yaw), math.sin(yaw), 0.0)

                local move = vector3(0.0, 0.0, 0.0)
                if IsDisabledControlPressed(0, K.fwd) then move = move + fwd end
                if IsDisabledControlPressed(0, K.back) then move = move - fwd end
                if IsDisabledControlPressed(0, K.right) then move = move + right end
                if IsDisabledControlPressed(0, K.left) then move = move - right end
                if IsDisabledControlPressed(0, K.up) or IsDisabledControlPressed(0, K.jump) then move = move + vector3(0.0, 0.0, 1.0) end
                if IsDisabledControlPressed(0, K.down) then move = move - vector3(0.0, 0.0, 1.0) end

                local pos = GetEntityCoords(ent)
                local new = pos + move * speed
                SetEntityCoordsNoOffset(ent, new.x, new.y, new.z, true, true, true)
                SetEntityHeading(ent, rot.z)
                SetEntityVelocity(ent, 0.0, 0.0, 0.0)
                Wait(0)
            end
        end)
    else
        local ped = PlayerPedId()
        if entity and DoesEntityExist(entity) then setEntityState(entity, false) end
        if entity ~= ped then setEntityState(ped, false) end
        SetEntityVisible(ped, not S.invisible)
        SetEntityInvincible(ped, S.god)
        -- drop to the ground gently
        local c = GetEntityCoords(ped)
        local ok, gz = GetGroundZFor_3dCoord(c.x, c.y, c.z, false)
        if ok and entity and DoesEntityExist(entity) and c.z - gz < 3.0 then
            SetEntityCoordsNoOffset(entity, c.x, c.y, gz + 0.2, false, false, false)
        end
        entity = nil
        SendNUIMessage({ action = 'noclip', value = false })
    end
end

function CES.SetNoclipSpeed(idx)
    S.noclipSpeed = math.max(1, math.min(#Config.Noclip.Speeds, idx))
    if S.noclip then SendNUIMessage({ action = 'noclip', value = true, speed = S.noclipSpeed }) end
end

if Config.Commands.Noclip then
    RegisterCommand(Config.Commands.Noclip, function() CES.SetNoclip(not S.noclip) end, false)
end

local noclipKey = CES_KeyHash(Config.Keys.Noclip)
if noclipKey then
    CreateThread(function()
        while true do
            Wait(0)
            if IsControlJustReleased(0, noclipKey) and not CES.Menu.prompting then
                CES.SetNoclip(not S.noclip)
            end
        end
    end)
end

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and S.noclip then CES.SetNoclip(false) end
end)
