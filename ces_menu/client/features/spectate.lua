local U = CES.Util
local S = CES.State

local spec = { active = false, target = nil, returnPos = nil, moved = false }
CES.Spectate = spec

local function setSpectatorMode(on, ped)
    U.Invoke(0x423DE3854BB50894, on, ped) -- NETWORK_SET_IN_SPECTATOR_MODE
end

local function hideSelf(on)
    local me = PlayerPedId()
    SetEntityVisible(me, not on and not S.invisible)
    SetEntityInvincible(me, on or S.god)
    SetEntityCollision(me, not on, not on)
    FreezeEntityPosition(me, on)
end

function CES.StopSpectate(silent)
    if not spec.active then return end
    spec.active = false
    setSpectatorMode(false, PlayerPedId())
    if spec.moved and spec.returnPos then
        local r = spec.returnPos
        SetEntityCoords(PlayerPedId(), r.x, r.y, r.z, false, false, false, false)
        hideSelf(false)
    end
    spec.target, spec.returnPos, spec.moved = nil, nil, false
    SendNUIMessage({ action = 'spectate', value = false })
    if not silent then CES.Notify('Stopped spectating.', 'info') end
end

function CES.StartSpectate(serverId, name)
    if spec.active then CES.StopSpectate(true) end
    local ok, c = CES.Callback('spectate', serverId)
    if not ok then return CES.Notify(c or 'Cannot spectate.', 'error') end

    local me = PlayerPedId()
    spec.returnPos = GetEntityCoords(me)
    spec.target = serverId
    spec.active = true
    spec.moved = false

    local player = GetPlayerFromServerId(serverId)
    if player == -1 or not DoesEntityExist(GetPlayerPed(player)) then
        -- target is out of scope (OneSync): park ourselves hidden above them until they stream in
        spec.moved = true
        hideSelf(true)
        SetEntityCoords(me, c.x, c.y, c.z + 30.0, false, false, false, false)
        local deadline = GetGameTimer() + 6000
        repeat
            Wait(100)
            player = GetPlayerFromServerId(serverId)
        until (player ~= -1 and DoesEntityExist(GetPlayerPed(player))) or GetGameTimer() > deadline
        if player == -1 then
            CES.StopSpectate(true)
            return CES.Notify('Could not load that player.', 'error')
        end
    end

    local targetPed = GetPlayerPed(player)
    setSpectatorMode(true, targetPed)
    SendNUIMessage({ action = 'spectate', value = true, name = name or ('ID ' .. serverId) })
    CES.Notify(('Spectating %s'):format(name or serverId), 'info')

    CreateThread(function()
        while spec.active and spec.target == serverId do
            local pl = GetPlayerFromServerId(serverId)
            if pl == -1 then
                CES.StopSpectate(true)
                CES.Notify('Player left or went out of range.', 'warning')
                break
            end
            local ped = GetPlayerPed(pl)
            if ped ~= targetPed and DoesEntityExist(ped) then
                targetPed = ped
                setSpectatorMode(true, targetPed)
            end
            if spec.moved then
                local tc = GetEntityCoords(targetPed)
                SetEntityCoordsNoOffset(PlayerPedId(), tc.x, tc.y, tc.z + 30.0, false, false, false)
            end
            Wait(500)
        end
    end)
end

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then CES.StopSpectate(true) end
end)
