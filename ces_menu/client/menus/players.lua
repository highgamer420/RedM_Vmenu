local Menu, U = CES.Menu, CES.Util

local players = {}
local frozen = {}

local BAN_LENGTHS = {
    { label = '1 Hour',    hours = 1 },
    { label = '6 Hours',   hours = 6 },
    { label = '1 Day',     hours = 24 },
    { label = '3 Days',    hours = 72 },
    { label = '1 Week',    hours = 168 },
    { label = '30 Days',   hours = 720 },
    { label = 'Permanent', hours = 0 },
}

local function fetchPlayers()
    local list = CES.Callback('getPlayers')
    if type(list) == 'table' then players = list end
end

Menu.Register('players', {
    title = 'Online Players',
    perms = { 'players.view' },
    empty = 'No players online.',
    onOpen = fetchPlayers,
    build = function(m)
        m:button({ label = 'Refresh List', right = ('%d online'):format(#players),
            onSelect = function() fetchPlayers() end })
        m:separator()
        for _, p in ipairs(players) do
            local label = ('[%d] %s'):format(p.id, p.name)
            if p.self then label = label .. '  (you)' end
            m:submenu({
                id = 'pl_' .. p.id,
                label = label,
                right = p.immune and 'Staff' or nil,
                desc = ('Server ID %d · Ping %dms'):format(p.id, p.ping or 0),
                menu = 'player',
                args = { key = p.id, id = p.id, name = p.name, self = p.self },
            })
        end
    end,
})

local function act(name, successText, ...)
    local ok, msg = CES.Callback(name, ...)
    return CES.Result(ok, msg, successText)
end

Menu.Register('player', {
    title = function(a) return ('[%d] %s'):format(a.id or 0, a.name or '?') end,
    perms = { 'players.view' },
    build = function(m, a)
        local id, name = a.id, a.name
        local spectating = CES.Spectate.active and CES.Spectate.target == id

        m:button({ label = 'Teleport To Player', perm = 'players.goto', visible = not a.self,
            onSelect = function()
                local ok, c = CES.Callback('goto', id)
                if not ok then return CES.Notify(c, 'error') end
                if CES.Spectate.active then CES.StopSpectate(true) end
                U.Teleport(c.x + 1.0, c.y, c.z)
            end })
        m:button({ label = 'Bring Player', perm = 'players.bring', visible = not a.self,
            onSelect = function() act('bring', ('Brought %s to you.'):format(name), id) end })
        m:checkbox({ label = 'Spectate', perm = 'players.spectate', visible = not a.self, checked = spectating,
            onChange = function(v)
                if v then CES.StartSpectate(id, name) else CES.StopSpectate() end
            end })
        m:checkbox({ label = 'Freeze', perm = 'players.freeze', checked = frozen[id] == true,
            onChange = function(v)
                if act('freeze', v and ('Froze %s.'):format(name) or ('Unfroze %s.'):format(name), id, v) then
                    frozen[id] = v
                end
            end })

        m:separator('Health')
        m:button({ label = 'Heal', perm = 'players.heal',
            onSelect = function() act('heal', ('Healed %s.'):format(name), id) end })
        m:button({ label = 'Revive', perm = 'players.revive',
            onSelect = function() act('revive', ('Revived %s.'):format(name), id) end })
        m:button({ label = 'Kill', perm = 'players.kill',
            onSelect = function() act('kill', ('Killed %s.'):format(name), id) end })

        m:separator('Moderation')
        m:button({ label = 'Send Message', perm = 'players.message',
            onSelect = function()
                local text = CES.Prompt(('Message to %s'):format(name), '', 'Type your message...')
                if text then act('message', 'Message sent.', id, text) end
            end })
        m:button({ label = 'Kick', perm = 'players.kick', visible = not a.self,
            onSelect = function()
                local reason = CES.Prompt(('Kick %s - reason'):format(name), '', 'Reason for the kick')
                if reason and act('kick', ('Kicked %s.'):format(name), id, reason) then fetchPlayers() Menu.Back() end
            end })
        m:list({ id = 'ban', label = 'Ban', perm = 'players.ban', visible = not a.self, options = BAN_LENGTHS,
            desc = 'Pick a length with ← →, then press Enter.',
            onSelect = function(_, opt)
                local reason = CES.Prompt(('Ban %s (%s) - reason'):format(name, opt.label), '', 'Reason for the ban')
                if reason and act('ban', ('Banned %s (%s).'):format(name, opt.label), id, opt.hours, reason) then
                    fetchPlayers() Menu.Back()
                end
            end })
    end,
})
