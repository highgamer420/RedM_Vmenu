local Menu, U, S = CES.Menu, CES.Util, CES.State

local speedLabels = {}
for i, v in ipairs(Config.Noclip.Speeds) do speedLabels[i] = ('%d  (x%s)'):format(i, tostring(v)) end

Menu.Register('self', {
    title = 'Self',
    perms = {
        'self.godmode', 'self.invisible', 'self.infinitestamina', 'self.infinitedeadeye', 'self.noragdoll',
        'self.heal', 'self.revive', 'self.clean', 'self.suicide', 'noclip',
    },
    build = function(m)
        m:checkbox({ label = 'God Mode', perm = 'self.godmode', checked = S.god,
            desc = 'You cannot be hurt or killed.',
            onChange = function(v) CES.SetToggle('god', v) end })
        m:checkbox({ label = 'Invisible', perm = 'self.invisible', checked = S.invisible,
            desc = 'Other players cannot see you.',
            onChange = function(v) CES.SetToggle('invisible', v) end })
        m:checkbox({ label = 'Infinite Stamina', perm = 'self.infinitestamina', checked = S.stamina,
            desc = 'Keeps your stamina core and bar full.',
            onChange = function(v) CES.SetToggle('stamina', v) end })
        m:checkbox({ label = 'Infinite Dead Eye', perm = 'self.infinitedeadeye', checked = S.deadeye,
            desc = 'Keeps your Dead Eye core full.',
            onChange = function(v) CES.SetToggle('deadeye', v) end })
        m:checkbox({ label = 'No Ragdoll', perm = 'self.noragdoll', checked = S.noragdoll,
            desc = 'You won\'t fall over from hits, falls or horses.',
            onChange = function(v) CES.SetToggle('noragdoll', v) end })

        m:separator('Noclip')
        m:checkbox({ label = 'Noclip', perm = 'noclip', checked = S.noclip,
            desc = 'Fly freely. W/A/S/D move, E/Space up, Q down, Shift fast, Ctrl slow.',
            onChange = function(v) CES.SetNoclip(v) end })
        m:list({ id = 'noclipSpeed', label = 'Noclip Speed', perm = 'noclip', options = speedLabels, index = S.noclipSpeed,
            onChange = function(i) CES.SetNoclipSpeed(i) end })

        m:separator('Actions')
        m:button({ label = 'Heal', perm = 'self.heal', desc = 'Restore health and fill all cores.',
            onSelect = function() U.Heal() CES.Notify('Healed.', 'success') end })
        m:button({ label = 'Revive', perm = 'self.revive', desc = 'Bring yourself back to life.',
            onSelect = function() U.Revive() end })
        m:button({ label = 'Clean Up', perm = 'self.clean', desc = 'Remove dirt, blood and wetness.',
            onSelect = function() U.Clean() CES.Notify('Cleaned up.', 'success') end })
        m:button({ label = 'Suicide', perm = 'self.suicide', desc = 'Kill yourself.',
            onSelect = function()
                if S.god then CES.SetToggle('god', false) end
                SetEntityHealth(PlayerPedId(), 0)
            end })
    end,
})
