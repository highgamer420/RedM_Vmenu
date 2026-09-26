local Menu, S = CES.Menu, CES.State

local FORMATS = {
    { label = 'vector3', value = 'vector3' },
    { label = 'vector4', value = 'vector4' },
    { label = 'Lua table', value = 'table' },
    { label = 'JSON', value = 'json' },
}

Menu.Register('misc', {
    title = 'Misc',
    perms = { 'misc.coords', 'misc.nametags', 'misc.blips' },
    build = function(m)
        m:checkbox({ label = 'Show Coordinates', perm = 'misc.coords', checked = S.coords,
            onChange = function(v) S.coords = v end })
        m:list({ id = 'copy', label = 'Copy Coordinates', perm = 'misc.coords', options = FORMATS,
            desc = 'Pick a format with ← →, press Enter to copy. Also printed to the F8 console.',
            onSelect = function(_, opt) CES.CopyCoords(opt.value) end })
        m:checkbox({ label = 'Player Name Tags', perm = 'misc.nametags', checked = S.names,
            desc = ('Show [ID] name above players within %dm.'):format(math.floor(Config.NameTags.Distance)),
            onChange = function(v) S.names = v end })
        m:checkbox({ label = 'Player Blips', perm = 'misc.blips', checked = S.blips,
            desc = 'Show nearby players on the map.',
            onChange = function(v) S.blips = v end })
    end,
})
