local Menu = CES.Menu

Menu.Register('main', {
    title = 'Main Menu',
    build = function(m)
        m:submenu({ label = 'Self',              menu = 'self',       desc = 'God mode, healing, cores, noclip and more.' })
        m:submenu({ label = 'Online Players',    menu = 'players',    desc = 'Teleport to, spectate, heal, kick or ban players.' })
        m:submenu({ label = 'Teleport',          menu = 'teleport',   desc = 'Waypoint, towns, coordinates and your saved spots.' })
        m:submenu({ label = 'Weapons',           menu = 'weapons',    desc = 'Give weapons, refill ammo, infinite ammo.' })
        m:submenu({ label = 'Horses & Wagons',   menu = 'mounts',     desc = 'Spawn and manage horses and wagons.' })
        m:submenu({ label = 'Appearance',        menu = 'appearance', desc = 'Player model, outfit presets and scale.' })
        m:submenu({ label = 'World',             menu = 'world',      desc = 'Server time and weather.' })
        m:submenu({ label = 'Admin Tools',       menu = 'admin',      desc = 'Announcements, ban list and the delete gun.' })
        m:submenu({ label = 'Misc',              menu = 'misc',       desc = 'Coordinates, name tags and player blips.' })
        for _, e in ipairs(Menu.mainEntries) do
            m:submenu({ label = e.label, menu = e.menu, desc = e.desc })
        end
        if #m.items > 0 then m:separator() end
        m:submenu({ label = 'Settings', menu = 'settings', desc = 'Theme, position and size of this menu.' })
    end,
})
