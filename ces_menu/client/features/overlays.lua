-- Coordinates HUD, overhead names, player blips and the delete gun.
local U = CES.Util
local S = CES.State

-- Coordinates HUD
CreateThread(function()
    local shown = false
    while true do
        if S.coords then
            local ent = U.GetMoveEntity(false)
            local c = GetEntityCoords(ent)
            SendNUIMessage({ action = 'coords', x = c.x, y = c.y, z = c.z, h = GetEntityHeading(ent) })
            shown = true
            Wait(150)
        else
            if shown then SendNUIMessage({ action = 'coords', hide = true }) shown = false end
            Wait(500)
        end
    end
end)

function CES.CopyCoords(format)
    local ped = PlayerPedId()
    local c, h = GetEntityCoords(ped), GetEntityHeading(ped)
    local x, y, z, hd = U.Round(c.x, 2), U.Round(c.y, 2), U.Round(c.z, 2), U.Round(h, 2)
    local text
    if format == 'vector4' then
        text = ('vector4(%.2f, %.2f, %.2f, %.2f)'):format(x, y, z, hd)
    elseif format == 'table' then
        text = ('{ x = %.2f, y = %.2f, z = %.2f, h = %.2f }'):format(x, y, z, hd)
    elseif format == 'json' then
        text = ('{"x": %.2f, "y": %.2f, "z": %.2f, "h": %.2f}'):format(x, y, z, hd)
    else
        text = ('vector3(%.2f, %.2f, %.2f)'):format(x, y, z)
    end
    SendNUIMessage({ action = 'copy', text = text })
    print('[ces_menu] ' .. text)
    CES.Notify(text, 'success', 'Copied to clipboard')
end

-- Overhead names
CreateThread(function()
    while true do
        if S.names and CES.HasPerm('misc.nametags') then
            local me = PlayerId()
            local myC = GetEntityCoords(PlayerPedId())
            for _, pl in ipairs(GetActivePlayers()) do
                if pl ~= me or Config.NameTags.ShowSelf then
                    local ped = GetPlayerPed(pl)
                    local c = GetEntityCoords(ped)
                    if #(c - myC) < Config.NameTags.Distance then
                        local zOff = IsPedOnMount(ped) and 2.1 or 1.15
                        U.DrawText3D(c.x, c.y, c.z + zOff, ('[%d] %s'):format(GetPlayerServerId(pl), GetPlayerName(pl)))
                    end
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- Player blips
local blips = {}

local function clearBlips()
    for pl, b in pairs(blips) do
        if DoesBlipExist(b.blip) then RemoveBlip(b.blip) end
        blips[pl] = nil
    end
end

CreateThread(function()
    while true do
        if S.blips and CES.HasPerm('misc.blips') then
            local seen, me = {}, PlayerId()
            for _, pl in ipairs(GetActivePlayers()) do
                if pl ~= me then
                    seen[pl] = true
                    local ped = GetPlayerPed(pl)
                    local b = blips[pl]
                    if not b or b.ped ~= ped or not DoesBlipExist(b.blip) then
                        if b and DoesBlipExist(b.blip) then RemoveBlip(b.blip) end
                        local blip = U.Invoke(0x23F74C2FDA6E7C61, -1230993421, ped) -- BLIP_ADD_FOR_ENTITY
                        if blip then
                            U.Invoke(0x9CB1A1623062F402, blip, ('[%d] %s'):format(GetPlayerServerId(pl), GetPlayerName(pl))) -- SET_BLIP_NAME
                            blips[pl] = { blip = blip, ped = ped }
                        end
                    end
                end
            end
            for pl, b in pairs(blips) do
                if not seen[pl] then
                    if DoesBlipExist(b.blip) then RemoveBlip(b.blip) end
                    blips[pl] = nil
                end
            end
            Wait(1000)
        else
            if next(blips) then clearBlips() end
            Wait(1000)
        end
    end
end)

-- Delete gun: aim + shoot at a ped, horse, wagon or object to delete it.
CreateThread(function()
    while true do
        if S.deleteGun and CES.HasPerm('misc.deletegun') then
            local ped = PlayerPedId()
            if IsPlayerFreeAiming(PlayerId()) and IsPedShooting(ped) then
                local hit, ent = GetEntityPlayerIsFreeAimingAt(PlayerId())
                if hit and ent and ent ~= 0 and DoesEntityExist(ent) then
                    if GetEntityType(ent) == 1 and IsPedAPlayer(ent) then
                        CES.Notify('You cannot delete players.', 'error')
                    else
                        U.DeleteEntity(ent)
                        CES.Notify('Entity deleted.', 'success')
                    end
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then clearBlips() end
end)
