-- Public API for other resources.
--
--   exports.ces_menu:RegisterMenu('my_menu', {
--       title = 'My Stuff',
--       perms = { 'noclip' },              -- optional, any CES Menu permission names
--       build = function(args)             -- return a list of items
--           return {
--               { type = 'button', label = 'Say hi', onSelect = function() print('hi') end },
--               { type = 'checkbox', label = 'Toggle', checked = false, onChange = function(v) end },
--           }
--       end,
--   })
--   exports.ces_menu:AddMainMenuEntry({ label = 'My Stuff', menu = 'my_menu', desc = '...' })

local Menu = CES.Menu

exports('RegisterMenu', function(id, def)
    Menu.Register(id, {
        title = def.title,
        perms = def.perms,
        empty = def.empty,
        build = function(m, args)
            local items = (def.build and def.build(args)) or def.items or {}
            for _, it in ipairs(items) do
                if it.type == 'separator' then m:separator(it.label) else m:add(it.type or 'button', it) end
            end
        end,
    })
end)

exports('AddMainMenuEntry', function(entry)
    for i, e in ipairs(Menu.mainEntries) do
        if e.menu == entry.menu then Menu.mainEntries[i] = entry return end
    end
    Menu.mainEntries[#Menu.mainEntries + 1] = entry
end)

exports('Open', function(id, args)
    CreateThread(function()
        Menu.Open()
        if id then Menu.Push(id, args) end
    end)
end)
exports('Close', function() Menu.Close() end)
exports('IsOpen', function() return Menu.open end)
exports('Refresh', function() Menu.Refresh() end)
exports('Notify', function(msg, kind, title) CES.Notify(msg, kind, title) end)
exports('HasPermission', function(perm) return CES.HasPerm(perm) end)
exports('Prompt', function(title, default, placeholder) return CES.Prompt(title, default, placeholder) end)

--- Add add-on content at runtime from another resource (client side, this player only).
--- kind: 'peds' | 'horses' | 'wagons' | 'weapons' | 'clothing' | 'horse_tack' | 'weapon_components'
exports('AddAddon', function(kind, entry)
    if not CES.Addons[kind] or type(entry) ~= 'table' then return false end
    table.insert(CES.Addons[kind], entry)
    for _, f in ipairs(CES.AddonListeners) do pcall(f) end
    Menu.Refresh()
    return true
end)
