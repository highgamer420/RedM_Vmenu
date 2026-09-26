local Menu, U, S = CES.Menu, CES.Util, CES.State

-- ─── Saved locations (per player, KVP) ──────────────────────
local KVP = 'ces_menu:locations'
local saved = json.decode(GetResourceKvpString(KVP) or '[]') or {}

local function persist() SetResourceKvp(KVP, json.encode(saved)) end

local function currentPos()
    local ent = U.GetMoveEntity(false)
    local c = GetEntityCoords(ent)
    return { x = U.Round(c.x, 2), y = U.Round(c.y, 2), z = U.Round(c.z, 2), h = U.Round(GetEntityHeading(ent), 2) }
end

local function parseCoords(text)
    local nums = {}
    for n in tostring(text):gmatch('-?%d+%.?%d*') do nums[#nums + 1] = tonumber(n) end
    if #nums < 2 then return nil end
    return nums[1], nums[2], nums[3], nums[4]
end

Menu.Register('teleport', {
    title = 'Teleport',
    perms = { 'teleport.waypoint', 'teleport.locations', 'teleport.coords', 'teleport.saved' },
    build = function(m)
        m:button({ label = 'Teleport to Waypoint', perm = 'teleport.waypoint',
            desc = 'Set a waypoint on the map first.',
            onSelect = function()
                if not IsWaypointActive() then return CES.Notify('No waypoint set.', 'error') end
                local w = GetWaypointCoords()
                U.Teleport(w.x, w.y, nil)
            end })
        m:submenu({ label = 'Locations', perm = 'teleport.locations', menu = 'tp_locations',
            desc = 'Towns and landmarks.' })
        m:button({ label = 'Teleport to Coordinates', perm = 'teleport.coords',
            desc = 'Type "x y" or "x y z" (commas and vector3() are fine).',
            onSelect = function()
                local text = CES.Prompt('Teleport to coordinates', '', 'x, y, z')
                if not text then return end
                local x, y, z, h = parseCoords(text)
                if not x then return CES.Notify('Could not read those coordinates.', 'error') end
                U.Teleport(x, y, z, h)
            end })
        m:submenu({ label = 'Saved Locations', perm = 'teleport.saved', menu = 'tp_saved',
            right = tostring(#saved), desc = 'Your personal teleport spots, saved on your PC.' })
        m:separator()
        m:checkbox({ label = 'Bring Horse / Wagon', checked = S.tpWithMount,
            desc = 'Teleport your horse or wagon with you when riding or driving.',
            onChange = function(v) S.tpWithMount = v end })
    end,
})

Menu.Register('tp_locations', {
    title = 'Locations',
    perms = { 'teleport.locations' },
    build = function(m)
        for i, loc in ipairs(Config.Locations) do
            m:button({ id = 'loc' .. i, label = loc.label,
                onSelect = function() U.Teleport(loc.x, loc.y, loc.z, loc.h) end })
        end
    end,
})

Menu.Register('tp_saved', {
    title = 'Saved Locations',
    perms = { 'teleport.saved' },
    build = function(m)
        m:button({ label = 'Save Current Location', desc = 'Stores where you stand right now.',
            onSelect = function()
                if #saved >= Config.MaxSavedLocations then
                    return CES.Notify(('You can save up to %d locations.'):format(Config.MaxSavedLocations), 'error')
                end
                local name = CES.Prompt('Name this location', ('Location %d'):format(#saved + 1), 'Name', 40)
                if not name then return end
                local p = currentPos()
                p.name = name
                saved[#saved + 1] = p
                persist()
                CES.Notify(('Saved "%s".'):format(name), 'success')
            end })
        if #saved > 0 then m:separator() end
        for i, loc in ipairs(saved) do
            m:submenu({ id = 'saved' .. i, label = loc.name, menu = 'tp_saved_item',
                desc = ('%.1f, %.1f, %.1f'):format(loc.x, loc.y, loc.z),
                args = { key = i .. ':' .. loc.name, index = i } })
        end
    end,
})

Menu.Register('tp_saved_item', {
    title = function(a) return saved[a.index] and saved[a.index].name or 'Location' end,
    perms = { 'teleport.saved' },
    build = function(m, a)
        local loc = saved[a.index]
        if not loc then return end
        m:button({ label = 'Teleport', onSelect = function() U.Teleport(loc.x, loc.y, loc.z, loc.h) end })
        m:button({ label = 'Rename', onSelect = function()
            local name = CES.Prompt('Rename location', loc.name, 'Name', 40)
            if name then loc.name = name persist() end
        end })
        m:button({ label = 'Overwrite With Current Position', onSelect = function()
            local p = currentPos()
            p.name = loc.name
            saved[a.index] = p
            persist()
            CES.Notify('Location updated.', 'success')
        end })
        m:button({ label = 'Copy Coordinates', onSelect = function()
            SendNUIMessage({ action = 'copy', text = ('vector4(%.2f, %.2f, %.2f, %.2f)'):format(loc.x, loc.y, loc.z, loc.h or 0.0) })
            CES.Notify('Copied to clipboard.', 'success')
        end })
        m:button({ label = 'Delete', onSelect = function()
            table.remove(saved, a.index)
            persist()
            CES.Notify('Location deleted.', 'success')
            Menu.Back()
        end })
    end,
})
