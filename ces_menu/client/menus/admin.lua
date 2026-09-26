local Menu, S = CES.Menu, CES.State

local bans = {}

Menu.Register('admin', {
    title = 'Admin Tools',
    perms = { 'players.announce', 'players.unban', 'misc.deletegun' },
    build = function(m)
        m:button({ label = 'Server Announcement', perm = 'players.announce',
            desc = 'Shows a banner to every player.',
            onSelect = function()
                local text = CES.Prompt('Announcement', '', 'Message for everyone', 400)
                if text then
                    local ok, err = CES.Callback('announce', text)
                    CES.Result(ok, err)
                end
            end })
        m:submenu({ label = 'Ban List', perm = 'players.unban', menu = 'bans' })
        m:checkbox({ label = 'Delete Gun', perm = 'misc.deletegun', checked = S.deleteGun,
            desc = 'Aim and shoot a ped, horse, wagon or object to delete it.',
            onChange = function(v) S.deleteGun = v end })
    end,
})

Menu.Register('bans', {
    title = 'Ban List',
    perms = { 'players.unban' },
    empty = 'No active bans.',
    onOpen = function()
        local list = CES.Callback('getBans')
        bans = type(list) == 'table' and list or {}
    end,
    build = function(m)
        for i, b in ipairs(bans) do
            m:submenu({ id = 'b' .. b.id, label = b.name or '?', right = b.expires == 'Permanent' and 'Perm' or nil,
                desc = ('%s · by %s · until %s'):format(b.reason, b.by, b.expires),
                menu = 'ban', args = { key = b.id, index = i } })
        end
    end,
})

Menu.Register('ban', {
    title = function(a) return bans[a.index] and bans[a.index].name or 'Ban' end,
    perms = { 'players.unban' },
    build = function(m, a)
        local b = bans[a.index]
        if not b then return end
        m:button({ label = 'Reason', right = b.reason, disabled = true })
        m:button({ label = 'Banned By', right = b.by, disabled = true })
        m:button({ label = 'Created', right = b.created, disabled = true })
        m:button({ label = 'Expires', right = b.expires, disabled = true })
        m:button({ label = 'Ban ID', right = b.id, disabled = true })
        m:separator()
        m:button({ label = 'Unban', onSelect = function()
            local ok, err = CES.Callback('unban', b.id)
            if CES.Result(ok, err, ('Unbanned %s.'):format(b.name)) then
                table.remove(bans, a.index)
                Menu.Back()
            end
        end })
    end,
})
